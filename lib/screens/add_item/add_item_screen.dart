import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/menu_item.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/veg_dot.dart';
import '../main/main_screen.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  /// Pass an existing item to edit, null to create new.
  final MenuItem? existingItem;

  const AddItemScreen({super.key, this.existingItem});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  String _category = 'Food';
  bool _isVeg = true;
  bool _isAvailable = true;
  Uint8List? _imageBytes;
  bool _isUploading = false;
  bool _isSaving = false;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item != null) {
      _nameController.text = item.name;
      _priceController.text = item.price.toStringAsFixed(0);
      _category = item.category;
      _isVeg = item.isVeg;
      _isAvailable = item.isAvailable;
      _existingImageUrl = item.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: source, maxWidth: 800, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      String? imageUrl = _existingImageUrl;

      if (_imageBytes != null) {
        setState(() => _isUploading = true);
        
        // Convert the image to a base64 string and save it directly in Firestore
        final base64String = base64Encode(_imageBytes!);
        imageUrl = 'data:image/jpeg;base64,$base64String';
        
        setState(() => _isUploading = false);
      }

      final item = MenuItem(
        id: widget.existingItem?.id ?? '',
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        category: _category,
        isVeg: _isVeg,
        isAvailable: _isAvailable,
        imageUrl: imageUrl,
      );

      await FirebaseService.instance.saveMenuItem(item);

      if (mounted) {
        // Clear fields
        if (widget.existingItem == null) {
          _nameController.clear();
          _priceController.clear();
          setState(() {
            _imageBytes = null;
            _existingImageUrl = null;
            _category = 'Food';
            _isVeg = true;
            _isAvailable = true;
          });
        }

        // Switch to menu tab and show success popup
        final state = context.findAncestorStateOfType<State<MainScreen>>();
        if (state is MainScreenState) {
          (state as MainScreenState).switchToMenuAndShowSuccess(item.name);
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Gradient App Bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: AppColors.maroon,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.maroon, AppColors.maroonLight, AppColors.orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: Text(
                isEditing ? 'EDIT ITEM' : 'ADD NEW ITEM',
                style: AppTextStyles.headlineSmall
                    .copyWith(color: Colors.white, fontSize: 18),
              ),
              centerTitle: true,
            ),
          ),

          // ── Form Body ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Image picker ─────────────────────────────────────
                    GestureDetector(
                      onTap: () => _showImageSourceDialog(),
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.outline, width: 0.5),
                        ),
                        child: _isUploading
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(
                                        color: AppColors.amber),
                                    const SizedBox(height: 12),
                                    Text('Uploading...',
                                        style: AppTextStyles.bodySmall.copyWith(
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                                  ],
                                ),
                              )
                            : _imageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.memory(_imageBytes!,
                                        width: double.infinity, fit: BoxFit.cover),
                                  )
                                : _existingImageUrl != null
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(18),
                                        child: Image.network(
                                            _existingImageUrl!,
                                            fit: BoxFit.cover,
                                            width: double.infinity),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: AppColors.maroon
                                                  .withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                                Icons
                                                    .add_photo_alternate_outlined,
                                                size: 36,
                                                color: AppColors.amber),
                                          ),
                                          const SizedBox(height: 12),
                                          Text('Tap to add photo',
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                                        ],
                                      ),
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 24),

                    // ── Item name ────────────────────────────────────────
                    _SectionLabel(label: 'ITEM NAME'),
                    const SizedBox(height: 8),
                    _StyledField(
                      controller: _nameController,
                      hint: 'e.g. Chicken Burger',
                      icon: Icons.restaurant_menu_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter item name';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 20),

                    // ── Price ────────────────────────────────────────────
                    _SectionLabel(label: 'PRICE'),
                    const SizedBox(height: 8),
                    _StyledField(
                      controller: _priceController,
                      hint: 'e.g. 150',
                      icon: Icons.currency_rupee_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter price';
                        if (double.tryParse(v.trim()) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 24),

                    // ── Category ─────────────────────────────────────────
                    _SectionLabel(label: 'CATEGORY'),
                    const SizedBox(height: 10),
                    Row(
                      children: ['Food', 'Drinks'].map((cat) {
                        final selected = _category == cat;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: cat == 'Food' ? 8 : 0),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _category = cat),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 250),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: selected
                                      ? AppColors.flameGradientHorizontal
                                      : null,
                                  color: selected
                                      ? null
                                      : Theme.of(context).cardColor,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: selected
                                      ? null
                                      : Border.all(
                                          color: Theme.of(context).colorScheme.outline),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.maroon
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset:
                                                const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        cat == 'Food'
                                            ? Icons.fastfood_rounded
                                            : Icons
                                                .local_drink_rounded,
                                        color: selected
                                            ? Colors.white
                                            : Theme.of(context).colorScheme.onSurfaceVariant,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                          cat.toUpperCase(),
                                          style: AppTextStyles.pill
                                              .copyWith(
                                            color: selected
                                                ? Colors.white
                                                : Theme.of(context).colorScheme.onSurfaceVariant,
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 24),

                    // ── Veg / Non-Veg ────────────────────────────────────
                    _SectionLabel(label: 'TYPE'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeToggle(
                            label: 'VEG',
                            isVeg: true,
                            selected: _isVeg,
                            onTap: () =>
                                setState(() => _isVeg = true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TypeToggle(
                            label: 'NON-VEG',
                            isVeg: false,
                            selected: !_isVeg,
                            onTap: () =>
                                setState(() => _isVeg = false),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 250.ms),
                    const SizedBox(height: 24),

                    // ── Availability ─────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Theme.of(context).colorScheme.outline, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (_isAvailable
                                      ? AppColors.vegGreen
                                      : AppColors.nonVegRed)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _isAvailable
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined,
                              color: _isAvailable
                                  ? AppColors.vegGreen
                                  : AppColors.nonVegRed,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('Available for Order',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: Theme.of(context).colorScheme.onSurface)),
                          const Spacer(),
                          Switch(
                            value: _isAvailable,
                            activeColor: AppColors.vegGreen,
                            onChanged: (v) =>
                                setState(() => _isAvailable = v),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 36),

                    // ── Done button ──────────────────────────────────────
                    PrimaryButton(
                      label: isEditing ? 'SAVE CHANGES' : 'ADD TO MENU',
                      isLoading: _isSaving,
                      onPressed: _save,
                      icon: isEditing
                          ? Icons.save_outlined
                          : Icons.add_circle_outline_rounded,
                    ).animate().fadeIn(delay: 350.ms).scale(
                        begin: const Offset(0.95, 0.95),
                        curve: Curves.easeOutBack),
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    if (_isSaving || _isUploading) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Select Image',
                style: AppTextStyles.headlineSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface, letterSpacing: 1)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.maroon.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.amber),
              ),
              title: Text('Take a photo',
                  style:
                      AppTextStyles.bodyLarge.copyWith(color: Theme.of(context).colorScheme.onSurface)),
              subtitle: Text('Use your camera',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.maroon.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: AppColors.amber),
              ),
              title: Text('Choose from gallery',
                  style:
                      AppTextStyles.bodyLarge.copyWith(color: Theme.of(context).colorScheme.onSurface)),
              subtitle: Text('Pick an existing image',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Styled field ────────────────────────────────────────────────────────────
class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 0.5),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: AppTextStyles.bodyLarge.copyWith(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyMedium
              .copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          prefixIcon: Icon(icon, color: AppColors.amber, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        validator: validator,
      ),
    );
  }
}

// ── Section label ───────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.amber,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: AppTextStyles.labelSmall.copyWith(
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, letterSpacing: 1.5)),
      ],
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String label;
  final bool isVeg;
  final bool selected;
  final VoidCallback onTap;

  const _TypeToggle({
    required this.label,
    required this.isVeg,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? AppColors.vegGreen : AppColors.nonVegRed;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:
              selected ? color.withValues(alpha: 0.15) : AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.dividerDark,
            width: selected ? 1.5 : 0.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VegDot(isVeg: isVeg, size: 13),
            const SizedBox(width: 8),
            Text(label,
                style: AppTextStyles.pill.copyWith(
                  color: selected ? color : AppColors.textSecondaryDark,
                )),
          ],
        ),
      ),
    );
  }
}
