import 'dart:convert';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

/// Most of this backend's GET pages are server-rendered HTML, not a JSON
/// API. A handful of pages (notifications, points, contacts) embed their
/// data as a `const NAME = [...]` / `const NAME = {...}` JS literal built
/// from the exact same `json_encode()` call a true API would use — these
/// are scraped here via brace-matching (robust against `];`/`};` appearing
/// inside string content, unlike a naive regex). Pages with no such blob
/// (billing, cart, subscription, orders, card-management's table) are
/// parsed as DOM via the `html` package elsewhere in each service.
class ScrapeUtils {
  ScrapeUtils._();

  /// Extracts and JSON-decodes the literal assigned to `const|var|let name = ...;`
  /// Returns null if the variable isn't found.
  static dynamic extractJsLiteral(String html, String varName) {
    final declRegex = RegExp(r'(?:const|var|let)\s+' + RegExp.escape(varName) + r'\s*=\s*');
    final match = declRegex.firstMatch(html);
    if (match == null) return null;

    var pos = match.end;
    if (pos >= html.length) return null;
    final openChar = html[pos];
    if (openChar != '[' && openChar != '{') return null;
    final closeChar = openChar == '[' ? ']' : '}';

    var depth = 0;
    var inString = false;
    String? quoteChar;
    var escaped = false;
    final start = pos;

    for (; pos < html.length; pos++) {
      final ch = html[pos];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (ch == r'\') {
          escaped = true;
        } else if (ch == quoteChar) {
          inString = false;
        }
        continue;
      }
      if (ch == '"' || ch == "'") {
        inString = true;
        quoteChar = ch;
        continue;
      }
      if (ch == openChar) {
        depth++;
      } else if (ch == closeChar) {
        depth--;
        if (depth == 0) {
          final literal = html.substring(start, pos + 1);
          try {
            return jsonDecode(literal);
          } catch (_) {
            return null;
          }
        }
      }
    }
    return null;
  }

  /// Extracts a value from `name="field" value="..."` in a rendered form.
  static String extractInputValue(String html, String fieldName) {
    final match = RegExp(
      'name=["\']${RegExp.escape(fieldName)}["\']\\s+value=["\']([^"\']*)["\']',
    ).firstMatch(html);
    return match?.group(1) ?? '';
  }

  /// Extracts the `checked` radio's value for a given field name, e.g.
  /// `<input type="radio" name="card_layout" value="classic" ... checked>`.
  static String? extractCheckedRadioValue(String html, String fieldName) {
    final regex = RegExp(
      'name=["\']${RegExp.escape(fieldName)}["\'][^>]*value=["\']([^"\']*)["\'][^>]*checked',
    );
    return regex.firstMatch(html)?.group(1);
  }

  /// Finds [anchor] (e.g. `getElementById('trendChart')`) then, scanning
  /// forward, extracts the bracket-matched array literal following the
  /// first `key:` (e.g. `labels:` or `data:`) — used for Chart.js blocks
  /// that embed their series directly in the `new Chart({...})` call
  /// rather than a standalone `const` (see analytics page research).
  static List<dynamic>? extractArrayAfterAnchor(String html, String anchor, String key) {
    final anchorIndex = html.indexOf(anchor);
    if (anchorIndex == -1) return null;

    // The outer Chart.js `data: { labels, datasets }` object also matches
    // `data:` before the dataset's own inner `data: [...]` array, so keep
    // scanning forward past non-array matches instead of stopping at the
    // first occurrence.
    var searchFrom = anchorIndex;
    int pos;
    while (true) {
      final keyIndex = html.indexOf('$key:', searchFrom);
      if (keyIndex == -1) return null;
      pos = keyIndex + key.length + 1;
      while (pos < html.length && html[pos] == ' ') {
        pos++;
      }
      if (pos < html.length && html[pos] == '[') break;
      searchFrom = keyIndex + key.length + 1;
    }

    var depth = 0;
    var inString = false;
    String? quoteChar;
    var escaped = false;
    final start = pos;
    for (; pos < html.length; pos++) {
      final ch = html[pos];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (ch == r'\') {
          escaped = true;
        } else if (ch == quoteChar) {
          inString = false;
        }
        continue;
      }
      if (ch == '"' || ch == "'") {
        inString = true;
        quoteChar = ch;
        continue;
      }
      if (ch == '[') {
        depth++;
      } else if (ch == ']') {
        depth--;
        if (depth == 0) {
          try {
            return jsonDecode(html.substring(start, pos + 1)) as List<dynamic>;
          } catch (_) {
            return null;
          }
        }
      }
    }
    return null;
  }

  static Document parseDocument(String html) => html_parser.parse(html);

  static String text(Element? el) => el?.text.trim() ?? '';
}
