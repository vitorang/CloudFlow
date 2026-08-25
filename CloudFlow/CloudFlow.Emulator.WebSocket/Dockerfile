FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
USER $APP_UID
WORKDIR /app
EXPOSE 3001
ENV ASPNETCORE_HTTP_PORTS=3001

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["CloudFlow.Emulator.WebSocket/CloudFlow.Emulator.WebSocket.csproj", "CloudFlow.Emulator.WebSocket/"]
RUN dotnet restore "./CloudFlow.Emulator.WebSocket/CloudFlow.Emulator.WebSocket.csproj"
COPY . .
WORKDIR "/src/CloudFlow.Emulator.WebSocket"
RUN dotnet build "./CloudFlow.Emulator.WebSocket.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./CloudFlow.Emulator.WebSocket.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "CloudFlow.Emulator.WebSocket.dll"]
