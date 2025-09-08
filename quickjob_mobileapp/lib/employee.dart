import 'package:flutter/material.dart';

class EmployeePage extends StatelessWidget {
  const EmployeePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee'),
      ),
      body: const Center(
        child: Text('Employee main page (placeholder)'),
      ),
    );
  }
}
