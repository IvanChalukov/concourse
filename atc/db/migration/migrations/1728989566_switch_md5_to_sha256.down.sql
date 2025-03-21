-- Step 1: Revert column renames from version_sha256 back to version_md5
ALTER TABLE resource_config_versions
RENAME COLUMN version_sha256 TO version_md5;

ALTER TABLE build_resource_config_version_inputs
RENAME COLUMN version_sha256 TO version_md5;

ALTER TABLE build_resource_config_version_outputs
RENAME COLUMN version_sha256 TO version_md5;

ALTER TABLE next_build_inputs
RENAME COLUMN version_sha256 TO version_md5;

ALTER TABLE resource_caches
RENAME COLUMN version_sha256 TO version_md5;

ALTER TABLE resource_disabled_versions
RENAME COLUMN version_sha256 TO version_md5;

-- Step 2: Revert all rows to their original md5 values
WITH json_string_cte AS (
    SELECT 
        rcv.id,
        rcv.version_md5 AS old_version_md5,
        '{' || string_agg('"' || kv.key || '":"' || kv.value || '"', ',' ORDER BY kv.key) || '}' AS json_string
    FROM resource_config_versions rcv
    JOIN jsonb_each_text(rcv.version::jsonb) AS kv ON true
    GROUP BY rcv.id, rcv.version_md5
),
hashed_json_string_cte AS (
    SELECT 
        json_string_cte.id,
        json_string_cte.old_version_md5,
        encode(digest(json_string_cte.json_string, 'md5'), 'hex') AS new_version_md5
    FROM json_string_cte
),
update_resource_versions AS (
    UPDATE resource_config_versions rcv
    SET version_md5 = hjs.new_version_md5
    FROM hashed_json_string_cte hjs
    WHERE rcv.id = hjs.id
),
update_resource_disabled_versions AS (
    UPDATE resource_disabled_versions rdv
    SET version_md5 = hjs.new_version_md5
    FROM hashed_json_string_cte hjs
    WHERE rdv.version_md5 = hjs.old_version_md5
),
update_build_resource_config_version_inputs AS (
    UPDATE build_resource_config_version_inputs bri
    SET version_md5 = hjs.new_version_md5
    FROM hashed_json_string_cte hjs
    WHERE bri.version_md5 = hjs.old_version_md5
),
update_build_resource_config_version_outputs AS (
    UPDATE build_resource_config_version_outputs bro
    SET version_md5 = hjs.new_version_md5
    FROM hashed_json_string_cte hjs
    WHERE bro.version_md5 = hjs.old_version_md5
),
update_resource_caches AS (
    UPDATE resource_caches rc
    SET version_md5 = hjs.new_version_md5
    FROM hashed_json_string_cte hjs
    WHERE rc.version_md5 = hjs.old_version_md5
)

UPDATE next_build_inputs nbi
SET version_md5 = hjs.new_version_md5
FROM hashed_json_string_cte hjs
WHERE nbi.version_md5 = hjs.old_version_md5;

-- Step 3: Revert constraints
ALTER TABLE resource_config_versions
  DROP CONSTRAINT IF EXISTS "resource_config_scope_id_and_version_unique",
  ADD CONSTRAINT "resource_config_scope_id_and_version_md5_unique" UNIQUE ("resource_config_scope_id", "version_md5");

-- Step 4: Revert indexes
DROP INDEX IF EXISTS resource_disabled_versions_resource_id_version_sha256_uniq;
CREATE UNIQUE INDEX resource_disabled_versions_resource_id_version_md5_uniq
ON resource_disabled_versions (resource_id, version_md5);

DROP INDEX IF EXISTS resource_caches_resource_config_id_version_sha256_params_hash_uniq;
CREATE UNIQUE INDEX resource_caches_resource_config_id_version_md5_params_hash_uniq
ON resource_caches (resource_config_id, version_md5, params_hash);

DROP INDEX IF EXISTS build_inputs_resource_versions_idx;
CREATE INDEX build_inputs_resource_versions_idx ON build_resource_config_version_inputs (resource_id, version_md5);

DROP INDEX IF EXISTS build_resource_config_version_inputs_uniq;
CREATE UNIQUE INDEX build_resource_config_version_inputs_uniq
ON build_resource_config_version_inputs (build_id, resource_id, version_md5, name);

DROP INDEX IF EXISTS build_resource_config_version_outputs_uniq;
CREATE UNIQUE INDEX build_resource_config_version_outputs_uniq
ON build_resource_config_version_outputs (build_id, resource_id, version_md5, name);