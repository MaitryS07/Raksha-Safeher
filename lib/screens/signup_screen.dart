import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/otp_service.dart';
import '../services/sos_api.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _email = TextEditingController();
  final _user = TextEditingController();
  final _phone = TextEditingController();
  final _pin = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _otp = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _showOTP = false;
  bool _loading = false;
  bool _verifyLoading = false;

  bool _hidePass = true;
  bool _hideConfirm = true;
  bool _hidePin = true;

  // --------------------------------------------------
  // UTIL: FORMAT PHONE (Twilio requires E.164)
  // --------------------------------------------------
  String _formatPhone(String phone) {
    phone = phone.trim();
    if (phone.startsWith("+")) return phone;
    return "+91$phone"; // India default
  }

  // --------------------------------------------------
  InputDecoration _darkField(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white10,
      prefixIcon: Icon(icon, color: Colors.white70),
      suffixIcon: suffix,
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white38),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
    );
  }

  String? _req(String? v, String name) =>
      (v == null || v.isEmpty) ? "Enter $name" : null;

  @override
  void dispose() {
    _email.dispose();
    _user.dispose();
    _phone.dispose();
    _pin.dispose();
    _pass.dispose();
    _confirm.dispose();
    _otp.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // SEND OTP
  // --------------------------------------------------
  Future<void> _requestOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final phone = _formatPhone(_phone.text);
    final otpService = OTPService();

    final ok = await otpService.sendOTP(phone);

    setState(() => _loading = false);

    if (!ok) {
      Utils.showSnackBar(context, "Failed to send OTP");
      return;
    }

    Utils.showSnackBar(context, "OTP sent to $phone");
    setState(() => _showOTP = true);
  }

  // --------------------------------------------------
  // VERIFY OTP + SIGNUP
  // --------------------------------------------------
  Future<void> _verifyAndSignup() async {
    if (_otp.text.trim().length != 6) {
      Utils.showSnackBar(context, "Enter valid 6-digit OTP");
      return;
    }

    setState(() => _verifyLoading = true);

    final otpService = OTPService();
    final valid = await otpService.verifyOTP(_otp.text.trim());

    if (!valid) {
      setState(() => _verifyLoading = false);
      Utils.showSnackBar(context, "Invalid or expired OTP");
      return;
    }

    final auth = AuthService();
    final userService = UserService();

    final phone = _formatPhone(_phone.text);

    final signed = await auth.signupWithEmail(
      _email.text.trim(),
      _pass.text,
      username: _user.text.trim(),
      phone: phone,
      safetyPin: _pin.text,
    );

    setState(() => _verifyLoading = false);

    if (!signed) {
      Utils.showSnackBar(context, "Signup failed");
      return;
    }

    // 🔔 Register user with SOS backend
    await SosApi.signup(phone, _pin.text);

    // Save local profile
    userService.updateUser(
      name: _user.text.trim(),
      age: 0,
      phone: phone,
      email: _email.text.trim(),
      username: _user.text.trim(),
      bloodGroup: "",
      address: "",
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  // --------------------------------------------------
  // OTP SCREEN
  // --------------------------------------------------
  Widget _otpScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Verify OTP",
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _otp,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
                maxLength: 6,
                decoration: _darkField("Enter OTP", Icons.key),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _verifyLoading ? null : _verifyAndSignup,
                child: _verifyLoading
                    ? const CircularProgressIndicator()
                    : const Text("Verify & Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // SIGNUP FORM
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_showOTP) return _otpScreen();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Icon(Icons.shield,
                      size: 80, color: AppConstants.primaryColor),
                  const SizedBox(height: 25),

                  TextFormField(
                    controller: _email,
                    style: const TextStyle(color: Colors.white),
                    decoration: _darkField("Email", Icons.email),
                    validator: (v) => _req(v, "email"),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _user,
                    style: const TextStyle(color: Colors.white),
                    decoration: _darkField("Username", Icons.person),
                    validator: (v) => _req(v, "username"),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: _darkField("Phone Number", Icons.phone),
                    validator: (v) => _req(v, "phone"),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _pin,
                    keyboardType: TextInputType.number,
                    obscureText: _hidePin,
                    style: const TextStyle(color: Colors.white),
                    decoration: _darkField(
                      "Safety PIN (4 digits)",
                      Icons.pin,
                      suffix: IconButton(
                        icon: Icon(
                          _hidePin ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () =>
                            setState(() => _hidePin = !_hidePin),
                      ),
                    ),
                    validator: (v) =>
                        v != null && v.length == 4 ? null : "Enter 4-digit PIN",
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _pass,
                    obscureText: _hidePass,
                    style: const TextStyle(color: Colors.white),
                    decoration: _darkField(
                      "Password",
                      Icons.lock,
                      suffix: IconButton(
                        icon: Icon(
                          _hidePass ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () =>
                            setState(() => _hidePass = !_hidePass),
                      ),
                    ),
                    validator: (v) =>
                        v != null && v.length >= 6 ? null : "Min 6 characters",
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _confirm,
                    obscureText: _hideConfirm,
                    style: const TextStyle(color: Colors.white),
                    decoration: _darkField(
                      "Confirm Password",
                      Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(
                          _hideConfirm
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () =>
                            setState(() => _hideConfirm = !_hideConfirm),
                      ),
                    ),
                    validator: (v) =>
                        v == _pass.text ? null : "Passwords do not match",
                  ),

                  const SizedBox(height: 22),

                  ElevatedButton(
                    onPressed: _loading ? null : _requestOTP,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text("Send OTP"),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text("Already have an account? Login"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
