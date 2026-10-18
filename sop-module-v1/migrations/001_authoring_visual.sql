-- MySQL 8.4. Select sop_dev; run this whole migration ONCE after the existing seven SOP tables.
-- No business data is reset. DDL is not an all-or-nothing transaction: inspect partial failures before retrying.
SET NAMES utf8mb4;
ALTER TABLE sop_step
  ADD COLUMN detection_wait_seconds DECIMAL(5,1) NOT NULL DEFAULT 0,
  ADD COLUMN voice_enabled TINYINT NOT NULL DEFAULT 0,
  ADD COLUMN voice_text VARCHAR(1000) NULL,
  ADD CONSTRAINT ck_sop_step_wait CHECK (detection_wait_seconds BETWEEN 0 AND 3600),
  ADD CONSTRAINT ck_sop_step_voice CHECK (voice_enabled IN (0,1));
CREATE TABLE sop_step_visual (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  attachment_id BIGINT NOT NULL,
  source_type VARCHAR(10) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'upload',
  image_width INT NOT NULL,
  image_height INT NOT NULL,
  schema_version INT NOT NULL DEFAULT 1,
  guide_items JSON NOT NULL,
  detection_regions JSON NOT NULL,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  UNIQUE KEY uk_sop_visual_attachment (attachment_id),
  CONSTRAINT fk_sop_visual_attachment FOREIGN KEY (attachment_id) REFERENCES sop_step_attachment(id) ON DELETE CASCADE,
  CONSTRAINT fk_sop_visual_creator FOREIGN KEY (created_by) REFERENCES sys_user(id),
  CONSTRAINT fk_sop_visual_updater FOREIGN KEY (updated_by) REFERENCES sys_user(id),
  CONSTRAINT ck_sop_visual_source CHECK (source_type='upload'),
  CONSTRAINT ck_sop_visual_dimensions CHECK (image_width BETWEEN 1 AND 8192 AND image_height BETWEEN 1 AND 8192 AND image_width*image_height<=16000000),
  CONSTRAINT ck_sop_visual_schema CHECK (schema_version=1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;
