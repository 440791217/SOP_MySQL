-- MySQL 8.4; select sop_dev first. Run ONCE after project-module-v1/schema.sql.
-- Existing tables/data are retained. DDL is not an atomic transaction.
ALTER TABLE sop_project
  ADD COLUMN archived_from_status TINYINT NULL COMMENT 'State before archival; 0 for legacy archives',
  ADD CONSTRAINT ck_project_archive_state CHECK (archived_from_status IS NULL OR archived_from_status IN (0,1,2));
ALTER TABLE sop_subproject
  ADD COLUMN archived_from_status TINYINT NULL COMMENT 'State before archival; 0 for legacy archives',
  ADD COLUMN archived_with_project TINYINT NOT NULL DEFAULT 0 COMMENT '1 only when archived by current parent archive operation',
  ADD CONSTRAINT ck_subproject_archive_state CHECK (archived_from_status IS NULL OR archived_from_status IN (0,1,2)),
  ADD CONSTRAINT ck_subproject_archive_parent CHECK (archived_with_project IN (0,1));
-- Older archives have no reliable state history; never infer that they were in progress.
UPDATE sop_project SET archived_from_status=0 WHERE status=3;
UPDATE sop_subproject SET archived_from_status=0 WHERE status=3;
