## Atualização de sincronização silenciosa — 21/11/2026

- Removido o banner de erro ou aviso de sincronização do topo das telas **Início** e **Viagem**. Os controles de diagnóstico/backup foram movidos para **Conta e compartilhamento → Dados pendentes neste dispositivo**, exibidos apenas quando necessário.
- Ao autenticar, caso exista rascunho de alterações não enviadas, a ORBITRIP tenta **reconciliar automaticamente** com a nuvem sem substituir informações existentes. Em coleções de etapas, despesas, compras e cenários, as adições são conciliadas por ID; edições ou exclusões concorrentes não são mescladas automaticamente.
- Se houver conflito que não possa ser unido com segurança, o app tenta criar **uma cópia recuperada** com novo identificador e sufixo "(recuperada)", mantendo o original intacto. O identificador da cópia é persistido para evitar duplicações por novas tentativas.
- Se a sincronização continuar indisponível, o rascunho permanece no armazenamento local e as opções de exportação/recuperação ficam disponíveis na área Conta. **Não declarar que os dados foram sincronizados até a gravação ser confirmada no Supabase.**
- Não houve desativação da RLS, mudança de permissões, remoção de dados ou atualização de schema.
- Testes simulados: recuperação aditiva de etapas, criação de cópia em conflito de metadados, preservação de exclusões, manutenção do rascunho e ausência do banner de topo.
- Validação com o rascunho real no iPhone ainda necessária: no Supabase, a viagem Rio de Janeiro (Visa) estava na revisão 2, sem eventos gravados, no momento da verificação.

**Antes de atualizar ou reiniciar a PWA caso apareça aviso de pendência:** toque em **Exportar rascunho** e salve o arquivo no app Arquivos do iPhone. Depois feche e reabra a ORBITRIP para carregar a versão atualizada. Se for preciso recuperar manualmente, acesse **Conta e compartilhamento**.

## Correção de conflitos de sincronização — V3.5.x (19/11/2026)

**Situação observada:** a viagem "Rio de Janeiro (Visa)" estava na revisão 2 do Supabase com zero etapas. O navegador mostrava três etapas não sincronizadas e repetia `CONFLICT_OR_DENIED` ao salvar usando uma revisão anterior. Atualizar código no GitHub **não** modifica revisões das viagens nem deveria, por si só, provocar esse erro.

**Correções no frontend:**

- O cliente pode consultar a revisão e o conteúdo mais recentes de uma viagem autorizada com `OrbitripCloud.getTrip(id)`. As permissões RLS permanecem.
- Quando o servidor reporta revisão desatualizada, o app tenta uma mesclagem de três versões: última sincronizada (base), alterações locais e versão atual da nuvem. Apenas alterações independentes são mescladas; alterações simultâneas conflitantes no mesmo campo ou exclusão versus edição exigem recuperação manual.
- Caso a mesclagem seja segura, salva novamente respeitando a revisão atual do servidor e conserva as novas etapas.
- Existe a ação **Recuperar rascunho como cópia** no aviso de sincronização pendente. Ela lê o rascunho já salvo no navegador, obtém as viagens autorizadas atuais da nuvem e cria cópias das viagens diferentes, sem sobrescrever o conteúdo original. Copiadas aparecem com o sufixo "(recuperada)".
- O rascunho deve ser exportado antes de atualizar a aplicação, clicar em Recarregar nuvem ou sair da conta. **Recarregar nuvem** descarta alterações locais e requer confirmação.
- Adicionada versão de cache no `cloud.js` para Safari/iPhone receber o módulo novo junto com o aplicativo.
- Não foram executadas migrações adicionais; a proteção por revisão e as regras de acesso permanecem.
- **Verificação:** testes simulados de rebase não conflitante, conflito real, exclusão versus edição, gravação na revisão atual e recuperação sem sobregravar o servidor passaram. Falta conferir a recuperação das três etapas reais no iPhone.

**Recuperação no iPhone:** salvar um backup com **Exportar rascunho**; atualizar a ORBITRIP no Safari ou reabrir o PWA; caso o aviso indique rascunho encontrado, usar **Recuperar rascunho como cópia**; verificar os dados antes de excluir/arquivar qualquer viagem original.

## Deslocamentos com rota — atualização de 19/11/2026

Ao criar ou editar uma etapa do roteiro e escolher a categoria **Deslocamento**, a ORBITRIP apresenta um cadastro de rota, preservando as etapas antigas:

- **Origem e destino:** nome de local, endereço ou coordenadas. São necessários para criar uma rota completa.
- **Paradas intermediárias:** até três, uma por linha, mantidas na ordem informada (limite compatível com links Google Maps em navegador móvel).
- **Transporte:** carro, caminhada, transporte público ou bicicleta.
- **Prévia:** dois links gerados automaticamente no formulário para conferir a rota antes de salvar.
- **Roteiro salvo:** mostra origem → destino, possíveis paradas e links **Mapas da Apple** e **Google Maps** na etapa. O atalho **Próxima parada** também utiliza o destino cadastrado.
- **Integração:** Google Maps URLs (`api=1`, `origin`, `destination`, `travelmode`, `waypoints`) e URL unificada do Apple Maps (`/directions?source=...&destination=...&waypoint=...&mode=...`), suportada no iOS 18.4+. Nenhuma chave paga/API de rotas é necessária.
- **Dados:** origem, destino, modo e paradas são propriedades adicionais do JSON da etapa, compatíveis com o banco existente. O campo de endereço/localização da etapa permanece para uso de marcadores no mapa interno.
- **Limites:** a ORBITRIP não calcula, desenha nem valida trajetos rodoviários; o serviço externo realiza a geocodificação e o cálculo da rota ao abrir o link. A disponibilidade de rotas ou paradas varia por serviço e transporte.
- **Verificações:** JavaScript compila; links gerados para os dois mapas, codificação de caracteres, paradas, bicicleta, compatibilidade com links de destino antigos e alternância de campos por categoria foram testados em ambiente simulado. Abertura em aplicativos físicos no iPhone ainda não foi verificada.

**Referências oficiais:** [Google Maps URLs](https://developers.google.com/maps/documentation/urls/get-started) · [Apple Maps — Unified URLs](https://developer.apple.com/documentation/mapkit/unified-map-urls).

## Correção da sincronização RLS — 19/11/2026

- **Sintoma:** ao criar uma viagem com uma conta autenticada, PostgREST retornava erro 42501 (`new row violates row-level security policy for table "trips"`) no `INSERT ... RETURNING revision`.
- **Diagnóstico:** a política `trips_select` dependia exclusivamente de um helper de leitura que consultava a própria tabela. Na operação com `RETURNING`, isso impedia a visualização imediata da linha recém-inserida.
- **Correção aplicada no banco existente:** `ALTER POLICY trips_select ON public.trips USING (owner_id = (select auth.uid()) OR orbitrip_private.can_view(id));`. Não foi necessário desabilitar RLS.
- **Esquema de referência:** `supabase/schema.sql` atualizado para replicar a política correta em projetos novos. **Não executar o arquivo inteiro no projeto existente**.
- **Verificação:** `INSERT ... RETURNING` autenticado passou em transação revertida; leitura simulada com identidade não proprietária retornou zero linhas; os dados de produção não foram alterados. Resta testar o botão **Tentar novamente** na ORBITRIP com o rascunho real.
- **Proteção de dados:** enquanto houver erro de sincronização, exportar rascunho antes de qualquer tentativa de recarga de nuvem. Não usar **Recarregar nuvem** se houver alterações não sincronizadas.

## V3.5.1 — Otimização para iPhone 16 Pro Max (19/11/2026)

**Dispositivo de referência:** iPhone 16 Pro Max, viewport de 440 × 956 pixels CSS em retrato. O design utiliza áreas seguras dinâmicas do iOS, não valores fixos.

- **Capa mobile-first:** tela inicial antes do login, marca ORBITRIP na tipografia original, sem ícone no cabeçalho, sem frase superior e sem rodapé textual; textos principais e ações preservados.
- **Dynamic Island e barra de início:** viewport-fit=cover e CSS env(safe-area-inset-*) no topo, laterais e base, inclusive na capa e no menu inferior.
- **Barra de navegação:** cinco áreas de toque otimizadas; oculta durante autenticação e ao usar campos de formulário para reduzir interferência com o teclado.
- **Formulários e diálogos:** entradas com 16 px no celular para evitar zoom involuntário no Safari, áreas de toque de pelo menos 44 px e modais em formato de folha inferior com rolagem e espaço protegido.
- **PWA:** metadados para instalação pela Tela de Início do iPhone, preservando o manifesto e o ícone oficial da aplicação.
- **Preservação:** login OTP (6–10 dígitos), Supabase, modo local, viagens, mapas, despesas e compartilhamento permanecem implementados.
- **Validação:** sintaxe JavaScript e 11 verificações automáticas/simuladas dos fluxos de abertura, login, sessão existente e modo local aprovadas. A conferência visual e tátil em iPhone físico permanece pendente.
- **Observação:** modo local usa dados deste navegador; não equivale a garantia de uso offline completo da PWA.

**Instalação no iPhone:** abrir a URL da Orbitrip no Safari → Compartilhar → Adicionar à Tela de Início. Depois, iniciar pelo ícone na Tela de Início.

## V3.5 — Capa de abertura (19/11/2026)

- **Tela de boas-vindas antes do login:** a capa aparece sempre que a aplicação carrega; o usuário não é encaminhado automaticamente para a tela de autenticação.
- **Identidade visual:** cabeçalho apenas com o nome ORBITRIP na fonte Outfit original, composição editorial minimalista em branco, cinza e preto, paisagem monocromática suave, órbitas decorativas e transições sutis.
- **Texto aprovado:** "Toda grande viagem começa com um bom planejamento." e "Planeje roteiros, organize gastos e acompanhe cada etapa da sua viagem."
- **Começar:** abre o acesso à conta Supabase. Se já existir uma sessão válida, entra diretamente no painel sem solicitar novo código.
- **Continuar no modo local:** abre as viagens armazenadas no navegador sem exigir autenticação e sem misturar os dados locais com os dados da nuvem.
- **Voltar à capa:** disponível na tela de login. A opção "Começar" reativa o fluxo da conta mesmo se antes foi escolhido o modo local.
- **Responsividade:** composição adaptada a computador e celular; respeita a preferência de reduzir animações do sistema.
- **Preservação:** o código V3.4 de login, compartilhamento, mapas, despesas e backup não foi removido; o novo fluxo só altera a entrada na aplicação.
- **Validação técnica:** sintaxe JavaScript conferida e cenários de abertura, acesso, retorno à capa, modo local e sessão Supabase ativa testados com ambiente simulado. Testes visuais manuais nos dispositivos ainda recomendados.

## Supabase ativado — Orbitrip V3.4 (19/11/2026)

O projeto **Orbitrip** foi criado no Supabase Free, na região São Paulo (`sa-east-1`), e sua URL/chave pública `publishable` foram conectadas via `config.js`.

- Banco instalado: `trips`, `trip_members`, `trip_invites`, RLS e RPC para convites/controle de revisões.
- Verificação de segurança do Supabase: **sem alertas**.
- **Login por código operacional:** SMTP da Brevo e templates OTP foram configurados e o primeiro acesso real foi confirmado; o teste de colaboração entre duas contas ainda está pendente.
- A opção **Continuar no modo local** permite manter viagens no navegador, sem sincronização com a nuvem.
- Guia completo: [`docs/V3.4-SUPABASE.md`](docs/V3.4-SUPABASE.md). **Não execute o SQL de instalação uma segunda vez no mesmo projeto.**

# ◎ Orbitrip
**Sua viagem, em outra dimensão.**

Aplicação web de planejamento de viagens, com itinerários, cenários financeiros, mapa interativo, simuladores de custo e importação de planilhas.

## Versão atual — V3.5.1

- Identidade visual Orbitrip: dashboard imersivo, capas fotográficas, transições responsivas e menu escuro.
- Múltiplas viagens com criação, edição, duplicação, arquivamento e reativação.
- Roteiro cronológico por dia, horários, categorias, links e localizações.
- **Mapa Leaflet + OpenStreetMap** com marcadores das etapas georreferenciadas, filtros por dia e categoria, popups e linha de sequência dos pontos. A linha não equivale a uma rota rodoviária.
- Orçamento previsto, realizado, distribuição por categoria e cenários independentes ou compartilhados.
- **Calculadora:** carro (combustível, consumo, distância, pedágios, aluguel) / avião (passagens, bagagens, transfers, seguro) / combinado, mais hospedagem, alimentação e margem; transferência confirmada dos resultados para Despesas.
- Lista de compras com preços e status.
- **Importador Excel XLSX/XLS:** leitura local no navegador, prévia das abas, cenários a partir dos três roteiros e captura de itens de compras e despesas na estrutura do arquivo do Rio de Janeiro. Importações precisam ser revisadas, especialmente linhas não estruturadas.
- Backup completo JSON.


## V3.4 — Mapa, ícone e colaboração (19/11/2026)

### Disponível no código

- **Apple Maps e Google Maps:** botões nas atividades que abrem direções para o destino pelo link oficial, sem precisar contratar as APIs de mapas.
- **Próxima parada:** atalho para a próxima atividade futura com endereço ou coordenadas.
- **Mapa interno mantido:** Leaflet + OpenStreetMap, marcadores categorizados e Photon para pesquisa.
- **Ícone oficial aprovado:** arquivos em `assets/`, favicon, `apple-touch-icon` (180×180) e manifesto web com ícones 192×192 PNG e 512×512 WebP.
- **Contas por código de e-mail (OTP):** tela de login com código numérico de 6–10 dígitos, sem senha, com sessão persistente através do Supabase.
- **Viagens compartilhadas:** convite por link ou código de uso único (expira em sete dias), com papéis proprietário/editor/visualizador.
- **Banco na nuvem com RLS:** esquema em [`supabase/schema.sql`](supabase/schema.sql), protegendo leitura e escrita por participante.
- **Sincronização:** carregamento dos roteiros autorizados, assinatura de alterações Realtime e verificação de revisão para evitar perda silenciosa quando dois usuários editam o mesmo roteiro ao mesmo tempo.
- **Migração de dados locais:** transferência opcional dos roteiros anteriores para a nuvem, mantendo os originais; importação JSON em modo nuvem adiciona cópias, sem excluir viagens existentes.
- **Segurança:** nenhuma chave secreta ou conta pessoal foi inserida no repositório.

### Compartilhamento: próximo teste

A autenticação por e-mail e o Supabase já estão configurados. O código de compartilhamento está disponível, mas a edição simultânea **ainda não foi validada com duas contas reais**.

Guia de manutenção: [**Configurar Supabase para a Orbitrip V3.4**](docs/V3.4-SUPABASE.md). **Não execute novamente o SQL de instalação no projeto existente e nunca publique chaves secretas no JavaScript.**

## Ajustes visuais e de usabilidade (após V3.2)

- **Capa:** cartão da viagem e prévia do editor usam a mesma proporção `1000:563`; a imagem de capa é apresentada integralmente, evitando o recorte extra por `background-size: cover`. Imagens antigas já salvas em 16:9 também seguem esta configuração.
- **Home:** mantido o card de apresentação da viagem; logotipo e botão de criação `+` alinhados verticalmente.
- **Cabeçalho da viagem:** retirada a linha “Minhas viagens / Planejamento”; mantido “Orbitrip / Sua viagem”.
- **Resumo:** quatro indicadores menores, em duas colunas no celular, sem textos explicativos secundários.
- **Busca de endereços:** sugestões com ícone, nome principal e endereço abaixo, linhas tocáveis, realce ao passar o cursor e seleção com setas/Enter ou toque; Escape fecha a lista. Resultados continuam dependendo da disponibilidade de Photon/OpenStreetMap.

Código JavaScript validado sintaticamente; testes completos no navegador e a disponibilidade da API pública ainda não estão certificados.

## V3.2 — Home, capas e visual monocromático

- Home reduzida aos cards das viagens, marca Orbitrip e botão discreto **+**. O título explicativo, os quatro indicadores e o banner promocional foram removidos.
- Fotos de capa independentes por viagem: carregamento de JPEG/PNG/WebP de até 12 MB, corte 16:9 com zoom e reposicionamento, compressão JPEG e remoção de capa. A edição pode ser aberta no card da viagem e em Informações.
- Paleta predominantemente branco, cinza e preto. Indicadores de categorias no roteiro e no mapa continuam com suas cores funcionais (verde, vermelho, azul, amarelo e complementares).
- Photon: removido `lang=pt` da URL que gerava erro HTTP 400 na instância pública. Sugestões aparecem após três caracteres e atraso de 850 ms, seleção preenche endereço e coordenadas. Exibição de erro de rede/limite de consultas; a interface permanece em português.
- Latitude e longitude não exibem campos técnicos visíveis no formulário; seus valores continuam gravados nos dados da etapa.
- O conteúdo da capa fica no mesmo armazenamento local usado pelos roteiros e está incluído nos backups JSON. O navegador tem cota de armazenamento; a aplicação informa quando o salvamento falha.

**Testes:** sintaxe JavaScript verificada; integração completa em navegador e disponibilidade do servidor público Photon não foram testadas de ponta a ponta.

## V3.1 — Interface minimalista

O estilo de passaporte da V3 foi substituído por uma linguagem **moderna, minimalista e mobile-first**. A V3.1 utiliza fundo branco/cinza-claro, tipografia sem serifa, um único acento turquesa, fotografias de viagem em áreas pontuais, superfícies discretas e navegação inferior flutuante em celulares.

A mudança foi **visual**, com preservação da estrutura de dados `viagens_v1` e das funcionalidades da V3: itinerários, mapas, categorias, calculadoras, importação Excel e busca de locais por Photon. As categorias continuam com as cores definidas anteriormente (hospedagem verde, deslocamento vermelho, atrações azul, restaurante amarelo e demais categorias com cores complementares).

A sintaxe JavaScript foi verificada antes do envio, mas **não houve execução de testes automatizados ponta a ponta** nem confirmação de publicação em domínio externo. A aplicação depende de recursos externos para mapas, fotos e importação Excel; os dados continuam apenas no armazenamento local do navegador.

## V3 — Histórico do design (19/11/2026)

A interface foi redesenhada para uso prioritário no celular, inspirada em páginas de passaporte e diário de viagem, sem reproduzir documentos oficiais: textura visível de papel, azul de capa, selos, tipografia sóbria, navegação inferior com cinco atalhos e transições discretas.

**Novidades:**
- Navegação inferior mobile: Início, Roteiro, Mapa, Gastos e Mais. As demais abas permanecem acessíveis no detalhe de cada viagem.
- Categorias de atividades com cores consistentes no roteiro e nos marcadores do mapa: hospedagem verde, deslocamento vermelho, atração azul, restaurante amarelo, voo roxo, passeio turquesa, compromisso laranja e outros cinza.
- Endereços: consulta do serviço público [Photon](https://github.com/komoot/photon) com dados do OpenStreetMap, iniciada após digitar ao menos três caracteres, com pequena espera entre digitação e solicitações. Escolher uma sugestão grava endereço e latitude/longitude na atividade; os marcadores aparecem na aba Mapa.
- Calendário de viagem: selecionar a data inicial limita a data de término ao mesmo dia ou a datas posteriores; ao alterar o início, a data final incompatível é limpa. O navegador tenta abrir automaticamente o calendário final quando permitido.

**Limites técnicos:**
- A instância pública Photon é um serviço demonstrativo, sujeita a restrição de uso e indisponibilidade. Para uso intenso ou comercial, provisionar instância própria ou outro provedor de geocodificação.
- As consultas de localização são enviadas ao provedor externo **enquanto você digita** no campo de endereço. Não use nomes confidenciais nesse campo.
- Mesmo após selecionar um resultado, valide a localização no mapa antes da viagem.
- Os dados permanecem no armazenamento local do navegador. A V3 não implementa login, banco remoto ou sincronização.
- Fotos, bibliotecas de mapas e parser Excel requerem conectividade.
- Código inspecionado e sintaxe JavaScript validada, mas sem suíte de testes ponta a ponta; recomenda-se conferir os fluxos em um navegador antes de depender da aplicação durante uma viagem.

## Execução

Abra `index.html` em um navegador moderno. Não há build nem instalação de dependências.

**Para disponibilizar como site:** configurar GitHub Pages ou serviço de hospedagem equivalente para publicar a branch `main` e a raiz `/`. A publicação não é automática enquanto essa configuração não for feita.

O carregamento de fotografias, mapa Leaflet e parser XLSX usa recursos de CDN; essas funções exigem conexão com a internet. Os dados pessoais registrados não são enviados a esses CDNs pelo código do aplicativo, mas o navegador solicita recursos externos, incluindo tiles do mapa.

## Persistência — atenção

A V2 **ainda usa localStorage** do navegador. Sem banco de dados e autenticação, viagens não são sincronizadas entre aparelhos, e limpar o armazenamento local pode causar perda de registros. Exporte cópias periódicas em **Dados e backup**. Não armazene dados confidenciais nesse ambiente sem autenticação.

O repositório contém apenas o código da aplicação, não os dados que você cria no navegador.

## Importação do arquivo de referência

Estrutura tratada:
- Roteiro Barato → cenário Econômico
- Roteiro Intermediário → cenário Intermediário
- Roteiro Caro → cenário Conforto
- Lista de Compras e Vilefort Lista de Compras → itens de compras
- Despesas → despesas estimadas

O importador lê as células do Excel em posições compatíveis com o arquivo de referência e **não garante conversão perfeita** de linhas com mesclagens, fórmulas ou anotações livres. Exibe contagem e solicita confirmação antes de criar a viagem.

## Limitações conhecidas

- Roteiros com somente endereço textual não recebem marcador até receber coordenadas decimais `latitude, longitude` ou DMS.
- Linhas de mapa ligam pontos em sequência, sem serviço de rotas viárias.
- O cálculo usa preços inseridos pelo usuário, sem cotações em tempo real.
- Imagens são decorativas e genéricas por enquanto; não representam necessariamente o destino do card.
- Falta autenticação/sincronização Supabase, upload de imagens privadas, importação universal de formatos Excel e exportação PDF.
- Aplicação entregue como código, sem publicação ou testes E2E automatizados ainda.

## Roadmap

1. Publicação permanente e hospedagem HTTPS.
2. Autenticação, banco Supabase e políticas RLS.
3. Geocodificação com consentimento e roteamento de estradas com serviços compatíveis.
4. Importador com mapeamento de colunas para planilhas arbitrárias.
5. Capas por destino, câmbio e exportação PDF.

Especificação detalhada: [Blueprint V2](docs/ORBITRIP-V2-BLUEPRINT.md).
