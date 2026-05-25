// ─────────────────────────────────────────────────────────────────────────────
// SEMANTIC VALIDATOR — Phase 3 of Compiler Construction
//
// Responsibility:
//   After syntax is confirmed correct, validates the MEANING of each command.
//   Ensures the combination of keyword + identifier + number makes sense
//   in the context of the Vitamin D health app.
//
// Rules:
//   ADD supplement N   → N must be a valid IU value (50–5000)
//   SET target N       → N must be a WHO-valid daily target (200–4000)
//   LOG symptom N      → N must be a severity score (1–5)
//   SHOW history N     → N must be a day range (1–365)
//   DELETE record N    → N must be a valid record ID (1–9999)
//   SHOW result N      → N must be 1–100 (result count)
//   LOG session N      → N must be 1–120 (minutes)
//   SET level N        → N must be 0–300 (ng/mL blood level)
// ─────────────────────────────────────────────────────────────────────────────

import 'parser.dart';

class SemanticResult {
  final CommandNode?  command;   // null if validation failed
  final bool          isValid;
  final String?       error;
  final String?       action;    // what the app will do if valid

  const SemanticResult({
    required this.isValid,
    this.command,
    this.error,
    this.action,
  });
}

class SemanticValidator {
  // Validate a single parsed command
  static SemanticResult validate(CommandNode cmd) {
    final kw  = cmd.keyword;
    final id  = cmd.identifier;
    final num = cmd.number;

    // ── ADD ────────────────────────────────────────────────────────────────
    if (kw == 'ADD') {
      if (id == 'supplement' || id == 'dose') {
        if (num < 50 || num > 5000) {
          return SemanticResult(
            isValid: false,
            error: 'ADD $id: IU value $num is out of range. '
                   'Valid range: 50–5000 IU.',
          );
        }
        return SemanticResult(
          isValid: true, command: cmd,
          action: 'Adding $num IU supplement to today\'s log.',
        );
      }
      if (id == 'member' || id == 'family') {
        if (num < 1 || num > 20) {
          return SemanticResult(
            isValid: false,
            error: 'ADD $id: Member count $num is invalid. Max 20 family members.',
          );
        }
        return SemanticResult(
          isValid: true, command: cmd,
          action: 'Adding $num new family member profile(s).',
        );
      }
    }

    // ── SET ────────────────────────────────────────────────────────────────
    if (kw == 'SET') {
      if (id == 'target') {
        if (num < 200 || num > 4000) {
          return SemanticResult(
            isValid: false,
            error: 'SET target: $num IU is outside safe daily target range (200–4000 IU).',
          );
        }
        return SemanticResult(
          isValid: true, command: cmd,
          action: 'Daily Vitamin D target updated to $num IU.',
        );
      }
      if (id == 'level') {
        if (num < 0 || num > 300) {
          return SemanticResult(
            isValid: false,
            error: 'SET level: $num ng/mL is outside valid blood level range (0–300).',
          );
        }
        return SemanticResult(
          isValid: true, command: cmd,
          action: 'Blood Vitamin D level recorded as $num ng/mL.',
        );
      }
    }

    // ── LOG ────────────────────────────────────────────────────────────────
    if (kw == 'LOG') {
      if (id == 'symptom') {
        if (num < 1 || num > 5) {
          return SemanticResult(
            isValid: false,
            error: 'LOG symptom: Severity $num is invalid. Must be 1–5 (1=mild, 5=severe).',
          );
        }
        return SemanticResult(
          isValid: true, command: cmd,
          action: 'Symptom logged with severity $num/5.',
        );
      }
      if (id == 'session') {
        if (num < 1 || num > 120) {
          return SemanticResult(
            isValid: false,
            error: 'LOG session: $num minutes is invalid. Valid range: 1–120 min.',
          );
        }
        return SemanticResult(
          isValid: true, command: cmd,
          action: 'UV exposure session of $num minutes logged.',
        );
      }
    }

    // ── SHOW ───────────────────────────────────────────────────────────────
    if (kw == 'SHOW') {
      if (id == 'history' || id == 'record') {
        if (num < 1 || num > 365) {
          return SemanticResult(
            isValid: false,
            error: 'SHOW $id: $num days is invalid. Valid range: 1–365 days.',
          );
        }
        return SemanticResult(
          isValid: true, command: cmd,
          action: 'Displaying $id for the last $num days.',
        );
      }
      if (id == 'result' || id == 'report') {
        if (num < 1 || num > 100) {
          return SemanticResult(
            isValid: false,
            error: 'SHOW $id: Count $num is invalid. Valid range: 1–100.',
          );
        }
        return SemanticResult(
          isValid: true, command: cmd,
          action: 'Showing last $num $id entries.',
        );
      }
    }

    // ── DELETE ─────────────────────────────────────────────────────────────
    if (kw == 'DELETE') {
      if (num < 1 || num > 9999) {
        return SemanticResult(
          isValid: false,
          error: 'DELETE $id: ID $num is invalid. Must be 1–9999.',
        );
      }
      return SemanticResult(
        isValid: true, command: cmd,
        action: 'Deleting $id with ID $num from the database.',
      );
    }

    // ── Default (valid syntax, generic handler) ────────────────────────────
    return SemanticResult(
      isValid: true, command: cmd,
      action: 'Executing: $kw $id with value $num.',
    );
  }
}
