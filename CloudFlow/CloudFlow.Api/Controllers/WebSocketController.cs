using CloudFlow.Core.Interfaces.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace CloudFlow.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class WebSocketController(IWebSocketConnectionRepository connectionRepository) : ControllerBase
{
    public record ConnectionRequest(string ConnectionId);

    [HttpPost("connect")]
    public async Task<IActionResult> Connect([FromBody] ConnectionRequest request, CancellationToken cancellationToken)
    {
        await connectionRepository.Add(request.ConnectionId, cancellationToken);
        return Ok();
    }

    [HttpPost("disconnect")]
    public async Task<IActionResult> Disconnect([FromBody] ConnectionRequest request, CancellationToken cancellationToken)
    {
        await connectionRepository.Remove(request.ConnectionId, cancellationToken);
        return NoContent();
    }
}
