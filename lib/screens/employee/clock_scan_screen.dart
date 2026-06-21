import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/services/pointage_service.dart';

class ClockScanScreen extends StatefulWidget {
  const ClockScanScreen({super.key});

  @override
  State<ClockScanScreen> createState() => _ClockScanScreenState();
}

class _ClockScanScreenState extends State<ClockScanScreen> {
  bool isProcessing = false;

Future<void> handleQrCode(String value) async {
  if (isProcessing) return;

  setState(() {
    isProcessing = true;
  });

  final result = await PointageService.clockWithQr(value);

  if (!mounted) return;

  showCupertinoDialog(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: Text(result["success"] == true ? "Pointage enregistré" : "Erreur"),
      content: Text(result["message"]?.toString() ?? ""),
      actions: [
        CupertinoDialogAction(
          child: const Text("OK"),
          onPressed: () {
            Navigator.pop(context);

            if (result["success"] == true) {
              Navigator.pop(context, true);
            } else {
              setState(() {
                isProcessing = false;
              });
            }
          },
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Scanner QR Code'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 340,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: CupertinoColors.black,
                  borderRadius: BorderRadius.circular(28),
                ),
                clipBehavior: Clip.antiAlias,
                child: MobileScanner(
                  onDetect: (capture) {
                    final barcode = capture.barcodes.firstOrNull;
                    final value = barcode?.rawValue;

                    if (value == null || value.isEmpty) return;

                    handleQrCode(value);
                  },
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Scanne le QR Code affiché dans le magasin pour enregistrer ton pointage.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: Color(0xFF6B7280)),
              ),
            ),

            const SizedBox(height: 20),

            if (isProcessing)
              const CupertinoActivityIndicator(radius: 14),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}