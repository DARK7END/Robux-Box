import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/error/result.dart';
import '../../../core/network/firebase_error_mapper.dart';
import '../../../core/utils/logger.dart';
import '../../../models/app_user.dart';
import '../../../models/support_ticket.dart';

/// Support-ticket data access, shared by the user-facing "Contact Support"
/// flow and the admin ticket-management screen — both sides of a
/// conversation are the same read/write shape, only `isAdmin` (checked
/// server-side by `firestore.rules`, not by this class) differs.
///
/// Non-economic, so — like `reports` and `rewards` — writes go straight to
/// Firestore rather than through a Cloud Function. Creating a ticket and
/// sending a message each touch two documents (the ticket + a message), so
/// both use a [WriteBatch] for atomicity.
class SupportRepository {
  SupportRepository(this._db, this._storage);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  static const _previewMaxLength = 120;

  /// Used when no admin-managed category list has been configured yet.
  static const defaultCategories = <String>[
    'payment',
    'account',
    'offer',
    'bug',
    'other',
  ];

  String _preview(String text) => text.length <= _previewMaxLength
      ? text
      : '${text.substring(0, _previewMaxLength)}…';

  /// The admin-managed ticket categories from `config/support`. Falls back to
  /// [defaultCategories] when unset so the ticket form always works.
  Stream<List<String>> watchCategories() {
    return _db.doc(FsPaths.configDoc('support')).snapshots().map((d) {
      final raw = d.data()?['ticketCategories'];
      if (raw is! List || raw.isEmpty) return defaultCategories;
      return raw.map((e) => e.toString()).toList();
    });
  }

  /// Admin-only (enforced by rules): replaces the category list wholesale.
  Future<Result<void>> saveCategories(List<String> categories) async {
    try {
      await _db.doc(FsPaths.configDoc('support')).set(
        {'ticketCategories': categories},
        SetOptions(merge: true),
      );
      return const Result.success(null);
    } catch (e, s) {
      log.e('saveCategories failed', e, s);
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  Stream<List<SupportTicket>> watchMyTickets(String uid) {
    return _db
        .collection(FsPaths.supportTickets)
        .where('uid', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map(SupportTicket.fromDoc).toList());
  }

  /// All tickets across every user — admin only (enforced by rules). Gold/
  /// Diamond's paid-for priority-support benefit: their tickets float to the
  /// top, most-recently-active first within each priority tier.
  Stream<List<SupportTicket>> watchAllTickets() {
    return _db
        .collection(FsPaths.supportTickets)
        .orderBy('updatedAt', descending: true)
        .limit(200)
        .snapshots()
        .map((s) {
      final tickets = s.docs.map(SupportTicket.fromDoc).toList();
      tickets.sort((a, b) => a.isPriority != b.isPriority
          ? (a.isPriority ? -1 : 1)
          : (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)));
      return tickets;
    });
  }

  Stream<List<TicketMessage>> watchMessages(String ticketId) {
    return _db
        .collection(FsPaths.ticketMessages(ticketId))
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map(TicketMessage.fromDoc).toList());
  }

  /// Uploads an attachment for a ticket message and returns its download URL.
  Future<String> _uploadAttachment(
    String ticketId,
    String messageId,
    File file,
  ) async {
    final ref = _storage.ref('support/$ticketId/$messageId.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<Result<String>> createTicket({
    required String uid,
    required String displayName,
    required String category,
    required String subject,
    required String message,
    bool isPriority = false,
    VipLevel vipLevel = VipLevel.none,
    File? attachment,
  }) async {
    try {
      final ticketRef = _db.collection(FsPaths.supportTickets).doc();
      final messageRef =
          _db.collection(FsPaths.ticketMessages(ticketRef.id)).doc();
      final imageUrl = attachment == null
          ? ''
          : await _uploadAttachment(ticketRef.id, messageRef.id, attachment);
      final batch = _db.batch()
        ..set(ticketRef, {
          'uid': uid,
          'displayName': displayName,
          'category': category,
          'subject': subject,
          'status': TicketStatus.open.name,
          'isPriority': isPriority,
          'vipLevel': vipLevel.name,
          'lastMessagePreview': _preview(message),
          'lastSenderIsAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        ..set(messageRef, {
          'senderUid': uid,
          'isAdmin': false,
          'text': message,
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
      await batch.commit();
      return Result.success(ticketRef.id);
    } catch (e, s) {
      log.e('createTicket failed', e, s);
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  /// Sends a reply. Reopens the ticket if it had been closed — an active
  /// message means the conversation isn't over.
  Future<Result<void>> sendMessage({
    required String ticketId,
    required String senderUid,
    required bool isAdmin,
    required String text,
    File? attachment,
  }) async {
    try {
      final messageRef = _db.collection(FsPaths.ticketMessages(ticketId)).doc();
      final imageUrl = attachment == null
          ? ''
          : await _uploadAttachment(ticketId, messageRef.id, attachment);
      final batch = _db.batch()
        ..set(messageRef, {
          'senderUid': senderUid,
          'isAdmin': isAdmin,
          'text': text,
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        })
        ..update(_db.collection(FsPaths.supportTickets).doc(ticketId), {
          'status': TicketStatus.open.name,
          'lastMessagePreview': text.isEmpty ? '📎' : _preview(text),
          'lastSenderIsAdmin': isAdmin,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      await batch.commit();
      return const Result.success(null);
    } catch (e, s) {
      log.e('sendMessage failed', e, s);
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  Future<Result<void>> setStatus(String ticketId, TicketStatus status) async {
    try {
      await _db.collection(FsPaths.supportTickets).doc(ticketId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Result.success(null);
    } catch (e, s) {
      log.e('setStatus failed', e, s);
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  /// Admin-only (enforced by rules): permanently removes a ticket and every
  /// message in it. Non-economic, so — like the rest of this class — a plain
  /// batched Firestore delete rather than a Cloud Function.
  Future<Result<void>> deleteTicket(String ticketId) async {
    try {
      final messages =
          await _db.collection(FsPaths.ticketMessages(ticketId)).get();
      final batch = _db.batch();
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_db.collection(FsPaths.supportTickets).doc(ticketId));
      await batch.commit();
      return const Result.success(null);
    } catch (e, s) {
      log.e('deleteTicket failed', e, s);
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }
}

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(
    ref.watch(firestoreProvider),
    ref.watch(storageProvider),
  );
});
