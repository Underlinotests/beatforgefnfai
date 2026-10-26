# TEMPLATE DE MOD — BeatForge Engine

Esta pasta é **somente um modelo**, não é um mod instalado. Ela não possui `mod.json` ativo, então **não aparece** no menu MODS, no Freeplay ou no Story Mode. Nenhuma música de teste vem incluída.

## Primeiros passos

1. **Copie** a pasta `_template` para `user://mods/meu_mod` (recomendado para testar uma engine exportada) ou `res://mods/meu_mod` (ao desenvolver no projeto). Não edite a pasta `_template` diretamente.
2. Renomeie `mod.example.json` para **`mod.json`**. Confira que `id` corresponde **exatamente** ao nome da pasta (`meu_mod`) e só usa minúsculas, números, `_` e `-`.
3. Substitua `songs/minha_musica/Inst.ogg` com a **sua própria música** (OGG). Caso prefira MP3, atualize a extensão no JSON da week. O template não inclui áudio.
4. Edite `songs/minha_musica/minha_musica-hard.json`: `bpm`, `speed`, notas e outros dados. O chart vem vazio propositalmente. As notas são arrays `[tempo_em_ms, lane_0_a_7, sustain_em_ms]`. Com `format: psych_v1_convert`, 0–3 são do jogador e 4–7 do oponente.
5. Edite `weeks/minha_week.json`: nome, `order`, músicas e caminhos. Menor `order` aparece primeiro no Story Mode. Para acrescentar outras dificuldades, crie os JSON correspondentes e inclua os caminhos em `charts`.
6. Abra o jogo → **MODS → RECARREGAR**. O mod só vira jogável com áudio existente, chart JSON válido e `mod.json` ativo. Quando o carregador reconhecer esses arquivos, a música aparecerá no Freeplay e a week no Story Mode.

## Recursos opcionais

- **Ícone**: se você não definir `icon`, a engine usa automaticamente o placeholder `icon-face` (dois frames lado a lado). Se colocar `icons/oponente.png` de **300×150 px**, acrescente `"icon": "icons/oponente.png"` na configuração da música em `weeks/minha_week.json`.
- **Stage**: `stages/palco.example.json` mostra os campos de câmera, posições, escalas e camadas. Copie para `stages/palco.json`, crie `stages/fundo.png` e adicione `"stage": "stages/palco.json"` à música.
- **Personagem**: `characters/personagem.example.json` mostra a estrutura das animações. Copie para `characters/personagem.json`, acrescente os sprites `characters/personagem.png` e `characters/personagem.xml` e adicione `"opponent_character": "characters/personagem.json"` à música.
- **GF**: mods podem adicionar `"hide_girlfriend": true` na música para ocultá-la. Sem isso, ela aparece normalmente.
- **Imagem da week**: crie `weeks/titulo.png` e acrescente `"menu_image": "weeks/titulo.png"` no JSON da week.

**Importante**: arquivos `.example.json` servem apenas como referência. Não renomeie o `palco.example.json` ou o `personagem.example.json` sem criar os sprites PNG/XML necessários. Paths em JSON devem ser relativos à raiz da pasta do mod.

Veja `MODDING.md` na raiz da engine para a especificação completa.
