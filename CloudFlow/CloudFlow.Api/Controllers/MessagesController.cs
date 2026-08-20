using CloudFlow.Core.Dtos;
using CloudFlow.Core.Interfaces.Services;
using Microsoft.AspNetCore.Mvc;

namespace CloudFlow.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class MessagesController : ControllerBase
{
    private readonly IMessageService _messageService;

    public MessagesController(IMessageService messageService)
    {
        _messageService = messageService;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<MessageResponseDto>>> GetRecent(CancellationToken cancellationToken)
    {
        var messages = await _messageService.GetRecent(cancellationToken);
        return Ok(messages);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateMessageDto dto, CancellationToken cancellationToken)
    {
        await _messageService.Create(dto, cancellationToken);
        return NoContent();
    }
}
