-- MySQL 8.4. Select sop_dev. Execute ONCE AFTER resource-module-v1/schema.sql.
-- No DROP, no fabricated station IP. Existing location text is preserved and migrated.
-- DDL is not atomic; inspect partial completion before any retry.
SET NAMES utf8mb4;
SET SESSION time_zone = '+00:00';
CREATE TABLE sop_location (
 id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
 code VARCHAR(64) NOT NULL UNIQUE,
 name VARCHAR(255) NOT NULL,
 status TINYINT NOT NULL DEFAULT 0 CHECK(status IN(0,1,2)),
 description VARCHAR(2000),
 created_by BIGINT NOT NULL, updated_by BIGINT NOT NULL,
 created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
 updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
 version INT NOT NULL DEFAULT 0, deleted_at DATETIME(3) NULL,
 FOREIGN KEY(created_by) REFERENCES sys_user(id), FOREIGN KEY(updated_by) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

ALTER TABLE sop_station
 ADD COLUMN location_id BIGINT NULL,
 ADD COLUMN ip_address VARCHAR(45) CHARACTER SET ascii COLLATE ascii_bin NULL,
 ADD COLUMN active_ip VARCHAR(45) CHARACTER SET ascii COLLATE ascii_bin
   GENERATED ALWAYS AS (CASE WHEN deleted_at IS NULL THEN ip_address ELSE NULL END) STORED,
 ADD UNIQUE KEY uk_station_active_ip(active_ip),
 ADD CONSTRAINT fk_station_location FOREIGN KEY(location_id) REFERENCES sop_location(id);

-- Convert old free-text locations; retain the original station.location column.
INSERT INTO sop_location(code,name,status,created_by,updated_by)
 SELECT CONCAT('LOC-LEGACY-',MIN(id)),TRIM(location),0,MIN(created_by),MIN(updated_by)
 FROM sop_station WHERE location IS NOT NULL AND CHAR_LENGTH(TRIM(location))>0
 GROUP BY TRIM(location);
UPDATE sop_station s JOIN sop_location l ON l.name=TRIM(s.location)
 SET s.location_id=l.id WHERE s.location_id IS NULL;

-- Review remaining unconfigured stations; fill their real IP through the UI.
SELECT id,code,name,location_id,ip_address FROM sop_station
 WHERE deleted_at IS NULL AND (location_id IS NULL OR ip_address IS NULL);
