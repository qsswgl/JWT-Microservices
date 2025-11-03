using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// 添加控制器
builder.Services.AddControllers();

// 配置Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo 
    { 
        Title = "订单服务 API", 
        Version = "v1",
        Description = "示例微服务 - 展示如何处理从API网关转发的请求"
    });
});

var app = builder.Build();

// 配置HTTP请求管道
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "订单服务 API v1");
    });
}

app.MapControllers();

app.Run();
