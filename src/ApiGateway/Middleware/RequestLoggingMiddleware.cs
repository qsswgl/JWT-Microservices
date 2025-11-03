namespace ApiGateway.Middleware;

/// <summary>
/// 请求日志中间件
/// </summary>
public class RequestLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestLoggingMiddleware> _logger;

    public RequestLoggingMiddleware(RequestDelegate next, ILogger<RequestLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var requestId = Guid.NewGuid().ToString();
        context.Items["RequestId"] = requestId;

        _logger.LogInformation(
            "Request {RequestId}: {Method} {Path} from {RemoteIp}",
            requestId,
            context.Request.Method,
            context.Request.Path,
            context.Connection.RemoteIpAddress
        );

        var sw = System.Diagnostics.Stopwatch.StartNew();
        
        await _next(context);
        
        sw.Stop();

        _logger.LogInformation(
            "Response {RequestId}: {StatusCode} completed in {ElapsedMs}ms",
            requestId,
            context.Response.StatusCode,
            sw.ElapsedMilliseconds
        );
    }
}
