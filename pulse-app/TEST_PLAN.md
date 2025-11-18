# Pulse App MVP - Comprehensive Test Plan

**Status:** Phase 4 - Testing & QA
**Target:** 100% critical path coverage
**Date:** November 18, 2025

---

## Executive Summary

This test plan covers unit, integration, UI, and manual testing for the Pulse App MVP across iOS and Android platforms. All tests are designed to verify core functionality without requiring live Firebase setup.

---

## Test Environment Setup

### Prerequisites
- iOS: Xcode 15.0+, iPhone 14 Pro Simulator
- Android: Android Studio 2023+, Pixel 6 Emulator
- Mock Framework: Firebase Emulator Suite (optional)

### Test Data
- 6 routine templates
- 5 achievement types
- 5 community tribes
- Mock user accounts

---

## Unit Testing

### iOS Unit Tests

**Location:** `ios/Tests/`

#### CoreDataManager Tests ✅
```
✓ testSaveRoutine - Verify Core Data persistence
✓ testFetchRoutines - Verify fetch operations
✓ testDeleteRoutine - Verify deletion
✓ testBackgroundContextOperations - Verify concurrent access
✓ testInvalidFetchRequest - Verify error handling
```

**Run:** `xcodebuild test -workspace ios/Pulse.xcworkspace -scheme Pulse`

#### HomeViewModel Tests ✅
```
✓ testGreetingMorning - Time-based greeting (5-12 AM)
✓ testGreetingAfternoon - Time-based greeting (12-5 PM)
✓ testGreetingEvening - Time-based greeting (5-9 PM)
✓ testLoadData - Data loading from mock
✓ testGreetingNotEmpty - Greeting validation
✓ testLoadingState - Loading state management
✓ testCurrentStreakDisplay - Streak data validation
✓ testTodaysRoutinesLoaded - Routine count verification
✓ testRoutineProgress - Progress bar calculation
✓ testWeeklyAchievements - Achievement loading
✓ testCommunityHighlights - Community feed loading
```

**Expected Results:** 16+ tests, 100% pass rate

### Android Unit Tests

**Location:** `android/Tests/`

#### HomeScreenViewModel Tests ✅
```
✓ testGreetingNotEmpty - Greeting present
✓ testGreetingContainsEmoji - Greeting format validation
✓ testTodaysRoutinesLoaded - 2 routines loaded
✓ testFirstRoutineNameCorrect - Correct routine name
✓ testCurrentStreakNotNull - Streak initialized
✓ testStreakHasCorrectEmoji - Emoji validation
✓ testWeeklyAchievementsLoaded - 5+ achievements
✓ testCommunityHighlightsLoaded - Community feed present
✓ testCommunityPostsHaveContent - Post data validation
✓ testRoutineProgressValidRange - Progress 0.0-1.0
✓ testLoadingStateUpdates - State management
```

**Run:** `./gradlew test`

#### RoutineRepository Tests ✅
```
✓ testCreateRoutine - CRUD create operation
✓ testGetAllRoutines - Multiple routine fetch
✓ testGetSingleRoutine - Single routine fetch
✓ testUpdateRoutine - Update operation
✓ testDeleteRoutine - Delete operation
✓ testCompleteTask - Task completion
✓ testSyncStatus - Sync state tracking
✓ testGetIncompleteRoutines - Filter incomplete
```

**Expected Results:** 16+ tests, 100% pass rate

---

## Integration Testing

### Offline-First Sync Tests

**Scenario 1: Create Routine Offline**
1. Disable network (WiFi + cellular)
2. Create new routine with 3 tasks
3. Verify routine saved locally
4. Enable network
5. Verify routine synced to Firestore
6. ✅ Expected: Data persists and syncs

**Scenario 2: Edit Routine Offline**
1. Open existing routine offline
2. Add 2 new tasks
3. Mark 1 task complete
4. Enable network
5. Verify changes synced
6. ✅ Expected: All changes present on remote

**Scenario 3: Complete Task Offline**
1. Load routine offline
2. Complete all tasks
3. Verify completion celebration animates
4. Enable network
5. Verify completion recorded in Firestore
6. ✅ Expected: Streak increments + achievements awarded

### Real-Time Sync Tests

**Scenario 4: Multi-Device Sync**
1. Create post on Device A
2. Verify instant appearance on Device B
3. Like post on Device B
4. Verify like count updates on Device A
5. ✅ Expected: Real-time updates across devices

**Scenario 5: Community Engagement**
1. Create post in Productivity tribe
2. Add comment from another user
3. Verify comment appears in real-time
4. Like comment
5. ✅ Expected: All updates immediate

### Conflict Resolution Tests

**Scenario 6: Last-Write-Wins**
1. Edit routine on Device A (timestamp T1)
2. Simultaneously edit on Device B (timestamp T2)
3. Verify newer timestamp wins
4. ✅ Expected: T2 changes apply if T2 > T1

---

## UI/E2E Testing

### iOS XCUITest Examples

```swift
// Onboarding Flow Test
func testCompleteOnboardingFlow() {
    app.buttons["Sign in with Apple"].tap()
    // ... fill profile
    // ... select routines
    // ... set notifications
    app.buttons["Get Started"].tap()

    // Verify home screen
    XCTAssertTrue(app.staticTexts["Home"].exists)
}

// Routine Completion Test
func testCompleteRoutine() {
    app.buttons["Open"].tap() // Open first routine

    // Complete all tasks
    for _ in 0..<3 {
        app.buttons["Checkbox"].tap()
    }

    app.buttons["Finish"].tap()

    // Verify celebration
    XCTAssertTrue(app.staticTexts["🎉"].exists)
}

// Community Interaction Test
func testCreateAndLikePost() {
    app.tabBars.buttons["Community"].tap()
    app.buttons["+ Create Post"].tap()

    app.textFields["What's on your mind?"].typeText("New post!")
    app.buttons["Share"].tap()

    // Verify post appears
    XCTAssertTrue(app.staticTexts["New post!"].exists)
}
```

### Android Espresso Tests

```kotlin
@Test
fun testOnboardingFlow() {
    onView(withId(R.id.signInAppleButton))
        .check(matches(isDisplayed()))
        .perform(click())

    onView(withId(R.id.nameInput))
        .perform(typeText("Test User"))

    onView(withId(R.id.continueButton))
        .perform(click())

    onView(withId(R.id.homeScreen))
        .check(matches(isDisplayed()))
}

@Test
fun testRoutineCompletion() {
    onView(withId(R.id.openButton))
        .perform(click())

    // Complete tasks
    onView(withId(R.id.taskCheckbox))
        .perform(click())

    onView(withId(R.id.finishButton))
        .perform(click())

    onView(withText("🎉"))
        .check(matches(isDisplayed()))
}
```

---

## Manual Testing Checklist

### Critical User Flows

#### Authentication
- [ ] Sign in with Apple (iOS)
- [ ] Sign in with Google (Android)
- [ ] Create user profile
- [ ] Profile data persists after restart
- [ ] Sign out clears user data

#### Routines Management
- [ ] Create routine with 3+ tasks
- [ ] Edit routine name and emoji
- [ ] Delete routine with confirmation
- [ ] Routine tasks show in correct order
- [ ] Task completion toggles visually
- [ ] Completed tasks show strikethrough

#### Streak & Progress
- [ ] Streak counter increments on routine completion
- [ ] Progress bar updates correctly
- [ ] Streak persists after app restart
- [ ] Streak resets after missed day (24h)

#### Achievements
- [ ] Unlock badge on 7-day streak
- [ ] Achievement notification appears
- [ ] Leaderboard shows user rank
- [ ] Points accumulate correctly

#### Community
- [ ] Create post in tribe
- [ ] Like post (counter increments)
- [ ] Comment appears immediately
- [ ] Tribe filter works
- [ ] Posts visible offline (cached)

#### Settings
- [ ] Change notification frequency
- [ ] Toggle dark mode
- [ ] Edit user profile
- [ ] All preferences persist

#### Offline Behavior
- [ ] App works with network disabled
- [ ] Pending changes queue locally
- [ ] Re-enable network triggers sync
- [ ] Sync status indicator shows

### Performance Benchmarks

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| App Launch | < 2s | — | ⏳ |
| Home Load | < 500ms | — | ⏳ |
| Routine Create | < 200ms | — | ⏳ |
| Post Sync | < 1s | — | ⏳ |
| Scroll (60 FPS) | 60 FPS | — | ⏳ |

### Device Testing

#### iOS
- [ ] iPhone 14 (latest)
- [ ] iPhone 13
- [ ] iPhone SE (small screen)
- [ ] iPad (large screen)
- [ ] Dark mode
- [ ] Light mode
- [ ] Landscape orientation

#### Android
- [ ] Pixel 6 / 6 Pro
- [ ] Samsung Galaxy S23
- [ ] OnePlus 11
- [ ] Different screen sizes
- [ ] Android 11+
- [ ] Dark mode
- [ ] Light mode

### Network Conditions

- [ ] WiFi (normal)
- [ ] 4G (throttled)
- [ ] 3G (slow)
- [ ] Poor signal (transition)
- [ ] Network unavailable
- [ ] Airplane mode

---

## Regression Testing

### After Each Build

1. **Smoke Tests** (5 min)
   - App launches
   - All screens accessible
   - No crashes on navigation

2. **Critical Paths** (10 min)
   - Authentication flow
   - Create routine
   - Complete routine
   - View achievements

3. **Edge Cases** (10 min)
   - Empty states
   - Large data sets
   - Concurrent operations
   - Network transitions

---

## Test Results Template

```
TEST RUN: [Date] [Platform] [Build #]
================================

Unit Tests:
- iOS: 16/16 PASSED ✅
- Android: 16/16 PASSED ✅

Integration Tests:
- Offline Sync: PASSED ✅
- Real-Time Updates: PASSED ✅
- Conflict Resolution: PASSED ✅

UI Tests:
- Onboarding: PASSED ✅
- Routine Completion: PASSED ✅
- Community: PASSED ✅

Manual Testing:
- Critical Flows: 100% ✅
- Performance: ACCEPTABLE ✅
- Device Coverage: COMPLETE ✅

Overall Status: READY FOR LAUNCH ✅
```

---

## Known Issues & Limitations

### Firebase Emulator
- Local testing without live Firebase
- Requires emulator setup for integration tests
- Production rules should be verified separately

### Mock Data
- All data is synthetic
- Real user behavior patterns untested
- Load testing deferred to production monitoring

---

## Sign-Off

**QA Lead:** [Signature]
**Date:** [Date]
**Status:** APPROVED FOR LAUNCH

---

## Next Steps

1. Execute all unit tests (target: 100% pass)
2. Run integration tests (target: 100% pass)
3. Complete manual testing checklist
4. Performance benchmarking
5. Document any issues found
6. Fix critical bugs
7. Approve for app store submission

**Estimated Timeline:** 2-3 days for thorough testing

---

**Test Plan Version:** 1.0
**Last Updated:** November 18, 2025
**Next Review:** Post-launch v1.0.1
