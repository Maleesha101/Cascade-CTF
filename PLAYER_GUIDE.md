# Cascade Challenge - Player Guide

## Challenge Overview
**Difficulty**: Hard (8-9/10)  
**Category**: Web Exploitation  
**Skills Required**: SSTI, SSRF, IP Encoding, Token Generation, Blacklist Bypass, JavaScript Exploitation

## Challenge Description
You've discovered a web application with multiple vulnerabilities. This challenge requires chaining **4 different vulnerabilities** to reach the flag:

1. **SSTI** (Server-Side Template Injection)
2. **SSRF** (Server-Side Request Forgery) with IP encoding bypass
3. **Token Generation** from internal service
4. **Eval Blacklist Bypass** using encoding techniques

**Target**: `http://[CHALLENGE_URL]:3000`

**Flag Location**: `/tmp/flag.txt`

## Architecture

The application has **two services**:
- **Main App** (port 3000): Publicly accessible
- **Internal Service** (port 3001): Only accessible from main app (SSRF required)

## Available Endpoints

### Main App (Port 3000)

#### 1. `/health` (GET)
Health check endpoint.

#### 2. `/profile/:username` (GET)
User profile viewer with template rendering.

#### 3. `/render` (POST)
Custom template rendering endpoint.
- Body: `{"template": "your_template_here"}`

#### 4. `/fetch` (GET)
URL fetcher (SSRF vulnerability).
- Parameters: `url`, `sig`
- **Blocks**: `localhost`, `127.0.0.1`, `::1`, private IPs
- **Allows**: IP encoding bypasses (research this!)
- Requires MD5 signature: `md5(url + "secret123")[:8]`

#### 5. `/eval` (POST)
Code evaluation endpoint.
- Body: `{"code": "your_code", "token": "eval_token_from_internal_service"}`
- **Requires token from internal service** (forces SSRF chain)
- Strong keyword blacklist
- Encoding pattern detection
- 150 character limit

### Internal Service (Port 3001)

⚠️ **Not directly accessible** - must use SSRF via `/fetch`

#### 6. `/health` (GET)
Internal health check.

#### 7. `/token` (GET)
Generates eval tokens for authenticated requests.
- Parameters: `ts` (timestamp), `token` (auth token)
- Token algorithm: `sha256("internal_" + timestamp + "_cascade")[:16]`
- Timestamp must be within 60 seconds
- Returns: `evalToken` (valid for 5 minutes)

## Exploitation Chain

### Step 1: SSRF with IP Encoding Bypass
- `/fetch` blocks `localhost` and `127.0.0.1`
- Research IP address encoding techniques
- Hint: What other ways can you represent 127.0.0.1?

### Step 2: Generate Auth Token
- Internal service requires timestamp + token
- Figure out the token generation algorithm
- Hint: Check the `/token` endpoint error messages

### Step 3: Get Eval Token
- Use SSRF to access `http://[BYPASS]:3001/token`
- Provide correct timestamp and auth token
- Receive `evalToken` for `/eval` endpoint

### Step 4: Bypass Eval Blacklist
- `/eval` blocks many keywords: `require`, `process`, `child_process`, etc.
- Also blocks encoding patterns: `fromCharCode`, string concatenation, `atob`
- 150 character limit
- Research: JavaScript string encoding bypasses
- Hint: There are multiple encoding schemes in JavaScript

## Your Mission

Chain all 4 vulnerabilities to read `/tmp/flag.txt`:
1. Bypass SSRF IP blacklist
2. Generate auth token for internal service  
3. Obtain eval token via SSRF
4. Bypass eval blacklist to read flag

## Hints

<details>
<summary>Hint 1: Finding the First Vulnerability</summary>

Look at the `/render` and `/profile` endpoints. Do they properly sanitize user input before rendering templates?

</details>

<details>
<summary>Hint 2: Accessing Internal Services</summary>

The `/fetch` endpoint can make HTTP requests. But there's signature verification...

The signature format is hinted in error messages. Look for MD5 and a secret.

There's also an internal service running on `localhost:3001` that you can't access directly.

</details>

<details>
<summary>Hint 3: Bypassing the Eval Blacklist</summary>

The `/eval` endpoint blocks dangerous keywords like:
- `require`
- `process`
- `child_process`
- `Function`
- `constructor`

But does it check for **encoded** versions of these keywords?

Research: JavaScript hex escape sequences (`\x??`)

</details>

<details>
<summary>Hint 4: The Complete Chain</summary>

You need to combine three vulnerabilities:

1. **SSTI** → Discover template injection
2. **SSRF** → Use it to access internal service (localhost:3001)
3. **Eval Bypass** → Use encoding to bypass keyword blacklist

The internal service has authentication. Check the error messages for hints about the token algorithm.

</details>

<details>
<summary>Hint 5: Reading the Flag</summary>

Once you've bypassed the blacklist, you need to:
1. Access Node.js built-in modules
2. Read a file from the filesystem
3. Return the contents

Example structure (blocked directly):
```javascript
module.require("fs").readFileSync("/tmp/flag.txt", "utf8")
```

Key question: How can you write `require` without triggering the blacklist?

</details>

## Testing Your Exploit

### Test 1: Basic Health Check
```bash
curl http://localhost:3000/health
```

### Test 2: Template Injection
```bash
curl -X POST http://localhost:3000/render \
  -H "Content-Type: application/json" \
  -d '{"template":"<%= 7*7 %>"}'
```

### Test 3: SSRF (needs signature)
```bash
curl "http://localhost:3000/fetch?url=http://localhost:3001/health&sig=???"
```

### Test 4: Eval (needs bypass)
```bash
curl -X POST http://localhost:3000/eval \
  -H "Content-Type: application/json" \
  -d '{"code":"1+1"}'
```

## Rate Limiting

⚠️ **Important**: The challenge has rate limiting enabled:
- **10 requests per minute** on `/eval` and `/fetch`
- **30 requests per minute** on `/render` and `/profile`

Plan your attacks carefully! Blind brute-forcing will get you rate-limited.

## Submission

Once you've successfully read the flag, submit it in the format:
```
MEDUSA2{...}
```

## Common Pitfalls

❌ **Don't**:
- Try to brute force the signature (you'll get rate limited)
- Use obvious string concatenation (it's blocked)
- Use `String.fromCharCode` (it's blocked)
- Make random requests without understanding the chain

✅ **Do**:
- Read error messages carefully (they contain hints)
- Understand each vulnerability before moving to the next
- Research JavaScript encoding techniques
- Think about how to chain the vulnerabilities together

## Resources

If you're stuck, research these topics:
- EJS template injection
- SSRF with localhost
- JavaScript hex escape sequences
- Node.js module system
- MD5 hash calculation
- SHA-256 hash calculation

## Time Estimate

- **Beginner-Intermediate**: 60-90 minutes
- **Intermediate**: 30-45 minutes
- **Advanced**: 15-30 minutes

Good luck! 🚩
