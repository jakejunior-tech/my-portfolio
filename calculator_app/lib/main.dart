import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: _themeMode,
      home: MainScreen(toggleTheme: _toggleTheme, isDarkMode: _themeMode == ThemeMode.dark),
    );
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const MainScreen({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          CalculatorScreen(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode),
          const HistoryScreen(),
          const CurrencyConverterScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calculate), label: 'Calculator'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.currency_exchange), label: 'Currency'),
        ],
      ),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const CalculatorScreen({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _expression = '';
  double? _firstOperand;
  String? _operator;

  void _onNumberPressed(String number) {
    setState(() {
      if (_display == '0' || _display == 'Error') {
        _display = number;
      } else {
        _display += number;
      }
    });
  }

  void _onOperatorPressed(String operator) {
    setState(() {
      _firstOperand = double.tryParse(_display);
      _operator = operator;
      _expression = '$_display $operator';
      _display = '0';
    });
  }

  void _onEqualsPressed() {
    if (_firstOperand == null || _operator == null) return;

    double secondOperand = double.tryParse(_display) ?? 0;
    double result = 0;

    switch (_operator) {
      case '+':
        result = _firstOperand! + secondOperand;
        break;
      case '-':
        result = _firstOperand! - secondOperand;
        break;
      case '×':
        result = _firstOperand! * secondOperand;
        break;
      case '÷':
        if (secondOperand != 0) {
          result = _firstOperand! / secondOperand;
        } else {
          setState(() => _display = 'Error');
          return;
        }
        break;
    }

    String calculation = '$_expression $_display = ${result.toString().replaceAll(RegExp(r'\.0$'), '')}';
    _saveToHistory(calculation);

    setState(() {
      _display = result.toString().replaceAll(RegExp(r'\.0$'), '');
      _expression = '';
      _firstOperand = null;
      _operator = null;
    });
  }

  void _onClearPressed() {
    setState(() {
      _display = '0';
      _expression = '';
      _firstOperand = null;
      _operator = null;
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
    });
  }

  Future<void> _saveToHistory(String calculation) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('history') ?? [];
    history.insert(0, calculation);
    if (history.length > 50) history = history.sublist(0, 50);
    await prefs.setStringList('history', history);
  }

  Widget _buildButton(String text, {Color? backgroundColor, Color? textColor}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: backgroundColor ?? (widget.isDarkMode ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              if (text == 'C') {
                _onClearPressed();
              } else if (text == '⌫') {
                _onBackspacePressed();
              } else if (text == '=') {
                _onEqualsPressed();
              } else if (['+', '-', '×', '÷'].contains(text)) {
                _onOperatorPressed(text);
              } else {
                _onNumberPressed(text);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 64,
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? (widget.isDarkMode ? Colors.white : Colors.black),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: widget.toggleTheme,
              ),
              const Text('Calculator', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.bottomRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _expression,
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  _display,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    _buildButton('C', backgroundColor: Colors.red[400], textColor: Colors.white),
                    _buildButton('⌫', backgroundColor: Colors.orange[400], textColor: Colors.white),
                    _buildButton('÷', backgroundColor: Colors.orange[400], textColor: Colors.white),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('7'),
                    _buildButton('8'),
                    _buildButton('9'),
                    _buildButton('×', backgroundColor: Colors.orange[400], textColor: Colors.white),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('4'),
                    _buildButton('5'),
                    _buildButton('6'),
                    _buildButton('-', backgroundColor: Colors.orange[400], textColor: Colors.white),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('1'),
                    _buildButton('2'),
                    _buildButton('3'),
                    _buildButton('+', backgroundColor: Colors.orange[400], textColor: Colors.white),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('0'),
                    _buildButton('.'),
                    _buildButton('=', backgroundColor: Colors.blue[500], textColor: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('history') ?? [];
    });
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('history');
    setState(() {
      _history = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                if (_history.isNotEmpty)
                  TextButton(
                    onPressed: _clearHistory,
                    child: const Text('Clear All'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _history.isEmpty
                ? const Center(child: Text('No history yet', style: TextStyle(fontSize: 18, color: Colors.grey)))
                : ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          ListTile(
                            title: Text(_history[index], style: const TextStyle(fontSize: 16)),
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController _amountController = TextEditingController(text: '1');
  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';
  double _result = 0;

  static const Map<String, double> _exchangeRates = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'JPY': 149.50,
    'INR': 83.12,
    'CAD': 1.36,
    'AUD': 1.53,
    'CHF': 0.88,
    'CNY': 7.24,
    'SGD': 1.34,
    'HKD': 7.82,
    'KRW': 1320.50,
    'MXN': 17.15,
    'BRL': 4.97,
    'RUB': 91.50,
    'ZAR': 18.65,
    'AED': 3.67,
    'SAR': 3.75,
    'THB': 35.50,
    'NZD': 1.64,
    'SEK': 10.45,
    'NOK': 10.55,
    'DKK': 6.87,
    'PLN': 3.98,
    'TRY': 32.15,
    'IDR': 15650.0,
    'MYR': 4.72,
    'PHP': 56.25,
    'VND': 24500.0,
    'EGP': 30.90,
  };

  static const Map<String, String> _currencyNames = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'INR': 'Indian Rupee',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
    'CHF': 'Swiss Franc',
    'CNY': 'Chinese Yuan',
    'SGD': 'Singapore Dollar',
    'HKD': 'Hong Kong Dollar',
    'KRW': 'South Korean Won',
    'MXN': 'Mexican Peso',
    'BRL': 'Brazilian Real',
    'RUB': 'Russian Ruble',
    'ZAR': 'South African Rand',
    'AED': 'UAE Dirham',
    'SAR': 'Saudi Riyal',
    'THB': 'Thai Baht',
    'NZD': 'New Zealand Dollar',
    'SEK': 'Swedish Krona',
    'NOK': 'Norwegian Krone',
    'DKK': 'Danish Krone',
    'PLN': 'Polish Zloty',
    'TRY': 'Turkish Lira',
    'IDR': 'Indonesian Rupiah',
    'MYR': 'Malaysian Ringgit',
    'PHP': 'Philippine Peso',
    'VND': 'Vietnamese Dong',
    'EGP': 'Egyptian Pound',
  };

  void _convert() {
    double amount = double.tryParse(_amountController.text) ?? 0;
    double fromRate = _exchangeRates[_fromCurrency] ?? 1;
    double toRate = _exchangeRates[_toCurrency] ?? 1;
    setState(() {
      _result = (amount / fromRate) * toRate;
    });
  }

  @override
  void initState() {
    super.initState();
    _convert();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Currency Converter', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              onChanged: (_) => _convert(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('From', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _fromCurrency,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _exchangeRates.keys.map((currency) {
                          return DropdownMenuItem(
                            value: currency,
                            child: Text('$currency - ${_currencyNames[currency]}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _fromCurrency = value!;
                          });
                          _convert();
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: IconButton(
                    icon: const Icon(Icons.swap_horiz, size: 32),
                    onPressed: () {
                      setState(() {
                        String temp = _fromCurrency;
                        _fromCurrency = _toCurrency;
                        _toCurrency = temp;
                      });
                      _convert();
                    },
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('To', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _toCurrency,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _exchangeRates.keys.map((currency) {
                          return DropdownMenuItem(
                            value: currency,
                            child: Text('$currency - ${_currencyNames[currency]}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _toCurrency = value!;
                          });
                          _convert();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    _amountController.text.isEmpty ? '0' : _amountController.text,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_fromCurrency = ${_result.toStringAsFixed(2)} $_toCurrency',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1 $_fromCurrency = ${(_exchangeRates[_toCurrency]! / _exchangeRates[_fromCurrency]!).toStringAsFixed(4)} $_toCurrency',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}