// ─────────────────────────────────────────────────────────────────────────────
// COMMAND INTERPRETER — Orchestrates all compiler phases
//
// Pipeline:
//   Raw Input String
//       ↓  Phase 1: Lexer       → Token List
//       ↓  Phase 2: Parser      → AST (CommandNode list)
//       ↓  Phase 3: Semantic    → Validated actions
//       ↓  Output: InterpretResult (success/errors/actions)
// ─────────────────────────────────────────────────────────────────────────────

import 'lexer.dart';
import 'parser.dart';
import 'semantic_validator.dart';
import 'token.dart';

class InterpretResult {
  final List<Token>          tokens;       // from Lexer
  final List<String>         lexerErrors;
  final List<CommandNode>    ast;          // from Parser
  final List<String>         parseErrors;
  final List<SemanticResult> semantics;    // from Validator
  final List<String>         actions;      // what the app does
  final List<String>         allErrors;    // combined

  bool get isFullyValid => allErrors.isEmpty;
  int  get validCount   => semantics.where((s) => s.isValid).length;
  int  get errorCount   => allErrors.length;

  const InterpretResult({
    required this.tokens,
    required this.lexerErrors,
    required this.ast,
    required this.parseErrors,
    required this.semantics,
    required this.actions,
    required this.allErrors,
  });
}

class CommandInterpreter {
  static InterpretResult interpret(String input) {
    // ── Phase 1: Lexical Analysis ─────────────────────────────────────────
    final lexResult = Lexer(input).tokenize();

    // ── Phase 2: Syntax Analysis (Parsing) ────────────────────────────────
    final parseResult = Parser(lexResult.tokens).parse();

    // ── Phase 3: Semantic Validation ──────────────────────────────────────
    final semantics = parseResult.commands
        .map((cmd) => SemanticValidator.validate(cmd))
        .toList();

    final semanticErrors = semantics
        .where((s) => !s.isValid)
        .map((s) => s.error!)
        .toList();

    final actions = semantics
        .where((s) => s.isValid && s.action != null)
        .map((s) => s.action!)
        .toList();

    final allErrors = [
      ...lexResult.errors,
      ...parseResult.errors,
      ...semanticErrors,
    ];

    return InterpretResult(
      tokens:      lexResult.tokens,
      lexerErrors: lexResult.errors,
      ast:         parseResult.commands,
      parseErrors: parseResult.errors,
      semantics:   semantics,
      actions:     actions,
      allErrors:   allErrors,
    );
  }
}
