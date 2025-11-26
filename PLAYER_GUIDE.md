# Cascade Challenge - Player Guide

## Challenge Overview
**Difficulty**: Medium (7/10)  
**Category**: Web Exploitation  
**Skills Required**: SSTI, SSRF, Blacklist Bypass, JavaScript Exploitation

## Challenge Description
You've discovered a web application with multiple vulnerabilities. Chain them together to read the flag from `/tmp/flag.txt`.

**Target**: `http://[CHALLENGE_URL]:3000`

## Available Endpoints

### 1. `/health` (GET)
Health check endpoint - tells you if the server is running.

### 2. `/profile/:username` (GET)
User profile viewer with template rendering.

### 3. `/render` (POST)
Custom template rendering endpoint.
- Body: `{"template": "your_template_here"}`

### 4. `/fetch` (GET)
URL fetcher that makes HTTP requests.
- Parameters: `url`, `sig`
- Note: Signature verification required

### 5. `/eval` (POST)
Code evaluation endpoint (intentionally vulnerable).
- Body: `{"code": "your_javascript_code"}`
- Has security filters - you'll need to bypass them

## Your Mission

Read the flag from `/tmp/flag.txt` by chaining vulnerabilities.

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
