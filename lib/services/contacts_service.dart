import '../models/contact.dart';
import 'api_client.dart';
import 'scrape_utils.dart';

class ContactActionResult {
  final bool success;
  final String? error;
  ContactActionResult(this.success, [this.error]);
}

/// `/contacts` embeds its data as `const contactsRows/incomingRows/
/// outgoingRows = [...]` JS arrays (see notifications/contacts scrape
/// research) — same JSON shape a real API would return, just delivered
/// inside an HTML page.
class ContactsService {
  ContactsService._internal();
  static final ContactsService instance = ContactsService._internal();

  final ApiClient _client = ApiClient.instance;

  Future<ContactsResponse> getContacts() async {
    final html = await _client.getAuthedHtml('/contacts');

    List<Contact> parse(String varName) {
      final raw = ScrapeUtils.extractJsLiteral(html, varName);
      if (raw is! List) return const [];
      return raw.whereType<Map<String, dynamic>>().map(Contact.fromJson).toList();
    }

    final contacts = parse('contactsRows');
    final incoming = parse('incomingRows');
    final outgoing = parse('outgoingRows');

    int countWhere(List<Contact> list, bool Function(Contact) test) =>
        list.where(test).length;

    return ContactsResponse(
      contacts: contacts,
      incoming: incoming,
      outgoing: outgoing,
      stats: ContactStats(
        total: contacts.length,
        waiting: incoming.length,
        sent: outgoing.length,
        manual: countWhere(contacts, (c) => c.isManual),
      ),
    );
  }

  Future<ContactActionResult> approve(int contactId) async {
    final res = await _client.get('/contacts/approve', queryParameters: {'id': contactId});
    final location = res.headers.value('location') ?? '';
    return ContactActionResult(location.contains('status=success'));
  }

  Future<ContactActionResult> reject(int contactId) async {
    final res = await _client.get('/contacts/reject', queryParameters: {'id': contactId});
    final location = res.headers.value('location') ?? '';
    return ContactActionResult(location.contains('status=success'));
  }

  Future<ContactActionResult> addManual({
    required String name,
    String? position,
    String? company,
    String? mobileNumber,
    String? email,
  }) async {
    final res = await _client.post('/contacts/manual/add', data: {
      'contact_name': name,
      if (position != null) 'position': position,
      if (company != null) 'company': company,
      if (mobileNumber != null) 'mobile_number': mobileNumber,
      if (email != null) 'email': email,
    });
    final location = res.headers.value('location') ?? '';
    return ContactActionResult(location.contains('status=success'));
  }

  Future<ContactActionResult> editManual({
    required int manualContactId,
    required String name,
    String? position,
    String? company,
    String? mobileNumber,
    String? email,
  }) async {
    final res = await _client.post('/contacts/manual/edit', data: {
      'manual_contact_id': manualContactId,
      'contact_name': name,
      if (position != null) 'position': position,
      if (company != null) 'company': company,
      if (mobileNumber != null) 'mobile_number': mobileNumber,
      if (email != null) 'email': email,
    });
    final location = res.headers.value('location') ?? '';
    return ContactActionResult(location.contains('status=success'));
  }

  Future<ContactActionResult> deleteManual(int id) async {
    final res = await _client.get('/contacts/manual/delete', queryParameters: {'id': id});
    final location = res.headers.value('location') ?? '';
    return ContactActionResult(location.contains('status=success'));
  }

  Future<List<int>> exportCsv() => _client.getBytes('/contacts/export');

  Future<List<int>> vcard({required String type, required int id}) =>
      _client.getBytes('/contacts/vcard', queryParameters: {'type': type, 'id': id});
}
