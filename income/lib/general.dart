import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountCard extends StatelessWidget {
  final Color color;
  final String label;
  final String amount;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const AccountCard({
    required this.color,
    required this.label,
    required this.amount,
    this.padding = const EdgeInsets.all(8.0),
    this.margin = const EdgeInsets.all(4.0),
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       theme: ThemeData(
        textTheme: GoogleFonts.gupterTextTheme(Theme.of(context).textTheme),
      ),
    home:Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    )
    );
  }
}
