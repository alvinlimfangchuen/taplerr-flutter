import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product.dart';
import '../../services/shop_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'cart_screen.dart';

class CustomizeUploadScreen extends StatefulWidget {
  final Product product;
  const CustomizeUploadScreen({super.key, required this.product});

  @override
  State<CustomizeUploadScreen> createState() => _CustomizeUploadScreenState();
}

class _CustomizeUploadScreenState extends State<CustomizeUploadScreen> {
  File? _file;
  bool _submitting = false;

  Future<void> _pickFile() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (picked != null) setState(() => _file = File(picked.path));
  }

  Future<void> _submit() async {
    if (_file == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a design file first.')));
      return;
    }
    setState(() => _submitting = true);
    final ok = await ShopService.instance.addUploadCustomization(productId: widget.product.productId, designFile: _file!);
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
    final total = widget.product.price + ShopService.uploadCharge;
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Own Design')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SectionHeading('Design Requirements'),
                Text('• JPEG, PNG, or WebP format', style: TextStyle(fontSize: 13)),
                SizedBox(height: 6),
                Text('• Maximum file size: 10MB', style: TextStyle(fontSize: 13)),
                SizedBox(height: 6),
                Text('• Recommended: high resolution, print-ready', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickFile,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.inputBorder, style: BorderStyle.solid, width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: _file != null
                  ? Image.file(_file!, fit: BoxFit.cover, width: double.infinity)
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 36, color: AppColors.placeholder),
                          SizedBox(height: 8),
                          Text('Tap to choose a design file', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _priceRow('Base Price', widget.product.price),
                _priceRow('Custom Service Charge', ShopService.uploadCharge),
                const Divider(),
                _priceRow('Total', total, bold: true),
              ],
            ),
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

  Widget _priceRow(String label, double value, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text('RM ${value.toStringAsFixed(2)}', style: style)],
      ),
    );
  }
}
