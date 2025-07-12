import 'package:flutter/material.dart';
import 'CalDividendPage.dart';
import 'CommitteePage.dart';
import 'Data_Loan.dart';
import 'Data_Savings.dart';
import 'Loan/EditLoanStatusPage.dart';
import 'LoanDocumentsPage.dart';
import 'Slip/SlipPage.dart';

class MenuPage extends StatelessWidget {
  final String idUser;

  const MenuPage({super.key, required this.idUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        title: const Text(
          "MenuPage",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _menuButton(
              icon: Icons.calculate,
              label: "คำนวณ\nเงินปันผล",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Caldividendpage(), // ต้องมี const ถ้าใช้ได้
                  ),
                );
              },
            ),
            _menuButton(
              icon: Icons.folder,
              label: "เอกสาร\nเงินกู้",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoanDocumentsPage(), // ต้องมี const ถ้าใช้ได้
                  ),
                );
              },
            ),
            _menuButton(
              icon: Icons.person_search,
              label: "รายชื่อสมาชิก\nเงินฝาก",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SavingScreen(idUser: idUser),
                  ),
                );
              },
            ),
            _menuButton(
              icon: Icons.person_search,
              label: "รายชื่อสมาชิก\nผู้กู้",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoanScreen(idUser: idUser),
                  ),
                );
              },
            ),
            _menuButton(
              icon: Icons.receipt_long,
              label: "สลิป\nเงินฝาก",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Slippage(), // ต้องมี const ถ้าใช้ได้
                  ),
                );
              },
            ),
            _menuButton(
              icon: Icons.group,
              label: "รายชื่อ\nคณะกรรมการ",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CommitteePage(), // ต้องมี const ถ้าใช้ได้
                  ),
                );
              },
            ),
            _menuButton(
              icon: Icons.group,
              label: "คำร้องขอกู้ยืม",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditLoanStatusPage(idUser: idUser), // ต้องมี const ถ้าใช้ได้
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
