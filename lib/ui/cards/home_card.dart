import 'package:flutter/material.dart';

class HomeCard extends StatelessWidget {
  const HomeCard({
    super.key,
    required this.color,
    required this.width,
    required this.count,
    required this.child,
  });
  final Color color;
  final double width;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Container(
        padding: EdgeInsets.all(25),
        //width: width,
        height: 100,
        child: child,
      ),
    );
  }
}
