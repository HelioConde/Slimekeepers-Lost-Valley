# Ambientação selvagem — remoção de mobiliário

Os mapas devem transmitir uma floresta que retomou os espaços humanos. A direção narrativa enviada pelo usuário orienta esta revisão; seu documento completo permanece fora deste relatório público.

## Alterações

- Removidos os três bancos: dois na Floresta do Despertar e um no Vale das Nascentes.
- Removidos os três postes com lanternas: um na floresta e dois no vale.
- Seus corpos de colisão deixaram de ser criados; não ficam obstáculos invisíveis.
- Retirado o arranjo de decoração criado especificamente para os assentos. Vegetação original, caminhos, pontes e ruínas preservados.
- Sprites originais continuam disponíveis no acervo. Nenhuma geração paga.
- Mantida a composição determinística entre entradas e a busca de posições visíveis para as ruínas.

A camada MapArt agora contém 26 elementos novos na floresta e 20 no vale, com três bases sólidas correspondentes às ruínas. Mantidas as 288 substituições de sprites naturais.

## Validação

- Regressão completa no checkout de entrega: 16 scripts, 10.635 verificações, zero falhas; 7 casos GdUnit aprovados.
- Composição: 9 verificações, zero falhas, incluindo ausência de bancos/postes em ambas as entradas de cada região.
- Assets, ancoragem, colisões e posicionamento: 4.550 verificações, zero falhas.
- Capturas nativas em 1280 × 720: clareira e entrada do vale sem bancos, caminho sem poste, ruínas preservadas.

[Clareira](FlorestaDoDespertarV2_clareira.png) · [Caminho](FlorestaDoDespertarV2_caminho_sem_poste.png) · [Entrada do vale](ValeDasNascentes_entrada_sem_banco.png)

As capturas do relatório composition_polish são históricas e ainda mostram o mobiliário que foi rejeitado. Para visualizar esta revisão no editor, reinicie a execução do jogo.
