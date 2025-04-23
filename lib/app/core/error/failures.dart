// app/core/error/failures.dart
import 'package:equatable/equatable.dart'; // Adicione equatable ao pubspec.yaml

abstract class Failure extends Equatable {
  final String? message; // Mensagem opcional para detalhar o erro

  const Failure({this.message});

  @override
  List<Object?> get props =>
      [message]; // Usa Equatable para facilitar comparações
}

// Implementações específicas de Failure

// Falha geral do servidor (ex: erro 500, 403, 404 não tratado especificamente)
class ServerFailure extends Failure {
  const ServerFailure({super.message});
}

// Falha de conexão com a rede
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = "No internet connection."});
}

// Falha ao fazer parse de dados (ex: JSON inválido)
class CacheFailure extends Failure {
  const CacheFailure({super.message = "Error accessing local cache."});
}
