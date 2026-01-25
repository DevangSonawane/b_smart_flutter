import '../models/reel_model.dart';
import '../services/dummy_data_service.dart';

class ReelsService {
  static final ReelsService _instance = ReelsService._internal();
  factory ReelsService() => _instance;

  List<Reel> _reels = [];

  ReelsService._internal() {
    _reels = _generateDummyReels();
  }

  List<Reel> getReels() {
    return List.from(_reels);
  }

  Reel? getReelById(String reelId) {
    try {
      return _reels.firstWhere((reel) => reel.id == reelId);
    } catch (e) {
      return null;
    }
  }

  List<Reel> getReelsByHashtag(String hashtag) {
    return _reels.where((reel) => reel.hashtags.contains(hashtag)).toList();
  }

  List<Reel> getReelsByAudio(String audioId) {
    return _reels.where((reel) => reel.audioId == audioId).toList();
  }

  List<Reel> getReelsByUser(String userId) {
    return _reels.where((reel) => reel.userId == userId).toList();
  }

  void toggleLike(String reelId) {
    final index = _reels.indexWhere((reel) => reel.id == reelId);
    if (index != -1) {
      final reel = _reels[index];
      _reels[index] = reel.copyWith(
        isLiked: !reel.isLiked,
        likes: reel.isLiked ? reel.likes - 1 : reel.likes + 1,
      );
    }
  }

  void toggleSave(String reelId) {
    final index = _reels.indexWhere((reel) => reel.id == reelId);
    if (index != -1) {
      final reel = _reels[index];
      _reels[index] = reel.copyWith(isSaved: !reel.isSaved);
    }
  }

  void toggleFollow(String userId) {
    for (int i = 0; i < _reels.length; i++) {
      if (_reels[i].userId == userId) {
        _reels[i] = _reels[i].copyWith(isFollowing: !_reels[i].isFollowing);
      }
    }
  }

  void incrementViews(String reelId) {
    final index = _reels.indexWhere((reel) => reel.id == reelId);
    if (index != -1) {
      final reel = _reels[index];
      _reels[index] = reel.copyWith(views: reel.views + 1);
    }
  }

  void incrementShares(String reelId) {
    final index = _reels.indexWhere((reel) => reel.id == reelId);
    if (index != -1) {
      final reel = _reels[index];
      _reels[index] = reel.copyWith(shares: reel.shares + 1);
    }
  }

  List<Reel> _generateDummyReels() {
    final now = DateTime.now();
    final users = DummyDataService().getOnlineUsers();

    return [
      Reel(
        id: 'reel-1',
        userId: users[0].id,
        userName: users[0].name,
        userAvatarUrl: users[0].avatarUrl,
        videoUrl: 'https://example.com/video1.mp4',
        caption: 'Check out this amazing content! #amazing #trending',
        hashtags: ['amazing', 'trending', 'viral'],
        audioTitle: 'Trending Sound 1',
        audioArtist: 'Artist Name',
        audioId: 'audio-1',
        likes: 1250,
        comments: 89,
        shares: 45,
        views: 15000,
        isLiked: false,
        isSaved: false,
        isFollowing: false,
        createdAt: now.subtract(const Duration(hours: 2)),
        duration: const Duration(seconds: 30),
        isRisingCreator: true,
      ),
      Reel(
        id: 'reel-2',
        userId: users[1].id,
        userName: users[1].name,
        userAvatarUrl: users[1].avatarUrl,
        videoUrl: 'https://example.com/video2.mp4',
        caption: 'Beautiful sunset vibes 🌅 #sunset #nature',
        hashtags: ['sunset', 'nature', 'beautiful'],
        audioTitle: 'Sunset Vibes',
        audioArtist: 'Nature Sounds',
        audioId: 'audio-2',
        likes: 890,
        comments: 34,
        shares: 12,
        views: 8500,
        isLiked: true,
        isSaved: true,
        isFollowing: true,
        createdAt: now.subtract(const Duration(hours: 5)),
        duration: const Duration(seconds: 25),
      ),
      Reel(
        id: 'reel-3',
        userId: users[2].id,
        userName: users[2].name,
        userAvatarUrl: users[2].avatarUrl,
        videoUrl: 'https://example.com/video3.mp4',
        caption: 'Sponsored: Check out our new product!',
        hashtags: ['sponsored', 'product', 'new'],
        audioTitle: 'Product Ad Music',
        audioArtist: 'Brand Music',
        audioId: 'audio-3',
        likes: 450,
        comments: 23,
        shares: 8,
        views: 12000,
        isLiked: false,
        isSaved: false,
        isFollowing: false,
        createdAt: now.subtract(const Duration(hours: 8)),
        duration: const Duration(seconds: 20),
        isSponsored: true,
        sponsorBrand: 'TechBrand',
        sponsorLogoUrl: null,
        productTags: [
          ProductTag(
            id: 'product-1',
            name: 'Smart Watch',
            price: 199.99,
            currency: 'USD',
            externalUrl: 'https://example.com/product/1',
          ),
        ],
        remixEnabled: false,
      ),
      Reel(
        id: 'reel-4',
        userId: users[0].id,
        userName: users[0].name,
        userAvatarUrl: users[0].avatarUrl,
        videoUrl: 'https://example.com/video4.mp4',
        caption: 'Remixed from @${users[1].name}',
        hashtags: ['remix', 'collab'],
        audioTitle: 'Trending Sound 1',
        audioArtist: 'Artist Name',
        audioId: 'audio-1',
        likes: 2100,
        comments: 156,
        shares: 78,
        views: 25000,
        isLiked: false,
        isSaved: false,
        isFollowing: false,
        createdAt: now.subtract(const Duration(hours: 12)),
        duration: const Duration(seconds: 30),
        originalReelId: 'reel-1',
        originalCreatorId: users[1].id,
        originalCreatorName: users[1].name,
        isTrending: true,
      ),
      Reel(
        id: 'reel-5',
        userId: users[3].id,
        userName: users[3].name,
        userAvatarUrl: users[3].avatarUrl,
        videoUrl: 'https://example.com/video5.mp4',
        caption: 'Fitness motivation! 💪 #fitness #motivation',
        hashtags: ['fitness', 'motivation', 'workout'],
        audioTitle: 'Workout Beat',
        audioArtist: 'Fitness Music',
        audioId: 'audio-4',
        likes: 3200,
        comments: 234,
        shares: 145,
        views: 45000,
        isLiked: true,
        isSaved: false,
        isFollowing: false,
        createdAt: now.subtract(const Duration(days: 1)),
        duration: const Duration(seconds: 35),
        isRisingCreator: true,
      ),
    ];
  }
}
