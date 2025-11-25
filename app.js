/**
 * MEDUSA 2.0 Challenge: Cascade
 * Main application exposing SSTI, SSRF, and deserialization vulnerabilities
 * Run as: node app.js (listens on 0.0.0.0:3000)
 */

const express = require('express');
const ejs = require('ejs');
const bodyParser = require('body-parser');
const http = require('http');
const fs = require('fs');

const app = express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Simple in-memory user store
const users = {
  'user1': { id: 1, username: 'user1', email: 'user1@example.com', bio: 'Hello world' },
  'user2': { id: 2, username: 'user2', email: 'user2@example.com', bio: 'Another user' }
};

// Request counter for rate limiting
let requestCount = 0;
const MAX_REQUESTS_PER_MINUTE = 100;
setInterval(() => { requestCount = 0; }, 60000);

// VULNERABILITY 1: Server-Side Template Injection (SSTI) in /profile
// Unsafely renders user-supplied template data
app.get('/profile/:username', (req, res) => {
  requestCount++;
  if (requestCount > MAX_REQUESTS_PER_MINUTE) {
    return res.status(429).json({ error: 'Too many requests' });
  }

  const username = req.params.username;
  const user = users[username];

  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }

  // Input sanitization (still bypassable but harder)
  const dangerousPatterns = [
    /<%/g, /%>/g, /\${/g, /<%=/g, /<%#/g, /<%_/g,
    /require/gi, /process/gi, /eval/gi, /function/gi,
    /\[\[/g, /\]\]/g  // Handlebars-style injection
  ];

  let sanitizedBio = user.bio;
  for (const pattern of dangerousPatterns) {
    sanitizedBio = sanitizedBio.replace(pattern, '');
  }

  // Vulnerable: ejs.render but with limited context
  try {
    const template = `
      <h1><%= username %></h1>
      <p><%= bio %></p>
    `;
    
    // VULNERABILITY: Still vulnerable but with restricted context
    // Removed direct access to require, process, etc.
    // Must find alternative ways to access these
    const rendered = ejs.render(template, {
      username: user.username,
      bio: sanitizedBio,
      // Removed dangerous globals - must find them through prototype chain
    });

    res.send(rendered);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// VULNERABILITY 2: Server-Side Request Forgery (SSRF) via template injection
// Attackers can use SSTI to make HTTP requests to internal services
app.get('/fetch', (req, res) => {
  requestCount++;
  if (requestCount > MAX_REQUESTS_PER_MINUTE) {
    return res.status(429).json({ error: 'Too many requests' });
  }

  const url = req.query.url;
  const signature = req.query.sig;
  
  if (!url) {
    return res.status(400).json({ error: 'Missing url parameter' });
  }

  // Enhanced URL validation
  const blockedPatterns = [
    'file://', '..', 'localhost', '127.0.0.1', '0.0.0.0',
    '::1', '169.254', '10.', '172.16', '192.168',
    'metadata', 'internal'
  ];
  
  const urlLower = url.toLowerCase();
  for (const pattern of blockedPatterns) {
    if (urlLower.includes(pattern)) {
      return res.status(403).json({ error: 'Blocked URL pattern' });
    }
  }

  // Signature verification (weak - can be bypassed with timing attack or brute force)
  const crypto = require('crypto');
  const expectedSig = crypto.createHash('md5').update(url + 'secret123').digest('hex').substring(0, 8);
  
  if (!signature || signature !== expectedSig) {
    return res.status(403).json({ error: 'Invalid signature', hint: 'sig=md5(url+secret)[:8]' });
  }

  // VULNERABILITY: Still allows SSRF if you can bypass validation
  // Need to find IP encoding tricks or DNS rebinding
  http.get(url, (response) => {
    let data = '';
    response.on('data', chunk => { data += chunk; });
    response.on('end', () => {
      // Obfuscate the response to make exploitation harder
      const obfuscated = Buffer.from(data).toString('base64');
      res.json({ url, statusCode: response.statusCode, data: obfuscated, encoding: 'base64' });
    });
  }).on('error', (e) => {
    res.status(500).json({ error: e.message });
  });
});

// VULNERABILITY 3: Insecure Deserialization via eval()
// Accepts and evaluates untrusted code objects
app.post('/eval', express.json(), (req, res) => {
  requestCount++;
  if (requestCount > MAX_REQUESTS_PER_MINUTE) {
    return res.status(429).json({ error: 'Too many requests' });
  }

  const code = req.body.code;
  if (!code) {
    return res.status(400).json({ error: 'Missing code parameter' });
  }

  // Enhanced blacklist - blocks more patterns and obfuscation techniques
  const blacklist = [
    'require', 'process', 'child_process', 'fs', 'module',
    'import', 'eval', 'Function', 'constructor', 'prototype',
    '__proto__', 'exec', 'spawn', 'fork', 'Buffer',
    'global', 'globalThis', 'this', 'self', 'window'
  ];
  
  // Check for direct keyword matches
  for (const keyword of blacklist) {
    if (code.toLowerCase().includes(keyword.toLowerCase())) {
      return res.status(403).json({ error: 'Blocked keyword: ' + keyword });
    }
  }

  // Block common encoding patterns
  const encodingPatterns = [
    /\\x[0-9a-fA-F]{2}/,           // Hex encoding: \x72
    /\\u[0-9a-fA-F]{4}/,           // Unicode: \u0072
    /\\[0-7]{1,3}/,                // Octal: \162
    /String\.fromCharCode/i,       // Character code conversion
    /fromCharCode/i,
    /String\[/,                    // String['fromCharCode']
    /\[\s*["'`]/,                  // Bracket notation: ['require']
    /\+\s*["'`]/,                  // String concatenation: 'req' + 'uire'
    /\$\{/,                        // Template literals: ${}
    /atob|btoa/i,                  // Base64 encoding
    /unescape|decodeURI/i,         // URI/escape decoding
    /\.call\(|.apply\(/i,          // Function call/apply
  ];

  for (const pattern of encodingPatterns) {
    if (pattern.test(code)) {
      return res.status(403).json({ error: 'Encoding pattern detected and blocked' });
    }
  }

  // Input length restriction (makes payload construction harder)
  if (code.length > 150) {
    return res.status(400).json({ error: 'Code too long. Maximum 150 characters allowed.' });
  }

  // Additional WAF-like checks for suspicious patterns
  const suspiciousPatterns = [
    /[\[\]]{3,}/,                  // Multiple brackets
    /["'`]{3,}/,                   // Multiple quotes
    /\(\s*\)/,                     // Empty function calls
    /\.{3,}/,                      // Multiple dots (property chaining)
  ];

  for (const pattern of suspiciousPatterns) {
    if (pattern.test(code)) {
      return res.status(403).json({ error: 'Suspicious pattern detected' });
    }
  }

  try {
    // VULNERABILITY: Direct eval of user-supplied code
    // Much harder to bypass with enhanced filtering
    const result = eval(`(function() { return ${code}; })()`);
    res.json({ result: String(result) });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Admin endpoint: returns flag after successful privilege escalation
app.get('/admin/flag', (req, res) => {
  requestCount++;
  if (requestCount > MAX_REQUESTS_PER_MINUTE) {
    return res.status(429).json({ error: 'Too many requests' });
  }

  // In real exploitation, this is reached via deserialization RCE
  // For testing, organizers can manually read the flag
  try {
    const flag = fs.readFileSync('/tmp/flag.txt', 'utf8').trim();
    res.json({ flag });
  } catch (e) {
    res.status(500).json({ error: 'Flag not found' });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'cascade' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`[Cascade] Main app listening on port ${PORT}`);
});