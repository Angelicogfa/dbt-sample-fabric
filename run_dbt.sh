#!/bin/bash
# Script para carregar variáveis de ambiente do .env e executar comandos DBT
# Uso: ./run_dbt.sh debug
#      ./run_dbt.sh run
#      ./run_dbt.sh test

# Carrega as variáveis do arquivo .env
if [ -f .env ]; then
    echo "Carregando variáveis de ambiente de .env..."
    set -a
    source .env
    set +a
    echo ""
else
    echo "Arquivo .env não encontrado"
    exit 1
fi

# Navega para o diretório do DBT
cd treinamento_dbt

# Executa o comando DBT
echo "Executando: dbt $@"
echo ""
dbt "$@"

# Retorna ao diretório original
cd ..
