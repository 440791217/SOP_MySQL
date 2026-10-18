-- SOP module design v1 / MySQL 8.4 / InnoDB.
-- Select sop_dev explicitly. Run ONCE as a whole file, after user + project schema
-- and project migrations 001 and 002. Adds seven NEW tables; no seed data.
-- Do not rerun existing schemas. MySQL DDL is not an atomic transaction.
-- No application support is implemented by this script alone.
SET NAMES utf8mb4;
SET SESSION time_zone = '+00:00';

CREATE TABLE sop_document (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  name VARCHAR(128) NOT NULL,
  managing_project_id BIGINT NOT NULL,
  owner_user_id BIGINT NOT NULL,
  deleted_at DATETIME(3) NULL,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  version INT NOT NULL DEFAULT 0,
  UNIQUE KEY uk_sop_document_code (code),
  KEY ix_sop_document_project (managing_project_id,deleted_at,id),
  KEY ix_sop_document_owner (owner_user_id),
  CONSTRAINT fk_sop_document_project FOREIGN KEY (managing_project_id) REFERENCES sop_project(id),
  CONSTRAINT fk_sop_document_owner FOREIGN KEY (managing_project_id,owner_user_id) REFERENCES sop_project_member(project_id,user_id),
  CONSTRAINT fk_sop_document_creator FOREIGN KEY (created_by) REFERENCES sys_user(id),
  CONSTRAINT fk_sop_document_updater FOREIGN KEY (updated_by) REFERENCES sys_user(id),
  CONSTRAINT ck_sop_document_code CHECK (REGEXP_LIKE(code,'^[A-Z0-9][A-Z0-9_-]{0,63}$','c')),
  CONSTRAINT ck_sop_document_name CHECK (CHAR_LENGTH(TRIM(name))>0),
  CONSTRAINT ck_sop_document_version CHECK (version>=0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE sop_revision (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  sop_id BIGINT NOT NULL,
  revision_no INT NOT NULL,
  title VARCHAR(128) NOT NULL,
  applicable_scope VARCHAR(1000) NULL,
  purpose TEXT NULL,
  precautions TEXT NULL,
  revision_note VARCHAR(1000) NULL,
  status TINYINT NOT NULL DEFAULT 0 COMMENT '0 draft, 1 published, 2 retired',
  published_by BIGINT NULL,
  published_at DATETIME(3) NULL,
  retired_by BIGINT NULL,
  retired_at DATETIME(3) NULL,
  deleted_at DATETIME(3) NULL COMMENT 'Only unused drafts may be discarded',
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  version INT NOT NULL DEFAULT 0,
  draft_slot BIGINT GENERATED ALWAYS AS (CASE WHEN status=0 AND deleted_at IS NULL THEN sop_id ELSE NULL END) STORED,
  UNIQUE KEY uk_sop_revision_number (sop_id,revision_no),
  UNIQUE KEY uk_sop_revision_identity (sop_id,id),
  UNIQUE KEY uk_sop_revision_draft (draft_slot),
  KEY ix_sop_revision_list (sop_id,status,deleted_at,revision_no),
  CONSTRAINT fk_sop_revision_document FOREIGN KEY (sop_id) REFERENCES sop_document(id),
  CONSTRAINT fk_sop_revision_creator FOREIGN KEY (created_by) REFERENCES sys_user(id),
  CONSTRAINT fk_sop_revision_updater FOREIGN KEY (updated_by) REFERENCES sys_user(id),
  CONSTRAINT fk_sop_revision_publisher FOREIGN KEY (published_by) REFERENCES sys_user(id),
  CONSTRAINT fk_sop_revision_retirer FOREIGN KEY (retired_by) REFERENCES sys_user(id),
  CONSTRAINT ck_sop_revision_number CHECK (revision_no>0 AND version>=0),
  CONSTRAINT ck_sop_revision_title CHECK (CHAR_LENGTH(TRIM(title))>0),
  CONSTRAINT ck_sop_revision_state CHECK (
    (status=0 AND published_by IS NULL AND published_at IS NULL AND retired_by IS NULL AND retired_at IS NULL)
    OR (status=1 AND published_by IS NOT NULL AND published_at IS NOT NULL AND retired_by IS NULL AND retired_at IS NULL AND deleted_at IS NULL)
    OR (status=2 AND published_by IS NOT NULL AND published_at IS NOT NULL AND retired_by IS NOT NULL AND retired_at IS NOT NULL AND deleted_at IS NULL)
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE sop_step (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  revision_id BIGINT NOT NULL,
  sort_order INT NOT NULL,
  title VARCHAR(128) NOT NULL,
  instruction TEXT NOT NULL,
  precautions TEXT NULL,
  check_requirements TEXT NULL,
  expected_duration_seconds DECIMAL(10,2) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  version INT NOT NULL DEFAULT 0,
  KEY ix_sop_step_order (revision_id,sort_order,id),
  CONSTRAINT fk_sop_step_revision FOREIGN KEY (revision_id) REFERENCES sop_revision(id),
  CONSTRAINT ck_sop_step_text CHECK (CHAR_LENGTH(TRIM(title))>0 AND CHAR_LENGTH(TRIM(instruction))>0),
  CONSTRAINT ck_sop_step_order CHECK (sort_order>0 AND version>=0),
  CONSTRAINT ck_sop_step_duration CHECK (expected_duration_seconds IS NULL OR expected_duration_seconds>=0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE sop_file (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  storage_key VARCHAR(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  original_name VARCHAR(255) NOT NULL,
  mime_type VARCHAR(100) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  file_kind TINYINT NOT NULL COMMENT '0 image, 1 video, 2 PDF',
  byte_size BIGINT NOT NULL,
  sha256 BINARY(32) NOT NULL,
  uploaded_by BIGINT NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL,
  UNIQUE KEY uk_sop_file_storage (storage_key),
  KEY ix_sop_file_upload (uploaded_by,created_at),
  CONSTRAINT fk_sop_file_uploader FOREIGN KEY (uploaded_by) REFERENCES sys_user(id),
  CONSTRAINT ck_sop_file_kind CHECK (file_kind IN (0,1,2)),
  CONSTRAINT ck_sop_file_size CHECK (byte_size>0),
  CONSTRAINT ck_sop_file_name CHECK (CHAR_LENGTH(TRIM(original_name))>0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE sop_step_attachment (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  step_id BIGINT NOT NULL,
  file_id BIGINT NOT NULL,
  sort_order INT NOT NULL DEFAULT 1,
  caption VARCHAR(500) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE KEY uk_sop_attachment_file (step_id,file_id),
  KEY ix_sop_attachment_order (step_id,sort_order,id),
  KEY ix_sop_attachment_reference (file_id),
  CONSTRAINT fk_sop_attachment_step FOREIGN KEY (step_id) REFERENCES sop_step(id),
  CONSTRAINT fk_sop_attachment_file FOREIGN KEY (file_id) REFERENCES sop_file(id),
  CONSTRAINT ck_sop_attachment_order CHECK (sort_order>0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE sop_project_binding (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  project_id BIGINT NOT NULL,
  sop_id BIGINT NOT NULL,
  revision_id BIGINT NOT NULL,
  sort_order INT NOT NULL DEFAULT 1,
  status TINYINT NOT NULL DEFAULT 1 COMMENT '1 enabled, 0 unbound; keep last selected revision',
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  version INT NOT NULL DEFAULT 0,
  UNIQUE KEY uk_sop_project_binding (project_id,sop_id),
  KEY ix_sop_project_binding_order (project_id,status,sort_order,id),
  KEY ix_sop_project_binding_revision (sop_id,revision_id),
  CONSTRAINT fk_sop_project_binding_project FOREIGN KEY (project_id) REFERENCES sop_project(id),
  CONSTRAINT fk_sop_project_binding_revision FOREIGN KEY (sop_id,revision_id) REFERENCES sop_revision(sop_id,id),
  CONSTRAINT fk_sop_project_binding_creator FOREIGN KEY (created_by) REFERENCES sys_user(id),
  CONSTRAINT fk_sop_project_binding_updater FOREIGN KEY (updated_by) REFERENCES sys_user(id),
  CONSTRAINT ck_sop_project_binding_values CHECK (status IN (0,1) AND sort_order>0 AND version>=0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE sop_subproject_binding (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  subproject_id BIGINT NOT NULL,
  sop_id BIGINT NOT NULL,
  revision_id BIGINT NOT NULL,
  sort_order INT NOT NULL DEFAULT 1,
  status TINYINT NOT NULL DEFAULT 1 COMMENT '1 enabled, 0 unbound; keep last selected revision',
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  version INT NOT NULL DEFAULT 0,
  UNIQUE KEY uk_sop_subproject_binding (subproject_id,sop_id),
  KEY ix_sop_subproject_binding_order (subproject_id,status,sort_order,id),
  KEY ix_sop_subproject_binding_revision (sop_id,revision_id),
  CONSTRAINT fk_sop_subproject_binding_sub FOREIGN KEY (subproject_id) REFERENCES sop_subproject(id),
  CONSTRAINT fk_sop_subproject_binding_revision FOREIGN KEY (sop_id,revision_id) REFERENCES sop_revision(sop_id,id),
  CONSTRAINT fk_sop_subproject_binding_creator FOREIGN KEY (created_by) REFERENCES sys_user(id),
  CONSTRAINT fk_sop_subproject_binding_updater FOREIGN KEY (updated_by) REFERENCES sys_user(id),
  CONSTRAINT ck_sop_subproject_binding_values CHECK (status IN (0,1) AND sort_order>0 AND version>=0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;
