#!/bin/bash
# MEDUSA 2.0 Challenge: Cascade - Flag Seeding Script
# Run BEFORE starting the challenge container to inject the actual flag

set -e

FLAG_FILE="/tmp/flag.txt"
FLAG_CONTENT="${1:-MEDUSA2{s0_m4ny_l4y3r5_t0_peel_b4ck}}"

echo "[*] Seeding flag to $FLAG_FILE"
echo "$FLAG_CONTENT" > "$FLAG_FILE"
chmod 440 "$FLAG_FILE"
chown 1000:1000 "$FLAG_FILE" 2>/dev/null || true

echo "[+] Flag seeded successfully"
echo "[+] Flag file: $FLAG_FILE"
ls -la "$FLAG_FILE"