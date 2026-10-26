# BeatForge Engine — Modding v1

Engine de FNF em **Godot 4.7.2**, com Week 1 completa (Bopeebo, Fresh e Dad Battle), Story Mode, Freeplay, Options, menus animados e suporte inicial a mods sem alterar o código principal.

## Abrir o projeto

1. Extraia o ZIP numa pasta limpa.
2. Abra `project.godot` com a Godot 4.7.2 Stable (ou versão compatível).
3. Pressione F5 e entre em **MODS** no menu principal.
4. Crie seu mod copiando `mods/_template` para uma pasta com seu ID e siga `mods/_template/README.md`.
5. Coloque o áudio e os charts próprios, ative o `mod.json`, depois use **MODS → RECARREGAR**.

A Week 1 continua intacta. O Story Mode da Week 1 joga Bopeebo → Fresh → Dad Battle. Mods podem criar outras weeks e músicas sem sobrescrever a Week 1.

**Documentação para criar mods:** [MODDING.md](MODDING.md). A pasta `mods/_template` contém um modelo editável com manifesto, week, chart vazio e exemplos de stage e personagem; não inclui nenhuma música de demonstração. Mods de usuário devem ser instalados pelo caminho apresentado no menu Mods, ou na pasta `user://mods`.

## Conteúdo suportado nesta versão

- Múltiplos mods, com IDs isolados, ativação/desativação e persistência em `user://`.
- Músicas com charts Easy/Normal/Hard quando cada arquivo existe; suporte aos formatos de chart nativo da Psych e `psych_v1_convert`.
- Áudio externo MP3 e OGG, PNG + XML Sparrow para personagens e imagens de palco.
- Weeks novas no Story Mode, e músicas de mods no Freeplay.
- Fade e retorno ao menu de origem, sistema de vida, ícones, Game Over e Options já existentes.

**Limite importante:** modding de dados, sem execução de scripts de terceiros ou eventos customizáveis, nesta primeira versão.

## Controles

- Menu principal: setas/WASD para navegar, Enter para confirmar.
- Story Mode: ↑/↓ alternam weeks, ←/→ alternam dificuldades disponíveis, Enter joga.
- Freeplay: ↑/↓ selecionam música, ←/→ alternam dificuldades.
- Gameplay: WASD ou setas (configurável), Esc retorna, F2 testa as poses dos personagens.
- MODS: navegue por teclado, confirme com Enter e use **RECARREGAR** para reler arquivos sem reiniciar.

## Validação

Os scripts de teste estão em `tests/`. O pacote sem mod de demonstração preserva os testes da Week 1 e inclui um teste de modding com conteúdo temporário gerado durante a execução. Testes headless não substituem testar visualmente no editor (câmera, sprites e sincronização real).


## Atualizacao — menus por teclado e Options VCR
- Mouse desativado na navegacao dos menus Main, Freeplay, Story, Options e Mods.
- Options redesenhado no estilo Freeplay: lista vertical com fonte VCR bitmap, sem botoes Godot convencionais.
- Setas/W/S navegam; Enter/Space confirma; Esc retorna. Setas esquerda/direita alternam Downscroll e Middlescroll.
- Para configurar teclas: selecione TECLA ou ALT e pressione Enter; pressione a nova tecla; Esc cancela.
- Main Menu e Options: menuBG move suavemente com o item selecionado.


## Atualizacao: camera, GF, Week Order e notas Sick (2026-10-26)

- A camera do mundo agora tem zoom mais proximo dos personagens. A HUD fica fixa.
- No menu principal e no Options, o fundo acompanha a opcao no sentido correto do eixo Y.
- Cada week tem campo `order` (numero inteiro). A menor ordem aparece primeiro; empate desempata por ID.
- Story Mode anima a week que chega deslizando com fade in, e a anterior desaparece com fade out.
- GF utiliza `GF_assets.png/XML` e `gf.json`, com danca alternada no ritmo. Weeks nativas sempre exibem a GF.
- Musicas de mods podem usar `"hide_girlfriend": true` para oculta-la. A musica futura `tutorial` tem gancho para canto da GF.
- `noteSplashes.png/XML` aparecem sobre a strumline do jogador exclusivamente para julgamento SICK!.
- O icone do BF esta espelhado horizontalmente para encarar o Dad.
- Novo teste: `tests/headless_week_gf_splashes.gd`.

A camera, os personagens e a transicao entre weeks foram conferidos tambem por renderizacao de frame via Godot Linux (Xvfb).


## Ajustes de proporcoes — Psych Engine

- Dad, Boyfriend e Girlfriend agora usam escalas independentes no `assets/stages/week1/stage.json` via `beatforge_display_scales`.
- Os icones do health bar foram ampliados de 75 para 110 px e reposicionados para manter a HUD legivel.
- A camera agora enquadra o personagem que esta cantando com focos mais separados, acompanhando as posicoes dos personagens do stage.
- Os mods podem especificar `beatforge_display_scales` no proprio `stage.json`, sem precisar modificar a engine.
- Veja `CHANGELOG_PROPORCOES.md` e `tests/test_visual_scales.gd`.

## Ajuste visual — BF, GF e ícones

A Week 1 mantém Dad em 0.96; GF usa 2.05; BF usa 1.95 e foi abaixado no palco. A barra de vida tem os dois ícones ancorados ao seu centro vertical, em vez de ficarem flutuando acima. Consulte `CHANGELOG_AJUSTE_VISUAL.md`.


## Modelo de mod (sem demo)

A versão atual não inclui `neon_demo`: há somente `mods/_template`, que não é carregado automaticamente. Para testar modding, siga o README desse template, ou execute o teste automatizado que cria e remove uma pasta temporária. O ícone padrão agora usa exatamente o PNG `icon-face.png` enviado.
