import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  List<PlanOffer> _plans = [];
  bool _loading = true;
  String? _submittingPlan;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final plans = await SubscriptionService.instance.getPlans();
      if (mounted) setState(() => _plans = plans);
    } catch (_) {
      // Keep previous state.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkout(PlanCheckoutForm form) async {
    setState(() => _submittingPlan = '${form.planId}-${form.billingCycle}');
    final url = await SubscriptionService.instance.submitCheckout(form);
    if (!mounted) return;
    setState(() => _submittingPlan = null);
    if (url != null) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start checkout. Please try again.'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _plans.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: const [EmptyState(icon: Icons.layers_outlined, message: 'No plans are available right now.')],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _plans.length,
                      itemBuilder: (context, i) => _PlanCard(
                        plan: _plans[i],
                        submitting: _submittingPlan,
                        onCheckout: _checkout,
                      ),
                    ),
            ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PlanOffer plan;
  final String? submitting;
  final void Function(PlanCheckoutForm) onCheckout;

  const _PlanCard({required this.plan, required this.submitting, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: plan.isRecommended ? AppColors.textPrimary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: plan.isRecommended ? AppColors.primary : AppColors.inputBorder, width: plan.isRecommended ? 2 : 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
              child: const Text('Most Popular', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          Text(
            plan.name,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: plan.isRecommended ? Colors.white : AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            plan.description,
            style: TextStyle(fontSize: 13, color: plan.isRecommended ? Colors.white70 : AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            '${plan.monthlyPriceLabel} / month',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: plan.isRecommended ? Colors.white : AppColors.textPrimary),
          ),
          if ((plan.yearlyPriceLabel ?? '').isNotEmpty)
            Text(
              plan.yearlyPriceLabel!,
              style: TextStyle(fontSize: 12, color: plan.isRecommended ? Colors.white60 : AppColors.textSecondary),
            ),
          const SizedBox(height: 16),
          ...plan.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: plan.isRecommended ? AppColors.primary : AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(f, style: TextStyle(fontSize: 13, color: plan.isRecommended ? Colors.white : AppColors.textPrimary)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          if (plan.isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text('Current Plan', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
            )
          else
            ...plan.checkoutForms.map((form) {
              final isSubmitting = submitting == '${form.planId}-${form.billingCycle}';
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : () => onCheckout(form),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: plan.isRecommended ? AppColors.primary : null,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                          )
                        : Text(form.buttonLabel),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
