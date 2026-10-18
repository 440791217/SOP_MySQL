-- OPTIONAL test location data. Run after migrations/001_station_location_ip.sql.
-- Select sop_dev. Repeatable, does not overwrite existing records; no station/IP fixtures.
SET NAMES utf8mb4;
START TRANSACTION;
INSERT INTO sop_location(code,name,status,description,created_by,updated_by)
 SELECT seed.code,seed.name,0,'测试位置，可通过位置管理修改或删除',u.id,u.id
 FROM (
  SELECT 'LOC-TEST-A' AS code,'测试区域 A' AS name
  UNION ALL SELECT 'LOC-TEST-B','测试区域 B'
  UNION ALL SELECT 'LOC-TEST-LAB','测试实验室'
 ) seed JOIN (SELECT MIN(id) AS id FROM sys_user WHERE is_superuser=1 AND deleted_at IS NULL) u ON u.id IS NOT NULL
 WHERE NOT EXISTS(SELECT 1 FROM sop_location l WHERE l.code=seed.code);
COMMIT;
SELECT code,name,status FROM sop_location WHERE code IN('LOC-TEST-A','LOC-TEST-B','LOC-TEST-LAB');
