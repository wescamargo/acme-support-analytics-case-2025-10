-- fct_sla_daily.sql
WITH src AS (
  SELECT created_day, first_response_time
  FROM {{ ref('stg_tickets') }}
)
SELECT
  created_day,
  AVG(first_response_time) AS avg_first_response,
  APPROX_PERCENTILE(first_response_time, 0.5) AS median_first_response,
  APPROX_PERCENTILE(first_response_time, 0.95) AS p95_first_response
FROM src
GROUP BY 1
ORDER BY 1;
