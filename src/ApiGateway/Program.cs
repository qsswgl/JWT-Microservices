using System.IdentityModel.Tokens.Jwt;
using System.Text;
using ApiGateway.Middleware;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Ocelot.DependencyInjection;
using Ocelot.Middleware;
using Ocelot.Cache.CacheManager;
using Shared.Services;
using StackExchange.Redis;

// 防止JWT claim类型被映射
JwtSecurityTokenHandler.DefaultInboundClaimTypeMap.Clear();

var builder = WebApplication.CreateBuilder(args);

// 添加Ocelot配置文件
builder.Configuration.AddJsonFile("ocelot.json", optional: false, reloadOnChange: true);

// 配置Redis
var redisConnection = builder.Configuration.GetConnectionString("Redis") ?? "localhost:6379";
builder.Services.AddSingleton<IConnectionMultiplexer>(ConnectionMultiplexer.Connect(redisConnection));
builder.Services.AddSingleton<ICacheService, RedisCacheService>();

// 配置JWT认证
var jwtSettings = builder.Configuration.GetSection("Jwt");
var secretKey = jwtSettings["SecretKey"] ?? throw new InvalidOperationException("JWT SecretKey not configured");

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer("Bearer", options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey)),
            ValidateIssuer = true,
            ValidIssuer = jwtSettings["Issuer"],
            ValidateAudience = true,
            ValidAudience = jwtSettings["Audience"],
            ValidateLifetime = true,
            ClockSkew = TimeSpan.Zero
        };
    });

// 添加Ocelot和缓存管理
builder.Services.AddOcelot()
    .AddCacheManager(x =>
    {
        x.WithDictionaryHandle();
    });

var app = builder.Build();

// 添加自定义中间件
app.UseMiddleware<RequestLoggingMiddleware>();

// 使用JWT认证
app.UseAuthentication();

// 添加Token验证中间件（检查黑名单）
app.UseMiddleware<TokenValidationMiddleware>();

// 使用Ocelot
await app.UseOcelot();

app.Run();
