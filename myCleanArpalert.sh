#! /bin/bash
/etc/init.d/arpalert stop
cp /etc/arpalert/* /home/pi/arpalert
chown pi -R /home/pi/arpalert
#rm /var/lib/arpalert/*
rm /var/lib/arpalert/arpalert.leases
if [ $# -eq 1 ] && [ $1 == AlL ]
then
   rm /var/lib/arpalert/arpalert.sqlite
else
   echo keep arpalert.sqlite
fi
rm /var/lib/arpalert/hosts
rm /var/lib/arpalert/Mail.html
rm /var/lib/arpalert/myArpalert.shhosts.log
rm /var/lib/arpalert/myArpalert.sh.log
rm /var/lib/arpalert/smokeping.list
chown arpalert /var/lib/arpalert

echo ArpAlert restarted and cleaned | sudo -u arpalert mail blörk@blurk.blerk -s "ArpAlert Cleaned"
/etc/init.d/arpalert start
sleep 10
/etc/arpalert/myArpalert.sh list
touch /var/www/html/arpDb.html
chown arpalert /var/www/html/arpDb.html
chmod 755 /var/www/html/arpDb.html
