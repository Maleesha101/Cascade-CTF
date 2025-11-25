# Cascade Challenge - HARDENED VERSION

## Difficulty Level: **HARD → EXPERT**

This version significantly increases the challenge difficulty from **Medium-Hard (6.5/10)** to **Expert (8.5/10)**.

---

## 🔒 New Security Enhancements

### 1. **Enhanced Eval Endpoint Protection**

#### Added Protections:
- ✅ **Expanded Blacklist**: Now blocks 20+ keywords including:
  - `require`, `process`, `child_process`, `fs`, `module`
  - `Function`, `constructor`, `prototype`, `__proto__`
  - `global`, `globalThis`, `this`, `eval`, `Buffer`
  
- ✅ **Anti-Encoding Filters**: Blocks common bypass techniques:
  - Hex encoding (`\x72`)
  - Unicode escapes (`\u0072`)
  - Octal encoding (`\162`)
  - Character code conversion (`String.fromCharCode`)
  - Template literals (`${}`)
  - String concatenation (`'req' + 'uire'`)
  - Bracket notation (`['require']`)
  - Base64 encoding/decoding
  
- ✅ **Length Restriction**: Maximum 150 characters
- ✅ **WAF-like Pattern Detection**: Blocks suspicious patterns
- ✅ **Case-insensitive Filtering**: Prevents case variation bypasses

#### Impact:
Previous simple bypasses **NO LONGER WORK**:
```javascript
// BLOCKED: module["\x72\x65\x71\x75\x69\x72\x65"]("fs")
// BLOCKED: String.fromCharCode(114,101,113,117,105,114,101)
// BLOCKED: module["req" + "uire"]("fs")
```

---

### 2. **Hardened SSRF Protection**

#### Added Protections:
- ✅ **Signature Verification**: Requires MD5 signature for requests
  - Format: `md5(url + "secret123")[:8]`
  - Must compute correct signature to access endpoint
  
- ✅ **Enhanced URL Filtering**: Blocks:
  - `localhost`, `127.0.0.1`, `0.0.0.0`, `::1`
  - Private IP ranges: `10.*`, `172.16.*`, `192.168.*`
  - Link-local addresses: `169.254.*`
  - Keywords: `metadata`, `internal`
  
- ✅ **Response Obfuscation**: 
  - Responses are base64 encoded
  - Must decode before processing
  
- ✅ **Rate Limiting**: Stricter request limits

#### New Requirements:
1. Calculate MD5 signature
2. Bypass IP blacklist (need DNS rebinding, IP encoding, or other tricks)
3. Decode base64 responses

---

### 3. **Hardened Internal Service**

#### Added Protections:
- ✅ **Token-based Authentication**:
  - Requires `token` parameter
  - Algorithm: `sha256("internal_" + timestamp + "_cascade")[:16]`
  
- ✅ **Time-based Challenge**:
  - Requires `ts` (timestamp) parameter
  - Must be within 60 seconds of server time
  - Prevents replay attacks
  
- ✅ **Multi-layer Obfuscation**:
  - Payload is base64 encoded
  - Contains hex-encoded data
  - Original payload: base64 → UTF-8 → hex → base64
  
- ✅ **No Direct Code**: No longer returns executable code directly

#### New Requirements:
1. Generate valid timestamp
2. Calculate correct token
3. Decode triple-encoded payload
4. Reconstruct the RCE vector

---

### 4. **Enhanced SSTI Protection**

#### Added Protections:
- ✅ **Input Sanitization**: Strips dangerous patterns:
  - EJS tags: `<%`, `%>`, `<%=`, `<%#`
  - Template literals: `${}`
  - Dangerous keywords: `require`, `process`, `eval`, `function`
  - Handlebars injection: `[[`, `]]`
  
- ✅ **Limited Context**: 
  - Removed direct access to `require`, `process`
  - Must traverse prototype chain to find globals
  
- ✅ **Multiple Pattern Filters**: Regex-based blocking

---

## 🎯 New Exploitation Requirements

### Required Skills (Expert Level):

1. **Advanced JavaScript Exploitation**:
   - Prototype chain traversal
   - VM escape techniques
   - Alternative code execution vectors
   - Context-free code execution

2. **Cryptographic Knowledge**:
   - MD5 hashing
   - SHA-256 hashing
   - Signature generation

3. **Network Bypass Techniques**:
   - DNS rebinding
   - IP encoding (decimal, octal, hex)
   - Unicode domain tricks
   - TOCTOU (Time-of-check to time-of-use) attacks

4. **Encoding/Obfuscation**:
   - Multi-layer encoding chains
   - Custom obfuscation techniques
   - Alternative character representations
   - JSFuck-style encoding

5. **Timing & Race Conditions**:
   - Time-based token generation
   - Timestamp synchronization
   - Rate limit exploitation

---

## 💡 Exploitation Hints

### Level 1: SSRF Bypass
```
Hint 1: localhost != 127.0.0.1 != 0x7f000001
Hint 2: DNS rebinding can bypass IP checks
Hint 3: Calculate signature: md5(url + "secret123")[:8]
```

### Level 2: Internal Service Access
```
Hint 1: Token = sha256("internal_" + unix_timestamp + "_cascade")[:16]
Hint 2: Timestamp must be current (within 60 seconds)
Hint 3: Response is base64 → JSON → hex → base64 → utf8
```

### Level 3: Eval Bypass
```
Hint 1: Simple encoding is blocked - need creative approaches
Hint 2: 150 character limit - code golf required
Hint 3: No direct access to dangerous objects - find alternate paths
Hint 4: Consider JavaScript language quirks and edge cases
```

### Level 4: SSTI Bypass
```
Hint 1: Context is restricted but not isolated
Hint 2: Prototype chain still exists
Hint 3: EJS tags are filtered - find alternatives
```

---

## 🚀 Advanced Bypass Techniques (Solutions)

### Technique 1: IP Encoding for SSRF
```python
# Decimal notation
"http://2130706433:3001"  # 127.0.0.1 in decimal

# Octal notation
"http://0177.0.0.1:3001"

# Hex notation
"http://0x7f.0.0.1:3001"
```

### Technique 2: VM Context Escape
```javascript
// Access process through Function constructor
({}).constructor.constructor('return process')()

// Access through error stack traces
try{null.f()}catch(e){e.stack}

// Use indirect eval
(1,eval)('this.process')
```

### Technique 3: Code Golf for Length Limit
```javascript
// Compress code using tricks
(a=>{...})(({}).constructor.constructor('ret...'))
```

### Technique 4: Alternative Code Execution
```javascript
// Without using blocked keywords
// Use computed properties with numbers
({}).constructor['constr'+'uctor']

// Use symbols
Object[Object.keys(Object).find(k=>k[0]=='g')]
```

---

## 📊 Difficulty Comparison

| Aspect | Original | Hardened |
|--------|----------|----------|
| **Blacklist Size** | 3 keywords | 20+ keywords |
| **Encoding Filters** | None | 12+ patterns |
| **Authentication** | None | Token + Signature |
| **Obfuscation Layers** | 0 | 3-4 layers |
| **Length Limits** | None | 150 chars |
| **SSRF Protection** | Basic | Advanced + IP filtering |
| **Time Required** | 1-2 hours | 4-8 hours |
| **Difficulty Rating** | 6.5/10 | 8.5/10 |
| **Skill Level** | Intermediate | Expert |
| **CTF Category** | Medium-Hard | Hard-Expert |

---

## 🎓 Learning Objectives

Players will learn:
- ✅ Advanced JavaScript exploitation techniques
- ✅ Cryptographic signature bypass methods
- ✅ Multi-layer encoding/obfuscation
- ✅ Network protocol manipulation
- ✅ Time-based attack vectors
- ✅ WAF bypass techniques
- ✅ Code golf and optimization
- ✅ VM escape methods

---

## 🔧 Testing the Hardened Version

```bash
# Rebuild with hardened code
docker-compose down
docker build -t cascade-challenge .
docker-compose up -d

# Test that simple exploits are blocked
curl -X POST http://localhost:3000/eval \
  -H "Content-Type: application/json" \
  -d '{"code":"module[\"\\x72\\x65\\x71\\x75\\x69\\x72\\x65\"](\"fs\")"}'
# Expected: 403 Encoding pattern detected

# Test SSRF signature requirement
curl "http://localhost:3000/fetch?url=http://example.com"
# Expected: 403 Invalid signature
```

---

## 🏆 Expected Solve Rate

- **Original Version**: 60-70% of intermediate players
- **Hardened Version**: 10-20% of expert players

This version is suitable for:
- Advanced CTF competitions (DEF CON, PlaidCTF level)
- Professional penetration testing assessments
- Advanced web security training
- Bug bounty preparation

---

## 📝 Notes for Challenge Organizers

1. **Hint System**: Consider progressive hints at 2, 4, and 6 hours
2. **Scoring**: Increase point value to 750-1000 points
3. **Time Limit**: Recommend 24-48 hour window
4. **Category**: Mark as "Hard" or "Expert Web"
5. **Prerequisites**: Recommend players complete medium challenges first

The hardened version maintains exploitability while significantly raising the skill ceiling.
