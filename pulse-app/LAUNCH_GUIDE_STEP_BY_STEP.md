# 🚀 PULSE APP LAUNCH - COMPLETE STEP-BY-STEP GUIDE

**For First-Time Launchers**
**Estimated Time: 2-3 weeks**

---

## **PHASE 1: FIREBASE SETUP (Days 1-2)**

### **Step 1.1: Create Firebase Project**

1. Go to https://console.firebase.google.com
2. Click **"Add project"**
3. Enter project name: `pulse-app-dev` (for testing)
4. Accept terms, click **Create Project**
5. Wait 5-10 minutes for setup

### **Step 1.2: Enable Firestore Database**

1. In Firebase Console, click **Firestore Database**
2. Click **Create Database**
3. Select **Production mode** (we have rules)
4. Location: **us-central1**
5. Click **Create**

**Expected:** Empty database created

### **Step 1.3: Enable Authentication**

1. Click **Authentication** in left sidebar
2. Click **Get started**
3. Enable **Apple Sign-In**:
   - Click **Apple**
   - Click **Enable**
   - You'll need Apple Developer account (we'll do this later)
4. Enable **Google Sign-In**:
   - Click **Google**
   - Click **Enable**
   - Select your email as support email
   - Click **Save**

**Expected:** Both auth methods enabled

### **Step 1.4: Deploy Firestore Security Rules**

1. In Firebase Console, click **Firestore Database**
2. Click **Rules** tab at top
3. Delete existing rules and paste from `backend/firestore.rules`:

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // ... (paste entire firestore.rules content)
  }
}
```

4. Click **Publish**

**Expected:** Rules deployed without errors

### **Step 1.5: Set Up Cloud Functions**

#### **Install Firebase CLI**
```bash
npm install -g firebase-tools
```

#### **Login to Firebase**
```bash
firebase login
```
(Opens browser, authenticate with your Google account)

#### **Initialize Firebase in your project**
```bash
cd pulse-app/backend
firebase init
```

When prompted:
- Select **Functions** and **Firestore**
- Use existing project: `pulse-app-dev`
- Language: **TypeScript**
- Use ESLint: **Y**

#### **Deploy Cloud Functions**
```bash
firebase deploy --only functions
```

**Expected:** Console shows "Deploy complete!" with function URLs

### **Step 1.6: Get Service Account Key (for later)**

1. In Firebase Console, click **Project Settings** (gear icon)
2. Click **Service Accounts** tab
3. Click **Generate New Private Key**
4. Save as `backend/serviceAccountKey.json`
5. **ADD TO .gitignore!**

```bash
echo "backend/serviceAccountKey.json" >> .gitignore
```

---

## **PHASE 2: iOS APP STORE SETUP (Days 3-5)**

### **Step 2.1: Create Apple Developer Account**

1. Go to https://developer.apple.com
2. Click **Account**
3. Sign in with Apple ID (create if needed)
4. Enroll in **Apple Developer Program** ($99/year)
5. Wait for approval (usually instant)

### **Step 2.2: Create App ID**

1. Log in to https://appstoreconnect.apple.com
2. Click **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → **App IDs**
4. Click **+** button
5. Select **App IDs**, click **Continue**
6. **Bundle ID:** `com.yourcompany.pulse` (must match Xcode)
7. **Capabilities:** Enable **Sign in with Apple**
8. Click **Register**

### **Step 2.3: Create App in App Store Connect**

1. Go to https://appstoreconnect.apple.com
2. Click **My Apps** → **+ New App**
3. Platform: **iOS**
4. **Name:** Pulse
5. **Primary Language:** English
6. **Bundle ID:** Select from dropdown (the one you created)
7. **SKU:** `com.yourcompany.pulse` (any unique ID)
8. Click **Create**

**Expected:** App appears in "My Apps"

### **Step 2.4: Prepare App Information**

On the App Store Connect page, fill in:

**General**
- App Name: `Pulse`
- Subtitle: `Build Better Habits`
- Privacy Policy URL: (create simple one, or use placeholder)

**App Information**
- Category: **Health & Fitness** or **Productivity**
- Age Rating: **4+**
- Copyright: `© 2025 [Your Name]`
- Primary Language: **English (US)**

**Pricing & Availability**
- Pricing Tier: **Free**
- Availability: Select countries (start with US)

### **Step 2.5: Create App Preview & Screenshots**

**iPhone Screenshot Requirements:**
- 1 screenshot minimum (5 maximum)
- Dimensions: 1242 x 2208 px (landscape OK too)

**What to show:**
1. Onboarding screen
2. Home screen with streak
3. Routine completion
4. Community post
5. Achievement unlock

**Options:**
- Use iOS Simulator, take screenshots manually
- Create mockups in Figma
- Or I can help create them

### **Step 2.6: Build & Submit to TestFlight (Internal Testing)**

```bash
# In Xcode:
1. Select "Pulse" scheme (top left)
2. Select "Any iOS Device (arm64)"
3. Product → Archive
4. Click "Distribute App"
5. Select "TestFlight & App Store"
6. Select "Upload"
7. Choose team → Next → Next → Done
```

**Expected:** Build uploaded to App Store Connect (5-10 min)

### **Step 2.7: Submit for App Review**

1. In App Store Connect, click your app
2. Click **App Review Information**
3. Fill in:
   - **Sign in Required:** No
   - **Demo Account:** (leave blank)
   - **Notes:** "First-time health habit tracking app"
   - **Contact Info:** Your email
4. Click **Save**
5. Click **Version 1.0** (left sidebar)
6. Scroll bottom → **Submit for Review**
7. Answer compliance questions (all "No" probably)
8. Click **Submit**

**Expected:** Status changes to "Waiting for Review"

**Review Timeline:** 1-3 business days usually

---

## **PHASE 3: ANDROID PLAY STORE SETUP (Days 3-5)**

### **Step 3.1: Create Google Play Developer Account**

1. Go to https://play.google.com/console
2. Click **Create Account**
3. Pay **$25** (one-time)
4. Complete registration

### **Step 3.2: Create App in Google Play Console**

1. Click **Create App**
2. **App Name:** Pulse
3. **Default Language:** English
4. **App or Game:** App
5. **Free or Paid:** Free
6. Accept policies → **Create App**

### **Step 3.3: Complete App Information**

**App Details**
- **Short Description:** (50 chars max) "Build better daily habits"
- **Full Description:** (4000 chars max) "Pulse helps you create and track routines..."
- **Category:** Health & Fitness
- **Content Rating:** Everyone/4+

**Graphics**
- **App Icon:** 512 x 512 px PNG
- **Feature Graphic:** 1024 x 500 px
- **Screenshots:** 4-8 screenshots
  - Size: 1080 x 1920 px (portrait)
  - Show: Onboarding, Home, Routine, Community, Achievements

### **Step 3.4: Create Signed APK/AAB**

In Android Studio:

```
1. Build → Generate Signed Bundle/APK
2. Select "Android App Bundle"
3. Click "Next"
4. Select "Create new..."
5. Fill in:
   - Key store path: [create new file]
   - Key store password: [secure password]
   - Alias: release_key
   - Password: [same as above]
6. Validity: 30 years (so app doesn't expire)
7. Certificate details: Your name/email
8. Click "Create"
9. Release: Select "Release"
10. Click "Finish"
```

**Expected:** AAB file created in `android/app/release/app-release.aab`

### **Step 3.5: Upload AAB to Google Play**

1. In Google Play Console, click **Testing → Internal Testing**
2. Click **Create new release**
3. **Upload AAB file** (drag and drop your `app-release.aab`)
4. Add **Release Notes:** "Initial MVP release"
5. Click **Save** → **Review Release**
6. Click **Start rollout to Internal Testing**

**Expected:** Build uploaded and testable

### **Step 3.6: Configure Content Rating**

1. In Google Play Console, click **Content Rating**
2. Click **Questionnaire**
3. Select Category: **Health/Medicine**
4. Answer questions (all likely "No")
5. Click **Save Questionnaire** → **Publish Rating**

### **Step 3.7: Add Privacy Policy**

1. Click **Policy & Programs**
2. Click **App Privacy**
3. Enter Privacy Policy URL (required!)
4. Click **Save**

**If you don't have one yet:**
- Use template: https://www.freeprivacypolicy.com/
- Create basic policy
- Host on GitHub or Firebase Hosting

### **Step 3.8: Submit for Review**

1. Click **Release** (in left sidebar)
2. Click **Manage Release**
3. Review **Production** section
4. Click **Create new release**
5. Upload your AAB again (if not already)
6. Add **Release Notes:** "Initial MVP release"
7. Click **Save** → **Review Release**
8. Check **I confirm...** checkbox
9. Click **Start rollout to Production**

**Expected:** Status changes to "Pending publication"

**Review Timeline:** Usually 2-4 hours, but can take up to 24 hours

---

## **PHASE 4: CONFIGURE OAUTH PROVIDERS (Days 5-6)**

### **Step 4.1: Apple Sign-In (iOS)**

1. In Apple Developer portal, click **Identifiers**
2. Select your **App ID**
3. Check **Sign in with Apple** capability
4. Click **Save** → **Confirm**
5. Back in Xcode:
   - Select `ios/Pulse` project
   - Select **Signing & Capabilities**
   - Click **+ Capability**
   - Add **Sign in with Apple**

### **Step 4.2: Google Sign-In (Android)**

1. In Firebase Console, click **Project Settings**
2. Go **Credentials** section
3. Click **Create Credentials** → **OAuth 2.0 Client ID**
4. Application type: **Android**
5. Package name: `com.yourcompany.pulse`
6. SHA-1 fingerprint: Get from Android Studio:
   ```
   ./gradlew signingReport
   ```
   (Copy "release" SHA-1)
7. Click **Create**

---

## **PHASE 5: PRE-LAUNCH CHECKLIST (Day 6)**

**Firebase**
- [ ] Firestore created
- [ ] Security rules deployed
- [ ] Cloud Functions deployed
- [ ] Authentication enabled (Apple + Google)

**iOS**
- [ ] App ID created
- [ ] App created in App Store Connect
- [ ] Screenshots uploaded
- [ ] Build submitted for review

**Android**
- [ ] App created in Google Play Console
- [ ] Screenshots uploaded
- [ ] Privacy policy added
- [ ] AAB submitted for review

**Code**
- [ ] All tests passing
- [ ] No console errors
- [ ] Offline mode working
- [ ] Sync logic tested

**Marketing (Optional)**
- [ ] App name finalized
- [ ] Icon looks good
- [ ] Description written
- [ ] Screenshots clear

---

## **PHASE 6: LAUNCH (Days 7-10)**

### **When App is Approved**

**iOS:**
1. App Store Connect → Your app
2. Click **Version 1.0**
3. Click **Release This Version**
4. Select **Release to App Store** → **Release**
5. Live within hours!

**Android:**
1. Google Play Console → Your app
2. Release → Manage release
3. Click **100% rollout to Production**
4. Live within 2-4 hours!

### **Post-Launch Day 1**

- [ ] Check both app stores for your app
- [ ] Download and test
- [ ] Monitor crash reports
- [ ] Check user feedback/reviews
- [ ] Announce on social media

### **Post-Launch Week 1**

- [ ] Respond to first reviews
- [ ] Monitor analytics
- [ ] Watch for crash reports
- [ ] Plan v1.0.1 if needed
- [ ] Engage with early users

---

## **ESTIMATED TIMELINE**

```
Day 1-2:   Firebase Setup & Deployment
Day 3-5:   App Store & Play Store Setup
Day 5-6:   OAuth Configuration & Testing
Day 6:     Final checks
Day 7-10:  App reviews (parallel process)
Day 10+:   Release & Launch! 🚀
```

**Total: ~2 weeks to live in app stores**

---

## **COMMON ISSUES & FIXES**

### **iOS App Rejected**

**Common reasons:**
- Missing privacy policy → Add URL
- App crashes → Check TestFlight logs
- Sign in doesn't work → Check OAuth config
- Misleading functionality → Update description

**Fix:** Click "Resolution Center" → Follow Apple's feedback

### **Android App Rejected**

**Common reasons:**
- Privacy policy URL broken → Fix URL
- Permission not explained → Add explanation
- Content rating incorrect → Re-do questionnaire

**Fix:** Click "View in Play Console" → Follow feedback

### **App Store Connect Issues**

```
"Bundle ID doesn't match"
→ Check your Xcode project settings
→ Must match App ID created in developer portal

"Screenshots rejected"
→ They need to be at EXACT dimensions
→ Can't have alpha/transparency
→ Must show actual app (not mockups)
```

### **Play Store Issues**

```
"Unsupported architecture"
→ Build AAB, not APK
→ Ensure arm64 is included

"Missing privacy policy"
→ Must have URL that resolves
→ Must be real text (not 404)

"APK signing issue"
→ Use same keystore for all releases
→ Never lose your keystore file!
```

---

## **RESOURCES YOU'LL NEED**

**Accounts to Create:**
- Apple Developer ($99/year)
- Google Play Console ($25 one-time)

**Files to Prepare:**
- App icon (512x512 PNG)
- Screenshots (1080x1920 for Android, 1242x2208 for iOS)
- Privacy policy (text or URL)
- Release notes

**Tools:**
- Xcode (for iOS)
- Android Studio (for Android)
- Firebase CLI (for backend)

---

## **YOU'VE GOT THIS!**

This is literally just:

1. **Click a bunch of buttons** in Firebase
2. **Click a bunch of buttons** in Apple/Google dashboards
3. **Hit deploy** in CLI
4. **Wait 1-2 weeks** for review
5. **Celebrate** 🎉

None of this is hard. It's just **procedural**.

**Next step?** Pick a day to start with Firebase setup. Once Firebase is live, the mobile apps will automatically sync to it.

Ready to pick a start date? 🚀

---

**You need help with ANY of these steps, just holler. I'll walk you through it.**

Let's get this launched, brother! 💪
