# JWT微服务项目 - 腾讯云自动部署脚本

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "JWT微服务项目 - 腾讯云自动部署" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# 配置信息
$serverHost = "tx.qsgl.net"
$serverUser = "root"
$sshKeyPath = "C:\Key\tx.qsgl.net_id_ed25519"
$projectName = "jwt-microservices"

# 检查SSH密钥是否存在
if (!(Test-Path $sshKeyPath)) {
    Write-Host "错误: SSH密钥文件不存在: $sshKeyPath" -ForegroundColor Red
    exit 1
}

Write-Host "步骤 1: 构建Docker镜像..." -ForegroundColor Yellow
docker-compose build
if ($LASTEXITCODE -ne 0) {
    Write-Host "构建失败!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Docker镜像构建完成" -ForegroundColor Green
Write-Host ""

Write-Host "步骤 2: 保存Docker镜像为tar文件..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$exportDir = ".\docker-images"
if (!(Test-Path $exportDir)) {
    New-Item -ItemType Directory -Path $exportDir | Out-Null
}

# 保存镜像
docker save jwt-authservice:latest -o "$exportDir\jwt-authservice.tar"
docker save jwt-apigateway:latest -o "$exportDir\jwt-apigateway.tar"
docker save jwt-orderservice:latest -o "$exportDir\jwt-orderservice.tar"

Write-Host "✓ Docker镜像已导出" -ForegroundColor Green
Write-Host ""

Write-Host "步骤 3: 创建部署包..." -ForegroundColor Yellow
$deployDir = ".\deploy-package"
if (Test-Path $deployDir) {
    Remove-Item -Recurse -Force $deployDir
}
New-Item -ItemType Directory -Path $deployDir | Out-Null

# 复制必要文件
Copy-Item "docker-compose.yml" "$deployDir\"
Copy-Item "$exportDir\*.tar" "$deployDir\"

# 创建远程部署脚本
$remoteDeployScript = @"
#!/bin/bash
set -e

echo "========================================="
echo "JWT微服务项目 - 远程部署"
echo "========================================="
echo ""

PROJECT_DIR="/opt/jwt-microservices"

# 创建项目目录
echo "步骤 1: 创建项目目录..."
mkdir -p `$PROJECT_DIR
cd `$PROJECT_DIR

# 停止并删除旧容器
echo "步骤 2: 停止旧容器..."
docker-compose down 2>/dev/null || true

# 删除旧镜像
echo "步骤 3: 清理旧镜像..."
docker rmi jwt-authservice:latest 2>/dev/null || true
docker rmi jwt-apigateway:latest 2>/dev/null || true
docker rmi jwt-orderservice:latest 2>/dev/null || true

# 加载新镜像
echo "步骤 4: 加载Docker镜像..."
docker load -i jwt-authservice.tar
docker load -i jwt-apigateway.tar
docker load -i jwt-orderservice.tar

# 启动服务
echo "步骤 5: 启动服务..."
docker-compose up -d

# 等待服务启动
echo "步骤 6: 等待服务启动..."
sleep 10

# 检查服务状态
echo "步骤 7: 检查服务状态..."
docker-compose ps

echo ""
echo "========================================="
echo "✓ 部署完成!"
echo "========================================="
echo ""
echo "服务访问地址:"
echo "  - 认证服务: http://tx.qsgl.net:5001/swagger"
echo "  - 订单服务: http://tx.qsgl.net:5002/swagger"
echo "  - API网关:   http://tx.qsgl.net:5005"
echo ""
"@

$remoteDeployScript | Out-File -FilePath "$deployDir\deploy.sh" -Encoding UTF8
Write-Host "✓ 部署包已创建" -ForegroundColor Green
Write-Host ""

Write-Host "步骤 4: 连接到腾讯云服务器..." -ForegroundColor Yellow
Write-Host "服务器: $serverHost" -ForegroundColor Gray

# 创建本地部署脚本
$localDeployScript = @"
# 上传文件到服务器
Write-Host "上传部署文件到服务器..." -ForegroundColor Yellow
scp -i "$sshKeyPath" -r "$deployDir\*" ${serverUser}@${serverHost}:/tmp/jwt-deploy/

# 在服务器上执行部署
Write-Host "在服务器上执行部署..." -ForegroundColor Yellow
ssh -i "$sshKeyPath" ${serverUser}@${serverHost} @"
    mkdir -p /opt/jwt-microservices
    cd /opt/jwt-microservices
    cp /tmp/jwt-deploy/* .
    chmod +x deploy.sh
    ./deploy.sh
"@

Write-Host ""
Write-Host "即将执行以下操作:" -ForegroundColor Yellow
Write-Host "1. 上传Docker镜像到服务器" -ForegroundColor White
Write-Host "2. 上传docker-compose.yml配置文件" -ForegroundColor White
Write-Host "3. 在服务器上加载镜像并启动服务" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "是否继续部署? (Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "部署已取消" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "步骤 5: 上传文件到服务器..." -ForegroundColor Yellow

# 创建远程临时目录
ssh -i $sshKeyPath ${serverUser}@${serverHost} "mkdir -p /tmp/jwt-deploy"

# 上传文件
scp -i $sshKeyPath -r "$deployDir\*" ${serverUser}@${serverHost}:/tmp/jwt-deploy/

Write-Host "✓ 文件上传完成" -ForegroundColor Green
Write-Host ""

Write-Host "步骤 6: 在服务器上执行部署..." -ForegroundColor Yellow

# 执行远程部署
ssh -i $sshKeyPath ${serverUser}@${serverHost} @"
    mkdir -p /opt/jwt-microservices
    cd /opt/jwt-microservices
    cp /tmp/jwt-deploy/* .
    chmod +x deploy.sh
    ./deploy.sh
"@

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "✓ 部署成功完成!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "服务访问地址:" -ForegroundColor Yellow
Write-Host "  - 认证服务: http://tx.qsgl.net:5001/swagger" -ForegroundColor White
Write-Host "  - 订单服务: http://tx.qsgl.net:5002/swagger" -ForegroundColor White
Write-Host "  - API网关:   http://tx.qsgl.net:5005" -ForegroundColor White
Write-Host ""
Write-Host "管理命令:" -ForegroundColor Yellow
Write-Host "  查看日志: ssh -i $sshKeyPath ${serverUser}@${serverHost} 'cd /opt/jwt-microservices && docker-compose logs -f'" -ForegroundColor Gray
Write-Host "  重启服务: ssh -i $sshKeyPath ${serverUser}@${serverHost} 'cd /opt/jwt-microservices && docker-compose restart'" -ForegroundColor Gray
Write-Host "  停止服务: ssh -i $sshKeyPath ${serverUser}@${serverHost} 'cd /opt/jwt-microservices && docker-compose down'" -ForegroundColor Gray
Write-Host ""

# 清理本地临时文件
Write-Host "清理本地临时文件..." -ForegroundColor Gray
Remove-Item -Recurse -Force $exportDir -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $deployDir -ErrorAction SilentlyContinue
Write-Host "✓ 清理完成" -ForegroundColor Green
