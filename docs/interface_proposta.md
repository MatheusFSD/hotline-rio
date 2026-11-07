# Proposta de interface — Hotline Rio

Documento só de proposta: nada aqui foi implementado e nenhuma ideia muda dano, vida, IA ou regras. As que encostam na jogabilidade estão marcadas **toca na jogabilidade** e ficam para o dono decidir. As referências de linha são do código atual (`scripts/*.gd`).

Base lida: `docs/narrativa.md` (seções 1, 2 e as aberturas e fechamentos dos atos da seção 7), o topo e os trechos de interface de `hud.gd`, `result_screen.gd`, `mission_screen.gd`, `act_card.gd`, `news_card.gd`, `main_menu.gd`, `menu_backdrop.gd`, `level_select.gd`, `combat_effects.gd`, o cursor em `main.gd` e as seções do `README.md` sobre menu, HUD, telas de resultado e sensação de impacto.

---

## 1. Identidade: o "neon da Lapa"

A interface do Hotline Rio é a sinalização da noite carioca escrita por cima da cena: o letreiro de lâmpadas do botequim, o LED vermelho de camelô, a placa azul de rua da prefeitura, a comanda de garçom rabiscada a caneta, o plantão policial com tarja amarela e o carimbo de cartório. O Caio era garçom, então a primeira linguagem dele é a da **conta do bar**: riscos de giz, "saideira", gorjeta. Conforme a conspiração aparece, essa linguagem é **invadida** por outras duas: a da vigilância (timestamp de câmera, tarja preta, fax interceptado da MARÉ) e a do **imóvel** (circular de condomínio, auto de despejo, carimbo). O rosa, o ciano e o amarelo que já existem (`hud.gd:11-16`) continuam sendo o neon, mas deixam de ser constantes: no Ato 1 eles queimam de tão saturados, no Ato 2 piscam e falham como letreiro com mau contato e no Ato 3 parecem lâmpadas de letreiro que alguém esqueceu de desligar às seis da manhã, ainda acesas mas lavadas pela luz do dia. A fonte Bungee (letreiro urbano) e a VT323 (terminal) ficam; o que muda é o suporte em que elas aparecem.

### O que já está perto demais de Hotline Miami

Vale mexer nisso independentemente dos atos:
- **Tela de vitória** (`result_screen.gd:166` e `:230-233`): o título ondula letra por letra (`[wave]`) trocando de cor sem parar, com uma nota em letra gigante batendo à direita (`:93-102`, `:255-264`). É a combinação mais reconhecível do original. A proposta D1 substitui por uma linguagem própria.
- **Cartões de ato** (`act_card.gd`): hoje são o briefing sobre preto. Ainda não copiam nada, mas um cartão de capítulo em tipografia grande sobre fundo escuro tende a cair no "PART X". A proposta E1 dá a eles um suporte carioca.
- O HUD **não** tem combo nem placar no canto, e isso é bom. As propostas abaixo evitam criar um.

---

## 2. A base: o humor da interface (pré-requisito de quase tudo)

**O que é hoje.** Nenhuma tela sabe em que ato está. As cores são `const` (`hud.gd:11-16`, `result_screen.gd:14-15`) e o tremor tem amplitude fixa (`hud.gd:275`, `result_screen.gd:220`).

**Proposta.** Um script pequeno de apresentação, por exemplo `scripts/ui_mood.gd`, com uma função estática que recebe o número da noite (de `Campaign.state.level` ou do índice da fase) e devolve três valores contínuos entre 0 e 1. Nenhum deles liga ou desliga: todas as telas leem e interpolam.

| Noite | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **euforia** | 1.0 | 1.0 | .9 | .8 | .6 | .45 | .35 | .25 | .15 | .1 | .05 | 0 |
| **paranoia** | 0 | 0 | .05 | .15 | .45 | .7 | .85 | 1.0 | .7 | .5 | .35 | .25 |
| **cansaço** | 0 | 0 | 0 | .05 | .1 | .15 | .2 | .3 | .5 | .65 | .8 | 1.0 |

Usos típicos: saturação das cores = `1 - .55 * cansaço`; amplitude do tremor do HUD = `10 * (.5 + .5 * euforia)`; chance de falha de letreiro por segundo = `.4 * paranoia`. A paranoia não zera no Ato 3: ela vira hábito (o Caio já sabe que é vigiado), por isso cai devagar. Opcional: cada nova tentativa na mesma noite soma +0,02 de cansaço, até +0,1, para quem morre muito sentir o peso.

- **Por que serve à história:** é a régua que faz a mudança ser gradual e lida sem explicação, como pede o arco euforia → paranoia → cansaço.
- **Por que não é cópia:** é infraestrutura; não tem equivalente visível no original.
- **Custo:** pequeno (um script de 30 linhas e trocar as constantes de cor por chamadas).

---

## 3. Propostas por tela

### A. HUD (`scripts/hud.gd`)

**A1. A comanda: o contador de corpos que pesa**
- **Hoje:** `ELIMINADOS 02/08` em Bungee com pulo e tremor a cada morte (`hud.gd:89-94`, `:204-206`, `:276`).
- **Ato 1:** o número continua, mas embaixo dele aparece uma fileira de **riscos de comanda** (os "pauzinhos" de garçom, quatro e um cortando). Cada morte risca um a giz, com o pulo atual. Duas mortes em menos de 1 s fazem o risco sair torto e maior; sem multiplicador, sem pontuação no canto.
- **Ato 2:** quando morre um Inquilino, o risco sai em tinta azul-preta (a mesma do sangue deles, `combat_effects.gd:22-27`) e o número pisca `??` por 0,1 s antes de corrigir. O HUD "não sabe" se aquilo contava como gente.
- **Ato 3:** sem pulo, sem tremor. Os riscos ficam cor de osso e uma segunda linha pequena aparece: `NA CONTA  147` (as mortes da campanha inteira). Cada morte soma ali com um tique seco.
- **Por que serve à história:** a contagem vai de troféu a dívida; o "na conta" é o cansaço em número.
- **Por que é do Hotline Rio:** é a comanda do garçom que o Caio era, não um placar de arcade.
- **Custo:** médio. O total da campanha precisa de um campo novo no save (`campaign.gd:60`), só de apresentação.

**A2. O objetivo que é interceptado**
- **Hoje:** `ELIMINE TODOS` → `PEGUE A PISTA` → `exit_hint` (`hud.gd:218-223`).
- **Ato 1:** como está, com a gíria do JSON ("SAIA PELO BECO →").
- **Ato 2:** ao trocar, o texto chega como sinal de rádio: alguns caracteres aparecem trocados por blocos (`▒`) e se resolvem em 0,3 s; com `paranoia` alta, uma vez por noite o objetivo mostra por meio segundo uma linha que não é dele, em ciano (`ELE TÁ VENDO VOCÊ  — C.`), e volta.
- **Ato 3:** telegráfico, sem cor quente: `HOSTIS 03`, `PISTA`, `SAÍDA ↑`. Bone a 80%.
- **Por que serve à história:** no Ato 2 a própria tela deixa de ser confiável; no 3 ela vira relatório.
- **Por que é do Hotline Rio:** rádio-scanner e MARÉ são do mundo do jogo, não telefonema de secretária eletrônica.
- **Custo:** pequeno (o efeito de embaralhar é só texto; as linhas novas vão no `en.json`).

**A3. Fôlego, não barra de mana**
- **Hoje:** blocos ciano com `ESPECTRO / ATIVO / ESGOTADO` (`hud.gd:132-141`, `:243-248`).
- **Ato 1:** os blocos cheios "respiram" (escala vertical 1,0 ↔ 1,15 num seno lento) e tremem em degraus quando ativos, como a silhueta instável da bíblia (`narrativa.md:88-91`).
- **Ato 2:** comportamento atual; com `paranoia`, um bloco apagado pisca aceso por um quadro de vez em quando (falso positivo).
- **Ato 3:** sem respiração nem tremor: blocos firmes, ciano mais denso, gasto em degraus limpos.
- **Por que serve à história:** a bíblia diz que a barra é o fôlego e que o espectro amadurece; o HUD acompanha a mesma curva do modelo.
- **Por que é do Hotline Rio:** o espectro e o Avesso são a mecânica própria do jogo.
- **Custo:** pequeno.

**A4. A câmera que olha de volta**
- **Hoje:** só existe o `● REC` da noite 12 (`hud.gd:102-107`, `:255-261`).
- **Ato 1:** nada.
- **Ato 2:** com `paranoia > .4`, a cada 20-40 s, aparece por 0,6 s no canto superior direito um carimbo de câmera de segurança, `CAM 03  01/11  03:12` (a fita da CAM 03 é um marco do ato, `narrativa.md` seção 8), com linhas de varredura sobre o HUD. Na fase 6 (câmeras inimigas), o carimbo pode aparecer quando uma câmera estiver vendo o Caio, se a simulação já expuser isso; caso contrário, fica só ambiental.
- **Ato 3:** o carimbo vira o `● REC` permanente e discreto, como se o Caio já tivesse aceitado ser filmado; na noite 12 ele já existe e só ganha o sentido de fechamento.
- **Por que serve à história:** "elementos que vigiam" do Ato 2, sem um modo que liga.
- **Por que é do Hotline Rio:** CFTV de prédio comercial do Centro e a fita do IML, não VHS de Miami.
- **Custo:** pequeno (ambiental); médio se ligado ao estado das câmeras.

**A5. A pista conforme quem a guarda**
- **Hoje:** flash de câmera e `PISTA` em amarelo (`hud.gd:143-164`, `:167-173`).
- **Ato 1:** flash de câmera descartável; caption `PISTA!`.
- **Ato 2:** sem flash branco; a caixa entra como fax com cabeçalho `INTERCEPTADO  — C.` e o texto digitando em VT323.
- **Ato 3:** ficha numerada: `PROVA Nº 07` (a bíblia fala em fitas e provas numeradas no quadro do Ato 3), sem tremor.
- **Custo:** pequeno.

**A6. Limpeza para o jogador:** `MODO DEUS` aparece no HUD (`hud.gd:98-101`) e na linha de controles do briefing (`mission_screen.gd:79`). Sugiro deixá-lo só numa build de desenvolvimento, como o seletor de fases (`level_select.gd`). Custo pequeno.

### B. Menu principal (`main_menu.gd`, `menu_backdrop.gd`)

**B1. O letreiro que envelhece com o save**
- **Hoje:** "HOTLINE RIO" em Bungee com sombra rosa que treme às vezes e a linha "Um tiro mata. Ninguém viu nada." (`main_menu.gd:55-66`). O fundo é sempre a Lapa do Ato 1 (`menu_backdrop.gd:2-15`).
- **Ato 1 (save novo ou noites 1-4):** como está.
- **Ato 2:** a sombra às vezes descola e vira uma cópia ciano deslocada (o letreiro com fantasma); a linha de tom vira "Um tiro mata. Alguém viu tudo."
- **Ato 3:** uma letra do letreiro fica **queimada** (o "O" de RIO apagado, aceso só de vez em quando, como neon de motel com defeito); cores com a saturação do `ui_mood`; a linha vira "Um tiro mata. Eu já nem conto."
- **Por que serve à história:** o menu é a primeira coisa que o jogador vê ao voltar; ele lembra onde a história está sem dizer.
- **Por que é do Hotline Rio:** o letreiro de neon com letra queimada é da Lapa e da Mem de Sá, não da tipografia de Miami.
- **Custo:** pequeno. Trocar o fundo 3D por ato (a Guardião, o quarto revirado) seria **grande** e fica como ideia futura.

**B2. Carregar jogo com data de plantão**
- **Hoje:** número da noite ao lado da opção (README, "Menu principal").
- **Proposta:** `CARREGAR  ·  NOITE 05  ·  26/11` em VT323, como o relógio do plantão. No Ato 3, com a hora (o `place` do Ato 3 já ganha hora).
- **Custo:** pequeno.

### C. Tela de missão e pausa (`mission_screen.gd`)

A bíblia já muda a voz do briefing (diário → dossiê da Celeste → plano operacional, `narrativa.md:105-109`). A proposta é a tela mudar junto.

**C1. Três suportes para o mesmo cartão**
- **Hoje:** lugar em ciano digitando, título com sombra rosa tremendo, fio rosa, corpo digitando a 55 caracteres/s (`mission_screen.gd:9-14`, `:139-157`).
- **Ato 1 (diário):** como está, um pouco mais rápido (65 c/s) e com o tremor do título mais frequente. O fio rosa se desenha como um traço de caneta, levemente torto.
- **Ato 2 (dossiê):** o corpo digita em VT323 ciano; duas ou três palavras saem cobertas por **tarja preta** que só se levanta depois que a linha termina (informação que some e volta); a assinatura "— C." chega por último, sozinha, com um bipe. O fio deixa de ser rosa e vira uma linha tracejada de fax.
- **Ato 3 (plano):** sem tremor no título; ritmo de 40 c/s, constante; antes do corpo, um cabeçalho fixo `HOSTIS 14  ·  SEM SOMBRA 3  ·  02:40` (dados que a bíblia já prevê no texto do briefing); o fio vira cinza-osso.
- **Por que serve à história:** o jogador "lê" o estado do Caio pela forma, antes do conteúdo.
- **Por que é do Hotline Rio:** caderno, dossiê com tarja e plano de operação são os três personagens que escrevem o briefing aqui.
- **Custo:** médio. As tarjas podem ser marcadas no próprio JSON (por exemplo, `[[palavra]]`), mantendo o texto traduzível pelo `en.json`.

**C2. A pausa fala com o ato**
- **Hoje:** "Respira. A próxima esquina pode esperar." (`mission_screen.gd:124`).
- **Ato 2:** "Respira. Tem alguém ouvindo?" **Ato 3:** "Respira. Falta pouco." Custo pequeno.

**C3. Controles só quando precisa**
- **Hoje:** a linha de controles aparece em todo briefing (`mission_screen.gd:79-80`).
- **Proposta:** completa nas noites 1-2, só as teclas novas quando aparece uma ferramenta nova, ausente no Ato 3 (continua na pausa). Profissional não lê manual. Custo pequeno.

### D. Tela de resultado (`result_screen.gd`)

**D1. "A CONTA" → "RELATÓRIO" → "AUTO DE DESPEJO"**
- **Hoje:** título ondulando com cores trocando, linhas de contagem que deslizam e rolam, nota S-D gigante à direita (`result_screen.gd:124-158`, `:166`, `:218-264`). É o trecho que mais lembra o original (seção 1).
- **Ato 1, "A CONTA":** o título é arremessado como hoje, mas sem `[wave]`: ele entra numa **placa de lâmpadas** cujas bolinhas correm em volta (letreiro de botequim). As linhas de contagem viram itens de uma **comanda** (papel amarelado em perspectiva leve, VT323 como caneta): `ELIMINADOS ....... 08/08`, `TEMPO ....... 00:52.3`. Os pontos viram `TOTAL`. A nota não é uma letra gigante: é escrita a pincel atômico no pé da comanda e **circulada** com um risco que se desenha (ver a nota sobre a escala abaixo). Frase: "ATÉ A PRÓXIMA." / "SAIDEIRA!".
- **Ato 2, "RELATÓRIO":** a comanda vira uma folha de dossiê; ao rolar, cada número passa por uma tarja preta que se levanta; num dos números, por 0,15 s, aparece um valor errado antes do certo. A nota vem com um carimbo `CONFERIDO` que bate torto. Canto inferior com `CAM 03` em timestamp. O shader `result_fx` troca a tinta roxa por um azul de monitor de vigilância.
- **Ato 3, "AUTO DE DESPEJO":** formulário de cartório, fundo quase cinza, sem lâmpadas, sem flash branco, linhas que entram mais devagar (SLIDE 0,15 → 0,35). A nota é um **carimbo** de cartório que bate uma vez, sem rebote. Nova linha no fim: `NA CONTA ..... 147`. Frase: "MAIS UM." O `cleared` de cada fase já vai para "CONDOMÍNIO DESPEJADO" e casa com o formulário.
- **Por que serve à história:** a mesma tela, três documentos: a conta do bar, o dossiê vigiado e o papel frio do despejo. Comemoração vira burocracia.
- **Por que é do Hotline Rio:** comanda de botequim, tarja de dossiê e carimbo de cartório usam o vocabulário do imóvel da bíblia; some a onda de cores e a letra gigante.
- **Custo:** grande para os três suportes; médio se fizer só o Ato 1 (comanda + placa de lâmpadas) e aplicar o `ui_mood` às cores e ao ritmo nos outros.
- **Nota sobre a escala:** manter S/A/B/C/D é o mais simples. Uma alternativa mais própria, para o dono decidir, é trocar as letras por palavras de cada suporte (Ato 1: `CASA CHEIA / BOA / MORNA / FRACA / FIADO`; Ato 3: carimbos `DEFERIDO / INDEFERIDO`). Só muda o rótulo; os limites de pontos (`:24`) ficam iguais.

**D2. Morte com a voz do ato**
- **Hoje:** "FIM DA NOITE" e frases de gíria aleatórias (`result_screen.gd:13`, `:124-134`).
- **Ato 1:** as atuais ("DEU RUIM.", "FOI DE ARRASTA.").
- **Ato 2:** "ELES JÁ SABIAM.", "TINHA CÂMERA.", "QUEM TE VENDEU?", "NÃO ERA GENTE."
- **Ato 3:** título "AINDA NÃO." no lugar de "FIM DA NOITE"; frases "LEVANTA.", "DE NOVO.", "VOCÊ JÁ MORREU UMA VEZ." Cores de morte com a saturação do `ui_mood`.
- **Por que serve à história:** ele já voltou da morte uma vez; no Ato 3 morrer é rotina.
- **Custo:** pequeno (listas por ato, todas no `en.json`).

### E. Cartões de ato (`act_card.gd`)

**E1. O inimigo toma a palavra**
- **Hoje:** o briefing sobre preto (`act_card.gd:9-19`), com o mesmo visual da missão.
- **Fim do Ato 1 ("O SÍNDICO AGRADECE"):** em vez do neon, um **cartão de visita** creme com letras douradas em serifa, centralizado, sem tremor, sem fio rosa. É a primeira vez que a interface do jogo não é do Caio. Ao fechar, o neon volta com um estalo.
- **Fim do Ato 2 ("Boa noite, inquilino"):** uma **circular de condomínio** em A4 presa com fita adesiva (`COMUNICADO AOS CONDÔMINOS`), em fonte de impressora; o texto do `act_end` digita como se impresso; nas bordas, o ciano do Caio vaza por baixo do papel como mancha.
- **Fim do jogo:** fundo preto, texto cor de osso, sem neon, sem som de impacto, digitação lenta.
- **Abertura de ato (novo, opcional):** uma **placa de rua** azul da prefeitura do Rio, `ATO 2  ·  O CONDOMÍNIO`, com a linha de bairros embaixo (`Caju · Centro · Lagoa · Ilha Fiscal`), entrando antes do primeiro briefing do ato.
- **Por que serve à história:** a virada de ato é quando o mundo do Castelar invade o do Caio; a troca de suporte mostra isso sem texto extra.
- **Por que é do Hotline Rio:** cartão de visita da elite, circular de condomínio e placa de logradouro carioca no lugar de um cartão de capítulo tipográfico.
- **Custo:** médio (fins de ato); a placa de abertura é média e pede um campo novo no JSON da primeira fase do ato.

### F. Noticiários (`news_card.gd` e programas em 3D de `intro.gd`)

**F1. O pacote gráfico muda de dono**
- **Hoje:** "ALERTA RIO" em vermelho e amarelo, `AO VIVO`, tarja de manchete, letreiro rolando e legenda oculta (`news_card.gd:200-252`), com chiado de CRT (`:100`).
- **Ato 1:** como está, sensacionalista e ruidoso.
- **Ato 2:** a MARÉ invade: no letreiro rolando, por um instante algumas letras trocam e formam outra frase (`NÃO TEM SOMBRA`) antes de voltar; a tarja de nome do Castelar pisca por um quadro com outro texto. O chiado do CRT sobe nos cortes.
- **Ato 3:** o "Alerta Rio" passa a usar o azul da campanha "ORDEM NA CASA" na faixa inferior: a emissora escolheu lado, como a bíblia descreve. A legenda oculta atrasa e repete palavras.
- **Letreiro com a conta:** em qualquer ato, o letreiro pode trazer o total da campanha ("VIGILANTE JÁ SOMA 147 MORTES NA CIDADE"), a mesma conta do HUD dita pela voz da cidade.
- **Por que serve à história:** o "Alerta Rio" é o coro grego; o pacote gráfico é a roupa do coro.
- **Por que é do Hotline Rio:** plantão policial da TV aberta brasileira, e não fita VHS de Miami.
- **Custo:** médio (os textos e cores podem vir do JSON do programa, que já tem `bug`, `ticker` e segmentos condicionais `when`, `news_card.gd:65-67`).

### G. Cursor (`main.gd:497-513`, `:939-948`)

**G1. A mira que muda de mão**
- **Hoje:** cruz amarela sem sombreamento, que abre no tiro, gira na recarga; cada morte deixa um X vermelho por 0,45 s.
- **Ato 1:** cruz amarela quente, abertura do tiro um pouco maior (só a escala do marcador, `:939`, não a dispersão).
- **Ato 2:** quando um inimigo passa a perseguir o Caio (o "!" de `:895`), a cruz ganha por 0,3 s um anel vermelho fino, como foco de câmera. O X sobre Inquilinos sai azul-preto, como o sangue deles.
- **Ato 3:** cruz mais fina, cor de osso, quase sem abertura; o X vira um risco curto que fica 1 s em vez de 0,45 s.
- **Por que serve à história:** a mão firme do profissional e as mortes que demoram a sair do chão.
- **Por que é do Hotline Rio:** liga a mira ao sangue de tinta e à regra da casca, que são deste jogo.
- **Custo:** pequeno.

### H. Feedback de combate (`combat_effects.gd`, `main.gd`)

**H1. Juice que se apaga**
- **Hoje:** congelamento no golpe, zoom e câmera lenta, empurrão da câmera, tremor do HUD, música abafada na câmera lenta, a última morte com pancada e a música voltando "abrindo" (README, "Sensação de impacto").
- **Ato 1:** tremor do HUD e flash cheios.
- **Ato 2:** igual, mais uma linha de varredura que atravessa a tela no congelamento das mortes de Inquilinos.
- **Ato 3:** tremor do HUD pela metade, sem flash nas mortes comuns; na última morte, a música **não volta abrindo**: fica abafada até a saída, só ambiente e passos. Silêncio onde antes havia festa.
- **Por que serve à história:** o cansaço é ouvido antes de ser visto.
- **Por que é do Hotline Rio:** a trilha de bossa e partido-alto do jogo é que some; não há empréstimo do original.
- **Custo:** pequeno para tremor e flash; pequeno para a música (só o volume na saída, `main.gd:223` e vizinhos).
- **Toca na jogabilidade:** encurtar ou alongar a câmera lenta e o congelamento por ato (`main.gd:28-30`, `:1006-1013`) muda o tempo do mundo e, portanto, o jogo. Fica para o dono decidir; a proposta acima não mexe neles.

---

## 4. Esboços

### HUD

```
ATO 1 (noite 2)                                         ATO 2 (noite 6)                                          ATO 3 (noite 11)
+---------------------------------------------+        +---------------------------------------------+        +---------------------------------------------+
| ELIMINADOS            ELIMINE TODOS         |        | ELIMINADOS        ELIM▒NE T▒DOS             |        | HOSTIS 03                      PISTA        |
| 05/11  ////  /                              |        | ??/14  ////  ////  (azul-preto)             |        | ////  ////  //                              |
| 00:41.2                                     |        | 01:07.9            CAM 03  01/11  03:12 ░░  |        | NA CONTA  147                       ● REC   |
|                                             |        |                                             |        |                                             |
|          (cores cheias, tremor forte)       |        |     (letreiro piscando, ruído às vezes)     |        |       (cores lavadas, nada pula)            |
|                                             |        |                                             |        |                                             |
| F  KATANA                                   |        | F  KATANA                                   |        | F  KATANA                                   |
| PISTOLA                          ESPECTRO   |        | FUZIL                            ESPECTRO   |        | PISTOLA                          ESPECTRO   |
| 09 /12                                      |        | 22 /30                                      |        | 07 /12                                      |
| ████████▒▒▒▒       ~█~█~█~█~█~█~ (respira)  |        | ██████████▒▒       ██████▒█▒▒▒▒ (falso)    |        | ███████▒▒▒▒▒       ████████████ (firme)     |
+---------------------------------------------+        +---------------------------------------------+        +---------------------------------------------+
```

### Tela de resultado

```
ATO 1 — A CONTA                     ATO 2 — RELATÓRIO                   ATO 3 — AUTO DE DESPEJO
 o o o o o o o o o o o o            ┌───────────────────────────┐       ┌───────────────────────────┐
 o    BAR LIMPO       o             │ DOSSIÊ  —  GUARDIÃO       │       │ AUTO DE DESPEJO  Nº 10     │
 o o o o o o o o o o o o            │ ELIMINADOS ..... ████ 14  │       │ IMÓVEL: MIRANTE DO JOÁ    │
  ┌─ comanda ─────────────┐         │ TEMPO ....... ████ 01:31  │       │ ELIMINADOS ........ 15/15 │
  │ ELIMINADOS ..... 08/08│         │ TENTATIVA .........  03   │       │ TEMPO ........... 02:04.0 │
  │ TEMPO ....... 00:52.3 │         │ TOTAL ........... 016400  │       │ TENTATIVA ............ 05 │
  │ TENTATIVA ........ 01 │         │            [CONFERIDO] B  │       │ NA CONTA ............ 147 │
  │ TOTAL ........ 015700 │         │ CAM 03  20/11  02:58      │       │                ┌────────┐ │
  │          ( S )  ←circ │         └───────────────────────────┘       │                │DEFERIDO│ │
  └───────────────────────┘          "ELES JÁ SABIAM."  (se morte)      │                └────────┘ │
       "SAIDEIRA!"                                                       └───────────────────────────┘
                                                                                   "MAIS UM."
```

### Tela de missão

```
ATO 1 — diário                       ATO 2 — dossiê                        ATO 3 — plano
02  LAVRADIO  —  GAFIEIRA            06  CENTRO  —  GUARDIÃO               11  BOTAFOGO  —  02:40
ÚLTIMA DANÇA  (sombra rosa treme)    ÚLTIMO TURNO                          ÚLTIMA CONSULTA
~~~~~~~~~~~~~ (caneta)               - - - - - - - - (fax)                 ─────────────── (cinza)
O Gravata cobra a gafieira...        Eles têm ████████ nas paredes.        HOSTIS 14 · SEM SOMBRA 3 · 02:40
                                     Já sabem que você ████████.           ALVO: ...
▸ ENTRAR NA GAFIEIRA  →                                         — C.       ▸ ENTRAR  →
WASD MOVE · MOUSE MIRA ...           ▸ ENTRAR NA GUARDIÃO  →               (sem linha de controles)
```

### Menu principal

```
ATO 1                          ATO 2                            ATO 3
LAPA / RIO DE JANEIRO          LAPA / RIO DE JANEIRO            LAPA / RIO DE JANEIRO
HOTLINE RIO                    HOTLINE RIO  (sombra ciano solta) HOTLINE RI○  (O queimado)
Um tiro mata.                  Um tiro mata.                    Um tiro mata.
Ninguém viu nada.              Alguém viu tudo.                 Eu já nem conto.
```

---

## 5. Textos novos para o `en.json`

Todas as frases novas passam por `tr()` e entram no `assets/lang/en.json` com o português como chave. Sugestões:

| Português | Inglês |
| --- | --- |
| NA CONTA | ON THE TAB |
| SAIDEIRA! | ONE FOR THE ROAD! |
| INTERCEPTADO | INTERCEPTED |
| PROVA Nº %02d | EVIDENCE #%02d |
| CONFERIDO | VERIFIED |
| AUTO DE DESPEJO | EVICTION NOTICE |
| DEFERIDO / INDEFERIDO | GRANTED / DENIED |
| ELES JÁ SABIAM. | THEY ALREADY KNEW. |
| TINHA CÂMERA. | THERE WAS A CAMERA. |
| QUEM TE VENDEU? | WHO SOLD YOU OUT? |
| NÃO ERA GENTE. | IT WASN'T PEOPLE. |
| AINDA NÃO. | NOT YET. |
| LEVANTA. | GET UP. |
| VOCÊ JÁ MORREU UMA VEZ. | YOU'VE DIED ONCE ALREADY. |
| MAIS UM. | ONE MORE. |
| Um tiro mata. Alguém viu tudo. | One shot kills. Someone saw everything. |
| Um tiro mata. Eu já nem conto. | One shot kills. I stopped counting. |
| Respira. Tem alguém ouvindo? | Breathe. Is someone listening? |
| Respira. Falta pouco. | Breathe. Almost there. |
| COMUNICADO AOS CONDÔMINOS | NOTICE TO RESIDENTS |
| ELE TÁ VENDO VOCÊ | HE CAN SEE YOU |

Regra lembrada: azulejo português, se usado, fica em molduras de interface e nunca vira padrão de piso.

---

## 6. As 5 propostas de maior impacto por custo

1. **Humor da interface (seção 2) + paleta e tremor por noite.** Pequeno. Sozinho já faz o jogo inteiro desbotar de forma gradual, e destrava todas as outras.
2. **Textos por ato: mortes, pausa, linha do menu, objetivo telegráfico (D2, C2, B1, A2).** Pequeno. Só listas e `en.json`, e o jogador sente a virada de humor em cada morte.
3. **Tela de resultado sem onda nem nota gigante: "A CONTA" no Ato 1, com o `ui_mood` cuidando dos outros atos (D1, versão média).** Médio. Maior ganho de identidade e tira a semelhança mais visível com o original.
4. **O contador que pesa: riscos de comanda e "NA CONTA" no HUD do Ato 3 e no letreiro do noticiário (A1, F1).** Médio. Transforma a pontuação em culpa sem mexer em regra nenhuma.
5. **Interceptação no Ato 2: tarjas no briefing, objetivo com ruído e o carimbo CAM 03 no HUD (C1, A2, A4).** Médio. É o que dá à paranoia uma cara própria, ligada à fita da CAM 03 e à MARÉ.

Logo atrás: a mira por ato (G1, pequena) e os cartões de fim de ato com a voz do inimigo (E1, média).
