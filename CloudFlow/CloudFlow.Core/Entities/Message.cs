namespace CloudFlow.Core.Entities;

public class Message
{
    public string Id { get; set; } = Ulid.NewUlid().ToString();
    public string Author { get; set; } = string.Empty;
    public string Text { get; set; } = string.Empty;
    public string? AttachmentKey { get; set; }
    public string? ThumbnailKey { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public long? ExpiresAt { get; set; }
}
