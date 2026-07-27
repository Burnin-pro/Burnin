import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/menu_item.dart';
import '../../models/shop_status.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/network_provider.dart';
import '../../services/firebase_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/veg_dot.dart';

/// Riverpod provider for the real-time menu item stream.
final menuItemsProvider = StreamProvider.autoDispose<List<MenuItem>>((ref) {
  return FirebaseService.instance.menuItemsStream();
});

/// Selected category filter ('All' | 'Food' | 'Drinks').
final categoryFilterProvider = StateProvider.autoDispose<String>((ref) => 'All');

/// Search query provider.
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Shop open/closed status today.
final shopStatusTodayProvider = StreamProvider.autoDispose<bool>((ref) {
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
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomePopup();
    });
  }

  void _showWelcomePopup() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Welcome',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => const _WelcomePopup(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Transform.scale(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack).value,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleShopStatus(bool current) async {
    final dateKey = FirebaseService.instance.todayKey();
    await FirebaseService.instance
        .setShopStatus(dateKey: dateKey, isOpen: !current);

    if (current) {
      // Shop is closing. Calculate income and show local notification.
      try {
        final orders = await FirebaseService.instance.ordersStreamForDate(dateKey).first;
        final totalIncome = orders.fold(0.0, (sum, o) => sum + o.total);
        await LocalNotificationService.instance.showShopClosedNotification(totalIncome);
      } catch (e) {
        debugPrint('Failed to calculate income for notification: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuItemsProvider);
    final category = ref.watch(categoryFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final cart = ref.watch(cartProvider);
    final shopAsync = ref.watch(shopStatusTodayProvider);
    final isOffline = ref.watch(isOfflineProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final mainNavBarHeight = bottomSafeArea + 70 + 16;
    
    // When cart has items, add enough padding to scroll past the View Cart button (which is roughly 60px tall)
    final gridBottomPadding = cart.totalItemCount > 0 
        ? mainNavBarHeight + 4 + 80.0 
        : mainNavBarHeight + 20.0;

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Premium Header with Logo ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 240,
                    child: CustomPaint(
                      painter: _PopupWavyPainter(color: Theme.of(context).scaffoldBackgroundColor),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left: Logo in white space
                              const AppLogo(size: 120, showTagline: false),
                              
                              const Spacer(),
                              
                              // Notifications Icon
                              GestureDetector(
                                onTap: () => Navigator.of(context).pushNamed('/notifications'),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? Colors.white24 : Colors.black12,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.notifications_none_rounded,
                                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                    size: 20,
                                  ),
                                ),
                              ),
                              
                              // Right: Shop Open/Close toggle
                              shopAsync.when(
                                data: (isOpen) => GestureDetector(
                                  onTap: () => _toggleShopStatus(isOpen),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isOpen
                                          ? AppColors.vegGreen.withValues(alpha: 0.1)
                                          : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isOpen
                                            ? AppColors.vegGreen
                                            : (isDark ? Colors.white70 : Colors.black38),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: isOpen
                                                ? AppColors.vegGreen
                                                : AppColors.nonVegRed,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isOpen ? 'OPEN' : 'CLOSED',
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: isOpen ? AppColors.vegGreen : (isDark ? Colors.white : AppColors.textPrimaryLight),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 54),

                      // Search Bar
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white24 : Colors.black26, width: 1.2),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: AppTextStyles.bodyMedium.copyWith(color: isDark ? Colors.white : AppColors.textPrimaryLight),
                          onChanged: (v) =>
                              ref.read(searchQueryProvider.notifier).state = v,
                          decoration: InputDecoration(
                            hintText: 'Search menu...',
                            hintStyle: AppTextStyles.bodyMedium.copyWith(color: isDark ? Colors.white54 : AppColors.textSecondaryLight),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: isDark ? Colors.white70 : AppColors.textSecondaryLight, size: 22),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.close,
                                        color: isDark ? Colors.white70 : AppColors.textSecondaryLight, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref.read(searchQueryProvider.notifier).state = '';
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Offline Banner ──────────────────────────────────────────────
          if (isOffline)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: AppColors.amber, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Offline Mode: Orders will sync automatically',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Category Pills ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: ['All', 'Food', 'Drinks'].map((cat) {
                    final selected = category == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => ref
                            .read(categoryFilterProvider.notifier)
                            .state = cat,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.maroon
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.maroon
                                  : Theme.of(context).colorScheme.outline,
                              width: 0.5,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: AppColors.maroon.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            cat.toUpperCase(),
                            style: AppTextStyles.pill.copyWith(
                              color: selected
                                  ? Colors.white
                                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // ── Menu Grid ───────────────────────────────────────────────────
          menuAsync.when(
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
                return SliverFillRemaining(
                  child: Center(
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
                  ),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, gridBottomPadding),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _MenuItemCard(item: filtered[index])
                          .animate()
                          .fadeIn(delay: (50 * index).ms, duration: 400.ms)
                          .slideY(begin: 0.05, end: 0);
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.amber),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 48, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    const SizedBox(height: 12),
                    Text('Could not load menu',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    const SizedBox(height: 8),
                    Text('Check your connection',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Sticky cart bar ─────────────────────────────────────────────────
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

// ── Header icon button ────────────────────────────────────────────────────────
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.orange, size: 24),
      ),
    );
  }
}

// ── Menu item card ──────────────────────────────────────────────────────────
class _MenuItemCard extends ConsumerWidget {
  final MenuItem item;
  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qty = ref.watch(
        cartProvider.select((s) => s.quantityOf(item.id)));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: qty > 0 ? AppColors.amber.withValues(alpha: 0.5) : Theme.of(context).colorScheme.outline,
          width: qty > 0 ? 1.5 : 0.5,
        ),
        boxShadow: qty > 0
            ? [
                BoxShadow(
                  color: AppColors.amber.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: item.imageUrl != null
                      ? (item.imageUrl!.startsWith('data:image')
                          ? Image.memory(
                              base64Decode(item.imageUrl!.split(',').last),
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : CachedNetworkImage(
                              imageUrl: item.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _PlaceholderImage(),
                            ))
                      : _PlaceholderImage(),
                ),
                // Veg/NonVeg badge top-left
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: VegDot(isVeg: item.isVeg, size: 14),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Expanded(
            flex: 4,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.price.toStringAsFixed(0)}',
                    style: AppTextStyles.price.copyWith(fontSize: 16),
                  ),
                  const Spacer(),
                  QuantityStepper(
                    value: qty,
                    onIncrement: () =>
                        ref.read(cartProvider.notifier).addItem(item),
                    onDecrement: () =>
                        ref.read(cartProvider.notifier).removeItem(item),
                  ),
                ],
              ),
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
      width: double.infinity,
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
    // Scaffold's bottomNavigationBar natively pads by the bottom safe area.
    // The MainScreen's bottom nav is 70px tall + 16px bottom padding = 86px tall.
    // Since Scaffold already pushes this up by bottomSafeArea, we only need to add 86 + 3px.
    const double bottomMargin = 86.0 + 3.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
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
            Text('VIEW CART',
                style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
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

// ── Animated Fire Beam Ring ──────────────────────────────────────────────────
class _FireBeamRing extends StatefulWidget {
  final double size;
  final Widget child;

  const _FireBeamRing({required this.size, required this.child});

  @override
  State<_FireBeamRing> createState() => _FireBeamRingState();
}

class _FireBeamRingState extends State<_FireBeamRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size + 8,
          height: widget.size + 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: const [
                AppColors.maroonDark,
                AppColors.amber,
                AppColors.amberLight,
                Colors.white,
                AppColors.orange,
                AppColors.maroon,
                AppColors.maroonDark,
              ],
              stops: const [0.0, 0.15, 0.3, 0.5, 0.7, 0.85, 1.0],
              transform: GradientRotation(_controller.value * 2 * math.pi),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.amber.withValues(alpha: 0.3),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.all(4), // Border width
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}

// ── Welcome Popup ───────────────────────────────────────────────────────────
class _WelcomePopup extends StatefulWidget {
  const _WelcomePopup();

  @override
  State<_WelcomePopup> createState() => _WelcomePopupState();
}

class _WelcomePopupState extends State<_WelcomePopup> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 340,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.maroon.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Wavy top (White)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 250,
                child: CustomPaint(
                  painter: _PopupWavyPainter(color: Theme.of(context).scaffoldBackgroundColor),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    const AppLogo(size: 140, showTagline: false)
                        .animate().scale(
                          begin: const Offset(0.5, 0.5),
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        ),
                    const SizedBox(height: 36),

                    Text(
                      'Welcome to Billing!',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        letterSpacing: 1.5,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 12),

                    Text(
                      'Ready to take some orders?',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontSize: 16,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 36),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                          foregroundColor: AppColors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          'CLOSE',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.orange,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms).scale(curve: Curves.easeOutBack),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Wavy Painter for Popup ──────────────────────────────────────────────────
class _PopupWavyPainter extends CustomPainter {
  final Color color;
  _PopupWavyPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.lineTo(0, size.height * 0.6);
    path.quadraticBezierTo(
        size.width * 0.25, size.height * 0.9,
        size.width * 0.5, size.height * 0.6);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.3,
        size.width, size.height * 0.8);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PopupWavyPainter oldDelegate) =>
      oldDelegate.color != color;
}
