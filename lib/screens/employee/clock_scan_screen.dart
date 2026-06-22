import 'dart:ui';

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
  static const Color pointageBlue = Color(0xFF0A84FF);
  static const Color pointagePurple = Color(0xFF7C3AED);

  bool isProcessing = false;

  Future<void> handleQrCode(String value) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    final result = await PointageService.clockWithQr(value);

    if (!mounted) return;

    await showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(
          result["success"] == true ? "Pointage enregistré" : "Erreur",
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(result["message"]?.toString() ?? ""),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("OK"),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result["success"] == true) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xCCF3F6FB),
        border: null,
        middle: Text(
          'Scanner QR Code',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _BlurCircle(
                size: 240,
                color: pointageBlue.withOpacity(0.22),
              ),
            ),
            Positioned(
              top: 180,
              left: -110,
              child: _BlurCircle(
                size: 260,
                color: pointagePurple.withOpacity(0.18),
              ),
            ),
            Positioned(
              bottom: -120,
              right: -90,
              child: _BlurCircle(
                size: 260,
                color: const Color(0xFF34C759).withOpacity(0.14),
              ),
            ),

            ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              children: [
                _HeroGlassCard(isProcessing: isProcessing),

                const SizedBox(height: 20),

                _ScannerGlassCard(
                  onDetect: (value) => handleQrCode(value),
                ),

                const SizedBox(height: 22),

                _InfoGlassCard(isProcessing: isProcessing),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroGlassCard extends StatelessWidget {
  const _HeroGlassCard({
    required this.isProcessing,
  });

  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A84FF),
            Color(0xFF7C3AED),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A84FF).withOpacity(0.20),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              CupertinoIcons.qrcode_viewfinder,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Pointage sécurisé",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isProcessing
                      ? "Validation du QR Code en cours..."
                      : "Scanne le QR Code affiché dans le magasin.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.86),
                    fontSize: 15,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerGlassCard extends StatelessWidget {
  const _ScannerGlassCard({
    required this.onDetect,
  });

  final ValueChanged<String> onDetect;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(10),
      child: Container(
        height: 355,
        width: double.infinity,
        decoration: BoxDecoration(
          color: CupertinoColors.black,
          borderRadius: BorderRadius.circular(26),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            MobileScanner(
              onDetect: (capture) {
                final barcode = capture.barcodes.firstOrNull;
                final value = barcode?.rawValue;

                if (value == null || value.isEmpty) return;

                onDetect(value);
              },
            ),

            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.20),
                    width: 1,
                  ),
                ),
              ),
            ),

            const Positioned.fill(
              child: Center(
                child: _ScannerFrame(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoGlassCard extends StatelessWidget {
  const _InfoGlassCard({
    required this.isProcessing,
  });

  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              _IconBubble(
                icon: CupertinoIcons.location_fill,
                color: Color(0xFF34C759),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "La position GPS est enregistrée uniquement au moment du pointage.",
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                if (isProcessing)
                  const CupertinoActivityIndicator(radius: 12)
                else
                  const Icon(
                    CupertinoIcons.checkmark_shield_fill,
                    color: Color(0xFF0A84FF),
                    size: 22,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isProcessing
                        ? "Vérification du QR Code et de la position..."
                        : "Prêt à scanner",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.78),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.65),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: color,
        size: 22,
      ),
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      width: 210,
      child: Stack(
        children: const [
          _Corner(alignment: Alignment.topLeft),
          _Corner(alignment: Alignment.topRight),
          _Corner(alignment: Alignment.bottomLeft),
          _Corner(alignment: Alignment.bottomRight),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({
    required this.alignment,
  });

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;

    return Align(
      alignment: alignment,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}