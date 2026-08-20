import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import 'api_constains.dart';

/// Whether the app can reach the server, watched app-wide.
///
/// Two different questions get confused here, so this keeps them apart:
///
///  * **Is there a network interface?** `connectivity_plus` answers instantly
///    and for free, but it only knows whether Wi-Fi or mobile data is switched
///    on. A hotel Wi-Fi behind a login page, or a SIM out of credit, both look
///    perfectly "connected" to it.
///  * **Does the server actually answer?** Only a real request can say, and it
///    costs a round trip.
///
/// So the interface state drives the fast path — losing it means offline,
/// immediately and certainly — and a real reachability probe backs it up on
/// launch and whenever the user taps Retry.
class ConnectivityService extends GetxService {
  /// What the UI watches. Starts true so nothing flashes an offline screen
  /// during the first frame, before the first check has had a chance to run.
  final RxBool isOnline = true.obs;

  /// True while a probe is in flight, so Retry can show a spinner.
  final RxBool isChecking = false.obs;

  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void onInit() {
    super.onInit();

    _sub = Connectivity().onConnectivityChanged.listen((results) async {
      final hasInterface = !results.contains(ConnectivityResult.none);

      // Losing the interface is conclusive — go offline without a round trip.
      if (!hasInterface) {
        isOnline.value = false;
        return;
      }

      // Gaining one is not: the network may still be a captive portal. Ask the
      // server before telling the user they're back.
      await verify();
    });

    // Don't trust the optimistic `true` any longer than the first probe takes.
    verify();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  /// Asks the server whether it can be reached, and updates [isOnline].
  ///
  /// Uses the public app-version endpoint — it needs no token, returns a few
  /// bytes, and is answered by the same host every other call goes to, so a
  /// success here means the app is genuinely usable.
  Future<bool> verify() async {
    if (isChecking.value) return isOnline.value;
    isChecking.value = true;
    try {
      final client =
          HttpClient()..connectionTimeout = const Duration(seconds: 6);
      final request = await client
          .getUrl(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.appVersion}'),
          )
          .timeout(const Duration(seconds: 8));
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      // Drain so the socket can be reused rather than left hanging.
      await response.drain<void>();
      client.close();

      // Any answer at all proves the server is reachable; the status code is
      // the version endpoint's business, not ours.
      isOnline.value = true;
    } catch (e) {
      log('⚠️ Connectivity probe failed: $e');
      isOnline.value = false;
    } finally {
      isChecking.value = false;
    }
    return isOnline.value;
  }

  /// Completes once the app can reach the server again.
  ///
  /// Used by the splash screen, which has nowhere to send a user who opened the
  /// app with no connection — better to hold there behind the offline screen
  /// than to bounce them to a login they also can't complete.
  Future<void> waitUntilOnline() async {
    if (isOnline.value) return;
    final completer = Completer<void>();
    late Worker worker;
    worker = ever<bool>(isOnline, (online) {
      if (online && !completer.isCompleted) {
        worker.dispose();
        completer.complete();
      }
    });
    return completer.future;
  }
}
