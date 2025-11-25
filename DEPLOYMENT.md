# Cascade Challenge - Deployment Guide for CTF Organizers

## 🚀 Quick Deployment

### Option 1: Docker Compose (Recommended)
```bash
docker-compose up -d
```

### Option 2: Docker Run
```bash
docker build -t cascade-challenge .
docker run -d -p 3000:3000 --name cascade cascade-challenge
```

---

## 🔧 Configuration

### Environment Variables
```bash
# Set custom flag (optional)
export FLAG="MEDUSA2{custom_flag_here}"

# Set port (default: 3000)
export PORT=3000
```

### Port Mapping
- **3000**: Main application (public)
- **3001**: Internal service (localhost only - should NOT be exposed)

---

## 🛡️ Security Considerations

### For Competition Deployment:

1. **Network Isolation**
   - Ensure port 3001 is NOT accessible from outside
   - Use firewall rules or Docker network isolation
   
2. **Resource Limits**
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '1'
         memory: 512M
   ```

3. **Rate Limiting**
   - Built-in: 100 requests/minute per service
   - Consider adding nginx reverse proxy for additional protection

4. **Challenge Isolation**
   - Deploy separate container per team if high-value competition
   - OR use shared instance with automatic resets

---

## 📊 Monitoring

### Health Check
```bash
curl http://localhost:3000/health
```

Expected: `{"status":"ok","service":"cascade"}`

### Logs
```bash
# Docker Compose
docker-compose logs -f

# Docker
docker logs -f cascade
```

---

## 🔄 Reset/Restart

```bash
# Docker Compose
docker-compose restart

# Docker
docker restart cascade
```

---

## 🎯 Validation

Run the test harness to ensure challenge is working:
```bash
npm test
```

All 8 tests should pass.

---

## 🏆 Solution Verification

### Expected Solution Path:
1. SSTI in user profile bio field
2. SSRF via /fetch endpoint to reach localhost:3001
3. Signature calculation: `md5(url + "secret123")[:8]`
4. Token generation: `sha256("internal_" + timestamp + "_cascade")[:16]`
5. Multi-layer decoding of payload
6. Eval blacklist bypass (multiple methods possible)

### First Blood Time: 
- Expert teams: ~30-60 minutes
- Average teams: 2-4 hours

---

## 🐛 Troubleshooting

### Port Already in Use
```bash
# Find process
netstat -tulpn | grep 3000
# Kill process
kill -9 <PID>
```

### Container Won't Start
```bash
# Check logs
docker logs cascade

# Common issues:
# - Port conflicts
# - Missing dependencies
# - File permissions
```

### Flag Not Accessible
```bash
# Verify flag file exists
docker exec cascade cat /tmp/flag.txt

# Recreate if needed
docker exec cascade sh -c 'echo "MEDUSA2{s0_m4ny_l4y3r5_t0_peel_b4ck}" > /tmp/flag.txt'
```

---

## 📈 Difficulty Adjustment

### Make Easier (Original Version):
- Remove signature requirement from SSRF
- Reduce blacklist keywords in eval
- Remove token authentication from internal service
- Provide more hints

### Make Harder (Already Implemented):
- Enhanced blacklist (20+ keywords)
- Anti-encoding filters
- Length restrictions (150 chars)
- WAF-like pattern detection
- Multi-factor authentication
- Multi-layer obfuscation

---

## 📝 Scoring Recommendations

**Points:** 500-750 (Hard category)

**Dynamic Scoring:** 
- First blood: 750 points
- 2-5 solves: 650 points
- 6-10 solves: 550 points
- 10+ solves: 500 points

**Hint Penalties:**
- Hint 1 (free): -0 points
- Hint 2: -50 points
- Hint 3: -100 points

---

## 🎓 Educational Value

### Learning Objectives:
- ✅ Template injection vulnerabilities
- ✅ SSRF and internal network access
- ✅ Blacklist bypass techniques
- ✅ Cryptographic signature generation
- ✅ Multi-stage exploitation chains
- ✅ JavaScript VM escape techniques

### Write-up Template:
Provide to competitors after CTF:
1. Vulnerability identification
2. Exploitation methodology
3. Code examples
4. Mitigation recommendations

---

## 📞 Support

For deployment issues, contact:
- Email: ctf-admin@example.com
- Discord: #ctf-tech-support
- GitHub Issues: [repo-link]

---

## ✅ Pre-Competition Checklist

- [ ] Docker image built and tested
- [ ] Ports configured correctly (3000 public, 3001 internal only)
- [ ] Flag file created with correct permissions
- [ ] Test harness passes all checks
- [ ] Health endpoint responding
- [ ] Rate limiting verified
- [ ] Resource limits configured
- [ ] Monitoring/logging enabled
- [ ] Backup/reset procedure tested
- [ ] Challenge description uploaded to platform
- [ ] Hints configured with timers
- [ ] First blood prize announced (optional)

---

## 🎉 Post-Competition

1. **Publish Write-up** (24-48 hours after)
2. **Release Source Code** (if open-source)
3. **Collect Feedback** from competitors
4. **Update Challenge** based on feedback
5. **Share Statistics**:
   - Total solves
   - Average solve time
   - First blood time
   - Most common approach

---

**Version:** 1.0.0  
**Last Updated:** November 2025  
**Tested On:** Docker 24.x, Node.js 18.x
