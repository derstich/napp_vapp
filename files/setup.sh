#!/bin/bash

# Bootstrap script

set -euo pipefail

if [ -e /root/ran_customization ]; then
    exit
else
    NETWORK_CONFIG_FILE=$(ls /etc/systemd/network | grep .network)

    MASTER_IP_ADDRESS_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep -m1 "guestinfo.master_ip")
    NODE_IP_ADDRESS_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep -m1 "guestinfo.node_ip")
    NETMASK_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep -m1 "guestinfo.netmask")
    VIP_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep -m1 "guestinfo.vip_pool")
    GATEWAY_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep -m1 "guestinfo.gateway")
    NTP_SERVER_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep -m1 "guestinfo.ntp")
    DNS_SERVER_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep -m1 "guestinfo.dns")
    DNS_DOMAIN_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep -m1 "guestinfo.domain")
    ROOT_PASSWORD_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep -m1 "guestinfo.root_password")
    ROLE_PROPERTY==$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep -m1 "guestinfo.role")
    NSXMGR_PROPERTY==$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep -m1 "guestinfo.nsxmanager")
    NSXUSER_PROPERTY==$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep -m1 "guestinfo.nsxuser")
    NSXPASSWORD_PROPERTY==$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep -m1 "guestinfo.nsxpassword")
    PODNET_PROPERTY==$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep -m1 "guestinfo.podnet")
    PRELOAD_PROPERTY==$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep -m1 "guestinfo.preload")
    NAPPFQDN_PROPERTY==$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep -m1 "guestinfo.nappfqdn")
    NAPPAUTODEPLOY_PROPERTY==$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep -m1 "guestinfo.nappautodeploy")
    LOCALCACHE_PROPERTY==$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep -m1 "guestinfo.localcache")
    CLUSTERSIZE_PROPERTY==$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep -m1 "guestinfo.clustersize")
    NODENUM_PROPERTY==$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep -m1 "guestinfo.nodenum")

    ROLE=$(echo "${ROLE_PROPERTY}" | cut -d'"' -f4)
    CLUSTERSIZE=$(echo "${CLUSTERSIZE_PROPERTY}" | cut -d'"' -f4)
    NODENUM=$(echo "${NODENUM_PROPERTY}" | cut -d'"' -f4)

    MASTER_IP_ADDRESS=$(echo "${MASTER_IP_ADDRESS_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    NODE_IP_ADDRESS=$(echo "${NODE_IP_ADDRESS_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')

    if [ ${ROLE} == "master" ]; then
        IP_ADDRESS=${MASTER_IP_ADDRESS}
	HOSTNAME="napp-k8s-master"
    else
        IP_ADDRESS=${NODE_IP_ADDRESS}	
	HOSTNAME="napp-k8s-node"
    fi

    echo "${NODE_IP_ADDRESS} napp-k8s-node" >> /etc/hosts
    echo "${MASTER_IP_ADDRESS} napp-k8s-master" >> /etc/hosts
    hostnamectl set-hostname ${HOSTNAME}

    NETMASK=$(echo "${NETMASK_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    GATEWAY=$(echo "${GATEWAY_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    DNS_SERVER=$(echo "${DNS_SERVER_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    DNS_DOMAIN=$(echo "${DNS_DOMAIN_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    NSXMGR=$(echo "${NSXMGR_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    NSXUSER=$(echo "${NSXUSER_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    NSXPASSWORD=$(echo "${NSXPASSWORD_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    VIP=$(echo "${VIP_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    PODNET=$(echo "${PODNET_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    NAPPFQDN=$(echo "${NAPPFQDN_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    NTP_SERVER=$(echo "${NTP_SERVER_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    LOCALCACHE=$(echo "${LOCALCACHE_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')

    NAPPAUTODEPLOY=$(echo "${NAPPAUTODEPLOY_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    PRELOAD=$(echo "${PRELOAD_PROPERTY}" | cut -d'"' -f4)


    # different OVA imlementations use upper/lowercase True/false operators. fix by checking without case sensitivity and setting to 1/0
    shopt -s nocasematch
    case $PRELOAD in
	true)
		PRELOAD=1
		;;
	*)
		PRELOAD=0
		;;
    esac


    case $NAPPAUTODEPLOY in
	true)
		NAPPAUTODEPLOY=1
		;;
	*)
		NAPPAUTODEPLOY=0
		;;
    esac 	
    shopt -u nocasematch

    echo -e "\e[92mConfiguring Static IP Address ...\e[37m"
    cat > /etc/systemd/network/${NETWORK_CONFIG_FILE} << __CUSTOMIZE_PHOTON__
[Match]
Name=e*

[Network]
Address=${IP_ADDRESS}/${NETMASK}
Gateway=${GATEWAY}
DNS=${DNS_SERVER}
Domains=${DNS_DOMAIN}
__CUSTOMIZE_PHOTON__

    echo -e "\e[92mRestarting Network ...\e[37m"
    systemctl restart systemd-networkd

    echo -e "\e[92mConfiguring root password ...\e[37m"
    ROOT_PASSWORD=$(echo "${ROOT_PASSWORD_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
	

    # disable PW quality check
    sed -i -e 's\# enforcing = 1\enforcing = 0\g'  /etc/security/pwquality.conf
    
    if [ -z "${ROOT_PASSWORD}" ]; then
	echo "Empty password setting. No Change"
    else
        echo "root:${ROOT_PASSWORD}" | /usr/sbin/chpasswd
    fi

    echo -e "\e[92mSetting up NTP\e[37m"
    echo "NTP=${NTP_SERVER}" >> /etc/systemd/timesyncd.conf
    systemctl restart systemd-timesyncd

    echo -e "\e[92mDisable HW Offload on eth0\e[37m"
    ethtool --offload eth0 rx off tx off

# check network connection

echo -e "\e[92mChecking Internet Connection\e[37m"
set +e
wget -nv -P /nappinstall https://raw.githubusercontent.com/danpaul81/napp_vapp/main/README.md 
rc=$?
while [[ $rc != 0 ]]; do
    echo -e "$(date) \e[91mFailed. Check your network and/or re-enroll with correct settings. Retry in 10sec\e[37m"
    echo -e "\e[91mIP: $IP_ADDRESS Netmask: $NETMASK GW: $GATEWAY DNS: $DNS_SERVER\e[37m"
    sleep 10s
    wget -nv -P /nappinstall https://raw.githubusercontent.com/danpaul81/napp_vapp/main/README.md
    rc=$? 
done 

echo -e "\e[92mDone....\e[37m"
set -e


# depending on appliance role (master or node) prepare vm

    if [ ${ROLE} == "master" ]; then
	# preparation of node -> will also setup master
	echo -e "\e[92m Role: k8s master\e[37m"
	echo -e "\e[92m preparing cluster with ${CLUSTERSIZE} worker nodes\e[37m"
	
	# create SSH Passphrase. Host Key checking is already disabled
	ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""

	# extract package with yaml templates
	tar -xzf /root/nappinstall.tgz -C /

        #if localcache exists try to download kubernetes packages
        if ! [ -z "${LOCALCACHE}" ]; then
		echo -e "$(date) \e[92mLocalCache is set. Trying to download k8s base package. can take >10 min\e[37m"
                set +e
                wget -nv -P /nappinstall http://${LOCALCACHE}/base-images.tgz
                rc=$?
                if [[ $rc -eq 0 ]]; then
                        echo -e "\e[92mUnpacking LocalCache Package & removing download\e[37m"
                        tar -xvf /nappinstall/base-images.tgz -C /nappinstall
                        rm /nappinstall/base-images.tgz
                        echo -e "\e[92mImporting LocalCache Package\e[37m"
			( cd /nappinstall/base-images && bash /nappinstall/base-images/load_docker_images.sh )
                        echo -e "\e[92mRemoving LocalCache Download/Directory\e[37m"
                        rm -rf /nappinstall/base-images
                else
                        echo -e "\e[92mDownload from LocalCache failed. Continuing\e[37m"
                fi
                set -e
        else
                echo -e "\e[92mLocalCache NOT set.\e[37m"
        fi

	echo -e "\e[92mprepare k8s cluster\e[37m"
	K8SVERSION=$(rpm -q kubernetes-kubeadm |cut -d'-' -f3)
	sed -i -e 's\{{K8SVERSION}}\'$K8SVERSION'\g' /nappinstall/k8s-master-setup.sh
	sed -i -e 's\{{K8SMASTER}}\'$MASTER_IP_ADDRESS'\g' /nappinstall/k8s-master-setup.sh
	sed -i -e 's\{{PODNET}}\'$PODNET'\g' /nappinstall/k8s-master-setup.sh
	
	bash /nappinstall/k8s-master-setup.sh
        tail -n 2 /nappinstall/kubeadm-init.out > /nappinstall/kubeadm-node.sh

	echo -e "\e[92mgrant local node api access\e[37m"
	mkdir -p /root/.kube
	cp /etc/kubernetes/admin.conf /root/.kube/config
 	chown $(id -u):$(id -g) /root/.kube/config
	export KUBECONFIG=/root/.kube/config

	if [ ${PRELOAD} == 1 ]; then
	    echo -e "\e[92mLoading Antrea/Metallb Image into local Docker Image Repo\e[37m"
	    docker pull projects.registry.vmware.com/antrea/antrea-ubuntu:v1.5.0
    	    docker pull quay.io/metallb/controller:v0.9.7
	    docker pull quay.io/metallb/speaker:v0.9.7
	else
	    echo -e "\e[92mNO pre-loading Antrea/Metallb Image into local Docker Image Repo\e[37m"
	fi

	# push VIP to metallb configmap
        sed -i -e 's\{{VIP}}\'$VIP'\g' /nappinstall/metallb-configmap.yaml

	# push NFS Server IP to nfs-provisioner.yaml
	sed -i -e 's\{{NFSSERVER}}\'$NODE_IP_ADDRESS'\g' /nappinstall/nfs-provisioner.yaml

	# install Antrea/MetalLB
	echo -e "\e[92mSetting Up k8s services Antrea, MetalLB\e[37m"

	# setup antrea
	kubectl apply -f https://github.com/antrea-io/antrea/releases/download/v1.5.0/antrea.yml

	# setup metallb. using 0.9.7 as 12.1 has issue with k8s 0.19
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.7/manifests/namespace.yaml
	kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
	#using local copy for deployment as online version refers to dockerhub (download quota...)
	kubectl apply -f /nappinstall/metallb.yaml
	kubectl apply -f /nappinstall/metallb-configmap.yaml


	# check if node1 is ready 
	set +e
	echo -e "\e[92mChecking if node1 is online (ping every 30sec) $NODE_IP_ADDRESS \e[37m"

	COUNT=1
	while [[ $COUNT -eq 1 ]]; do
        	ping -c 1 $NODE_IP_ADDRESS &>/dev/null
	        rc=$?
    	    if [[ $rc -eq 0 ]]; then
                COUNT=0
    	    else
                COUNT=1
		echo -e "\e[92mNO answer from $NODE_IP_ADDRESS. retry in 30sec \e[37m"
    	    fi
	#wait 30s even if successful
	sleep 30s
	done
	echo -e "\e[92mGot response from node1. Copy SSH Key\e[37m"

	export SSHPASS=${ROOT_PASSWORD}
	sshpass -e ssh-copy-id -i /root/.ssh/id_rsa ${NODE_IP_ADDRESS}

	echo -e "\e[92mChecking if Node1 has finished its base setup \e[37m"

        COUNT=1
        while [[ $COUNT -eq 1 ]]; do
                ssh ${NODE_IP_ADDRESS} test -f /nappinstall/READY_BASE
                rc=$?
            if [[ $rc -eq 0 ]]; then
                COUNT=0
            else
                echo -e "\e[92mstill checking if node1 has finished its base setup. retry in 30sec \e[37m"
		COUNT=1
		sleep 30s
            fi
        done
        echo -e "\e[92mGot response from node1. Load Base k8s images and do cluster join\e[37m"
	
	set -e
	# preload is set and localcache not used. copy bass images to node
	if [ ${PRELOAD} == 1 ] && [ -z "$LOCALCACHE}" ]; then
	    echo -e "\e[92mLoading Antrea/Metallb Image into local Docker Image Repo of node\e[37m"
  
	    docker save -o /nappinstall/antrea-ubuntu:v1.5.0.tar projects.registry.vmware.com/antrea/antrea-ubuntu:v1.5.0
	    docker save -o /nappinstall/controller:v0.9.7.tar quay.io/metallb/controller:v0.9.7
	    docker save -o /nappinstall/speaker:v0.9.7.tar quay.io/metallb/speaker:v0.9.7
   
	    scp /nappinstall/antrea-ubuntu:v1.5.0.tar ${NODE_IP_ADDRESS}:/nappinstall
	    scp /nappinstall/controller:v0.9.7.tar ${NODE_IP_ADDRESS}:/nappinstall
	    scp /nappinstall/speaker:v0.9.7.tar ${NODE_IP_ADDRESS}:/nappinstall
	    ssh ${NODE_IP_ADDRESS} docker load -i /nappinstall/antrea-ubuntu:v1.5.0.tar
	    ssh ${NODE_IP_ADDRESS} docker load -i /nappinstall/controller:v0.9.7.tar
	    ssh ${NODE_IP_ADDRESS} docker load -i /nappinstall/speaker:v0.9.7.tar
	else
	    echo -e "\e[92mNOT Loading Antrea/Metallb Image into local Docker Image Repo of node\e[37m"
	fi
	
	echo -e "\e[92mJoin K8S Cluster\e[37m"
	scp /nappinstall/kubeadm-node.sh ${NODE_IP_ADDRESS}:/nappinstall
	ssh ${NODE_IP_ADDRESS} bash /nappinstall/kubeadm-node.sh

	# nfs-provisioner
	kubectl apply -f /nappinstall/nfs-provisioner.yaml

#check if node2 is ready
#push ssh key
#push images
#add to cluster


#check if node3 is ready
#push ssh key
#push images
#add to cluster


# check if node one has finished base image preload
	set +e
	echo -e "\e[92mChecking if node1 has finished loading NSX base images. This may take >60min\e[37m"

        COUNT=1
        while [[ $COUNT -eq 1 ]]; do
                ssh ${NODE_IP_ADDRESS} test -f /nappinstall/READY_BASE_IMAGES
                rc=$?
            if [[ $rc -eq 0 ]]; then
                COUNT=0
            else
                echo -e "$(date) \e[92mstill checking if node1 has finished loading base images. retry in 5min \e[37m"
		COUNT=1
		sleep 5m
            fi
        done
        echo -e "\e[92mGot response from node1. Starting NSX manager setup\e[37m"
	
	set -e

	echo -e "\e[92mPreparing NSX Manager NAPP Settings\e[37m"
        sed -i -e 's\{{nsxuser}}\'$NSXUSER'\g' /nappinstall/napp-prepare-nsx.sh
        sed -i -e 's\{{nsxpasswd}}\'$NSXPASSWORD'\g' /nappinstall/napp-prepare-nsx.sh
        sed -i -e 's\{{nsxmanager}}\'$NSXMGR'\g' /nappinstall/napp-prepare-nsx.sh
        sed -i -e 's\{{nappfqdn}}\'$NAPPFQDN'\g' /nappinstall/napp-prepare-nsx.sh

        sed -i -e 's\{{nsxuser}}\'$NSXUSER'\g' /nappinstall/napp-deploy-nsx.sh
        sed -i -e 's\{{nsxpasswd}}\'$NSXPASSWORD'\g' /nappinstall/napp-deploy-nsx.sh
        sed -i -e 's\{{nsxmanager}}\'$NSXMGR'\g' /nappinstall/napp-deploy-nsx.sh

	echo -e "\e[92mPreparing NAPP Deployment on NSX Manager\e[37m"
	bash /nappinstall/napp-prepare-nsx.sh

        #start NAPP Deployment on NSX Manager
	if [ ${NAPPAUTODEPLOY} == 1 ]; then
	  echo -e "\e[92mStarting NAPP Deployment on NSX Manager\e[37m"
	  bash /nappinstall/napp-deploy-nsx.sh
	else
	  echo -e "\e[92mNAPP Platform will not Auto Deploy. You need to start manually on NSX MGR\e[37m"
	fi
	echo -e "\e[92mFinished master setup script\e[37m"

    else
	# preparation of node
	echo -e "\e[92m Role: k8s worker #${NODENUM}\e[37m"
	
	tar -xzf /root/nappinstall.tgz -C /
        
	#prepare data disk sdb1. only necessary on node
	echo -e "\e[92mCreating Data Disk\e[37m"
	echo 'type=83' | sfdisk /dev/sdb
	mkfs.ext4 /dev/sdb1
	mkdir -p /nfs
	mount /dev/sdb1 /nfs
	echo '/dev/sdb1       /nfs    ext4    defaults     0   0' | tee -a /etc/fstab

	# re-mount docker / kubelet datadir to data disk
	echo -e "\e[92mre-mount Docker / Kubelet storage\e[37m"
	#docker rm -f $(docker ps -aq); docker rmi -f $(docker images -q)
	systemctl stop docker
	rm -rf /var/lib/docker
	rm -rf /var/lib/kubelet

	mkdir /var/lib/docker
	mkdir /var/lib/kubelet

	mkdir /nfs/docker
	mkdir /nfs/kubelet
	#mount --rbind /nfs/docker/ /var/lib/docker
	#mount --rbind /nfs/kubelet/ /var/lib/kubelet
	
        echo '/nfs/docker     /var/lib/docker  none  defaults,rbind    0   0' | tee -a /etc/fstab
        echo '/nfs/kubelet    /var/lib/kubelet none  defaults,rbind    0   0' | tee -a /etc/fstab
	mount /nfs/docker
	mount /nfs/kubelet

	
	systemctl start docker
	systemctl restart kubelet

	echo -e "\e[92mCreating NFS SERVER\e[37m"
	mkdir -p /nfs/k8s
	echo '/nfs/k8s        *(rw,sync,no_root_squash,no_subtree_check)' | tee -a /etc/exports
	chown nobody:nogroup /nfs/k8s
	systemctl enable nfs-server.service	
	systemctl start nfs-server.service

        #if localcache exists try to download kubernetes packages
        if ! [ -z "${LOCALCACHE}" ]; then
		echo -e "$(date) \e[92mLocalCache is set. Trying to download k8s base package. Can take >10min\e[37m"
                set +e
                wget -nv -P /nfs http://${LOCALCACHE}/base-images.tgz
                rc=$?
                if [[ $rc -eq 0 ]]; then
                        echo -e "\e[92mUnpacking LocalCache Package & removing download\e[37m"
                        tar -xvf /nfs/base-images.tgz -C /nfs
                        rm /nfs/base-images.tgz
                        echo -e "\e[92mImporting LocalCache Package\e[37m"
			( cd /nfs/base-images && bash /nfs/base-images/load_docker_images.sh )
                        echo -e "\e[92mRemoving LocalCache Download/Directory\e[37m"
                        rm -rf /nfs/base-images
                else
                        echo -e "\e[92mDownload from LocalCache failed. Continuing\e[37m"
                fi
                set -e
        else
                echo -e "\e[92mLocalCache NOT set.\e[37m"
        fi

	echo -e "\e[92mFinished Base Setup\e[37m"
	touch /nappinstall/READY_BASE

	#if localcache exists try to download nsx packages
	if ! [ -z "${LOCALCACHE}" ]; then
		echo -e "$(date) \e[92mLocalCache is set. Trying to download package. Can take >10min\e[37m"
		set +e
		wget -nv -P /nfs http://${LOCALCACHE}/napp-images.tgz
		rc=$?
		if [[ $rc -eq 0 ]]; then
			echo -e "\e[92mUnpacking LocalCache Package & removing download\e[37m"
			tar -xvf /nfs/napp-images.tgz -C /nfs
			rm /nfs/napp-images.tgz
			echo -e "\e[92mImporting LocalCache Package\e[37m"
			( cd /nfs/napp-images && bash /nfs/napp-images/load_docker_images.sh )
			echo -e "\e[92memoving LocalCache Download/Directory\e[37m"
			rm -rf /nfs/napp-images
		else 
			echo -e "\e[92mDownload from LocalCache failed. Continuing\e[37m"
		fi		
		set -e
	else
        	echo -e "\e[92mLocalCache NOT set.\e[37m"
	fi


        #preload container base images
	if [ ${PRELOAD} == 1 ]; then
	  echo -e "\e[92mpreloading NSX container base images\e[37m"
	  # if image pre-load fail it can still be loaded from nsx manager setup
	  set +e
	  bash /nappinstall/download-base-images.sh
	  set -e
  	else
	  echo -e "\e[92mno NSX container preload for base images selected\e[37m"
	fi
	touch /nappinstall/READY_BASE_IMAGES

        #preload container application images
	if [ ${PRELOAD} == 1 ]; then
	  echo -e "\e[92mpreloading NSX application platform container images\e[37m"
	  set +e
	  bash /nappinstall/download-solution-images.sh
	  set -e
  	else
	  echo -e "\e[92mno NSX container preload for solution images selected\e[37m"
	fi
	touch /nappinstall/READY_APPLICATION_IMAGES
        echo -e "\e[92mFinished node setup\e[37m"
	  
    fi


    # Ensure we don't run customization again
    touch /root/ran_customization
fi
