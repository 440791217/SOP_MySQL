-- Project module v1, MySQL 8.4 / InnoDB.
-- Select sop_dev explicitly in your SQL client before running this whole file.
-- Requires existing user-module-v1 sys_user. Adds only three NEW tables.
-- Run once; no DROP, no existing-table modification, no sample data.
-- MySQL DDL is not an all-or-nothing transaction: inspect errors before retrying.
SET NAMES utf8mb4;
SET SESSION time_zone = '+00:00';

CREATE TABLE sop_project (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  name VARCHAR(128) NOT NULL,
  customer_name VARCHAR(128) NULL,
  owner_user_id BIGINT NOT NULL,
  description TEXT NULL,
  status TINYINT NOT NULL DEFAULT 0 COMMENT '0 pending, 1 in progress, 2 completed, 3 archived',
  deleted_at DATETIME(3) NULL,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  version INT NOT NULL DEFAULT 0,
  UNIQUE KEY uk_project_code (code),
  KEY ix_project_list (deleted_at, status, id),
  KEY ix_project_owner (owner_user_id, deleted_at, id),
  CONSTRAINT fk_project_owner FOREIGN KEY (owner_user_id) REFERENCES sys_user(id),
  CONSTRAINT fk_project_creator FOREIGN KEY (created_by) REFERENCES sys_user(id),
  CONSTRAINT fk_project_updater FOREIGN KEY (updated_by) REFERENCES sys_user(id),
  CONSTRAINT ck_project_code CHECK (REGEXP_LIKE(code, '^[A-Z0-9][A-Z0-9_-]{0,63}$', 'c')),
  CONSTRAINT ck_project_name CHECK (CHAR_LENGTH(TRIM(name)) > 0),
  CONSTRAINT ck_project_customer CHECK (customer_name IS NULL OR CHAR_LENGTH(TRIM(customer_name)) > 0),
  CONSTRAINT ck_project_status CHECK (status IN (0,1,2,3)),
  CONSTRAINT ck_project_version CHECK (version >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE sop_project_member (
  project_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  access_level TINYINT NOT NULL DEFAULT 0 COMMENT '0 viewer, 1 editor; owner is defined by project.owner_user_id',
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  version INT NOT NULL DEFAULT 0,
  PRIMARY KEY (project_id, user_id),
  KEY ix_project_member_user (user_id, project_id),
  CONSTRAINT fk_project_member_project FOREIGN KEY (project_id) REFERENCES sop_project(id),
  CONSTRAINT fk_project_member_user FOREIGN KEY (user_id) REFERENCES sys_user(id),
  CONSTRAINT fk_project_member_creator FOREIGN KEY (created_by) REFERENCES sys_user(id),
  CONSTRAINT fk_project_member_updater FOREIGN KEY (updated_by) REFERENCES sys_user(id),
  CONSTRAINT ck_project_member_access CHECK (access_level IN (0,1)),
  CONSTRAINT ck_project_member_version CHECK (version >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE sop_subproject (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  project_id BIGINT NOT NULL,
  code VARCHAR(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  name VARCHAR(128) NOT NULL,
  owner_user_id BIGINT NOT NULL,
  description TEXT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  status TINYINT NOT NULL DEFAULT 0 COMMENT '0 pending, 1 in progress, 2 completed, 3 archived',
  deleted_at DATETIME(3) NULL,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  version INT NOT NULL DEFAULT 0,
  UNIQUE KEY uk_subproject_code (project_id, code),
  KEY ix_subproject_list (project_id, deleted_at, sort_order, id),
  KEY ix_subproject_owner (owner_user_id),
  CONSTRAINT fk_subproject_project FOREIGN KEY (project_id) REFERENCES sop_project(id),
  CONSTRAINT fk_subproject_owner_member FOREIGN KEY (project_id, owner_user_id)
    REFERENCES sop_project_member(project_id, user_id),
  CONSTRAINT fk_subproject_creator FOREIGN KEY (created_by) REFERENCES sys_user(id),
  CONSTRAINT fk_subproject_updater FOREIGN KEY (updated_by) REFERENCES sys_user(id),
  CONSTRAINT ck_subproject_code CHECK (REGEXP_LIKE(code, '^[A-Z0-9][A-Z0-9_-]{0,63}$', 'c')),
  CONSTRAINT ck_subproject_name CHECK (CHAR_LENGTH(TRIM(name)) > 0),
  CONSTRAINT ck_subproject_sort CHECK (sort_order >= 0),
  CONSTRAINT ck_subproject_status CHECK (status IN (0,1,2,3)),
  CONSTRAINT ck_subproject_version CHECK (version >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;
