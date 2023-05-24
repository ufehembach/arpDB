# arpDB
take output from famous arpalert and put it into a sqliteDB as well as create a dumb html table

needs to have sqlite(3?) installed
assumes website is in /var/www/html and creates there a arpDB.html page

in arpalert.conf find "action on detect"
and change to "action on detect  = <path to my folder with>/myArpalert.sh

myCleanArpaler
