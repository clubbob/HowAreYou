import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import '../utils/constants.dart';

/// 보호대상자 핸드폰 이동 감지 → lastMovementAt 업데이트
/// 프리미엄 6h/9h/12h 무활동 알림의 기준이 됨
class MovementDetectionService {
  static MovementDetectionService? _instance;
  static MovementDetectionService get instance =>
      _instance ??= MovementDetectionService._();

  MovementDetectionService._();

  StreamSubscription<ActivityEvent>? _subscription;
  final ActivityRecognition _activityRecognition = ActivityRecognition();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 이동으로 간주하는 활동 (STILL, UNKNOWN 제외) — 플러그인 5.x enum (UPPER_CASE)
  static const _movementTypes = {
    ActivityType.WALKING,
    ActivityType.RUNNING,
    ActivityType.ON_FOOT,
    ActivityType.IN_VEHICLE,
    ActivityType.ON_BICYCLE,
    ActivityType.TILTING,
  };

  /// 최소 신뢰도 (%)
  static const int _minConfidence = 50;

  /// Firestore 업데이트 최소 간격 (중복 쓰기·비용·배터리 절감)
  static const Duration _minUpdateInterval = Duration(minutes: 15);
  DateTime? _lastUpdateTime;

  bool _isRunning = false;
  String? _currentSubjectId;

  bool get isRunning => _isRunning;

  /// 보호대상자 모드 진입 시 호출
  Future<void> start(String subjectId) async {
    if (_isRunning && _currentSubjectId == subjectId) return;
    await stop();

    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('[이동감지] 모바일만 지원');
      return;
    }

    if (Platform.isAndroid) {
      final status = await Permission.activityRecognition.request();
      if (!status.isGranted) {
        debugPrint('[이동감지] 활동 인식 권한 없음');
        return;
      }
    }

    _currentSubjectId = subjectId;
    _subscription = _activityRecognition
        .activityStream(runForegroundService: true)
        .listen(_onActivity, onError: _onError);

    _isRunning = true;
    debugPrint('[이동감지] 시작 subjectId=$subjectId');
  }

  /// 보호대상자 모드 종료 시 호출
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _isRunning = false;
    _currentSubjectId = null;
    debugPrint('[이동감지] 중지');
  }

  void _onActivity(ActivityEvent event) {
    if (!_movementTypes.contains(event.type)) return;
    if (event.confidence < _minConfidence) return;

    final now = DateTime.now();
    if (_lastUpdateTime != null &&
        now.difference(_lastUpdateTime!) < _minUpdateInterval) {
      return;
    }

    _updateLastMovementAt();
  }

  void _onError(Object error) {
    debugPrint('[이동감지] 오류: $error');
  }

  Future<void> _updateLastMovementAt() async {
    final subjectId = _currentSubjectId;
    if (subjectId == null) return;

    try {
      await _firestore.collection(AppConstants.subjectsCollection).doc(subjectId).set({
        'lastMovementAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _lastUpdateTime = DateTime.now();
      debugPrint('[이동감지] lastMovementAt 업데이트 subjectId=$subjectId');
    } catch (e) {
      debugPrint('[이동감지] Firestore 쓰기 오류: $e');
    }
  }

  /// 앱에서 수동 호출 (예: 컨디션 기록 시 - 터치 = 이동)
  static Future<void> reportMovement(String subjectId) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.subjectsCollection)
          .doc(subjectId)
          .set({
        'lastMovementAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[이동감지] reportMovement subjectId=$subjectId');
    } catch (e) {
      debugPrint('[이동감지] reportMovement 오류: $e');
    }
  }
}
