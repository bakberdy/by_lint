import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'src/rules/crashlytics_in_catch.dart';

PluginBase createPlugin() => _ByLint();

class _ByLint extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        CrashlyticsInCatch(),
      ];
}
