# Script para compilar e publicar o app Flutter no GitHub Pages

$root = $PSScriptRoot
$flutterDir = Join-Path $root "cloud_flow_app"
$buildWebDir = Join-Path $flutterDir "build\web"

Write-Host "Compilando Flutter Web para producao com base-href '/CloudFlow/'..." -ForegroundColor Cyan
Set-Location $flutterDir
flutter build web --release --base-href "/CloudFlow/"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha na compilacao do Flutter Web."
    Set-Location $root
    exit 1
}

Write-Host "Publicando pasta de build no GitHub Pages (branch gh-pages)..." -ForegroundColor Cyan
Set-Location $root

# Salva a branch atual
$currentBranch = git branch --show-current
if (-not $currentBranch) {
    $currentBranch = "main"
}

# Inicializa um repositorio temporario dentro de build/web para subir direto para gh-pages
Set-Location $buildWebDir

# Cria .nojekyll para evitar que o GitHub Pages oculte arquivos especiais
New-Item -ItemType File -Name ".nojekyll" -Force | Out-Null

git init -b gh-pages
git add -A
git commit -m "Deploy CloudFlow Web via script"

# Obtem a URL remota do repositorio principal
$remoteUrl = git -C $root config --get remote.origin.url
if (-not $remoteUrl) {
    Write-Error "Remoto origin nao encontrado no repositorio Git principal."
    Remove-Item -Recurse -Force .git
    Set-Location $root
    exit 1
}

Write-Host "Enviando arquivos para o GitHub ($remoteUrl)..." -ForegroundColor Cyan
git push $remoteUrl gh-pages --force

# Remove o .git temporario de dentro de build/web
Remove-Item -Recurse -Force .git

Set-Location $root
Write-Host "Publicacao concluida com sucesso!" -ForegroundColor Green
Write-Host "Acesse o GitHub > Settings > Pages para garantir que a branch 'gh-pages' esta selecionada." -ForegroundColor Yellow
