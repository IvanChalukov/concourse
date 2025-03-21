-- Ensure the pgcrypto extension is available for hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Rename columns from version_md5 to version_sha256
ALTER TABLE resource_config_versions
RENAME COLUMN version_md5 TO version_sha256;

ALTER TABLE build_resource_config_version_inputs
RENAME COLUMN version_md5 TO version_sha256;

ALTER TABLE build_resource_config_version_outputs
RENAME COLUMN version_md5 TO version_sha256;

ALTER TABLE next_build_inputs
RENAME COLUMN version_md5 TO version_sha256;

ALTER TABLE resource_caches
RENAME COLUMN version_md5 TO version_sha256;

ALTER TABLE resource_disabled_versions
RENAME COLUMN version_md5 TO version_sha256;

WITH json_string_cte AS (
    SELECT 
        rcv.id,
        rcv.version_sha256 AS old_version_sha256,
        '{' || string_agg('"' || kv.key || '":"' || kv.value || '"', ',' ORDER BY kv.key) || '}' AS json_string
    FROM resource_config_versions rcv
    JOIN jsonb_each_text(rcv.version::jsonb) AS kv ON true
    GROUP BY rcv.id, rcv.version_sha256
),
hashed_json_string_cte AS (
    SELECT 
        json_string_cte.id,
        json_string_cte.old_version_sha256,
        encode(digest(json_string_cte.json_string, 'sha256'), 'hex') AS new_version_sha256
    FROM json_string_cte
),
update_resource_versions AS (
    UPDATE resource_config_versions rcv
    SET version_sha256 = hjs.new_version_sha256
    FROM hashed_json_string_cte hjs
    WHERE rcv.id = hjs.id
),
update_resource_disabled_versions AS (
    UPDATE resource_disabled_versions rdv
    SET version_sha256 = hjs.new_version_sha256
    FROM hashed_json_string_cte hjs
    WHERE rdv.version_sha256 = hjs.old_version_sha256
),
update_build_resource_config_version_inputs AS (
    UPDATE build_resource_config_version_inputs bri
    SET version_sha256 = hjs.new_version_sha256
    FROM hashed_json_string_cte hjs
    WHERE bri.version_sha256 = hjs.old_version_sha256
),
update_build_resource_config_version_outputs AS (
    UPDATE build_resource_config_version_outputs bro
    SET version_sha256 = hjs.new_version_sha256
    FROM hashed_json_string_cte hjs
    WHERE bro.version_sha256 = hjs.old_version_sha256
),
update_resource_caches AS (
    UPDATE resource_caches rc
    SET version_sha256 = hjs.new_version_sha256
    FROM hashed_json_string_cte hjs
    WHERE rc.version_sha256 = hjs.old_version_sha256
)

UPDATE next_build_inputs nbi
SET version_sha256 = hjs.new_version_sha256
FROM hashed_json_string_cte hjs
WHERE nbi.version_sha256 = hjs.old_version_sha256;


-- Update constraints
ALTER TABLE resource_config_versions
  DROP CONSTRAINT IF EXISTS "resource_config_scope_id_and_version_md5_unique",
  ADD CONSTRAINT "resource_config_scope_id_and_version_unique" UNIQUE ("resource_config_scope_id", "version_sha256");

-- Update indexes
DROP INDEX IF EXISTS resource_disabled_versions_resource_id_version_md5_uniq;
CREATE UNIQUE INDEX resource_disabled_versions_resource_id_version_sha256_uniq
ON resource_disabled_versions (resource_id, version_sha256);

DROP INDEX IF EXISTS resource_caches_resource_config_id_version_md5_params_hash_uniq;
CREATE UNIQUE INDEX resource_caches_resource_config_id_version_sha256_params_hash_uniq
ON resource_caches (resource_config_id, version_sha256, params_hash);

DROP INDEX IF EXISTS build_inputs_resource_versions_idx;
CREATE INDEX build_inputs_resource_versions_idx ON build_resource_config_version_inputs (resource_id, version_sha256);

DROP INDEX IF EXISTS build_resource_config_version_inputs_uniq;
CREATE UNIQUE INDEX build_resource_config_version_inputs_uniq
ON build_resource_config_version_inputs (build_id, resource_id, version_sha256, name);

DROP INDEX IF EXISTS build_resource_config_version_outputs_uniq;
CREATE UNIQUE INDEX build_resource_config_version_outputs_uniq
ON build_resource_config_version_outputs (build_id, resource_id, version_sha256, name);
