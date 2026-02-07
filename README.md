# Treinamento dbt com Microsoft Fabric

Este documento descreve, de forma **coerente, lógica e replicável**, o passo a passo para criação e execução de um projeto de **dbt** integrado ao **Microsoft Fabric**, servindo como base para treinamentos e desenvolvimento.

---

## 📋 1. Pré-requisitos

Antes de iniciar, garanta que os seguintes itens estejam disponíveis:

- Sistema operacional: **Linux, macOS ou Windows**
- **Python 3.8 ou superior**
- Acesso a um workspace do **Microsoft Fabric** (para ambiente de produção)
- **Docker** (opcional - para desenvolvimento local com SQL Server)
- **Azure CLI** instalado e configurado (para autenticação CLI)
- **Microsoft ODBC Driver 18** ou superior para SQL Server
- **Git** para versionamento

### Instalação do Azure CLI

- Windows: [Download Azure CLI](https://learn.microsoft.com/pt-br/cli/azure/install-azure-cli-windows)
- Linux/macOS: 
  ```bash
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  ```

### Instalação do ODBC Driver

- Windows: [Download ODBC Driver 18](https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server)
- Linux: [Instruções de instalação](https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server)

---

## 🚀 2. Setup do Ambiente

### 2.1 Criação do diretório do projeto

```bash
mkdir treinamento-dbt
cd treinamento-dbt
```

### 2.2 Criação e ativação do ambiente virtual

**Criar ambiente virtual:**
```bash
python -m venv .venv
```

**Ativar ambiente virtual:**

- **Linux / macOS:**
  ```bash
  source .venv/bin/activate
  ```

- **Windows (PowerShell):**
  ```powershell
  .venv\Scripts\Activate.ps1
  ```

- **Windows (CMD):**
  ```cmd
  .venv\Scripts\activate.bat
  ```

### 2.3 Instalação das dependências

Crie um arquivo `requirements.txt` na raiz do projeto:

```txt
# =====================================================
# DBT Dependencies
# =====================================================
dbt-core==1.11.2
dbt-fabric==1.9.3
dbt-sqlserver==1.9.0
python-dotenv==1.2.1
```

**Instale as dependências:**

```bash
pip install -r requirements.txt
```

**Verificar instalação:**
```bash
dbt --version
```

---

## 📁 3. Criação do Projeto dbt

### 3.1 Inicializar projeto dbt

```bash
dbt init treinamento_dbt
```

Durante a inicialização, o dbt fará algumas perguntas:
- **Which database would you like to use?** Escolha o número correspondente ao **fabric**
- As demais configurações serão feitas via `profiles.yml`

### 3.2 Estrutura do projeto criada

```text
treinamento-dbt/
├── .venv/                    # Ambiente virtual Python
├── .env                      # Variáveis de ambiente (NÃO versionar)
├── .gitignore               # Arquivos ignorados pelo Git
├── requirements.txt         # Dependências Python
├── run_dbt.ps1             # Script PowerShell para executar DBT
├── run_dbt.sh              # Script Bash para executar DBT
├── PERFIS_DBT.md           # Documentação dos perfis
└── treinamento_dbt/        # Pasta do projeto DBT
    ├── dbt_project.yml     # Configuração do projeto
    ├── profiles.yml        # Configuração de conexões
    ├── models/             # Modelos SQL
    ├── tests/              # Testes customizados
    ├── macros/             # Macros Jinja
    ├── seeds/              # Arquivos CSV para carga
    ├── snapshots/          # Snapshots de dados
    └── analyses/           # Análises ad-hoc
```

---

## 🔐 4. Configuração de Variáveis de Ambiente

### 4.1 Criar arquivo `.env`

Crie um arquivo `.env` na **raiz do projeto** (fora da pasta `treinamento_dbt`):

```env
# =====================================================
# DBT Database Configuration
# =====================================================

# ========== PERFIL ATIVO ==========
# Escolha: 'local', 'fabric_local' ou 'fabric'
DBT_TARGET=local

# ========== CONFIGURAÇÃO LOCAL (Docker SQL Server) ==========
LOCAL_SERVER=localhost,1433
LOCAL_DATABASE=DataWarehouseTreinamento
LOCAL_SCHEMA=dbo
LOCAL_USER=sa
LOCAL_PASSWORD=Password_Muito_Forte_123

# ========== CONFIGURAÇÃO FABRIC LOCAL (Desenvolvimento com az login) ==========
# Use este perfil para desenvolvimento local com suas credenciais Azure
# Requisito: Execute 'az login' antes de usar o DBT
# FABRIC_SERVER=seu-workspace.datawarehouse.fabric.microsoft.com
# FABRIC_DATABASE=DataWarehouseTreinamento
# FABRIC_SCHEMA=dbo

# ========== CONFIGURAÇÃO FABRIC (Service Principal - Produção/CI/CD) ==========
# Use este perfil para automação e pipelines
# Descomente e configure para usar Fabric:
# FABRIC_SERVER=seu-workspace.datawarehouse.fabric.microsoft.com
# FABRIC_DATABASE=DataWarehouseTreinamento
# FABRIC_SCHEMA=dbo
# FABRIC_TENANT_ID=your-tenant-id
# FABRIC_CLIENT_ID=your-client-id
# FABRIC_CLIENT_SECRET=your-client-secret

# ========== CONFIGURAÇÕES GERAIS ==========
ODBC_DRIVER=ODBC Driver 18 for SQL Server
DBT_THREADS=4
```

> **⚠️ IMPORTANTE:** Nunca versione o arquivo `.env` com credenciais reais!

### 4.2 Criar arquivo `.env.example`

Crie um template sem credenciais para versionamento:

```env
# =====================================================
# DBT Database Configuration - TEMPLATE
# =====================================================
# Copie este arquivo para .env e preencha com suas credenciais

DBT_TARGET=local

# Local Configuration
LOCAL_SERVER=localhost,1433
LOCAL_DATABASE=DataWarehouseTreinamento
LOCAL_SCHEMA=dbo
LOCAL_USER=sa
LOCAL_PASSWORD=your_password_here

# Fabric Configuration
# FABRIC_SERVER=your-server.datawarehouse.fabric.microsoft.com
# FABRIC_DATABASE=DataWarehouseTreinamento
# FABRIC_SCHEMA=dbo
# FABRIC_TENANT_ID=your-tenant-id
# FABRIC_CLIENT_ID=your-client-id
# FABRIC_CLIENT_SECRET=your-client-secret

ODBC_DRIVER=ODBC Driver 18 for SQL Server
DBT_THREADS=4
```

### 4.3 Configurar `.gitignore`

Crie ou atualize o arquivo `.gitignore` na raiz:

```gitignore
# DBT
target/
dbt_packages/
logs/
dbt_modules/

# Python
__pycache__/
*.py[cod]
*$py.class
.Python
.venv/
venv/
ENV/
env/

# Ambiente e Credenciais
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Outros
*.log
```

---

## ⚙️ 5. Configuração do Profiles do dbt

### 5.1 Criar `treinamento_dbt/profiles.yml`

Crie ou substitua o conteúdo do arquivo `treinamento_dbt/profiles.yml`:

```yaml
treinamento_dbt:
  target: "{{ env_var('DBT_TARGET', 'local') }}"
  outputs:
    # Perfil para SQL Server Local (Docker)
    local:
      type: fabric
      driver: "{{ env_var('ODBC_DRIVER', 'ODBC Driver 18 for SQL Server') }}"
      server: "{{ env_var('LOCAL_SERVER', 'localhost,1433') }}"
      port: 1433
      database: "{{ env_var('LOCAL_DATABASE', 'DataWarehouseTreinamento') }}"
      schema: "{{ env_var('LOCAL_SCHEMA', 'dbo') }}"
      threads: "{{ env_var('DBT_THREADS', '4') | int }}"
      authentication: sql
      user: "{{ env_var('LOCAL_USER', 'sa') }}"
      password: "{{ env_var('LOCAL_PASSWORD') }}"
      encrypt: true
      trust_cert: true
    
    # Perfil para Microsoft Fabric Local (Desenvolvimento com az login)
    fabric_local:
      type: fabric
      driver: "{{ env_var('ODBC_DRIVER', 'ODBC Driver 18 for SQL Server') }}"
      server: "{{ env_var('FABRIC_SERVER') }}"
      port: 1433
      database: "{{ env_var('FABRIC_DATABASE', 'DataWarehouseTreinamento') }}"
      schema: "{{ env_var('FABRIC_SCHEMA', 'dbo') }}"
      threads: "{{ env_var('DBT_THREADS', '4') | int }}"
      authentication: CLI
      encrypt: true
      trust_cert: false
    
    # Perfil para Microsoft Fabric (Service Principal - Produção/CI/CD)
    fabric:
      type: fabric
      driver: "{{ env_var('ODBC_DRIVER', 'ODBC Driver 18 for SQL Server') }}"
      server: "{{ env_var('FABRIC_SERVER') }}"
      port: 1433
      database: "{{ env_var('FABRIC_DATABASE', 'DataWarehouseTreinamento') }}"
      schema: "{{ env_var('FABRIC_SCHEMA', 'dbo') }}"
      threads: "{{ env_var('DBT_THREADS', '4') | int }}"
      authentication: ServicePrincipal
      tenant_id: "{{ env_var('FABRIC_TENANT_ID') }}"
      client_id: "{{ env_var('FABRIC_CLIENT_ID') }}"
      client_secret: "{{ env_var('FABRIC_CLIENT_SECRET') }}"
      encrypt: true
      trust_cert: false
```

### 5.2 Entendendo os perfis

**🖥️ local** - Desenvolvimento com SQL Server (Docker)
- Usa autenticação SQL (usuário/senha)
- Ideal para desenvolvimento offline
- Requer Docker com SQL Server rodando

**☁️ fabric_local** - Desenvolvimento com Microsoft Fabric
- Usa autenticação CLI (`az login`)
- Não precisa de Service Principal
- Usa suas credenciais pessoais do Azure

**🏭 fabric** - Produção/CI/CD com Microsoft Fabric
- Usa autenticação Service Principal
- Ideal para automação e pipelines
- Requer configuração de App Registration no Azure

---

## 🛠️ 6. Scripts de Execução

### 6.1 Script PowerShell (Windows)

Crie o arquivo `run_dbt.ps1` na raiz do projeto:

```powershell
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
```

### 6.2 Script Bash (Linux/macOS)

Crie o arquivo `run_dbt.sh` na raiz do projeto:

```bash
#!/bin/bash
# Script para carregar variáveis de ambiente do .env e executar comandos DBT
# Uso: ./run_dbt.sh debug
#      ./run_dbt.sh run
#      ./run_dbt.sh test

# Carrega as variáveis do arquivo .env
if [ -f .env ]; then
    echo "Carregando variáveis de ambiente de .env..."
    export $(grep -v '^#' .env | xargs)
    echo ""
else
    echo "Arquivo .env não encontrado"
    exit 1
fi

# Ativa o ambiente virtual se existir
if [ -f .venv/bin/activate ]; then
    echo "Ativando ambiente virtual..."
    source .venv/bin/activate
    echo ""
fi

# Navega para o diretório do DBT
cd treinamento_dbt

# Executa o comando DBT
echo "Executando: dbt $@"
echo ""
dbt "$@"

# Retorna ao diretório original
cd ..
```

**Tornar executável (Linux/macOS):**
```bash
chmod +x run_dbt.sh
```

---

## ✅ 7. Validação da Configuração

### 7.1 Testar conexão

**Windows:**
```powershell
.\run_dbt.ps1 debug
```

**Linux/macOS:**
```bash
./run_dbt.sh debug
```

### 7.2 Interpretar resultados

✅ **Sucesso** - Todas as verificações passaram:
```
Configuration:
  profiles.yml file [OK found and valid]
  dbt_project.yml file [OK found and valid]
Connection test: [OK connection ok]
```

❌ **Erro** - Revise:
- Variáveis de ambiente no `.env`
- Driver ODBC instalado corretamente
- Credenciais válidas
- Servidor acessível
- Para `fabric_local`: Execute `az login` primeiro
- Para `local`: Verifique se Docker com SQL Server está rodando

---

## 🎯 8. Execução do dbt

### 8.1 Comandos principais

**Validar conexão:**
```powershell
.\run_dbt.ps1 debug
```

**Executar todos os modelos:**
```powershell
.\run_dbt.ps1 run
```

**Executar modelo específico:**
```powershell
.\run_dbt.ps1 "run --select my_model"
```

**Executar testes:**
```powershell
.\run_dbt.ps1 test
```

**Gerar documentação:**
```powershell
.\run_dbt.ps1 "docs generate"
.\run_dbt.ps1 "docs serve"
```

**Compilar sem executar:**
```powershell
.\run_dbt.ps1 compile
```

### 8.2 Alternar entre perfis

**Opção 1 - Editar `.env`:**
```env
DBT_TARGET=local         # Para desenvolvimento local
DBT_TARGET=fabric_local  # Para Fabric com az login
DBT_TARGET=fabric        # Para Fabric com Service Principal
```

**Opção 2 - Variável temporária (PowerShell):**
```powershell
$env:DBT_TARGET="fabric_local"; .\run_dbt.ps1 debug
```

**Opção 3 - Variável temporária (Bash):**
```bash
DBT_TARGET=fabric_local ./run_dbt.sh debug
```

---

## 🔑 9. Configuração de Autenticação Fabric

### 9.1 Autenticação CLI (fabric_local)

**Passo 1 - Login no Azure:**
```bash
az login
```

**Passo 2 - Verificar conta:**
```bash
az account show
```

**Passo 3 - Configurar `.env`:**
```env
DBT_TARGET=fabric_local
FABRIC_SERVER=seu-workspace.datawarehouse.fabric.microsoft.com
FABRIC_DATABASE=DataWarehouseTreinamento
FABRIC_SCHEMA=dbo
```

### 9.2 Autenticação Service Principal (fabric)

**Passo 1 - Criar App Registration no Azure:**
1. Portal Azure → Azure Active Directory
2. App registrations → New registration
3. Copiar: **Application (client) ID**
4. Copiar: **Directory (tenant) ID**

**Passo 2 - Criar Client Secret:**
1. Certificates & secrets → New client secret
2. Copiar o **Value** (aparece só uma vez!)

**Passo 3 - Dar permissões no Fabric:**
1. Fabric workspace → Settings → Manage access
2. Adicionar o Service Principal como Admin/Member

**Passo 4 - Configurar `.env`:**
```env
DBT_TARGET=fabric
FABRIC_SERVER=seu-workspace.datawarehouse.fabric.microsoft.com
FABRIC_DATABASE=DataWarehouseTreinamento
FABRIC_SCHEMA=dbo
FABRIC_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
FABRIC_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
FABRIC_CLIENT_SECRET=seu_secret_value
```

---

## 📚 10. Próximos Passos para Desenvolvimento

### 10.1 Estrutura de modelos recomendada

```text
models/
├── staging/          # Camada de ingestão (1:1 com fontes)
│   └── stg_yellow_taxi.sql
├── intermediate/     # Transformações intermediárias
│   └── int_taxi_metrics.sql
└── marts/           # Modelos finais para consumo
    ├── core/        # Métricas principais
    └── finance/     # Área específica
```

### 10.2 Sugestão de evolução

1. **Sources** - Documentar fontes de dados
2. **Staging Models** - Camada de ingestão limpa
3. **Tests** - Validação de qualidade (schema tests)
4. **Intermediate Models** - Transformações reutilizáveis
5. **Marts** - Modelos finais organizados por domínio
6. **Documentation** - `dbt docs generate`
7. **Snapshots** - Histórico de mudanças (SCD Type 2)
8. **CI/CD** - Automação com GitHub Actions

### 10.3 Exemplo de modelo básico

Criar `models/staging/stg_yellow_taxi.sql`:

```sql
{{ config(materialized='view') }}

SELECT
    VendorID,
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    passenger_count,
    trip_distance,
    fare_amount,
    total_amount
FROM {{ source('raw', 'yellow_taxi_trips') }}
WHERE tpep_pickup_datetime IS NOT NULL
```

---

## 🐳 11. Setup Opcional: SQL Server Local com Docker

Para desenvolvimento local sem dependência de Fabric:

### 11.1 Criar `docker-compose.yml`

```yaml
version: '3.8'

services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=Password_Muito_Forte_123
      - MSSQL_PID=Developer
    ports:
      - "1433:1433"
    volumes:
      - sqlserver_data:/var/opt/mssql

volumes:
  sqlserver_data:
```

### 11.2 Iniciar SQL Server

```bash
docker-compose up -d
```

### 11.3 Criar banco de dados

```bash
docker exec -it <container-id> /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P Password_Muito_Forte_123 \
  -Q "CREATE DATABASE DataWarehouseTreinamento"
```

---

## 📖 12. Recursos Adicionais

### 12.1 Documentação oficial

- [dbt Documentation](https://docs.getdbt.com/)
- [dbt-fabric Adapter](https://docs.getdbt.com/docs/core/connect-data-platform/fabric-setup)
- [Microsoft Fabric Docs](https://learn.microsoft.com/en-us/fabric/)

### 12.2 Boas práticas

- ✅ Sempre versionar código no Git
- ✅ Nunca commitar credenciais (usar `.env`)
- ✅ Documentar modelos com `description` e `schema.yml`
- ✅ Implementar testes de qualidade
- ✅ Usar nomenclatura consistente (prefixos: stg_, int_, fct_, dim_)
- ✅ Revisar código via Pull Requests

### 12.3 Troubleshooting

**Erro: "environment variable 'XXX' not found"**
- Verifique se o `.env` existe e está configurado
- Use os scripts `run_dbt.ps1` ou `run_dbt.sh`

**Erro: "Unable to connect to database"**
- Verifique credenciais no `.env`
- Para `fabric_local`: Execute `az login`
- Para `local`: Verifique se Docker está rodando
- Teste conectividade com `ping` ou ferramentas SQL

**Erro: "SQL Authentication not supported"**
- O adapter dbt-fabric pode não suportar SQL auth totalmente
- Use `fabric_local` (CLI) ou `fabric` (Service Principal)

---

## 🎓 13. Observações Finais

- ✨ Este projeto foi estruturado para fins **educacionais e profissionais**
- 🔄 Facilmente adaptável para diferentes ambientes
- 🔐 Segurança via variáveis de ambiente e `.gitignore`
- 📊 Suporta múltiplos perfis (local, desenvolvimento, produção)
- 🚀 Scripts automatizados para facilitar execução

---

**🎉 Pronto!** Este setup garante uma base sólida, **reutilizável e profissional** para projetos dbt com Microsoft Fabric.

