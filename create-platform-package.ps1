# Cascade Challenge - Platform Deployment Package Creator
# Run this script to create a clean package for CTF platform providers

Write-Host "`nCascade CTF - Platform Deployment Package Creator`n" -ForegroundColor Cyan

# Configuration
$packageName = "cascade-challenge-platform-v1.0"
$distDir = ".\$packageName"

# Clean old package
Write-Host "[1/6] Cleaning old package..." -ForegroundColor Yellow
if (Test-Path $distDir) {
    Remove-Item -Recurse -Force $distDir
}
New-Item -ItemType Directory -Path $distDir | Out-Null

# Copy platform files
Write-Host "[2/6] Copying platform files..." -ForegroundColor Yellow
Copy-Item "PLAYER_GUIDE.md" $distDir
Copy-Item "PLATFORM_HOSTING_GUIDE.md" $distDir
Copy-Item "challenge-config.json" $distDir
Copy-Item "docker-compose.yml" $distDir
Copy-Item "Dockerfile" $distDir
Copy-Item "README_DISTRIBUTION.md" "$distDir\README.md"

# Build Docker image
Write-Host "[3/6] Building Docker image..." -ForegroundColor Yellow
docker build -t cascade-ctf:v1.0 . 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Docker build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "   ✓ Image built successfully" -ForegroundColor Green

# Export Docker image
Write-Host "[4/6] Exporting Docker image..." -ForegroundColor Yellow
docker save cascade-ctf:v1.0 -o "$distDir\cascade-ctf-v1.0.tar"
$imageSize = (Get-Item "$distDir\cascade-ctf-v1.0.tar").Length / 1MB
Write-Host "   Docker image exported: $([math]::Round($imageSize, 2)) MB" -ForegroundColor Green

# Create email template
Write-Host "[5/6] Creating email template..." -ForegroundColor Yellow
$imageSizeMB = [math]::Round($imageSize, 0)
$emailFile = "$distDir\email-template.txt"

"Subject: Cascade Web Challenge - Deployment Request" | Out-File $emailFile -Encoding UTF8
"" | Add-Content $emailFile
"Hi [Platform Team]," | Add-Content $emailFile
"" | Add-Content $emailFile
"We would like to host the Cascade web exploitation challenge on your platform." | Add-Content $emailFile
"" | Add-Content $emailFile
"CHALLENGE DETAILS:" | Add-Content $emailFile
"Name: Cascade" | Add-Content $emailFile
"Category: Web Exploitation" | Add-Content $emailFile
"Difficulty: Medium (7/10)" | Add-Content $emailFile
"Points: 400-500" | Add-Content $emailFile
"Technology: Docker (Node.js 18)" | Add-Content $emailFile
"Ports: 3000 (main), 3001 (internal service)" | Add-Content $emailFile
"Resources: 0.5 CPU, 512MB RAM per instance" | Add-Content $emailFile
""  | Add-Content $emailFile
"FILES ATTACHED:" | Add-Content $emailFile
"cascade-ctf-v1.0.tar (Docker image, approx $imageSizeMB MB)" | Add-Content $emailFile
"PLAYER_GUIDE.md" | Add-Content $emailFile
"PLATFORM_HOSTING_GUIDE.md" | Add-Content $emailFile
"challenge-config.json" | Add-Content $emailFile
"docker-compose.yml" | Add-Content $emailFile
"README.md" | Add-Content $emailFile
"" | Add-Content $emailFile
"DEPLOYMENT REQUIREMENTS:" | Add-Content $emailFile
"Both ports (3000, 3001) must be accessible" | Add-Content $emailFile
"512MB RAM per instance minimum" | Add-Content $emailFile
"Rate limiting: Built-in" | Add-Content $emailFile
"Flag: MEDUSA2{s0_m4ny_l4y3r5_t0_peel_b4ck}" | Add-Content $emailFile
"" | Add-Content $emailFile
"SUPPORT:" | Add-Content $emailFile
"Repository: https://github.com/Maleesha101/Cascade-CTF" | Add-Content $emailFile
"" | Add-Content $emailFile
"Please let us know if you need additional information." | Add-Content $emailFile
"" | Add-Content $emailFile
"Thank you!" | Add-Content $emailFile

Write-Host "   ✓ Email template created" -ForegroundColor Green

# Create archive
Write-Host "[6/6] Creating distribution archive..." -ForegroundColor Yellow
$archiveName = "$packageName.zip"
if (Test-Path $archiveName) {
    Remove-Item -Force $archiveName
}
Compress-Archive -Path $distDir -DestinationPath $archiveName
$archiveSize = (Get-Item $archiveName).Length / 1MB
$archiveSizeMB = [math]::Round($archiveSize, 2)
Write-Host "   Archive created: $archiveName - $archiveSizeMB MB" -ForegroundColor Green

# Summary
Write-Host "`nPackage Creation Complete!" -ForegroundColor Green
Write-Host "" -ForegroundColor Green

Write-Host "Package Contents:" -ForegroundColor Cyan
Write-Host "   PLAYER_GUIDE.md" -ForegroundColor White
Write-Host "   PLATFORM_HOSTING_GUIDE.md" -ForegroundColor White
Write-Host "   challenge-config.json" -ForegroundColor White
Write-Host "   docker-compose.yml" -ForegroundColor White
Write-Host "   Dockerfile" -ForegroundColor White
Write-Host "   README.md" -ForegroundColor White
$imageSizeStr = [math]::Round($imageSize, 2)
Write-Host "   cascade-ctf-v1.0.tar - $imageSizeStr MB" -ForegroundColor White
Write-Host "   email-template.txt" -ForegroundColor White
Write-Host "" -ForegroundColor White

Write-Host "Ready to Send:" -ForegroundColor Cyan
Write-Host "   File: $archiveName" -ForegroundColor Yellow
Write-Host "   Size: $archiveSizeMB MB" -ForegroundColor Yellow
Write-Host "" -ForegroundColor Yellow

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Upload $archiveName to file sharing service" -ForegroundColor White
Write-Host "   2. Copy email template from: $distDir\email-template.txt" -ForegroundColor White
Write-Host "   3. Send to platform provider with download link" -ForegroundColor White
Write-Host "   4. Wait for confirmation and testing" -ForegroundColor White
Write-Host "" -ForegroundColor White

Write-Host "Package ready for platform deployment!" -ForegroundColor Green
Write-Host ""
