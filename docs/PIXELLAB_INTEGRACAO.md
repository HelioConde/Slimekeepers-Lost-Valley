# PixelLab no Slimekeepers: Lost Valley

Integração migrada de [video-forge-ia2](https://github.com/HelioConde/video-forge-ia2), especialmente `videoforge/pixellab/client.py` e `.github/workflows/pixellab-character.yml`.

## O que está disponível
- Cliente Python para API PixelLab v2, sem dependências externas.
- Workflow manual **PixelLab - Conexao Slimekeepers** com `plan` (sem token), `inventory` (GET autenticado) e `export` (GET autenticado; baixa ZIPs de personagem existente).
- Testes offline para evitar regressões. **Não existe geração paga ativa neste workflow**, nenhuma Action automática em push, nenhuma mudança em cenas Godot ou sprites aprovados.
- A pasta `output/pixellab/` não é versionada. ZIPs só podem ser anexados a Actions mediante confirmação explícita de exposição pública.

## Ligar a conta no repositório de destino
**Secrets são isolados por repositório:** o GitHub não permite simplesmente ler/copiar `PIXELLAB_API_TOKEN` a partir do `video-forge-ia2`. Para migrar, cadastre o mesmo token novamente no destino (ou use um secret organizacional com acesso aprovado a ambos, se aplicável).

1. Em [PixelLab / Account](https://www.pixellab.ai/account), obtenha seu token com segurança.
2. Em [Slimekeepers / Actions secrets](https://github.com/HelioConde/Slimekeepers-Lost-Valley/settings/secrets/actions), adicione `PIXELLAB_API_TOKEN`. **Nunca publique o token em arquivos, issues ou chat.**
3. Opcionalmente, adicione `PIXELLAB_CHARACTER_ID` (UUID de um personagem existente) para exportar. Não use o ID do Alex automaticamente: o Slimekeepers possui seus próprios personagens e slimes.
4. Após merge da PR, abra **Actions → PixelLab - Conexao Slimekeepers → Run workflow** e execute `plan`, depois `inventory`. O modo `inventory` retorna só a contagem de personagens, sem IDs, nomes ou prompts.
5. Para exportar um personagem, configure o ID no secret e execute `export` com `confirmar_artefatos_publicos=true`. Essa opção permite baixar os ZIPs existentes, **sem gerar novos sprites**. O artefato fica disponível no GitHub Actions público por 1 dia e pode conter informações de identificação do personagem. Evite essa modalidade para assets privados; prefira exportação local.

## Rodar localmente

```powershell
python tools/pixellab_bridge.py --operation plan
$env:PIXELLAB_API_TOKEN = "<token-local>"
python tools/pixellab_bridge.py --operation inventory
$env:PIXELLAB_CHARACTER_ID = "<uuid-do-personagem>"
python tools/pixellab_bridge.py --operation export --public-artifacts-confirmed
python -m unittest discover -s tests -p "test_pixellab_bridge.py" -v
```

O argumento de confirmação é exigido para `export` a fim de manter o mesmo controle do workflow; rodando localmente os arquivos são salvos em `output/pixellab/` e não são enviados automaticamente.

## Próxima fase (não incluída nesta migração)
Adicionar perfis específicos do Slimekeepers (jogador, Gelito, Brotinho, Brasinha), sprites de 8 direções e pipeline de importação/QA para Godot, com revisão visual antes de substituir qualquer asset existente. O workflow de geração do VideoForge foi deixado de fora intencionalmente para não cobrar créditos nem gerar personagens da produtora de vídeo dentro do jogo.

## Autorização de produção visual — 19/11/2026

O criador **autorizou gerar todas as imagens necessárias ao jogo usando PixelLab**, inclusive personagens, slimes, objetos, cenários e animações, conforme a necessidade real do desenvolvimento. Esta autorização é ampla quanto à quantidade de imagens e **não exige uma nova confirmação para cada asset necessário**.

A autorização **não significa que todos os sprites existentes devam ser regenerados** nem que se deva consumir créditos em massa sem um requisito concreto. Aplicar o seguinte procedimento:

1. Cruzar cada nova necessidade do gameplay e das cenas com o inventário em `assets/`, os manifests de assets existentes e a Bíblia Narrativa; reutilizar assets aprovados antes de gerar.
2. Registrar cada necessidade na fila visual com nome estável, categoria, referência aprovada, dimensões/escala compatíveis com o Godot, direções e animações exigidas, arquivo de destino, prioridade, status e dependências.
3. Gerar via PixelLab somente o que faltar ou o que a revisão visual reprovar, incluindo variações/direções suficientes para a função no jogo; não há teto arbitrário de imagens necessárias. **Não repetir POST** em caso de timeout, 429 ou resposta ambígua: consultar primeiro o histórico/job.
4. Antes de qualquer chamada paga, confirmar token e créditos reais, além de verificar se já existe job/arquivo para a mesma chave. Registrar ID/job, status, parâmetros não sigilosos e utilização/custo quando a API informar; nunca publicar token ou payload privado.
5. Comparar os novos sprites às referências aprovadas: personagem reconhecível, proporções, pixel art consistente, orientação 2D do jogo, transparência válida, quadros/direções completos e animação sem saltos ou cortes. Separar geração concluída de qualidade visual aprovada.
6. Conservar versões e SHA-256; disponibilizar prévias e relatórios para revisão antes de substituir arte já aprovada. Integração em cenas e testes Godot devem ocorrer em PRs verificadas, não em substituição silenciosa de PNGs.

**Estado técnico nesta data:** o workflow `pixellab-connection.yml` continua apenas com `plan`, `inventory` e `export` e **não está autorizado tecnicamente a realizar POST nesse workflow** até que se implemente e teste o produtor controlado. O cliente `tools/pixellab_client.py` já tem métodos de geração de personagem/estado/animação, mas isso isoladamente não comprova que o token, quota ou qualquer geração estejam ativos. A autorização humana foi concedida; a execução deve demonstrar evidência real.

**Prioridade:** concluir gameplay pelo proxy Astra e identificar lacunas visuais concretas. A produção de assets acompanha as dependências de cada cena, sem alterar a narrativa nem fabricar sprites desnecessários.
