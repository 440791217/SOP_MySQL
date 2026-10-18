# 数据库文档导航

| 模块 | 当前设计 | 核对记录 | 变更记录 |
|---|---|---|---|
| 公共 | [业务自动编号](common/README.md) | 独立H2验证；MySQL尚未执行 | [变更记录](common/changelog.md) |
| 用户 | [表结构及业务约束](user/README.md) | [2026-10-16结构核对](user/schema_review.md) | [变更记录](user/changelog.md) |
| 项目 | [项目、子项目与成员设计](project/README.md) | 设计说明中列明验证范围 | [变更记录](project/changelog.md) |
| SOP | [版本、步骤、附件与项目关联设计](sop/README.md) | 图文/关联及前端已实现，实际MySQL尚未验证 | [变更记录](sop/changelog.md) |
| 现场资源 | [工位、工具及 SOP 关联方案](resource/README.md) | 脚本与接口已提供；实际 MySQL 未执行 | [变更记录](resource/changelog.md) |

后续模块使用 docs/<模块>/README.md 和 changelog.md；执行过的数据库核对记录保留日期，不作为实时数据库状态。当前设计随功能更新，历史变化只写简要记录。SQL继续保留原模块路径，已有脚本不得为迁就文档目录而重复执行；后续改表提供独立迁移脚本并说明执行顺序。

数据库文档维护字段、约束、索引及迁移规则，接口以后台文档和OpenAPI为准。跨仓库链接假定三个工程位于同一父目录。
