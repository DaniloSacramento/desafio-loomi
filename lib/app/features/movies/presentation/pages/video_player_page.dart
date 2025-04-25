// lib/features/movies/presentation/pages/video_player_page.dart
import 'dart:async';
import 'package:desafio_loomi/app/features/movies/presentation/widgets/comments_side_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart' as chewie;
import 'package:dio/dio.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/movie_entity.dart';
import 'package:desafio_loomi/app/features/movies/presentation/store/video_player_store.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/subtitle_entity.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

Future<String?> fetchSubtitleContent(String url) async {
  if (url.isEmpty) return null;
  try {
    final dio = Dio();
    print("[Util] Baixando legenda da URL: $url");
    final response = await dio.get<String>(url); // Pede String direto
    if (response.statusCode == 200 && response.data != null) {
      print(
          "[Util] Conteúdo da legenda baixado (${response.data!.length} chars).");
      return response.data;
    }
    print("[Util] Falha ao baixar legenda: Status ${response.statusCode}");
    return null;
  } catch (e) {
    print("[Util] Erro ao baixar conteúdo da legenda de $url: $e");
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
  late final VideoPlayerStore videoStore;
  VideoPlayerController? _videoPlayerController;
  chewie.ChewieController? _chewieController;
  bool _isPlayerInitialized = false;
  ReactionDisposer? _subtitleReactionDisposer;

  bool _isCommentsPanelVisible = false;
  final double _commentsPanelWidth = 360.0; // Largura do painel (ajuste)

  @override
  void initState() {
    super.initState();
    videoStore = GetIt.I.get<VideoPlayerStore>();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    videoStore.fetchSubtitles(widget.movie.id).then((_) {
      if (mounted) {
        initializePlayer();
      }
    });

    _subtitleReactionDisposer = reaction(
      (_) => videoStore.selectedSubtitle,
      (Subtitle? newSubtitle) => _updatePlayerSubtitle(newSubtitle),
      delay: 200,
    );
  }

  Future<void> initializePlayer() async {
    if (_isPlayerInitialized || _videoPlayerController != null) return;
    print(
        "[VideoPlayerPage] initializePlayer: Iniciando para ${widget.movie.streamLink}");

    await _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _videoPlayerController = null;
    _chewieController = null;
    _isPlayerInitialized = false;
    if (mounted) setState(() {});

    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.movie.streamLink),
      );
      await _videoPlayerController!.initialize(); // Espera inicializar
      print(
          "[VideoPlayerPage] initializePlayer: VideoPlayerController inicializado.");

      _createChewieController();

      _isPlayerInitialized = true;
      if (mounted) setState(() {});
      print("[VideoPlayerPage] initializePlayer: Player pronto.");

      if (videoStore.selectedSubtitle != null) {
        print(
            "[VideoPlayerPage] initializePlayer: Chamando _updatePlayerSubtitle para legenda inicial selecionada.");
        await _updatePlayerSubtitle(videoStore.selectedSubtitle);
      }
    } catch (e) {
      print("[VideoPlayerPage] initializePlayer: ERRO $e");
      _isPlayerInitialized = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao carregar vídeo: ${e.toString()}")),
        );
        setState(() {});
      }
    }
  }

  Future<void> _updatePlayerSubtitle(Subtitle? subtitle) async {
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized) {
      print(
          "[VideoPlayerPage] _updatePlayerSubtitle: Player não pronto. Ignorando.");
      return;
    }
    print(
        "[VideoPlayerPage] _updatePlayerSubtitle: Atualizando para ${subtitle?.language ?? 'Nenhuma'} (URL: ${subtitle?.fileUrl})");

    ClosedCaptionFile? captionFile; // Tipo esperado pelo video_player

    if (subtitle != null && subtitle.fileUrl.isNotEmpty) {
      final String? subtitleContent =
          await fetchSubtitleContent(subtitle.fileUrl);

      if (subtitleContent != null) {
        try {
          if (subtitle.format.toLowerCase().contains('vtt')) {
            captionFile = WebVTTCaptionFile(subtitleContent);
            print(
                "[VideoPlayerPage] _updatePlayerSubtitle: Arquivo WebVTT criado.");
          } else if (subtitle.format.toLowerCase().contains('srt')) {
            captionFile = SubRipCaptionFile(subtitleContent);
            print(
                "[VideoPlayerPage] _updatePlayerSubtitle: Arquivo SubRip criado.");
          } else {
            print(
                "[VideoPlayerPage] _updatePlayerSubtitle: Formato '${subtitle.format}' não reconhecido, tentando como VTT.");
            captionFile = WebVTTCaptionFile(subtitleContent); // Fallback
          }
        } catch (e) {
          print(
              "[VideoPlayerPage] _updatePlayerSubtitle: Erro ao processar legenda ${subtitle.language}: $e");
          captionFile = null;
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    Text("Erro ao processar legenda ${subtitle.language}.")));
        }
      } else {
        print(
            "[VideoPlayerPage] _updatePlayerSubtitle: Falha ao baixar conteúdo da legenda ${subtitle.language}.");
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Falha ao baixar legenda ${subtitle.language}.")));
      }
    } else {
      print(
          "[VideoPlayerPage] _updatePlayerSubtitle: Nenhuma legenda para definir (selecionado 'Nenhuma' ou URL vazia).");
    }

    try {
      await _videoPlayerController!
          .setClosedCaptionFile(Future.value(captionFile));
      print(
          "[VideoPlayerPage] _updatePlayerSubtitle: setClosedCaptionFile chamado com ${captionFile == null ? 'null' : 'arquivo'}.");
    } catch (e) {
      print(
          "[VideoPlayerPage] _updatePlayerSubtitle: ERRO ao definir legenda no player: $e");
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erro ao ativar legenda.")));
    }
  }

  void _createChewieController() {
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized) return;
    print("[VideoPlayerPage] _createChewieController: Criando...");

    _chewieController?.dispose(); // Limpa anterior se houver

    _chewieController = chewie.ChewieController(
      videoPlayerController: _videoPlayerController!,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      autoPlay: true,
      looping: false,
      // Não precisa mais passar legendas aqui, Chewie usa as do _videoPlayerController
      allowedScreenSleep: false,
      allowFullScreen: true,
      showControls: true,
      // Melhora a exibição de erros no player
      errorBuilder: (context, errorMessage) {
        return Container(
          color: Colors.black,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Erro no vídeo: $errorMessage",
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
    print("[VideoPlayerPage] _createChewieController: Criado.");
  }

  void _toggleCommentsPanel() {
    setState(() {
      _isCommentsPanelVisible = !_isCommentsPanelVisible;
    });
  }

  @override
  void dispose() {
    print("[VideoPlayerPage] dispose: Iniciando limpeza...");
    _subtitleReactionDisposer?.call();
    _videoPlayerController?.pause();
    _chewieController?.pause();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    print("[VideoPlayerPage] dispose: Controllers disposed.");
    // Volta para orientação retrato
    // É importante fazer isso DEPOIS que a tela foi removida
    // Usar addPostFrameCallback pode não ser ideal aqui.
    // Uma abordagem mais simples é agendar com um pequeno delay.
    Future.delayed(const Duration(milliseconds: 100), () {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      print("[VideoPlayerPage] dispose: Orientação restaurada.");
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height; // Altura da tela

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        title: Text(widget.movie.name, style: const TextStyle(fontSize: 16)),
        actions: [
          // Botão Legendas (como antes)
          Observer(builder: (_) {
            if (videoStore.isLoadingSubtitles) {
              return const Padding(
                padding: EdgeInsets.all(14.0),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white)),
              );
            }
            if (videoStore.subtitles.isEmpty) {
              return const SizedBox.shrink();
            }
            return PopupMenuButton<Subtitle?>(
              icon: const Icon(Icons.subtitles_outlined, color: Colors.white),
              tooltip: "Selecionar Legenda",
              onSelected: videoStore.selectSubtitle, // Chama action do store
              itemBuilder: (BuildContext context) {
                List<PopupMenuItem<Subtitle?>> items = [
                  PopupMenuItem<Subtitle?>(
                    value: null,
                    child: Text("Desativada",
                        style: TextStyle(
                            fontWeight: videoStore.selectedSubtitle == null
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                ];
                items.addAll(videoStore.subtitles.map((subtitle) {
                  bool isSelected =
                      videoStore.selectedSubtitle?.id == subtitle.id;
                  return PopupMenuItem<Subtitle?>(
                    value: subtitle,
                    child: Text(
                      subtitle.language,
                      style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal),
                    ),
                  );
                }).toList());
                return items;
              },
              initialValue: videoStore.selectedSubtitle,
            );
          }),

          IconButton(
            icon: const Icon(Icons.comment_outlined, color: Colors.white),
            tooltip: "Comentários",
            onPressed:
                _toggleCommentsPanel, // Chama a função para mostrar/esconder
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: _isPlayerInitialized && _chewieController != null
                ? chewie.Chewie(controller: _chewieController!)
                : const CircularProgressIndicator(
                    color: Colors.white), // Loading
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300), // Duração da animação
            curve: Curves.easeInOut, // Curva da animação
            right:
                _isCommentsPanelVisible ? 0 : -_commentsPanelWidth, // Posição
            top: 0,
            bottom: 0,
            width: _commentsPanelWidth, // Largura definida
            child: CommentsSidePanel(
              // O novo widget
              movieId: widget.movie.id.toString(), // Passa o ID do filme
              movieTitle: widget.movie.name, // Passa o título
              onClose: _toggleCommentsPanel, // Passa a função para fechar
            ),
          ),
        ],
      ),
    );
  }
}
