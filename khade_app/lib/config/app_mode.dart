/// Which Khade app build is running — customer (book services) or provider (manage business).
enum KhadeAppMode { customer, provider }

class AppConfig {
  AppConfig._();

  static KhadeAppMode mode = KhadeAppMode.customer;

  static bool get isProviderApp => mode == KhadeAppMode.provider;
  static bool get isCustomerApp => mode == KhadeAppMode.customer;

  static String get appTitle => isProviderApp ? 'Khade Pro' : 'Khade';
  static String get tagline => isProviderApp ? 'for professionals' : 'your beauty, on demand';
}
