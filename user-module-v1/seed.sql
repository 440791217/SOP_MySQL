-- Run once after schema.sql in the SAME new schema.
SET NAMES utf8mb4;
SET SESSION time_zone = '+00:00';
START TRANSACTION;
-- root exists but cannot log in until a deployment-time password is installed.
INSERT INTO sys_user (username, real_name, status, is_superuser, password_hash)
VALUES ('root', '超级管理员', 0, 1, NULL);

INSERT INTO sys_role (code, name, description) VALUES
('user_admin', '用户管理员', '管理普通用户；不能管理 root 或授予超出自身范围的角色'),
('member', '普通用户', '允许登录，业务权限后续按需分配');

INSERT INTO sys_permission (code, name) VALUES
('user:list', '查询用户'),
('user:create', '新增用户'),
('user:update', '编辑用户'),
('user:delete', '删除用户'),
('user:status', '变更用户状态'),
('user:reset-password', '重置用户密码'),
('user:assign-role', '分配用户角色');

INSERT INTO sys_role_permission (role_id, permission_id)
SELECT r.id, p.id FROM sys_role r CROSS JOIN sys_permission p
WHERE r.code = 'user_admin';
COMMIT;
