import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/mood_service.dart';
import '../models/mood_response_model.dart';
import 'question_screen.dart';
import 'guardian_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MoodService _moodService = MoodService();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('지금 어때?'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/auth');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '지금 어때?',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => _navigateToQuestion(),
              icon: const Icon(Icons.sentiment_satisfied),
              label: const Text('상태 알려주기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GuardianScreen()),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('지정자 관리'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToQuestion() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.user?.uid;
    
    if (userId == null) return;

    final currentSlot = await _moodService.getCurrentTimeSlot();
    
    if (currentSlot == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('현재는 질문 시간이 아닙니다.'),
          ),
        );
      }
      return;
    }

    final hasResponded = await _moodService.hasRespondedToday(
      subjectId: userId,
      slot: currentSlot,
    );

    if (hasResponded) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이미 오늘 이 시간대에 응답하셨습니다.'),
          ),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuestionScreen(timeSlot: currentSlot),
        ),
      );
    }
  }
}
