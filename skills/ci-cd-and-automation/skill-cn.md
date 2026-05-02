---
name: ci-cd-and-automation
description: 自动化 CI/CD 管道设置。在设置或修改构建和部署管道时使用。需要自动化质量门、在 CI 中配置测试运行程序或建立部署策略时使用。
---

# CI/CD 和自动化

## 概述

自动化质量门，使任何更改在没有通过测试、lint、类型检查和构建的情况下都无法到达生产环境。CI/CD 是每个其他技能的执行机制——它捕获人类和代理遗漏的内容，并且在每一次更改中一致地这样做。

**左移（Shift Left）：** 在管道中尽可能早地捕获问题。在 lint 中捕获的错误花费几分钟；在生产中捕获的相同错误花费几小时。将检查向上游移动——测试之前的静态分析，登台之前的测试，生产之前的登台。

**更快更安全：** 更小的批次和更频繁的发布降低风险，而不是增加风险。包含 3 个更改的部署比包含 30 个更改的部署更容易调试。频繁的发布建立对发布过程本身的信心。

## 使用场景

- 设置新项目的 CI 管道
- 添加或修改自动化检查
- 配置部署管道
- 当更改应触发自动化验证时
- 调试 CI 失败

## 质量门管道

每个更改在合并前都通过这些门：

```
拉取请求已打开
    │
    ▼
┌─────────────────┐
│   LINT 检查     │  eslint, prettier
│   ↓ 通过         │
│   类型检查       │  tsc --noEmit
│   ↓ 通过         │
│   单元测试       │  jest/vitest
│   ↓ 通过         │
│   构建          │  npm run build
│   ↓ 通过         │
│   集成测试       │  API/DB 测试
│   ↓ 通过         │
│   E2E（可选）   │  Playwright/Cypress
│   ↓ 通过         │
│   安全审计       │  npm audit
│   ↓ 通过         │
│   打包大小       │  bundlesize 检查
└─────────────────┘
    │
    ▼
  准备审查
```

**不能跳过任何门。** 如果 lint 失败，修复 lint——不要禁用规则。如果测试失败，修复代码——不要跳过测试。

## GitHub Actions 配置

### 基本 CI 管道

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'

      - name: 安装依赖
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: 类型检查
        run: npx tsc --noEmit

      - name: 测试
        run: npm test -- --coverage

      - name: 构建
        run: npm run build

      - name: 安全审计
        run: npm audit --audit-level=high
```

### 带数据库集成测试

```yaml
  integration:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_DB: testdb
          POSTGRES_USER: ci_user
          POSTGRES_PASSWORD: ${{ secrets.CI_DB_PASSWORD }}
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - name: 运行迁移
        run: npx prisma migrate deploy
        env:
          DATABASE_URL: postgresql://ci_user:${{ secrets.CI_DB_PASSWORD }}@localhost:5432/testdb
      - name: 集成测试
        run: npm run test:integration
        env:
          DATABASE_URL: postgresql://ci_user:${{ secrets.CI_DB_PASSWORD }}@localhost:5432/testdb
```

> **注意：** 即使对于仅用于 CI 的测试数据库，也要使用 GitHub Secrets 存储凭据，而不是硬编码值。这培养了良好的习惯，并防止在其他上下文中意外重用测试凭据。

### E2E 测试

```yaml
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - name: 安装 Playwright
        run: npx playwright install --with-deps chromium
      - name: 构建
        run: npm run build
      - name: 运行 E2E 测试
        run: npx playwright test
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-report
          path: playwright-report/
```

## 将 CI 失败反馈给代理

AI 代理与 CI 的强大之处在于反馈循环。当 CI 失败时：

```
CI 失败
    │
    ▼
复制失败输出
    │
    ▼
将其提供给代理：
"CI 管道失败，错误如下：
[粘贴特定错误]
在再次推送之前修复问题并在本地验证。"
    │
    ▼
代理修复 → 推送 → CI 再次运行
```

**关键模式：**

```
Lint 失败 → 代理运行 `npm run lint --fix` 并提交
类型错误 → 代理读取错误位置并修复类型
测试失败 → 代理遵循 debugging-and-error-recovery 技能
构建错误 → 代理检查配置和依赖项
```

## 部署策略

### 预览部署

每个 PR 都获得一个用于手动测试的预览部署：

```yaml
# 在 PR 上部署预览 (Vercel/Netlify/etc.)
deploy-preview:
  runs-on: ubuntu-latest
  if: github.event_name == 'pull_request'
  steps:
    - uses: actions/checkout@v4
    - name: 部署预览
      run: npx vercel --token=${{ secrets.VERCEL_TOKEN }}
```

### 功能标志

功能标志将部署与发布解耦。在标志后面部署不完整或有风险的功能，以便你可以：

- **在不启用的情况下发布代码。** 尽早合并到 main，准备就绪时启用。
- **在不重新部署的情况下回滚。** 禁用标志而不是还原代码。
- **金丝雀发布新功能。** 为 1% 的用户启用，然后 10%，然后 100%。
- **运行 A/B 测试。** 比较有和没有该功能的行为。

```typescript
// 简单功能标志模式
if (featureFlags.isEnabled('new-checkout-flow', { userId })) {
  return renderNewCheckout();
}
return renderLegacyCheckout();
```

**标志生命周期：** 创建 → 启用测试 → 金丝雀 → 完全推出 → 删除标志和死代码。永远存在的标志成为技术债务——创建它们时设置清理日期。

### 分阶段推出

```
PR 合并到 main
    │
    ▼
  登台部署（自动）
    │ 手动验证
    ▼
  生产部署（手动触发或登台后自动）
    │
    ▼
  监控错误（15 分钟窗口）
    │
    ├── 检测到错误 → 回滚
    └── 干净 → 完成
```

### 回滚计划

每个部署都应该是可逆的：

```yaml
# 手动回滚工作流
name: Rollback
on:
  workflow_dispatch:
    inputs:
      version:
        description: '要回滚到的版本'
        required: true

jobs:
  rollback:
    runs-on: ubuntu-latest
    steps:
      - name: 回滚部署
        run: |
          # 部署指定的先前版本
          npx vercel rollback ${{ inputs.version }}
```

## 环境管理

```
.env.example       → 已提交（开发者的模板）
.env                → 不提交（本地开发）
.env.test           → 已提交（测试环境，无真实秘密）
CI secrets          → 存储在 GitHub Secrets / 保险库中
生产 secrets  → 存储在部署平台 / 保险库中
```

CI 永远不应该有生产秘密。对 CI 测试使用单独的秘密。

## 超越 CI 的自动化

### Dependabot / Renovate

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: npm
    directory: /
    schedule:
      interval: weekly
    open-pull-requests-limit: 5
```

### 构建管理员角色

指定负责保持 CI 绿色的人。当构建损坏时，构建管理员的任务是修复或还原——而不是导致损坏的人的更改。这防止了构建损坏累积，而每个人都假设别人会修复它。

### PR 检查

- **必需审查：** 合并前至少 1 个批准
- **必需状态检查：** CI 必须在合并前通过
- **分支保护：** 不允许对 main 进行强制推送
- **自动合并：** 如果所有检查通过并获批准，自动合并

## CI 优化

当管道超过 10 分钟时，按影响顺序应用这些策略：

```
缓慢的 CI 管道？
├── 缓存依赖项
│   └── 对 node_modules 使用 actions/cache 或 setup-node 缓存选项
├── 并行运行作业
│   └── 将 lint、类型检查、测试、构建拆分为单独的并行作业
├── 仅运行更改的内容
│   └── 使用路径过滤器跳过不相关的作业（例如，对仅文档的 PR 跳过 e2e）
├── 使用矩阵构建
│   └── 在多个运行程序之间分片测试套件
├── 优化测试套件
│   └── 从关键路径中删除缓慢的测试，改为按计划运行它们
└── 使用更大的运行程序
    └── GitHub 托管的大型运行程序或自托管用于 CPU 密集型构建
```

**示例：缓存和并行性**

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22', cache: 'npm' }
      - run: npm ci
      - run: npm run lint

  typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22', cache: 'npm' }
      - run: npm ci
      - run: npx tsc --noEmit

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22', cache: 'npm' }
      - run: npm ci
      - run: npm test -- --coverage
```

## 常见合理化理由

| 合理化理由 | 现实 |
|---|---|
| "CI 太慢" | 优化管道（见下面的 CI 优化），不要跳过它。5 分钟的管道防止数小时的调试。 |
| "这个更改微不足道，跳过 CI" | 微不足道的更改会破坏构建。CI 对微不足道的更改来说很快。 |
| "测试不稳定，只需重新运行" | 不稳定的测试掩盖了真正的错误并浪费大家的时间。修复不稳定性。 |
| "我们稍后添加 CI" | 没有 CI 的项目会累积损坏状态。在第一天就设置它。 |
| "手动测试就足够了" | 手动测试无法扩展且不可重复。尽可能自动化。 |

## 危险信号

- 项目中没有 CI 管道
- CI 失败被忽略或静音
- 测试在 CI 中被禁用以使管道通过
- 生产部署没有登台验证
- 没有回滚机制
- 秘密存储在代码或 CI 配置文件中（不是秘密管理器）
- 长 CI 时间没有优化工作

## 验证

设置或修改 CI 后：

- [ ] 所有质量门都存在（lint、类型、测试、构建、审计）
- [ ] 管道在每个 PR 和运行到 main 的推送上运行
- [ ] 失败阻止合并（配置了分支保护）
- [ ] CI 结果反馈到开发循环中
- [ ] 秘密存储在秘密管理器中，而不是代码中
- [ ] 部署有回滚机制
- [ ] 管道在 10 分钟内运行测试套件
