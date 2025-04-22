// ... inside _LoginPageState class ...

void _login() {
  if (_formKey.currentState!.validate()) {
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      final userExists = _users.any(
        (user) => user["email"] == email && user["password"] == password,
      );

      if (userExists) {
        // Navigate to MainPage instead of WelcomePage
        Navigator.of(context).pushReplacement(
          // Use pushReplacement to prevent going back to login
          MaterialPageRoute(
            builder: (context) => const MainPage(),
          ), // Changed here
        );
      } else {
        setState(() {
          _errorMessage = 'Usuário ou senha incorretos!';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao fazer login. Tente novamente.';
      });
    }
  }
}

Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (context) => const MainPage(),
  ),
);

// ... rest of the LoginPage code ...

// Remove the old WelcomePage class from this file if it's here.
// We'll create MainPage below (or in a separate file).
