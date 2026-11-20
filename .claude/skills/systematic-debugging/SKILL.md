---
name: systematic-debugging
description: "Diagnosticar bugs, falhas de testes, importação de assets e problemas Godot 4.7 por evidência antes de corrigir."
---

# Systematic Debugging — Slimekeepers

Regra: **não corrija sintomas sem investigar a causa raiz**. Use em falhas de Godot, GDScript, colisões, cenas, animações, PixelLab e workflows.

## 1. Investigar
- Leia mensagens completas, stack traces, arquivos e passos de reprodução.
- Compare com mudanças recentes e verifique versão Godot, caminho de cenas e UIDs.
- Se não for reproduzível, peça observações/logs adicionais antes de alterar código.
- Para falhas PixelLab, verifique status do job; não reenvie POST pago.

## 2. Comparar
- Encontre um exemplo funcional semelhante dentro do projeto.
- Identifique a menor diferença entre o caso que funciona e o que falha.
- Inspecione dependências: autoloads, sinais, `TileMapLayer`, `Resource`, inputs e testes.

## 3. Formular hipótese e testar
- Declare uma hipótese falsificável e um teste mínimo.
- Altere uma variável por vez, sem reescrever múltiplos sistemas.
- Use `tests/`, `addons/gdUnit4` e `tools/validate_forest.ps1` quando disponíveis.
- Se o Godot não estiver instalado, descreva o teste pendente; não invente sucesso.

## 4. Corrigir e prevenir
- Corrija na origem, adicione regressão e confirme que o comportamento original continua.
- Registre evidência, causa raiz, alteração e resultados. Se não houver evidência suficiente, informe `NÃO CONFIRMADO`.

Base: obra/superpowers, `systematic-debugging`, commit `bb92a77741419a4ab5f06e711a283343f1ada0c3`, MIT. Adaptação local sem shell scripts.

