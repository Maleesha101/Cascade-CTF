# Simple Docker Deployment (Without ECS)
$Region = "ap-south-1"
$AccountId = "149195854976"
$RepoUri = "149195854976.dkr.ecr.ap-south-1.amazonaws.com/cascade-challenge"

Write-Host "Deploying challenge directly with Docker (simpler approach)..." -ForegroundColor Cyan

# Get instance details
$InstanceId = (aws ec2 describe-instances --filters "Name=tag:Name,Values=cascade-ecs-instance" "Name=instance-state-name,Values=running" --region $Region --query 'Reservations[0].Instances[0].InstanceId' --output text)
$PublicIp = (aws ec2 describe-instances --instance-ids $InstanceId --region $Region --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

if (-not $InstanceId -or $InstanceId -eq "None") {
    Write-Host "No instance found!" -ForegroundColor Red
    exit 1
}

Write-Host "Instance ID: $InstanceId"
Write-Host "Public IP: $PublicIp"

# Create a startup script
$StartupScript = @"
#!/bin/bash
# Install Docker
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker

# Login to ECR
aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $AccountId.dkr.ecr.$Region.amazonaws.com

# Pull and run container
docker pull $RepoUri:latest
docker stop cascade-challenge 2>/dev/null || true
docker rm cascade-challenge 2>/dev/null || true
docker run -d --name cascade-challenge --restart always -p 3000:3000 $RepoUri:latest

echo "Container started!"
"@

# Save script locally
$StartupScript | Out-File -FilePath "startup.sh" -Encoding UTF8

Write-Host "`nScript created. Now we need to run it on the EC2 instance."
Write-Host "`nOPTION 1: Use AWS Systems Manager (SSM) - Recommended"
Write-Host "========================================" -ForegroundColor Cyan

# Check if SSM agent is available
$ssmStatus = aws ssm describe-instance-information --filters "Key=InstanceIds,Values=$InstanceId" --region $Region --query 'InstanceInformationList[0].PingStatus' --output text 2>&1

if ($ssmStatus -eq "Online") {
    Write-Host "SSM is available! Running deployment script..." -ForegroundColor Green
    
    $commands = @(
        "yum update -y",
        "yum install -y docker",
        "systemctl start docker",
        "systemctl enable docker",
        "aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $AccountId.dkr.ecr.$Region.amazonaws.com",
        "docker pull $RepoUri`:latest",
        "docker stop cascade-challenge 2>/dev/null || true",
        "docker rm cascade-challenge 2>/dev/null || true",
        "docker run -d --name cascade-challenge --restart always -p 3000:3000 $RepoUri`:latest"
    )
    
    foreach ($cmd in $commands) {
        Write-Host "Running: $cmd"
        aws ssm send-command --instance-ids $InstanceId --document-name "AWS-RunShellScript" --parameters "commands=[$cmd]" --region $Region --output text | Out-Null
        Start-Sleep -Seconds 5
    }
    
    Write-Host "`nWaiting for container to start (30 seconds)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    Write-Host "`nTesting endpoint..."
    try {
        $response = Invoke-RestMethod "http://${PublicIp}:3000/health" -TimeoutSec 10
        Write-Host "`nSUCCESS! Challenge is LIVE!" -ForegroundColor Green
        Write-Host "Challenge URL: http://${PublicIp}:3000" -ForegroundColor Green
    } catch {
        Write-Host "`nContainer may still be starting. Test in 2 minutes:" -ForegroundColor Yellow
        Write-Host "curl http://${PublicIp}:3000/health" -ForegroundColor Cyan
    }
} else {
    Write-Host "SSM not available. Using OPTION 2..." -ForegroundColor Yellow
    Write-Host "`nOPTION 2: Manual SSH Deployment"
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "`n1. Get your EC2 key pair or create one"
    Write-Host "2. SSH into the instance:"
    Write-Host "   ssh -i your-key.pem ec2-user@$PublicIp" -ForegroundColor Cyan
    Write-Host "`n3. Run these commands:"
    Write-Host "   sudo yum install -y docker" -ForegroundColor Cyan
    Write-Host "   sudo systemctl start docker" -ForegroundColor Cyan
    Write-Host "   aws ecr get-login-password --region $Region | sudo docker login --username AWS --password-stdin $AccountId.dkr.ecr.$Region.amazonaws.com" -ForegroundColor Cyan
    Write-Host "   sudo docker pull $RepoUri`:latest" -ForegroundColor Cyan
    Write-Host "   sudo docker run -d --name cascade-challenge --restart always -p 3000:3000 $RepoUri`:latest" -ForegroundColor Cyan
    Write-Host "`n4. Test: curl http://localhost:3000/health" -ForegroundColor Cyan
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Challenge URL: http://${PublicIp}:3000" -ForegroundColor Green
Write-Host "Instance ID: $InstanceId" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
