namespace CloudFlow.Core.Dtos;

public record WebSocketMessageDto<T>(string Event, T Data);
