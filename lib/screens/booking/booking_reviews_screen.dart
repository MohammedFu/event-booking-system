import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/services/api_service_real.dart';

class BookingReviewsScreen extends StatefulWidget {
  final String serviceId;
  final String serviceTitle;

  const BookingReviewsScreen({
    super.key,
    required this.serviceId,
    required this.serviceTitle,
  });

  @override
  State<BookingReviewsScreen> createState() => _BookingReviewsScreenState();
}

class _BookingReviewsScreenState extends State<BookingReviewsScreen> {
  final ApiServiceReal _api = ApiServiceReal();
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  double _averageRating = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final response = await _api.getServiceReviews(widget.serviceId);
    if (response.success && response.data != null) {
      setState(() {
        _reviews = response.data!;
        _averageRating = _reviews.isEmpty
            ? 0
            : _reviews.fold(0.0, (sum, r) => sum + r.rating) / _reviews.length;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildRatingSummary()),
                const SliverToBoxAdapter(child: Divider(height: 1)),
                SliverPadding(
                  padding: const EdgeInsets.all(defaultPadding),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ReviewCard(review: _reviews[index]),
                      childCount: _reviews.length,
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: ElevatedButton(
            onPressed: () => _showWriteReviewDialog(context),
            child: Text(l10n.writeAReview),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSummary() {
    final ratingCounts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in _reviews) {
      ratingCounts[r.rating] = (ratingCounts[r.rating] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                _averageRating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < _averageRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          size: 16,
                          color: Colors.amber,
                        )),
              ),
              const SizedBox(height: 4),
              Text(context.tr('reviews_count_compact',
                      params: {'count': _reviews.length.toString()}),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(width: defaultPadding * 2),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((rating) {
                final count = ratingCounts[rating] ?? 0;
                final pct = _reviews.isEmpty ? 0.0 : count / _reviews.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$rating',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 4),
                      Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: Theme.of(context).dividerColor,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.amber),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 24,
                        child: Text('$count',
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showWriteReviewDialog(BuildContext context) {
    int selectedRating = 0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context).writeAReview),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    5,
                    (i) => IconButton(
                          onPressed: () =>
                              setDialogState(() => selectedRating = i + 1),
                          icon: Icon(
                            i < selectedRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                        )),
              ),
              const SizedBox(height: defaultPadding),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).shareYourExperience,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            ElevatedButton(
              onPressed: selectedRating == 0
                  ? null
                  : () async {
                      final response = await _api.submitReview(
                        bookingItemId: 'item-latest',
                        providerId: widget.serviceId,
                        rating: selectedRating,
                        comment: commentController.text.trim(),
                      );
                      if (response.success && response.data != null) {
                        setState(() {
                          _reviews.insert(0, response.data!);
                          _averageRating =
                              _reviews.fold(0.0, (sum, r) => sum + r.rating) /
                                  _reviews.length;
                        });
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
              child: Text(AppLocalizations.of(context).submit),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Text(
                    review.isAnonymous
                        ? '?'
                        : review.consumerId.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: primaryColor),
                  ),
                ),
                const SizedBox(width: defaultPadding / 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.isAnonymous
                            ? AppLocalizations.of(context).translate('anonymous')
                            : review.consumerId,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${review.createdAt.month}/${review.createdAt.day}/${review.createdAt.year}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                      5,
                      (i) => Icon(
                            i < review.rating ? Icons.star : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          )),
                ),
              ],
            ),
            if (review.comment != null) ...[
              const SizedBox(height: defaultPadding / 2),
              Text(review.comment!),
            ],
          ],
        ),
      ),
    );
  }
}
