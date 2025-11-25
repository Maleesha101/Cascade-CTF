#!/bin/bash
# Install Docker
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker

# Login to ECR
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 149195854976.dkr.ecr.ap-south-1.amazonaws.com

# Pull and run container
docker pull 
docker stop cascade-challenge 2>/dev/null || true
docker rm cascade-challenge 2>/dev/null || true
docker run -d --name cascade-challenge --restart always -p 3000:3000 

echo "Container started!"
