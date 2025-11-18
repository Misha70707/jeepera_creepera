import SwiftUI

// MARK: - Community View
struct CommunityFeedView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @State private var selectedTribe: Tribe?
    @State private var showCreatePost = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseDarkBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tribe Filter Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // All filter
                            FilterPill(
                                label: "All",
                                isSelected: selectedTribe == nil,
                                action: { selectedTribe = nil }
                            )

                            // Tribe filters
                            ForEach(Tribe.allTribes) { tribe in
                                FilterPill(
                                    label: "\(tribe.icon) \(tribe.name)",
                                    isSelected: selectedTribe?.id == tribe.id,
                                    action: { selectedTribe = tribe }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 12)
                    .background(Color.pulseSurface)

                    // Feed
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if viewModel.filteredPosts.isEmpty {
                                EmptyStateView(
                                    emoji: "📭",
                                    title: "No Posts Yet",
                                    subtitle: "Be the first to share your achievement!"
                                )
                                .padding(.vertical, 40)
                            } else {
                                ForEach(viewModel.filteredPosts) { post in
                                    PostCardView(post: post)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showCreatePost = true }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.pulseAccent)
                    }
                }
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView(isPresented: $showCreatePost)
            }
            .onAppear {
                viewModel.loadPosts()
            }
        }
        .background(Color.pulseDarkBg)
    }
}

// MARK: - Community View Model
class CommunityViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var selectedTribe: Tribe?
    @Published var isLoading = false

    var filteredPosts: [Post] {
        if let tribe = selectedTribe {
            return posts.filter { $0.tribeId == tribe.id }
        }
        return posts
    }

    func loadPosts() {
        isLoading = true
        // Mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.posts = Post.mockPosts + [
                Post(
                    authorId: "user_321",
                    author: "casey_gamer",
                    content: "Finally achieved my gaming streaming goal! 1000 hours played this month! 🎮",
                    tribeId: "tribe_gamers"
                ),
                Post(
                    authorId: "user_654",
                    author: "alex_runs",
                    content: "Marathon season starts! Just hit 50k total distance 🏃‍♂️ #running #fitness",
                    tribeId: "tribe_fitness"
                ),
            ]
            self.isLoading = false
            AnalyticsService.shared.logEvent("community_loaded", properties: ["post_count": self.posts.count])
        }
    }

    func likePost(_ post: Post) {
        // Update like count
        AnalyticsService.shared.logEvent("post_liked", properties: ["post_id": post.id])
    }

    func sharePost(_ post: Post) {
        AnalyticsService.shared.logEvent("post_shared", properties: ["post_id": post.id])
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .pulseDarkBg : .pulseText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.pulseAccent : Color.pulseSeparator)
                .cornerRadius(16)
        }
    }
}

// MARK: - Post Card
struct PostCardView: View {
    let post: Post
    @State private var isLiked = false
    @State private var likeCount = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author Info
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.pulseSeparator)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(post.author.prefix(1).uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.pulseAccent)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.pulseText)

                    Text(post.createdAt.timeUntilNow)
                        .font(.system(size: 11))
                        .foregroundColor(.pulseSecondary)
                }

                Spacer()

                if let tribeId = post.tribeId,
                   let tribe = Tribe.allTribes.first(where: { $0.id == tribeId }) {
                    Text(tribe.icon)
                        .font(.system(size: 16))
                }
            }

            // Content
            Text(post.content)
                .font(.system(size: 14))
                .foregroundColor(.pulseText)
                .lineLimit(nil)

            // Reactions
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .pulseError : .pulseSecondary)
                        .font(.system(size: 14))

                    Text("\(likeCount + (isLiked ? 1 : 0))")
                        .font(.system(size: 12))
                        .foregroundColor(.pulseSecondary)
                }
                .onTapGesture {
                    isLiked.toggle()
                    likeCount = Int.random(in: 100...1000)
                }

                HStack(spacing: 6) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 14))
                        .foregroundColor(.pulseSecondary)

                    Text("\(Int.random(in: 10...100))")
                        .font(.system(size: 12))
                        .foregroundColor(.pulseSecondary)
                }

                Spacer()

                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundColor(.pulseSecondary)
                }
            }
        }
        .padding(12)
        .background(Color.pulseSurface)
        .cornerRadius(8)
    }
}

// MARK: - Create Post View
struct CreatePostView: View {
    @Binding var isPresented: Bool
    @State private var postContent = ""
    @State private var selectedTribe: Tribe?

    var canPost: Bool {
        !postContent.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Tribe selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Share to...")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.pulseText)

                    Menu {
                        Button(action: { selectedTribe = nil }) {
                            HStack {
                                Text("Public Feed")
                                if selectedTribe == nil {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }

                        Divider()

                        ForEach(Tribe.allTribes) { tribe in
                            Button(action: { selectedTribe = tribe }) {
                                HStack {
                                    Text("\(tribe.icon) \(tribe.name)")
                                    if selectedTribe?.id == tribe.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedTribe?.name ?? "Public Feed")
                                .foregroundColor(.pulseText)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.pulseAccent)
                        }
                        .padding(12)
                        .background(Color.pulseSurface)
                        .cornerRadius(8)
                    }
                }

                // Content input
                VStack(alignment: .leading, spacing: 8) {
                    Text("What did you achieve today?")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.pulseText)

                    TextEditor(text: $postContent)
                        .font(.system(size: 14))
                        .foregroundColor(.pulseText)
                        .padding(12)
                        .background(Color.pulseSurface)
                        .cornerRadius(8)
                        .frame(minHeight: 120)
                }

                Spacer()

                // Buttons
                HStack(spacing: 12) {
                    Button(action: { isPresented = false }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundColor(.pulseSecondary)
                            .background(Color.pulseSurface)
                            .cornerRadius(8)
                    }

                    Button(action: {
                        // Post
                        isPresented = false
                        AnalyticsService.shared.logEvent("post_created")
                    }) {
                        Text("Share")
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundColor(.pulseDarkBg)
                            .background(canPost ? Color.pulseAccent : Color.pulseSeparator)
                            .cornerRadius(8)
                    }
                    .disabled(!canPost)
                }
            }
            .padding(16)
            .background(Color.pulseDarkBg)
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    CommunityFeedView()
}
