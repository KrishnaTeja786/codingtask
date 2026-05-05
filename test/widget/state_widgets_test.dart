import 'package:codingtask/features/github_trends/presentation/widgets/state_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EmptyStateView renders title and subtitle', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: EmptyStateView(title: 'No items', subtitle: 'try later'),
      ),
    ));

    expect(find.text('No items'), findsOneWidget);
    expect(find.text('try later'), findsOneWidget);
  });

  testWidgets('ErrorRetryView calls onRetry', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ErrorRetryView(
          message: 'oops',
          onRetry: () => tapped++,
        ),
      ),
    ));

    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('OfflineCacheBanner shows recent age', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OfflineCacheBanner(fetchedAt: DateTime.now()),
      ),
    ));
    expect(find.textContaining('cached'), findsOneWidget);
  });
}
