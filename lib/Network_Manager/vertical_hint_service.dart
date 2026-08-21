import 'dart:async';
import 'dart:developer';

import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Whatever the phone can say about which floor it is on.
///
/// GPS has no useful vertical resolution, so a check-in at a restaurant on the
/// fourth floor of a mall is indistinguishable from one in the car park below
/// it. These are the only two signals that bear on that, and both are partial:
///
///  * [floor] — iOS only, and only inside venues Apple has surveyed (mostly
///    large malls and airports). Where it exists it is the actual floor index,
///    0 for ground, negative for basement, and needs no interpretation.
///    `geolocator` already surfaces it on `Position`; Android has no equivalent
///    and it is always null there.
///  * [pressureHpa] — a barometer reading. Roughly ~5% of Android models carry
///    the sensor; most iPhones do. On its own it cannot name a floor, because
///    consecutive floors are only ~0.3-0.4 hPa apart while weather and air
///    conditioning move the reading further than that across a day. It is worth
///    sending so the server can one day compare two readings taken in the same
///    building at the same time — which is the only way it becomes an answer.
///
/// Both are sent with the check-in and recorded. Neither decides anything: on
/// most Android handsets both are null, and a rule built on them would reject
/// people for owning the wrong phone.
class VerticalHint {
  const VerticalHint({this.floor, this.pressureHpa});

  final int? floor;
  final double? pressureHpa;

  bool get isEmpty => floor == null && pressureHpa == null;

  /// Multipart form fields, omitting whatever the phone couldn't provide. The
  /// server treats an absent field and an unreadable one the same way.
  Map<String, String> toFields() => {
    if (floor != null) 'floor': '$floor',
    if (pressureHpa != null) 'pressureHpa': pressureHpa!.toStringAsFixed(2),
  };
}

class VerticalHintService {
  /// How long to wait for a barometer sample.
  ///
  /// The stream never fires at all on a phone without the sensor, so this is
  /// the normal path rather than the error path — it has to be short enough
  /// that most check-ins don't notice it. iOS delivers roughly one sample per
  /// second and the rate can't be asked for, so a second and a half is about
  /// the smallest window that still catches one.
  static const Duration _sampleWindow = Duration(milliseconds: 1500);

  /// The last pressure seen, kept so a check-in usually has one to hand without
  /// waiting at all. Cheap: one double, updated by whatever sample arrives.
  static double? _lastPressure;
  static StreamSubscription<BarometerEvent>? _sub;

  /// Starts listening in the background so [read] usually returns instantly.
  ///
  /// Safe to call on a phone with no barometer: `onError` swallows the platform
  /// exception and the reading simply stays null for ever.
  static void start() {
    if (_sub != null) return;
    try {
      _sub = barometerEventStream().listen(
        (event) => _lastPressure = event.pressure,
        onError: (e) {
          log('ℹ️ No barometer on this device: $e');
          _sub?.cancel();
          _sub = null;
        },
        cancelOnError: true,
      );
    } catch (e) {
      log('ℹ️ Barometer unavailable: $e');
    }
  }

  static void stop() {
    _sub?.cancel();
    _sub = null;
  }

  /// Reads both hints for a check-in that is about to be sent.
  ///
  /// [position] is the fix the check-in is already using — passing it avoids a
  /// second GPS read purely to get the floor off it.
  ///
  /// Never throws and never blocks for long: anything it can't get is null, and
  /// a check-in must not fail because a sensor was quiet.
  static Future<VerticalHint> read({Position? position}) async {
    int? floor;
    try {
      floor = position?.floor;
    } catch (e) {
      log('⚠️ Could not read floor: $e');
    }

    var pressure = _lastPressure;
    if (pressure == null) {
      // Nothing cached — the listener may not have started, or this is the
      // first check-in of the session. Wait briefly for one sample.
      start();
      try {
        final event = await barometerEventStream().first.timeout(_sampleWindow);
        pressure = event.pressure;
        _lastPressure = pressure;
      } catch (_) {
        // No sensor, or none arrived in time. Both are ordinary.
      }
    }

    if (floor != null || pressure != null) {
      log('ℹ️ Vertical hint: floor=$floor pressure=$pressure');
    }
    return VerticalHint(floor: floor, pressureHpa: pressure);
  }
}
