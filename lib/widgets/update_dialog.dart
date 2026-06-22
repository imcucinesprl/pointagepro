import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog {

  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> versionData,
    bool forceUpdate,
  ) async {

    await showCupertinoDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (_) {

        return CupertinoAlertDialog(
          title: Text(
            versionData['title'] ?? 'Mise à jour',
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              versionData['message'] ??
                  'Une nouvelle version est disponible.',
            ),
          ),
          actions: [

            if (!forceUpdate)
              CupertinoDialogAction(
                child: const Text('Plus tard'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),

            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Mettre à jour'),
              onPressed: () async {

                final url =
                    versionData['store_url'];

                await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
          ],
        );
      },
    );
  }
}