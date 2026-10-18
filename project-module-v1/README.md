# 项目模块 SQL

完整设计见 [docs/project](../docs/project/README.md)，更新记录见 [changelog.md](../docs/project/changelog.md)。

- [schema.sql](schema.sql)：在已有用户模块的库中新增项目三表；已建表不要重跑。
- [001_archive_restore.sql](migrations/001_archive_restore.sql)：归档恢复升级，建表后执行一次；已有表也只执行这份升级脚本，不重建。
- [002_members_and_activity.sql](migrations/002_members_and_activity.sql)：成员状态与操作记录升级；001之后执行一次，历史成员默认有效，不重建原表。
- [permissions.sql](permissions.sql)：可选的项目编辑角色及权限定义，可重复执行，不自动给用户授权；root无需此脚本。

本目录保留SQL和执行入口，业务设计与后续修改说明统一维护在 docs/project。

新库顺序：schema.sql → migrations/001_archive_restore.sql → migrations/002_members_and_activity.sql → 按需permissions.sql。已有项目表只执行尚未执行的迁移，按001、002顺序；已执行的脚本不要重跑。部署新版后端前先完成迁移。permissions.sql可重复执行，提供“项目查看人员”“项目协作人员”和含创建项目权限的“项目编辑人员”，不自动为用户分配角色。
