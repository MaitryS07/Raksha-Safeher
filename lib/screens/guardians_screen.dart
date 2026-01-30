import 'package:flutter/material.dart';
import '../models/guardian_model.dart';
import '../widgets/guardian_card.dart';
import '../services/guardian_service.dart';
import '../core/utils.dart';

// IMPORTANT: Use the correct import for the file containing class ApiService
// If your file is named api_service.dart → keep this
// If it's sos_api.dart → change to: import '../services/sos_api.dart';
import '../services/api_service.dart';

class GuardiansScreen extends StatefulWidget {
  const GuardiansScreen({super.key});

  @override
  State<GuardiansScreen> createState() => _GuardiansScreenState();
}

class _GuardiansScreenState extends State<GuardiansScreen> {
  final GuardianService _guardianService = GuardianService();

  final nameC = TextEditingController();
  final ageC = TextEditingController();
  final relationC = TextEditingController();
  final phoneC = TextEditingController();

  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  // =====================================================
  // 🇮🇳 NORMALIZE INDIAN PHONE NUMBER (+91 FIX)
  // =====================================================
  String normalizeIndianPhone(String input) {
    String phone = input.trim().replaceAll(" ", "");
    // Already with +91
    if (phone.startsWith("+91") && RegExp(r'^\+91[6-9]\d{9}$').hasMatch(phone)) {
      return phone;
    }
    // Plain 10-digit Indian number
    if (RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      return "+91$phone";
    }
    throw Exception("Invalid Indian phone number");
  }

  // =====================================================
  // ⭐ SYNC ALL CURRENT GUARDIANS TO BACKEND
  // =====================================================
  Future<bool> _syncGuardiansToBackend() async {
    final phones = _guardianService
        .getGuardians()
        .map((g) => g.phone.trim())
        .toList();

    print("DEBUG: Syncing ${phones.length} guardians to backend: $phones");

    if (phones.isEmpty) return true;

    bool allSuccess = true;

    for (final phone in phones) {
      final result = await ApiService.addGuardian(phone);
      if (result["success"] != true) {
        print("DEBUG: Failed to sync guardian $phone → ${result["error"] ?? result["response"]}");
        allSuccess = false;
      }
    }

    return allSuccess;
  }

  // =====================================================
  // ➕ ADD GUARDIAN
  // =====================================================
  Future<void> addGuardian() async {
    if (nameC.text.trim().isEmpty || phoneC.text.trim().isEmpty) {
      Utils.showSnackBar(context, "Name and phone are required");
      return;
    }

    String formattedPhone;
    try {
      formattedPhone = normalizeIndianPhone(phoneC.text);
    } catch (_) {
      Utils.showSnackBar(context, "Enter valid Indian phone number (10 digits)");
      return;
    }

    final newGuardian = Guardian(
      name: nameC.text.trim(),
      age: int.tryParse(ageC.text) ?? 0,
      relation: relationC.text.trim().isEmpty ? "Guardian" : relationC.text.trim(),
      phone: formattedPhone,
    );

    // 1. Add locally
    _guardianService.addGuardian(newGuardian);

    // 2. Sync to backend
    final result = await ApiService.addGuardian(formattedPhone);

    setState(() {});

    if (result["success"] == true) {
      Utils.showSnackBar(context, "Guardian added and synced successfully");
      print("SUCCESS: Guardian $formattedPhone added to backend");
    } else {
      Utils.showSnackBar(
        context,
        "Added locally, but sync failed: ${result["error"] ?? 'Unknown error'}",
      );
      print("ERROR: Failed to add $formattedPhone to backend → ${result["error"]}");
    }

    nameC.clear();
    ageC.clear();
    relationC.clear();
    phoneC.clear();
  }

  // =====================================================
  // 🗑 DELETE GUARDIAN
  // =====================================================
  Future<void> deleteGuardian(int index) async {
    setState(() {
      _guardianService.removeGuardianAt(index);
    });

    final success = await _syncGuardiansToBackend();

    Utils.showSnackBar(
      context,
      success ? "Guardian removed & server updated" : "Removed locally, but server sync failed",
    );

    if (!success) {
      print("WARNING: Delete sync failed – some guardians may still be on server");
    }
  }

  @override
  void dispose() {
    nameC.dispose();
    ageC.dispose();
    relationC.dispose();
    phoneC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guardians = _guardianService.getGuardians();

    return Scaffold(
      appBar: AppBar(title: const Text("Guardians")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameC,
              decoration: const InputDecoration(
                labelText: "Name *",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ageC,
              decoration: const InputDecoration(
                labelText: "Age",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relationC,
              decoration: const InputDecoration(
                labelText: "Relation",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.family_restroom),
                hintText: "e.g., Mother, Father, Friend",
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneC,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: "Phone Number *",
                hintText: "10 digit Indian number",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                prefixText: "+91 ",
                counterText: "",
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: addGuardian,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Add Guardian"),
              ),
            ),
            const Divider(),
            Expanded(
              child: guardians.isEmpty
                  ? const Center(
                      child: Text(
                        "No guardians added yet.\nAdd guardians to receive emergency alerts.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: guardians.length,
                      itemBuilder: (c, i) => GuardianCard(
                        guardian: guardians[i],
                        onDelete: () => deleteGuardian(i),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}