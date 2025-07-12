import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:mobile_app/constants.dart' as config;

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final memberIdController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final newPinController = TextEditingController();
  final confirmPinController = TextEditingController();
  bool? isPinMatched;

  @override
  void dispose() {
    memberIdController.dispose();
    phoneController.dispose();
    otpController.dispose();
    newPinController.dispose();
    confirmPinController.dispose();
    super.dispose();
  }

  Future<void> submitChangePin() async {
    if (newPinController.text != confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("รหัส PIN ไม่ตรงกัน")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${config.apiUrl}/change-pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_user': memberIdController.text,
          'otp': otpController.text,
          'new_pin': newPinController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF2979FF), size: 60),
                const SizedBox(height: 20),
                const Text(
                  "สำเร็จ!",
                  style: TextStyle(
                    color: Color(0xFF2979FF),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "เปลี่ยนรหัส PIN เสร็จสิ้น",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );

        await Future.delayed(const Duration(seconds: 3));
        if (context.mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        }

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "เกิดข้อผิดพลาด")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เชื่อมต่อ API ไม่สำเร็จ")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FE),
      body: Column(
        children: [
          const CustomAppBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PhoneAndOtpForm(
                        memberIdController: memberIdController,
                        phoneController: phoneController,
                        otpController: otpController,
                      ),
                      const SizedBox(height: 20),
                      PinForm(
                        newPinController: newPinController,
                        confirmPinController: confirmPinController,
                        onMatchChanged: (matched) {
                          setState(() {
                            isPinMatched = matched;
                          });
                        },
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isPinMatched == true ? submitChangePin : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPinMatched == true ? const Color(0xFF2979FF) : Colors.grey,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text(
                            "บันทึกรหัสใหม่",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF2979FF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 10),
          const Text(
            "เปลี่ยนรหัส PIN",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class PhoneAndOtpForm extends StatefulWidget {
  final TextEditingController memberIdController;
  final TextEditingController phoneController;
  final TextEditingController otpController;

  const PhoneAndOtpForm({
    super.key,
    required this.memberIdController,
    required this.phoneController,
    required this.otpController,
  });

  @override
  State<PhoneAndOtpForm> createState() => _PhoneAndOtpFormState();
}
class _PhoneAndOtpFormState extends State<PhoneAndOtpForm> {
  int countdown = 0;
  Timer? timer;
  bool? isMemberFound;
  Color getBorderColor() {
    if (isMemberFound == null) return Colors.grey;
    return isMemberFound! ? Colors.green : Colors.red;
  }
  bool? isOtpCorrect;

  Color getOtpBorderColor() {
    if (isOtpCorrect == null) return Colors.grey;
    return isOtpCorrect! ? Colors.green : Colors.red;
  }

  Future<void> checkMemberId(String id) async {
    try {
      final url = Uri.parse('${config.apiUrl}/check-id');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_user': id}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          isMemberFound = data['found'] == true;
        });
      } else {
        setState(() {
          isMemberFound = false;
        });
      }
    } catch (e) {
      setState(() {
        isMemberFound = false;
      });
    }
  }

  void startCountdown() {
    setState(() {
      countdown = 30;
    });

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (countdown == 0) {
        t.cancel();
      } else {
        setState(() {
          countdown--;
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("รหัสสมาชิก", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: widget.memberIdController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly
          ],
          onChanged: (value) {
            if (value.isNotEmpty) {
              checkMemberId(value);
            } else {
              setState(() {
                isMemberFound = null;
              });
            }
          },
          decoration: InputDecoration(
            hintText: "กรอกรหัสสมาชิก",
            prefixIcon: const Icon(Icons.badge, color: Color(0xFF2979FF)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: getBorderColor()),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: getBorderColor(), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text("เบอร์โทรศัพท์", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: widget.phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            hintText: "กรอกเบอร์โทร",
            prefixIcon: const Icon(Icons.phone, color: Color(0xFF2979FF)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 20),
        const Text("รหัส OTP", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.otpController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                onChanged: (value) {
                  setState(() {
                    if (value.length == 5) {
                      isOtpCorrect = value == '12345';
                    } else {
                      isOtpCorrect = null;
                    }
                  });
                },
                decoration: InputDecoration(
                  hintText: "รหัส OTP",
                  prefixIcon: const Icon(Icons.lock_open, color: Color(0xFF2979FF)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: getOtpBorderColor()),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: getOtpBorderColor(), width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: countdown == 0
                  ? () {
                startCountdown();
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2979FF),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                countdown == 0 ? "ขอ OTP" : "$countdown วิ",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PinForm extends StatefulWidget {
  final TextEditingController newPinController;
  final TextEditingController confirmPinController;
  final Function(bool) onMatchChanged;

  const PinForm({
    super.key,
    required this.newPinController,
    required this.confirmPinController,
    required this.onMatchChanged,
  });

  @override
  State<PinForm> createState() => _PinFormState();
}

class _PinFormState extends State<PinForm> {
  bool? isMatched;

  void checkPinMatch() {
    final newPin = widget.newPinController.text;
    final confirmPin = widget.confirmPinController.text;

    if (confirmPin.length == 6) {
      final matched = newPin == confirmPin;
      setState(() {
        isMatched = matched;
      });
      widget.onMatchChanged(matched);
    } else {
      setState(() {
        isMatched = null;
      });
      widget.onMatchChanged(false);
    }
  }

  Color getColor() {
    if (isMatched == null) return Colors.grey;
    return isMatched! ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ตั้งรหัส PIN ใหม่", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        PinCodeTextField(
          appContext: context,
          length: 6,
          controller: widget.newPinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          animationType: AnimationType.fade,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(10),
            fieldHeight: 50,
            fieldWidth: 40,
            activeColor: getColor(),
            inactiveColor: getColor(),
            selectedColor: getColor(),
          ),
          onChanged: (_) {
            checkPinMatch(); // ให้ตรวจทุกครั้งที่แก้ PIN ช่องแรกด้วย
          },
        ),

        const SizedBox(height: 20),
        const Text("ยืนยันรหัส PIN ใหม่", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        PinCodeTextField(
          appContext: context,
          length: 6,
          controller: widget.confirmPinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          animationType: AnimationType.fade,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(10),
            fieldHeight: 50,
            fieldWidth: 40,
            activeColor: getColor(),
            inactiveColor: getColor(),
            selectedColor: getColor(),
          ),
          onChanged: (_) {
            checkPinMatch();
          },
        ),
        if (isMatched == false)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              "รหัสไม่ตรงกัน",
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }
}
