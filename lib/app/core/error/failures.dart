import 'package:equatable/equatable.dart'; // Adicione equatable ao pubspec.yaml

abstract class Failure extends Equatable {
  final String? message;
  const Failure({this.message});

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({super.message});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required String message}) : super(message: message);
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = "No internet connection."});
}

// Falha ao fazer parse de dados (ex: JSON inválido)
class CacheFailure extends Failure {
  const CacheFailure({super.message = "Error accessing local cache."});
}
