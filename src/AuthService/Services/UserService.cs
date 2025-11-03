using Shared.Models;

namespace AuthService.Services;

public interface IUserService
{
    Task<User?> ValidateCredentialsAsync(string username, string password);
    Task<User?> GetUserAsync(string userId);
}

public class UserService : IUserService
{
    // 模拟数据库 - 实际应用中应该连接真实数据库
    private static readonly List<User> _users = new()
    {
        new User
        {
            Id = "user123",
            Username = "admin",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("admin123"),
            Roles = new List<string> { "Admin", "User" },
            Permissions = new List<string> { "order:read", "order:write", "order:delete", "user:read", "user:write" }
        },
        new User
        {
            Id = "user456",
            Username = "zhangsan",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("pass123"),
            Roles = new List<string> { "User" },
            Permissions = new List<string> { "order:read", "order:write" }
        }
    };

    public Task<User?> ValidateCredentialsAsync(string username, string password)
    {
        var user = _users.FirstOrDefault(u => u.Username == username);
        
        if (user == null || !BCrypt.Net.BCrypt.Verify(password, user.PasswordHash))
        {
            return Task.FromResult<User?>(null);
        }

        return Task.FromResult<User?>(user);
    }

    public Task<User?> GetUserAsync(string userId)
    {
        var user = _users.FirstOrDefault(u => u.Id == userId);
        return Task.FromResult(user);
    }
}
