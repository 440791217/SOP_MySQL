-- MySQL 8.4. Select sop_dev explicitly. Execute this WHOLE file ONCE.
-- Requires user/project/SOP schemas, project migrations 001/002 and SOP authoring migration 001.
-- Adds seven tables + one optional step field. No DROP, no existing data reset.
-- DDL is not atomic: inspect errors and existing objects before retrying.
SET NAMES utf8mb4;
SET SESSION time_zone = '+00:00';

CREATE TABLE sop_station (
 id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, code VARCHAR(64) NOT NULL UNIQUE, name VARCHAR(128) NOT NULL, location VARCHAR(255), owner_user_id BIGINT, status TINYINT NOT NULL DEFAULT 0 CHECK(status IN(0,1,2)), description VARCHAR(2000), FOREIGN KEY(owner_user_id) REFERENCES sys_user(id),
 created_by BIGINT NOT NULL, updated_by BIGINT NOT NULL,
 created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3), updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
 version INT NOT NULL DEFAULT 0, deleted_at DATETIME(3) NULL,
 FOREIGN KEY(created_by) REFERENCES sys_user(id), FOREIGN KEY(updated_by) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE sop_resource_model (
 id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, code VARCHAR(64) NOT NULL UNIQUE, name VARCHAR(128) NOT NULL, type_code VARCHAR(64) NOT NULL, model VARCHAR(128), specification VARCHAR(1000), unit VARCHAR(32) NOT NULL, status TINYINT NOT NULL DEFAULT 0 CHECK(status IN(0,1,2)), description VARCHAR(2000),
 created_by BIGINT NOT NULL, updated_by BIGINT NOT NULL,
 created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3), updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
 version INT NOT NULL DEFAULT 0, deleted_at DATETIME(3) NULL,
 FOREIGN KEY(created_by) REFERENCES sys_user(id), FOREIGN KEY(updated_by) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE sop_resource_device (
 id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, code VARCHAR(64) NOT NULL UNIQUE, name VARCHAR(128) NOT NULL, model_id BIGINT NOT NULL, serial_number VARCHAR(128), station_id BIGINT, owner_user_id BIGINT, status TINYINT NOT NULL DEFAULT 0 CHECK(status IN(0,1,2)), description VARCHAR(2000), FOREIGN KEY(model_id) REFERENCES sop_resource_model(id), FOREIGN KEY(station_id) REFERENCES sop_station(id), FOREIGN KEY(owner_user_id) REFERENCES sys_user(id),
 created_by BIGINT NOT NULL, updated_by BIGINT NOT NULL,
 created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3), updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
 version INT NOT NULL DEFAULT 0, deleted_at DATETIME(3) NULL,
 FOREIGN KEY(created_by) REFERENCES sys_user(id), FOREIGN KEY(updated_by) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE sop_device_connection (
 id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, device_id BIGINT NOT NULL UNIQUE, transport VARCHAR(16) NOT NULL CHECK(transport IN('network','usb','serial','none')), protocol VARCHAR(32) NOT NULL, host VARCHAR(255), port INT CHECK(port BETWEEN 1 AND 65535), rtsp_url VARCHAR(1300) NULL COMMENT '完整RTSP地址，仅设备管理权限可读取认证信息', path VARCHAR(1000), host_key VARCHAR(128), device_key VARCHAR(255), enabled TINYINT NOT NULL DEFAULT 1 CHECK(enabled IN(0,1)), FOREIGN KEY(device_id) REFERENCES sop_resource_device(id),
 created_by BIGINT NOT NULL, updated_by BIGINT NOT NULL,
 created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3), updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
 version INT NOT NULL DEFAULT 0, deleted_at DATETIME(3) NULL,
 FOREIGN KEY(created_by) REFERENCES sys_user(id), FOREIGN KEY(updated_by) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE sop_step_resource_requirement (
 id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, step_id BIGINT NOT NULL, model_id BIGINT NOT NULL, name VARCHAR(128) NOT NULL, type_code VARCHAR(64) NOT NULL, model VARCHAR(128), specification VARCHAR(1000), unit VARCHAR(32) NOT NULL, quantity INT NOT NULL CHECK(quantity BETWEEN 1 AND 9999), description VARCHAR(2000), sort_order INT NOT NULL, UNIQUE(step_id,model_id), FOREIGN KEY(step_id) REFERENCES sop_step(id) ON DELETE CASCADE, FOREIGN KEY(model_id) REFERENCES sop_resource_model(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE sop_task (
 id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, code VARCHAR(64) NOT NULL UNIQUE, name VARCHAR(128) NOT NULL, subproject_id BIGINT NOT NULL, station_id BIGINT, owner_user_id BIGINT NOT NULL, sort_order INT NOT NULL DEFAULT 0 CHECK(sort_order>=0), status TINYINT NOT NULL DEFAULT 0 CHECK(status IN(0,1,2)), description VARCHAR(2000), FOREIGN KEY(subproject_id) REFERENCES sop_subproject(id), FOREIGN KEY(station_id) REFERENCES sop_station(id), FOREIGN KEY(owner_user_id) REFERENCES sys_user(id),
 created_by BIGINT NOT NULL, updated_by BIGINT NOT NULL,
 created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3), updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
 version INT NOT NULL DEFAULT 0, deleted_at DATETIME(3) NULL,
 FOREIGN KEY(created_by) REFERENCES sys_user(id), FOREIGN KEY(updated_by) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE sop_task_standard (
 id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, task_id BIGINT NOT NULL, sop_id BIGINT NOT NULL, revision_id BIGINT NOT NULL, active TINYINT NOT NULL DEFAULT 1 CHECK(active IN(0,1)), created_by BIGINT NOT NULL, created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3), FOREIGN KEY(task_id) REFERENCES sop_task(id), FOREIGN KEY(sop_id,revision_id) REFERENCES sop_revision(sop_id,id), FOREIGN KEY(created_by) REFERENCES sys_user(id), active_task_id BIGINT GENERATED ALWAYS AS (CASE WHEN active=1 THEN task_id ELSE NULL END) STORED, UNIQUE(active_task_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

ALTER TABLE sop_step ADD COLUMN workplace_requirements VARCHAR(2000) NULL;

CREATE INDEX ix_resource_device_station ON sop_resource_device(station_id,deleted_at,status);
CREATE INDEX ix_task_subproject_order ON sop_task(subproject_id,deleted_at,sort_order,id);
CREATE INDEX ix_task_standard_revision ON sop_task_standard(revision_id,active,task_id);

-- Additive task-owned content mapping. MySQL 8.4 / InnoDB.
-- Select sop_dev explicitly. Does not delete or rewrite any existing data.
CREATE TABLE IF NOT EXISTS sop_task_content (
 task_id BIGINT NOT NULL PRIMARY KEY,
 sop_id BIGINT NOT NULL,
 created_by BIGINT NOT NULL,
 created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
 CONSTRAINT uk_task_content_sop UNIQUE (sop_id),
 CONSTRAINT fk_task_content_task FOREIGN KEY(task_id) REFERENCES sop_task(id),
 CONSTRAINT fk_task_content_sop FOREIGN KEY(sop_id) REFERENCES sop_document(id),
 CONSTRAINT fk_task_content_creator FOREIGN KEY(created_by) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

