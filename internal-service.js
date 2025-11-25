/**
 * MEDUSA 2.0 Challenge: Cascade - Internal Service
 * Runs on localhost:3001 (not exposed to the public)
 * Serves serialized gadget chain that triggers RCE when deserialized
 */

const express = require('express');
const app = express();

// Health endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'internal' });
});

// VULNERABILITY: Serves a crafted serialized object that, when deserialized,
// allows code execution. This simulates a real gadget chain or unsafe deserialization pattern.
app.get('/data', (req, res) => {
  const token = req.query.token;
  const timestamp = req.query.ts;
  
  // Time-based challenge (must be within 60 seconds)
  const now = Math.floor(Date.now() / 1000);
  if (!timestamp || Math.abs(now - parseInt(timestamp)) > 60) {
    return res.status(401).json({ error: 'Invalid or expired timestamp' });
  }
  
  // Token verification (must know the algorithm)
  const crypto = require('crypto');
  const expectedToken = crypto.createHash('sha256')
    .update(`internal_${timestamp}_cascade`)
    .digest('hex')
    .substring(0, 16);
  
  if (!token || token !== expectedToken) {
    return res.status(403).json({ 
      error: 'Invalid token',
      hint: 'Token algorithm: sha256("internal_" + timestamp + "_cascade")[:16]'
    });
  }

  // Encrypted payload - requires decryption
  const payload = {
    __proto__: {
      exec: true
    },
    // Encoded and obfuscated RCE vector
    encrypted: Buffer.from('ZnMucmVhZEZpbGVTeW5jKCIvdG1wL2ZsYWcudHh0IiwgInV0ZjgiKQ==', 'base64').toString('hex'),
    algorithm: 'hex->base64->utf8',
    hint: 'Decode and reconstruct the payload'
  };

  // Add additional obfuscation layer
  const obfuscatedPayload = Buffer.from(JSON.stringify(payload)).toString('base64');
  
  res.json({ 
    data: obfuscatedPayload,
    encoding: 'base64',
    message: 'Decrypt the payload to proceed'
  });
});

const PORT = 3001;
app.listen(PORT, 'localhost', () => {
  console.log(`[Internal Service] Listening on localhost:${PORT}`);
});