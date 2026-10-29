# Correção da margem da poça

A poça da Clareira do Despertar havia sido deslocada na ampliação do mapa. Uma pedra e cinco tiles de grama herdados continuavam no novo contorno da água.

- Pedra reposicionada na margem noroeste, junto com samambaia, sombra de contato e colisão.
- Cinco tiles de vegetação terrestre redistribuídos em células livres fora da água, com distância visual da margem. Os tiles originais e suas variantes foram preservados.
- Contorno, animação, interação e colisão da água preservados.
- A regra é aplicada ao carregar o mapa e é idempotente. A composição restante é mantida.

## Evidência

- 9 verificações da poça: vegetação preservada, raízes fora da água, pedra e colisão em terreno seco, água inalterada e execução repetida estável.
- 157 verificações da floresta, incluindo rotas físicas e preservação das células fora da poça.
- Verificações de assets e profundidade registradas nos logs adjacentes.
- Capturas nativas em 1280 × 720 conferidas visualmente.

[Antes](before.png) · [Depois](after.png)

Nenhum novo sprite gerado. Reinicie a execução atual no Godot para carregar a correção.
