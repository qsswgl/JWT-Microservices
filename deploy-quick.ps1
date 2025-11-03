# JWT微服务项目 - 快速部署到腾讯云

param(
    [switch]$SkipBuild = $false
)

$ErrorActionPreference = "Stop"

# 配置
$SERVER = "tx.qsgl.net"
$USER = "root"
$KEY = "C:\Key\tx.qsgl.net_id_ed25519"
$REMOTE_DIR = "/opt/jwt-microservices"

Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  JWT微服务 - 腾讯云自动部署  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Cyan

# 检查SSH密钥
if (!(Test-Path $KEY)) {
    Write-Host "❌ SSH密钥不存在: $KEY" -ForegroundColor Red
    exit 1
}

# 测试SSH连接
Write-Host "📡 测试服务器连接..." -ForegroundColor Yellow
try {
    ssh -i $KEY -o ConnectTimeout=5 ${USER}@${SERVER} "echo '连接成功'" | Out-Null
    Write-Host "✓ 服务器连接正常`n" -ForegroundColor Green
} catch {
    Write-Host "❌ 无法连接到服务器 $SERVER" -ForegroundColor Red
    exit 1
}

if (!$SkipBuild) {
    Write-Host "🔨 步骤 1: 构建Docker镜像..." -ForegroundColor Yellow
    docker-compose build
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ 构建失败!" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ 镜像构建完成`n" -ForegroundColor Green
}

Write-Host "📦 步骤 2: 导出Docker镜像..." -ForegroundColor Yellow
$tempDir = ".\temp-deploy"
if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }
New-Item -ItemType Directory -Path $tempDir | Out-Null

docker save jwt-authservice:latest -o "$tempDir\authservice.tar"
docker save jwt-apigateway:latest -o "$tempDir\apigateway.tar"
docker save jwt-orderservice:latest -o "$tempDir\orderservice.tar"
Copy-Item "docker-compose.yml" "$tempDir\"

Write-Host "✓ 镜像已导出`n" -ForegroundColor Green

Write-Host "📤 步骤 3: 上传到服务器..." -ForegroundColor Yellow
ssh -i $KEY ${USER}@${SERVER} "mkdir -p $REMOTE_DIR"
scp -i $KEY -r "$tempDir\*" ${USER}@${SERVER}:${REMOTE_DIR}/

Write-Host "✓ 文件上传完成`n" -ForegroundColor Green

Write-Host "🚀 步骤 4: 在服务器上部署..." -ForegroundColor Yellow

$deployCommands = @"
cd $REMOTE_DIR
echo '停止旧容器...'
docker-compose down 2>/dev/null || true
echo '加载新镜像...'
docker load -i authservice.tar
docker load -i apigateway.tar
docker load -i orderservice.tar
echo '启动服务...'
docker-compose up -d
echo '等待服务启动...'
sleep 10
echo '服务状态:'
docker-compose ps
"@

ssh -i $KEY ${USER}@${SERVER} $deployCommands

Write-Host "`n✓ 部署完成!`n" -ForegroundColor Green

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║        服务访问地址        ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
Write-Host "  认证服务: http://tx.qsgl.net:6001/swagger" -ForegroundColor White
Write-Host "  订单服务: http://tx.qsgl.net:6002/swagger" -ForegroundColor White
Write-Host "  API网关:   http://tx.qsgl.net:6005`n" -ForegroundColor White

Write-Host "📝 管理命令:" -ForegroundColor Yellow
Write-Host "  查看日志: ssh -i $KEY ${USER}@${SERVER} 'cd $REMOTE_DIR && docker-compose logs -f'" -ForegroundColor Gray
Write-Host "  查看状态: ssh -i $KEY ${USER}@${SERVER} 'cd $REMOTE_DIR && docker-compose ps'" -ForegroundColor Gray
Write-Host "  重启服务: ssh -i $KEY ${USER}@${SERVER} 'cd $REMOTE_DIR && docker-compose restart'" -ForegroundColor Gray
Write-Host "  停止服务: ssh -i $KEY ${USER}@${SERVER} 'cd $REMOTE_DIR && docker-compose down'`n" -ForegroundColor Gray

# 清理
Write-Host "🧹 清理临时文件..." -ForegroundColor Gray
Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
ssh -i $KEY ${USER}@${SERVER} "cd $REMOTE_DIR && rm -f *.tar"
Write-Host "✓ 清理完成`n" -ForegroundColor Green
