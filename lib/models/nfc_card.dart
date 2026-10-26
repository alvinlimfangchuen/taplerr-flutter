class NfcCard {
  final String serialNumber;
  final String cardStatus; // Active | Deactive | Inactive | Expired
  final DateTime? activatedOn;
  final String? cardHash;

  NfcCard({
    required this.serialNumber,
    required this.cardStatus,
    this.activatedOn,
    this.cardHash,
  });

  factory NfcCard.fromJson(Map<String, dynamic> json) {
    DateTime? activated;
    final raw = json['activated_on']?.toString();
    if (raw != null && raw.isNotEmpty) {
      activated = DateTime.tryParse(raw);
    }
    return NfcCard(
      serialNumber: json['serial_number']?.toString() ?? '',
      cardStatus: json['card_status']?.toString() ?? 'Inactive',
      activatedOn: activated,
      cardHash: json['card_hash']?.toString(),
    );
  }
}
