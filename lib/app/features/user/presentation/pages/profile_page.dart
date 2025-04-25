import 'package:desafio_loomi/app/core/routes/app_routes.dart';
import 'package:desafio_loomi/app/core/themes/app_colors.dart';
import 'package:desafio_loomi/app/features/auth/domain/entities/user.dart'; // Import AppUser
import 'package:desafio_loomi/app/features/auth/presentation/store/auth_store.dart'; // Import AuthStore
import 'package:desafio_loomi/app/features/auth/presentation/widgets/custom_text_form_field.dart';
import 'package:desafio_loomi/app/features/auth/presentation/widgets/logo_auth_widget.dart';
import 'package:desafio_loomi/app/features/movies/domain/entities/movie_entity.dart';
import 'package:desafio_loomi/app/features/movies/presentation/store/movie_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart'; // Import flutter_mobx
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart'; // Import GetIt

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthStore _authStore = GetIt.instance<AuthStore>();
  final MovieStore _movieStore = GetIt.instance<MovieStore>();
  late List<ReactionDisposer> _disposers;

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    // Controlador, chave de formulário e estado de visibilidade para o campo de senha
    final TextEditingController passwordController = TextEditingController();
    final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();
    bool obscurePassword = true;
    // Estados para loading e erro dentro do diálogo
    bool isDialogLoading = false;
    String? dialogErrorMessage;

    return showDialog<void>(
      context: context,
      // Descomente se quiser permitir fechar clicando fora (quando não está carregando)
      // barrierDismissible: !isDialogLoading,
      builder: (BuildContext dialogContext) {
        // StatefulBuilder para atualizar o estado interno do diálogo (obscure, loading, error)
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              // Estilo do Dialog
              backgroundColor:
                  AppColors.profileOptionBackground, // Fundo escuro do dialog
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(20.0)), // Cantos arredondados
              // Controlar paddings manualmente para mais precisão
              titlePadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 15.0),
              actionsPadding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),

              // Título customizado igual ao da imagem
              title: Padding(
                padding: const EdgeInsets.only(
                    top: 12.0, left: 8.0, right: 8.0, bottom: 8.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      // Ícone de voltar à esquerda
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left,
                            color: AppColors.white, size: 30),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: isDialogLoading
                            ? null
                            : () => Navigator.of(dialogContext)
                                .pop(), // Fecha o diálogo
                      ),
                    ),
                    const Text(
                      // Texto centralizado
                      'Warning',
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Conteúdo: Textos + Campo de Senha
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    const SizedBox(height: 10),
                    const Text(
                      // Pergunta centralizada e em negrito
                      'Are you sure you want to delete your account?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      // Texto descritivo centralizado
                      'This action is irreversible and all of your data will be permanently deleted. If you\'re having any issues with our app, we\'d love to help you resolve them.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.profileSecondaryText,
                          fontSize: 14,
                          height: 1.4),
                    ),
                    const SizedBox(height: 25), // Mais espaço antes da senha

                    // --- Seção do Formulário de Senha ---
                    const Text(
                      // Instrução centralizada
                      'Please enter your password to confirm:',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 15),
                    Form(
                      key: dialogFormKey,
                      child: CustomTextFormField(
                        // Reutiliza seu widget
                        controller: passwordController,
                        labelText: 'Current Password',
                        obscureText: obscurePassword,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Password is required'
                            : null,
                        showVisibilityToggle: true,
                        onToggleVisibility: () {
                          setDialogState(() {
                            // Atualiza estado do dialog
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),

                    if (dialogErrorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: Text(dialogErrorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13)),
                      ),
                  ],
                ),
              ),

              // Botões de Ação iguais aos da imagem
              actions: <Widget>[
                const SizedBox(width: 10), // Espaço entre botões
                ElevatedButton(
                  // Botão Deletar (Fundo Roxo)
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary, // Fundo roxo
                      foregroundColor: Colors.white, // Texto branco
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8)), // Borda do botão
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  child: isDialogLoading // Indicador de loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text('Delete account'),
                  onPressed: isDialogLoading
                      ? null
                      : () async {
                          // Valida o formulário da senha
                          if (dialogFormKey.currentState!.validate()) {
                            setDialogState(() {
                              isDialogLoading = true;
                              dialogErrorMessage = null;
                            });
                            try {
                              // Chama o store com a senha digitada
                              await _authStore
                                  .deleteUserAccount(passwordController.text);
                              if (mounted)
                                Navigator.of(dialogContext)
                                    .pop(); // Fecha o dialog em caso de sucesso
                            } catch (e) {
                              // Exibe o erro no dialog
                              setDialogState(() {
                                dialogErrorMessage = e
                                    .toString()
                                    .replaceFirst('Exception: ', '');
                                isDialogLoading = false;
                              });
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProfileOptionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color iconColor = AppColors.profileOptionText, // Cor padrão
    Color textColor = AppColors.profileOptionText, // Cor padrão
    Color backgroundColor = AppColors.profileOptionBackground, // Cor de fundo
  }) {
    return Padding(
      // Adiciona um espaçamento vertical entre os botões
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Material(
        // Use Material para InkWell funcionar corretamente com borderRadius
        color: backgroundColor,
        borderRadius:
            BorderRadius.circular(15.0), // Ajuste o raio conforme a imagem
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
              15.0), // Mantém o efeito de toque dentro das bordas
          child: Padding(
            // Padding interno do botão
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24), // Ícone à esquerda
                const SizedBox(width: 15), // Espaço entre ícone e texto
                Expanded(
                  // Faz o texto ocupar o espaço disponível
                  child: Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight
                          .w500, // Ajuste o peso da fonte se necessário
                    ),
                  ),
                ),
                //const SizedBox(width: 10), // Espaço antes do chevron (opcional)
                Icon(Icons.chevron_right,
                    color: iconColor, size: 24), // Chevron à direita
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color:
            AppColors.profileOptionBackground, // Mesma cor de fundo dos botões
        borderRadius: BorderRadius.circular(15.0), // Mesmo arredondamento
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center, // Alinha itens verticalmente
        children: [
          // Ícone à Esquerda
          Container(
              width: 50, // Largura do container do ícone
              height: 50, // Altura do container do ícone
              decoration: BoxDecoration(
                color:
                    AppColors.subscriptionIconBackground, // Cor roxa de fundo
                borderRadius: BorderRadius.circular(
                    10.0), // Cantos arredondados para o container do ícone
              ),
              child: HalfCircleWithLine(size: 30)),
          const SizedBox(width: 15), // Espaço entre ícone e texto

          // Coluna de Texto (Meio)
          Expanded(
            // Faz a coluna ocupar o espaço disponível
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Alinha textos à esquerda
              mainAxisAlignment: MainAxisAlignment
                  .center, // Centraliza verticalmente na coluna
              children: const [
                Text(
                  'STREAM Premium', // Texto Principal
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4), // Espaço entre os textos
                Text(
                  'Jan 22, 2023', // Texto Secundário (Data)
                  style: TextStyle(
                    color: AppColors.profileSecondaryText, // Cor cinza
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15), // Espaço entre texto e tag

          // Tag "Coming Soon" (Direita)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.tagBackground, // Cor de fundo da tag
              borderRadius: BorderRadius.circular(
                  20.0), // Cantos bem arredondados (pill shape)
            ),
            child: const Text(
              'Coming soon',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryMovieCard(Movie movie) {
    // Determina a URL a ser usada (fallback se necessário)
    // Usar 'small' ou 'thumbnail' é geralmente bom para listas
    final imageUrl = movie.poster?.smallUrl ??
        movie.poster?.thumbnailUrl ??
        movie.poster?.url;
    // O ano não está no modelo, vamos exibir apenas o nome por enquanto
    // Se você adicionar 'year' ao MovieModel, pode usá-lo aqui.
    final String movieTitle = movie.name;
    // final String movieInfo = '${movie.name} • ${movie.year ?? 'N/A'}'; // Se tivesse o ano

    return Container(
      width: 110, // Largura do card (ajuste conforme necessário)
      margin: const EdgeInsets.only(right: 12.0), // Espaço entre os cards
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Stack(
          fit: StackFit.expand, // Faz o Stack preencher o Container
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover, // Cobre todo o espaço do card
                // Placeholder enquanto carrega
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    // Container cinza como placeholder
                    color: Colors.grey[800],
                    child: Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white54))),
                  );
                },
                // Tratamento de erro se a imagem falhar
                errorBuilder: (context, error, stackTrace) {
                  print("Erro ao carregar imagem: $imageUrl - $error");
                  return Container(
                    // Placeholder em caso de erro
                    color: Colors.grey[800],
                    child: const Center(
                        child:
                            Icon(Icons.error_outline, color: Colors.white54)),
                  );
                },
              )
            else
              // Placeholder se não houver URL de imagem
              Container(
                color: Colors.grey[800],
                child: const Center(
                    child: Icon(Icons.movie_creation_outlined,
                        color: Colors.white54)),
              ),

            // Gradiente escuro na parte inferior para legibilidade do texto
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 50, // Altura do gradiente
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8), // Mais escuro na base
                      Colors.black.withOpacity(0.0), // Transparente no topo
                    ],
                  ),
                ),
              ),
            ),

            // Texto sobreposto (Nome do Filme)
            Positioned(
              bottom: 8, // Posição do texto a partir da base
              left: 8,
              right: 8,
              child: Text(
                movieTitle, // Usa a variável definida acima
                maxLines: 2, // Limita a duas linhas
                overflow: TextOverflow
                    .ellipsis, // Adiciona "..." se o texto for muito longo
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600, // Um pouco mais forte
                    shadows: [
                      // Sombra leve para destacar mais
                      Shadow(blurRadius: 2.0, color: Colors.black54)
                    ]),
              ),
            ),

            // InkWell para tornar o card clicável (opcional)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  print('Clicou no filme: ${movie.name} (ID: ${movie.id})');
                  // TODO: Navegar para detalhes do filme, passando movie.id ou o objeto movie
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    if (_movieStore.movies.isEmpty && !_movieStore.isLoadingMovies) {
      print("ProfilePage initState: Fetching movies...");
      _movieStore.fetchMovies();
    }

    _disposers = [
      reaction((_) => _authStore.isLoggedIn, (bool loggedIn) {
        if (!loggedIn && mounted) {
          print("ProfilePage Reaction: User logged out. Navigating to login.");
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.login, (route) => false);
        }
      })
    ];
  }

  @override
  void dispose() {
    for (var d in _disposers) {
      d();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Observer(
          builder: (_) {
            final AppUser currentUser = _authStore.user;
            final bool isLoggedIn = _authStore.isLoggedIn;

            if (!isLoggedIn) {
              return const Center(child: Text('Nenhum usuário logado.'));
            }
            final bool isLoadingMovies = _movieStore.isLoadingMovies;
            final String? movieError = _movieStore.errorMessage;
            final List<Movie> movies = _movieStore.movies;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.06),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: AppColors.buttonText,
                        size: 30, // Aumentar um pouco o ícone
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.home);
                      },
                    ),
                    Flexible(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor:
                              AppColors.buttonPrimary, // Cor do texto e ícones
                          elevation: 0,
                          shape:
                              const StadiumBorder(), // Bordas arredondadas (formato de pílula)
                          side: const BorderSide(
                            color: AppColors
                                .buttonPrimary, // Cor da borda (mesma do texto)
                            width: 1.0, // Espessura da borda
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.editProfile);
                        },
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 14, // Tamanho da fonte
                            fontWeight: FontWeight.bold,
                            color: AppColors
                                .buttonPrimary, // Garante que a cor do texto seja a primária
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: (currentUser.photoUrl != null &&
                              currentUser.photoUrl!.isNotEmpty)
                          ? NetworkImage(currentUser.photoUrl!)
                          : null,
                      // Se não houver imagem, mostra um ícone
                      child: (currentUser.photoUrl == null ||
                              currentUser.photoUrl!.isEmpty)
                          ? Icon(Icons.person,
                              size: 40, color: Colors.grey.shade600)
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hello,',
                          style:
                              TextStyle(fontSize: 14, color: AppColors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentUser.name.toString(),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors
                                  .white // Ajuste a cor conforme seu tema
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                _buildProfileOptionButton(
                  icon: Icons
                      .shield_outlined, // Ícone de escudo (parece com o da imagem)
                  text: 'Change Password',
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.changePassword,
                      (route) => false,
                    );
                  },
                ),
                _buildProfileOptionButton(
                  icon: Icons.delete_outline,
                  text: 'Delete my account',
                  // Chama o diálogo de confirmação
                  onTap: () => _showDeleteConfirmationDialog(context),
                  iconColor: Colors.red,
                  textColor: Colors.red,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                Text(
                  'Subscriptions',
                  style: TextStyle(fontSize: 18, color: AppColors.white),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                _buildSubscriptionCard(),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Text(
                    'History',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                SizedBox(
                  height: 160, // Altura dos cards do histórico (ajuste)
                  child: Builder(
                    // Usa Builder para acesso ao estado mais recente
                    builder: (context) {
                      if (isLoadingMovies && movies.isEmpty) {
                        // Mostra loading apenas se estiver carregando e não tiver filmes ainda
                        return const Center(child: CircularProgressIndicator());
                      } else if (movieError != null) {
                        // Mostra erro se houver
                        return Center(
                            child: Text(
                                'Erro ao carregar histórico: $movieError',
                                style: const TextStyle(color: Colors.red)));
                      } else if (movies.isEmpty && !isLoadingMovies) {
                        // Mostra mensagem se não houver filmes e não estiver carregando
                        return const Center(
                            child: Text('Nenhum filme no histórico.',
                                style: TextStyle(color: Colors.grey)));
                      } else {
                        // Mostra a lista de filmes
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          // Adiciona padding à direita da lista para não cortar o último item abruptamente
                          padding: const EdgeInsets.only(right: 16.0),
                          itemCount: movies.length,
                          itemBuilder: (context, index) {
                            final movie = movies[index];
                            return _buildHistoryMovieCard(movie);
                          },
                        );
                      }
                    },
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          shape: const StadiumBorder(),
                          side: BorderSide(
                            color: Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        onPressed: () async {
                          try {
                            await _authStore.signOut();

                            if (mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.login,
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error ${e.toString()}')),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
