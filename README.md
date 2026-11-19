## Supabase ativado — Orbitrip V3.4 (19/11/2026)

O projeto **Orbitrip** foi criado no Supabase Free, na região São Paulo (`sa-east-1`), e sua URL/chave pública `publishable` foram conectadas via `config.js`.

- Banco instalado: `trips`, `trip_members`, `trip_invites`, RLS e RPC para convites/controle de revisões.
- Verificação de segurança do Supabase: **sem alertas**.
- O **login por código ainda não está liberado para uso geral**: precisa da configuração manual de templates OTP e de SMTP para enviar códigos a e-mails que não pertençam à equipe administrativa da organização.
- A opção **Continuar no modo local** preserva o acesso aos roteiros no navegador enquanto a configuração de e-mail é concluída.
- Guia completo: [`docs/V3.4-SUPABASE.md`](docs/V3.4-SUPABASE.md). **Não execute o SQL de instalação uma segunda vez no mesmo projeto.**

# ◎ Orbitrip
**Sua viagem, em outra dimensão.**

Aplicação web de planejamento de viagens, com itinerários, cenários financeiros, mapa interativo, simuladores de custo e importação de planilhas.

## Versão atual — V3.4

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
- **Contas por código de e-mail (OTP):** tela de login com código de seis dígitos, sem senha, com sessão persistente através do Supabase.
- **Viagens compartilhadas:** convite por link ou código de uso único (expira em sete dias), com papéis proprietário/editor/visualizador.
- **Banco na nuvem com RLS:** esquema em [`supabase/schema.sql`](supabase/schema.sql), protegendo leitura e escrita por participante.
- **Sincronização:** carregamento dos roteiros autorizados, assinatura de alterações Realtime e verificação de revisão para evitar perda silenciosa quando dois usuários editam o mesmo roteiro ao mesmo tempo.
- **Migração de dados locais:** transferência opcional dos roteiros anteriores para a nuvem, mantendo os originais; importação JSON em modo nuvem adiciona cópias, sem excluir viagens existentes.
- **Segurança:** nenhuma chave secreta ou conta pessoal foi inserida no repositório.

### Ativação necessária para duas pessoas usarem o mesmo roteiro

**A autenticação e a colaboração ainda não estão ativadas em um Supabase real.** O arquivo [`config.js`](config.js) está propositalmente sem URL e chave pública, pois você ainda não criou/conectou o projeto Supabase.

Enquanto essas informações não forem preenchidas e o SQL não tiver sido executado, a aplicação **continua no modo local**, sem login nem sincronização de viagens. Não existe uma conta compartilhada já criada, e os dados existentes no navegador permanecem intactos.

Siga o guia [**Configurar Supabase para a Orbitrip V3.4**](docs/V3.4-SUPABASE.md) para habilitar todos os recursos. Nunca inserir `service_role` nem outras chaves secretas no JavaScript público.

**Validação:** sintaxe JavaScript e conteúdo publicado no GitHub verificados. Ainda faltam testes de ponta a ponta no navegador e testes reais com duas contas, após ativação do Supabase. Restrições e limites dos serviços externos continuam aplicáveis.

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
