import 'package:flutter/material.dart';

class ScaffoldPlaceholder extends StatelessWidget {
  const ScaffoldPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elena App - Dev Mode'),
      ),
      body: const Center(
        child: Text(
          'Sistema Metabólico Iniciado',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
