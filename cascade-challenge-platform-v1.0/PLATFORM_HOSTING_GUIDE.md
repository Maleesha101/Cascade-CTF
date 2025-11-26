# 🚀 Cascade Challenge - Platform Hosting Guide

## Overview

This guide explains how to deploy the Cascade challenge on popular CTF platforms.

---

## 🎯 Deployment Options

### Option 1: Docker-Based Platforms (Recommended)
**Best for**: CTFd, rCTF, FBCTF, PicoCTF

#### What to Provide to Platform:

1. **Docker Image**
   ```bash
   # Build and export
   docker build -t cascade-ctf:v1.0 .
   docker save cascade-ctf:v1.0 | gzip > cascade-ctf-v1.0.tar.gz
   ```

2. **docker-compose.yml** (if platform supports it)
   ```yaml
   version: '3.8'
   services:
     cascade:
       image: cascade-ctf:v1.0
       ports:
         - "3000:3000"
         - "3001:3001"
       environment:
         - FLAG=MEDUSA2{dynamic_flag_here}
       restart: unless-stopped
       healthcheck:
         test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
         interval: 10s
         timeout: 3s
         retries: 3
   ```

3. **Challenge Configuration File**
   ```json
   {
     "name": "Cascade",
     "category": "Web",
     "difficulty": "Medium",
     "points": 400,
     "description": "See PLAYER_GUIDE.md",
     "ports": [3000, 3001],
     "resources": {
       "cpu": "0.5",
       "memory": "512Mi"
     },
     "flags": [
       {
         "type": "static",
         "content": "MEDUSA2{s0_m4ny_l4y3r5_t0_peel_b4ck}"
       }
     ]
   }
   ```

---

## 📦 Platform-Specific Instructions

### CTFd (Most Popular)

**Files to Upload:**
1. Docker image tarball (`cascade-ctf-v1.0.tar.gz`)
2. Challenge description (from `PLAYER_GUIDE.md`)
3. Flag: `MEDUSA2{s0_m4ny_l4y3r5_t0_peel_b4ck}`

**Configuration:**
```yaml
# CTFd Challenge Configuration
name: Cascade
category: Web
value: 400
description: |
  Chain multiple vulnerabilities to read /tmp/flag.txt
  
  Server: http://[INSTANCE_URL]:3000
  
  See attached PLAYER_GUIDE.md for hints and endpoint documentation.
  
  Rate limiting: 10 requests/minute on critical endpoints.

type: dynamic_docker
image: cascade-ctf:v1.0
ports:
  - 3000:3000
  - 3001:3001
```

**Steps:**
1. Admin Panel → Challenges → Create Challenge
2. Choose "Docker" challenge type
3. Upload `cascade-ctf-v1.0.tar.gz`
4. Set ports: 3000, 3001
5. Set flag: `MEDUSA2{s0_m4ny_l4y3r5_t0_peel_b4ck}`
6. Upload `PLAYER_GUIDE.md` as attachment
7. Set point value: 400-500

---

### rCTF (Challenge CTF Platform)

**Files to Provide:**
```
cascade/
├── challenge.yaml
├── Dockerfile
├── docker-compose.yml
└── description.md
```

**challenge.yaml:**
```yaml
name: Cascade
category: web
difficulty: medium
points:
  - 400
flag:
  - MEDUSA2{s0_m4ny_l4y3r5_t0_peel_b4ck}
description: |
  See description.md
files: []
expose:
  - 3000/tcp
  - 3001/tcp
```

---

### PicoCTF / picoCTF-shell-manager

**Challenge Directory Structure:**
```
cascade/
├── Makefile
├── Dockerfile
├── challenge.py
└── metadata.json
```

**metadata.json:**
```json
{
  "name": "Cascade",
  "score": 400,
  "category": "Web Exploitation",
  "grader": "cascade/grader.py",
  "description": "Chain SSTI → SSRF → Deserialization to read the flag.",
  "hints": [
    {"cost": 50, "text": "Research Server-Side Template Injection"},
    {"cost": 100, "text": "The /fetch endpoint requires MD5 signature"},
    {"cost": 150, "text": "Use hex escape sequences to bypass blacklist"}
  ]
}
```

---

## 🔧 Dynamic Flag Support

If your platform supports dynamic flags per team:

### Modify Dockerfile:
```dockerfile
# Add at the end before CMD
ARG FLAG
ENV FLAG=${FLAG}

# Modify flag creation
RUN echo "${FLAG:-MEDUSA2{default_flag}}" > /tmp/flag.txt && \
    chmod 440 /tmp/flag.txt && \
    chown 1000:1000 /tmp/flag.txt
```

### For CTFd Dynamic Flags:
```python
# In challenge configuration
flag_type: dynamic
flag_template: MEDUSA2{[TEAM_ID]_cascade_solved}
```

---

## 🌐 Cloud Platform Deployment

### AWS ECS (Recommended for Scale)

**Task Definition:**
```json
{
  "family": "cascade-ctf",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "containerDefinitions": [{
    "name": "cascade",
    "image": "[ECR_URL]/cascade-ctf:v1.0",
    "portMappings": [
      {"containerPort": 3000, "protocol": "tcp"},
      {"containerPort": 3001, "protocol": "tcp"}
    ],
    "healthCheck": {
      "command": ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"],
      "interval": 30,
      "timeout": 5,
      "retries": 3
    }
  }]
}
```

**Load Balancer Configuration:**
- Target port: 3000
- Health check: `/health`
- Sticky sessions: Recommended

### Kubernetes

**deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cascade-ctf
spec:
  replicas: 3
  selector:
    matchLabels:
      app: cascade-ctf
  template:
    metadata:
      labels:
        app: cascade-ctf
    spec:
      containers:
      - name: cascade
        image: cascade-ctf:v1.0
        ports:
        - containerPort: 3000
        - containerPort: 3001
        resources:
          limits:
            cpu: "500m"
            memory: "512Mi"
          requests:
            cpu: "250m"
            memory: "256Mi"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: cascade-ctf-service
spec:
  type: LoadBalancer
  ports:
  - name: main
    port: 3000
    targetPort: 3000
  - name: internal
    port: 3001
    targetPort: 3001
  selector:
    app: cascade-ctf
```

---

## 📊 Resource Requirements

### Per Instance:
- **CPU**: 0.5 core (500m)
- **Memory**: 512MB
- **Disk**: 200MB
- **Network**: 100 requests/min (rate limited to 10 req/min per IP)

### For 100 Concurrent Players:
- **Instances**: 5-10 (with load balancing)
- **Total CPU**: 2.5-5 cores
- **Total Memory**: 2.5-5GB
- **Bandwidth**: 1-2 Mbps

---

## 🔐 Security Considerations

### Isolation (Important!):

1. **Network Isolation**: Each team gets their own instance
   ```bash
   # Use Docker network isolation
   docker network create --internal cascade-net-team1
   ```

2. **Resource Limits**: Prevent DoS
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '0.5'
         memory: 512M
       reservations:
         cpus: '0.25'
         memory: 256M
   ```

3. **Rate Limiting**: Already built-in (10 req/min)

4. **Flag Isolation**: Use dynamic flags per team if possible

---

## 📝 What to Provide Platform Admins

### Minimal Package:
```
cascade-challenge-platform/
├── cascade-ctf-v1.0.tar.gz        # Docker image
├── PLAYER_GUIDE.md                # Player documentation
├── PLATFORM_HOSTING_GUIDE.md      # This file
├── challenge-config.json          # Platform configuration
└── docker-compose.yml             # Optional: for testing
```

### Complete Package (if they need source):
```
cascade-challenge-platform/
├── cascade-ctf-v1.0.tar.gz
├── PLAYER_GUIDE.md
├── PLATFORM_HOSTING_GUIDE.md
├── Dockerfile
├── docker-compose.yml
├── app.js                         # Source code
├── internal-service.js            # Source code
├── package.json
└── README.md
```

---

## 🎯 Recommended Deployment Strategy

### Option A: Individual Instances per Team (Recommended)
**Pros**: Complete isolation, no interference between teams
**Cons**: Higher resource usage
**Implementation**: Platform creates Docker container per team

### Option B: Shared Instance with Session Management
**Pros**: Lower resource usage
**Cons**: Potential for interference, requires session isolation
**Implementation**: One instance, use cookies/tokens to isolate teams

### Option C: Instance Pool
**Pros**: Balance between isolation and resources
**Cons**: Requires load balancing
**Implementation**: Pool of 5-10 instances, round-robin assignment

**Recommendation**: Use **Option A** for CTFs with < 50 teams, **Option C** for larger events.

---

## 🧪 Testing Before Deployment

```bash
# 1. Load image
docker load -i cascade-ctf-v1.0.tar.gz

# 2. Test run
docker run -d -p 3000:3000 -p 3001:3001 --name test-cascade cascade-ctf:v1.0

# 3. Verify health
curl http://localhost:3000/health
# Expected: {"status":"ok","service":"cascade"}

# 4. Test rate limiting
for i in {1..15}; do 
  curl -X POST http://localhost:3000/eval \
    -H "Content-Type: application/json" \
    -d '{"code":"1+1"}' 
done
# Expected: 11th-15th requests should return 429 (rate limited)

# 5. Verify flag exists
docker exec test-cascade cat /tmp/flag.txt
# Expected: MEDUSA2{s0_m4ny_l4y3r5_t0_peel_b4ck}

# 6. Test exploit works
python exploit.py  # (organizer testing only)

# 7. Cleanup
docker rm -f test-cascade
```

---

## 📧 Email Template for Platform Provider

```
Subject: Cascade Web Challenge - Deployment Request

Hi [Platform Team],

We'd like to host the "Cascade" web exploitation challenge on your platform.

Challenge Details:
- Name: Cascade
- Category: Web Exploitation
- Difficulty: Medium (7/10)
- Points: 400-500
- Technology: Docker (Node.js 18)
- Ports: 3000 (main), 3001 (internal service)
- Resources: 0.5 CPU, 512MB RAM per instance

Files Attached:
- cascade-ctf-v1.0.tar.gz (Docker image, 150MB)
- PLAYER_GUIDE.md (Player documentation)
- PLATFORM_HOSTING_GUIDE.md (Deployment instructions)
- challenge-config.json (Platform configuration)

Deployment Preference:
[ ] Individual instances per team (recommended)
[ ] Shared instance pool
[ ] Your recommendation

Special Requirements:
- Rate limiting: Built-in (10 req/min per IP)
- Flag: MEDUSA2{s0_m4ny_l4y3r5_t0_peel_b4ck}
- Both ports (3000, 3001) must be accessible

Testing:
We've included a docker-compose.yml for local testing.

Questions:
1. Do you support dynamic flags per team?
2. What's the maximum number of concurrent instances?
3. Should we provide the source code or just the image?

Please let us know if you need any additional information.

Thank you!
[Your Name]
```

---

## ✅ Pre-Deployment Checklist

- [ ] Docker image built and tested
- [ ] Flag file exists in image (`/tmp/flag.txt`)
- [ ] Both services start automatically (ports 3000, 3001)
- [ ] Health check endpoint working (`/health`)
- [ ] Rate limiting tested and working
- [ ] Exploit verified to work (organizer testing)
- [ ] PLAYER_GUIDE.md reviewed for clarity
- [ ] No exploit scripts included in player package
- [ ] Platform configuration file prepared
- [ ] Resource requirements documented
- [ ] Contact information provided
- [ ] Testing instructions included

---

## 🆘 Support & Troubleshooting

### Common Issues:

**Issue**: Port 3001 not accessible
**Solution**: Ensure platform exposes both ports, not just 3000

**Issue**: Container fails health check
**Solution**: Increase `initialDelaySeconds` to 15-20 seconds

**Issue**: Rate limiting too aggressive
**Solution**: Can increase limits in app.js if needed for platform

**Issue**: Flag not found
**Solution**: Verify `/tmp/flag.txt` exists: `docker exec [container] cat /tmp/flag.txt`

### Platform Support Contact:
- Create issue on: https://github.com/Maleesha101/Cascade-CTF
- Email: [Your contact email]
- Discord: [Your Discord handle]

---

**Good luck with your CTF! 🚩**
