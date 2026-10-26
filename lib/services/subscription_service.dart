import 'package:html/dom.dart';
import 'api_client.dart';
import 'scrape_utils.dart';

/// A plan's checkout/switch form, scraped straight off `/subscription` —
/// the CSRF token lives in that form's hidden input, so there's no need
/// for a separate fetchCsrfToken() round-trip for this action.
class PlanCheckoutForm {
  final String action; // /subscription/checkout | /subscription/switch
  final String csrfToken;
  final int planId;
  final String billingCycle; // Monthly | Yearly
  final String buttonLabel;

  PlanCheckoutForm({
    required this.action,
    required this.csrfToken,
    required this.planId,
    required this.billingCycle,
    required this.buttonLabel,
  });
}

class PlanOffer {
  final String name;
  final String description;
  final String monthlyPriceLabel;
  final String? yearlyPriceLabel;
  final List<String> features;
  final bool isCurrent;
  final bool isRecommended;
  final List<PlanCheckoutForm> checkoutForms;

  PlanOffer({
    required this.name,
    required this.description,
    required this.monthlyPriceLabel,
    this.yearlyPriceLabel,
    required this.features,
    required this.isCurrent,
    required this.isRecommended,
    required this.checkoutForms,
  });
}

class BillingSnapshot {
  final String planName;
  final String planDescription;
  final String priceLabel;
  final String billingCycle;
  final String renewsLabel;
  final String digitalProfilesLabel;
  final List<String> features;
  final String? paymentMethodLabel;
  final String ctaLabel;
  final String ctaHref;
  final bool ctaOpensExternally;

  BillingSnapshot({
    required this.planName,
    required this.planDescription,
    required this.priceLabel,
    required this.billingCycle,
    required this.renewsLabel,
    required this.digitalProfilesLabel,
    required this.features,
    this.paymentMethodLabel,
    required this.ctaLabel,
    required this.ctaHref,
    required this.ctaOpensExternally,
  });
}

/// `/subscription` (plan comparison) and `/billing` (current plan +
/// payment method) are both plain server-rendered HTML — scraped via DOM
/// using the confirmed `.plan-card`/`.plan-row` class structure.
class SubscriptionService {
  SubscriptionService._internal();
  static final SubscriptionService instance = SubscriptionService._internal();

  final ApiClient _client = ApiClient.instance;

  Future<List<PlanOffer>> getPlans() async {
    final res = await _client.get('/subscription');
    final html = res.data is String ? res.data as String : '';
    final doc = ScrapeUtils.parseDocument(html);
    final offers = <PlanOffer>[];

    for (final card in doc.querySelectorAll('.plan-card')) {
      final name = ScrapeUtils.text(card.querySelector('.plan-name'));
      if (name.isEmpty) continue;
      final forms = <PlanCheckoutForm>[];
      for (final form in card.querySelectorAll('form')) {
        final action = form.attributes['action'] ?? '';
        if (!action.contains('/subscription/')) continue;
        String fieldValue(String fieldName) =>
            form.querySelector('input[name="$fieldName"]')?.attributes['value'] ?? '';
        final planId = int.tryParse(fieldValue('plan_id'));
        if (planId == null) continue;
        forms.add(PlanCheckoutForm(
          action: action,
          csrfToken: fieldValue('csrf_token'),
          planId: planId,
          billingCycle: fieldValue('billing_cycle').isEmpty ? 'Monthly' : fieldValue('billing_cycle'),
          buttonLabel: ScrapeUtils.text(form.querySelector('button')),
        ));
      }

      offers.add(PlanOffer(
        name: name,
        description: ScrapeUtils.text(card.querySelector('.plan-desc')),
        monthlyPriceLabel: ScrapeUtils.text(card.querySelector('.plan-price .amt')),
        yearlyPriceLabel: ScrapeUtils.text(card.querySelector('.plan-period')).isEmpty
            ? null
            : ScrapeUtils.text(card.querySelector('.plan-period')),
        features: card
            .querySelectorAll('.plan-feature')
            .map(ScrapeUtils.text)
            .where((t) => t.isNotEmpty)
            .toList(),
        isCurrent: card.querySelector('.plan-current-badge') != null,
        isRecommended: card.attributes['class']?.contains('recommended') ?? false,
        checkoutForms: forms,
      ));
    }
    return offers;
  }

  Future<BillingSnapshot?> getBilling() async {
    final html = await _client.getAuthedHtml('/billing');
    final doc = ScrapeUtils.parseDocument(html);
    final card = doc.querySelector('.card');
    if (card == null) return null;

    String? metaValue(String label) {
      for (final item in doc.querySelectorAll('.meta-item')) {
        if (ScrapeUtils.text(item.querySelector('.label')) == label) {
          return ScrapeUtils.text(item.querySelector('.value'));
        }
      }
      return null;
    }

    Element? ctaLink;
    for (final a in doc.querySelectorAll('.btn-row a')) {
      ctaLink = a;
      break;
    }

    String? paymentLabel;
    final paymentRow = doc.querySelector('.payment-method-row');
    if (paymentRow != null) {
      final brand = ScrapeUtils.text(paymentRow.querySelector('.brand'));
      final last4 = ScrapeUtils.text(paymentRow.querySelector('.last4'));
      paymentLabel = [brand, last4].where((s) => s.isNotEmpty).join(' ');
    }

    return BillingSnapshot(
      planName: ScrapeUtils.text(doc.querySelector('.plan-row-name')),
      planDescription: ScrapeUtils.text(doc.querySelector('.plan-row-desc')),
      priceLabel: ScrapeUtils.text(doc.querySelector('.plan-row-price .amt')),
      billingCycle: metaValue('Billing cycle') ?? '—',
      renewsLabel: metaValue('Renews') ?? '—',
      digitalProfilesLabel: metaValue('Digital profiles') ?? '—',
      features: doc.querySelectorAll('.plan-features li').map(ScrapeUtils.text).toList(),
      paymentMethodLabel: paymentLabel,
      ctaLabel: ctaLink != null ? ScrapeUtils.text(ctaLink) : '',
      ctaHref: ctaLink?.attributes['href'] ?? '',
      ctaOpensExternally: (ctaLink?.attributes['href'] ?? '').contains('/subscription/manage'),
    );
  }

  /// Returns the Stripe-hosted URL to open externally on success, or null
  /// if the backend flash-redirected back to /subscription on failure.
  Future<String?> submitCheckout(PlanCheckoutForm form) async {
    final res = await _client.post(form.action, data: {
      'plan_id': form.planId,
      'billing_cycle': form.billingCycle,
      'csrf_token': form.csrfToken,
    });
    final location = res.headers.value('location') ?? '';
    if (location.startsWith('http') && !location.contains('/subscription')) {
      return location;
    }
    return null;
  }
}
