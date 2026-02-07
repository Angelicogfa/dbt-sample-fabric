# Treinamento dbt com Microsoft Fabric

Este documento descreve, de forma **coerente, lógica e replicável**, o passo a passo para criação e execução de um projeto de **dbt** integrado ao **Microsoft Fabric**, servindo como base para treinamentos e desenvolvimento.

---

## 📋 1. Pré-requisitos

Antes de iniciar, garanta que os seguintes itens estejam disponíveis:

- Sistema operacional: **Linux, macOS ou Windows**
- **Python 3.8 ou superior**
- Acesso a um workspace do **Microsoft Fabric**
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
# Escolha: 'fabric_local' (desenvolvimento) ou 'fabric' (produção)
DBT_TARGET=fabric_local

# ========== CONFIGURAÇÃO FABRIC LOCAL (Desenvolvimento com az login) ==========
# Use este perfil para desenvolvimento com suas credenciais Azure
# Requisito: Execute 'az login' antes de usar o DBT
FABRIC_SERVER=seu-workspace.datawarehouse.fabric.microsoft.com
FABRIC_DATABASE=DataWarehouseTreinamento
FABRIC_SCHEMA=dbo

# ========== CONFIGURAÇÃO FABRIC (Service Principal - Produção/CI/CD) ==========
# Use este perfil para automação e pipelines
# Descomente e configure para usar Fabric em produção:
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

DBT_TARGET=fabric_local

# Fabric Configuration (Development)
FABRIC_SERVER=your-workspace.datawarehouse.fabric.microsoft.com
FABRIC_DATABASE=DataWarehouseTreinamento
FABRIC_SCHEMA=dbo

# Fabric Configuration (Production - Service Principal)
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
  target: "{{ env_var('DBT_TARGET', 'fabric_local') }}"
  outputs:
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
DBT_TARGET=fabric_local  # Para desenvolvimento com az login (padrão)
DBT_TARGET=fabric        # Para produção com Service Principal
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

## � 10. Entendendo a Arquitetura do Projeto

Antes de começarmos a construir os modelos, é importante entender a arquitetura que seguiremos.

### 10.1 Arquitetura Medallion em 3 Camadas

Este projeto segue a arquitetura **Medallion**, organizando os dados em **3 camadas lógicas**:

```text
🥉 BRONZE (Staging)      →  🥈 SILVER (Intermediate)  →  🥇 GOLD (Marts)
   Ingestão Bruta             Transformações                Consumo Final
   Views                      Views Reutilizáveis           Tables/Incremental
```

| Camada | Propósito | Materialização | Nomenclatura |
|--------|-----------|----------------|--------------|
| **🥉 Staging** | Ingestão 1:1 com fontes, limpeza básica | `view` | `stg_{sistema}__{entidade}` |
| **🥈 Intermediate** | Transformações reutilizáveis, regras de negócio | `view` | `int_{conceito}` |
| **🥇 Marts** | Modelos finais para consumo (dimensões/fatos) | `table`/`incremental` | `dim_{entidade}` ou `fct_{processo}` |

### 10.2 Configuração no dbt_project.yml

O arquivo `dbt_project.yml` já está configurado com estas definições:

```yaml
models:
  treinamento_dbt:
    staging:
      +materialized: view
      +schema: staging
    intermediate:
      +materialized: view
      +schema: intermediate
    marts:
      +materialized: table
      +schema: marts
```

### 10.3 Resultado no Microsoft Fabric

Quando executamos `dbt run`, o dbt criará os seguintes schemas no Fabric:

```text
DataWarehouseTreinamento/
├── dbo_staging/          # Views de ingestão
├── dbo_intermediate/     # Views de transformação
└── dbo_marts/            # Tabelas finais (dimensions + facts)
```

---

## 🏗️ 11. CONSTRUINDO: Camada Staging (Bronze)

Agora vamos construir nossa primeira camada! A camada de **staging** faz a ingestão dos dados brutos.

### 11.1 Passo 1: Criar o diretório de staging

```bash
mkdir -p treinamento_dbt/models/staging/lakehouse
```

### 11.2 Passo 2: Documentar a Source

Crie o arquivo `treinamento_dbt/models/staging/lakehouse/_lakehouse_sources.yml`:

```yaml
version: 2

sources:
  - name: lakehouse_treinamento
    description: "Lakehouse contendo dados para treinamento do time"
    database: LakehouseTreinamento
    schema: dbo
    
    # Alertas se dados estiverem desatualizados
    freshness:
      warn_after: {count: 24, period: hour}
      error_after: {count: 7, period: day}
    
    tables:
      - name: taxi
        loaded_at_field: lpepPickupDatetime
        description: "Dados de viagens de táxi do lakehouse"
        columns:
          - name: vendorID
            description: "ID do fornecedor de dados (1=CMT, 2=VTS)"
            tests:
              - not_null
          
          - name: lpepPickupDatetime
            description: "Data e hora de início da viagem"
            tests:
              - not_null
          
          - name: lpepDropoffDatetime
            description: "Data e hora de término da viagem"
          
          - name: passengerCount
            description: "Número de passageiros na viagem"
          
          - name: tripDistance
            description: "Distância da viagem em milhas"
          
          - name: puLocationId
            description: "ID da localização de pickup"
          
          - name: doLocationId
            description: "ID da localização de dropoff"
          
          - name: paymentType
            description: "Tipo de pagamento (1=Cartão, 2=Dinheiro, 3=Sem cobrança, etc.)"
          
          - name: fareAmount
            description: "Valor da tarifa"
          
          - name: totalAmount
            description: "Valor total da viagem"
```

### 11.3 Passo 3: Testar a Source

Verifique se o dbt consegue ler a source:

```powershell
.\run_dbt.ps1 "source freshness"
```

✅ **Resultado esperado:** Confirmação de que a tabela existe e está acessível.

### 11.4 Passo 4: Criar o Modelo Staging

Crie o arquivo `treinamento_dbt/models/staging/lakehouse/stg_lakehouse__taxi.sql`:

```sql
-- =====================================================
-- Staging: Dados de Táxi do Lakehouse
-- =====================================================
-- Descrição: Ingestão e limpeza básica dos dados de viagens de táxi
-- Materialização: VIEW
-- Dependências: source('lakehouse_treinamento', 'taxi')
-- =====================================================

with source as (
    -- Lê os dados da source documentada
    select * 
    from {{ source('lakehouse_treinamento', 'taxi') }}
),

filtered_source as (
    -- Filtra apenas dados até 2019
    select * 
    from source
    where year(lpepPickupDatetime) <= 2019 
       or year(lpepDropoffDatetime) <= 2019
),

unique_row as (
    -- Remove duplicatas mantendo maior totalAmount
    select *,
        ROW_NUMBER() OVER (
            PARTITION BY vendorID, lpepPickupDatetime 
            ORDER BY totalAmount DESC
        ) AS row_num
    from filtered_source
),

filtered as (
    -- Mantém apenas primeira linha de cada grupo
    select * 
    from unique_row
    where row_num = 1
),

with_sk_id as (
    -- Cria surrogate key única para cada viagem
    select *,
        HASHBYTES(
            'SHA2_256', 
            CONCAT_WS(
                '|',
                vendorID,
                CAST(lpepPickupDatetime AS VARCHAR(50))
            )
        ) AS sk_id
    from filtered
)

-- Retorna todos os campos incluindo a surrogate key
select * 
from with_sk_id
```

### 11.5 Passo 5: Executar o Modelo Staging

```powershell
.\run_dbt.ps1 "run --select stg_lakehouse__taxi"
```

✅ **Resultado esperado:**
```
Completed successfully
1 of 1 OK created view model dbo_staging.stg_lakehouse__taxi
```

### 11.6 Passo 6: Explorar os Dados Criados

Agora que a view foi criada, vamos explorar os dados para entender o que foi construído.

**Consulta 1: Ver estrutura e primeiros registros**
```sql
-- Ver as primeiras 10 viagens
SELECT TOP 10 
    vendorID,
    lpepPickupDatetime,
    lpepDropoffDatetime,
    passengerCount,
    tripDistance,
    fareAmount,
    totalAmount,
    sk_id  -- Surrogate key criada pelo staging
FROM dbo_staging.stg_lakehouse__taxi
ORDER BY lpepPickupDatetime DESC;
```

**Consulta 2: Validar remoção de duplicatas**
```sql
-- Verificar se existem duplicatas (deve retornar 0)
SELECT 
    vendorID,
    lpepPickupDatetime,
    COUNT(*) as qtd_registros
FROM dbo_staging.stg_lakehouse__taxi
GROUP BY vendorID, lpepPickupDatetime
HAVING COUNT(*) > 1;
```

**Consulta 3: Estatísticas gerais**
```sql
-- Estatísticas dos dados de staging
SELECT 
    COUNT(*) as total_viagens,
    COUNT(DISTINCT vendorID) as total_vendors,
    MIN(lpepPickupDatetime) as primeira_viagem,
    MAX(lpepPickupDatetime) as ultima_viagem,
    AVG(tripDistance) as distancia_media,
    AVG(totalAmount) as valor_medio,
    SUM(totalAmount) as receita_total
FROM dbo_staging.stg_lakehouse__taxi;
```

**Consulta 4: Distribuição por vendor**
```sql
-- Quantas viagens por fornecedor
SELECT 
    vendorID,
    COUNT(*) as total_viagens,
    AVG(tripDistance) as distancia_media,
    AVG(totalAmount) as valor_medio,
    MIN(lpepPickupDatetime) as primeira_viagem,
    MAX(lpepPickupDatetime) as ultima_viagem
FROM dbo_staging.stg_lakehouse__taxi
GROUP BY vendorID
ORDER BY vendorID;
```

**Consulta 5: Validar filtro de ano**
```sql
-- Verificar se todas as viagens são até 2019
SELECT 
    YEAR(lpepPickupDatetime) as ano_pickup,
    YEAR(lpepDropoffDatetime) as ano_dropoff,
    COUNT(*) as quantidade
FROM dbo_staging.stg_lakehouse__taxi
GROUP BY YEAR(lpepPickupDatetime), YEAR(lpepDropoffDatetime)
ORDER BY ano_pickup, ano_dropoff;
```

💡 **Interpretação dos Resultados:**
- **Total de viagens**: Deve mostrar todas as viagens após remoção de duplicatas
- **Surrogate key (sk_id)**: Cada viagem tem um identificador único em hash
- **Anos**: Apenas viagens até 2019 devem aparecer
- **Vendors**: Normalmente 2 vendors (1=CMT, 2=VTS)

### 11.7 Passo 7: Validar Qualidade dos Dados

Execute consultas para garantir a qualidade:

```sql
-- 1. Verificar registros com valores nulos em campos críticos
SELECT 
    COUNT(*) as total,
    COUNT(vendorID) as com_vendor,
    COUNT(lpepPickupDatetime) as com_pickup_date,
    COUNT(totalAmount) as com_total_amount,
    COUNT(*) - COUNT(vendorID) as sem_vendor,
    COUNT(*) - COUNT(lpepPickupDatetime) as sem_pickup_date
FROM dbo_staging.stg_lakehouse__taxi;

-- 2. Verificar viagens com valores negativos (não deveria haver)
SELECT 
    COUNT(*) as viagens_valor_negativo
FROM dbo_staging.stg_lakehouse__taxi
WHERE totalAmount < 0 OR fareAmount < 0 OR tripDistance < 0;

-- 3. Verificar viagens com data de dropoff antes de pickup (anomalia)
SELECT 
    COUNT(*) as viagens_anomalas,
    MIN(DATEDIFF(MINUTE, lpepPickupDatetime, lpepDropoffDatetime)) as menor_duracao_minutos
FROM dbo_staging.stg_lakehouse__taxi
WHERE lpepDropoffDatetime < lpepPickupDatetime;
```

✅ **Resultados esperados:**
- Campos críticos não devem ter nulos (vendorID, lpepPickupDatetime)
- Não deve haver valores negativos em distância/valores
- Dropoff sempre deve ser após pickup

### 11.8 Passo 8: Validar no Fabric (Interface Gráfica)

Acesse o **Microsoft Fabric** e verifique:
1. Schema `dbo_staging` foi criado
2. View `stg_lakehouse__taxi` existe
3. Consulte alguns registros para validar

```sql
SELECT TOP 10 * 
FROM dbo_staging.stg_lakehouse__taxi
```

✅ **Checkpoint:** Camada Staging criada com sucesso! Você agora tem uma view limpa dos dados brutos com qualidade validada.

---

## 🔄 12. CONSTRUINDO: Camada Intermediate (Silver)

A camada intermediate prepara componentes reutilizáveis. Aqui criaremos **6 dimensões intermediárias** a partir dos dados de táxi.

### 12.1 Criar o diretório intermediate

```bash
mkdir -p treinamento_dbt/models/intermediate/lakehouse
```

### 12.2 Modelo 1: int_dim_date (Calendário Completo)

**Objetivo:** Gerar todas as datas entre a menor e maior data das viagens com atributos de calendário.

Crie `treinamento_dbt/models/intermediate/lakehouse/int_dim_date.sql`:

```sql
-- =====================================================
-- Intermediate: Dimensão de Data
-- =====================================================
-- Gera um calendário completo entre min e max das viagens
-- com todos os atributos de data úteis para análise
--=====================================================

WITH source_data AS (
    SELECT *
    from {{ ref('stg_lakehouse__taxi') }}
    WHERE year(lpepPickupDatetime) <= 2019 OR year(lpepDropoffDatetime) <= 2019
),

date_bounds AS (
    -- Encontra a data mínima e máxima
    SELECT 
        MIN(CAST(lpepPickupDatetime AS DATE)) AS min_date,
        MAX(CAST(lpepPickupDatetime AS DATE)) AS max_date
    FROM source_data
),

-- Gerador de números (0 a 9)
ten_rows AS (
    SELECT 1 AS n UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL
    SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
),

-- Gera sequência grande de dias (10 x 10 x 10 x 10 x 10 = 100.000 dias ~ 274 anos)
number_series AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM ten_rows a
    CROSS JOIN ten_rows b
    CROSS JOIN ten_rows c
    CROSS JOIN ten_rows d
    CROSS JOIN ten_rows e
),

-- Gera as datas brutas
raw_dates AS (
    SELECT 
        CAST(DATEADD(DAY, ns.n, db.min_date) AS DATE) AS date_value
    FROM date_bounds db
    CROSS JOIN number_series ns
    WHERE DATEADD(DAY, ns.n, db.min_date) <= db.max_date
),

-- Adiciona todos os atributos de data
date_attributes AS (
    SELECT
        date_value AS date,
        YEAR(date_value) AS year,
        MONTH(date_value) AS month,
        DAY(date_value) AS day_of_month,
        DATENAME(MONTH, date_value) AS month_name,
        LEFT(DATENAME(MONTH, date_value), 3) AS month_name_abbrev,
        DATENAME(WEEKDAY, date_value) AS day_of_week_name,
        LEFT(DATENAME(WEEKDAY, date_value), 3) AS day_of_week_abbrev,
        DATEPART(WEEKDAY, date_value) AS day_of_week_num,
        CASE WHEN DATEPART(WEEKDAY, date_value) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend,
        DATEPART(QUARTER, date_value) AS quarter,
        CONCAT('Q', DATEPART(QUARTER, date_value), '-', YEAR(date_value)) AS year_quarter,
        CEILING(MONTH(date_value) / 2.0) AS bimester,
        CEILING(MONTH(date_value) / 6.0) AS semester,
        CONCAT('S', CEILING(MONTH(date_value) / 6.0), '-', YEAR(date_value)) AS year_semester,
        CEILING(DAY(date_value) / 15.0) AS fortnight,
        DATEPART(DAYOFYEAR, date_value) AS day_of_year,
        DATEPART(WEEK, date_value) AS week_of_year
    FROM raw_dates
)

SELECT * FROM date_attributes
ORDER BY date
```

### 12.3 Modelo 2: int_dim_location (Localizações)

**Objetivo:** Extrair todos os IDs únicos de localização (pickup + dropoff).

Crie `treinamento_dbt/models/intermediate/lakehouse/int_dim_location.sql`:

```sql
-- =====================================================
-- Intermediate: Dimensão de Localização
-- =====================================================
-- Extrai IDs únicos de localização (pickup e dropoff)
-- e cria surrogate key para cada localização
-- =====================================================

with sg_taxi as (
    select *
    from {{ ref('stg_lakehouse__taxi') }}
),

location as (
    -- União de localizações de pickup
    select distinct puLocationId as location_id
    from sg_taxi
    
    UNION
    
    -- União de localizações de dropoff
    select distinct doLocationId as location_id
    from sg_taxi
),

dim_location as (
    select
        distinct location_id,
        HASHBYTES(
            'SHA2_256',
            CAST(location_id AS VARCHAR(50))
        ) AS sk_location_id
    from location
)

select *
from dim_location
```

### 12.4 Modelo 3: int_dim_vendor (Fornecedores)

**Objetivo:** Criar dimensão de fornecedores com nomes descritivos.

Crie `treinamento_dbt/models/intermediate/lakehouse/int_dim_vendor.sql`:

```sql
-- =====================================================
-- Intermediate: Dimensão de Fornecedor
-- =====================================================
-- Lista de fornecedores de dados com nomes descritivos
-- =====================================================

WITH vendor_data AS (
    -- Busca os IDs únicos da camada de staging
    SELECT DISTINCT 
        CAST("vendorID" AS INT) AS vendor_id
    from {{ ref('stg_lakehouse__taxi') }}
    WHERE "vendorID" IS NOT NULL
)

SELECT
    vendor_id,
    CASE vendor_id
        WHEN 1 THEN 'Creative Mobile Technologies'
        WHEN 2 THEN 'VeriFone Inc.'
        ELSE 'Unknown/Other'
    END AS vendor_name,
    CASE vendor_id
        WHEN 1 THEN 'CMT'
        WHEN 2 THEN 'VTS'
        ELSE 'UNK'
    END AS vendor_abbreviation
FROM vendor_data
```

### 12.5 Modelo 4: int_dim_payment_type (Tipos de Pagamento)

Crie `treinamento_dbt/models/intermediate/lakehouse/int_dim_payment_type.sql`:

```sql
-- =====================================================
-- Intermediate: Dimensão de Tipo de Pagamento
-- =====================================================
-- Mapeia códigos de pagamento para descrições legíveis
-- =====================================================

WITH data AS (
    SELECT DISTINCT paymentType as payment_type
    FROM {{ ref('stg_lakehouse__taxi') }}
    WHERE paymentType IS NOT NULL
)

SELECT
    payment_type,
    CASE payment_type
        WHEN 1 THEN 'Credit card'
        WHEN 2 THEN 'Cash'
        WHEN 3 THEN 'No charge'
        WHEN 4 THEN 'Dispute'
        WHEN 5 THEN 'Unknown'
        ELSE 'Not Specified'
    END AS payment_type_name
FROM data
```

### 12.6 Modelo 5: int_dim_rate_code (Códigos de Tarifa)

Crie `treinamento_dbt/models/intermediate/lakehouse/int_dim_rate_code.sql`:

```sql
-- =====================================================
-- Intermediate: Dimensão de Rate Code
-- =====================================================
-- Mapeia códigos de tarifa para descrições legíveis
-- =====================================================

WITH data AS (
    SELECT DISTINCT rateCodeId as rate_code_id
    FROM {{ ref('stg_lakehouse__taxi') }}
    WHERE rateCodeId IS NOT NULL
)

SELECT
    rate_code_id,
    CASE rate_code_id
        WHEN 1 THEN 'Standard rate'
        WHEN 2 THEN 'JFK'
        WHEN 3 THEN 'Newark'
        WHEN 4 THEN 'Nassau or Westchester'
        WHEN 5 THEN 'Negotiated fare'
        WHEN 6 THEN 'Group ride'
        ELSE 'Unknown'
    END AS rate_code_name
FROM data
```

### 12.7 Modelo 6: int_dim_time (Horários do Dia)

Crie `treinamento_dbt/models/intermediate/lakehouse/int_dim_time.sql`:

```sql
-- =====================================================
-- Intermediate: Dimensão de Tempo (Horário do Dia)
-- =====================================================
-- Gera todos os horários do dia (00:00 a 23:59)
-- com atributos úteis para análise temporal
-- =====================================================

WITH hour_series AS (
    -- Gera números de 0 a 23 (horas)
    SELECT TOP 24 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS hour_num
    FROM sys.objects
),

minute_series AS (
    -- Gera números de 0 a 59 (minutos)
    SELECT TOP 60 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS minute_num
    FROM sys.objects
),

time_combinations AS (
    SELECT
        h.hour_num,
        m.minute_num,
        CAST(FORMAT(h.hour_num, '00') + ':' + FORMAT(m.minute_num, '00') + ':00' AS TIME) AS time_value
    FROM hour_series h
    CROSS JOIN minute_series m
),

time_attributes AS (
    SELECT
        time_value,
        hour_num AS hour,
        minute_num AS minute,
        CASE 
            WHEN hour_num BETWEEN 0 AND 5 THEN 'Madrugada'
            WHEN hour_num BETWEEN 6 AND 11 THEN 'Manhã'
            WHEN hour_num BETWEEN 12 AND 17 THEN 'Tarde'
            ELSE 'Noite'
        END AS period_of_day,
        CASE 
            WHEN hour_num BETWEEN 7 AND 9 OR hour_num BETWEEN 17 AND 19 THEN 1
            ELSE 0
        END AS is_rush_hour
    FROM time_combinations
)

SELECT * FROM time_attributes
ORDER BY time_value
```

### 12.8 Executar Todos os Modelos Intermediate

```powershell
.\run_dbt.ps1 "run --select intermediate"
```

✅ **Resultado esperado:**
```
Completed successfully
6 of 6 OK created view model dbo_intermediate.int_dim_date
6 of 6 OK created view model dbo_intermediate.int_dim_location  
6 of 6 OK created view model dbo_intermediate.int_dim_vendor
6 of 6 OK created view model dbo_intermediate.int_dim_payment_type
6 of 6 OK created view model dbo_intermediate.int_dim_rate_code
6 of 6 OK created view model dbo_intermediate.int_dim_time
```

### 12.9 Explorar os Dados Criados

Agora vamos validar cada dimensão intermediária criada com consultas práticas.

**📅 Consulta 1: Dimensão de Data (int_dim_date)**
```sql
-- Ver primeiras e últimas datas do calendário
SELECT TOP 5 
    date,
    year,
    month,
    month_name,
    day_of_week_name,
    is_weekend,
    quarter,
    year_quarter
FROM dbo_intermediate.int_dim_date
ORDER BY date;

-- Última data
SELECT TOP 5 
    date,
    day_of_week_name,
    is_weekend
FROM dbo_intermediate.int_dim_date
ORDER BY date DESC;

-- Estatísticas do calendário
SELECT 
    COUNT(*) as total_dias,
    MIN(date) as primeira_data,
    MAX(date) as ultima_data,
    COUNT(CASE WHEN is_weekend = 1 THEN 1 END) as dias_fim_semana,
    COUNT(CASE WHEN is_weekend = 0 THEN 1 END) as dias_uteis
FROM dbo_intermediate.int_dim_date;
```

**📍 Consulta 2: Dimensão de Localização (int_dim_location)**
```sql
-- Ver todas as localizações únicas
SELECT TOP 10
    location_id,
    sk_location_id
FROM dbo_intermediate.int_dim_location
ORDER BY location_id;

-- Estatísticas
SELECT 
    COUNT(*) as total_localizacoes,
    MIN(location_id) as menor_id,
    MAX(location_id) as maior_id
FROM dbo_intermediate.int_dim_location;
```

**🚖 Consulta 3: Dimensão de Vendor (int_dim_vendor)**
```sql
-- Ver todos os vendors
SELECT 
    vendor_id,
    vendor_name,
    vendor_abbreviation
FROM dbo_intermediate.int_dim_vendor
ORDER BY vendor_id;
```

**💳 Consulta 4: Dimensão de Tipo de Pagamento (int_dim_payment_type)**
```sql
-- Ver todos os tipos de pagamento
SELECT 
    payment_type,
    payment_type_name
FROM dbo_intermediate.int_dim_payment_type
ORDER BY payment_type;
```

**💰 Consulta 5: Dimensão de Rate Code (int_dim_rate_code)**
```sql
-- Ver todos os códigos de tarifa
SELECT 
    rate_code_id,
    rate_code_name
FROM dbo_intermediate.int_dim_rate_code
ORDER BY rate_code_id;
```

**🕐 Consulta 6: Dimensão de Tempo (int_dim_time)**
```sql
-- Ver primeiros horários do dia
SELECT TOP 20
    time_value,
    hour,
    minute,
    period_of_day,
    is_rush_hour
FROM dbo_intermediate.int_dim_time
ORDER BY time_value;

-- Horários de pico (rush hour)
SELECT 
    time_value,
    hour,
    period_of_day
FROM dbo_intermediate.int_dim_time
WHERE is_rush_hour = 1
ORDER BY time_value;

-- Estatísticas por período do dia
SELECT 
    period_of_day,
    COUNT(*) as total_minutos,
    COUNT(CASE WHEN is_rush_hour = 1 THEN 1 END) as minutos_pico
FROM dbo_intermediate.int_dim_time
GROUP BY period_of_day
ORDER BY 
    CASE period_of_day
        WHEN 'Madrugada' THEN 1
        WHEN 'Manhã' THEN 2
        WHEN 'Tarde' THEN 3
        WHEN 'Noite' THEN 4
    END;
```

**📊 Consulta 7: Resumo Geral de Todas as Dimensões**
```sql
-- Contagem de registros em cada dimensão intermediate
SELECT 'int_dim_date' as dimensao, COUNT(*) as total_registros 
FROM dbo_intermediate.int_dim_date
UNION ALL
SELECT 'int_dim_location', COUNT(*) 
FROM dbo_intermediate.int_dim_location
UNION ALL
SELECT 'int_dim_vendor', COUNT(*) 
FROM dbo_intermediate.int_dim_vendor
UNION ALL
SELECT 'int_dim_payment_type', COUNT(*) 
FROM dbo_intermediate.int_dim_payment_type
UNION ALL
SELECT 'int_dim_rate_code', COUNT(*) 
FROM dbo_intermediate.int_dim_rate_code
UNION ALL
SELECT 'int_dim_time', COUNT(*) 
FROM dbo_intermediate.int_dim_time
ORDER BY total_registros DESC;
```

💡 **Resultados Esperados:**
- **int_dim_date**: ~1.500 datas (do mínimo ao máximo das viagens)
- **int_dim_location**: ~260 localizações únicas
- **int_dim_vendor**: 2 vendors (CMT e VTS)
- **int_dim_payment_type**: ~5 tipos de pagamento
- **int_dim_rate_code**: ~6 códigos de tarifa
- **int_dim_time**: 1.440 registros (24h × 60min)

### 12.10 Validar no Fabric
```sql
-- Verificar quantidade de registros em cada view
SELECT COUNT(*) FROM dbo_intermediate.int_dim_date;        -- ~1.500 datas
SELECT COUNT(*) FROM dbo_intermediate.int_dim_location;    -- ~260 localizações
SELECT COUNT(*) FROM dbo_intermediate.int_dim_vendor;      -- 2 vendors
SELECT COUNT(*) FROM dbo_intermediate.int_dim_payment_type; -- ~5 tipos
SELECT COUNT(*) FROM dbo_intermediate.int_dim_rate_code;   -- ~6 códigos
SELECT COUNT(*) FROM dbo_intermediate.int_dim_time;        -- 1.440 minutos (24h x 60min)
```

✅ **Checkpoint:** Camada Intermediate criada! Agora temos componentes reutilizáveis prontos e validados com dados reais.

---

## 🎯 13. CONSTRUINDO: Camada Marts - Dimensions (Gold)

Agora vamos criar as **dimensões finais** do Data Warehouse. Estas serão **tabelas materializadas** para melhor performance.

### 13.1 Criar o diretório marts

```bash
mkdir -p treinamento_dbt/models/marts/dimensions
```

### 13.2 Dimensão 1: dim_date (Incremental)

**Objetivo:** Dimensão de data otimizada com carga incremental.

Crie `treinamento_dbt/models/marts/dimensions/dim_date.sql`:

```sql
-- =====================================================
-- Marts: Dimensão de Data (INCREMENTAL)
-- =====================================================
-- Dimensão conformed de data para todo o Data Warehouse
-- Materialização: INCREMENTAL para performance
-- =====================================================

{{
    config(
        materialized='incremental',
        unique_key='date',
        on_schema_change='fail'
    )
}}

WITH data AS (
    SELECT *
    FROM {{ ref ('int_dim_date') }}
    {% if is_incremental() %}
    -- Processa apenas datas que ainda não existem na tabela
    WHERE date > (SELECT MAX(date) FROM {{ this }})
    {% endif %}
)

SELECT 
    date,
    year,
    month,
    day_of_month,
    month_name,
    month_name_abbrev,
    day_of_week_name,
    day_of_week_abbrev,
    day_of_week_num,
    is_weekend,
    quarter,
    year_quarter,
    bimester,
    semester,
    year_semester,
    fortnight,
    day_of_year,
    week_of_year
FROM data
ORDER BY date
```

Crie `treinamento_dbt/models/marts/dimensions/dim_date.yml`:

```yaml
version: 2

models:
  - name: dim_date
    description: "Dimensão conformed de data com todos os atributos de calendário"
    columns:
      - name: date
        description: "Data (chave primária)"
        tests:
          - unique
          - not_null
      
      - name: year
        description: "Ano (YYYY)"
        tests:
          - not_null
      
      - name: month
        description: "Mês (1-12)"
        tests:
          - not_null
      
      - name: is_weekend
        description: "Indicador de final de semana (0=Não, 1=Sim)"
      
      - name: quarter
        description: "Trimestre (1-4)"
```

### 13.3 Dimensão 2: dim_location

Crie `treinamento_dbt/models/marts/dimensions/dim_location.sql`:

```sql
-- =====================================================
-- Marts: Dimensão de Localização
-- =====================================================

WITH data AS (
    SELECT *
    FROM {{ ref ('int_dim_location') }}
)

SELECT 
    location_id,
    sk_location_id
FROM data
ORDER BY location_id
```

Crie `treinamento_dbt/models/marts/dimensions/dim_location.yml`:

```yaml
version: 2

models:
  - name: dim_location
    description: "Dimensão de localizações (zonas de táxi)"
    columns:
      - name: location_id
        description: "ID da localização (chave primária)"
        tests:
          - unique
          - not_null
      
      - name: sk_location_id
        description: "Surrogate key da localização"
```

### 13.4 Dimensão 3: dim_vendor

Crie `treinamento_dbt/models/marts/dimensions/dim_vendor.sql`:

```sql
-- =====================================================
-- Marts: Dimensão de Fornecedor
-- =====================================================

WITH data AS (
    SELECT *
    FROM {{ ref ('int_dim_vendor') }}
)

SELECT 
    vendor_id,
    vendor_name,
    vendor_abbreviation
FROM data
ORDER BY vendor_id
```

Crie `treinamento_dbt/models/marts/dimensions/dim_vendor.yml`:

```yaml
version: 2

models:
  - name: dim_vendor
    description: "Dimensão de fornecedores de dados"
    columns:
      - name: vendor_id
        description: "ID do fornecedor (chave primária)"
        tests:
          - unique
          - not_null
      
      - name: vendor_name
        description: "Nome completo do fornecedor"
      
      - name: vendor_abbreviation
        description: "Sigla do fornecedor"
```

### 13.5 Dimensão 4: dim_payment_type

Crie `treinamento_dbt/models/marts/dimensions/dim_payment_type.sql`:

```sql
-- =====================================================
-- Marts: Dimensão de Tipo de Pagamento
-- =====================================================

WITH data AS (
    SELECT *
    FROM {{ ref ('int_dim_payment_type') }}
)

SELECT 
    payment_type,
    payment_type_name
FROM data
ORDER BY payment_type
```

Crie `treinamento_dbt/models/marts/dimensions/dim_payment_type.yml`:

```yaml
version: 2

models:
  - name: dim_payment_type
    description: "Dimensão de tipos de pagamento"
    columns:
      - name: payment_type
        description: "Código do tipo de pagamento (chave primária)"
        tests:
          - unique
          - not_null
      
      - name: payment_type_name
        description: "Descrição do tipo de pagamento"
```

### 13.6 Dimensão 5: dim_rate_code

Crie `treinamento_dbt/models/marts/dimensions/dim_rate_code.sql`:

```sql
-- =====================================================
-- Marts: Dimensão de Rate Code
-- =====================================================

WITH data AS (
    SELECT *
    FROM {{ ref ('int_dim_rate_code') }}
)

SELECT 
    rate_code_id,
    rate_code_name
FROM data
ORDER BY rate_code_id
```

Crie `treinamento_dbt/models/marts/dimensions/dim_rate_code.yml`:

```yaml
version: 2

models:
  - name: dim_rate_code
    description: "Dimensão de códigos de tarifa"
    columns:
      - name: rate_code_id
        description: "ID do código de tarifa (chave primária)"
        tests:
          - unique
          - not_null
      
      - name: rate_code_name
        description: "Descrição do código de tarifa"
```

### 13.7 Dimensão 6: dim_time

Crie `treinamento_dbt/models/marts/dimensions/dim_time.sql`:

```sql
-- =====================================================
-- Marts: Dimensão de Tempo
-- =====================================================

WITH data AS (
    SELECT *
    FROM {{ ref ('int_dim_time') }}
)

SELECT 
    time_value,
    hour,
    minute,
    period_of_day,
    is_rush_hour
FROM data
ORDER BY time_value
```

Crie `treinamento_dbt/models/marts/dimensions/dim_time.yml`:

```yaml
version: 2

models:
  - name: dim_time
    description: "Dimensão de tempo (horários do dia)"
    columns:
      - name: time_value
        description: "Hora e minuto (HH:MM:SS) - chave primária"
        tests:
          - unique
          - not_null
      
      - name: hour
        description: "Hora (0-23)"
      
      - name: minute
        description: "Minuto (0-59)"
      
      - name: period_of_day
        description: "Período do dia (Madrugada, Manhã, Tarde, Noite)"
      
      - name: is_rush_hour
        description: "Indica horário de pico (0=Não, 1=Sim)"
```

### 13.8 Executar Todas as Dimensões

```powershell
.\run_dbt.ps1 "run --select marts.dimensions"
```

✅ **Resultado esperado:**
```
Completed successfully
6 of 6 OK created table model dbo_marts.dim_date
6 of 6 OK created table model dbo_marts.dim_location
6 of 6 OK created table model dbo_marts.dim_vendor
6 of 6 OK created table model dbo_marts.dim_payment_type
6 of 6 OK created table model dbo_marts.dim_rate_code
6 of 6 OK created table model dbo_marts.dim_time
```

### 13.9 Executar Testes de Qualidade

```powershell
.\run_dbt.ps1 "test --select marts.dimensions"
```

✅ **Resultado esperado:** Todos os testes de `unique` e `not_null` devem passar.

### 13.10 Explorar as Dimensões Criadas

Agora que as dimensões finais foram materializadas como **tabelas**, vamos explorar os dados com consultas analíticas.

**📅 Consulta 1: Explorar dim_date (Dimensão de Data)**
```sql
-- Ver estrutura completa da dimensão
SELECT TOP 10 
    date,
    year,
    month,
    day_of_month,
    month_name,
    day_of_week_name,
    is_weekend,
    quarter,
    year_quarter,
    semester,
    week_of_year
FROM dbo_marts.dim_date
ORDER BY date DESC;

-- Análise de finais de semana por ano
SELECT 
    year,
    COUNT(*) as total_dias,
    SUM(is_weekend) as dias_fim_semana,
    COUNT(*) - SUM(is_weekend) as dias_uteis,
    CAST(SUM(is_weekend) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as pct_fim_semana
FROM dbo_marts.dim_date
GROUP BY year
ORDER BY year;

-- Distribuição de dias por trimestre
SELECT 
    year_quarter,
    COUNT(*) as total_dias,
    MIN(date) as primeira_data,
    MAX(date) as ultima_data
FROM dbo_marts.dim_date
GROUP BY year_quarter
ORDER BY year_quarter;
```

**📍 Consulta 2: Explorar dim_location (Dimensão de Localização)**
```sql
-- Ver todas as localizações
SELECT 
    location_id,
    sk_location_id
FROM dbo_marts.dim_location
ORDER BY location_id;

-- Estatísticas de localizações
SELECT 
    COUNT(*) as total_localizacoes,
    MIN(location_id) as menor_location_id,
    MAX(location_id) as maior_location_id
FROM dbo_marts.dim_location;
```

**🚖 Consulta 3: Explorar dim_vendor (Dimensão de Fornecedor)**
```sql
-- Ver detalhes de todos os vendors
SELECT 
    vendor_id,
    vendor_name,
    vendor_abbreviation
FROM dbo_marts.dim_vendor
ORDER BY vendor_id;
```

**💳 Consulta 4: Explorar dim_payment_type (Dimensão de Pagamento)**
```sql
-- Ver todos os tipos de pagamento disponíveis
SELECT 
    payment_type,
    payment_type_name
FROM dbo_marts.dim_payment_type
ORDER BY payment_type;
```

**💰 Consulta 5: Explorar dim_rate_code (Dimensão de Tarifa)**
```sql
-- Ver todos os códigos de tarifa
SELECT 
    rate_code_id,
    rate_code_name
FROM dbo_marts.dim_rate_code
ORDER BY rate_code_id;
```

**🕐 Consulta 6: Explorar dim_time (Dimensão de Tempo)**
```sql
-- Ver primeiros e últimos horários
SELECT TOP 10
    time_value,
    hour,
    minute,
    period_of_day,
    is_rush_hour
FROM dbo_marts.dim_time
ORDER BY time_value;

-- Análise de horários de pico por período do dia
SELECT 
    period_of_day,
    COUNT(*) as total_minutos,
    SUM(is_rush_hour) as minutos_pico,
    CAST(SUM(is_rush_hour) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as pct_pico
FROM dbo_marts.dim_time
GROUP BY period_of_day
ORDER BY 
    CASE period_of_day
        WHEN 'Madrugada' THEN 1
        WHEN 'Manhã' THEN 2
        WHEN 'Tarde' THEN 3
        WHEN 'Noite' THEN 4
    END;
```

**🔍 Consulta 7: Análise Cross-Dimensional (Combinando Dimensões)**
```sql
-- Criar dataset combinado para análise
-- Exemplo: Todas as combinações de Data x Vendor x Tipo de Pagamento
SELECT TOP 100
    d.date,
    d.day_of_week_name,
    d.is_weekend,
    v.vendor_name,
    p.payment_type_name,
    r.rate_code_name
FROM dbo_marts.dim_date d
CROSS JOIN dbo_marts.dim_vendor v
CROSS JOIN dbo_marts.dim_payment_type p
CROSS JOIN dbo_marts.dim_rate_code r
WHERE d.year = 2019 AND d.month = 12  -- Filtro para reduzir resultados
ORDER BY d.date DESC, v.vendor_name, p.payment_type_name;

-- Análise de dias úteis vs finais de semana
SELECT 
    CASE WHEN d.is_weekend = 1 THEN 'Fim de Semana' ELSE 'Dia Útil' END as tipo_dia,
    COUNT(DISTINCT d.date) as total_dias
FROM dbo_marts.dim_date d
GROUP BY d.is_weekend
ORDER BY d.is_weekend;
```

**📊 Consulta 8: Resumo Geral de Todas as Dimensões**
```sql
-- Contagem de registros em cada dimensão final
SELECT 'dim_date' as dimensao, COUNT(*) as total_registros, 'Tabela' as tipo
FROM dbo_marts.dim_date
UNION ALL
SELECT 'dim_location', COUNT(*), 'Tabela'
FROM dbo_marts.dim_location
UNION ALL
SELECT 'dim_vendor', COUNT(*), 'Tabela'
FROM dbo_marts.dim_vendor
UNION ALL
SELECT 'dim_payment_type', COUNT(*), 'Tabela'
FROM dbo_marts.dim_payment_type
UNION ALL
SELECT 'dim_rate_code', COUNT(*), 'Tabela'
FROM dbo_marts.dim_rate_code
UNION ALL
SELECT 'dim_time', COUNT(*), 'Tabela'
FROM dbo_marts.dim_time
ORDER BY total_registros DESC;
```

💡 **Insights das Dimensões:**
- **dim_date**: Base temporal completa para análises históricas
- **dim_location**: Permite análise geográfica das viagens
- **dim_vendor**: Comparação entre fornecedores de dados
- **dim_payment_type**: Análise de preferências de pagamento
- **dim_rate_code**: Análise de tipos de tarifas aplicadas
- **dim_time**: Análise de padrões horários e períodos do dia

### 13.11 Validar no Fabric

```sql
-- Validar dimensões criadas no schema marts
SELECT COUNT(*) FROM dbo_marts.dim_date;          -- ~1.500 registros
SELECT COUNT(*) FROM dbo_marts.dim_location;      -- ~260 registros
SELECT COUNT(*) FROM dbo_marts.dim_vendor;        -- 2 registros
SELECT COUNT(*) FROM dbo_marts.dim_payment_type;  -- ~5 registros
SELECT COUNT(*) FROM dbo_marts.dim_rate_code;     -- ~6 registros
SELECT COUNT(*) FROM dbo_marts.dim_time;          -- 1.440 registros

-- Testar consulta analítica
SELECT TOP 10 
    d.date,
    d.day_of_week_name,
    d.is_weekend,
    v.vendor_name
FROM dbo_marts.dim_date d
CROSS JOIN dbo_marts.dim_vendor v
ORDER BY d.date DESC;
```

✅ **Checkpoint:** Data Warehouse dimensional criado! Todas as 6 dimensões estão prontas, validadas e com dados exploráveis.

---

## 📖 14. Documentação e Lineage

### 14.1 Gerar Documentação

O dbt gera documentação automática com lineage (linhagem) dos dados:

```powershell
.\run_dbt.ps1 "docs generate"
```

### 14.2 Visualizar Documentação

```powershell
.\run_dbt.ps1 "docs serve"
```

Isso abrirá um servidor local (geralmente `http://localhost:8080`) com:
- 📊 **Lineage Graph** - Visualização do fluxo de dados
- 📝 **Documentação** - Descriptions de todos os modelos
- ✅ **Testes** - Status de todos os testes
- 📈 **Métricas** - Tempo de execução, rows processadas

### 14.3 Navegar na Documentação

1. **Project** → Navegue pelos modelos
2. **Database** → Veja os objetos criados no Fabric
3. **Graph** → Explore o lineage visual:
   - Verde = Sources
   - Azul = Models
   - Linhas = Dependências

### 14.4 Compartilhar Documentação

Para compartilhar a documentação com o time:

**Opção 1 - Hospedar em GitHub Pages:**
1. Gerar docs: `dbt docs generate`
2. Copiar `/target/index.html` e `/target/catalog.json`
3. Publicar em GitHub Pages

**Opção 2 - Usar dbt Cloud:**
- Upload automático da documentação
- Acesso via web para todo o time

---

## 🛠️ 15. Comandos Úteis do Dia a Dia

### 15.1 Execução Seletiva

```powershell
# Executar apenas staging
.\run_dbt.ps1 "run --select staging"

# Executar apenas intermediate
.\run_dbt.ps1 "run --select intermediate"

# Executar apenas marts
.\run_dbt.ps1 "run --select marts"

# Executar um modelo específico
.\run_dbt.ps1 "run --select dim_date"

# Executar um modelo e suas dependências
.\run_dbt.ps1 "run --select +dim_date"

# Executar um modelo e seus dependentes
.\run_dbt.ps1 "run --select dim_date+"

# Executar modelos modificados
.\run_dbt.ps1 "run --select state:modified+"
```

### 15.2 Testes

```powershell
# Executar todos os testes
.\run_dbt.ps1 test

# Testar apenas staging
.\run_dbt.ps1 "test --select staging"

# Testar um modelo específico
.\run_dbt.ps1 "test --select dim_date"
```

### 15.3 Compilação e Debug

```powershell
# Compilar sem executar (ver SQL gerado)
.\run_dbt.ps1 compile

# Ver SQL compilado de um modelo
.\run_dbt.ps1 "compile --select dim_date"
# Resultado em: treinamento_dbt/target/compiled/

# Debug de conexão
.\run_dbt.ps1 debug
```

### 15.4 Freshness de Sources

```powershell
# Verificar atualização das sources
.\run_dbt.ps1 "source freshness"
```

### 15.5 Limpeza

```powershell
# Limpar diretório target
.\run_dbt.ps1 clean
```

---

## 🔍 16. Troubleshooting

### 16.1 Erros de Conexão

**Erro: "environment variable 'XXX' not found"**
```
Solução:
1. Verifique se o arquivo .env existe na raiz do projeto
2. Confirme que está usando os scripts run_dbt.ps1 ou run_dbt.sh
3. Verifique se as variáveis estão definidas corretamente no .env
```

**Erro: "Unable to connect to database"**
```
Solução:
1. Verifique se FABRIC_SERVER está correto no.env
2. Para fabric_local: Execute 'az login' e verifique a conta ativa com 'az account show'
3. Para fabric: Valide tenant_id, client_id e client_secret
4. Teste conectividade com Azure Data Studio ou outra ferramenta SQL
5. Confirme que você tem permissões no workspace Fabric
```

**Erro: "Authentication failed"**
```
Solução:
1. Para fabric_local: Token pode ter expirado, execute 'az login' novamente
2. Para fabric: Verifique as credenciais do Service Principal
3. Confirme que o Service Principal tem permissões Admin/Member no workspace
```

### 16.2 Erros de Execução

**Erro: "Compilation Error" ou "Syntax Error"**
```
Solução:
1. Execute 'dbt compile' para ver o SQL gerado
2. Verifique se há erros de sintaxe SQL no modelo
3. Confirme que todas as referências {{ ref() }} e {{ source() }} estão corretas
4. Verifique se os nomes de colunas correspondem aos dados reais
```

**Erro: "Relation does not exist"**
```
Solução:
1. Verifique se a source ou modelo referenciado existe
2. Execute os modelos upstream primeiro (ex: staging antes de intermediate)
3. Confirme que o schema está correto no profiles.yml
```

**Erro: "Column not found"**
```
Solução:
1. Verifique se a coluna existe na tabela fonte
2. Confirme se o nome da coluna está correto (case-sensitive)
3. Execute SELECT * na source para ver estrutura real
```

### 16.3 Erros de Performance

**Modelo muito lento**
```
Solução:
1. Considere usar materialização 'table' ao invés de 'view'
2. Para tabelas grandes, use materialização 'incremental'
3. Adicione índices nas tabelas finais (após o dbt run)
4. Revise queries para otimizar joins e filtros
```

**Erro: "Timeout" ou "Memory exceeded"**
```
Solução:
1. Aumente o valor de DBT_THREADS no .env (ex: DBT_THREADS=2)
2. Execute modelos em lotes menores com --select
3. Use materialização incremental para tabelas grandes
```

### 16.4 Erros de Testes

**Teste failing: "unique" ou "not_null"**
```
Solução:
1. Execute query direto no Fabric para investigar:
   SELECT column_name, COUNT(*) 
   FROM schema.table 
   GROUP BY column_name 
   HAVING COUNT(*) > 1
2. Adicione filtros ou transformações no modelo para corrigir dados
3. Se esperado, remova ou ajuste o teste
```

### 16.5 Dicas de Debug

**Ver SQL compilado:**
```powershell
.\run_dbt.ps1 compile
# Resultado em: treinamento_dbt/target/compiled/...
```

**Executar apenas um modelo para testar:**
```powershell
.\run_dbt.ps1 "run --select dim_date --full-refresh"
```

**Ver logs detalhados:**
```powershell
.\run_dbt.ps1 "run --select dim_date --debug"
```

**Verificar dependências de um modelo:**
```powershell
.\run_dbt.ps1 "list --select +dim_date+"
```

---

## 📚 17. Recursos e Próximos Passos

### 17.1 Documentação Oficial

- [dbt Documentation](https://docs.getdbt.com/) - Documentação completa do dbt
- [dbt-fabric Adapter](https://docs.getdbt.com/docs/core/connect-data-platform/fabric-setup) - Específico para Microsoft Fabric
- [Microsoft Fabric Docs](https://learn.microsoft.com/en-us/fabric/) - Documentação do Fabric
- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices) - Boas práticas oficiais

### 17.2 Evolução do Projeto

**Próximos passos recomendados:**

1. **✅ Criar Tabelas Fato**
   - `fct_taxi_trips` - Fato de viagens com métricas
   - Joins com todas as dimensões criadas
   - Materialização incremental

2. **📊 Implementar Métricas**
   - Criar métricas reutilizáveis com dbt metrics
   - Total de viagens, receita média, distância total, etc.

3. **📸 Adicionar Snapshots (SCD Type 2)**
   - Rastrear mudanças históricas em dimensões
   - Manter histórico de alterações

4. **🔍 Testes Customizados**
   - Criar macros de testes específicos do negócio
   - Validações de regras de negócio complexas

5. **🤖 CI/CD com GitHub Actions**
   - Automatizar execução do dbt em PRs
   - Deploy automático em produção
   - Testes automáticos antes de merge

6. **📈 Monitoring e Alertas**
   - Configurar alertas de freshness
   - Monitorar tempo de execução
   - Dashboard de quality checks

7. **🔐 Governança de Dados**
   - Adicionar tags para classificação
   - Documentar ownership de modelos
   - Implementar access control

### 17.3 Boas Práticas

**Sempre faça:**
- ✅ Versionar código no Git com commits descritivos
- ✅ Nunca commitar credenciais (usar `.env`)
- ✅ Documentar todos os modelos com `description`
- ✅ Implementar testes de qualidade em campos críticos
- ✅ Usar nomenclatura consistente (prefixos: stg_, int_, dim_, fct_)
- ✅ Revisar código via Pull Requests
- ✅ Executar `dbt test` antes de fazer merge
- ✅ Manter `README.md` atualizado

**Evite:**
- ❌ Hardcodear valores (usar variáveis e macros)
- ❌ Criar dependências circulares entre modelos
- ❌ Modelos muito complexos (quebrar em intermediate)
- ❌ Commit direto em main/master
- ❌ Pular testes por "falta de tempo"

### 17.4 Estrutura de Branches Recomendada

```text
main/master     → Produção (fabric com Service Principal)
develop         → Desenvolvimento (fabric_local com az login)
feature/*       → Features individuais
hotfix/*        → Correções urgentes
```

### 17.5 Template de Commit

```bash
# Formato sugerido
<tipo>: <descrição curta>

<descrição detalhada opcional>

Tipos:
- feat: Nova feature
- fix: Correção de bug
- docs: Documentação
- refactor: Refatoração
- test: Adicionar testes
- chore: Manutenção

Exemplo:
feat: adicionar dimensão de tempo com período do dia

- Criar int_dim_time com geração de horários
- Adicionar dim_time no marts
- Incluir atributos de período e horário de pico
```

### 17.6 Comunidade e Suporte

- [dbt Community Slack](https://www.getdbt.com/community/join-the-community/) - Comunidade ativa
- [dbt Discourse](https://discourse.getdbt.com/) - Fórum de discussões
- [GitHub dbt-core](https://github.com/dbt-labs/dbt-core) - Issues e contribuições
- [GitHub dbt-fabric](https://github.com/microsoft/dbt-fabric) - Adapter específico

---

## 🎓 18. Observações Finais

### ✨ O que você construiu:

Este projeto implementa um **Data Warehouse dimensional completo** seguindo as melhores práticas de engenharia de dados:

**📊 Arquitetura:**
- 🥉 **Camada Bronze (Staging)**: 1 source, 1 modelo de ingestão
- 🥈 **Camada Silver (Intermediate)**: 6 dimensões intermediárias
- 🥇 **Camada Gold (Marts)**: 6 dimensões finais otimizadas

**🔧 Infraestrutura:**
- ☁️ Totalmente integrado com **Microsoft Fabric**
- 🔐 Segurança via variáveis de ambiente e `.gitignore`
- 🚀 Scripts automatizados para facilitar execução
- 📝 Documentação completa com lineage automático
- ✅ Testes de qualidade implementados

**📈 Boas Práticas:**
- Arquitetura Medallion (Bronze/Silver/Gold)
- Separação de responsabilidades por camada
- Nomenclatura consistente e descritiva
- Código versionado e documentado
- Estratégias de materialização otimizadas

### 🎯 Benefícios Alcançados:

1. **Replicabilidade** - Qualquer pessoa pode seguir este README e recriar o projeto
2. **Manutenibilidade** - Código organizado e documentado
3. **Escalabilidade** - Arquitetura preparada para crescer
4. **Qualidade** - Testes garantem integridade dos dados
5. **Performance** - Materializações otimizadas por caso de uso
6. **Colaboração** - Documentação facilita trabalho em equipe

### 🚀 Próxima Jornada:

Você agora tem uma **base sólida** para:
- Adicionar novas fontes de dados
- Criar tabelas fato complexas
- Implementar métricas de negócio
- Automatizar com CI/CD
- Escalar para produção

---

**🎉 Parabéns!** Você completou o treinamento de dbt com Microsoft Fabric.

Este projeto está pronto para ser usado como:
- 📚 **Material de treinamento** para novos membros do time
- 🏗️ **Template** para novos projetos dbt
- 📖 **Referência** de boas práticas
- 🎯 **Base** para evolução contínua

**Continue aprendendo e construindo! 🚀**

---

_Última atualização: Fevereiro 2026_
