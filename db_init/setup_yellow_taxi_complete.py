#!/usr/bin/env python3
"""
Script: setup_yellow_taxi_complete.py
Descrição: Automação completa para setup do dataset NYC Yellow Taxi 2013
Executa: Criação de tabela + Carregamento de dados Parquet + Validação
Fonte: NYC TLC Official Parquet Files (CloudFront CDN)
"""

import os
import sys
import time
import subprocess
from pathlib import Path
from datetime import datetime
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv(Path(__file__).parent.parent / '.env')

# Diretório dos scripts
SCRIPT_DIR = Path(__file__).parent

# Scripts a serem executados
SCRIPTS = [
    ('00_create_database.sql', 'Criação do Database', 'sql'),
    ('01_create_yellow_taxi_table.sql', 'Criação da Tabela Yellow Taxi', 'sql'),
    ('02_load_yellow_taxi_parquet.py', 'Carregamento de Dados Parquet', 'python'),
    ('03_validate_yellow_taxi_data.sql', 'Validação dos Dados', 'sql'),
]


class Colors:
    """Cores ANSI para output colorido"""
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'


def print_header(message):
    """Imprime cabeçalho formatado"""
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'=' * 60}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{message}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'=' * 60}{Colors.ENDC}\n")


def print_success(message):
    """Imprime mensagem de sucesso"""
    print(f"{Colors.OKGREEN}✓ {message}{Colors.ENDC}")


def print_error(message):
    """Imprime mensagem de erro"""
    print(f"{Colors.FAIL}✗ {message}{Colors.ENDC}")


def print_info(message):
    """Imprime mensagem informativa"""
    print(f"{Colors.OKCYAN}ℹ {message}{Colors.ENDC}")


def print_warning(message):
    """Imprime mensagem de aviso"""
    print(f"{Colors.WARNING}⚠ {message}{Colors.ENDC}")


def ensure_database_exists():
    """Garante que o database existe antes de prosseguir"""
    try:
        import pyodbc
        
        SERVER = os.getenv('DBT_SERVER', 'localhost')
        DATABASE = os.getenv('DBT_DATABASE', 'DataWarehouseTreinamento')
        USERNAME = os.getenv('DBT_USER', 'sa')
        PASSWORD = os.getenv('DBT_PASSWORD', '')
        DRIVER = os.getenv('ODBC_DRIVER', 'ODBC Driver 18 for SQL Server')
        
        trust_cert = "yes" if "localhost" in SERVER or "127.0.0.1" in SERVER else "no"
        
        # Conectar ao master para verificar/criar database
        conn_str = (
            f"DRIVER={{{DRIVER}}};"
            f"SERVER={SERVER};"
            f"DATABASE=master;"
            f"UID={USERNAME};"
            f"PWD={PASSWORD};"
            f"TrustServerCertificate={trust_cert};"
        )
        
        print_info(f"Verificando se database '{DATABASE}' existe...")
        
        # Tentar conectar com retry (SQL Server pode estar iniciando)
        max_retries = 5
        retry_delay = 2
        
        for attempt in range(1, max_retries + 1):
            try:
                conn = pyodbc.connect(conn_str, timeout=30, autocommit=True)
                break
            except pyodbc.Error as e:
                if attempt < max_retries:
                    print_warning(f"Tentativa {attempt}/{max_retries} falhou. Aguardando {retry_delay}s...")
                    time.sleep(retry_delay)
                    retry_delay *= 2  # Exponential backoff
                else:
                    raise
        
        cursor = conn.cursor()
        
        # Verificar se database existe
        cursor.execute(f"SELECT database_id FROM sys.databases WHERE name = '{DATABASE}'")
        exists = cursor.fetchone()
        
        if exists:
            print_success(f"Database '{DATABASE}' já existe!")
        else:
            print_info(f"Criando database '{DATABASE}'...")
            cursor.execute(f"CREATE DATABASE [{DATABASE}]")
            print_success(f"Database '{DATABASE}' criado com sucesso!")
        
        cursor.close()
        conn.close()
        return True
        
    except Exception as e:
        print_error(f"Erro ao verificar/criar database: {str(e)}")
        return False


def execute_python_script(filepath, description):
    """Executa um script Python"""
    print_header(description)
    
    if not filepath.exists():
        print_error(f"Arquivo não encontrado: {filepath}")
        return False
    
    print_info(f"Executando: {filepath.name}")
    
    try:
        start_time = time.time()
        
        # Executar script Python
        result = subprocess.run(
            [sys.executable, str(filepath)],
            cwd=filepath.parent,
            capture_output=False,
            text=True
        )
        
        elapsed_time = time.time() - start_time
        minutes = int(elapsed_time // 60)
        seconds = int(elapsed_time % 60)
        
        if result.returncode == 0:
            print_success(f"Concluído em {minutes}m {seconds}s")
            return True
        else:
            print_error(f"Script falhou com código {result.returncode}")
            return False
        
    except Exception as e:
        print_error(f"Erro ao executar {filepath.name}: {str(e)}")
        return False


def execute_sql_script(filepath, description):
    """Executa um script SQL via pyodbc"""
    print_header(description)
    
    if not filepath.exists():
        print_error(f"Arquivo não encontrado: {filepath}")
        return False
    
    print_info(f"Executando: {filepath.name}")
    
    try:
        import pyodbc
        
        # Configurações de conexão
        SERVER = os.getenv('DBT_SERVER', 'localhost')
        DATABASE = os.getenv('DBT_DATABASE', 'DataWarehouseTreinamento')
        USERNAME = os.getenv('DBT_USER', 'sa')
        PASSWORD = os.getenv('DBT_PASSWORD', '')
        DRIVER = os.getenv('ODBC_DRIVER', 'ODBC Driver 18 for SQL Server')
        
        # Se for o script de criação do database, conectar ao master
        if filepath.name == '00_create_database.sql':
            DATABASE = 'master'
        
        trust_cert = "yes" if "localhost" in SERVER or "127.0.0.1" in SERVER else "no"
        
        conn_str = (
            f"DRIVER={{{DRIVER}}};"
            f"SERVER={SERVER};"
            f"DATABASE={DATABASE};"
            f"UID={USERNAME};"
            f"PWD={PASSWORD};"
            f"TrustServerCertificate={trust_cert};"
        )
        
        # Ler o arquivo SQL
        with open(filepath, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        # Conectar ao banco
        conn = pyodbc.connect(conn_str, timeout=3600)
        cursor = conn.cursor()
        
        # Dividir por GO e executar cada batch
        batches = sql_content.split('GO')
        
        start_time = time.time()
        
        for batch in batches:
            batch = batch.strip()
            if not batch:
                continue
            
            try:
                cursor.execute(batch)
                while cursor.nextset():
                    pass
                conn.commit()
            except pyodbc.Error as e:
                if "PRINT" not in batch.upper():
                    print_warning(f"Aviso: {str(e)}")
        
        cursor.close()
        conn.close()
        
        elapsed_time = time.time() - start_time
        minutes = int(elapsed_time // 60)
        seconds = int(elapsed_time % 60)
        
        print_success(f"Concluído em {minutes}m {seconds}s")
        return True
        
    except Exception as e:
        print_error(f"Erro ao executar {filepath.name}: {str(e)}")
        return False


def main():
    """Função principal"""
    print_header("Setup Completo - NYC Yellow Taxi 2013 (Parquet)")
    print_info(f"Início: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print_info("Fonte: NYC TLC Official Parquet Files")
    print_info("URL: https://d37ci6vzurychx.cloudfront.net/trip-data/")
    print("")
    
    # Avisos importantes
    print_warning("ATENÇÃO: Este processo vai baixar arquivos Parquet do CDN oficial")
    print_warning("ATENÇÃO: Pode demorar de 30 minutos a 2 horas dependendo da conexão")
    print("")
    
    # Confirmar execução
    response = input(f"{Colors.BOLD}Deseja continuar? (s/N): {Colors.ENDC}").strip().lower()
    if response != 's':
        print_info("Operação cancelada pelo usuário.")
        return 0
    
    # Garantir que o database existe ANTES de executar os scripts
    print_header("Verificação do Database")
    if not ensure_database_exists():
        print_error("Não foi possível criar/verificar o database. Abortando.")
        return 1
    
    # Executar scripts
    overall_start = time.time()
    success = True
    
    for script_file, description, script_type in SCRIPTS:
        script_path = SCRIPT_DIR / script_file
        
        # Pular o script de criação do database (já foi feito acima)
        if script_file == '00_create_database.sql':
            continue
        
        if script_type == 'sql':
            if not execute_sql_script(script_path, description):
                success = False
                break
        elif script_type == 'python':
            if not execute_python_script(script_path, description):
                success = False
                break
    
    # Tempo total
    overall_elapsed = time.time() - overall_start
    overall_minutes = int(overall_elapsed // 60)
    overall_seconds = int(overall_elapsed % 60)
    
    # Resumo final
    if success:
        print_header("Setup Concluído com Sucesso!")
        print_success(f"Tempo total: {overall_minutes}m {overall_seconds}s")
        print_info(f"Término: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print_info("\nPróximos passos:")
        print_info("  - Execute queries de análise nos dados")
        print_info("  - Integre com DBT para transformações")
        print_info("  - Crie visualizações com Power BI")
        return 0
    else:
        print_error("Setup falhou! Verifique os erros acima.")
        return 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print_warning("\n\nOperação interrompida pelo usuário.")
        sys.exit(130)
    except Exception as e:
        print_error(f"\nErro inesperado: {str(e)}")
        sys.exit(1)
