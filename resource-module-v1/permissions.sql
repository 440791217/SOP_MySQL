-- Optional repeatable role definitions, after schema.sql. Root needs no assignment.
SET NAMES utf8mb4;
START TRANSACTION;
INSERT IGNORE INTO sys_permission(code,name) VALUES
 ('resource:read','查询现场资源'),('resource:manage','维护现场资源'),('resource:use','使用工位设备'),('task:manage','管理子项目SOP任务');
INSERT IGNORE INTO sys_role(code,name,description,status) VALUES
 ('resource_manager','现场资源管理员','管理工位、工具设备及连接配置',1),
 ('task_editor','SOP任务配置人员','在项目编辑成员范围内配置任务与查询资源',1);
INSERT IGNORE INTO sys_role_permission(role_id,permission_id)
 SELECT r.id,p.id FROM sys_role r CROSS JOIN sys_permission p
 WHERE (r.code='resource_manager' AND p.code IN('resource:read','resource:manage','resource:use'))
 OR (r.code='task_editor' AND p.code IN('resource:read','resource:use','task:manage','project:read','project:list'));
COMMIT;
