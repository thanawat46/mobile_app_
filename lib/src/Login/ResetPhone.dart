import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:mobile_app/constants.dart' as config;

class ChangePasswordPage extends StatefulWidget {
  final bool isThai;
  const ChangePasswordPage({super.key, required this.isThai});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController memberIdController = TextEditingController();
  final TextEditingController phoneEmailController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  Color memberIdBorderColor = Colors.grey;

  Future<void> checkMemberId() async {
    if (memberIdController.text.isEmpty) return;
    final response = await http.post(
      Uri.parse('${config.apiUrl}/check-id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_user': memberIdController.text}),
    );

    final data = jsonDecode(response.body);
    setState(() {
      if (data['found'] == true) {
        memberIdBorderColor = Colors.green;
      } else {
        memberIdBorderColor = Colors.red;
      }
    });
  }

  int countdown = 0;
  Timer? timer;

  void startCountdown() {
    setState(() {
      countdown = 30;
    });

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          widget.isThai ? "เปลี่ยนเบอร์โทร" : "Change Phone",
          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.shade300, blurRadius: 10, spreadRadius: 2)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhoneEmailInput(
                  phoneController: phoneEmailController,
                  memberIdController: memberIdController,
                  checkMemberId: checkMemberId,
                  memberIdBorderColor: memberIdBorderColor,
                  countdown: countdown,
                  startCountdown: startCountdown,
                  isThai: widget.isThai,
                ),
                const SizedBox(height: 20),
                OtpInput(isThai: widget.isThai),
                const SizedBox(height: 20),
                NewPasswordInput(
                  newPasswordController: newPasswordController,
                  confirmPasswordController: confirmPasswordController,
                  memberId: memberIdController.text,
                  isThai: widget.isThai,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ======================== ปรับแต่ละส่วนด้านล่าง ============================

class PhoneEmailInput extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController memberIdController;
  final Function checkMemberId;
  final Color memberIdBorderColor;
  final int countdown;
  final VoidCallback startCountdown;
  final bool isThai;

  const PhoneEmailInput({
    super.key,
    required this.phoneController,
    required this.memberIdController,
    required this.checkMemberId,
    required this.memberIdBorderColor,
    required this.countdown,
    required this.startCountdown,
    required this.isThai,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(isThai ? "กรุณากรอกรหัสสมาชิก" : "Enter Member ID"),
        const SizedBox(height: 10),
        TextField(
          controller: memberIdController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.perm_identity),
            hintText: isThai ? "รหัสสมาชิก" : "Member ID",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: memberIdBorderColor, width: 2),
            ),
          ),
          onSubmitted: (_) => checkMemberId(),
        ),
        const SizedBox(height: 20),
        Text(isThai ? "กรุณากรอกเบอร์โทรศัพท์" : "Enter Phone Number"),
        const SizedBox(height: 10),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.phone_android),
            hintText: isThai ? "เบอร์โทรศัพท์" : "Phone Number",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: (countdown == 0) ? startCountdown : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size.fromHeight(50),
          ),
          child: (countdown == 0)
              ? Text(isThai ? "ส่งรหัส OTP" : "Send OTP", style: const TextStyle(fontSize: 16, color: Colors.white))
              : Text("${isThai ? "ส่งอีกใน" : "Resend in"} $countdown s", style: const TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ],
    );
  }
}

class OtpInput extends StatefulWidget {
  final bool isThai;
  const OtpInput({super.key, required this.isThai});

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final TextEditingController otpController = TextEditingController();
  final String correctOTP = '12345';
  Color fieldColor = Colors.grey;
  bool isOtpVerified = false;

  void verifyOTP() {
    if (otpController.text == correctOTP) {
      setState(() {
        fieldColor = Colors.green;
        isOtpVerified = true;
      });
    } else {
      setState(() {
        fieldColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.isThai ? "กรอกรหัส OTP" : "Enter OTP"),
        const SizedBox(height: 20),
        PinCodeTextField(
          appContext: context,
          controller: otpController,
          length: 5,
          obscureText: false,
          animationType: AnimationType.fade,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(8),
            fieldHeight: 60,
            fieldWidth: 50,
            activeColor: fieldColor,
            selectedColor: fieldColor,
            inactiveColor: fieldColor,
          ),
          keyboardType: TextInputType.number,
          animationDuration: const Duration(milliseconds: 300),
          enableActiveFill: false,
          onChanged: (value) {},
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: isOtpVerified ? null : verifyOTP,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size.fromHeight(50),
          ),
          child: Text(widget.isThai ? "ยืนยัน OTP" : "Confirm OTP",
              style: const TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ],
    );
  }
}

class NewPasswordInput extends StatefulWidget {
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final String memberId;
  final bool isThai;

  const NewPasswordInput({
    super.key,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.memberId,
    required this.isThai,
  });

  @override
  State<NewPasswordInput> createState() => _NewPasswordInputState();
}

class _NewPasswordInputState extends State<NewPasswordInput> {
  Color firstBorderColor = Colors.grey;
  Color confirmBorderColor = Colors.grey;
  String? errorMessage;

  void validateMatch() {
    setState(() {
      if (widget.newPasswordController.text == widget.confirmPasswordController.text) {
        firstBorderColor = Colors.green;
        confirmBorderColor = Colors.green;
        errorMessage = null;
      } else {
        firstBorderColor = Colors.grey;
        confirmBorderColor = Colors.red;
        errorMessage = widget.isThai ? "เบอร์ใหม่ไม่ตรงกัน" : "Phone numbers do not match";
      }
    });
  }

  Future<void> changePhone() async {
    final response = await http.post(
      Uri.parse('${config.apiUrl}/change-phone'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_user': widget.memberId,
        'new_phone_number': widget.newPasswordController.text,
      }),
    );

    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          });
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 60),
                const SizedBox(height: 16),
                Text(widget.isThai ? "เปลี่ยนเบอร์เรียบร้อย" : "Phone number changed successfully",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${data['message']}")));
    }
  }

  final List<TextInputFormatter> phoneInputFormatter = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(10),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.newPasswordController,
          keyboardType: TextInputType.number,
          inputFormatters: phoneInputFormatter,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.phone_android),
            hintText: widget.isThai ? "เบอร์ใหม่" : "New Phone",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: widget.confirmPasswordController,
          keyboardType: TextInputType.number,
          inputFormatters: phoneInputFormatter,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.phone_android),
            hintText: widget.isThai ? "ยืนยันเบอร์ใหม่" : "Confirm Phone",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onEditingComplete: validateMatch,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 5),
          Text(errorMessage!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: changePhone,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size.fromHeight(50),
          ),
          child: Text(widget.isThai ? "เปลี่ยนเบอร์โทร" : "Change Phone", style: const TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ],
    );
  }
}
