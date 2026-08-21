using CloudFlow.Core.Dtos;
using CloudFlow.Core.Interfaces.Services;
using Microsoft.AspNetCore.Mvc;

namespace CloudFlow.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class MessagesController(IMessageService messageService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<MessageResponseDto>>> GetRecent(CancellationToken cancellationToken)
    {
        var messages = await messageService.GetRecent(cancellationToken);
        return Ok(messages);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateMessageDto dto, CancellationToken cancellationToken)
    {
        await messageService.Create(dto, cancellationToken);
        return NoContent();
    }
}
