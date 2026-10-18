-- MySQL 8.4. Select sop_dev; run ONCE after 001_archive_restore.sql.
-- Retains member rows and historical owner foreign keys. DDL is not atomic.
ALTER TABLE sop_project_member
  ADD COLUMN member_status TINYINT NOT NULL DEFAULT 1 COMMENT '1 active, 0 removed',
  ADD COLUMN removed_at DATETIME(3) NULL,
  ADD CONSTRAINT ck_project_member_status CHECK (member_status IN (0,1));

CREATE TABLE sop_project_activity (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  project_id BIGINT NOT NULL,
  subproject_id BIGINT NULL,
  action VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  actor_user_id BIGINT NOT NULL,
  actor_name VARCHAR(64) NOT NULL,
  target_user_id BIGINT NOT NULL,
  target_name VARCHAR(64) NOT NULL,
  before_value VARCHAR(255) NULL,
  after_value VARCHAR(255) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  KEY ix_project_activity (project_id,id),
  CONSTRAINT fk_activity_project FOREIGN KEY (project_id) REFERENCES sop_project(id),
  CONSTRAINT fk_activity_subproject FOREIGN KEY (subproject_id) REFERENCES sop_subproject(id),
  CONSTRAINT fk_activity_actor FOREIGN KEY (actor_user_id) REFERENCES sys_user(id),
  CONSTRAINT fk_activity_target FOREIGN KEY (target_user_id) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;
