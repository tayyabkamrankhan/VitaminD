// ─────────────────────────────────────────────────────────────────────────────
// LEXER (Lexical Analyser) — Phase 1 of Compiler Construction
//
// Responsibility:
//   Scans the raw input string character-by-character and converts it into
//   a flat list of Tokens. No grammar is applied here — only tokenisation.
//
// Rules:
//   1. Skip whitespace between tokens.
//   2. If the current character starts a letter → scan full word.
//      - Check if word is a KEYWORD (uppercase match against vitdKeywords).
//      - Else treat as IDENTIFIER.
//      - If the word contains digits → UNKNOWN (e.g. "123abc", "supp1ement").
//   3. If the current character is a digit → scan full integer → NUMBER.
//   4. If the current character is ';' → TERMINATOR.
//   5. Anything else (e.g. '@', '!', '#') → UNKNOWN.
// ─────────────────────────────────────────────────────────────────────────────

import 'token.dart';

class LexerResult {
  final List<Token> tokens;
  final List<String> errors;
  bool get hasErrors => errors.isNotEmpty;

  const LexerResult({required this.tokens, required this.errors});
}

class Lexer {
  final String input;
  int _pos = 0;

  Lexer(this.input);

  // ── Public entry point ────────────────────────────────────────────────────
  LexerResult tokenize() {
    final List<Token> tokens = [];
    final List<String> errors = [];

    while (_pos < input.length) {
      _skipWhitespace();
      if (_pos >= input.length) break;

      final startPos = _pos;
      final ch = input[_pos];

      // ── Rule 3: digit → NUMBER ───────────────────────────────────────────
      if (_isDigit(ch)) {
        final num = _readWhile(_isDigit);
        tokens.add(Token(type: TokenType.number, value: num, position: startPos));
        continue;
      }

      // ── Rule 2: letter → word (KEYWORD or IDENTIFIER) ───────────────────
      if (_isLetter(ch)) {
        final word = _readWhile((c) => _isLetter(c) || _isDigit(c));
        // Words that mix letters + digits are invalid identifiers
        if (word.contains(RegExp(r'\d'))) {
          tokens.add(Token(type: TokenType.unknown, value: word, position: startPos));
          errors.add('Invalid token "$word" at position $startPos — identifiers cannot contain digits.');
        } else if (vitdKeywords.contains(word.toUpperCase()) && word == word.toUpperCase()) {
          tokens.add(Token(type: TokenType.keyword, value: word.toUpperCase(), position: startPos));
        } else {
          // Treat as identifier (case-insensitive domain noun)
          tokens.add(Token(type: TokenType.identifier, value: word.toLowerCase(), position: startPos));
        }
        continue;
      }

      // ── Rule 4: semicolon → TERMINATOR ──────────────────────────────────
      if (ch == ';') {
        tokens.add(Token(type: TokenType.terminator, value: ';', position: startPos));
        _pos++;
        continue;
      }

      // ── Rule 5: unknown character ────────────────────────────────────────
      tokens.add(Token(type: TokenType.unknown, value: ch, position: startPos));
      errors.add('Unexpected character "$ch" at position $startPos.');
      _pos++;
    }

    return LexerResult(tokens: tokens, errors: errors);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _skipWhitespace() {
    while (_pos < input.length && input[_pos].trim().isEmpty) {
      _pos++;
    }
  }

  String _readWhile(bool Function(String) predicate) {
    final start = _pos;
    while (_pos < input.length && predicate(input[_pos])) {
      _pos++;
    }
    return input.substring(start, _pos);
  }

  bool _isDigit(String c)  => RegExp(r'[0-9]').hasMatch(c);
  bool _isLetter(String c) => RegExp(r'[a-zA-Z_]').hasMatch(c);
}
