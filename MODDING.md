# BeatForge Engine — Modding v1

**Godot 4.7.2 / GDScript.** Esta versão instala **mods de dados** (arquivos JSON, PNG/XML Sparrow e OGG/MP3) sem precisar modificar o código da engine. Não executa GDScript/Lua de terceiros.

## Instalar um mod

1. Abra o jogo, selecione **MODS** no menu principal usando o teclado e escolha **ABRIR PASTA**.
2. Extraia cada mod numa pasta própria: `mods/<id>/mod.json`. Não deixe duas pastas intermediárias.
3. Volte ao menu MODS, escolha **RECARREGAR MODS** e deixe o mod em **ON**.
4. Entre em **Story Mode** e navegue entre as semanas com ↑ e ↓, ou abra **Freeplay**. As músicas só aparecem se tiverem áudio e pelo menos um chart reconhecido.

O diretório de instalação de jogadores é `user://mods/` (uma pasta de dados da Godot; o endereço absoluto é exibido pelo jogo). Ao desenvolver na Godot, você também pode colocar mods em `res://mods/`. Em caso de IDs iguais, `user://mods` tem prioridade. O estado ON/OFF fica salvo no armazenamento de usuário.

Este projeto inclui `mods/_template`, **modelo editável sem áudio de demonstração**. Para criar um mod novo, copie o template para uma pasta com o ID desejado, renomeie `mod.example.json` para `mod.json` e siga o `README.md` do template.

## Estrutura de pasta sugerida

```text
meu_mod/
├── mod.json
├── weeks/
│   └── minha_week.json
├── songs/
│   └── minha_musica/
│       ├── instrumental.ogg
│       ├── minha_musica-normal.json
│       └── minha_musica-hard.json
├── stages/
│   ├── palco.json
│   └── fundo.png
├── characters/
│   ├── personagem.json
│   ├── personagem.png
│   └── personagem.xml
└── icons/
    └── oponente.png
```

Os nomes dos arquivos não precisam ser iguais aos exemplos, desde que `mod.json` e `weeks/*.json` apontem para os caminhos corretos. **Todos os caminhos devem ser relativos à raiz do mod** (não use `res://`, `user://`, `../` nem caminhos absolutos nos manifests).

## mod.json

```json
{
  "api_version": 1,
  "id": "meu_mod",
  "name": "Meu Mod",
  "version": "1.0",
  "author": "Seu nome",
  "weeks": ["weeks/minha_week.json"]
}
```

O campo `id` deve ser idêntico ao nome da pasta, em minúsculas, usando apenas letras `a-z`, números, hífen ou sublinhado. Cada week é um JSON separado, e o mod pode listar várias weeks.

## weeks/minha_week.json

```json
{
  "id": "minha_week",
  "name": "MINHA WEEK",
  "opponent": "NOVO PERSONAGEM",
  "menu_image": "weeks/titulo.png",
  "songs": [
    {
      "id": "minha_musica",
      "title": "MINHA MÚSICA",
      "audio": "songs/minha_musica/instrumental.ogg",
      "charts": {
        "normal": "songs/minha_musica/minha_musica-normal.json",
        "hard": "songs/minha_musica/minha_musica-hard.json"
      },
      "stage": "stages/palco.json",
      "opponent_character": "characters/personagem.json",
      "icon": "icons/oponente.png"
    }
  ]
}
```

`player_character` também é aceito. `stage`, `icon`, `menu_image` e ambos os personagens são opcionais; sem eles, a engine usa os gráficos padrão. `charts` reconhece `easy`, `normal` e `hard`, mas **só exibe uma dificuldade se o arquivo JSON existir**. No Story Mode, a seleção oferece apenas dificuldades disponíveis para *todas* as músicas da week. No Freeplay, cada música possui suas próprias dificuldades.

Os IDs das músicas são separados por namespace. `meu_mod:minha_musica` nunca substitui `bopeebo` nem músicas de outros mods.

## Formato de chart

O leitor aceita o JSON de notas tradicional da Psych Engine (`{"song": {"song":..., "bpm":..., "speed":..., "notes":[...]}}`). Os tempos e sustains são dados em **milissegundos**, com lanes `0..7`.

- Charts **nativos da Psych**: `mustHitSection` determina de quem são as colunas `0..3`; as `4..7` pertencem ao outro personagem.
- Charts **convertidos** da BeatForge: marque `"format":"psych_v1_convert"` no objeto `song`; então as colunas `0..3` são sempre do jogador, e `4..7` sempre do oponente, sem inversão por seção.

Confira `mods/_template/songs/minha_musica/minha_musica-hard.json` para um chart vazio válido. Adicione notas conforme o formato explicado acima.

## Stages personalizados

```json
{
  "defaultZoom": 0.9,
  "camera_speed": 1.0,
  "opponent": [100, 100],
  "boyfriend": [770, 100],
  "camera_opponent": [0, 0],
  "camera_boyfriend": [0, 0],
  "layers": [
    {"image": "stages/fundo.png", "position": [550, 305], "scale": [1, 1], "z_index": -10}
  ]
}
```

Cada `layer` é um PNG independente. As posições da imagem são em pixels para a resolução de referência **1100×620** do projeto. As posições de `boyfriend` e `opponent` seguem o sistema de coordenadas do palco. Com `layers` presentes, as camadas do stage da Week 1 são ocultadas.

## Personagem personalizado

Use um spritesheet PNG e um XML Sparrow/Starling com `SubTexture name`, `x`, `y`, `width`, `height` e, opcionalmente, `frameX/frameY/frameWidth/frameHeight`. O JSON pode usar prefixos de animação da Psych Engine.

```json
{
  "atlas": "characters/personagem",
  "scale": 1.7,
  "flip_x": false,
  "offset_scale": 1.0,
  "position": [0, 0],
  "animations": [
    {"anim": "idle", "name": "Personagem idle", "fps": 12, "loop": true, "offsets": [0, 0], "indices": []},
    {"anim": "singLEFT", "name": "Personagem left", "fps": 24, "loop": false, "offsets": [0, 0], "indices": []},
    {"anim": "singDOWN", "name": "Personagem down", "fps": 24, "loop": false, "offsets": [0, 0], "indices": []},
    {"anim": "singUP", "name": "Personagem up", "fps": 24, "loop": false, "offsets": [0, 0], "indices": []},
    {"anim": "singRIGHT", "name": "Personagem right", "fps": 24, "loop": false, "offsets": [0, 0], "indices": []}
  ]
}
```

`atlas` é relativo à raiz do mod **sem a extensão**; requer `personagem.png` e `personagem.xml`. `offset_scale` é um multiplicador dos offsets do JSON. Em PNGs que já foram redimensionados, ajuste esse campo e `scale` conforme necessário.

Os personagens de gameplay são configurados por música. Nesta primeira versão os **personagens ilustrativos do seletor de weeks** ainda são os da Week 1, mesmo para uma semana customizada; a gameplay usa o personagem do mod.

## Limitações da versão 1

- Não há scripts de mod, eventos personalizados executáveis, skins de nota, editor de chart integrado nem download automático de mods.
- Mods devem ser instalados manualmente como pastas; `.zip` não é carregado diretamente.
- Só é possível usar PNG, OGG Vorbis ou MP3 para os assets dinâmicos cobertos pelos tipos acima.
- Conflitos de ID de mod entre `user://` e `res://` são resolvidos dando prioridade ao primeiro.
- Instale somente arquivos de procedência confiável. O carregador não executa código dos mods e bloqueia caminhos relativos que tentem sair da pasta do mod.

## Testes automatizados

No editor Godot 4.7.2, rode testes sem interface:

```bash
Godot --headless --path /caminho/BeatForge --script res://tests/modding_integration.gd
Godot --headless --path /caminho/BeatForge --script res://tests/headless_integration.gd
```

O template está em `mods/_template` e não é carregado até ser copiado e configurado como mod válido. O teste `tests/modding_integration.gd` cria um mod temporário e o apaga ao encerrar.


## Ordem das weeks

Todas as weeks devem definir `"order"` como um inteiro no JSON da week.
A lista é ordenada de forma crescente; empate é resolvido pelo ID da week.
Weeks antigas sem `order` vão para o fim (`9999`) e geram aviso.

```json
{ "id": "minha_week", "name": "MINHA WEEK", "order": 2, "songs": [] }
```

Em cada música do mod, `"hide_girlfriend": true` permite ocultar a GF.
Sem esse campo, ela aparece e dança. Mods podem também configurar
`"girlfriend_character": "characters/minha_gf.json"`, com o mesmo
formato de atlas externo dos outros personagens. A GF padrão dança no
ritmo; o canto é reservado para a música `tutorial`.


## Ícone fallback para mods

Se uma música de mod não declarar `icon`, a engine mostra `assets/health/icon-mod-placeholder.png`, o sprite `icon-face.png` enviado (dois frames de 150×150). Para substituir, acrescente `"icon": "icons/personagem.png"` na música da week, com o PNG correspondente.
