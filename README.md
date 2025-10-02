# acme-support-analytics-case-2025-10

![Python](https://img.shields.io/badge/Python-3.11%2B-blue)
![SQL](https://img.shields.io/badge/SQL-db%2Fanalytics-informational)
![dbt](https://img.shields.io/badge/dbt-optional-lightgrey)
![Status](https://img.shields.io/badge/status-WIP-yellow)
![License](https://img.shields.io/badge/license-TBD-lightgrey)

**Portfolio case** for a Data/Analytics Engineer: from raw support tickets to curated analytics (**SLA/FCR/trends**), AI ticket categorization **design** (prompt only—no LLM runtime), data quality checks, and dashboard recommendations.

> Everything is written in **English**, production‑minded, and organized so a reviewer can run it locally in minutes.

---

## 1) Case Brief
ACME launched a Support Dashboard. Ticket volume grew and it’s now harder to **measure SLA**, see **recurring issues**, and **prioritize fixes**.  
This repo delivers: a clean **data model**, **SLA/FCR** metrics (avg/median/**p95**), rolling trends, category mix, backlog views, and an **LLM prompt design** for auto‑classification (no LLM runtime required). It also proposes a **Support Health dashboard**.

## 2) Data
**Main table:** `tickets_raw`  
Fields:
- `ticket_id` (PK), `created_at`, `resolved_at`, `status` (`resolved|pending|escalated|closed_without_solution`),  
  `channel` (`whatsapp|email|in_app|chatbot`), `creator_id`, `tag` (`checkout|financial|engagement|others`),  
  `first_response_time` (minutes), `message_text` (AI‑generated summary).

**Optional enrichment:** `users_raw` (keyed by `creator_id`).

## 3) Objectives & PM Questions
1. Explore support data to understand what’s happening (volume, mix, channels, status, trends).  
2. Auto‑classify tickets into meaningful categories (there are missing categories).  
3. Define metrics to evaluate performance and **SLA**.  
4. Show how insights can improve product / reduce friction for creators.  
5. Share additional hypotheses worth testing.

## 4) Metric Dictionary (core)
| Metric | Definition | Formula / Notes |
|---|---|---|
| **Tickets/day** | Volume by day | `COUNT(DISTINCT ticket_id)` grouped by `DATE(created_at)` |
| **Tickets/week** | Volume by week | group by ISO week |
| **Category mix** | Share by effective category | `category_effective = COALESCE(tag, ai_category)` |
| **FRT_avg / median / p95** | First Response Time in minutes | `AVG`, `P50`, `P95` of `first_response_time` |
| **FRT_avg_7d** | Rolling 7‑day avg of FRT | rolling mean over daily FRT_avg |
| **Resolved** | Tickets with solution | `status='resolved' AND resolved_at IS NOT NULL` |
| **Resolution time (min)** | From create to resolve | `TIMESTAMPDIFF(min, created_at, resolved_at)` (resolved only) |
| **Backlog (open)** | Still open | `status IN ('pending','escalated')` |
| **Closed w/o solution** | Closed unresolved | `status='closed_without_solution'` |
| **FCR_strict (proxy)** | % resolved ≤ 60 min | `resolved AND resolution_time_minutes ≤ 60` |
| **FCR_lenient (proxy)** | % resolved ≤ 240 min | `resolved AND resolution_time_minutes ≤ 240` |
| **AI vs Tag accuracy** | Where tag exists | `% ai_category == tag` (monitor drift) |

> **Note:** FCR here is a **proxy** (time‑based). For “official” FCR we need #interactions or a first‑contact flag from the support platform.

## 5) Modeling Approach
**Grain:** per ticket; derived daily/weekly grains for trends.  
**Keys:** `ticket_id` (PK), `creator_id` for user enrichment.  
**Layers (dbt‑style):**
- `staging` → type casting, standardization, derived fields (`is_resolved`, `resolution_time_minutes`, `created_day`, `created_week`).  
- `intermediate` → classification (`ai_category`), `category_effective`, joins with users.  
- `marts` → daily/weekly aggregates, SLA tables, FCR, confusion matrix, executive outputs.

## 6) AI Classification (Design)
No LLM runtime needed; this is the **prompt spec** used in an enrichment step:

```
System: You are a support analyst. Classify the ticket into ONE category:
- checkout — purchase/checkout/payment flow issues
- financial — billing, refund, payout, chargeback
- engagement — reach, delivery, notifications, audience
- others — general

Rules: Use only the ticket content and available fields; output JSON.
User: Message="{message_text}" | Current tag="{tag}" | Channel="{channel}"

Output JSON: {"ai_category":"<checkout|financial|engagement|others>","rationale":"<max 2 sentences>"}
```

**Where:** batch job during ingestion/ELT to add `ai_category` + `rationale` to an enriched table.

## 7) Reproducibility & Data Quality
Minimum checks:
- **Uniqueness:** `ticket_id` unique  
- **Valid enums:** `status`, `channel` in allowed sets  
- **Resolved logic:** if `status='resolved'`, then `resolved_at` present and `resolved_at ≥ created_at`  
- **FRT range:** non‑negative and reasonable (e.g., ≤ 7 days in minutes)  
- **Joinability:** `%` of tickets with matching `creator_id` in `users_raw` (if present)

## 8) Project Structure (planned)
```
.
├─ data/                          # raw CSVs for local runs
│  ├─ tickets_raw.csv
│  └─ users_raw.csv
├─ models/
│  ├─ staging/                    # stg_tickets.sql / stg_users.sql
│  ├─ intermediate/               # int_tickets_classified.sql
│  └─ marts/                      # fct_sla_daily.sql, fct_tickets_by_category_daily.sql, fct_fcr_daily.sql, ...
├─ analyses/                      # exploratory SQL/notes
├─ reports/                       # executive report, dashboard notes
├─ scripts/                       # optional Python CLI to run transforms
├─ tests/                         # data quality tests
├─ README.md
└─ LICENSE (optional)
```

## 9) Requirements
- **Python 3.11+**  
- Optional: **dbt Core** + **DuckDB** for a dbt‑first variant

Install (Python only):
```bash
python -m venv .venv
# Windows: .venv\Scriptsctivate ; macOS/Linux:
source .venv/bin/activate
pip install -r requirements.txt
```

## 10) Running locally (Python path)
> Scripts will land in `scripts/` as we progress (step‑by‑step). Example CLI to come:
```bash
python scripts/build_metrics.py   --tickets data/tickets_raw.csv   --users data/users_raw.csv   --out data/outputs
```
Outputs (CSV) will feed a BI dashboard (Looker Studio / Power BI).

## 11) Running locally (dbt + DuckDB — optional)
```bash
pip install dbt-core dbt-duckdb
# configure ~/.dbt/profiles.yml (a sample will be provided)
dbt seed
dbt run
dbt test
dbt docs generate && dbt docs serve
```

## 12) Dashboard Blueprint
**Executive:** Total Tickets, Resolved, Backlog, Closed w/o Solution, FRT avg/median/p95, FCR (strict/lenient).  
**Trends:** Tickets/day (7D MA), FRT/day (7D MA).  
**Categories:** Stacked bars by day/week.  
**Channels:** FRT and resolution rate by channel.  
**Backlog:** Open by status, average age and p95.  
**Quality:** AI vs Tag accuracy + Confusion Matrix.  
**Outliers:** slowest first response, with message summary.

## 13) Roadmap / Next Steps
- [ ] Stage raw data (staging models)  
- [ ] Add AI baseline classification + effective category  
- [ ] Build marts: `tickets_by_category_daily`, `sla_daily`, `fcr_daily` (+ weekly versions)  
- [ ] Implement data quality tests  
- [ ] Export dashboard‑ready CSVs / tables  
- [ ] Write executive report and product recommendations  

---

### Credits
Designed and implemented by **Weslei Camargo** — Data/AI Engineer.