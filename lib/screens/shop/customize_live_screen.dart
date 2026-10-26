import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product.dart';
import '../../services/shop_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'cart_screen.dart';

const _themes = ['black-gold', 'midnight-blue', 'classic-white'];
const _fonts = ['Poppins', 'Inter', 'Playfair Display', 'Roboto Mono'];

class _LiveText {
  String text = '';
  String font = 'Poppins';
  double size = 20;
  String color = '#A67C52';
}

/// Simplified first pass per the confirmed scope cut: theme + text-list
/// management (add/edit/remove up to 10 texts, font/size/color/content)
/// without freeform drag positioning — that's a fast-follow enhancement.
class CustomizeLiveScreen extends StatefulWidget {
  final Product product;
  const CustomizeLiveScreen({super.key, required this.product});

  @override
  State<CustomizeLiveScreen> createState() => _CustomizeLiveScreenState();
}

class _CustomizeLiveScreenState extends State<CustomizeLiveScreen> {
  String _theme = _themes.first;
  final List<_LiveText> _texts = [];
  File? _logo;
  bool _submitting = false;

  void _addText() {
    if (_texts.length >= 10) return;
    setState(() => _texts.add(_LiveText()));
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (picked != null) setState(() => _logo = File(picked.path));
  }

  Future<void> _submit() async {
    final nonEmpty = _texts.where((t) => t.text.trim().isNotEmpty).toList();
    setState(() => _submitting = true);
    final ok = await ShopService.instance.addLiveCustomization(
      productId: widget.product.productId,
      theme: _theme,
      texts: nonEmpty
          .map((t) => {'text': t.text.trim(), 'font': t.font, 'size': t.size.round(), 'color': t.color})
          .toList(),
      logo: _logo,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CartScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not add to cart.'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.product.price + ShopService.liveEditorCharge;
    return Scaffold(
      appBar: AppBar(title: const Text('Live Studio Editor')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeading('Theme'),
          Wrap(
            spacing: 10,
            children: _themes.map((t) {
              final selected = t == _theme;
              return ChoiceChip(
                label: Text(t),
                selected: selected,
                onSelected: (_) => setState(() => _theme = t),
                selectedColor: AppColors.primaryLight,
                labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeading('Text Elements'),
              TextButton.icon(
                onPressed: _texts.length >= 10 ? null : _addText,
                icon: const Icon(Icons.add),
                label: const Text('Add Text'),
              ),
            ],
          ),
          if (_texts.isEmpty)
            const EmptyState(icon: Icons.text_fields, message: 'Add up to 10 text elements to your card.')
          else
            ..._texts.asMap().entries.map((entry) => _TextEditorCard(
                  liveText: entry.value,
                  onChanged: () => setState(() {}),
                  onRemove: () => setState(() => _texts.removeAt(entry.key)),
                )),
          const SizedBox(height: 20),
          const SectionHeading('Logo (optional)'),
          InkWell(
            onTap: _pickLogo,
            child: Container(
              height: 100,
              decoration: BoxDecoration(border: Border.all(color: AppColors.inputBorder), borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: _logo != null
                  ? Image.file(_logo!, fit: BoxFit.cover, width: double.infinity)
                  : const Center(child: Icon(Icons.add_photo_alternate_outlined, color: AppColors.placeholder)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('RM ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }
}

class _TextEditorCard extends StatelessWidget {
  final _LiveText liveText;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _TextEditorCard({required this.liveText, required this.onChanged, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'Text (max 60 chars)'),
                    maxLength: 60,
                    onChanged: (v) {
                      liveText.text = v;
                      onChanged();
                    },
                  ),
                ),
                IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline, color: AppColors.error)),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: liveText.font,
                    items: _fonts.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) {
                      liveText.font = v ?? liveText.font;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Size'),
                    controller: TextEditingController(text: liveText.size.round().toString()),
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      if (parsed != null) liveText.size = parsed.clamp(10, 48);
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
