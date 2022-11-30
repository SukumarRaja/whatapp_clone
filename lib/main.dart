import 'dart:core';
import 'package:camera/camera.dart';
import 'package:chat/Configs/Dbkeys.dart';
import 'package:chat/Configs/app_constants.dart';
import 'package:chat/Screens/homepage/initialize.dart';
import 'package:chat/Screens/splash_screen/splash_screen.dart';
import 'package:chat/Services/Providers/BroadcastProvider.dart';
import 'package:chat/Services/Providers/AvailableContactsProvider.dart';
import 'package:chat/Services/Providers/GroupChatProvider.dart';
import 'package:chat/Services/Providers/LazyLoadingChatProvider.dart';
import 'package:chat/Services/Providers/Observer.dart';
import 'package:chat/Services/Providers/StatusProvider.dart';
import 'package:chat/Services/Providers/TimerProvider.dart';
import 'package:chat/Services/Providers/currentchat_peer.dart';
import 'package:chat/Services/Providers/seen_provider.dart';
import 'package:chat/Services/localization/demo_localization.dart';
import 'package:chat/Services/localization/language_constants.dart';
import 'package:chat/Services/Providers/DownloadInfoProvider.dart';
import 'package:chat/Services/Providers/call_history_provider.dart';
import 'package:chat/Services/Providers/user_provider.dart';
import 'package:chat/Utils/setStatusBarColor.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<CameraDescription> cameras = <CameraDescription>[];

void main() async {
  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();

  binding.renderView.automaticSystemUiAdjustment = false;
  setStatusBarColor();
  if (IsBannerAdShow == true ||
      IsInterstitialAdShow == true ||
      IsVideoAdShow == true) {
    MobileAds.instance.initialize();
  }

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    logError(e.code, e.description);
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(OverlaySupport(child: chatWrapper()));
  });
}

class chatWrapper extends StatefulWidget {
  const chatWrapper({Key? key}) : super(key: key);
  static void setLocale(BuildContext context, Locale newLocale) {
    _chatWrapperState state =
        context.findAncestorStateOfType<_chatWrapperState>()!;
    state.setLocale(newLocale);
  }

  @override
  _chatWrapperState createState() => _chatWrapperState();
}

class _chatWrapperState extends State<chatWrapper> {
  Locale? _locale;
  setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  void didChangeDependencies() {
    getLocale().then((locale) {
      setState(() {
        this._locale = locale;
      });
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseGroupServices firebaseGroupServices = FirebaseGroupServices();
    final FirebaseBroadcastServices firebaseBroadcastServices =
        FirebaseBroadcastServices();
    if (this._locale == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Splashscreen(),
      );
    } else {
      return FutureBuilder(
          future: _initialization,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                home: Splashscreen(),
              );
            }
            if (snapshot.connectionState == ConnectionState.done) {
              return FutureBuilder(
                  future: SharedPreferences.getInstance(),
                  builder:
                      (context, AsyncSnapshot<SharedPreferences> snapshot) {
                    if (snapshot.hasData) {
                      return MultiProvider(
                        providers: [
                          ChangeNotifierProvider(
                              create: (_) =>
                                  FirestoreDataProviderMESSAGESforBROADCASTCHATPAGE()),
                          //---
                          ChangeNotifierProvider(
                              create: (_) => StatusProvider()),
                          ChangeNotifierProvider(
                              create: (_) => TimerProvider()),
                          ChangeNotifierProvider(
                              create: (_) =>
                                  FirestoreDataProviderMESSAGESforGROUPCHAT()),
                          ChangeNotifierProvider(
                              create: (_) =>
                                  FirestoreDataProviderMESSAGESforLAZYLOADINGCHAT()),

                          ChangeNotifierProvider(
                              create: (_) => AvailableContactsProvider()),
                          ChangeNotifierProvider(create: (_) => Observer()),
                          Provider(create: (_) => SeenProvider()),
                          ChangeNotifierProvider(
                              create: (_) => DownloadInfoprovider()),
                          ChangeNotifierProvider(create: (_) => UserProvider()),
                          ChangeNotifierProvider(
                              create: (_) =>
                                  FirestoreDataProviderCALLHISTORY()),
                          ChangeNotifierProvider(
                              create: (_) => CurrentChatPeer()),
                        ],
                        child: StreamProvider<List<BroadcastModel>>(
                          initialData: [],
                          create: (BuildContext context) =>
                              firebaseBroadcastServices.getBroadcastsList(
                                  snapshot.data!.getString(Dbkeys.phone) ?? ''),
                          child: StreamProvider<List<GroupModel>>(
                            initialData: [],
                            create: (BuildContext context) =>
                                firebaseGroupServices.getGroupsList(
                                    snapshot.data!.getString(Dbkeys.phone) ??
                                        ''),
                            child: MaterialApp(
                              builder: (BuildContext? context, Widget? widget) {
                                ErrorWidget.builder =
                                    (FlutterErrorDetails errorDetails) {
                                  return CustomError(
                                      errorDetails: errorDetails);
                                };

                                return widget!;
                              },
                              theme: ThemeData(
                                  fontFamily: FONTFAMILY_NAME,
                                  primaryColor: chatgreen,
                                  primaryColorLight: chatgreen,
                                  indicatorColor: chatLightGreen),
                              title: Appname,
                              debugShowCheckedModeBanner: false,
                              home: Initialize(
                                app: K11,
                                doc: K9,
                                prefs: snapshot.data!,
                                id: snapshot.data!.getString(Dbkeys.phone),
                              ),
                              // home: Homepage(
                              //   doc: ,
                              //   prefs: snapshot.data!,
                              //   currentUserNo:
                              //       snapshot.data!.getString(Dbkeys.phone),
                              //   isSecuritySetupDone: snapshot.data!.getString(
                              //               Dbkeys.isSecuritySetupDone) ==
                              //           null
                              //       ? false
                              //       : ((snapshot.data!
                              //                   .getString(Dbkeys.phone) ==
                              //               null)
                              //           ? false
                              //           : (snapshot.data!.getString(Dbkeys
                              //                       .isSecuritySetupDone) ==
                              //                   snapshot.data!
                              //                       .getString(Dbkeys.phone))
                              //               ? true
                              //               : false),
                              // ),

                              // ignore: todo
                              //TODO:---- All localizations settings----
                              locale: _locale,
                              supportedLocales: supportedlocale,
                              localizationsDelegates: [
                                DemoLocalization.delegate,
                                GlobalMaterialLocalizations.delegate,
                                GlobalWidgetsLocalizations.delegate,
                                GlobalCupertinoLocalizations.delegate,
                              ],
                              localeResolutionCallback:
                                  (locale, supportedLocales) {
                                for (var supportedLocale in supportedLocales) {
                                  if (supportedLocale.languageCode ==
                                          locale!.languageCode &&
                                      supportedLocale.countryCode ==
                                          locale.countryCode) {
                                    return supportedLocale;
                                  }
                                }
                                return supportedLocales.first;
                              },
                              //--- All localizations settings ended here----
                            ),
                          ),
                        ),
                      );
                    }
                    return MultiProvider(
                      providers: [
                        ChangeNotifierProvider(create: (_) => UserProvider()),
                      ],
                      child: MaterialApp(
                          theme: ThemeData(
                              fontFamily: FONTFAMILY_NAME,
                              primaryColor: chatgreen,
                              primaryColorLight: chatgreen,
                              indicatorColor: chatLightGreen),
                          debugShowCheckedModeBanner: false,
                          home: Splashscreen()),
                    );
                  });
            }
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Splashscreen(),
            );
          });
    }
  }
}

class CustomError extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const CustomError({
    Key? key,
    required this.errorDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0,
      width: 0,
    );
  }
}

void logError(String code, String? message) {
  if (message != null) {
    print('Error: $code\nError Message: $message');
  } else {
    print('Error: $code');
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
