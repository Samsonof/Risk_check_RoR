"""
Six-block rule engine, faithful to the architecture spec.

Each block accepts a feature dict + settings dict and returns a BlockResult.
The dispatcher in server.py composes them and computes the final outcome.

block_no  name
   1      Financial limits
   2      Account history
   3      KYC + recipient details
   4      Behavioral
   5      Risk scoring (the weighted points block)
   6      Payment patterns
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


@dataclass
class Reason:
    block: int
    code: str
    message: str
    pts: int = 0  # only block 5 contributes points; others can also feed pts if useful


@dataclass
class BlockResult:
    block_no: int
    passed: bool                  # True = no signal, request can still auto-approve
    reasons: list[Reason] = field(default_factory=list)
    score_pts: int = 0            # only block 5 sets this meaningfully
    hard_review: bool = False     # if True, immediately route to manual review regardless of others


def _get_b(settings: dict, key: str) -> bool:
    return bool(settings.get(key, True))


def _get_n(settings: dict, key: str, default: float) -> float:
    v = settings.get(key)
    return float(v) if v is not None else float(default)


# ---------- BLOCK 1 — Financial limits ----------

def block1_financial_limits(features: dict, settings: dict) -> BlockResult:
    res = BlockResult(block_no=1, passed=True)
    if not _get_b(settings, "block1_financial_limits"):
        return res

    amount = features["amount_usd"]
    sum_24h = features["sum_withdrawals_24h_usd"] + amount
    sum_7d = features["sum_withdrawals_7d_usd"] + amount
    sum_30d = features["sum_withdrawals_30d_usd"] + amount
    count_24h = features["count_withdrawals_24h"] + 1

    # Country override comes first, then global
    cp = features.get("country_profile") or {}
    country_single = cp.get("max_single_usd")
    country_24h = cp.get("max_24h_usd")
    country_count = cp.get("max_24h_count")

    global_single = _get_n(settings, "global_single_max_usd", 500)
    global_24h = _get_n(settings, "global_24h_max_usd", 500)
    global_7d = _get_n(settings, "global_7d_max_usd", 10_000)
    global_30d = _get_n(settings, "global_30d_max_usd", 30_000)
    hard_limit = _get_n(settings, "hard_limit_usd", 5_000)
    min_amount = 10  # spec mentions $10 minimum

    # KYC tier multiplier applies to AUTO-approve single limit only (Tier 1 = 50%)
    tier = features["kyc_tier"]
    if tier == 0:
        res.passed = False
        res.hard_review = True
        res.reasons.append(Reason(1, "tier0_no_withdrawal", "Tier 0 client cannot withdraw"))
        return res

    tier_mult = _get_n(settings, "tier1_limit_multiplier_pct", 50) / 100.0 if tier == 1 else 1.0
    single_cap = (country_single if country_single is not None else global_single) * tier_mult

    if amount > hard_limit:
        res.passed = False
        res.hard_review = True
        res.reasons.append(Reason(1, "hard_limit_exceeded", f"Amount ${amount:.0f} exceeds hard limit ${hard_limit:.0f}"))
    if amount < min_amount:
        res.passed = False
        res.reasons.append(Reason(1, "below_minimum", f"Amount ${amount:.0f} below minimum ${min_amount}"))
    if amount > single_cap:
        res.passed = False
        res.reasons.append(Reason(1, "single_amount_over_cap",
                                  f"Amount ${amount:.0f} exceeds single-tx cap ${single_cap:.0f} (Tier {tier}{' / country override' if country_single else ''})"))

    if country_24h is not None and sum_24h > country_24h:
        res.passed = False
        res.reasons.append(Reason(1, "country_24h_amount", f"24h sum ${sum_24h:.0f} exceeds country cap ${country_24h:.0f}"))
    elif sum_24h > global_24h:
        res.passed = False
        res.reasons.append(Reason(1, "global_24h_amount", f"24h sum ${sum_24h:.0f} exceeds global 24h cap ${global_24h:.0f}"))

    if country_count is not None and count_24h > country_count:
        res.passed = False
        res.reasons.append(Reason(1, "country_24h_count", f"{count_24h} requests in 24h exceeds country cap {country_count}"))

    if sum_7d > global_7d:
        res.passed = False
        res.reasons.append(Reason(1, "global_7d_amount", f"7d sum ${sum_7d:.0f} exceeds 7d cap ${global_7d:.0f}"))
    if sum_30d > global_30d:
        res.passed = False
        res.reasons.append(Reason(1, "global_30d_amount", f"30d sum ${sum_30d:.0f} exceeds 30d cap ${global_30d:.0f}"))

    return res


# ---------- BLOCK 2 — Account history ----------

def block2_account_history(features: dict, settings: dict) -> BlockResult:
    res = BlockResult(block_no=2, passed=True)
    if not _get_b(settings, "block2_account_history"):
        return res

    min_age_days = _get_n(settings, "min_account_age_days", 3)
    min_hours_since_deposit = _get_n(settings, "min_hours_since_last_deposit", 24)
    min_trade_vol = _get_n(settings, "min_trade_volume_usd", 500)

    if features["account_age_days"] < min_age_days:
        res.passed = False
        res.reasons.append(Reason(2, "account_too_young",
                                  f"Account age {features['account_age_days']}d < min {int(min_age_days)}d"))

    last_dep = features.get("hours_since_last_deposit")
    if last_dep is not None and last_dep < min_hours_since_deposit:
        res.passed = False
        res.reasons.append(Reason(2, "deposit_too_recent",
                                  f"Last deposit was {last_dep:.0f}h ago, threshold is {int(min_hours_since_deposit)}h"))

    if features["total_trade_volume_usd"] < min_trade_vol and not features["is_first_withdrawal"]:
        # spec wraps trade-vol in "before first withdrawal" but we also use it as a soft baseline
        res.passed = False
        res.reasons.append(Reason(2, "low_trading_volume",
                                  f"Total trade volume ${features['total_trade_volume_usd']:.0f} below ${int(min_trade_vol)}"))

    return res


# ---------- BLOCK 3 — KYC + recipient ----------

def block3_kyc_recipient(features: dict, settings: dict) -> BlockResult:
    res = BlockResult(block_no=3, passed=True)
    if not _get_b(settings, "block3_kyc_recipient"):
        return res

    tier = features["kyc_tier"]
    amount = features["amount_usd"]
    tier1_cap = _get_n(settings, "global_single_max_usd", 500) * _get_n(settings, "tier1_limit_multiplier_pct", 50) / 100.0

    if tier == 1 and amount > tier1_cap:
        res.passed = False
        res.reasons.append(Reason(3, "tier1_above_cap", f"Tier 1 client requesting ${amount:.0f} above Tier 1 cap ${tier1_cap:.0f}"))

    # "new destination" check does not apply to a client's very first withdrawal —
    # the first-withdrawal policy is a separate gate for that case.
    if (_get_b(settings, "check_new_destination") and features["destination_is_new"]
        and not features["is_first_withdrawal"]):
        res.passed = False
        kind = {"bank": "bank account", "crypto": "crypto wallet", "binance": "Binance account"}.get(features["method"], features["method"])
        res.reasons.append(Reason(3, "new_destination", f"First withdrawal to this {kind}"))

    if features.get("name_mismatch"):
        res.passed = False
        res.reasons.append(Reason(3, "name_mismatch", "Destination account holder differs from KYC name"))

    if features.get("hours_since_recipient_change") is not None and features["hours_since_recipient_change"] < 48:
        res.passed = False
        res.reasons.append(Reason(3, "recent_recipient_change",
                                  f"Recipient details changed {features['hours_since_recipient_change']:.0f}h ago (<48h)"))

    return res


# ---------- BLOCK 4 — Behavioral ----------

def block4_behavioral(features: dict, settings: dict) -> BlockResult:
    res = BlockResult(block_no=4, passed=True)
    if not _get_b(settings, "block4_behavioral"):
        return res

    if _get_b(settings, "check_new_ip") and features.get("origin_ip_is_new"):
        res.passed = False
        res.reasons.append(Reason(4, "new_ip", f"Request from new IP {features.get('origin_ip')}"))

    hsp = features.get("hours_since_password_change")
    if hsp is not None and hsp < 1:
        res.passed = False
        res.reasons.append(Reason(4, "post_password_change", f"Withdrawal {hsp*60:.0f}min after password change"))

    if features.get("multi_account_ip"):
        res.passed = False
        res.reasons.append(Reason(4, "shared_ip", "Multiple accounts seen from this IP"))

    return res


# ---------- BLOCK 5 — Risk scoring (weighted points) ----------

def block5_scoring(features: dict, settings: dict) -> BlockResult:
    res = BlockResult(block_no=5, passed=True)
    if not _get_b(settings, "block5_risk_scoring"):
        return res

    threshold = _get_n(settings, "scoring_threshold_pts", 10)
    pts = 0
    contributions: list[Reason] = []

    def add(code, message, p):
        nonlocal pts
        pts += p
        contributions.append(Reason(5, code, message, pts=p))

    cap = features.get("country_profile", {}).get("max_single_usd") or _get_n(settings, "global_single_max_usd", 500)
    if features["amount_usd"] > 0.8 * cap:
        add("near_cap", f"Amount ${features['amount_usd']:.0f} > 80% of cap ${cap:.0f}", 3)
    if features["destination_is_new"] and not features["is_first_withdrawal"]:
        add("first_to_destination", "First withdrawal to this destination", 4)
    if features["account_age_days"] < 7:
        add("young_account", f"Account younger than 7d ({features['account_age_days']}d)", 5)
    if features.get("withdraw_over_50pct_same_day_deposit"):
        add("over_half_same_day_deposit", "Withdrawal > 50% of today's deposit", 6)
    if features.get("origin_ip_is_new"):
        add("new_ip_pts", "New IP at request time", 3)
    if features["total_trade_volume_usd"] == 0:
        add("no_trading", "Withdrawal with zero trading activity", 6)
    if features["deposit_method"] == "card" and features["method"] in ("crypto", "binance"):
        add("card_to_crypto", "Card-funded → crypto/binance withdrawal (hardcoded high risk)", 8)
    if features.get("crypto_transit_no_activity"):
        add("crypto_transit", "Crypto→crypto with negligible trading activity", 7)

    res.score_pts = pts
    res.reasons = contributions
    if pts >= threshold:
        res.passed = False

    return res


# ---------- BLOCK 6 — Payment patterns ----------

def block6_payment_patterns(features: dict, settings: dict) -> BlockResult:
    res = BlockResult(block_no=6, passed=True)
    if not _get_b(settings, "block6_payment_patterns"):
        return res

    cards_24h = features.get("distinct_cards_24h", 0)
    card_threshold = int(_get_n(settings, "card_count_review_threshold", 2))

    if cards_24h >= 3 and features["method"] in ("bank", "crypto", "binance"):
        res.passed = False
        res.reasons.append(Reason(6, "carding_3plus_cards",
                                  f"{cards_24h} different cards in 24h before withdrawal"))
    elif cards_24h >= card_threshold and features["method"] == "bank":
        res.passed = False
        res.reasons.append(Reason(6, "carding_multi_cards_bank",
                                  f"{cards_24h} cards in 24h → bank withdrawal"))

    hsc = features.get("hours_since_last_card_deposit")
    if hsc is not None and hsc < 1:
        res.passed = False
        res.reasons.append(Reason(6, "withdrawal_within_hour_of_card",
                                  f"Withdrawal {hsc*60:.0f}min after a card deposit"))

    same_day_card_dep = features.get("today_card_deposit_sum_usd", 0)
    if same_day_card_dep > 0 and features["amount_usd"] > 0.8 * same_day_card_dep:
        res.passed = False
        res.reasons.append(Reason(6, "over_80pct_card_today",
                                  f"Withdrawal ${features['amount_usd']:.0f} > 80% of today's card deposits ${same_day_card_dep:.0f}"))

    if features.get("distinct_cardholders_count", 0) >= 2:
        res.passed = False
        res.reasons.append(Reason(6, "different_cardholders",
                                  f"{features['distinct_cardholders_count']} different cardholder names on account"))

    if features.get("crypto_transit_no_activity"):
        res.passed = False
        res.reasons.append(Reason(6, "crypto_transit_review",
                                  "Crypto-in → crypto-out with negligible trading"))

    return res


# ---------- First withdrawal policy (overlay, spec section "Условия авто-апрува первого вывода") ----------

def first_withdrawal_policy(features: dict, settings: dict) -> tuple[bool, list[Reason]]:
    """
    Returns (eligible_for_auto_approve, reasons_if_not).
    Only relevant when is_first_withdrawal=True AND blocks 1-6 would otherwise pass.
    Block-1's hard rules still take precedence.
    """
    if not features["is_first_withdrawal"] or not _get_b(settings, "first_withdrawal_policy"):
        return True, []

    issues: list[Reason] = []
    cap = _get_n(settings, "first_withdrawal_limit_usd", 100)
    min_trades = int(_get_n(settings, "min_trades_first_withdrawal", 1))

    if features["amount_usd"] > cap:
        issues.append(Reason(0, "first_over_cap", f"First-withdrawal amount ${features['amount_usd']:.0f} > cap ${cap:.0f}"))
    if _get_b(settings, "check_method_match") and features["deposit_method"] != features["method"]:
        issues.append(Reason(0, "first_method_mismatch",
                             f"First withdrawal method '{features['method']}' differs from deposit method '{features['deposit_method']}'"))
    if (features.get("hours_since_last_deposit") or 0) < 24:
        issues.append(Reason(0, "first_too_soon_after_deposit",
                             "First withdrawal less than 24h after deposit"))
    if features["closed_trades_count"] < min_trades:
        issues.append(Reason(0, "first_no_trades",
                             f"First withdrawal with only {features['closed_trades_count']} closed trades (need {min_trades})"))
    if features.get("origin_ip_is_new"):
        issues.append(Reason(0, "first_new_ip", "First withdrawal from a new IP (≠ registration IP)"))

    return (len(issues) == 0), issues


# ---------- Priority assignment (spec "Система приоритетов") ----------

def assign_priority(features: dict, all_reasons: list[Reason]) -> str:
    """
    P1 — first withdrawal
    P2 — chargeback: 2+ cards in 24h → bank withdrawal
    P3 — card → crypto/binance
    P4 — withdrawal within 24h of card deposit
    P5 — returning clean (≥3 successful) but tripped a formal rule
    P6 — escalation (recomputed at render time based on age)
    P7 — everything else
    """
    codes = {r.code for r in all_reasons}
    if features.get("is_first_withdrawal"):
        return "P1"
    if "carding_multi_cards_bank" in codes or "carding_3plus_cards" in codes:
        return "P2"
    if "card_to_crypto" in codes:
        return "P3"
    if "withdrawal_within_hour_of_card" in codes:
        return "P4"
    hsc = features.get("hours_since_last_card_deposit")
    if hsc is not None and hsc < 24:
        return "P4"
    if features.get("completed_prior_withdrawals", 0) >= 3:
        return "P5"
    return "P7"
