#!/bin/bash
################################################################################
# Script for installing Odoo on CentOS 7
# Author: Dushko Davchev (Matkach)
#-------------------------------------------------------------------------------
# This script is based on the installation script of Yenthe V.G (https://github.com/Yenthe666/InstallScript)
# Inspired by his work I have created similar script for automated Odoo installation on CentOS 7 server. 
################################################################################

LPURPLE='\033[1;35m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

#--------------------------------------------------
# Questions for the user
#--------------------------------------------------
echo
echo -e "Please insert the information required for the ${LPURPLE}Odoo${NC} installation."
echo ""

echo -n "Insert Odoo user name (default: odoo): "
read ODOO_USER

ODOO_USER="${ODOO_USER:-odoo}"

echo
echo -e "You have selected the ${BLUE}$ODOO_USER${NC} as username"
echo ""

echo -n "Insert Odoo location (default: /opt/$ODOO_USER): "
read LOCATION

LOCATION="${LOCATION:-/opt/$ODOO_USER}"

  if  [[ $LOCATION == / ]] || [[ $LOCATION == /* ]] ;
    then
        ODOO_HOME="$LOCATION/$ODOO_USER"
    else
        ODOO_HOME="/$LOCATION/$ODOO_USER"
  fi

mkdir -p $ODOO_HOME

echo
echo -e "You have selected the following location ${BLUE}$LOCATION${NC}"
echo ""

echo
while ! [[ "$ODOO_PORT" =~ ^[0-9]+$ ]]
do

echo -n "Inset Odoo port number (default: 8069) : "
read ODOO_PORT
echo

ODOO_PORT="${ODOO_PORT:-8069}"

done

echo
echo -e "You have selected the following port number: ${BLUE}$ODOO_PORT${NC}"
echo ""

echo
while true; do
echo
echo -e "Select the Odoo version: "
echo ""
echo -e "${GREEN}1${NC}) Odoo version ${LPURPLE}12.0${NC}"
echo ""
echo -e "${GREEN}2${NC}) Odoo version ${LPURPLE}11.0${NC}"
echo ""
echo -e "${GREEN}3${NC}) Odoo version ${LPURPLE}10.0${NC}"
echo ""
echo -e "${GREEN}4${NC}) Odoo version  ${LPURPLE}9.0${NC}"
echo ""
echo -ne "Choose a number from ${GREEN}1${NC} to ${GREEN}4${NC}: " 
read SELECT_VERSION

echo

case $SELECT_VERSION in
     1)
     ODOO_VERSION="12.0"
     break
     ;;
     2)
     ODOO_VERSION="11.0"
     break
     ;;
     3)
     ODOO_VERSION="10.0"
     break
     ;;
     4)
     ODOO_VERSION="9.0"
     break
     ;;
     q)
     echo "The quit option was selected, and the script has stopped. Goodbye, until the next time."
     exit -1
     break
     ;;
     Q)
     echo "The quit option was selected, and the script has stopped. Goodbye, until the next time."
     exit -1
     break
     ;;
     *)
     echo -e "The ${RED}$SELECT_VERSION${NC} is not a valid choice. Choose from ${GREEN}1${NC} to ${GREEN}4${NC} or type q for quit."
     ;;
esac  
done

echo
echo -e "You have selected the ${LPURPLE}Odoo${NC} version ${LPURPLE}$ODOO_VERSION ${NC}"
echo ""

echo
while true; do
echo -ne "Please select your ${LPURPLE}Odoo${NC} Edition. "
echo ""
echo -e "${GREEN}1${NC}) - Enterprise edition"
echo ""
echo -e "${GREEN}2${NC}) - Community Edition"
echo ""
echo -ne "Please select your choice: " 
read ODOO_EDITON

echo

case $ODOO_EDITON in
     1)
     ENTERPRISE_EDITON="Y"
     echo ""
     echo -e "You have choose the ${LPURPLE}Enterprise Edition${NC}"
     break
     ;;
     2)
     ENTERPRISE_EDITON="N"
     echo ""
     echo -e "You have choose the ${LPURPLE}Community Edition${NC}"
     break
     ;;
     q)
     echo -e "The quit option was selected, and the script has stopped. Goodbye, until the next time."
     exit -1
     break
     ;;
     Q)
     echo -e "The quit option was selected, and the script has stopped. Goodbye, until the next time."
     exit -1
     break
     ;;
     *)
     echo -e "The ${RED}$ODOO_EDITON${NC} is not a valid choice. Please select from the offered options ${GREEN}1${NC}/${GREEN}2${NC} or you can type ${GREEN}q${NC} for quit."
     ;;
esac  
done

echo
echo -ne "Please insert your ${LPURPLE}Odoo Master Password${NC}: "
read -s ODOO_MASTER_PASSWD
echo

ODOO_HOME_EXT="$ODOO_HOME/$ODOO_USER"
ODOO_CONFIG="/etc/$ODOO_USER.conf"

echo 
echo ""
echo -e "---------------------- ${RED}WARNING${NC} ----------------------------"
echo "The script is in beta-mode ... and it's not yet tested! :] "
echo "-----------------------------------------------------------"
echo 

function install_odoo_centos {

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

sudo yum install epel-release wget git gcc libxslt-devel bzip2-devel openldap-devel libjpeg-devel freetype-devel -y

echo -e "\n--- Installing Python --"

sudo yum install python-pip -y
sudo pip install --upgrade pip
sudo pip install --upgrade setuptools
#sudo pip install Babel decorator docutils ebaysdk feedparser gevent greenlet jcconv Jinja2 lxml Mako MarkupSafe mock ofxparse passlib Pillow psutil psycogreen psycopg2-binary pydot pyparsing pyPdf pyserial Python-Chart python-dateutil python-ldap python-openid pytz pyusb PyYAML qrcode reportlab requests six suds-jurko vatnumber vobject Werkzeug wsgiref XlsxWriter xlwt xlrd
sudo pip install -r https://github.com/odoo/odoo/raw/$ODOO_VERSION/requirements.txt

sudo yum install python36 -y

echo -e "\n---- Install python packages ----"

sudo yum install python36-devel libxslt-devel libxml2-devel openldap-devel python36-setuptools python-devel -y
python3.6 -m ensurepip
#sudo pip3 install pypdf2 Babel passlib Werkzeug decorator python-dateutil pyyaml psycopg2-binary psutil html2text docutils lxml pillow reportlab ninja2 requests gdata XlsxWriter vobject python-openid pyparsing pydot mock mako Jinja2 ebaysdk feedparser xlwt psycogreen suds-jurko pytz pyusb greenlet xlrd num2words
sudo pip3 install -r https://github.com/odoo/odoo/raw/$ODOO_VERSION/requirements.txt

echo -e "\n--- Install other required packages"
sudo yum install nodejs npm -y
sudo npm install -g less
sudo npm install -g less-plugin-clean-css
sudo npm install -g rtlcss

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------

echo -e "\n---- Install PostgreSQL Server ----"
sudo yum install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-redhat96-9.6-3.noarch.rpm -y
sudo yum install postgresql96 postgresql96-server postgresql96-contrib postgresql96-libs -y

echo -e "\n---- Creating the ODOO PostgreSQL Database  ----"
sudo /usr/pgsql-9.6/bin/postgresql96-setup initdb

echo -e "\n---- Enable & Start the ODOO PostgreSQL Database  ----"
sudo systemctl start postgresql-9.6.service
sudo systemctl enable postgresql-9.6.service

#--------------------------------------------------
# Creating Odoo and PostgreSQL users
#--------------------------------------------------

echo -e "\n---- Creating PostgreSQL user ----"
sudo su - postgres -c "createuser -s $ODOO_USER"

echo -e "\n---- Creating Odoo user ----"
sudo useradd -m -U -r -d $ODOO_HOME -s /bin/bash $ODOO_USER

#--------------------------------------------------
# Install Wkhtmltopdf
#--------------------------------------------------
sudo yum install wkhtmltopdf -y

echo -e "\n---- Create Log directory ----"
sudo mkdir /var/log/$ODOO_USER

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n==== Installing ODOO Server ===="
sudo git clone --depth 1 --branch $ODOO_VERSION https://www.github.com/odoo/odoo $ODOO_HOME_EXT/

if [ $ENTERPRISE_EDITON = "Y" ]; then
    # Odoo Enterprise install!
    echo -e "\n--- Create symlink for node"
    sudo ln -s /usr/bin/nodejs /usr/bin/node
    sudo mkdir $ODOO_HOME/enterprise
    sudo mkdir $ODOO_HOME/enterprise/addons

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
    sudo pip3 install num2words ofxparse
    sudo yum install nodejs npm
    sudo npm install -g less
    sudo npm install -g less-plugin-clean-css
fi

echo -e "\n---- Create custom module directory ----"

sudo mv $ODOO_HOME_EXT/odoo.py $ODOO_HOME_EXT/odoo-bin
sudo mkdir $ODOO_HOME/custom
sudo mkdir $ODOO_HOME/custom/addons

echo -e "\n---- Create server config file"

sudo su root -c "touch '$ODOO_CONFIG'"

sudo su root -c "echo "[options]" >> $ODOO_CONFIG"
sudo su root -c "echo ';This is the password that allows database operations:' >> $ODOO_CONFIG"
sudo su root -c "echo 'admin_passwd = $ODOO_MASTER_PASSWD' >> $ODOO_CONFIG"
sudo su root -c "echo 'xmlrpc_port = $ODOO_PORT' >> $ODOO_CONFIG"
sudo su root -c "echo 'logfile = /var/log/$ODOO_USER/$ODOO_USER.log' >> $ODOO_CONFIG"
if [ $ENTERPRISE_EDITON = "Y" ]; then
    sudo su root -c "echo 'addons_path=$ODOO_HOME/enterprise/addons,$ODOO_HOME_EXT/addons' >> $ODOO_CONFIG"
else
    sudo su root -c "echo 'addons_path=$ODOO_HOME_EXT/addons,$ODOO_HOME/custom/addons' >> $ODOO_CONFIG"
fi

sudo chmod 640 $ODOO_CONFIG

echo -e "\n---- Creating systemd config file"
sudo touch /etc/systemd/system/$ODOO_USER.service

sudo su root -c "echo "[Unit]" >> /etc/systemd/system/$ODOO_USER.service"
sudo su root -c "echo 'Description=Odoo server' >> /etc/systemd/system/$ODOO_USER.service"
sudo su root -c "echo '#Requires=postgresql-9.6.service' >> /etc/systemd/system/$ODOO_USER.service"
sudo su root -c "echo '#After=network.target postgresql-9.6.service' >> /etc/systemd/system/$ODOO_USER.service"
sudo su root -c "echo "[Service]" >> /etc/systemd/system/$ODOO_USER.service"
sudo su root -c "echo 'Type=simple' >> /etc/systemd/system/$ODOO_USER.service"
sudo su root -c "echo 'SyslogIdentifier=odoo12' >> /etc/systemd/system/$ODOO_USER.service"
sudo su root -c "echo 'PermissionsStartOnly=true' >> /etc/systemd/system/$ODOO_USER.service"
sudo su root -c "echo 'User=$ODOO_USER' >> /etc/systemd/system/$ODOO_USER.service"
sudo su root -c "echo 'Group=$ODOO_USER' >> /etc/systemd/system/$ODOO_USER.service"
sudo su root -c "echo 'ExecStart=$ODOO_HOME/$ODOO_USER/odoo-bin -c /etc/$ODOO_USER.conf' >> /etc/systemd/system/$ODOO_USER.service"
sudo su root -c "echo 'StandardOutput=journal+console' >> /etc/systemd/system/$ODOO_USER.service"
sudo su root -c "echo "[Install]" >> /etc/systemd/system/$ODOO_USER.service"
sudo su root -c "echo 'WantedBy=multi-user.target' >> /etc/systemd/system/$ODOO_USER.service"

echo -e "\n---- Start ODOO on Startup"
sudo chmod +x /etc/systemd/system/$ODOO_USER.service
sudo systemctl daemon-reload

sudo chown -R $ODOO_USER: $ODOO_HOME
sudo chown $ODOO_USER: $ODOO_CONFIG

echo -e "\n---- Starting Odoo Service"

sudo systemctl start $ODOO_USER.service
sudo systemctl enable $ODOO_USER.service
sudo systemctl status $ODOO_USER.service

echo "-----------------------------------------------------------"
echo "Done! The Odoo server is up and running. Specifications:"
echo "-----------------------------------------------------------"
echo "Port: $ODOO_PORT"
echo "Master password: $ODOO_MASTER_PASSWD"
echo "User service: $ODOO_USER"
echo "User PostgreSQL: $ODOO_USER"
echo "Addons folder: $ODOO_HOME_EXT/addons and $ODOO_HOME/custom/addons"
echo "Start Odoo service: service $ODOO_USER start"
echo "Stop Odoo service: service $ODOO_USER stop"
echo "Restart Odoo service: service $ODOO_USER restart"
echo "-----------------------------------------------------------"
echo " "

}

echo
while true; do
echo "---------------------------------------------------------------"
echo "Your Odoo will be installed with the following specifications: "
echo "---------------------------------------------------------------"
echo "Odoo username: $ODOO_USER"
echo "Location will be at: $ODOO_HOME"
echo "Odoo port number: $ODOO_PORT"
echo "Odoo Master password: $ODOO_MASTER_PASSWD"
echo "Addons folder: $ODOO_HOME_EXT/addons and $ODOO_HOME/custom/addons"
echo "Start Odoo service: service $ODOO_USER start"
echo "Stop Odoo service: service $ODOO_USER stop"
echo "Restart Odoo service: service $ODOO_USER restart"
echo ""
echo "-----------------------------------------------------------"
echo -n "Do you want to proceed with the installation (y/n)? "
read FINAL_QUESTION
echo "-----------------------------------------------------------"

echo

case $FINAL_QUESTION in
     Y)
     ODOO_INSTALL="Y"
     echo ""
     echo -e "Please wait. The installation will begin shortly"
     break
     ;;
     y)
     ODOO_INSTALL="y"
     echo ""
     echo -e "Please wait. The installation will begin shortly"
     break
     ;;
     N)
     ODOO_INSTALL="n"
     echo ""
     echo -e "You have choose NO. Bye Bye."
     exit -1
     break
     ;;
     n)
     ODOO_INSTALL="N"
     echo ""
     echo -e "You have choose NO. Bye Bye."
     exit -1
     break
     ;;
     q)
     echo -e "The quit option was selected, and the script has stopped. Goodbye, until the next time."
     exit -1
     break
     ;;
     Q)
     echo -e "The quit option was selected, and the script has stopped. Goodbye, until the next time."
     exit -1
     break
     ;;
     *)
     echo -e "The ${RED}$FINAL_QUESTION${NC} is not a valid choice, try with ${GREEN}Y${NC}/${GREEN}N${NC} or type ${GREEN}q${NC} for quit."
     ;;
esac  
done

if [ "$ODOO_INSTALL" = y ] || [ "$ODOO_INSTALL" = Y ]
    then
        install_odoo_centos
else
                    exit 0
    fi
