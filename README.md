# JWT配合API网关实现微服务架构API授权解决方案

[![.NET](https://img.shields.io/badge/.NET-8.0-blue.svg)](https://dotnet.microsoft.com/)
[![Ocelot](https://img.shields.io/badge/Ocelot-23.0.0-green.svg)](https://github.com/ThreeMammals/Ocelot)
[![Redis](https://img.shields.io/badge/Redis-7--alpine-red.svg)](https://redis.io/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-qsswgl%2FJWT--Microservices-black.svg)](https://github.com/qsswgl/JWT-Microservices)

这是一个完整的基于JWT和API网关的微服务认证授权解决方案，使用.NET 8和Ocelot实现。

🌐 **GitHub 仓库**: https://github.com/qsswgl/JWT-Microservices

## 📋 项目架构

```
┌─────────────┐
│   客户端     │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────┐
│      API网关 (Ocelot)            │
│  - JWT Token验证                │
│  - 路由转发                      │
│  - 权限检查                      │
│  - 限流控制                      │
│  - Token黑名单检查               │
└────┬──────────────────┬─────────┘
     │                  │
     ▼                  ▼
┌──────────┐      ┌──────────┐
│认证服务   │      │订单服务   │
│- 登录     │      │- CRUD    │
│- Token生成│      │- 权限控制 │
│- 刷新     │      └──────────┘
│- 登出     │
└──────────┘
     │
     ▼
┌──────────┐
│  Redis   │
│- Token黑名单
│- 缓存     │
└──────────┘
```

## 🚀 核心功能

### 1. 认证服务 (AuthService) - 端口 5001
- ✅ 用户登录验证
- ✅ JWT Token生成（Access Token + Refresh Token）
- ✅ Token刷新机制
- ✅ 用户登出（Token撤销）
- ✅ 获取当前用户信息

### 2. API网关 (ApiGateway) - 端口 5000
- ✅ JWT Token验证
- ✅ 路由转发和负载均衡
- ✅ 基于角色的权限控制
- ✅ Token黑名单检查
- ✅ 请求限流（100请求/分钟）
- ✅ 请求日志记录
- ✅ 自动添加用户信息到请求头

### 3. 订单服务 (OrderService) - 端口 5002
- ✅ 订单CRUD操作
- ✅ 基于角色的权限控制
- ✅ 从网关Header获取用户信息
- ✅ 数据隔离（用户只能访问自己的订单）

### 4. Redis缓存 - 端口 6379
- ✅ Token黑名单存储
- ✅ 缓存验证结果
- ✅ 持久化支持

## 📦 技术栈

- **.NET 8.0** - 后端框架
- **Ocelot 23.0** - API网关
- **JWT Bearer Authentication** - 身份认证
- **Redis** - 缓存和Token黑名单
- **Swagger/OpenAPI** - API文档
- **Docker & Docker Compose** - 容器化部署

## 🛠️ 快速开始

### 方式一：使用Docker Compose（推荐）

1. **启动所有服务**
```powershell
docker-compose up -d
```

2. **查看服务状态**
```powershell
docker-compose ps
```

3. **查看日志**
```powershell
docker-compose logs -f
```

4. **停止服务**
```powershell
docker-compose down
```

### 方式二：本地运行

1. **安装Redis**
```powershell
# 使用Docker运行Redis
docker run -d -p 6379:6379 --name redis redis:7-alpine
```

2. **启动认证服务**
```powershell
cd src\AuthService
dotnet restore
dotnet run --urls "http://localhost:5001"
```

3. **启动订单服务**
```powershell
cd src\OrderService
dotnet restore
dotnet run --urls "http://localhost:5002"
```

4. **启动API网关**
```powershell
cd src\ApiGateway
dotnet restore
dotnet run --urls "http://localhost:5000"
```

## 📖 API文档

服务启动后，可以访问以下Swagger文档：

- **认证服务**: http://localhost:5001/swagger
- **订单服务**: http://localhost:5002/swagger
- **API网关**: http://localhost:5000 (通过网关访问所有服务)

## 🔐 测试流程

### 1. 用户登录

**请求：**
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123"
  }'
```

**响应：**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 1800,
  "tokenType": "Bearer"
}
```

### 2. 访问受保护的API

**请求：**
```bash
curl -X GET http://localhost:5000/api/orders \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**响应：**
```json
[
  {
    "id": 1,
    "orderNumber": "ORD-2025-001",
    "userId": "user123",
    "userName": "admin",
    "totalAmount": 299.99,
    "status": "Completed",
    "items": [...]
  }
]
```

### 3. 创建订单

**请求：**
```bash
curl -X POST http://localhost:5000/api/orders \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {
        "productName": "键盘",
        "quantity": 2,
        "price": 199.99
      }
    ]
  }'
```

### 4. 刷新Token

**请求：**
```bash
curl -X POST http://localhost:5000/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "YOUR_REFRESH_TOKEN"
  }'
```

### 5. 用户登出

**请求：**
```bash
curl -X POST http://localhost:5000/api/auth/logout \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## 👥 测试用户

系统预置了两个测试用户：

### 管理员用户
- **用户名**: `admin`
- **密码**: `admin123`
- **角色**: Admin, User
- **权限**: 所有订单的读写删除权限

### 普通用户
- **用户名**: `zhangsan`
- **密码**: `pass123`
- **角色**: User
- **权限**: 只能访问自己的订单

## 🔧 配置说明

### JWT配置

在 `appsettings.json` 中配置：

```json
{
  "Jwt": {
    "SecretKey": "your-super-secret-key-at-least-32-characters-long-for-security",
    "Issuer": "AuthService",
    "Audience": "ApiGateway"
  }
}
```

**注意**: 生产环境请使用更强的密钥，并通过环境变量或密钥管理服务配置。

### Ocelot路由配置

在 `src/ApiGateway/ocelot.json` 中配置路由规则：

```json
{
  "Routes": [
    {
      "DownstreamPathTemplate": "/api/orders/{everything}",
      "UpstreamPathTemplate": "/api/orders/{everything}",
      "AuthenticationOptions": {
        "AuthenticationProviderKey": "Bearer"
      },
      "RouteClaimsRequirement": {
        "Role": "Admin,User"
      },
      "RateLimitOptions": {
        "EnableRateLimiting": true,
        "Period": "1m",
        "Limit": 100
      }
    }
  ]
}
```

## 🔒 安全特性

1. **JWT签名验证** - 使用HMAC-SHA256算法签名
2. **Token过期控制** - Access Token 30分钟，Refresh Token 7天
3. **Token黑名单** - 支持Token撤销，登出后Token立即失效
4. **HTTPS强制** - 生产环境必须使用HTTPS
5. **密码加密** - 使用BCrypt加密存储密码
6. **请求限流** - 防止API滥用
7. **角色权限控制** - 细粒度的访问控制
8. **敏感信息保护** - JWT Payload不包含敏感数据

## 📊 工作流程

### 认证流程

```
1. 客户端 → API网关 → 认证服务: 发送登录请求
2. 认证服务: 验证用户凭证
3. 认证服务: 生成JWT Token (Access + Refresh)
4. 认证服务 → API网关 → 客户端: 返回Token
```

### 授权流程

```
1. 客户端 → API网关: 携带Token访问API
2. API网关: 验证Token签名和有效性
3. API网关: 检查Token是否在黑名单
4. API网关: 验证用户角色权限
5. API网关 → 微服务: 转发请求，添加用户信息Header
6. 微服务: 处理业务逻辑
7. 微服务 → API网关 → 客户端: 返回响应
```

## 🧪 测试脚本

运行测试脚本验证所有功能：

```powershell
# PowerShell
.\test-api.ps1
```

或手动测试：

```powershell
# 1. 管理员登录
$adminLogin = Invoke-RestMethod -Uri "http://localhost:5000/api/auth/login" -Method Post -ContentType "application/json" -Body '{"username":"admin","password":"admin123"}'
$adminToken = $adminLogin.accessToken

# 2. 获取订单列表
Invoke-RestMethod -Uri "http://localhost:5000/api/orders" -Method Get -Headers @{"Authorization"="Bearer $adminToken"}

# 3. 创建订单
Invoke-RestMethod -Uri "http://localhost:5000/api/orders" -Method Post -Headers @{"Authorization"="Bearer $adminToken"} -ContentType "application/json" -Body '{"items":[{"productName":"测试商品","quantity":1,"price":99.99}]}'

# 4. 登出
Invoke-RestMethod -Uri "http://localhost:5000/api/auth/logout" -Method Post -Headers @{"Authorization"="Bearer $adminToken"}
```

## 📁 项目结构

```
JWT/
├── src/
│   ├── ApiGateway/          # API网关
│   │   ├── Middleware/      # 中间件
│   │   ├── ocelot.json      # Ocelot配置
│   │   └── Program.cs
│   ├── AuthService/         # 认证服务
│   │   ├── Controllers/     # 控制器
│   │   ├── Services/        # 服务层
│   │   └── Program.cs
│   ├── OrderService/        # 订单服务（示例）
│   │   ├── Controllers/
│   │   ├── Models/
│   │   └── Program.cs
│   └── Shared/              # 共享库
│       ├── Models/          # 共享模型
│       └── Services/        # 共享服务
├── docker-compose.yml       # Docker编排
├── JwtMicroservices.sln     # 解决方案文件
└── README.md                # 本文档
```

## 🔍 故障排查

### 问题1: Token验证失败

**原因**: JWT密钥不一致
**解决**: 确保所有服务的 `Jwt:SecretKey` 配置相同

### 问题2: Redis连接失败

**原因**: Redis服务未启动
**解决**: 
```powershell
docker run -d -p 6379:6379 redis:7-alpine
```

### 问题3: 跨域问题

**解决**: 在API网关添加CORS配置
```csharp
builder.Services.AddCors(options => {
    options.AddDefaultPolicy(policy => {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});
```

## 📚 扩展功能

### 1. 添加新的微服务

1. 创建新服务项目
2. 在 `ocelot.json` 添加路由配置
3. 配置认证和权限要求
4. 在 `docker-compose.yml` 添加服务定义

### 2. 使用非对称加密 (RS256)

替换 `SymmetricSecurityKey` 为 `RsaSecurityKey`，提供更高的安全性。

### 3. 集成数据库

替换内存数据为真实数据库（SQL Server, PostgreSQL等）。

### 4. 添加监控和追踪

集成 Serilog, Application Insights 或 Prometheus。

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📄 许可证

MIT License

## 📞 联系方式

如有问题，请提交Issue或联系项目维护者。

---

**开发日期**: 2025年11月3日
**版本**: 1.0.0
