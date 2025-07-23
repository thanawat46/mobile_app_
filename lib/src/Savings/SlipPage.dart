import 'dart:io';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
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
  String? _extractedSlipNumber;
  String? _extractedAmount;
  String? _qrCodeValue;

  @override
  void initState() {
    super.initState();
    debugPrint('ได้รับ idDepositAm: ${widget.idDepositAm}');
  }

  Future<void> _pickSlipImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() {
        _slipImage = file;
      });

      await scanQRCodeFromImage(file);
      await scanTextFromImage(file);
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

    final slipNumber = _extractedSlipNumber ?? '';
    final amount = _extractedAmount ?? '';
    final dataSlip = _qrCodeValue ?? '';

    try {
      // 🔍 ตรวจสอบสลิปซ้ำ
      final checkUrl = Uri.parse('${config.apiUrl}/check-slip-duplicate');
      final checkResponse = await http.post(
        checkUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "slip_number": slipNumber,
          "data_slip": dataSlip,
        }),
      );

      final isDuplicate = checkResponse.statusCode == 200 &&
          jsonDecode(checkResponse.body)['duplicate'] == true;

      if (isDuplicate) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Color(0xFF0069FF), size: 28),
                SizedBox(width: 10),
                Text(
                  "คำเตือน",
                  style: TextStyle(
                    color: Color(0xFF0069FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: const Text(
              "❌ สลิปนี้ถูกใช้งานแล้ว",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (context.mounted) Navigator.of(context).pop();
        setState(() => _isLoading = false);
        return;
      }

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
      await ref.putFile(_slipImage!, SettableMetadata(contentType: 'image/jpeg'));
      final downloadUrl = await ref.getDownloadURL();

      final body = {
        "id_user": widget.memberId,
        "image_slip": downloadUrl,
        "id_DepositAm": widget.idDepositAm,
        "slip_number": slipNumber,
        "amount_slip": amount,
        "data_slip": dataSlip,
      };

      final uploadUrl = Uri.parse('${config.apiUrl}/upload-slip');
      final response = await http.post(
        uploadUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (context.mounted) Navigator.of(context).pop();

      if (response.statusCode == 200) {
        if (!context.mounted) return;

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

        Navigator.of(context).pop();

        Navigator.pop(context, 'slip_uploaded');
        await Future.delayed(const Duration(milliseconds: 200));

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

  Future<void> scanQRCodeFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final barcodeScanner = BarcodeScanner();
      final barcodes = await barcodeScanner.processImage(inputImage);

      for (final barcode in barcodes) {
        final qrText = barcode.rawValue;
        if (qrText != null) {
          _qrCodeValue = qrText;
          debugPrint('📦 ข้อมูลใน QR Code: $_qrCodeValue');
        }
      }

      await barcodeScanner.close();
    } catch (e) {
      debugPrint('❌ อ่าน QR ไม่สำเร็จ: $e');
    }
  }

  Future<void> scanTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final extracted = extractSlipData(recognizedText.text);
      _extractedAmount = extracted['amount'];
      _extractedSlipNumber = extracted['reference'];

      debugPrint('📖 ข้อความที่อ่านได้:\n${recognizedText.text}');
      debugPrint('💰 จำนวนเงิน: $_extractedAmount');
      debugPrint('🔢 เลขที่รายการ: $_extractedSlipNumber');
    } catch (e) {
      debugPrint('❌ อ่านข้อความไม่สำเร็จ: $e');
    }
  }

  Map<String, String> extractSlipData(String text) {
    final Map<String, String> result = {};

    final cleanedText = text.replaceAll('\n', ' ').replaceAll('\r', ' ');

    final amountMatch = RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d{2}))').firstMatch(cleanedText);
    if (amountMatch != null) result['amount'] = amountMatch.group(1)!;

    final refPattern = RegExp(
      r'(?:เลขที่รายการ|รหัสอ้างอิง|รหัสทำรายการ|Ref(?:erence)?)?[\s:\-]*([A-Z0-9]{12,})',
      caseSensitive: false,
    );
    final refMatch = refPattern.firstMatch(cleanedText);
    if (refMatch != null) result['reference'] = refMatch.group(1)!;

    final datePattern = RegExp(r'(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}|\d{1,2} [ก-๙]+\.? \d{4})');
    final dateMatch = datePattern.firstMatch(cleanedText);
    if (dateMatch != null) result['date'] = dateMatch.group(1)!;

    final timeMatch = RegExp(r'(\d{1,2}:\d{2})').firstMatch(cleanedText);
    if (timeMatch != null) result['time'] = timeMatch.group(1)!;

    return result;
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
