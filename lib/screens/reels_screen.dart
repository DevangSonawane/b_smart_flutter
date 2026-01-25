import 'package:flutter/material.dart';
import 'dart:async';
import '../models/reel_model.dart';
import '../services/reels_service.dart';
import 'profile_screen.dart';
import 'reel_comments_screen.dart';
import 'reel_remix_screen.dart';
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share via...'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share sheet opened')),
                );
              },
            ),
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reel.isSponsored)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('View Ad Details'),
                onTap: () {
                  Navigator.pop(context);
                  _showAdDetails(reel);
                },
              ),
            if (reel.remixEnabled)
              ListTile(
                leading: const Icon(Icons.shuffle),
                title: const Text('Remix this Reel'),
                onTap: () {
                  Navigator.pop(context);
                  _handleRemix(reel);
                },
              ),
            if (reel.audioReuseEnabled)
              ListTile(
                leading: const Icon(Icons.music_note),
                title: const Text('Use this Audio'),
                onTap: () {
                  Navigator.pop(context);
                  _handleUseAudio(reel);
                },
              ),
            ListTile(
              leading: const Icon(Icons.not_interested),
              title: const Text('Not Interested'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('We\'ll show you less like this')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                _handleReport(reel);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAdDetails(Reel reel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ad Details - ${reel.sponsorBrand}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Brand: ${reel.sponsorBrand ?? 'N/A'}'),
            if (reel.productTags != null && reel.productTags!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Products:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...reel.productTags!.map((tag) => ListTile(
                leading: const Icon(Icons.shopping_bag),
                title: Text(tag.name),
                subtitle: tag.price != null ? Text('${tag.currency ?? '\$'}${tag.price}') : null,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opening ${tag.externalUrl}')),
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
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
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isMuted ? Icons.volume_off : Icons.volume_up,
                              color: Colors.white,
                            ),
                            onPressed: _toggleMute,
                          ),
                          Text(
                            '${_currentIndex + 1} / ${_reels.length}',
                            style: const TextStyle(color: Colors.white),
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
              bottom: 100,
              child: _buildRightActions(),
            ),

            // Bottom Left Metadata
            Positioned(
              left: 16,
              bottom: 120,
              right: 100,
              child: _buildBottomMetadata(),
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
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[900],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isPlaying ? Icons.play_circle_outline : Icons.pause_circle_outline,
                  size: 80,
                  color: Colors.white54,
                ),
                const SizedBox(height: 16),
                Text(
                  reel.caption ?? 'No caption',
                  style: const TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Play/Pause overlay
          if (!_isPlaying)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Icon(
                  Icons.pause,
                  size: 60,
                  color: Colors.white,
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
          color: reel.isLiked ? Colors.red : Colors.white,
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
          color: reel.isSaved ? Colors.yellow : Colors.white,
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
          Icon(icon, color: color ?? Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 12,
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
                backgroundColor: Colors.grey[800],
                backgroundImage: reel.userAvatarUrl != null
                    ? NetworkImage(reel.userAvatarUrl!)
                    : null,
                child: reel.userAvatarUrl == null
                    ? Text(reel.userName[0].toUpperCase())
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: Text(
                      reel.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (reel.isRisingCreator)
                    const Text(
                      'Rising Creator',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  if (reel.isTrending)
                    const Text(
                      'Trending Today',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (!reel.isFollowing)
              TextButton(
                onPressed: () {
                  _reelsService.toggleFollow(reel.userId);
                  setState(() {});
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Follow'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Caption
        if (reel.caption != null)
          GestureDetector(
            onTap: () {
              // Expand caption
            },
            child: Text(
              reel.caption!,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const SizedBox(height: 8),
        
        // Hashtags
        if (reel.hashtags.isNotEmpty)
          Wrap(
            spacing: 8,
            children: reel.hashtags.map((tag) {
              return GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opening #$tag')),
                  );
                },
                child: Text(
                  '#$tag ',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        
        // Audio
        if (reel.audioTitle != null)
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening audio: ${reel.audioTitle}')),
              );
            },
            child: Row(
              children: [
                const Icon(Icons.music_note, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${reel.audioTitle}${reel.audioArtist != null ? ' - ${reel.audioArtist}' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        
        // Sponsored Badge
        if (reel.isSponsored)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Sponsored',
              style: TextStyle(
                color: Colors.white,
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: tag.imageUrl != null
                      ? Image.network(tag.imageUrl!)
                      : const Icon(Icons.shopping_bag),
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
                      ),
                    ),
                    if (tag.price != null)
                      Text(
                        '${tag.currency ?? '\$'}${tag.price}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                    const Text(
                      'Opens external site',
                      style: TextStyle(
                        color: Colors.blue,
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
