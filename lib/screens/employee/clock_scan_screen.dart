import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ClockScanScreen extends StatelessWidget {
  const ClockScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Scanner QR Code'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 30),

              Container(
                height: 320,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: CupertinoColors.black,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Center(
                  child: Icon(
                    CupertinoIcons.qrcode_viewfinder,
                    color: CupertinoColors.white,
                    size: 90,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Scanne le QR Code affiché dans le magasin pour enregistrer ton pointage.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: Color(0xFF6B7280)),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: CupertinoButton(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(18),
                  onPressed: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (_) => CupertinoAlertDialog(
                        title: const Text('Pointage enregistré'),
                        content: const Text(
                          'Le pointage sera bientôt relié au QR Code dynamique et à la géolocalisation.',
                        ),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('OK'),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text(
                    'Simulation pointage',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
