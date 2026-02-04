import 'package:flutter/foundation.dart';

/// Simple singleton notifier used to signal that the projects folder
/// has changed (e.g. when a ZIP extraction creates a new project folder).
class ProjectsUpdateNotifier extends ChangeNotifier {
  ProjectsUpdateNotifier._();
  static final ProjectsUpdateNotifier instance = ProjectsUpdateNotifier._();

  /// Notify listeners that projects changed.
  void markUpdated() => notifyListeners();
}
