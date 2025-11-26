# 📦 Cascade Challenge - Distribution Checklist

## Before distributing to players, ensure:

### ✅ Files to INCLUDE for Players:
- [ ] `docker-compose.yml` - For local testing
- [ ] `Dockerfile` - Container configuration
- [ ] `PLAYER_GUIDE.md` - Main guide with hints
- [ ] `README_DISTRIBUTION.md` - Renamed to `README.md` for players
- [ ] `challenge-description.md` - Optional: Brief challenge description

### ❌ Files to EXCLUDE (Keep for Organizers):
- [ ] `exploit.py` - **DO NOT DISTRIBUTE** (automated solution)
- [ ] `exploit_hardened.py` - **DO NOT DISTRIBUTE** (advanced solution)
- [ ] `ORGANIZER_HINTS.md` - **DO NOT DISTRIBUTE** (hint strategy)
- [ ] `test-harness.js` - Testing only
- [ ] `app.js` - Source code (spoilers)
- [ ] `internal-service.js` - Source code (spoilers)
- [ ] `package.json` - Source code details
- [ ] All `deploy-*.ps1` scripts
- [ ] All AWS deployment files
- [ ] `IAM-PERMISSIONS-FIX.md`
- [ ] `cascade-ctf-admin-policy.json`
- [ ] `DEPLOYMENT.md`
- [ ] `HARDENED_CHALLENGE.md`

### 🐳 Docker Image Distribution

**Recommended**: Distribute as a **pre-built Docker image** instead of source code.

```bash
# 1. Build the final image
docker build -t cascade-ctf:v1.0 .

# 2. Save image to tar file
docker save cascade-ctf:v1.0 -o cascade-ctf-v1.0.tar

# 3. Compress (optional)
gzip cascade-ctf-v1.0.tar

# 4. Distribute cascade-ctf-v1.0.tar.gz to players
```

**Player load command:**
```bash
docker load -i cascade-ctf-v1.0.tar.gz
docker run -d -p 3000:3000 -p 3001:3001 cascade-ctf:v1.0
```

### 🔒 Alternative: Hide Source Completely

If you want players to have ZERO source code access:

1. **Only distribute:**
   - `PLAYER_GUIDE.md`
   - `README.md` (from README_DISTRIBUTION.md)
   - Docker image (tar.gz)

2. **Do not include:**
   - Dockerfile (reveals structure)
   - docker-compose.yml (reveals ports/config)
   - Any source files

3. **Provide:**
   - Competition server URL
   - Rate limit warnings
   - Hints document only

### 📝 Distribution Package Structure

**Option A: Full Local Testing**
```
cascade-challenge-player/
├── README.md                    (from README_DISTRIBUTION.md)
├── PLAYER_GUIDE.md             
├── docker-compose.yml
├── Dockerfile
└── cascade-ctf-v1.0.tar.gz     (pre-built image)
```

**Option B: Competition Only (No Source)**
```
cascade-challenge-player/
├── README.md                    (competition info)
├── PLAYER_GUIDE.md             (hints only)
└── cascade-ctf-v1.0.tar.gz     (optional - for local testing)
```

### 🎯 Competition Deployment

For the actual competition server:

1. **Deploy to cloud** (AWS/Azure/GCP)
2. **Use environment variables** for flag
3. **Monitor rate limiting** effectiveness
4. **Log attempts** for post-CTF analysis
5. **Have backup instances** ready

### 🧪 Pre-Competition Testing

Before competition starts:

- [ ] Deploy to test server
- [ ] Verify rate limiting works (10 req/min on /eval, /fetch)
- [ ] Confirm exploit.py works (for validation)
- [ ] Test with 3-5 beta testers
- [ ] Ensure flag file exists: `/tmp/flag.txt`
- [ ] Verify both services start (ports 3000, 3001)
- [ ] Check logs are working
- [ ] Test from external network

### 📊 Expected Solve Rates

Based on difficulty (7/10):
- **Beginner**: 5-10% (with hints)
- **Intermediate**: 40-60% (with minimal hints)
- **Advanced**: 80-95% (minimal hints needed)

### 🎓 Hint Strategy

1. **0-30 min**: No hints, let them explore
2. **30-60 min**: Give SSTI discovery hints
3. **60-90 min**: Give SSRF + signature hints
4. **90-120 min**: Give blacklist bypass hints
5. **120+ min**: Consider giving solution structure

Use `ORGANIZER_HINTS.md` for progressive hint giving.

### ✅ Final Checklist Before Launch

- [ ] Exploit files excluded from player package
- [ ] Source code hidden (if desired)
- [ ] Docker image tested and working
- [ ] Player guide reviewed for clarity
- [ ] Rate limiting configured and tested
- [ ] Flag file contains correct flag
- [ ] Competition server deployed and accessible
- [ ] Backup plan in place
- [ ] Monitoring/logging enabled
- [ ] Team has organizer documentation

---

## 🚀 Quick Distribution Command

```bash
# Create clean distribution folder
mkdir cascade-challenge-dist
cd cascade-challenge-dist

# Copy only player files
cp ../PLAYER_GUIDE.md .
cp ../README_DISTRIBUTION.md README.md
cp ../docker-compose.yml .
cp ../Dockerfile .

# Build and export Docker image
docker build -t cascade-ctf:v1.0 ..
docker save cascade-ctf:v1.0 | gzip > cascade-ctf-v1.0.tar.gz

# Create distribution archive
cd ..
tar -czf cascade-challenge-player-v1.0.tar.gz cascade-challenge-dist/

# Distribute cascade-challenge-player-v1.0.tar.gz
```

---

**Remember**: The goal is to challenge players to learn, not to hand them the solution on a silver platter! 🎓🚩
