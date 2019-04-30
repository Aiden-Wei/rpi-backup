# rpi-backup
在linux虚拟机上备份树莓派镜像

1 在官网https://www.raspberrypi.org/downloads/raspbian/下载Raspbian Stretch Lite
2 安装vm虚拟机
3 安装Raspbian系统，系统内存应大于需要备份镜像的3倍，建议30G以上
4 将需要备份的镜像sd卡插到电脑上（用读卡器）
5 将rpi-backup克隆到虚拟机里
6 df -h查看sd卡是否挂载为sdb，如果不是要修改代码里sdb相应的地方
7 sudo chmod +x rpi-backup
8 sudo ./rpi-backup
