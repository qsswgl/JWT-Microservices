# JWT微服务快速启动脚本

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "JWT微服务架构 - 快速启动" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# 检查Docker是否运行
Write-Host "检查Docker状态..." -ForegroundColor Yellow
try {
    docker version | Out-Null
    Write-Host "✓ Docker已就绪" -ForegroundColor Green
}
catch {
    Write-Host "✗ Docker未运行，请先启动Docker Desktop" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 显示菜单
Write-Host "请选择启动方式:" -ForegroundColor Cyan
Write-Host "1. 使用Docker Compose启动（推荐）" -ForegroundColor White
Write-Host "2. 本地开发模式启动" -ForegroundColor White
Write-Host "3. 仅启动Redis" -ForegroundColor White
Write-Host "4. 停止所有服务" -ForegroundColor White
Write-Host "5. 查看服务状态" -ForegroundColor White
Write-Host "6. 查看服务日志" -ForegroundColor White
Write-Host "0. 退出" -ForegroundColor White
Write-Host ""

$choice = Read-Host "请输入选项 (0-6)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "启动Docker Compose..." -ForegroundColor Yellow
        docker-compose up -d
        Write-Host ""
        Write-Host "等待服务启动..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        Write-Host ""
        Write-Host "✓ 所有服务已启动!" -ForegroundColor Green
        Write-Host ""
        Write-Host "服务地址:" -ForegroundColor Cyan
        Write-Host "  - API网关:    http://localhost:5000" -ForegroundColor White
        Write-Host "  - 认证服务:   http://localhost:5001/swagger" -ForegroundColor White
        Write-Host "  - 订单服务:   http://localhost:5002/swagger" -ForegroundColor White
        Write-Host "  - Redis:      localhost:6379" -ForegroundColor White
        Write-Host ""
        Write-Host "运行测试脚本: .\test-api.ps1" -ForegroundColor Yellow
    }
    "2" {
        Write-Host ""
        Write-Host "启动本地开发模式..." -ForegroundColor Yellow
        
        # 启动Redis
        Write-Host "1. 启动Redis容器..." -ForegroundColor Yellow
        docker run -d -p 6379:6379 --name jwt-redis redis:7-alpine
        Write-Host "✓ Redis已启动" -ForegroundColor Green
        Write-Host ""
        
        # 启动认证服务
        Write-Host "2. 启动认证服务..." -ForegroundColor Yellow
        Write-Host "请在新的终端窗口运行以下命令:" -ForegroundColor Cyan
        Write-Host "cd src\AuthService" -ForegroundColor White
        Write-Host "dotnet run --urls `"http://localhost:5001`"" -ForegroundColor White
        Write-Host ""
        
        # 启动订单服务
        Write-Host "3. 启动订单服务..." -ForegroundColor Yellow
        Write-Host "请在新的终端窗口运行以下命令:" -ForegroundColor Cyan
        Write-Host "cd src\OrderService" -ForegroundColor White
        Write-Host "dotnet run --urls `"http://localhost:5002`"" -ForegroundColor White
        Write-Host ""
        
        # 启动API网关
        Write-Host "4. 启动API网关..." -ForegroundColor Yellow
        Write-Host "请在新的终端窗口运行以下命令:" -ForegroundColor Cyan
        Write-Host "cd src\ApiGateway" -ForegroundColor White
        Write-Host "dotnet run --urls `"http://localhost:5000`"" -ForegroundColor White
        Write-Host ""
    }
    "3" {
        Write-Host ""
        Write-Host "启动Redis..." -ForegroundColor Yellow
        docker run -d -p 6379:6379 --name jwt-redis redis:7-alpine
        Write-Host "✓ Redis已启动在端口 6379" -ForegroundColor Green
    }
    "4" {
        Write-Host ""
        Write-Host "停止所有服务..." -ForegroundColor Yellow
        docker-compose down
        docker stop jwt-redis 2>$null
        docker rm jwt-redis 2>$null
        Write-Host "✓ 所有服务已停止" -ForegroundColor Green
    }
    "5" {
        Write-Host ""
        Write-Host "查看服务状态..." -ForegroundColor Yellow
        Write-Host ""
        docker-compose ps
    }
    "6" {
        Write-Host ""
        Write-Host "显示服务日志 (按Ctrl+C退出)..." -ForegroundColor Yellow
        Write-Host ""
        docker-compose logs -f
    }
    "0" {
        Write-Host "退出" -ForegroundColor Gray
        exit 0
    }
    default {
        Write-Host "无效的选项" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
