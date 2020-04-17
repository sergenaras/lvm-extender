#!/bin/bash

#
#Karşılama
#

scsi_discovery() {
	fdisk -l | grep "Disk /dev/sd" | awk -F" " '{ print$2 }' | sed 's/.$//' | while read file; do echo $file;done > /tmp/scsi_first
	scsi_first=$(cat /tmp/scsi_first | wc -l)
	ls /sys/class/scsi_host/ | awk -F" " '{ print$1 }' | while read hosts; do echo "- - -" > /sys/class/scsi_host/$hosts/scan ;done
	ls /sys/class/scsi_device/ | awk -F" " '{ print$1 }' | while read devices; do echo 1 > /sys/class/scsi_device/$devices/device/rescan; done
	fdisk -l | grep "Disk /dev/sd" | awk -F" " '{ print$2 }' | sed 's/.$//' | while read file; do echo $file;done > /tmp/scsi_second
	scsi_second=$(cat /tmp/scsi_second| wc -l)
	
	if [ $scsi_second -gt $scsi_first ]
	then
		eklenen_disk=$(diff /tmp/scsi_second /tmp/scsi_first | tail -n +2 | cut -c 3-)
		#echo $eklenen_disk #eklenen disk denemesi
		kacsd=$(fdisk -l | grep $eklenen_disk | wc -l)
		if [ $kacsd -gt 2 ]
		then
			echo "There i no disk for upgrade"
		else
			echo $eklenen_disk
		fi
	fi
}

fdisk_create(){
(
	echo n
	echo p
	echo 1
	echo 
	echo 
	echo t
	echo 8e
	echo w
 ) | fdisk $eklenen_disk
}

pv_section(){
	pvs
	echo "-----------------------"
	pvcreate $eklenen_disk 1
	echo "-----------------------"
	pvs
	
	echo "------------------------------------------"
}


vg_section(){
	vgs
	vgextend $(vgs | tail -n +2| awk -F" " '{ print$1 }') $eklenen_disk 1
	vgs

	echo "Genişletilebilir kısım: " $(vgs | tail -n +2| awk -F" " '{ print$7 }' | cut -c 2-)
	echo "------------------------------------------"
}

lv_section(){
	df -h
	echo "------------------------------------------"
	dosya_sistemi=$(df -h | grep "/$" | awk -F" " '{ print$1 }')
	#lvextend -l %100FREE $dosya_sistemi
	lvextend $dosya_sistemi $eklenen_disk 1
	vgs
	echo "------------------------------------------"
}

filesystem_section(){
	system_type=$(df -Th | grep "/$" | awk -F" " '{ print$2 }')

	if [ system_type == "xfs" ]
	then
		xfs_growfs /
	elif [ system_type == "ext4" ]
	then
		resize2fs /
	fi
}

scsi_discovery
fdisk_create
pv_section
vg_section
lv_section
filesystem_section





















