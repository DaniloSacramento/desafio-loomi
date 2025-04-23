// features/movies/domain/usecases/get_likes_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:desafio_loomi/app/core/error/failures.dart'; // Importa sua classe Failure
import 'package:desafio_loomi/app/features/movies/domain/entities/like_entity.dart';
import '../repositories/movie_repository.dart'; // Importa a interface do repositório

class GetLikesUseCase {
  final MovieRepository repository;

  GetLikesUseCase(this.repository);

  /// Busca os likes para um usuário específico.
  ///
  /// Retorna um [Either] contendo uma [Failure] em caso de erro,
  /// ou uma lista de [Like] em caso de sucesso.
  Future<Either<Failure, List<Like>>> call(int userId) async {
    // Delega a chamada diretamente para o método correspondente no repositório
    return await repository.getLikes(userId);
  }
}
