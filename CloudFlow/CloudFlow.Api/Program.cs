using CloudFlow.Core.Extensions;
using CloudFlow.Infrastructure.Aws.Extensions;


namespace CloudFlow.Api;

public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        builder.Services.AddAWSLambdaHosting(LambdaEventSource.HttpApi);

        builder.Services.AddCors(options =>
        {
            options.AddDefaultPolicy(policy =>
            {
                policy.AllowAnyOrigin()
                      .AllowAnyHeader()
                      .AllowAnyMethod();
            });
        });

        builder.Services.AddControllers();

        builder.Services.AddProblemDetails(options =>
        {
            options.CustomizeProblemDetails = context =>
            {
                context.ProblemDetails.Extensions["traceId"] = context.HttpContext.TraceIdentifier;
                context.ProblemDetails.Extensions["instance"] = $"{context.HttpContext.Request.Method} {context.HttpContext.Request.Path}";
            };
        });

        builder.Services.AddOpenApi();
        builder.Services.AddCoreServices(builder.Configuration);
        builder.Services.AddAwsInfrastructure(builder.Configuration);

        var app = builder.Build();

        app.UseCors();
        app.UseExceptionHandler();
        app.UseStatusCodePages();

        if (app.Environment.IsDevelopment())
        {
            app.MapOpenApi();
        }

        app.UseAuthorization();
        app.MapControllers();

        app.Run();
    }
}
