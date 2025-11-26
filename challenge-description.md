# Cascade - Hard Web Challenge

## Challenge Information
- **Name:** Cascade
- **Category:** Web Exploitation
- **Difficulty:** Hard
- **Points:** 500
- **Author:** MEDUSA 2.0 CTF Team

---

## Description

You've discovered an internal web application with multiple security layers. The developers thought they were being clever by implementing various "security" measures, but are they really secure?

Your goal: Read the flag from `/tmp/flag.txt` on the server.

The application appears to be some kind of user management system. Start exploring and see what interesting functionality you can discover. There might be more than meets the eye...

---

## Connection Information

**Target:** `http://[CHALLENGE_IP]:3000`

**Flag Format:** `MEDUSA2{...}`

---

## Hints

### Hint 1 (Available after 2 hours - Free)
> The application might be making requests to places you can't directly reach. What if you could control where it fetches data from?

### Hint 2 (Available after 4 hours - Costs 50 points)
> Found a way to execute code? Check what security filters are in place. JavaScript has many ways to represent the same thing.

### Hint 3 (Available after 6 hours - Costs 100 points)
> Services behind firewalls often trust each other. If something requires authentication, look for patterns in how tokens or signatures are generated.

---

## Notes

- Rate limiting is in place (100 requests/minute)
- The challenge resets every 30 minutes if needed
- No brute forcing required
- All exploitation is achievable through the web interface

---

## Support

If you're stuck or encounter technical issues, contact the CTF organizers
Good luck! 🚀
