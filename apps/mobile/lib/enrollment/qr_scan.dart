import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EnrollmentScanner extends StatefulWidget {
  const EnrollmentScanner({super.key});
  @override
  State<EnrollmentScanner> createState() => _EnrollmentScannerState();
}

class _EnrollmentScannerState extends State<EnrollmentScanner> {
  bool completed = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scan your study code')),
    body: MobileScanner(
      onDetect: (capture) {
        if (completed) return;
        for (final barcode in capture.barcodes) {
          final value = barcode.rawValue;
          final uri = value == null ? null : Uri.tryParse(value);
          if (uri?.scheme == 'collector' &&
              uri?.host == 'enroll' &&
              uri!.queryParameters.containsKey('token')) {
            completed = true;
            Navigator.of(context).pop(value);
            return;
          }
        }
      },
      errorBuilder: (context, error) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Camera access is unavailable. Go back and enter your participant code.',
          ),
        ),
      ),
    ),
  );
}
