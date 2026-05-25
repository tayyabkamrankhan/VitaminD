// ─────────────────────────────────────────────────────────────────────────────
// TOKEN TYPES — Vitamin D Health Command Language
// ─────────────────────────────────────────────────────────────────────────────
//
// Grammar:
//   command    → KEYWORD IDENTIFIER NUMBER TERMINATOR
//   KEYWORD    → ADD | SHOW | DELETE | SET | LOG
//   IDENTIFIER → [a-zA-Z][a-zA-Z_]* (letters and underscores only)
//   NUMBER     → [0-9]+ (positive integer)
//   TERMINATOR → ;
//
// Valid examples:
//   ADD supplement 400 ;
//   SHOW history 7 ;
//   SET target 600 ;
//   LOG symptom 3 ;
//   DELETE record 5 ;
// ─────────────────────────────────────────────────────────────────────────────

enum TokenType {
  keyword,      // ADD, SHOW, DELETE, SET, LOG
  identifier,   // supplement, history, target, symptom, record, session
  number,       // 400, 600, 7, 3 ...
  terminator,   // ;
  unknown,      // anything unrecognised → triggers error
}

class Token {
  final TokenType type;
  final String    value;
  final int       position; // character index in original input

  const Token({
    required this.type,
    required this.value,
    required this.position,
  });

  @override
  String toString() => 'Token(${type.name}, "$value", pos:$position)';
}

// Recognised keywords for the Vitamin D command language
const Set<String> vitdKeywords = {
  'ADD', 'SHOW', 'DELETE', 'SET', 'LOG',
};

// Recognised identifiers (domain nouns specific to VitaminD project)
const Set<String> vitdIdentifiers = {
  'supplement', 'history', 'target', 'symptom',
  'record',     'session', 'report', 'level',
  'result',     'family',  'member', 'dose',
};
