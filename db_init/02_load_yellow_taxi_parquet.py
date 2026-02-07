#!/usr/bin/env python3
"""
Script: 02_load_yellow_taxi_parquet.py
Descrição: Carregamento de dados Yellow Taxi 2013 em formato Parquet
Fonte: NYC TLC Official Data (CloudFront CDN)
URL Base: https://d37ci6vzurychx.cloudfront.net/trip-data/
"""

import os
import sys
import time
import requests
import pyarrow.parquet as pq
from pathlib import Path
from datetime import datetime
from dotenv import load_dotenv
from io import BytesIO
from sqlalchemy import create_engine
from urllib.parse import quote_plus

# Carregar variáveis de ambiente
load_dotenv(Path(__file__).parent.parent / '.env')

# Configurações de conexão
SERVER = os.getenv('DBT_SERVER', 'localhost')
DATABASE = os.getenv('DBT_DATABASE', 'DataWarehouseTreinamento')
USERNAME = os.getenv('DBT_USER', 'sa')
PASSWORD = os.getenv('DBT_PASSWORD', '')
DRIVER = os.getenv('ODBC_DRIVER', 'ODBC Driver 18 for SQL Server')

# URL base dos arquivos Parquet
BASE_URL = "https://d37ci6vzurychx.cloudfront.net/trip-data"

# Meses a carregar (2013)
MONTHS = list(range(1, 13))  # Janeiro a Dezembro


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
    print(f"{Colors.OKGREEN}[OK] {message}{Colors.ENDC}")


def print_error(message):
    """Imprime mensagem de erro"""
    print(f"{Colors.FAIL}[ERRO] {message}{Colors.ENDC}")


def print_info(message):
    """Imprime mensagem informativa"""
    print(f"{Colors.OKCYAN}[INFO] {message}{Colors.ENDC}")


def print_warning(message):
    """Imprime mensagem de aviso"""
    print(f"{Colors.WARNING}[AVISO] {message}{Colors.ENDC}")


def get_connection_string():
    """Retorna string de conexão"""
    trust_cert = "yes" if "localhost" in SERVER or "127.0.0.1" in SERVER else "no"
    
    conn_str = (
        f"DRIVER={{{DRIVER}}};"
        f"SERVER={SERVER};"
        f"DATABASE={DATABASE};"
        f"UID={USERNAME};"
        f"PWD={PASSWORD};"
        f"TrustServerCertificate={trust_cert};"
    )
    return conn_str


def download_and_load_month(year, month, is_first_month=False):
    """Baixa e carrega dados de um mês específico"""
    filename = f"yellow_tripdata_{year}-{month:02d}.parquet"
    url = f"{BASE_URL}/{filename}"
    
    print_header(f"Carregando: {filename}")
    start_time = time.time()
    
    try:
        # 1. Baixar arquivo Parquet
        print_info(f"Baixando de: {url}")
        response = requests.get(url, stream=True, timeout=300)
        response.raise_for_status()
        
        # 2. Ler Parquet com PyArrow
        print_info("Lendo arquivo Parquet...")
        parquet_file = pq.read_table(BytesIO(response.content))
        df = parquet_file.to_pandas()
        
        rows_count = len(df)
        print_info(f"Total de linhas: {rows_count:,}")
        
        # 3. Adicionar metadados
        df['load_date'] = datetime.now()
        df['source_file'] = filename
        
        # 4. Garantir lowercase nas colunas
        df.columns = df.columns.str.lower()
        
        # 5. Ajustar tipos de dados para melhor compatibilidade
        print_info("Ajustando tipos de dados...")
        
        # Converter store_and_fwd_flag para string (se existir)
        if 'store_and_fwd_flag' in df.columns:
            df['store_and_fwd_flag'] = df['store_and_fwd_flag'].astype(str)
        
        # Garantir que colunas numéricas sejam float64 (melhor compatibilidade)
        numeric_cols = ['trip_distance', 'fare_amount', 'extra', 'mta_tax', 
                       'tip_amount', 'tolls_amount', 'improvement_surcharge', 'total_amount']
        for col in numeric_cols:
            if col in df.columns:
                df[col] = df[col].astype('float64')
        
        # Garantir que IDs sejam Int64 (suporta NULL)
        id_cols = ['vendorid', 'passenger_count', 'pulocationid', 'dolocationid', 
                   'ratecodeid', 'payment_type']
        for col in id_cols:
            if col in df.columns:
                df[col] = df[col].astype('Int64')
        
        # 6. Conectar ao SQL Server
        print_info("Conectando ao SQL Server...")
        conn_str = get_connection_string()
        
        # Criar engine SQLAlchemy com otimizações de performance
        from urllib.parse import quote_plus
        params = quote_plus(conn_str)
        
        # OTIMIZAÇÃO: Usar fast_executemany para performance máxima
        engine = create_engine(
            f"mssql+pyodbc:///?odbc_connect={params}",
            fast_executemany=True,  # CRÍTICO para performance!
            pool_pre_ping=True,
            pool_recycle=3600
        )
        
        # 7. Inserir dados usando pandas to_sql
        if is_first_month:
            print_info("Criando tabela automaticamente (primeiro mês)...")
            if_exists_mode = 'replace'
        else:
            print_info("Inserindo dados na tabela existente...")
            if_exists_mode = 'append'
        
        print_info(f"Inserindo {rows_count:,} linhas no SQL Server...")
        
        # OTIMIZAÇÃO: Usar chunksize otimizado e method='multi'
        df.to_sql(
            name='YellowTaxiTrips',
            con=engine,
            schema='dbo',
            if_exists=if_exists_mode,
            index=False,
            chunksize=10000,  # Otimizado para bulk insert
            method='multi'     # Usa executemany para melhor performance
        )
        
        engine.dispose()
        
        elapsed_time = time.time() - start_time
        minutes = int(elapsed_time // 60)
        seconds = int(elapsed_time % 60)
        
        print_success(f"Concluído! {rows_count:,} linhas carregadas em {minutes}m {seconds}s")
        return True, rows_count
        
    except requests.exceptions.RequestException as e:
        print_error(f"Erro ao baixar dados: {str(e)}")
        return False, 0
    except Exception as e:
        print_error(f"Erro ao carregar dados: {str(e)}")
        import traceback
        traceback.print_exc()
        return False, 0


def main():
    """Função principal"""
    print_header("Carregamento Yellow Taxi 2013 - NYC TLC Parquet")
    print_info(f"Início: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print_info(f"Servidor: {SERVER}")
    print_info(f"Database: {DATABASE}")
    print_info(f"Fonte: NYC TLC CloudFront CDN")
    print("")
    
    # Avisos
    print_warning("ATENÇÃO: Este processo vai carregar 12 meses de dados (2013)")
    print_warning("ATENÇÃO: Pode demorar de 30 minutos a 2 horas dependendo da conexão")
    print("")
    
    # Perguntar quais meses carregar
    print(f"{Colors.BOLD}Opções:{Colors.ENDC}")
    print("  1. Carregar todos os meses (Janeiro a Dezembro 2013)")
    print("  2. Carregar apenas um mês (para teste)")
    print("  3. Cancelar")
    print("")
    
    choice = input(f"{Colors.BOLD}Escolha uma opção (1/2/3): {Colors.ENDC}").strip()
    
    if choice == '3':
        print_info("Operação cancelada pelo usuário.")
        return 0
    elif choice == '2':
        month_input = input(f"{Colors.BOLD}Digite o mês (1-12): {Colors.ENDC}").strip()
        try:
            month = int(month_input)
            if 1 <= month <= 12:
                months_to_load = [month]
            else:
                print_error("Mês inválido! Use 1-12.")
                return 1
        except ValueError:
            print_error("Entrada inválida!")
            return 1
    else:
        months_to_load = MONTHS
    
    # Carregar dados
    overall_start = time.time()
    success_count = 0
    total_rows = 0
    
    for idx, month in enumerate(months_to_load):
        # Primeiro mês cria a tabela automaticamente
        is_first = (idx == 0)
        success, rows = download_and_load_month(2013, month, is_first_month=is_first)
        if success:
            success_count += 1
            total_rows += rows
        else:
            print_error(f"Falha ao carregar mês {month}. Deseja continuar? (s/N)")
            response = input().strip().lower()
            if response != 's':
                break
    
    # Resumo
    overall_elapsed = time.time() - overall_start
    overall_minutes = int(overall_elapsed // 60)
    overall_seconds = int(overall_elapsed % 60)
    
    print_header("Resumo Final")
    print_info(f"Meses carregados: {success_count}/{len(months_to_load)}")
    print_info(f"Total de linhas: {total_rows:,}")
    print_info(f"Tempo total: {overall_minutes}m {overall_seconds}s")
    print_info(f"Término: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    if success_count == len(months_to_load):
        print_success("Todos os dados foram carregados com sucesso!")
        return 0
    else:
        print_warning("Alguns meses falharam no carregamento.")
        return 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print_warning("\n\nOperação interrompida pelo usuário.")
        sys.exit(130)
    except Exception as e:
        print_error(f"\nErro inesperado: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
