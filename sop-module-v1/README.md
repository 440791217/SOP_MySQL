# SOP 模块建表入口

本目录维护SOP表结构与可选权限脚本。图文SOP后台、图片授权读取、项目/子项目关联与前端已实现，统一制作新增[制作增量迁移](migrations/001_authoring_visual.sql)，已有七表不要重跑schema.sql，先执行一次增量脚本再重启后台。完整规则见 [数据库设计](../docs/sop/README.md)，接口见 [后台文档](../../SOP_Server_of_Java/docs/sop/README.md)，历史变更见 [changelog](../docs/sop/changelog.md)。

[schema.sql](schema.sql) 面向MySQL 8.4，在已有用户模块、项目模块及项目迁移001、002之后，新增七张表。不修改旧表、不初始化演示数据、不自动授权。本次未连接实际数据库执行。

[permissions.sql](permissions.sql) 可选、可重复执行，定义查看/编写/负责人角色（编写/负责人包含sop:bind关联功能），不自动为用户分配。root或管理项目负责人无需这些角色；普通成员需要对应功能角色及有效项目成员身份。角色脚本也补齐所需project:list/read功能定义，不要求先执行可选的项目角色脚本。

执行前选择sop_dev，检查SELECT DATABASE(), VERSION()，确认新表均不存在，再全选执行整个文件。已有用户/项目表不能重建。MySQL DDL不会整体回滚，部分失败后先检查实际已建表，不要盲目重跑。

这份脚本只创建数据结构，需要配套新版后台。既有项目删除、成员移除/降级的SOP引用检查已接入，新后台的相关接口会查询SOP表，因此先完成七表建表再重启后端。不要直接手填业务数据来绕过接口校验。
