package com.pulse.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.ViewModel
import com.pulse.app.data.models.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.text.SimpleDateFormat
import java.util.*

// MARK: - Home Screen
@Composable
fun HomeScreenContent(routineViewModel: RoutineViewModel) {
    val viewModel = remember { HomeScreenViewModel() }
    val greeting by viewModel.greeting.collectAsState()
    val currentStreak by viewModel.currentStreak.collectAsState()
    val todaysRoutines by viewModel.todaysRoutines.collectAsState()
    val achievements by viewModel.achievements.collectAsState()
    val communityPosts by viewModel.communityPosts.collectAsState()

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(PulseColors.darkBg)
            .padding(bottom = 60.dp)
    ) {
        // Header
        item {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    greeting,
                    fontSize = 28.sp,
                    fontWeight = FontWeight.Bold,
                    color = PulseColors.text
                )

                Text(
                    "Let's crush today's goals! 💪",
                    fontSize = 14.sp,
                    color = PulseColors.secondary
                )
            }
        }

        // Streak Card
        if (currentStreak != null) {
            item {
                StreakCardContent(streak = currentStreak!!)
            }
        }

        // Today's Routines Section
        item {
            SectionHeaderContent(title = "📋 TODAY'S ROUTINES")
        }

        if (todaysRoutines.isEmpty()) {
            item {
                EmptyStateContent(
                    emoji = "📅",
                    title = "No Routines Yet",
                    subtitle = "Create your first routine to get started!"
                )
            }
        } else {
            items(todaysRoutines) { routine ->
                RoutineCardContent(routine = routine)
            }
        }

        // Achievements Section
        item {
            SectionHeaderContent(title = "🎖️ THIS WEEK'S ACHIEVEMENTS")
        }

        if (achievements.isEmpty()) {
            item {
                EmptyStateContent(
                    emoji = "",
                    title = "No achievements yet",
                    subtitle = "Complete routines to unlock badges!"
                )
            }
        } else {
            item {
                LazyRow(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(achievements.take(5)) { achievement ->
                        AchievementBadgeContent(achievement = achievement)
                    }
                }
            }
        }

        // Community Highlights
        item {
            SectionHeaderContent(title = "👥 COMMUNITY HIGHLIGHTS")
        }

        if (communityPosts.isEmpty()) {
            item {
                EmptyStateContent(
                    emoji = "👥",
                    title = "Community Feed Empty",
                    subtitle = "Follow users to see their achievements!"
                )
            }
        } else {
            items(communityPosts.take(3)) { post ->
                CommunityPostCardContent(post = post)
            }
        }

        item {
            Spacer(modifier = Modifier.height(20.dp))
        }
    }
}

// MARK: - Home Screen ViewModel
class HomeScreenViewModel : ViewModel() {
    private val _greeting = MutableStateFlow("")
    val greeting: StateFlow<String> = _greeting

    private val _currentStreak = MutableStateFlow<Streak?>(null)
    val currentStreak: StateFlow<Streak?> = _currentStreak

    private val _todaysRoutines = MutableStateFlow<List<Routine>>(emptyList())
    val todaysRoutines: StateFlow<List<Routine>> = _todaysRoutines

    private val _achievements = MutableStateFlow<List<Achievement>>(emptyList())
    val achievements: StateFlow<List<Achievement>> = _achievements

    private val _communityPosts = MutableStateFlow<List<Post>>(emptyList())
    val communityPosts: StateFlow<List<Post>> = _communityPosts

    init {
        loadData()
    }

    private fun loadData() {
        updateGreeting()

        // Mock data
        _currentStreak.value = Streak(
            id = "streak_1",
            name = "Daily Active",
            icon = "🔥",
            currentCount = 4,
            bestCount = 12
        )

        _todaysRoutines.value = listOf(
            Routine(name = "Morning Routine").copy(emoji = "📅"),
            Routine(name = "Productivity Boost").copy(emoji = "🎯")
        )

        _achievements.value = Achievement.allAchievements

        _communityPosts.value = MockData.mockPosts
    }

    private fun updateGreeting() {
        val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
        _greeting.value = when (hour) {
            in 5..<12 -> "Good morning! 🌅"
            in 12..<17 -> "Good afternoon! ☀️"
            in 17..<21 -> "Good evening! 🌙"
            else -> "Burning the midnight oil? 🌃"
        }
    }
}

// MARK: - Components

@Composable
fun SectionHeaderContent(title: String) {
    Text(
        title,
        fontSize = 14.sp,
        fontWeight = FontWeight.SemiBold,
        color = PulseColors.secondary,
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
    )
}

@Composable
fun StreakCardContent(streak: Streak) {
    val percentage = if (streak.bestCount > 0) {
        (streak.currentCount.toFloat() / streak.bestCount.toFloat()) * 100
    } else {
        0f
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = PulseColors.surface)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Row(
                    modifier = Modifier.weight(1f),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(streak.icon, fontSize = 32.sp)

                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(streak.name, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = PulseColors.text)
                        Text("${streak.currentCount} days", fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = PulseColors.accent)
                        Text("Best: ${streak.bestCount} days", fontSize = 12.sp, color = PulseColors.secondary)
                    }
                }

                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        "${percentage.toInt()}%",
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold,
                        color = PulseColors.accent
                    )
                    Text("of best", fontSize = 10.sp, color = PulseColors.secondary)
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Progress bar
            LinearProgressIndicator(
                progress = { percentage / 100f },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp),
                color = PulseColors.accent,
                trackColor = PulseColors.separator,
            )
        }
    }
}

@Composable
fun RoutineCardContent(routine: Routine) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 6.dp),
        shape = RoundedCornerShape(8.dp),
        colors = CardDefaults.cardColors(containerColor = PulseColors.surface)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    modifier = Modifier.weight(1f),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(routine.emoji, fontSize = 24.sp)

                    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Text(routine.name, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = PulseColors.text)
                        Text("${routine.completedTasks}/${routine.totalTasks} tasks", fontSize = 12.sp, color = PulseColors.secondary)
                    }
                }

                Button(
                    onClick = { },
                    modifier = Modifier
                        .height(32.dp)
                        .width(60.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = PulseColors.accent),
                    shape = RoundedCornerShape(6.dp)
                ) {
                    Text("Open", fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = PulseColors.darkBg)
                }
            }

            // Progress bar
            LinearProgressIndicator(
                progress = { routine.progressPercent.toFloat() },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(6.dp),
                color = PulseColors.accent,
                trackColor = PulseColors.separator,
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                "${(routine.progressPercent * 100).toInt()}% Complete",
                fontSize = 11.sp,
                color = PulseColors.secondary
            )
        }
    }
}

@Composable
fun AchievementBadgeContent(achievement: Achievement) {
    Column(
        modifier = Modifier
            .width(56.dp)
            .background(
                if (achievement.isUnlocked) PulseColors.surface else PulseColors.separator.copy(alpha = 0.5f),
                shape = RoundedCornerShape(8.dp)
            )
            .border(
                width = if (achievement.isUnlocked) 1.dp else 0.dp,
                color = if (achievement.isUnlocked) PulseColors.accent else Color.Transparent,
                shape = RoundedCornerShape(8.dp)
            )
            .padding(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Text(achievement.icon, fontSize = 20.sp, textAlign = TextAlign.Center)

        Text(
            if (achievement.isUnlocked) "Unlocked" else "Locked",
            fontSize = 8.sp,
            fontWeight = FontWeight.SemiBold,
            color = if (achievement.isUnlocked) PulseColors.success else PulseColors.secondary
        )
    }
}

@Composable
fun CommunityPostCardContent(post: Post) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 6.dp),
        shape = RoundedCornerShape(8.dp),
        colors = CardDefaults.cardColors(containerColor = PulseColors.surface)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            // Author info
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(32.dp)
                        .background(PulseColors.separator, shape = RoundedCornerShape(50.dp)),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        post.author.take(1).uppercase(),
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                        color = PulseColors.accent
                    )
                }

                Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(post.author, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = PulseColors.text)
                    Text(getRelativeTime(post.createdAt), fontSize = 11.sp, color = PulseColors.secondary)
                }
            }

            // Content
            Text(
                post.content,
                fontSize = 14.sp,
                color = PulseColors.text,
                maxLines = 3,
                modifier = Modifier.padding(bottom = 12.dp)
            )

            // Reactions
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text("🔥", fontSize = 12.sp)
                    Text("1.2K", fontSize = 12.sp, color = PulseColors.secondary)
                }

                Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text("❤️", fontSize = 12.sp)
                    Text("342", fontSize = 12.sp, color = PulseColors.secondary)
                }
            }
        }
    }
}

@Composable
fun EmptyStateContent(emoji: String, title: String, subtitle: String) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        shape = RoundedCornerShape(8.dp),
        colors = CardDefaults.cardColors(containerColor = PulseColors.surface)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            if (emoji.isNotEmpty()) {
                Text(emoji, fontSize = 40.sp)
            }

            Text(title, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = PulseColors.text)

            Text(
                subtitle,
                fontSize = 14.sp,
                color = PulseColors.secondary,
                textAlign = TextAlign.Center
            )
        }
    }
}

// MARK: - Helpers
private fun getRelativeTime(timestamp: Long): String {
    val now = System.currentTimeMillis()
    val diff = now - timestamp

    return when {
        diff < 60000 -> "just now"
        diff < 3600000 -> "${diff / 60000}m ago"
        diff < 86400000 -> "${diff / 3600000}h ago"
        diff < 604800000 -> "${diff / 86400000}d ago"
        else -> {
            val format = SimpleDateFormat("MMM d", Locale.getDefault())
            format.format(Date(timestamp))
        }
    }
}
