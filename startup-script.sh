#!/bin/bash

# Script de instalación de Odoo 18 Community en Ubuntu 20.04/22.04
# Autor: Asistente AI
# Fecha: $(date +%Y-%m-%d)

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para mostrar mensajes
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Variables
ODOO_VERSION="18.0"
ODOO_USER="odoo"
ODOO_HOME="/opt/odoo"
ODOO_CONFIG="/etc/odoo"
VENV_PATH="/opt/odoo/venv"
POSTGRES_VERSION="14"

print_status "Iniciando instalación de Odoo 18 Community..."

# Actualizar sistema
print_status "Actualizando sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar dependencias del sistema
print_status "Instalando dependencias del sistema..."
sudo apt install -y \
    wget \
    curl \
    git \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    build-essential \
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
    libgeoip-dev \
    libmaxminddb-dev \
    pkg-config \
    libcairo2-dev \
    libjpeg8-dev \
    libpango1.0-dev \
    libgif-dev \
    libffi-dev \
    gfortran \
    libatlas-base-dev \
    python3-tk \
    fontconfig \
    libxml2 \
    libxslt1.1 \
    libz-dev \
    libmysqlclient-dev \
    mysqlclient \
    npm \
    nodejs \
    node-less \
    gdebi-core \
    lsb-release \
    ca-certificates \
    apt-transport-https \
    gnupg

# Instalar wkhtmltopdf
print_status "Instalando wkhtmltopdf..."
cd /tmp
wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb
sudo gdebi -n wkhtmltox_0.12.6.1-2.jammy_amd64.deb

# Instalar PostgreSQL
print_status "Instalando PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib postgresql-client

# Configurar PostgreSQL
print_status "Configurando PostgreSQL..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Crear usuario de PostgreSQL para Odoo
print_status "Creando usuario de PostgreSQL..."
sudo -u postgres createuser --createdb --username postgres --no-createrole --no-superuser $ODOO_USER 2>/dev/null || true
sudo -u postgres psql -c "ALTER USER $ODOO_USER CREATEDB;"

# Crear usuario del sistema para Odoo
print_status "Creando usuario del sistema para Odoo..."
sudo useradd --system --home $ODOO_HOME --shell /bin/bash $ODOO_USER 2>/dev/null || true

# Crear directorios necesarios
print_status "Creando directorios..."
sudo mkdir -p $ODOO_HOME
sudo mkdir -p $ODOO_CONFIG
sudo mkdir -p /var/log/odoo
sudo mkdir -p /var/lib/odoo

# Cambiar propietario de directorios
sudo chown -R $ODOO_USER:$ODOO_USER $ODOO_HOME
sudo chown -R $ODOO_USER:$ODOO_USER /var/log/odoo
sudo chown -R $ODOO_USER:$ODOO_USER /var/lib/odoo

# Descargar código fuente de Odoo
print_status "Descargando código fuente de Odoo..."
cd $ODOO_HOME
sudo -u $ODOO_USER git clone --depth 1 --branch $ODOO_VERSION https://github.com/odoo/odoo.git || {
    print_warning "El repositorio ya existe, actualizando..."
    cd $ODOO_HOME/odoo
    sudo -u $ODOO_USER git pull
}

# Crear entorno virtual
print_status "Creando entorno virtual..."
sudo -u $ODOO_USER python3 -m venv $VENV_PATH

# Actualizar pip
print_status "Actualizando pip..."
sudo -u $ODOO_USER $VENV_PATH/bin/pip install --upgrade pip

# Instalar dependencias Python
print_status "Instalando dependencias Python..."
sudo -u $ODOO_USER $VENV_PATH/bin/pip install -r /opt/odoo/odoo/requirements.txt

# Instalar dependencias adicionales necesarias para Odoo 18
print_status "Instalando dependencias adicionales..."
sudo -u $ODOO_USER $VENV_PATH/bin/pip install lxml_html_clean psutil

# Verificar dependencias críticas
print_status "Verificando dependencias críticas..."
MISSING_DEPS=$(sudo -u $ODOO_USER $VENV_PATH/bin/python -c "
import sys
modules = ['psutil', 'lxml', 'pillow', 'babel', 'python-dateutil', 'decorator', 'docutils', 'feedparser', 'gevent', 'greenlet', 'jinja2', 'libsass', 'markupsafe', 'num2words', 'ofxparse', 'passlib', 'polib', 'psycopg2', 'pydot', 'pypdf2', 'pyserial', 'python-stdnum', 'pytz', 'pyusb', 'qrcode', 'reportlab', 'requests', 'urllib3', 'vobject', 'werkzeug', 'xlrd', 'xlsxwriter', 'xlwt', 'zeep']
missing = []
for module in modules:
    try:
        __import__(module)
        print(f'✓ {module}')
    except ImportError as e:
        print(f'✗ {module}: {e}')
        missing.append(module)
        
if missing:
    print(f'MISSING:{\" \".join(missing)}')
    sys.exit(1)
else:
    print('✓ Todas las dependencias críticas están instaladas')
" 2>&1)

# Si hay dependencias faltantes, intentar instalarlas
if echo "$MISSING_DEPS" | grep -q "MISSING:"; then
    print_status "Instalando dependencias faltantes..."
    MISSING_LIST=$(echo "$MISSING_DEPS" | grep "MISSING:" | cut -d: -f2)
    for dep in $MISSING_LIST; do
        print_status "Instalando $dep..."
        sudo -u $ODOO_USER $VENV_PATH/bin/pip install $dep
    done
    
    # Verificar nuevamente
    print_status "Verificando dependencias después de la instalación..."
    sudo -u $ODOO_USER $VENV_PATH/bin/python -c "
import sys
modules = ['psutil', 'lxml', 'pillow', 'babel', 'python-dateutil', 'decorator', 'docutils', 'feedparser', 'gevent', 'greenlet', 'jinja2', 'libsass', 'markupsafe', 'num2words', 'ofxparse', 'passlib', 'polib', 'psycopg2', 'pydot', 'pypdf2', 'pyserial', 'python-stdnum', 'pytz', 'pyusb', 'qrcode', 'reportlab', 'requests', 'urllib3', 'vobject', 'werkzeug', 'xlrd', 'xlsxwriter', 'xlwt', 'zeep']
missing = []
for module in modules:
    try:
        __import__(module)
        print(f'✓ {module}')
    except ImportError as e:
        print(f'✗ {module}: {e}')
        missing.append(module)
        
if missing:
    print(f'ERROR: Dependencias aún faltantes: {missing}')
    sys.exit(1)
else:
    print('✓ Todas las dependencias críticas están instaladas')
"
else
    echo "$MISSING_DEPS"
fi

# Verificar que lxml.html.clean funcione correctamente
print_status "Verificando lxml.html.clean..."
sudo -u $ODOO_USER $VENV_PATH/bin/python -c "import lxml.html.clean; print('✓ lxml.html.clean funcionando correctamente')"

# Crear archivo de configuración de Odoo
print_status "Creando archivo de configuración..."
sudo tee $ODOO_CONFIG/odoo.conf > /dev/null <<EOF
[options]
; This is the password that allows database operations:
admin_passwd = admin
db_host = False
db_port = False
db_user = $ODOO_USER
db_password = False
addons_path = $ODOO_HOME/odoo/addons
logfile = /var/log/odoo/odoo.log
log_level = info
workers = 2
max_cron_threads = 2
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_time_cpu = 60
limit_time_real = 120
xmlrpc_port = 8069
longpolling_port = 8072
proxy_mode = True
EOF

# Establecer permisos del archivo de configuración
sudo chown $ODOO_USER:$ODOO_USER $ODOO_CONFIG/odoo.conf
sudo chmod 640 $ODOO_CONFIG/odoo.conf

# Crear archivo de servicio systemd
print_status "Creando servicio systemd..."
sudo tee /etc/systemd/system/odoo.service > /dev/null <<EOF
[Unit]
Description=Odoo 18 Community
Documentation=http://www.odoo.com
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=$ODOO_USER
Group=$ODOO_USER
ExecStart=$VENV_PATH/bin/python $ODOO_HOME/odoo/odoo-bin -c $ODOO_CONFIG/odoo.conf
WorkingDirectory=$ODOO_HOME/odoo
Environment=PATH=$VENV_PATH/bin
StandardOutput=journal+console
Restart=always
RestartSec=10
KillMode=mixed
KillSignal=SIGINT
TimeoutStopSec=600
SyslogIdentifier=odoo

[Install]
WantedBy=multi-user.target
EOF

# Recargar systemd y habilitar el servicio
print_status "Configurando servicio systemd..."
sudo systemctl daemon-reload
sudo systemctl enable odoo
sudo systemctl start odoo

# Esperar un momento para que el servicio inicie
sleep 5

# Verificar estado del servicio
print_status "Verificando estado del servicio..."
sudo systemctl status odoo --no-pager

# Configurar firewall (opcional)
print_status "Configurando firewall..."
sudo ufw allow 8069/tcp
sudo ufw allow 8072/tcp

# Mostrar información final
print_status "¡Instalación completada!"
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Odoo 18 Community instalado exitosamente${NC}"
echo -e "${GREEN}================================${NC}"
echo -e "URL de acceso: http://$(hostname -I | awk '{print $1}'):8069"
echo -e "Usuario de base de datos: $ODOO_USER"
echo -e "Archivo de configuración: $ODOO_CONFIG/odoo.conf"
echo -e "Archivo de log: /var/log/odoo/odoo.log"
echo -e "Directorio de Odoo: $ODOO_HOME"
echo -e ""
echo -e "${YELLOW}Comandos útiles:${NC}"
echo -e "sudo systemctl start odoo    # Iniciar servicio"
echo -e "sudo systemctl stop odoo     # Detener servicio"
echo -e "sudo systemctl restart odoo  # Reiniciar servicio"
echo -e "sudo systemctl status odoo   # Ver estado"
echo -e "sudo journalctl -u odoo -f   # Ver logs en tiempo real"
echo -e ""
echo -e "${YELLOW}Nota:${NC} En el primer acceso, deberás crear una base de datos desde la interfaz web"
