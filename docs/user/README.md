# 通用 SOP 平台：用户模块第一版设计

用户管理前后端现已实现。实际表核对结论见 [表结构核对](schema_review.md)，
当前接口及业务约定见 [后台用户模块](../../../SOP_Server_of_Java/docs/user/README.md)；现有表无需重建。

SQL脚本：[schema.sql](../../user-module-v1/schema.sql)、[seed.sql](../../user-module-v1/seed.sql)。

本设计依据当前用户页面及已实现的用户模块维护。旧数据库方案不作为本方案依据；SQL位于user-module-v1，本目录仅维护设计与核对记录。

## 范围和约定

第一版按一个平台、一套用户设计，不预先加入多租户、组织树、项目成员和 SOP 执行表。一个用户可有多个角色，第一版只属于一个班组，工卡最多一张。班组与权限无关。以后项目的数据访问范围需要单独设计，不能把拥有一个功能权限等同于可以访问全部项目。

支持账号密码登录、登出、获取当前用户、分页查询、新增、编辑、状态变更、软删除、密码修改/重置和角色分配。工卡只作资料绑定，本版不支持刷卡登录。账号创建后不可修改。

## 七张表

| 表 | 用途 | 关键内容 |
|---|---|---|
| sys_user | 账号与人员资料 | 用户名、密码哈希、姓名、工卡、班组、电话、头像、状态、超级用户标记、软删除时间 |
| sys_team | 班组 | 名称、启用状态；替换前端写死的班组 |
| sys_role | 角色 | 稳定编码、显示名称、说明、启用状态 |
| sys_permission | 权限定义 | 如 user:create、user:delete；由代码迁移维护 |
| sys_user_role | 用户与角色关联 | 复合主键，防止重复分配 |
| sys_role_permission | 角色与权限关联 | 复合主键，防止重复授权 |
| sys_user_session | 登录会话 | token 哈希、所属用户、失效和撤销时间 |

所有字段类型、空值、默认值、索引和约束以 schema.sql 为准。ID 使用正数 BIGINT，由数据库生成；接口统一输出为字符串，避免前端 JavaScript 大整数精度丢失。时间统一存 UTC，接口返回带 Z 的 ISO 8601 字符串，由前端转本地时间。

## 用户字段与前端对应

| 字段 | 规则 |
|---|---|
| id | 内部主键，接口字符串 |
| username | 必填，3–64 个字符；后端去首尾空白并转小写，只接受 a-z、0-9、下划线、点、连字符；全平台唯一，软删除后也不复用 |
| password_hash | 仅服务端使用；Argon2id 编码字符串，包含盐和参数；绝不返回前端。只有未初始化的禁用 root 可以为空 |
| real_name | 必填，去首尾空白，1–64 个字符 |
| card_number | 可空，去首尾空白；空字符串转 NULL；区分大小写；未删除用户中唯一，删除后可重新绑定 |
| team_id | 可空，关联班组；新分配时要求班组启用 |
| phone | 可空，最多 20 字符；通用平台不限定中国大陆手机号，不作登录账号、不要求唯一 |
| avatar_url | 可空，最多 255 字符，服务端校验允许的地址格式 |
| status | 1 正常、0 禁用、2 离职；后两者不能登录 |
| is_superuser | 仅 root 为 1，不接受普通创建/编辑接口输入 |
| must_change_password | 新建、管理员重置后为 1；改密成功后为 0 |
| deleted_at | 非空即已删除；普通查询不返回，不允许登录或授权 |
| version | 乐观锁版本；前端编辑和状态/角色等变更提交版本，冲突返回 409 |

sys_user 还记录 password_changed_at、last_login_at、created_at、updated_at。数据库 CHECK 只覆盖行内基本约束；密码格式、字段规范化、权限、root 保护、软删除过滤和事务规则必须由后端实现。

## root 与普通用户授权

seed.sql 创建唯一 root，初始禁用且没有密码，不存在公开通用初始密码。部署初始化命令从交互输入或密钥配置取得密码，用服务端密码编码器生成 Argon2id 哈希，再在事务中锁定 root 行：仅当 password_hash IS NULL 且 status=0 时设置哈希、password_changed_at、status=1、must_change_password=0，并增加 version；必须检查恰好更新一行。重复初始化跳过已有密码，不能覆盖密码或重新启用账号。Java 侧已提供可选启动初始化器，配置方法见 [登录与初始化](../../../SOP_Server_of_Java/docs/user/login.md)；未开启初始化前，执行两个 SQL 文件后 root 仍不能登录。

认证成功且账号正常、未删除、会话有效后，后端读取数据库 is_superuser：root 跳过功能权限匹配，自动拥有现在及未来所有功能权限；不需要枚举全部角色或逐条插入权限关联。root 同样必须遵守业务数据校验和事务约束。

root 不可通过业务 API 删除、禁用、设为离职、改名、移除超级用户身份或被普通管理员编辑/重置密码。root 可在验证当前密码后修改自己的密码。数据库约束限制 root 的身份和软删除；禁止物理删除、禁用和跨用户修改仍须服务层控制。应用不提供物理删除接口。

普通用户的有效权限是全部启用角色所关联权限的并集；无角色或无权限也可登录，但不能调用受保护管理接口。默认新用户分配 member。预置 user_admin 拥有用户管理权限，但不是超级用户。

分配角色必须独立检查 user:assign-role；普通管理员只能分配其本人已经持有的启用角色，不能修改自身角色，不能编辑角色权限定义，不能操作 root。不能仅检查 user:update 就接受 role_ids、is_superuser 或 password_hash。未来角色管理接口须独立设计授权边界；第一版角色和权限由迁移维护。

## 登录和会话

1. 按规范化 username 查找未删除且正常的用户，用密码编码器验证密码；失败统一返回“账号或密码错误”。服务端实施登录频率限制，记录不包含密码/token 的安全日志；前端固定验证码不是有效验证机制，应移除或接入真实服务端验证码。
2. 创建至少 32 个密码学安全随机字节的 token，原 token 只在登录响应中返回；数据库存 SHA-256 的 32 字节摘要。会话固定 8 小时有效，不实现 refresh token；到期重新登录。
3. 每次请求根据 token 摘要读取会话，同时校验用户状态、deleted_at、到期时间、revoked_at；权限从数据库当前角色关系读取，第一版不缓存，避免变更后仍使用旧权限。
4. must_change_password=1 时，仅允许当前用户资料、修改自己密码和登出接口；业务接口返回 PASSWORD_CHANGE_REQUIRED。改密后撤销全部会话，重新登录。
5. 禁用、离职、删除、密码重置/修改时，在同一事务中修改用户并撤销其全部会话。登录创建会话和上述操作使用同一用户行锁，防止并发登录逃过撤销。登出撤销当前会话，重复登出可成功。

请求推荐 Authorization: Bearer <token>。当前前端使用 X-Token，接入时统一修改请求拦截器。登录密码放在 POST JSON 请求体，不放 URL 查询参数；日志不得记录密码、完整 token、哈希。

密码采用 Argon2id，最低参数参考 OWASP：内存 19 MiB、迭代 2、并行度 1，部署时可按性能提高。第一版密码长度建议 8–128 个字符，创建、初始化、修改和重置使用同一套规则。禁止使用明文、MD5 或单次 SHA-256 保存密码。

## 增删改和并发

- 新增：校验输入 → 哈希密码 → 插入用户 → 分配 member 或经授权角色；同一事务完成。用户名/卡号冲突返回 409，不能只靠事先查询排重。
- 编辑：白名单接受 real_name、card_number、team_id、phone、avatar_url；status 使用专门接口，角色使用专门接口。UPDATE 带 id、version、deleted_at IS NULL 条件，成功后 version+1；零行表示已删除或版本冲突。
- 删除：设置 deleted_at、status=0、version+1，撤销会话；保留用户和关联，不级联删除未来生产数据。不提供恢复入口；恢复功能需以后处理工卡冲突。禁止自删、自禁用、自设离职，避免意外退出管理能力。
- 离职：资料保留、禁止登录；允许管理员将普通用户重新设为正常，但历史会话不能复活。
- 班组禁用：保留人员归属，不允许新增分配，不阻止其成员登录；班组有引用时不允许物理删除。
- 所有用户写操作先锁定操作者和目标用户行（按 id 顺序），在事务内重新验证操作者当前会话和权限。角色分配也遵守此锁规则，防止并发撤权后继续写入。

## 接口约定与前端接入

下列为相对 API 基础地址的路径。统一成功响应 {code:200,message:"成功",data:...}，失败使用合适的 HTTP 状态和同值 code（400/401/403/404/409）。前端 request.js 需要同时处理 HTTP 错误响应中的业务消息。列表 data 为 {items:[],total:0}；分页 page>=1，limit 为 1–100，排序固定 id DESC。查询条件用参数绑定，禁止拼接 SQL。

| 方法和路径 | 内容 / 权限 |
|---|---|
| POST /user/auth/login | JSON {account,password}；返回 data {access_token,token_type:"Bearer",expires_in:28800,must_change_password,user} |
| POST /user/auth/logout | 撤销当前会话 |
| GET /user/me | 当前资料；roles 为编码数组，permissions 为编码数组，root 返回 permissions:["*"]、roles:["superuser"] |
| PUT /user/me/password | {old_password,new_password}，修改本人密码并撤销全部会话 |
| GET /user/list | user:list；page、limit、username、real_name、card_number、team_id、status；状态 0 不可当作未传 |
| POST /user | user:create；创建字段、password，可选 role_ids（提供时另检查分配权限） |
| PUT /user/{id} | user:update；资料白名单与 version |
| PUT /user/{id}/status | user:status；JSON {status,version} |
| DELETE /user/{id} | user:delete；JSON {version}，执行软删除 |
| PUT /user/{id}/password | user:reset-password；JSON {new_password,version}，设置必须改密并撤销会话 |
| PUT /user/{id}/roles | user:assign-role；JSON {role_ids,version}，替换角色集合 |
| GET /user/role/options | user:create 或 user:assign-role；返回操作者可分配的启用角色 |
| GET /user/team/options | user:list/user:create/user:update 任一；返回班组，新增选择只允许启用班组 |

用户返回字段白名单：id、username、real_name、card_number、team_id、shift_group（班组显示名）、phone、avatar_url、status、is_superuser、created_at、updated_at、version、roles。编辑所需 role_ids 仅向有分配权限的用户返回。绝不返回 password_hash 或 token_hash。

前端需要：shift_group 字符串选择改 team_id；统一使用 username/real_name，移除 user_name 混用；适配登录响应并取消对“必须有角色才能登录”的限制；加入改密、重置密码、角色分配；编辑状态改专用接口；补齐离职操作、版本提交；root 隐藏禁用/删除按钮，但后端仍强制校验。卡号随机生成按钮改成明确的模拟提示或暂时移除。

## 执行和验收

目标 MySQL 8.4。仅首次初始化全新独立空库时依次执行 schema.sql、seed.sql；不要与旧初始化脚本混用，已有用户表不要重跑。脚本无 DROP、无自动覆盖、非幂等，DDL不是整体可回滚事务，出错后停止并排查。用户接口已实现；实际开发库的只读核对范围见 [结构核对](schema_review.md)，后台自动化测试使用独立H2库，不能视为实际MySQL写入验收。

持续验收应覆盖：root初始化一次成功、重复初始化不覆盖已有密码；root登录并访问新增权限；普通用户正常登录但无管理权；用户名重复/并发工卡绑定失败；软删除后用户名保留、工卡可重绑；禁用/删除/改密后旧token立即失效；不能操作root或越权分配角色；乐观锁冲突；登录与禁用并发；首次改密前不能访问业务；列表和响应不泄露密码哈希。MySQL写入验收需在独立测试库执行，勿对实际业务用户做破坏性验收。

参考：[MySQL CHECK 约束](https://dev.mysql.com/doc/refman/8.4/en/create-table-check-constraints.html)、[OWASP 密码存储](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)。
