// lib/features/movies/presentation/store/video_player_store.dart
import 'package:desafio_loomi/app/core/error/failures.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/subtitle_entity.dart';
import 'package:desafio_loomi/app/features/movies/domain/usecases/get_subtitles_usecase.dart';
import 'package:mobx/mobx.dart';

part 'video_player_store.g.dart';

class VideoPlayerStore = _VideoPlayerStoreBase with _$VideoPlayerStore;

abstract class _VideoPlayerStoreBase with Store {
  final GetSubtitlesUseCase getSubtitlesUseCase;

  _VideoPlayerStoreBase({required this.getSubtitlesUseCase});

  @observable
  ObservableList<Subtitle> subtitles = ObservableList<Subtitle>();

  @observable
  Subtitle? selectedSubtitle; // Legenda selecionada pelo usuário

  @observable
  bool isLoadingSubtitles = false;

  @observable
  String? subtitleError;

  @action
  Future<void> fetchSubtitles(int movieId) async {
    isLoadingSubtitles = true;
    subtitleError = null;
    subtitles.clear();
    selectedSubtitle = null; // Reseta seleção

    final result = await getSubtitlesUseCase(movieId);
    result.fold(
      (failure) {
        subtitleError = _mapFailureToMessage(
            failure); // Use sua função _mapFailureToMessage
        print("[VideoPlayerStore] Erro ao buscar legendas: $subtitleError");
      },
      (subtitleList) {
        subtitles = ObservableList.of(subtitleList);
        print("[VideoPlayerStore] Legendas carregadas: ${subtitles.length}");
        // Opcional: Selecionar a primeira legenda por padrão
        if (subtitles.isNotEmpty) {
          // TODO: Adicionar lógica para escolher um padrão (ex: 'pt-BR' ou 'en')
          // selectSubtitle(subtitles.first);
        }
      },
    );
    isLoadingSubtitles = false;
  }

  @action
  void selectSubtitle(Subtitle? subtitle) {
    print(
        "[VideoPlayerStore] Legenda selecionada: ${subtitle?.language ?? 'Nenhuma'}");
    selectedSubtitle = subtitle;
    // TODO: Notificar o player de vídeo para carregar/trocar a legenda
  }

  String _mapFailureToMessage(Failure failure) {
    // Adapte sua função existente ou crie uma nova
    switch (failure.runtimeType) {
      case ServerFailure:
        return (failure as ServerFailure).message ?? 'Server Error';
      default:
        return 'Failed to load subtitles.';
    }
  }
}
