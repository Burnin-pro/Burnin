import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/menu_item.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/veg_dot.dart';

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
  File? _pickedImage;
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
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      String? imageUrl = _existingImageUrl;

      if (_pickedImage != null) {
        setState(() => _isUploading = true);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${_nameController.text.replaceAll(' ', '_')}.jpg';
        imageUrl = await FirebaseService.instance
            .uploadMenuImage(_pickedImage!, fileName);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingItem == null
                  ? '${item.name} added to menu!'
                  : '${item.name} updated!',
            ),
          ),
        );
        Navigator.of(context).pop();
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
    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        title: Text(widget.existingItem == null ? 'ADD ITEM' : 'EDIT ITEM'),
        leading: BackButton(color: AppColors.amber),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Image picker ─────────────────────────────────────────
              GestureDetector(
                onTap: () => _showImageSourceDialog(),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.dividerDark, width: 0.5),
                  ),
                  child: _isUploading
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                  color: AppColors.amber),
                              SizedBox(height: 12),
                              Text('Uploading...',
                                  style:
                                      TextStyle(color: AppColors.textSecondaryDark)),
                            ],
                          ),
                        )
                      : _pickedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(_pickedImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity),
                            )
                          : _existingImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(_existingImageUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_photo_alternate_outlined,
                                        size: 48,
                                        color: AppColors.textSecondaryDark),
                                    const SizedBox(height: 8),
                                    Text('Tap to add photo',
                                        style: AppTextStyles.bodySmall.copyWith(
                                            color:
                                                AppColors.textSecondaryDark)),
                                  ],
                                ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Item name ────────────────────────────────────────────
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Price ────────────────────────────────────────────────
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Price (₹)',
                  prefixText: '₹ ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter price';
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Category ─────────────────────────────────────────────
              Text('CATEGORY',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textSecondaryDark)),
              const SizedBox(height: 10),
              Row(
                children: ['Food', 'Drinks'].map((cat) {
                  final selected = _category == cat;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: cat == 'Food' ? 8 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.maroon
                                : AppColors.cardDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? AppColors.amber
                                  : AppColors.dividerDark,
                            ),
                          ),
                          child: Center(
                            child: Text(cat.toUpperCase(),
                                style: AppTextStyles.pill.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textSecondaryDark,
                                )),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Veg / Non-Veg ────────────────────────────────────────
              Text('TYPE',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textSecondaryDark)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TypeToggle(
                      label: 'VEG',
                      isVeg: true,
                      selected: _isVeg,
                      onTap: () => setState(() => _isVeg = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TypeToggle(
                      label: 'NON-VEG',
                      isVeg: false,
                      selected: !_isVeg,
                      onTap: () => setState(() => _isVeg = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Availability ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.dividerDark, width: 0.5),
                ),
                child: Row(
                  children: [
                    Text('Available for Order',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: Colors.white)),
                    const Spacer(),
                    Switch(
                      value: _isAvailable,
                      onChanged: (v) => setState(() => _isAvailable = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Done button ──────────────────────────────────────────
              PrimaryButton(
                label: widget.existingItem == null ? 'ADD TO MENU' : 'SAVE CHANGES',
                isLoading: _isSaving,
                onPressed: _save,
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                color: AppColors.dividerDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.amber),
              title: const Text('Take a photo',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.amber),
              title: const Text('Choose from gallery',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
          color: selected ? color.withValues(alpha: 0.15) : AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.dividerDark,
            width: selected ? 1.5 : 0.5,
          ),
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
