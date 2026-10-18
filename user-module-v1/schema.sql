-- Independent user module draft. MySQL 8.4 / InnoDB.
-- Run ONCE in a NEW EMPTY schema; do not mix with database/migrations.
SET NAMES utf8mb4;
SET SESSION time_zone = '+00:00';

CREATE TABLE sys_team (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(64) NOT NULL,
  status TINYINT NOT NULL DEFAULT 1,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  UNIQUE KEY uk_team_name (name),
  CONSTRAINT ck_team_status CHECK (status IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE sys_user (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(64) NOT NULL,
  password_hash VARCHAR(255) CHARACTER SET ascii COLLATE ascii_bin NULL,
  real_name VARCHAR(64) NOT NULL,
  card_number VARCHAR(64) COLLATE utf8mb4_0900_bin NULL,
  team_id BIGINT NULL,
  phone VARCHAR(20) NULL,
  avatar_url VARCHAR(255) NULL,
  status TINYINT NOT NULL DEFAULT 1 COMMENT '0 disabled, 1 active, 2 departed',
  is_superuser TINYINT NOT NULL DEFAULT 0,
  must_change_password TINYINT NOT NULL DEFAULT 1,
  password_changed_at DATETIME(3) NULL,
  last_login_at DATETIME(3) NULL,
  deleted_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  version INT NOT NULL DEFAULT 0,
  active_card_number VARCHAR(64) COLLATE utf8mb4_0900_bin
    GENERATED ALWAYS AS (CASE WHEN deleted_at IS NULL THEN card_number ELSE NULL END) STORED,
  UNIQUE KEY uk_user_username (username),
  UNIQUE KEY uk_user_active_card (active_card_number),
  KEY ix_user_list (deleted_at, status, id),
  KEY ix_user_team (team_id),
  CONSTRAINT fk_user_team FOREIGN KEY (team_id) REFERENCES sys_team(id),
  CONSTRAINT ck_user_status CHECK (status IN (0,1,2)),
  CONSTRAINT ck_user_flags CHECK (is_superuser IN (0,1) AND must_change_password IN (0,1)),
  CONSTRAINT ck_user_active_password CHECK (status <> 1 OR password_hash IS NOT NULL),
  CONSTRAINT ck_user_password_required CHECK (
    password_hash IS NOT NULL OR (username = 'root' AND status = 0)
  ),
  CONSTRAINT ck_user_root CHECK (
    (username = 'root' AND is_superuser = 1 AND deleted_at IS NULL)
    OR (username <> 'root' AND is_superuser = 0)
  ),
  CONSTRAINT ck_user_card CHECK (card_number IS NULL OR CHAR_LENGTH(TRIM(card_number)) > 0),
  CONSTRAINT ck_user_version CHECK (version >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE sys_role (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  name VARCHAR(64) NOT NULL,
  description VARCHAR(255) NULL,
  status TINYINT NOT NULL DEFAULT 1,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  UNIQUE KEY uk_role_code (code),
  CONSTRAINT ck_role_status CHECK (status IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE sys_permission (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(100) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  name VARCHAR(64) NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE KEY uk_permission_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE sys_user_role (
  user_id BIGINT NOT NULL,
  role_id BIGINT NOT NULL,
  PRIMARY KEY (user_id, role_id),
  KEY ix_user_role_role (role_id),
  CONSTRAINT fk_user_role_user FOREIGN KEY (user_id) REFERENCES sys_user(id),
  CONSTRAINT fk_user_role_role FOREIGN KEY (role_id) REFERENCES sys_role(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE sys_role_permission (
  role_id BIGINT NOT NULL,
  permission_id BIGINT NOT NULL,
  PRIMARY KEY (role_id, permission_id),
  KEY ix_role_permission_permission (permission_id),
  CONSTRAINT fk_role_permission_role FOREIGN KEY (role_id) REFERENCES sys_role(id),
  CONSTRAINT fk_role_permission_permission FOREIGN KEY (permission_id) REFERENCES sys_permission(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE sys_user_session (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  token_hash BINARY(32) NOT NULL COMMENT 'SHA-256 of cryptographically random bearer token',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  expires_at DATETIME(3) NOT NULL,
  revoked_at DATETIME(3) NULL,
  UNIQUE KEY uk_session_token (token_hash),
  KEY ix_session_user (user_id, revoked_at),
  KEY ix_session_expiry (expires_at),
  CONSTRAINT fk_session_user FOREIGN KEY (user_id) REFERENCES sys_user(id),
  CONSTRAINT ck_session_expiry CHECK (expires_at > created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;
