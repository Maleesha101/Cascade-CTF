# ========================================
# Cascade Challenge - FREE TIER Deployment
# Run this on your Windows PC
# ========================================

$Region = "ap-south-1"
$ErrorActionPreference = "Continue"

Write-Host "Starting FREE TIER deployment..." -ForegroundColor Cyan

# Step 1: Get Account Info
$AccountId = (aws sts get-caller-identity --query Account --output text 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Host "AWS credentials not configured properly" -ForegroundColor Red
    Write-Host "Run: aws configure" -ForegroundColor Yellow
    exit 1
}
Write-Host "Account ID: $AccountId"

# Step 2: Create ECR Repository
Write-Host "`nSetting up ECR repository..."
$RepoUri = $null

$existingRepo = aws ecr describe-repositories --repository-names cascade-challenge --region $Region 2>&1
if ($LASTEXITCODE -eq 0) {
    $RepoUri = (aws ecr describe-repositories --repository-names cascade-challenge --region $Region --query 'repositories[0].repositoryUri' --output text)
    Write-Host "Using existing repository: $RepoUri"
}
else {
    Write-Host "Creating new ECR repository..."
    aws ecr create-repository --repository-name cascade-challenge --region $Region | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        $RepoUri = (aws ecr describe-repositories --repository-names cascade-challenge --region $Region --query 'repositories[0].repositoryUri' --output text)
        Write-Host "Repository created: $RepoUri"
    }
    else {
        Write-Host "Failed to create ECR repository" -ForegroundColor Red
        exit 1
    }
}

# Step 3: Check Docker
Write-Host "`nChecking Docker..."
docker ps 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}
Write-Host "Docker is running"

# Step 4: Build Docker Image
Write-Host "`nBuilding Docker image..."
docker build -t cascade-challenge .
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker build failed" -ForegroundColor Red
    exit 1
}
Write-Host "Image built"

# Step 5: Login to ECR and Push
Write-Host "`nLogging into ECR..."
$loginCmd = aws ecr get-login-password --region $Region
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to get ECR login" -ForegroundColor Red
    exit 1
}

$loginCmd | docker login --username AWS --password-stdin "$AccountId.dkr.ecr.$Region.amazonaws.com"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker login failed" -ForegroundColor Red
    exit 1
}
Write-Host "Logged into ECR"

Write-Host "`nPushing image to ECR (this may take 2-3 minutes)..."
docker tag cascade-challenge:latest "$RepoUri`:latest"
docker push "$RepoUri`:latest"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to push image" -ForegroundColor Red
    exit 1
}
Write-Host "Image pushed successfully"

# Step 6: Create ECS Cluster
Write-Host "`nCreating ECS cluster..."
$clusterExists = aws ecs describe-clusters --clusters cascade-ctf-cluster --region $Region --query 'clusters[0].status' --output text 2>&1

if ($clusterExists -ne "ACTIVE") {
    aws ecs create-cluster --cluster-name cascade-ctf-cluster --region $Region | Out-Null
    Write-Host "Cluster created"
}
else {
    Write-Host "Using existing cluster"
}

# Step 7: Create IAM Roles
Write-Host "`nSetting up IAM roles..."

# ECS Task Execution Role - create JSON file
$TaskExecTrustJson = @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Effect = "Allow"
            Principal = @{ Service = "ecs-tasks.amazonaws.com" }
            Action = "sts:AssumeRole"
        }
    )
} | ConvertTo-Json -Depth 10 -Compress

$TaskExecTrustJson | Out-File -FilePath "task-exec-trust.json" -Encoding ascii -NoNewline

$roleExists = aws iam get-role --role-name ecsTaskExecutionRole 2>&1
if ($LASTEXITCODE -ne 0) {
    aws iam create-role --role-name ecsTaskExecutionRole --assume-role-policy-document file://task-exec-trust.json | Out-Null
    aws iam attach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
    Write-Host "Task execution role created"
}
else {
    Write-Host "Task execution role exists"
}

# EC2 Instance Role
$Ec2TrustJson = @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Effect = "Allow"
            Principal = @{ Service = "ec2.amazonaws.com" }
            Action = "sts:AssumeRole"
        }
    )
} | ConvertTo-Json -Depth 10 -Compress

$Ec2TrustJson | Out-File -FilePath "ec2-trust.json" -Encoding ascii -NoNewline

$ec2RoleExists = aws iam get-role --role-name ecsInstanceRole 2>&1
if ($LASTEXITCODE -ne 0) {
    aws iam create-role --role-name ecsInstanceRole --assume-role-policy-document file://ec2-trust.json | Out-Null
    aws iam attach-role-policy --role-name ecsInstanceRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role
    Write-Host "EC2 instance role created"
}
else {
    Write-Host "EC2 instance role exists"
}

# Create instance profile
$profileExists = aws iam get-instance-profile --instance-profile-name ecsInstanceProfile 2>&1
if ($LASTEXITCODE -ne 0) {
    aws iam create-instance-profile --instance-profile-name ecsInstanceProfile | Out-Null
    Start-Sleep -Seconds 10
    aws iam add-role-to-instance-profile --instance-profile-name ecsInstanceProfile --role-name ecsInstanceRole 2>&1 | Out-Null
    Write-Host "Instance profile created"
}
else {
    Write-Host "Instance profile exists"
}

# Step 8: Create Security Group
Write-Host "`nSetting up security group..."
$VpcId = (aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text --region $Region)
$SubnetId = (aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VpcId" --query 'Subnets[0].SubnetId' --output text --region $Region)

$SgId = (aws ec2 describe-security-groups --filters "Name=group-name,Values=cascade-sg" "Name=vpc-id,Values=$VpcId" --region $Region --query 'SecurityGroups[0].GroupId' --output text 2>&1)

if ($SgId -eq "" -or $SgId -eq "None" -or $LASTEXITCODE -ne 0) {
    $SgId = (aws ec2 create-security-group --group-name cascade-sg --description "Cascade CTF Security Group" --vpc-id $VpcId --region $Region --query 'GroupId' --output text)
    
    aws ec2 authorize-security-group-ingress --group-id $SgId --protocol tcp --port 3000 --cidr 0.0.0.0/0 --region $Region 2>&1 | Out-Null
    aws ec2 authorize-security-group-ingress --group-id $SgId --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $Region 2>&1 | Out-Null
    Write-Host "Security group created: $SgId"
}
else {
    Write-Host "Using existing security group: $SgId"
}

# Step 9: Create CloudWatch Log Group
Write-Host "`nCreating log group..."
$logGroupExists = aws logs describe-log-groups --log-group-name-prefix /ecs/cascade-challenge --region $Region --query 'logGroups[0].logGroupName' --output text 2>&1
if ($logGroupExists -ne "/ecs/cascade-challenge") {
    aws logs create-log-group --log-group-name /ecs/cascade-challenge --region $Region 2>&1 | Out-Null
    Write-Host "Log group created"
}
else {
    Write-Host "Log group exists"
}

# Step 10: Create Task Definition
Write-Host "`nCreating task definition..."

$TaskDefJson = @{
    family = "cascade-challenge"
    networkMode = "bridge"
    requiresCompatibilities = @("EC2")
    cpu = "256"
    memory = "512"
    executionRoleArn = "arn:aws:iam::${AccountId}:role/ecsTaskExecutionRole"
    containerDefinitions = @(
        @{
            name = "cascade-challenge"
            image = "${RepoUri}:latest"
            essential = $true
            portMappings = @(
                @{
                    containerPort = 3000
                    hostPort = 3000
                    protocol = "tcp"
                }
            )
            environment = @(
                @{ name = "NODE_ENV"; value = "production" }
                @{ name = "PORT"; value = "3000" }
            )
            logConfiguration = @{
                logDriver = "awslogs"
                options = @{
                    "awslogs-group" = "/ecs/cascade-challenge"
                    "awslogs-region" = $Region
                    "awslogs-stream-prefix" = "ecs"
                }
            }
        }
    )
} | ConvertTo-Json -Depth 10 -Compress

$TaskDefJson | Out-File -FilePath task-definition.json -Encoding ascii -NoNewline
aws ecs register-task-definition --cli-input-json file://task-definition.json --region $Region | Out-Null
Write-Host "Task definition registered"

# Step 11: Launch EC2 Instance
Write-Host "`nLaunching EC2 t2.micro instance (FREE TIER)..."

$existingInstance = aws ec2 describe-instances --filters "Name=tag:Name,Values=cascade-ecs-instance" "Name=instance-state-name,Values=running,pending" --query 'Reservations[0].Instances[0].InstanceId' --output text --region $Region 2>&1

if ($existingInstance -and $existingInstance -ne "None" -and $existingInstance -ne "") {
    $InstanceId = $existingInstance
    Write-Host "Using existing instance: $InstanceId"
}
else {
    Write-Host "Creating new EC2 instance..."
    
    # Get ECS-optimized AMI
    $AmiId = (aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id --region $Region --query 'Parameters[0].Value' --output text)
    Write-Host "Using AMI: $AmiId"

    # User data script
    $UserData = @"
#!/bin/bash
echo ECS_CLUSTER=cascade-ctf-cluster >> /etc/ecs/ecs.config
"@

    $UserDataBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($UserData))

    # Try to find a suitable instance type
    Write-Host "Finding available instance type..."
    
    # Try these instance types in order (cheapest first)
    $instanceTypes = @("t3.micro", "t4g.micro", "t3.small", "t2.micro")
    $instanceTypeToUse = $null
    
    foreach ($type in $instanceTypes) {
        Write-Host "Checking if $type is available in region..."
        $available = aws ec2 describe-instance-type-offerings --location-type availability-zone --filters "Name=instance-type,Values=$type" --region $Region --query 'InstanceTypeOfferings[0].InstanceType' --output text 2>&1
        if ($available -eq $type) {
            $instanceTypeToUse = $type
            Write-Host "Will use instance type: $type" -ForegroundColor Green
            break
        }
    }
    
    if (-not $instanceTypeToUse) {
        Write-Host "ERROR: No suitable instance type found!" -ForegroundColor Red
        exit 1
    }
    
    # Important note about free tier
    Write-Host "`nIMPORTANT:" -ForegroundColor Yellow
    Write-Host "- If your AWS account is within the first 12 months, this may be FREE" -ForegroundColor Yellow
    Write-Host "- If not, this will cost approximately $0.01-0.02 per hour" -ForegroundColor Yellow
    Write-Host "- For a 3-hour CTF event, cost will be less than $0.10" -ForegroundColor Yellow
    Write-Host "- Remember to terminate the instance after the CTF!" -ForegroundColor Yellow
    Start-Sleep -Seconds 3
    
    # Launch instance WITHOUT free-tier-eligible flag
    Write-Host "`nLaunching instance with $instanceTypeToUse..."
    $InstanceId = (aws ec2 run-instances --image-id $AmiId --instance-type $instanceTypeToUse --iam-instance-profile Name=ecsInstanceProfile --security-group-ids $SgId --subnet-id $SubnetId --user-data $UserDataBase64 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=cascade-ecs-instance}]" --region $Region --query 'Instances[0].InstanceId' --output text 2>&1)

    if ($LASTEXITCODE -ne 0 -or -not $InstanceId -or $InstanceId -eq "None") {
        Write-Host "Failed to launch instance. Error: $InstanceId" -ForegroundColor Red
        exit 1
    }

    Write-Host "Instance launched: $InstanceId"
    Write-Host "Waiting for instance to initialize (90 seconds)..."
    Start-Sleep -Seconds 90
}

# Get public IP with retry
Write-Host "Getting public IP address..."
$maxRetries = 10
$retryCount = 0
$PublicIp = $null

while ($retryCount -lt $maxRetries -and (-not $PublicIp -or $PublicIp -eq "None" -or $PublicIp -eq "")) {
    $PublicIp = (aws ec2 describe-instances --instance-ids $InstanceId --region $Region --query 'Reservations[0].Instances[0].PublicIpAddress' --output text 2>&1)
    
    if (-not $PublicIp -or $PublicIp -eq "None" -or $PublicIp -eq "") {
        $retryCount++
        Write-Host "Waiting for public IP (attempt $retryCount of $maxRetries)..."
        Start-Sleep -Seconds 10
    }
}

if (-not $PublicIp -or $PublicIp -eq "None" -or $PublicIp -eq "") {
    Write-Host "Could not get public IP address. Check instance status:" -ForegroundColor Red
    Write-Host "aws ec2 describe-instances --instance-ids $InstanceId --region $Region" -ForegroundColor Yellow
    exit 1
}

Write-Host "Public IP: $PublicIp"

# Step 12: Create ECS Service
Write-Host "`nCreating ECS service..."
$serviceExists = aws ecs describe-services --cluster cascade-ctf-cluster --services cascade-service --region $Region --query 'services[0].status' --output text 2>&1

if ($serviceExists -ne "ACTIVE") {
    aws ecs create-service --cluster cascade-ctf-cluster --service-name cascade-service --task-definition cascade-challenge --desired-count 1 --launch-type EC2 --region $Region | Out-Null
    Write-Host "Service created"
    Write-Host "Waiting for container to start (60 seconds)..."
    Start-Sleep -Seconds 60
}
else {
    Write-Host "Service already exists, updating..."
    aws ecs update-service --cluster cascade-ctf-cluster --service cascade-service --force-new-deployment --region $Region | Out-Null
    Write-Host "Waiting for deployment (60 seconds)..."
    Start-Sleep -Seconds 60
}

# Step 13: Test Deployment
Write-Host "`nTesting deployment..."
$maxRetries = 5
$retryCount = 0
$success = $false

while ($retryCount -lt $maxRetries -and -not $success) {
    try {
        $response = Invoke-RestMethod "http://${PublicIp}:3000/health" -TimeoutSec 10 -ErrorAction Stop
        Write-Host "Challenge is LIVE!" -ForegroundColor Green
        Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Green
        $success = $true
    }
    catch {
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-Host "Attempt $retryCount of $maxRetries - Service still starting, waiting 20 seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds 20
        }
        else {
            Write-Host "Could not connect after $maxRetries attempts" -ForegroundColor Yellow
            Write-Host "The service may still be starting. Wait 2-3 minutes and test manually:" -ForegroundColor Yellow
            Write-Host "   curl http://${PublicIp}:3000/health" -ForegroundColor Cyan
        }
    }
}

# Step 14: Save Info
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Challenge URL: http://${PublicIp}:3000" -ForegroundColor Green
Write-Host "`nDetails:" -ForegroundColor Cyan
Write-Host "   Instance ID: $InstanceId"
Write-Host "   Security Group: $SgId"
Write-Host "   Region: $Region"
Write-Host "   ECR Repository: $RepoUri"
Write-Host "   Account ID: $AccountId"

Write-Host "`nGIVE TO COMPETITORS:" -ForegroundColor Yellow
Write-Host "   http://${PublicIp}:3000" -ForegroundColor Green

Write-Host "`nVIEW LOGS:" -ForegroundColor Cyan
Write-Host "   aws logs tail /ecs/cascade-challenge --follow --region $Region"

Write-Host "`nRESTART SERVICE:" -ForegroundColor Cyan
Write-Host "   aws ecs update-service --cluster cascade-ctf-cluster --service cascade-service --force-new-deployment --region $Region"

Write-Host "`nCLEANUP (after CTF):" -ForegroundColor Cyan
Write-Host "   aws ecs delete-service --cluster cascade-ctf-cluster --service cascade-service --force --region $Region"
Write-Host "   aws ec2 terminate-instances --instance-ids $InstanceId --region $Region"

Write-Host "`nCOST ESTIMATE:" -ForegroundColor Green
Write-Host "   Instance Type: t3.micro (or t4g.micro)"
Write-Host "   If FREE TIER eligible: $0.00"
Write-Host "   If NOT free tier: ~$0.01/hour = ~$0.10 for 10-hour event"
Write-Host "   ECR: FREE for 500MB storage"
Write-Host "   Data transfer: FREE for 1GB/month"
Write-Host "`n   TOTAL FOR 10-HOUR CTF: $0.00 to $0.10" -ForegroundColor Cyan

Write-Host "`n========================================" -ForegroundColor Cyan

# Save to file
$DeploymentInfo = @"
Cascade Challenge Deployment

Challenge URL: http://${PublicIp}:3000

Instance ID: $InstanceId
Security Group: $SgId
Region: $Region
ECR Repository: $RepoUri
Account ID: $AccountId

View Logs:
aws logs tail /ecs/cascade-challenge --follow --region $Region

Restart Service:
aws ecs update-service --cluster cascade-ctf-cluster --service cascade-service --force-new-deployment --region $Region

Cleanup:
aws ecs delete-service --cluster cascade-ctf-cluster --service cascade-service --force --region $Region
aws ec2 terminate-instances --instance-ids $InstanceId --region $Region
"@

$DeploymentInfo | Out-File -FilePath deployment-info.txt -Encoding UTF8
Write-Host "Deployment info saved to: deployment-info.txt" -ForegroundColor Yellow
