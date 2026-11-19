# ◎ Orbitrip
**Sua viagem, em outra dimensão.**

Aplicação web de planejamento de viagens, com itinerários, cenários financeiros, mapa interativo, simuladores de custo e importação de planilhas.

## Versão atual — V2

- Identidade visual Orbitrip: dashboard imersivo, capas fotográficas, transições responsivas e menu escuro.
- Múltiplas viagens com criação, edição, duplicação, arquivamento e reativação.
- Roteiro cronológico por dia, horários, categorias, links e localizações.
- **Mapa Leaflet + OpenStreetMap** com marcadores das etapas georreferenciadas, filtros por dia e categoria, popups e linha de sequência dos pontos. A linha não equivale a uma rota rodoviária.
- Orçamento previsto, realizado, distribuição por categoria e cenários independentes ou compartilhados.
- **Calculadora:** carro (combustível, consumo, distância, pedágios, aluguel) / avião (passagens, bagagens, transfers, seguro) / combinado, mais hospedagem, alimentação e margem; transferência confirmada dos resultados para Despesas.
- Lista de compras com preços e status.
- **Importador Excel XLSX/XLS:** leitura local no navegador, prévia das abas, cenários a partir dos três roteiros e captura de itens de compras e despesas na estrutura do arquivo do Rio de Janeiro. Importações precisam ser revisadas, especialmente linhas não estruturadas.
- Backup completo JSON.

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
