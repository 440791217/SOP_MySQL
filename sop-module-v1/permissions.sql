-- Optional SOP roles for the SOP authoring and fixed-version binding interfaces. Safe to repeat.
-- Select sop_dev, run AFTER schema.sql. Does not assign roles to any user.
SET NAMES utf8mb4;
START TRANSACTION;
INSERT IGNORE INTO sys_permission(code,name) VALUES
 ('project:list','查看项目列表'),('project:read','查看项目详情'),
 ('sop:list','查看SOP列表'),('sop:read','查看SOP版本'),('sop:create','创建SOP'),
 ('sop:update','编写SOP草稿'),('sop:publish','发布负责的SOP'),
 ('sop:bind','关联项目SOP'),('sop:retire','停用负责的SOP版本'),('sop:delete','删除未发布SOP');
INSERT IGNORE INTO sys_role(code,name,description,status) VALUES
 ('sop_viewer','SOP查看人员','结合管理项目有效成员身份查看SOP，不授予项目访问范围',1),
 ('sop_editor','SOP编写人员','结合管理项目编辑成员身份编写草稿，不含发布权限',1),
 ('sop_publisher','SOP负责人','编写及发布能力；发布/停用/删除仍要求本人为SOP负责人',1);
INSERT IGNORE INTO sys_role_permission(role_id,permission_id)
 SELECT r.id,p.id FROM sys_role r CROSS JOIN sys_permission p
 WHERE (r.code IN ('sop_viewer','sop_editor','sop_publisher') AND p.code IN ('project:list','project:read','sop:list','sop:read'))
 OR (r.code IN ('sop_editor','sop_publisher') AND p.code IN ('sop:create','sop:update','sop:bind'))
 OR (r.code='sop_publisher' AND p.code IN ('sop:publish','sop:retire','sop:delete'));
COMMIT;
