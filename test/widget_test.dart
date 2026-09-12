// 冒烟测试：APP能构建出Splash开屏并显示logo/标题
import 'package:flutter_test/flutter_test.dart';

import 'package:yzbjfpv/main.dart';

void main() {
  testWidgets('Splash smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const YzbjfpvApp());
    // Splash动画期间应出现标题与格言
    expect(find.text('YZBJFPV'), findsOneWidget);
    expect(find.text('为方便模友而生'), findsOneWidget);
  });
}
