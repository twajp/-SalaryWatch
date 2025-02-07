import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'save_settings.dart';
import 'settings_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    // 縦向き
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SalaryWatch',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.green,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.green,
        // textTheme: const TextTheme(
        // displayLarge: TextStyle(fontSize: 64), // 金額表示
        // bodyMedium: TextStyle(fontSize: 14, fontFamily: 'Hind'),
        // ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (BuildContext context) => const StopwatchPage(title: 'SalaryWatch'),
        '/settings': (BuildContext context) => const SettingsPage(title: '設定'),
      },
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en'),
        Locale('ja'),
      ],
    );
  }
}

class StopwatchPage extends StatefulWidget {
  const StopwatchPage({super.key, required this.title});

  final String title;

  @override
  StopwatchPageState createState() => StopwatchPageState();
}

class StopwatchPageState extends State<StopwatchPage> {
  Timer? _stopwatchTimer;
  Timer? _clockTimer;
  Duration _elapsed = Duration.zero;
  DateTime _currentTime = DateTime.now();
  bool _isRunning = false;
  double hourlyWage = 0;

  @override
  void initState() {
    super.initState();
    loadHourlyWage().then((wage) {
      setState(() {
        hourlyWage = wage;
      });
    });
    // 時計用のタイマーを設定して1秒ごとに更新
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    // タイマーのキャンセル
    _stopwatchTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _toggleStopwatch() {
    if (_isRunning) {
      // ストップウォッチが動作中の場合、停止
      _stopwatchTimer?.cancel();
    } else {
      // ストップウォッチが停止している場合、開始
      _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
        setState(() {
          _elapsed += const Duration(milliseconds: 10);
        });
      });
    }
    setState(() {
      _isRunning = !_isRunning; // ストップウォッチの状態をトグル
    });
  }

  void _resetStopwatch() {
    // ストップウォッチをリセット
    _stopwatchTimer?.cancel();
    setState(() {
      _elapsed = Duration.zero;
      _isRunning = false;
    });
  }

  void _navigateToSettings() async {
    RouteSettings settings = RouteSettings(arguments: hourlyWage);
    var result = await Navigator.of(context).push(
      MaterialPageRoute(
        settings: settings,
        builder: (context) => const SettingsPage(title: '設定'),
      ),
    );
    // 設定画面から戻った後、最新の時給を再ロード
    loadHourlyWage().then((wage) {
      setState(() {
        hourlyWage = wage;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // 端末のロケール情報を取得
    final Locale currentLocale = Localizations.localeOf(context);

    // ストップウォッチ下の金額表示用フォーマッタ
    final NumberFormat detailedFormatter = NumberFormat.currency(
      locale: currentLocale.toString(),
      symbol: '',
    );
    detailedFormatter
      ..minimumFractionDigits = currentLocale.languageCode == 'ja' ? 2 : 4
      ..maximumFractionDigits = currentLocale.languageCode == 'ja' ? 2 : 4;

    // 一番下の/h表示用フォーマッタ（通常の小数点以下2桁）
    final NumberFormat standardFormatter = NumberFormat.simpleCurrency(
      locale: currentLocale.toString(),
    );

    // ストップウォッチ下の金額をフォーマット
    final String detailedAmount = detailedFormatter.format(
      _elapsed.inMilliseconds * (hourlyWage / 3600000),
    );

    // 一番下の/h表示用の金額をフォーマット
    final String standardHourlyWage = standardFormatter.format(hourlyWage);

    // 通貨記号
    final String currencySymbol = standardFormatter.currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings, // 設定ページへのナビゲーション
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Expanded(child: SizedBox()),
          Text(
            '${_elapsed.inHours.toString().padLeft(2, '0')}:'
            '${(_elapsed.inMinutes % 60).toString().padLeft(2, '0')}:'
            '${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}.'
            '${(_elapsed.inMilliseconds % 1000 / 10).toStringAsFixed(0).padLeft(2, '0')}',
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(height: 20),
          Text(
            '$currencySymbol$detailedAmount',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _toggleStopwatch,
                child: Text(_isRunning == false ? '開始' : '停止'),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: _resetStopwatch,
                child: const Text('リセット'),
              ),
            ],
          ),
          const Expanded(child: SizedBox()),
          // Text(
          //   // '$currentLocale'
          //   // '${currentLocale.countryCode}'
          //   '$currencySymbol'
          //   '$hourlyWage/h',
          //   style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 18),
          // ),
          Text(
            '$standardHourlyWage/h',
            style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 18),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
