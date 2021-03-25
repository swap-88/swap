#!/bin/bash
###########################parttion.sh##########################
#!/bin/sh
#delete all userpartitions and create 3G partition if ram size is greater than 4G

s /dev/nvme*n1 2> /dev/null
is_nvme=$?
ls /dev/mmcblk*  2> /dev/null
is_mmcblk=$?

if [ $is_nvme -eq 0 ]; then
        DISK=/dev/nvme0n1
        count=`ls $DISK* | wc | awk '{print $1}'`
        count=`expr $count - 1`
        var=`ls $DISK*`
        last_part=`echo $var | awk '{print $NF}'`
elif [ $is_mmcblk -eq 0 ]; then
        DISK=/dev/mmcblk0
        count=`ls $DISK* | wc | awk '{print $1}'`
        count=`expr $count - 1`
        var=`ls $DISK*`
        last_part=`echo $var | awk '{print $NF}'`
else
        DISK=/dev/sda
        count=`ls $DISK* | wc | awk '{print $1}'`
        count=`expr $count - 1`
        var=`ls $DISK*`
        last_part=`echo $var | awk '{print $NF}'`
fi
echo $count
echo $last_part
#exit

ram=`free -g | head -n 2 | tail -n 1  | awk '{print $2}'`
if [ $ram -lt 3 ]
then
        echo "ERROR: Ram size is less than 4g"
        exit
fi

if [ -f /tmp/dom_size_error ]; then
  rm /tmp/dom_size_error
fi

disk=`parted -s $DISK print | grep Disk | head -n 1 | awk '{print $3}'` ## check dom size

echo $disk | grep GB > /dev/null
if [ $? -eq 0 ]
then
  Disk=`echo $disk | sed 's/..$//'`
  if [ ! $Disk -gt 7 ]; then
    echo "ERROR: Disk size is less than 8GB. Exiting.."
    echo "ERROR: Disk size is less than 8GB. Exiting.." >  /tmp/dom_size_error
    exit
  fi
fi
echo $disk | grep MB > /dev/null
if [ $? -eq 0 ]
then
  Disk=`echo $disk | sed 's/..$//'`
 if [ ! $Disk -gt 7000 ]; then
    echo "ERROR: Disk size is less than 8GB. Exiting.."
    echo "ERROR: Disk size is less than 8GB. Exiting.." >  /tmp/dom_size_error
    exit
  fi
fi

mountpoint -q /mnt/
if [ $? = 0 ]
then
        umount /mnt/
fi
partprobe
#find underlying image is lvm or not
parted -s $DISK  print | grep -i lvm > /dev/null

if [ $? = 0 ]
then
  #count=`grep -E d[a-g] /proc/partitions | sed '1,1d' | awk '{print $4}' | wc -w`

  if [ $count -gt 3 ]
  then
    mkdir -p /mnt/
    count1=`expr $count - 5`
    #echo c=$count c1=$count1
ext=`fdisk -l $DISK | grep Extended | awk '{print $5}' | sed 's/.$//'`
    fdisk -l | grep $DISK | sed '1,/494/d' | awk '{print $5}' > /tmp/disk
    disk1=0
    disk2=0
    while read -r line; do
        echo $line | grep M > /dev/null
        if [ $? -eq 0 ]; then
           line=`echo $line | sed 's/.$//'`
           line=$(echo $line*0.001 | bc )
           disk1=$(echo $disk1+$line | bc)
        fi
        echo $line | grep G > /dev/null
        if [ $? -eq 0 ]; then
           line=`echo $line | sed 's/.$//'`
           disk2=$(echo $disk2+$line | bc)
        fi
    done < /tmp/disk
    disk_used=$(echo $disk1+$disk2 | bc)
    disk_avai=$(echo $ext-$disk_used | bc)

    if (( $(echo "$disk_avai > 3.492" |bc -l) ));
    then
        echo "Free space available" > /tmp/disk_status
        echo "Free space available" 
fdisk $DISK << EOF
n

+3G
w
EOF

    else
      echo "Free space is not available, Deleting User partition" > /tmp/disk_status
      echo "Free space is not available, Deleting User partition"

for (( i=1; i<=$count1; i++,--count )); do
partprobe
fdisk $DISK << EOF
d
6
w
EOF
done
partprobe
sync
fdisk $DISK << EOF
n

+3G
w
EOF
    fi
 if [ $? = 0 ]
        then
           echo "partition Created succesfully!"
        else
           echo "Failed to create partition"
           exit
        fi
        partprobe
        #################################
        if [ $is_nvme -eq 0 ]; then
                var=`ls $DISK*`
                last_part=`echo $var | awk '{print $NF}'`
        elif [ $is_mmcblk -eq 0 ]; then
                var=`ls $DISK*`
                last_part=`echo $var | awk '{print $NF}'`
        else
                var=`ls $DISK*`
                last_part=`echo $var | awk '{print $NF}'`
        fi
        #####################################
        umount /mnt/ 2> /dev/null
        mkfs.ext4 $last_part > /dev/null
        fi
        mountpoint -q /mnt/
        if [ $? = 0 ]
        then
           umount /mnt/
        fi
        mount $last_part /mnt/
   rm -r /mnt/lost+found/
        umount /mnt/
        e2label $last_part DLTM

else
#45 image, 3 partition image
    if [ $count > 2 ]
      then

        mkdir -p /mnt/
        count1=`expr $count - 3`

        hdd=`fdisk -l | grep $DISK | grep Disk | awk '{print $3}'`
        fdisk -l | grep /dev/sda | grep -v Disk | awk '{print $5}' > /tmp/disk
        disk1=0
        disk2=0
        while read -r line; do
          echo $line | grep M > /dev/null
          if [ $? -eq 0 ]; then
            line=`echo $line | sed 's/.$//'`
            line=$(echo $line*0.001 | bc )
            disk1=$(echo $disk1+$line | bc)
        fi
        echo $line | grep G > /dev/null
        if [ $? -eq 0 ]; then
          line=`echo $line | sed 's/.$//'`
	   disk2=$(echo $disk2+$line | bc)
        fi
        done < /tmp/disk
        disk_used=$(echo $disk1+$disk2 | bc)
        echo disk used= $disk_used
        disk_avai=$(echo $hdd-$disk_used | bc)
        echo disk avai=$disk_avai

        if (( $(echo "$disk_avai > 3.492" |bc -l) ));
        then
          echo "Free space available" > /tmp/disk_status
          echo "Free space available"
fdisk $DISK << EOF
n

+3G
w
EOF
else
        echo "Free space is not available, Deleting User partition" > /tmp/disk_status
        echo "Free space is not available, Deleting User partition"

for (( i=1; i<=$count1; i++ )); do
fdisk $DISK << EOF
d
4
w
EOF
done
partprobe
sync
fdisk $DISK << EOF
n

+3G
w
EOF
fi
        if [ $? = 0 ]
        then
                echo "partition Created succesfully!"
        else
                echo "Failed to create partition"
                exit
        fi
        partprobe

        if [ $is_nvme -eq 0 ]; then
                var=`ls $DISK*`                                                                                                            
	       	last_part=`echo $var | awk '{print $NF}'`
        elif [ $is_mmcblk -eq 0 ]; then
                var=`ls $DISK*`
                last_part=`echo $var | awk '{print $NF}'`
        else
                var=`ls $DISK*`
                last_part=`echo $var | awk '{print $NF}'`
        fi

        umount /mnt/ 2> /dev/null
        mkfs.ext4 $last_part > /dev/null
        fi
        mountpoint -q /mnt/
        if [ $? = 0 ]
        then
            umount /mnt/
        fi
        mount $part /mnt/
        rm -r /mnt/lost+found/
        umount /mnt
        e2label $last_part DLTM

fi
sync


#########################################33333333
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
               	 	exit 1
        	fi
   fi

        }
   fi
#exit 
################################################################


#!/bin/sh
#store deploy file names in /tmp/deploy_files file
. /fudmconfig.txt
PROTOCOL=`echo ${PROTOCOL} | tr [:lower:] [:upper:]`
echo $PROTOCOL
if [ ${PROTOCOL} = "HTTP" ]; then
	echo in http
  FOLDER=`echo $FOLDER | sed 's/\///g'`
  echo $FOLDER | grep html 2> /dev/null
  if [ $? -eq 0 ]; then
  curl -s http://${IPADDRESS}/${FOLDER}/ -u "${FTUSERNAME}":"${FTPASSWORD}" | grep -i ${IMAGEFILENAME} | awk '{print $6}' | sed 's/"/ /g' | awk '{print $2}' > /tmp/deploy_files
  else
curl -s http://${IPADDRESS}/${FOLDER}/ -u ${FTUSERNAME}:${FTPASSWORD} | sed 's/>/ /g' | sed 's/</ /g' | sed 's/ /\n/g'  | grep $IMAGEFILENAME | grep -v HREF > /tmp/deploy_files 
  fi

elif [ ${PROTOCOL} = "FTP" ]; then
	echo in ftp
  FOLDER=`echo $FOLDER | sed 's/\///g'`
  curl -s ftp://${IPADDRESS}/${FOLDER}/ -u "${FTUSERNAME}":"${FTPASSWORD}" | grep -i ${IMAGEFILENAME} | sed 's/ /\n/g' | grep $IMAGEFILENAME  > /tmp/deploy_files

elif [ $PROTOCOL = "HTTPS" ]; then
  if [ ! -z "$CERTNAME" ]; then
   curl -s -k https://${IPADDRESS}/${FOLDER}/ -u ${FTUSERNAME}:${FTPASSWORD} | sed 's/>/ /g' | sed 's/</ /g' | sed 's/ /\n/g'  | grep $IMAGEFILENAME | grep -v HREF > /tmp/deploy_files 
  else
   curl -s -k https://${IPADDRESS}/${FOLDER}/ -u ${FTUSERNAME}:${FTPASSWORD} | sed 's/>/ /g' | sed 's/</ /g' | sed 's/ /\n/g'  | grep $IMAGEFILENAME | grep -v HREF > /tmp/deploy_files 
  fi

elif [ $PROTOCOL = FTPS ]; then
	echo in ftps
  	FOLDER=`echo $FOLDER | sed 's/\///g'`
	if [ -z "$CERTNAME" ]; then
   	 echo "curl -s -u "${FTUSERNAME}":"${FTPASSWORD}" -k ftps://${IPADDRESS}/${FOLDER}/ --connect-timeout ${TIMEOUT} | sed "s/ /\n/g" | grep $IMAGEFILENAME > /tmp/deploy_files"
   	 curl -s -u "${FTUSERNAME}":"${FTPASSWORD}" -k ftps://${IPADDRESS}/${FOLDER}/ --connect-timeout ${TIMEOUT} | sed "s/ /\n/g" | grep $IMAGEFILENAME > /tmp/deploy_files
	else
   	 curl -s -u "${FTUSERNAME}":"${FTPASSWORD}" -k ftps://${IPADDRESS}/${FOLDER}/ --connect-timeout ${TIMEOUT} | sed "s/ /\n/g" | grep $IMAGEFILENAME > /tmp/deploy_files
	fi
fi

DLTM=`findfs LABEL=DLTM`

if [ -z "$DLTM" ]; then
	mount $DLTM /mnt
        MountPoint="/mnt"	
fi


cat /tmp/deploy_files | grep ${IMAGEFILENAME}  > /dev/null
status=$?
echo $status

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
	#remotesize=`rclone size remote:$FOLDER/$IMAGEFILENAME --no-check-certificate=true | tail -1 | awk '{print $3}'`
	#echo $remotesize
	#exit
	#received=`rclone size ${IMAGEFILENAME} 2>/dev/null | tail -1 | awk '{print $3}'`
	online_MD5sum=`$(curl  -sL  -u ${ftusername}:${ftpassword} -k $PROTOCOL://${IPADDRESS}/$FOLDER/$IMAGEFILENAME | md5sum | cut -d ' ' -f 1)`

	rclone --stats-one-line -P --stats 1s copy remote://$FOLDER/$IMAGEFILENAME --no-check-certificate=true $MountPoint > /tmp/777 &


#	exit 
	pid="$!"

	COUNTER=1

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
     
#	cat /tmp/777 | grep -i error
#	error=$?
#	if [ $? -ne 0 ]; then
 #       	zenity --error --text "Download Failed" --timeout 7 --width 400 --height 100 &
#		sleep 7
#	fi



	installStatus="Success"
        printf " [%s]\n" "${installStatus}"

	#remotesize=`rclone size remote:$FOLDER/$IMAGEFILENAME --no-check-certificate=true | tail -1 | awk '{print $3}'`
	local_MD5sum=`$(md5sum "$MountPoint/$IMAGEFILENAME" | cut -d ' ' -f 1)`	
	#received=`rclone size ${IMAGEFILENAME} 2>/dev/null | tail -1 | awk '{print $3}'`
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


