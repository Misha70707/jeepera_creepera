package com.example.pulse.android

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.MutableStateFlow

// MARK: - Community Screen
@Composable
fun CommunityScreenContent(viewModel: CommunityViewModel = remember { CommunityViewModel() }) {
    val posts by viewModel.posts.collectAsState(initial = emptyList())
    val selectedTribe by viewModel.selectedTribe.collectAsState(initial = "All")
    val showCreatePost by viewModel.showCreatePost.collectAsState(initial = false)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(PulseColors.darkBg)
    ) {
        // Top Bar with Title
        TopAppBar(
            title = { Text("Community", color = PulseColors.text, fontSize = 18.sp, fontWeight = FontWeight.Bold) },
            backgroundColor = PulseColors.darkBg,
            elevation = 0.dp
        )

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .weight(1f),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            contentPadding = PaddingValues(16.dp)
        ) {
            // Tribe Filter Pills
            item {
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    items(listOf("All", "Productivity", "Creators", "Fitness", "Parents", "Gamers")) { tribe ->
                        FilterPillContent(
                            label = tribe,
                            isSelected = selectedTribe == tribe,
                            onSelect = { viewModel.selectTribe(tribe) }
                        )
                    }
                }
            }

            // Create Post Button
            item {
                Button(
                    onClick = { viewModel.toggleCreatePost() },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = PulseColors.accent,
                        contentColor = PulseColors.darkBg
                    ),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Text("+ Create Post", fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                }
            }

            // Posts Feed
            if (posts.isEmpty()) {
                item {
                    EmptyStateContent(
                        emoji = "📱",
                        title = "No Posts Yet",
                        subtitle = "Be the first to share with the community!"
                    )
                }
            } else {
                items(posts) { post ->
                    PostCardContent(
                        post = post,
                        onLike = { viewModel.toggleLike(post.id) },
                        onComment = { viewModel.commentOnPost(post.id) },
                        onShare = { viewModel.sharePost(post.id) }
                    )
                }
            }

            item { Spacer(modifier = Modifier.height(20.dp)) }
        }
    }

    // Create Post Modal
    if (showCreatePost) {
        CreatePostModalContent(
            onDismiss = { viewModel.toggleCreatePost() },
            onPost = { content, tribe ->
                viewModel.createPost(content, tribe)
                viewModel.toggleCreatePost()
            }
        )
    }
}

// MARK: - Filter Pill Component
@Composable
fun FilterPillContent(
    label: String,
    isSelected: Boolean,
    onSelect: () -> Unit
) {
    Surface(
        modifier = Modifier
            .height(36.dp)
            .clip(RoundedCornerShape(18.dp))
            .clickable(onClick = onSelect),
        color = if (isSelected) PulseColors.accent else PulseColors.surface,
        shape = RoundedCornerShape(18.dp)
    ) {
        Box(
            modifier = Modifier
                .padding(horizontal = 12.dp, vertical = 8.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = label,
                fontSize = 12.sp,
                fontWeight = FontWeight.SemiBold,
                color = if (isSelected) PulseColors.darkBg else PulseColors.secondary
            )
        }
    }
}

// MARK: - Post Card Component
@Composable
fun PostCardContent(
    post: Post,
    onLike: () -> Unit = {},
    onComment: () -> Unit = {},
    onShare: () -> Unit = {}
) {
    var isLiked by remember { mutableStateOf(post.likedByUser) }

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
            // Author Info
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    modifier = Modifier.weight(1f),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Avatar Circle
                    Surface(
                        modifier = Modifier
                            .size(32.dp)
                            .clip(CircleShape),
                        color = PulseColors.separator
                    ) {
                        Box(
                            contentAlignment = Alignment.Center,
                            modifier = Modifier.fillMaxSize()
                        ) {
                            Text(
                                text = post.author.take(1),
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                color = PulseColors.accent
                            )
                        }
                    }

                    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Text(
                            text = post.author,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = PulseColors.text
                        )
                        Text(
                            text = getRelativeTime(post.createdAt),
                            fontSize = 11.sp,
                            color = PulseColors.secondary
                        )
                    }
                }
            }

            // Content
            Text(
                text = post.content,
                fontSize = 14.sp,
                color = PulseColors.text,
                maxLines = 5,
                overflow = TextOverflow.Ellipsis
            )

            // Engagement Metrics
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Like Button
                Row(
                    modifier = Modifier.clickable {
                        isLiked = !isLiked
                        onLike()
                    },
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = if (isLiked) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
                        contentDescription = "Like",
                        tint = if (isLiked) Color(0xFFFF4757) else PulseColors.secondary,
                        modifier = Modifier.size(12.sp.value.dp)
                    )
                    Text(
                        text = (post.likeCount + if (isLiked && !post.likedByUser) 1 else 0).toString(),
                        fontSize = 12.sp,
                        color = PulseColors.secondary
                    )
                }

                // Comment Button
                Row(
                    modifier = Modifier.clickable(onClick = onComment),
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "💬",
                        fontSize = 12.sp
                    )
                    Text(
                        text = post.commentCount.toString(),
                        fontSize = 12.sp,
                        color = PulseColors.secondary
                    )
                }

                // Share Button
                Row(
                    modifier = Modifier.clickable(onClick = onShare),
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Filled.Share,
                        contentDescription = "Share",
                        tint = PulseColors.secondary,
                        modifier = Modifier.size(12.sp.value.dp)
                    )
                }

                Spacer(modifier = Modifier.weight(1f))

                // Tribe Label
                Surface(
                    modifier = Modifier
                        .clip(RoundedCornerShape(4.dp))
                        .padding(4.dp),
                    color = PulseColors.separator.copy(alpha = 0.3f)
                ) {
                    Text(
                        text = post.tribe,
                        fontSize = 10.sp,
                        color = PulseColors.secondary,
                        modifier = Modifier.padding(4.dp)
                    )
                }
            }
        }
    }
}

// MARK: - Create Post Modal
@Composable
fun CreatePostModalContent(
    onDismiss: () -> Unit,
    onPost: (String, String) -> Unit
) {
    var postContent by remember { mutableStateOf("") }
    var selectedTribe by remember { mutableStateOf("Productivity") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Create Post", color = PulseColors.text) },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(PulseColors.darkBg),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Tribe Dropdown
                ExposedDropdownMenuBox(
                    expanded = false,
                    onExpandedChange = {}
                ) {
                    TextField(
                        value = selectedTribe,
                        onValueChange = { selectedTribe = it },
                        label = { Text("Tribe") },
                        readOnly = true,
                        modifier = Modifier.fillMaxWidth(),
                        colors = TextFieldDefaults.textFieldColors(
                            containerColor = PulseColors.surface,
                            textColor = PulseColors.text
                        )
                    )
                }

                // Content Input
                TextField(
                    value = postContent,
                    onValueChange = { postContent = it },
                    label = { Text("What's on your mind?") },
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = 100.dp, max = 200.dp),
                    colors = TextFieldDefaults.textFieldColors(
                        containerColor = PulseColors.surface,
                        textColor = PulseColors.text
                    )
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    if (postContent.isNotBlank()) {
                        onPost(postContent, selectedTribe)
                    }
                },
                colors = ButtonDefaults.buttonColors(
                    containerColor = PulseColors.accent,
                    contentColor = PulseColors.darkBg
                ),
                enabled = postContent.isNotBlank()
            ) {
                Text("Share")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel", color = PulseColors.accent)
            }
        },
        containerColor = PulseColors.surface
    )
}

// MARK: - Community View Model
class CommunityViewModel : androidx.lifecycle.ViewModel() {
    private val _posts = MutableStateFlow<List<Post>>(Post.mockPosts)
    val posts: StateFlow<List<Post>> = _posts

    private val _selectedTribe = MutableStateFlow("All")
    val selectedTribe: StateFlow<String> = _selectedTribe

    private val _showCreatePost = MutableStateFlow(false)
    val showCreatePost: StateFlow<Boolean> = _showCreatePost

    fun selectTribe(tribe: String) {
        _selectedTribe.value = tribe
        loadPosts(tribe)
    }

    fun toggleCreatePost() {
        _showCreatePost.value = !_showCreatePost.value
    }

    fun createPost(content: String, tribe: String) {
        val newPost = Post(
            id = "post_${System.currentTimeMillis()}",
            author = "You",
            content = content,
            tribe = tribe,
            createdAt = System.currentTimeMillis(),
            likeCount = 0,
            commentCount = 0,
            totalReactions = 0,
            likedByUser = false
        )
        val updatedPosts = listOf(newPost) + _posts.value
        _posts.value = updatedPosts
        AnalyticsService.shared.logEvent("post_created")
    }

    fun toggleLike(postId: String) {
        val updatedPosts = _posts.value.map { post ->
            if (post.id == postId) {
                post.copy(
                    likeCount = if (post.likedByUser) post.likeCount - 1 else post.likeCount + 1,
                    likedByUser = !post.likedByUser
                )
            } else post
        }
        _posts.value = updatedPosts
        AnalyticsService.shared.logEvent("post_liked")
    }

    fun commentOnPost(postId: String) {
        val updatedPosts = _posts.value.map { post ->
            if (post.id == postId) {
                post.copy(commentCount = post.commentCount + 1)
            } else post
        }
        _posts.value = updatedPosts
        AnalyticsService.shared.logEvent("post_commented")
    }

    fun sharePost(postId: String) {
        AnalyticsService.shared.logEvent("post_shared")
    }

    private fun loadPosts(tribe: String) {
        val filtered = if (tribe == "All") {
            Post.mockPosts
        } else {
            Post.mockPosts.filter { it.tribe == tribe }
        }
        _posts.value = filtered
        AnalyticsService.shared.logEvent("posts_filtered")
    }
}

// MARK: - Helper Functions
private fun getRelativeTime(timestamp: Long): String {
    val now = System.currentTimeMillis()
    val diffMinutes = (now - timestamp) / (1000 * 60)
    val diffHours = diffMinutes / 60
    val diffDays = diffHours / 24

    return when {
        diffMinutes < 1 -> "Just now"
        diffMinutes < 60 -> "${diffMinutes}m ago"
        diffHours < 24 -> "${diffHours}h ago"
        diffDays == 1L -> "Yesterday"
        diffDays < 7 -> "${diffDays}d ago"
        else -> "1w ago"
    }
}
