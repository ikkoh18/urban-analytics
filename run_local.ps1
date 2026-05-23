# run_local.ps1 — Sobe backend + app Flutter lendo as chaves de .env.local
# Uso: .\run_local.ps1

$envFile = Join-Path $PSScriptRoot ".env.local"

if (-not (Test-Path $envFile)) {
    Write-Error "Arquivo .env.local nao encontrado em $envFile"
    exit 1
}

# Le .env.local e exporta as variaveis
foreach ($line in Get-Content $envFile) {
    $line = $line.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) { continue }
    $parts = $line -split "=", 2
    [System.Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim(), "Process")
}

$groqKey    = $env:GROQ_API_KEY
$apiBaseUrl = $env:API_BASE_URL
$keyPreview = if ($groqKey.Length -ge 8) { $groqKey.Substring(0, 8) + "..." } else { "(vazio)" }

Write-Host ""
Write-Host "=== Urban Analytics - Local ===" -ForegroundColor Cyan
Write-Host "API_BASE_URL : $apiBaseUrl"
Write-Host "GROQ_API_KEY : $keyPreview" -ForegroundColor DarkGray
Write-Host ""

# Sobe o backend em background
Write-Host ">> Iniciando backend (uvicorn)..." -ForegroundColor Yellow

$uvicornCmd = "`$env:GROQ_API_KEY='$groqKey'; cd '$PSScriptRoot\backend'; ..\.venv\Scripts\uvicorn main:app --host 0.0.0.0 --port 8000 --reload"
$backend = Start-Process -PassThru -NoNewWindow powershell -ArgumentList "-NoProfile", "-Command", $uvicornCmd

Write-Host "   PID backend: $($backend.Id)"
Write-Host ""

# Aguarda o backend subir
Start-Sleep -Seconds 3

# Sobe o app Flutter no Chrome
Write-Host ">> Iniciando Flutter (Chrome)..." -ForegroundColor Green

$dartDefines = "--dart-define=API_BASE_URL=$apiBaseUrl"

Set-Location (Join-Path $PSScriptRoot "app")
flutter run -d chrome $dartDefines

# Ao sair do Flutter, encerra o backend
Write-Host ""
Write-Host ">> Encerrando backend..." -ForegroundColor Yellow
Stop-Process -Id $backend.Id -ErrorAction SilentlyContinue
