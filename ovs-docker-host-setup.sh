#!/bin/bash

# install basic tools
yum update -y 
yum install -y vim git net-tools epel-release
yum install -y arp-scan

# install ovs (openvswitch) 2.5.9
yum install -y wget openssl-devel gcc make python-devel openssl-devel kernel-devel graphviz kernel-debug-devel autoconf automake rpm-build redhat-rpm-config libtool python-twisted-core python-zope-interface PyQt4 desktop-file-utils libcap-ng-devel groff checkpolicy selinux-policy-devel

adduser ovs
su - ovs -c " \
mkdir -p ~/rpmbuild/SOURCES && \
wget https://www.openvswitch.org/releases/openvswitch-2.5.9.tar.gz && \
cp openvswitch-2.5.9.tar.gz ~/rpmbuild/SOURCES/ && \
tar xfz openvswitch-2.5.9.tar.gz && \
rpmbuild -bb --nocheck openvswitch-2.5.9/rhel/openvswitch-fedora.spec && \
exit"

yum localinstall -y /home/ovs/rpmbuild/RPMS/x86_64/openvswitch-2.5.9-1.el7.x86_64.rpm
systemctl enable openvswitch
systemctl start openvswitch
systemctl status openvswitch

# setup ovs network
nic_config=$(ls -l /etc/sysconfig/network-scripts/ifcfg-* | grep -v ifcfg-lo | head -n 1 | awk '{print $NF}')
cat > /etc/sysconfig/network-scripts/ifcfg-br-ext <<< $'
TYPE=OVSBridge
DEVICETYPE=ovs
BOOTPROTO="static"
DEFROUTE="yes"
NAME="br-ext"
DEVICE="br-ext"
ONBOOT="yes"'
cat ${nic_config} | grep "IPADDR\|PREFIX\|GATEWAY\|DNS*" >> /etc/sysconfig/network-scripts/ifcfg-br-ext

device=$(cat ${nic_config} | grep "DEVICE=")
cat > ${nic_config} <<< $'
TYPE=OVSPort
DEVICETYPE=ovs
OVS_BRIDGE=br-ext
ONBOOT=yes'
echo "${device}" >> ${nic_config}

systemctl restart network

# install docker-ce
yum install -y yum-utils
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io

systemctl enable docker
systemctl start docker
systemctl status docker
