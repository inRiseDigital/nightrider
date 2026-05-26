# Nightride App — Infrastructure & Server Requirements
**Prepared for:** Nightride / RISE AI  
**Date:** April 2026  
**Prepared by:** Technical Team

---

## 1. Overview

The Nightride platform consists of four components that require infrastructure:

| Component | Type | Hosting |
|---|---|---|
| Mobile App (Flutter) | iOS & Android | App Store / Google Play |
| AI Chat Backend (Python) | Server | VPS / Cloud |
| Web Admin Panel (Next.js) | Web | Firebase Hosting |
| Database & Auth | Cloud | Firebase (Google) |

---

## 2. Servers to Purchase

### 2.1 AI Backend Server (Required)

This is the core server that runs the Nightride AI chat agent. It processes all user messages, connects to Claude AI, and fetches live event data from the database.

**Minimum Specifications:**
- CPU: 2 vCPU cores
- RAM: 4 GB
- Storage: 40 GB SSD
- OS: Ubuntu 22.04 LTS
- Network: 1 Gbps with 3 TB monthly transfer

**Recommended Providers:**

| Provider | Plan | Monthly Cost | Region |
|---|---|---|---|
| Hetzner Cloud | CX22 | €4.35 (~$5) | EU Frankfurt |
| DigitalOcean | Basic Droplet | $24 | EU Amsterdam |
| Google Cloud | e2-medium | $25 | EU / Asia |
| AWS EC2 | t3.medium | $30 | EU Frankfurt |

> **Recommendation:** Hetzner CX22 — best value, enterprise-grade hardware, low latency to Dubai/London.

**Recommended Region:** EU (Frankfurt or London)  
Reason: Central to all target markets — Dubai, Tokyo, London, Melbourne.

---

### 2.2 Domain Name (Required)

A custom domain for the API server (e.g. `api.nightride.app`).

| Provider | Cost |
|---|---|
| Cloudflare | ~$10/year |
| Namecheap | ~$12/year |

**Suggested domains:**
- `api.nightride.app`
- `api.nightrideai.com`

> **Recommendation:** Register through **Cloudflare** — includes free DDoS protection and SSL.

---

## 3. Third-Party Services (Already Integrated)

These are cloud services already connected to the app. No server purchase needed — billed by usage.

### 3.1 Firebase (Google)
**Purpose:** User database, chat history, event storage, authentication  
**Plan:** Spark (Free) → upgrade to **Blaze (Pay-as-you-go)** for production  
**Estimated Cost:** $0–$50/month depending on user volume  
**URL:** firebase.google.com

### 3.2 Anthropic Claude API
**Purpose:** Powers the Nightride AI chat brain  
**Model in Use:** Claude Sonnet (claude-sonnet-4-6)  
**Pricing:** ~$3 per 1M input tokens / ~$15 per 1M output tokens  
**Estimated Cost:** $30–$100/month depending on chat volume  
**URL:** console.anthropic.com

### 3.3 Ticketmaster Discovery API
**Purpose:** Live event data — concerts, DJ nights, festivals (18 countries)  
**Current Key:** Active  
**Free Tier:** 5,000 API calls/day  
**Production Plan:** Contact Ticketmaster for commercial licensing  
**URL:** developer.ticketmaster.com

### 3.4 Mapbox
**Purpose:** Maps and location features in the mobile app  
**Free Tier:** 50,000 map loads/month  
**Estimated Cost:** $0–$25/month  
**URL:** mapbox.com

---

## 4. Monthly Cost Summary

### Minimum (Startup / MVP)

| Item | Cost/Month |
|---|---|
| VPS Server (Hetzner CX22) | $6 |
| Domain Name | $1 |
| Anthropic Claude API | $30–50 |
| Firebase (Blaze) | $10–30 |
| Ticketmaster API | Free |
| Mapbox | Free |
| **Total** | **~$47–87/month** |

### Scaling (10,000+ Active Users)

| Item | Cost/Month |
|---|---|
| VPS Server (upgraded, 4 vCPU / 8GB) | $30–50 |
| Domain + SSL + CDN | $5 |
| Anthropic Claude API | $150–300 |
| Firebase (Blaze) | $50–150 |
| Ticketmaster Commercial License | TBD |
| Mapbox | $25–100 |
| **Total** | **~$260–600/month** |

---

## 5. Target Markets & Infrastructure Notes

The app currently targets the following cities:

| City | Country | Ticketmaster Coverage |
|---|---|---|
| Dubai | UAE | Yes (AE) |
| Tokyo | Japan | Yes (JP) |
| London | UK | Yes (GB) |
| Melbourne | Australia | Yes (AU) |

All four markets are covered by the current Ticketmaster API integration.

---

## 6. Deployment Architecture

```
┌─────────────────────┐     HTTPS      ┌──────────────────────┐
│  Nightride Mobile   │ ─────────────► │  VPS Backend Server  │
│  App (iOS/Android)  │                │  FastAPI + Claude AI  │
└─────────────────────┘                └──────────┬───────────┘
                                                   │
                              ┌────────────────────┼────────────────────┐
                              │                    │                    │
                    ┌─────────▼──────┐  ┌──────────▼──────┐  ┌────────▼────────┐
                    │   Firebase     │  │  Anthropic API  │  │ Ticketmaster API │
                    │  (Firestore +  │  │  (Claude AI)    │  │  (Live Events)   │
                    │    Auth)       │  └─────────────────┘  └─────────────────┘
                    └────────────────┘
```

---

## 7. Immediate Next Steps

1. **Purchase VPS** — Hetzner CX22 or DigitalOcean Droplet
2. **Buy domain** — via Cloudflare
3. **Deploy backend** — copy `Nightride/Agent/` to VPS, start server on port 443 with SSL
4. **Update Flutter app** — change `BACKEND_URL` to the new domain
5. **Upgrade Firebase** — switch to Blaze plan before launch
6. **Apply for Ticketmaster commercial API** — required for production use

---

## 8. Contact & Support

For technical deployment assistance, contact the development team.  
All source code is located in the `Nightride/` directory of the project repository.

---

*Document generated by RISE AI Technical Team — Nightride Platform*
