import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'model_utils.dart';

/// Lifecycle of a support ticket. Either side can close it; either side
/// re-opens it just by sending another message.
enum TicketStatus { open, closed }

/// A support conversation at `supportTickets/{id}`, with its messages in the
/// `messages` subcollection. Created directly by the client (owner-scoped,
/// like `reports`) — no economic data involved, so no Cloud Function needed.
class SupportTicket extends Equatable {
  const SupportTicket({
    required this.id,
    required this.uid,
    required this.displayName,
    required this.category,
    required this.subject,
    required this.status,
    required this.lastMessagePreview,
    required this.lastSenderIsAdmin,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String uid;

  /// The requester's display name, copied in at creation so the admin list
  /// can show who a ticket is from without a per-row user lookup.
  final String displayName;
  final String category;
  final String subject;
  final TicketStatus status;
  final String lastMessagePreview;
  final bool lastSenderIsAdmin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SupportTicket.fromMap(String id, Map<String, dynamic> map) {
    return SupportTicket(
      id: id,
      uid: Parse.toStr(map['uid']),
      displayName: Parse.toStr(map['displayName']),
      category: Parse.toStr(map['category'], 'other'),
      subject: Parse.toStr(map['subject']),
      status: Parse.enumFromName(map['status'], TicketStatus.values, TicketStatus.open),
      lastMessagePreview: Parse.toStr(map['lastMessagePreview']),
      lastSenderIsAdmin: Parse.toBool(map['lastSenderIsAdmin']),
      createdAt: Parse.toDate(map['createdAt']),
      updatedAt: Parse.toDate(map['updatedAt']),
    );
  }

  factory SupportTicket.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      SupportTicket.fromMap(doc.id, doc.data() ?? const {});

  @override
  List<Object?> get props => [id, uid, status, updatedAt, lastMessagePreview];
}

/// A single message in a ticket's `messages` subcollection.
class TicketMessage extends Equatable {
  const TicketMessage({
    required this.id,
    required this.senderUid,
    required this.isAdmin,
    required this.text,
    required this.imageUrl,
    required this.createdAt,
  });

  final String id;
  final String senderUid;
  final bool isAdmin;
  final String text;

  /// Optional attached screenshot, uploaded to
  /// `support/{ticketId}/{messageId}.jpg`. Empty when the message is text-only.
  final String imageUrl;
  final DateTime? createdAt;

  bool get hasImage => imageUrl.isNotEmpty;

  factory TicketMessage.fromMap(String id, Map<String, dynamic> map) {
    return TicketMessage(
      id: id,
      senderUid: Parse.toStr(map['senderUid']),
      isAdmin: Parse.toBool(map['isAdmin']),
      text: Parse.toStr(map['text']),
      imageUrl: Parse.toStr(map['imageUrl']),
      createdAt: Parse.toDate(map['createdAt']),
    );
  }

  factory TicketMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      TicketMessage.fromMap(doc.id, doc.data() ?? const {});

  @override
  List<Object?> get props => [id, senderUid, text, createdAt];
}
