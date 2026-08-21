using CloudFlow.Core.Dtos;
using Microsoft.AspNetCore.Mvc;

namespace CloudFlow.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class ConfigController : ControllerBase
{
    [HttpGet]
    public ActionResult<AppConfigDto> Get()
    {
        var request = HttpContext.Request;
        var apiUrl = $"{request.Scheme}://{request.Host}";

        var config = new AppConfigDto(
            Name: "CloudFlow",
            ApiUrl: apiUrl,
            WebSocketUrl: string.Empty
        );

        return Ok(config);
    }
}
