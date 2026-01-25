import '../models/feed_post_model.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';
import '../services/dummy_data_service.dart';

class FeedService {
  static final FeedService _instance = FeedService._internal();
  factory FeedService() => _instance;

  FeedService._internal();

  // Get personalized feed with ranking
  List<FeedPost> getPersonalizedFeed({
    List<String>? followedUserIds,
    List<String>? userInterests,
    List<String>? searchHistory,
  }) {
    final allPosts = _generateFeedPosts();
    
    // Rank posts based on relevance
    final rankedPosts = allPosts.map((post) {
      double score = 0.0;
      
      // Follow relationship (high priority)
      if (followedUserIds != null && followedUserIds.contains(post.userId)) {
        score += 100.0;
      }
      
      // Tagged posts (high priority)
      if (post.isTagged) {
        score += 80.0;
      }
      
      // Engagement history (liked posts from followed users)
      if (post.isLiked && followedUserIds != null && followedUserIds.contains(post.userId)) {
        score += 50.0;
      }
      
      // Interest matching
      if (userInterests != null) {
        final matchingHashtags = post.hashtags
            .where((tag) => userInterests.any((interest) => 
                tag.toLowerCase().contains(interest.toLowerCase())))
            .length;
        score += matchingHashtags * 10.0;
      }
      
      // Search history matching
      if (searchHistory != null && post.caption != null) {
        final matchingKeywords = searchHistory
            .where((keyword) => post.caption!.toLowerCase().contains(keyword.toLowerCase()))
            .length;
        score += matchingKeywords * 5.0;
      }
      
      // Recent posts get slight boost
      final hoursSincePost = DateTime.now().difference(post.createdAt).inHours;
      score += (24 - hoursSincePost).clamp(0, 24) * 0.5;
      
      return {'post': post, 'score': score};
    }).toList();
    
    // Sort by score (highest first)
    rankedPosts.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    
    // Insert ads every 5 posts
    final finalFeed = <FeedPost>[];
    for (int i = 0; i < rankedPosts.length; i++) {
      finalFeed.add(rankedPosts[i]['post'] as FeedPost);
      if ((i + 1) % 5 == 0 && i < rankedPosts.length - 1) {
        // Insert ad
        final ads = _getAds();
        if (ads.isNotEmpty) {
          finalFeed.add(ads[i % ads.length]);
        }
      }
    }
    
    return finalFeed;
  }

  List<FeedPost> _generateFeedPosts() {
    final now = DateTime.now();
    return [
      // Followed user posts
      FeedPost(
        id: 'post-1',
        userId: 'user-2',
        userName: 'Alice Smith',
        mediaType: PostMediaType.image,
        mediaUrls: ['image_url_1'],
        caption: 'Beautiful sunset today! 🌅 #sunset #nature #photography',
        hashtags: ['sunset', 'nature', 'photography'],
        createdAt: now.subtract(const Duration(hours: 2)),
        likes: 245,
        comments: 12,
        isLiked: false,
        isFollowed: true,
      ),
      FeedPost(
        id: 'post-2',
        userId: 'user-3',
        userName: 'Bob Johnson',
        mediaType: PostMediaType.video,
        mediaUrls: ['video_url_1'],
        caption: 'Working on something exciting! 💻 #coding #tech',
        hashtags: ['coding', 'tech'],
        createdAt: now.subtract(const Duration(hours: 5)),
        likes: 189,
        comments: 8,
        views: 1200,
        isLiked: true,
        isFollowed: true,
      ),
      // Tagged post
      FeedPost(
        id: 'post-3',
        userId: 'user-4',
        userName: 'Emma Wilson',
        mediaType: PostMediaType.carousel,
        mediaUrls: ['image_url_2', 'image_url_3', 'image_url_4'],
        caption: 'Tagged you in this! @JohnDoe #friends #memories',
        hashtags: ['friends', 'memories'],
        createdAt: now.subtract(const Duration(hours: 1)),
        likes: 156,
        comments: 5,
        isLiked: false,
        isTagged: true,
      ),
      // Carousel post
      FeedPost(
        id: 'post-4',
        userId: 'user-5',
        userName: 'Mike Brown',
        mediaType: PostMediaType.carousel,
        mediaUrls: ['image_url_5', 'image_url_6'],
        caption: 'Check out my new collection! 🎨 #art #design',
        hashtags: ['art', 'design'],
        createdAt: now.subtract(const Duration(hours: 3)),
        likes: 320,
        comments: 15,
        isLiked: false,
        isFollowed: true,
      ),
      // Reel
      FeedPost(
        id: 'post-5',
        userId: 'user-6',
        userName: 'Sarah Davis',
        mediaType: PostMediaType.reel,
        mediaUrls: ['reel_url_1'],
        caption: 'Quick tutorial! #tutorial #tips',
        hashtags: ['tutorial', 'tips'],
        createdAt: now.subtract(const Duration(hours: 4)),
        likes: 890,
        comments: 45,
        views: 5000,
        isLiked: true,
      ),
      // Suggested public post
      FeedPost(
        id: 'post-6',
        userId: 'user-7',
        userName: 'David Lee',
        mediaType: PostMediaType.image,
        mediaUrls: ['image_url_7'],
        caption: 'Amazing day at the beach! 🏖️ #beach #summer',
        hashtags: ['beach', 'summer'],
        createdAt: now.subtract(const Duration(hours: 6)),
        likes: 278,
        comments: 22,
        isLiked: false,
      ),
      FeedPost(
        id: 'post-7',
        userId: 'user-8',
        userName: 'Lisa Chen',
        isVerified: true,
        mediaType: PostMediaType.video,
        mediaUrls: ['video_url_2'],
        caption: 'New recipe I tried today! 🍰 #food #cooking',
        hashtags: ['food', 'cooking'],
        createdAt: now.subtract(const Duration(hours: 8)),
        likes: 412,
        comments: 18,
        views: 2500,
        isLiked: true,
      ),
    ];
  }

  List<FeedPost> _getAds() {
    final now = DateTime.now();
    return [
      FeedPost(
        id: 'ad-post-1',
        userId: 'advertiser-1',
        userName: 'Sponsored',
        mediaType: PostMediaType.image,
        mediaUrls: ['ad_image_1'],
        caption: 'Special Offer - 50% Off!',
        createdAt: now.subtract(const Duration(hours: 1)),
        likes: 0,
        comments: 0,
        isAd: true,
        adTitle: 'Special Offer',
        adCompanyId: 'company-1',
        adCompanyName: 'TechCorp',
      ),
    ];
  }

  // Get stories for online users
  List<StoryGroup> getStories() {
    final users = DummyDataService().getOnlineUsers();
    final now = DateTime.now();
    
    return users.map((user) {
      return StoryGroup(
        userId: user.id,
        userName: user.name,
        userAvatar: user.avatarUrl,
        isOnline: user.isOnline,
        stories: [
          Story(
            id: 'story-${user.id}-1',
            userId: user.id,
            userName: user.name,
            mediaUrl: 'story_media_url',
            mediaType: StoryMediaType.image,
            createdAt: now.subtract(const Duration(hours: 2)),
            views: 50,
            isViewed: false,
          ),
          Story(
            id: 'story-${user.id}-2',
            userId: user.id,
            userName: user.name,
            mediaUrl: 'story_media_url_2',
            mediaType: StoryMediaType.video,
            createdAt: now.subtract(const Duration(hours: 1)),
            views: 30,
            isViewed: false,
          ),
        ],
      );
    }).toList();
  }
  
  // Get current user for profile icon
  User getCurrentUser() {
    return DummyDataService().getCurrentUser();
  }

  // Like/Unlike post
  FeedPost toggleLike(FeedPost post) {
    return post.copyWith(
      isLiked: !post.isLiked,
      likes: post.isLiked ? post.likes - 1 : post.likes + 1,
    );
  }

  // Save/Unsave post
  FeedPost toggleSave(FeedPost post) {
    return post.copyWith(isSaved: !post.isSaved);
  }

  // Follow/Unfollow user
  FeedPost toggleFollow(FeedPost post) {
    return post.copyWith(isFollowed: !post.isFollowed);
  }
}
