#!/usr/bin/env python3
import json
from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer


WEIGHTS = {
    "shared_crypto_wallet": 28,
    "deposit_before_kyc": 18,
    "recent_kyc": 16,
    "no_trading": 18,
    "two_cards_same_bank": 14,
    "failed_payments_descending": 18,
    "foreign_card_country": 16,
    "withdrawal_geo_mismatch": 14,
    "first_deposit_less_than_week": 12,
    "manual_review_volume": 6,
    "multi_ip_registration": 24,
    "phone_bank_country_mismatch": 16,
    "shared_bank_card": 24,
    "recent_email_change": 18,
    "recent_2fa_change": 18,
}


class RiskHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.respond({"status": "ok", "service": "python_risk_engine"})
        else:
            self.send_error(404)

    def do_POST(self):
        if self.path != "/score":
            self.send_error(404)
            return

        length = int(self.headers.get("content-length", "0"))
        payload = json.loads(self.rfile.read(length) or "{}")
        triggers = payload.get("triggers", [])

        score = 25 + sum(WEIGHTS.get(trigger, 8) for trigger in triggers)
        if not payload.get("kyc_level_2"):
            score += 10
        if payload.get("deposits_before_kyc_l1"):
            score += 10
        if payload.get("kyc_l1_hours_before_withdrawal", 999) < 36:
            score += 10
        if payload.get("trades_count", 0) == 0:
            score += 12

        score = min(score, 98)
        decision = "block" if score >= 85 else "review" if score >= 55 else "allow"

        self.respond(
            {
                "risk_score": score,
                "decision": decision,
                "engine_status": "python_rules_v1",
                "checked_at": datetime.now().strftime("%H:%M:%S"),
                "reasons": triggers,
                "model_note": "Prototype risk engine: rules now, ML/anomaly model later",
            }
        )

    def respond(self, data):
        body = json.dumps(data).encode("utf-8")
        self.send_response(200)
        self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        return


if __name__ == "__main__":
    server = HTTPServer(("127.0.0.1", 5055), RiskHandler)
    print("Python risk engine running at http://127.0.0.1:5055")
    server.serve_forever()
