#!/bin/bash

# Script corregido para instalación de Odoo 18 Community
# Soluciona problemas de compilación con gevent y otras dependencias
# Autor: Asistente de Claude
# Fecha: $(date)

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
ODOO_VERSION="18.0"
ODOO_USER="odoo"
ODOO_HOME="/opt/odoo"
ODOO_CONFIG="/etc/odoo.conf"
ODOO_SERVICE="odoo"
POSTGRES_VERSION="15"

# Función para mostrar mensajes
show_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

show_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

show_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Verificar si el script se ejecuta como root
if [[ $EUID -ne 0 ]]; then
    show_error "Este script debe ejecutarse como root (usar sudo)"
    exit 1
fi

show_header "INSTALACIÓN CORREGIDA DE ODOO 18 COMMUNITY"

# Actualizar sistema
show_header "Actualizando sistema"
apt update && apt upgrade -y

# Instalar dependencias del sistema (incluyendo todas las necesarias para compilación)
show_header "Instalando dependencias del sistema"
apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-setuptools \
    python3-wheel \
    python3-babel \
    python3-lxml \
    python3-pil \
    python3-psycopg2 \
    python3-requests \
    python3-werkzeug \
    python3-jinja2 \
    git \
    wget \
    curl \
    build-essential \
    gcc \
    g++ \
    make \
    libc6-dev \
    libxml2-dev \
    libxslt1-dev \
    libevent-dev \
    libsasl2-dev \
    libldap2-dev \
    libpq-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libwebp-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libxcb1-dev \
    libssl-dev \
    zlib1g-dev \
    libffi-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncurses5-dev \
    libgdbm-dev \
    libnss3-dev \
    liblzma-dev \
    libev-dev \
    libevdev-dev \
    libevent-dev \
    fontconfig \
    xfonts-75dpi \
    xfonts-base \
    wkhtmltopdf \
    nodejs \
    npm \
    cython3 \
    pkg-config

# Instalar PostgreSQL
show_header "Instalando PostgreSQL"
apt install -y postgresql postgresql-contrib postgresql-server-dev-all

# Configurar PostgreSQL
show_message "Configurando PostgreSQL..."
systemctl start postgresql
systemctl enable postgresql

# Crear usuario de PostgreSQL para Odoo
show_message "Creando usuario de PostgreSQL para Odoo..."
sudo -u postgres createuser -s $ODOO_USER 2>/dev/null || show_warning "Usuario PostgreSQL ya existe"

# Crear usuario del sistema para Odoo
show_header "Creando usuario del sistema para Odoo"
if ! id "$ODOO_USER" &>/dev/null; then
    useradd -m -d $ODOO_HOME -U -r -s /bin/bash $ODOO_USER
    show_message "Usuario $ODOO_USER creado"
else
    show_warning "Usuario $ODOO_USER ya existe"
fi

# Crear directorio de Odoo
show_message "Creando directorios de Odoo..."
mkdir -p $ODOO_HOME
mkdir -p $ODOO_HOME/custom-addons
mkdir -p $ODOO_HOME/log
chown -R $ODOO_USER:$ODOO_USER $ODOO_HOME

# Descargar código fuente de Odoo
show_header "Descargando código fuente de Odoo $ODOO_VERSION"
cd $ODOO_HOME
if [ -d "odoo" ]; then
    show_warning "Directorio odoo ya existe, eliminando..."
    rm -rf odoo
fi

sudo -u $ODOO_USER git clone --depth 1 --branch $ODOO_VERSION https://github.com/odoo/odoo.git
show_message "Código fuente descargado exitosamente"

# Crear entorno virtual
show_header "Creando entorno virtual de Python"
sudo -u $ODOO_USER python3 -m venv $ODOO_HOME/venv
show_message "Entorno virtual creado"

# Actualizar pip, setuptools y wheel
show_message "Actualizando herramientas básicas..."
sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install --upgrade pip
sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install --upgrade setuptools wheel cython

# Instalar dependencias problemáticas con versiones específicas
show_header "Instalando dependencias problemáticas con versiones específicas"

# Instalar gevent con versión específica y pre-compilada
show_message "Instalando gevent pre-compilado..."
sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install --only-binary=all gevent==23.9.1 || \
sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install --only-binary=all gevent

# Instalar greenlet pre-compilado
show_message "Instalando greenlet pre-compilado..."
sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install --only-binary=all greenlet

# Instalar lxml pre-compilado
show_message "Instalando lxml pre-compilado..."
sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install --only-binary=all lxml

# Instalar pillow pre-compilado
show_message "Instalando pillow pre-compilado..."
sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install --only-binary=all pillow

# Instalar psycopg2 pre-compilado
show_message "Instalando psycopg2 pre-compilado..."
sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install psycopg2-binary

# Instalar otras dependencias críticas
show_header "Instalando dependencias críticas"
CRITICAL_DEPS=(
    "babel>=2.6.0"
    "chardet"
    "cryptography"
    "decorator"
    "docutils"
    "feedparser"
    "jinja2>=2.10.1"
    "markupsafe>=2.0.0"
    "python-dateutil"
    "pytz"
    "requests"
    "urllib3"
    "werkzeug>=2.0.0"
)

for dep in "${CRITICAL_DEPS[@]}"; do
    show_message "Instalando $dep..."
    sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install "$dep" --prefer-binary
done

# Instalar dependencias adicionales con manejo de errores
show_header "Instalando dependencias adicionales"
ADDITIONAL_DEPS=(
    "ebaysdk"
    "freezegun"
    "idna"
    "libsass"
    "num2words"
    "ofxparse"
    "passlib"
    "polib"
    "pydot"
    "pyopenssl"
    "pypdf2"
    "pyserial"
    "python-ldap"
    "python-stdnum"
    "pyusb"
    "qrcode"
    "reportlab"
    "vobject"
    "xlrd"
    "xlsxwriter"
    "xlwt"
    "zeep"
)

for dep in "${ADDITIONAL_DEPS[@]}"; do
    show_message "Instalando $dep..."
    if ! sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install "$dep" --prefer-binary; then
        show_warning "Error instalando $dep, intentando sin binarios pre-compilados..."
        sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install "$dep" --no-binary=:all: || show_warning "No se pudo instalar $dep, continuando..."
    fi
done

# Instalar dependencias desde requirements.txt si existe
if [ -f "$ODOO_HOME/odoo/requirements.txt" ]; then
    show_message "Instalando dependencias desde requirements.txt..."
    sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install -r $ODOO_HOME/odoo/requirements.txt --prefer-binary || show_warning "Algunos paquetes del requirements.txt fallaron"
fi

# Verificar instalación de dependencias críticas
show_header "Verificando instalación de dependencias críticas"
VERIFY_DEPS=("babel" "lxml" "psycopg2" "pillow" "werkzeug" "jinja2" "markupsafe" "gevent" "greenlet")

all_ok=true
for dep in "${VERIFY_DEPS[@]}"; do
    if sudo -u $ODOO_USER $ODOO_HOME/venv/bin/python -c "import $dep; print('✓ $dep version:', getattr($dep, '__version__', 'unknown'))" 2>/dev/null; then
        show_message "✓ $dep está disponible"
    else
        show_error "✗ $dep no está disponible"
        all_ok=false
    fi
done

if [ "$all_ok" = false ]; then
    show_error "Algunas dependencias críticas no están disponibles"
    show_message "Continuando con la instalación..."
fi

# Crear archivo de configuración de Odoo
show_header "Creando archivo de configuración de Odoo"
cat > $ODOO_CONFIG << EOF
[options]
; This is the password that allows database operations:
admin_passwd = admin
db_host = False
db_port = False
db_user = $ODOO_USER
db_password = False
addons_path = $ODOO_HOME/odoo/addons,$ODOO_HOME/custom-addons
logfile = $ODOO_HOME/log/odoo.log
log_level = info
; Configuración para entorno de producción
workers = 2
max_cron_threads = 1
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_time_cpu = 60
limit_time_real = 120
limit_request = 8192
; Configuración de red
xmlrpc_port = 8069
; Configuración de seguridad
list_db = False
proxy_mode = False
; Configuración de archivos
data_dir = $ODOO_HOME/.local/share/Odoo
EOF

chown $ODOO_USER:$ODOO_USER $ODOO_CONFIG
chmod 640 $ODOO_CONFIG
show_message "Archivo de configuración creado en $ODOO_CONFIG"

# Crear archivo de servicio systemd
show_header "Creando servicio systemd para Odoo"
cat > /etc/systemd/system/$ODOO_SERVICE.service << EOF
[Unit]
Description=Odoo 18 Community
Documentation=https://www.odoo.com/documentation/18.0/
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=$ODOO_USER
Group=$ODOO_USER
Environment=PATH=$ODOO_HOME/venv/bin
Environment=PYTHONPATH=$ODOO_HOME/venv/lib/python3.11/site-packages
ExecStart=$ODOO_HOME/venv/bin/python $ODOO_HOME/odoo/odoo-bin -c $ODOO_CONFIG
WorkingDirectory=$ODOO_HOME
StandardOutput=journal+console
StandardError=journal+console
Restart=always
RestartSec=10
KillMode=mixed
KillSignal=SIGINT
TimeoutStopSec=60
SyslogIdentifier=odoo

[Install]
WantedBy=multi-user.target
EOF

show_message "Servicio systemd creado"

# Configurar permisos
show_header "Configurando permisos"
chown -R $ODOO_USER:$ODOO_USER $ODOO_HOME
chmod -R 755 $ODOO_HOME
chmod 750 $ODOO_HOME/log

# Crear directorio de datos
sudo -u $ODOO_USER mkdir -p $ODOO_HOME/.local/share/Odoo

# Recargar systemd y habilitar servicio
show_message "Habilitando servicio de Odoo..."
systemctl daemon-reload
systemctl enable $ODOO_SERVICE

# Crear scripts de utilidad
show_header "Creando scripts de utilidad"
cat > /usr/local/bin/odoo-start << 'EOF'
#!/bin/bash
sudo systemctl start odoo
sudo systemctl status odoo
EOF

cat > /usr/local/bin/odoo-stop << 'EOF'
#!/bin/bash
sudo systemctl stop odoo
sudo systemctl status odoo
EOF

cat > /usr/local/bin/odoo-restart << 'EOF'
#!/bin/bash
sudo systemctl restart odoo
sudo systemctl status odoo
EOF

cat > /usr/local/bin/odoo-logs << 'EOF'
#!/bin/bash
sudo journalctl -u odoo -f
EOF

cat > /usr/local/bin/odoo-test << 'EOF'
#!/bin/bash
echo "Probando Odoo manualmente..."
sudo -u odoo /opt/odoo/venv/bin/python /opt/odoo/odoo/odoo-bin -c /etc/odoo.conf --stop-after-init
EOF

chmod +x /usr/local/bin/odoo-*

# Configurar firewall (si está activo)
show_header "Configurando firewall"
if command -v ufw &> /dev/null; then
    ufw allow 8069/tcp
    show_message "Puerto 8069 abierto en UFW"
fi

# Probar Odoo manualmente antes de iniciar el servicio
show_header "Probando Odoo manualmente"
show_message "Ejecutando prueba de Odoo..."
if sudo -u $ODOO_USER $ODOO_HOME/venv/bin/python $ODOO_HOME/odoo/odoo-bin -c $ODOO_CONFIG --stop-after-init; then
    show_message "✓ Prueba manual exitosa"
else
    show_error "✗ Prueba manual falló"
    show_message "Revisando configuración..."
fi

# Iniciar servicio de Odoo
show_header "Iniciando servicio de Odoo"
systemctl start $ODOO_SERVICE

# Esperar un poco y verificar estado
sleep 15
if systemctl is-active $ODOO_SERVICE &>/dev/null; then
    show_message "✓ Servicio de Odoo iniciado correctamente"
else
    show_error "✗ Servicio de Odoo no está funcionando"
    show_message "Revisando logs..."
    journalctl -u $ODOO_SERVICE --no-pager --lines=30
fi

# Información final
show_header "INSTALACIÓN COMPLETADA"
echo -e "${GREEN}Odoo 18 Community ha sido instalado${NC}"
echo ""
echo -e "${BLUE}Información de acceso:${NC}"
echo -e "  URL: ${GREEN}http://$(hostname -I | awk '{print $1}'):8069${NC}"
echo -e "  Usuario: ${GREEN}admin${NC}"
echo -e "  Contraseña: ${GREEN}admin${NC}"
echo ""
echo -e "${BLUE}Comandos útiles:${NC}"
echo -e "  Iniciar Odoo: ${GREEN}odoo-start${NC}"
echo -e "  Detener Odoo: ${GREEN}odoo-stop${NC}"
echo -e "  Reiniciar Odoo: ${GREEN}odoo-restart${NC}"
echo -e "  Ver logs: ${GREEN}odoo-logs${NC}"
echo -e "  Probar Odoo: ${GREEN}odoo-test${NC}"
echo ""
echo -e "${BLUE}Verificación final:${NC}"
echo "Estado del servicio:"
systemctl status $ODOO_SERVICE --no-pager
echo ""
echo "Si hay problemas, ejecuta: odoo-logs"
