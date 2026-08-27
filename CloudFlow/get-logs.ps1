# Script para carregar o .env e buscar os logs de uma Lambda

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
    Write-Host "Uso: ./get-logs.ps1 <NomeDaFuncao>"
    Write-Host "Exemplo: ./get-logs.ps1 CloudFlow_DynamoDbMessageStream"
    exit 1
}

$region = $envVars["AWS_REGION"]
$accessKey = $envVars["AWS_ACCESS_KEY_ID"]
$secretKey = $envVars["AWS_SECRET_ACCESS_KEY"]

if (Get-Command aws -ErrorAction SilentlyContinue) {
    $env:AWS_ACCESS_KEY_ID = $accessKey
    $env:AWS_SECRET_ACCESS_KEY = $secretKey
    $env:AWS_DEFAULT_REGION = $region
    aws logs tail "/aws/lambda/$functionName" --follow
} else {
    Write-Host "AWS CLI não encontrado"
}
