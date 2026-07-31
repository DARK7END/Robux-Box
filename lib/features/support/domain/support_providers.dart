import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../../../models/support_ticket.dart';
import '../data/support_repository.dart';

/// The signed-in user's own tickets, newest activity first.
final myTicketsProvider = StreamProvider<List<SupportTicket>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(supportRepositoryProvider).watchMyTickets(uid);
});

/// Every user's tickets — admin only (enforced by `firestore.rules`).
final allTicketsProvider = StreamProvider<List<SupportTicket>>((ref) {
  return ref.watch(supportRepositoryProvider).watchAllTickets();
});

final ticketMessagesProvider =
    StreamProvider.family<List<TicketMessage>, String>((ref, ticketId) {
  return ref.watch(supportRepositoryProvider).watchMessages(ticketId);
});

/// The admin-managed ticket category list from `config/support`.
final ticketCategoriesProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(supportRepositoryProvider).watchCategories();
});

/// Open tickets whose last reply was from the user — i.e. waiting on an
/// admin. Surfaced as the admin dashboard badge.
final openTicketsCountProvider = Provider<int>((ref) {
  final tickets = ref.watch(allTicketsProvider).valueOrNull ?? const [];
  return tickets
      .where((t) => t.status == TicketStatus.open && !t.lastSenderIsAdmin)
      .length;
});
