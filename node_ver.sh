# 方法1：持续检查，直到返回空数组
while [ -n "$(aws eks list-nodegroups --cluster-name aws-eks-cluster --output text)" ]; do
  echo "节点组正在删除中... 等待30秒后再次检查"
  sleep 30
done
echo "所有节点组已删除成功！"

# 方法2：分别检查每个节点组的详细状态（如果想看更详细的信息）
aws eks describe-nodegroup \
  --cluster-name aws
