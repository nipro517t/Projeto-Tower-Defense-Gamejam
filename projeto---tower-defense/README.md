# Tower Defense — Game Jam

Jogo de Tower Defense feito em Godot 4.7, estilo Bloons TD (câmera top-down 2D), para a Game Jam do curso Técnico em Programação de Jogos Digitais (Colégio João Netto de Campos).

> Este README é atualizado conforme o projeto evolui — reflete sempre o estado mais recente do código.

---

## Fluxo de telas

`Menu Principal` → `Seleção de Fases` → `Fase 1` (única fase existente hoje; Fase 2 e 3 aparecem desabilitadas como placeholder). O botão "Voltar ao Menu" (dentro do menu de pausa, ou na tela de Game Over) volta pro Menu Principal a qualquer momento, resetando o estado do jogo (dinheiro/vida/rodada).

## Controles

| Ação | Como fazer |
|---|---|
| Comprar uma torre | Clique no botão "Torres" (canto inferior direito) pra abrir a loja, depois clique numa das opções |
| Posicionar a torre comprada | Depois de escolher na loja, clique no mapa onde quer colocá-la (aparece um preview transparente seguindo o mouse antes de confirmar) |
| Ver o alcance de uma torre já colocada | Passe o mouse em cima dela |
| Ver informações, fazer upgrade ou vender uma torre | Clique nela (a loja some enquanto esse painel está aberto); clique fora do painel ou no botão "Fechar" pra voltar |
| Mudar a prioridade de alvo de uma torre | Setas `<`/`>` dentro do painel de informações da torre |
| Começar a partida | Clique em "Play" (o jogo começa pausado, esperando esse clique) |
| Pausar/despausar | Botão "Play"/"Pause" |
| Acelerar o jogo (2x) | Botão de velocidade (mostra "1x" ou "2x" conforme o estado atual) |
| Abrir o menu de pausa | Botão "Menu" (Continuar / Configurações* / Voltar ao Menu / Sair) |

*Configurações ainda não tem efeito — não existe essa tela no projeto ainda.

## Feedback visual

- **Projétil**: cada torre dispara um projétil de verdade (não é mais dano instantâneo) que persegue o alvo até acertar — "sempre vai acertar" mesmo que o inimigo se mova nesse meio tempo.
- **Indicador de dano**: um número vermelho sobe e desaparece sobre o inimigo toda vez que ele leva dano.

## Torres criadas

| Torre | Tipo de dano | Custo | Descrição |
|---|---|---|---|
| Torre Normal | Direto | 250 | Dano instantâneo no inimigo mais avançado dentro do alcance |
| Torre de Fogo | Burn (DOT) | 375 | Aplica queimadura contínua; acumula potência se atingida por múltiplas torres de fogo (teto de stacks), reseta a duração a cada novo hit |

## Inimigos

| Inimigo | Vida | Velocidade |
|---|---|---|
| Padrão | 10 | 100 |
| Forte | 25 | 80 |

---

## Arquitetura do projeto

```
Scenes/
  menu_principal.tscn — tela inicial (Jogar / Sair)
  selecao_fases.tscn   — seleção de fase (só Fase 1 existe de verdade hoje)
  level_1.tscn      — cena principal (mapa, caminho, spawner, torres de teste, HUD)
  inimigo.tscn       — inimigo padrão
  inimigo_forte.tscn  — variante com mais vida
  torre.tscn          — torre normal (sprite Foozle "Tower 01")
  torre_burn.tscn      — torre de fogo (mesmo script, tipo_dano="Fogo", sprite Foozle "Tower 03")
  projetil_normal.tscn  — projétil da torre normal (flecha)
  projetil_fogo.tscn      — projétil da torre de fogo (orbe)
  hud.tscn             — toda a interface (dinheiro, vida, rodada, loja, controles de jogo, menu de pausa)

Scripts/
  Game.gd              — Autoload global (dinheiro, vida do jogador, onda atual, game over, reset de estado)
  menu_principal.gd      — navegação do menu inicial
  selecao_fases.gd         — navegação da seleção de fase
  inimigo.gd            — movimento pelo caminho, vida, dano, Burn (DOT), indicador de dano flutuante
  torre.gd               — detecção de alcance, seleção de alvo, dispara projétil, upgrade, venda, indicador de alcance
  projetil.gd              — persegue o alvo até acertar, aplica o dano (direto ou Burn) na chegada
  spawner.gd               — sistema de ondas (lê o Array "Ondas" configurado no Inspector)
  grupo_inimigo.gd          — Resource: um bloco de inimigos dentro de uma onda (cena + quantidade + intervalo)
  onda_config.gd             — Resource: uma onda = lista de GrupoInimigo em sequência
  gerenciador_torres.gd       — compra/posicionamento por clique + preview transparente da torre
  info_torre_panel.gd          — painel de informações da torre clicada: stats, prioridade de alvo, upgrade e venda
  shop_panel.gd                — painel retrátil da loja (abre/fecha, guarda qual torre está selecionada)
  hud_manager.gd                 — atualiza os textos de dinheiro/vida/rodada na tela
  controles_jogo.gd               — Play/Pause, velocidade 2x, menu de pausa, voltar ao menu
```

### Como tudo se conecta

- **`Game` (Autoload)** guarda o estado que qualquer script pode ler/escrever a qualquer momento: `Game.dinheiro`, `Game.vida_jogador`, `Game.wave`. Não precisa de `@export` nem `$` pra acessar — é global.
- **Pausa controla o "jogo não começou ainda"**: o jogo nasce pausado (`Game.gd`) e só o botão Play despausa. Tudo que tem `process_mode` padrão (spawner, torres, inimigos) fica congelado enquanto pausado; a HUD inteira e o `GerenciadorTorres` têm `process_mode = ALWAYS`, então dá pra comprar/posicionar torres mesmo antes de apertar Play.
- **O caminho é compartilhado**: existe 1 só `Path2D` no mapa; cada inimigo ganha seu próprio `PathFollow2D` (criado pelo spawner), então vários inimigos andam na mesma curva sem duplicar nada.

---

## Como estender o jogo

### Adicionar uma onda nova (ou editar as existentes)

1. Abra `level_1.tscn`, selecione o nó `Spawner`
2. No Inspector, campo `Ondas` → "Adicionar Elemento" (cria um `OndaConfig`)
3. Expanda ele → `Grupos` → "Adicionar Elemento" (cria um `GrupoInimigo`)
4. Preencha `Inimigo Cena` (arraste `inimigo.tscn` ou `inimigo_forte.tscn`), `Quantidade` e `Intervalo`
5. Pode adicionar mais de um `GrupoInimigo` na mesma onda — eles spawnam em sequência, um bloco depois do outro

### Criar um novo tipo de inimigo

1. Duplique `inimigo.tscn` (botão direito → Duplicar)
2. Ajuste `Vida Max` e `Velocidade` no Inspector do novo arquivo (mesmo script `inimigo.gd`, só muda os valores)
3. Use essa nova cena em qualquer `GrupoInimigo` das ondas

### Criar uma nova torre

1. Duplique `torre.tscn` ou `torre_burn.tscn`
2. Ajuste `Dano`, `Cadência`, `Tipo Dano` (dropdown "Normal"/"Fogo") no Inspector
3. Em `gerenciador_torres.gd`, adicione a nova cena como um `@export` e conecte um botão novo na loja (`shop_panel.gd`) chamando `_selecionar()` com ela

### Adicionar um novo tipo de dano (Freeze, Poison, etc.)

Siga o padrão do Burn: em `inimigo.gd`, crie uma função `aplicar_X()` parecida com `aplicar_burn()`; em `torre.gd`, adicione mais um caso no `match tipo_dano:` do `_atacar()`.

---

## Créditos de assets

- Sprites de torres e projéteis: "Spire - Tower Pack" (Foozle / Baldur), licença CC0
- Ícones de moeda/coração da HUD: CraftPix (uso livre)
- Tilesets top-down (floresta/lava/vilarejo/campos) baixados da CraftPix — ainda não aplicados no mapa, ver Pendências

## Pendências conhecidas (não bloqueiam a jam, mas estão no roadmap)

- Aplicar os tilesets top-down (vilarejo/campos) no mapa — hoje o chão ainda é o `Path2D` sem textura de fundo; os tiles já estão na pasta `Assets` esperando serem montados numa `TileMap`
- Loja sumir da tela ao clicar pra posicionar uma torre (já some ao ver informações de uma torre; falta o mesmo pro momento de posicionar uma nova)
- Contador de Rodada se reposicionar se a loja cobrir ele
- Tela de Configurações (o botão já existe no menu de pausa, sem destino ainda)
- Fase 2 e 3 (botões existem na seleção de fases, desabilitados — precisam de mapas/ondas próprios)
- `selecionar_fase.tscn`/`.gd`: protótipo em andamento de uma tela de seleção mais rica (mapa com câmera que desliza lateralmente revelando "mundos"/fases, ideia registrada em comentário no próprio script) — ainda não conectada ao fluxo principal
- Árvores de upgrade completas ao estilo Bloons TD (decidido conscientemente que está fora do escopo do prazo — hoje o upgrade é só +dano/+cadência, 5 níveis, custo crescente)
