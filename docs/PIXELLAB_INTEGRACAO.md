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
