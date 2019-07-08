#!/bin/bash
################################################################################
# Script for installing Odoo on CentOS 7
# Author: Dushko Davchev (Matkach)
#-------------------------------------------------------------------------------
# This script is based on the installation script of Yenthe V.G (https://github.com/Yenthe666/InstallScript)
# Inspired by his work I have created similar script for automated Odoo installation on CentOS 7 server. 
#-------------------------------------------------------------------------------
# Make a new file:
# sudo nano odoo_install_centos.sh
# Place this content in it and then make the file executable:
# sudo chmod +x odoo_install_centos.sh
# Execute the script to install Odoo:
# ./odoo_install_centos
################################################################################

yum update
yum install -y epel-release centos-release-scl rh-python35 git gcc wget nodejs-less libxslt-devel bzip2-devel openldap-devel libjpeg-devel freetype-devel
useradd -m -U -r -d /opt/odoo -s /bin/bash odoo
yum install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-redhat96-9.6-3.noarch.rpm -y
yum install postgresql96 postgresql96-server postgresql96-contrib postgresql96-libs -y
/usr/pgsql-9.6/bin/postgresql96-setup initdb
systemctl start postgresql-9.6.service
systemctl enable postgresql-9.6.service
su - postgres -c "createuser -s odoo"
cd /opt/
wget https://downloads.wkhtmltopdf.org/0.12/0.12.5/wkhtmltox-0.12.5-1.centos7.x86_64.rpm
yum localinstall wkhtmltox-0.12.5-1.centos7.x86_64.rpm -y
git clone https://www.github.com/odoo/odoo --depth 1 --branch 12.0 /opt/odoo/odoo12
scl enable rh-python35 bash
cd /opt/odoo
python3 -m venv odoo12-venv
source odoo12-venv/bin/activate
pip install --upgrade pip
pip3 install wheel
pip3 install -r odoo12/requirements.txt
deactivate && exit

mkdir /opt/odoo/odoo12-custom-addons
chown odoo: /opt/odoo/odoo12-custom-addons
nano /etc/odoo.conf

sudo touch /etc/odoo.conf
printf '[options] \n; This is the password that allows database operations:\n' >> /etc/odoo.conf
printf 'admin_passwd = master_password\n' >> /etc/odoo.conf
printf 'db_host = False\n' >> /etc/odoo.conf
printf 'db_port = False\n' >> /etc/odoo.conf
printf 'db_user = odoo\n' >> /etc/odoo.conf
printf 'xmlrpc_port = 8069\n' >> /etc/odoo.conf
printf 'logfile = /var/log/odoo/odoo.log\n' >> /etc/odoo.conf
printf 'addons_path=/opt/odoo/odoo12/addons,/opt/odoo/odoo12-custom-addons\n' >> /etc/odoo.conf

touch /etc/systemd/system/odoo.service
printf '[Unit] \n; Description=Odoo12\n' >> /etc/systemd/system/odoo.service
printf 'Requires=postgresql-9.6.service\n' >> /etc/systemd/system/odoo.service
printf 'After=network.target postgresql-9.6.service\n; \n' >> /etc/systemd/system/odoo.service
printf '[Service] \n; Type=simple\n' >> /etc/systemd/system/odoo.service
printf 'SyslogIdentifier=odoo12\n' >> /etc/systemd/system/odoo.service
printf 'PermissionsStartOnly=true\n' >> /etc/systemd/system/odoo.service
printf 'User=odoo\n' >> /etc/systemd/system/odoo.service
printf 'Group=odoo\n' >> /etc/systemd/system/odoo.service
printf 'ExecStart=/usr/bin/scl enable rh-python35 -- /opt/odoo/odoo12-venv/bin/python3 /opt/odoo/odoo12/odoo-bin -c /etc/odoo.conf\n' >> /etc/systemd/system/odoo.service
printf 'StandardOutput=journal+console\n' >> /etc/systemd/system/odoo.service
printf ' \n; [Install] \n; WantedBy=multi-user.target\n' >> /etc/systemd/system/odoo.service

systemctl daemon-reload
systemctl start odoo
systemctl enable odoo

echo "Done! The Odoo server is up and running."


