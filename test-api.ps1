# JWT微服务API测试脚本
# PowerShell版本

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "JWT微服务架构API测试" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:5000"

# 测试1: 管理员登录
Write-Host "[测试1] 管理员登录..." -ForegroundColor Yellow
try {
    $adminLogin = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body '{"username":"admin","password":"admin123"}'
    
    $adminToken = $adminLogin.accessToken
    Write-Host "✓ 登录成功!" -ForegroundColor Green
    Write-Host "Access Token: $($adminToken.Substring(0, 50))..." -ForegroundColor Gray
    Write-Host "过期时间: $($adminLogin.expiresIn)秒" -ForegroundColor Gray
    Write-Host ""
}
catch {
    Write-Host "✗ 登录失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 测试2: 获取当前用户信息
Write-Host "[测试2] 获取当前用户信息..." -ForegroundColor Yellow
try {
    $currentUser = Invoke-RestMethod -Uri "$baseUrl/api/auth/me" `
        -Method Get `
        -Headers @{"Authorization"="Bearer $adminToken"}
    
    Write-Host "✓ 成功获取用户信息!" -ForegroundColor Green
    Write-Host "用户ID: $($currentUser.id)" -ForegroundColor Gray
    Write-Host "用户名: $($currentUser.username)" -ForegroundColor Gray
    Write-Host "角色: $($currentUser.roles -join ', ')" -ForegroundColor Gray
    Write-Host ""
}
catch {
    Write-Host "✗ 获取用户信息失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试3: 获取订单列表
Write-Host "[测试3] 获取所有订单..." -ForegroundColor Yellow
try {
    $orders = Invoke-RestMethod -Uri "$baseUrl/api/orders" `
        -Method Get `
        -Headers @{"Authorization"="Bearer $adminToken"}
    
    Write-Host "✓ 成功获取订单列表!" -ForegroundColor Green
    Write-Host "订单数量: $($orders.Count)" -ForegroundColor Gray
    if ($orders.Count -gt 0) {
        Write-Host "第一个订单: $($orders[0].orderNumber) - 金额: $($orders[0].totalAmount)" -ForegroundColor Gray
    }
    Write-Host ""
}
catch {
    Write-Host "✗ 获取订单失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试4: 创建新订单
Write-Host "[测试4] 创建新订单..." -ForegroundColor Yellow
try {
    $newOrder = Invoke-RestMethod -Uri "$baseUrl/api/orders" `
        -Method Post `
        -Headers @{"Authorization"="Bearer $adminToken"} `
        -ContentType "application/json" `
        -Body '{
            "items": [
                {
                    "productName": "MacBook Pro",
                    "quantity": 1,
                    "price": 12999.00
                },
                {
                    "productName": "Magic Mouse",
                    "quantity": 2,
                    "price": 699.00
                }
            ]
        }'
    
    Write-Host "✓ 订单创建成功!" -ForegroundColor Green
    Write-Host "订单号: $($newOrder.orderNumber)" -ForegroundColor Gray
    Write-Host "总金额: $($newOrder.totalAmount)" -ForegroundColor Gray
    Write-Host "状态: $($newOrder.status)" -ForegroundColor Gray
    $orderId = $newOrder.id
    Write-Host ""
}
catch {
    Write-Host "✗ 创建订单失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试5: 获取单个订单
if ($orderId) {
    Write-Host "[测试5] 获取订单详情 (ID: $orderId)..." -ForegroundColor Yellow
    try {
        $order = Invoke-RestMethod -Uri "$baseUrl/api/orders/$orderId" `
            -Method Get `
            -Headers @{"Authorization"="Bearer $adminToken"}
        
        Write-Host "✓ 成功获取订单详情!" -ForegroundColor Green
        Write-Host "订单号: $($order.orderNumber)" -ForegroundColor Gray
        Write-Host "用户: $($order.userName)" -ForegroundColor Gray
        Write-Host "商品数: $($order.items.Count)" -ForegroundColor Gray
        Write-Host ""
    }
    catch {
        Write-Host "✗ 获取订单详情失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 测试6: 更新订单状态
if ($orderId) {
    Write-Host "[测试6] 更新订单状态..." -ForegroundColor Yellow
    try {
        $updatedOrder = Invoke-RestMethod -Uri "$baseUrl/api/orders/$orderId/status" `
            -Method Put `
            -Headers @{"Authorization"="Bearer $adminToken"} `
            -ContentType "application/json" `
            -Body '{"status": "Processing"}'
        
        Write-Host "✓ 订单状态更新成功!" -ForegroundColor Green
        Write-Host "新状态: $($updatedOrder.status)" -ForegroundColor Gray
        Write-Host ""
    }
    catch {
        Write-Host "✗ 更新订单状态失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 测试7: 普通用户登录
Write-Host "[测试7] 普通用户登录..." -ForegroundColor Yellow
try {
    $userLogin = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body '{"username":"zhangsan","password":"pass123"}'
    
    $userToken = $userLogin.accessToken
    Write-Host "✓ 登录成功!" -ForegroundColor Green
    Write-Host "Access Token: $($userToken.Substring(0, 50))..." -ForegroundColor Gray
    Write-Host ""
}
catch {
    Write-Host "✗ 登录失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试8: 普通用户尝试查看所有订单（只能看到自己的）
if ($userToken) {
    Write-Host "[测试8] 普通用户获取订单（数据隔离测试）..." -ForegroundColor Yellow
    try {
        $userOrders = Invoke-RestMethod -Uri "$baseUrl/api/orders" `
            -Method Get `
            -Headers @{"Authorization"="Bearer $userToken"}
        
        Write-Host "✓ 成功获取订单!" -ForegroundColor Green
        Write-Host "可见订单数: $($userOrders.Count) (普通用户只能看到自己的订单)" -ForegroundColor Gray
        Write-Host ""
    }
    catch {
        Write-Host "✗ 获取订单失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 测试9: 普通用户尝试删除订单（应该失败）
if ($userToken -and $orderId) {
    Write-Host "[测试9] 普通用户尝试删除订单（权限测试）..." -ForegroundColor Yellow
    try {
        Invoke-RestMethod -Uri "$baseUrl/api/orders/$orderId" `
            -Method Delete `
            -Headers @{"Authorization"="Bearer $userToken"}
        
        Write-Host "✗ 意外成功！普通用户不应该有删除权限" -ForegroundColor Red
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 403) {
            Write-Host "✓ 权限检查正常！普通用户无法删除订单" -ForegroundColor Green
        }
        else {
            Write-Host "✗ 发生错误: $($_.Exception.Message)" -ForegroundColor Red
        }
        Write-Host ""
    }
}

# 测试10: Token刷新
Write-Host "[测试10] 刷新Token..." -ForegroundColor Yellow
try {
    $refreshResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/refresh" `
        -Method Post `
        -ContentType "application/json" `
        -Body "{`"refreshToken`":`"$($adminLogin.refreshToken)`"}"
    
    Write-Host "✓ Token刷新成功!" -ForegroundColor Green
    Write-Host "新Access Token: $($refreshResponse.accessToken.Substring(0, 50))..." -ForegroundColor Gray
    Write-Host ""
}
catch {
    Write-Host "✗ Token刷新失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试11: 无Token访问受保护的API
Write-Host "[测试11] 无Token访问受保护的API（应该失败）..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "$baseUrl/api/orders" -Method Get
    Write-Host "✗ 意外成功！应该需要认证" -ForegroundColor Red
}
catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "✓ 认证检查正常！未授权访问被拒绝" -ForegroundColor Green
    }
    else {
        Write-Host "✗ 发生错误: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

# 测试12: 用户登出
Write-Host "[测试12] 管理员登出..." -ForegroundColor Yellow
try {
    $logoutResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/logout" `
        -Method Post `
        -Headers @{"Authorization"="Bearer $adminToken"}
    
    Write-Host "✓ 登出成功!" -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Host "✗ 登出失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试13: 使用已撤销的Token（应该失败）
Write-Host "[测试13] 使用已撤销的Token（应该失败）..." -ForegroundColor Yellow
Start-Sleep -Seconds 2  # 等待Redis更新
try {
    Invoke-RestMethod -Uri "$baseUrl/api/orders" `
        -Method Get `
        -Headers @{"Authorization"="Bearer $adminToken"}
    
    Write-Host "✗ 意外成功！已撤销的Token不应该有效" -ForegroundColor Red
}
catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "✓ Token撤销机制正常！已撤销的Token被拒绝" -ForegroundColor Green
    }
    else {
        Write-Host "✗ 发生错误: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "测试完成！" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
