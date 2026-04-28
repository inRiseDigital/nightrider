This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://github.com/vercel/next.js/tree/canary/packages/create-next-app).

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Tech Stack

Frontend: Next.js (React-based, SSR/SSG for performance).
Backend: Firebase (Auth, Firestore DB, Functions for serverless logic, Storage for images/uploads).
Deployment: Vercel (optimized for Next.js, integrates with Firebase).
Additional: Google Maps API for venue mapping; CAPTCHA (reCAPTCHA via Firebase); ID verification (e.g., Stripe Identity or manual via uploads).

Data Schema (Firestore Collections)

users (Document ID: userId from Firebase Auth)
Fields:
type: string ('explorer' | 'publisher')
email: string
name: string
kycStatus: string ('pending' | 'approved' | 'rejected' | 'spam')
kycDetails: object { idProof: string (Storage URL), addressProof: string, submittedAt: timestamp }
appeals: array of objects { reason: string, submittedAt: timestamp, status: string }
banned: boolean
loginHistory: array of objects { ip: string, time: timestamp, device: string }


venues (Document ID: auto-generated)
Fields:
ownerId: string (userId)
name: string
address: string
coordinates: object { lat: number, lng: number }
status: string ('pending' | 'approved' | 'rejected' | 'banned' | 'duplicate')
photos: array of strings (Storage URLs)
events: array of strings (eventIds)
disputes: array of objects { claimantId: string, reason: string, resolved: boolean }


events (Document ID: auto-generated)
Fields:
publisherId: string
venueId: string
title: string
description: string
date: timestamp
images: array of strings (Storage URLs)
status: string ('draft' | 'pending' | 'approved' | 'rejected' | 'disabled' | 'visible')
scanResults: object { passed: boolean, issues: array of strings (e.g., 'profanity') }
approvals: object { ownerApproved: boolean, adminApproved: boolean, timedOut: boolean }
violations: array of strings


approvals (Subcollection under events/venues for requests)
Document ID: auto-generated
Fields: requesterId: string, targetId: string (venue/event), type: string ('owner' | 'admin'), status: string, timestamp: timestamp

logs (For audits/abuse)
Document ID: auto-generated
Fields: action: string, userId: string, details: object, timestamp: timestamp


Indexes: Composite on status + timestamps for queues; Geo-index on coordinates for duplicates.
Implementation with Next.js + Firebase

Project Structure:
/pages: API routes (/api/* for Firebase Functions proxy); Dashboard pages (/admin, /publisher).
/components: Reusable (e.g., StatusChecklist, MapPicker, ApprovalQueueTable).
/lib: Firebase config, hooks (useAuth, useFirestoreQuery).
/public: Static assets.

Authentication:
Firebase Auth: Email/password + Google; 2FA via Firebase Extensions.
Next.js: Use next-auth with Firebase adapter; Protect routes with middleware (e.g., redirect unauth to login).
Admin: Role check in Firestore (users doc has 'isAdmin: boolean'); IP whitelisting via Functions.

Admin Dashboard (/admin):
Page: Protected, SSR fetch initial data via getServerSideProps.
Components:
UsersOverview: Table with filters (use react-table); Actions trigger Firestore updates/Functions (e.g., banUser).
VenuesPlaces: Map view (Google Maps); Duplicate check via Functions (geohash query for nearby).
KYCManagement: Queue list; Upload handling to Storage; Auto-reject via ML (Firebase ML for ID scan) or manual.
EventQueue: DataGrid with columns; Auto-scan via Functions (profanity API like Perspective); Escalations via scheduled Functions.


Event Publisher Dashboard (/publisher):
Page: Protected, client-side fetches.
Components:
Profile: Formik forms for KYC submit (CAPTCHA via reCAPTCHA); Rate-limit via Functions.
MyPlaces: MapPicker component; Register triggers duplicate check Function.
MyEvents: Event form; Real-time scan preview (client-side debounce + Function call).
IncomingRequests: Notification bell; Approve triggers Firestore update.


Workflow Logic (Firebase Functions):
onCreate(event/venue): Run auto-scan (configurable via Firestore config doc); Check duplicates (geofirestore); Route approvals (send email/push via FCM).
onUpdate(approval): Escalate timeouts (cron job); Secondary admin review post-owner.
Abuse: onWrite monitor rates; Auto-ban patterns (e.g., >10 rejects/day).
Notifications: FCM for real-time; Email via SendGrid integration.

Conflict Mitigations:
Timeouts: Functions cron auto-escalate/reject after 3 days.
Duplicates: Geohash + fuzzy string match (e.g., Levenshtein via npm in Functions).
Spam: Rate limits in Functions; CAPTCHA on forms.
Malicious Approvals: Always final admin scan; Legal disclaimers in TOS (stored in Firestore).
Over-sensitive Filters: User-config per region in admin UI.
Spoofing: API validate coords; Require venue photo geotag match.
Bulk Abuse: Global rate limits; ML anomaly detection.

Security/Performance:
Firestore Rules: Read/write based on auth.uid + roles.
Next.js: API routes secured; Image optimization.
Testing: Unit (Jest) for components; Integration for workflows


### Tech Stack
- **Frontend**: Next.js (React-based, SSR/SSG for performance).
- **Backend**: Firebase (Auth, Firestore DB, Functions for serverless logic, Storage for images/uploads).
- **Deployment**: Firebase Hosting (use `firebase deploy` after setup).
- **Additional**: Mapbox for venue mapping (use your paid account); reCAPTCHA v3 via Firebase App Check (free); ID verification manual via uploads to Storage.

### Deployment Guide (Firebase Hosting with Next.js)
1. Install Firebase CLI: `npm install -g firebase-tools`.
2. Enable web frameworks: `firebase experiments:enable webframeworks`.
3. Init project: `firebase init hosting` (select GitHub integration if needed).
4. Build Next.js: `npm run build`.
5. Deploy: `firebase deploy --only hosting` (handles SSR via Functions automatically).

### reCAPTCHA Guide (v3 with Firebase + Next.js, Free)
1. Create reCAPTCHA v3 site in Google Console (admin console > reCAPTCHA > v3 key).
2. In Firebase Console: Enable App Check > Add reCAPTCHA v3 provider with site key.
3. Install libs: `npm i @firebase/app-check firebase`.
4. Init in Next.js (/lib/firebase.js): 
   ```js
   import { initializeAppCheck, ReCaptchaV3Provider } from 'firebase/app-check';
   const appCheck = initializeAppCheck(app, { provider: new ReCaptchaV3Provider('YOUR_SITE_KEY') });
   ```
5. Use in forms: Wrap API calls with App Check token (getToken()).
6. Verify in Functions: Check context.app in onRequest.

### Data Schema (Firestore Collections)
- **users** (ID: userId from Auth)
  - type: string ('explorer' | 'publisher')
  - email: string
  - name: string
  - kycStatus: string ('pending' | 'approved' | 'rejected' | 'spam')
  - kycDetails: { idProof: string (Storage URL), addressProof: string, submittedAt: timestamp }
  - appeals: [{ reason: string, submittedAt: timestamp, status: string }]
  - banned: boolean
  - loginHistory: [{ ip: string, time: timestamp, device: string }]
  - isAdmin: boolean (for role check)

- **venues** (ID: auto-generated)
  - ownerId: string
  - name: string
  - address: string
  - coordinates: { lat: number, lng: number }
  - status: string ('pending' | 'approved' | 'rejected' | 'banned' | 'duplicate')
  - photos: [string] (Storage URLs)
  - events: [string] (eventIds)
  - disputes: [{ claimantId: string, reason: string, resolved: boolean }]

- **events** (ID: auto-generated)
  - publisherId: string
  - venueId: string
  - title: string
  - description: string
  - date: timestamp
  - images: [string] (Storage URLs)
  - status: string ('draft' | 'pending' | 'approved' | 'rejected' | 'disabled' | 'visible')
  - scanResults: { passed: boolean, issues: [string] }
  - approvals: { ownerApproved: boolean, adminApproved: boolean, timedOut: boolean }
  - violations: [string]

- **approvals** (Subcollection under events/venues)
  - ID: auto-generated
  - requesterId: string, targetId: string, type: string ('owner' | 'admin'), status: string, timestamp: timestamp

- **logs** (For audits/abuse)
  - ID: auto-generated
  - action: string, userId: string, details: object, timestamp: timestamp

- **Indexes**: Composite (status + timestamps); Geo (coordinates via Geofirestore).

### Implementation with Next.js + Firebase
- **Project Structure**:
  - /pages: API routes (/api/* proxy to Functions); Dashboards (/admin, /publisher).
  - /components: Reusable (StatusChecklist, MapPicker with react-map-gl, ApprovalQueueTable).
  - /lib: Firebase config, hooks (useAuth, useFirestoreQuery).
  - /public: Assets.
  - .env.local: MAPBOX_TOKEN=your-key.

- **Authentication**:
  - Firebase Auth: Email/password + Google; 2FA via TOTP (free extension).
  - Next.js: next-auth with Firebase adapter; Middleware protects routes.
  - Admin: Firestore role check (isAdmin); IP whitelisting in Functions.

- **Admin Dashboard (/admin)**:
  - Protected, SSR via getServerSideProps.
  - Components:
    - UsersOverview: react-table filters; Actions update Firestore/Functions (e.g., ban).
    - VenuesPlaces: Mapbox view (react-map-gl); Duplicate check via Functions (geohash).
    - KYCManagement: Queue; Manual review uploads; No auto-ML.
    - EventQueue: DataGrid; Auto-scan via Functions (bad-words npm for profanity); Scheduled escalations.

- **Event Publisher Dashboard (/publisher)**:
  - Protected, client-side fetches.
  - Components:
    - Profile: Formik for KYC (reCAPTCHA v3 token); Rate-limit in Functions.
    - MyPlaces: MapPicker (react-map-gl); Register triggers duplicate Function.
    - MyEvents: Form; Real-time scan (debounce + Function).
    - IncomingRequests: FCM notification; Approve updates Firestore.

- **Workflow Logic (Functions)**:
  - onCreate(event/venue): Auto-scan (Firestore config); Duplicates (geofirestore); Route approvals (FCM push).
  - onUpdate(approval): Cron escalate timeouts; Secondary admin review.
  - Abuse: onWrite rate monitor; Auto-ban (>10 rejects/day).
  - Notifications: FCM only (real-time).

- **Conflict Mitigations**:
  - Timeouts: Cron auto-escalate/reject (3 days).
  - Duplicates: Geohash + Levenshtein (npm in Functions).
  - Spam: Function rate limits; reCAPTCHA on forms.
  - Malicious: Final admin scan; TOS in Firestore.
  - Filters: Configurable in admin UI.
  - Spoofing: Mapbox validate coords; Photo geotag match.
  - Bulk: Global limits; Anomaly detection.

- **Security/Performance**:
  - Firestore Rules: auth.uid + roles.
  - Next.js: Secured APIs; Image opt.
  - Testing: Jest units; Workflow integration.