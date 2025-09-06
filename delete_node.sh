# 删除第一个节点组
aws eks delete-nodegroup \
  --cluster-name aws-eks-cluster \
  --nodegroup-name development-1

# 等待几秒后再删除第二个，避免 API 限制
sleep 5

# 删除第二个节点组
aws eks delete-nodegroup \
  --cluster-name aws-eks-cluster \
  --nodegroup-name development-8
