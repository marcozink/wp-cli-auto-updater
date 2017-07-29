#!/usr/bin/env bash
# Author: Marco Zink
# https://github.com/marcozink/wp-cli-auto-updater/
# Licence GNU GPLv3

BLUE='\033[0;34m'
LIGHTGRAY='\033[0;37m'
LIGHTPURPLE='\033[1;35m'
NC='\033[0m'

while getopts ":q" opt
do
	case $opt in
		q)
			echo "Executing in quiet mode"
			ALERT=OFF
		;;
    h)
     echo "WordPress Auto-Updater:
     This script will find all the WordPress installations under a path, and update, languages, plugins, themes and core instalations.
     It will also send pushover notifications, make sure you have it in your PATH with.
     -q option will not send PushOver notifications." 1>&2
     echo "Usage:\n    As root: ./wp-updater.sh {-q}" 1>&2
     exit 1
		\?)
			echo "Invalid Option"
			exit 1
		;;
	esac
done
		
cd /tmp/
echo -e "${BLUE}Actualizando WP-CLI${NC}"
wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
for i in $(find /var/www -name "wp-config.php"|cut -d"/" -f4)
do
	SITE=$i
	echo -e "${LIGHTPURPLE}Working with $SITE${NC}"
	echo "Updating plugins"
	if [ "$ALERT" != "OFF" ];then /sbin/push "Updating plugins for $SITE" "$SITE" "1" &
	fi
	/usr/bin/sudo -u asterisk -i -- wp --path="/var/www/$SITE" plugin update --all
	echo "Updating themes"
	if [ "$ALERT" != "OFF" ];then /sbin/push "Updating themes for $SITE" "$SITE" "1" &
	fi
	/usr/bin/sudo -u asterisk -i -- wp --path="/var/www/$SITE" theme update --all
	echo "Updating WordPress"
	if [ "$ALERT" != "OFF" ];then /sbin/push "Updating WordPress from $SITE" "$SITE" "1" &
	fi
	/usr/bin/sudo -u asterisk -i -- wp --path="/var/www/$SITE" core update
	echo "Updating DB"
	if [ "$ALERT" != "OFF" ];then /sbin/push "Updating DB from $SITE" "$SITE" "1" &
	fi
	if [ "$(/bin/egrep "'MULTISITE', true" /var/www/$i/wp-config.php)" ]
	then
		/usr/bin/sudo -u asterisk -i -- wp --path="/var/www/$SITE" core update-db --network
	else
		/usr/bin/sudo -u asterisk -i -- wp --path="/var/www/$SITE" core update-db
	fi
done
