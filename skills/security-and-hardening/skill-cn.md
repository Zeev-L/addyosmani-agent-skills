---
name: security-and-hardening
description: 强化代码以抵御漏洞。在处理用户输入、身份验证、数据存储或外部集成时使用。在构建接受不可信数据、管理用户会话或与第三方服务交互的任何功能时使用。
---

# 安全与加固

## 概述#

安全优先的 Web 应用开发实践。将每个外部输入视为恶意的，每个秘密视为神圣的，每个授权检查视为强制性的。安全不是一个阶段 —— 它是触及用户数据、身份验证或外部系统的每一行代码的约束。

## 使用场景#

- 构建任何接受用户输入的内容
- 实现身份验证或授权
- 存储或传输敏感数据
- 与外部 API 或服务集成
- 添加文件上传、webhooks 或回调
- 处理支付或 PII 数据

## 三层边界系统#

### 始终执行（无例外）#

- **在所有外部输入** 在系统边界验证（API 路由、表单处理程序）
- **参数化所有数据库查询** —— 永远不要将用户输入连接到 SQL
- **编码输出** 以防止 XSS（使用框架自动转义，不要绕过它）
- **对所有外部通信使用 HTTPS**#
- **使用 bcrypt/scrypt/argon2 哈希密码**（永远不要存储明文）
- **设置安全标头**（CSP、HSTS、X-Frame-Options、X-Content-Type-Options）#
- **对会话使用 httpOnly、secure、sameSite cookie**#
- **在每次发布之前运行 `npm audit`**（或等效项）#

### 首先询问（需要人工批准）#

- 添加新的身份验证流或更改身份验证逻辑
- 存储新类别的敏感数据（PII、支付信息）
- 添加新的外部服务集成#
- 更改 CORS 配置#
- 添加文件上传处理程序#
- 修改速率限制或节流#
- 授予提升的权限或角色#

### 永远不要做#

- **永远不要将秘密** 提交到版本控制（API 密钥、密码、令牌）
- **永远不要记录敏感数据**（密码、令牌、完整信用卡号）
- **永远不要信任客户端验证** 作为安全边界#
- **永远不要为方便而禁用安全标头**#
- **永远不要将 `eval()` 或 `innerHTML`** 与用户提供的数据一起使用#
- **永远不要将会话存储在客户端可访问的存储中**（用于身份验证令牌的 localStorag）#
- **永远不要向用户暴露堆栈跟踪** 或内部错误详细信息#

## OWASP 前十名预防#

### 1. 注入（SQL、NoSQL、OS 命令）#

```typescript
// 坏：通过字符串连接的 SQL 注入
const query = `SELECT * FROM users WHERE id = '${userId}'`;

// 好：参数化查询
const user = await db.query('SELECT * FROM users WHERE id = $1', [userId]);

// 好：带有参数化输入的 ORM
const user = await prisma.user.findUnique({ where: { id: userId } });
```

### 2. 身份验证损坏#

```typescript
// 密码哈希
import { hash, compare } from 'bcrypt';

const SALT_ROUNDS = 12;
const hashedPassword = await hash(plaintext, SALT_ROUNDS);
const isValid = await compare(plaintext, hashedPassword);

// 会话管理
app.use(session({
  secret: process.env.SESSION_SECRET,  // 来自环境，不是代码
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,     // 通过 JavaScript 不可访问
    secure: true,       // 仅 HTTPS
    sameSite: 'lax',    // CSRF 保护
    maxAge: 24 * 60 * 60 * 1000,  // 24 小时
  },
}));
```

### 3. 跨站脚本（XSS）#

```typescript
// 坏：将用户输入作为 HTML 渲染
element.innerHTML = userInput;

// 好：使用框架自动转义（React 默认执行此操作）
return <div>{userInput}</div>;

// 如果你必须渲染 HTML，请首先净化
import DOMPurify from 'dompurify';
const clean = DOMPurify.sanitize(userInput);
```

### 4. 访问控制损坏#

```typescript
// 始终检查授权，而不仅仅是身份验证
app.patch('/api/tasks/:id', authenticate, async (req, res) => {
  const task = await taskService.findById(req.params.id);

  // 检查经过身份验证的用户是否拥有此资源
  if (task.ownerId !== req.user.id) {
    return res.status(403).json({
      error: { code: 'FORBIDDEN', message: 'Not authorized to modify this task' }
    });
  }

  // 继续更新
  const updated = await taskService.update(req.params.id, req.body);
  return res.json(updated);
});
```

### 5. 安全配置错误#

```typescript
// 安全标头（对 Express 使用 helmet）
import helmet from 'helmet';
app.use(helmet());

// 内容安全策略
app.use(helmet.contentSecurityPolicy({
  directives: {
    defaultSrc: ["'self'"],
    scriptSrc: ["'self'"],
    styleSrc: ["'self'", "'unsafe-inline'"],  // 尽可能收紧
    imgSrc: ["'self'", 'data:', 'https:'],
    connectSrc: ["'self'"],
  },
}));

// CORS —— 限制为已知源
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || 'http://localhost:3000',
  credentials: true,
}));
```

### 6. 敏感数据暴露#

```typescript
// 永远不要在 API 响应中返回敏感字段
function sanitizeUser(user: UserRecord): PublicUser {
  const { passwordHash, resetToken, ...publicFields } = user;
  return publicFields;
}

// 对秘密使用环境变量
const STRIPE_API_KEY = process.env.STRIPE_API_KEY;
if (!STRIPE_API_KEY) throw new Error('STRIPE_API_KEY not configured');
```

## 输入验证模式#

### 边界处的架构验证#

```typescript
import { z } from 'zod';

const CreateTaskSchema = z.object({
  title: z.string().min(1).max(200).trim(),
  description: z.string().max(2000).optional(),
  priority: z.enum(['low', 'medium', 'high']).default('medium'),
  dueDate: z.string().datetime().optional(),
});

// 在路由处理程序中验证
app.post('/api/tasks', async (req, res) => {
  const result = CreateTaskSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid input',
        details: result.error.flatten(),
      },
    });
  }
  // result.data 现在已类型化并已验证
  const task = await taskService.create(result.data);
  return res.status(201).json(task);
});
```

### 文件上传安全#

```typescript
// 限制文件类型和大小
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_SIZE = 5 * 1024 * 1024; // 5MB

function validateUpload(file: UploadedFile) {
  if (!ALLOWED_TYPES.includes(file.mimetype)) {
    throw new ValidationError('File type not allowed');
  }
  if (file.size > MAX_SIZE) {
    throw new ValidationError('File too large (max 5MB)');
  }
  // 不要信任文件扩展名 —— 如果关键，请检查幻数
}
```

## 分类 npm audit 结果#

并非所有审计发现都需要立即采取行动。使用此决策树：

```
npm audit 报告漏洞
├── 严重性：严重或高
│   ├── 你的应用中是否可访问易受攻击的代码？
│   │   ├── 是 --> 立即修复（更新、修补或替换依赖项）
│   │   └── 否（仅开发依赖项、未使用的代码路径）--> 很快修复，但不是阻止程序
│   └── 是否有修复可用？
│       ├── 是 --> 更新到已修补的版本
│       └── 否 --> 检查解决方法，考虑替换依赖项，或使用审查日期添加到允许列表
├── 严重性：中等
│   ├── 生产中可访问？--> 在下一个发布周期中修复
│   └── 仅开发？--> 方便时修复，在积压工作中跟踪
└── 严重性：低
    └── 定期依赖项更新期间跟踪并修复
```

**关键问题：**
- 在你的代码路径中是否实际调用了易受攻击的函数？
- 依赖项是运行时依赖项还是仅用于开发？
- 鉴于你的部署上下文，此漏洞是否可利用（例如，纯客户端应用中的服务器端漏洞）？

当你推迟修复时，请记录原因并设置审查日期。

## 速率限制#

```typescript
import rateLimit from 'express-rate-limit';

// 常规 API 速率限制
app.use('/api/', rateLimit({
  windowMs: 15 * 60 * 1000, // 15 分钟
  max: 100,                   // 每个窗口 100 个请求
  standardHeaders: true,
  legacyHeaders: false,
}));

// 身份验证端点的更严格限制
app.use('/api/auth/', rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,  // 每 15 分钟 10 次尝试
}));
```

## 秘密管理#

```
.env 文件：
  ├── .env.example  → 已提交（带有占位符值的模板）
  ├── .env          → 未提交（包含真实秘密）
  └── .env.local    → 未提交（本地替代项）

.gitignore 必须包含：
  .env
  .env.local
  .env.*.local
  *.pem
  *.key
```

**在提交之前始终检查：**
```bash
# 检查意外暂存的秘密
git diff --cached | grep -i "password\|secret\|api_key\|token"
```

## 安全审查清单#

```markdown
### 身份验证
- [ ] 使用 bcrypt/scrypt/argon2 哈希的密码（盐轮数 ≥ 12）
- [ ] 会话令牌是 httpOnly、secure、sameSite
- [ ] 登录具有速率限制
- [ ] 密码重置令牌过期

### 授权
- [ ] 每个端点都检查用户权限
- [ ] 用户只能访问自己的资源
- [ ] 管理员操作需要管理员角色验证

### 输入
- [ ] 所有用户输入都在边界处验证
- [ ] SQL 查询已参数化
- [ ] HTML 输出已编码/转义

### 数据
- [ ] 代码或版本控制中没有秘密
- [ ] API 响应中排除的敏感字段
- [ ] PII 在静态时加密（如果适用）

### 基础设施
- [ ] 已配置安全标头（CSP、HSTS 等）
- [ ] CORS 限制为已知源
- [ ] 依赖项已审计漏洞
- [ ] 错误消息不会暴露内部信息
```

## 另见#

有关详细的安全检查表和提交前验证步骤，请参见 `references/security-checklist.md`。

## 常见合理化理由#

| 合理化理由 | 现实 |
|---|---|
| "这是内部工具，安全不重要" | 内部工具会被入侵。攻击者以最薄弱的环节为目标。 |
| "我们稍后添加安全" | 安全改造比内置它难 10 倍。现在就添加它。 |
| "没有人会尝试利用这一点" | 自动化扫描程序会发现它。通过模糊性实现安全不是安全。 |
| "框架处理安全性" | 框架提供工具，而不是保证。你仍然需要正确使用它们。 |
| "这只是一个原型" | 原型会成为生产。从第一天开始的安全习惯。 |

## 危险信号#

- 用户输入直接传递到数据库查询、shell 命令或 HTML 渲染
- 源代码或提交历史记录中的秘密#
- 没有身份验证或授权检查的 API 端点
- 缺少 CORS 配置或通配符（`*`）源#
- 身份验证端点上没有速率限制#
- 向用户暴露的堆栈跟踪或内部错误#
- 具有已知严重漏洞的依赖项#

## 验证#

实现安全相关代码后：

- [ ] `npm audit` 显示没有严重或高严重性漏洞#
- [ ] 源代码或 git 历史记录中没有秘密#
- [ ] 所有用户输入都在系统边界处验证#
- [ ] 在每个受保护的端点上检查和授权#
- [ ] 响应中存在安全标头（使用浏览器 DevTools 检查）
- [ ] 错误响应不会暴露内部详细信息#
- [ ] 身份验证端点上的速率限制处于活动状态#
