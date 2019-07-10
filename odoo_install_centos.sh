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

#!/bin/bash

OE_USER="odoo"

OE_HOME="/opt/$OE_USER"

OE_HOME_EXT="/opt/$OE_USER/$OE_USER"

INSTALL_WKHTMLTOPDF="True"

OE_PORT="8069"

OE_VERSION="12.0"

IS_ENTERPRISE="False"

OE_SUPERADMIN="Str0n9_Pas$w0rD"

OE_CONFIG="$OE_USER"

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo yum update -y
yum upgrade -y

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n--- Dependencies & Tools --"
sudo yum install epel-release wget git -y

echo -e "\n--- Installing Python3 --"
sudo yum install python36 -y

echo -e "\n---- Install python3 packages ----"
yum install python36-devel libxslt-devel libxml2-devel openldap-devel python36-setuptools-y
python3.6 -m ensurepip
#pip3 install pypdf2 Babel passlib Werkzeug decorator python-dateutil pyyaml psycopg2 psutil html2text docutils lxml pillow reportlab ninja2 requests gdata XlsxWriter vobject python-openid pyparsing pydot mock mako Jinja2 ebaysdk feedparser xlwt psycogreen suds-jurko #pytz pyusb greenlet xlrd 
pip3 install -r https://github.com/odoo/odoo/raw/$OE_VERSION/requirements.txt

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
su - postgres -c "createuser -s $OE_USER"

echo -e "\n---- Creating Odoo user ----"
useradd -m -U -r -d $OE_HOME -s /bin/bash $OE_USER

#--------------------------------------------------
# Install Wkhtmltopdf
#--------------------------------------------------
yum install wkhtmltopdf -y

echo -e "\n---- Create Log directory ----"
mkdir /var/log/$OE_USER

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n==== Installing ODOO Server ===="
sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME_EXT/

if [ $IS_ENTERPRISE = "True" ]; then
    # Odoo Enterprise install!
    echo -e "\n--- Create symlink for node"
    ln -s /usr/bin/nodejs /usr/bin/node
    mkdir $OE_HOME/enterprise
    mkdir $OE_HOME/enterprise/addons

    GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    while [[ $GITHUB_RESPONSE == *"Authentication"* ]]; do
        echo "------------------------WARNING------------------------------"
        echo "Your authentication with Github has failed! Please try again."
        printf "In order to clone and install the Odoo enterprise version you \nneed to be an offical Odoo partner and you need access to\nhttp://github.com/odoo/enterprise.\n"
        echo "TIP: Press ctrl+c to stop this script."
        echo "-------------------------------------------------------------"
        echo " "
        GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    done

    echo -e "\n---- Added Enterprise code under $OE_HOME/enterprise/addons ----"
    echo -e "\n---- Installing Enterprise specific libraries ----"
    pip3 install num2words ofxparse
    yum install nodejs npm
    npm install -g less
    npm install -g less-plugin-clean-css
fi

echo -e "\n---- Create custom module directory ----"
mkdir $OE_HOME/custom
mkdir $OE_HOME/custom/addons

echo -e "* Create server config file"

sudo touch /etc/$OE_CONFIG.conf
echo -e "* Creating server config file"
printf '[options] \n; This is the password that allows database operations:\n' >> /etc/$OE_CONFIG.conf
printf 'admin_passwd = $OE_SUPERADMIN\n' >> /etc/$OE_CONFIG.conf
printf 'xmlrpc_port = $OE_PORT\n' >> /etc/$OE_CONFIG.conf
printf 'logfile = /var/log/$OE_USER/$OE_CONFIG.log\n' >> /etc/$OE_CONFIG.conf
if [ $IS_ENTERPRISE = "True" ]; then
    printf 'addons_path=$OE_HOME/enterprise/addons,$OE_HOME_EXT/addons\n' >> /etc/$OE_CONFIG.conf
else
    printf 'addons_path=$OE_HOME_EXT/addons,$OE_HOME/custom/addons\n' >> /etc/$OE_CONFIG.conf
fi

sudo chmod 640 /etc/$OE_CONFIG.conf

echo -e "* Create startup file"
echo '#!/bin/sh' >> $OE_HOME_EXT/start.sh
chmod 755 $OE_HOME_EXT/start.sh

#--------------------------------------------------
# Adding ODOO as a deamon (initscript)
#--------------------------------------------------

echo -e "* Create init file"
cat <<EOF > ~/$OE_CONFIG
#!/bin/sh
### BEGIN INIT INFO
# Provides: $OE_CONFIG
# Required-Start: \$remote_fs \$syslog
# Required-Stop: \$remote_fs \$syslog
# Should-Start: \$network
# Should-Stop: \$network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Enterprise Business Applications
# Description: ODOO Business Applications
### END INIT INFO
PATH=/bin:/sbin:/usr/bin
DAEMON=$OE_HOME_EXT/odoo-bin
NAME=$OE_CONFIG
DESC=$OE_CONFIG
# Specify the user name (Default: odoo).
USER=$OE_USER
# Specify an alternate config file (Default: /etc/openerp-server.conf).
CONFIGFILE="/etc/$OE_CONFIG.conf"
# pidfile
PIDFILE=/var/run/\$NAME.pid
# Additional options that are passed to the Daemon.
DAEMON_OPTS="-c \$CONFIGFILE"
[ -x \$DAEMON ] || exit 0
[ -f \$CONFIGFILE ] || exit 0
checkpid() {
[ -f \$PIDFILE ] || return 1
pid=\`cat \$PIDFILE\`
[ -d /proc/\$pid ] && return 0
return 1
}
case "\$1" in
start)
echo -n "Starting \$DESC: "
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\$NAME."
;;
stop)
echo -n "Stopping \$DESC: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
echo "\$NAME."
;;
restart|force-reload)
echo -n "Restarting \$DESC: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
sleep 1
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\$NAME."
;;
*)
N=/etc/init.d/\$NAME
echo "Usage: \$NAME {start|stop|restart|force-reload}" >&2
exit 1
;;
esac
exit 0
EOF

echo -e "* Security Init File"
sudo mv ~/$OE_CONFIG /etc/init.d/$OE_CONFIG
sudo chmod 755 /etc/init.d/$OE_CONFIG
sudo chown root: /etc/init.d/$OE_CONFIG

echo -e "* Creating systemd config file"
touch /etc/systemd/system/$OE_USER.service
printf '[Unit] \n Description=Odoo12\n' >> /etc/systemd/system/$OE_USER.service
printf 'Requires=postgresql-9.6.service\n' >> /etc/systemd/system/$OE_USER.service
printf 'After=network.target postgresql-9.6.service\n; \n' >> /etc/systemd/system/$OE_USER.service
printf '[Service] \n Type=simple\n' >> /etc/systemd/system/$OE_USER.service
printf 'SyslogIdentifier=odoo12\n' >> /etc/systemd/system/$OE_USER.service
printf 'PermissionsStartOnly=true\n' >> /etc/systemd/system/$OE_USER.service
printf 'User=$OE_USER\n' >> /etc/systemd/system/$OE_USER.service
printf 'Group=$OE_USER\n' >> /etc/systemd/system/$OE_USER.service
printf 'ExecStart=$OE_HOME/$OE_USER/odoo-bin -c /etc/$OE_USER.conf\n' >> /etc/systemd/system/$OE_USER.service
printf 'StandardOutput=journal+console\n' >> /etc/systemd/system/$OE_USER.service
printf ' \n [Install] \n WantedBy=multi-user.target\n' >> /etc/systemd/system/$OE_USER.service

echo -e "* Start ODOO on Startup"
sudo update-rc.d $OE_CONFIG defaults
sudo systemctl daemon-reload

chown -R $OE_USER: $OE_HOME
chown $OE_USER: /etc/$OE_CONFIG.conf

echo -e "* Starting Odoo Service"
etc/init.d/$OE_CONFIG start

echo "-----------------------------------------------------------"
echo "Done! The Odoo server is up and running. Specifications:"
echo "Port: $OE_PORT"
echo "User service: $OE_USER"
echo "User PostgreSQL: $OE_USER"
echo "Code location: $OE_USER"
echo "Addons folder: $OE_USER/$OE_CONFIG/addons/"
echo "Start Odoo service: sudo service $OE_CONFIG start"
echo "Stop Odoo service: sudo service $OE_CONFIG stop"
echo "Restart Odoo service: sudo service $OE_CONFIG restart"
echo "-----------------------------------------------------------"


