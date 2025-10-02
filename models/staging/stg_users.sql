-- stg_users.sql
-- Purpose: standardize users for joins by creator_id (optional).
WITH src AS (
  SELECT
    CAST(creator_id AS VARCHAR) AS creator_id,
    *
  FROM {{ source('raw', 'users_raw') }}
)
SELECT * FROM src;
