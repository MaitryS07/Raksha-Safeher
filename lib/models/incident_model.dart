class IncidentModel {
  final int? id;
  final String description;
  final bool emergencyTriggered;
  final String? location;
  final DateTime date;

  IncidentModel({
    this.id,
    required this.description,
    required this.emergencyTriggered,
    this.location,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "description": description,
      "emergency": emergencyTriggered ? 1 : 0,
      "location": location,
      "date": date.toIso8601String(),
    };
  }

  factory IncidentModel.fromMap(Map<String, dynamic> map) {
    return IncidentModel(
      id: map["id"],
      description: map["description"],
      emergencyTriggered: map["emergency"] == 1,
      location: map["location"],
      date: DateTime.parse(map["date"]),
    );
  }
}
