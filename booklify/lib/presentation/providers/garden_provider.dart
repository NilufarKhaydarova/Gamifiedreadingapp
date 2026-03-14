import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/progress.dart';
import '../../data/models/book.dart';
import '../../widgets/garden/tree_painter.dart';

// Progress Provider
final progressProvider = StateProvider<Progress?>((ref) {
  return null;
});

// Current Book Provider
final currentBookProvider = StateProvider<Book?>((ref) {
  return null;
});

// Garden Weather Provider - calculates weather based on reading streak
final gardenWeatherProvider = Provider<GardenWeather>((ref) {
  final progress = ref.watch(progressProvider);

  if (progress == null || progress.completedDays.isEmpty) {
    return GardenWeather.cloudy;
  }

  final lastReadDate = DateTime.tryParse(progress.completedDays.last);
  if (lastReadDate == null) return GardenWeather.cloudy;

  final daysSinceReading = DateTime.now().difference(lastReadDate).inDays;

  if (daysSinceReading == 0) {
    return GardenWeather.sunny;
  } else if (daysSinceReading == 1) {
    return GardenWeather.cloudy;
  } else {
    return GardenWeather.stormy;
  }
});

// Progress Notifier for managing progress state
class ProgressNotifier extends StateNotifier<Progress?> {
  ProgressNotifier() : super(null);

  void updateProgress(Progress progress) {
    state = progress;
  }

  void completeDay(Progress progress) {
    final updated = progress.completeDay();
    state = updated;
  }
}

// Book Notifier for managing book state
class BookNotifier extends StateNotifier<Book?> {
  BookNotifier() : super(null);

  void setCurrentBook(Book book) {
    state = book;
  }

  void updateBook(Book book) {
    state = book;
  }
}

// Providers for notifiers
final progressNotifierProvider = StateNotifierProvider<ProgressNotifier, Progress?>((ref) {
  return ProgressNotifier();
});

final bookNotifierProvider = StateNotifierProvider<BookNotifier, Book?>((ref) {
  return BookNotifier();
});