import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_nav_bar/google_nav_bar.dart';
import '../Loan/LoanPage.dart';
import '../Loan/LoanRequestPage.dart';
import '../Menu/MenuPage.dart';
import 'package:mobile_app/constants.dart' as config;
import 'package:intl/intl.dart';
import '../Profile/ProfilePage.dart';
import '../Savings/SavingsPage.dart';
import 'HistoryPage.dart';

class HomePage extends StatefulWidget {
  final String idUser;

  const HomePage({super.key, required this.idUser});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  String userName = "กำลังโหลด...";
  double depositAmount = 0.0;
  double loanAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userRes = await http.get(Uri.parse("${config.apiUrl}/users/${widget.idUser.trim()}"));
      if (userRes.statusCode == 200) {
        final data = jsonDecode(userRes.body)["data"];
        setState(() {
          userName = "${data['first_name']} ${data['last_name']}";
        });
      }

      final depositRes = await http.get(Uri.parse("${config.apiUrl}/deposit/total/${widget.idUser.trim()}"));
      if (depositRes.statusCode == 200) {
        final depositData = jsonDecode(depositRes.body);
        setState(() {
          depositAmount = (depositData["total_deposit"] ?? 0).toDouble();
        });
      }

      final loanRes = await http.get(Uri.parse("${config.apiUrl}/loan-amount/${widget.idUser.trim()}"));
      if (loanRes.statusCode == 200) {
        final loanData = jsonDecode(loanRes.body);
        setState(() {
          loanAmount = double.tryParse(loanData["loan_amount"].toString()) ?? 0.0;
        });
      }

    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  void _onTabChange(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Color getAppBarColor() {
    switch (_selectedIndex) {
      case 1:
        return const Color(0xFF2E7D32);
      case 2:
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF0D47A1);
    }
  }


  Widget _getPage(int index) {
    switch (index) {
      case 0:
        _fetchUserData(); // โหลดใหม่ทุกครั้งเมื่อกลับหน้าหลัก
        return _homeBody();
      case 1:
        return Savingspage(idUser: widget.idUser); // สร้างใหม่ทุกครั้ง
      case 2:
        return Loanpage(idUser: widget.idUser);
      case 3:
        return Profilepage(idUser: widget.idUser);
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: getAppBarColor(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userName,
                style: const TextStyle(color: Colors.white, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MenuPage(idUser: widget.idUser),
                ),
              );
            },
          ),
        ],
      ),
      body: _getPage(_selectedIndex),
      bottomNavigationBar: _bottomMenu(),
    );
  }

  Widget _homeBody() {
    final formattedDeposit = NumberFormat("#,##0", "en_US").format(depositAmount);
    final formattedLoan = NumberFormat("#,##0", "en_US").format(loanAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("บัญชีเงินฝากทั้งหมด", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 5),
                Text(
                  "฿$formattedDeposit",
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                const Text("ยอดเงินกู้คงเหลือ", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 5),
                Text(
                  "฿$formattedLoan",
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            children: [
              _menuButton(Icons.arrow_downward, "เงินฝาก"),
              _menuButton(Icons.arrow_upward, "เงินกู้"),
              _menuButton(Icons.history, "ประวัติ"),
              _menuButton(Icons.admin_panel_settings, "เมนูแอดมิน"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuButton(IconData icon, String title) {
    return GestureDetector(
      onTap: () async {
        if (title == "เงินกู้") {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoanRequestPage(idUser: widget.idUser)),
          );
        } else if (title == "เงินฝาก") {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Savingspage(idUser: widget.idUser)),
          );
        } else if (title == "เมนูแอดมิน") {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MenuPage(idUser: widget.idUser)),
          );
        } else if (title == "ประวัติ") {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => HistoryPage(idUser: widget.idUser)),
          );
        }
        await _fetchUserData();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.blue)),
          ],
        ),
      ),
    );
  }

  Widget _bottomMenu() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: GNav(
          activeColor: Colors.white,
          tabBackgroundColor: const Color(0xFF0D47A1),
          gap: 10,
          padding: const EdgeInsets.all(15),
          selectedIndex: _selectedIndex,
          onTabChange: _onTabChange,
          tabs: const [
            GButton(icon: Icons.home, text: 'หน้าหลัก'),
            GButton(icon: Icons.account_balance_wallet, text: 'เงินฝาก'),
            GButton(icon: Icons.attach_money, text: 'เงินกู้'),
            GButton(icon: Icons.person, text: 'โปรไฟล์'),
          ],
        ),
      ),
    );
  }
}
