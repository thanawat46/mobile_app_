import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/constants.dart' as config;

class CreateSavingsPage extends StatefulWidget {
  final String idUser;

  const CreateSavingsPage({Key? key, required this.idUser}) : super(key: key);

  @override
  State<CreateSavingsPage> createState() => _CreateSavingsPageState();
}

class _CreateSavingsPageState extends State<CreateSavingsPage> {
  final _formKey = GlobalKey<FormState>();

  String? _prefix;
  final _nameController = TextEditingController();
  final _lnameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();

  final List<String> _prefixOptions = ['นาย', 'นางสาว', 'นาง'];

  @override
  void dispose() {
    _nameController.dispose();
    _lnameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final body = {
        "pre_name_text": _prefix,
        "first_name": _nameController.text,
        "last_name": _lnameController.text,
        "address": _addressController.text,
        "phone_number": _phoneController.text,
        "deposit_amount": double.tryParse(_amountController.text) ?? 0
      };

      try {
        final response = await http.post(
          Uri.parse('${config.apiUrl}/add-users'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body),
        );

        final resData = jsonDecode(response.body);

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('บันทึกข้อมูลสำเร็จ'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception(resData['error'] ?? 'เกิดข้อผิดพลาด');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue.shade700),
      filled: true,
      fillColor: Colors.blue.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มข้อมูลบัญชีเงินฝาก'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: _buildInputDecoration('คำนำหน้า', Icons.person_outline),
                value: _prefix,
                items: _prefixOptions.map((prefix) {
                  return DropdownMenuItem(value: prefix, child: Text(prefix));
                }).toList(),
                onChanged: (value) => setState(() => _prefix = value),
                validator: (value) => value == null ? 'กรุณาเลือกคำนำหน้า' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration('ชื่อ', Icons.account_circle),
                validator: (value) =>
                value == null || value.isEmpty ? 'กรุณากรอกชื่อ' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lnameController,
                decoration: _buildInputDecoration('นามสกุล', Icons.account_circle_outlined),
                validator: (value) =>
                value == null || value.isEmpty ? 'กรุณากรอกนามสกุล' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: _buildInputDecoration('บ้านเลขที่', Icons.home),
                validator: (value) =>
                value == null || value.isEmpty ? 'กรุณากรอกบ้านเลขที่' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: _buildInputDecoration('เบอร์โทร', Icons.phone),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกเบอร์โทร';
                  }
                  if (value.length != 10) {
                    return 'กรุณากรอกเบอร์โทรให้ถูกต้อง (10 หลัก)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration('จำนวนเงินฝากเริ่มต้น', Icons.attach_money),
                validator: (value) =>
                value == null || double.tryParse(value) == null
                    ? 'กรุณากรอกจำนวนเงินเป็นตัวเลข'
                    : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'บันทึกข้อมูล',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
