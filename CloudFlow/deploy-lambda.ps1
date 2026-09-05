# Script para carregar o .env e fazer o deploy das Lambdas

$envFile = Join-Path $PSScriptRoot ".env"

if (-not (Test-Path $envFile)) {
    Write-Error "Arquivo .env não encontrado em $envFile"
    exit 1
}

$envVars = @{}
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
        $parts = $line.Split("=", 2)
        $key = $parts[0].Trim()
        $value = $parts[1].Trim()
        $envVars[$key] = $value
        [System.Environment]::SetEnvironmentVariable($key, $value, "Process")
    }
}

$functionName = $args[0]
if (-not $functionName) {
    Write-Host "Uso: ./deploy-lambda.ps1 <NomeDaFuncao>"
    Write-Host "Exemplo: ./deploy-lambda.ps1 CloudFlow_WebSocketConnect"
    exit 1
}

$projectFolder = if ($functionName -match "Api") { "CloudFlow.Api" } else { "CloudFlow.Workers.Aws" }
$projectLocation = Join-Path $PSScriptRoot $projectFolder
$region = $envVars["AWS_REGION"]
$accessKey = $envVars["AWS_ACCESS_KEY_ID"]
$secretKey = $envVars["AWS_SECRET_ACCESS_KEY"]

Write-Host "Iniciando deploy de $functionName usando o projeto $projectFolder..."

dotnet lambda deploy-function $functionName `
    --project-location $projectLocation `
    --region $region `
    --aws-access-key-id $accessKey `
    --aws-secret-key $secretKey

