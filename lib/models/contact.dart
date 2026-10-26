/// One row from GET /contacts — mutual/incoming/outgoing/manual all share
/// this shape (see UserController.php shapeContactRow/shapeManualRow).
class Contact {
  final String uid; // "<type>-<ref_id>"
  final String type; // mutual | incoming | outgoing | manual
  final int refId;
  final String name;
  final String? position;
  final String? company;
  final String? email;
  final String? mobile;
  final String source; // "Tapped card" | "Added manually"
  final String? addedAt;
  final String? profileSlug;

  Contact({
    required this.uid,
    required this.type,
    required this.refId,
    required this.name,
    this.position,
    this.company,
    this.email,
    this.mobile,
    required this.source,
    this.addedAt,
    this.profileSlug,
  });

  bool get isManual => type == 'manual';

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      uid: json['uid']?.toString() ?? '',
      type: json['type']?.toString() ?? 'manual',
      refId: json['ref_id'] is int
          ? json['ref_id'] as int
          : int.tryParse('${json['ref_id'] ?? ''}') ?? 0,
      name: json['name']?.toString() ?? '',
      position: json['position']?.toString(),
      company: json['company']?.toString(),
      email: json['email']?.toString(),
      mobile: json['mobile']?.toString(),
      source: json['source']?.toString() ?? 'Added manually',
      addedAt: json['added_at']?.toString(),
      profileSlug: json['profile_slug']?.toString(),
    );
  }
}

class ContactStats {
  final int total;
  final int waiting;
  final int sent;
  final int manual;

  ContactStats({this.total = 0, this.waiting = 0, this.sent = 0, this.manual = 0});

  factory ContactStats.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
    return ContactStats(
      total: asInt(json['total']),
      waiting: asInt(json['waiting']),
      sent: asInt(json['sent']),
      manual: asInt(json['manual']),
    );
  }
}

class ContactsResponse {
  final List<Contact> contacts;
  final List<Contact> incoming;
  final List<Contact> outgoing;
  final ContactStats stats;

  ContactsResponse({
    required this.contacts,
    required this.incoming,
    required this.outgoing,
    required this.stats,
  });

  factory ContactsResponse.fromJson(Map<String, dynamic> json) {
    List<Contact> list(dynamic raw) => (raw is List)
        ? raw.whereType<Map<String, dynamic>>().map(Contact.fromJson).toList()
        : <Contact>[];
    return ContactsResponse(
      contacts: list(json['contacts']),
      incoming: list(json['incoming']),
      outgoing: list(json['outgoing']),
      stats: json['stats'] is Map<String, dynamic>
          ? ContactStats.fromJson(json['stats'] as Map<String, dynamic>)
          : ContactStats(),
    );
  }
}
