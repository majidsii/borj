import 'package:borj/app/bootstrap/app_bootstrap.dart';
import 'package:borj/app/bootstrap/application_entrypoint.dart';

Future<void> main(List<String> arguments) async {
  final entrypoint = buildProductionApplicationEntrypoint(
    normalApplicationRunner: CallbackNormalApplicationRunner(
      _runNormalApplication,
    ),
  );
  await entrypoint.run(arguments);
}

Future<void> _runNormalApplication() async {
  await bootstrapApp();
}
