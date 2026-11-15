/// Route paths in one place.
abstract final class Routes {
  static const splash = '/splash';
  static const language = '/language';
  static const onboarding = '/onboarding';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const resetPassword = '/reset-password';
  static const home = '/home';
  static const assistant = '/assistant';
  static const history = '/assistant/history';
  static const activity = '/activity';
  static String transaction(String id) => '/activity/$id';
  static const accounts = '/accounts';
  static const transfer = '/transfer';
  static const transferConfirm = '/transfer/confirm';
  static const transferReceipt = '/transfer/receipt';
  static const insights = '/insights';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const accessibility = '/settings/accessibility';

  static const publicRoutes = {splash, language, onboarding, welcome, login, register, resetPassword};
}
