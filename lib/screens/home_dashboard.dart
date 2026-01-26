import 'package:flutter/material.dart';
import '../services/dummy_data_service.dart';
import '../theme/instagram_theme.dart';
import '../widgets/clay_container.dart';
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
    setState(() => _isLoading = true);
    await _dataService.fetchAds();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(InstagramTheme.primaryPink),
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
      bottomNavigationBar: _buildClayNavigationBar(),
    );
  }

  Widget _buildClayNavigationBar() {
    return Container(
      color: InstagramTheme.backgroundWhite, // Match scaffold
      padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16, top: 10),
      child: ClayContainer(
        height: 70,
        borderRadius: 35,
        color: InstagramTheme.surfaceWhite,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home_rounded, 0),
            _buildNavItem(Icons.campaign_rounded, 1),
            _buildCenterNavItem(),
            _buildNavItem(Icons.video_library_rounded, 3),
            _buildNavItem(Icons.shopping_bag_rounded, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: isSelected
            ? InstagramTheme.cardDecoration(
                color: InstagramTheme.backgroundGrey,
                borderRadius: 20,
                hasBorder: false,
              )
            : null,
        child: Icon(
          icon,
          color: isSelected ? InstagramTheme.primaryPink : InstagramTheme.textGrey,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildCenterNavItem() {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: ClayContainer(
        width: 50,
        height: 50,
        borderRadius: 25,
        child: Container(
          decoration: InstagramTheme.gradientDecoration(
            borderRadius: 25,
          ),
          child: const Center(
            child: Icon(
              Icons.add,
              color: InstagramTheme.textBlack,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}
