-- int_tickets_classified.sql
-- Purpose: add AI classification (design) and compute effective category.
WITH base AS (
  SELECT * FROM {{ ref('stg_tickets') }}
),
ai_enriched AS (
  -- NOTE: Replace this with your AI-enriched table when available.
  -- For now, keep NULL and fall back to tag.
  SELECT
    b.*,
    NULL AS ai_category -- to be populated by enrichment job
  FROM base b
)
SELECT
  *,
  COALESCE(ai_category, tag, 'others') AS category_effective
FROM ai_enriched;
