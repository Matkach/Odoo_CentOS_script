# Odoo_CentOS_script

Automated bash script for installing Odoo on CentOS.

This script is based on the installation script of Yenthe V.G (https://github.com/Yenthe666/InstallScript)
Inspired by his work I have created similar script for automated Odoo installation on CentOS 7 server. 

Make a new file:
<pre>sudo nano odoo_install_centos.sh</pre>

You can also modify the script if you would like and change the version you would like to install, the location of where it will installed, whether you install the enterprise version or not and most important you can change the master admin password you would like to use.

After you make the desired changes, make sure you save them.

Make the file executable:
<pre>sudo chmod +x odoo_install_centos.sh</pre>

Execute the script to install Odoo:
<pre>./odoo_install_centos</pre>

<b>Please note:</b> The script is only tested on a clean server and is still in a development mode. 
