import 'package:flutter/material.dart';
import '../services/dummy_data_service.dart';
import '../theme/sci_fi_theme.dart';
import 'instagram_feed_screen.dart';
import 'ads_page_screen.dart';
import 'create_screen.dart';
import 'reels_screen.dart';
import 'promoted_products_screen.dart';

class HomeDashboard extends StatefulWidget {
  final int? initialIndex;

  const HomeDashboard({super.key, this.initialIndex});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final DummyDataService _dataService = DummyDataService();
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialIndex != null) {
      _currentIndex = widget.initialIndex!;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    await _dataService.fetchAds();
    setState(() {
      _isLoading = false;
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
            : IndexedStack(
                index: _currentIndex,
                children: [
                  const InstagramFeedScreen(),
                  const AdsPageScreen(),
                  const CreateScreen(),
                  const ReelsScreen(),
                  const PromotedProductsScreen(),
                ],
              ),
      ),
      bottomNavigationBar: _buildSciFiNavigationBar(),
    );
  }

  Widget _buildSciFiNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: SciFiTheme.cardGradient,
        boxShadow: [
          BoxShadow(
            color: SciFiTheme.accentCyan.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Home', 0),
                _buildNavItem(Icons.ads_click, 'Ads', 1),
                _buildNavItem(Icons.add_circle_outline, 'Create', 2, isCenter: true),
                _buildNavItem(Icons.video_library, 'Reels', 3),
                _buildNavItem(Icons.shopping_bag, 'Products', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index,
      {bool isCenter = false}) {
    final isSelected = _currentIndex == index;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    if (isCenter) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: SizedBox(
          width: isTablet ? 56 : 52,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              gradient: isSelected
                  ? SciFiTheme.accentGradient
                  : SciFiTheme.cardGradient,
              shape: BoxShape.circle,
              border: Border.all(
                color: SciFiTheme.accentCyan,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: SciFiTheme.accentCyan.withValues(alpha: 0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: SciFiTheme.textPrimary,
              size: isTablet ? 28 : 26,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: isSelected ? SciFiTheme.accentGradient : null,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : Border.all(
                  color: SciFiTheme.accentCyan.withValues(alpha: 0.3),
                  width: 1,
                ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? SciFiTheme.textPrimary
                  : SciFiTheme.textSecondary,
              size: isTablet ? 22 : 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? SciFiTheme.textPrimary
                    : SciFiTheme.textSecondary,
                fontSize: isTablet ? 11 : 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
