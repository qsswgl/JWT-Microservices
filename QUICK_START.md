# 🚀 快速参考卡片

## 一键启动

```powershell
# 方式1: 使用启动脚本（推荐）
.\start.ps1

# 方式2: 直接启动Docker Compose
docker-compose up -d

# 方式3: 查看帮助
Get-Content README.md
```

## 服务端口

| 服务 | 端口 | 用途 |
|------|------|------|
| API网关 | 5000 | 统一入口 |
| 认证服务 | 5001 | 登录、Token管理 |
| 订单服务 | 5002 | 订单CRUD |
| Redis | 6379 | 缓存、黑名单 |

## API快速测试

```powershell
# 1. 登录获取Token
$response = Invoke-RestMethod -Uri "http://localhost:5000/api/auth/login" -Method Post -ContentType "application/json" -Body '{"username":"admin","password":"admin123"}'
$token = $response.accessToken

# 2. 查询订单
Invoke-RestMethod -Uri "http://localhost:5000/api/orders" -Method Get -Headers @{"Authorization"="Bearer $token"}

# 3. 创建订单
Invoke-RestMethod -Uri "http://localhost:5000/api/orders" -Method Post -Headers @{"Authorization"="Bearer $token"} -ContentType "application/json" -Body '{"items":[{"productName":"商品","quantity":1,"price":99.99}]}'

# 4. 登出
Invoke-RestMethod -Uri "http://localhost:5000/api/auth/logout" -Method Post -Headers @{"Authorization"="Bearer $token"}
```

## 测试账号

| 用户 | 密码 | 角色 | 权限 |
|------|------|------|------|
| admin | admin123 | Admin, User | 全部权限 |
| zhangsan | pass123 | User | 自己的订单 |

## 常用命令

```powershell
# 查看日志
docker-compose logs -f

# 查看状态
docker-compose ps

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 运行测试
.\test-api.ps1

# 进入Redis
docker exec -it jwt-redis redis-cli
```

## 核心API

### 认证API
- `POST /api/auth/login` - 登录
- `POST /api/auth/refresh` - 刷新Token
- `POST /api/auth/logout` - 登出
- `GET /api/auth/me` - 获取当前用户

### 订单API
- `GET /api/orders` - 获取订单列表
- `GET /api/orders/{id}` - 获取订单详情
- `POST /api/orders` - 创建订单
- `PUT /api/orders/{id}/status` - 更新订单状态
- `DELETE /api/orders/{id}` - 删除订单（仅管理员）

## Swagger文档

- 认证服务: http://localhost:5001/swagger
- 订单服务: http://localhost:5002/swagger

## 故障排查

| 问题 | 解决方案 |
|------|----------|
| 端口被占用 | 修改docker-compose.yml或appsettings.json中的端口 |
| Redis连接失败 | 检查Redis容器是否运行: `docker ps` |
| Token验证失败 | 确保所有服务的JWT密钥一致 |
| 401错误 | 检查Token是否过期或已撤销 |
| 403错误 | 检查用户角色权限 |

## 项目结构速览

```
JWT/
├── src/
│   ├── ApiGateway/     → Ocelot网关
│   ├── AuthService/    → JWT认证
│   ├── OrderService/   → 示例微服务
│   └── Shared/         → 共享库
├── docker-compose.yml  → 容器编排
├── README.md           → 完整文档
├── start.ps1           → 启动脚本
└── test-api.ps1        → 测试脚本
```

## JWT配置要点

```json
{
  "Jwt": {
    "SecretKey": "至少32字符的密钥",
    "Issuer": "AuthService",
    "Audience": "ApiGateway"
  }
}
```

⚠️ **生产环境必须更换密钥并启用HTTPS！**

## Token生命周期

- **Access Token**: 30分钟
- **Refresh Token**: 7天
- **黑名单TTL**: Token剩余有效时间

## 文件清单

✅ JwtMicroservices.sln - 解决方案文件  
✅ docker-compose.yml - Docker编排  
✅ README.md - 完整文档  
✅ ARCHITECTURE.md - 架构设计  
✅ PROJECT_SUMMARY.md - 项目总结  
✅ start.ps1 - 启动脚本  
✅ test-api.ps1 - 测试脚本  
✅ postman_collection.json - Postman集合  
✅ .gitignore - Git配置  
✅ .dockerignore - Docker配置  

## 下一步

1. 阅读 `README.md` 了解详细信息
2. 运行 `.\start.ps1` 启动项目
3. 运行 `.\test-api.ps1` 执行测试
4. 访问 Swagger 文档探索API
5. 阅读 `ARCHITECTURE.md` 理解架构

---

**快速支持**: 查看 README.md 的"故障排查"章节  
**完整文档**: PROJECT_SUMMARY.md  
**架构设计**: ARCHITECTURE.md
