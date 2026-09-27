import 'package:flutter/material.dart';

/// Separate researcher entrypoint: never linked from the participant flow.
void main() => runApp(const MaterialApp(home: DiagnosticsScreen()));

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Researcher diagnostics')),
    body: const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dataset schema: 1'),
          Text(
            'Native sensor verification is required before a hardware pilot.',
          ),
          Text('Participant codes and enrollment tokens are not logged.'),
        ],
      ),
    ),
  );
}
