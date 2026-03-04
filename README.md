# by_lint

Custom Dart lint rules for `by_` Flutter projects.

Currently ships one rule:

| Rule | Severity | Description |
|---|---|---|
| `crashlytics_in_catch` | ⚠️ Warning | Every `catch` block inside a repository class must call `Crashlytics.recordError(...)` |

---

## Installation

### 1. Add to `pubspec.yaml`

```yaml
dev_dependencies:
  custom_lint: ^0.7.0
  by_lint:
    git:
      url: git@github.com:bakberdy/by_lint.git
      ref: main   # or a specific tag / commit SHA
```

Run:

```sh
dart pub get
```

### 2. Enable in `analysis_options.yaml`

```yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    - crashlytics_in_catch: true
```

---

## Running

### In the terminal

```sh
dart run custom_lint
```

### In the IDE

Warnings appear inline in VS Code and Android Studio automatically once the plugin is registered in `analysis_options.yaml` and `dart pub get` has been run. No additional setup is required.

---

## Rules

### `crashlytics_in_catch`

**Applies to** classes whose name ends with `Impl` **or** that implement at least one interface whose name ends with `Repository`.

**Wrong** — missing error reporting:

```dart
class UserRepositoryImpl implements UserRepository {
  Future<User> getUser(String id) async {
    try {
      return await _api.fetchUser(id);
    } catch (e, st) {           // ⚠️ crashlytics_in_catch
      throw ServerFailure();
    }
  }
}
```

**Correct** — error reported to Crashlytics:

```dart
class UserRepositoryImpl implements UserRepository {
  Future<User> getUser(String id) async {
    try {
      return await _api.fetchUser(id);
    } catch (e, st) {
      Crashlytics.recordError(
        e,
        st ?? (e as Error?)?.stackTrace,
        reason: failure.code,
        data: failure.data,
      );
      throw ServerFailure();
    }
  }
}
```

**Quick fix** — a one-click fix is available in the IDE. It inserts the `Crashlytics.recordError(...)` call as the first statement in the catch body, using the actual exception and stack-trace parameter names from your code.

---

## Disabling a rule for a single line

```dart
// ignore: crashlytics_in_catch
} catch (e, st) {
```

## Disabling a rule for an entire file

```dart
// ignore_for_file: crashlytics_in_catch
```

---

## Requirements

- Dart SDK `>=3.0.0 <4.0.0`
- [`custom_lint`](https://pub.dev/packages/custom_lint) `^0.7.0` in the consuming project
