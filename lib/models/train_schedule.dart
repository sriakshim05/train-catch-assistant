class TrainSchedule {
  final String trainNo;
  final String trainName;
  final String fromStation;
  final String toStation;
  final String departureTime; // "HH:mm"
  final String arrivalTime; // "HH:mm"
  final String trainType; // Local / Passenger / Express
  final List<String> districtsCovered;

  TrainSchedule({
    required this.trainNo,
    required this.trainName,
    required this.fromStation,
    required this.toStation,
    required this.departureTime,
    required this.arrivalTime,
    required this.trainType,
    required this.districtsCovered,
  });

  factory TrainSchedule.fromJson(Map<String, dynamic> json) {
    return TrainSchedule(
      trainNo: json['train_no'] as String,
      trainName: json['train_name'] as String,
      fromStation: json['from_station'] as String,
      toStation: json['to_station'] as String,
      departureTime: json['departure_time'] as String,
      arrivalTime: json['arrival_time'] as String,
      trainType: json['train_type'] as String,
      districtsCovered: (json['districts_covered'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
    );
  }
}

