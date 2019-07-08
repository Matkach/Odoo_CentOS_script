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
... not finished.
