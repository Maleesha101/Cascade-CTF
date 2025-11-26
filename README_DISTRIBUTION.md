# 🎯 Cascade Challenge - CTF Distribution Package

## For Competitors

This package contains everything you need to understand and attempt the Cascade challenge.

**⚠️ Important**: This is a **learning challenge**. The files included are for understanding the challenge structure, NOT for running automated exploits.

---

## 📦 What's Included

```
cascade-challenge/
├── docker-compose.yml          # Easy local deployment
├── Dockerfile                  # Container configuration  
├── PLAYER_GUIDE.md            # Challenge walkthrough with hints
└── README.md                   # This file
```

**NOT INCLUDED** (Organizer/Testing Only):
- `exploit.py` - Automated exploit script (DO NOT DISTRIBUTE)
- `exploit_hardened.py` - Advanced exploit (DO NOT DISTRIBUTE)
- `ORGANIZER_HINTS.md` - Hint strategy guide (for organizers only)
- `app.js`, `internal-service.js` - Source code (to prevent spoilers)

---

## 🚀 Local Testing (Optional)

You can deploy this challenge locally to practice:

### Prerequisites
- Docker & Docker Compose installed
- Port 3000 available

### Deploy
```bash
docker-compose up -d
```

### Access
Open your browser: `http://localhost:3000`

### Stop
```bash
docker-compose down
```

---

## 🎯 Competition Details

**Challenge Name:** Cascade  
**Category:** Web Exploitation  
**Difficulty:** Medium (7/10)  
**Points:** 350-500 (depends on CTF scoring)

**Competition Server:** `http://[PROVIDED_BY_ORGANIZERS]:3000`

---

## 📖 Getting Started

1. **Read** `PLAYER_GUIDE.md` for challenge overview and hints
2. **Explore** the available endpoints listed in the guide
3. **Research** the vulnerability types mentioned
4. **Chain** the vulnerabilities to read `/tmp/flag.txt`

## 🎓 Learning Objectives

This challenge teaches:
- Server-Side Template Injection (SSTI)
- Server-Side Request Forgery (SSRF)
- Blacklist bypass techniques
- JavaScript encoding methods
- Vulnerability chaining

## ⏱️ Rate Limiting

Be aware of rate limits:
- **10 requests/minute** on critical endpoints
- Plan your attacks carefully
- Blind brute-forcing will fail

## 🏆 Submission

Submit the flag in format: `MEDUSA2{...}`

Good luck! 🚩

---

## 📋 Challenge Objectives

Your mission is to exploit a web application with multiple security layers and read the flag from `/tmp/flag.txt`.

**Flag Format:** `MEDUSA2{...}`

---

## 🔍 Getting Started

The web application is live at the target URL. Start by:

1. **Explore the Interface**: Visit the site and see what's there
2. **Test Basic Functionality**: Try normal user interactions
3. **Directory Enumeration**: Look for common paths and endpoints
4. **Analyze Responses**: Check HTTP headers, error messages, HTML comments
5. **Find Entry Points**: Where does the app accept user input?

**Tools for Reconnaissance:**
```bash
# Basic exploration
curl http://target:3000

# Directory fuzzing
gobuster dir -u http://target:3000 -w wordlist.txt

# Endpoint discovery
ffuf -u http://target:3000/FUZZ -w wordlist.txt
```

---

## 💡 Getting Started

1. **Reconnaissance**: Explore all endpoints
2. **Identify Vulnerabilities**: Look for injection points
3. **Chain Exploits**: Multiple vulnerabilities need to be chained
4. **Bypass Filters**: Expect security filters and blacklists
5. **Capture Flag**: Read from `/tmp/flag.txt`

---

## 🛠️ Tools You Might Need

- `curl` or `Burp Suite` - HTTP requests
- `python3` with `requests` library
- Text editor for scripting
- Base64/hex encoding tools
- Hash calculators (MD5, SHA-256)

---

## ⚡ Pro Tips

- Rate limiting is in place (100 req/min)
- Multiple vulnerability types are involved
- Look for ways to access internal services
- JavaScript knowledge is helpful
- Creative thinking required for bypass techniques

---

## 📚 Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [PortSwigger Web Security Academy](https://portswigger.net/web-security)
- [HackTricks - Web Exploitation](https://book.hacktricks.xyz/pentesting-web/)

---

## 🏆 Hints System

Hints are available on the CTF platform:
- **Hint 1**: Free after 2 hours
- **Hint 2**: -50 points after 4 hours  
- **Hint 3**: -100 points after 6 hours

---

## ⚠️ Rules

1. **No DDoS**: Respect rate limits
2. **No Sharing**: Don't share solutions during competition
3. **Report Bugs**: Contact organizers if you find technical issues
4. **Have Fun**: Learn and enjoy the challenge!

---

## 📞 Support

**Discord:** `#cascade-support`  
**Email:** `ctf-support@example.com`

---

## 🎓 Learning Outcomes

By completing this challenge, you'll learn:
- Server-Side Template Injection (SSTI)
- Server-Side Request Forgery (SSRF)
- Blacklist bypass techniques
- Cryptographic signature generation
- Multi-stage exploit chaining
- JavaScript security concepts

---

## ✅ Submission

Submit your flag on the CTF platform:

**Flag Format:** `MEDUSA2{...}`

---

**Good Luck! 🚀**

*Challenge created by MEDUSA 2.0 CTF Team*
