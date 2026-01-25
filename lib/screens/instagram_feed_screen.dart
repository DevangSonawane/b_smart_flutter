import 'package:flutter/material.dart';
import 'dart:async';
import '../models/feed_post_model.dart';
import '../models/story_model.dart';
import '../services/feed_service.dart';
import '../services/wallet_service.dart';
import '../services/notification_service.dart';
import '../theme/sci_fi_theme.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'wallet_screen.dart';
import 'story_viewer_screen.dart';
import 'ad_company_detail_screen.dart';

class InstagramFeedScreen extends StatefulWidget {
  const InstagramFeedScreen({super.key});

  @override
  State<InstagramFeedScreen> createState() => _InstagramFeedScreenState();
}

class _InstagramFeedScreenState extends State<InstagramFeedScreen> {
  final FeedService _feedService = FeedService();
  final WalletService _walletService = WalletService();
  final NotificationService _notificationService = NotificationService();
  
  final ScrollController _scrollController = ScrollController();
  bool _isHeaderVisible = true;
  double _lastScrollOffset = 0;
  
  List<FeedPost> _feedPosts = [];
  List<StoryGroup> _stories = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFeed();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;
    
    // Hide/show header based on scroll direction
    if (currentOffset > _lastScrollOffset && currentOffset > 50) {
      // Scrolling down - hide header
      if (_isHeaderVisible) {
        setState(() {
          _isHeaderVisible = false;
        });
      }
    } else if (currentOffset < _lastScrollOffset) {
      // Scrolling up - show header
      if (!_isHeaderVisible) {
        setState(() {
          _isHeaderVisible = true;
        });
      }
    }
    
    _lastScrollOffset = currentOffset;
    
    // Load more when near bottom
    if (currentOffset >= _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final posts = _feedService.getPersonalizedFeed(
      followedUserIds: ['user-2', 'user-3', 'user-4', 'user-5'],
      userInterests: ['technology', 'photography', 'art'],
    );
    final stories = _feedService.getStories();

    setState(() {
      _feedPosts = posts;
      _stories = stories;
      _isLoading = false;
    });
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    // Load more posts (in real app, this would be paginated API call)
    final morePosts = _feedService.getPersonalizedFeed();
    setState(() {
      _feedPosts.addAll(morePosts);
      _isLoadingMore = false;
    });
  }

  void _handleLike(FeedPost post) {
    setState(() {
      final index = _feedPosts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _feedPosts[index] = _feedService.toggleLike(post);
      }
    });
  }

  void _handleSave(FeedPost post) {
    setState(() {
      final index = _feedPosts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _feedPosts[index] = _feedService.toggleSave(post);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(post.isSaved ? 'Post unsaved' : 'Post saved'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleFollow(FeedPost post) {
    setState(() {
      final index = _feedPosts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _feedPosts[index] = _feedService.toggleFollow(post);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: SciFiTheme.backgroundGradient,
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      SciFiTheme.accentCyan),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadFeed,
                color: SciFiTheme.accentCyan,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Dynamic Header
                    SliverAppBar(
                      floating: true,
                      pinned: false,
                      snap: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: _isHeaderVisible ? _buildProfileIcon() : null,
                      title: _isHeaderVisible ? _buildSearchBar() : null,
                      actions: _isHeaderVisible ? _buildHeaderActions() : null,
                    ),

                  // Stories Section
                  SliverToBoxAdapter(
                    child: _buildStoriesSection(),
                  ),

                  // Feed Posts
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < _feedPosts.length) {
                          return _buildPostCard(_feedPosts[index]);
                        } else if (_isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    SciFiTheme.accentCyan),
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                      childCount: _feedPosts.length + (_isLoadingMore ? 1 : 0),
                    ),
                  ),
                ],
              ),
            ),
        ),
    );
  }

  Widget _buildProfileIcon() {
    final user = _feedService.getCurrentUser();
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SciFiTheme.accentGradient,
          border: Border.all(
            color: SciFiTheme.accentCyan,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: SciFiTheme.accentCyan.withValues(alpha: 0.3),
              blurRadius: 6,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 14,
          backgroundColor: Colors.transparent,
          child: Text(
            user.name[0].toUpperCase(),
            style: const TextStyle(
              color: SciFiTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Expanded(
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: SciFiTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: SciFiTheme.accentCyan.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: SciFiTheme.accentCyan.withValues(alpha: 0.1),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: TextField(
          style: const TextStyle(color: SciFiTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Search',
            hintStyle: TextStyle(color: SciFiTheme.textSecondary),
            prefixIcon: Icon(Icons.search, size: 20, color: SciFiTheme.accentCyan),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Search feature coming soon'),
                backgroundColor: SciFiTheme.cardDark,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildHeaderActions() {
    return [
      // Notifications
      Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: SciFiTheme.cardGradient,
              shape: BoxShape.circle,
              border: Border.all(
                color: SciFiTheme.accentCyan.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.favorite_outline,
                  size: 24, color: SciFiTheme.accentCyan),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                ).then((_) {
                  setState(() {}); // Refresh badge
                });
              },
            ),
          ),
          if (_notificationService.getUnreadCount() > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF3B5C), Color(0xFFFF6B8A)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3B5C).withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  _notificationService.getUnreadCount() > 99
                      ? '99+'
                      : _notificationService.getUnreadCount().toString(),
                  style: const TextStyle(
                    color: SciFiTheme.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      // Coins
      GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const WalletScreen()),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                blurRadius: 6,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on,
                  color: SciFiTheme.textPrimary, size: 16),
              const SizedBox(width: 4),
              Text(
                '${_walletService.getCoinBalance()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SciFiTheme.textPrimary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildStoriesSection() {
    if (_stories.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _stories.length,
        itemBuilder: (context, index) {
          final storyGroup = _stories[index];
          return _buildStoryItem(storyGroup);
        },
      ),
    );
  }

  Widget _buildStoryItem(StoryGroup storyGroup) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StoryViewerScreen(
              storyGroups: _stories,
              initialIndex: _stories.indexOf(storyGroup),
            ),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.pink, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                    ),
                    child: Center(
                      child: Text(
                        storyGroup.userName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                if (storyGroup.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              storyGroup.userName.split(' ').first,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(FeedPost post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: SciFiTheme.cardGradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: SciFiTheme.accentCyan.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          _buildPostHeader(post),
          
          // Media Section
          _buildMediaSection(post),
          
          // Action Bar
          _buildActionBar(post),
          
          // Engagement Info
          _buildEngagementInfo(post),
          
          // Caption & Tags
          if (post.caption != null) _buildCaption(post),
          
          // Comments Link
          if (post.comments > 0) _buildCommentsLink(post),
          
          // Timestamp
          _buildTimestamp(post),
          
          const SizedBox(height: 8),
        ],
        ),
      ),
    );
  }

  Widget _buildPostHeader(FeedPost post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue,
            child: Text(
              post.userName[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      post.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: SciFiTheme.textPrimary,
                      ),
                    ),
                    if (post.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 16, color: Colors.blue),
                    ],
                    if (post.isAd) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Sponsored',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
                if (post.isTagged)
                  Text(
                    'Tagged you',
                    style: TextStyle(color: Colors.orange[400], fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20, color: SciFiTheme.textPrimary),
            onPressed: () => _showPostOptions(post),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection(FeedPost post) {
    if (post.mediaType == PostMediaType.carousel) {
      return _buildCarousel(post);
    }
    
    return GestureDetector(
      onDoubleTap: () => _handleLike(post),
      child: Container(
        width: double.infinity,
        height: 400,
        color: Colors.grey[300],
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Placeholder for media
            Icon(
              post.mediaType == PostMediaType.video || post.mediaType == PostMediaType.reel
                  ? Icons.play_circle_outline
                  : Icons.image,
              size: 80,
              color: Colors.grey[600],
            ),
            if (post.mediaType == PostMediaType.video || post.mediaType == PostMediaType.reel)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel(FeedPost post) {
    return SizedBox(
      height: 400,
      child: PageView.builder(
        itemCount: post.mediaUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onDoubleTap: () => _handleLike(post),
            child: Container(
              width: double.infinity,
              color: Colors.grey[300],
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.image, size: 80, color: Colors.grey),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${index + 1}/${post.mediaUrls.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionBar(FeedPost post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              post.isLiked ? Icons.favorite : Icons.favorite_border,
              color: post.isLiked ? Colors.red : SciFiTheme.textPrimary,
            ),
            onPressed: () => _handleLike(post),
          ),
          IconButton(
            icon: const Icon(Icons.comment_outlined, color: SciFiTheme.textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Comments feature coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined, color: SciFiTheme.textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon')),
              );
            },
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              post.isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: post.isSaved ? Colors.yellow : SciFiTheme.textPrimary,
            ),
            onPressed: () => _handleSave(post),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementInfo(FeedPost post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.likes > 0)
            Text(
              '${post.likes} likes',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: SciFiTheme.textPrimary,
              ),
            ),
          if (post.views > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${post.views} views',
              style: TextStyle(color: SciFiTheme.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCaption(FeedPost post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: SciFiTheme.textPrimary),
          children: [
            TextSpan(
              text: '${post.userName} ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ...post.hashtags.map((tag) => TextSpan(
              text: '#$tag ',
              style: const TextStyle(color: SciFiTheme.accentCyan),
            )),
            TextSpan(text: post.caption?.replaceAll(RegExp(r'#\w+'), '') ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsLink(FeedPost post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('View all ${post.comments} comments')),
          );
        },
        child: Text(
          'View all ${post.comments} comments',
          style: TextStyle(color: SciFiTheme.textSecondary, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildTimestamp(FeedPost post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        _formatTimestamp(post.createdAt),
        style: TextStyle(color: SciFiTheme.textSecondary, fontSize: 12),
      ),
    );
  }

  void _showPostOptions(FeedPost post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(post.isFollowed ? Icons.person_remove : Icons.person_add),
            title: Text(post.isFollowed ? 'Unfollow' : 'Follow'),
            onTap: () {
              Navigator.pop(context);
              _handleFollow(post);
            },
          ),
          ListTile(
            leading: const Icon(Icons.volume_off),
            title: const Text('Mute'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User muted')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Report'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted')),
              );
            },
          ),
          if (post.isAd)
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View Advertiser'),
              onTap: () {
                Navigator.pop(context);
                if (post.adCompanyId != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AdCompanyDetailScreen(
                        companyId: post.adCompanyId!,
                      ),
                    ),
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
