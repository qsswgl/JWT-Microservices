namespace Shared.Services;

public interface ICacheService
{
    Task<string?> GetAsync(string key);
    Task SetAsync(string key, string value, TimeSpan? expiry = null);
    Task<bool> ExistsAsync(string key);
    Task RemoveAsync(string key);
}
