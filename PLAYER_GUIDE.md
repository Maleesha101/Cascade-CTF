# Cascade Challenge - Player Guide

## Challenge Overview
**Difficulty**: Hard (8-9/10)  
**Category**: Web Exploitation  
**Skills Required**: SSTI, SSRF, IP Encoding, Token Generation, Blacklist Bypass, JavaScript Exploitation

## Challenge Description
You've discovered a web application with multiple vulnerabilities. This challenge requires chaining **5 different steps** to reach the flag:

1. **Discover SSRF** endpoint with signature verification
2. **Bypass SSRF filters** to access internal service (port-based bypass)
3. **Reverse-engineer token algorithm** for internal service authentication
4. **Decode response** from SSRF to extract eval token
5. **Bypass eval blacklist** using hex escape encoding

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
- **Blocks**: Most localhost representations and private IPs
- **Special behavior**: Check what happens with different ports
- Requires MD5 signature: `md5(url + "secret123")[:8]`
- **Hint**: The blacklist has port-specific rules

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
- Timestamp must be within 60 seconds of current time
- Returns: Base64-encoded JSON with `evalToken` (valid for 5 minutes)
- **Important**: Response is base64-encoded, you must decode it

## Exploitation Chain

### Step 1: Discover SSRF Endpoint
- Find the `/fetch` endpoint
- Calculate MD5 signature: `md5(url + "secret123")[:8]`
- Test basic requests

### Step 2: Bypass SSRF Filters
- `/fetch` has a blacklist for localhost access
- BUT: There's a special case for port `:3001` (internal service)
- Research: Does the blacklist treat all ports the same?
- Hint: Try `localhost:3001` vs `localhost:3000`

### Step 3: Generate Auth Token for Internal Service
- Internal `/token` endpoint requires authentication
- Algorithm: `sha256("internal_" + timestamp + "_cascade")[:16]`
- Use current Unix timestamp
- Must be within 60 seconds of server time

### Step 4: Decode SSRF Response
- The `/fetch` endpoint returns: `{"url": "...", "statusCode": 200, "data": "base64...", "encoding": "base64"}`
- You must decode the base64 `data` field to get the actual JSON response
- The decoded response contains your `evalToken`

### Step 5: Bypass Eval Blacklist
- `/eval` blocks keywords: `require`, `process`, `child_process`, etc.
- Also blocks: `fromCharCode`, string concatenation (`+`), `atob`, `btoa`
- 150 character limit
- **Solution**: Use hex escape sequences (`\x??`) to encode blocked keywords
- Example: `\x72\x65\x71\x75\x69\x72\x65` = "require"

## Your Mission

Chain all 5 steps to read `/tmp/flag.txt`:
1. Discover `/fetch` endpoint and calculate MD5 signature
2. Find port-based SSRF bypass for accessing `localhost:3001`
3. Generate SHA-256 auth token for internal service
4. Decode base64 response to extract eval token
5. Use hex escapes to bypass eval blacklist and read flag

## Hints

<details>
<summary>Hint 1: Finding the First Vulnerability</summary>

Look at the `/render` and `/profile` endpoints. Do they properly sanitize user input before rendering templates?

</details>

<details>
<summary>Hint 2: Accessing Internal Services</summary>

The `/fetch` endpoint can make HTTP requests and requires signature verification.

**Signature format**: `md5(url + "secret123")[:8]`

The internal service runs on `localhost:3001`. The SSRF filter blocks most localhost access...

**BUT**: Try accessing different ports. Does the blacklist treat port 3001 specially?

**Hint**: The filter has port-specific rules. `localhost:3000` is blocked, but what about `localhost:3001`?

</details>

<details>
<summary>Hint 3: Token Algorithm</summary>

The internal `/token` endpoint requires:
- `ts`: Unix timestamp (current time in seconds)
- `token`: Authentication token

**Algorithm hint from error messages**:
```
sha256("internal_" + timestamp + "_cascade")[:16]
```

Example:
```python
import hashlib, time
ts = str(int(time.time()))
token = hashlib.sha256(f"internal_{ts}_cascade".encode()).hexdigest()[:16]
```

</details>

<details>
<summary>Hint 4: Decoding the Response</summary>

When you use SSRF via `/fetch`, the response format is:
```json
{
  "url": "http://localhost:3001/token?...",
  "statusCode": 200,
  "data": "eyJ0aW1lc3RhbXA...",  // <-- BASE64 encoded!
  "encoding": "base64"
}
```

You need to:
1. Extract the `data` field
2. Decode from base64
3. Parse the resulting JSON
4. Extract `evalToken`

</details>

<details>
<summary>Hint 5: Bypassing the Eval Blacklist</summary>

The `/eval` endpoint blocks dangerous keywords:
- `require`, `process`, `child_process`, `import`, `Function`, `constructor`

It also blocks encoding patterns:
- `String.fromCharCode`, `atob`, `btoa`, string concatenation (`"req" + "uire"`)

**BUT**: Hex escape sequences (`\x??`) are NOT blocked!

**Example**: The word "require" can be written as:
```javascript
"\x72\x65\x71\x75\x69\x72\x65"
```

**Full payload structure**:
```javascript
module["\x72\x65\x71\x75\x69\x72\x65"]("fs").readFileSync("/tmp/flag.txt","utf8")
```

Note: `module`, `fs`, and bracket notation `[]` are NOT blocked.

</details>

<details>
<summary>Hint 6: The Complete Chain (Spoiler Alert!)</summary>

1. **Calculate signature** for SSRF:
   ```python
   md5(url + "secret123")[:8]
   ```

2. **Generate auth token**:
   ```python
   sha256("internal_" + timestamp + "_cascade")[:16]
   ```

3. **SSRF to get eval token**:
   ```
   GET /fetch?url=http://localhost:3001/token?ts={timestamp}&token={auth_token}&sig={signature}
   ```

4. **Decode base64 response** to extract `evalToken`

5. **Bypass eval with hex escapes**:
   ```json
   {
     "code": "module[\"\\x72\\x65\\x71\\x75\\x69\\x72\\x65\"](\"fs\").readFileSync(\"/tmp/flag.txt\",\"utf8\")",
     "token": "{evalToken}"
   }
   ```

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

### Test 3: SSRF (with signature)
```bash
# Calculate signature: md5("http://localhost:3001/health" + "secret123")[:8]
# Result: 4427720f

curl "http://localhost:3000/fetch?url=http://localhost:3001/health&sig=4427720f"
```

### Test 4: Eval (needs token from internal service)
```bash
curl -X POST http://localhost:3000/eval \
  -H "Content-Type: application/json" \
  -d '{"code":"1+1", "token":"eval_..."}'
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
- SSRF with port-based filter bypass
- JavaScript hex escape sequences (`\x??` notation)
- Node.js module system and `module` object
- MD5 hash calculation
- SHA-256 hash calculation  
- Base64 encoding/decoding
- Unix timestamps

## Time Estimate

- **Beginner**: 90-120 minutes (with hints)
- **Intermediate**: 45-60 minutes
- **Advanced**: 20-30 minutes

Good luck! 🚩
