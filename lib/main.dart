import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'pages/global.dart';
import 'pages/login_page.dart';

const String _apiUrl = 'http://10.0.2.2:8000';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  runApp(const GastosApp());
}

class GastosApp extends StatelessWidget {
  const GastosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Painel de Gastos',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        cardColor: Colors.white,
        useMaterial3: true,
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Gasto {
  final String categoria;
  final String descricao;
  final double valor;
  final DateTime data;

  Gasto({required this.categoria, required this.descricao, required this.valor, required this.data});
}

const List<String> categorias = [

];

final List<Gasto> mockGastos = [];

class PainelGastosPage extends StatefulWidget {
  const PainelGastosPage({super.key});

  @override
  State<PainelGastosPage> createState() => _PainelGastosPageState();
}

class _PainelGastosPageState extends State<PainelGastosPage> {
  late int _anoSelecionado;
  late int _mesSelecionado;
  List<Gasto> _gastos = [];
  bool _loadingGastos = false;
  String? _errorGastos;
  List<String> _categorias = [];
  bool _loadingCategorias = false;
  String? _errorCategorias;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anoSelecionado = now.year;
    _mesSelecionado = now.month;
    _fetchGastos();
    _fetchCategorias();
  }

  Future<void> _fetchGastos() async {
    setState(() { _loadingGastos = true; _errorGastos = null; });
    try {
      final resp = await http.get(Uri.parse('$_apiUrl/gastos?usuario_id=$usuarioIdLogado'));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List;
        final list = data.map((e) => Gasto(
          categoria: e['categoria']['nome'],
          descricao: e['descricao'],
          valor: (e['valor'] as num).toDouble(),
          data: DateTime.parse(e['data']),
        )).toList();
        setState(() { _gastos = list; });
      } else {
        setState(() { _errorGastos = 'Erro ${resp.statusCode}'; });
      }
    } catch (e) {
      setState(() { _errorGastos = 'Erro de conexão'; });
    } finally {
      setState(() { _loadingGastos = false; });
    }
  }

  Future<void> _fetchCategorias() async {
    setState(() { _loadingCategorias = true; _errorCategorias = null; });
    try {
      final resp = await http.get(Uri.parse('$_apiUrl/categorias'));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List;
        setState(() { _categorias = data.map((e) => e['nome'] as String).toList(); });
      } else {
        setState(() { _errorCategorias = 'Erro ${resp.statusCode}'; });
      }
    } catch (e) {
      setState(() { _errorCategorias = 'Erro de conexão'; });
    } finally {
      setState(() { _loadingCategorias = false; });
    }
  }

  List<int> get anosDisponiveis {
    final anos = _gastos.map((g) => g.data.year).toSet().toList();
    anos.sort();
    return anos;
  }

  List<Gasto> get gastosFiltrados => _gastos.where((g) => g.data.year == _anoSelecionado && g.data.month == _mesSelecionado).toList();

  List<Gasto> get gastosAno => _gastos.where((g) => g.data.year == _anoSelecionado).toList();

  Map<String, double> get totalPorCategoria {
    final map = <String, double>{};
    for (var g in gastosFiltrados) {
      map[g.categoria] = (map[g.categoria] ?? 0) + g.valor;
    }
    return map;
  }

  Map<int, double> get totalPorMes {
    final map = <int, double>{};
    for (var g in gastosAno) {
      map[g.data.month] = (map[g.data.month] ?? 0) + g.valor;
    }
    return map;
  }

  Map<String, List<Gasto>> get gastosPorCategoria {
    final map = <String, List<Gasto>>{};
    for (var cat in categorias) {
      final lista = gastosFiltrados.where((g) => g.categoria == cat).toList();
      if (lista.isNotEmpty) map[cat] = lista;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Gastos'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _mesSelecionado,
                    decoration: const InputDecoration(labelText: 'Mês'),
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(DateFormat.MMMM('pt_BR').format(DateTime(0, m))),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _mesSelecionado = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _anoSelecionado,
                    decoration: const InputDecoration(labelText: 'Ano'),
                    items: anosDisponiveis
                        .map((a) => DropdownMenuItem(
                              value: a,
                              child: Text(a.toString()),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _anoSelecionado = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distribuição de Gastos por Categoria',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(
                      height: 240,
                      child: SfCircularChart(
                        legend: Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
                        series: <PieSeries<_PieData, String>>[
                          PieSeries<_PieData, String>(
                            dataSource: totalPorCategoria.entries
                                .map((e) => _PieData(e.key, e.value))
                                .toList(),
                            xValueMapper: (_PieData data, _) => data.categoria,
                            yValueMapper: (_PieData data, _) => data.valor,
                            dataLabelMapper: (_PieData data, _) =>
                                '${data.categoria}\nR\$ ${data.valor.toStringAsFixed(0)}',
                            dataLabelSettings: const DataLabelSettings(isVisible: true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: ElevatedButton(
                        child: const Text('Gastos Detalhados'),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              String? _selectedCategory;
                              return StatefulBuilder(
                                builder: (context, setModalState) {
                                  // Primeiro filtra por mês/ano selecionados no painel
                                  final dateFiltered = _gastos
                                      .where((g) => g.data.year == _anoSelecionado && g.data.month == _mesSelecionado)
                                      .toList();
                                  // Depois aplica filtro de categoria, se houver
                                  final filtered = _selectedCategory == null
                                      ? dateFiltered
                                      : dateFiltered.where((g) => g.categoria == _selectedCategory).toList();
                                  return Container(
                                    height: 400,
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        DropdownButton<String>(
                                          isExpanded: true,
                                          hint: const Text('Filtrar por categoria'),
                                          value: _selectedCategory,
                                          items: [
                                            const DropdownMenuItem<String>(value: null, child: Text('Todos'))
                                          ]
                                              .followedBy(_categorias.map(
                                                  (cat) => DropdownMenuItem(value: cat, child: Text(cat))))
                                              .toList(),
                                          onChanged: (value) => setModalState(() => _selectedCategory = value),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Gastos Detalhados',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: filtered.isEmpty
                                              ? const Center(child: Text('Nenhum gasto encontrado'))
                                              : ListView.builder(
                                                  itemCount: filtered.length,
                                                  itemBuilder: (context, index) {
                                                    final gasto = filtered[index];
                                                    return ListTile(
                                                      contentPadding: EdgeInsets.zero,
                                                      title: Text(gasto.descricao),
                                                      subtitle: Text(
                                                          DateFormat('dd/MM/yyyy').format(gasto.data)),
                                                      trailing: Text(
                                                        'R\$ ${gasto.valor.toStringAsFixed(2)}',
                                                        style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.black87),
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total de Gastos por Mês',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(
                      height: 220,
                      child: SfCartesianChart(
                        primaryXAxis: CategoryAxis(
                          labelRotation: 45,
                          majorGridLines: const MajorGridLines(width: 0),
                        ),
                        primaryYAxis: NumericAxis(
                          numberFormat: NumberFormat.simpleCurrency(locale: 'pt_BR', decimalDigits: 0),
                          majorGridLines: const MajorGridLines(dashArray: [2, 2]),
                        ),
                        series: <CartesianSeries<dynamic, dynamic>>[
                          ColumnSeries<dynamic, dynamic>(
                            color: Colors.blue[400],
                            dataSource: totalPorMes.entries
                                .map((e) => _BarData(DateFormat.MMM('pt_BR').format(DateTime(0, e.key)), e.value))
                                .toList(),
                            xValueMapper: (data, _) => (data as _BarData).mes,
                            yValueMapper: (data, _) => (data as _BarData).valor,
                            dataLabelSettings: const DataLabelSettings(isVisible: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PieData {
  final String categoria;
  final double valor;
  _PieData(this.categoria, this.valor);
}

class _BarData {
  final String mes;
  final double valor;
  _BarData(this.mes, this.valor);
}
