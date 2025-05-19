#!/bin/bash
# full-network-diagnosis.sh

INSTANCE_ID="i-08aef7e0b902cce76"
IP="54.157.47.216"

echo "=== Diagnóstico Completo de Rede ==="

# 1. Instância
echo -e "\n1. Detalhes da Instância:"
aws ec2 describe-instances --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].[InstanceId,State.Name,PublicIpAddress,PrivateIpAddress,SubnetId,VpcId,SecurityGroups[0].GroupId]' \
  --output table

# 2. Security Group
SG_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text)
echo -e "\n2. Security Group ($SG_ID):"
aws ec2 describe-security-groups --group-ids $SG_ID \
  --query 'SecurityGroups[0].IpPermissions[*].[IpProtocol,FromPort,ToPort,IpRanges[0].CidrIp]' \
  --output table

# 3. Subnet
SUBNET_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].SubnetId' --output text)
echo -e "\n3. Subnet ($SUBNET_ID):"
aws ec2 describe-subnets --subnet-ids $SUBNET_ID \
  --query 'Subnets[0].[SubnetId,MapPublicIpOnLaunch,CidrBlock,AvailabilityZone]' \
  --output table

# 4. Route Table
echo -e "\n4. Route Table:"
aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,Values=$SUBNET_ID" \
  --query 'RouteTables[0].Routes[*].[DestinationCidrBlock,GatewayId,NatGatewayId,State]' \
  --output table

# 5. Internet Gateway
VPC_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].VpcId' --output text)
echo -e "\n5. Internet Gateway:"
aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query 'InternetGateways[*].[InternetGatewayId,Attachments[0].State]' \
  --output table

# 6. Network ACLs
echo -e "\n6. Network ACLs:"
aws ec2 describe-network-acls \
  --filters "Name=association.subnet-id,Values=$SUBNET_ID" \
  --query 'NetworkAcls[0].Entries[?RuleNumber<=`100`].[RuleNumber,Protocol,RuleAction,CidrBlock,Egress]' \
  --output table

# 7. Verificar IP elástico
echo -e "\n7. Elastic IP:"
aws ec2 describe-addresses \
  --filters "Name=instance-id,Values=$INSTANCE_ID" \
  --query 'Addresses[*].[PublicIp,AllocationId,AssociationId]' \
  --output table