import 'package:cloud_firestore/cloud_firestore.dart';

/// 공지사항 모델
class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final bool pinned;
  final DateTime? createdAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    this.pinned = false,
    this.createdAt,
  });
}

/// 공지사항 서비스 (Firestore announcements 컬렉션)
class AnnouncementService {
  static final AnnouncementService _instance = AnnouncementService._();
  factory AnnouncementService() => _instance;
  AnnouncementService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'announcements';

  /// 공지사항 목록 조회 (최신순, 최대 20건)
  Future<List<AnnouncementModel>> getAnnouncements() async {
    final snap = await _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    final list = <AnnouncementModel>[];
    for (final doc in snap.docs) {
      final d = doc.data();
      final createdAt = d['createdAt'] as Timestamp?;
      list.add(AnnouncementModel(
        id: doc.id,
        title: d['title'] as String? ?? '',
        content: d['content'] as String? ?? '',
        pinned: d['pinned'] as bool? ?? false,
        createdAt: createdAt?.toDate(),
      ));
    }

    // 상단 고정 먼저 정렬
    list.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      final ta = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final tb = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return tb.compareTo(ta);
    });

    return list;
  }
}
