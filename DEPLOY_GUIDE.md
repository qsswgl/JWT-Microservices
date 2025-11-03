# 🚀 腾讯云部署指南

## 服务器信息

- **服务器地址**: tx.qsgl.net
- **操作系统**: Ubuntu
- **用户**: root
- **SSH密钥**: C:\Key\tx.qsgl.net_id_ed25519

## 快速部署

### 方式1：一键部署（推荐）

```powershell
# 完整部署（构建 + 上传 + 启动）
.\deploy-quick.ps1

# 跳过构建，直接部署已有镜像
.\deploy-quick.ps1 -SkipBuild
```

### 方式2：详细部署

```powershell
.\deploy-to-tencent.ps1
```

## 部署步骤说明

### 自动执行的操作：

1. **检查SSH连接** - 验证服务器可访问性
2. **构建Docker镜像** - 在本地构建所有服务镜像
3. **导出镜像** - 将Docker镜像保存为tar文件
4. **上传到服务器** - 通过SCP上传镜像和配置文件
5. **远程部署** - 在服务器上加载镜像并启动容器
6. **清理临时文件** - 删除本地和远程的临时文件

## 手动部署步骤

如果自动部署失败，可以手动执行：

### 1. 本地构建和导出

```powershell
# 构建镜像
docker-compose build

# 导出镜像
docker save jwt-authservice:latest -o authservice.tar
docker save jwt-apigateway:latest -o apigateway.tar
docker save jwt-orderservice:latest -o orderservice.tar
```

### 2. 上传到服务器

```powershell
# 使用SCP上传
scp -i "C:\Key\tx.qsgl.net_id_ed25519" *.tar root@tx.qsgl.net:/opt/jwt-microservices/
scp -i "C:\Key\tx.qsgl.net_id_ed25519" docker-compose.yml root@tx.qsgl.net:/opt/jwt-microservices/
```

### 3. 在服务器上部署

```bash
# SSH登录到服务器
ssh -i "C:\Key\tx.qsgl.net_id_ed25519" root@tx.qsgl.net

# 进入项目目录
cd /opt/jwt-microservices

# 停止旧容器
docker-compose down

# 加载镜像
docker load -i authservice.tar
docker load -i apigateway.tar
docker load -i orderservice.tar

# 启动服务
docker-compose up -d

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

## 服务管理

### 查看服务状态

```powershell
ssh -i "C:\Key\tx.qsgl.net_id_ed25519" root@tx.qsgl.net "cd /opt/jwt-microservices && docker-compose ps"
```

### 查看服务日志

```powershell
# 查看所有服务日志
ssh -i "C:\Key\tx.qsgl.net_id_ed25519" root@tx.qsgl.net "cd /opt/jwt-microservices && docker-compose logs -f"

# 查看特定服务日志
ssh -i "C:\Key\tx.qsgl.net_id_ed25519" root@tx.qsgl.net "cd /opt/jwt-microservices && docker-compose logs -f authservice"
```

### 重启服务

```powershell
# 重启所有服务
ssh -i "C:\Key\tx.qsgl.net_id_ed25519" root@tx.qsgl.net "cd /opt/jwt-microservices && docker-compose restart"

# 重启特定服务
ssh -i "C:\Key\tx.qsgl.net_id_ed25519" root@tx.qsgl.net "cd /opt/jwt-microservices && docker-compose restart authservice"
```

### 停止服务

```powershell
ssh -i "C:\Key\tx.qsgl.net_id_ed25519" root@tx.qsgl.net "cd /opt/jwt-microservices && docker-compose down"
```

### 更新服务

```powershell
# 重新部署
.\deploy-quick.ps1
```

## 服务访问

部署成功后，可以通过以下地址访问：

- **认证服务 Swagger**: http://tx.qsgl.net:6001/swagger
- **订单服务 Swagger**: http://tx.qsgl.net:6002/swagger
- **API网关**: http://tx.qsgl.net:6005

> ⚠️ **端口说明**: 为避免与服务器现有服务冲突，端口已调整：
> - AuthService: 6001 (原5001)
> - OrderService: 6002 (原5002，避开envoy-proxy)
> - ApiGateway: 6005 (原5005)

## 测试部署

### 1. 测试认证服务

```powershell
# 登录
$response = Invoke-RestMethod -Uri "http://tx.qsgl.net:5001/api/auth/login" `
    -Method Post `
    -ContentType "application/json" `
    -Body '{"username":"admin","password":"admin123"}'

$token = $response.accessToken
Write-Host "Token获取成功: $($token.Substring(0,50))..."
```

### 2. 测试订单服务

```powershell
# 获取订单
$orders = Invoke-RestMethod -Uri "http://tx.qsgl.net:5002/api/orders" `
    -Method Get `
    -Headers @{
        "Authorization" = "Bearer $token"
        "X-User-Id" = "user123"
        "X-User-Roles" = "Admin,User"
    }

Write-Host "订单数量: $($orders.Count)"
```

## 服务器环境要求

### 必需软件

- Docker (>= 20.10)
- Docker Compose (>= 2.0)

### 安装Docker（如果未安装）

```bash
# 更新包索引
sudo apt-get update

# 安装必要的包
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# 添加Docker官方GPG密钥
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# 添加Docker仓库
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# 安装Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# 安装Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 验证安装
docker --version
docker-compose --version
```

## 防火墙配置

确保以下端口已开放：

```bash
# 开放端口
sudo ufw allow 5001/tcp  # 认证服务
sudo ufw allow 5002/tcp  # 订单服务
sudo ufw allow 5005/tcp  # API网关
sudo ufw allow 6379/tcp  # Redis（仅内部访问）

# 查看防火墙状态
sudo ufw status
```

## 故障排查

### 问题1: SSH连接失败

```powershell
# 测试连接
ssh -i "C:\Key\tx.qsgl.net_id_ed25519" root@tx.qsgl.net "echo 'Connection OK'"

# 检查密钥权限（Windows）
icacls "C:\Key\tx.qsgl.net_id_ed25519" /inheritance:r /grant:r "$env:USERNAME:(R)"
```

### 问题2: Docker镜像加载失败

```bash
# 检查磁盘空间
df -h

# 清理未使用的镜像
docker system prune -a

# 重新加载镜像
docker load -i authservice.tar
```

### 问题3: 容器启动失败

```bash
# 查看详细日志
docker-compose logs authservice

# 检查容器状态
docker-compose ps

# 重启容器
docker-compose restart authservice
```

### 问题4: 端口被占用

```bash
# 查看端口占用
netstat -tulpn | grep :5001

# 停止占用端口的进程
kill -9 <PID>
```

## 性能监控

### 查看资源使用

```bash
# 查看容器资源使用
docker stats

# 查看系统资源
top
htop
```

### 查看容器日志大小

```bash
# 查看日志大小
docker-compose logs authservice 2>&1 | wc -l

# 限制日志大小（在docker-compose.yml中配置）
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

## 备份和恢复

### 备份Redis数据

```bash
# 备份Redis数据
docker-compose exec redis redis-cli SAVE
docker cp jwt-redis:/data/dump.rdb ./backup/dump.rdb
```

### 恢复Redis数据

```bash
# 恢复Redis数据
docker cp ./backup/dump.rdb jwt-redis:/data/dump.rdb
docker-compose restart redis
```

## 安全建议

1. **更改默认密码**: 修改测试账号密码
2. **配置HTTPS**: 使用Nginx反向代理配置SSL证书
3. **限制访问**: 配置防火墙规则，只允许必要的IP访问
4. **定期更新**: 定期更新Docker镜像和系统包
5. **监控日志**: 设置日志监控和告警

## 常用命令快速参考

```powershell
# 部署
.\deploy-quick.ps1

# 查看状态
ssh -i "C:\Key\tx.qsgl.net_id_ed25519" root@tx.qsgl.net "cd /opt/jwt-microservices && docker-compose ps"

# 查看日志
ssh -i "C:\Key\tx.qsgl.net_id_ed25519" root@tx.qsgl.net "cd /opt/jwt-microservices && docker-compose logs -f"

# 重启服务
ssh -i "C:\Key\tx.qsgl.net_id_ed25519" root@tx.qsgl.net "cd /opt/jwt-microservices && docker-compose restart"

# 停止服务
ssh -i "C:\Key\tx.qsgl.net_id_ed25519" root@tx.qsgl.net "cd /opt/jwt-microservices && docker-compose down"
```

---

**注意**: 首次部署可能需要较长时间，因为需要下载基础镜像。后续部署会快很多。
