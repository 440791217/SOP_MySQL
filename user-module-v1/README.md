# 用户模块 SQL

完整设计已归档到 [docs/user](../docs/user/README.md)，历史核对见 [结构核对](../docs/user/schema_review.md)。

- [schema.sql](schema.sql)：用户模块建表脚本。
- [seed.sql](seed.sql)：角色、权限及待初始化root种子数据。

这两个脚本用于首次初始化，已有用户表不要重跑。本目录仅保留SQL及导航，后续设计更新写到 docs/user，变更记录写到 [changelog.md](../docs/user/changelog.md)。
