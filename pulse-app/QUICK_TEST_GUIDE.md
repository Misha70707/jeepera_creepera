# Pulse App MVP - Quick Testing Guide (5 min)

**Quick validation before launch**

## Pre-Test Setup

1. Clear app data
2. Restart device/simulator
3. Ensure network connectivity
4. iPhone 14 Simulator (iOS) or Pixel 6 Emulator (Android)

---

## Test Scenario 1: Onboarding (1 min)

### iOS
```
1. Launch app → Onboarding screen appears ✓
2. Tap "Sign in with Apple" button
3. Select "User Profile"
4. Fill name: "Test User"
5. Tap Continue
6. Select 3 routines from list
7. Set notification frequency
8. Tap "Get Started"
```

### Android
```
1. Launch app → Onboarding screen appears ✓
2. Tap "Sign in with Google" button
3. Fill name: "Test User"
4. Select 3 routines
5. Set notifications
6. Tap "Complete Setup"
```

**Expected:** Home screen shows with greeting

---

## Test Scenario 2: Create & Complete Routine (2 min)

### Both Platforms
```
1. Navigate to Routines tab
2. Tap "+ Create Routine"
3. Select emoji (🌅)
4. Enter name: "Test Routine"
5. Add 3 tasks: Exercise, Breakfast, Meditate
6. Tap "Create"
6. Tap "Open" on new routine card
7. Check off each task (should strikethrough)
8. Tap "Finish"
```

**Expected:**
- ✓ Routine appears in list
- ✓ Tasks complete and show strikethrough
- ✓ Confetti animation plays
- ✓ Celebration screen appears
- ✓ Streak increments

---

## Test Scenario 3: Community Post (1 min)

### Both Platforms
```
1. Navigate to Community tab
2. Tribe filter shows "All"
3. Tap "+ Create Post"
4. Select tribe: "Productivity"
5. Type message: "Just completed my routine!"
6. Tap "Share"
7. Post appears in feed
8. Tap heart icon to like
```

**Expected:**
- ✓ Post created successfully
- ✓ Post visible in community feed
- ✓ Like counter increments
- ✓ Proper tribe is shown

---

## Test Scenario 4: Achievements (0.5 min)

### Both Platforms
```
1. Navigate to Achievements tab
2. Check three sub-tabs:
   - Badges (show locked/unlocked)
   - Streaks (show progress bars)
   - Leaderboard (show rankings)
3. Verify user is ranked #5
```

**Expected:**
- ✓ All tabs populate with data
- ✓ Visual hierarchy clear
- ✓ Current user highlighted in leaderboard

---

## Test Scenario 5: Settings & Profile (0.5 min)

### Both Platforms
```
1. Navigate to Settings tab
2. View user profile card
3. Notification frequency dropdown works
4. Dark mode toggle works
5. DND toggle works
```

**Expected:**
- ✓ All settings interactive
- ✓ Toggles change visual state
- ✓ Dropdowns show options

---

## Test Scenario 6: Offline Behavior (1 min)

### iOS/Android Specific
**iOS:**
```
1. Settings → WiFi → Disconnect
2. Create new routine offline
3. Complete a task offline
4. Settings → WiFi → Reconnect
```

**Android:**
```
1. Settings → Network → Airplane Mode ON
2. Create new routine offline
3. Complete a task offline
4. Settings → Network → Airplane Mode OFF
```

**Expected:**
- ✓ App works while offline
- ✓ Changes save locally
- ✓ No crashes or errors
- ✓ (Sync would occur with Firebase enabled)

---

## Smoke Test Checklist ✅

| Test | Pass | Notes |
|------|------|-------|
| App launches without crash | [ ] | |
| Onboarding flow completes | [ ] | |
| Routine creation works | [ ] | |
| Routine completion animates | [ ] | |
| Community post creates | [ ] | |
| Achievements display | [ ] | |
| Settings responsive | [ ] | |
| All tab navigation works | [ ] | |
| Back buttons work | [ ] | |
| No visual glitches | [ ] | |

---

## Critical Issues to Report

🔴 **CRITICAL** (Blocks Launch)
- App crashes on any screen
- Onboarding can't complete
- Routine completion doesn't work
- Data doesn't persist

🟡 **HIGH** (Should Fix)
- Visual bugs or layout issues
- Performance < 2s load time
- Navigation broken
- Audio/animation missing

🟢 **LOW** (Nice to Fix)
- Copy/grammar errors
- Minor layout alignment
- Timing tweaks
- Optional features

---

## Performance Quick Check

| Action | Target | Acceptable |
|--------|--------|-----------|
| App Launch | < 1.5s | < 2s |
| Home Load | < 300ms | < 500ms |
| Routine Open | < 200ms | < 500ms |
| Tab Switch | < 100ms | < 200ms |
| Scroll | 60 FPS | 50+ FPS |

**How to measure:** Use Simulator's timing tools or count seconds manually.

---

## Quick Bug Report Template

```
Platform: iOS / Android
Device: [Model]
Build: [Version]
Date: [Date/Time]

Steps to Reproduce:
1.
2.
3.

Expected Result:
[What should happen]

Actual Result:
[What actually happens]

Screenshots:
[Attached]

Severity: Critical / High / Low
```

---

## Testing Complete ✅

If all smoke tests pass:
1. ✅ Core functionality works
2. ✅ App is stable
3. ✅ UX is polished
4. ✅ Ready for app store submission

**Estimated Testing Time:** 5-10 minutes
**Success Criteria:** All smoke tests pass, no critical issues

---

## Next Steps

- ✅ Pass all smoke tests
- ✅ Log any issues found
- ✅ Approve for submission
- ✅ Deploy to app stores
- ✅ Monitor real user metrics

**Launch Status:** 🚀 READY TO DEPLOY
