import 'package:flutter/material.dart';
import 'Account/Account_Deposit.dart';
import 'CalDividendPage.dart';
import 'CommitteePage.dart';
import 'Data_Loan.dart';
import 'Data_Savings/Data_Savings.dart';
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
        title: const Text("MenuPage", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Padding(
          padding: const EdgeInsets.only(left: 20), // ขยับขวา 30px
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            color: Colors.white,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
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
              label: "คำนวณเงินปันผล",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Caldividendpage(),
                  ),
                );
              },
            ),
            _menuButton(
              icon: Icons.folder,
              label: "เอกสารเงินกู้",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoanDocumentsPage(),
                  ),
                );
              },
            ),
            _menuButton(
              icon: Icons.group_add,
              label: "รายชื่อสมาชิกเงินฝาก",
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
              icon: Icons.group_remove,
              label: "รายชื่อสมาชิกเงินกู้",
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
              label: "สลิปเงินฝาก",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => const Slippage(), // ต้องมี const ถ้าใช้ได้
                  ),
                );
              },
            ),
            _menuButton(
              icon: Icons.diversity_3,
              label: "รายชื่อคณะกรรมการ",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            const CommitteePage(),
                  ),
                );
              },
            ),
            _menuButton(
              icon: Icons.play_for_work,
              label: "คำร้องขอกู้ยืม",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => EditLoanStatusPage(
                          idUser: idUser,
                        )
                  ),
                );
              },
            ),
            _menuButton(
              icon: Icons.account_balance,
              label: "ยอดเงินฝากรวม",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder:
                          (context) => Account_Deposit(
                      )
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
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
              style: const TextStyle(
                fontSize: 16,
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
