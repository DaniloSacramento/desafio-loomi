// lib/features/movies/presentation/pages/video_player_page.dart
import 'dart:async'; // Para Future
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart'; // Import video_player
import 'package:chewie/chewie.dart' as chewie; // Import chewie
import 'package:dio/dio.dart'; // Import Dio para o helper
import 'package:desafio_loomi/app/features/movies/domain/entities/movie_entity.dart';
import 'package:desafio_loomi/app/features/movies/presentation/store/video_player_store.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/subtitle_entity.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart'; // Import MobX para ReactionDisposer

// Função helper para baixar legendas (pode ficar aqui ou em outro arquivo)
Future<String?> fetchSubtitleContent(String url) async {
  if (url.isEmpty) return null;
  try {
    final dio = Dio();
    print("Baixando legenda da URL: $url");
    final response = await dio.get<String>(url);
    if (response.statusCode == 200 && response.data != null) {
      print("Conteúdo da legenda baixado (${response.data!.length} chars).");
      return response.data;
    }
    print("Falha ao baixar legenda: Status ${response.statusCode}");
    return null;
  } catch (e) {
    print("Erro ao baixar conteúdo da legenda de $url: $e");
    return null;
  }
}

class VideoPlayerPage extends StatefulWidget {
  final Movie movie;

  const VideoPlayerPage({super.key, required this.movie});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  // Use 'late final' se for inicializar no initState via GetIt e tiver certeza que está registrado
  // Ou inicialize diretamente se não usar GetIt para o store específico da página
  late final VideoPlayerStore videoStore;

  VideoPlayerController? _videoPlayerController; // Inicializa como null
  chewie.ChewieController? _chewieController;
  bool _isPlayerInitialized = false; // Flag para UI
  ReactionDisposer? _subtitleReactionDisposer; // Para limpar a reação do MobX

  @override
  void initState() {
    super.initState();
    videoStore = GetIt.I.get<VideoPlayerStore>();

    print(
        "VideoPlayerPage: Iniciando e configurando orientação para paisagem...");
    // *** FORÇA A ORIENTAÇÃO PARA PAISAGEM AO ENTRAR NA TELA ***
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    // Opcional: Entrar em modo de tela cheia (esconder barras de status/navegação)
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Busca metadados das legendas e inicializa player (como antes)
    videoStore.fetchSubtitles(widget.movie.id).then((_) {
      if (mounted) {
        initializePlayer();
      }
    });

    // Reaction para legendas (como antes)
    _subtitleReactionDisposer = reaction(
      (_) => videoStore.selectedSubtitle,
      (Subtitle? newSubtitle) => _updatePlayerSubtitle(newSubtitle),
      delay: 300,
    );
    print("VideoPlayerPage: initState completo.");
  }

  /// Inicializa o VideoPlayerController e o ChewieController
  Future<void> initializePlayer() async {
    // Garante que não estamos inicializando múltiplas vezes
    if (_isPlayerInitialized || _videoPlayerController != null) {
      print("Inicialização do Player já em andamento ou concluída.");
      return;
    }
    print("Inicializando Player para: ${widget.movie.streamLink}");

    // Limpa controllers antigos (importante se re-inicializar)
    await _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _videoPlayerController = null;
    _chewieController = null;
    _isPlayerInitialized = false;
    if (mounted) setState(() {}); // Mostra loading na UI

    // Cria o controller base
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.movie.streamLink),
    );

    try {
      // Inicializa o controller base
      await _videoPlayerController!.initialize();
      print("VideoPlayerController inicializado com sucesso.");

      // Define a legenda inicial (se houver uma selecionada no store)
      // await _updatePlayerSubtitle(videoStore.selectedSubtitle); // <<< MOVIDO para reaction

      // Cria o ChewieController APÓS inicializar o video player
      _createChewieController();

      _isPlayerInitialized = true; // Marca como inicializado para a UI
      if (mounted) setState(() {}); // Atualiza a UI para mostrar o player
      print("Player pronto para exibição.");
    } catch (e) {
      print("ERRO ao inicializar video player: $e");
      _isPlayerInitialized = false; // Garante que está falso em caso de erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao carregar vídeo: ${e.toString()}")),
        );
        setState(() {}); // Atualiza UI para mostrar erro ou estado vazio
      }
    }
  }

  /// Atualiza a legenda no VideoPlayerController base
  Future<void> _updatePlayerSubtitle(Subtitle? subtitle) async {
    // Não faz nada se o player base não estiver pronto
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized) {
      print("Atualização de legenda ignorada: Player não inicializado.");
      return;
    }
    print(
        "Tentando atualizar legenda para: ${subtitle?.language ?? 'Nenhuma'} (URL: ${subtitle?.fileUrl})");

    ClosedCaptionFile? captionFile; // Objeto esperado pelo video_player

    if (subtitle != null && subtitle.fileUrl.isNotEmpty) {
      // 1. Baixa o conteúdo da legenda
      final String? subtitleContent =
          await fetchSubtitleContent(subtitle.fileUrl);

      if (subtitleContent != null) {
        print(
            "Conteúdo da legenda ${subtitle.language} obtido. Preparando ClosedCaptionFile.");
        // 2. Cria o objeto ClosedCaptionFile com o conteúdo baixado
        //    Assume VTT como padrão se não conseguir determinar, ajuste se necessário.
        //    Verifique o formato real retornado pela sua API (no SubtitleModel.fromJson).
        try {
          if (subtitle.format.toLowerCase().contains('vtt')) {
            captionFile = WebVTTCaptionFile(subtitleContent); // Para WebVTT
            print("Arquivo WebVTT preparado.");
          } else if (subtitle.format.toLowerCase().contains('srt')) {
            captionFile = SubRipCaptionFile(subtitleContent); // Para SubRip
            print("Arquivo SubRip preparado.");
          } else {
            print(
                "Formato de legenda não suportado diretamente: ${subtitle.format}. Tentando como VTT.");
            captionFile =
                WebVTTCaptionFile(subtitleContent); // Tenta VTT como fallback
          }
        } catch (e) {
          print("Erro ao processar conteúdo da legenda: $e");
          captionFile = null;
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    Text("Erro ao processar legenda ${subtitle.language}.")));
        }
      } else {
        print("Falha ao baixar conteúdo da legenda ${subtitle.language}.");
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Falha ao baixar legenda ${subtitle.language}.")));
      }
    } else {
      print("Nenhuma legenda selecionada ou URL vazia.");
    }

    // 3. Define a legenda no VideoPlayerController
    try {
      // Passa o Future diretamente. Use Future.value(null) para limpar.
      await _videoPlayerController!
          .setClosedCaptionFile(Future.value(captionFile));
      print(
          "setClosedCaptionFile chamado com ${captionFile == null ? 'null' : 'arquivo'}.");

      // Força a exibição das legendas se uma foi definida (opcional)
      _videoPlayerController!
          .setCaptionOffset(Duration.zero); // Garante offset zero
      // A visibilidade da legenda geralmente é controlada pelo usuário nos controles do Chewie
      // mas você pode tentar forçar aqui se necessário:
      // await _videoPlayerController!.setClosedCaptionFile(Future.value(captionFile), /* enable: captionFile != null */); // 'enable' não existe mais
    } catch (e) {
      print("ERRO ao definir legenda no player: $e");
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erro ao ativar legenda.")));
    }
  }

  /// Cria ou recria o ChewieController
  void _createChewieController() {
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized) {
      print("Criação do ChewieController ignorada: Player não inicializado.");
      return;
    }
    print("Criando ChewieController...");

    // Limpa o controller antigo do Chewie se existir
    _chewieController?.dispose();

    _chewieController = chewie.ChewieController(
      videoPlayerController: _videoPlayerController!,
      aspectRatio: _videoPlayerController!
          .value.aspectRatio, // Usa aspect ratio do vídeo
      autoPlay: true, // Começa tocando
      looping: false,
      // --- Configurações de Legenda no Chewie ---
      // Não passamos mais `subtitle` ou `closedCaptionFile` aqui.
      // Chewie deve usar as legendas configuradas no _videoPlayerController.
      // Apenas garantimos que os controles de legenda estejam habilitados (geralmente padrão).
      allowedScreenSleep: false,
      allowFullScreen: true,
      showControls:
          true, // Garante que os controles (incluindo de legenda) apareçam

      // Placeholder e Error Builder (opcional)
      placeholder: Container(color: Colors.black),
      errorBuilder: (context, errorMessage) {
        return Center(
          child:
              Text(errorMessage, style: const TextStyle(color: Colors.white)),
        );
      },

      // TODO (Avançado): Adicionar botão customizado para seleção de legendas
      // usando `customControls` ou explorando `additionalOptions` se suportado.
    );
    print("ChewieController criado.");
  }

  @override
  void dispose() {
    print("Disposing VideoPlayerPage e agendando restauração de orientação...");
    _subtitleReactionDisposer?.call(); // Limpa reaction MobX

    // Pausa e libera os controllers de vídeo PRIMEIRO
    _chewieController?.pause();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();

    // --- ATRASA A MUDANÇA DE ORIENTAÇÃO ---
    // Aguarda um curto período (ex: 100ms) antes de voltar para retrato
    Future.delayed(const Duration(milliseconds: 100), () {
      // Só executa se o widget ainda existir (boa prática)
      // Embora no dispose seja menos crítico, não custa manter
      // if (mounted) { // 'mounted' não é acessível diretamente após o delay inicial do dispose
      print("Restaurando orientação para retrato/padrão...");
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      // Restaura modo da UI também (se você usou immersiveSticky)
      SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge); // Ou SystemUiMode.manual
      // }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fundo preto para player
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.movie.name, style: const TextStyle(fontSize: 16)),
        actions: [
          // Botão para selecionar legendas (usa Observer para reagir ao store)
          Observer(builder: (_) {
            // Mostra um indicador enquanto carrega as legendas
            if (videoStore.isLoadingSubtitles) {
              return const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))),
              );
            }
            // Não mostra o botão se não houver legendas disponíveis
            if (videoStore.subtitles.isEmpty) {
              return const SizedBox.shrink();
            }
            // Botão para abrir o menu de legendas
            return PopupMenuButton<Subtitle?>(
              icon: const Icon(Icons.subtitles_outlined),
              tooltip: "Legendas",
              onSelected: (Subtitle? selected) {
                // Chama a action no store para atualizar a seleção
                // A reaction no initState cuidará de atualizar o player
                videoStore.selectSubtitle(selected);
              },
              itemBuilder: (BuildContext context) {
                List<PopupMenuItem<Subtitle?>> items = [];
                // Opção "Nenhuma"
                items.add(
                  const PopupMenuItem<Subtitle?>(
                    value: null, // Valor nulo para desativar
                    child: Text("Nenhuma"),
                  ),
                );
                // Opções para cada legenda disponível
                items.addAll(videoStore.subtitles.map((subtitle) {
                  return PopupMenuItem<Subtitle?>(
                    value: subtitle,
                    child: Text(subtitle.language), // Exibe o idioma
                  );
                }).toList());
                return items;
              },
              // Define o valor inicial baseado na seleção atual do store
              initialValue: videoStore.selectedSubtitle,
            );
          })
        ],
      ),
      // Corpo da tela com o player
      body: Center(
        child: _isPlayerInitialized && _chewieController != null
            ? chewie.Chewie(
                controller: _chewieController!) // Mostra o player Chewie
            : const Column(
                // Mostra loading enquanto inicializa
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text('Carregando vídeo...',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
      ),
    );
  }
}
