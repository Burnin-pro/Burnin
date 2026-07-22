import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/menu_item.dart';
import '../../providers/cart_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/veg_dot.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Riverpod provider for the real-time menu item stream.
final menuItemsProvider = StreamProvider<List<MenuItem>>((ref) {
  return FirebaseService.instance.menuItemsStream();
});

/// Selected category filter ('All' | 'Food' | 'Drinks').
final categoryFilterProvider = StateProvider<String>((ref) => 'All');

/// Search query provider.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Shop open/closed status today.
final shopStatusTodayProvider = StreamProvider<bool>((ref) {
  final dateKey = FirebaseService.instance.todayKey();
  return FirebaseService.instance
      .shopStatusStream(dateKey)
      .map((s) => s.isOpen);
});

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleShopStatus(bool current) async {
    final dateKey = FirebaseService.instance.todayKey();
    await FirebaseService.instance
        .setShopStatus(dateKey: dateKey, isOpen: !current);
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuItemsProvider);
    final category = ref.watch(categoryFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final cart = ref.watch(cartProvider);
    final shopAsync = ref.watch(shopStatusTodayProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ───────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const AppLogo(size: 44),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BURNIN',
                            style: AppTextStyles.headlineSmall
                                .copyWith(color: Colors.white, letterSpacing: 2)),
                        Text('HOTFIRE',
                            style: AppTextStyles.tagline
                                .copyWith(fontSize: 10)),
                      ],
                    ),
                  ),
                  // Shop open/close toggle
                  shopAsync.when(
                    data: (isOpen) => GestureDetector(
                      onTap: () => _toggleShopStatus(isOpen),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? AppColors.vegGreen.withValues(alpha: 0.15)
                              : AppColors.nonVegRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isOpen
                                ? AppColors.vegGreen
                                : AppColors.nonVegRed,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: isOpen
                                    ? AppColors.vegGreen
                                    : AppColors.nonVegRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOpen ? 'OPEN' : 'CLOSED',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isOpen
                                    ? AppColors.vegGreen
                                    : AppColors.nonVegRed,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 10),
                  // Add item
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppColors.amber),
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/add-item'),
                  ),
                  // Profile
                  IconButton(
                    icon: const Icon(Icons.person_outline_rounded,
                        color: AppColors.textSecondaryDark),
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/profile'),
                  ),
                ],
              ),
            ),

            // ── Search ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: (v) =>
                    ref.read(searchQueryProvider.notifier).state = v,
                decoration: InputDecoration(
                  hintText: 'Search menu...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textSecondaryDark),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              color: AppColors.textSecondaryDark),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Category Pills ────────────────────────────────────────────
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: ['All', 'Food', 'Drinks'].map((cat) {
                  final selected = category == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => ref
                          .read(categoryFilterProvider.notifier)
                          .state = cat,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.maroon
                              : AppColors.cardDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.amber
                                : AppColors.dividerDark,
                            width: selected ? 1.5 : 0.5,
                          ),
                        ),
                        child: Text(
                          cat.toUpperCase(),
                          style: AppTextStyles.pill.copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondaryDark,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // ── Menu Grid ─────────────────────────────────────────────────
            Expanded(
              child: menuAsync.when(
                data: (items) {
                  final filtered = items.where((item) {
                    final catMatch =
                        category == 'All' || item.category == category;
                    final searchMatch = searchQuery.isEmpty ||
                        item.name
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase());
                    return catMatch && searchMatch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 64,
                              color: AppColors.textSecondaryDark
                                  .withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('No items found',
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondaryDark)),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _MenuItemCard(item: filtered[index]);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.amber),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 48, color: AppColors.textSecondaryDark),
                      const SizedBox(height: 12),
                      Text('Could not load menu',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondaryDark)),
                      const SizedBox(height: 8),
                      Text('Check your connection',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondaryDark)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Sticky cart bar ───────────────────────────────────────────────
      bottomNavigationBar: cart.totalItemCount > 0
          ? _CartBar(
              itemCount: cart.totalItemCount,
              total: cart.totalAmount,
              onTap: () => Navigator.of(context).pushNamed('/cart'),
            )
          : null,
    );
  }
}

// ── Menu item card ──────────────────────────────────────────────────────────
class _MenuItemCard extends ConsumerWidget {
  final MenuItem item;
  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(
        cartProvider.select((s) => s.quantityOf(item.id)));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerDark, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _PlaceholderImage(),
                    )
                  : _PlaceholderImage(),
            ),
          ),
          // Details
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    VegDot(isVeg: item.isVeg),
                    const Spacer(),
                    Text(
                      '₹${item.price.toStringAsFixed(0)}',
                      style: AppTextStyles.price.copyWith(fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.name,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                QuantityStepper(
                  value: qty,
                  onIncrement: () =>
                      ref.read(cartProvider.notifier).addItem(item),
                  onDecrement: () =>
                      ref.read(cartProvider.notifier).removeItem(item),
                  height: 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceDark,
      child: const Center(
        child: Icon(Icons.fastfood_rounded,
            size: 48, color: AppColors.dividerDark),
      ),
    );
  }
}

// ── Sticky cart bottom bar ──────────────────────────────────────────────────
class _CartBar extends StatelessWidget {
  final int itemCount;
  final double total;
  final VoidCallback onTap;

  const _CartBar({
    required this.itemCount,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.flameGradientHorizontal,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.maroon.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$itemCount item${itemCount > 1 ? 's' : ''}',
                style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text('VIEW CART',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
            const Spacer(),
            Text(
              '₹${total.toStringAsFixed(0)}',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
