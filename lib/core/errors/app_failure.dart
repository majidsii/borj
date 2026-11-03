sealed class AppFailure implements Exception {
  const AppFailure(this.userMessage, {this.cause});

  final String userMessage;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $userMessage';
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.userMessage);
}

final class PersistenceFailure extends AppFailure {
  const PersistenceFailure(super.userMessage, {super.cause});
}

final class NotificationFailure extends AppFailure {
  const NotificationFailure(super.userMessage, {super.cause});
}

final class ImportFailure extends AppFailure {
  const ImportFailure(super.userMessage, {super.cause});
}

final class BackupFailure extends AppFailure {
  const BackupFailure(super.userMessage, {super.cause});
}

final class MoneyOverflowFailure extends AppFailure {
  const MoneyOverflowFailure() : super('مبلغ از محدوده قابل نمایش بیشتر است.');
}
