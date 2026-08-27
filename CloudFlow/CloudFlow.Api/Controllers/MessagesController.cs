using CloudFlow.Core.Dtos;
using CloudFlow.Core.Interfaces.Services;
using Microsoft.AspNetCore.Mvc;

namespace CloudFlow.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class MessagesController(IMessageService messageService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<RecentMessagesResponseDto>> GetRecent([FromQuery] DateTime? before, CancellationToken cancellationToken)
    {
        var result = await messageService.GetRecent(before ?? DateTime.UtcNow, cancellationToken);
        return Ok(result);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateMessageDto dto, CancellationToken cancellationToken)
    {
        await messageService.Create(dto, cancellationToken);
        return NoContent();
    }

    [HttpDelete]
    public async Task<IActionResult> DeleteMany([FromBody] DeleteMessagesDto dto, CancellationToken cancellationToken)
    {
        await messageService.DeleteMany(dto, cancellationToken);
        return NoContent();
    }
}
