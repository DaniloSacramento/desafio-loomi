// lib/features/movies/presentation/widgets/rating_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/movie_entity.dart';
// Ensure correct import for MovieStore and RatingAction if not already correct
import 'package:desafio_loomi/app/features/movies/presentation/store/movie_store.dart';
import 'package:desafio_loomi/app/core/themes/app_colors.dart';

// Função PÚBLICA que será chamada pela HomePage
void displayRatingSheet({
  required BuildContext context,
  required Movie movie,
  required MovieStore movieStore,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.grey[900]?.withOpacity(0.95),
    isScrollControlled:
        true, // Permite altura flexível, crucial for larger content
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
    ),
    builder: (BuildContext bc) {
      // Chama o widget interno que constrói o conteúdo
      return _RatingBottomSheetContent(movie: movie, movieStore: movieStore);
    },
  );
}

class _RatingBottomSheetContent extends StatelessWidget {
  final Movie movie;
  final MovieStore movieStore;

  const _RatingBottomSheetContent({
    required this.movie,
    required this.movieStore,
  });

  @override
  Widget build(BuildContext context) {
    // Pega o estado atual de like para destacar a opção correta
    final bool isCurrentlyLiked = movieStore.likedMovieIds.contains(movie.id);
    // TODO: Adicionar lógica se quiser destacar 'dislike' ou 'love it' baseado em estado local futuro
    //       Ex: final RatingAction? currentRating = movieStore.getRatingForMovie(movie.id);

    return Padding(
      // Padding geral dentro do bottom sheet - AUMENTADO para mais espaço
      padding: EdgeInsets.only(
          top: 30.0, // Aumentado de 20.0
          left: 20.0, // Aumentado de 15.0
          right: 20.0, // Aumentado de 15.0
          // Garante espaço abaixo, especialmente se o teclado aparecer (embora improvável aqui)
          bottom: MediaQuery.of(context).viewInsets.bottom +
              35.0 // Aumentado de 20.0
          ),
      child: Wrap(
        // Wrap permite que os itens quebrem linha se necessário
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 25.0, // Espaço horizontal AUMENTADO de 15.0
        runSpacing: 20.0, // Espaço vertical entre linhas AUMENTADO de 10.0
        children: <Widget>[
          // Opção Dislike
          _buildRatingOption(
            context: context,
            icon: Icons.thumb_down_outlined,
            label: "It's not for me",
            // Exemplo: isSelected: currentRating == RatingAction.dislike,
            isSelected: false, // Mudar se tiver estado 'disliked'
            onTap: () {
              Navigator.pop(context);
              movieStore.rateMovie(movie.id, RatingAction.dislike);
            },
          ),
          // Opção Like
          _buildRatingOption(
            context: context,
            icon: Icons.thumb_up_outlined,
            label: "I Like it",
            // Exemplo: isSelected: currentRating == RatingAction.like,
            isSelected: isCurrentlyLiked, // Destaca se está curtido
            onTap: () {
              Navigator.pop(context);
              movieStore.rateMovie(movie.id, RatingAction.like);
            },
          ),
          // Opção Love It
          _buildRatingOption(
            context: context,
            icon: Icons.favorite_outline, // Ícone de coração
            label: "I love it!",
            // Exemplo: isSelected: currentRating == RatingAction.loveIt,
            isSelected: false, // Mudar se tiver estado 'loved'
            onTap: () {
              Navigator.pop(context);
              movieStore.rateMovie(movie.id, RatingAction.loveIt);
            },
          ),
          // Botão Fechar
          // Adicionado um Padding extra para garantir separação, especialmente se o Wrap quebrar linha
          Padding(
            padding: const EdgeInsets.only(
                left: 15.0, top: 5.0), // Ajuste conforme necessário
            child: IconButton(
              icon: Icon(Icons.close,
                  color: AppColors.buttonPrimary), // Tamanho um pouco maior
              tooltip: 'Close',
              padding: const EdgeInsets.all(12.0), // Aumenta a área de toque
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  // Helper para construir cada opção de avaliação
  Widget _buildRatingOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color selectedColor =
        AppColors.buttonPrimary; // Cor da opção selecionada
    final Color defaultColor = Colors.grey[400]!; // Cor padrão

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12), // Raio um pouco maior
      child: Padding(
        // Padding interno da opção aumentado
        padding: const EdgeInsets.symmetric(
            horizontal: 12.0, vertical: 12.0), // Aumentado de 10/8
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 35, // Tamanho do ícone AUMENTADO de 30
              color: isSelected
                  ? selectedColor
                  : defaultColor, // Muda cor se selecionado
            ),
            const SizedBox(height: 8), // Espaço AUMENTADO de 6
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13, // Tamanho da fonte AUMENTADO de 12
                color: isSelected
                    ? selectedColor
                    : defaultColor, // Muda cor se selecionado
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
