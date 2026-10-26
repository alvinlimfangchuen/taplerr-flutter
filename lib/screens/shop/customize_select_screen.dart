import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'customize_basic_screen.dart';
import 'customize_upload_screen.dart';
import 'customize_live_screen.dart';

class CustomizeSelectScreen extends StatelessWidget {
  final Product product;
  const CustomizeSelectScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('RM ${product.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 16),
          _OptionCard(
            icon: Icons.text_fields,
            title: 'Standard Personalization',
            description: 'Add your name, position, or member level as text overlays.',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomizeBasicScreen(product: product))),
          ),
          _OptionCard(
            icon: Icons.upload_file_outlined,
            title: 'Upload Own Design',
            description: 'Upload a complete design file for your card.',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomizeUploadScreen(product: product))),
          ),
          _OptionCard(
            icon: Icons.edit_note_outlined,
            title: 'Live Studio Editor',
            description: 'Build a custom layout with text, theme, and logo.',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomizeLiveScreen(product: product))),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _OptionCard({required this.icon, required this.title, required this.description, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SectionCard(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
