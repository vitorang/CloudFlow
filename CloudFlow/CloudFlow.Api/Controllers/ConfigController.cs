using CloudFlow.Core.Configuration;
using CloudFlow.Core.Dtos;
using CloudFlow.Infrastructure.Aws.Configuration;
using Microsoft.AspNetCore.Mvc;

namespace CloudFlow.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class ConfigController(AwsOptions awsOptions, AppOptions appOptions) : ControllerBase
{
    [HttpGet]
    public ActionResult<AppConfigDto> Get()
    {
        var request = HttpContext.Request;
        var apiUrl = $"{request.Scheme}://{request.Host}";

        var config = new AppConfigDto(
            Name: "CloudFlow",
            ApiUrl: apiUrl,
            WebSocketUrl: awsOptions.WebSocket.PublicUrl,
            DemoModeEnabled: appOptions.DemoModeEnabled
        );

        return Ok(config);
    }
}
