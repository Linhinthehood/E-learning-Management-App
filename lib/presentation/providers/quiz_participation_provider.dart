import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/quiz_participation_remote_datasource.dart';

/// Provider for quiz participation data source
final quizParticipationDataSourceProvider =
    Provider<QuizParticipationRemoteDataSource>((ref) {
      return QuizParticipationRemoteDataSourceImpl();
    });

/// Provider for real-time quiz participant count stream
final quizParticipantCountStreamProvider = StreamProvider.family<int, String>((
  ref,
  quizId,
) {
  final dataSource = ref.read(quizParticipationDataSourceProvider);
  return dataSource.listenToParticipantCount(quizId);
});

/// Helper to join a quiz
Future<void> joinQuiz(WidgetRef ref, String quizId, String studentId) async {
  final dataSource = ref.read(quizParticipationDataSourceProvider);
  await dataSource.joinQuiz(quizId, studentId);
}

/// Helper to leave a quiz
Future<void> leaveQuiz(WidgetRef ref, String quizId, String studentId) async {
  final dataSource = ref.read(quizParticipationDataSourceProvider);
  await dataSource.leaveQuiz(quizId, studentId);
}
