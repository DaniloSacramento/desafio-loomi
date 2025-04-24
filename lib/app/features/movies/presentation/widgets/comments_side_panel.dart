// lib/features/movies/presentation/widgets/comments_side_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart'; // Para formatar datas

import 'package:desafio_loomi/app/features/movies/domain/entities/comments_entity.dart';
import 'package:desafio_loomi/app/features/movies/presentation/store/comments_store.dart';
// Remova a importação do AuthStore daqui se não for usar diretamente na UI
// import 'package:desafio_loomi/app/features/auth/presentation/store/auth_store.dart';

class CommentsSidePanel extends StatefulWidget {
  final String movieId;
  final String movieTitle; // Pode usar para o título se quiser
  final VoidCallback onClose; // Função para fechar o painel

  const CommentsSidePanel({
    super.key,
    required this.movieId,
    required this.movieTitle,
    required this.onClose,
  });

  @override
  State<CommentsSidePanel> createState() => _CommentsSidePanelState();
}

class _CommentsSidePanelState extends State<CommentsSidePanel> {
  // Obtém instância do store (assumindo GetIt configurado com factory)
  late final CommentsStore _commentsStore;
  // Controller para o campo de texto de *novo* comentário
  final TextEditingController _commentController = TextEditingController();
  // Controller para a lista de comentários (para rolar para o topo ao adicionar)
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _commentsStore = GetIt.I.get<
        CommentsStore>(); // Pega instância nova ou existente (depende do registro)
    print(
        "[CommentsSidePanel initState] Store HashCode: ${_commentsStore.hashCode}, MovieId: ${widget.movieId}");

    // Adiciona listener para habilitar/desabilitar botão Enviar (baseado no texto)
    // setState({}) vazio força a reconstrução do botão que depende do controller
    _commentController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // Inicia o listener para os comentários deste filme específico
    // Garante que será chamado após a instância do store ser obtida.
    _commentsStore.listenToComments(widget.movieId);
  }

  @override
  void dispose() {
    print(
        "[CommentsSidePanel dispose] Store HashCode: ${_commentsStore.hashCode}. Chamando store.dispose().");
    _commentsStore.dispose(); // Cancela a inscrição do stream de comentários
    _commentController.dispose(); // Limpa o controller de novo comentário
    _scrollController.dispose(); // Limpa o controller da lista
    super.dispose();
  }

  // --- Função para Enviar Novo Comentário ---
  void _sendComment() async {
    if (_commentsStore.isAddingComment ||
        _commentController.text.trim().isEmpty) {
      return;
    }
    final success = await _commentsStore.addComment(
        widget.movieId, _commentController.text);
    if (success && mounted) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
      // <<<<<< AQUI: FORÇA O RECARREGAMENTO >>>>>>
      print("[CommentsSidePanel Workaround] Recarregando após add...");
      _commentsStore.listenToComments(widget.movieId);
      // <<<<<< FIM >>>>>>
    } else if (!success && mounted) {
      // (Mostrar erro SnackBar)
      final errorMsg =
          _commentsStore.addCommentError ?? "Erro desconhecido ao enviar";
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red[700]));
    }
  }

  // --- Função para Mostrar Opções do Comentário (Editar/Excluir/Reportar) ---
  void _showCommentOptionsDialog(BuildContext context, CommentEntity comment) {
    final currentUserId = _commentsStore.getCurrentUserId();
    // Verifica se o usuário logado é o dono do comentário
    final bool isOwner =
        currentUserId != null && currentUserId == comment.userId;

    showModalBottomSheet(
      context: context,
      // Cantos arredondados
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      // Define cor de fundo (opcional, para combinar com tema)
      // backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.white,
      builder: (bottomSheetContext) {
        // Usa um contexto diferente para o pop
        return SafeArea(
          // Garante que não fique sob status bar/notch
          child: Wrap(
            // Usa Wrap para que o conteúdo determine a altura
            children: <Widget>[
              // --- Opções do Dono ---
              if (isOwner) ...[
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Editar'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext); // Fecha o BottomSheet
                    _showEditCommentDialog(
                        context, comment); // Abre Dialog de Edição
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red[400]),
                  title:
                      Text('Excluir', style: TextStyle(color: Colors.red[400])),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext); // Fecha o BottomSheet
                    _confirmDeleteCommentDialog(
                        context, comment); // Abre confirmação
                  },
                ),
              ],
              // --- Opção de Reportar (se não for dono) ---
              if (!isOwner)
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Reportar'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    // TODO: Implementar lógica de reportar (chamar store/backend)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Funcionalidade Reportar ainda não implementada.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              // --- Divisor e Cancelar ---
              const Divider(height: 1, thickness: 1),
              ListTile(
                title: const Center(child: Text('Cancelar')),
                onTap: () =>
                    Navigator.pop(bottomSheetContext), // Fecha o BottomSheet
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Função para Confirmar Exclusão ---
  void _confirmDeleteCommentDialog(
      BuildContext context, CommentEntity comment) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text(
              'Tem certeza que deseja excluir este comentário? Esta ação não pode ser desfeita.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () =>
                  Navigator.of(dialogContext).pop(false), // Retorna false
            ),
            TextButton(
              child: Text('Excluir', style: TextStyle(color: Colors.red[400])),
              onPressed: () =>
                  Navigator.of(dialogContext).pop(true), // Retorna true
            ),
          ],
        );
      },
    );

    // Se o usuário confirmou (retornou true)
    if (confirmDelete == true) {
      final success = await _commentsStore.deleteComment(comment.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Comentário excluído.'),
              backgroundColor: Colors.green));
          // <<<<<< AQUI: FORÇA O RECARREGAMENTO >>>>>>
          print("[CommentsSidePanel Workaround] Recarregando após delete...");
          _commentsStore.listenToComments(widget.movieId);
          // <<<<<< FIM >>>>>>
        } else {
          // (Mostrar erro SnackBar)
          final errorMsg = _commentsStore.deleteCommentError ??
              'Erro ao excluir comentário.';
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
        }
      }
    }
  }

  // --- Função para Mostrar Diálogo de Edição ---
  void _showEditCommentDialog(BuildContext context, CommentEntity comment) {
    // Controller específico para este diálogo
    final TextEditingController editController =
        TextEditingController(text: comment.text);
    // Chave para acessar o estado do formulário (opcional, para validação)
    final formKey = GlobalKey<FormState>();
    // Estado local para botão Salvar
    bool canSave = false;

    showDialog(
      context: context,
      // barrierDismissible: false, // Impede fechar clicando fora? Talvez não seja bom
      builder: (dialogContext) {
        // Usa StatefulBuilder para permitir atualização do estado do botão Salvar
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Atualiza se pode salvar baseado no texto
            canSave = editController.text.trim().isNotEmpty &&
                editController.text.trim() != comment.text;

            return AlertDialog(
              title: const Text('Editar Comentário'),
              content: Form(
                // Usa Form para validação se necessário
                key: formKey,
                child: TextFormField(
                  // Usa TextFormField para integrar com Form
                  controller: editController,
                  autofocus: true,
                  maxLines: null, // Permite múltiplas linhas
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Digite seu comentário...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (text) {
                    // Atualiza o estado do botão quando o texto muda
                    setDialogState(() {});
                  },
                  // Validação (opcional)
                  // validator: (value) {
                  //   if (value == null || value.trim().isEmpty) {
                  //     return 'O comentário não pode ficar vazio.';
                  //   }
                  //   return null;
                  // },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  // Desabilita se o store estiver atualizando (evita duplo clique)
                  onPressed: _commentsStore.isUpdatingComment
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                ),
                // Observer dentro do TextButton para o estado de loading
                Observer(builder: (_) {
                  // Verifica se pode salvar E se não está atualizando
                  final bool finalCanSave =
                      canSave && !_commentsStore.isUpdatingComment;

                  return TextButton(
                    onPressed: finalCanSave
                        ? () async {
                            // Validação do Form (opcional)
                            // if (!(formKey.currentState?.validate() ?? false)) {
                            //   return;
                            // }

                            final String textToSave =
                                editController.text.trim();

                            // Chama o update do store
                            final success = await _commentsStore.updateComment(
                                comment.id, textToSave);

                            // Verifica se o widget ainda está montado ANTES de interagir com o context
                            if (!mounted) return;

                            if (success) {
                              Navigator.of(dialogContext)
                                  .pop(); // Fecha o dialog SÓ SE SUCESSO
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Comentário atualizado!'),
                                    backgroundColor: Colors.green),
                              );
                            } else {
                              // Mostra erro DENTRO do dialog ou via SnackBar após fechar?
                              // Por simplicidade, mostramos SnackBar após fechar
                              Navigator.of(dialogContext)
                                  .pop(); // Fecha mesmo com erro
                              final errorMsg =
                                  _commentsStore.updateCommentError ??
                                      "Erro ao atualizar.";
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(errorMsg),
                                    backgroundColor: Colors.red),
                              );
                            }
                          }
                        : null, // Desabilita o botão se não puder salvar ou se já estiver salvando
                    child: _commentsStore.isUpdatingComment &&
                            _commentsStore.editingCommentId == comment.id
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Salvar'),
                  );
                }),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      // Garante a limpeza do controller quando o dialog for fechado
      // Usar microtask ajuda a evitar erros se o dispose for chamado muito rápido
      Future.microtask(() => editController.dispose());
      print("[CommentsSidePanel] Edit dialog closed and controller disposed.");
    });
  }

  // --- Construção da UI do Painel ---
  @override
  Widget build(BuildContext context) {
    print(
        "[CommentsSidePanel] build: Construindo UI. Store: ${_commentsStore.hashCode}");
    // Definindo cores baseadas no tema
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color panelBackgroundColor =
        isDark ? Colors.grey[850]! : Colors.grey[100]!;
    final Color headerBackgroundColor =
        isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final Color inputAreaBackgroundColor =
        isDark ? Colors.grey[900]! : Colors.grey[200]!;
    final Color inputFieldBackgroundColor =
        isDark ? Colors.grey[800]! : Colors.white;

    return Material(
      // Material para dar elevação e cor de fundo padrão
      elevation: 8.0, // Sombra para destacar o painel
      color: panelBackgroundColor, // Cor de fundo geral do painel
      child: Column(
        children: [
          // --- Cabeçalho ---
          AppBar(
            backgroundColor: headerBackgroundColor,
            elevation: 1, // Linha sutil de separação
            title: const Text("Comentários"), // Título
            leading:
                const SizedBox.shrink(), // Remove o botão de voltar automático
            leadingWidth: 0,
            actions: [
              // Botão para fechar o painel
              TextButton(
                onPressed: widget.onClose,
                child: const Text("Fechar"),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.color, // Cor do texto do botão
                ),
              ),
              const SizedBox(width: 8), // Espaçamento
            ],
          ),

          // --- Lista de Comentários ---
          Expanded(
            child: Observer(
              // Observer principal para a lista e estados gerais
              builder: (_) {
                print(
                    "[CommentsSidePanel List Observer] isLoading: ${_commentsStore.isLoadingComments}, comments: ${_commentsStore.comments.length}, error: ${_commentsStore.commentsError}");

                // 1. Estado de Carregamento Inicial
                if (_commentsStore.isLoadingComments &&
                    _commentsStore.comments.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 2. Estado de Erro
                if (_commentsStore.commentsError != null &&
                    _commentsStore.comments.isEmpty) {
                  // Mostra erro apenas se a lista estiver vazia (pode ter dados antigos com erro de atualização)
                  return Center(
                      child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                              'Erro ao carregar: ${_commentsStore.commentsError}',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red[300]))));
                }

                // 3. Estado Vazio (Após carregar e sem erro)
                if (_commentsStore.comments.isEmpty) {
                  return const Center(
                      child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                              'Nenhum comentário ainda. Seja o primeiro!',
                              textAlign: TextAlign.center)));
                }

                // 4. Estado com Comentários
                return ListView.builder(
                  controller: _scrollController, // Controller para rolagem
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0), // Espaçamento
                  // reverse: true, // Se quiser ordem ASC e input no topo
                  itemCount: _commentsStore.comments.length,
                  itemBuilder: (context, index) {
                    final comment = _commentsStore.comments[index];
                    // Renderiza cada tile de comentário
                    return CommentTile(
                      key: ValueKey(
                          comment.id), // Key para otimização do Flutter
                      comment: comment,
                      // Passa a função para abrir o menu de opções
                      onMoreOptionsTap: () =>
                          _showCommentOptionsDialog(context, comment),
                    );
                  },
                );
              },
            ),
          ),

          // --- Área de Input para Novo Comentário ---
          _buildCommentInputArea(
              inputAreaBackgroundColor, inputFieldBackgroundColor),
        ],
      ),
    );
  }

  // --- Widget para a Área de Input (Separado para organização) ---
  Widget _buildCommentInputArea(
      Color backgroundColor, Color fieldBackgroundColor) {
    return SafeArea(
      // Garante que não fique sob notch/elementos do sistema na base
      top: false, // Não precisa no topo
      bottom: true, // Precisa na base
      child: Container(
        padding: const EdgeInsets.only(
            left: 12.0, right: 8.0, top: 8.0, bottom: 12.0),
        decoration: BoxDecoration(
          color: backgroundColor, // Cor de fundo da área
          boxShadow: [
            // Sombra sutil no topo da área de input
            BoxShadow(
              offset: const Offset(0, -1),
              blurRadius: 2,
              color: Colors.black.withOpacity(0.1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // Alinha verticalmente
          children: [
            // --- Campo de Texto ---
            Expanded(
              child: TextField(
                controller: _commentController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 5, // Permite digitar mais linhas
                decoration: InputDecoration(
                  hintText: 'Adicionar comentário...',
                  // Borda arredondada sem linha visível
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0), // Arredondado
                    borderSide: BorderSide.none, // Sem linha de borda
                  ),
                  filled: true, // Necessário para fillColor funcionar
                  fillColor: fieldBackgroundColor, // Cor de fundo do campo
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0), // Padding interno
                  isDense: true, // Deixa o campo um pouco mais compacto
                ),
                // Envia ao pressionar Enter/Done no teclado
                onSubmitted: (_) => _sendComment(),
              ),
            ),
            const SizedBox(width: 4.0), // Pequeno espaço

            // --- Botão Enviar (Reativo) ---
            Observer(
              // Observa o estado de envio e texto
              builder: (_) {
                // Pode enviar se o texto não estiver vazio E não estiver adicionando
                final bool canSend =
                    _commentController.text.trim().isNotEmpty &&
                        !_commentsStore.isAddingComment;

                return IconButton(
                  iconSize: 24.0, // Tamanho do ícone
                  icon: _commentsStore.isAddingComment
                      // Mostra loading se estiver adicionando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      // Mostra ícone de enviar normal
                      : Icon(
                          Icons.send,
                          color: canSend // Cor depende se pode enviar
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary // Cor primária se puder
                              : Colors.grey, // Cinza se desabilitado
                        ),
                  tooltip: 'Enviar Comentário',
                  // Desabilita o botão se não puder enviar
                  onPressed: canSend ? _sendComment : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- Widget para o Tile de Comentário (Separado para organização) ---
class CommentTile extends StatelessWidget {
  final CommentEntity comment;
  final VoidCallback onMoreOptionsTap; // Função para o botão de opções

  const CommentTile({
    super.key, // Use Key para melhor performance da lista
    required this.comment,
    required this.onMoreOptionsTap,
  });

  @override
  Widget build(BuildContext context) {
    // Pega o store via GetIt (ou receba por parâmetro se preferir)
    final commentsStore = GetIt.I.get<CommentsStore>();
    // Formata a data
    final formattedDate =
        DateFormat('dd/MM/yy HH:mm').format(comment.timestamp.toDate());
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Observer para reagir a mudanças de estado *deste* comentário específico
    return Observer(
      builder: (_) {
        // Verifica se ESTE comentário está sendo editado ou deletado
        final bool isBeingEdited = commentsStore.isUpdatingComment &&
            commentsStore.editingCommentId == comment.id;
        final bool isBeingDeleted = commentsStore.isDeletingComment &&
            commentsStore.deletingCommentId == comment.id;
        final bool isDisabled = isBeingEdited || isBeingDeleted; // Flag geral

        // Define a opacidade para dar feedback visual
        final double opacity = isDisabled ? 0.5 : 1.0;
        // Define a cor de fundo para destacar a ação (opcional)
        final Color? overlayColor = isBeingDeleted
            ? Colors.red.withOpacity(0.1)
            : (isBeingEdited
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : null);

        return IgnorePointer(
          // Impede interações enquanto desabilitado
          ignoring: isDisabled,
          child: Opacity(
            opacity: opacity,
            child: Container(
              color: overlayColor, // Cor de fundo sutil durante a ação
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 12.0), // Padding interno
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Alinha itens no topo
                    children: [
                      // --- Avatar (Opcional) ---
                      // CircleAvatar(
                      //   radius: 18,
                      //   backgroundImage: comment.userAvatarUrl != null
                      //       ? NetworkImage(comment.userAvatarUrl!)
                      //       : null,
                      //   child: comment.userAvatarUrl == null
                      //       ? const Icon(Icons.person, size: 18)
                      //       : null,
                      // ),
                      // const SizedBox(width: 12.0), // Espaço após avatar

                      // --- Nome, Data e Botão de Opções ---
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nome do Usuário
                            Text(
                              comment.userName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            // Data formatada
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                formattedDate,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --- Botão de 3 pontos ou Loading ---
                      SizedBox(
                        height: 24, // Altura fixa para alinhar
                        width: 36, // Largura fixa
                        child: isDisabled
                            // Mostra loading se editando/deletando
                            ? const Center(
                                child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)))
                            // Mostra botão de opções normal
                            : IconButton(
                                padding:
                                    EdgeInsets.zero, // Remove padding interno
                                iconSize: 18, // Tamanho do ícone
                                icon: const Icon(Icons.more_vert),
                                onPressed:
                                    onMoreOptionsTap, // Chama a função passada
                                tooltip: 'Mais opções',
                                splashRadius: 18, // Área de clique
                              ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8.0), // Espaço antes do texto

                  // --- Texto do Comentário ---
                  SelectableText(
                    // Permite copiar o texto
                    comment.text,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
