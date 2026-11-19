# ORBITRIP — Blueprint funcional e visual V2
**Status:** especificação de produto aprovada quanto a nome e formato de entrega; implementação pendente.  
**Repositório-alvo:** `cesarsbatista/viagens`  
**Base:** V1 do projeto e planilha de referência `2027_01 - Rio de Janeiro.xlsx`.

## 1. Identidade de marca
- **Nome:** Orbitrip
- **Assinatura proposta:** *Sua viagem, em outra dimensão.*
- **Posicionamento:** um espaço de planejamento visual e financeiro de viagens para carro, avião e roteiros multimodais.
- **Símbolo:** órbita circular interrompida por um pequeno marcador de localização; deve funcionar como favicon/app icon.
- **Tipografia:** Sora (títulos) e Inter (corpo); alternativas sans-serif de sistema para funcionamento offline.
- **Cores:** fundo noite `#0B1221`, azul oceano `#163B60`, azul elétrico `#4B89FF`, turquesa `#35D0C1`, areia `#F6F2E9`, coral `#FF8066`, branco `#FFFFFF`.
- **Modo:** claro prioritário com hero e navegação escuros; futura opção escura.
- **Imagem:** fotografias de destinos em proporção 16:9 nas capas; imagens carregadas com lazy loading e fallback em gradiente caso falhem.
- **Movimento:** entrada 160–280ms, realce dos cards 120–180ms, carregamentos com skeleton, suporte a `prefers-reduced-motion`.

## 2. Shell/navegação
**Desktop:** lateral 248px recolhível; barra superior com busca global, seletor de viagem, indicador de moeda e ações rápidas; conteúdo máximo 1440px.  
**Mobile:** cabeçalho compacto; navegação inferior para Início, Roteiro, Mapa, Orçamento e Mais; formulários em drawer/modal fullscreen.  
**Menu principal:** Visão geral, Minhas viagens, Roteiro, Mapa, Orçamento, Calculadora, Compras, Importar, Arquivo e Configurações.  
**Contexto:** módulos de roteiro, mapa, orçamento e compras exigem seleção de uma viagem e um cenário ativo.  
**Estados comuns:** carregando, vazio, erro, salvo, sem rede; avisar antes de excluir ou substituir um conjunto de dados.

## 3. Tela 01 — Boas-vindas e dashboard geral
**Hero:** imagem de viagem com gradiente, nome Orbitrip, subtítulo “Seu próximo destino começa aqui”, CTA “Nova viagem”.  
**Indicadores:** viagens em preparação, próximas partidas, viagens arquivadas, orçamento combinado das viagens ativas (apenas quando mesma moeda; senão por moeda).  
**Cards de viagens:** foto, destinos, período, status, dias até a partida, resumo de custo, ação “Abrir”.  
**Interações:** criar, duplicar, pesquisar, filtrar por status e ano, ordenar pela data.  
**Estado vazio:** card de criação orientada.

## 4. Tela 02 — Nova viagem / detalhes
**Etapas do assistente:** (1) nome e destinos; (2) datas, origem e viajantes; (3) modal: carro / avião / misto / outros; (4) moeda principal; (5) imagem de capa; (6) criar cenário principal.  
**Detalhes:** editar dados, notas, participantes, capa, duplicar ou arquivar.  
**Regras:** datas inválidas bloqueiam salvamento; destino não obriga geocodificação imediata; arquivamento não exclui dados.  
**Persistência:** cada viagem possui ID, status, datas, moeda, cenário(s) e conjuntos relacionados.

## 5. Tela 03 — Visão geral da viagem
**Cabeçalho imersivo:** capa, título, destinos, duração e contagem regressiva.  
**KPIs:** orçamento previsto, gasto realizado, saldo planejado, atrações, quilômetros estimados (se calculados).  
**Linha do tempo:** próximos três compromissos e ação “Ver roteiro completo”.  
**Mini-mapa:** recorte de marcadores cadastrados; sem pontos, mostra explicação e botão “Adicionar localização”.  
**Ações:** nova etapa, nova despesa, abrir calculadora, exportar resumo.

## 6. Tela 04 — Roteiro (timeline)
**Layout desktop:** coluna esquerda por dia/data; corpo central com blocos por horário; painel direito com resumo do dia, custos e mapa pequeno.  
**Mobile:** dias em scroll horizontal e cards em lista.  
**Campos do compromisso:** título; tipo (voo, carro, trem, ônibus, hospedagem, alimentação, atração, passeio, compra, outro); data; início/fim; endereço; lat/lon opcionais; URL; custo informativo; observações; cenário (“todos” ou específico).  
**Interações:** criar, editar, duplicar, excluir, reordenar por hora, filtrar por dia/tipo, abrir ponto no mapa.  
**Regra financeira:** custo informativo de etapa NÃO compõe orçamento enquanto não houver lançamento em Despesas; evitar duplicidade.

## 7. Tela 05 — Mapa interativo
**Mapa:** Leaflet + OpenStreetMap, com atribuição visível e política de uso dos tiles respeitada.  
**Camadas lógicas:** pontos de interesse, hospedagem, alimentação, aeroportos, origem e deslocamentos.  
**Elementos:** marcadores coloridos por categoria; popup com nome, dia, horário, endereço, link e ação “Ir para etapa”; lista lateral cronológica; filtro dia / categoria / cenário; botão “Enquadrar roteiro”.  
**Localização:** usar coordenadas informadas ou geocodificar endereço mediante acionamento explícito; pontos ambíguos precisam de confirmação.  
**Rota:** linha ligando pontos em ordem cronológica é **visualização de sequência**, não cálculo viário; quando houver provedor de roteamento, traçar trajeto real e exibir distância e duração como estimativas com fonte.  
**Ausência de rede:** apresentar estado de indisponibilidade dos mapas sem perder o roteiro.  
**Privacidade:** não solicitar localização atual do usuário por padrão.

## 8. Tela 06 — Orçamento
**Painel:** previsto, realizado, diferença, gasto por pessoa, distribuição por categoria, progresso por limite de gastos.  
**Tabela:** descrição, categoria, data, cenário, previsto, realizado, moeda e observação; ações CRUD.  
**Cenários:** econômico, intermediário, conforto ou personalizado; despesas compartilhadas e exclusivas; comparativo sem contagem dupla.  
**Multimoeda:** armazenar moeda original e taxa de câmbio registrada no lançamento; não somar moedas distintas sem conversão explícita.  
**Gráficos:** barras por categoria e comparação previsto/realizado; textos numéricos acessíveis.  
**Exportação:** CSV primeiro; PDF em etapa posterior.

## 9. Tela 07 — Calculadora de custos
**Seletor:** terrestre / aéreo / combinado.  
**Carro:** quilômetros de ida, quilômetros de volta (ou toggle “ida e volta”), km/L, preço/L, pedágios, estacionamentos, diária de aluguel, dias de aluguel, hospedagem por noite, número de noites, alimentação por pessoa/dia, pessoas, dias, margem extra %.  
**Fórmulas:** combustível = (km totais ÷ km/L) × preço/L; aluguel = diária × dias; hospedagem = diária × noites; alimentação = gasto por pessoa/dia × pessoas × dias; total = soma das parcelas + extras + margem; por pessoa = total ÷ pessoas. Validar km/L>0 e pessoas>0.  
**Avião:** passagens por pessoa, passageiros, bagagem, transfer, aluguel local, seguro, diárias hospedagem, alimentação, atrações, extras; total consolidado e por pessoa.  
**Combinado:** somatório de componentes sem replicar hospedagem/alimentação.  
**Interações:** editar valores, visualizar resultado em tempo real, salvar estimativa como despesas do cenário ativo (com confirmação e sem duplicar automaticamente), imprimir resumo.  
**Limite:** cálculos são simulações, sem preços reais automáticos até integração de serviços de terceiros.

## 10. Tela 08 — Compras
**Lista:** nome do item, quantidade, unidade, preço unitário, total, loja, comprado/pendente, cenário.  
**Ações:** adicionar, filtrar, marcar comprado, editar; ordenação por loja/categoria.  
**Importante:** compra registrada não é automaticamente despesa até usuário associar ao orçamento.

## 11. Tela 09 — Importação Excel
**Etapas:** enviar `.xlsx`/`.xls` (quando parser suportar), pré-visualizar abas e linhas, mapear colunas e reconhecer cenários, validar, confirmar criação de viagem e gerar relatório de importação.  
**Planilha de referência:** abas Roteiro Barato, Roteiro Intermediário, Roteiro Caro, Lista de Compras, Vilefort Lista de Compras e Despesas.  
**Política:** as três abas de roteiro são **cenários da mesma viagem**; compras e despesas devem ser reconhecidas como módulos próprios.  
**Tratamento:** ignorar linhas totalmente vazias, sinalizar datas inválidas, valores sem parsing e locais incompletos. Nunca inventar horários, coordenadas ou preços ausentes.  
**Segurança:** leitura preferencialmente local no navegador; preservar arquivo original; prévia e aceite antes de gravar; importação transacional (ou tudo ou nada); geração de relatório de campos não reconhecidos.  
**Duplicatas:** oferecer criar nova viagem, substituir ou anexar a existente; nunca sobrescrever silenciosamente.

## 12. Tela 10 — Arquivo de viagens
**Lista:** ano, destino, capa, duração, custo planejado/efetivo, status e notas.  
**Ações:** visualizar, reativar, duplicar como nova viagem e exportar backup.  
**Arquivo ≠ exclusão:** status altera somente a visualização e edição opcional.

## 13. Tela 11 — Dados / configurações
**Itens:** exportar JSON completo; importar backup JSON; configurar moedas; preferências de animação e acessibilidade; gerenciamento futuro de conta/sincronização.  
**Aviso V1:** dados locais só no navegador. Não sugerir que estão na nuvem antes de implementar autenticação e banco de dados.  
**Futuro banco:** Supabase com políticas RLS por usuário, upload privado, migrações e backup; necessidade de configuração de projeto e credenciais fora do código.

## 14. Modelo lógico
- `Trip {id, title, origin, destinations[], startDate, endDate, participants, transportMode, currency, cover, notes, archived}`
- `Scenario {id, tripId, name, notes}`
- `ItineraryItem {id, tripId, scenarioId|null, date, startTime, endTime, category, title, address, latitude?, longitude?, url?, notes, informativeCost?}`
- `Expense {id, tripId, scenarioId|null, date?, title, category, expected, actual, currency, exchangeRate?, notes?}`
- `ShoppingItem {id, tripId, scenarioId|null, title, quantity, unit, unitPrice, store, purchased}`
- `Estimate {id, tripId, scenarioId, mode, inputs, outputs, createdAt}`
Regras: `scenarioId=null` significa válido para todos; exclusão de cenário pede confirmação de registros exclusivos; valores monetários devem usar precisão decimal/cêntimos para evitar erros de ponto flutuante.

## 15. Componentes e design system
- `AppShell`, `SideNav`, `MobileNav`, `GlobalHeader`, `PageHeader`
- `TripHero`, `TripCard`, `StatCard`, `ScenarioPicker`
- `DailyTimeline`, `ItineraryCard`, `MapView`, `MapFilters`, `MapPopup`
- `ExpenseTable`, `BudgetChart`, `EstimateCalculator`, `ShoppingChecklist`
- `ImportWizard`, `ValidationSummary`, `EmptyState`, `ConfirmDialog`, `Toast`
Todos os controles devem ter foco visível, labels, contraste suficiente e navegação por teclado.

## 16. Critérios de aceite da V2
1. Criar duas viagens independentes sem cruzar registros.
2. Criar dois cenários e despesa compartilhada + despesa exclusiva; comparar totais corretos.
3. Marcar ponto com coordenadas e visualizá-lo no mapa, acessando a etapa pelo popup.
4. Filtrar mapa por data/categoria sem perder pontos de outros dias armazenados.
5. Calcular carro e avião, validar entradas inválidas e registrar orçamento somente com consentimento.
6. Importar a planilha do Rio de Janeiro com preview, três cenários e relatório de campos não reconhecidos.
7. Arquivar, reativar e duplicar viagens preservando integridade de dados.
8. Usar em telas de 360px e desktop, com experiência adequada a teclado e movimento reduzido.
9. Exportar backup e restaurar todas as relações.
10. Não afirmar sincronização remota sem backend configurado.

## 17. Entregas técnicas sugeridas
**V2.1:** identidade Orbitrip + shell + dashboard + formulários e migração da V1.  
**V2.2:** roteiro e mapa Leaflet, marcadores e filtros.  
**V2.3:** calculadoras, orçamento e gráficos.  
**V2.4:** importação Excel com pré-visualização e mapeamento, ajustes de cenários.  
**V2.5:** autenticação, Supabase, sincronização, segurança e deploy.  
Separar sempre recursos implementados de propostas; não anunciar deploy antes de conferir o endereço funcional.
