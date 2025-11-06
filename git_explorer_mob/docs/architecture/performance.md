# Performance — How to make the app extremely FAST

This document collects concrete performance strategies, profiling tips, and a
prioritized implementation checklist to make Git Explorer Mobile fast and
responsive. The goal is measurable improvements (lower jank, faster cold and
warm starts, smooth scrolling for huge file trees, quick editor open/save).

Notes on scope

- Focus on user-perceivable performance first: cold start, navigation, scrolling large lists, editor responsiveness.
- Measure before changing behavior. Use Flutter DevTools, Observatory, and platform profilers to verify improvements.

## High-level strategies (what to aim for)

- Reduce unnecessary rebuilds and repaints.
- Defer heavy work off the UI thread (use isolates / compute / native processes).
- Avoid allocating many large objects per frame (reuse buffers, use const widgets where possible).
- Virtualize lists and lazily load content on demand.
- Cache expensive results (filesystem metadata, parsed markdown, thumbnails).

## Concrete techniques and where to apply them

### 1 Minimize rebuild scope

- Use provider patterns carefully: prefer `ref.select` (Riverpod) to listen to a single value rather than entire provider objects.
- Break large widgets into smaller, pure widgets and mark them `const` when possible. `const` avoids runtime rebuilds.
- Avoid calling methods that allocate inside `build` (formatters, heavy string operations). Compute those once and store results in state.

### 2 Virtualize and paginate long lists

- Use `ListView.builder`/`SliverList` with `itemCount` and (if possible) `itemExtent` to allow the framework to optimize layout.
- For file trees, render only expanded nodes. Use a flat list model of visible nodes and update it when the expanded state changes — this avoids deep recursion in the widget tree.
- For grids, prefer `SliverGridDelegateWithFixedCrossAxisCount` with predictable dimensions; for complex grids consider `flutter_staggered_grid_view`.

### 3 Debounce and batch UI-triggered work

- Debounce fast UI inputs (search, filter, typing) and perform expensive operations after a short delay or on explicit submit.
- Batch multiple filesystem operations together (e.g., when importing manyfiles, do fewer setState calls — update UI when the batch completes).

### 4 Offload heavy CPU work to isolates or platform code

- Use `compute()` or spawn an `Isolate` for:
  - parsing large files (JSON, YAML)
  - markdown rendering if you pre-process to HTML
  - heavy archive extraction or git operations
- Example: use compute for markdown parsing

```dart
final html = await compute(parseMarkdownToHtml, markdownSource);
```

### 5 Efficient filesystem I/O

- Read files in chunks for very large files, avoid slurping multi-megabyte files into memory unless necessary.
- Cache directory listings and file metadata (mtime, size) and invalidate caches on clear, import or explicit refresh.
- When saving file content from the editor, perform a fast write to a temp file then atomically rename to the final path to reduce the window where indexers/readers can see partial content.

### 6 Reduce memory churn for the editor

- For large files, stream content into the editor widget and limit the amount kept in RAM. Use editor plugins that support virtualized rendering if available.
- Avoid copies of the whole file during operations (editing, formatting, linting). When formatting, operate on ranges if possible.

### 7 UI rendering optimizations

- Use `RepaintBoundary` around heavy widgets that paint frequently to avoid repainting the whole screen.
- Avoid nested `Opacity` or `BackdropFilter` layers on lists.
- Prefer `DecoratedBox` or `Container` with simple backgrounds instead of expensive shader-backed backgrounds.

### 8 Image and icon performance

- Use `FadeInImage` with low-resolution placeholders for thumbnails.
- Pre-scale large images to the needed display size and cache them (e.g.`flutter_cache_manager`) instead of decoding the full resolution each time.

### 9 Network & git operations

- Run network and git work off the UI thread (background isolates or separate services). Provide progress and cancelation.
- Cache git results (commit lists, diffs) and refresh incrementally.

### 10 Startup performance

- Defer non-critical initialization until after first frame: plugin catalog, background indexes, analytics. Use `WidgetsBinding.instance.addPostFrameCallback` or schedule work on the first idle frame.
- Keep the initial displayed widget tree minimal and then populate secondary elements (thumbnails, long lists) lazily.

## Measurement tools & commands

- Flutter DevTools: CPU / Memory / Performance timeline.
- Observatory / Dart DevTools profiler: record allocations, heap snapshots.
- Use `flutter run --profile` or `flutter run --trace-startup` for startup timing.
- On Android: use Systrace or Perfetto. On iOS: Instruments.

Recommended workflow

1. Identify a user-visible hotspot (eg: opening a large project directory).
2. Reproduce the scenario in profile mode: `flutter run --profile`.
3. Record a timeline in DevTools and find the long frames or expensive tasks.
4. Apply a single targeted fix and re-run (measure delta). Prioritize fixes that reduce CPU on the main thread.

## Prioritized checklist (what to do first)

1) Profile the app cold-start and the HomeScreen with a large project(10k files). Identify top 3 expensive functions.
2) Make list rendering for projects and file trees virtualized (Slivers/ListView.builder) and ensure `itemExtent` where possible.
3) Move all archive extraction and git operations into isolates or background services.
4) Add caching for directory listings and markdown rendering (LRU cache).
5) Debounce search and file system watchers; batch UI updates.
6) Replace expensive widget rebuilds by scoping provider listeners with `ref.select` and splitting large widgets.
7) Measure again and repeat.

## Quick code patterns & examples

- Use `ref.select` to only rebuild when a specific value changes:

```dart
final isDark = ref.select((Prefs p) => p.isDarkTheme);
```

- Run heavy parsing in an isolate (example):

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';

Map<String, dynamic> parseLargeJson(String src) => json.decode(src) as Map<String, dynamic>;

final parsed = await compute(parseLargeJson, sourceString);
```

## Caching suggestions

- Directory listing cache: key by absolute path + folder mtime; invalidate on change events or after imports/deletes.
- Rendered README cache: store the parsed HTML/AST for each README by path.
- Thumbnail cache (LRU): for project images and icons use a small in-memory LRU and disk cache via `flutter_cache_manager`.

## Instrumentation and telemetry

- Add simple counters and timers around heavy tasks so you can track them in analytics (optional). Example: time to import a zip, time to open a file.
- Emit events only in profile/dev builds to avoid skewing metrics.

## Long-running maintenance items

- Add automated performance tests: warm/cold start times and interactive scrolling benchmarks using `integration_test`.
- Regularly (weekly/monthly) run profiling on CI emulators if feasible and capture telemetry artifacts.

## Example improvement plan (2-week sprint)

- Week 1:
  - Add directory listing cache and virtualized file tree.
  - Move zip extraction into an isolate.
  - Add DevTools-based benchmarks and a reproducible test case (large test repo).

- Week 2:
  - Debounce search and batch UI updates.
  - Implement README / markdown cache.
  - Optimize editor startup: lazy-load heavy editor plugins and ensure `ref.select` is used to scope rebuilds.

## Final notes

Performance gains are iterative. Always measure before and after a change and
prefer fixes that reduce main-thread CPU usage. If you'd like, I can:

- Add an `integration_test` that reproduces the import/open flow with a large zip and produce a baseline perf artifact.
- Implement the directory listing cache and a small benchmark harness.
