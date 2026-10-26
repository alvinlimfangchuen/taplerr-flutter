import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'subscription_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  BillingSnapshot? _billing;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final billing = await SubscriptionService.instance.getBilling();
      if (mounted) setState(() => _billing = billing);
    } catch (_) {
      // Keep previous state.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final billing = _billing;
    return Scaffold(
      appBar: AppBar(title: const Text('Billing')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : billing == null
              ? RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [EmptyState(icon: Icons.receipt_long_outlined, message: 'Could not load billing details.')],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeading('Current Plan'),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(billing.planName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      Text(billing.planDescription, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Text(billing.priceLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _metaTile('Billing cycle', billing.billingCycle)),
                                Expanded(child: _metaTile('Renews', billing.renewsLabel)),
                                Expanded(child: _metaTile('Profiles', billing.digitalProfilesLabel)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...billing.features.map((f) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
                                    ],
                                  ),
                                )),
                            if (billing.paymentMethodLabel != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: AppColors.inputBackground, borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.credit_card, color: AppColors.textSecondary),
                                    const SizedBox(width: 12),
                                    Text(billing.paymentMethodLabel!),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            if (billing.ctaHref.isNotEmpty)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (billing.ctaOpensExternally) {
                                      await launchUrl(
                                        Uri.parse('https://demo.taplerr.com${billing.ctaHref}'),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } else {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                                    }
                                  },
                                  child: Text(billing.ctaLabel),
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

  Widget _metaTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
