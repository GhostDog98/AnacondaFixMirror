#!/bin/bash

# This script patches both pip and anaconda to not give self-signed cert errors while maintaining an ssl connection.
# Made by Jake Aronleigh - contact me at: ghostoverflow256@gmail.com

echo "Patching pip first"
# This patch tells the pip program to always trust the needed sites through a global config file. 
# The loading order for config files is as follows:
# Path specified by the PIP_CONFIG_FILE enviroment variable (couldnt get that to work without root)
# Global - /Library/Application Support/pip/pip.conf
# User - $HOME/Library/Application Support/pip/pip.conf OR $HOME/.config/pip/pip.conf
# Site - $VIRTUAL_ENV/pip.conf

# Here I'm using the Global method. It would be better to use the PIP_CONFIG_FILE method,
# however to edit the enviroemtn variables I would need root access. 
# This creates an issue of authentication, meaning I would be unable to portably pack this 
# Application without giving EVERY user some sort of admin role, which is not wise. 
mkdir -p /Library/Application\ Support/pip &&  printf "%s\n" "[global]" "trusted-host = pypi.python.org" "               pypi.org" "               files.pythonhosted.org" > /Library/Application\ Support/pip/pip.conf || echo "Failed to create conf file, please run with root permissions and try again"
echo "Patched pip, attempting anaconda"

# The way this patch works is it gets the file for ssl certificates, then patches in the
# woodleigh ssl certs to make sure anaconda doesn't think it's being attacked by a Man-in-the-middle attack. 
b=.conda.ssl.pem
c="ssl_verify: $HOME/$b"
a=.continuum/anaconda-client/config.yaml
mv "$PWD/$b" "$PWD/old_certs/$b" || echo "Couldn't move old file, assuming this is the first time running this patch"
curl https://curl.se/ca/cacert.pem -o $PWD/$b || echo "Curl failed, couldn't get default certificate!" # This sometimes doesnt work - Why?
echo quit | openssl s_client -showcerts -servername "curl.haxx.se" -connect curl.haxx.se:443 | pcregrep -M -e "----.*(\n.*){19}" | pcregrep -M -v -e "---\nServer certificate" >> $b || echo "Failed to append to new certificate"
cp $PWD/$b $HOME/$b || echo "Failed to move the new certificate, do I have root?"
sed -i '' "s~ssl_verify: true~$c~" $HOME/$a ||  sed -i '' "s~ssl_verify: True~$c~" $HOME/$a || echo "Failed to write to conda config! Do I have root?"
# Here, not only is sed different on macos than linux or other bash systems, 
# but it also needs the double quotes in order to expand the $b option.
# You will also notice that i have used '~' as the seporator, this is because my variables
# have slashes in them
echo "Patched Both successfully!"
