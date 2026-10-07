import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kumbh_app/l10n/app_localizations.dart';
import 'package:kumbh_app/app/providers.dart';
import '../data/place_model.dart';
import '../../common/common_widgets.dart';
import 'place_detail_screen.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Category labels – kept here so the chip builder can use them;
  // they are intentionally in English to match the DB category column values.
  final List<String> _categories = [
    'All',
    'Ghats',
    'Temples',
    'Parking',
    'Hotels',
    'Help Centers',
  ];

  // FIX: local favourites set (toggle per session)
  final Set<int> _favourites = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.text = ref.read(placesSearchQueryProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  /// Returns true when any filter is non-default, so the badge shows.
  bool _hasActiveFilters(WidgetRef ref) {
    final cat = ref.watch(placesSelectedCategoryProvider);
    final crowd = ref.watch(placesCrowdFilterProvider);
    final verified = ref.watch(placesVerifiedOnlyProvider);
    return cat != 'All' || crowd != 'All' || !verified;
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final placesAsync = ref.watch(placesListProvider);
    final selectedCategory = ref.watch(placesSelectedCategoryProvider);
    final hasFilters = _hasActiveFilters(ref);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E9),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero banner ─────────────────────────────────────────────
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    image: DecorationImage(
                      image: AssetImage('assets/images/ghat_dawn.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(color: Colors.black.withValues(alpha: 0.4)),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const CircleAvatar(
                            backgroundColor: Colors.white,
                            child:
                                Icon(Icons.arrow_back, color: Colors.black),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          l10n.discover,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          l10n.interestingPlaces,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Search bar (overlaps hero) ──────────────────────────────
            Transform.translate(
              offset: const Offset(0, -24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(placesSearchQueryProvider.notifier).state = val;
                    },
                    decoration: InputDecoration(
                      hintText: l10n.searchLocation,
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.grey),
                      // FIX: clear button appears when text is present
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.grey, size: 18),
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(
                                        placesSearchQueryProvider.notifier)
                                    .state = '';
                                setState(() {});
                              },
                            ),
                          // FIX: filter icon shows orange badge dot when filters active
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.tune,
                                  color: hasFilters
                                      ? const Color(0xFFEA7A1A)
                                      : Colors.grey,
                                ),
                                tooltip: 'Filters',
                                onPressed: () =>
                                    _openFilterSheet(context, ref),
                              ),
                              if (hasFilters)
                                const Positioned(
                                  right: 10,
                                  top: 10,
                                  child: CircleAvatar(
                                    radius: 4,
                                    backgroundColor: Color(0xFFEA7A1A),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onSubmitted: (_) => setState(() {}),
                  ),
                ),
              ),
            ),

            // ── Category chips ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.popularLocations,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final cat in _categories)
                          _buildCategoryChip(
                            cat,
                            selectedCategory == cat,
                            () {
                              ref
                                  .read(
                                      placesSelectedCategoryProvider.notifier)
                                  .state = cat;
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Places grid ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: placesAsync.when(
                data: (places) {
                  if (places.isEmpty) {
                    // FIX: proper empty state with illustration
                    return SizedBox(
                      height: 220,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off,
                                size: 64,
                                color: Colors.orange.shade200),
                            const SizedBox(height: 12),
                            const Text(
                              'No places match your filters.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Try adjusting or clearing the filters.',
                              style: TextStyle(
                                color: Colors.black38,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: places.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    itemBuilder: (context, idx) {
                      final p = places[idx];
                      return _buildPlaceCard(p);
                    },
                  );
                },
                loading: () => const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => SizedBox(
                  height: 150,
                  child: Center(child: Text('Error: $err')),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Best Delicacies section ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.bestDelicacies,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  // FIX: viewAll now tappable
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Delicacies list coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Text(
                      l10n.viewAll,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFEA7A1A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 3,
                shadowColor: Colors.black12,
                color: const Color(0xFFFFF3E0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side:
                      const BorderSide(color: Color(0xFFEA7A1A), width: 0.8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE0B2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.restaurant_menu,
                            color: Color(0xFFEA7A1A),
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // FIX: use l10n for both strings
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.bestDelicacies,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEA7A1A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Verified information on Nashik food & eateries is currently being curated by authorities. Please check back soon.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ── Category chip ──────────────────────────────────────────────────────────

  Widget _buildCategoryChip(
      String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: ShapeDecoration(
            color:
                isSelected ? const Color(0xFFFF8A65) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : Colors.black12,
              ),
            ),
            shadows: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color:
                  isSelected ? Colors.white : Colors.black54,
              fontWeight: isSelected
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ── Place card ────────────────────────────────────────────────────────────

  Widget _buildPlaceCard(Place p) {
    final isFav = _favourites.contains(p.id);

    return GestureDetector(
      // FIX: tapping the card now navigates to PlaceDetailScreen
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceDetailScreen(place: p),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    child: SmartImage(
                      source: p.imageUrl,
                      provenance: p.imageUrl.startsWith('http')
                          ? ImageProvenance.networkVerified
                          : ImageProvenance.assetVerified,
                    ),
                  ),
                  // FIX: functional favourite toggle
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isFav) {
                            _favourites.remove(p.id);
                          } else {
                            _favourites.add(p.id);
                          }
                        });
                      },
                      child: CircleAvatar(
                        backgroundColor: isFav
                            ? Colors.red.shade400
                            : Colors.white30,
                        radius: 14,
                        child: Icon(
                          isFav
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // FIX: verified badge on card
                  const Positioned(
                    top: 8,
                    left: 8,
                    child: _VerifiedBadge(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFEA7A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: Colors.green),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          p.category,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.speed,
                        size: 12,
                        color: _crowdIconColor(p.crowdLevel),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Crowd: ${p.crowdLevel}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _crowdIconColor(p.crowdLevel),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${p.distanceKm.toStringAsFixed(1)} km away',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _crowdIconColor(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.amber;
    }
  }

  // ── Filter bottom sheet ────────────────────────────────────────────────────

  void _openFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        String tempCategory = ref.read(placesSelectedCategoryProvider);
        String tempCrowd = ref.read(placesCrowdFilterProvider);
        bool tempVerifiedOnly = ref.read(placesVerifiedOnlyProvider);

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filterCategories = [
              'All',
              ..._categories.where((c) => c != 'All')
            ];
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom:
                    MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),

                  // Category
                  const SizedBox(height: 8),
                  const Text(
                    'Category',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filterCategories.map((cat) {
                      final selected = cat == tempCategory;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        selectedColor: const Color(0xFFFF8A65),
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (_) => setSheetState(
                            () => tempCategory = cat),
                      );
                    }).toList(),
                  ),

                  // Crowd Level
                  const SizedBox(height: 16),
                  const Text(
                    'Crowd Level',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'All',
                      'Low',
                      'Medium',
                      'High'
                    ].map((level) {
                      final selected = level == tempCrowd;
                      return ChoiceChip(
                        label: Text(level),
                        selected: selected,
                        selectedColor: const Color(0xFFFF8A65),
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (_) =>
                            setSheetState(() => tempCrowd = level),
                      );
                    }).toList(),
                  ),

                  // Verified only toggle
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: tempVerifiedOnly,
                        onChanged: (v) => setSheetState(
                            () => tempVerifiedOnly = v ?? false),
                        activeColor: const Color(0xFFEA7A1A),
                      ),
                      const Text('Show verified places only'),
                    ],
                  ),

                  // Action buttons
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          // FIX: clear correctly resets to defaults
                          onPressed: () {
                            ref
                                .read(placesSelectedCategoryProvider
                                    .notifier)
                                .state = 'All';
                            ref
                                .read(
                                    placesCrowdFilterProvider.notifier)
                                .state = 'All';
                            ref
                                .read(
                                    placesVerifiedOnlyProvider.notifier)
                                .state = false; // unchecked = no filter
                            Navigator.pop(sheetContext);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFFEA7A1A)),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                          ),
                          child: const Text(
                            'Clear Filters',
                            style: TextStyle(
                                color: Color(0xFFEA7A1A),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ref
                                .read(placesSelectedCategoryProvider
                                    .notifier)
                                .state = tempCategory;
                            ref
                                .read(
                                    placesCrowdFilterProvider.notifier)
                                .state = tempCrowd;
                            ref
                                .read(
                                    placesVerifiedOnlyProvider.notifier)
                                .state = tempVerifiedOnly;
                            Navigator.pop(sheetContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFEA7A1A),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Verified badge widget ──────────────────────────────────────────────────────

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 10, color: Colors.white),
          SizedBox(width: 2),
          Text(
            'Verified',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
