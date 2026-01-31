import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:path/path.dart' as p;   // for extension()

extension MonacoLanguageHelper on String {
  /// Returns a [MonacoLanguage] that matches the file extension of the
  /// current open file path.
  ///
  /// Example:
  /// ```dart
  /// final lang = getCurrentOpenFile().toMonacoLanguage();
  /// ```
  MonacoLanguage toMonacoLanguage({MonacoLanguage fallback = MonacoLanguage.markdown}) {
    // 1. Get the file path
    final path = this;

    // 2. Extract the extension (without the leading dot)
    final ext = p.extension(path).toLowerCase(); // e.g. ".dart" → "dart"
    final cleanExt = ext.isEmpty ? '' : ext.substring(1); // remove leading dot

    // 3. Map known extensions to Monaco ids
    //    (add more entries when you need additional languages)
    const Map<String, String> extToId = {
      // ── Text / Markup ─────────────────────
      'txt':  'plaintext',
      'md':   'markdown',
      'mdx':  'mdx',
      'html': 'html',
      'htm':  'html',
      'xml':  'xml',
      'json': 'json',
      'yaml': 'yaml',
      'yml':  'yaml',
      'css':  'css',
      'scss': 'scss',
      'less': 'less',

      // ── Scripts ───────────────────────────
      'js':   'javascript',
      'ts':   'typescript',
      'jsx':  'javascript',
      'tsx':  'typescript',
      'c':    'c',
      'cpp':  'cpp',
      'cc':   'cpp',
      'cxx':  'cpp',
      'h':    'c',          // header files usually treated as C/C++
      'hpp':  'cpp',
      'cs':   'csharp',
      'java': 'java',
      'kt':   'kotlin',
      'kts':  'kotlin',
      'py':   'python',
      'go':   'go',
      'rs':   'rust',
      'rb':   'ruby',
      'php':  'php',
      'sh':   'shell',
      'bash': 'shell',
      'zsh':  'shell',
      'ps1':  'powershell',

      // ── Config / Data ─────────────────────
      'ini':  'ini',
      'toml': 'toml',        // not in the enum yet – you can add it
      'dockerfile': 'dockerfile',
      'dockerignore': 'dockerfile',
      'sql':  'sql',
      'pgsql': 'pgsql',
      'mysql': 'mysql',

      // ── Others (add as needed) ───────────
      'dart': 'dart',
      'swift': 'swift',
      'scala': 'scala',
      'lua':  'lua',
      'r':    'r',
      'jl':   'julia',
      'fs':   'fsharp',
      'fsx':  'fsharp',
      'clj':  'clojure',
      'coffee': 'coffeescript',
      'graphql': 'graphql',
      'proto': 'proto',
      'sol':  'sol',
      'tf':   'hcl',         // Terraform
      'tfvars': 'hcl',
    };

    // 4. Look-up the id
    final id = extToId[cleanExt] ?? fallback.id;

    // 5. Resolve the enum value
    return MonacoLanguage.fromId(id, orElse: fallback);
  }
}