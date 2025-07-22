import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_app/constants.dart' as config;

class LoanRequestPage extends StatefulWidget {
  final String idUser;

  const LoanRequestPage({Key? key, required this.idUser}) : super(key: key);

  @override
  State<LoanRequestPage> createState() => _LoanRequestPageState();
}

class _LoanRequestPageState extends State<LoanRequestPage> {
  bool _isLoanRequested = false;
  final TextEditingController _loanReasonController = TextEditingController();
  final TextEditingController _loanAmountController = TextEditingController();
  String? uploadedDocumentUrl;

  final String _contractTemplateUrl =
      'https://firebasestorage.googleapis.com/v0/b/YOUR_PROJECT.appspot.com/o/contract%2Fcontract_template.pdf?alt=media';

  Future<void> _downloadOriginalContract() async {
    final uri = Uri.parse(_contractTemplateUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ไม่สามารถเปิดเอกสารสัญญาได้")),
      );
    }
  }

  Future<void> pickAndUploadDocument() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (picked == null) return;

      final file = File(picked.path);
      if (!file.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ไม่พบไฟล์ที่เลือก")),
        );
        return;
      }

      final fileName =
          'loan_doc_${widget.idUser}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destination = 'loan_documents/$fileName';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: Color(0xFF0069FF)),
              SizedBox(width: 16),
              Text("กำลังอัปโหลดเอกสาร..."),
            ],
          ),
        ),
      );

      final ref = FirebaseStorage.instance.ref(destination);
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      Navigator.of(context).pop();

      setState(() {
        uploadedDocumentUrl = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("อัปโหลดเอกสารสำเร็จ")),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("อัปโหลดล้มเหลว: $e")),
      );
    }
  }

  Future<void> _submitLoanRequest() async {
    final reason = _loanReasonController.text.trim();
    final amount = double.tryParse(_loanAmountController.text.trim());

    if (reason.isEmpty || amount == null || uploadedDocumentUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("กรุณากรอกข้อมูลและอัปโหลดเอกสารให้ครบ"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = Uri.parse('${config.apiUrl}/loan_requests');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_user': widget.idUser,
          'loan_amount': amount,
          'notes': reason,
          'document_url': uploadedDocumentUrl,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isLoanRequested = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("ส่งคำขอกู้เงินสำเร็จ"),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("ผิดพลาด: ${response.statusCode}"),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("เชื่อมต่อเซิร์ฟเวอร์ไม่ได้: $e"),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        title: const Text("ขอกู้เงิน", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text("รหัสผู้ใช้: ${widget.idUser}"),
                subtitle: const Text("กรุณากรอกข้อมูลให้ครบถ้วน"),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6F8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                children: [
                  ElevatedButton.icon(
                    onPressed: _downloadOriginalContract,
                    icon: const Icon(Icons.download, color: Colors.white), // <-- ไอคอนขาว
                    label: const Text("ดาวน์โหลดเอกสารสัญญา", style: TextStyle(color: Colors.white)), // <-- ข้อความขาว
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: pickAndUploadDocument,
                    icon: const Icon(Icons.upload, color: Colors.white),
                    label: const Text("อัปโหลดเอกสารสัญญาที่เขียนแล้ว", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  if (uploadedDocumentUrl != null) ...[
                    const SizedBox(height: 8),
                    Text("✔️ อัปโหลดแล้ว", style: TextStyle(color: Colors.green)),
                  ],
                  const SizedBox(height: 24),
                  const Text("จำนวนเงินที่ต้องการกู้"),
                  TextField(
                    controller: _loanAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.attach_money),
                      filled: true,
                      hintText: "เช่น 10000",
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("เหตุผลในการกู้"),
                  TextField(
                    controller: _loanReasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.edit_note),
                      filled: true,
                      hintText: "เพื่อซ่อมบ้าน, เพื่อเรียน ฯลฯ",
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _isLoanRequested ? null : _submitLoanRequest,
                    icon: const Icon(Icons.send, color: Colors.white), // ไอคอนขาว
                    label: const Text("ส่งคำขอกู้", style: TextStyle(color: Colors.white)), // ข้อความขาว
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLoanRequested ? Colors.grey : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
