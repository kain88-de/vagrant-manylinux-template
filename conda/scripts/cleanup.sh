#remove network mac and interface information
sudo sed -i '/HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-eth0
sudo sed -i "/^UUID/d" /etc/sysconfig/network-scripts/ifcfg-eth0

#disable selinux
sudo rm /etc/sysconfig/selinux
sudo ln -s /etc/selinux/config /etc/sysconfig/selinux
sudo sed -i "s/^\(SELINUX=\).*/\1disabled/g" /etc/selinux/config

#remove any ssh keys or persistent routes, dhcp leases
sudo rm -f /etc/ssh/ssh_host_*
sudo rm -f /etc/udev/rules.d/70-persistent-net.rules
sudo rm -f /var/lib/dhclient/dhclient-eth0.leases
sudo rm -rf /tmp/*
sudo yum -y clean all
