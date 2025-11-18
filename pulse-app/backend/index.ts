import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as cors from 'cors';

// Initialize Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

// CORS enabled for API calls
const corsHandler = cors({ origin: true });

// MARK: - Authentication Triggers

/**
 * Create user document when new user signs up
 */
export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  try {
    const userData = {
      id: user.uid,
      name: user.displayName || 'User',
      email: user.email || '',
      avatar: user.photoURL || null,
      joinedTribes: ['Productivity'],
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
      preferences: {
        notificationFrequency: 'balanced',
        notificationStyle: 'text_emoji',
        darkMode: true,
        dndEnabled: false
      },
      stats: {
        routinesCompleted: 0,
        currentStreak: 0,
        bestStreak: 0,
        postsCreated: 0,
        pointsEarned: 0
      }
    };

    await db.collection('users').doc(user.uid).set(userData);
    console.log(`User created: ${user.uid}`);
  } catch (error) {
    console.error(`Error creating user: ${error}`);
  }
});

/**
 * Clean up user data when account is deleted
 */
export const onUserDeleted = functions.auth.user().onDelete(async (user) => {
  try {
    await db.collection('users').doc(user.uid).delete();

    const routinesSnapshot = await db.collection('routines')
      .where('userId', '==', user.uid)
      .get();

    for (const doc of routinesSnapshot.docs) {
      await doc.ref.delete();
    }

    const postsSnapshot = await db.collection('posts')
      .where('authorId', '==', user.uid)
      .get();

    for (const doc of postsSnapshot.docs) {
      await doc.ref.delete();
    }

    console.log(`User deleted: ${user.uid}`);
  } catch (error) {
    console.error(`Error deleting user: ${error}`);
  }
});

// MARK: - Routine Functions

/**
 * Get routine suggestions
 */
export const getRoutineSuggestions = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const templates = [
    { name: 'Morning Routine', emoji: '🌅', tasks: ['Exercise', 'Breakfast', 'Meditation'] },
    { name: 'Productivity Boost', emoji: '🎯', tasks: ['Focus Session 1', 'Break', 'Focus Session 2'] },
    { name: 'Evening Wind Down', emoji: '🌙', tasks: ['Journal', 'Read', 'Prepare for tomorrow'] },
    { name: 'Health & Fitness', emoji: '💪', tasks: ['Warm up', 'Strength training', 'Stretch'] },
    { name: 'Creative Session', emoji: '🎨', tasks: ['Brainstorm', 'Create', 'Review work'] },
    { name: 'Family Time', emoji: '👨‍👩‍👧‍👦', tasks: ['Meal together', 'Activity', 'Bedtime'] }
  ];

  return { suggestions: templates };
});

// MARK: - Achievement Functions

/**
 * Award achievement when routine is completed
 */
export const onRoutineCompleted = functions.firestore
  .document('routines/{routineId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (!before?.completedToday && after?.completedToday) {
      const userId = after.userId;

      try {
        const userDoc = await db.collection('users').doc(userId).get();
        const userData = userDoc.data();
        const currentStreak = (userData?.stats?.currentStreak || 0) + 1;

        await db.collection('users').doc(userId).update({
          'stats.routinesCompleted': admin.firestore.FieldValue.increment(1),
          'stats.currentStreak': currentStreak,
          'stats.pointsEarned': admin.firestore.FieldValue.increment(10)
        });

        if (currentStreak === 7) await grantAchievement(userId, 'streak_7');
        else if (currentStreak === 30) await grantAchievement(userId, 'streak_30');
        else if (currentStreak === 100) await grantAchievement(userId, 'streak_100');

        await updateLeaderboard(userId, currentStreak);
        console.log(`Routine completed for user: ${userId}`);
      } catch (error) {
        console.error(`Error processing routine completion: ${error}`);
      }
    }
  });

/**
 * Grant achievement to user
 */
async function grantAchievement(userId: string, achievementId: string) {
  try {
    const achievementRef = db.collection('users')
      .doc(userId)
      .collection('achievements')
      .doc(achievementId);

    await achievementRef.set({
      achievementId,
      unlockedAt: admin.firestore.Timestamp.now()
    });

    await sendNotification(userId, {
      title: '🎉 Achievement Unlocked!',
      body: `You've unlocked a new achievement!`,
      type: 'achievement'
    });
  } catch (error) {
    console.error(`Error granting achievement: ${error}`);
  }
}

/**
 * Update leaderboard
 */
async function updateLeaderboard(userId: string, streakCount: number) {
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data();

    await db.collection('leaderboard').doc(userId).set({
      userId,
      username: userData?.name || 'Anonymous',
      points: (userData?.stats?.pointsEarned || 0),
      streak: streakCount,
      updatedAt: admin.firestore.Timestamp.now()
    });
  } catch (error) {
    console.error(`Error updating leaderboard: ${error}`);
  }
}

// MARK: - Notification Functions

/**
 * Send routine reminder
 */
export const sendRoutineReminder = functions.pubsub
  .schedule('0 8 * * *')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    try {
      const usersSnapshot = await db.collection('users')
        .where('preferences.notificationFrequency', 'in', ['balanced', 'assertive'])
        .get();

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        await sendNotification(userId, {
          title: '⏰ Time for your routine!',
          body: 'Start your routine to build your streak',
          type: 'reminder'
        });
      }

      console.log(`Sent routine reminders to ${usersSnapshot.size} users`);
    } catch (error) {
      console.error(`Error sending reminders: ${error}`);
    }
  });

/**
 * Generic notification sender
 */
async function sendNotification(userId: string, notification: any) {
  try {
    const notificationRef = db.collection('notifications')
      .doc(userId)
      .collection('messages')
      .doc();

    await notificationRef.set({
      title: notification.title,
      body: notification.body,
      type: notification.type,
      read: false,
      createdAt: admin.firestore.Timestamp.now()
    });
  } catch (error) {
    console.error(`Error sending notification: ${error}`);
  }
}

// MARK: - Community Functions

/**
 * Create post and update tribe statistics
 */
export const onPostCreated = functions.firestore
  .document('posts/{postId}')
  .onCreate(async (snap, context) => {
    const postData = snap.data();

    try {
      const tribeRef = db.collection('tribes').doc(postData.tribe);
      await tribeRef.update({
        postCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.Timestamp.now()
      });

      await db.collection('users').doc(postData.authorId).update({
        'stats.postsCreated': admin.firestore.FieldValue.increment(1)
      });

      console.log(`Post created: ${context.params.postId}`);
    } catch (error) {
      console.error(`Error processing post creation: ${error}`);
    }
  });

/**
 * React to post
 */
export const reactToPost = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { postId, reactionType } = data;

  try {
    const postRef = db.collection('posts').doc(postId);
    const postDoc = await postRef.get();
    const postData = postDoc.data();

    if (!postData) {
      throw new functions.https.HttpsError('not-found', 'Post not found');
    }

    await postRef
      .collection('reactions')
      .doc(context.auth.uid)
      .set({
        userId: context.auth.uid,
        type: reactionType,
        createdAt: admin.firestore.Timestamp.now()
      });

    if (reactionType === 'like') {
      await postRef.update({
        likeCount: admin.firestore.FieldValue.increment(1)
      });
    }

    if (postData.authorId !== context.auth.uid) {
      await sendNotification(postData.authorId, {
        title: `❤️ Someone liked your post!`,
        body: postData.content.substring(0, 50) + '...',
        type: 'reaction'
      });
    }

    return { success: true };
  } catch (error) {
    console.error(`Error reacting to post: ${error}`);
    throw new functions.https.HttpsError('internal', 'Error reacting to post');
  }
});

// MARK: - Analytics Functions

/**
 * Get user analytics
 */
export const getUserAnalytics = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  try {
    const userId = context.auth.uid;
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data();

    return {
      routinesCompleted: userData?.stats?.routinesCompleted || 0,
      currentStreak: userData?.stats?.currentStreak || 0,
      bestStreak: userData?.stats?.bestStreak || 0,
      postsCreated: userData?.stats?.postsCreated || 0,
      pointsEarned: userData?.stats?.pointsEarned || 0,
      joinedTribes: userData?.joinedTribes || []
    };
  } catch (error) {
    console.error(`Error getting analytics: ${error}`);
    throw new functions.https.HttpsError('internal', 'Error getting analytics');
  }
});

// MARK: - Health Check

export const healthCheck = functions.https.onRequest((req, res) => {
  res.status(200).send({ status: 'healthy', timestamp: new Date().toISOString() });
});
