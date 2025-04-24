import 'package:dartz/dartz.dart'; // Para o Either
import 'package:desafio_loomi/app/core/error/failures.dart'; // Suas classes de Failure
import 'package:desafio_loomi/app/features/movies/domain/repositories/comments_repository.dart'; // A interface do Repository

// Define o Use Case para adicionar um comentário
class AddCommentUseCase {
  final CommentsRepository repository; // Depende da interface do repositório

  // Construtor que recebe o repositório via injeção de dependência
  AddCommentUseCase({required this.repository});

  // Método principal (geralmente 'call') que executa a lógica
  // Recebe os dados necessários para criar o comentário
  Future<Either<Failure, void>> call({
    required String movieId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    // Poderia adicionar validações básicas aqui se quisesse (ex: texto não vazio)
    return await repository.addComment(movieId, userId, userName, text);
  }
}
