package com.example.pulse.android

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.MutableStateFlow

// MARK: - Achievements Screen
@Composable
fun AchievementsScreenContent(viewModel: AchievementsViewModel = remember { AchievementsViewModel() }) {
    val achievements by viewModel.achievements.collectAsState(initial = emptyList())
    val streaks by viewModel.streaks.collectAsState(initial = emptyList())
    val leaderboardEntries by viewModel.leaderboardEntries.collectAsState(initial = emptyList())
    var selectedTab by remember { mutableStateOf(AchievementTab.BADGES) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(PulseColors.darkBg)
    ) {
        // Top Bar with Title
        TopAppBar(
            title = { Text("Achievements", color = PulseColors.text, fontSize = 18.sp, fontWeight = FontWeight.Bold) },
            backgroundColor = PulseColors.darkBg,
            elevation = 0.dp
        )

        // Tab Selector
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(PulseColors.surface)
                .padding(vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(0.dp)
        ) {
            TabSelectorButtonContent(
                label = "🏆 Badges",
                isSelected = selectedTab == AchievementTab.BADGES,
                modifier = Modifier.weight(1f),
                action = { selectedTab = AchievementTab.BADGES }
            )

            TabSelectorButtonContent(
                label = "🔥 Streaks",
                isSelected = selectedTab == AchievementTab.STREAKS,
                modifier = Modifier.weight(1f),
                action = { selectedTab = AchievementTab.STREAKS }
            )

            TabSelectorButtonContent(
                label = "📊 Leaderboard",
                isSelected = selectedTab == AchievementTab.LEADERBOARD,
                modifier = Modifier.weight(1f),
                action = { selectedTab = AchievementTab.LEADERBOARD }
            )
        }

        // Tab Content
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .weight(1f),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            when (selectedTab) {
                AchievementTab.BADGES -> {
                    item {
                        BadgesContent(achievements = achievements)
                    }
                }
                AchievementTab.STREAKS -> {
                    items(streaks) { streak ->
                        StreakRowContent(streak = streak)
                    }
                }
                AchievementTab.LEADERBOARD -> {
                    items(leaderboardEntries) { entry ->
                        LeaderboardRowContent(entry = entry)
                    }
                }
            }

            item { Spacer(modifier = Modifier.height(20.dp)) }
        }
    }
}

// MARK: - Tab Selector Button
@Composable
fun TabSelectorButtonContent(
    label: String,
    isSelected: Boolean,
    modifier: Modifier = Modifier,
    action: () -> Unit
) {
    Column(
        modifier = modifier
            .clickable(onClick = action)
            .padding(vertical = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Text(
            text = label,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            color = if (isSelected) PulseColors.accent else PulseColors.secondary
        )

        if (isSelected) {
            Spacer(
                modifier = Modifier
                    .fillMaxWidth(0.6f)
                    .height(2.dp)
                    .background(PulseColors.accent, shape = RoundedCornerShape(1.dp))
            )
        }
    }
}

// MARK: - Badges Content
@Composable
fun BadgesContent(achievements: List<Achievement>) {
    val unlockedAchievements = achievements.filter { it.isUnlocked }
    val lockedAchievements = achievements.filter { !it.isUnlocked }

    Column(
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        if (unlockedAchievements.isNotEmpty()) {
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = "🎉 Unlocked",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = PulseColors.secondary
                )

                LazyVerticalGrid(
                    columns = GridCells.Fixed(5),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    items(unlockedAchievements) { achievement ->
                        BadgeContent(achievement = achievement, isUnlocked = true)
                    }
                }
            }
        }

        if (lockedAchievements.isNotEmpty()) {
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = "🔒 Locked",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = PulseColors.secondary
                )

                LazyVerticalGrid(
                    columns = GridCells.Fixed(5),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    items(lockedAchievements) { achievement ->
                        BadgeContent(achievement = achievement, isUnlocked = false)
                    }
                }
            }
        }
    }
}

// MARK: - Badge Item
@Composable
fun BadgeContent(
    achievement: Achievement,
    isUnlocked: Boolean
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(
                if (isUnlocked) PulseColors.surface
                else PulseColors.separator.copy(alpha = 0.5f)
            )
            .padding(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Text(
            text = achievement.icon,
            fontSize = 24.sp
        )

        Text(
            text = achievement.name,
            fontSize = 10.sp,
            fontWeight = FontWeight.SemiBold,
            color = PulseColors.text,
            maxLines = 2,
            textAlignment = androidx.compose.ui.text.style.TextAlign.Center
        )
    }

    if (isUnlocked) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(2.dp)
                .offset(y = (-10).dp)
                .clip(RoundedCornerShape(1.dp))
                .background(PulseColors.accent)
        )
    }
}

// MARK: - Streak Row Content
@Composable
fun StreakRowContent(streak: Streak) {
    val percentage = if (streak.bestCount > 0) {
        streak.currentCount.toDouble() / streak.bestCount.toDouble()
    } else 0.0

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp)),
        colors = CardDefaults.cardColors(
            containerColor = PulseColors.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = streak.icon,
                    fontSize = 28.sp
                )

                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = streak.name,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = PulseColors.text
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "${streak.currentCount} days",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = PulseColors.accent
                        )

                        Divider(
                            modifier = Modifier
                                .width(1.dp)
                                .height(12.dp),
                            color = PulseColors.separator
                        )

                        Text(
                            text = "Best: ${streak.bestCount} days",
                            fontSize = 12.sp,
                            color = PulseColors.secondary
                        )
                    }
                }

                Column(
                    horizontalAlignment = Alignment.End,
                    verticalArrangement = Arrangement.spacedBy(2.dp)
                ) {
                    Text(
                        text = "${(percentage * 100).toInt()}%",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = PulseColors.accent
                    )

                    Text(
                        text = "of best",
                        fontSize = 10.sp,
                        color = PulseColors.secondary
                    )
                }
            }

            // Progress Bar
            LinearProgressIndicator(
                progress = percentage.toFloat(),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp)
                    .clip(RoundedCornerShape(4.dp)),
                color = PulseColors.accent,
                trackColor = PulseColors.separator,
                strokeCap = androidx.compose.ui.graphics.StrokeCap.Round
            )
        }
    }
}

// MARK: - Leaderboard Row Content
@Composable
fun LeaderboardRowContent(entry: LeaderboardEntry) {
    val medalEmoji = when (entry.rank) {
        1 -> "🥇"
        2 -> "🥈"
        3 -> "🥉"
        else -> "#${entry.rank}"
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp)),
        colors = CardDefaults.cardColors(
            containerColor = if (entry.isCurrentUser) {
                PulseColors.accent.copy(alpha = 0.1f)
            } else {
                PulseColors.surface
            }
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        border = if (entry.isCurrentUser) {
            CardDefaults.outlinedCardBorder(
                enabled = true,
                width = 2.dp
            ).copy(color = PulseColors.accent)
        } else {
            null
        }
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = medalEmoji,
                fontSize = 20.sp
            )

            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(2.dp)
            ) {
                Text(
                    text = entry.username,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = PulseColors.text
                )

                Text(
                    text = "Rank #${entry.rank}",
                    fontSize = 12.sp,
                    color = PulseColors.secondary
                )
            }

            Column(
                horizontalAlignment = Alignment.End,
                verticalArrangement = Arrangement.spacedBy(2.dp)
            ) {
                Text(
                    text = "${entry.points}",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    color = PulseColors.accent
                )

                Text(
                    text = "points",
                    fontSize = 10.sp,
                    color = PulseColors.secondary
                )
            }
        }
    }
}

// MARK: - Achievement Tab Enum
enum class AchievementTab {
    BADGES, STREAKS, LEADERBOARD
}

// MARK: - Achievements View Model
class AchievementsViewModel : androidx.lifecycle.ViewModel() {
    private val _achievements = MutableStateFlow<List<Achievement>>(emptyList())
    val achievements: StateFlow<List<Achievement>> = _achievements

    private val _streaks = MutableStateFlow<List<Streak>>(emptyList())
    val streaks: StateFlow<List<Streak>> = _streaks

    private val _leaderboardEntries = MutableStateFlow<List<LeaderboardEntry>>(emptyList())
    val leaderboardEntries: StateFlow<List<LeaderboardEntry>> = _leaderboardEntries

    init {
        loadData()
    }

    private fun loadData() {
        // Mock achievements
        _achievements.value = Achievement.allAchievements

        // Mock streaks
        _streaks.value = listOf(
            Streak(
                id = "streak_1",
                name = "Daily Active",
                icon = "🔥",
                currentCount = 4,
                bestCount = 12
            ),
            Streak(
                id = "streak_2",
                name = "Productivity",
                icon = "🎯",
                currentCount = 2,
                bestCount = 8
            ),
            Streak(
                id = "streak_3",
                name = "Health",
                icon = "💪",
                currentCount = 6,
                bestCount = 20
            )
        )

        // Mock leaderboard
        _leaderboardEntries.value = listOf(
            LeaderboardEntry(rank = 1, username = "alex_productivity", points = 2450),
            LeaderboardEntry(rank = 2, username = "maya_creates", points = 2180),
            LeaderboardEntry(rank = 3, username = "jordan_family", points = 1890),
            LeaderboardEntry(rank = 4, username = "casey_gamer", points = 1650),
            LeaderboardEntry(rank = 5, username = "you", points = 1245, isCurrentUser = true)
        )

        AnalyticsService.shared.logEvent("achievements_loaded")
    }
}

// MARK: - Leaderboard Entry Data Class
data class LeaderboardEntry(
    val rank: Int,
    val username: String,
    val points: Int,
    val isCurrentUser: Boolean = false
)
