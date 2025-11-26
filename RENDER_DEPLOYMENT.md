# Deploying Cascade Challenge to Render

## Quick Deploy

### Option 1: Deploy from GitHub (Recommended)

1. **Push to GitHub** (if not already):
   ```bash
   git add .
   git commit -m "Add Render deployment config"
   git push origin main
   ```

2. **Go to Render Dashboard**:
   - Visit: https://dashboard.render.com
   - Click "New +" → "Web Service"

3. **Connect Repository**:
   - Connect your GitHub account
   - Select: `Maleesha101/Cascade-CTF`
   - Click "Connect"

4. **Configure Service**:
   ```
   Name: cascade-ctf
   Region: Choose closest to your users
   Branch: main
   Runtime: Docker
   
   Instance Type: Free (for testing) or Starter ($7/month for production)
   
   Docker Command: (leave default, uses CMD from Dockerfile)
   ```

5. **Environment Variables** (Optional):
   - No environment variables needed for basic deployment
   - Flag is embedded in Docker image

6. **Click "Create Web Service"**

7. **Wait for deployment** (5-10 minutes first time)

### Option 2: Deploy with Render Blueprint

Create a `render.yaml` in your repo root:

```yaml
services:
  - type: web
    name: cascade-ctf
    runtime: docker
    region: oregon
    plan: free
    dockerfilePath: ./Dockerfile
    dockerContext: .
    envVars: []
```

Then:
1. Push to GitHub
2. Dashboard → New → Blueprint
3. Connect repo and deploy

---

## Configuration Details

### Ports
Render will automatically expose port 3000 (main app).
**Note**: Port 3001 (internal service) runs internally and is NOT exposed to the internet, which is perfect for security!

### Health Checks
Render will use the `/health` endpoint automatically.

### Resources (Free Tier)
- **CPU**: 0.5 vCPU
- **RAM**: 512 MB
- **Disk**: 1 GB
- **Sleep**: Spins down after 15 min inactivity
- **Monthly Hours**: 750 hours free

### Resources (Starter $7/month)
- **CPU**: 0.5 vCPU
- **RAM**: 512 MB
- **Disk**: 1 GB
- **No sleep**: Always on
- **Better for CTF events**

---

## Post-Deployment

### Get Your URL
After deployment, Render provides a URL like:
```
https://cascade-ctf.onrender.com
```

### Test Deployment
```bash
# Health check
curl https://cascade-ctf.onrender.com/health

# Should return: {"status":"ok","service":"cascade"}
```

### Update exploit.py
Change the BASE_URL in your exploit script:
```python
BASE_URL = "https://cascade-ctf.onrender.com"
```

---

## Important Notes

### ⚠️ Free Tier Limitations
1. **Spins down after 15 minutes** of inactivity
2. **Cold start**: Takes 30-60 seconds to wake up
3. **Not suitable for CTF events** (players will experience delays)
4. **Good for**: Testing, demos, practice

### ✅ Starter Tier ($7/month) for CTF Events
1. **Always on**: No spin-down
2. **Instant response**
3. **Suitable for competitions**
4. **Worth it for CTF events**

### 🔒 Security on Render
- Port 3001 (internal service) is NOT exposed to internet
- Only port 3000 is accessible
- **This is actually MORE secure than expected!**
- Players must use SSRF through port 3000 to access internal service
- Perfect for the challenge design

---

## Troubleshooting

### Build Fails
**Issue**: Docker build fails on Render
**Solution**: Check Dockerfile syntax, ensure all files are committed

### Health Check Fails
**Issue**: Render shows "Deploy failed - health check timeout"
**Solution**: Ensure `/health` endpoint returns 200 OK within 30 seconds

### Memory Issues
**Issue**: Container crashes with OOM (Out of Memory)
**Solution**: Upgrade to Starter plan or optimize app

### Slow Cold Starts (Free Tier)
**Issue**: First request takes 30-60 seconds
**Solution**: Upgrade to Starter plan ($7/month) for always-on

---

## Custom Domain (Optional)

If you have a domain:
1. Dashboard → Your Service → Settings
2. Scroll to "Custom Domains"
3. Add your domain (e.g., `ctf.yourdomain.com`)
4. Follow DNS instructions

---

## Monitoring

### View Logs
```bash
# In Render dashboard
Services → cascade-ctf → Logs
```

### Check Metrics
- Dashboard shows CPU, Memory, Request rate
- Free tier has basic metrics
- Starter tier has detailed metrics

---

## Cost Estimate

### For Testing/Practice:
- **Free Tier**: $0/month
- Sleeps after 15 min
- Good for personal use

### For CTF Event (100 players, 4 hours):
- **Starter Tier**: $7/month
- Always on
- Handles moderate traffic
- Recommended

### For Large CTF (200+ players):
- **Standard Tier**: $25/month
- 1 vCPU, 2 GB RAM
- Better for high traffic
- Or use multiple instances

---

## Alternative: Deploy to Multiple Instances

For large CTF events, consider:
1. Deploy multiple instances (cascade-ctf-1, cascade-ctf-2, etc.)
2. Use round-robin DNS or load balancer
3. Give different teams different URLs
4. Better isolation and performance

---

## Deployment Checklist

- [ ] Code pushed to GitHub
- [ ] Dockerfile tested locally
- [ ] render.yaml created (if using blueprint)
- [ ] Render account created
- [ ] Service configured (name, region, plan)
- [ ] Deployment successful
- [ ] Health check passing
- [ ] URL accessible
- [ ] Flag verified: `curl https://[your-url]/health`
- [ ] exploit.py updated with new URL
- [ ] Rate limiting tested
- [ ] Documented URL for players

---

## Quick Commands

```bash
# Test locally before deploying
docker build -t cascade-ctf:v1.0 .
docker run -d -p 3000:3000 -p 3001:3001 cascade-ctf:v1.0
curl http://localhost:3000/health

# Deploy to Render (via Git)
git add .
git commit -m "Deploy to Render"
git push origin main
# Then create service in Render dashboard

# Update exploit script
# Change BASE_URL in exploit.py to your Render URL

# Test exploit
python exploit.py
```

---

## Success! 🎉

Your challenge is now live at: `https://[your-service].onrender.com`

Players can access it directly, and you can monitor usage from the Render dashboard.

For CTF events, **strongly recommend Starter tier ($7/month)** to avoid cold starts and ensure consistent performance.
