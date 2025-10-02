-- fct_tickets_by_category_daily.sql
WITH src AS (
  SELECT created_day, category_effective, ticket_id
  FROM {{ ref('int_tickets_classified') }}
)
SELECT
  created_day,
  category_effective AS category,
  COUNT(DISTINCT ticket_id) AS tickets_count
FROM src
GROUP BY 1, 2
ORDER BY 1, 2;
