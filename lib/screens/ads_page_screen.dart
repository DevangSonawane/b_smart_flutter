import 'package:flutter/material.dart';
import 'dart:async';
import '../models/ad_model.dart';
import '../models/ad_category_model.dart';
import '../services/ad_category_service.dart';
import '../services/ad_eligibility_service.dart';
import '../services/wallet_service.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import 'ad_company_detail_screen.dart';

class AdsPageScreen extends StatefulWidget {
  const AdsPageScreen({super.key});

  @override
  State<AdsPageScreen> createState() => _AdsPageScreenState();
}

class _AdsPageScreenState extends State<AdsPageScreen>
    with WidgetsBindingObserver {
  final AdCategoryService _categoryService = AdCategoryService();
  final AdEligibilityService _eligibilityService = AdEligibilityService();
  final WalletService _walletService = WalletService();
  final NotificationService _notificationService = NotificationService();

  final String _userId = 'user-1';

  List<AdCategory> _categories = [];
  String _selectedCategoryId = 'all';
  List<Ad> _ads = [];
  Ad? _currentAd;
  AdWatchSession? _watchSession;
  Timer? _watchTimer;
  
  bool _isLoading = true;
  bool _isPaused = false;
  bool _isMuted = false;
  int _pauseCount = 0;
  int _totalPauseDuration = 0;
  DateTime? _pauseStartTime;
  bool _isInForeground = true;
  int _views = 0;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCategoriesAndAds();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _watchTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final wasInForeground = _isInForeground;
    _isInForeground = state == AppLifecycleState.resumed;
    if (!_isInForeground && _watchSession != null) {
      _pauseAd();
    } else if (_isInForeground && !wasInForeground && _watchSession != null && _isPaused) {
      _resumeAd();
    }
  }

  void _loadCategoriesAndAds() {
    setState(() {
      _isLoading = true;
    });

    _categories = _categoryService.getCategories();
    _ads = _categoryService.getAdsByCategory(
      categoryId: _selectedCategoryId,
      userLanguages: ['en'],
      userPreferences: ['technology', 'fashion'],
      userLocation: 'US',
    );

    if (_ads.isNotEmpty) {
      _currentAd = _ads[0];
      _loadAdDetails();
      _startWatchingAd();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _loadAdDetails() {
    if (_currentAd == null) return;
    
    // Load ad engagement data (dummy)
    setState(() {
      _views = _currentAd!.currentViews + 100;
      _isLiked = false;
    });
  }

  void _onCategorySelected(String categoryId) {
    if (_selectedCategoryId == categoryId) return;

    _watchTimer?.cancel();
    setState(() {
      _selectedCategoryId = categoryId;
      _isPaused = false;
      _pauseCount = 0;
      _totalPauseDuration = 0;
    });

    _loadCategoriesAndAds();
  }

  void _startWatchingAd() {
    if (_currentAd == null) return;

    final eligibility = _eligibilityService.checkEligibility(_userId, _currentAd!);
    if (!eligibility.isEligible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(eligibility.reason ?? 'Not eligible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _watchSession = AdWatchSession(
        adId: _currentAd!.id,
        startTime: DateTime.now(),
        totalDuration: _currentAd!.watchDurationSeconds,
      );
      _isPaused = false;
      _isInForeground = true;
    });

    _startWatchTimer();
  }

  void _startWatchTimer() {
    _watchTimer?.cancel();
    int watchedSeconds = 0;

    _watchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused || !_isInForeground) {
        return;
      }

      watchedSeconds++;
      final percentage = (watchedSeconds / (_currentAd?.watchDurationSeconds ?? 1)) * 100;

      setState(() {
        if (_watchSession != null) {
          _watchSession = _watchSession!.copyWith(
            watchedDuration: watchedSeconds,
            watchPercentage: percentage,
            isMuted: _isMuted,
            pauseCount: _pauseCount,
            totalPauseDuration: _totalPauseDuration,
            isInForeground: _isInForeground,
          );
        }
      });

      if (watchedSeconds >= (_currentAd?.watchDurationSeconds ?? 0)) {
        _completeAdWatch();
        timer.cancel();
      }
    });
  }

  void _pauseAd() {
    if (_isPaused) return;
    
    if (_pauseCount >= AdEligibilityService.maxPauseCount) {
      return;
    }

    _watchTimer?.cancel();
    setState(() {
      _isPaused = true;
      _pauseCount++;
      _pauseStartTime = DateTime.now();
    });
  }

  void _resumeAd() {
    if (!_isPaused) return;

    if (_pauseStartTime != null) {
      final pauseDuration = DateTime.now().difference(_pauseStartTime!).inSeconds;
      _totalPauseDuration += pauseDuration;
      _pauseStartTime = null;
    }

    setState(() {
      _isPaused = false;
    });
    _startWatchTimer();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });
  }

  void _handleComment() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(hintText: 'Add a comment...'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comment added')),
                );
              },
              child: const Text('Post Comment'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon')),
    );
  }

  Future<void> _completeAdWatch() async {
    if (_currentAd == null || _watchSession == null) return;

    final watchPercentage = _watchSession!.watchPercentage;
    if (watchPercentage < AdEligibilityService.minWatchPercentage * 100) {
      return;
    }

    if (_pauseCount > AdEligibilityService.maxPauseCount ||
        _totalPauseDuration > AdEligibilityService.maxTotalPauseDuration) {
      return;
    }

    if (!_isInForeground) {
      return;
    }

    final eligibility = _eligibilityService.checkEligibility(_userId, _currentAd!);
    if (!eligibility.isEligible) {
      return;
    }

    final success = await _walletService.addCoinsViaLedger(
      amount: _currentAd!.coinReward,
      description: 'Watched Ad: ${_currentAd!.title}',
      adId: _currentAd!.id,
      metadata: {
        'watchPercentage': watchPercentage,
        'watchDuration': _watchSession!.watchedDuration,
        'pauseCount': _pauseCount,
      },
    );

    if (success) {
      _eligibilityService.recordAdWatch(_userId, _currentAd!.id, _currentAd!.coinReward);

      _notificationService.addNotification(
        NotificationItem(
          id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.activity,
          title: 'Coins Earned',
          message: 'You earned ${_currentAd!.coinReward} coins by watching an ad',
          timestamp: DateTime.now(),
          isRead: false,
        ),
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Success!'),
            content: Text('You earned ${_currentAd!.coinReward} coins!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadNextAd();
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _loadNextAd() {
    final nextAd = _categoryService.getNextEligibleAd(
      currentAdId: _currentAd?.id ?? '',
      categoryId: _selectedCategoryId,
      userLanguages: ['en'],
      userPreferences: ['technology', 'fashion'],
      userLocation: 'US',
    );

    if (nextAd != null) {
      _watchTimer?.cancel();
      setState(() {
        _currentAd = nextAd;
        _isPaused = false;
        _pauseCount = 0;
        _totalPauseDuration = 0;
        _isLiked = false;
      });
      _loadAdDetails();
      _startWatchingAd();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more ads available')),
      );
    }
  }

  void _loadPreviousAd() {
    final previousAd = _categoryService.getPreviousAd(
      currentAdId: _currentAd?.id ?? '',
      categoryId: _selectedCategoryId,
      userLanguages: ['en'],
      userPreferences: ['technology', 'fashion'],
      userLocation: 'US',
    );

    if (previousAd != null) {
      _watchTimer?.cancel();
      setState(() {
        _currentAd = previousAd;
        _isPaused = false;
        _pauseCount = 0;
        _totalPauseDuration = 0;
        _isLiked = false;
      });
      _loadAdDetails();
      _startWatchingAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentAd == null
              ? _buildEmptyState()
              : GestureDetector(
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity != null) {
                      if (details.primaryVelocity! < -500) {
                        // Swipe up
                        _loadNextAd();
                      } else if (details.primaryVelocity! > 500) {
                        // Swipe down
                        _loadPreviousAd();
                      }
                    }
                  },
                  onHorizontalDragEnd: (details) {
                    // Horizontal swipe for tab navigation
                    // This will be handled by the parent HomeDashboard
                    // For now, we'll just pause the ad
                    if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 500) {
                      _pauseAd();
                    }
                  },
                  child: Column(
                    children: [
                      // Video Player Section
                      Expanded(
                        child: Stack(
                          children: [
                            _buildVideoPlayer(),
                            _buildRightOverlay(),
                            // Category Header positioned lower
                            Positioned(
                              top: 60,
                              left: 0,
                              right: 0,
                              child: _buildCategoryHeader(),
                            ),
                          ],
                        ),
                      ),

                      // Information Section
                      _buildInformationSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCategoryHeader() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategoryId == category.id;

          return GestureDetector(
            onTap: () => _onCategorySelected(category.id),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  category.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_currentAd == null) return const SizedBox();

    final progress = _watchSession?.watchPercentage ?? 0.0 / 100;

    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Placeholder for video
          const Icon(Icons.play_circle_outline, size: 100, color: Colors.white54),
          
          // Progress bar at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 4,
            ),
          ),

          // Play/Pause overlay
          if (_isPaused)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Icon(Icons.play_arrow, size: 60, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRightOverlay() {
    return Positioned(
      right: 16,
      bottom: 120,
      child: Column(
        children: [
          // Views Count
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.visibility, color: Colors.white, size: 20),
                const SizedBox(height: 4),
                Text(
                  '$_views',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Like Button
          IconButton(
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : Colors.white,
              size: 32,
            ),
            onPressed: _toggleLike,
          ),
          const SizedBox(height: 8),

          // Comment Button
          IconButton(
            icon: const Icon(Icons.comment_outlined, color: Colors.white, size: 32),
            onPressed: _handleComment,
          ),
          const SizedBox(height: 8),

          // Share Button
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white, size: 32),
            onPressed: _handleShare,
          ),
          const SizedBox(height: 8),

          // Mute/Unmute Button
          IconButton(
            icon: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
              size: 32,
            ),
            onPressed: _toggleMute,
          ),
        ],
      ),
    );
  }

  Widget _buildInformationSection() {
    if (_currentAd == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Details
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AdCompanyDetailScreen(
                    companyId: _currentAd!.companyId,
                  ),
                ),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _currentAd!.companyName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (_currentAd!.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 16, color: Colors.blue),
                          ],
                        ],
                      ),
                      Text(
                        'Tap to view company details',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Ad Category/Tags
          if (_currentAd!.targetCategories.isNotEmpty)
            Wrap(
              spacing: 8,
              children: [
                const Text(
                  'Related to: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ..._currentAd!.targetCategories.map((cat) => Chip(
                      label: Text(cat),
                      labelStyle: const TextStyle(fontSize: 12),
                    )),
              ],
            ),
          const SizedBox(height: 8),

          // Ad Description
          if (_currentAd!.description.isNotEmpty)
            Text(
              _currentAd!.description,
              style: TextStyle(color: Colors.grey[700]),
            ),
          const SizedBox(height: 16),

          // Coins Reward Information
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Watch & Earn ${_currentAd!.coinReward} Coins',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Video Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '${_watchSession?.watchedDuration ?? 0}s / ${_currentAd!.watchDurationSeconds}s',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_watchSession?.watchPercentage ?? 0.0) / 100,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                minHeight: 6,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.ads_click, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Ads Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for more ads',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
