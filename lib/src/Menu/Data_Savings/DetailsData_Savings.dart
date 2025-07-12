import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_app/constants.dart' as config;

class DetailsData_Savings extends StatefulWidget {
  final String idUser;

  const DetailsData_Savings({Key? key, required this.idUser}) : super(key: key);

  @override
  State<DetailsData_Savings> createState() => _DetailsData_SavingsState();
}

class _DetailsData_SavingsState extends State<DetailsData_Savings> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserDetail();
  }

  Future<void> fetchUserDetail() async {
    try {
      final url = Uri.parse('${config.apiUrl}/users_data/${widget.idUser}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          setState(() {
            userData = data['user'];
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  double calculateTotalDeposit() {
    final deposits = userData?['deposits'] ?? [];
    if (deposits is List) {
      return deposits.fold<double>(
        0.0,
            (sum, item) => sum + (item['deposit_amount'] ?? 0.0),
      );
    }
    return 0.0;
  }

  Future<void> _deleteUser() async {
    final url = Uri.parse('${config.apiUrl}/users/${widget.idUser}');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบข้อมูลสำเร็จ')),
          );
          Navigator.pop(context, 'refresh'); // ✅ แก้ตรงนี้
        } else {
          _showError('เกิดข้อผิดพลาด: ${result['message']}');
        }
      } else {
        _showError('ไม่สามารถลบได้ (${response.statusCode})');
      }
    } catch (e) {
      _showError('เกิดข้อผิดพลาดขณะลบข้อมูล');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: const Text("คุณแน่ใจหรือไม่ว่าต้องการลบข้อมูลผู้ใช้นี้?"),
        actions: [
          TextButton(
            child: const Text("ยกเลิก"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("ลบ", style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context, 'refresh');
              _deleteUser();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('รายละเอียดสมาชิก', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : userData == null
              ? const Center(
              child: Text('ไม่พบข้อมูลผู้ใช้',
                  style: TextStyle(color: Colors.white, fontSize: 18)))
              : Padding(
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 80),
            child: GlassCard(
              child: UserDetailSection(
                userData: userData!,
                totalDeposit: calculateTotalDeposit(),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton.extended(
              onPressed: _confirmDelete,
              backgroundColor: Colors.redAccent,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text("ลบข้อมูล", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class UserDetailSection extends StatelessWidget {
  final Map<String, dynamic> userData;
  final double totalDeposit;

  const UserDetailSection({
    super.key,
    required this.userData,
    required this.totalDeposit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ข้อมูลสมาชิก',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              UserInfoTile(icon: Icons.badge, label: 'รหัสสมาชิก', value: userData['id_user']),
              UserInfoTile(
                icon: Icons.person,
                label: 'ชื่อ',
                value:
                '${userData['pre_name'] ?? ''} ${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}',
              ),
              UserInfoTile(icon: Icons.verified_user, label: 'บทบาท', value: userData['role']),
              UserInfoTile(icon: Icons.home, label: 'ที่อยู่', value: userData['address']),
              UserInfoTile(icon: Icons.phone, label: 'เบอร์โทร', value: userData['phone_number']),
              UserInfoTile(
                icon: Icons.savings,
                label: 'ยอดเงินฝากรวม',
                value: '${NumberFormat("#,##0.0", "en_US").format(totalDeposit)} บาท',
                highlight: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class UserInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool highlight;

  const UserInfoTile({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlight ? Colors.blue.shade50 : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(icon, color: Colors.blue.shade900),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(value ?? '-', style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;

  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}
