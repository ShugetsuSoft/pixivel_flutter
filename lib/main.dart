import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:universal_platform/universal_platform.dart';
import 'pages/main_scaffold.dart';
import 'services/update_service.dart';
import 'widgets/update_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final UpdateService _updateService = UpdateService();
  UpdateInfo? _pendingUpdate;

  @override
  void initState() {
    super.initState();
    // Check for updates after app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    try {
      final updateInfo = await _updateService.checkForUpdates();
      if (updateInfo != null && mounted) {
        // Check if this version was already skipped
        final isSkipped = await _updateService.isVersionSkipped(updateInfo.version);
        if (!isSkipped) {
          setState(() {
            _pendingUpdate = updateInfo;
          });
          _showUpdateDialog(updateInfo);
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  void _showUpdateDialog(UpdateInfo updateInfo) {
    if (!mounted) return;
    
    UpdateDialog.show(
      context,
      updateInfo,
      onSkip: () async {
        await _updateService.skipVersion(updateInfo.version);
        setState(() {
          _pendingUpdate = null;
        });
      },
      onUpdate: () async {
        try {
          await _updateService.downloadAndInstallUpdate(updateInfo.downloadUrl);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to open update: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      onLater: () {
        setState(() {
          _pendingUpdate = null;
        });
      },
    );
  }

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