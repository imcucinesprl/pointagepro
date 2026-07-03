import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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

  @override
  void initState() {
    super.initState();

    // Empêche le téléphone de se mettre en veille
    WakelockPlus.enable();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.qrUrl));
  }

  @override
  void dispose() {
    // Réactive la mise en veille normale
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
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
                  top: 12,
                  right: 12,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
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
    );
  }
}