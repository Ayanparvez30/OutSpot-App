import 'package:flutter_test/flutter_test.dart';
import 'package:outspot/Views/ShopCloths/shopCloths_controller.dart';

/// Unit tests for the shared-SKU IAP confirm logic.
///
/// These cover the two pure pieces the purchase flow depends on:
///  - [ShopClothsController.buildItemConfirmBody] — the `/shop/iap/confirm`
///    payload, which MUST carry a per-purchase `transactionId` (the iOS app
///    receipt is cumulative and the SKU is shared, so receipt/productId alone
///    collide → 409 on the 2nd cosmetic).
///  - [ShopClothsController.mapItemConfirmStatus] — HTTP status → outcome,
///    including the 409 "already used" path.
void main() {
  group('mapItemConfirmStatus', () {
    test('200 and 201 → granted', () {
      expect(ShopClothsController.mapItemConfirmStatus(200),
          IapItemConfirm.granted);
      expect(ShopClothsController.mapItemConfirmStatus(201),
          IapItemConfirm.granted);
    });

    test('409 → alreadyUsed (receipt already spent)', () {
      expect(ShopClothsController.mapItemConfirmStatus(409),
          IapItemConfirm.alreadyUsed);
    });

    test('other codes → failed (retryable)', () {
      for (final code in [400, 401, 404, 500, 503]) {
        expect(ShopClothsController.mapItemConfirmStatus(code),
            IapItemConfirm.failed,
            reason: 'HTTP $code should be failed');
      }
    });
  });

  group('buildItemConfirmBody', () {
    Map<String, dynamic> body({
      String receipt = 'rcpt',
      String transactionId = 'txn-1',
      int itemId = 402,
    }) =>
        ShopClothsController.buildItemConfirmBody(
          platform: 'apple',
          productId: 'item_unlock_299',
          receipt: receipt,
          transactionId: transactionId,
          itemId: itemId,
          slot: 'TOP',
          applyNow: true,
        );

    test('carries all required fields incl. transactionId + shared SKU', () {
      final b = body();
      expect(b['platform'], 'apple');
      expect(b['productId'], 'item_unlock_299'); // shared SKU, not per-item
      expect(b['type'], 'item');
      expect(b['itemId'], 402);
      expect(b['slot'], 'TOP');
      expect(b['applyNow'], true);
      expect(b['receipt'], 'rcpt');
      expect(b['transactionId'], 'txn-1');
    });

    test('transactionId is always present (never dropped)', () {
      expect(body().containsKey('transactionId'), isTrue);
    });

    // The core iOS fix: shirt then pant carry the SAME cumulative app receipt
    // and the SAME shared productId, but DIFFERENT per-purchase transaction ids.
    // The backend dedups on transactionId, so both must confirm independently.
    test('iOS: same receipt + same SKU but different txn → distinct dedup key',
        () {
      final shirt = body(receipt: 'same-app-receipt', transactionId: 'txn-1', itemId: 402);
      final pant = body(receipt: 'same-app-receipt', transactionId: 'txn-2', itemId: 511);

      expect(shirt['receipt'], pant['receipt']); // cumulative iOS receipt
      expect(shirt['productId'], pant['productId']); // shared SKU
      expect(shirt['transactionId'], isNot(pant['transactionId'])); // unique key
    });
  });
}
