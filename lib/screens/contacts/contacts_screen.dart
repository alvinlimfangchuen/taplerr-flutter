import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/contact.dart';
import '../../services/contacts_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  ContactsResponse? _data;
  bool _loading = true;
  String _tab = 'All';
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ContactsService.instance.getContacts();
      if (mounted) setState(() => _data = data);
    } catch (_) {
      // Keep previous state; user can pull to retry.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Contact> get _currentList {
    final data = _data;
    if (data == null) return const [];
    List<Contact> list;
    switch (_tab) {
      case 'Requests':
        list = data.incoming;
        break;
      case 'Sent':
        list = data.outgoing;
        break;
      case 'Manual':
        list = data.contacts.where((c) => c.isManual).toList();
        break;
      default:
        list = data.contacts;
    }
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return list;
    return list.where((c) => c.name.toLowerCase().contains(query)).toList();
  }

  Future<void> _approve(Contact c) async {
    final result = await ContactsService.instance.approve(c.refId);
    if (!mounted) return;
    _notify(result.success, result.success ? 'Request accepted.' : 'Could not accept request.');
    if (result.success) _load();
  }

  Future<void> _reject(Contact c) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Decline Request',
      message: 'Decline the connection request from ${c.name}?',
      confirmLabel: 'Decline',
    );
    if (!confirmed) return;
    final result = await ContactsService.instance.reject(c.refId);
    if (!mounted) return;
    _notify(result.success, result.success ? 'Request declined.' : 'Could not decline request.');
    if (result.success) _load();
  }

  Future<void> _deleteManual(Contact c) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Contact',
      message: 'Remove ${c.name} from your manual contacts?',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;
    final result = await ContactsService.instance.deleteManual(c.refId);
    if (!mounted) return;
    _notify(result.success, result.success ? 'Contact deleted.' : 'Could not delete contact.');
    if (result.success) _load();
  }

  void _notify(bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: success ? AppColors.success : AppColors.error),
    );
  }

  Future<void> _openAddEditModal({Contact? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final positionController = TextEditingController(text: existing?.position ?? '');
    final companyController = TextEditingController(text: existing?.company ?? '');
    final mobileController = TextEditingController(text: existing?.mobile ?? '');
    final emailController = TextEditingController(text: existing?.email ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(existing == null ? 'Add Contact' : 'Edit Contact', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Only the name is required.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Name *')),
            const SizedBox(height: 12),
            TextField(controller: positionController, decoration: const InputDecoration(hintText: 'Position')),
            const SizedBox(height: 12),
            TextField(controller: companyController, decoration: const InputDecoration(hintText: 'Company')),
            const SizedBox(height: 12),
            TextField(controller: mobileController, decoration: const InputDecoration(hintText: 'Mobile')),
            const SizedBox(height: 12),
            TextField(controller: emailController, decoration: const InputDecoration(hintText: 'Email')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || nameController.text.trim().isEmpty) return;
    final result = existing == null
        ? await ContactsService.instance.addManual(
            name: nameController.text.trim(),
            position: positionController.text.trim(),
            company: companyController.text.trim(),
            mobileNumber: mobileController.text.trim(),
            email: emailController.text.trim(),
          )
        : await ContactsService.instance.editManual(
            manualContactId: existing.refId,
            name: nameController.text.trim(),
            position: positionController.text.trim(),
            company: companyController.text.trim(),
            mobileNumber: mobileController.text.trim(),
            email: emailController.text.trim(),
          );
    if (!mounted) return;
    _notify(result.success, result.success ? 'Contact saved.' : 'Could not save contact.');
    if (result.success) _load();
  }

  Future<void> _exportCsv() async {
    final bytes = await ContactsService.instance.exportCsv();
    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(Uint8List.fromList(bytes), name: 'contacts.csv', mimeType: 'text/csv')],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final stats = _data?.stats;
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('Contacts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                      IconButton(onPressed: _exportCsv, icon: const Icon(Icons.file_download_outlined)),
                      IconButton(onPressed: () => _openAddEditModal(), icon: const Icon(Icons.person_add_alt_1_outlined)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (stats != null)
                    Row(
                      children: [
                        Expanded(child: StatCard(value: '${stats.total}', label: 'Total contacts')),
                        const SizedBox(width: 10),
                        Expanded(child: StatCard(value: '${stats.waiting}', label: 'Waiting for reply')),
                        const SizedBox(width: 10),
                        Expanded(child: StatCard(value: '${stats.sent}', label: 'Sent requests')),
                      ],
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['All', 'Requests', 'Sent', 'Manual'].map((tab) {
                        final selected = tab == _tab;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(tab),
                            selected: selected,
                            onSelected: (_) => setState(() => _tab = tab),
                            selectedColor: AppColors.primaryLight,
                            labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search contacts',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_currentList.isEmpty)
                    const EmptyState(icon: Icons.people_outline, message: 'No contacts match this view yet.')
                  else
                    ..._currentList.map((c) => _ContactTile(
                          contact: c,
                          tab: _tab,
                          onApprove: () => _approve(c),
                          onReject: () => _reject(c),
                          onEdit: () => _openAddEditModal(existing: c),
                          onDelete: () => _deleteManual(c),
                        )),
                ],
              ),
            ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;
  final String tab;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContactTile({
    required this.contact,
    required this.tab,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if ((contact.position ?? '').isNotEmpty || (contact.company ?? '').isNotEmpty)
                    Text(
                      [contact.position, contact.company].where((s) => (s ?? '').isNotEmpty).join(' · '),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  Text(contact.source, style: const TextStyle(fontSize: 11, color: AppColors.placeholder)),
                ],
              ),
            ),
            if (tab == 'Requests') ...[
              IconButton(onPressed: onApprove, icon: const Icon(Icons.check_circle, color: AppColors.success)),
              IconButton(onPressed: onReject, icon: const Icon(Icons.cancel, color: AppColors.error)),
            ] else if (tab == 'Sent')
              const Text('Pending', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
            else if (contact.isManual)
              PopupMenuButton<String>(
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
