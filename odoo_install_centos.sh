#!/bin/bash
################################################################################
# Script for installing Odoo on CentOS 7
# Author: Dushko Davchev (Matkach)
#-------------------------------------------------------------------------------
# This script is based on the installation script of Yenthe V.G (https://github.com/Yenthe666/InstallScript)
# Inspired by his work I have created similar script for automated Odoo installation on CentOS 7 server. 
#-------------------------------------------------------------------------------
# Make a new file:
# nano odoo_install_centos.sh
# Place this content in it and then make the file executable:
# chmod +x odoo_install_centos.sh
# Execute the script to install Odoo:
# ./odoo_install_centos
################################################################################

ODOO_USER="odoo"

ODOO_HOME="$ODOO_USER"

ODOO_HOME_EXT="$ODOO_USER/$ODOO_USER"

INSTALL_WKHTMLTOPDF="True"

ODOO_PORT="8069"

ODOO_VERSION="12.0"

IS_ENTERPRISE="False"

ODOO_MASTER_PASSWD="Str0n9_PasSw0rD"

ODOO_CONFIG="/etc/$ODOO_USER.conf"

echo "---------------------- WARNING ----------------------------"
echo "The script is in beta-mode ... and it's not yet tested! :] "
echo "-----------------------------------------------------------"
echo " "

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"

yum update -y
yum upgrade -y

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------

echo -e "\n--- Dependencies & Tools --"

yum install epel-release wget git gcc libxslt-devel bzip2-devel openldap-devel libjpeg-devel freetype-devel -y

echo -e "\n--- Installing Python --"

yum install python-pip -y
pip install --upgrade pip
pip install --upgrade setuptools
pip install Babel decorator docutils ebaysdk feedparser gevent greenlet jcconv Jinja2 lxml Mako MarkupSafe mock ofxparse passlib Pillow psutil psycogreen psycopg2-binary pydot pyparsing pyPdf pyserial Python-Chart python-dateutil python-ldap python-openid pytz pyusb PyYAML qrcode reportlab requests six suds-jurko vatnumber vobject Werkzeug wsgiref XlsxWriter xlwt xlrd

yum install python36 -y

echo -e "\n---- Install python packages ----"

yum install python36-devel libxslt-devel libxml2-devel openldap-devel python36-setuptools python-devel -y
python3.6 -m ensurepip
pip3 install pypdf2 Babel passlib Werkzeug decorator python-dateutil pyyaml psycopg2-binary psutil html2text docutils lxml pillow reportlab ninja2 requests gdata XlsxWriter vobject python-openid pyparsing pydot mock mako Jinja2 ebaysdk feedparser xlwt psycogreen suds-jurko pytz pyusb greenlet xlrd num2words
pip3 install -r https://github.com/odoo/odoo/raw/$ODOO_VERSION/requirements.txt

echo -e "\n--- Install other required packages"
yum install nodejs npm -y
npm install -g less
npm install -g less-plugin-clean-css

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------

echo -e "\n---- Install PostgreSQL Server ----"
yum install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-redhat96-9.6-3.noarch.rpm -y
yum install postgresql96 postgresql96-server postgresql96-contrib postgresql96-libs -y

echo -e "\n---- Creating the ODOO PostgreSQL Database  ----"
/usr/pgsql-9.6/bin/postgresql96-setup initdb

echo -e "\n---- Enable & Start the ODOO PostgreSQL Database  ----"
systemctl start postgresql-9.6.service
systemctl enable postgresql-9.6.service

#--------------------------------------------------
# Creating Odoo and PostgreSQL users
#--------------------------------------------------

echo -e "\n---- Creating PostgreSQL user ----"
su - postgres -c "createuser -s $ODOO_USER"

echo -e "\n---- Creating Odoo user ----"
useradd -m -U -r -d $ODOO_HOME -s /bin/bash $ODOO_USER

#--------------------------------------------------
# Install Wkhtmltopdf
#--------------------------------------------------
yum install wkhtmltopdf -y

echo -e "\n---- Create Log directory ----"
mkdir /var/log/$ODOO_USER

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n==== Installing ODOO Server ===="
git clone --depth 1 --branch $ODOO_VERSION https://www.github.com/odoo/odoo $ODOO_HOME_EXT/

if [ $IS_ENTERPRISE = "True" ]; then
    # Odoo Enterprise install!
    echo -e "\n--- Create symlink for node"
    ln -s /usr/bin/nodejs /usr/bin/node
    mkdir $ODOO_HOME/enterprise
    mkdir $ODOO_HOME/enterprise/addons

    GITHUB_RESPONSE=$(git clone --depth 1 --branch $ODOO_VERSION https://www.github.com/odoo/enterprise "$ODOO_HOME/enterprise/addons" 2>&1)
    while [[ $GITHUB_RESPONSE == *"Authentication"* ]]; do
        echo "------------------------WARNING------------------------------"
        echo "Your authentication with Github has failed! Please try again."
        printf "In order to clone and install the Odoo enterprise version you \nneed to be an offical Odoo partner and you need access to\nhttp://github.com/odoo/enterprise.\n"
        echo "TIP: Press ctrl+c to stop this script."
        echo "-------------------------------------------------------------"
        echo " "
        GITHUB_RESPONSE=$(git clone --depth 1 --branch $ODOO_VERSION https://www.github.com/odoo/enterprise "$ODOO_HOME/enterprise/addons" 2>&1)
    done

    echo -e "\n---- Added Enterprise code under $ODOO_HOME/enterprise/addons ----"
    echo -e "\n---- Installing Enterprise specific libraries ----"
    pip3 install num2words ofxparse
    yum install nodejs npm
    npm install -g less
    npm install -g less-plugin-clean-css
fi

echo -e "\n---- Create custom module directory ----"

mv $ODOO_HOME_EXT/odoo.py $ODOO_HOME_EXT/odoo-bin
mkdir $ODOO_HOME/custom
mkdir $ODOO_HOME/custom/addons

echo -e "\n---- Create server config file"

touch $ODOO_CONFIG

echo "[options]" >> $ODOO_CONFIG
echo ";This is the password that allows database operations:" >> $ODOO_CONFIG
echo "admin_passwd = $ODOO_MASTER_PASSWD" >> $ODOO_CONFIG
echo "xmlrpc_port = $ODOO_PORT" >> $ODOO_CONFIG
echo "logfile = /var/log/$ODOO_USER/$ODOO_USER.log" >> $ODOO_CONFIG
if [ $IS_ENTERPRISE = "True" ]; then
    echo "addons_path=$ODOO_HOME/enterprise/addons,$ODOO_HOME_EXT/addons" >> $ODOO_CONFIG
else
    echo "addons_path=$ODOO_HOME_EXT/addons,$ODOO_HOME/custom/addons" >> $ODOO_CONFIG
fi

chmod 640 $ODOO_CONFIG

echo -e "\n---- Creating systemd config file"
touch /etc/systemd/system/$ODOO_USER.service

echo "[Unit]" >> /etc/systemd/system/$ODOO_USER.service
echo "Description=Odoo server" >> /etc/systemd/system/$ODOO_USER.service
echo "#Requires=postgresql-9.6.service" >> /etc/systemd/system/$ODOO_USER.service
echo "#After=network.target postgresql-9.6.service" >> /etc/systemd/system/$ODOO_USER.service
echo "[Service]" >> /etc/systemd/system/$ODOO_USER.service
echo "Type=simple" >> /etc/systemd/system/$ODOO_USER.service
echo "SyslogIdentifier=odoo12" >> /etc/systemd/system/$ODOO_USER.service
echo "PermissionsStartOnly=true" >> /etc/systemd/system/$ODOO_USER.service
echo "User=$ODOO_USER" >> /etc/systemd/system/$ODOO_USER.service
echo "Group=$ODOO_USER" >> /etc/systemd/system/$ODOO_USER.service
echo "ExecStart=$ODOO_HOME/$ODOO_USER/odoo-bin -c /etc/$ODOO_USER.conf" >> /etc/systemd/system/$ODOO_USER.service
echo "StandardOutput=journal+console" >> /etc/systemd/system/$ODOO_USER.service
echo "[Install]" >> /etc/systemd/system/$ODOO_USER.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/$ODOO_USER.service

echo -e "\n---- Start ODOO on Startup"
chmod +x /etc/systemd/system/$ODOO_USER.service
systemctl daemon-reload

chown -R $ODOO_USER: $ODOO_HOME
chown $ODOO_USER: $ODOO_CONFIG

echo -e "\n---- Starting Odoo Service"

systemctl start $ODOO_USER.service
systemctl enable $ODOO_USER.service

echo "-----------------------------------------------------------"
echo "Done! The Odoo server is up and running. Specifications:"
echo "-----------------------------------------------------------"
echo "Port: $ODOO_PORT"
echo "Master password: $ODOO_MASTER_PASSWD"
echo "User service: $ODOO_USER"
echo "User PostgreSQL: $ODOO_USER"
echo "Addons folder: $ODOO_USER/$ODOO_CONFIG/addons/"
echo "Start Odoo service: service $ODOO_USER start"
echo "Stop Odoo service: service $ODOO_USER stop"
echo "Restart Odoo service: service $ODOO_USER restart"
echo "-----------------------------------------------------------"

echo " "
echo "---------------------- WARNING ----------------------------"
echo "The script is in beta-mode ... and it's not yet tested! :] "
echo "-----------------------------------------------------------"
