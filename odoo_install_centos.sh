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

ODOO_USER="odoo"

ODOO_HOME="$ODOO_USER"

ODOO_HOME_EXT="$ODOO_USER/$ODOO_USER"

INSTALL_WKHTMLTOPDF="True"

ODOO_PORT="8069"

ODOO_VERSION="12.0"

IS_ENTERPRISE="False"

ODOO_MASTER_PASSWD="Str0n9_PasSw0rD"

ODOO_CONFIG="/etc/$ODOO_USER.conf"

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo yum update -y
sudo yum upgrade -y

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n--- Dependencies & Tools --"
sudo yum install epel-release wget git -y

echo -e "\n--- Installing Python3 --"
sudo yum install python36 -y

echo -e "\n---- Install python3 packages ----"
sudo yum install python36-devel libxslt-devel libxml2-devel openldap-devel python36-setuptools -y
python3.6 -m ensurepip
#pip3 install pypdf2 Babel passlib Werkzeug decorator python-dateutil pyyaml psycopg2 psutil html2text docutils lxml pillow reportlab ninja2 requests gdata XlsxWriter vobject python-openid pyparsing pydot mock mako Jinja2 ebaysdk feedparser xlwt psycogreen suds-jurko #pytz pyusb greenlet xlrd 
pip3 install -r https://github.com/odoo/odoo/raw/$ODOO_VERSION/requirements.txt

echo -e "\n--- Install other required packages"
yum install nodejs npm -y
npm install -g less
npm install -g less-plugin-clean-css

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
echo -e "\n---- Install PostgreSQL Server ----"
yum install postgresql -y

echo -e "\n---- Creating the ODOO PostgreSQL Database  ----"
postgresql-setup initdb

echo -e "\n---- Enable & Start the ODOO PostgreSQL Database  ----"
systemctl enable postgresql
systemctl start postgresql

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
sudo git clone --depth 1 --branch $ODOO_VERSION https://www.github.com/odoo/odoo $ODOO_HOME_EXT/

if [ $IS_ENTERPRISE = "True" ]; then
    # Odoo Enterprise install!
    echo -e "\n--- Create symlink for node"
    ln -s /usr/bin/nodejs /usr/bin/node
    mkdir $ODOO_HOME/enterprise
    mkdir $ODOO_HOME/enterprise/addons

    GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $ODOO_VERSION https://www.github.com/odoo/enterprise "$ODOO_HOME/enterprise/addons" 2>&1)
    while [[ $GITHUB_RESPONSE == *"Authentication"* ]]; do
        echo "------------------------WARNING------------------------------"
        echo "Your authentication with Github has failed! Please try again."
        printf "In order to clone and install the Odoo enterprise version you \nneed to be an offical Odoo partner and you need access to\nhttp://github.com/odoo/enterprise.\n"
        echo "TIP: Press ctrl+c to stop this script."
        echo "-------------------------------------------------------------"
        echo " "
        GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $ODOO_VERSION https://www.github.com/odoo/enterprise "$ODOO_HOME/enterprise/addons" 2>&1)
    done

    echo -e "\n---- Added Enterprise code under $ODOO_HOME/enterprise/addons ----"
    echo -e "\n---- Installing Enterprise specific libraries ----"
    pip3 install num2words ofxparse
    yum install nodejs npm
    npm install -g less
    npm install -g less-plugin-clean-css
fi

echo -e "\n---- Create custom module directory ----"
mkdir $ODOO_HOME/custom
mkdir $ODOO_HOME/custom/addons

echo -e "\n---- Create server config file"

sudo touch $ODOO_CONFIG

sudo echo "[options]" >> $CONF_ODOO
sudo echo ";This is the password that allows database operations:" >> $ODOO_CONFIG
sudo echo "Master_password = $ODOO_MASTER_PASSWD" >> $ODOO_CONFIG
sudo echo "xmlrpc_port = $ODOO_PORT" >> $ODOO_CONFIG
sudo echo "logfile = /var/log/$ODOO_USER/$ODOO_USER.log" >> $ODOO_CONFIG
if [ $IS_ENTERPRISE = "True" ]; then
    sudo echo "addons_path=$ODOO_HOME/enterprise/addons,$ODOO_HOME_EXT/addons" >> $ODOO_CONFIG
else
    sudo echo "addons_path=$ODOO_HOME_EXT/addons,$ODOO_HOME/custom/addons" >> $ODOO_CONFIG
fi

sudo chmod 640 $ODOO_CONFIG

echo -e "\n---- Creating systemd config file"
touch /etc/systemd/system/$ODOO_USER.service

sudo echo "[Unit]" >> /etc/systemd/system/$ODOO_USER.service
sudo echo "Description=Odoo12" >> /etc/systemd/system/$ODOO_USER.service
sudo echo "Requires=postgresql-9.6.service" >> /etc/systemd/system/$ODOO_USER.service
sudo echo "After=network.target postgresql-9.6.service" >> /etc/systemd/system/$ODOO_USER.service
sudo echo "[Service]" >> /etc/systemd/system/$ODOO_USER.service
sudo echo "Type=simple" >> /etc/systemd/system/$ODOO_USER.service
sudo echo "SyslogIdentifier=odoo12" >> /etc/systemd/system/$ODOO_USER.service
sudo echo "PermissionsStartOnly=true" >> /etc/systemd/system/$ODOO_USER.service
sudo echo "User=$ODOO_USER" >> /etc/systemd/system/$ODOO_USER.service
sudo echo "Group=$ODOO_USER" >> /etc/systemd/system/$ODOO_USER.service
sudo echo "ExecStart=$ODOO_HOME/$ODOO_USER/odoo-bin -c /etc/$ODOO_USER.conf" >> /etc/systemd/system/$ODOO_USER.service
sudo echo "StandardOutput=journal+console" >> /etc/systemd/system/$ODOO_USER.service
sudo echo "[Install]" >> /etc/systemd/system/$ODOO_USER.service
sudo echo "WantedBy=multi-user.target" >> /etc/systemd/system/$ODOO_USER.service

echo -e "\n---- Start ODOO on Startup"
sudo update-rc.d $ODOO_CONFIG defaults
sudo systemctl daemon-reload

chown -R $ODOO_USER: $ODOO_HOME
chown $ODOO_USER: $ODOO_CONFIG

echo -e "\n---- Starting Odoo Service"

sudo systemctl start $ODOO_USER.service
sudo systemctl enable $ODOO_USER.service

echo "-----------------------------------------------------------"
echo "Done! The Odoo server is up and running. Specifications:"
echo "-----------------------------------------------------------"
echo "Port: $ODOO_PORT"
echo "Master password: $ODOO_MASTER_PASSWD"
echo "User service: $ODOO_USER"
echo "User PostgreSQL: $ODOO_USER"
echo "Addons folder: $ODOO_USER/$ODOO_CONFIG/addons/"
echo "Start Odoo service: sudo service $ODOO_CONFIG start"
echo "Stop Odoo service: sudo service $ODOO_CONFIG stop"
echo "Restart Odoo service: sudo service $ODOO_CONFIG restart"
echo "-----------------------------------------------------------"

echo "---------------------- WARNING ----------------------------"
echo "The script is in beta-mode ... and it's not yet tested! :] "

