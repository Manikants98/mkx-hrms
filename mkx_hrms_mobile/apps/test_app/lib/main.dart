import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'screens/music_home_screen.dart';
import 'services/music_audio_handler.dart';

/// Global reference to the system audio background handler.
late final MusicAudioHandler appAudioHandler;

/// Entry point of the Apple Music iOS 26 application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  appAudioHandler = await AudioService.init(
    builder: () => MusicAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.test_app.channel.audio_v2',
      androidNotificationChannelName: 'MKX Music Playback',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
      androidNotificationClickStartsActivity: true,
      androidResumeOnClick: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
      notificationColor: Color(0xFFFA2D48),
      preloadArtwork: true,
      artDownscaleWidth: 512,
      artDownscaleHeight: 512,
    ),
  );
  await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: CupertinoColors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF000000),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    LiquidGlassWidgets.wrap(
      adaptiveQuality: true,
      adaptiveConfig: const GlassAdaptiveScopeConfig(
        initialQuality: GlassQuality.standard,
        allowStepUp: false,
      ),
      theme: const GlassThemeData(
        dark: GlassThemeVariant(quality: GlassQuality.standard),
        light: GlassThemeVariant(quality: GlassQuality.standard),
      ),
      child: const MKXMusicApp(),
    ),
  );
}

/// Root widget configuring Apple Music iOS 26 liquid glass aesthetic.
class MKXMusicApp extends StatelessWidget {
  /// Constructor for MKXMusicApp.
  const MKXMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Apple Music',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => ScaffoldMessenger(
        child: child ?? const SizedBox.shrink(),
      ),
      theme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFFFA2D48),
        scaffoldBackgroundColor: Color(0xFF000000),
        barBackgroundColor: Color(0xCC000000),
      ),
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      home: const MusicHomeScreen(),
    );
  }
}
