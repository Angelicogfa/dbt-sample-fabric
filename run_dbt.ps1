# Script para carregar variáveis de ambiente do .env e executar comandos DBT
# Uso: .\run_dbt.ps1 debug
#      .\run_dbt.ps1 run
#      .\run_dbt.ps1 test

param(
    [Parameter(Mandatory=$false)]
    [string]$Command = "debug"
)

# Carrega as variáveis do arquivo .env
$envFile = Join-Path $PSScriptRoot ".env"

if (Test-Path $envFile) {
    Write-Host "Carregando variáveis de ambiente de $envFile..." -ForegroundColor Green
    
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            
            # Remove aspas se existirem
            $value = $value -replace '^["'']|["'']$', ''
            
            # Define a variável de ambiente
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
            Write-Host "  $key = $value" -ForegroundColor Cyan
        }
    }
    Write-Host ""
} else {
    Write-Host "Arquivo .env não encontrado em $envFile" -ForegroundColor Yellow
}

# Ativa o ambiente virtual se existir
$venvPath = Join-Path $PSScriptRoot ".venv\Scripts\Activate.ps1"
if (Test-Path $venvPath) {
    Write-Host "Ativando ambiente virtual..." -ForegroundColor Green
    & $venvPath
    Write-Host ""
}

# Navega para o diretório do DBT
Set-Location (Join-Path $PSScriptRoot "treinamento_dbt")

# Executa o comando DBT
Write-Host "Executando: dbt $Command" -ForegroundColor Green
Write-Host ""

$dbtArgs = $Command -split ' '
& dbt @dbtArgs

# Retorna ao diretório original
Set-Location $PSScriptRoot
