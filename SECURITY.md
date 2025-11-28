# Security Policy

CodeForge AI takes security seriously. This document outlines our security practices and how to report vulnerabilities.

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

**Note**: Pre-release versions (alpha, beta) are not guaranteed to receive security patches. Please update to the stable release.

## Reporting a Vulnerability

**DO NOT** create a public GitHub issue for security vulnerabilities.

### How to Report

**Email**: security@codeforgeai.app

**PGP Key**: [Available on request]

### What to Include

Please provide as much information as possible:

1. **Description**: Clear description of the vulnerability
2. **Type**: Category (e.g., XSS, SQL injection, authentication bypass)
3. **Impact**: Potential damage or exploitation scenario
4. **Affected Components**: Which parts of the system are vulnerable
5. **Reproduction Steps**: Detailed steps to reproduce the issue
6. **Proof of Concept**: Code, screenshots, or video demonstration
7. **Suggested Fix**: If you have ideas for remediation
8. **Your Contact Info**: For follow-up questions

### Example Report

```
Subject: [SECURITY] Authentication bypass in API

Description:
The /v1/user/profile endpoint does not properly validate JWT tokens,
allowing unauthenticated access to user profiles.

Type: Authentication Bypass

Impact:
An attacker can read any user's profile data including email and
usage statistics by sending a request with an expired or malformed token.

Affected Components:
- Backend API: Auth middleware (auth.middleware.ts)
- Endpoint: GET /v1/user/profile

Reproduction Steps:
1. Send GET request to https://api.codeforgeai.app/v1/user/profile
2. Include header: Authorization: Bearer expired_or_invalid_token
3. Response: 200 OK with user profile data (should be 401 Unauthorized)

Proof of Concept:
curl -H "Authorization: Bearer invalid_token" \
  https://api.codeforgeai.app/v1/user/profile

Suggested Fix:
Update auth middleware to properly validate token expiration and signature.

Contact: researcher@example.com
```

## Response Timeline

1. **Acknowledgment**: Within 48 hours of report
2. **Initial Assessment**: Within 5 business days
3. **Status Update**: Every 7 days until resolved
4. **Fix Development**: Depends on severity (see below)
5. **Disclosure**: Coordinated disclosure after fix is deployed

### Severity Levels

**Critical** (CVSS 9.0-10.0)
- Fix timeline: 24-48 hours
- Examples: Remote code execution, authentication bypass

**High** (CVSS 7.0-8.9)
- Fix timeline: 7 days
- Examples: Privilege escalation, SQL injection

**Medium** (CVSS 4.0-6.9)
- Fix timeline: 30 days
- Examples: XSS, CSRF

**Low** (CVSS 0.1-3.9)
- Fix timeline: 90 days
- Examples: Information disclosure (non-sensitive)

## Disclosure Policy

### Coordinated Disclosure

We follow coordinated disclosure:

1. **Report received** → Security team investigates
2. **Vulnerability confirmed** → Fix developed and tested
3. **Patch released** → Users notified to update
4. **Public disclosure** → 30 days after patch (or sooner if agreed)

### Public Disclosure

After the fix is released, we will:
- Publish a security advisory on GitHub
- Credit the researcher (unless anonymity requested)
- Update this document with mitigation advice

## Security Best Practices

### For Users

**Mobile App**:
- Keep the app updated to the latest version
- Enable device passcode/biometric lock
- Don't jailbreak/root your device (weakens security)
- Review app permissions regularly
- Use official app stores only (no sideloading)

**Account Security**:
- Use strong authentication (Google/Apple Sign-In preferred)
- Enable two-factor authentication (if available)
- Review connected devices periodically
- Don't share account credentials

**Data Privacy**:
- Review privacy settings in the app
- Understand what data is synced to the cloud
- Use offline mode for sensitive code
- Regularly export and backup your projects

### For Developers

**Code Security**:
- Never commit API keys, secrets, or credentials
- Use `.env` files and add them to `.gitignore`
- Store secrets in secure vaults (Keychain, Keystore)
- Validate all user inputs
- Use parameterized queries (prevent SQL injection)
- Sanitize outputs (prevent XSS)
- Implement rate limiting on API endpoints

**Authentication**:
- Use OAuth 2.0 with PKCE flow
- Implement JWT token expiration (15 minutes)
- Rotate refresh tokens
- Use HTTPS/TLS 1.3 only
- Pin API certificates in mobile apps

**Data Protection**:
- Encrypt sensitive data at rest (AES-256)
- Use TLS for data in transit
- Implement proper access controls (RBAC)
- Log security events (failed logins, etc.)
- Anonymize user data before sending to AI models

**Dependencies**:
- Keep dependencies updated
- Run security scans: `npm audit`, `snyk test`
- Review dependency licenses
- Use lock files (package-lock.json, Podfile.lock)

**CI/CD Security**:
- Scan for secrets in commits (e.g., `git-secrets`)
- Run SAST (Static Application Security Testing)
- Run DAST (Dynamic Application Security Testing)
- Require code reviews for all changes
- Use signed commits (GPG)

## Known Security Features

### Mobile App

**iOS**:
- Keychain for token storage (hardware-backed encryption)
- Face ID / Touch ID for app unlock (optional)
- Certificate pinning for API calls
- App Transport Security (ATS) enforced
- Jailbreak detection (warning only)

**Android**:
- Android Keystore for token storage
- Biometric authentication for app unlock (optional)
- Certificate pinning for API calls
- Network Security Config (enforces HTTPS)
- Root detection (warning only)

### Backend

**API Security**:
- OAuth 2.0 authentication
- JWT tokens with short expiration
- Rate limiting (per-user and per-IP)
- CORS policy (whitelist mobile apps only)
- Input validation on all endpoints
- SQL injection prevention (parameterized queries)
- XSS prevention (Content Security Policy headers)

**Infrastructure**:
- DDoS protection (Cloud Armor / AWS Shield)
- Web Application Firewall (WAF)
- TLS 1.3 with strong cipher suites
- Regular security audits (annual penetration testing)
- Automated vulnerability scanning (Snyk, Dependabot)

### Data Privacy

- End-to-end encryption for sensitive data (optional)
- Code anonymization before AI processing
- No code retention by AI provider (contractual)
- GDPR/CCPA compliance (user data export, deletion)
- Minimal data collection (privacy-by-design)

## Security Audits

### Internal Audits
- Quarterly security reviews
- Automated dependency scanning (continuous)
- SAST/DAST in CI/CD pipeline

### External Audits
- Annual third-party penetration testing
- Compliance audits (GDPR, CCPA)
- Bug bounty program (post-launch)

## Bug Bounty Program

**Status**: Coming soon (after public launch)

We plan to launch a bug bounty program on:
- [HackerOne](https://hackerone.com/) or
- [Bugcrowd](https://www.bugcrowd.com/)

**Scope** (planned):
- Mobile apps (Android, iOS)
- Backend API (api.codeforgeai.app)
- Web app (app.codeforgeai.app)

**Out of Scope**:
- Third-party services (Google, Apple, OpenAI)
- Social engineering attacks
- Physical attacks
- Denial of Service (DoS)

**Rewards** (planned):
- Critical: $500 - $5,000
- High: $250 - $500
- Medium: $100 - $250
- Low: Recognition only

## Incident Response

### In Case of a Breach

If a security incident occurs, we will:

1. **Immediate Response** (within 1 hour)
   - Isolate affected systems
   - Stop the attack/breach
   - Preserve evidence for investigation

2. **Assessment** (within 24 hours)
   - Determine scope of breach
   - Identify compromised data
   - Assess impact on users

3. **Notification** (within 72 hours, per GDPR)
   - Notify affected users via email
   - Provide details of breach
   - Advise on protective measures
   - Notify regulators if required

4. **Remediation**
   - Deploy security patches
   - Reset compromised credentials
   - Enhance security controls
   - Conduct post-mortem

5. **Public Disclosure**
   - Publish incident report (after remediation)
   - Explain what happened and why
   - Detail steps taken to prevent recurrence

### User Actions After Breach

If you receive a breach notification:
1. **Change your password** (if applicable)
2. **Review account activity** for unauthorized access
3. **Enable two-factor authentication** (if available)
4. **Monitor for phishing** attempts using your email
5. **Contact support** if you notice suspicious activity

## Security Contact

**Email**: security@codeforgeai.app

**PGP Key**: Available on request

**Response Time**: Within 48 hours (business days)

**Escalation**: If no response within 48 hours, contact: escalation@codeforgeai.app

## Hall of Fame

We recognize security researchers who responsibly disclose vulnerabilities:

*(No entries yet - be the first!)*

---

**Last Updated**: 2025-11-28

**Version**: 1.0.0

For questions about this security policy, email security@codeforgeai.app
