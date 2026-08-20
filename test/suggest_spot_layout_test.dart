import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outspot/CommonWidgets/ExploreWidgets/redesign/explore_redesign_tokens.dart';

/// The "sent so far" card, in the shape it has on the Suggest a Spot screen.
///
/// Copied here rather than driving the real screen because that one reads GPS
/// and hits the network on init. What matters for this test is the layout: a
/// coloured rail beside a text column, inside a scrolling list.
Widget sentCard({required bool withIntrinsicHeight}) {
  final row = Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(width: 4, color: ExploreColors.gold),
      const Expanded(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text('Aryans Home'), Text('Saidpur Nilphamari')],
          ),
        ),
      ),
    ],
  );

  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            Container(
              child: withIntrinsicHeight ? IntrinsicHeight(child: row) : row,
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  group('The status rail on a "what you\'ve sent" card', () {
    testWidgets('breaks layout without IntrinsicHeight', (tester) async {
      await tester.pumpWidget(sentCard(withIntrinsicHeight: false));
      await tester.pump();

      // A Row inside a ListView is laid out with unbounded height, so
      // `stretch` hands the rail an infinite height constraint and layout
      // fails. That one failure cascades — layout, then paint, then hit test —
      // so what comes back is a bundle of them rather than a single error. The
      // last of that cascade is the "Cannot hit test a render box with no
      // size" seen on the device, one step removed from its actual cause.
      expect(
        tester.takeException(),
        isNotNull,
        reason: 'this is the bug the IntrinsicHeight fix exists for',
      );
    });

    testWidgets('has a real height with IntrinsicHeight', (tester) async {
      await tester.pumpWidget(sentCard(withIntrinsicHeight: true));
      await tester.pump();

      final rail = tester.getSize(find.byType(Container).last);
      expect(rail.height, greaterThan(0));
      expect(rail.width, 4);
    });

    testWidgets('the list still scrolls and takes a tap', (tester) async {
      await tester.pumpWidget(sentCard(withIntrinsicHeight: true));
      await tester.pump();

      // Both of the things the bug broke.
      await tester.drag(find.byType(ListView), const Offset(0, -50));
      await tester.pump();
      await tester.tap(find.text('Aryans Home'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
