Vagrant.configure("2") do |config|
  config.vm.box = "bento/debian-12"
  config.vm.box_version = "202510.26.0"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end
  
  MASTER_IP = "192.168.50.11"

  # Script d’installation de Docker
  docker_kube_install = <<-SHELL
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg lsb-release gpg
    
    #kube requirements
    swapoff -a
    sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

    mkdir -p /etc/apt/keyrings

    # kube
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
    apt-get update -y
    apt-get install -y containerd kubelet kubeadm kubectl libglib2.0-0
    sudo apt install -y qemu-user-static binfmt-support

    # réseau
    echo "Loading kernel modules..."
    cat <<EOF | tee /etc/modules-load.d/k8s.conf
    br_netfilter
    overlay
EOF
    modprobe br_netfilter
    modprobe overlay
    
    echo "Setting sysctl parameters..."
    cat <<EOF | tee /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-iptables  = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    net.ipv4.ip_forward                 = 1
EOF

    sysctl --system
    
    systemctl restart containerd
    systemctl enable --now containerd
    systemctl enable --now kubelet
    apt-mark hold kubelet kubeadm kubectl
  SHELL

  kubeadm_init = <<-SHELL
    kubeadm config images pull
    kubeadm init --apiserver-advertise-address=#{MASTER_IP} \
      --node-name=primary-node \
      --pod-network-cidr=10.244.0.0/16

    echo "export config"
    export KUBECONFIG=/etc/kubernetes/admin.conf
    mkdir -p /home/vagrant/.kube
    sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
    sudo chown vagrant:vagrant /home/vagrant/.kube/config
    echo "end export config | Install Flannel"


    until kubectl get nodes >/dev/null 2>&1; do
    echo "  → API server not ready yet, waiting 10s..."
    sleep 10
    done 

    echo "node ready"
  
    kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

    echo "create token into join-command.sh"
    kubeadm token create --print-join-command > /vagrant/join-command.sh
    chmod +x /vagrant/join-command.sh
    
    containerd config default | tee /etc/containerd/config.toml
    sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
    systemctl restart containerd
    systemctl restart kubelet
    kubectl delete pod -n kube-flannel --all
  SHELL

  kubeadm_join = <<-SHELL
    while [ ! -f /vagrant/join-command.sh ]; do
      echo "Waiting for join command..."
      sleep 10
      done

      echo "Joining cluster"
    bash /vagrant/join-command.sh
  SHELL

  repair_flannel = <<-SHELL
    echo "repair flannels on node"
    sudo mkdir -p /opt/cni/bin
    sudo mkdir -p /usr/lib/cni
    sudo curl -L https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-amd64-v1.2.0.tgz | tar -C /opt/cni/bin -xz
    sudo ln -s /opt/cni/bin/* /usr/lib/cni/
    systemctl restart kubelet
    systemctl restart containerd
  SHELL
  # === VM 1 ===
  config.vm.define "primary-node" do |node|
    node.vm.hostname = "primary-node"
    node.vm.network "private_network", ip: "192.168.50.11"
    node.vm.provision "shell", inline: docker_kube_install
    node.vm.provision "shell", inline: kubeadm_init
    node.vm.provision "shell", inline: repair_flannel
  end

  # === VM 2 ===
  config.vm.define "worker-node1" do |node|
    node.vm.hostname = "worker-node1"
    node.vm.network "private_network", ip: "192.168.50.12"
    node.vm.provision "shell", inline: docker_kube_install
    node.vm.provision "shell", inline: kubeadm_join
    node.vm.provision "shell", inline: repair_flannel
  end

  # === VM 3 ===
  config.vm.define "worker-node2" do |node|
    node.vm.hostname = "worker-node2"
    node.vm.network "private_network", ip: "192.168.50.13"
    node.vm.provision "shell", inline: docker_kube_install
    node.vm.provision "shell", inline: kubeadm_join
    node.vm.provision "shell", inline: repair_flannel
  end
end