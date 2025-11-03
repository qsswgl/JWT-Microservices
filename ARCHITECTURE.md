# JWT微服务架构详细设计

## 系统架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                           客户端应用                              │
│                  (Web浏览器/移动应用/桌面应用)                     │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTPS
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API网关 (Ocelot)                            │
│                         端口: 5000                               │
├─────────────────────────────────────────────────────────────────┤
│ 职责:                                                            │
│ 1. 请求路由和转发                                                │
│ 2. JWT Token验证 (验证签名、过期时间、Issuer/Audience)           │
│ 3. Token黑名单检查 (查询Redis)                                   │
│ 4. 基于角色的权限控制                                            │
│ 5. 请求限流 (100请求/分钟)                                       │
│ 6. 添加用户信息到请求头 (X-User-Id, X-User-Roles等)              │
│ 7. 请求日志记录                                                  │
└───────┬──────────────┬──────────────────────────┬───────────────┘
        │              │                          │
        │              │                          │
        ▼              ▼                          ▼
┌───────────────┐ ┌────────────────┐    ┌─────────────────┐
│  认证服务     │ │   订单服务      │    │  其他微服务      │
│  端口: 5001   │ │   端口: 5002   │    │  端口: 500x     │
├───────────────┤ ├────────────────┤    ├─────────────────┤
│ • 用户登录    │ │ • 订单CRUD     │    │ • 业务功能      │
│ • Token生成   │ │ • 权限控制     │    │ • 数据处理      │
│ • Token刷新   │ │ • 数据隔离     │    │ • API暴露       │
│ • 用户登出    │ │ • 业务逻辑     │    │                 │
│ • Token撤销   │ └────────────────┘    └─────────────────┘
└───────┬───────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Redis缓存层                              │
│                         端口: 6379                               │
├─────────────────────────────────────────────────────────────────┤
│ 存储内容:                                                        │
│ 1. Token黑名单 (key: revoked_token:{jti}, ttl: Token剩余有效期) │
│ 2. Token验证缓存 (可选，提升性能)                                │
│ 3. 用户会话信息 (可选)                                           │
└─────────────────────────────────────────────────────────────────┘
```

## 数据流详解

### 1. 登录流程

```
┌────────┐    1. POST /api/auth/login    ┌──────────┐
│ 客户端  │ ──────────────────────────▶ │ API网关   │
└────────┘    {username, password}       └─────┬────┘
                                               │ 2. 转发
                                               ▼
                                        ┌──────────┐
                                        │ 认证服务  │
                                        └─────┬────┘
                                              │ 3. 验证凭证
                                              │ 4. 查询用户信息
                                              │ 5. 生成JWT
                                              ▼
┌────────┐    6. 返回Token              ┌──────────┐
│ 客户端  │ ◀────────────────────────── │ API网关   │
└────────┘    {accessToken,             └──────────┘
              refreshToken,
              expiresIn: 1800}
```

**JWT Token结构:**
```
Header:
{
  "alg": "HS256",
  "typ": "JWT"
}

Payload:
{
  "sub": "user123",              // 用户ID
  "jti": "unique-token-id",      // Token唯一标识
  "name": "admin",               // 用户名
  "role": "Admin,User",          // 角色
  "permissions": "[...]",        // 权限列表
  "iat": 1699000000,            // 签发时间
  "exp": 1699001800,            // 过期时间 (30分钟后)
  "iss": "AuthService",         // 签发者
  "aud": "ApiGateway"           // 受众
}

Signature:
HMACSHA256(
  base64UrlEncode(header) + "." + base64UrlEncode(payload),
  "your-secret-key"
)
```

### 2. 访问受保护API流程

```
┌────────┐    1. GET /api/orders          ┌──────────┐
│ 客户端  │ ──────────────────────────▶   │ API网关   │
└────────┘    Authorization:               └─────┬────┘
              Bearer eyJhbGc...                  │
                                                 │ 2. 提取Token
                                                 │ 3. 验证签名
                                                 │ 4. 验证过期时间
                                                 │ 5. 检查黑名单
                                                 ▼
                                          ┌──────────┐
                                          │  Redis   │
                                          └─────┬────┘
                                                │ 6. Token未撤销
                                                ▼
┌────────┐    10. 返回订单数据            ┌──────────┐
│ 客户端  │ ◀────────────────────────── │ API网关   │
└────────┘    [{order1}, {order2}]       └─────┬────┘
                                               │ 7. 添加Header
                                               │    X-User-Id: user123
                                               │    X-User-Roles: Admin,User
                                               ▼
                                        ┌──────────┐
                                        │ 订单服务  │
                                        └─────┬────┘
                                              │ 8. 从Header获取用户信息
                                              │ 9. 执行业务逻辑
                                              │    (权限检查、数据过滤)
                                              ▼
                                           返回数据
```

### 3. Token刷新流程

```
┌────────┐    1. POST /api/auth/refresh   ┌──────────┐
│ 客户端  │ ──────────────────────────▶   │ API网关   │
└────────┘    {refreshToken}               └─────┬────┘
                                                  │ 2. 转发
                                                  ▼
                                           ┌──────────┐
                                           │ 认证服务  │
                                           └─────┬────┘
                                                 │ 3. 验证RefreshToken
                                                 │ 4. 提取用户ID
                                                 │ 5. 查询用户最新信息
                                                 │ 6. 生成新AccessToken
                                                 ▼
┌────────┐    7. 返回新Token               ┌──────────┐
│ 客户端  │ ◀────────────────────────────  │ API网关   │
└────────┘    {accessToken,                └──────────┘
              expiresIn: 1800}
```

### 4. 登出流程 (Token撤销)

```
┌────────┐    1. POST /api/auth/logout     ┌──────────┐
│ 客户端  │ ──────────────────────────▶    │ API网关   │
└────────┘    Authorization:                └─────┬────┘
              Bearer eyJhbGc...                   │ 2. 验证Token
                                                  │ 3. 转发
                                                  ▼
                                           ┌──────────┐
                                           │ 认证服务  │
                                           └─────┬────┘
                                                 │ 4. 提取JTI和过期时间
                                                 │ 5. 计算TTL
                                                 ▼
                                           ┌──────────┐
                                           │  Redis   │
                                           └─────┬────┘
                                                 │ 6. 添加到黑名单
                                                 │    SET revoked_token:{jti}
                                                 │    EX {ttl_seconds}
                                                 ▼
┌────────┐    7. 返回成功                  ┌──────────┐
│ 客户端  │ ◀────────────────────────────  │ API网关   │
└────────┘    {message: "登出成功"}        └──────────┘

Note: 之后使用该Token的请求将在步骤5被拒绝
```

## 安全机制详解

### 1. Token验证步骤 (API网关)

```csharp
// 伪代码展示验证过程
public async Task<bool> ValidateToken(string token)
{
    // 步骤1: 验证Token格式
    if (!IsValidJwtFormat(token))
        return false;

    // 步骤2: 验证签名
    if (!VerifySignature(token, secretKey))
        return false;

    // 步骤3: 验证Issuer和Audience
    if (token.Issuer != "AuthService" || token.Audience != "ApiGateway")
        return false;

    // 步骤4: 验证过期时间
    if (token.Expiration < DateTime.UtcNow)
        return false;

    // 步骤5: 检查黑名单
    var jti = GetJti(token);
    if (await redis.ExistsAsync($"revoked_token:{jti}"))
        return false;

    // 步骤6: (可选) 检查缓存的验证结果
    var cacheKey = $"token_validated:{Hash(token)}";
    if (await redis.GetAsync(cacheKey) != null)
        return true;

    // 步骤7: 缓存验证结果 (5分钟)
    await redis.SetAsync(cacheKey, "valid", TimeSpan.FromMinutes(5));

    return true;
}
```

### 2. 权限控制机制

**层级1: API网关层 (Ocelot配置)**
```json
{
  "RouteClaimsRequirement": {
    "Role": "Admin,User"  // 必须拥有Admin或User角色
  }
}
```

**层级2: 微服务层 (业务逻辑)**
```csharp
// 从网关转发的Header获取用户信息
var userId = Request.Headers["X-User-Id"];
var roles = Request.Headers["X-User-Roles"].ToString().Split(',');

// 业务级权限控制
if (operation == "delete" && !roles.Contains("Admin"))
{
    return Forbid(); // 403
}

// 数据隔离
if (!roles.Contains("Admin"))
{
    // 普通用户只能访问自己的数据
    orders = orders.Where(o => o.UserId == userId);
}
```

### 3. 限流机制

**配置:**
```json
{
  "RateLimitOptions": {
    "EnableRateLimiting": true,
    "Period": "1m",           // 时间窗口: 1分钟
    "PeriodTimespan": 60,     // 60秒
    "Limit": 100              // 最多100个请求
  }
}
```

**实现原理:**
- 使用滑动窗口算法
- 基于客户端IP或用户ID限流
- 超过限制返回 429 Too Many Requests

## 性能优化策略

### 1. Token验证缓存

```
首次验证: 50ms (完整验证)
缓存命中: 2ms  (Redis查询)
性能提升: 25倍
```

### 2. Redis连接池

```csharp
// 使用连接复用
builder.Services.AddSingleton<IConnectionMultiplexer>(
    ConnectionMultiplexer.Connect(redisConnection)
);
```

### 3. 异步操作

所有I/O操作使用async/await，避免线程阻塞。

## 扩展性设计

### 1. 水平扩展

```
          负载均衡器
               │
    ┌──────────┼──────────┐
    ▼          ▼          ▼
  网关1      网关2      网关3
    │          │          │
    └──────────┼──────────┘
               │
          ┌────┴────┐
          │  Redis  │
          └─────────┘
```

### 2. 微服务独立部署

每个服务可以独立:
- 部署到不同服务器
- 使用不同的数据库
- 独立扩展
- 独立版本控制

### 3. 服务发现 (未来扩展)

可以集成Consul或Eureka实现动态服务发现。

## 监控和日志

### 请求追踪

每个请求生成唯一ID，贯穿整个调用链:

```
Request-Id: abc-def-ghi
[Gateway] 接收请求: abc-def-ghi
[AuthService] 处理登录: abc-def-ghi
[Gateway] 转发响应: abc-def-ghi
```

### 关键指标监控

- Token生成速率
- Token验证失败率
- API响应时间
- 限流触发次数
- Redis连接状态

## 生产环境部署清单

- [ ] 更换强随机JWT密钥
- [ ] 启用HTTPS
- [ ] 配置防火墙规则
- [ ] 设置Redis密码
- [ ] 启用日志收集
- [ ] 配置监控告警
- [ ] 备份Redis数据
- [ ] 设置自动重启策略
- [ ] 配置健康检查
- [ ] 文档API速率限制

## 常见问题

**Q: Token泄露怎么办?**
A: 用户登出会立即撤销Token，或等待Token自然过期(30分钟)。

**Q: 如何应对高并发?**
A: 水平扩展网关，Redis使用集群模式。

**Q: Token过期后用户体验?**
A: 前端应自动使用RefreshToken刷新AccessToken。

**Q: 如何处理跨域?**
A: 在API网关配置CORS策略。
