/// Lightweight FX helper mirroring the web mock's mock rates so math on
/// multi-currency obligations/remittances stays consistent across clients.
/// TODO(backend): replace with live FX rates from a Supabase edge function.
class Currency {
  static const Map<String, double> _mockRates = {
    'USD': 1,
    'EUR': 0.92,
    'GBP': 0.79,
    'AED': 3.67,
    'INR': 83.35,
    'PHP': 56.12,
    'PKR': 278.50,
    'EGP': 47.50,
    'MYR': 4.75,
    'SGD': 1.35,
    'IDR': 15800,
    'THB': 36.5,
    'VND': 25000,
    'BND': 1.35,
    'MMK': 3500,
    'KHR': 4000,
    'LAK': 21000,
  };

  static double convert(num amount, String from, String to) {
    if (from == to) return amount.toDouble();
    final fromRate = _mockRates[from.toUpperCase()] ?? 1;
    final toRate = _mockRates[to.toUpperCase()] ?? 1;
    final inUsd = amount.toDouble() / fromRate;
    return inUsd * toRate;
  }
}
