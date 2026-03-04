import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Lint rule that ensures every `catch` block inside a repository class
/// (name ending with `Impl` or implementing an interface ending with
/// `Repository`) contains a `Crashlytics.recordError(...)` call.
class CrashlyticsInCatch extends DartLintRule {
  const CrashlyticsInCatch() : super(code: _code);

  static const _code = LintCode(
    name: 'crashlytics_in_catch',
    problemMessage:
        'catch block in a repository must call Crashlytics.recordError.',
    correctionMessage:
        'Add Crashlytics.recordError(e, st ?? (e as Error?)?.stackTrace, reason: failure.code, data: failure.data);',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCatchClause((node) {
      // Walk up to the enclosing class declaration.
      final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();
      if (classDecl == null) return;

      final className = classDecl.name.lexeme;
      final endsWithImpl = className.endsWith('Impl');

      final implementsRepository =
          classDecl.implementsClause?.interfaces.any(
                (iface) => iface.name2.lexeme.endsWith('Repository'),
              ) ??
          false;

      // Only applies to repository-like classes.
      if (!endsWithImpl && !implementsRepository) return;

      // Search the catch body for a Crashlytics.recordError call.
      final visitor = _CrashlyticsCallVisitor();
      node.body.accept(visitor);

      if (!visitor.found) {
        reporter.atNode(node, _code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_CrashlyticsInCatchFix()];
}

// ---------------------------------------------------------------------------
// Visitor – detects Crashlytics.recordError(...) anywhere in an AST subtree.
// ---------------------------------------------------------------------------

class _CrashlyticsCallVisitor extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target?.toSource() == 'Crashlytics' &&
        node.methodName.name == 'recordError') {
      found = true;
      return; // No need to recurse further once found.
    }
    super.visitMethodInvocation(node);
  }
}

// ---------------------------------------------------------------------------
// Quick fix – inserts Crashlytics.recordError as the first statement.
// ---------------------------------------------------------------------------

class _CrashlyticsInCatchFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addCatchClause((node) {
      // Match only the catch clause that triggered the lint.
      if (node.offset != analysisError.offset) return;

      final exceptionParam = node.exceptionParameter?.name.lexeme ?? 'e';
      final stackTraceParam = node.stackTraceParameter?.name.lexeme ?? 'st';

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Add Crashlytics.recordError call',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        // Insert right after the opening `{` of the catch body.
        final insertOffset = node.body.leftBracket.end;
        builder.addSimpleInsertion(
          insertOffset,
          '\n      Crashlytics.recordError('
              '$exceptionParam, '
              '$stackTraceParam ?? ($exceptionParam as Error?)?.stackTrace, '
              'reason: failure.code, '
              'data: failure.data);',
        );
      });
    });
  }
}
