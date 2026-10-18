-- Run in the application's database before restarting the backend. Safe to rerun.
SET @rtsp_column_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sop_device_connection' AND COLUMN_NAME = 'rtsp_url');
SET @rtsp_upgrade = IF(@rtsp_column_exists = 0,
 'ALTER TABLE sop_device_connection ADD COLUMN rtsp_url VARCHAR(1300) NULL COMMENT ''完整RTSP地址'' AFTER path',
 'SELECT 1');
PREPARE rtsp_upgrade_statement FROM @rtsp_upgrade;
EXECUTE rtsp_upgrade_statement;
DEALLOCATE PREPARE rtsp_upgrade_statement;
