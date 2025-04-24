// lib/features/movies/presentation/widgets/rating_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/movie_entity.dart';
import 'package:desafio_loomi/app/features/movies/presentation/store/movie_store.dart'; // Precisa do MovieStore e RatingAction
import 'package:desafio_loomi/app/core/themes/app_colors.dart';

// Função PÚBLICA que será chamada pela HomePage
void displayRatingSheet({
  required BuildContext context,
  required Movie movie,
  required MovieStore movieStore,
}) {
  final screenHeight = MediaQuery.of(context).size.height;
  final sheetHeight = screenHeight * 0.35;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.grey[900]?.withOpacity(0.95),
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: sheetHeight,
      minHeight: sheetHeight,
    ),
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
    final double iconSize = 36.0; // Tamanho maior para os ícones
    final double textSize = 14.0;
    return Padding(
      // Padding geral dentro do bottom sheet
      padding: EdgeInsets.only(
          top: 20.0,
          left: 15.0,
          right: 15.0,
          bottom: MediaQuery.of(context).viewInsets.bottom +
              20.0 // Espaço para teclado (se houver) e geral
          ),
      child: Wrap(
        // Wrap permite que os itens quebrem linha se necessário
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 15.0, // Espaço horizontal
        runSpacing: 10.0, // Espaço vertical entre linhas
        children: <Widget>[
          // Opção Dislike
          _buildRatingOption(
            context: context,
            icon: Icons.thumb_down_outlined,
            label: "It's not for me",
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
            isSelected: false, // Mudar se tiver estado 'loved'
            onTap: () {
              Navigator.pop(context);
              movieStore.rateMovie(movie.id, RatingAction.loveIt);
            },
          ),
          // Botão Fechar (pode ser um IconButton ou um TextButton)
          Container(
            // Container para dar um alinhamento ou espaço se necessário
            margin: const EdgeInsets.only(left: 10), // Exemplo de margem
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.grey[400], size: 28),
              tooltip: 'Close',
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
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 30,
              color: isSelected
                  ? selectedColor
                  : defaultColor, // Muda cor se selecionado
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
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
