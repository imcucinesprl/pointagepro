import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/services/push_notification_service.dart';
import 'core/services/session_service.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_tab_screen.dart';

/*
|--------------------------------------------------------------------------
| Réception Firebase en arrière-plan
|--------------------------------------------------------------------------
|
| Cette fonction doit rester en dehors de toute classe.
| L’annotation vm:entry-point est nécessaire pour les builds release.
|
*/

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint(
    'Notification Firebase reçue en arrière-plan.',
  );

  debugPrint(
    'Message Firebase arrière-plan : ${message.messageId}',
  );

  debugPrint(
    'Données Firebase arrière-plan : ${message.data}',
  );
}

/*
|--------------------------------------------------------------------------
| Démarrage de l’application
|--------------------------------------------------------------------------
*/

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /*
   * Le gestionnaire d’arrière-plan doit être enregistré
   * avant le lancement de l’interface.
   */
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  runApp(
    const PointageProApp(),
  );
}

/*
|--------------------------------------------------------------------------
| Application principale
|--------------------------------------------------------------------------
*/

class PointageProApp extends StatelessWidget {
  const PointageProApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'PointagePro',

      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],

      supportedLocales: [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],

      locale: Locale('fr', 'FR'),

      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF007AFF),
        scaffoldBackgroundColor: Color(
          0xFFF2F2F7,
        ),
      ),

      home: AuthGate(),
    );
  }
}

/*
|--------------------------------------------------------------------------
| Vérification de la connexion
|--------------------------------------------------------------------------
*/

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
  });

  @override
  State<AuthGate> createState() =>
      _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<bool> _loginStateFuture;

  @override
  void initState() {
    super.initState();

    _loginStateFuture =
        _initializeApplication();
  }

  /*
   * Vérifie la session puis initialise les notifications
   * uniquement lorsqu’un utilisateur est déjà connecté.
   */
  Future<bool> _initializeApplication() async {
    final isLoggedIn =
        await SessionService.isLoggedIn();

    if (isLoggedIn) {
      /*
       * L’interface peut continuer à démarrer pendant que
       * Firebase récupère le token et enregistre l’appareil.
       */

    }

    return isLoggedIn;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _loginStateFuture,
      builder: (
        BuildContext context,
        AsyncSnapshot<bool> snapshot,
      ) {
        if (snapshot.connectionState !=
            ConnectionState.done) {
          return const CupertinoPageScaffold(
            child: Center(
              child: CupertinoActivityIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint(
            'Erreur vérification session : '
            '${snapshot.error}',
          );

          return const LoginScreen();
        }

        if (snapshot.data == true) {
          return const MainTabScreen();
        }

        return const LoginScreen();
      },
    );
  }
}