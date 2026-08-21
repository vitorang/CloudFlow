using CloudFlow.Core.Interfaces.Services;
using CloudFlow.Core.Services;
using Microsoft.Extensions.DependencyInjection;

namespace CloudFlow.Core.Extensions;

public static class CoreServiceExtensions
{
    public static IServiceCollection AddCoreServices(this IServiceCollection services)
    {
        services.AddScoped<IMessageService, MessageService>();

        return services;
    }
}
