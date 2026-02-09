import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../fasting/domain/fasting_session.dart';
import '../../fasting/data/fasting_repository.dart';
import '../../authentication/data/auth_repository.dart';

enum MetricType { week, month, year }

class FastingHistoryState {
  final MetricType view;
  final DateTime focusedDate;
  final List<FastingSession> allSessions;
  final bool isLoading;

  const FastingHistoryState({
    this.view = MetricType.week,
    required this.focusedDate,
    this.allSessions = const [],
    this.isLoading = true,
  });

  FastingHistoryState copyWith({
    MetricType? view,
    DateTime? focusedDate,
    List<FastingSession>? allSessions,
    bool? isLoading,
  }) {
    return FastingHistoryState(
      view: view ?? this.view,
      focusedDate: focusedDate ?? this.focusedDate,
      allSessions: allSessions ?? this.allSessions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FastingHistoryController extends StateNotifier<FastingHistoryState> {
  final FastingRepository _repository;
  final String? _uid;

  FastingHistoryController(this._repository, this._uid)
      : super(FastingHistoryState(focusedDate: DateTime.now())) {
    _loadHistory();
  }

  void _loadHistory() {
    if (_uid == null) {
       state = state.copyWith(allSessions: [], isLoading: false);
       return;
    }
    _repository.getHistoryStream(_uid!).listen((sessions) {
      if (mounted) {
        state = state.copyWith(allSessions: sessions, isLoading: false);
      }
    });
  }

  void setView(MetricType view) {
    state = state.copyWith(view: view, focusedDate: DateTime.now());
  }

  void next() {
    state = state.copyWith(focusedDate: _adjustDate(1));
  }

  void previous() {
    state = state.copyWith(focusedDate: _adjustDate(-1));
  }

  DateTime _adjustDate(int factor) {
    final date = state.focusedDate;
    switch (state.view) {
      case MetricType.week:
        return date.add(Duration(days: 7 * factor));
      case MetricType.month:
        return DateTime(date.year, date.month + factor, date.day);
      case MetricType.year:
        return DateTime(date.year + factor, date.month, date.day);
    }
  }

  String getDateLabel() {
    final date = state.focusedDate;
    final now = DateTime.now();
    
    // Configuración local español simplificada
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    switch (state.view) {
      case MetricType.week:
        final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        
        final startFormat = DateFormat('d MMM');
        final endFormat = DateFormat('d MMM');
        
        // Si es la semana actual
        if (startOfWeek.isBefore(now) && endOfWeek.isAfter(now)) {
           return "Esta Semana";
        }
        
        return "${startFormat.format(startOfWeek)} - ${endFormat.format(endOfWeek)}";
        
      case MetricType.month:
        if (date.year == now.year && date.month == now.month) return "Este Mes";
        return "${months[date.month - 1]} ${date.year}";
        
      case MetricType.year:
        if (date.year == now.year) return "Este Año";
        return "${date.year}";
    }
  }

  List<ChartDataPoint> getAggregatedData() {
    final sessions = state.allSessions;
    final view = state.view;
    final focus = state.focusedDate;
    
    List<ChartDataPoint> points = [];

    if (view == MetricType.week) {
      // Logic: 7 days of the week (Mon-Sun)
      final startOfWeek = DateTime(focus.year, focus.month, focus.day)
          .subtract(Duration(days: focus.weekday - 1));
      
      for (int i = 0; i < 7; i++) {
        final currentDay = startOfWeek.add(Duration(days: i));
        final daySessions = sessions.where((s) {
           return s.endTime != null && 
                  s.endTime!.year == currentDay.year && 
                  s.endTime!.month == currentDay.month && 
                  s.endTime!.day == currentDay.day;
        });
        
        // Sum total hours for that day
        double totalHours = 0;
        for (var s in daySessions) {
           final duration = s.endTime!.difference(s.startTime).inMinutes / 60.0;
           totalHours += duration;
        }

        const weekDays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
        points.add(ChartDataPoint(
           x: i, 
           y: totalHours, 
           label: weekDays[i],
           fullDate: currentDay
        ));
      }

    } else if (view == MetricType.month) {
      // Logic: Days of the month
      final daysInMonth = DateUtils.getDaysInMonth(focus.year, focus.month);
      
      // Agrupar visualmente cada 5 días para no saturar, o mostrar todos si cabe?
      // FlChart permite scroll, pero aquí simplificaremos mostrando todos los días.
      
      for (int i = 1; i <= daysInMonth; i++) {
         final currentDay = DateTime(focus.year, focus.month, i);
         final daySessions = sessions.where((s) {
           return s.endTime != null && 
                  s.endTime!.year == currentDay.year && 
                  s.endTime!.month == currentDay.month && 
                  s.endTime!.day == currentDay.day;
        });

        double totalHours = 0;
        for (var s in daySessions) {
           final duration = s.endTime!.difference(s.startTime).inMinutes / 60.0;
           totalHours += duration;
        }
        
        points.add(ChartDataPoint(
            x: i - 1, 
            y: totalHours,
            label: (i % 5 == 0 || i == 1) ? '$i' : '', // Show label every 5 days
            fullDate: currentDay
        ));
      }

    } else if (view == MetricType.year) {
      // Logic: 12 Months
      for (int i = 1; i <= 12; i++) {
         final monthSessions = sessions.where((s) {
            return s.endTime != null && 
                   s.endTime!.year == focus.year && 
                   s.endTime!.month == i;
         });
         
         // Average daily fasting for that month? Or Total?
         // Average duration per fast is more user-friendly to compare consistency.
         double avgDuration = 0;
         if (monthSessions.isNotEmpty) {
            double totalDuration = 0;
            for (var s in monthSessions) {
              totalDuration += s.endTime!.difference(s.startTime).inMinutes / 60.0;
            }
            avgDuration = totalDuration / monthSessions.length;
         }

         const months = ['E', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
         points.add(ChartDataPoint(
            x: i - 1,
            y: avgDuration,
            label: months[i-1],
            fullDate: DateTime(focus.year, i)
         ));
      }
    }

    return points;
  }
}

class ChartDataPoint {
  final int x;
  final double y;
  final String label;
  final DateTime? fullDate;

  ChartDataPoint({required this.x, required this.y, required this.label, this.fullDate});
}

final fastingHistoryProvider = 
    StateNotifierProvider.autoDispose<FastingHistoryController, FastingHistoryState>((ref) {
  final repo = ref.watch(fastingRepositoryProvider);
  final user = ref.watch(authStateChangesProvider).value;
  return FastingHistoryController(repo, user?.uid);
});
