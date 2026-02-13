#!/bin/bash
# filepath: .devcontainer/post-create.sh

set -e

echo "🚀 Configurando ambiente de desenvolvimento..."

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar se estamos no diretório correto
if [ ! -f "requirements.txt" ]; then
    echo -e "${YELLOW}⚠️  Aviso: requirements.txt não encontrado na raiz${NC}"
fi

# Verificar instalação do Python e pip
echo -e "${BLUE}🐍 Verificando Python...${NC}"
python --version
pip --version

# Verificar instalação do dbt
echo -e "${BLUE}📦 Verificando dbt...${NC}"
dbt --version

# Verificar Azure CLI
echo -e "${BLUE}☁️  Verificando Azure CLI...${NC}"
az --version

# Verificar ODBC Driver
echo -e "${BLUE}🔌 Verificando ODBC Driver...${NC}"
odbcinst -j
echo ""
echo "Drivers ODBC disponíveis:"
odbcinst -q -d || echo "Nenhum driver ODBC configurado"

# Criar diretórios necessários (se não existirem)
echo -e "${BLUE}📁 Criando estrutura de diretórios...${NC}"
mkdir -p treinamento_dbt/{models/{staging,intermediate,marts},tests,macros,seeds,snapshots,analyses}

# Configurar Git safe directory
echo -e "${BLUE}🔐 Configurando Git safe directory...${NC}"
git config --global --add safe.directory /workspace

# Criar .env.sample se não existir
if [ ! -f ".env.sample" ]; then
    echo -e "${BLUE}📝 Criando .env.sample...${NC}"
    cat > .env.sample << 'EOF'
# =====================================================
# DBT Database Configuration - TEMPLATE
# =====================================================
# Copie este arquivo para .env e preencha com suas credenciais

# ========== PERFIL ATIVO ==========
DBT_TARGET=fabric_local

# ========== FABRIC LOCAL (Desenvolvimento com az login) ==========
FABRIC_SERVER=your-workspace.datawarehouse.fabric.microsoft.com
FABRIC_DATABASE=DataWarehouseTreinamento
FABRIC_SCHEMA=dbo

# ========== FABRIC (Service Principal - Produção) ==========
# FABRIC_TENANT_ID=your-tenant-id
# FABRIC_CLIENT_ID=your-client-id
# FABRIC_CLIENT_SECRET=your-client-secret

# ========== CONFIGURAÇÕES GERAIS ==========
ODBC_DRIVER=ODBC Driver 18 for SQL Server
DBT_THREADS=4
EOF
fi

# Criar .gitignore se não existir
if [ ! -f ".gitignore" ]; then
    echo -e "${BLUE}📝 Criando .gitignore...${NC}"
    cat > .gitignore << 'EOF'
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
EOF
fi

# Verificar se .env existe (sem exibir conteúdo por segurança)
if [ -f ".env" ]; then
    echo -e "${GREEN}✅ Arquivo .env encontrado${NC}"
else
    echo -e "${YELLOW}⚠️  Arquivo .env não encontrado. Copie .env.sample para .env e configure.${NC}"
fi

# Instalar pre-commit hooks (opcional)
# if [ -f ".pre-commit-config.yaml" ]; then
#     echo -e "${BLUE}🔨 Instalando pre-commit hooks...${NC}"
#     pre-commit install
# fi

# Mensagem final
echo ""
echo -e "${GREEN}✨ Ambiente configurado com sucesso!${NC}"
echo ""
echo -e "${BLUE}📚 Próximos passos:${NC}"
echo "1. Configure o arquivo .env com suas credenciais"
echo "2. Execute: az login (para autenticação no Azure)"
echo "3. Execute: ./run_dbt.sh debug (para testar conexão)"
echo "4. Execute: ./run_dbt.sh run (para executar os modelos)"
echo ""
echo -e "${GREEN}🚀 Bom desenvolvimento!${NC}"