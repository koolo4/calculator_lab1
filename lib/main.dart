import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(const MaterialApp(
  title: 'Calculator',
  debugShowCheckedModeBanner: false,
  home: CalculatorScreen(),
));

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expr = '', _result = '0';
  String? _pressed;
  bool _calculated = false, _dark = true;

  static const _maxLen = 30;

  static const _colors = [
    [0xFF6B6B6B, 0xFF2196F3, 0xFF37474F, 0xFF1A2634, 0xFFECEFF1, 0xFF263545, 0xFF212121, 0xFF757575],
    [0xFFE0E0E0, 0xFF42A5F5, 0xFFB0BEC5, 0xFFF5F5F5, 0xFFFFFFFF, 0xFFE8EDF2, 0xFF212121, 0xFF9E9E9E],
  ];

  Color _c(int i) => Color(_colors[_dark ? 0 : 1][i]);

  void _onTap(String v) {
    setState(() {
      if (v == 'C') {
        _expr = '';
        _result = '0';
        _calculated = false;
      } else if (v == '=') {
        _calculate();
      } else if (v == '☀️' || v == '🌙') {
        _dark = !_dark;
      } else if ('÷×-+^'.contains(v)) {
        _appendOp({'÷': '/', '×': '*'}[v] ?? v);
      } else if (v == '.') {
        _appendDec();
      } else {
        _appendDigit(v);
      }
    });
  }

  void _appendDigit(String d) {
    if (_calculated) {
      _expr = d;
      _result = '0';
      _calculated = false;
      return;
    }
    if (_expr.length < _maxLen) {
      _expr += d;
    }
  }

  void _appendOp(String op) {
    if (_expr.length >= _maxLen) return;
    if (_calculated) {
      if (_result == 'Ошибка' || _result == 'Бесконечность') {
        _expr = op == '-' ? '-' : '';
        _result = '0';
        _calculated = false;
        return;
      }
      _expr = _result + op;
      _calculated = false;
      return;
    }
    if (_expr.isEmpty) {
      if (op == '-') _expr = '-';
      return;
    }
    var last = _expr[_expr.length - 1];
    if (last == '.') {
      _expr = _expr.substring(0, _expr.length - 1);
      if (_expr.isEmpty) {
        if (op == '-') _expr = '-';
        return;
      }
      last = _expr[_expr.length - 1];
    }
    if ('+-*/^'.contains(last)) {
      if (op == '-' && '*/^'.contains(last)) {
        _expr += op;
      } else if (_expr.length >= 2 && last == '-' && '*/^'.contains(_expr[_expr.length - 2])) {
        _expr = _expr.substring(0, _expr.length - 2) + op;
      } else {
        _expr = _expr.substring(0, _expr.length - 1) + op;
      }
    } else {
      _expr += op;
    }
  }

  void _appendDec() {
    if (_calculated) {
      _expr = '0.';
      _result = '0';
      _calculated = false;
      return;
    }
    if (_expr.length >= _maxLen) return;
    if (_expr.isEmpty) {
      _expr = '0.';
      return;
    }
    var lastNum = '';
    for (var i = _expr.length - 1; i >= 0 && !'+-*/^'.contains(_expr[i]); i--) {
      lastNum = _expr[i] + lastNum;
    }
    if (!lastNum.contains('.')) {
      _expr += lastNum.isEmpty ? '0.' : '.';
    }
  }

  void _calculate() {
    if (_expr.isEmpty) return;
    var e = _expr;
    while (e.isNotEmpty && '+-*/^'.contains(e[e.length - 1])) {
      e = e.substring(0, e.length - 1);
    }
    if (e.isEmpty) {
      _result = '0';
      return;
    }
    try {
      var r = _Parser(e).parse();
      if (r.isInfinite) {
        _result = 'Бесконечность';
      } else if (r.isNaN) {
        _result = 'Ошибка';
      } else if (r.abs() > 1e15) {
        _result = r.toStringAsExponential(2);
      } else if (r == r.truncateToDouble()) {
        _result = r.toInt().toString();
      } else {
        _result = r.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
      _calculated = true;
    } catch (_) {
      _result = 'Ошибка';
      _calculated = true;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _c(3),
    body: SafeArea(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _buildDisplay(),
        const SizedBox(height: 16),
        Expanded(child: _buildKeypad()),
      ]),
    )),
  );

  Widget _buildDisplay() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: BoxDecoration(
      color: _c(4),
      borderRadius: BorderRadius.circular(15),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: double.infinity, child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, reverse: true,
        child: Text(_expr.isEmpty ? '' : '${_expr.replaceAll('*', '×').replaceAll('/', '÷')}=',
          style: TextStyle(fontSize: 16, color: _c(7))),
      )),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: FittedBox(
        fit: BoxFit.scaleDown, alignment: Alignment.centerRight,
        child: Text(_result, style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _c(6))),
      )),
    ]),
  );

  Widget _buildKeypad() => LayoutBuilder(builder: (_, constraints) {
    var gap = 10.0;
    var sz = ((constraints.maxWidth - gap * 3) / 4).clamp(0.0, 80.0);
    var h = ((constraints.maxHeight - gap * 4 - 24) / 5).clamp(0.0, 65.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _c(5), borderRadius: BorderRadius.circular(25)),
      child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        for (var row in [['C', '^', '÷'], ['7', '8', '9', '×'], ['4', '5', '6', '-'],
                         ['1', '2', '3', '+'], [_dark ? '☀️' : '🌙', '0', '.', '=']])
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < row.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              _buildBtn(row[i], sz, h),
            ]
          ]),
      ]),
    );
  });

  Widget _buildBtn(String t, double sz, double h) {
    var isOp = '÷×-+^='.contains(t);
    var isClear = t == 'C';
    var isTheme = t == '☀️' || t == '🌙';
    var pressed = _pressed == t;
    var baseColor = isClear ? _c(2) : isTheme ? Color(_dark ? 0xFFFF9800 : 0xFF5C6BC0) : isOp ? _c(1) : _c(0);
    var textColor = isClear ? (_dark ? Colors.white : Colors.black87) : (isOp || isTheme ? Colors.white : (_dark ? Colors.white : Colors.black87));

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = t),
      onTapUp: (_) {
        setState(() => _pressed = null);
        _onTap(t);
      },
      onTapCancel: () => setState(() => _pressed = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: isClear ? sz * 2 + 10 : sz,
        height: h,
        decoration: BoxDecoration(
          color: pressed ? baseColor.withOpacity(0.6) : baseColor,
          borderRadius: BorderRadius.circular(h / 2),
          boxShadow: pressed ? [] : [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Center(child: Text(t, style: TextStyle(
          fontSize: isTheme ? h * 0.5 : h * 0.4,
          fontWeight: FontWeight.bold,
          color: pressed ? textColor.withOpacity(0.7) : textColor,
        ))),
      ),
    );
  }
}

class _Parser {
  final String _e;
  int _p = 0;
  _Parser(this._e);

  double parse() {
    var r = _addSub();
    if (_p < _e.length) throw const FormatException();
    return r;
  }

  double _addSub() {
    var l = _mulDiv();
    while (_p < _e.length && '+-'.contains(_e[_p])) {
      var op = _e[_p++];
      l = op == '+' ? l + _mulDiv() : l - _mulDiv();
    }
    return l;
  }

  double _mulDiv() {
    var l = _pow();
    while (_p < _e.length && '*/'.contains(_e[_p])) {
      var op = _e[_p++];
      var r = _pow();
      l = op == '*' ? l * r : (r == 0 ? double.infinity : l / r);
    }
    return l;
  }

  double _pow() {
    var l = _num();
    while (_p < _e.length && _e[_p] == '^') {
      _p++;
      l = pow(l, _num()).toDouble();
    }
    return l;
  }

  double _num() {
    while (_p < _e.length && _e[_p] == ' ') {
      _p++;
    }
    var neg = false;
    if (_p < _e.length && _e[_p] == '-') {
      neg = true;
      _p++;
    }
    var s = _p;
    while (_p < _e.length && _e[_p].contains(RegExp(r'[0-9.]'))) {
      _p++;
    }
    if (s == _p) throw const FormatException();
    var v = double.parse(_e.substring(s, _p));
    return neg ? -v : v;
  }
}
