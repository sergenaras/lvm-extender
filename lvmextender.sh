#!/bin/bash

echo "-----------------------------------------------"
echo "-----------------------------------------------"

echo "Taktığınız disk SATA mı yoksa SCSI mi?"
read type_of_disk
if [ $type_of_disk == 'scsi' ]
        then

        fdisk -l | grep "Disk /dev/sd" | awk -F" " '{ print$2 }' | sed 's/.$//' | while read file; do echo $file;done > /tmp/scsi_first
        scsi_first=$(cat /tmp/scsi_first | wc -l)
        ls /sys/class/scsi_host/ | awk -F" " '{ print$1 }' | while read hosts; do echo "- - -" > /sys/class/scsi_host/$hosts/scan ;done
        ls /sys/class/scsi_device/ | awk -F" " '{ print$1 }' | while read devices; do echo 1 > /sys/class/scsi_device/$devices/device/rescan; done
        fdisk -l | grep "Disk /dev/sd" | awk -F" " '{ print$2 }' | sed 's/.$//' | while read file; do echo $file;done > /tmp/scsi_second
        scsi_second=$(cat /tmp/scsi_second| wc -l)

        if [ $scsi_second -gt $scsi_first ]
        then
                eklenen_disk=$(diff /tmp/scsi_second /tmp/scsi_first | tail -n +2 | cut -c 3-)
                #echo $eklenen_disk
				kacsd=$(fdisk -l | grep $eklenecek_disk | wc -l)
				if [ $kacsd -gt 2 ]
				then
					echo "There i no disk for upgrade"
				fi
        fi
fi

(
  n
  p
  1
  [Enter]
  [Enter]
  t
  8e
  w
 ) | fdisk $disk

pvs
pvcreate /dev/sde1
pvs

vgs
vgextend $(vgs | tail -n +2| awk -F" " '{ print$1 }') /dev/sdb1 
vgs

echo "Genişletilebilir kısım: " $(vgs | tail -n +2| awk -F" " '{ print$7 }' | cut -c 2-)

df -h
dosya_sistemi=$(df -h | grep "/$" | awk -F" " '{ print$1 }')
lvextend -l %100FREE $dosya_sistemi
vgs

system_type=$(df -Th | grep "/$" | awk -F" " '{ print$2 }')

if [ system_type == "xfs" ]
then
	xfs_growfs /
else if [ system_type == "ext4" ]
then
	resize2fs /
fi
