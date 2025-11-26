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
const rateLimit = require('express-rate-limit');

const app = express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Simple in-memory user store
const users = {
  'user1': { id: 1, username: 'user1', email: 'user1@example.com', bio: 'Hello world' },
  'user2': { id: 2, username: 'user2', email: 'user2@example.com', bio: 'Another user' }
};

// Rate limiting configuration to prevent brute force attacks
const strictLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 10, // 10 requests per minute per IP
  message: { error: 'Too many requests, please try again later' },
  standardHeaders: true,
  legacyHeaders: false,
});

const moderateLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 30, // 30 requests per minute per IP
  message: { error: 'Rate limit exceeded' },
  standardHeaders: true,
  legacyHeaders: false,
});

// VULNERABILITY 1: Server-Side Template Injection (SSTI) in /profile
// Unsafely renders user-supplied template data
app.get('/profile/:username', moderateLimiter, (req, res) => {
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
    
    // VULNERABILITY 1: Removed direct access to dangerous globals
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
app.get('/fetch', strictLimiter, (req, res) => {
  const url = req.query.url;
  const signature = req.query.sig;
  
  if (!url) {
    return res.status(400).json({ error: 'Missing url parameter' });
  }

  // Enhanced URL validation - blocks obvious patterns but allows encoding bypasses
  // Allows: 127.1, 0x7f.1, 0x7f000001, 2130706433 (decimal IP), etc.
  const blockedPatterns = [
    'file://', '..', 
    'localhost',    // blocks "localhost" string
    '127.0.0.1',    // blocks full dotted notation
    '0.0.0.0',      // blocks wildcard
    '::1',          // blocks IPv6 localhost
    'metadata'      // blocks cloud metadata
  ];
  
  const urlLower = url.toLowerCase();
  for (const pattern of blockedPatterns) {
    if (urlLower.includes(pattern)) {
      return res.status(403).json({ error: 'Blocked URL pattern' });
    }
  }
  
  // Additional check: block if it looks like internal RFC1918 addresses
  // But allow encoded versions
  if (/(?:^|\.)10\./.test(urlLower) || 
      /(?:^|\.)192\.168\./.test(urlLower) || 
      /(?:^|\.)172\.(?:1[6-9]|2[0-9]|3[01])\./.test(urlLower)) {
    return res.status(403).json({ error: 'Private IP range blocked' });
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
app.post('/eval', strictLimiter, express.json(), (req, res) => {
  const code = req.body.code;
  
  if (!code) {
    return res.status(400).json({ error: 'Missing code parameter' });
  }

  // Moderate blacklist - blocks dangerous keywords but allows encoding bypass
  const blacklist = [
    'require', 'process', 'child_process',
    'import', 'Function', 'constructor', 'prototype',
    '__proto__', 'exec', 'spawn', 'fork'
  ];

  // Check for direct keyword matches (case-insensitive)
  for (const keyword of blacklist) {
    if (code.toLowerCase().includes(keyword.toLowerCase())) {
      return res.status(403).json({ error: 'Blocked keyword: ' + keyword });
    }
  }
  
  // Block SOME encoding patterns (but allow hex escape which is the intended bypass)
  const encodingPatterns = [
    /String\.fromCharCode/i,       // Block obvious character conversion
    /fromCharCode/i,
    /String\[/,                    // Block bracket notation: String['fromCharCode']
    /\+\s*["'`]/,                  // Block string concatenation: 'req' + 'uire'
    /atob|btoa/i,                  // Block base64 encoding functions
    /unescape|decodeURI/i,         // Block URI/escape decoding
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
/*
app.get('/admin/flag', strictLimiter, (req, res) => {
  // In real exploitation, this is reached via deserialization RCE
  // For testing, organizers can manually read the flag
  try {
    const flag = fs.readFileSync('/tmp/flag.txt', 'utf8').trim();
    res.json({ flag });
  } catch (e) {
    res.status(500).json({ error: 'Flag not found' });
  }
});

*/
// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'cascade' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`[Cascade] Main app listening on port ${PORT}`);
});