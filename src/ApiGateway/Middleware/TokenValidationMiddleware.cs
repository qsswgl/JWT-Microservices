using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Shared.Services;

namespace ApiGateway.Middleware;

/// <summary>
/// Token验证中间件 - 验证JWT并检查黑名单
/// </summary>
public class TokenValidationMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<TokenValidationMiddleware> _logger;

    public TokenValidationMiddleware(RequestDelegate next, ILogger<TokenValidationMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context, ICacheService cacheService)
    {
        // 跳过认证服务的请求（已经在Ocelot中配置）
        var path = context.Request.Path.Value?.ToLower() ?? "";
        
        // 如果有用户信息（已通过JWT认证），检查Token是否被撤销
        if (context.User.Identity?.IsAuthenticated == true)
        {
            var jti = context.User.FindFirst(JwtRegisteredClaimNames.Jti)?.Value;
            
            if (!string.IsNullOrEmpty(jti))
            {
                // 检查Token是否在黑名单中
                if (await cacheService.ExistsAsync($"revoked_token:{jti}"))
                {
                    _logger.LogWarning("Revoked token attempted access: {Jti}", jti);
                    context.Response.StatusCode = 401;
                    await context.Response.WriteAsJsonAsync(new { message = "Token已被撤销" });
                    return;
                }
            }
        }

        await _next(context);
    }
}
