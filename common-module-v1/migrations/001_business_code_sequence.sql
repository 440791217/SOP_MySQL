-- DEPRECATED: historical server-counter design. DO NOT EXECUTE for the current app.
-- Client-generated business codes no longer require this table. Do not drop an existing table.
-- MySQL 8.4 / InnoDB. Select sop_dev explicitly before executing this whole file.
-- Additive migration; never rewrites existing business codes or recreates business tables.
SET NAMES utf8mb4;
CREATE TABLE IF NOT EXISTS sop_business_code_sequence (
  business_type VARCHAR(3) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT 'PRJ/SUB/SOP',
  business_date DATE NOT NULL COMMENT 'Asia/Shanghai business date',
  `last_value` BIGINT NOT NULL DEFAULT 0 COMMENT 'Last allocated value; retain permanently',
  PRIMARY KEY (business_type,business_date),
  CONSTRAINT ck_business_code_type CHECK (business_type IN ('PRJ','SUB','SOP')),
  CONSTRAINT ck_business_code_value CHECK (`last_value`>=0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Daily business code counters';
