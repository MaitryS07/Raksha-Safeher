import 'package:flutter/material.dart';
import '../models/guardian_model.dart';

class GuardianCard extends StatelessWidget {
  final Guardian guardian;
  final VoidCallback onDelete;

  const GuardianCard({super.key, required this.guardian, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person),
        title: Text(guardian.name),
        subtitle: Text("${guardian.relation} | ${guardian.phone}"),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
