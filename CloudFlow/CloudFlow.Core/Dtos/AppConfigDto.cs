namespace CloudFlow.Core.Dtos;

public record AppConfigDto(
    string Name,
    string ApiUrl,
    string WebSocketUrl,
    bool DemoModeEnabled
);
