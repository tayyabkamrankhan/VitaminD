import 'package:flutter/material.dart';
import '../../core/compiler/command_interpreter.dart';
import '../../core/compiler/token.dart';
import '../../core/compiler/parser.dart';
import '../../core/compiler/semantic_validator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Compiler Demo Screen — integrated into the Vitamin D Sensor app
// Accessible from Health Hub → "Command Mode" tab
// ─────────────────────────────────────────────────────────────────────────────

class CompilerScreen extends StatefulWidget {
  const CompilerScreen({super.key});

  @override
  State<CompilerScreen> createState() => _CompilerScreenState();
}

class _CompilerScreenState extends State<CompilerScreen> {
  final _ctrl    = TextEditingController();
  InterpretResult? _result;

  // Colour palette matching app theme
  static const _bg      = Color(0xFF0D0D1A);
  static const _card    = Color(0xFF12122A);
  static const _primary = Color(0xFF818CF8);
  static const _green   = Color(0xFF4ADE80);
  static const _red     = Color(0xFFF87171);
  static const _yellow  = Color(0xFFFBBF24);
  static const _accent  = Color(0xFF38BDF8);
  static const _muted   = Color(0xFF8888AA);
  static const _border  = Color(0xFF2A2A4A);

  void _run() {
    final input = _ctrl.text.trim();
    if (input.isEmpty) return;
    setState(() => _result = CommandInterpreter.interpret(input));
  }

  void _loadExample(String ex) {
    _ctrl.text = ex;
    _run();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: const Text('Health Command Interpreter',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Info banner ────────────────────────────────────────────────
          _card_(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: const [
              Icon(Icons.code_rounded, color: _primary, size: 18),
              SizedBox(width: 8),
              Text('Compiler Construction Integration',
                  style: TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            const Text(
              'Type health commands below. The interpreter runs three compiler phases:\n'
              '  1. Lexical Analysis   → Tokenisation\n'
              '  2. Syntax Analysis    → Grammar validation\n'
              '  3. Semantic Analysis  → Meaning validation',
              style: TextStyle(color: _muted, fontSize: 12, height: 1.6),
            ),
          ])),
          const SizedBox(height: 12),

          // ── Grammar reference ──────────────────────────────────────────
          _card_(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Grammar: KEYWORD  IDENTIFIER  NUMBER  ;',
                style: TextStyle(color: _accent, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Keywords:     ADD | SHOW | DELETE | SET | LOG',
                style: TextStyle(color: _muted, fontSize: 11, fontFamily: 'monospace')),
            const Text('Identifiers:  supplement | history | target | symptom | record | session | report | level | dose | family',
                style: TextStyle(color: _muted, fontSize: 11, fontFamily: 'monospace')),
            const Text('Number:       1 – 9999',
                style: TextStyle(color: _muted, fontSize: 11, fontFamily: 'monospace')),
          ])),
          const SizedBox(height: 12),

          // ── Examples ──────────────────────────────────────────────────
          const Text('Quick Examples', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _exBtn('ADD supplement 400 ;', true),
            _exBtn('SHOW history 7 ;', true),
            _exBtn('SET target 600 ;', true),
            _exBtn('LOG symptom 3 ;', true),
            _exBtn('DELETE record 5 ;', true),
            _exBtn('ADD supplement 400 ; SHOW history 7 ; DELETE record 5 ;', true),
            _exBtn('ADD 123abc 50 ;', false),
            _exBtn('SHOW result ;', false),
            _exBtn('DELETE @record 5 ;', false),
            _exBtn('ADD supplement 9999 ;', false),
          ]),
          const SizedBox(height: 16),

          // ── Input ─────────────────────────────────────────────────────
          TextField(
            controller: _ctrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              filled: true, fillColor: _card,
              hintText: 'e.g.  ADD supplement 400 ; SHOW history 7 ;',
              hintStyle: TextStyle(color: _muted.withOpacity(0.6), fontFamily: 'monospace', fontSize: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primary, width: 1.5)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _run,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Run Interpreter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // ── Results ───────────────────────────────────────────────────
          if (_result != null) ...[
            const SizedBox(height: 20),
            _ResultPanel(result: _result!),
          ],
        ]),
      ),
    );
  }

  Widget _exBtn(String text, bool valid) => GestureDetector(
    onTap: () => _loadExample(text),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: valid ? const Color(0xFF1A3D2A) : const Color(0xFF3D1212),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: valid ? _green : _red, width: 0.5),
      ),
      child: Text(text,
          style: TextStyle(color: valid ? _green : _red,
              fontSize: 10, fontFamily: 'monospace')),
    ),
  );

  Widget _card_({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 0.5)),
    child: child,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Result Panel Widget
// ─────────────────────────────────────────────────────────────────────────────
class _ResultPanel extends StatelessWidget {
  final InterpretResult result;
  const _ResultPanel({required this.result});

  static const _card    = Color(0xFF12122A);
  static const _primary = Color(0xFF818CF8);
  static const _green   = Color(0xFF4ADE80);
  static const _red     = Color(0xFFF87171);
  static const _yellow  = Color(0xFFFBBF24);
  static const _accent  = Color(0xFF38BDF8);
  static const _muted   = Color(0xFF8888AA);
  static const _border  = Color(0xFF2A2A4A);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Status header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: result.isFullyValid ? const Color(0xFF1A3D2A) : const Color(0xFF3D1212),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: result.isFullyValid ? _green : _red, width: 0.5),
        ),
        child: Row(children: [
          Icon(result.isFullyValid ? Icons.check_circle_rounded : Icons.error_rounded,
              color: result.isFullyValid ? _green : _red, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(
            result.isFullyValid
                ? '✓  ${result.validCount} command(s) valid — executing actions'
                : '✗  ${result.errorCount} error(s) found — execution stopped',
            style: TextStyle(
                color: result.isFullyValid ? _green : _red,
                fontWeight: FontWeight.w600, fontSize: 13),
          )),
        ]),
      ),
      const SizedBox(height: 14),

      // ── Phase 1: Tokens ──────────────────────────────────────────────
      _sectionTitle('Phase 1 — Lexical Analysis (Tokens)', _accent),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6,
        children: result.tokens.map((t) => _TokenChip(token: t)).toList(),
      ),
      if (result.lexerErrors.isNotEmpty) ...[
        const SizedBox(height: 8),
        ...result.lexerErrors.map((e) => _errorRow(e)),
      ],
      const SizedBox(height: 14),

      // ── Phase 2: AST ────────────────────────────────────────────────
      _sectionTitle('Phase 2 — Syntax Analysis (Parse Tree)', _yellow),
      const SizedBox(height: 8),
      if (result.ast.isEmpty)
        _infoRow('No valid statements parsed.', _red)
      else
        ...result.ast.map((cmd) => _ASTCard(cmd: cmd)),
      if (result.parseErrors.isNotEmpty) ...[
        const SizedBox(height: 6),
        ...result.parseErrors.map((e) => _errorRow(e)),
      ],
      const SizedBox(height: 14),

      // ── Phase 3: Semantic + Actions ──────────────────────────────────
      _sectionTitle('Phase 3 — Semantic Validation & Actions', _green),
      const SizedBox(height: 8),
      if (result.actions.isEmpty && result.semantics.every((s) => !s.isValid))
        _infoRow('No actions executed.', _red)
      else
        ...result.semantics.map((s) => _SemanticCard(sem: s)),
    ]);
  }

  Widget _sectionTitle(String t, Color c) => Text(t,
      style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 13));

  Widget _errorRow(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: const Color(0xFF3D1212),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _red, width: 0.5)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.error_outline, color: _red, size: 14),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(color: _red, fontSize: 11))),
    ]),
  );

  Widget _infoRow(String msg, Color c) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(msg, style: TextStyle(color: c, fontSize: 12)),
  );
}

class _TokenChip extends StatelessWidget {
  final Token token;
  const _TokenChip({required this.token});

  Color get _color {
    switch (token.type) {
      case TokenType.keyword:    return const Color(0xFF818CF8);
      case TokenType.identifier: return const Color(0xFF38BDF8);
      case TokenType.number:     return const Color(0xFF4ADE80);
      case TokenType.terminator: return const Color(0xFFFBBF24);
      case TokenType.unknown:    return const Color(0xFFF87171);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color, width: 0.5),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(token.value,
            style: TextStyle(color: _color, fontFamily: 'monospace',
                fontSize: 12, fontWeight: FontWeight.w600)),
        Text(token.type.name,
            style: TextStyle(color: _color.withOpacity(0.7), fontSize: 9)),
      ]),
    );
  }
}

class _ASTCard extends StatelessWidget {
  final CommandNode cmd;
  const _ASTCard({required this.cmd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFBBF24), width: 0.5),
      ),
      child: Row(children: [
        const Icon(Icons.account_tree_rounded, color: Color(0xFFFBBF24), size: 16),
        const SizedBox(width: 10),
        Text('CommandNode  ', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
        Text('keyword=', style: const TextStyle(color: Color(0xFF8888AA), fontSize: 11)),
        Text('${cmd.keyword}  ', style: const TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
        Text('id=', style: const TextStyle(color: Color(0xFF8888AA), fontSize: 11)),
        Text('${cmd.identifier}  ', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontFamily: 'monospace')),
        Text('num=', style: const TextStyle(color: Color(0xFF8888AA), fontSize: 11)),
        Text('${cmd.number}', style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 11, fontFamily: 'monospace')),
      ]),
    );
  }
}

class _SemanticCard extends StatelessWidget {
  final SemanticResult sem;
  const _SemanticCard({required this.sem});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: sem.isValid ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
          width: 0.5,
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(sem.isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: sem.isValid ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
            size: 16),
        const SizedBox(width: 10),
        Expanded(child: Text(
          sem.isValid ? (sem.action ?? '') : (sem.error ?? ''),
          style: TextStyle(
              color: sem.isValid ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
              fontSize: 12),
        )),
      ]),
    );
  }
}
