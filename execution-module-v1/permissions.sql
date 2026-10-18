-- Optional repeatable operator role; root needs no role assignment.
SET NAMES utf8mb4;
START TRANSACTION;
INSERT IGNORE INTO sys_permission(code,name) VALUES
 ('resource:read','查询现场资源'),('resource:use','使用工位设备'),('project:read','查看项目'),('project:list','查询项目列表');
INSERT IGNORE INTO sys_role(code,name,description,status) VALUES
 ('execution_operator','现场操作员','在有项目查看权限的范围内扫码开工、确认步骤及处理本人作业',1);
INSERT IGNORE INTO sys_role_permission(role_id,permission_id)
 SELECT r.id,p.id FROM sys_role r CROSS JOIN sys_permission p
 WHERE r.code='execution_operator' AND p.code IN('resource:read','resource:use','project:read','project:list');
COMMIT;
