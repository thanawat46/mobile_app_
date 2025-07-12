import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Home/HomePage.dart';
import 'ResetPin.dart';
import 'package:mobile_app/constants.dart' as config ;

class PinPage extends StatefulWidget {
  final bool isThai;
  final String idUser;

  const PinPage({super.key, required this.isThai, required this.idUser});

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  String pin = '';
  String newPin = '';
  String confirmPin = '';
  bool hasPin = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkHasPin();
  }

  Future<void> checkHasPin() async {
    final url = Uri.parse('${config.apiUrl}/check-has-pin');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_user': widget.idUser}),
    );

    final result = jsonDecode(response.body);
    setState(() {
      hasPin = result['hasPin'];
      isLoading = false;
    });
  }

  void onKeyboardTap(String value) {
    setState(() {
      if (!hasPin) {
        if (newPin.length < 6) {
          newPin += value;
        } else if (confirmPin.length < 6) {
          confirmPin += value;
          if (confirmPin.length == 6) {
            if (newPin == confirmPin) {
              savePin(newPin);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("PIN ไม่ตรงกัน")),
              );
              newPin = '';
              confirmPin = '';
            }
          }
        }
      } else {
        if (pin.length < 6) {
          pin += value;
          if (pin.length == 6) {
            checkPin();
          }
        }
      }
    });
  }

  void deletePin() {
    setState(() {
      if (!hasPin) {
        if (confirmPin.isNotEmpty) {
          confirmPin = confirmPin.substring(0, confirmPin.length - 1);
        } else if (newPin.isNotEmpty) {
          newPin = newPin.substring(0, newPin.length - 1);
        }
      } else {
        if (pin.isNotEmpty) {
          pin = pin.substring(0, pin.length - 1);
        }
      }
    });
  }

  void clearPin() {
    setState(() {
      pin = '';
    });
  }

  Future<void> checkPin() async {
    final url = Uri.parse('${config.apiUrl}/check-pin');

    // ✅ แสดง dialog loading ทันที
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(color: Color(0xFF0069FF)),
                ),
                SizedBox(height: 16),
                Text(
                  "กำลังตรวจสอบ...",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_user': widget.idUser, 'pin': pin}),
      );

      final result = jsonDecode(response.body);

      // ✅ ปิด loading ก่อนทุกกรณี
      if (mounted) Navigator.pop(context);

      if (result['success']) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(idUser: widget.idUser),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PIN ไม่ถูกต้อง")),
        );
        clearPin();
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เกิดข้อผิดพลาด")),
      );
    }
  }


  Future<void> savePin(String pinToSave) async {
    final url = Uri.parse('${config.apiUrl}/add-pin');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_user': widget.idUser, 'pin_user': pinToSave})
    );

    final result = jsonDecode(response.body);
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ตั้ง PIN สำเร็จ")),
      );
      setState(() {
        hasPin = true;
        pin = '';
        newPin = '';
        confirmPin = '';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("บันทึก PIN ไม่สำเร็จ")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F9),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              backgroundColor: Colors.white,
              radius: 40,
              child: Icon(Icons.lock, color: Color(0xFF1565C0), size: 42),
            ),
            const SizedBox(height: 25),
            Text(
              hasPin
                  ? (widget.isThai ? 'กรุณาใส่รหัสผ่าน' : 'Enter PIN Code')
                  : (newPin.length < 6
                  ? (widget.isThai ? 'ตั้งรหัส PIN ใหม่' : 'Set New PIN')
                  : (widget.isThai ? 'ยืนยันรหัส PIN' : 'Confirm PIN')),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                6,
                    (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (hasPin
                        ? index < pin.length
                        : (newPin.length < 6
                        ? index < newPin.length
                        : index < confirmPin.length))
                        ? const Color(0xFF0D47A1)
                        : Colors.white,
                    border: Border.all(color: const Color(0xFF0D47A1), width: 2),
                    boxShadow: (hasPin
                        ? index < pin.length
                        : (newPin.length < 6
                        ? index < newPin.length
                        : index < confirmPin.length))
                        ? [
                      const BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2))
                    ]
                        : [],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: buildKeyboard(),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChangePinScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  widget.isThai ? 'ลืมรหัสผ่าน?' : 'Forgot password?',
                  style: const TextStyle(
                    color: Color(0xFF0D47A1),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildKeyboard() {
    List<String> keys = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '', '0', '<'
    ];
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 30,
        crossAxisSpacing: 30,
      ),
      itemBuilder: (context, index) {
        String key = keys[index];
        if (key == '') {
          return const SizedBox.shrink();
        } else if (key == '<') {
          return buildButton(
            icon: Icons.backspace_outlined,
            onTap: deletePin,
          );
        } else {
          return buildButton(
            text: key,
            onTap: () => onKeyboardTap(key),
          );
        }
      },
    );
  }

  Widget buildButton(
      {String? text, IconData? icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: text != null
              ? Text(
            text,
            style: const TextStyle(
              fontSize: 28,
              color: Color(0xFF0D47A1),
              fontWeight: FontWeight.bold,
            ),
          )
              : Icon(icon, color: const Color(0xFF0D47A1), size: 32),
        ),
      ),
    );
  }
}
