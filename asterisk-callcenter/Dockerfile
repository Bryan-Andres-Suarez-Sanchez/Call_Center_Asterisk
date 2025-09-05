# Dockerfile para Asterisk Call Center
FROM debian:bullseye-slim

# Instalar dependencias
RUN apt-get update && apt-get install -y \
    asterisk \
    asterisk-config \
    asterisk-modules \
    asterisk-moh-opsound-gsm \
    vim \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Crear directorios necesarios
RUN mkdir -p /etc/asterisk/conf.d \
    && mkdir -p /var/log/asterisk \
    && mkdir -p /var/spool/asterisk

# Copiar archivos de configuración
COPY config/asterisk.conf /etc/asterisk/
COPY config/sip.conf /etc/asterisk/
COPY config/extensions.conf /etc/asterisk/
COPY config/queues.conf /etc/asterisk/
COPY config/agents.conf /etc/asterisk/
COPY config/modules.conf /etc/asterisk/

# Crear usuario asterisk si no existe
RUN useradd -r -d /var/lib/asterisk -s /bin/false asterisk || true

# Configurar permisos
RUN chown -R asterisk:asterisk /var/log/asterisk \
    && chown -R asterisk:asterisk /var/spool/asterisk \
    && chown -R asterisk:asterisk /etc/asterisk

# Exponer puertos
EXPOSE 5060/udp 10000-20000/udp

# Comando de inicio
CMD ["asterisk", "-f", "-vvv"]