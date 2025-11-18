import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Timestamp} from "firebase-admin/firestore";

// Initialize Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

// MARK: - Type Definitions

interface User {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  bio?: string;
  joinedTribes: string[];
  createdAt: Timestamp;
  preferences: UserPreferences;
}

interface UserPreferences {
  notificationFrequency: "gentle" | "balanced" | "assertive";
  notificationStyle: "textAndEmojiAndSound" | "textAndEmoji" | "silent";
  darkMode: boolean;
  soundEnabled: boolean;
  doNotDisturbStart?: Timestamp;
  doNotDisturbEnd?: Timestamp;
}

interface Routine {
  id: string;
  name: string;
  description?: string;
  emoji: string;
  tasks: RoutineTask[];
  schedule: "daily" | "weekdays" | "weekends" | "weekly" | "custom";
  startTime?: Timestamp;
  estimatedDuration: number;
  isActive: boolean;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

interface RoutineTask {
  id: string;
  name: string;
  description?: string;
  estimatedDuration?: number;
  isCompleted: boolean;
  completedAt?: Timestamp;
  order: number;
}

interface Post {
  id: string;
  authorId: string;
  author: string;
  content: string;
  imageUrl?: string;
  tribeId?: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  reactions: {[emoji: string]: number};
  commentCount: number;
  viewCount: number;
}

interface Achievement {
  id: string;
  name: string;
  description: string;
  icon: string;
  rarity: "common" | "rare" | "epic" | "legendary";
  unlockedAt?: Timestamp;
  progress?: number;
}

// MARK: - Auth Triggers

/**
 * Create user document on signup
 */
export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  const userData: User = {
    id: user.uid,
    name: user.displayName || "User",
    email: user.email || "",
    joinedTribes: [],
    createdAt: admin.firestore.Timestamp.now(),
    preferences: {
      notificationFrequency: "balanced",
      notificationStyle: "textAndEmojiAndSound",
      darkMode: true,
      soundEnabled: true,
    },
  };

  try {
    await db.collection("users").doc(user.uid).set(userData);
    console.log("✅ User document created:", user.uid);
    return {success: true};
  } catch (error) {
    console.error("❌ Error creating user document:", error);
    throw error;
  }
});

/**
 * Delete user data on account deletion
 */
export const onUserDeleted = functions.auth.user().onDelete(async (user) => {
  try {
    await db.collection("users").doc(user.uid).delete();
    console.log("✅ User data deleted:", user.uid);
    return {success: true};
  } catch (error) {
    console.error("❌ Error deleting user data:", error);
    throw error;
  }
});

// MARK: - Routine Functions

/**
 * Get routine suggestions based on user behavior
 */
export const getRoutineSuggestions = functions.https.onCall(
    async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be authenticated"
        );
      }

      const userId = context.auth.uid;

      try {
        // TODO: Implement ML-based routine suggestion logic
        // For MVP, return hardcoded suggestions

        const suggestions: Routine[] = [
          {
            id: "sug_morning",
            name: "Morning Routine",
            emoji: "📅",
            tasks: [
              {
                id: "task_1",
                name: "Exercise",
                order: 0,
                isCompleted: false,
              },
              {
                id: "task_2",
                name: "Breakfast",
                order: 1,
                isCompleted: false,
              },
            ],
            schedule: "daily",
            estimatedDuration: 1800,
            isActive: true,
            createdAt: admin.firestore.Timestamp.now(),
            updatedAt: admin.firestore.Timestamp.now(),
          },
        ];

        console.log("✅ Routine suggestions generated for user:", userId);

        return {
          success: true,
          suggestions,
        };
      } catch (error) {
        console.error("❌ Error generating suggestions:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to generate suggestions"
        );
      }
    }
);

// MARK: - Achievement Functions

/**
 * Check and award achievements on task completion
 */
export const onTaskCompleted = functions.firestore
    .document("users/{userId}/routines/{routineId}/tasks/{taskId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();

      // Only process if task was just completed
      if (before.isCompleted || !after.isCompleted) {
        return null;
      }

      const {userId} = context.params;

      try {
        // Check for "First Routine" achievement
        const routines = await db
            .collection("users")
            .doc(userId)
            .collection("routines")
            .get();

        const completedRoutines = routines.docs.filter((doc) => {
          const tasks = doc.data().tasks || [];
          return tasks.every((t: RoutineTask) => t.isCompleted);
        });

        if (completedRoutines.length === 1) {
          // First routine completed!
          await awardAchievement(
              userId,
              "ach_first_routine",
              "Getting Started",
              "Complete your first routine",
              "🎯"
          );
        }

        console.log("✅ Task completion processed for user:", userId);
        return null;
      } catch (error) {
        console.error("❌ Error processing task completion:", error);
        throw error;
      }
    });

/**
 * Award an achievement to a user
 */
async function awardAchievement(
    userId: string,
    achievementId: string,
    name: string,
    description: string,
    icon: string
) {
  const achievement: Achievement = {
    id: achievementId,
    name,
    description,
    icon,
    rarity: "common",
    unlockedAt: admin.firestore.Timestamp.now(),
  };

  await db
      .collection("users")
      .doc(userId)
      .collection("achievements")
      .doc(achievementId)
      .set(achievement, {merge: true});

  console.log("🏆 Achievement awarded:", name, "to user:", userId);
}

// MARK: - Notification Functions

/**
 * Send routine reminder notification
 */
export const sendRoutineReminder = functions.pubsub
    .schedule("every 1 hours")
    .onRun(async (context) => {
      try {
        // TODO: Query all users with active routines
        // Send notifications to those matching their schedule

        console.log("✅ Routine reminders sent");
        return {success: true};
      } catch (error) {
        console.error("❌ Error sending reminders:", error);
        throw error;
      }
    });

/**
 * Send push notification to user
 */
export const sendNotification = functions.https.onCall(
    async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be authenticated"
        );
      }

      const {userId, title, body, badge} = data;

      try {
        // TODO: Send via FCM/APNs

        console.log("📬 Notification sent:", title);

        return {success: true};
      } catch (error) {
        console.error("❌ Error sending notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send notification"
        );
      }
    }
);

// MARK: - Community Functions

/**
 * Create a new post
 */
export const createPost = functions.https.onCall(
    async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be authenticated"
        );
      }

      const {content, tribeId} = data;
      const userId = context.auth.uid;

      try {
        // Get user info
        const user = await db.collection("users").doc(userId).get();
        const userData = user.data() as User;

        // Create post
        const postRef = await db.collection("posts").add({
          authorId: userId,
          author: userData.name,
          content,
          tribeId: tribeId || null,
          createdAt: admin.firestore.Timestamp.now(),
          updatedAt: admin.firestore.Timestamp.now(),
          reactions: {},
          commentCount: 0,
          viewCount: 0,
        });

        console.log("✅ Post created:", postRef.id);

        return {
          success: true,
          postId: postRef.id,
        };
      } catch (error) {
        console.error("❌ Error creating post:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to create post"
        );
      }
    }
);

/**
 * React to a post
 */
export const reactToPost = functions.https.onCall(
    async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be authenticated"
        );
      }

      const {postId, emoji} = data;

      try {
        const postRef = db.collection("posts").doc(postId);
        await postRef.update({
          [`reactions.${emoji}`]: admin.firestore.FieldValue.increment(1),
        });

        console.log("✅ Reaction added to post:", postId);

        return {success: true};
      } catch (error) {
        console.error("❌ Error adding reaction:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to add reaction"
        );
      }
    }
);

// MARK: - Admin Functions

/**
 * Get analytics for admin dashboard
 */
export const getAnalytics = functions.https.onCall(
    async (data, context) => {
      // TODO: Add admin role check
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be authenticated"
        );
      }

      try {
        const users = await db.collection("users").count().get();
        const posts = await db.collection("posts").count().get();

        console.log("✅ Analytics retrieved");

        return {
          totalUsers: users.data().count,
          totalPosts: posts.data().count,
          timestamp: new Date().toISOString(),
        };
      } catch (error) {
        console.error("❌ Error retrieving analytics:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to retrieve analytics"
        );
      }
    }
);

// MARK: - Health Check

export const health = functions.https.onRequest((req, res) => {
  res.status(200).json({
    status: "OK",
    timestamp: new Date().toISOString(),
    message: "Pulse App Backend is running",
  });
});
