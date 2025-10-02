-- fct_confusion_matrix.sql
-- Cross-tab of tag vs ai_category (where tag is present)
WITH base AS (
  SELECT tag, ai_category
  FROM {{ ref('int_tickets_classified') }}
  WHERE tag IS NOT NULL
)
SELECT
  tag,
  ai_category,
  COUNT(*) AS n
FROM base
GROUP BY 1, 2
ORDER BY 1, 2;
