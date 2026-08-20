import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/offline_screen.dart';
import 'package:outspot/Network_Manager/connectivity_service.dart';

/// Stands in for the real service so the tests can drive the online/offline
/// flag directly, without a device or a network.
class FakeConnectivity extends ConnectivityService {
  int verifyCalls = 0;

  /// What the next [verify] should conclude.
  bool nextResult = true;

  // Skips ConnectivityService.onInit deliberately — that one subscribes to the
  // platform connectivity stream and fires a live probe, neither of which a
  // unit test has.
  // ignore: must_call_super
  @override
  void onInit() {}

  @override
  Future<bool> verify() async {
    verifyCalls++;
    isOnline.value = nextResult;
    return nextResult;
  }
}

/// Sizes the test surface like a phone.
///
/// The default 800x600 is tablet-shaped, and ScreenUtil scales against the
/// 360-wide design — so everything comes out 2.2x too big and the button lands
/// off-screen. That is a harness artefact, not a layout bug.
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget app(Widget child) => ScreenUtilInit(
  designSize: const Size(360, 690),
  builder: (_, __) => GetMaterialApp(
    home: Builder(builder: (_) => OfflineGate(child: child)),
  ),
);

void main() {
  late FakeConnectivity service;

  setUp(() {
    Get.reset();
    service = Get.put<ConnectivityService>(FakeConnectivity())
        as FakeConnectivity;
  });

  group('The offline screen', () {
    testWidgets('stays out of the way while online', (tester) async {
      usePhoneScreen(tester);
      service.isOnline.value = true;
      await tester.pumpWidget(app(const Text('Explore feed')));
      await tester.pump();

      expect(find.text('Explore feed'), findsOneWidget);
      expect(find.text('No connection'), findsNothing);
    });

    testWidgets('covers whatever screen the user was on', (tester) async {
      usePhoneScreen(tester);
      service.isOnline.value = true;
      await tester.pumpWidget(app(const Text('Explore feed')));
      await tester.pump();

      // The connection drops mid-session, on some arbitrary screen.
      service.isOnline.value = false;
      await tester.pump();

      expect(find.text('No connection'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      // The screen underneath is covered, not replaced — nothing was
      // navigated, so the user's place in the app survives the outage.
      expect(find.text('Explore feed'), findsOneWidget);
    });

    testWidgets('Retry asks the server again', (tester) async {
      usePhoneScreen(tester);
      service.isOnline.value = false;
      await tester.pumpWidget(app(const Text('Explore feed')));
      await tester.pump();

      expect(service.verifyCalls, 0);

      // Still offline — the screen stays.
      service.nextResult = false;
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(service.verifyCalls, 1);
      expect(find.text('No connection'), findsOneWidget);

      // Connection is back — one more tap and the screen lets go.
      service.nextResult = true;
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(service.verifyCalls, 2);
      expect(find.text('No connection'), findsNothing);
    });

    testWidgets('lets go on its own when the connection returns', (
      tester,
    ) async {
      usePhoneScreen(tester);
      service.isOnline.value = false;
      await tester.pumpWidget(app(const Text('Explore feed')));
      await tester.pump();
      expect(find.text('No connection'), findsOneWidget);

      // No tap — the service noticed by itself.
      service.isOnline.value = true;
      await tester.pump();

      expect(find.text('No connection'), findsNothing);
      expect(service.verifyCalls, 0);
    });
  });

  group('waitUntilOnline', () {
    test('returns straight away when already online', () async {
      service.isOnline.value = true;
      // Would hang forever if it waited regardless.
      await service.waitUntilOnline().timeout(const Duration(seconds: 1));
    });

    test('completes once the connection comes back', () async {
      service.isOnline.value = false;

      var done = false;
      // ignore: unawaited_futures
      service.waitUntilOnline().then((_) => done = true);

      await Future<void>.delayed(Duration.zero);
      expect(done, isFalse, reason: 'still offline');

      service.isOnline.value = true;
      await Future<void>.delayed(Duration.zero);

      expect(done, isTrue);
    });
  });
}
