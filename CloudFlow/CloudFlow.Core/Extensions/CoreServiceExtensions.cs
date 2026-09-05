using CloudFlow.Core.Configuration;
using CloudFlow.Core.Interfaces.Services;
using CloudFlow.Core.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace CloudFlow.Core.Extensions;

public static class CoreServiceExtensions
{
    public static IServiceCollection AddCoreServices(this IServiceCollection services, IConfiguration configuration)
    {
        var demoModeString = configuration["DemoModeEnabled"]
            ?? throw new InvalidOperationException("Configuração DemoModeEnabled não foi definida.");

        if (!bool.TryParse(demoModeString, out var demoModeEnabled))
            throw new InvalidOperationException("Configuração DemoModeEnabled deve ser um booleano válido (true/false).");

        var cloudProvider = configuration["CloudProvider"]
            ?? throw new InvalidOperationException("Configuração CloudProvider não foi definida.");

        services.AddSingleton(new AppOptions(demoModeEnabled, cloudProvider));
        services.AddScoped<IMessageService, MessageService>();

        return services;
    }
}
