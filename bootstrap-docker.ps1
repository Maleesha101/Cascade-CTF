# Enable SSM and Deploy Container
$Region = "ap-south-1"
$InstanceId = "i-0d3e9eb155b1baff0"
$PublicIp = "13.233.131.50"
$AccountId = "149195854976"
$RepoUri = "149195854976.dkr.ecr.ap-south-1.amazonaws.com/cascade-challenge"

Write-Host "Enabling SSM access and deploying container..." -ForegroundColor Cyan

# Step 1: Attach SSM policy to the instance role
Write-Host "`nStep 1: Adding SSM permissions to instance role..."
aws iam attach-role-policy --role-name ecsInstanceRole --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore --region $Region 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "SSM policy attached successfully" -ForegroundColor Green
} else {
    Write-Host "SSM policy might already be attached" -ForegroundColor Yellow
}

# Step 2: Install SSM agent via user data (requires reboot)
Write-Host "`nStep 2: Checking if we can use an alternative method..."

# Option A: Try using EC2 Instance Connect (no key required)
Write-Host "`nAttempting EC2 Instance Connect method..." -ForegroundColor Cyan

# Create a temporary SSH key
$TempKeyName = "cascade-temp-key-$(Get-Random)"
Write-Host "Creating temporary EC2 key pair: $TempKeyName"

$keyOutput = aws ec2 create-key-pair --key-name $TempKeyName --query 'KeyMaterial' --output text --region $Region 2>&1

if ($LASTEXITCODE -eq 0) {
    $keyOutput | Out-File -FilePath "temp-key.pem" -Encoding ASCII
    Write-Host "Key pair created and saved to temp-key.pem" -ForegroundColor Green
    
    # Set proper permissions (Windows doesn't use chmod, but note for user)
    Write-Host "`nNow you can SSH into the instance:"
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "ssh -i temp-key.pem ec2-user@$PublicIp" -ForegroundColor Yellow
    Write-Host "`nOr I can create a script that does it automatically..." -ForegroundColor Cyan
    
    # Create an automated deployment script
    $sshCommands = @"
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
aws ecr get-login-password --region $Region | sudo docker login --username AWS --password-stdin $AccountId.dkr.ecr.$Region.amazonaws.com
sudo docker pull $RepoUri:latest
sudo docker stop cascade-challenge 2>/dev/null || true
sudo docker rm cascade-challenge 2>/dev/null || true
sudo docker run -d --name cascade-challenge --restart always -p 3000:3000 $RepoUri:latest
echo "Container deployed! Testing..."
sleep 5
curl http://localhost:3000/health
"@
    
    $sshCommands | Out-File -FilePath "remote-deploy.sh" -Encoding UTF8
    
    Write-Host "`nBUT WAIT - You don't have SSH client or the key won't work on Windows!" -ForegroundColor Yellow
    Write-Host "Let me use a different approach..." -ForegroundColor Cyan
    
    # Delete the temp key since we can't easily use it on Windows
    aws ec2 delete-key-pair --key-name $TempKeyName --region $Region 2>&1 | Out-Null
    Remove-Item temp-key.pem -ErrorAction SilentlyContinue
}

# Option B: Use User Data to bootstrap on next reboot
Write-Host "`nOption B: Installing via User Data (requires instance restart)..." -ForegroundColor Cyan

$BootstrapScript = @"
#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $AccountId.dkr.ecr.$Region.amazonaws.com
docker pull $RepoUri:latest
docker stop cascade-challenge 2>/dev/null || true
docker rm cascade-challenge 2>/dev/null || true
docker run -d --name cascade-challenge --restart always -p 3000:3000 $RepoUri:latest
"@

$UserDataBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($BootstrapScript))

Write-Host "Stopping instance to apply user data..."
aws ec2 stop-instances --instance-ids $InstanceId --region $Region | Out-Null
Start-Sleep -Seconds 20

Write-Host "Modifying instance user data..."
aws ec2 modify-instance-attribute --instance-id $InstanceId --user-data Value=$UserDataBase64 --region $Region

Write-Host "Starting instance..."
aws ec2 start-instances --instance-ids $InstanceId --region $Region | Out-Null

Write-Host "`nWaiting for instance to boot and run setup (120 seconds)..."
Start-Sleep -Seconds 120

# Get new public IP (it might change after restart)
$NewPublicIp = (aws ec2 describe-instances --instance-ids $InstanceId --region $Region --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
Write-Host "New Public IP: $NewPublicIp" -ForegroundColor Cyan

Write-Host "`nTesting challenge endpoint..."
$maxRetries = 10
$retryCount = 0

while ($retryCount -lt $maxRetries) {
    try {
        $response = Invoke-RestMethod "http://${NewPublicIp}:3000/health" -TimeoutSec 10 -ErrorAction Stop
        Write-Host "`nSUCCESS! Challenge is LIVE!" -ForegroundColor Green
        Write-Host "Challenge URL: http://${NewPublicIp}:3000" -ForegroundColor Green
        Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Cyan
        break
    } catch {
        $retryCount++
        Write-Host "Attempt $retryCount/$maxRetries - Waiting for container to start..." -ForegroundColor Yellow
        Start-Sleep -Seconds 15
    }
}

if ($retryCount -ge $maxRetries) {
    Write-Host "`nContainer may still be starting. Check in a few minutes:" -ForegroundColor Yellow
    Write-Host "curl http://${NewPublicIp}:3000/health" -ForegroundColor Cyan
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "FINAL CHALLENGE URL: http://${NewPublicIp}:3000" -ForegroundColor Green
Write-Host "Instance ID: $InstanceId"
Write-Host "========================================" -ForegroundColor Cyan

# Update deployment info
$DeploymentInfo = @"
Cascade Challenge Deployment

Challenge URL: http://${NewPublicIp}:3000

Instance ID: $InstanceId
Region: $Region

To restart container:
ssh to instance and run: sudo docker restart cascade-challenge

Cleanup:
aws ec2 terminate-instances --instance-ids $InstanceId --region $Region
"@

$DeploymentInfo | Out-File -FilePath deployment-info.txt -Encoding UTF8
Write-Host "`nDeployment info saved to deployment-info.txt" -ForegroundColor Yellow
