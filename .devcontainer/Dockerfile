FROM mcr.microsoft.com/devcontainers/python:3.11-bullseye

# Evita prompts interativos durante instalação
ENV DEBIAN_FRONTEND=noninteractive

# Argumentos de build
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Remover repositório Yarn (não necessário e causa erro de chave GPG)
RUN rm -f /etc/apt/sources.list.d/yarn.list

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    # Ferramentas essenciais
    git \
    curl \
    wget \
    unzip \
    gnupg2 \
    ca-certificates \
    apt-transport-https \
    lsb-release \
    # Build tools para compilação de pacotes Python
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev \
    # ODBC dependencies
    unixodbc \
    unixodbc-dev \
    # Ferramentas de rede para debug
    iputils-ping \
    netcat \
    telnet \
    # Editor de texto
    vim \
    nano \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Instalar Microsoft ODBC Driver 18 for SQL Server
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql18 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Instalar Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Configurar usuário não-root
RUN if [ "$USER_GID" != "1000" ] || [ "$USER_UID" != "1000" ]; then \
        groupmod --gid $USER_GID $USERNAME \
        && usermod --uid $USER_UID --gid $USER_GID $USERNAME \
        && chown -R $USER_UID:$USER_GID /home/$USERNAME; \
    fi

# Mudar para o usuário
USER $USERNAME

# Configurar diretório de trabalho
WORKDIR /workspace

# Copiar requirements.txt e instalar dependências Python
COPY --chown=$USERNAME:$USERNAME requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

# Configurar PATH para incluir binários do pip instalados localmente
ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"

# Verificar instalação do dbt
RUN dbt --version

# Configurar Git (será sobrescrito pelas configurações do host)
RUN git config --global init.defaultBranch main

# Criar diretório para Azure CLI cache
RUN mkdir -p /home/${USERNAME}/.azure

# Porta padrão para dbt docs serve
EXPOSE 8080

# Manter o container rodando
CMD ["sleep", "infinity"]