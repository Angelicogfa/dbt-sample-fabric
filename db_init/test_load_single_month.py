#!/usr/bin/env python3
"""
Script de teste rápido: Carrega apenas Janeiro/2013 para validar a solução
"""
import subprocess
import sys
from pathlib import Path

def main():
    script_path = Path(__file__).parent / "02_load_yellow_taxi_parquet.py"
    
    print("=" * 60)
    print("TESTE RÁPIDO: Carregamento de Janeiro/2013")
    print("=" * 60)
    print()
    print("Este script vai:")
    print("  1. Criar a tabela automaticamente via pandas")
    print("  2. Carregar apenas Janeiro/2013 (~14M linhas)")
    print("  3. Validar tipos de dados e performance")
    print()
    
    # Executar script com input automático (opção 2, mês 1)
    process = subprocess.Popen(
        [sys.executable, str(script_path)],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1
    )
    
    # Enviar inputs: opção 2 (um mês), mês 1 (janeiro)
    stdout, _ = process.communicate(input="2\n1\n")
    
    print(stdout)
    
    return process.returncode

if __name__ == "__main__":
    sys.exit(main())
