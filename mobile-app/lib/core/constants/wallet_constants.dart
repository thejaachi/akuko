/// Cowrie conversion and wallet-related constants.
class WalletConstants {
  const WalletConstants._();

  // 50 Cowries = ₦1,000 NGN → 1 Cowrie = ₦20 NGN
  static const int cowriesPerThousandNgn = 50;
  static const int minTopUpNgn = 1000;
  static const int minTopUpCowries = 50;

  static int ngnToCowries(num amountNgn) {
    // Cowries = (amount / 1000) * 50, round DOWN to whole integer
    return ((amountNgn / 1000) * cowriesPerThousandNgn).floor();
  }

  static int cowriesToNgnDisplay(int cowries) => cowries * 20; // for UI hints

  static bool isValidTopUpNgn(num amountNgn) =>
      amountNgn >= minTopUpNgn && ngnToCowries(amountNgn) >= minTopUpCowries;
}
