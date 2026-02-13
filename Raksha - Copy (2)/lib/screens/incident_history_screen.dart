import 'package:flutter/material.dart';
import '../services/sqlite_service.dart';

class IncidentHistoryScreen extends StatefulWidget {
  const IncidentHistoryScreen({super.key});

  @override
  State<IncidentHistoryScreen> createState() => _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends State<IncidentHistoryScreen> {
  List<Map<String, dynamic>> _incidents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    final data = await SQLiteService.getIncidents();
    setState(() {
      _incidents = data;
      _loading = false;
    });
  }

  String _formatTime(String t) {
    final dt = DateTime.parse(t);
    return "${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2,'0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Incident History"),
        actions: [
          IconButton(
            onPressed: _loadIncidents,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          )
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _incidents.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text("No incidents recorded yet",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _incidents.length,
                  padding: const EdgeInsets.all(10),
                  itemBuilder: (_, i) {
                    final item = _incidents[i];
                    final bool isSOS = item["emergency"] == 1;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isSOS ? Colors.red.shade100 : Colors.blue.shade100,
                          child: Icon(
                            isSOS ? Icons.warning : Icons.note,
                            color: isSOS ? Colors.red : Colors.blue,
                          ),
                        ),

                        title: Text(item["message"] ?? ""),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_formatTime(item["time"])),

                            if (item["location"] != null &&
                                item["location"].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 16, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text(item["location"],
                                        style:
                                            const TextStyle(color: Colors.green)),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        trailing: isSOS
                            ? const Chip(
                                label: Text("SOS",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 11)),
                                backgroundColor: Colors.red,
                              )
                            : const Chip(
                                label: Text("Manual",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 11)),
                                backgroundColor: Colors.blue,
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
