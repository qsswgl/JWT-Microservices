using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using Shared.Models;

namespace AuthService.Services;

public class JwtTokenGenerator
{
    private readonly IConfiguration _configuration;

    public JwtTokenGenerator(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public TokenResponse GenerateToken(User user)
    {
        var secretKey = _configuration["Jwt:SecretKey"] ?? throw new InvalidOperationException("JWT SecretKey not configured");
        var issuer = _configuration["Jwt:Issuer"] ?? "AuthService";
        var audience = _configuration["Jwt:Audience"] ?? "ApiGateway";

        var claims = new List<Claim>
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim(ClaimTypes.Name, user.Username),
            new Claim("permissions", System.Text.Json.JsonSerializer.Serialize(user.Permissions))
        };

        // 为每个角色添加独立的role claim
        foreach (var role in user.Roles)
        {
            claims.Add(new Claim("role", role));
        }

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        // 生成Access Token (短期 - 30分钟)
        var accessToken = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(30),
            signingCredentials: credentials
        );

        // 生成Refresh Token (长期 - 7天)
        var refreshTokenClaims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var refreshToken = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: refreshTokenClaims,
            expires: DateTime.UtcNow.AddDays(7),
            signingCredentials: credentials
        );

        return new TokenResponse
        {
            AccessToken = new JwtSecurityTokenHandler().WriteToken(accessToken),
            RefreshToken = new JwtSecurityTokenHandler().WriteToken(refreshToken),
            ExpiresIn = 1800, // 30分钟
            TokenType = "Bearer"
        };
    }

    public ClaimsPrincipal? ValidateToken(string token)
    {
        var secretKey = _configuration["Jwt:SecretKey"] ?? throw new InvalidOperationException("JWT SecretKey not configured");
        var issuer = _configuration["Jwt:Issuer"] ?? "AuthService";
        var audience = _configuration["Jwt:Audience"] ?? "ApiGateway";

        try
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.UTF8.GetBytes(secretKey);

            var validationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ValidateIssuer = true,
                ValidIssuer = issuer,
                ValidateAudience = true,
                ValidAudience = audience,
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero // 不允许时间偏差
            };

            var principal = tokenHandler.ValidateToken(token, validationParameters, out SecurityToken validatedToken);
            return principal;
        }
        catch
        {
            return null;
        }
    }
}
