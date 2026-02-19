import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// 1:1 문의 모델
class InquiryModel {
  final String id;
  final String userId;
  final String userPhone;
  final String? userDisplayName;
  final String role;
  final String message;
  final DateTime createdAt;
  final List<InquiryReply> replies;

  InquiryModel({
    required this.id,
    required this.userId,
    required this.userPhone,
    this.userDisplayName,
    required this.role,
    required this.message,
    required this.createdAt,
    this.replies = const [],
  });

  factory InquiryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final repliesRaw = data['replies'] as List<dynamic>? ?? [];
    final replies = repliesRaw
        .map((e) => InquiryReply.fromMap(e as Map<String, dynamic>))
        .toList();
    final createdAt = data['createdAt'];
    return InquiryModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userPhone: data['userPhone'] as String? ?? '',
      userDisplayName: data['userDisplayName'] as String?,
      role: data['role'] as String? ?? 'subject',
      message: data['message'] as String? ?? '',
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.now(),
      replies: replies,
    );
  }
}

/// 문의 답변 모델
class InquiryReply {
  final String message;
  final DateTime createdAt;
  final bool isAdmin;

  InquiryReply({
    required this.message,
    required this.createdAt,
    this.isAdmin = true,
  });

  factory InquiryReply.fromMap(Map<String, dynamic> map) {
    final createdAt = map['createdAt'];
    DateTime date = DateTime.now();
    if (createdAt is Timestamp) {
      date = createdAt.toDate();
    } else if (createdAt is Map) {
      final sec = createdAt['_seconds'] ?? createdAt['seconds'];
      if (sec != null) {
        final ms = (sec is int ? sec : (sec is num ? sec.toInt() : 0)) * 1000;
        date = DateTime.fromMillisecondsSinceEpoch(ms);
      }
    }
    return InquiryReply(
      message: map['message'] as String? ?? '',
      createdAt: date,
      isAdmin: map['isAdmin'] as bool? ?? true,
    );
  }
}

/// 1:1 문의 서비스
class InquiryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 내 문의 목록 스트림
  Stream<List<InquiryModel>> streamMyInquiries(String userId) {
    return _firestore
        .collection(AppConstants.inquiriesCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => InquiryModel.fromFirestore(d)).toList());
  }

  /// 내 문의 목록 한 번 조회 (FutureBuilder용)
  Future<List<InquiryModel>> getMyInquiries(String userId) async {
    final snap = await _firestore
        .collection(AppConstants.inquiriesCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => InquiryModel.fromFirestore(d)).toList();
  }

  /// 문의 등록 (웹과 동일 필드: name, email, phone, message)
  Future<String?> createInquiry({
    required String userId,
    required String userPhone,
    String? userDisplayName,
    String? email,
    required String role,
    required String message,
  }) async {
    try {
      final emailTrimmed = email != null && email.trim().isNotEmpty ? email.trim().toLowerCase() : null;
      final ref = await _firestore.collection(AppConstants.inquiriesCollection).add({
        'userId': userId,
        'userPhone': userPhone,
        'userDisplayName': userDisplayName,
        if (emailTrimmed != null) 'email': emailTrimmed,
        'role': role,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'replies': <Map<String, dynamic>>[],
      });
      return ref.id;
    } catch (e) {
      return null;
    }
  }
}
