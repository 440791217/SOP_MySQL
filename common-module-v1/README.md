# 公共模块历史脚本

当前业务编号采用前端时间戳＋随机后缀，后台校验和保存，**无需执行本目录流水表脚本**。

migrations/001_business_code_sequence.sql保留为旧方案历史，不再是部署前置步骤。已建流水表可闲置保留，未建无需创建；不自动删除任何数据库对象。当前规则见[公共数据说明](../docs/common/README.md)，变化见[变更记录](../docs/common/changelog.md)。
