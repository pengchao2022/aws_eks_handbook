#!/bin/bash
set -ex

# 设置主机名
hostnamectl set-hostname ${node_name}

# 安装必要的包
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# 安装 Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# 配置 Docker 使用 systemd cgroup driver
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

systemctl daemon-reload
systemctl restart docker
systemctl enable docker

# 安装 kubelet, kubeadm, kubectl
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# 安装 AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf awscliv2.zip ./aws

# 安装 SSM agent
snap install amazon-ssm-agent --classic

# 配置 kubelet 使用正确的集群信息
mkdir -p /etc/kubernetes
cat > /etc/kubernetes/kubelet.conf << EOF
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
evictionHard:
  memory.available: "100Mi"
  nodefs.available: "10%"
  nodefs.inodesFree: "5%"
  imagefs.available: "10%"
EOF

# 创建 kubelet 服务配置
cat > /etc/systemd/system/kubelet.service.d/10-kubeadm.conf << EOF
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
Environment="KUBELET_EXTRA_ARGS=--node-ip=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) --node-labels=node.kubernetes.io/lifecycle=normal --register-with-taints="
ExecStart=
ExecStart=/usr/bin/kubelet \$KUBELET_KUBECONFIG_ARGS \$KUBELET_CONFIG_ARGS \$KUBELET_EXTRA_ARGS
EOF

systemctl daemon-reload
systemctl restart kubelet
systemctl enable kubelet

# 等待网络就绪
sleep 10

# 获取集群信息并配置 kubelet
CLUSTER_NAME=${cluster_name}
REGION=${region}

# 获取集群证书和端点
mkdir -p /etc/kubernetes/pki
aws eks describe-cluster --region $REGION --name $CLUSTER_NAME --query cluster.certificateAuthority.data --output text | base64 -d > /etc/kubernetes/pki/ca.crt

ENDPOINT=$(aws eks describe-cluster --region $REGION --name $CLUSTER_NAME --query cluster.endpoint --output text)

# 创建 bootstrap kubeconfig
cat > /etc/kubernetes/bootstrap-kubelet.conf << EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/pki/ca.crt
    server: $ENDPOINT
  name: ${cluster_name}
contexts:
- context:
    cluster: ${cluster_name}
    user: kubelet-bootstrap
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: kubelet-bootstrap
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
      - eks
      - get-token
      - --cluster-name
      - ${cluster_name}
      - --region
      - ${region}
EOF

# 重启 kubelet 以应用新配置
systemctl daemon-reload
systemctl restart kubelet

echo "Node setup completed for cluster: ${cluster_name}, node: ${node_name}"