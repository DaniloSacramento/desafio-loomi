// lib/features/movies/presentation/widgets/movie_card_skeleton.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // Importa o pacote shimmer

class MovieCardSkeleton extends StatelessWidget {
  const MovieCardSkeleton({super.key});

  // Helper para criar os retângulos cinzas do skeleton
  Widget _buildPlaceholder(double height, double width,
      {double borderRadius = 8.0}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white, // Cor base sobre a qual o shimmer vai desenhar
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define as cores do efeito shimmer
    final Color baseColor =
        Colors.grey[850]!; // Cinza escuro para o fundo do placeholder
    final Color highlightColor =
        Colors.grey[700]!; // Cinza um pouco mais claro para o brilho

    final screenWidth = MediaQuery.of(context).size.width;

    // Envolve todo o skeleton com o widget Shimmer
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(
          milliseconds: 1200), // Controla a velocidade da animação
      child: Container(
        // Container principal com a mesma forma do MovieCard
        decoration: BoxDecoration(
          color: Colors.black, // Cor de fundo necessária para o shimmer
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: ClipRRect(
          // Mantém as bordas arredondadas
          borderRadius: BorderRadius.circular(24.0),
          child: Stack(
            // Usa Stack para simular as camadas
            fit: StackFit.expand,
            children: [
              // Simula a área de conteúdo principal (textos, botões)
              Positioned.fill(
                child: Padding(
                  // Padding igual ao do MovieCard original
                  padding: const EdgeInsets.only(
                      top: 40.0, bottom: 25.0, left: 25.0, right: 25.0),
                  child: Column(
                    // Estrutura vertical similar ao MovieCard
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Placeholder para Gênero
                      _buildPlaceholder(14, 80),
                      const SizedBox(height: 10.0),
                      // Placeholder para Nome
                      _buildPlaceholder(22, screenWidth * 0.5),
                      const SizedBox(height: 12.0),
                      // Placeholders para Sinopse (várias linhas)
                      _buildPlaceholder(14, double.infinity), // Linha completa
                      const SizedBox(height: 6.0),
                      _buildPlaceholder(14, double.infinity), // Linha completa
                      const SizedBox(height: 6.0),
                      _buildPlaceholder(14, screenWidth * 0.7), // Linha parcial
                      const SizedBox(height: 28.0),

                      // Placeholder para Botão Watch
                      _buildPlaceholder(50, double.infinity,
                          borderRadius: 12.0),
                      const SizedBox(height: 15.0),
                      // Placeholder para Divisor
                      _buildPlaceholder(1, double.infinity),
                      const SizedBox(height: 10.0),
                      // Placeholders para botões Rate/Share
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            // Placeholder Botão Rate
                            children: [
                              _buildPlaceholder(30, 30),
                              const SizedBox(height: 6),
                              _buildPlaceholder(11, 40),
                            ],
                          ),
                          Column(
                            // Placeholder Botão Share
                            children: [
                              _buildPlaceholder(30, 30),
                              const SizedBox(height: 6),
                              _buildPlaceholder(11, 40),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
