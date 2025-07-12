import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import ' Create_Savings.dart';
import 'DetailsData_Savings.dart';
import 'package:mobile_app/constants.dart' as config;

class SavingScreen extends StatefulWidget {
  final String idUser;

  const SavingScreen({Key? key, required this.idUser}) : super(key: key);

  @override
  State<SavingScreen> createState() => _SavingScreenState();
}

class _SavingScreenState extends State<SavingScreen> {
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final url = Uri.parse('${config.apiUrl}/users');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          users = decoded['users'];
          filteredUsers = users;
        });
      } else {
        print('API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Fetch error: $e');
    }
  }

  void filterUsers(String query) {
    final lowerQuery = query.toLowerCase();
    final result = users.where((user) {
      final fullName = '${user['first_name']} ${user['last_name']}'.toLowerCase();
      final memberId = (user['id_user'] ?? '').toString().toLowerCase();
      final address = (user['address'] ?? '').toString().toLowerCase();
      return fullName.contains(lowerQuery) ||
          memberId.contains(lowerQuery) ||
          address.contains(lowerQuery);
    }).toList();

    setState(() {
      searchQuery = query;
      filteredUsers = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("รายชื่อสมาชิกเงินฝาก", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D47A1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: filterUsers,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'ค้นหาชื่อ, รหัสสมาชิก, หรือบ้านเลขที่',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            HeaderRow(),
            const SizedBox(height: 8),
            Expanded(
              child: filteredUsers.isEmpty
                  ? const Center(child: Text('ไม่พบข้อมูล'))
                  : ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) => UserRowItem(
                  user: filteredUsers[index],
                  index: index,
                  // ✅ สำหรับเปิดดูรายละเอียด
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsData_Savings(
                          idUser: filteredUsers[index]['id_user'] ?? '',
                        ),
                      ),
                    );

                    if (result == 'refresh') {
                      await fetchUsers(); // รีเฟรชหลังลบ
                    }
                  },

                ),
              ),
            ),
            const SizedBox(height: 16),
            FooterButtons(idUser: widget.idUser),
          ],
        ),
      ),
    );
  }
}

class HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('ชื่อ-นามสกุล',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text('รหัสสมาชิก',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text('บ้านเลขที่',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Expanded(flex: 1, child: SizedBox()),
        ],
      ),
    );
  }
}

class UserRowItem extends StatelessWidget {
  final dynamic user;
  final int index;
  final VoidCallback onTap;

  const UserRowItem({
    Key? key,
    required this.user,
    required this.index,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '${user['first_name']} ${user['last_name']}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              (index + 1).toString().padLeft(3, '0'),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user['address'] ?? '-',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.search, color: Colors.orange),
                onPressed: onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FooterButtons extends StatelessWidget {
  final String idUser;

  const FooterButtons({Key? key, required this.idUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateSavingsPage(idUser: idUser),
              ),
            );

            if (result == 'refresh') {
              // โหลดข้อมูลใหม่
              if (context.mounted) {
                final state = context.findAncestorStateOfType<_SavingScreenState>();
                state?.fetchUsers();
              }
            }
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('เพิ่มข้อมูล', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
