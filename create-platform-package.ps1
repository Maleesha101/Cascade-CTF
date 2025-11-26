# Cascade Challenge - Platform Deployment Package Creator
# Run this script to create a clean package for CTF platform providers

Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Cascade CTF - Platform Deployment Package Creator    ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

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
docker save cascade-ctf:v1.0 | gzip > "$distDir\cascade-ctf-v1.0.tar.gz"
$imageSize = (Get-Item "$distDir\cascade-ctf-v1.0.tar.gz").Length / 1MB
Write-Host "   ✓ Image exported: $([math]::Round($imageSize, 2)) MB" -ForegroundColor Green

# Create email template
Write-Host "[5/6] Creating email template..." -ForegroundColor Yellow
$emailTemplate = @"
Subject: Cascade Web Challenge - Deployment Request

Hi [Platform Team],

We'd like to host the "Cascade" web exploitation challenge on your platform.

CHALLENGE DETAILS:
------------------
Name: Cascade
Category: Web Exploitation
Difficulty: Medium (7/10)
Points: 400-500
Technology: Docker (Node.js 18)
Ports: 3000 (main), 3001 (internal service)
Resources: 0.5 CPU, 512MB RAM per instance

FILES ATTACHED:
--------------
✓ cascade-ctf-v1.0.tar.gz - Docker image (~$([math]::Round($imageSize, 0)) MB)
✓ PLAYER_GUIDE.md - Player documentation & hints
✓ PLATFORM_HOSTING_GUIDE.md - Deployment instructions
✓ challenge-config.json - Platform configuration
✓ docker-compose.yml - Testing configuration
✓ README.md - Overview

DEPLOYMENT REQUIREMENTS:
-----------------------
✓ Both ports (3000, 3001) must be accessible
✓ 512MB RAM per instance minimum
✓ Rate limiting: Built-in (10 req/min per IP on critical endpoints)
✓ Flag: MEDUSA2{s0_m4ny_l4y3r5_t0_peel_b4ck}

TESTING INSTRUCTIONS:
--------------------
# Load image
docker load -i cascade-ctf-v1.0.tar.gz

# Test run
docker run -d -p 3000:3000 -p 3001:3001 --name test-cascade cascade-ctf:v1.0

# Verify health
curl http://localhost:3000/health
# Expected: {"status":"ok","service":"cascade"}

# Verify flag
docker exec test-cascade cat /tmp/flag.txt
# Expected: MEDUSA2{s0_m4ny_l4y3r5_t0_peel_b4ck}

DEPLOYMENT PREFERENCE:
---------------------
Please advise on:
1. Do you support dynamic flags per team?
2. What's the maximum number of concurrent instances?
3. Individual instances per team or shared pool?

SUPPORT:
--------
Repository: https://github.com/Maleesha101/Cascade-CTF
Issues: https://github.com/Maleesha101/Cascade-CTF/issues
Contact: [Your Email/Discord]

Please let us know if you need any additional information.

Thank you!
[Your Name]
[Your Team]
"@

$emailTemplate | Out-File -FilePath "$distDir\email-template.txt" -Encoding UTF8
Write-Host "   ✓ Email template created" -ForegroundColor Green

# Create archive
Write-Host "[6/6] Creating distribution archive..." -ForegroundColor Yellow
$archiveName = "$packageName.zip"
if (Test-Path $archiveName) {
    Remove-Item -Force $archiveName
}
Compress-Archive -Path $distDir -DestinationPath $archiveName
$archiveSize = (Get-Item $archiveName).Length / 1MB
Write-Host "   ✓ Archive created: $archiveName ($([math]::Round($archiveSize, 2)) MB)" -ForegroundColor Green

# Summary
Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              Package Creation Complete! ✓                 ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "📦 Package Contents:" -ForegroundColor Cyan
Write-Host "   • PLAYER_GUIDE.md" -ForegroundColor White
Write-Host "   • PLATFORM_HOSTING_GUIDE.md" -ForegroundColor White
Write-Host "   • challenge-config.json" -ForegroundColor White
Write-Host "   • docker-compose.yml" -ForegroundColor White
Write-Host "   • Dockerfile" -ForegroundColor White
Write-Host "   • README.md" -ForegroundColor White
Write-Host "   • cascade-ctf-v1.0.tar.gz ($([math]::Round($imageSize, 2)) MB)" -ForegroundColor White
Write-Host "   • email-template.txt`n" -ForegroundColor White

Write-Host "📤 Ready to Send:" -ForegroundColor Cyan
Write-Host "   File: $archiveName" -ForegroundColor Yellow
Write-Host "   Size: $([math]::Round($archiveSize, 2)) MB`n" -ForegroundColor Yellow

Write-Host "📧 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Upload $archiveName to file sharing service" -ForegroundColor White
Write-Host "   2. Copy email template from: $distDir\email-template.txt" -ForegroundColor White
Write-Host "   3. Send to platform provider with download link" -ForegroundColor White
Write-Host "   4. Wait for confirmation and testing`n" -ForegroundColor White

Write-Host "✓ Package ready for platform deployment!" -ForegroundColor Green
Write-Host ""
