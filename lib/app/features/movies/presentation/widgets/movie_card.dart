// lib/features/movies/presentation/widgets/movie_card.dart

import 'package:desafio_loomi/app/core/themes/app_colors.dart'; // Importa suas cores
import 'package:desafio_loomi/app/features/movies/domain/entities/movie_entity.dart'; // Importa a entidade Movie
import 'package:flutter/material.dart';
import 'dart:ui'
    as ui; // Usado para efeitos se necessário (mas não neste código)

// MovieCard agora é Stateless e recebe um callback para a ação de "Rate"
class MovieCard extends StatelessWidget {
  final Movie movie;
  final bool isLiked; // Estado atual de like (vem do store)
  final bool isLoadingLike; // Estado de loading da ação de like/unlike
  final VoidCallback onRatePressed;
  final VoidCallback onSharePressed; // Callback para compartilhar
  final VoidCallback onWatchPressed; // Callback para assistir

  const MovieCard({
    required Key key, // Chave é importante para listas e performance
    required this.movie,
    required this.isLiked,
    required this.isLoadingLike,
    required this.onRatePressed, // Exige o callback onRatePressed
    required this.onSharePressed,
    required this.onWatchPressed,
  }) : super(key: key);

  // Estilo de sombra para textos sobre a imagem (opcional)
  final List<Shadow> _overlayTextShadows = const [
    Shadow(blurRadius: 6.0, color: Colors.black87, offset: Offset(0, 1.5))
  ];

  @override
  Widget build(BuildContext context) {
    // Obtém informações de tamanho e padding da tela
    final EdgeInsets safePadding = MediaQuery.of(context).padding;
    final screenHeight = MediaQuery.of(context).size.height;

    // Define qual URL de imagem usar (com fallbacks)
    final String? backgroundImageUrl =
        movie.poster?.largeUrl ?? movie.poster?.mediumUrl ?? movie.poster?.url;

    // Estrutura principal do Card
    return OrientationBuilder(builder: (context, orientation) {
      // Determina se está em modo retrato
      bool isPortrait = orientation == Orientation.portrait;
      // Log para depuração (opcional)
      // print("MovieCard build - Orientation: $orientation");

      // Ajusta valores com base na orientação
      double bottomPadding =
          isPortrait ? 25.0 : 15.0; // Menos padding embaixo em paisagem
      int synopsisMaxLines =
          isPortrait ? 3 : 2; // Menos linhas para sinopse em paisagem
      double titleFontSize = isPortrait ? 22 : 20; // Fonte menor em paisagem
      double synopsisFontSize = isPortrait ? 14 : 13; // Fonte menor em paisagem
      double spacingBeforeButtons =
          isPortrait ? 25.0 : 15.0; // Menos espaço antes dos botões

      // Retorna a estrutura do Card
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            // Sombra sutil no card
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          // Corta o conteúdo para as bordas arredondadas
          borderRadius: BorderRadius.circular(24.0),
          child: Stack(
            // Empilha imagem, gradiente e conteúdo
            fit: StackFit.expand,
            children: [
              _buildBackgroundImage(
                  backgroundImageUrl), // Camada de fundo (Imagem)
              _buildGradientOverlay(screenHeight), // Camada de gradiente
              _buildContentOverlay(
                  safePadding,
                  context,
                  isPortrait,
                  bottomPadding,
                  synopsisMaxLines,
                  titleFontSize,
                  synopsisFontSize,
                  spacingBeforeButtons), // Camada de texto e botões
            ],
          ),
        ),
      );
    });
  }

  // --- Widgets Internos (Helpers) ---

  // Constrói a imagem de fundo com tratamento de loading/erro
  Widget _buildBackgroundImage(String? imageUrl) {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: (imageUrl != null && imageUrl.isNotEmpty)
            ? Image.network(
                imageUrl,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  // Animação de fade-in da imagem
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  // Placeholder enquanto carrega
                  if (loadingProgress == null) return child;
                  return Container(color: Colors.grey[900]);
                },
                errorBuilder: (context, error, stackTrace) {
                  // Placeholder em caso de erro ao carregar imagem
                  return Container(
                    color: Colors.grey[850],
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: Colors.white38, size: 50),
                    ),
                  );
                },
              )
            : Container(
                // Placeholder se não houver imagem
                color: Colors.grey[900],
                child: const Center(
                  child: Icon(Icons.movie_filter_outlined,
                      color: Colors.white54, size: 60),
                ),
              ),
      ),
    );
  }

  // Constrói o gradiente escuro na base do card
  Widget _buildGradientOverlay(double screenHeight) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.1),
              Colors.black.withOpacity(0.85), // Mais escuro na base
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0], // Pontos de parada do gradiente
          ),
        ),
      ),
    );
  }

  // Constrói a camada de conteúdo (textos e botões)
  Widget _buildContentOverlay(
      EdgeInsets safePadding,
      BuildContext context,
      bool isPortrait,
      double bottomPadding,
      int synopsisMaxLines,
      double titleFontSize,
      double synopsisFontSize,
      double spacingBeforeButtons) {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 40.0, bottom: 25.0, left: 25.0, right: 25.0, // Padding interno
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end, // Alinha conteúdo na base
          crossAxisAlignment:
              CrossAxisAlignment.start, // Alinha textos à esquerda
          children: [
            // --- Textos do Filme ---
            Text(
              movie.genre.toUpperCase(),
              style: TextStyle(
                color: AppColors.white.withOpacity(0.85),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                shadows: _overlayTextShadows,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              movie.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.2,
                shadows: _overlayTextShadows,
              ),
            ),
            const SizedBox(height: 10.0),
            Text(
              movie.synopsis,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                shadows: _overlayTextShadows,
              ),
            ),
            const SizedBox(height: 25.0),

            // --- Botões de Ação ---
            _buildActionButtons(context), // Chama o helper que contém os botões
          ],
        ),
      ),
    );
  }

  // Constrói a seção com os botões principais (Watch, Rate, Share)
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- Botão Watch ---
        ElevatedButton(
          onPressed: onWatchPressed, // Usa o callback passado
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.buttonText,
            minimumSize: const Size(double.infinity, 50),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ).copyWith(elevation: MaterialStateProperty.all(5.0)),
          child: const Text('Watch'), // Texto do botão (ajuste se necessário)
        ),
        const SizedBox(height: 15.0),

        // --- Divisor ---
        Divider(color: AppColors.grey.withOpacity(0.5), thickness: 1),
        const SizedBox(height: 10.0),

        // --- Linha com botões Rate e Share ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, // Espaça igualmente
          children: [
            _buildRateButton(context), // Chama o helper do botão Rate
            _buildActionButton(
              // Chama o helper do botão Share
              Icons.share_outlined,
              'Share',
              onSharePressed, // Usa o callback passado
              showText: true, // Mostra o texto abaixo do ícone
            ),
          ],
        ),
      ],
    );
  }

  // Helper para o botão "Rate" que agora abre o BottomSheet via callback
  Widget _buildRateButton(BuildContext context) {
    IconData currentIcon;
    String currentLabel;
    Color currentColor;
    final List<Shadow> textShadows = _overlayTextShadows;

    // Define a aparência baseado no estado atual
    if (isLoadingLike) {
      currentIcon = Icons.hourglass_empty;
      currentLabel = "Rating...";
      currentColor = Colors.grey[600]!;
    } else if (isLiked) {
      currentIcon = Icons.thumb_up;
      currentLabel = "Liked";
      currentColor = AppColors.buttonPrimary;
    } else {
      currentIcon = Icons.thumb_up_off_alt;
      currentLabel = "Rate";
      currentColor = Colors.white.withOpacity(0.9);
    }

    // Widget clicável
    return InkWell(
      onTap: isLoadingLike
          ? null
          : onRatePressed, // <<< Chama o callback onRatePressed
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Container para o ícone e possível spinner de loading
            SizedBox(
              width: 30,
              height: 30,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(currentIcon,
                      color: currentColor, size: 30, shadows: textShadows),
                  // Mostra spinner se estiver carregando
                  if (isLoadingLike)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white70),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Texto abaixo do ícone
            Text(
              currentLabel,
              style: TextStyle(
                  color: currentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  shadows: textShadows),
            ),
          ],
        ),
      ),
    );
  }

  // Helper genérico para outros botões de ação (como Share)
  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed,
      {bool showText = true}) {
    final iconWidget = Icon(icon,
        color: Colors.white.withOpacity(0.9),
        size: 28,
        shadows: _overlayTextShadows);
    final textWidget = Text(label,
        style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            shadows: _overlayTextShadows));

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            if (showText) const SizedBox(height: 6),
            if (showText) textWidget,
          ],
        ),
      ),
    );
  }
}
