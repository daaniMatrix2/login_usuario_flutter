import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  List<dynamic> _users = [];
  String? _errorMessage;
  bool _isLoading = false;
  static const _apiUrl = 'http://10.0.2.2:8000';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/usuarios'));
      if (response.statusCode == 200) {
        setState(() => _users = json.decode(response.body));
      }
    } catch (_) {}
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/usuarios'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nome': _nomeController.text,
          'email': _emailController.text,
          'senha': _senhaController.text,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _nomeController.clear();
        _emailController.clear();
        _senhaController.clear();
        _fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário cadastrado com sucesso!')),
        );
      } else {
        final data = json.decode(response.body);
        setState(() => _errorMessage = data['detail'] ?? 'Erro ao cadastrar usuário');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erro de conexão');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar-se')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    validator: (v) => v == null || v.isEmpty ? 'Informe seu nome' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Informe seu email';
                      if (!v.contains('@')) return 'Email inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _senhaController,
                    decoration: const InputDecoration(labelText: 'Senha'),
                    obscureText: true,
                    validator: (v) => v == null || v.isEmpty ? 'Informe sua senha' : null,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _register,
                          child: const Text('Cadastrar'),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Usuários Cadastrados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(
              child: _users.isEmpty
                  ? const Text('Nenhum usuário cadastrado.')
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final u = _users[index];
                        return ListTile(
                          title: Text(u['nome']),
                          subtitle: Text(u['email']),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
