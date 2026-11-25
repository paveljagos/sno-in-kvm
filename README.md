# single node openshift on kvm 


Tested on `RHEL9` and `Fedora 43`.



## server with hardware virtualization

```sh
$ lscpu | grep -i virtualization
Virtualization:                          AMD-V
```




## prerequsities

[dowload tools and coreos iso from openshift mirror](https://mirror.openshift.com/pub/openshift-v4/x86_64/)

##### tooling
* coreos-installer_amd64
* openshift-install

##### iso
* rhcos-live-iso.x86_64.iso


##### pull-secret
* [download pull-secret](https://console.redhat.com/openshift/downloads)





## install dependecies

* usefull tooling
```sh
bash install-deps.sh
```

* install and configure the `systemd-resolved`
```sh
bash systemd-resolved.sh
```



### copy some files: are small so by hand is innafe..

File `sno-net.xml` is definition on the *virtual network* which is provided for the **openshift single node** installation.

* start the virtual network
```sh
sudo virsh net-define sno-net.xml
sudo virsh net-start sno-dev
sudo virsh net-autostart sno-dev
```





## prepare installation configs / ssh key, pull secreat

* generate new key with `ssh-keygen`


### prepare install-config.yaml

* prepare env variables

```sh
export pullSecret=$(cat pull-secret)

echo $pullSecret | less
{"auths":{"cloud.openshift.com":{"auth":...}}}


export sshKey=$(cat ~/.ssh/id_rsa.pub)

echo $sshKey | less
ssh-rsa ..
```


* substitute env variables into the `install-config.yaml`
```sh
envsubst '$pullSecret $sshKey' < template_install-config.yaml > install-config.yaml
```

### generate configs for the openshift sno

* create config by `openshift-install`
```sh
[lab-user@bastion ~]$
mkdir -p /home/lab-user/install-out/
cp install-config.yaml install-out/
./openshift-install create single-node-ignition-config --dir=./install-out
```



* EMBED CONFIGS / produce `sno-installer.iso`
```sh
./coreos-installer_amd64 iso customize \
  --dest-device /dev/vda \
  --live-ignition ./install-out/bootstrap-in-place-for-live-iso.ign \
  --output sno-installer.iso \
  rhcos-live-iso.x86_64.iso
```
> GOOD NOTE: you may need to regenerate iso to get fresh certificates before you start installation


* copy the `iso` into path for the `qemu` user
```sh
sudo cp /home/lab-user/sno-installer.iso /var/lib/libvirt/qemu/
sudo chown qemu:qemu /var/lib/libvirt/qemu/sno-installer.iso
```




* i need to over come the *MAC mismatch* with `virt-install`
```sh
sudo virt-install \
  --name sno-node \
  --ram 53248 \
  --vcpus 52 \
  --os-variant linux2024 \
  --disk path=/var/lib/libvirt/qemu/sno-node.qcow2,bus=virtio,size=135  \
  --cdrom /var/lib/libvirt/qemu/sno-installer.iso \
  --network network=sno-dev,model=virtio,mac=02:01:00:00:00:66 \
  --graphics vnc,listen=0.0.0.0 \
  --noautoconsole \
  --boot hd,cdrom

```


* is it running? after while the vm `sno-node` will stop, so restart it.
```sh
sudo virsh list --all

# START sno-node
sudo virsh start sno-node
```


* progress..
```sh
./openshift-install wait-for install-complete --dir=./install-out --log-level=info
./openshift-install wait-for install-complete --dir=./install-out --log-level=debug
```


### WHEN CLUSTER IS READY

```sh
export KUBECONFIG=/home/$USER/install-out/auth/kubeconfig
oc get clusteroperators
oc get nodes
```






#### more usefull notes

Here are notes which i found usefull and create this simple category for it.

##### manual confirmation the `192.168.123.5` is resolved

```sh
[devops@bastion1 ~]$ dig @192.168.123.1 api.sno.ocp.dev +short
192.168.123.5
```


* [wow, after relorver configuration -> works]
```sh
$ resolvectl query api.sno.ocp.dev
api.sno.ocp.dev: 192.168.123.5           -- link: virbr1

-- Information acquired via protocol DNS in 6.0649s.
-- Data is authenticated: no; Data was acquired via local or encrypted transport: no
-- Data from: network
```

* ps aux | grep dnsmasq
```sh
ps aux | grep dnsmasq
dnsmasq    34388  0.0  0.0   9552  2108 ?        S    08:37   0:00 /usr/sb
in/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/default.conf --leasefile-r
```


##### ssh core@192.168.123.5

```sh
[core@node ~]$ sudo sudo journalctl -xe

[core@node ~]$ sudo journalctl -u kubelet -f

[core@node ~]$ journalctl -b -f -u release-image.service -u bootkube.service
```




### firewalld rulles

> in case you have active firewall, you need to allow the traffic

* commands

```sh
sudo firewall-cmd --zone=trusted --add-interface=virbr1 --permanent
sudo firewall-cmd --zone=trusted --add-service=https --permanent
sudo firewall-cmd --zone=trusted --add-port=6443/tcp --permanent
sudo firewall-cmd --zone=trusted --add-port=22623/tcp --permanent
sudo firewall-cmd --reload
```

* trusted.xml

```sh
sudo cat /etc/firewalld/zones/trusted.xml
[sudo] password for pjagos: 
<?xml version="1.0" encoding="utf-8"?>
<zone target="ACCEPT">
  <short>Trusted</short>
  <description>All network connections are accepted.</description>
  <service name="https"/>
  <port port="6443" protocol="tcp"/>
  <port port="22623" protocol="tcp"/>
  <interface name="virbr1"/>
  <forward/>
</zone>
```






#### future imporovements

This can be taken as notes and ides for future me.

> in bash scripts i do has check for root user and also the use of `sudo` and so, now it is redundant and can be removed







