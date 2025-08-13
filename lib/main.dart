import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:universal_platform/universal_platform.dart';
import 'pages/main_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  List<String> get _fontFallbacks {
    if (UniversalPlatform.isMacOS) {
      return const [
        'PingFang SC', // macOS Chinese Simplified
        'PingFang TC', // macOS Chinese Traditional 
        'Hiragino Sans GB', // macOS Chinese fallback
        'Hiragino Kaku Gothic ProN', // macOS Japanese
        'SF Pro Text', // macOS system font
        '.AppleSystemUIFont', // macOS system UI font
        'Yu Gothic', // Japanese
        'Noto Sans CJK SC', // Chinese Simplified
        'Noto Sans CJK TC', // Chinese Traditional
        'Noto Sans CJK JP', // Japanese
      ];
    } else if (UniversalPlatform.isWindows) {
      return const [
        'Microsoft YaHei', // Windows Chinese
        'Yu Gothic', // Windows Japanese
        'Noto Sans CJK SC',
        'Noto Sans CJK TC', 
        'Noto Sans CJK JP',
        'PingFang SC',
        'Hiragino Sans GB',
      ];
    } else {
      // Linux, Android, iOS, Web
      return const [
        'Noto Sans CJK SC',
        'Noto Sans CJK TC',
        'Noto Sans CJK JP',
        'PingFang SC',
        'Hiragino Sans GB',
        'Microsoft YaHei',
        'Yu Gothic',
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixivel',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('zh', 'CN'),
        Locale('zh', 'TW'),
        Locale('ja', ''),
      ],
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
        physics: const BouncingScrollPhysics(),
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0096FA),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansTextTheme().apply(
          fontFamilyFallback: _fontFallbacks,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 65,
          indicatorColor: const Color(0xFF0096FA).withValues(alpha: 0.1),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0096FA),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme).apply(
          fontFamilyFallback: _fontFallbacks,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 65,
          indicatorColor: const Color(0xFF0096FA).withValues(alpha: 0.1),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      ),
      home: const MainScaffold(),
    );
  }
}