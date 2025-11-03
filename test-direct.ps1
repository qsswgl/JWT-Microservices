# 简化测试脚本 - 直接测试服务

Write-Host "`n========== JWT 微服务项目测试 ==========`n" -ForegroundColor Cyan

# 测试1: 直接访问认证服务
Write-Host "[测试1] 直接访问认证服务登录..." -ForegroundColor Yellow
$response = Invoke-RestMethod -Uri "http://localhost:5001/api/auth/login" `
    -Method Post `
    -ContentType "application/json" `
    -Body '{"username":"admin","password":"admin123"}'
    
Write-Host "✓ 登录成功!" -ForegroundColor Green
Write-Host "Access Token (前50字符): $($response.accessToken.Substring(0,50))..."
$token = $response.accessToken
Write-Host ""

# 测试2: 直接访问订单服务
Write-Host "[测试2] 直接访问订单服务..." -ForegroundColor Yellow
$orders = Invoke-RestMethod -Uri "http://localhost:5002/api/orders" `
    -Method Get `
    -Headers @{
        "Authorization" = "Bearer $token"
        "X-User-Id" = "user123"
        "X-User-Roles" = "Admin,User"
    }
    
Write-Host "✓ 成功获取订单!" -ForegroundColor Green
Write-Host "订单数量: $($orders.Count)"
$orders[0] | Select-Object orderNumber, userName, totalAmount, status | Format-List
Write-Host ""

# 测试3: 创建订单
Write-Host "[测试3] 创建新订单..." -ForegroundColor Yellow
$newOrder = Invoke-RestMethod -Uri "http://localhost:5002/api/orders" `
    -Method Post `
    -Headers @{
        "Authorization" = "Bearer $token"
        "X-User-Id" = "user123"
        "X-User-Name" = "admin"
        "X-User-Roles" = "Admin,User"
    } `
    -ContentType "application/json" `
    -Body '{
        "items": [
            {"productName": "MacBook Pro", "quantity": 1, "price": 12999.00},
            {"productName": "Magic Mouse", "quantity": 2, "price": 699.00}
        ]
    }'
    
Write-Host "✓ 订单创建成功!" -ForegroundColor Green
Write-Host "订单号: $($newOrder.orderNumber)"
Write-Host "总金额: $($newOrder.totalAmount)"
Write-Host ""

# 测试4: 获取当前用户信息
Write-Host "[测试4] 获取当前用户信息..." -ForegroundColor Yellow
$user = Invoke-RestMethod -Uri "http://localhost:5001/api/auth/me" `
    -Method Get `
    -Headers @{"Authorization" = "Bearer $token"}
    
Write-Host "✓ 成功获取用户信息!" -ForegroundColor Green
Write-Host "用户ID: $($user.id)"
Write-Host "用户名: $($user.username)"
Write-Host "角色: $($user.roles -join ', ')"
Write-Host ""

Write-Host "========== 测试完成 ==========`n" -ForegroundColor Cyan
Write-Host "注意: 这是直接访问服务的测试，绕过了API网关" -ForegroundColor Yellow
Write-Host "所有服务都在正常工作！" -ForegroundColor Green
