# Minis 学习 1.15 升级说明

## 固定来源

- 官方底座：OpenMinis/OpenMinis `1a71df0f381cefde80bf912b723de6f9831bc177`。
- 学习版原版本：`d49d4dd5eec9b522334cfeda5bf06ae4846b5c65`（1.14 build 8）。
- 同步采用完整官方树加三方适配的学习版补丁，提交保留两端祖先，不改写 build 8 历史。

## 保留的学习版功能

独立 Bundle/扩展/App Group/iCloud 身份、无 App Group 的沙盒回退与启动保护、Application Support/environment 的 rootfs 路径及旧路径迁移回退、Files 交换目录、System Share 备份目的地、显式 UIDocumentPicker 的备份文件/文件夹选择修复。

## 新增：Codex 版本号

在 ChatGPT OAuth 供应商详情中设置；默认继承官方内置值 `0.159.0`。支持保存、恢复默认、版本格式校验（含 beta/构建后缀）。

- 作用于模型发现的 client_version/User-Agent、两条推理请求路径的 Version/User-Agent 和额度查询。
- 推理按请求读取设置，正在使用的会话下一次请求即可使用新值；已发出的请求不重写。
- 模型发现与离线回退缓存按有效版本区分；编辑触发刷新，旧版本在途响应不覆盖新目录。
- 登录凭据、手动模型、模型组不因编辑版本号被删除。
- 可选字段兼容旧配置；JSON备份、供应商单项导入导出均保留它。SQLite 使用既有 extras_json，同步透传且不增加数据库 schema 迁移。
- 版本号只解决客户端标识，不能授予账号权限或自动适配未来协议。

## 构建与验证

- `python3 scripts/verify_study_ios_identity.py`
- `python3 scripts/tests/study-codex/run.py --static-only`：本地接线/补丁回归。
- `python3 scripts/tests/study-codex/run.py`：Mac 上编译实际 ProviderInstance.swift；其他依赖全为隔离桩，不接触 Keychain/用户容器/网络。
- Mac CI 运行 CodexModelDiscoveryTests、GPT6SolLunaOpus55CatalogTests，并编译 Release IPA。
- 原生缓存包含 iSH revision 和 Go 源码，校验 FFmpeg.xcframework 与 libish_aot.a，防止沿用旧依赖。

公开源码缺少 AOJIT 预编译镜像；本构建允许使用官方占位库，不宣称达到商店版 AOJIT 加速。测试只使用合成数据；未用真实账号验证模型权限，也未进行真机/UI 实测。
