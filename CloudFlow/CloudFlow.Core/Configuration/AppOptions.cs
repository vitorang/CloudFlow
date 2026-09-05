namespace CloudFlow.Core.Configuration;

public record AppOptions(
    bool DemoModeEnabled,
    string CloudProvider
);
