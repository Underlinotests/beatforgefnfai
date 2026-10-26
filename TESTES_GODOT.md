# BeatForge Engine — validação com Godot 4.7.2 Stable

## O que foi executado

- **Importação do projeto** com `--headless --editor --import --quit`: concluída.
- **Cenas carregadas individualmente:** `main`, `week_select`, `freeplay_menu`, `options_menu`, `gameplay`.
- **Testes de integração:** 56 PASS; 0 FAIL.
- **Teste de áudio:** 12 PASS; 0 FAIL.

## Comandos para reproduzir

Abra um terminal na pasta do projeto e substitua `godot` pelo caminho para a Godot 4.7.2 instalada.

```bash
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tests/headless_integration.gd
godot --headless --path . --script res://tests/headless_audio_smoke.gd
```

No Windows, use o caminho do executável, por exemplo:

```powershell
& "C:\CAMINHO\Godot_v4.7.2-stable_win64.exe" --headless --editor --path . --import --quit
& "C:\CAMINHO\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/headless_integration.gd
& "C:\CAMINHO\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/headless_audio_smoke.gd
```

## O que os testes cobrem

- Bopeebo (124 notas, BPM 100), Fresh (264, BPM 120), Dad Battle (323, BPM 180).
- Existência de áudios e disponibilidade da dificuldade Hard.
- Progressão da Story Mode: Bopeebo → Fresh → Dad Battle → menu de Week 1.
- Execução independente do Freeplay e retorno ao Freeplay.
- Estados de Game Over, sons importados e reinício na confirmação.
- Contagem inicial e reprodução efetiva de cada arquivo MP3 após a contagem.

## Limitações

O teste de progressão invoca `_complete_song()` diretamente para simular o fim da música, não espera a reprodução de cada faixa por completo. O teste de Game Over ativa o estado de derrota por código e simula o término do áudio de confirmação. O modo headless não permite validar visualmente posições, camadas e animações.

Ao terminar a rotina de integração, a Godot pode registrar avisos de `ObjectDB`/recursos em uso durante o fechamento da sessão de testes; durante as verificações não ocorreram erros de inicialização das cenas.

## Correção aplicada

`scripts/character.gd`: o nome usado no JSON (`BF HEY`) foi mapeado para o nome do atlas compilado (`BF HEY!!`) antes de buscar os frames, removendo um aviso desnecessário e garantindo a animação correta.


## Menu Options estilo Freeplay (2026-10-26)
Testado no Godot 4.7.2 headless com `tests/headless_menu_keyboard.gd`: 27 verificacoes aprovadas.
Main Menu, Freeplay, Story, Mods e Options sem interacao por mouse. Options e Mods agora sao listas VCR controladas por teclado. Fundo menuBG segue suavemente a selecao no Main Menu e Options. Os testes `headless_integration.gd` e `modding_integration.gd` tambem passaram. Avisos de recursos ainda em uso podem aparecer ao encerrar os testes headless.


## Suite adicional (GF, ordenacao das weeks, splash)

```bash
godot --headless --path . --script res://tests/headless_week_gf_splashes.gd
```

Confere ordem crescente das weeks (incluindo mod), transicao em ambos os sentidos, carregamento de animacoes GF, zoom de camera, 4 splashes por cor, efeito apenas no julgamento SICK! e ocultacao da GF por mod. A verificacao visual foi realizada com renderizacao Xvfb. Avisos de recursos em uso no encerramento de suites anteriores ainda podem ocorrer.
