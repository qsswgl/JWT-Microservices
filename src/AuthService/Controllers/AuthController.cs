using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using AuthService.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Shared.Models;
using Shared.Services;

namespace AuthService.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly JwtTokenGenerator _tokenGenerator;
    private readonly ICacheService _cacheService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(
        IUserService userService,
        JwtTokenGenerator tokenGenerator,
        ICacheService cacheService,
        ILogger<AuthController> logger)
    {
        _userService = userService;
        _tokenGenerator = tokenGenerator;
        _cacheService = cacheService;
        _logger = logger;
    }

    /// <summary>
    /// 用户登录
    /// </summary>
    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        _logger.LogInformation("Login attempt for user: {Username}", request.Username);

        // 验证用户凭证
        var user = await _userService.ValidateCredentialsAsync(request.Username, request.Password);
        
        if (user == null)
        {
            _logger.LogWarning("Login failed for user: {Username}", request.Username);
            return Unauthorized(new { message = "用户名或密码错误" });
        }

        // 生成JWT Token
        var tokenResponse = _tokenGenerator.GenerateToken(user);

        _logger.LogInformation("User {Username} logged in successfully", request.Username);
        
        return Ok(tokenResponse);
    }

    /// <summary>
    /// 刷新Token
    /// </summary>
    [HttpPost("refresh")]
    [AllowAnonymous]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request)
    {
        try
        {
            // 验证Refresh Token
            var principal = _tokenGenerator.ValidateToken(request.RefreshToken);
            
            if (principal == null)
            {
                return Unauthorized(new { message = "无效的Refresh Token" });
            }

            var userId = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value 
                        ?? principal.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
            
            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "无效的Token Claims" });
            }

            // 查询用户最新信息
            var user = await _userService.GetUserAsync(userId);
            
            if (user == null)
            {
                return Unauthorized(new { message = "用户不存在" });
            }

            // 生成新的Access Token
            var tokenResponse = _tokenGenerator.GenerateToken(user);

            _logger.LogInformation("Token refreshed for user: {UserId}", userId);
            
            return Ok(new { AccessToken = tokenResponse.AccessToken, ExpiresIn = tokenResponse.ExpiresIn });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error refreshing token");
            return Unauthorized(new { message = "Token刷新失败" });
        }
    }

    /// <summary>
    /// 用户登出 - 撤销Token
    /// </summary>
    [HttpPost("logout")]
    [Authorize]
    public async Task<IActionResult> Logout()
    {
        try
        {
            var jti = User.FindFirst(JwtRegisteredClaimNames.Jti)?.Value;
            var expClaim = User.FindFirst(JwtRegisteredClaimNames.Exp)?.Value;

            if (!string.IsNullOrEmpty(jti) && !string.IsNullOrEmpty(expClaim))
            {
                // 计算Token剩余有效时间
                var expireTime = DateTimeOffset.FromUnixTimeSeconds(long.Parse(expClaim));
                var ttl = expireTime - DateTimeOffset.UtcNow;

                if (ttl > TimeSpan.Zero)
                {
                    // 将Token加入黑名单，直到其自然过期
                    await _cacheService.SetAsync($"revoked_token:{jti}", "revoked", ttl);
                    _logger.LogInformation("Token {Jti} has been revoked", jti);
                }
            }

            return Ok(new { message = "登出成功" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during logout");
            return StatusCode(500, new { message = "登出失败" });
        }
    }

    /// <summary>
    /// 获取当前用户信息
    /// </summary>
    [HttpGet("me")]
    [Authorize]
    public async Task<IActionResult> GetCurrentUser()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value 
                    ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        var user = await _userService.GetUserAsync(userId);
        
        if (user == null)
        {
            return NotFound(new { message = "用户不存在" });
        }

        return Ok(new
        {
            user.Id,
            user.Username,
            user.Roles,
            user.Permissions
        });
    }
}
