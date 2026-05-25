// ─────────────────────────────────────────────────────────────────────────────
// PARSER (Syntax Analyser) — Phase 2 of Compiler Construction
//
// Responsibility:
//   Takes the token list from the Lexer and validates it against the
//   grammar. Produces an AST node (CommandNode) for each valid command.
//
// Grammar (BNF):
//   program    → statement+
//   statement  → KEYWORD IDENTIFIER NUMBER TERMINATOR
//   KEYWORD    → ADD | SHOW | DELETE | SET | LOG
//   IDENTIFIER → valid domain noun
//   NUMBER     → positive integer
//   TERMINATOR → ;
//
// Error cases:
//   • First token is not a KEYWORD
//   • Second token is not an IDENTIFIER
//   • Third token is not a NUMBER
//   • Fourth token is not a TERMINATOR
//   • IDENTIFIER not in domain vocabulary
//   • NUMBER out of valid range (1–9999)
//   • Missing tokens before TERMINATOR
// ─────────────────────────────────────────────────────────────────────────────

import 'token.dart';

// ── AST Node ──────────────────────────────────────────────────────────────────
class CommandNode {
  final String keyword;
  final String identifier;
  final int    number;

  const CommandNode({
    required this.keyword,
    required this.identifier,
    required this.number,
  });

  @override
  String toString() => 'CommandNode($keyword, $identifier, $number)';
}

// ── Parse result ──────────────────────────────────────────────────────────────
class ParseResult {
  final List<CommandNode> commands;
  final List<String>      errors;
  bool get isValid => errors.isEmpty;

  const ParseResult({required this.commands, required this.errors});
}

// ── Parser ────────────────────────────────────────────────────────────────────
class Parser {
  final List<Token> tokens;
  int _pos = 0;

  Parser(this.tokens);

  ParseResult parse() {
    final commands = <CommandNode>[];
    final errors   = <String>[];

    while (_pos < tokens.length) {
      // Skip stray terminators between statements
      if (_current?.type == TokenType.terminator) { _pos++; continue; }

      final result = _parseStatement();
      if (result != null) {
        commands.add(result);
      } else {
        // Collect error and advance past the next terminator to recover
        errors.add(_lastError);
        _advancePastTerminator();
      }
    }

    return ParseResult(commands: commands, errors: errors);
  }

  // ── Statement parser ──────────────────────────────────────────────────────
  String _lastError = '';

  CommandNode? _parseStatement() {
    // ── Step 1: Expect KEYWORD ────────────────────────────────────────────
    final kwToken = _current;
    if (kwToken == null) return null;

    if (kwToken.type != TokenType.keyword) {
      if (kwToken.type == TokenType.unknown) {
        _lastError = 'Syntax error at position ${kwToken.position}: '
            '"${kwToken.value}" is not a valid keyword. '
            'Expected one of: ADD, SHOW, DELETE, SET, LOG.';
      } else {
        _lastError = 'Syntax error at position ${kwToken.position}: '
            'Expected a KEYWORD (ADD/SHOW/DELETE/SET/LOG) '
            'but found ${kwToken.type.name} "${kwToken.value}".';
      }
      return null;
    }
    _pos++;

    // ── Step 2: Expect IDENTIFIER ─────────────────────────────────────────
    final idToken = _current;
    if (idToken == null || idToken.type == TokenType.terminator) {
      _lastError = 'Syntax error after "${kwToken.value}": '
          'Expected an IDENTIFIER (e.g. supplement, history, target) but found end of statement.';
      return null;
    }
    if (idToken.type != TokenType.identifier) {
      _lastError = 'Syntax error at position ${idToken.position}: '
          'Expected IDENTIFIER after "${kwToken.value}" '
          'but found ${idToken.type.name} "${idToken.value}".';
      return null;
    }
    if (!vitdIdentifiers.contains(idToken.value)) {
      _lastError = 'Semantic error at position ${idToken.position}: '
          '"${idToken.value}" is not a recognised domain identifier. '
          'Valid identifiers: ${vitdIdentifiers.join(', ')}.';
      return null;
    }
    _pos++;

    // ── Step 3: Expect NUMBER ─────────────────────────────────────────────
    final numToken = _current;
    if (numToken == null || numToken.type == TokenType.terminator) {
      _lastError = 'Syntax error after "${kwToken.value} ${idToken.value}": '
          'Expected a NUMBER but found end of statement.';
      return null;
    }
    if (numToken.type != TokenType.number) {
      _lastError = 'Syntax error at position ${numToken.position}: '
          'Expected NUMBER after "${idToken.value}" '
          'but found ${numToken.type.name} "${numToken.value}".';
      return null;
    }
    final number = int.parse(numToken.value);
    if (number < 1 || number > 9999) {
      _lastError = 'Semantic error at position ${numToken.position}: '
          'Number $number is out of valid range (1–9999).';
      return null;
    }
    _pos++;

    // ── Step 4: Expect TERMINATOR ─────────────────────────────────────────
    final termToken = _current;
    if (termToken == null || termToken.type != TokenType.terminator) {
      _lastError = 'Syntax error: Missing ";" after '
          '"${kwToken.value} ${idToken.value} $number". '
          'Every command must end with a semicolon.';
      return null;
    }
    _pos++;

    return CommandNode(
      keyword:    kwToken.value,
      identifier: idToken.value,
      number:     number,
    );
  }

  void _advancePastTerminator() {
    while (_pos < tokens.length && _current?.type != TokenType.terminator) _pos++;
    if (_current?.type == TokenType.terminator) _pos++;
  }

  Token? get _current => _pos < tokens.length ? tokens[_pos] : null;
}
