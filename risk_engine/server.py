"""
Withdrawal-architecture engine — FastAPI.

Endpoints:
  GET  /health
  POST /evaluate {"withdrawal_request_id": N}
  POST /reseed-decisions   — re-evaluate every withdrawal_request, used after config changes
  GET  /settings           — debug helper: dumps current settings

Reads SQLite shared with Rails. Persists one row per evaluation in `decisions`.
"""

from __future__ import annotations

import json
import os
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel

import blocks as B

ENGINE_VERSION = "withdrawal-engine v1.0 (spec v10)"
ROOT = Path(__file__).resolve().parent.parent
DEFAULT_DB = ROOT / "storage" / "development.sqlite3"
DB_PATH = Path(os.environ.get("RISK_ENGINE_DB", DEFAULT_DB))

app = FastAPI(title="Withdrawal Decision Engine", version="1.0")


# ---------- DB helpers ----------

def conn() -> sqlite3.Connection:
    if not DB_PATH.exists():
        raise HTTPException(503, f"DB missing at {DB_PATH}. Run `bin/rails db:setup`.")
    c = sqlite3.connect(DB_PATH, isolation_level=None)
    c.row_factory = sqlite3.Row
    c.execute("PRAGMA journal_mode=WAL")
    return c


def load_settings(c) -> dict:
    out = {}
    for row in c.execute("SELECT key, value, kind FROM settings"):
        if row["kind"] == "boolean":
            out[row["key"]] = row["value"].lower() in ("true", "1", "yes", "on")
        elif row["kind"] == "number":
            try:
                out[row["key"]] = float(row["value"])
            except ValueError:
                out[row["key"]] = 0.0
        else:
            out[row["key"]] = row["value"]
    return out


def load_country(c, code: str) -> dict | None:
    row = c.execute("SELECT * FROM country_profiles WHERE code=?", (code,)).fetchone()
    return dict(row) if row else None


# ---------- feature extraction (the hard part) ----------

def hours_since(reference_iso: str, target_iso: str | None) -> float | None:
    if not target_iso:
        return None
    ref = datetime.fromisoformat(reference_iso.replace("Z", "+00:00"))
    tgt = datetime.fromisoformat(target_iso.replace("Z", "+00:00"))
    return (ref - tgt).total_seconds() / 3600.0


def extract_features(c: sqlite3.Connection, wr_id: int, settings: dict) -> dict:
    wr = c.execute("SELECT * FROM withdrawal_requests WHERE id=?", (wr_id,)).fetchone()
    if not wr:
        raise HTTPException(404, f"withdrawal_request {wr_id} not found")
    client = c.execute("SELECT * FROM clients WHERE id=?", (wr["client_id"],)).fetchone()
    cp = load_country(c, client["country_code"])

    submitted = wr["submitted_at"]
    # past withdrawals (completed only, for amount-window sums)
    def sum_window(window_hours: int) -> int:
        row = c.execute(
            """SELECT COALESCE(SUM(amount_usd),0) AS s, COUNT(*) AS n
                 FROM previous_withdrawals
                WHERE client_id=? AND status='completed'
                  AND (julianday(?) - julianday(occurred_at)) * 24 <= ?""",
            (client["id"], submitted, window_hours),
        ).fetchone()
        return int(row["s"]), int(row["n"])

    sum_24h, count_24h = sum_window(24)
    sum_7d, _ = sum_window(24 * 7)
    sum_30d, _ = sum_window(24 * 30)

    completed_prior = c.execute(
        "SELECT COUNT(*) AS n FROM previous_withdrawals WHERE client_id=? AND status='completed'",
        (client["id"],),
    ).fetchone()["n"]

    # destination is new if no prior completed withdrawal hit this fingerprint
    dest_used_before = c.execute(
        "SELECT 1 FROM previous_withdrawals WHERE client_id=? AND status='completed' AND destination_fingerprint=? LIMIT 1",
        (client["id"], wr["destination_fingerprint"]),
    ).fetchone() is not None

    # most recent deposit
    last_dep = c.execute(
        "SELECT method, occurred_at, amount_usd FROM deposits WHERE client_id=? ORDER BY occurred_at DESC LIMIT 1",
        (client["id"],),
    ).fetchone()
    deposit_method = last_dep["method"] if last_dep else None
    hours_since_last_deposit = hours_since(submitted, last_dep["occurred_at"]) if last_dep else None

    # cards-in-24h
    cards_24h_rows = c.execute(
        """SELECT DISTINCT card_fingerprint FROM deposits
            WHERE client_id=? AND method='card' AND card_fingerprint IS NOT NULL
              AND (julianday(?) - julianday(occurred_at)) * 24 <= 24""",
        (client["id"], submitted),
    ).fetchall()
    distinct_cards_24h = len(cards_24h_rows)

    cardholder_rows = c.execute(
        "SELECT DISTINCT cardholder_name FROM deposits WHERE client_id=? AND cardholder_name IS NOT NULL AND cardholder_name != ''",
        (client["id"],),
    ).fetchall()
    distinct_cardholders_count = len(cardholder_rows)

    last_card_dep = c.execute(
        "SELECT occurred_at FROM deposits WHERE client_id=? AND method='card' ORDER BY occurred_at DESC LIMIT 1",
        (client["id"],),
    ).fetchone()
    hours_since_last_card_deposit = hours_since(submitted, last_card_dep["occurred_at"]) if last_card_dep else None

    # today's card deposit sum (last 24h)
    today_card_dep_sum = c.execute(
        """SELECT COALESCE(SUM(amount_usd),0) AS s FROM deposits
            WHERE client_id=? AND method='card'
              AND (julianday(?) - julianday(occurred_at)) * 24 <= 24""",
        (client["id"], submitted),
    ).fetchone()["s"]

    # same-day deposit total (any method)
    today_any_dep_sum = c.execute(
        """SELECT COALESCE(SUM(amount_usd),0) AS s FROM deposits
            WHERE client_id=? AND (julianday(?) - julianday(occurred_at)) * 24 <= 24""",
        (client["id"], submitted),
    ).fetchone()["s"]
    over_50pct_same_day = (today_any_dep_sum > 0 and wr["amount_usd"] > 0.5 * today_any_dep_sum)

    # trade totals
    trade_row = c.execute(
        "SELECT COALESCE(SUM(volume_usd),0) AS v, COUNT(*) AS n FROM trades WHERE client_id=?",
        (client["id"],),
    ).fetchone()

    # registration IP
    origin_ip_is_new = (wr["origin_ip"] is not None and wr["origin_ip"] != client["registration_ip"])

    # any password/bank/wallet change events? grab the most recent
    last_pw = c.execute(
        "SELECT occurred_at FROM account_events WHERE client_id=? AND kind='password_change' ORDER BY occurred_at DESC LIMIT 1",
        (client["id"],),
    ).fetchone()
    hours_since_password_change = hours_since(submitted, last_pw["occurred_at"]) if last_pw else None

    last_recipient_change = c.execute(
        """SELECT occurred_at FROM account_events WHERE client_id=?
            AND kind IN ('bank_change','crypto_address_change','binance_change')
            ORDER BY occurred_at DESC LIMIT 1""",
        (client["id"],),
    ).fetchone()
    hours_since_recipient_change = hours_since(submitted, last_recipient_change["occurred_at"]) if last_recipient_change else None

    # multi-account-IP flag
    multi_account_ip = c.execute(
        "SELECT 1 FROM ip_events WHERE client_id=? AND kind='shared_with_another_account' LIMIT 1",
        (client["id"],),
    ).fetchone() is not None

    # name mismatch: simple case-insensitive compare
    name_mismatch = False
    if wr["destination_holder_name"]:
        name_mismatch = wr["destination_holder_name"].strip().lower() != (client["kyc_full_name"] or "").strip().lower()

    # crypto transit detection
    crypto_transit = False
    if deposit_method == "crypto" and wr["method"] == "crypto":
        # trading activity as % of LAST crypto deposit
        last_crypto = c.execute(
            "SELECT amount_usd FROM deposits WHERE client_id=? AND method='crypto' ORDER BY occurred_at DESC LIMIT 1",
            (client["id"],),
        ).fetchone()
        if last_crypto:
            threshold_pct = settings.get("crypto_transit_activity_pct", 10.0)
            if trade_row["v"] < (threshold_pct / 100.0) * last_crypto["amount_usd"]:
                crypto_transit = True

    account_age_days = max(0, int((datetime.fromisoformat(submitted.replace("Z","+00:00")) -
                                   datetime.fromisoformat(client["registered_at"].replace("Z","+00:00"))).days))

    return {
        "withdrawal_request_id": wr_id,
        "request_id_label": wr["request_id"],
        "amount_usd": int(wr["amount_usd"]),
        "method": wr["method"],
        "deposit_method": deposit_method,
        "is_first_withdrawal": bool(wr["is_first_withdrawal"]),
        "kyc_tier": int(client["kyc_tier"]),
        "country_profile": cp,

        "sum_withdrawals_24h_usd": sum_24h,
        "sum_withdrawals_7d_usd":  sum_7d,
        "sum_withdrawals_30d_usd": sum_30d,
        "count_withdrawals_24h":   count_24h,
        "completed_prior_withdrawals": completed_prior,

        "destination_is_new": not dest_used_before,
        "name_mismatch": name_mismatch,
        "hours_since_recipient_change": hours_since_recipient_change,

        "account_age_days": account_age_days,
        "hours_since_last_deposit": hours_since_last_deposit,
        "total_trade_volume_usd": int(trade_row["v"]),
        "closed_trades_count": int(trade_row["n"]),

        "origin_ip": wr["origin_ip"],
        "origin_ip_is_new": origin_ip_is_new,
        "hours_since_password_change": hours_since_password_change,
        "multi_account_ip": multi_account_ip,

        "distinct_cards_24h": distinct_cards_24h,
        "distinct_cardholders_count": distinct_cardholders_count,
        "hours_since_last_card_deposit": hours_since_last_card_deposit,
        "today_card_deposit_sum_usd": int(today_card_dep_sum),
        "withdraw_over_50pct_same_day_deposit": bool(over_50pct_same_day),
        "crypto_transit_no_activity": crypto_transit,
    }


# ---------- composer ----------

def evaluate_one(c: sqlite3.Connection, wr_id: int, settings: dict, country_lookup=None) -> dict:
    features = extract_features(c, wr_id, settings)
    block_fns = [
        B.block1_financial_limits,
        B.block2_account_history,
        B.block3_kyc_recipient,
        B.block4_behavioral,
        B.block5_scoring,
        B.block6_payment_patterns,
    ]
    results = [fn(features, settings) for fn in block_fns]

    # First-withdrawal policy is an overlay
    fw_ok, fw_reasons = B.first_withdrawal_policy(features, settings)

    all_reasons: list[B.Reason] = []
    for r in results:
        all_reasons.extend(r.reasons)
    all_reasons.extend(fw_reasons)

    # Decide
    hard_review = any(r.hard_review for r in results)
    all_passed = all(r.passed for r in results) and fw_ok and not hard_review
    outcome = "auto_approve" if all_passed else "review"
    score_pts = next((r.score_pts for r in results if r.block_no == 5), 0)
    priority = B.assign_priority(features, all_reasons) if outcome == "review" else None

    block_results = {
        f"block{r.block_no}": {"passed": r.passed, "reasons_count": len(r.reasons), "score_pts": r.score_pts}
        for r in results
    }
    block_results["first_withdrawal_policy"] = {"passed": fw_ok, "reasons_count": len(fw_reasons)}

    reasons_payload = [{"block": r.block, "code": r.code, "message": r.message, "pts": r.pts} for r in all_reasons]

    now_iso = datetime.now(timezone.utc).isoformat()
    c.execute(
        """INSERT INTO decisions (withdrawal_request_id, outcome, score_pts, priority,
                                  reasons_json, block_results_json, engine_version, decided_at,
                                  created_at, updated_at)
           VALUES (?,?,?,?,?,?,?,?,?,?)""",
        (wr_id, outcome, score_pts, priority,
         json.dumps(reasons_payload), json.dumps(block_results),
         ENGINE_VERSION, now_iso, now_iso, now_iso),
    )

    return {
        "withdrawal_request_id": wr_id,
        "request_id_label": features["request_id_label"],
        "outcome": outcome,
        "priority": priority,
        "score_pts": score_pts,
        "engine_version": ENGINE_VERSION,
        "reasons": reasons_payload,
        "block_results": block_results,
        "checked_at": datetime.now().strftime("%H:%M:%S"),
    }


# ---------- API ----------

class EvalIn(BaseModel):
    withdrawal_request_id: int


@app.get("/health")
def health():
    settings_ok = False
    try:
        c = conn()
        settings_ok = c.execute("SELECT COUNT(*) FROM settings").fetchone()[0] > 0
        c.close()
    except Exception:
        pass
    return {
        "status": "ok",
        "service": "withdrawal_decision_engine",
        "engine": ENGINE_VERSION,
        "db_present": DB_PATH.exists(),
        "settings_loaded": settings_ok,
    }


@app.post("/evaluate")
def evaluate(p: EvalIn):
    c = conn()
    try:
        settings = load_settings(c)
        return JSONResponse(evaluate_one(c, p.withdrawal_request_id, settings))
    finally:
        c.close()


@app.post("/reseed-decisions")
def reseed_decisions():
    """Re-evaluate every withdrawal request. Useful after a settings change."""
    c = conn()
    try:
        settings = load_settings(c)
        ids = [row["id"] for row in c.execute("SELECT id FROM withdrawal_requests ORDER BY id")]
        results = []
        for wr_id in ids:
            try:
                results.append(evaluate_one(c, wr_id, settings))
            except HTTPException as e:
                results.append({"withdrawal_request_id": wr_id, "error": e.detail})
        summary = {
            "total": len(results),
            "auto_approve": sum(1 for r in results if r.get("outcome") == "auto_approve"),
            "review": sum(1 for r in results if r.get("outcome") == "review"),
        }
        return {"summary": summary, "results": results}
    finally:
        c.close()


@app.get("/settings")
def dump_settings():
    c = conn()
    try:
        return load_settings(c)
    finally:
        c.close()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("server:app",
                host=os.environ.get("RISK_ENGINE_HOST", "127.0.0.1"),
                port=int(os.environ.get("RISK_ENGINE_PORT", "5055")),
                reload=False)
