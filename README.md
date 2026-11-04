# Macro de Clique e Segurar

Este projeto cria um macro com AutoHotkey v2 para:

- iniciar com um atalho
- clicar e segurar por um tempo configuravel
- soltar o clique
- repetir o ciclo ate o atalho de parada

## Requisitos

- Windows
- AutoHotkey v2 instalado

## Arquivos

- `macro_mouse.ahk`: script principal
- `config.ini`: configuracao de atalho, tecla/botao e tempo

## Como usar

1. De duplo clique em `macro_mouse.ahk`.
2. Na janela do macro, configure todos os campos.
3. Use os botoes `Gravar` para capturar teclas/atalhos.
4. Clique em `Salvar e aplicar`.
5. Use `Iniciar`/`Parar` na interface ou os atalhos definidos.

## Configuracao na interface

Campos disponiveis:

- `start_hotkey`: atalho para iniciar (ex.: `F6`, `^!s`)
- `stop_hotkey`: atalho para parar (ex.: `F7`, `^!x`)
- `target_key`: tecla ou botao a pressionar (ex.: `LButton`, `RButton`, `Space`, `Enter`)
- `hold_ms`: tempo segurando pressionado, em milissegundos
- `interval_ms`: pausa entre ciclos, em milissegundos

## Exemplos uteis

- `LButton` = botao esquerdo do mouse
- `RButton` = botao direito do mouse
- `MButton` = botao do meio
- `Space` = barra de espaco
- `Enter` = tecla Enter

## Observacao

- O arquivo `config.ini` ainda existe para persistir suas configuracoes.
- Pressione `Esc` durante a gravacao para cancelar.
- Se o atalho nao funcionar, verifique conflito com outro programa e troque na interface.
