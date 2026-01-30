import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../core/utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isEditing = false;
  bool _isEmailLogin = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final UserModel? user = _userService.getCurrentUser();
    final userEmail = _authService.getCurrentUserEmail();
    final userPhone = _authService.getCurrentUserPhone();
    final username = _authService.getCurrentUsername();
    
    // Check if user logged in with email
    _isEmailLogin = userEmail != null && userEmail.isNotEmpty;
    
    if (user != null) {
      _nameController.text = user.name;
      _ageController.text = user.age.toString();
      _phoneController.text = user.phone;
      _emailController.text = user.email;
      _usernameController.text = user.username;
      _bloodGroupController.text = user.bloodGroup;
      _addressController.text = user.address;
    } else {
      // Initialize with default values or auth service data
      final currentUserId = _authService.getCurrentUserId();
      _nameController.text = username ?? "User Name";
      _ageController.text = "21";
      
      // If logged in with email, show email; otherwise show phone
      if (_isEmailLogin && userEmail != null) {
        _emailController.text = userEmail;
        _phoneController.text = userPhone ?? "";
      } else {
        _phoneController.text = currentUserId ?? "";
        _emailController.text = "";
      }
      
      _usernameController.text = username ?? "";
      _bloodGroupController.text = "O+";
      _addressController.text = "Maharashtra, India";
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Age is optional
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid age';
    }
    if (age < 1 || age > 150) {
      return 'Please enter a valid age (1-150)';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final trimmedValue = value?.trim() ?? "";
    
    // Phone is required for non-email logins, optional for email logins
    if (!_isEmailLogin) {
      // Required for phone-based logins
      if (trimmedValue.isEmpty) {
        return 'Phone number is required';
      }
    }
    
    // Validate format if value is provided
    if (trimmedValue.isNotEmpty) {
      final cleaned = trimmedValue.replaceAll(RegExp(r'[^\d]'), '');
      if (cleaned.length < 10) {
        return 'Please enter a valid 10-digit phone number';
      }
    }
    
    return null;
  }

  String? _validateBloodGroup(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Blood group is optional
    }
    final validGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    if (!validGroups.contains(value.trim().toUpperCase())) {
      return 'Please enter a valid blood group (e.g., O+, A-)';
    }
    return null;
  }

  void _saveProfile() {
    // Validate all fields
    final nameError = _validateName(_nameController.text);
    final ageError = _validateAge(_ageController.text);
    final phoneError = _validatePhone(_phoneController.text);
    final bloodGroupError = _validateBloodGroup(_bloodGroupController.text);

    if (nameError != null || ageError != null || phoneError != null || bloodGroupError != null) {
      String errorMessage = '';
      if (nameError != null) errorMessage += nameError + '\n';
      if (ageError != null) errorMessage += ageError + '\n';
      if (phoneError != null) errorMessage += phoneError + '\n';
      if (bloodGroupError != null) errorMessage += bloodGroupError + '\n';
      
      Utils.showSnackBar(context, errorMessage.trim());
      return;
    }

    final age = int.tryParse(_ageController.text) ?? 0;
    final cleanedPhone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    
    _userService.updateUser(
      name: _nameController.text.trim(),
      age: age,
      phone: cleanedPhone,
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      bloodGroup: _bloodGroupController.text.trim().toUpperCase(),
      address: _addressController.text.trim(),
    );
    setState(() => _isEditing = false);
    Utils.showSnackBar(context, "Profile updated successfully");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _bloodGroupController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.purple,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            enabled: _isEditing,
            decoration: InputDecoration(
              labelText: "Name *",
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person),
              errorText: _isEditing ? _validateName(_nameController.text) : null,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ageController,
            enabled: _isEditing,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Age",
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.calendar_today),
              errorText: _isEditing ? _validateAge(_ageController.text) : null,
            ),
          ),
          const SizedBox(height: 16),
          // Show email field if logged in with email, otherwise show phone
          if (_isEmailLogin) ...[
            TextField(
              controller: _emailController,
              enabled: false, // Email is not editable (comes from login)
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
                helperText: "Email cannot be changed",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Phone Number",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone),
                hintText: "10 digit phone number",
                errorText: _isEditing ? _validatePhone(_phoneController.text) : null,
              ),
              maxLength: 10,
            ),
          ] else ...[
            TextField(
              controller: _phoneController,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Phone Number *",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone),
                hintText: "10 digit phone number",
                errorText: _isEditing ? _validatePhone(_phoneController.text) : null,
              ),
              maxLength: 10,
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            enabled: _isEditing,
            decoration: InputDecoration(
              labelText: "Username",
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person_outline),
              hintText: "Enter your username",
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bloodGroupController,
            enabled: _isEditing,
            decoration: InputDecoration(
              labelText: "Blood Group",
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.bloodtype),
              hintText: "e.g., O+, A-",
              errorText: _isEditing ? _validateBloodGroup(_bloodGroupController.text) : null,
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            enabled: _isEditing,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: "Address",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
              hintText: "Enter your address",
            ),
            textCapitalization: TextCapitalization.words,
          ),
          if (_isEditing) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                child: const Text("Save Changes"),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _isEditing = false);
                  _loadUserData(); // Reload to discard changes
                },
                child: const Text("Cancel"),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
