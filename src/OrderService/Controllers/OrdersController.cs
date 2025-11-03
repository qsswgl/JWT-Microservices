using Microsoft.AspNetCore.Mvc;
using OrderService.Models;

namespace OrderService.Controllers;

[ApiController]
[Route("api/[controller]")]
public class OrdersController : ControllerBase
{
    private readonly ILogger<OrdersController> _logger;
    
    // 模拟数据库
    private static readonly List<Order> _orders = new()
    {
        new Order
        {
            Id = 1,
            OrderNumber = "ORD-2025-001",
            UserId = "user123",
            UserName = "admin",
            TotalAmount = 299.99m,
            Status = "Completed",
            Items = new List<OrderItem>
            {
                new OrderItem { Id = 1, ProductName = "笔记本电脑", Quantity = 1, Price = 299.99m }
            }
        }
    };

    public OrdersController(ILogger<OrdersController> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// 获取所有订单
    /// </summary>
    [HttpGet]
    public IActionResult GetOrders()
    {
        // 从网关转发的Header中获取用户信息
        var userId = Request.Headers["X-User-Id"].ToString();
        var userName = Request.Headers["X-User-Name"].ToString();
        var userRoles = Request.Headers["X-User-Roles"].ToString().Split(',', StringSplitOptions.RemoveEmptyEntries);

        _logger.LogInformation("User {UserName} (ID: {UserId}, Roles: {Roles}) is fetching orders", 
            userName, userId, string.Join(",", userRoles));

        // 如果是普通用户，只返回自己的订单
        if (userRoles.Any(r => r.Trim() == "Admin"))
        {
            return Ok(_orders);
        }
        else
        {
            var userOrders = _orders.Where(o => o.UserId == userId).ToList();
            return Ok(userOrders);
        }
    }

    /// <summary>
    /// 根据ID获取订单
    /// </summary>
    [HttpGet("{id}")]
    public IActionResult GetOrder(int id)
    {
        var userId = Request.Headers["X-User-Id"].ToString();
        var userRoles = Request.Headers["X-User-Roles"].ToString().Split(',', StringSplitOptions.RemoveEmptyEntries);

        var order = _orders.FirstOrDefault(o => o.Id == id);
        
        if (order == null)
        {
            return NotFound(new { message = "订单不存在" });
        }

        // 权限检查：管理员可以查看所有订单，普通用户只能查看自己的订单
        if (!userRoles.Any(r => r.Trim() == "Admin") && order.UserId != userId)
        {
            return Forbid();
        }

        return Ok(order);
    }

    /// <summary>
    /// 创建订单
    /// </summary>
    [HttpPost]
    public IActionResult CreateOrder([FromBody] CreateOrderRequest request)
    {
        var userId = Request.Headers["X-User-Id"].ToString();
        var userName = Request.Headers["X-User-Name"].ToString();

        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized(new { message = "用户信息缺失" });
        }

        var order = new Order
        {
            Id = _orders.Count > 0 ? _orders.Max(o => o.Id) + 1 : 1,
            OrderNumber = $"ORD-{DateTime.UtcNow:yyyy}-{_orders.Count + 1:D3}",
            UserId = userId,
            UserName = userName,
            Items = request.Items.Select((item, index) => new OrderItem
            {
                Id = index + 1,
                ProductName = item.ProductName,
                Quantity = item.Quantity,
                Price = item.Price
            }).ToList(),
            Status = "Pending",
            CreatedAt = DateTime.UtcNow
        };

        order.TotalAmount = order.Items.Sum(i => i.Price * i.Quantity);
        _orders.Add(order);

        _logger.LogInformation("Order {OrderNumber} created by user {UserName}", order.OrderNumber, userName);

        return CreatedAtAction(nameof(GetOrder), new { id = order.Id }, order);
    }

    /// <summary>
    /// 更新订单状态
    /// </summary>
    [HttpPut("{id}/status")]
    public IActionResult UpdateOrderStatus(int id, [FromBody] UpdateOrderStatusRequest request)
    {
        var userId = Request.Headers["X-User-Id"].ToString();
        var userRoles = Request.Headers["X-User-Roles"].ToString().Split(',', StringSplitOptions.RemoveEmptyEntries);

        var order = _orders.FirstOrDefault(o => o.Id == id);
        
        if (order == null)
        {
            return NotFound(new { message = "订单不存在" });
        }

        // 只有管理员或订单拥有者可以更新订单状态
        if (!userRoles.Any(r => r.Trim() == "Admin") && order.UserId != userId)
        {
            return Forbid();
        }

        order.Status = request.Status;

        _logger.LogInformation("Order {OrderId} status updated to {Status}", id, request.Status);

        return Ok(order);
    }

    /// <summary>
    /// 删除订单（仅管理员）
    /// </summary>
    [HttpDelete("{id}")]
    public IActionResult DeleteOrder(int id)
    {
        var userRoles = Request.Headers["X-User-Roles"].ToString().Split(',', StringSplitOptions.RemoveEmptyEntries);

        if (!userRoles.Any(r => r.Trim() == "Admin"))
        {
            return Forbid();
        }

        var order = _orders.FirstOrDefault(o => o.Id == id);
        
        if (order == null)
        {
            return NotFound(new { message = "订单不存在" });
        }

        _orders.Remove(order);

        _logger.LogInformation("Order {OrderId} deleted", id);

        return NoContent();
    }
}

public class UpdateOrderStatusRequest
{
    public string Status { get; set; } = string.Empty;
}
