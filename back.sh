#!/bin/bash
start_tm=`date +%s%N`
if [ -d backupimg ]; then
  sudo rm -rf backupimg
  mkdir backupimg
  cd backupimg
else
  mkdir backupimg
  echo "create backupimg"
  cd backupimg
fi

if [ ! -d src_boot ]; then
  mkdir src_boot
  echo "create src_boot"
fi

if [ ! -d src_Root ]; then
  mkdir src_Root
  echo "create src_Root"
fi

bootsz=`df -P | grep /dev/sdb1 | awk '{print $2}'`
rootsz=`df -P | grep /dev/sdb2 | awk '{print $3}'`
totalsz=`echo $bootsz $rootsz | awk '{print int(($1+$2)*1.2/4)}'`
if [ ! -f raspberrypi.img ]; then
  sudo dd if=/dev/zero of=raspberrypi.img bs=4K count=$totalsz
  echo "create raspberrypi.img"
fi

sudo parted raspberrypi.img --script -- mklabel msdos
sudo parted raspberrypi.img --script -- mkpart primary fat32 8192s 122479s
sudo parted raspberrypi.img --script -- mkpart primary ext4 122880s -1

sudo mount -t vfat -o uid=pi,gid=pi,umask=0000 /dev/sdb1 ./src_boot/
sudo mount -t ext4 /dev/sdb2 ./src_Root/

loopdevice=`sudo losetup -f --show raspberrypi.img`
device=`sudo kpartx -va $loopdevice | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
device="/dev/mapper/${device}"
partBoot="${device}p1"
partRoot="${device}p2"
sudo mkfs.vfat -n boot $partBoot
sudo mkfs.ext4 $partRoot

if [ ! -d tgt_boot ]; then
  mkdir tgt_boot
  echo "create tgt_boot"
fi

if [ ! -d tgt_Root ]; then
  mkdir tgt_Root
  echo "create tgt_Root"
fi

sudo mount -t vfat -o uid=pi,gid=pi,umask=0000 $partBoot ./tgt_boot/
sudo mount -t ext4 $partRoot ./tgt_Root/
sudo cp -rfp ./src_boot/* ./tgt_boot/
sudo chmod 777 tgt_Root
sudo chown pi.pi tgt_Root
sudo rm -rf ./tgt_Root/*
cd src_Root/
sudo tar pcf ../backup.tar .
cd ../tgt_Root/
sudo tar pxf ../backup.tar
cd ..
sudo rm backup.tar 

opartuuidb=`sudo blkid -o export /dev/sdb1 | grep PARTUUID`
opartuuidr=`sudo blkid -o export /dev/sdb2 | grep PARTUUID`
npartuuidb=`sudo blkid -o export $partBoot | grep PARTUUID`
npartuuidr=`sudo blkid -o export $partRoot | grep PARTUUID`
sudo sed -i "s/$opartuuidr/$npartuuidr/g" /tgt_boot/cmdline.txt 
sudo sed -i "s/$opartuuidb/$npartuuidb/g" /tgt_Root/etc/fstab
sudo sed -i "s/$opartuuidr/$npartuuidr/g" /tgt_Root/etc/fstab

if [ ! -f /tgt_boot/temporaryfiles.txt ]; then
  sudo touch /tgt_boot/temporaryfiles.txt
  echo "create temporaryfiles.txt"
fi

sudo umount src_boot src_Root tgt_boot tgt_Root
sudo kpartx -d $loopdevice
sudo losetup -d $loopdevice
rmdir src_boot src_Root tgt_boot tgt_Root

end_tm=`date +%s%N`
use_tm=`echo $end_tm $start_tm | awk '{ print ($1 - $2) / 1000000000}'`
echo $use_tm
