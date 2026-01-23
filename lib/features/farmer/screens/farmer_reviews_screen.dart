import 'package:flutter/material.dart';
import '../../../core/services/review_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/star_rating_display.dart';
import '../../../shared/widgets/review_widgets.dart';
import '../../../shared/widgets/error_widgets.dart';

class FarmerReviewsScreen extends StatefulWidget {
  const FarmerReviewsScreen({super.key});

  @override
  State<FarmerReviewsScreen> createState() => _FarmerReviewsScreenState();
}

class _FarmerReviewsScreenState extends State<FarmerReviewsScreen>
    with SingleTickerProviderStateMixin {
  final ReviewService _reviewService = ReviewService();
  final AuthService _authService = AuthService();

  late TabController _tabController;
  
  List<SellerReviewModel> _allReviews = [];
  ReviewSummary? _reviewSummary;
  bool _isLoading = true;
  String _error = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final reviews = await _reviewService.getSellerReviews(currentUser.id);
      final summary = await _reviewService.getReviewSummary(currentUser.id);

      setState(() {
        _allReviews = reviews;
        _reviewSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<SellerReviewModel> get _filteredReviews {
    switch (_selectedFilter) {
      case 'positive':
        return _allReviews.where((r) => r.rating >= 4).toList();
      case 'negative':
        return _allReviews.where((r) => r.rating <= 3).toList();
      case 'recent':
        return _allReviews.take(10).toList();
      default:
        return _allReviews;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Reviews'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.analytics, size: 18)),
            Tab(text: 'All Reviews', icon: Icon(Icons.reviews, size: 18)),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? ErrorMessage(
                  message: _error,
                  onRetry: _loadReviews,
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildReviewsTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Stats
          if (_reviewSummary != null) ...[
            ReviewSummaryWidget(summary: _reviewSummary!),
            const SizedBox(height: 24),
          ],

          // Review Analytics
          _buildAnalyticsCards(),

          const SizedBox(height: 24),

          // Recent Reviews Preview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Reviews',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _tabController.animateTo(1);
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _allReviews.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.reviews_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No reviews yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Keep providing great service to earn your first review!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ReviewsList(
                          reviews: _allReviews.take(3).toList(),
                          showEmpty: false,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCards() {
    final totalReviews = _reviewSummary?.totalReviews ?? 0;
    final avgRating = _reviewSummary?.averageRating ?? 0.0;
    final positiveReviews = _allReviews.where((r) => r.rating >= 4).length;
    final verifiedReviews = _allReviews.where((r) => r.isVerifiedPurchase).length;

    return Row(
      children: [
        Expanded(
          child: _buildAnalyticsCard(
            'Total Reviews',
            totalReviews.toString(),
            Icons.reviews,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAnalyticsCard(
            'Average Rating',
            avgRating.toStringAsFixed(1),
            Icons.star,
            Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAnalyticsCard(
            'Positive',
            totalReviews > 0 ? '${((positiveReviews / totalReviews) * 100).round()}%' : '0%',
            Icons.thumb_up,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAnalyticsCard(
            'Verified',
            totalReviews > 0 ? '${((verifiedReviews / totalReviews) * 100).round()}%' : '0%',
            Icons.verified,
            AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              const Text(
                'Filter:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All (${_allReviews.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip('positive', 'Positive (${_allReviews.where((r) => r.rating >= 4).length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip('negative', 'Critical (${_allReviews.where((r) => r.rating <= 3).length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip('recent', 'Recent'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Reviews List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadReviews,
            child: _filteredReviews.isEmpty
                ? ListView(
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height * 0.5,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedFilter == 'all' ? Icons.reviews_outlined : Icons.filter_list_off,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFilter == 'all' 
                                  ? 'No reviews yet'
                                  : 'No reviews match this filter',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredReviews.length,
                    itemBuilder: (context, index) {
                      final review = _filteredReviews[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ReviewCard(review: review),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}