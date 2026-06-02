# ERP Ops Toolkit

ERP 实施、运维与技术支持常用脚本工具箱。项目用于沉淀企业 ERP / 进销存 / B/S 管理系统中常见的前端误操作拦截、表单校验、动态表单控制、财务字段处理、数据库状态修正、权限与数据范围、库存异常、主数据清洗、死锁诊断、接口重试、附件审计和批量政策更新等实践模板。

> 说明：本仓库中的脚本均为学习与演示模板，不应在生产环境中直接复制执行。涉及数据库写操作时，必须先备份、先查询确认、再在测试环境验证，最后由有权限人员按变更流程执行。

## 项目定位

这个仓库重点展示四类能力：

- 前端基础排查与修复：通过 JavaScript 处理重复提交、必填项、金额联动、粘贴数据清洗、动态表单控制等常见问题。
- 数据库安全意识：使用事务、备份、精准 WHERE 条件、影响行数核对，降低误操作风险。
- ERP 业务理解：覆盖审批流、库存、财务金额、用户权限、供应商主数据、财务月结和批量政策变更等高频实施运维场景。
- 实施运维闭环：把问题现象、处理步骤、回滚方案和交付文档整理清楚，方便客户现场支持和团队交接。

适用场景：

- ERP / 进销存 / 财务 / 采购 / 库存管理系统实施支持。
- 客户现场问题排查、数据核对、操作培训和服务台账沉淀。
- 初级运维、实施工程师、技术支持工程师的脚本能力展示。

## 目录结构

```text
erp-ops-toolkit/
├── README.md
├── docs/
│   ├── AGENT_BUILD_INSTRUCTION.md
│   ├── INTERVIEW_SCENARIOS.md
│   └── RUNBOOK.md
├── scripts/
│   ├── js/
│   │   ├── anti_double_submit.js
│   │   ├── app_error_recorder.js
│   │   ├── currency_to_words.js
│   │   ├── dependent_select_reset.js
│   │   ├── dynamic_form_control.js
│   │   ├── form_validator.js
│   │   ├── paste_data_cleaner.js
│   │   └── query_export_guard.js
│   └── sql/
│       ├── attachment_orphan_audit.sql
│       ├── bulk_policy_update.sql
│       ├── data_deduplication.sql
│       ├── deadlock_diagnosis.sql
│       ├── dictionary_option_repair.sql
│       ├── integration_retry_queue.sql
│       ├── inventory_adjustment.sql
│       ├── order_status_correction.sql
│       ├── report_query_diagnosis.sql
│       ├── user_data_scope_audit.sql
│       ├── user_login_unlock.sql
│       ├── user_permission_clone.sql
│       └── user_view_config_reset.sql
└── .gitignore
```

## 脚本说明

### 前端脚本

| 文件 | 场景 | 价值 |
| --- | --- | --- |
| `scripts/js/anti_double_submit.js` | 用户在网络慢或页面卡顿时重复点击提交按钮 | 在提交过程中锁定按钮，减少重复单据和重复请求 |
| `scripts/js/form_validator.js` | 表单必填项、金额、日期、数量等基础数据不合法 | 在请求进入后端前做基础校验，减少无效请求 |
| `scripts/js/currency_to_words.js` | 财务单据需要数字金额与中文大写金额联动 | 自动生成大写金额，减少人工录入和核对成本 |
| `scripts/js/paste_data_cleaner.js` | 从 Excel / 网页复制税号、银行账号、发票信息时带入空格、换行或全角字符 | 清洗粘贴数据，降低字段格式错误和长度超限概率 |
| `scripts/js/dynamic_form_control.js` | 报销类型、项目类型等字段变化后，需要动态显示、隐藏或强制填写其他字段 | 用规则驱动方式控制条件字段，减少错填和漏填 |
| `scripts/js/app_error_recorder.js` | 页面白屏、按钮无响应、接口报错但客户无法描述细节 | 记录前端异常、接口失败和网络错误，方便服务台账取证 |
| `scripts/js/query_export_guard.js` | 客户不加条件查询或导出大范围报表，导致页面长时间等待 | 限制日期范围和必要条件，提示分批查询 / 导出 |
| `scripts/js/dependent_select_reset.js` | 组织、部门、项目、仓库等级联下拉切换后保留旧值 | 父级字段变化时清空子级缓存，避免提交不一致数据 |

### SQL 模板

| 文件 | 场景 | 价值 |
| --- | --- | --- |
| `scripts/sql/order_status_correction.sql` | 审批流状态卡住，单据无法继续流转 | 使用事务和影响行数校验修正状态 |
| `scripts/sql/inventory_adjustment.sql` | 库存数量异常，影响出入库业务 | 先备份异常记录，再通过事务修正库存 |
| `scripts/sql/user_permission_clone.sql` | 新员工入职或岗位调动，需要参考同岗位用户配置权限 | 先检查源用户和目标用户，再通过事务复制权限记录 |
| `scripts/sql/data_deduplication.sql` | 供应商、物料等基础数据初始化阶段出现重复记录 | 预览重复组，备份受影响数据，用失效标记替代直接删除 |
| `scripts/sql/deadlock_diagnosis.sql` | 财务月结、成本核算或报表任务出现阻塞，页面长时间转圈 | 查询阻塞链、长事务、锁信息和死锁图，辅助判断处理范围 |
| `scripts/sql/bulk_policy_update.sql` | 税率、报销规则或业务政策变化，需要批量更新未结案单据 | 先预览范围并备份，再用事务批量更新和复核 |
| `scripts/sql/user_login_unlock.sql` | 用户因多次输错密码或误锁定导致无法登录 | 先确认账号状态，备份后只重置锁定相关字段 |
| `scripts/sql/user_data_scope_audit.sql` | 用户能进菜单但看不到项目、部门或业务数据 | 区分菜单权限和数据范围，按同岗位参考用户审计修复 |
| `scripts/sql/dictionary_option_repair.sql` | 页面下拉框为空、缺少选项或显示错误字典值 | 备份字典后恢复启用或补齐缺失字典项 |
| `scripts/sql/report_query_diagnosis.sql` | 报表、台账或列表查询慢 | 只读诊断慢 SQL、逻辑读、缺失索引和现有索引 |
| `scripts/sql/attachment_orphan_audit.sql` | 附件上传后看不到、附件串单或存在孤儿附件 | 审计附件元数据和业务单据关系，备份后逻辑标记 |
| `scripts/sql/integration_retry_queue.sql` | OA、移动审批或第三方接口回调失败 | 只重试临时失败且未超次数的消息，避免重复回调 |
| `scripts/sql/user_view_config_reset.sql` | 单个用户列表字段消失、页面布局异常 | 备份并失效个人视图配置，恢复系统默认页面 |

## 高频场景映射

| 场景 | 问题现象 | 对应脚本 |
| --- | --- | --- |
| 1. 高频连击导致一单多发 | 网络慢时用户重复点击提交，生成重复单据 | `scripts/js/anti_double_submit.js` |
| 2. 金额 / 数量为空或负数 | 脏数据进入后端，引发报错或流程卡住 | `scripts/js/form_validator.js` |
| 3. 外部复制数据带隐形空格 | 税号、银行账号等字段存入异常字符，后续查询失败 | `scripts/js/paste_data_cleaner.js` |
| 4. 动态表单控制失效 | 科研经费等特定类型需要显示并强制填写项目编号 | `scripts/js/dynamic_form_control.js` |
| 5. 审批流状态卡死 | 前端提示成功但数据库状态未流转 | `scripts/sql/order_status_correction.sql` |
| 6. 库存跌成负数 | 并发扣减或异常单据导致库存无法正常出入库 | `scripts/sql/inventory_adjustment.sql` |
| 7. 批量新员工权限配置 | 人工逐个勾选菜单和按钮，容易漏配错配 | `scripts/sql/user_permission_clone.sql` |
| 8. 主数据重复污染 | 供应商、物料基础数据导入前未清洗 | `scripts/sql/data_deduplication.sql` |
| 9. 财务月结阻塞 / 死锁 | 报表或凭证生成进程互相等待，页面持续转圈 | `scripts/sql/deadlock_diagnosis.sql` |
| 10. 政策变化批量改写 | 税率、项目有效期等规则变化，需要批量处理存量单据 | `scripts/sql/bulk_policy_update.sql` |
| 11. 页面白屏 / 按钮无响应 | 客户无法描述报错细节，只说页面打不开 | `scripts/js/app_error_recorder.js` |
| 12. 大范围查询 / 导出拖慢系统 | 报表不加组织、项目或日期条件，导致长时间等待 | `scripts/js/query_export_guard.js` |
| 13. 级联下拉旧值残留 | 切换组织后项目、仓库仍保留旧选项 | `scripts/js/dependent_select_reset.js` |
| 14. 账号被锁 / 登录失败 | 用户多次输错密码或账号误锁定 | `scripts/sql/user_login_unlock.sql` |
| 15. 有菜单但看不到数据 | 菜单权限正常，组织 / 项目数据范围缺失 | `scripts/sql/user_data_scope_audit.sql` |
| 16. 下拉字典为空 / 错误 | 字典项停用、漏配或显示名称错误 | `scripts/sql/dictionary_option_repair.sql` |
| 17. 报表 / 列表查询慢 | 成本报表、库存台账、报销列表响应慢 | `scripts/sql/report_query_diagnosis.sql` |
| 18. 附件看不到 / 串单 | 附件元数据和业务单据关联异常 | `scripts/sql/attachment_orphan_audit.sql` |
| 19. 接口回调失败 | OA / 移动审批已操作但 ERP 未同步 | `scripts/sql/integration_retry_queue.sql` |
| 20. 个人页面配置异常 | 单个用户列表字段消失或查询条件错乱 | `scripts/sql/user_view_config_reset.sql` |

## 安全原则

1. 写操作前必须先查询：先确认目标单据、商品、客户、用户或库存记录是否唯一。
2. 写操作前必须先备份：保留修正前的数据快照，便于回滚与审计。
3. UPDATE / DELETE 必须带精准 WHERE：禁止无条件更新，禁止用模糊条件直接改生产数据。
4. 尽量使用逻辑失效替代物理删除：主数据、权限和业务单据优先保留审计痕迹。
5. 必须检查影响行数：预期 1 行就只能影响 1 行，批量场景要提前计算预期行数。
6. 生产执行必须走变更流程：测试环境验证、负责人确认、低峰执行、执行后复核。
7. 处理过程必须留痕：记录问题现象、执行脚本、执行人、时间、影响范围和结果。

## 推荐使用方式

1. 在测试库或本地模拟库中验证 SQL 模板。
2. 将脚本中的示例表名、字段名、状态值改成实际系统定义。
3. 执行前先运行 `SELECT` 语句确认目标数据。
4. 事务内执行 `UPDATE` / `INSERT`，检查影响行数。
5. 确认无误后提交；异常时回滚。
6. 将处理过程写入服务台账或项目问题记录。

## 能体现的工程能力

- JavaScript 基础、DOM 操作、表单校验、重复提交保护、粘贴事件处理、动态表单控制。
- 财务金额处理、税号 / 银行账号字段清洗、前端输入规范化、前端异常取证。
- SQL Server / 关系型数据库基础、事务、备份、影响行数核对、阻塞链排查、慢查询诊断。
- ERP 业务理解：采购单、审批流、库存、出入库、财务对账、权限配置、数据范围、字典配置、接口回调、附件管理、主数据初始化、月结和政策更新。
- 运维实施意识：先备份、可回滚、可复核、可交接。
- 文档沉淀能力：把脚本、业务场景、风险和处理流程写清楚。

## License

MIT License. 本仓库用于个人工程实践与学习交流。
