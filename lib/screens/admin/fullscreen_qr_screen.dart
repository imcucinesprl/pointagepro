import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:local_auth/local_auth.dart';

class FullScreenQrScreen extends StatefulWidget {
  const FullScreenQrScreen({
    super.key,
    required this.qrUrl,
    required this.companyName,
  });

  final String qrUrl;
  final String companyName;

  @override
  State<FullScreenQrScreen> createState() => _FullScreenQrScreenState();
}

class _FullScreenQrScreenState extends State<FullScreenQrScreen> {
  late final WebViewController _controller;
  final LocalAuthentication _auth = LocalAuthentication();

  bool _showExitButton = false;

  @override
  void initState() {
    super.initState();

    WakelockPlus.enable();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.qrUrl));
  }

  Future<void> _requestExit() async {
    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Authentifiez-vous pour quitter le mode QR plein écran',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate && mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      // Si l'authentification échoue, on reste sur la page.
    }
  }

  void _revealExitButton() {
    if (_showExitButton) return;

    setState(() {
      _showExitButton = true;
    });

    Future.delayed(const Duration(seconds: 12), () {
      if (!mounted) return;
      setState(() {
        _showExitButton = false;
      });
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _requestExit();
      },
      child: CupertinoPageScaffold(
        backgroundColor: Colors.black,
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;

            return SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: SizedBox(
                      width: isLandscape
                          ? MediaQuery.of(context).size.height * 0.95
                          : MediaQuery.of(context).size.width,
                      height: isLandscape
                          ? MediaQuery.of(context).size.height * 0.95
                          : MediaQuery.of(context).size.height,
                      child: WebViewWidget(controller: _controller),
                    ),
                  ),

                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onLongPress: _revealExitButton,
                      child: const SizedBox(
                        width: 90,
                        height: 90,
                      ),
                    ),
                  ),

                  if (_showExitButton)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _requestExit,
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}