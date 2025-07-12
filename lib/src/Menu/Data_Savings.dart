import 'package:flutter/material.dart';

import '../Home/HomePage.dart';
import 'Data_Loan.dart';

class SavingScreen extends StatefulWidget {
  final String idUser;

  const SavingScreen({Key? key, required this.idUser}) : super(key: key);

  @override
  State<SavingScreen> createState() => _SavingScreenState();
}

class _SavingScreenState extends State<SavingScreen> {
  bool isLoanSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        title: const Text(
          "รายชื่อสมาชิกเงินฝาก",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔍 Search
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'ค้นหา',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 🔁 Toggle Button
            Row(
              children: [
                const SizedBox(width: 10),
                Expanded(child: _buildToggleButton("เงินออม", !isLoanSelected)),
              ],
            ),
            const SizedBox(height: 16),

            // 🧾 Header Row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blue[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('ชื่อ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('รหัสสมาชิก', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('บ้านเลขที่', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('เพิ่มเติม', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 📋 List
            Expanded(
              child: ListView.builder(
                itemCount: 8,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Expanded(flex: 2, child: Text('Test', style: TextStyle(fontWeight: FontWeight.bold))),
                        const Expanded(flex: 3, child: Text('6517', textAlign: TextAlign.center)),
                        const Expanded(flex: 2, child: Text('124', textAlign: TextAlign.center)),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.search, color: Colors.orange),
                              onPressed: () {},
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 🔚 Footer Buttons
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFooterButton('ย้อนกลับ', Colors.red, Icons.arrow_back, () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage(idUser: widget.idUser)),
                        (Route<dynamic> route) => false,
                  );
                }),
                _buildFooterButton('เพิ่มข้อมูล', Colors.green, Icons.add, () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (text == "เงินกู้") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoanScreen(idUser: widget.idUser)),
          );
        }
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.blue[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildFooterButton(String text, Color color, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(text, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
