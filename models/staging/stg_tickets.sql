-- stg_tickets.sql
-- Purpose: standardize raw ticket fields and derive helper columns.
-- Grain: 1 row per ticket_id.
-- Replace the FROM clause with your raw source table (or external stage).
WITH src AS (
  SELECT
    ticket_id,
    CAST(created_at AS TIMESTAMP) AS created_at,
    CAST(resolved_at AS TIMESTAMP) AS resolved_at,
    LOWER(TRIM(status)) AS status,
    LOWER(TRIM(channel)) AS channel,
    CAST(creator_id AS VARCHAR) AS creator_id,
    LOWER(NULLIF(TRIM(tag), '')) AS tag,
    CAST(first_response_time AS DOUBLE) AS first_response_time,
    message_text
  FROM {{ source('raw', 'tickets_raw') }}
)
SELECT
  *,
  (CASE WHEN status = 'resolved' AND resolved_at IS NOT NULL THEN 1 ELSE 0 END) AS is_resolved,
  DATE_TRUNC('day', created_at) AS created_day,
  DATE_TRUNC('week', created_at) AS created_week,
  (CASE WHEN status = 'resolved' AND resolved_at IS NOT NULL
        THEN EXTRACT(EPOCH FROM (resolved_at - created_at))/60.0
        ELSE NULL END) AS resolution_time_minutes
FROM src;
