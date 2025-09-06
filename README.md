# aws_eks_handbook
DevOps Tutorials

written be pengchao in shanghai

v1.v2.v3.v4.v5

If you are using an ubuntu server for eks cluster management, some apps you need to check and install if needed.

1, check the aws cli.

    aws --version

2, Install kubectl

3, Install eksctl

4, Install Helm

5, Install Docker

<p>sudo apt-get update</p>
<p>sudo apt-get install docker.io</p>
<p>sudo usermod -aG docker $USER  # add the current user to docker group，then</p> <p>you will not use sudo everytime </p>
<p>(you need logoff and login again) </p>
<p>newgrp docker # or you just run this command to function immediately</p>

6, aws configure command to added your aws credentials

# update the  kubeconfig ( this is very important part)

aws eks update-kubeconfig --region us-east-1 --name aws-eks-cluster

# test the connection

kubectl get nodes
kubectl get pods -A

# use kubectl to install the latest metrics-server

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

1,check the metrics-server running or not 

kubectl get pods -n kube-system -l k8s-app=metrics-server

2,check the pod and nodes cpu and memory usage

kubectl top nodes
kubectl top pods -A

