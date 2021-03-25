#!/bin/sh
#delete all userpartitions and create 3G partition if ram size is greater than 4G

ls /dev/nvme*n1 2> /dev/null
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
	e2label $last_part CLTM

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
	e2label $last_part CLTM

fi
sync

