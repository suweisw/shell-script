#!/bin/bash
sudo systemctl stop firewalld	#临时关闭防火墙
sudo systemctl disable firewalld	#永久关闭防火墙
sudo setenforce 0	#临时关闭SELinux
sudo swapoff -a		#关闭交换，注释交换分区
sudo sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config	#永久关闭SELinux

yum -y install wget

#检查MAC地址和product_uuid
sudo ip link
sudo cat /sys/class/dmi/id/product_uuid

#安装docker
sudo yum install wget container-selinux -y
sudo wget https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm
sudo yum erase runc -y
sudo rpm -ivh containerd.io-1.2.6-3.3.el7.x86_64.rpm
#注意：上面的步骤在centos7中无须操作
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo yum install -y yum-utils device-mapper-persistent-data lvm2 && yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && yum makecache && yum -y install docker-ce -y && systemctl enable docker.service && systemctl start docker

#配置aliyun的yum源
sudo cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
#安装最新版kubeadm
sudo yum makecache -y
sudo yum install -y kubelet kubeadm kubectl ipvsadm
#配置内核参数
sudo cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
vm.swappiness=0
EOF
sudo sysctl --system
sudo modprobe br_netfilter
sudo sysctl -p /etc/sysctl.d/k8s.conf
sudo modprobe ip_vs
sudo modprobe ip_vs_rr
sudo modprobe ip_vs_wrr
sudo modprobe ip_vs_sh
sudo modprobe nf_conntrack_ipv4
#查看是否加载成功
sudo lsmod | grep ip_vs
#获取镜像
sudo kubeadm config images list
#使用下面的方法在aliyun拉取相应的镜像并重新打标
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.18.3

docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.18.3 k8s.gcr.io/kube-apiserver:v1.18.3

docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:v1.18.3

docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:v1.18.3 k8s.gcr.io/kube-controller-manager:v1.18.3

docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.18.3

docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.18.3 k8s.gcr.io/kube-scheduler:v1.18.3

docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.18.3

docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.18.3 k8s.gcr.io/kube-proxy:v1.18.3

docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.1

docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.1 k8s.gcr.io/pause:3.1

docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.4.3-0

docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.4.3-0 k8s.gcr.io/etcd:3.4.3-0

docker pull coredns/coredns:1.6.5

docker tag coredns/coredns:1.6.5 k8s.gcr.io/coredns:1.6.5 

#查看docker镜像
sudo docker images

#配置kubelet使用国内pause镜像
DOCKER_CGROUPS=$(docker info | grep 'Cgroup' | cut -d' ' -f4)
echo $DOCKER_CGROUPS
#配置kubelet的cgroups
sudo cat <<EOF > /etc/sysconfig/kubelet
KUBELET_EXTRA_ARGS="--cgroup-driver=$DOCKER_CGROUPS --pod-infra-container-image=k8s.gcr.io/pause:3.1"
EOF
systemctl daemon-reload
systemctl enable kubelet && systemctl start kubelet
docker images