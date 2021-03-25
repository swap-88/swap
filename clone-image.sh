#!/bin/bash

CLTM=`findfs LABEL=CLTM`

if [[ ! -z "$CLTM" ]]; then

        mkdir -p /mnt
        mount $CLTM /mnt
        umount /mnt
        sync
fi

cd /
rm /tmp/777
touch /tmp/777

IPADDRESS=`cat fudmconfig.txt | grep IPADDRESS | grep  -vi network | cut -d'=' -f2 | cut -d '"' -f2`

PROTOCOL=`cat fudmconfig.txt | grep PROTOCOL | cut -d'=' -f2 | cut -d '"' -f2 | tr '[:upper:]' '[:lower:]'`

ALTPORTchk=`cat fudmconfig.txt | grep ALTPORT | cut -d'=' -f2 | cut -d '"' -f2`

ALTPORT=`cat fudmconfig.txt | grep ALTPORT | cut -d'=' -f2 | cut -d '"' -f2`

ftpassword=`cat fudmconfig.txt | grep FTPASSWORD | cut -d'=' -f2 | cut -d '"' -f2`

ftusername=`cat fudmconfig.txt | grep FTUSERNAME | cut -d'=' -f2 | cut -d '"' -f2`

FOLDER=`cat fudmconfig.txt | grep FOLDER | cut -d'=' -f2 | cut -d '"' -f2 | cut -d '/' -f2` 

IMAGEFILENAME=`cat fudmconfig.txt | grep IMAGEFILENAME | cut -d'=' -f2 | cut -d '"' -f2`

TIMEOUT=`cat fudmconfig.txt | grep TIMEOUT | cut -d'=' -f2 | cut -d '"' -f2`

if [ $ALTPORT ]; then

        if [ ${ALTPORTchk} -ge "0" ]; then
		url="$PROTOCOL://${IPADDRESS}:${ALTPORTchk}/${FOLDER}/$IMAGEFILENAME"
		echo $url
	else
		url="$PROTOCOL://${IPADDRESS}/${FOLDER}/$IMAGEFILENAME"
		echo $url
        fi
fi



validate_url()
{
    wget --spider -q $1 --no-proxy
    echo "$url..."
    return $?
}


   if [ "${PROTOCOL}" = "http" ]; then
        {
			if [ -z ${ftusername} ]; then
				
				echo "[remote]" > /root/.config/rclone/rclone.conf
                		echo "$PROTOCOL"
                		echo "type = http" >> /root/.config/rclone/rclone.conf
                		echo "$IPADDRESS"
                		echo "[$IPADDRESS]"
                		echo "$ALTPORT"
                		echo "url = $PROTOCOL://$IPADDRESS:$ALTPORT" >> /root/.config/rclone/rclone.conf
				
				if validate_url "${url}  --no-check-certificate"; then
        				if [ $? -eq 0 ]; then
                				echo "URL exists: $url"
        				else
                				echo "URL does not exist: $url"
                			exit 1
        				fi
   				fi
		else
				echo "[remote]" > /root/.config/rclone/rclone.conf
                		echo "$PROTOCOL"
                		echo "type = http" >> /root/.config/rclone/rclone.conf
                		echo "$IPADDRESS"
                		echo "[$IPADDRESS]"
                		echo "$ALTPORT"
                		echo "url = $PROTOCOL://$ftusername:`urlencode $ftpassword`@$IPADDRESS:$ALTPORT" >> /root/.config/rclone/rclone.conf	

				if validate_url "${url} --user=${ftusername} --password=${ftpassword}  --no-check-certificate"; then
                        		if [ $? -eq 0 ]; then
                                		echo "URL exists: $url"
                        		else
                                		echo "URL does not exist: $url"
                        		exit 1
                			fi
				fi
			fi
       }
   fi

   #exit

   if [ "${PROTOCOL}" = "ftp" ]; then
        {

		echo "[remote]" > /root/.config/rclone/rclone.conf
		echo "$PROTOCOL"
		echo "type = $PROTOCOL" >> /root/.config/rclone/rclone.conf
		echo "host = $IPADDRESS" >> /root/.config/rclone/rclone.conf
		echo "user = $ftusername" >> /root/.config/rclone/rclone.conf
		echo "port = $ALTPORT" >> /root/.config/rclone/rclone.conf
		echo "pass = `rclone obscure $ftpassword`" >> /root/.config/rclone/rclone.conf

		if validate_url "${url} --user=${ftusername} --password=${ftpassword}  --no-check-certificate"; then
	        	if [ $? -eq 0 ]; then
        	        	echo "URL exists: $url"
        		else
                		echo "URL does not exist: $url"
        	fi
		fi

        }
   fi


################################################################
CLTM=`findfs LABEL=CLTM`

if [[ ! -z "$CLTM" ]]; then

        mkdir -p /mnt
        mount $CLTM /mnt
        ls /mnt > /tmp/deploy_files
        sleep 2
        sync
fi

cd /mnt

####################################################33

while read -r line; do

IMAGEFILENAME=${line}
sleep 1
count=0
while [ $count -le 2 ]
do
#if [ "${PROTOCOL}" = "https" ]; then
	echo ${0}: uploading ${IMAGEFILENAME} from server ${IPADDRESS}
	#curl -u ${ftusername}:${ftpassword} -C - ${url}  --connect-timeout ${TIMEOUT} -o ${IMAGEFILENAME} --stderr /tmp/out &
	echo $IMAGEFILENAME
	echo $url
	local_MD5sum=`md5sum "/mnt/$IMAGEFILENAME" | cut -d ' ' -f 1`	
	echo "$local_MD5sum...."
	rclone --stats-one-line -P --stats 1s copy $IMAGEFILENAME remote:$FOLDER/ --no-check-certificate=true > /tmp/777 &
#	exit 
	pid="$!"

			while true; do
                	sleep 0.5
			awk '{ for (i=0;i<=NF;i+=1) print $i }' /tmp/777 | grep -i % | grep -v ETA | cut -d, -f1 | tail -1 > /tmp/percent
			awk '{ for (i=0;i<=NF;i+=1) print "\n"$i"\n" }' /tmp/777 | grep -v MB | grep s | cut -d's' -f1 | tail -1 > /tmp/estimate
                	done &
			pid2="$!"

	while kill -0 "$pid" 2> /dev/null
	do
		sleep 1

		{
			for i in `cat /tmp/percent | cut -d'%' -f1` ; do 		
                        sleep 0.1
			percent=`cat /tmp/percent | cut -d'%' -f1`
			estimatedtime=`cat /tmp/estimate`
			ARR_NODE=$(echo $estimatedtime | tr "," "\n")
		echo -e "XXX\n$i The NEW MEssage \nETA : ${ARR_NODE}"
  			echo "# uploading $IMAGEFILENAME      Completed: $percent %"
			if [ ${percent} -eq 100 ]; then
				echo "# uploading $IMAGEFILENAME      Completed: 100 %"
			fi
                	done
		} 
	done | zenity --progress --percentage=0 --auto-close --title "VXL Main Program" --text "uploading ${IMAGEFILENAME} $percent" --width 400 --height 100 --no-cancel --time-remaining


	installStatus="Success"
        printf " [%s]\n" "${installStatus}"
	online_MD5sum=`curl  -sL  -u ${ftusername}:${ftpassword} -k $PROTOCOL://${IPADDRESS}/$FOLDER/$IMAGEFILENAME | md5sum | cut -d ' ' -f 1
`
	echo "$online_MD5sum....online"
	percent=`cat /tmp/percent | cut -d'%' -f1`

#kill -9 $pid2
#echo $pid2
#exit

        if [ ${online_MD5sum} == ${local_MD5sum} ]; then

		if [ ! -z ${online_MD5sum} ]; then
                	echo "hurray, they are equal!"
                	echo "remote size is $remotesize uploaded file size is $received"
                	echo "File ${IMAGEFILENAME} uploaded Successfully"
                	kill -9 $pid2
			echo $pid2
                	count=3
			sed -i /${IMAGEFILENAME}/d /tmp/deploy_files
                     
		else
		#if [ ${remotesize} = 0 ]; then

			zenity --error --text "Unautherized Access2" --timeout 7 --width 400 --height 100 &
                	sleep 7
                	count=$(( $count+1 ))
                	echo "Try attempt $count"
                	echo "remote size is $remotesize uploaded file size is $received"
                	kill -9 $pid2
			echo $pid2
			rm /tmp/777
			touch /tmp/777
		fi

        else
                count=$(( $count+1 ))
                echo "Try attempt $count"
                echo "remote size is $remotesize uploaded file size is $received"
                kill -9 $pid2
		echo $pid2
		rm /tmp/777
		touch /tmp/777
                sleep 10
                #exit 1
        fi
#fi
done
done < /tmp/deploy_files



if [ -s /tmp/deploy_files ]
then
	echo "file has somthing.."

else
        echo "file is empty... "
	echo "100" > /tmp/percent

fi

