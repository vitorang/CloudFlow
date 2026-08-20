using CloudFlow.Core.Enums;

namespace CloudFlow.Core.Entities;

public class Message
{
    public string Id { get; set; } = Ulid.NewUlid().ToString();
    public string Text { get; set; } = string.Empty;
    public MessageType Type { get; set; } = MessageType.Text;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
