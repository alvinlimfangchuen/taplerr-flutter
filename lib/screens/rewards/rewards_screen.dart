import 'package:flutter/material.dart';
import '../../widgets/common_widgets.dart';

/// `/rewards` is a "Coming soon" placeholder on the web today — no real
/// catalogue exists yet (confirmed against the live backend), so this
/// mirrors that rather than inventing a speculative full catalogue UI.
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SectionCard(
          child: Column(
            children: [
              SectionHeading('Rewards Catalogue'),
              EmptyState(
                icon: Icons.card_giftcard_outlined,
                message: 'Coming soon — redeem your points for rewards right here.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
