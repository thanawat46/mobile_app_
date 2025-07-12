import 'dart:io';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:mobile_app/constants.dart' as config;

import '../Home/HomePage.dart';

class SlipPage extends StatefulWidget {
  final String memberId;
  final double amount;
  final String idDepositAm;

  const SlipPage({
    super.key,
    required this.memberId,
    required this.amount,
    required this.idDepositAm,
  });

  @override
  State<SlipPage> createState() => _SlipPageState();
}

class _SlipPageState extends State<SlipPage> {
  File? _slipImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    debugPrint('ได้รับ idDepositAm: ${widget.idDepositAm}');
  }

  Future<void> _pickSlipImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _slipImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitSlip(BuildContext context) async {
    if (_slipImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาแนบสลิปก่อน")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final fileName = basename(_slipImage!.path);
    final destination = 'slips/$fileName';

    try {
      // 🔵 แสดง popup โหลด
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          backgroundColor: Colors.white,
          content: Row(
            children: [
              CircularProgressIndicator(color: Color(0xFF0069FF)),
              SizedBox(width: 16),
              Text("กำลังอัปโหลด...", style: TextStyle(color: Colors.black87)),
            ],
          ),
        ),
      );

      final ref = FirebaseStorage.instance.ref(destination);
      await ref.putFile(
        _slipImage!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await ref.getDownloadURL();

      final body = {
        "id_user": widget.memberId,
        "image_slip": downloadUrl,
        "id_DepositAm": widget.idDepositAm,
      };

      final url = Uri.parse('${config.apiUrl}/upload-slip');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      // 🔵 ปิด popup โหลด
      if (context.mounted) Navigator.of(context).pop();

      if (response.statusCode == 200) {
        if (!context.mounted) return;

        // แสดง popup แบบไม่มีปุ่มและปิดเองใน 3 วิ
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.check_circle, color: Color(0xFF0069FF), size: 28),
                SizedBox(width: 10),
                Text("สำเร็จ", style: TextStyle(color: Color(0xFF0069FF), fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text("ฝากเงินเสร็จสิ้นเรียบร้อยแล้ว"),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (!context.mounted) return;
        Navigator.of(context).pop(); // ปิด dialog
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomePage(idUser: widget.memberId)),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ฝากเงินไม่สำเร็จ")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FB),
      appBar: AppBar(
        leading: IconButton(
          padding: const EdgeInsets.only(left: 20),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "แนบสลิปการฝากเงิน",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0069FF),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              _buildInfoCard("รหัสสมาชิก", widget.memberId),
              const SizedBox(height: 12),
              _buildInfoCard("จำนวนเงิน", "${widget.amount.toStringAsFixed(2)} บาท"),
              const SizedBox(height: 12),
              _buildInfoCard("รหัสฝากเงิน", widget.idDepositAm),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _pickSlipImage,
                icon: const Icon(Icons.upload_file, color: Color(0xFF0069FF)),
                label: const Text(
                  "แนบสลิป",
                  style: TextStyle(color: Color(0xFF0069FF), fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF0069FF), width: 5),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 24),
              _slipImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_slipImage!, height: 200, fit: BoxFit.cover),
              )
                  : Column(
                children: const [
                  Icon(Icons.image, size: 80, color: Colors.grey),
                  SizedBox(height: 8),
                  Text("ยังไม่ได้แนบสลิป", style: TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                  if (widget.idDepositAm.isNotEmpty) {
                    _submitSlip(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("ไม่พบรหัสฝากเงิน")),
                    );
                  }
                },
                icon: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.check_circle_outline, size: 24, color: Colors.white),
                label: Text(
                  _isLoading ? "กำลังฝากเงิน..." : "ฝากเงิน",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
