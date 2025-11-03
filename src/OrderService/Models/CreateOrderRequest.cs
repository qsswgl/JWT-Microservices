namespace OrderService.Models;

public class CreateOrderRequest
{
    public List<OrderItemRequest> Items { get; set; } = new();
}

public class OrderItemRequest
{
    public string ProductName { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal Price { get; set; }
}
