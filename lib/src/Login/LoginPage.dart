import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pin_code_fields/pin_code_fields.dart';
import '../PIN/PinPage.dart';
import 'ResetPhone.dart';
import 'package:mobile_app/constants.dart' as config;

void main() {
  runApp(const MyApp());
}

Map<String, Map<String, String>> errorMessages = {
  'userNotFound': {
    'th': 'ไม่พบรหัสสมาชิก',
    'en': 'Member ID not found',
  },
  'addPhoneFailed': {
    'th': 'เพิ่มเบอร์โทรไม่สำเร็จ',
    'en': 'Failed to add phone number',
  },
  'phoneNotMatch': {
    'th': 'เบอร์โทรไม่ตรงกับข้อมูลในระบบ',
    'en': 'Phone number does not match',
  },
  'serverError': {
    'th': 'เชื่อมต่อ server ไม่สำเร็จ',
    'en': 'Failed to connect to server',
  },
  'otpIncorrect': {
    'th': 'รหัส OTP ไม่ถูกต้อง',
    'en': 'Incorrect OTP',
  },
};

String getErrorMessage(String key, bool isThai) {
  return errorMessages[key]?[isThai ? 'th' : 'en'] ?? 'Unknown Error';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: const LoginPage());
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isThai = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Colors.white],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const LogoSection(),
                    const SizedBox(height: 40),
                    LoginForm(
                      isThai: isThai,
                      onLoginPressed: (idUser) {
                        showDialog(
                          context: context,
                          builder: (context) => OTPDialog(isThai: isThai, idUser: idUser),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: TextButton(
                onPressed: () => setState(() => isThai = !isThai),
                child: Text(isThai ? 'EN' : 'TH',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LogoSection extends StatelessWidget {
  const LogoSection({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 150, height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: ClipOval(
            child: Image.asset('asset/imge/img.png', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 10),
        const Text('Login',
          style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class LoginForm extends StatefulWidget {
  final bool isThai;
  final Function(String idUser) onLoginPressed;

  const LoginForm({super.key, required this.isThai, required this.onLoginPressed});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final idController = TextEditingController();
  final phoneController = TextEditingController();
  bool isLoading = false;

  Future<void> checkLogin() async {
    final idUser = idController.text.trim();
    final phoneNumber = phoneController.text.trim();

    setState(() => isLoading = true);

    try {
      final idResponse = await http.post(
        Uri.parse('${config.apiUrl}/check-id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_user': idUser}),
      );

      if (idResponse.statusCode != 200) throw Exception('Server error');
      final idData = jsonDecode(idResponse.body);

      if (!idData['found']) {
        await showErrorDialog(context, getErrorMessage('userNotFound', widget.isThai), isThai: widget.isThai);
        return;
      }

      final existingPhone = idData['user']['phone_number'];

      if (existingPhone == null || existingPhone.isEmpty) {
        final addPhoneResponse = await http.post(
          Uri.parse('${config.apiUrl}/add-phone'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id_user': idUser, 'phone_number': phoneNumber}),
        );

        final addPhoneData = jsonDecode(addPhoneResponse.body);

        if (addPhoneResponse.statusCode != 200 || !addPhoneData['success']) {
          await showErrorDialog(context, getErrorMessage('addPhoneFailed', widget.isThai), isThai: widget.isThai);
          return;
        }
      } else {
        if (existingPhone != phoneNumber) {
          await showErrorDialog(context, getErrorMessage('phoneNotMatch', widget.isThai), isThai: widget.isThai);
          return;
        }
      }
      widget.onLoginPressed(idUser);
    } catch (e) {
      await showErrorDialog(context, getErrorMessage('serverError', widget.isThai), isThai: widget.isThai);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          TextField(
            controller: idController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person, color: Color(0xFF0D47A1)),
              labelText: widget.isThai ? 'รหัสสมาชิก' : 'Member ID',
              labelStyle: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.w600),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.call, color: Color(0xFF0D47A1)),
              labelText: widget.isThai ? 'เบอร์โทร' : 'Phone',
              labelStyle: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.w600),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: isLoading ? null : checkLogin,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(widget.isThai ? 'เข้าสู่ระบบ' : 'Login',
                  style: const TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 15),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangePasswordPage(isThai: widget.isThai)),
              );
            },
            child: Text(
              widget.isThai ? 'เปลี่ยนเบอร์โทร' : 'Change Phone',
              style: const TextStyle(color: Color(0xFF0D47A1)),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showErrorDialog(BuildContext context, String message, {bool isThai = true}) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFFE3F2FD),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 30),
          const SizedBox(width: 10),
          Text(isThai ? 'ข้อผิดพลาด' : 'Error',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0D47A1))),
        ],
      ),
      content: Text(message, style: const TextStyle(fontSize: 16)),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(isThai ? 'ตกลง' : 'OK',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.white)),
        ),
      ],
    ),
  );
}

class OTPDialog extends StatefulWidget {
  final bool isThai;
  final String idUser;

  const OTPDialog({super.key, required this.isThai, required this.idUser});
  @override
  State<OTPDialog> createState() => _OTPDialogState();
}

class _OTPDialogState extends State<OTPDialog> {
  String otp = '';
  int countdown = 0;
  Timer? timer;

  static const correctOtp = '123456';

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startCountdown() {
    setState(() => countdown = 30);
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (countdown == 0) {
        t.cancel();
      } else {
        setState(() => countdown--);
      }
    });
  }

  void checkOtp() async {
    if (otp.length != 6) {
      await showErrorDialog(context, widget.isThai ? "กรุณาใส่รหัสให้ครบ 6 หลัก" : "Please enter 6 digits");
      return;
    }

    if (otp == correctOtp) {
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PinPage(isThai: widget.isThai, idUser: widget.idUser),
        ),
      );
    } else {
      await showErrorDialog(context, getErrorMessage('otpIncorrect', widget.isThai), isThai: widget.isThai);
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFE3F2FD),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.isThai ? 'กรุณาใส่รหัส OTP' : 'Enter OTP',
          style: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 70,
            child: PinCodeTextField(
              appContext: context,
              length: 6,
              autoFocus: true,
              keyboardType: TextInputType.number,
              onChanged: (value) => otp = value,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 45,
                fieldWidth: 32,
                activeFillColor: Colors.white,
                selectedFillColor: Colors.white,
                inactiveFillColor: Colors.white,
                activeColor: Colors.blue,
                selectedColor: Colors.blueAccent,
                inactiveColor: Colors.grey,
                fieldOuterPadding: const EdgeInsets.symmetric(horizontal: 2),
              ),
              enableActiveFill: true,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: countdown == 0 ? startCountdown : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: countdown == 0 ? const Color(0xFF0D47A1) : Colors.grey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              countdown == 0
                  ? (widget.isThai ? 'ส่ง OTP อีกครั้ง' : 'Resend OTP')
                  : '${widget.isThai ? "ขอ OTP ใหม่ได้ใน" : "Resend in"} $countdown s',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
            ),
          ),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(widget.isThai ? 'ยกเลิก' : 'Cancel',
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 16)),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: checkOtp,
              child: Text(widget.isThai ? 'ยืนยัน' : 'Confirm',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16)),
            ),
          ],
        ),
      ],
    );
  }
}