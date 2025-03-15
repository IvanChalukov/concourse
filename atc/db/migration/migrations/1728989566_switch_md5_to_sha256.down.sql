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


-- CONSTRAINTs
ALTER TABLE resource_config_versions
  DROP CONSTRAINT IF EXISTS "resource_config_scope_id_and_version_sha256_unique",
  ADD CONSTRAINT "resource_config_scope_id_and_version_md5_unique" UNIQUE ("resource_config_scope_id", "version_md5");


-- UNIQUE INDEXs
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

-- Convert the latest resource config versions to with the md5 hash 
WITH latest_versions AS (
    SELECT DISTINCT ON (resource_config_scope_id) 
        id, version, version_md5 AS old_version_md5
    FROM resource_config_versions
    ORDER BY resource_config_scope_id, check_order DESC
),
json_string_cte AS (
    SELECT 
        lv.id,
        lv.old_version_md5,
        '{' || string_agg('"' || kv.key || '":"' || kv.value || '"', ',' ORDER BY kv.key) || '}' AS json_string
    FROM latest_versions lv
    JOIN jsonb_each_text(lv.version::jsonb) AS kv ON true
    GROUP BY lv.id, lv.old_version_md5
),
hashed_json_string_cte AS (
    SELECT 
        json_string_cte.id,
        json_string_cte.old_version_md5,
        md5(json_string_cte.json_string) AS new_version_md5
    FROM json_string_cte
),
update_resource_versions AS (
    UPDATE resource_config_versions rcv
    SET version_md5 = hjs.new_version_md5
    FROM hashed_json_string_cte hjs
    WHERE rcv.id = hjs.id
)
UPDATE resource_disabled_versions rdv
SET version_md5 = hjs.new_version_md5
FROM hashed_json_string_cte hjs
WHERE rdv.version_md5 = hjs.old_version_md5;
