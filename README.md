# VIAGENS — Planejador pessoal de viagens

Aplicação web estática e responsiva, criada a partir do modelo de planejamento do usuário no arquivo `2027_01 - Rio de Janeiro.xlsx`.

## Versão 1.0

- Criação, edição, duplicação e arquivamento de múltiplas viagens.
- Destinos, origem, datas, viajantes, modal de transporte e moeda.
- Itinerário diário com atividades, horários, categorias, endereços, coordenadas, links e observações.
- Cenários alternativos de planejamento em cada viagem, com eventos e despesas compartilhados ou específicos.
- Orçamento previsto e gasto realizado, com detalhamento por categoria e comparativo entre cenários.
- Listas de compras com quantidades, lojas, preços e estado de aquisição.
- Backup completo e restauração por JSON.
- Layout responsivo para computador, tablet e celular.

## Executar

Abra `index.html` em um navegador atual. A aplicação não precisa de servidor, instalação, dependências ou chaves de API.

Também pode ser publicada com GitHub Pages, após habilitar Pages nas configurações do repositório (se o plano e a visibilidade do repositório permitirem).

## Armazenamento e privacidade

**Importante:** na V1 os dados são salvos em `localStorage` **somente no navegador/dispositivo em uso**. Não existe login, banco de dados ou sincronização automática. Limpar os dados do navegador pode apagar os roteiros; use **Dados e backup → Baixar backup JSON**. O GitHub armazena apenas o código-fonte, não os registros pessoais inseridos no aplicativo.

## Estrutura do projeto

- `index.html`: interface, estilos e lógica (aplicação sem dependências).

## Próximas versões sugeridas

1. Persistência sincronizada entre dispositivos com autenticação e banco de dados.
2. Importação direta de planilhas XLSX legadas.
3. Mapas, marcadores georreferenciados e visualização espacial do percurso.
4. Custos automáticos de viagens terrestres: distância, consumo, pedágios e estimativa de combustível.
5. Câmbio, orçamento multimoeda e exportação de roteiros em PDF.
6. Documentos e reservas, com anexos protegidos e comprovantes.

## Modelo da planilha original

A pasta de trabalho analisada contém três cenários de roteiro (Barato, Intermediário, Caro), duas listas de compras e uma aba de despesas. A V1 reaproveita a lógica da planilha, mas os cenários passam a ser alternativas **dentro de uma única viagem**.

## Nota sobre valores

Valores colocados nas etapas do roteiro são informativos. O total financeiro consolidado é calculado com os registros de **Despesas**; isso evita contagens duplicadas quando um custo é anotado apenas como referência na programação.
