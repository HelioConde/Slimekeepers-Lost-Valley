# Continuação do polimento dos mapas

> Registro intermediário, anterior à revisão narrativa. Bancos e postes foram retirados na [versão atual](../wilderness_polish/RELATORIO.md). As contagens e capturas abaixo documentam aquele estágio.

## Ajustes desta rodada

- Poste do Caminho das Nascentes reposicionado em uma abertura legível. Antes, apenas 10% dos pixels amostrados apareciam entre as copas; agora, 98%.
- Ruína do Círculo Musgoso saiu de uma posição totalmente encoberta para 98% de visibilidade. A busca por posições também encontrou lugar adequado para a pequena ruína no vale.
- Flores e pedras pequenas acompanham os bancos, mantendo a aproximação livre.
- A composição deixou de depender da posição atual do jogador durante a inicialização: entrar, voltar de outra região ou mover o personagem antes de carregar os detalhes produz a mesma disposição.
- A seleção de posição considera transparência dos sprites e ordem por Y das árvores. Não altera as copas nem força objetos para uma camada visual incorreta. Imagens das copas são compartilhadas por textura para evitar cópias repetidas em memória.

A camada atual tem 33 elementos adicionais na floresta e 24 no vale (57 no total), além das 288 substituições já realizadas. São nove objetos sólidos com colisões na base. Nenhum novo asset ou geração paga.

## Verificação

O teste novo reproduziu quatro falhas antes da alteração. Depois, suas 11 verificações passaram, incluindo comparação da disposição completa em duas situações de entrada para cada região.

- Regressão: 16 scripts, 10.697 verificações, zero falhas; GdUnit: 7 casos aprovados.
- Profundidade real no Godot: 117 comparações de base inferior, parte superior e passagem à frente, zero falhas.
- Natação: 32 verificações com física em passos fixos, zero falhas.
- Cinco pontes atravessadas no Godot nativo, sem bloqueios.
- Capturas reais em 1280 × 720, conferidas visualmente. Os percentuais de visibilidade são amostragens da transparência das imagens; as capturas verificam a aparência durante o jogo, com vento.

## Capturas

- [Poste reposicionado](FlorestaDoDespertarV2_poste.png)
- [Poste antes](before_FlorestaDoDespertarV2_poste.png)
- [Banco da clareira](FlorestaDoDespertarV2_clareira.png)
- [Ruína na floresta](FlorestaDoDespertarV2_ruinas.png)
- [Ruína no vale](ValeDasNascentes_ruinas.png)

As capturas dos postes acompanham a posição do objeto: o enquadramento mudou com a relocação. A comparação da clareira mantém o ponto de câmera anterior.

[Reprodução antes](before.log) · [Teste após correção](after.log) · [Regressão completa](regression.log) · [Profundidade](depth.log)

Mudanças locais preservadas. Reiniciar a execução atual no Godot para carregar o polimento.
