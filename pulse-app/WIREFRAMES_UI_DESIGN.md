# Pulse App - Wireframes & UI Design Specification

## Overview
This document provides detailed wireframe specifications for all primary screens in the Pulse MVP. Each screen includes layout, components, interactions, and design notes.

---

## **Visual Design System**

### **Color Palette**
| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| **Primary Brand** | Vibrant Cyan | `#00D4FF` | CTAs, highlights, badges |
| **Background (Dark)** | Deep Navy | `#0A1428` | Main app background |
| **Surface (Card)** | Charcoal | `#1A1F2E` | Cards, modals, inputs |
| **Text Primary** | Off-White | `#E8ECEF` | Main content |
| **Text Secondary** | Silver | `#A0A8B2` | Secondary info |
| **Accent Success** | Lime Green | `#4AEE6F` | Achievements, completed |
| **Accent Warning** | Amber | `#FFA500` | Alerts, pending |
| **Accent Error** | Coral Red | `#FF6B6B` | Errors, inactive |
| **Separator** | Slate | `#2D3748` | Dividers, borders |

### **Typography**
- **Display Font:** SF Pro Display (iOS), Roboto (Android) — Bold, 24-32px
- **Heading Font:** SF Pro Text (iOS), Roboto (Android) — Semibold, 18-20px
- **Body Font:** SF Pro Text (iOS), Roboto (Android) — Regular, 14-16px
- **Caption Font:** SF Pro Text (iOS), Roboto (Android) — Regular, 12px

### **Spacing & Grid**
- **Base Unit:** 8px (multiples: 8, 16, 24, 32, 40, 48)
- **Safe Areas:** 16px horizontal padding (mobile), 24px (tablet)
- **Corner Radius:** 12px (cards), 8px (buttons), 4px (small elements)
- **Shadow:** `0 4px 12px rgba(0, 0, 0, 0.3)` (cards), `0 2px 4px rgba(0, 0, 0, 0.2)` (buttons)

---

## **Core Screens**

### **1. Onboarding Flow**

#### **Screen 1.1: Welcome Screen**

**Purpose:** First impression, brand introduction

**Layout:**
```
┌────────────────────────────────┐
│                                │
│  [Pulse Logo - Large, Animated]│  (Top 35%)
│                                │
│  "Your Personal AI Assistant   │
│   for Daily Excellence"        │
│                                │  (Text Section)
│  "Automate habits, connect with│
│   communities, unlock your     │
│   potential—all on your device."
│                                │
│  [Sign in with Apple]          │  (CTA Section)
│  [Sign in with Google]         │
│                                │
│  "Privacy-first. On-device. Yours."
│                                │
└────────────────────────────────┘
```

**Components:**
- **Pulse Logo Animation:** 2.5s loop, cyan glow effect, subtle pulsing
- **Headline:** SF Pro Display, 28px, bold, `#E8ECEF`
- **Subheading:** SF Pro Text, 16px, regular, `#A0A8B2`
- **CTA Buttons:** Full-width, 48px height, `#00D4FF` background, rounded corners 8px
- **Privacy Badge:** SF Pro Text, 12px, `#A0A8B2`, centered

**Interactions:**
- Buttons have subtle hover/tap animation (scale 0.98)
- Logo pulses on first load (3x then stops)
- Bottom text fades in after 1s delay

**Design Notes:**
- Keep it minimal; avoid information overload
- Emphasize privacy & local-first approach
- Animation should feel playful, not jarring

---

#### **Screen 1.2: Profile Setup**

**Purpose:** Gather basic user info, personalize experience

**Layout:**
```
┌────────────────────────────────┐
│ < Back                    Skip >│  (Header)
│                                │
│ "Let's Set Up Your Profile"    │  (Title)
│ "Just a few quick questions"   │  (Subtitle)
│                                │
│ ┌────────────────────────────┐ │
│ │ [Profile Photo Placeholder]│ │  (Photo Input)
│ │  Tap to upload             │ │
│ └────────────────────────────┘ │
│                                │
│ ┌────────────────────────────┐ │
│ │ Name                       │ │  (Text Input)
│ │ [____________]             │ │
│ └────────────────────────────┘ │
│                                │
│ ┌────────────────────────────┐ │
│ │ Primary Focus?             │ │  (Select Input)
│ │ ▼ Productivity             │ │
│ └────────────────────────────┘ │
│                                │
│ ┌────────────────────────────┐ │
│ │ ☐ Creator/Influencer       │ │  (Checkbox Group)
│ │ ☐ Parent/Family-focused    │ │
│ │ ☐ Health/Fitness-focused   │ │
│ │ ☐ Hobbyist/Niche-focused   │ │
│ └────────────────────────────┘ │
│                                │
│                  [Continue >>]  │  (CTA Button)
│                                │
└────────────────────────────────┘
```

**Components:**
- **Profile Photo:** Circle, 96px, border `#00D4FF` 2px, tap to upload
- **Text Inputs:** Full-width, background `#1A1F2E`, border `#2D3748` 1px, padding 12px, focus border `#00D4FF`
- **Dropdown Select:** Full-width, chevron icon on right
- **Checkboxes:** 16x16px, checked state `#4AEE6F`, label text `#E8ECEF`
- **Continue Button:** Full-width, `#00D4FF` background, 48px height

**Interactions:**
- Checkboxes allow multiple selections
- Dropdown opens picker on tap
- Form validates before allowing continue
- All fields optional except Name

**Design Notes:**
- Add icons next to focus areas (laptop for productivity, camera for creator, etc.)
- Show progress bar: "Step 1 of 3"
- Reorder based on persona selection

---

#### **Screen 1.3: Routine Selection**

**Purpose:** Choose initial routine templates

**Layout:**
```
┌────────────────────────────────┐
│ < Back                    Skip >│  (Header)
│                                │
│ "Choose Your First Routines"   │  (Title)
│ "Pick one or more to get started"
│                                │
│ ┌────────────────────────────┐ │
│ │ 📅 Morning Routine         │ │  (Routine Card)
│ │                            │ │
│ │ Exercise → Breakfast →     │ │
│ │ Meditation → Work          │ │
│ │                      [Add] │ │
│ └────────────────────────────┘ │
│                                │
│ ┌────────────────────────────┐ │
│ │ 🎯 Productivity Boost      │ │  (Routine Card)
│ │                            │ │
│ │ Focus Session → Break →    │ │
│ │ Review Progress            │ │
│ │                      [Add] │ │
│ └────────────────────────────┘ │
│                                │
│ ┌────────────────────────────┐ │
│ │ 🌙 Evening Wind-down       │ │  (Routine Card)
│ │                            │ │
│ │ Review Day → Reflection →  │ │
│ │ Sleep Prep                 │ │
│ │                      [Add] │ │
│ └────────────────────────────┘ │
│                                │
│                  [Continue >>]  │  (CTA Button)
│                                │
└────────────────────────────────┘
```

**Components:**
- **Routine Card:** 100% width, background `#1A1F2E`, padding 16px, corner radius 12px, border `#2D3748`
- **Routine Icon:** 28px, emoji or custom icon
- **Routine Title:** SF Pro Display, 16px, bold, `#E8ECEF`
- **Routine Description:** SF Pro Text, 14px, regular, `#A0A8B2`
- **Add Button:** 40px, background `#00D4FF`, rounded 8px, icon "+"
- **Card Tap Animation:** Slight lift effect on tap, selection state shows `#00D4FF` left border

**Interactions:**
- Tap "Add" button to select routine
- Selected routines highlight with checkmark or left border
- Can select multiple routines
- Skip allows continuing without any routine

**Design Notes:**
- Cards personalized based on focus area selected in previous screen
- Show estimated time per routine (e.g., "15 min")
- Allow custom routine creation after MVP launch

---

#### **Screen 1.4: Notification Preferences**

**Purpose:** Set notification frequency & style

**Layout:**
```
┌────────────────────────────────┐
│ < Back                    Skip >│  (Header)
│                                │
│ "Notification Preferences"     │  (Title)
│ "Choose how Pulse reminds you" │  (Subtitle)
│                                │
│ ┌────────────────────────────┐ │
│ │ Reminder Frequency         │ │  (Toggle Group)
│ │                            │ │
│ │ ☉ Gentle (1 reminder/day)  │ │
│ │ ◉ Balanced (3-5 per day)   │ │  (Selected)
│ │ ☉ Assertive (10+ per day)  │ │
│ └────────────────────────────┘ │
│                                │
│ ┌────────────────────────────┐ │
│ │ Notification Style         │ │  (Toggle Group)
│ │                            │ │
│ │ ◉ Text + Emoji + Sound     │ │  (Selected)
│ │ ☉ Text + Emoji             │ │
│ │ ☉ Silent (badge only)      │ │
│ └────────────────────────────┘ │
│                                │
│ ┌────────────────────────────┐ │
│ │ Do Not Disturb             │ │  (Time Range)
│ │ 22:00 - 08:00              │ │
│ │ [Edit]                     │ │
│ └────────────────────────────┘ │
│                                │
│ ☑ Allow sound notifications    │  (Checkbox)
│                                │
│          [Complete Setup!]      │  (CTA Button)
│                                │
└────────────────────────────────┘
```

**Components:**
- **Radio Button Group:** Circle buttons, selected state filled `#00D4FF`
- **Checkbox:** 16x16px, checked state `#4AEE6F`
- **Time Input:** Shows "22:00 - 08:00", tappable to edit
- **Complete Button:** Full-width, `#00D4FF` background, 48px height

**Interactions:**
- Radio buttons mutually exclusive within groups
- Tapping time range opens time picker
- Checkbox toggles sound setting
- "Complete Setup!" transitions to home screen

**Design Notes:**
- Show example notifications for each style choice
- DND (Do Not Disturb) uses system time format (24-hour or 12-hour based on locale)
- Include "Test Notification" button to preview

---

### **2. Home Screen (Dashboard)**

**Purpose:** Central hub, quick access to routines, quick stats, community highlights

**Layout:**
```
┌────────────────────────────────┐
│ Pulse      Search        Settings│  (Header)
│                                │
│ "Good morning, Alex! 🌅"       │  (Greeting)
│                                │
│ ┌────────────────────────────┐ │
│ │ 🔥 4-Day Streak            │ │  (Streak Card)
│ │ You're on 🔥! Keep it up!  │ │
│ └────────────────────────────┘ │
│                                │
│ 📋 TODAY'S ROUTINES            │  (Section Header)
│                                │
│ ┌────────────────────────────┐ │
│ │ Morning Routine       [60%] │ │  (Routine Progress)
│ │ ✓ Exercise            [✓]  │ │
│ │ ✓ Breakfast           [✓]  │ │
│ │ ○ Meditation          [ ]  │ │
│ │                      [Open]│ │
│ └────────────────────────────┘ │
│                                │
│ ┌────────────────────────────┐ │
│ │ Productivity Boost    [20%] │ │  (Routine Progress)
│ │ ○ Focus Session       [ ]  │ │
│ │                      [Open]│ │
│ └────────────────────────────┘ │
│                                │
│ 🎖️ THIS WEEK'S ACHIEVEMENTS   │  (Section Header)
│                                │
│ ┌─┬─┬─┬─┐                      │
│ │⭐│⭐│🏆│ │ (Badge Grid)       │
│ └─┴─┴─┴─┘                      │
│                                │
│ 👥 COMMUNITY HIGHLIGHTS        │  (Section Header)
│                                │
│ ┌────────────────────────────┐ │
│ │ @maya_creates shared:      │ │  (Community Post)
│ │ "Just hit 30-day streak!" │ │
│ │ 🔥❤️ 2.1K reactions        │ │
│ │                    [View]  │ │
│ └────────────────────────────┘ │
│                                │
└────────────────────────────────┘
```

**Components:**
- **Header:** Navigation bar with Pulse logo (left), search icon (center-right), settings gear (right)
- **Greeting:** Dynamic based on time of day, includes name & emoji
- **Streak Card:** Highlight card, `#1A1F2E` background, `#00D4FF` accent, flame emoji, current streak count
- **Section Headers:** SF Pro Display, 16px, bold, `#E8ECEF`, with section icon
- **Routine Card:** Progress bar (background `#2D3748`, filled `#00D4FF`), checkbox list, percentage complete, "Open" button
- **Achievement Badge:** 32x32px, emoji/icon, hover shows tooltip with achievement name
- **Community Post:** Background `#1A1F2E`, rounded corners 8px, username + avatar (24px), post text, reaction count, "View" button
- **Bottom Tab Bar:** 5 icons (Home, Routines, Community, Achievements, Settings), active state `#00D4FF`

**Interactions:**
- Pull-down refresh on home screen
- Tap "Open" on routine card opens detailed routine view
- Tap achievement badge shows details modal
- Tap community post expands post detail view
- Bottom tab navigation switches between main sections

**Design Notes:**
- Greeting updates based on time: "Good morning" (5 AM - 12 PM), "Good afternoon" (12 PM - 5 PM), "Good evening" (5 PM - 9 PM), "Burning the midnight oil?" (9 PM - 5 AM)
- Routine progress auto-updates when tasks are checked
- Community highlights refresh daily
- Show "no routines for today" placeholder if none exist

---

### **3. Routine Detail Screen**

**Purpose:** Execute routine, check off tasks, view progress, exit triggers

**Layout:**
```
┌────────────────────────────────┐
│ < Home          [⋮] Settings   │  (Header)
│                                │
│ 📅 Morning Routine             │  (Routine Title)
│ Started at 7:45 AM             │  (Start Time)
│                                │
│ Progress: 60% (3/5 tasks) ████░│  (Progress Bar)
│                                │
│ ┌────────────────────────────┐ │
│ │ ✓ Exercise (7:45 - 8:15)  │ │  (Completed Task)
│ │   Duration: 30 min         │ │
│ │                            │ │
│ │ ✓ Breakfast (8:15 - 8:45) │ │
│ │   Duration: 30 min         │ │
│ │                            │ │
│ │ ○ Meditation               │ │  (Current Task)
│ │   Set a timer... [15 min]  │ │
│ │   [Start]                  │ │
│ │                            │ │
│ │ ○ Journaling               │ │  (Pending Task)
│ │                            │ │
│ │ ○ Review Calendar          │ │  (Pending Task)
│ └────────────────────────────┘ │
│                                │
│ [Skip Task]  [Finish Routine]  │  (Action Buttons)
│                                │
└────────────────────────────────┘
```

**Components:**
- **Header:** Back button (left), routine title (center), menu icon (right)
- **Routine Title:** SF Pro Display, 20px, bold, `#E8ECEF`
- **Start Time:** SF Pro Text, 14px, `#A0A8B2`
- **Progress Bar:** Full-width, background `#2D3748`, filled `#00D4FF`, 8px height, rounded corners
- **Task Item:**
  - Completed: `#4AEE6F` checkmark, text strikethrough `#A0A8B2`
  - Current: `#00D4FF` circle, text `#E8ECEF`, timer button highlighted
  - Pending: Gray circle, text `#A0A8B2`
  - Padding: 16px, background `#1A1F2E`, border `#2D3748`, margin 8px, radius 8px
- **Timer Input:** Shows duration (e.g., "15 min"), tappable to edit
- **Start Button:** 40px, background `#00D4FF`, rounded 8px, icon or "Start"
- **Skip Button:** Outlined style, border `#2D3748`, text `#A0A8B2`
- **Finish Button:** Full-width, background `#4AEE6F`, 48px height, text "🎉 Finish Routine"

**Interactions:**
- Tap task to mark complete/incomplete
- Tap "Start" to activate timer (system notification alerts when complete)
- "Skip Task" moves to next task
- "Finish Routine" when all tasks complete unlocks achievement & updates streak
- Long-press task to edit or delete

**Design Notes:**
- Active task highlighted with subtle background color change
- Timer shows seconds countdown when active
- Confetti animation when routine completed
- Record task completion time for analytics
- Suggest next routine after finishing one

---

### **4. Community Feed Screen**

**Purpose:** Browse community posts, discover connections, join tribes

**Layout:**
```
┌────────────────────────────────┐
│ Pulse      Filter       Search  │  (Header)
│                                │
│ 👥 Community                   │  (Tab: Feed | Tribes)
│                                │
│ [Your Tribes: Productivity, Creators]
│                                │
│ ┌────────────────────────────┐ │
│ │ @alex_productivity        │ │  (Post)
│ │ 2 hours ago              │ │
│ │                          │ │
│ │ "Just completed my 30-day│ │
│ │  meditation challenge! 🧘│ │
│ │  Feeling zen & ready."   │ │
│ │                          │ │
│ │ 🔥 1.2K  ❤️ 342  💬 28    │ │
│ │        [Comment] [Share] │ │
│ └────────────────────────────┘ │
│                                │
│ ┌────────────────────────────┐ │
│ │ @maya_creates            │ │  (Post)
│ │ 4 hours ago              │ │
│ │                          │ │
│ │ [Image: Content calendar]│ │
│ │                          │ │
│ │ "New creator tribe meetup│ │
│ │  schedule open! 📅 Link: │ │
│ │  pulse.app/events/meetup"│ │
│ │                          │ │
│ │ 👁️ 542  ❤️ 289  💬 64   │ │
│ │        [Comment] [Share] │ │
│ └────────────────────────────┘ │
│                                │
│ ┌────────────────────────────┐ │
│ │ @jordan_family           │ │  (Post)
│ │ 6 hours ago              │ │
│ │                          │ │
│ │ "Family chore chart made │ │
│ │  weekly cleanup fun! Kids│ │
│ │  are earning badges & we │ │
│ │  all win! 🏆"             │ │
│ │                          │ │
│ │ ❤️ 897  💬 142  👁️ 3.2K  │ │
│ │        [Comment] [Share] │ │
│ └────────────────────────────┘ │
│                                │
│              [Load More...]     │
│                                │
└────────────────────────────────┘
```

**Components:**
- **Header:** Tab selector (Feed | Tribes), filter & search icons
- **Tribe Tags:** Horizontal scrollable list, selected state highlighted `#00D4FF`
- **Post Card:**
  - Avatar: 32x32px, rounded, left side
  - Username: SF Pro Display, 14px, bold, `#E8ECEF`
  - Timestamp: SF Pro Text, 12px, `#A0A8B2`
  - Post Content: SF Pro Text, 14px, `#E8ECEF`, multiline
  - Optional Image: 100% width, corner radius 8px, max height 300px
  - Reaction Icons: 🔥 (trending), ❤️ (like), 💬 (comment), 👁️ (views)
  - Action Buttons: Comment, Share (outlined style)
  - Background: `#1A1F2E`, padding 16px, margin 8px, radius 8px

**Interactions:**
- Swipe left to like post (animated heart)
- Tap avatar to view user profile
- Tap "Comment" opens comment modal
- Tap "Share" opens share sheet (copy link, share to social)
- Infinite scroll loads more posts
- Pull-down refresh
- Tap tribe filter to show only that tribe's posts

**Design Notes:**
- Posts sorted by trending (combination of engagement & recency)
- Show "no posts yet" if tribe has no activity
- Comments load on tap (don't show in feed)
- Image posts auto-play video if available (post-MVP)

---

### **5. Achievements Screen**

**Purpose:** Display badges, streaks, milestones, leaderboard

**Layout:**
```
┌────────────────────────────────┐
│ Achievements                   │  (Header)
│                                │
│ 🔥 CURRENT STREAKS             │  (Section)
│                                │
│ ┌────────────────────────────┐ │
│ │ 🔥 Daily Active            │ │  (Streak Badge)
│ │ 4 days                     │ │
│ │ Best: 12 days              │ │
│ └────────────────────────────┘ │
│                                │
│ ┌────────────────────────────┐ │
│ │ 🎯 Productivity            │ │  (Streak Badge)
│ │ 2 days                     │ │
│ │ Best: 8 days               │ │
│ └────────────────────────────┘ │
│                                │
│ 🏆 MILESTONES & BADGES        │  (Section)
│                                │
│ ┌─┬─┬─┬─┬─┐                    │
│ │⭐│⭐│⭐│⭐│🏅│ (Badge Row)   │
│ └─┴─┴─┴─┴─┘                    │
│                                │
│ ┌─┬─┬─┬─┬─┐                    │
│ │🎖️│🎖️│?│?│?│ (Locked Badges)│
│ └─┴─┴─┴─┴─┘                    │
│                                │
│ 📊 THIS MONTH'S STATS          │  (Section)
│                                │
│ Routines Completed: 18/20      │  (Stat)
│ Tasks Completed: 847/1000      │  (Stat)
│ Achievements Unlocked: 3       │  (Stat)
│                                │
│ 🥇 LEADERBOARD                │  (Section)
│                                │
│ 🥇 @alex_productivity  145 pts │  (Rank)
│ 🥈 @maya_creates       128 pts │  (Rank)
│ 🥉 @jordan_family      112 pts │  (Rank)
│                                │
└────────────────────────────────┘
```

**Components:**
- **Streak Card:**
  - Background gradient `#1A1F2E` → darker
  - Icon large (48px), text `#E8ECEF`
  - Streak count bold, large
  - Best streak smaller, secondary text color
  - Padding 16px, radius 8px

- **Badge Grid:**
  - Grid layout, 5 badges per row on mobile
  - Badge size: 48x48px, emoji or custom icon
  - Unlocked: `#00D4FF` border, visible
  - Locked: Grayed out (`#2D3748` background), "?" icon
  - Tap to show details modal

- **Stat Item:**
  - Name (left), value (right)
  - Background `#1A1F2E`, padding 12px, border `#2D3748`
  - Value: `#00D4FF` bold

- **Leaderboard Item:**
  - Rank (medal icon), username, points
  - Tap to view user profile
  - Highlight own entry with `#00D4FF` background

**Interactions:**
- Tap badge to show unlock requirements & description
- Tap leaderboard entry to view profile
- Swipe between tabs (Streaks, Badges, Stats, Leaderboard)
- Pull-down refresh stats from server

**Design Notes:**
- Show "Almost there!" for nearly-unlocked badges
- Leaderboard refreshes daily, ranked by points
- Points earned per task: 1pt, streak bonuses: +5pts per day
- Locked badges show hint: "Complete 20 routines"

---

### **6. Settings Screen**

**Purpose:** Account, preferences, integrations, privacy, support

**Layout:**
```
┌────────────────────────────────┐
│ Settings                       │  (Header)
│                                │
│ 👤 ACCOUNT                     │  (Section)
│                                │
│ [Profile Photo] Alex           │  (Profile)
│ alex@email.com                 │
│ [Edit Profile]                 │
│                                │
│ 🔔 NOTIFICATIONS               │  (Section)
│                                │
│ Frequency: Balanced (3-5/day)  │
│ [Customize]                    │
│                                │
│ 🎨 PERSONALIZATION             │  (Section)
│                                │
│ Theme: Dark (System)           │
│ [Browse Themes]                │
│                                │
│ ┌────────────────────────────┐ │
│ │ ☑ Animations & Confetti   │ │  (Toggles)
│ │ ☑ Sound Effects           │ │
│ │ ☐ Simplified UI (Lite)    │ │
│ └────────────────────────────┘ │
│                                │
│ 🔐 PRIVACY & SECURITY          │  (Section)
│                                │
│ Data Storage: Local + Cloud    │
│ [Configure]                    │
│ Biometric: Enabled             │
│ [Disable]                      │
│                                │
│ 🔗 INTEGRATIONS                │  (Section)
│                                │
│ Calendar: Not Connected        │
│ [Connect]                      │
│ Social Media: Not Connected    │
│ [Connect]                      │
│                                │
│ 💬 SUPPORT & FEEDBACK          │  (Section)
│                                │
│ [FAQs]  [Contact Support]      │
│ [Report Bug]  [Give Feedback]  │
│                                │
│ ℹ️ APP INFO                    │  (Section)
│                                │
│ Version: 1.0.0                 │
│ Build: 1001                    │
│ [View Privacy Policy]          │
│ [View Terms of Service]        │
│                                │
│                  [Sign Out]     │  (Action)
│                                │
└────────────────────────────────┘
```

**Components:**
- **Profile Section:**
  - Avatar: 64x64px, rounded, tap to edit
  - Name, email below
  - "Edit Profile" button: outlined style

- **Section Headers:** SF Pro Display, 12px, bold, all-caps, `#A0A8B2`, left margin 16px

- **Toggle Row:**
  - Description (left), toggle switch (right)
  - Background `#1A1F2E` on tap
  - Padding 12px

- **Action Rows:**
  - Description (left), chevron icon (right)
  - Tap opens detail screen or modal
  - Padding 12px, border-bottom `#2D3748`

- **Sign Out Button:** Full-width, outlined style, border `#FF6B6B`, text `#FF6B6B`, 48px height

**Interactions:**
- Toggles update immediately (optimistic update)
- Tap action rows to open detail screens
- Pull-down refresh user data
- Swipe profile section to edit

**Design Notes:**
- "Configure Privacy" opens detailed privacy controls (data retention, cloud sync, deletion)
- Integrations show connection status + quick disconnect
- Version auto-updates on app launch, shows banner if update available

---

## **Component Library**

### **Buttons**

**Primary (CTA):**
- Background: `#00D4FF`
- Text: `#0A1428` (dark text)
- Height: 48px
- Border radius: 8px
- Padding: 12px 24px

**Secondary (Outlined):**
- Background: Transparent
- Border: 1px `#2D3748`
- Text: `#A0A8B2`
- Height: 48px

**Icon Button:**
- 40x40px
- Background: `#1A1F2E`
- Icon: 24px, centered

### **Input Fields**

- **Background:** `#1A1F2E`
- **Border:** 1px `#2D3748`
- **Focus Border:** 1px `#00D4FF`
- **Border Radius:** 8px
- **Padding:** 12px 16px
- **Placeholder Text:** `#A0A8B2`
- **Error State:** Border `#FF6B6B`, error message below in red

### **Cards**

- **Background:** `#1A1F2E`
- **Border:** 1px `#2D3748` (optional)
- **Border Radius:** 12px
- **Padding:** 16px
- **Shadow:** `0 4px 12px rgba(0, 0, 0, 0.3)` (elevated)
- **Tap State:** Scale 0.98, shadow increase

### **Navigation**

**Top Navigation Bar:**
- Background: `#0A1428`
- Height: 56px
- Safe area included
- Title centered, icons on sides

**Bottom Tab Bar:**
- Background: `#0A1428`
- Height: 60px + safe area
- 5 tabs, icons + labels
- Active tab text: `#00D4FF`
- Inactive tab text: `#A0A8B2`

---

## **Animations & Micro-Interactions**

| Interaction | Animation | Duration | Easing |
|------------|-----------|----------|--------|
| **Button Tap** | Scale 0.98 → 1.0 | 200ms | ease-out |
| **Checkbox Toggle** | Bounce scale 1.0 → 1.2 → 1.0 | 300ms | spring |
| **Streak Update** | Flame icon grows + rotates | 500ms | ease-in-out |
| **Routine Complete** | Confetti animation | 2s | natural |
| **Achievement Unlock** | Pop-up scale 0 → 1.1 → 1.0 with shine | 600ms | spring |
| **Like Animation** | Heart appears + floats up, opacity → 0 | 1.5s | ease-out |
| **Page Transition** | Fade + slight slide up | 300ms | ease-in-out |
| **Pull-to-Refresh** | Spinner rotation, smooth release | - | linear |
| **Notification** | Slide down from top, auto-dismiss in 5s | - | ease-out |

---

## **Responsiveness**

### **Mobile (320px - 480px)**
- Single-column layout
- Full-width cards (16px padding)
- Bottom tab navigation
- Larger touch targets (48px minimum)

### **Tablet (481px - 1024px)**
- Two-column layout where appropriate
- Sidebar navigation (optional)
- Wider cards with constraints (max 600px)
- Enhanced tablet-specific gestures

### **Desktop (1025px+)**
- Three-column layout
- Sidebar + main content + detail pane
- Mouse/keyboard optimizations
- Hover states for buttons & interactions

---

## **Dark Mode**

All colors already optimized for dark mode (primary design). Light mode support planned for post-MVP if user demand exists.

---

## **Accessibility**

- **Color Contrast:** All text meets WCAG AA standards (4.5:1 minimum)
- **Touch Targets:** All interactive elements 48px minimum
- **Typography:** Scalable up to 200% without truncation
- **Icons:** All have text labels or aria-labels
- **Animations:** Reduce Motion respects system settings

---

## **Next Steps for Design**

1. **Create Figma Prototype:** Implement all wireframes with interactive components
2. **High-Fidelity Mockups:** Design detailed screens with all visual polish
3. **Design System Documentation:** Build component library for developers
4. **Usability Testing:** Validate prototypes with target personas
5. **Developer Handoff:** Prepare design specs & assets for engineering team

---

## **Design Resources**

- **Color Codes:** See Color Palette section
- **Fonts:** SF Pro (iOS), Roboto (Android)
- **Icons:** Use custom SVG or system icons (SF Symbols on iOS, Material Design on Android)
- **Images:** Placeholder images 1:1 aspect ratio for profile, variable for posts

