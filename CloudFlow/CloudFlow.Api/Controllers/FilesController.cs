using CloudFlow.Core.Dtos;
using CloudFlow.Core.Interfaces.Services;
using Microsoft.AspNetCore.Mvc;

namespace CloudFlow.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class FilesController(IStorageService storageService) : ControllerBase
{
    [HttpPost("presigned-urls")]
    public async Task<ActionResult<UploadUrlsResponseDto>> GenerateUploadUrls(
        [FromBody] GenerateUploadUrlsDto dto,
        CancellationToken cancellationToken)
    {
        var result = await storageService.GenerateUploadUrls(dto, cancellationToken);
        return Ok(result);
    }
}
