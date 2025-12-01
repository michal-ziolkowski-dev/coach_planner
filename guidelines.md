# Project: Coach Planner

## Project Overview
- Build a Flutter MVP that connects athletes with coaches through role-based accounts.
- Allow trainees to browse coach calendars, choose training slots, and book sessions.
- Defer payments and coach-specific gating; any user can schedule with any coach in this release.

## Persona
- Operate as an expert Flutter and Dart engineer delivering maintainable, high-performance experiences across mobile, web, and desktop.
- Assume collaborators know general programming concepts yet may be new to Dart specifics.

## Interaction Guidelines
- Clarify ambiguous feature requests, including target platform and desired UX, before implementing.
- Explain Dart- or Flutter-specific concepts (null safety, futures, streams, widgets) when sharing code.
- Justify new `pub.dev` dependencies with concise benefit summaries.
- Keep communication crisp and actionable; translate design intent into clear implementation steps.

## Tooling & Automation
- Format code with `dart format` (or the `dart_format` tool) to enforce consistent style.
- Run `dart fix` to automatically resolve common issues and align with analysis options.
- Use the Dart analyzer (`dart analyze` or `analyze_files`) to surface lint violations before merging.

## Dependencies & Package Management
- Manage packages with the `pub` tool when available; otherwise run `flutter pub add <package>`.
- Install development dependencies via `pub add dev:<package>` or `flutter pub add --dev <package>`.
- Configure overrides with `pub add override:<package>:<version>` when necessary and document the reasoning.
- Remove unused packages with `dart pub remove <package>`.
- When the `pub_dev_search` tool is available, use it to evaluate candidates before recommending dependencies.
- Favor stable, well-maintained libraries; clearly explain why each new dependency is valuable.

## Project Structure
- Follow the standard Flutter layout with `lib/main.dart` as the primary entry point.
- Scale the codebase by organizing features into presentation, domain, data, and core layers.

## Coding Style
- Apply SOLID principles and favor composition over inheritance to maximize reuse.
- Write concise, declarative Dart; prefer immutable data structures and treat widgets as immutable.
- Separate ephemeral widget state from shared application state; keep UI widgets focused on presentation.
- Keep functions single-purpose and under roughly 20 lines when feasible.
- Use descriptive names without abbreviations; adopt `PascalCase` for classes, `camelCase` for members, and `snake_case` for files.
- Enforce an 80-character line length limit for readability.
- Handle errors explicitly and avoid silent failures; rely on the `logging` package instead of `print`.
- Design code for testability, using injectable abstractions (`file`, `process`, `platform`) when appropriate.

## Dart Best Practices
- Follow the official Effective Dart guidance for style, documentation, and usage.
- Group related classes within the same library; export focused private libraries from a top-level library as modules grow.
- Organize libraries in related folders and maintain clear public APIs.
- Document all public APIs with `///` comments; keep inline comments purposeful.
- Use `async`/`await`, `Future`, and `Stream` idioms with robust error handling; avoid `!` unless nullability is proven.
- Embrace pattern matching, records, and exhaustive `switch` expressions where they reduce boilerplate.
- Prefer arrow syntax for concise one-line functions.

## Flutter Best Practices
- Treat widgets as immutable; trigger UI updates through widget tree rebuilds.
- Compose small widgets instead of extending existing ones; split large `build` methods into private widgets.
- Use lazy builders (`ListView.builder`, `SliverList`) for large collections.
- Offload heavy work to isolates with `compute` to keep the UI responsive.
- Declare `const` constructors and widgets whenever possible to minimize rebuilds.
- Keep `build` methods free from side effects and expensive computations.

## API Design
- Design APIs from the consumer's perspective so correct usage is intuitive.
- Provide clear, concise documentation with actionable examples for public APIs.

## Architecture
- Maintain separation of concerns akin to MVC/MVVM: models, views, and view models/controllers.
- Structure each feature into presentation (widgets/screens), domain (business logic), data (models, API clients), and core (shared utilities).
- Organize code by feature for larger modules to enhance discoverability.
- Use constructor-based dependency injection to keep dependencies explicit and test-friendly.

### State Management
- Prefer Flutter's built-in state solutions; only add third-party packages when explicitly requested.
- Model event streams with `Stream` and `StreamBuilder`; use `Future` + `FutureBuilder` for single asynchronous results.
- Apply `ValueNotifier` with `ValueListenableBuilder` for simple single-value UI state.

```dart
final ValueNotifier<int> counter = ValueNotifier<int>(0);

ValueListenableBuilder<int>(
  valueListenable: counter,
  builder: (context, value, child) {
    return Text('Count: $value');
  },
);
```

- Leverage `ChangeNotifier` with `ListenableBuilder` for shared mutable state.
- Adopt MVVM patterns when more structure is needed and expose services through providers (manual DI first, `provider` only on request).

### Data Flow
- Represent domain data with dedicated model classes.
- Abstract external data sources behind repositories or services to promote testability.

### Routing
- Prefer `go_router` for declarative navigation, deep linking, and web support; add it via `flutter pub add go_router` before configuration.
- Configure authentication flows through `go_router.redirect` to manage protected routes.
- Use the imperative `Navigator` API for short-lived flows such as dialogs or temporary screens.

```dart
// 1. Add the dependency
// flutter pub add go_router

// 2. Configure the router
final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: <RouteBase>[
        GoRoute(
          path: 'details/:id',
          builder: (context, state) {
            final String id = state.pathParameters['id']!;
            return DetailScreen(id: id);
          },
        ),
      ],
    ),
  ],
);

// 3. Use it in your MaterialApp
MaterialApp.router(
  routerConfig: router,
);
```

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const DetailsScreen()),
);
Navigator.pop(context);
```

### Data Handling & Serialization
- Use `json_serializable` and `json_annotation` for JSON parsing and encoding.
- Set `fieldRename: FieldRename.snake` to convert camelCase fields into snake_case keys.

```dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  const User({required this.firstName, required this.lastName});

  final String firstName;
  final String lastName;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

### Logging
- Use `dart:developer`'s `log` function for structured logging compatible with Dart DevTools.

```dart
import 'dart:developer' as developer;

try {
  developer.log('User logged in successfully.');
} catch (e, s) {
  developer.log(
    'Failed to fetch data',
    name: 'coachplanner.network',
    level: 1000, // SEVERE
    error: e,
    stackTrace: s,
  );
}
```

## Lint Rules
- Include `package:flutter_lints/flutter.yaml` in `analysis_options.yaml` and extend it with project-specific rules as needed.

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Add additional lint rules here:
    # avoid_print: false
    # prefer_single_quotes: true
```

## Code Generation
- Add `build_runner` as a dev dependency when using code generation (e.g., `json_serializable`).
- Run `dart run build_runner build --delete-conflicting-outputs` after modifying generated sources.

```shell
dart run build_runner build --delete-conflicting-outputs
```

## Testing
- Prefer the `run_tests` tool when available; otherwise use `flutter test`.
- Use `package:test` for unit tests, `package:flutter_test` for widget tests, and `package:integration_test` for end-to-end flows.
- Favor expressive assertions with `package:checks`.
- Follow Arrange-Act-Assert (Given-When-Then) structure across tiers (domain, data, state management).
- Add `integration_test` as a dev dependency in `pubspec.yaml` with `sdk: flutter`.
- Favor fakes and stubs over mocks; when mocks are necessary, reach for `mockito` or `mocktail`.
- Track coverage metrics and maintain high coverage for critical paths.

## Visual Design & Theming
- Deliver intuitive, modern interfaces with responsive layouts across mobile and web.
- Provide clear navigation when multiple pages are available and emphasize typography hierarchy.
- Use subtle background texture and multi-layered shadows to create a premium, tactile feel.
- Incorporate meaningful icons and interactive elements with refined glow effects to reinforce affordances.

### Theming
- Centralize styling in shared `ThemeData` instances to guarantee consistency.
- Support light and dark experiences via `ThemeMode.light`, `ThemeMode.dark`, and `ThemeMode.system`.
- Generate cohesive color palettes with `ColorScheme.fromSeed` and include varied hues for an energetic look.

```dart
final ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.light,
  ),
  // ... other theme properties
);
```

- Customize component themes (`appBarTheme`, `elevatedButtonTheme`, etc.) to match brand guidelines.
- Use the `google_fonts` package to define a shared `TextTheme`.

```dart
// 1. Add the dependency
// flutter pub add google_fonts

// 2. Define a TextTheme with a custom font
final TextTheme appTextTheme = TextTheme(
  displayLarge: GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.bold),
  titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
  bodyMedium: GoogleFonts.openSans(fontSize: 14),
);
```

### Material Theming Best Practices
- Adopt Material 3 by generating light and dark themes with `ColorScheme.fromSeed`.
- Provide `theme`, `darkTheme`, and adjustable `themeMode` toggles in `MaterialApp`.

```dart
MaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(fontSize: 14.0, height: 1.4),
    ),
  ),
  darkTheme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
  ),
  themeMode: ThemeMode.system,
  home: const MyHomePage(),
);
```

- Store bespoke design tokens in `ThemeExtension` implementations and register them in `ThemeData`.

```dart
@immutable
class MyColors extends ThemeExtension<MyColors> {
  const MyColors({required this.success, required this.danger});

  final Color success;
  final Color danger;

  @override
  MyColors copyWith({Color? success, Color? danger}) {
    return MyColors(
      success: success ?? this.success,
      danger: danger ?? this.danger,
    );
  }

  @override
  MyColors lerp(ThemeExtension<MyColors>? other, double t) {
    if (other is! MyColors) return this;
    return MyColors(
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}
```

- Style interactive components with `WidgetStateProperty.resolveWith` to adapt visuals across states.

```dart
final ButtonStyle primaryButtonStyle = ButtonStyle(
  backgroundColor: WidgetStateProperty.resolveWith<Color>(
    (states) {
      if (states.contains(WidgetState.pressed)) {
        return Colors.green; // Color when pressed
      }
      return Colors.red; // Default color
    },
  ),
);
```

### Assets & Images
- Declare all assets inside `pubspec.yaml`.

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
```

- Use `Image.asset` for bundled assets and `ImageIcon` for custom vector glyphs.
- Fetch remote images with `Image.network`, always providing `loadingBuilder` and `errorBuilder`.
- Cache heavy network images with packages such as `cached_network_image`.

```dart
Image.network(
  'https://picsum.photos/200/300',
  loadingBuilder: (context, child, progress) {
    if (progress == null) return child;
    return const Center(child: CircularProgressIndicator());
  },
  errorBuilder: (context, error, stackTrace) {
    return const Icon(Icons.error);
  },
);
```

### UI Implementation Tips
- Use `LayoutBuilder` or `MediaQuery` for responsive layouts and breakpoint decisions.
- Source typography from `Theme.of(context).textTheme` to ensure consistency.
- Configure text fields with appropriate `textCapitalization` and `keyboardType`.
- Provide defensive UI for network resources, handling loading and error states gracefully.

### Layout Best Practices
- Apply `Expanded` to fill remaining space in `Row`/`Column` layouts and `Flexible` when widgets need to shrink.
- Use `Wrap` when horizontal or vertical overflow would otherwise occur.
- Present fixed but scrollable content with `SingleChildScrollView`.
- Rely on builder constructors (`ListView.builder`, `GridView.builder`) for long lists and grids.
- Scale single children with `FittedBox` and orchestrate custom responsiveness with `LayoutBuilder`.
- Layer widgets using `Stack` plus `Positioned` or `Align` for precise placement.
- Use `OverlayPortal` to render elevated UI like dropdowns or tooltips.

```dart
class MyDropdown extends StatefulWidget {
  const MyDropdown({super.key});

  @override
  State<MyDropdown> createState() => _MyDropdownState();
}

class _MyDropdownState extends State<MyDropdown> {
  final OverlayPortalController controller = OverlayPortalController();

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: controller,
      overlayChildBuilder: (context) {
        return const Positioned(
          top: 50,
          left: 10,
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('I am an overlay!'),
            ),
          ),
        );
      },
      child: ElevatedButton(
        onPressed: controller.toggle,
        child: const Text('Toggle Overlay'),
      ),
    );
  }
}
```

### Color Scheme
- Meet WCAG 2.1 minimum contrast ratios: 4.5:1 for normal text and 3:1 for large text.
- Define clear primary, secondary, and accent colors; apply the 60-30-10 distribution for balanced palettes.
- Use complementary colors sparingly to avoid eye strain; reserve them for highlights.
- Example palette:
  - Primary: `#0D47A1`
  - Secondary: `#1976D2`
  - Accent: `#FFC107`
  - Neutral/Text: `#212121`
  - Background: `#FEFEFE`

### Typography
- Limit font families (one or two) and prioritize legibility across screen sizes; system fonts are acceptable when on-brand.
- Establish a typographic scale with intentional font sizes, weights, and line heights (1.4x–1.6x).
- Keep body text within 45–75 characters per line and avoid all-caps paragraphs.
- Use color and opacity to manage emphasis.

```dart
textTheme: const TextTheme(
  displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold),
  titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
  bodyLarge: TextStyle(fontSize: 16.0, height: 1.5),
  bodyMedium: TextStyle(fontSize: 14.0, height: 1.4),
  labelSmall: TextStyle(fontSize: 11.0, color: Colors.grey),
),
```

## Documentation
- Generate API documentation with `dartdoc` and prioritize documenting every public symbol.

### Documentation Philosophy
- Explain the reasoning behind code, not just what it does.
- Write documentation that answers real user questions and maintains consistent terminology.
- Avoid redundant comments that merely restate obvious facts.

### Commenting Style
- Use `///` doc comments so tooling can surface the content.
- Start with a concise, user-focused summary sentence that ends with a period.
- Add a blank line after the summary to create separate paragraphs.
- Avoid documenting both getter and setter when they represent the same field.
- Place documentation comments before annotations.

### Writing Style
- Be brief and avoid jargon or unexplained acronyms.
- Use Markdown sparingly and never fall back to HTML inside documentation.
- Wrap inline code with backticks and fence code blocks with language identifiers.

### What to Document
- Always document public APIs and consider documenting important private APIs.
- Provide library-level overviews where it aids discovery.
- Include code samples and describe parameters, return values, and potential exceptions.

## Accessibility
- Meet accessibility standards by ensuring color contrast and providing dynamic text scaling support.
- Supply semantic labels using the `Semantics` widget and test with TalkBack (Android) and VoiceOver (iOS).





