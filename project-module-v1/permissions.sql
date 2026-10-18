-- Optional project role setup; select sop_dev before execution.
-- Root works without this script. No existing users are assigned automatically.
-- Run AFTER schema.sql. Safe to repeat; transaction affects only these definitions.
SET NAMES utf8mb4;
START TRANSACTION;
INSERT IGNORE INTO sys_permission(code,name) VALUES
 ('project:list','查看项目列表'),('project:read','查看项目详情'),
 ('project:create','创建项目'),('project:update','编辑项目资料'),
 ('subproject:create','创建子项目'),('subproject:update','编辑及排序子项目'),
 ('subproject:status','变更子项目状态'),('subproject:delete','删除未开始子项目'),
 ('subproject:restore','恢复归档子项目');
INSERT IGNORE INTO sys_role(code,name,description,status)
 VALUES('project_editor','项目编辑人员','可创建项目；其他项目内操作仍受成员范围及负责人规则限制',1);
INSERT IGNORE INTO sys_role_permission(role_id,permission_id)
 SELECT r.id,p.id FROM sys_role r CROSS JOIN sys_permission p
 WHERE r.code='project_editor' AND p.code IN
 ('project:list','project:read','project:create','project:update',
  'subproject:create','subproject:update','subproject:status','subproject:delete','subproject:restore');
COMMIT;

-- Optional least-privilege roles for project membership; neither grants project creation.
START TRANSACTION;
INSERT IGNORE INTO sys_role(code,name,description,status) VALUES
 ('project_viewer','项目查看人员','配合有效项目成员身份，只提供列表与查看功能',1),
 ('project_contributor','项目协作人员','配合编辑成员身份进行项目协作，不授予创建主项目权限',1);
INSERT IGNORE INTO sys_role_permission(role_id,permission_id)
 SELECT r.id,p.id FROM sys_role r CROSS JOIN sys_permission p
 WHERE (r.code='project_viewer' AND p.code IN ('project:list','project:read'))
 OR (r.code='project_contributor' AND p.code IN ('project:list','project:read','project:update',
 'subproject:create','subproject:update','subproject:status','subproject:delete','subproject:restore'));
COMMIT;
