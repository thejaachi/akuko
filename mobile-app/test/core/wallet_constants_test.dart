import 'package:akuko/core/constants/wallet_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WalletConstants.ngnToCowries', () {
    test('1000 NGN → 50 cowries', () {
      expect(WalletConstants.ngnToCowries(1000), 50);
    });

    test('2000 NGN → 100 cowries', () {
      expect(WalletConstants.ngnToCowries(2000), 100);
    });

    test('999 NGN → invalid (below minimum)', () {
      expect(WalletConstants.ngnToCowries(999), 49);
      expect(WalletConstants.isValidTopUpNgn(999), isFalse);
    });

    test('1500 NGN → 75 cowries (floor)', () {
      expect(WalletConstants.ngnToCowries(1500), 75);
    });
  });

  group('WalletConstants.cowriesToNgnDisplay', () {
    test('50 cowries → ₦1000 display', () {
      expect(WalletConstants.cowriesToNgnDisplay(50), 1000);
    });
  });
}
