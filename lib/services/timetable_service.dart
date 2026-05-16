import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

import '../models/train_schedule.dart';

class TimetableService {
  static final TimetableService _instance = TimetableService._internal();

  factory TimetableService() => _instance;

  TimetableService._internal();

  List<TrainSchedule> _allTrains = [];
  bool _loaded = false;

  Future<void> loadFromAsset(String assetPath) async {
    if (_loaded) return;
    final raw = await rootBundle.loadString(assetPath);
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    _allTrains = decoded
        .map((e) => TrainSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
    _loaded = true;
  }

  /// Very simple time comparison using today's date.
  DateTime _parseTime(String hhmm) {
    final now = DateTime.now();
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return DateTime(now.year, now.month, now.day, h, m);
  }

  /// Core recommendation logic.
  ///
  /// [homeToStationMinutes] - time from home to nearest local station in minutes.
  /// [bufferMinutes] - safety buffer before main train departure.
  Future<TrainRecommendation?> recommendTrain({
    required String mainStation,
    required DateTime mainDepartureTime,
    required String nearestLocalStation,
    required int homeToStationMinutes,
    int bufferMinutes = 15,
    int delaySimulationMinutes = 5,
  }) async {
    if (!_loaded) {
      throw StateError('Timetable not loaded. Call loadFromAsset first.');
    }

    // Filter trains that go to the main station and start from a nearby/any station
    final candidates = _allTrains.where(
      (t) =>
          t.toStation.toLowerCase() == mainStation.toLowerCase() &&
          t.fromStation.toLowerCase() == nearestLocalStation.toLowerCase(),
    );

    final List<TrainOption> feasible = [];

    for (final t in candidates) {
      final localDeparture = _parseTime(t.departureTime);
      final localArrival = _parseTime(t.arrivalTime);

      // Simulate small delay
      final simulatedArrival =
          localArrival.add(Duration(minutes: delaySimulationMinutes));

      // Time user must reach local station
      final mustReachLocalStationBy =
          localDeparture.subtract(const Duration(minutes: 5));

      final latestLeaveHome =
          mustReachLocalStationBy.subtract(Duration(minutes: homeToStationMinutes));

      final latestAllowedAtMain =
          mainDepartureTime.subtract(Duration(minutes: bufferMinutes));

      if (simulatedArrival.isBefore(latestAllowedAtMain) ||
          simulatedArrival.isAtSameMomentAs(latestAllowedAtMain)) {
        feasible.add(
          TrainOption(
            schedule: t,
            leaveHomeBy: latestLeaveHome,
            reachMainBy: simulatedArrival,
          ),
        );
      }
    }

    if (feasible.isEmpty) return null;

    feasible.sort((a, b) => a.leaveHomeBy.compareTo(b.leaveHomeBy));
    final best = feasible.first;

    final timeFmt = DateFormat('hh:mm a');

    return TrainRecommendation(
      message:
          'Leave home by ${timeFmt.format(best.leaveHomeBy)}.\n'
          'Go to ${nearestLocalStation} Railway Station.\n'
          'Catch the ${best.schedule.trainNo} - ${best.schedule.trainName} at ${best.schedule.departureTime}.\n'
          'You will reach $mainStation by ${timeFmt.format(best.reachMainBy)}.\n',
      option: best,
    );
  }
}

class TrainOption {
  final TrainSchedule schedule;
  final DateTime leaveHomeBy;
  final DateTime reachMainBy;

  TrainOption({
    required this.schedule,
    required this.leaveHomeBy,
    required this.reachMainBy,
  });
}

class TrainRecommendation {
  final String message;
  final TrainOption option;

  TrainRecommendation({
    required this.message,
    required this.option,
  });
}

