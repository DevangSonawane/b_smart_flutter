import 'package:flutter/material.dart';
import 'dart:async';
import '../models/reel_model.dart';
import '../services/reels_service.dart';
import '../services/user_account_service.dart';
import '../models/user_account_model.dart';
import '../theme/instagram_theme.dart';
import 'profile_screen.dart';
import 'reel_comments_screen.dart';
import 'reel_remix_screen.dart';
import 'boost_post_screen.dart';
import 'report_content_screen.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final ReelsService _reelsService = ReelsService();
  final PageController _pageController = PageController();
  
  int _currentIndex = 0;
  bool _isMuted = false;
  bool _isPlaying = true;
  Timer? _viewTimer;
  List<Reel> _reels = [];

  @override
  void initState() {
    super.initState();
    _loadReels();
    _startViewTracking();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _viewTimer?.cancel();
    super.dispose();
  }

  void _loadReels() {
    setState(() {
      _reels = _reelsService.getReels();
    });
    if (_reels.isNotEmpty) {
      _reelsService.incrementViews(_reels[_currentIndex].id);
    }
  }

  void _startViewTracking() {
    _viewTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_reels.isNotEmpty && _isPlaying) {
        _reelsService.incrementViews(_reels[_currentIndex].id);
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isPlaying = true;
    });
    if (index < _reels.length) {
      _reelsService.incrementViews(_reels[index].id);
    }
  }

  void _handleSwipeUp() {
    if (_currentIndex < _reels.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleSwipeDown() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _handleDoubleTap() {
    _reelsService.toggleLike(_reels[_currentIndex].id);
    setState(() {});
    
    // Show like animation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❤️'),
        duration: Duration(milliseconds: 500),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  void _handleLike() {
    _reelsService.toggleLike(_reels[_currentIndex].id);
    setState(() {});
  }

  void _handleComment() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReelCommentsScreen(
          reel: _reels[_currentIndex],
        ),
      ),
    );
  }

  void _handleShare() {
    _reelsService.incrementShares(_reels[_currentIndex].id);
    setState(() {});
    
    showModalBottomSheet(
      context: context,
      backgroundColor: InstagramTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link, color: InstagramTheme.textBlack),
              title: Text(
                'Copy Link',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Link copied to clipboard'),
                    backgroundColor: InstagramTheme.surfaceWhite,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: InstagramTheme.textBlack),
              title: Text(
                'Share via...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Share sheet opened'),
                    backgroundColor: InstagramTheme.surfaceWhite,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    _reelsService.toggleSave(_reels[_currentIndex].id);
    setState(() {});
  }

  void _handleMore() {
    final reel = _reels[_currentIndex];
    showModalBottomSheet(
      context: context,
      backgroundColor: InstagramTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reel.isSponsored)
              ListTile(
                leading: const Icon(Icons.info_outline, color: InstagramTheme.textBlack),
                title: Text(
                  'View Ad Details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showAdDetails(reel);
                },
              ),
            if (reel.remixEnabled)
              ListTile(
                leading: const Icon(Icons.shuffle, color: InstagramTheme.textBlack),
                title: Text(
                  'Remix this Reel',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleRemix(reel);
                },
              ),
            if (reel.audioReuseEnabled)
              ListTile(
                leading: const Icon(Icons.music_note, color: InstagramTheme.textBlack),
                title: Text(
                  'Use this Audio',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleUseAudio(reel);
                },
              ),
            ListTile(
              leading: const Icon(Icons.trending_up, color: InstagramTheme.textBlack),
              title: Text(
                'Boost Reel',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () {
                Navigator.pop(context);
                final accountService = UserAccountService();
                final currentAccount = accountService.getCurrentAccount();
                if (currentAccount.accountType == AccountType.regular) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Only Creator and Business accounts can boost content'),
                      backgroundColor: InstagramTheme.errorRed,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BoostPostScreen(
                      postId: reel.id,
                      contentType: 'reel',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.not_interested, color: InstagramTheme.textBlack),
              title: Text(
                'Not Interested',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('We\'ll show you less like this'),
                    backgroundColor: InstagramTheme.surfaceWhite,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: InstagramTheme.errorRed),
              title: Text(
                'Report',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: InstagramTheme.errorRed,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleReport(reel);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAdDetails(Reel reel) {
    showDialog(
      context: context,
      barrierColor: InstagramTheme.backgroundWhite.withValues(alpha: 0.7),
      builder: (context) => AlertDialog(
        backgroundColor: InstagramTheme.surfaceWhite,
        title: Text(
          'Ad Details - ${reel.sponsorBrand}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Brand: ${reel.sponsorBrand ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (reel.productTags != null && reel.productTags!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Products:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ...reel.productTags!.map((tag) => ListTile(
                leading: const Icon(Icons.shopping_bag, color: InstagramTheme.primaryPink),
                title: Text(
                  tag.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: tag.price != null
                    ? Text(
                        '${tag.currency ?? '\$'}${tag.price}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening ${tag.externalUrl}'),
                      backgroundColor: InstagramTheme.surfaceWhite,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleRemix(Reel reel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReelRemixScreen(reel: reel),
      ),
    );
  }

  void _handleUseAudio(Reel reel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReelRemixScreen(reel: reel, useAudioOnly: true),
      ),
    );
  }

  void _handleReport(Reel reel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReportContentScreen(reelId: reel.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_reels.isEmpty) {
      return const Scaffold(
        backgroundColor: InstagramTheme.backgroundWhite,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(InstagramTheme.primaryPink),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: InstagramTheme.backgroundWhite,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < -500) {
              _handleSwipeUp();
            } else if (details.primaryVelocity! > 500) {
              _handleSwipeDown();
            }
          }
        },
        onTap: _togglePlayPause,
        onDoubleTap: _handleDoubleTap,
        onLongPressStart: (_) {
          setState(() {
            _isPlaying = false;
          });
        },
        onLongPressEnd: (_) {
          setState(() {
            _isPlaying = true;
          });
        },
        child: Stack(
          children: [
            // Video Player (PageView)
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: _onPageChanged,
              itemCount: _reels.length,
              itemBuilder: (context, index) {
                final reel = _reels[index];
                return _buildReelPlayer(reel);
              },
            ),

            // Top Controls
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: InstagramTheme.textBlack, size: 24),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isMuted ? Icons.volume_off : Icons.volume_up,
                              color: InstagramTheme.textBlack,
                              size: 24,
                            ),
                            onPressed: _toggleMute,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_currentIndex + 1} / ${_reels.length}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Right Side Actions
            Positioned(
              right: 16,
              bottom: 0,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 80),
                child: _buildRightActions(),
              ),
            ),

            // Bottom Left Metadata
            Positioned(
              left: 16,
              bottom: 0,
              right: 100,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 80),
                child: _buildBottomMetadata(),
              ),
            ),

            // Product Tags (if sponsored)
            if (_reels[_currentIndex].isSponsored &&
                _reels[_currentIndex].productTags != null &&
                _reels[_currentIndex].productTags!.isNotEmpty)
              Positioned(
                bottom: 280,
                left: 16,
                child: _buildProductTags(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReelPlayer(Reel reel) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: InstagramTheme.backgroundWhite,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            color: InstagramTheme.backgroundGrey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isPlaying ? Icons.play_circle_outline : Icons.pause_circle_outline,
                  size: 80,
                  color: InstagramTheme.textGrey.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
          
          // Play/Pause overlay
          if (!_isPlaying)
            Container(
              color: InstagramTheme.backgroundWhite.withValues(alpha: 0.6),
              child: const Center(
                child: Icon(
                  Icons.pause,
                  size: 60,
                  color: InstagramTheme.textBlack,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRightActions() {
    final reel = _reels[_currentIndex];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: reel.isLiked ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(reel.likes),
          color: reel.isLiked ? InstagramTheme.errorRed : InstagramTheme.textBlack,
          onTap: _handleLike,
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          icon: Icons.comment_outlined,
          label: _formatCount(reel.comments),
          onTap: _handleComment,
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          icon: Icons.share,
          label: _formatCount(reel.shares),
          onTap: _handleShare,
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          icon: reel.isSaved ? Icons.bookmark : Icons.bookmark_border,
          label: 'Save',
          color: reel.isSaved ? InstagramTheme.primaryPink : InstagramTheme.textBlack,
          onTap: _handleSave,
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          icon: Icons.more_vert,
          label: 'More',
          onTap: _handleMore,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color ?? InstagramTheme.textBlack, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomMetadata() {
    final reel = _reels[_currentIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Creator Info
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: InstagramTheme.surfaceWhite,
                backgroundImage: reel.userAvatarUrl != null
                    ? NetworkImage(reel.userAvatarUrl!)
                    : null,
                child: reel.userAvatarUrl == null
                    ? Text(
                        reel.userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: InstagramTheme.textBlack,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          },
                          child: Text(
                            reel.userName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (!reel.isFollowing) ...[
                        const SizedBox(width: 10),
                        Container(
                          height: 28,
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: () {
                              _reelsService.toggleFollow(reel.userId);
                              setState(() {});
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: InstagramTheme.primaryPink,
                              foregroundColor: InstagramTheme.backgroundWhite,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                              minimumSize: const Size(0, 28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Follow',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (reel.isRisingCreator || reel.isTrending) ...[
                    const SizedBox(height: 3),
                    Text(
                      reel.isRisingCreator ? 'Rising Creator' : 'Trending Today',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: InstagramTheme.primaryPink,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        
        // Caption
        if (reel.caption != null) ...[
          GestureDetector(
            onTap: () {
              // Expand caption
            },
            child: Text(
              reel.caption!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
        ],
        
        // Hashtags
        if (reel.hashtags.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: reel.hashtags.map((tag) {
              return GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening #$tag'),
                      backgroundColor: InstagramTheme.surfaceWhite,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                child: Text(
                  '#$tag ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: InstagramTheme.primaryPink,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
        ],
        
        // Audio
        if (reel.audioTitle != null) ...[
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening audio: ${reel.audioTitle}'),
                  backgroundColor: InstagramTheme.surfaceWhite,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Row(
              children: [
                const Icon(
                  Icons.music_note,
                  color: InstagramTheme.textBlack,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${reel.audioTitle}${reel.audioArtist != null ? ' - ${reel.audioArtist}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: InstagramTheme.textBlack,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Sponsored Badge
        if (reel.isSponsored)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: InstagramTheme.primaryPink,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Sponsored',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: InstagramTheme.backgroundWhite,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductTags() {
    final tags = _reels[_currentIndex].productTags!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tags.map((tag) {
        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening external product: ${tag.externalUrl}'),
                action: SnackBarAction(
                  label: 'Open',
                  onPressed: () {
                    // Open external URL
                  },
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: InstagramTheme.cardDecoration(
              color: InstagramTheme.surfaceWhite,
              borderRadius: 12,
              hasBorder: true,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: InstagramTheme.dividerGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: tag.imageUrl != null
                      ? Image.network(tag.imageUrl!)
                      : const Icon(Icons.shopping_bag, color: InstagramTheme.textBlack),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: InstagramTheme.textBlack,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tag.price != null)
                      Text(
                        '${tag.currency ?? '\$'}${tag.price}',
                        style: TextStyle(
                          color: InstagramTheme.textGrey,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Text(
                      'Opens external site',
                      style: TextStyle(
                        color: InstagramTheme.primaryPink,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
