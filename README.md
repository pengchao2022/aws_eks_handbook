# aws_eks_handbook
DevOps Tutorials

written be pengchao in shanghai

v1

If you are using an ubuntu server for eks cluster management, some apps you need to check and install if needed.

1, check the aws cli.

    aws --version

2, Install kubectl

3, Install eksctl

4, Install Helm

5, Install Docker

sudo apt-get update
sudo apt-get install docker.io
sudo usermod -aG docker $USER  # add the current user to docker group，then you will not use sudo everytime
(you need logoff and login again) 
newgrp docker # or you just run this command to function immediately

6, aws configure command to added your aws credentials

# update the  kubeconfig ( this is very important part)

aws eks update-kubeconfig --region <your-region> --name <your-cluster-name>

# test the connection

kubectl get nodes
kubectl get pods -A