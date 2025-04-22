import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'global.dart';

class GastosPage extends StatefulWidget {
  const GastosPage({Key? key}) : super(key: key);

  @override
  State<GastosPage> createState() => _GastosPageState();
}

class _GastosPageState extends State<GastosPage> {
  final String apiUrl = 'http://10.0.2.2:8000';
  final GlobalKey<_CadastroGastoWidgetState> _gastoKey = GlobalKey();

  void _atualizarCategorias() {
    _gastoKey.currentState?._buscarCategorias();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Gastos'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Cadastro de Gastos', icon: Icon(Icons.attach_money)),
              Tab(text: 'Cadastro de Categoria', icon: Icon(Icons.category)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            CadastroGastoWidget(key: _gastoKey, apiUrl: apiUrl),
            CadastroCategoriaWidget(apiUrl: apiUrl, onCategoriaCadastrada: () {
              _atualizarCategorias();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Categoria cadastrada com sucesso!')),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class CadastroGastoWidget extends StatefulWidget {
  final String apiUrl;
  const CadastroGastoWidget({Key? key, required this.apiUrl}) : super(key: key);

  @override
  State<CadastroGastoWidget> createState() => _CadastroGastoWidgetState();
}

class _CadastroGastoWidgetState extends State<CadastroGastoWidget> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();
  DateTime? _dataSelecionada;
  int? _categoriaSelecionada;
  String? _mensagemErro;
  List categorias = [];
  List gastos = [];
  bool _carregandoCategorias = false;
  String? _erroCategorias;

  @override
  void initState() {
    super.initState();
    _buscarCategorias();
    _buscarGastos();
  }

  Future<void> _buscarCategorias() async {
    setState(() {
      _carregandoCategorias = true;
      _erroCategorias = null;
    });
    try {
      final response = await http.get(Uri.parse('${widget.apiUrl}/categorias'));
      if (response.statusCode == 200) {
        setState(() {
          categorias = json.decode(utf8.decode(response.bodyBytes));
        });
      } else {
        setState(() {
          _erroCategorias = 'Erro ao buscar categorias';
        });
      }
    } catch (e) {
      setState(() {
        _erroCategorias = 'Erro de conexão ao buscar categorias';
      });
    } finally {
      setState(() {
        _carregandoCategorias = false;
      });
    }
  }

  Future<void> _buscarGastos() async {
    final response = await http.get(Uri.parse('${widget.apiUrl}/gastos?usuario_id=$usuarioIdLogado'));
    if (response.statusCode == 200) {
      setState(() {
        gastos = json.decode(utf8.decode(response.bodyBytes));
      });
    }
  }

  Future<void> _cadastrarGasto() async {
    if (!_formKey.currentState!.validate() || _categoriaSelecionada == null || _dataSelecionada == null) {
      setState(() {
        _mensagemErro = 'Preencha todos os campos.';
      });
      return;
    }
    final body = {
      'valor': double.parse(_valorController.text),
      'descricao': _descricaoController.text,
      'data': DateFormat('yyyy-MM-dd').format(_dataSelecionada!),
      'categoria_id': _categoriaSelecionada,
      'usuario_id': usuarioIdLogado,
    };
    final response = await http.post(
      Uri.parse('${widget.apiUrl}/gastos'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    print('POST /gastos => status ${response.statusCode}, body: ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      _valorController.clear();
      _descricaoController.clear();
      _dataSelecionada = null;
      _categoriaSelecionada = null;
      _mensagemErro = null;
      _buscarGastos();
      setState(() {});
    } else {
      try {
        final errorData = json.decode(response.body);
        setState(() {
          _mensagemErro = 'Erro ${response.statusCode}: ${errorData['detail'] ?? errorData}';
        });
      } catch (e) {
        setState(() {
          _mensagemErro = 'Erro ${response.statusCode} ao cadastrar gasto.';
        });
      }
    }
  }

  Future<void> _excluirGasto(int id) async {
    final response = await http.delete(Uri.parse('${widget.apiUrl}/gastos/$id'));
    if (response.statusCode == 200 || response.statusCode == 204) {
      _buscarGastos();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gasto excluído com sucesso!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir gasto.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cadastrar Gasto', style: Theme.of(context).textTheme.titleLarge),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _valorController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Valor'),
                  validator: (v) => v == null || v.isEmpty ? 'Informe o valor' : null,
                ),
                TextFormField(
                  controller: _descricaoController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  validator: (v) => v == null || v.isEmpty ? 'Informe a descrição' : null,
                ),
                if (_carregandoCategorias)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  )
                else if (_erroCategorias != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(_erroCategorias!, style: const TextStyle(color: Colors.red)),
                  )
                else if (categorias.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Nenhuma categoria cadastrada.'),
                  )
                else
                  DropdownButtonFormField<int>(
                    value: _categoriaSelecionada,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: categorias.map<DropdownMenuItem<int>>((cat) {
                      return DropdownMenuItem<int>(
                        value: cat['id'],
                        child: Text(cat['nome']),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _categoriaSelecionada = v),
                    validator: (v) => v == null ? 'Selecione uma categoria' : null,
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Text(_dataSelecionada == null
                          ? 'Selecione a data'
                          : 'Data: ${DateFormat('dd/MM/yyyy').format(_dataSelecionada!)}'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final data = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (data != null) {
                          setState(() => _dataSelecionada = data);
                        }
                      },
                      child: const Text('Selecionar Data'),
                    ),
                  ],
                ),
                if (_mensagemErro != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(_mensagemErro!, style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _cadastrarGasto,
                  child: const Text('Cadastrar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Gastos cadastrados', style: Theme.of(context).textTheme.titleLarge),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gastos.length,
            itemBuilder: (context, idx) {
              final gasto = gastos[idx];
              return Card(
                child: ListTile(
                  title: Text(
                    'R\$ ${gasto['valor'].toStringAsFixed(2)} - ${gasto['descricao']}',
                  ),
                  subtitle: Text(
                    'Data: ${gasto['data']}\nCategoria: ${gasto['categoria']['nome']}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Excluir gasto'),
                          content: Text('Tem certeza que deseja excluir o gasto "${gasto['descricao']}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Excluir'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        _excluirGasto(gasto['id']);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class CadastroCategoriaWidget extends StatefulWidget {
  final String apiUrl;
  final VoidCallback onCategoriaCadastrada;
  const CadastroCategoriaWidget({Key? key, required this.apiUrl, required this.onCategoriaCadastrada}) : super(key: key);

  @override
  State<CadastroCategoriaWidget> createState() => _CadastroCategoriaWidgetState();
}

class _CadastroCategoriaWidgetState extends State<CadastroCategoriaWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  String? _mensagemErro;
  List categorias = [];

  @override
  void initState() {
    super.initState();
    _buscarCategorias();
  }

  Future<void> _buscarCategorias() async {
    final response = await http.get(Uri.parse('${widget.apiUrl}/categorias'));
    if (response.statusCode == 200) {
      setState(() {
        categorias = json.decode(utf8.decode(response.bodyBytes));
      });
    }
  }

  Future<void> _cadastrarCategoria() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _mensagemErro = 'Preencha o nome da categoria.';
      });
      return;
    }
    final body = {
      'nome': _nomeController.text,
    };
    final response = await http.post(
      Uri.parse('${widget.apiUrl}/categorias'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      _nomeController.clear();
      _mensagemErro = null;
      _buscarCategorias();
      setState(() {});
      widget.onCategoriaCadastrada();
    } else {
      setState(() {
        _mensagemErro = 'Erro ao cadastrar categoria.';
      });
    }
  }

  Future<void> _excluirCategoria(int id) async {
    final response = await http.delete(Uri.parse('${widget.apiUrl}/categorias/$id'));
    if (response.statusCode == 200 || response.statusCode == 204) {
      _buscarCategorias();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoria excluída com sucesso!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir categoria.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cadastrar Categoria', style: Theme.of(context).textTheme.titleLarge),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(labelText: 'Nome da Categoria'),
                  validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                ),
                if (_mensagemErro != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(_mensagemErro!, style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _cadastrarCategoria,
                  child: const Text('Cadastrar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Categorias cadastradas', style: Theme.of(context).textTheme.titleLarge),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categorias.length,
            itemBuilder: (context, idx) {
              final cat = categorias[idx];
              return Card(
                child: ListTile(
                  title: Text(cat['nome']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Excluir categoria'),
                          content: Text('Tem certeza que deseja excluir a categoria "${cat['nome']}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Excluir'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        _excluirCategoria(cat['id']);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
