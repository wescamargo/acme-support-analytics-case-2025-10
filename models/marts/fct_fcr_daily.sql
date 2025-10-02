-- fct_fcr_daily.sql
-- Proxy: strict <= 60 min ; lenient <= 240 min
WITH base AS (
  SELECT
    created_day,
    is_resolved,
    resolution_time_minutes
  FROM {{ ref('stg_tickets') }}
),
agg AS (
  SELECT
    created_day,
    SUM(CASE WHEN is_resolved = 1 THEN 1 ELSE 0 END) AS resolved,
    SUM(CASE WHEN is_resolved = 1 AND resolution_time_minutes <= 60  THEN 1 ELSE 0 END) AS fcr_strict_sum,
    SUM(CASE WHEN is_resolved = 1 AND resolution_time_minutes <= 240 THEN 1 ELSE 0 END) AS fcr_lenient_sum
  FROM base
  GROUP BY 1
)
SELECT
  created_day,
  resolved,
  fcr_strict_sum,
  fcr_lenient_sum,
  CASE WHEN resolved > 0 THEN fcr_strict_sum  / resolved::DOUBLE ELSE NULL END AS fcr_strict_rate,
  CASE WHEN resolved > 0 THEN fcr_lenient_sum / resolved::DOUBLE ELSE NULL END AS fcr_lenient_rate
FROM agg
ORDER BY 1;
