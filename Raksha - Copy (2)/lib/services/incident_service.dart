import '../models/incident_model.dart';

class IncidentService {
  static List<Incident> incidents = [];

  static void logIncident(String desc, bool sos) {
    incidents.add(
      Incident(
        date: DateTime.now(),
        description: desc,
        emergencyTriggered: sos,
      ),
    );
  }
}
