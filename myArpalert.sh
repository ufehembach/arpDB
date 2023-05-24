#! /bin/bash

myMail=bla@blupp.blipp

#action on detect = ""
#    Script launched on each detection. Parameters are: mac adress of requestor, ip of requestor, supp. parm., type of alert .IP type of alert:
#    0: IP change
#    1: Mac address already detected but not in white list
#    2: Mac address in black list
#    3: New mac address
#    4: Unauthorized arp request
#    5: Abusive number of arp request detected
#    6: Ethernet mac address different from arp mac address
#    7: Flood detected
#    8: New mac address whithout ip address 

Message=( "IP change" "Mac address already detected but not in white list" "Mac address in black list" "New mac address" "Unauthorized arp request" "Abusive number of arp request detected" "Ethernet mac address different from arp mac address" "Flood detected" "New mac address whithout ip address" "Mac address changed" "10" ) 

VARLIBARPALERT=/var/lib/arpalert
DB=$VARLIBARPALERT/arpalert.sqlite

#echo ${Message[0]}
#echo ${Message[1]}
#echo ${Message[2]}
#echo ${Message[3]}
#echo ${Message[4]}
#echo ${Message[5]}
#echo ${Message[6]}
#echo ${Message[7]}
#echo ${Message[8]}
#echo ${Message[9]}

find /tmp  -name 'myArpalert*.tmp' -mmin +9 -delete > /dev/null

MailBody="/tmp/$(basename $0).$$.tmp"
function finish {
  echo rm -rf "$MailBody" >> "/tmp/$(basename $0).log"
  rm -rf "$MailBody"  >> "/tmp/$(basename $0).log" 2&>1
  find /tmp/ -type f -mtime +1 -delete
  }
trap finish EXIT


function writeHTMLTable(){
	writeStyleStart
	writeData
	writeStyleEnd
}

function writeStyleStart(){
#myDate=date -u +"%a %b %d %T %Z %Y"`
myDate=`date --iso-8601=minutes`
cat << EOF2 
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
   <head>
   	<title>ARPdb</title>
        <meta http-equiv="content-type" content="text/html; charset=iso-8859-15" >
        <META HTTP-EQUIV="Refresh" CONTENT="300" >
        <META HTTP-EQUIV="Cache-Control" content="no-cache" >
        <META HTTP-EQUIV="Pragma" CONTENT="no-cache" >
        <META HTTP-EQUIV="Expires" CONTENT="$myDate" >
        <LINK HREF="favicon.ico" rel="shortcut icon" >
  	<style>
		table.darkTable {
		font-family: Verdana, Geneva, "sans-serif";
		border: 2px solid #000000;
		background-color: #4A4A4A;
		width: 100%;
		height: 200px;
		text-align: center;
		border-collapse: collapse;
		}
		table.darkTable td, table.darkTable th {
		border: 1px solid #4A4A4A;
		padding: 3px 2px;
		}
		table.darkTable tbody td {
		font-size: 13px;
		color: #E6E6E6;
		}
		table.darkTable tr:nth-child(even) {
		background: #888888;
		}
		table.darkTable thead {
		background: #000000;
		border-bottom: 3px solid #000000;
		}
		table.darkTable thead th {
		font-size: 15px;
		font-weight: bold;
		color: #E6E6E6;
		text-align: center;
		border-left: 2px solid #4A4A4A;
		}
		table.darkTable thead th:first-child {
		border-left: none;
		}

		table.darkTable tfoot {
		font-size: 12px;
		font-weight: bold;
		color: #E6E6E6;
		background: #000000;
		background: -moz-linear-gradient(top, #404040 0%, #191919 66%, #000000 100%);
		background: -webkit-linear-gradient(top, #404040 0%, #191919 66%, #000000 100%);
		background: linear-gradient(to bottom, #404040 0%, #191919 66%, #000000 100%);
		border-top: 1px solid #4A4A4A;
		}
		table.darkTable tfoot td {
		font-size: 12px;
		}
        </style>
    </head>
    <body>
	<p> </>
	`date --iso-8601=seconds`
	`hostname`
	<p> </>
	<p> </>
EOF2
}

function writeData(){
	echo \<table class="darkTable"\> 

cat << EOF | sqlite3 $DB 
.header on
.mode html
.width auto

select   
	lastupdate, Mac, IP, Hostname, Device, Vendor, ToAMessage, SuppParm  
from arp 
group by device, mac
order by lastupdate desc;
EOF
}
function writeStyleEnd(){

echo "</table> </body> </html>" 

}


if [ ! -f $DB ]
then
#	sqlite3 test.db  "create table n (id INTEGER PRIMARY KEY,f TEXT,l TEXT);"
	sqlite3 $DB "create table arp (id INTEGER PRIMARY KEY,lastupdate datetime,Mac TEXT,IP TEXT,Hostname TEXT,Device TEXT,Vendor TEXT, ToA TEXT,ToAMessage TEXT,SuppParm TEXT);"
fi

if [ $# -eq 1 ] && [ $1 == dump ]
then
#	sqlite3 -column -header $DB "select  lastupdate, Mac, IP, Hostname,Device, ToAMessage, SuppParm  from arp order by mac, lastupdate asc";
	echo  "select  lastupdate, Mac, IP, Hostname,Device, Vendor, ToAMessage, SuppParm  from arp order by mac, lastupdate asc;" \
	| sqlite3 $DB
	exit
fi

if [ $# -eq 1 ] && [ $1 == dummy ]
then
 echo "Dummy RUN"
 AdressOfRequestor=01:23:45:67:89:ab
 IpOfRequestor=1.2.3.4
 SuppParm=dummyHost
 Device=alert
 ToA=6
 Vendor=Fritz
fi
if  [ $# -eq 0 ]
then
#	sqlite3 -column -header $DB "select   lastupdate, Mac, IP, Hostname,Device, ToAMessage, SuppParm  from arp group by mac order by lastupdate desc";
cat << EOF | sqlite3 $DB 
.header on
.mode column
.width 16 17 18 30 7 14 30

select   
	lastupdate, Mac, IP, Hostname,Device, Vendor, ToAMessage, SuppParm  
from arp 
	group by device, mac
	order by ip;
EOF
	writeHTMLTable  > /var/www/html/arpDb.html
	
	rm $MailBody
	exit
else
 if [  $1 != dummy ]
 then
 echo "Normal RUN"
  AdressOfRequestor=01:23:45:67:89:ab
  AdressOfRequestor=$1
  IpOfRequestor=$2
  SuppParm=$3
  Device=$4
  ToA=$5
  Vendor=$6
 fi
fi

if [ $# -eq 1 ] 
then
	echo missing parameters
	exit
fi


if [ $ToA -eq 8 ] 
then 
	exit
	echo bla
fi
RequestorHostname=`host $IpOfRequestor | awk  '{ print $5 }'`
myHostname=`hostname`
if [ 1 -eq  `echo  $RequestorHostname | grep -i $myHostname | wc -l `  ] 
then 
	exit
	echo bla
fi
if [ 1  -eq  `echo  $IpOfRequestor | grep -i 192.168.0.3 | wc -l `  ] 
then 
	exit
	echo bla
fi

#		values('`date +"%Y-%m-%d %H:%M:%S.%s"`',\
#sqlite3 test.db  "insert into n (f,l) values ('john','smith');"
sqlite3 $DB "insert into arp (lastupdate,Mac,IP,Hostname,Device,Vendor,ToA,ToAMessage,SuppParm) \
		values('`date +"%Y-%m-%d %H:%M:%S"`',\
			'$AdressOfRequestor',\
			'$IpOfRequestor',\
			'$RequestorHostname',\
			'$Device',\
			'$Vendor',\
			'$ToA',\
			'${Message[$ToA]}',\
			'$SuppParm');"

writeStyleStart > $MailBody

echo -e "<p>Mac:\t\t" $AdressOfRequestor"</>" >> $MailBody
echo -e "<p>IP:\t\t" $IpOfRequestor"</>"  >> $MailBody
echo -e "<p>Hostname:\t" $RequestorHostname"</>"  >> $MailBody
echo -e "<p>SuppParm:\t" $SuppParm"</>"  >> $MailBody
echo -e "<p>Device:\t" $Device"</>" >> $MailBody
echo -e "<p>Vendor:\t" $Vendor"</>" >> $MailBody
echo -e "<p>ToA:\t" $ToA  ${Message[$ToA]}"</>" >> $MailBody
echo -e "<p>\n ip neigh</>"  >> $MailBody

ip neigh | grep "$AdressOfRequestor" | while read i 
do
	echo "<p>"$i >> $MailBody
thisIP=`echo  $i | awk '{ print $1 }'` 
	host $thisIP | awk  '{ print $5 }' >> $MailBody
done
echo -e "\\ ip neigh<p>"  >> $MailBody

echo "<p> </>" >> $MailBody
echo "<p> </>" >> $MailBody
echo "<p> </>" >> $MailBody

echo \<table class="darkTable"\>  >> $MailBody

#sqlite3 -html -header $DB "select lastupdate, IP, Hostname, ToAMessage from arp where mac = \"$AdressOfRequestor\" order by lastupdate desc;" >> $MailBody

writeStyleEnd >> $MailBody

writeHTMLTable  > /var/www/html/arpDb.html


if [ $ToA -eq 7 ]
then
	rm $MailBody
	exit
fi

cat $MailBody | mail pi@h1netpi  -s \""${AdressOfRequestor} - ${Message[$ToA]} - $RequestorHostname $IpOfRequestor"\" \
	-a "MIME-Version: 1.0" \
        -a "Content-Type: text/html" 
echo mail $myMail  -s \""${AdressOfRequestor} - ${Message[$ToA]} :: $RequestorHostname $IpOfRequestor"\" \
	-a "MIME-Version: 1.0" \
        -a "Content-Type: text/html" >> "/tmp/$(basename $0).log"
rm $MailBody
if  grep "$RequestorHostname" $VARLIBARPALERT/smokeping.list &>   /dev/null
then 
	echo `date` OK $AdressOfRequestor $IpOfRequestor $RequestorHostname $SuppParm $Device >> $VARLIBARPALERT/`basename $0`.log
else 
	echo `date` KO $AdressOfRequestor $IpOfRequestor $RequestorHostname $SuppParm $Device >> $VARLIBARPALERT/`basename $0`.log
{
echo " " 
echo "# created by $0 on `date --iso-8601`" 
echo "++ " $RequestorHostname | sed -e 's/\./ /g' | awk '{ print $1,$2 }'
echo "menu = " $RequestorHostname
echo "title = " $RequestorHostname $AdressOfRequestor 
echo "host = " $IpOfRequestor 
echo "alerts = someloss" 
echo " " 
} > $MailBody 
cat $MailBody >> $VARLIBARPALERT/smokeping.list
rm $MailBody
fi


if  grep "$RequestorHostname" $VARLIBARPALERT/hosts &>   /dev/null
then 
	echo `date` OK $AdressOfRequestor $IpOfRequestor $RequestorHostname $SuppParm $Device >> $VARLIBARPALERT/`basename $0o `hosts.log
else 
	echo `date` KO $AdressOfRequestor $IpOfRequestor $RequestorHostname $SuppParm $Device >> $VARLIBARPALERT/`basename $0`hosts.log
{
echo "# added by $0 on `date`" 
HOSTName=`echo  $RequestorHostname | sed -e 's/\./ /g' | awk '{ print $1,$2 }'` 
echo  $IpOfRequestor " " $HOSTName
echo " " 
} > $MailBody 
cat $MailBody >> $VARLIBARPALERT/hosts
fi
rm $MailBody

