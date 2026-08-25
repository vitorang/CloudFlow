using System.Collections.Concurrent;
using System.Net.WebSockets;
using System.Text;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddHttpClient();

var app = builder.Build();

app.UseWebSockets();

var connections = new ConcurrentDictionary<string, (WebSocket Socket, SemaphoreSlim Lock)>();
var httpClientFactory = app.Services.GetRequiredService<IHttpClientFactory>();
var apiUrl = builder.Configuration["API_URL"] ?? "http://api:8080";

app.MapPost("/@connections/{connectionId}", async (string connectionId, HttpRequest request, CancellationToken cancellationToken) =>
{
    if (!connections.TryGetValue(connectionId, out var connection) || connection.Socket.State != WebSocketState.Open)
        return Results.StatusCode(StatusCodes.Status410Gone);

    using var reader = new StreamReader(request.Body, Encoding.UTF8);
    var body = await reader.ReadToEndAsync(cancellationToken);
    var bytes = Encoding.UTF8.GetBytes(body);

    await connection.Lock.WaitAsync(cancellationToken);
    try
    {
        if (connection.Socket.State == WebSocketState.Open)
            await connection.Socket.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, cancellationToken);
    }
    finally
    {
        connection.Lock.Release();
    }

    return Results.Ok();
});

app.MapDelete("/@connections/{connectionId}", async (string connectionId, CancellationToken cancellationToken) =>
{
    if (connections.TryRemove(connectionId, out var connection))
    {
        if (connection.Socket.State == WebSocketState.Open)
            await connection.Socket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closed by server", cancellationToken);
    }

    return Results.NoContent();
});

app.Map("/", async (HttpContext context, CancellationToken cancellationToken) =>
{
    if (!context.WebSockets.IsWebSocketRequest)
    {
        context.Response.StatusCode = StatusCodes.Status400BadRequest;
        return;
    }

    using var webSocket = await context.WebSockets.AcceptWebSocketAsync();
    var connectionId = Ulid.NewUlid().ToString();
    connections.TryAdd(connectionId, (webSocket, new SemaphoreSlim(1, 1)));

    var client = httpClientFactory.CreateClient();

    try
    {
        var connectPayload = new StringContent(
            $"{{\"connectionId\":\"{connectionId}\"}}",
            Encoding.UTF8,
            "application/json"
        );
        await client.PostAsync($"{apiUrl}/api/websocket/connect", connectPayload, cancellationToken);
    }
    catch
    {
    }

    var buffer = new byte[1024 * 4];
    try
    {
        while (webSocket.State == WebSocketState.Open)
        {
            var result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), cancellationToken);
            if (result.MessageType == WebSocketMessageType.Close)
                break;
        }
    }
    catch
    {
    }
    finally
    {
        connections.TryRemove(connectionId, out _);

        try
        {
            var disconnectPayload = new StringContent(
                $"{{\"connectionId\":\"{connectionId}\"}}",
                Encoding.UTF8,
                "application/json"
            );
            await client.PostAsync($"{apiUrl}/api/websocket/disconnect", disconnectPayload, CancellationToken.None);
        }
        catch
        {
        }

        if (webSocket.State == WebSocketState.Open)
            await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closed", CancellationToken.None);
    }
});

app.Run();
