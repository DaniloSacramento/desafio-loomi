import 'package:dartz/dartz.dart'; // Para o Either
import 'package:desafio_loomi/app/core/error/failures.dart'; // Suas classes de Failure
import 'package:desafio_loomi/app/features/movies/domain/entities/comments_entity.dart';
import 'package:desafio_loomi/app/features/movies/domain/repositories/comments_repository.dart'; // A interface do Repository

// Define o Use Case para obter o stream de comentários
class GetCommentsStreamUseCase {
  final CommentsRepository repository; // Depende da interface do repositório

  // Construtor que recebe o repositório via injeção de dependência
  GetCommentsStreamUseCase({required this.repository});

  // Método principal (geralmente 'call') que executa a lógica
  // Recebe o movieId e retorna o Stream vindo do repositório
  Stream<Either<Failure, List<CommentEntity>>> call(String movieId) {
    return repository.getCommentsStream(movieId);
  }
}
