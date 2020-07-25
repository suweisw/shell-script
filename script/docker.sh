#!/bin/bash
sudo systemctl stop firewalld	#临时关闭防火墙
sudo systemctl disable firewalld	#永久关闭防火墙
sudo setenforce 0	#临时关闭SELinux
sudo swapoff -a		#关闭交换，注释交换分区
sudo sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config	#永久关闭SELinux
sudo curl https://download.docker.com/linux/centos/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo #下载docker-ce repo
sudo yum -y install https://download.docker.com/linux/fedora/30/x86_64/stable/Packages/containerd.io-1.2.6-3.3.fc30.x86_64.rpm #安装containerd.io依赖
sudo yum -y install docker-ce #安装docker
sudo systemctl start docker #启动软件
sudo systemctl enable docker #开机自启动
sudo systemctl daemon-reload #重载所有修改过的配置文件
sudo docker version	#查看软件版本

yum erase firewall -y && yum install iptables -y && systemctl enable iptables
systemctl start iptables #开启防火墙规则
iptables -F #清空防火墙规则
systemctl status firewalld #查看防火墙
free -m	#确认sawp关闭