import 'package:flutter/material.dart';

import 'app_state.dart';
import 'pages/home_page.dart';
import 'services/pipeline.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.instance.load();
  runApp(const ShenjianApp());
  // 启动后在后台补齐历史记录缺的译文
  Future<void>.delayed(const Duration(milliseconds: 800), () {
    Pipeline.backfill();
  });
}

class ShenjianApp extends StatelessWidget {
  const ShenjianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '声笺',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomePage(),
    );
  }
}
