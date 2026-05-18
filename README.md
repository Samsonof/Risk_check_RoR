# RiskOps — client risk prototype

A presentation-grade prototype for a broker's withdrawal-review desk.

- **Rails 8 + Tailwind** — UI, queue, decision panel, reviewers/superadmin, rules editor.
- **Python FastAPI engine** — rules-based scorer (default) + ML-scorer stub.
  Reads the same SQLite file the Rails app writes to and persists every
  decision into `risk_decisions` for audit.

## Demo scenarios (8 cases, seeded)

| Case | Channel | Picture | Expected decision |
|---|---|---|---|
| C-10482 Ivan Petrov | crypto out | shared wallet, deposit before KYC | **block** |
| C-10508 Elena Garcia | card out (Visa OCT) | same-bank cards, failed deposits descending | review |
| C-10512 Diego Ruiz | crypto out | foreign BIN, shared wallet, geo mismatch | **block** |
| C-10519 Maya Thompson | bank transfer | clean, verified, returning customer | allow |
| C-10527 Sofia Almeida | crypto out | multi-IP cluster, no trading, KYC 18h | **hard block** |
| C-10534 Noah Stein | SEPA out | card seen on 2 profiles | review |
| C-10541 Aisha Khan | wire out | email changed 4h before withdrawal | review |
| C-10549 Luis Martinez | crypto out | 2FA change + shared wallet + foreign BIN | **hard block** |

## Personas

- **Marta Kowalska — Risk analyst** (toggles operation locks, approves)
- **Omar Haddad — Compliance lead** (approves, can edit rules)
- **Lucia Romero — Payments manager** (approves)
- **Anya Morozova — Superadmin** (overrides anything)

Switch persona from the avatar dropdown in the top-right.

## Setup

```bash
# 1. Ruby gems
bundle install

# 2. SQLite database + 8 seeded cases
bin/rails db:setup

# 3. Python engine
python3 -m venv risk_engine/.venv
risk_engine/.venv/bin/pip install -r risk_engine/requirements.txt

# 4. Start everything (Rails on :3000, Tailwind watcher, FastAPI on :5055)
bin/dev
```

Then open <http://localhost:3000>.

## How scoring works

1. Rails renders the dashboard and asks Python for the score of the selected case
   via `POST /score {"withdrawal_request_id": N}`.
2. Python opens the same SQLite file, loads client features + fired rules,
   runs the active scorer, writes a row to `risk_decisions`, returns JSON.
3. Browser polls `/cases/:id/score` every 5s (paused when the tab is hidden).
4. If Python is offline, Rails falls back to a built-in heuristic so the UI
   still works.

## Pluggable scorers

The Python engine ships with two implementations sharing one interface
(`risk_engine/scorers/base.py`):

- `RulesScorer` — weighted-rules + common-sense AML escalation.
- `MLScorer` — placeholder. Wire your trained model in `score()`,
  expose a `train` step, and switch at startup:

```bash
SCORER=ml risk_engine/.venv/bin/python risk_engine/server.py
```

Health check at <http://localhost:5055/health> shows which scorer is active.
OpenAPI docs at <http://localhost:5055/docs>.

## Adding a rule

Add an entry to `rules_seed` in `db/seeds.rb` and run `bin/rails db:seed`.
No code change needed in the Python engine — it loads weights from SQLite
per scoring call.

You can also edit weights / toggle rules live from the **Rules** page
(Compliance lead or Superadmin persona required).
