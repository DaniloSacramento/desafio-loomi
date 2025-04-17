import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Adicione aqui qualquer lógica de inicialização
    // e navegação para a próxima tela após um delay
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/login'); // ou '/home'
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fundo preto
      body: Center(
        child: Container(
          width: 100, // Tamanho do círculo
          height: 100, // Tamanho do círculo
          decoration: const BoxDecoration(
            color: Colors.white, // Cor do círculo
            shape: BoxShape.circle, // Forma circular
          ),
        ),
      ),
    );
  }
}
