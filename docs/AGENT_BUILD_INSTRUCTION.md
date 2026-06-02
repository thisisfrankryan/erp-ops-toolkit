# Agent 构建指令优化版

你是一个企业 ERP 实施与运维脚本项目生成 Agent。请在当前目录生成一个名为 `ERP Ops Toolkit` 的工程化脚本仓库，用于展示 ERP / 进销存 / 财务 / 采购 / 库存管理系统中的实施运维能力。

## 目标

生成一个简洁、可信、可交付的本地仓库，重点体现：

- JavaScript 前端误操作拦截能力。
- SQL Server 数据修正安全意识。
- ERP 业务理解，包括审批流、采购单、库存、出入库、财务对账、用户权限、主数据初始化、月结阻塞、批量政策更新。
- 运维交付意识，包括备份、事务、回滚、影响行数核对、服务台账。
- 文档沉淀能力。

## 不要出现

- 不要使用夸张营销词或求职话术。
- 不要夸张表达，不要伪装生产经验。
- 不要生成会直接误导生产执行的危险 SQL。
- 不要把 SQL 写成无条件 UPDATE / DELETE。

## 必须生成

```text
README.md
.gitignore
docs/RUNBOOK.md
scripts/js/anti_double_submit.js
scripts/js/form_validator.js
scripts/js/currency_to_words.js
scripts/js/paste_data_cleaner.js
scripts/js/dynamic_form_control.js
scripts/sql/order_status_correction.sql
scripts/sql/inventory_adjustment.sql
scripts/sql/user_permission_clone.sql
scripts/sql/data_deduplication.sql
scripts/sql/deadlock_diagnosis.sql
scripts/sql/bulk_policy_update.sql
```

## README 要求

README 要像工程项目说明书，不要像求职话术。包含：

- 项目定位
- 目录结构
- 脚本说明
- 安全原则
- 推荐使用方式
- 能体现的工程能力
- License

## 脚本要求

JavaScript：

- 用清晰函数封装。
- 保留示例用法。
- 注释解释业务场景和技术动作。
- 财务大写金额和粘贴数据清洗要提供真实可复用逻辑，不要只返回固定示例。
- 动态表单控制要用规则方式封装，避免只写死某一个页面。

SQL：

- 默认使用 SQL Server 模板。
- 必须有 `SET XACT_ABORT ON`。
- 必须先 SELECT 确认目标数据。
- 必须先 SELECT INTO 备份原始数据。
- 必须 BEGIN TRANSACTION。
- 必须检查 `@@ROWCOUNT`。
- 影响行数符合预期才 COMMIT，否则 ROLLBACK。
- 主数据去重场景禁止直接 DELETE，优先使用失效标记并保留可追溯字段。
- 死锁处理脚本默认只诊断，不默认执行 `KILL`。
- 批量政策更新必须先预览影响范围、备份受影响数据，再事务更新。

## Git 要求

如果目录尚未初始化 Git，可执行：

```bash
git init
git add .
git commit -m "feat: init ERP ops toolkit"
```

不要自动配置远程仓库，除非用户明确提供 GitHub 仓库地址。
