# Fix ECS Instance Registration
$Region = "ap-south-1"
$ClusterName = "cascade-ctf-cluster"

Write-Host "Fixing ECS instance registration..." -ForegroundColor Cyan

# Get instance ID
$InstanceId = (aws ec2 describe-instances --filters "Name=tag:Name,Values=cascade-ecs-instance" "Name=instance-state-name,Values=running" --region $Region --query 'Reservations[0].Instances[0].InstanceId' --output text)

if (-not $InstanceId -or $InstanceId -eq "None") {
    Write-Host "No running instance found!" -ForegroundColor Red
    exit 1
}

Write-Host "Instance ID: $InstanceId"

# Terminate the problematic instance
Write-Host "`nTerminating the current instance (it's not configured properly)..."
aws ec2 terminate-instances --instance-ids $InstanceId --region $Region | Out-Null
Write-Host "Waiting for termination (30 seconds)..."
Start-Sleep -Seconds 30

# Get the security group and subnet
$VpcId = (aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text --region $Region)
$SubnetId = (aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VpcId" --query 'Subnets[0].SubnetId' --output text --region $Region)
$SgId = (aws ec2 describe-security-groups --filters "Name=group-name,Values=cascade-sg" --region $Region --query 'SecurityGroups[0].GroupId' --output text)

Write-Host "VPC: $VpcId"
Write-Host "Subnet: $SubnetId"
Write-Host "Security Group: $SgId"

# Get the correct ECS-optimized AMI for ap-south-1
Write-Host "`nGetting ECS-optimized AMI for $Region..."
$AmiId = (aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id --region $Region --query 'Parameters[0].Value' --output text)
Write-Host "AMI ID: $AmiId"

# Create proper user-data script
$UserData = @"
#!/bin/bash
echo ECS_CLUSTER=$ClusterName >> /etc/ecs/ecs.config
echo ECS_ENABLE_TASK_IAM_ROLE=true >> /etc/ecs/ecs.config
echo ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true >> /etc/ecs/ecs.config
systemctl restart ecs
"@

$UserDataBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($UserData))

# Launch new instance with ARM-based t4g.micro (cheaper) or t3.micro
Write-Host "`nLaunching new EC2 instance with proper ECS configuration..."

# Try t3.micro first
$NewInstanceId = (aws ec2 run-instances `
    --image-id $AmiId `
    --instance-type t3.micro `
    --iam-instance-profile Name=ecsInstanceProfile `
    --security-group-ids $SgId `
    --subnet-id $SubnetId `
    --user-data $UserDataBase64 `
    --associate-public-ip-address `
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=cascade-ecs-instance}]" `
    --region $Region `
    --query 'Instances[0].InstanceId' `
    --output text 2>&1)

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to launch instance: $NewInstanceId" -ForegroundColor Red
    exit 1
}

Write-Host "New instance launched: $NewInstanceId" -ForegroundColor Green
Write-Host "`nWaiting for instance to start and register with ECS (120 seconds)..."
Start-Sleep -Seconds 120

# Check if instance registered
Write-Host "`nChecking ECS cluster registration..."
$containerInstances = (aws ecs list-container-instances --cluster $ClusterName --region $Region --query 'containerInstanceArns' --output text)

if ($containerInstances) {
    Write-Host "SUCCESS! Instance registered with ECS cluster!" -ForegroundColor Green
} else {
    Write-Host "WARNING: Instance not registered yet. Wait another 60 seconds and check logs." -ForegroundColor Yellow
}

# Get new public IP
$NewPublicIp = (aws ec2 describe-instances --instance-ids $NewInstanceId --region $Region --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
Write-Host "`nNew Public IP: $NewPublicIp" -ForegroundColor Cyan

# Force service update to deploy task
Write-Host "`nForcing ECS service to deploy container..."
aws ecs update-service --cluster $ClusterName --service cascade-service --force-new-deployment --region $Region | Out-Null

Write-Host "`nWaiting for container to start (60 seconds)..."
Start-Sleep -Seconds 60

# Test the deployment
Write-Host "`nTesting challenge endpoint..."
try {
    $response = Invoke-RestMethod "http://${NewPublicIp}:3000/health" -TimeoutSec 10
    Write-Host "SUCCESS! Challenge is LIVE!" -ForegroundColor Green
    Write-Host "URL: http://${NewPublicIp}:3000" -ForegroundColor Green
} catch {
    Write-Host "Container may still be starting. Test manually in 2-3 minutes:" -ForegroundColor Yellow
    Write-Host "curl http://${NewPublicIp}:3000/health" -ForegroundColor Cyan
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Challenge URL: http://${NewPublicIp}:3000" -ForegroundColor Green
Write-Host "Instance ID: $NewInstanceId"
Write-Host "========================================" -ForegroundColor Cyan

# Update deployment info
$DeploymentInfo = @"
Cascade Challenge Deployment

Challenge URL: http://${NewPublicIp}:3000

Instance ID: $NewInstanceId
Security Group: $SgId
Region: $Region

View Logs:
aws logs tail /ecs/cascade-challenge --follow --region $Region

Cleanup:
aws ecs delete-service --cluster $ClusterName --service cascade-service --force --region $Region
aws ec2 terminate-instances --instance-ids $NewInstanceId --region $Region
"@

$DeploymentInfo | Out-File -FilePath deployment-info.txt -Encoding UTF8
Write-Host "`nDeployment info updated in: deployment-info.txt" -ForegroundColor Yellow
