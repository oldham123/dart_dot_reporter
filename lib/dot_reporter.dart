import 'dart:io';

import 'model.dart';
import 'parser.dart';

import 'package:emojis/emoji.dart';

String warning = Emoji.byName('frowning face with open mouth').char;
String success = Emoji.byName('smiling face with smiling eyes').char;
String defaultSymbol = Emoji.byName('white question mark').char;
String skipped = Emoji.byName('sleeping face').char;
String fail = Emoji.byName('fire').char;

class DotReporter {
  final Parser parser;

  int failedCount = 0;
  int skippedCount = 0;
  int successCount = 0;

  // TODO: move flags to some config model
  final bool showId;
  final bool showSuccess;
  final bool hideSkipped;
  final bool failSkipped;
  final bool showMessage;
  final bool noColor;
  final Stdout out;

  DotReporter({
    this.parser,
    this.showId = false,
    this.showSuccess = false,
    this.hideSkipped = false,
    this.failSkipped = false,
    this.showMessage = false,
    this.noColor = false,
    this.out,
  });

  void printReport() {
    // Mutates results, used to remove invalid parsed data
    parser.tests.removeWhere((k, v) => v.state == null);

    _countTestResults();
    final resultIconsLine = _renderSingleLineOfIcons();
    final result = _renderShortResultLines();

    _render(resultIconsLine, result);

    if (skippedCount > 0 && failSkipped) {
      exitCode = 1;
    }
    if (failedCount > 0) {
      exitCode = 2;
    }
  }

  void _render(String resultIconsLine, String result) {
    out.write(resultIconsLine);

    out.writeln();
    out.writeln();

    out.write(result);

    out.writeln();
    out.writeln();

    out.writeAll(
      [
        'Total: ${parser.tests.length}',
        _green('Success: $successCount'),
        _yellow('Skipped: $skippedCount'),
        _red('Failure: $failedCount'),
      ],
      '\n',
    );
    out.writeln();
  }

  String _renderShortResultLines() {
    return parser.tests.values
        .where((i) {
          final hideSuccess = !showSuccess && i.state == State.Success;
          final _hideSkipped = hideSkipped && i.state == State.Skipped;
          if (_hideSkipped) {
            return false;
          }
          if (hideSuccess) {
            return false;
          }

          return true;
        })
        .map(_testToString)
        .join('\n');
  }

  String _renderSingleLineOfIcons() => parser.tests.values.map(_getIcon).join('');

  void _countTestResults() {
    for (var item in parser.tests.values) {
      switch (item.state) {
        case State.Failure:
          failedCount += 1;
          break;
        case State.Skipped:
          skippedCount += 1;
          break;
        case State.Success:
          successCount += 1;
          break;
        default:
      }
    }
  }

  String _getIcon(TestModel model) {
    switch (model.state) {
      case State.Failure:
        return fail;
      case State.Skipped:
        return skipped;
      case State.Success:
        return success;
      default:
        return defaultSymbol;
    }
  }

  String _testToString(TestModel model) {
    var base = _getIcon(model) + ' ';

    switch (model.state) {
      case State.Failure:
        base += _red(model.name);
        break;
      case State.Skipped:
        base += _yellow(model.name);
        break;
      case State.Success:
        base += _green(model.name);
        break;
      default:
        base += model.name;
        break;
    }

    if (model.message != null && showMessage) {
      base += '\n' + model.message;
    }
    if (showId) {
      return '${model.id} $base';
    }
    return base;
  }

  String _red(String text) {
    if (noColor) {
      return text;
    }
    return '\x1B[31m' + text + '\x1B[0m';
  }

  String _green(String text) {
    if (noColor) {
      return text;
    }
    return '\x1B[32m' + text + '\x1B[0m';
  }

  String _yellow(String text) {
    if (noColor) {
      return text;
    }
    return '\x1B[33m' + text + '\x1B[0m';
  }
}
