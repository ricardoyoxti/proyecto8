#!/bin/bash
# Script completo instalación Odoo 18 - NO solicita contraseña ni cierra SSH

echo "🚀 Iniciando instalación Odoo 18..."

# Sistema
sudo apt-get update -qq
sudo apt-get install -y postgresql postgresql-contrib git python3-pip python3-dev python3-venv \
python3-wheel build-essential wget nano net-tools libxml2-dev libxslt1-dev libldap2-dev \
libsasl2-dev libtiff5-dev libjpeg8-dev libopenjp2-7-dev zlib1g-dev libfreetype6-dev \
liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev libpq-dev libssl-dev \
libffi-dev python3-cffi libzip-dev

# wkhtmltopdf
wget -q https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb
sudo dpkg -i wkhtmltox_0.12.6.1-2.jammy_amd64.deb || sudo apt-get install -f -y
rm wkhtmltox_0.12.6.1-2.jammy_amd64.deb

# Usuario
sudo adduser --system --home=/opt/odoo --group odoo 2>/dev/null || true
sudo -u postgres createuser -s odoo 2>/dev/null || true

# Clonar Odoo
sudo git clone --depth 1 --branch 18.0 https://github.com/odoo/odoo /opt/odoo/odoo18
sudo chown -R odoo:odoo /opt/odoo/

# Entorno virtual
sudo python3 -m venv /opt/odoo/venv18
sudo chown -R odoo:odoo /opt/odoo/venv18

# Actualizar pip
sudo /opt/odoo/venv18/bin/pip install --upgrade pip wheel

# Instalar TODAS las dependencias
sudo /opt/odoo/venv18/bin/pip install \
babel \
lxml \
lxml_html_clean \
pyOpenSSL \
cryptography \
rjsmin \
geoip2 \
chardet \
python-stdnum \
openpyxl \
decorator \
docutils \
ebaysdk \
freezegun \
gevent \
greenlet \
html2text \
Jinja2 \
libsass \
MarkupSafe \
num2words \
ofxparse \
passlib \
Pillow \
polib \
psutil \
psycopg2-binary \
pydot \
pyparsing \
PyPDF2 \
pyserial \
python-dateutil \
python-ldap \
pytz \
pyusb \
qrcode \
reportlab \
requests \
vobject \
Werkzeug \
xlrd \
xlsxwriter \
xlwt \
zeep

# Requirements
sudo /opt/odoo/venv18/bin/pip install -r /opt/odoo/odoo18/requirements.txt

# Directorios
sudo mkdir -p /etc/odoo /var/log/odoo
sudo chown odoo:odoo /var/log/odoo

# Configuración
sudo tee /etc/odoo/odoo.conf > /dev/null <<EOF
[options]
admin_passwd = admin
db_host = False
db_port = False
db_user = odoo
db_password = False
addons_path = /opt/odoo/odoo18/addons
xmlrpc_port = 8069
proxy_mode = True
list_db = True
geoip_database = False
logfile = /var/log/odoo/odoo.log
log_level = info
EOF
sudo chown odoo:odoo /etc/odoo/odoo.conf
sudo chmod 640 /etc/odoo/odoo.conf

# Servicio
sudo tee /etc/systemd/system/odoo18.service > /dev/null <<EOF
[Unit]
Description=Odoo18
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
User=odoo
Group=odoo
ExecStart=/opt/odoo/venv18/bin/python3 /opt/odoo/odoo18/odoo-bin -c /etc/odoo/odoo.conf
StandardOutput=journal+console
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Iniciar
sudo systemctl daemon-reload
sudo systemctl enable odoo18
sudo systemctl start odoo18

# Obtener IP
IP=$(curl -s http://checkip.amazonaws.com)

echo "✅ Instalación completada"
echo "🔗 Accede a: http://$IP:8069"
echo "🔑 Password master: admin"
echo ""
echo "Verificar estado: sudo systemctl status odoo18"
