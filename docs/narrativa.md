# Hotline Rio — Bíblia de narrativa

Documento de história e design narrativo. Ele parte do que o projeto já tem (quatro fases em JSON, noticiário de abertura, quarto entre as noites, katana, espectro, cinco armas) e propõe o que falta. Nada aqui muda o layout das fases existentes.

---

## 0. O que já existe no código (ponto de partida)

Confirmado lendo `README.md`, `assets/level*.json` e `scripts/*.gd`:

| Área | Estado atual |
| --- | --- |
| **Fases** | Quatro arquivos JSON em `Simulation.LEVELS`. Cada um traz `scene`, `briefing` (`place`, `title`, `body`, `button`), `cleared`, `exit_hint`, `mission`, `lamps`, `bounds`, `start`, `entrance`, `exit`, `solids` e `enemies` (`pose`, `p`, `patrol`, `reaction`, `angle`). Os títulos seguem o padrão "ÚLTIMO/ÚLTIMA ___". Depois da fase 4 o jogo volta para a 1 (`(sim.level+1) % LEVELS.size()` em `main.gd`). |
| **Pistola** | Pente de 12, recarga de 0,75 s, cadência de 0,26 s (231 tiros/min), bala a 29 m/s. Reserva infinita. Um tiro alerta todo inimigo vivo num raio de 9,25 m (`shoot()`). |
| **Katana (F)** | A troca leva 0,22 s. Um corte a cada 0,45 s, que acerta 0,2 s depois do clique. Mata todos num arco de ±65° (`arc` 1,13 rad) e até 1,8 m, sem parede no meio. É silenciosa (não chama `alert`). Não funciona como espectro (`slash()` e `_strike()` retornam se `phasing`). Sempre desmembra. |
| **Espectro (Shift, Q ou botão direito)** | Mana de 100 que drena 34/s (cerca de 2,94 s). Precisa de pelo menos 12 para ativar. Depois de 0,8 s fora do espectro, recupera 18/s. Ao esgotar, trava até soltar o botão. Atravessa sólidos e balas. Não atira nem recarrega. Se acabar dentro de um sólido, volta ao ponto livre mais próximo. **Os inimigos continuam vendo o herói nesse estado**, porque a regra `sees` não testa `phasing`: só as balas atravessam. |
| **Abate** | Zoom de 0,08 s, câmera lenta a 30% por 0,4 s e zoom saindo em 0,35 s. A morte do herói tem um ritmo próprio (2 s a 20%). |
| **Desmembramento** | É sorteado **na apresentação** (`CombatEffects.roll_gore_variant`, com um gerador próprio), por arma: pistola e submetralhadora deixam o corpo inteiro em 55% dos casos; escopeta e fuzil sempre arrancam algo; a minigun sempre corta ao meio; a katana sempre arranca algo. A simulação não sabe o resultado. |
| **Armas** | Pistola, submetralhadora, escopeta, fuzil e minigun, **todas disponíveis desde o começo** na estante do quarto. Os inimigos só usam pistola. |
| **Modo deus (G)** | Só para depuração. Fica fora da história. |
| **Noticiário** | `intro.gd`: o "Alerta Rio" da TV TELERIO, com 32 s, só antes da fase 1. Câmera de segurança "CAM 03 BAR DO ARCO" em 26/10/2026 às 23:47, o fantasma azul atravessando o balcão, uma testemunha, o "TEN. SOUZA — POLÍCIA MILITAR", oito suspeitos e o letreiro "BONDE DE SANTA TERESA SUSPENSO". Plano, legenda e letreiro são constantes no código. |
| **Quarto** | `room.gd`: um apartamento na Rua do Lavradio, "4:12 DA MANHÃ" fixo. Tem quatro hotspots: computador, estante de armas, quadro de investigação e porta. |
| **Investigação** | **Não existe como sistema.** O quadro é uma decoração fixa feita em `tools/build_room.py`: 12 cartões tirados de um atlas de 8 células (recorte, foto do bar, polaroide do fantasma, mapa da Lapa, post-it, foto 3×4, dossiê carimbado e os Arcos) e 13 fios fixos. Clicar no quadro abre o painel "MISSÕES", que lista o campo `mission` de cada JSON e uma linha "??? — siga os fios vermelhos — EM BREVE". Não há pistas coletáveis nem noticiário entre as fases. |
| **Upgrades** | **Não existem.** O computador abre "LAPANET — LOJA", uma prévia com quatro itens a "R$ ---": COLETE IMPROVISADO, CARREGADOR ESTENDIDO, ESPECTRO +1 s e PASSOS SILENCIOSOS. Não há dinheiro: os pontos da tela de vitória "são só exibidos". |
| **Progresso salvo** | **Não existe.** Arma, katana e modo deus duram só enquanto o jogo está aberto. |
| **Modelos** | Herói: `Character_01`, de camisa social branca, jeans e barba por fazer. Inimigos: `Character_04` (jaqueta marrom) e `Character_08` (camisa azul), alternados. Já adaptados ao rig UAL na abertura, e reaproveitáveis: `Character_29` (terno e gravata vermelha), `Character_29_Female` e `Character_17_Police`. |

Tudo o que este documento pede além disso aparece marcado como **[novo sistema]** e está detalhado no plano de implementação (seção 9).

---

## 1. Premissa e tom

**Logline.** Um garçom da Lapa, morto num beco e de volta com o poder de atravessar paredes por três segundos, segue o dinheiro de um agiota da noite carioca até descobrir que a elite do Rio está sendo ocupada por coisas que vestem gente, e que a mais antiga delas é candidata a governador com a promessa de acabar com o crime.

**Tom.** Neo-noir tropical. Violência seca e rápida, no registro de "um tiro mata", com câmera lenta que dá peso a cada morte. Por baixo, melancolia e sátira:
- **A cidade é vítima, não vilã.** Lapa, gafieira, ateliês de Santa Teresa, o bonde, o porto: são lugares vivos, de gente que trabalha à noite. O jogo nunca ri deles.
- **O mal sobe, não desce.** O agiota do Ato 1 é miserável perto de quem o aluga. Os monstros moram na Zona Sul, no Joá, nos estúdios de TV e nos palanques, e não no morro. A favela não aparece como cenário de tiroteio.
- **Nada real é acusado.** Nenhuma facção, milícia, partido, emissora, empresa, clube ou político real. Toda organização é fictícia ("a firma do Gravata", "Pilar Administração", "Guardião Segurança", "Condomínio", "TeleRio"). Os bairros e os marcos são reais; os prédios onde há crime são fictícios ou usados num evento fictício, como o baile alugado na Ilha Fiscal. A Polícia Militar aparece só como instituição genérica (o Ten. Souza da abertura), sem batalhão nem unidade real.
- **Sátira de programa policial.** O "Alerta Rio" é o coro grego: grita, distorce e muda de lado conforme quem manda. A legenda oculta em caixa alta é a voz da cidade.
- **Horror discreto.** Os Inquilinos não são criaturas de tentáculo na tela. São gente sem sombra, que nunca bebe, que sangra preto. O horror está no detalhe que a câmera de cima consegue mostrar.

**Palavra-chave do mundo: o imóvel.** O vocabulário dos vilões é o do mercado imobiliário carioca: os corpos são "cascas" ou "imóveis", quem ocupa é "inquilino", o chefe é o "Síndico", a rede é o "Condomínio", tirar alguém é "despejo". Isso amarra a sátira (especulação, gentrificação da Lapa e de Santa Teresa, o bonde parado para valorizar terreno) ao sobrenatural.

---

## 2. Protagonista

### Quem é

**Caio Bento**, 27 anos, nascido e criado na Rua do Lavradio. Garçom do **Bar do Arco** havia seis anos. Filho de **Seu Bento**, amolador e cuteleiro que tinha uma portinha no Lavradio e morreu quando Caio tinha 19. Mora no mesmo quarto-e-sala em cima da antiga oficina do pai (o quarto do jogo, "RUA DO LAVRADIO, LAPA").

A camisa social branca e o jeans do modelo `Character_01` são o **uniforme de garçom** do Bar do Arco. No Ato 1 ele luta com a roupa com que morreu.

### A noite do beco (origem do espectro)

Em **12 de outubro de 2026**, fechando o bar, Caio levou o lixo para o beco da direita (a saída da fase 1). Lá ele viu **Russo**, o cobrador do Gravata, entregando um envelope a um homem de terno, **Edmundo Prates**. Prates virou o rosto para ele, e o rosto **dobrou como papel molhado**: por um segundo havia outra coisa olhando por trás. Russo atirou no peito de Caio.

Caio ficou morto cerca de três minutos no chão do beco. Nesse tempo esteve no **Avesso**: o lado de baixo da cidade, onde as paredes são neblina, as pessoas são calor e algumas delas têm **outra coisa dobrada dentro**. Uma dessas coisas tentou entrar nele pela ferida. Caio voltou antes que ela terminasse de entrar. Ela ficou presa na porta.

Quando acordou, a pistola de Russo estava no chão ao lado dele: o assassino tinha fugido apavorado, depois de ver o corpo ficar azul e afundar na parede.

**O que isso justifica nas mecânicas:**
- **3 segundos:** o espectro é **fôlego**. Caio só aguenta ficar no Avesso enquanto prende a respiração, e a barra de energia do HUD é esse fôlego. Mais tempo exige treino (upgrades "Fôlego").
- **Não pode atirar nem recarregar:** no Avesso, a matéria não o toca e ele não toca a matéria. A bala atravessa os dois sentidos.
- **Os inimigos ainda o veem:** veem um vulto azul, igual ao da CAM 03. Por isso atiram, e as balas passam.
- **A franja ciano da sombra** (`actor_look.gd`, `HERO_FRINGE`) é o resíduo do Avesso preso nele. Como espectro, a sombra quase some: **o que pertence ao Avesso não faz sombra**. Essa regra vira a principal pista visual dos Inquilinos.
- **A katana:** a única lâmina que Seu Bento forjou e nunca vendeu. Ficava enrolada num pano em cima do guarda-roupa. É ela que Caio pega na noite da abertura.

### Por que investiga

1. **Para entender o que viu.** O rosto que dobrou. A coisa na porta.
2. **Pelo bar.** O Gravata cobra uma "taxa da noite" de cada bar, gafieira e ateliê da Lapa e de Santa Teresa. Seu Arlindo, dono do Bar do Arco, foi espancado quando atrasou.
3. **Por medo do que ele mesmo é.** A partir do Ato 2 ele percebe que o poder é um pedaço *deles*. Essa dúvida move o final.

### Evolução: amador → profissional

A regra de design: **a cada ato Caio sabe mais antes de entrar, faz menos barulho e erra menos**. O poder não o deixa mais resistente (um tiro continua matando); o que melhora é a informação, o controle do espectro e a escolha de ferramenta.

#### Camada visual

| Ato | Roupa e equipamento | O que exige |
| --- | --- | --- |
| **1 — Amador** | O uniforme de garçom: camisa branca de manga comprida, jeans, tênis. **Mancha de sangue seco no peito** e um furo na camisa (a noite do beco). Katana na mão, sem bainha: ele a carrega como quem carrega um pedaço de pau. Pistola enfiada na cintura. | Só uma **variação de textura** de `hero_Character_01.png` (mancha e furo pintados no peito). Mesmo modelo. |
| **2 — Em formação** | Camisa preta, jeans escuro, **luvas pretas** (as mãos pintadas de preto na textura), **bainha da katana nas costas**, coldre. Na fase 8 ele volta de propósito ao **dólmã branco de garçom** para se infiltrar no baile. | **Textura** `hero_act2.png` (mesma malha). **Malha nova pequena:** a bainha, presa ao osso `spine_03` como as armas são presas ao punho. Textura do dólmã: `hero_waiter.png`. |
| **3 — Profissional** | **Terno preto e gravata preta** (o terno do enterro do pai), luvas, bainha nas costas e um **fone de rádio** na orelha. Parece um dos seguranças da elite, e essa é a ideia. | **Textura** `hero_act3.png`. **Gravata:** reaproveitar a técnica da gravata vermelha do apresentador em `build_intro.py` (malha presa ao osso do peito), em preto. Um sobretudo ou colete tático pediria **modelo novo** com pele; fica fora do escopo mínimo. |

O espectro também amadurece (apresentação em `actor_visual.gd` e `actor_look.gd`):
- **Ato 1:** a tremulação em degraus fica mais forte e a silhueta, instável.
- **Ato 2:** o comportamento atual.
- **Ato 3:** a tremulação fica mais contida e o ciano mais firme. O rastro fantasma fica mais curto e limpo.

#### Camada de jogabilidade

| Ato | Ferramentas no fim do ato | O que ele faz melhor |
| --- | --- | --- |
| 1 | Pistola, katana, escopeta, submetralhadora. Fôlego I. Rádio-scanner. | Aprende que o espectro é **fuga e reposicionamento**, não ataque. Aprende a chegar por trás com a katana. |
| 2 | + Olho do Avesso, Mão do Avesso, fuzil, Recuperação, Véu. Encomendas da Celeste (carregador, sola de borracha, bainha, silenciador). | Lê a sala antes de entrar (a planta no briefing). **Distingue gente de Inquilino.** Usa o espectro como arma, mas só contra o que vive no Avesso. |
| 3 | + Corte de saída, credencial de imprensa, minigun, Fôlego II. | Entra sabendo **quem é o quê**. Encadeia espectro → corte. Escolhe a arma pela regra da casca (seção 4). |

Os números dos inimigos já carregam essa curva, e isso **só pede dados**: no Ato 1 as reações vão de 1,4 a 0,7 s e há muitas poses `drink`; no Ato 2, de 1,1 a 0,6 s, com mais patrulha e mais `phone`; no Ato 3, de 0,9 a 0,5 s, sem nenhum `drink` (ninguém relaxa mais perto dele).

#### Camada de apresentação

| Ato | Briefing | Quarto | Quadro | Inimigos e vítimas | Noticiário |
| --- | --- | --- | --- | --- | --- |
| 1 | **Primeira pessoa, diário.** Frases curtas e nervosas, com as dicas de controle. | Bagunçado: cama desfeita, avental do Bar do Arco na cadeira, garrafas, camisa ensanguentada na pia. | Poucos cartões, muitos "?". O mapa da Lapa. Fios para "N.V." | Relaxados: bebem, falam ao telefone. São pegos de surpresa: a pose do dia a dia cai na hora em que o veem. | "VIGILANTE FANTASMA ATERRORIZA A LAPA". Medo e curiosidade. |
| 2 | **Dossiê da Celeste, segunda pessoa**, assinado "— C.". Inclui a planta com os inimigos marcados (rádio-scanner). | Arrumado: o avental sai, entra o rádio ligado na mesa e um mapa do Rio inteiro. As armas penduradas por ordem. | Duas camadas: a firma (embaixo) e "O AVESSO" (em cima), com desenhos de silhuetas dobradas e a lista de desaparecidos. | Patrulham mais. Na fase 6 já esperam por ele: "ELE ATRAVESSA PAREDE" escrito no quadro branco da Guardião. | "FANTASMA AMEAÇA A CIDADE". Castelar aparece prometendo caçá-lo. |
| 3 | **Plano operacional, sem pessoa.** "ALVO:", contagem de hostis, quantos "sem sombra", hora (`place` passa a ter a hora). | Revirado pela Guardião no começo do ato e **reconstruído como sala de operações**: jornais cobrindo a janela, o quadro ocupando a parede, a foto do Castelar com os olhos recortados. | Organograma do Condomínio com nomes riscados em vermelho, o Síndico no topo e as fitas e provas numeradas. | Seguranças treinados, sem pose relaxada. Os humanos fogem quando o veem. | "FANTASMA: TERRORISTA OU HERÓI?" A emissora é o campo de batalha. |

A entrada a pé (`entrance`, já suportada) conta a mesma história:
- **Ato 1:** `"hold": 0.9`, `"speed": 1.2`. Ele hesita na porta.
- **Ato 2:** os valores padrão.
- **Ato 3:** `"hold": 0.2`, `"speed": 2.0`, `"pull_back": 1.1`. Entra decidido e a câmera abre mais rápido.

A tela de vitória também muda de registro. O `cleared` vai da gíria ("BAR LIMPO") ao relatório ("CENTRAL DESLIGADA") e ao despejo ("CONDOMÍNIO DESPEJADO").

---

## 3. Elenco de apoio

| Personagem | Papel | Onde aparece | Modelo |
| --- | --- | --- | --- |
| **Seu Arlindo Matos** | Dono do Bar do Arco, 70 anos. Pagava a taxa. É a razão humana do Ato 1. | Citado nos briefings. Aparece no final A reabrindo o bar. | Só em texto ou na tela final. |
| **Celeste Andrade** ("MARÉ" na LapaNet) | Perita legista aposentada à força do IML depois de denunciar **corpos que sumiam da gaveta**. Viu a fita da CAM 03 e reconheceu o "frio" no corpo do fantasma. É o contato no computador: dossiês, encomendas, teoria do Avesso. Nunca aparece em pessoa, só como texto no CRT. | A partir da fase 2, no computador do quarto. | Nenhum (texto). |
| **Ten. Elias Souza** | O tenente da abertura. Honesto e cansado. Caça o Fantasma no Ato 1, desconfia da Guardião no Ato 2 e no Ato 3 está marcado para "consulta" na Clínica Santa Aurora. | Noticiários. Fase 11 (pista opcional). Final. | `Character_17_Police` (já existe). |
| **Jairo Trovão** | Apresentador do "Alerta Rio" (o homem da gravata vermelha). Humano, comprado e com medo. No Ato 3 pode virar o aliado que põe a verdade no ar. | Todos os noticiários. Fase 9. Final A. | `Character_29` (já existe). |

---

## 4. Antagonistas

### 4.1 A cadeia

```
ÁLVARO CASTELAR — "o Síndico"            candidato a governador; Inquilino desde 1977
   └── O CONDOMÍNIO (conselho de 7 Proprietários: Vera Lis e outros)
         ├── TeleRio / "Alerta Rio"             a narrativa
         ├── Clínica Santa Aurora               onde gente vira casca
         ├── Guardião Segurança                 o braço armado (dono humano: Rufino Avelar)
         └── Pilar Administração de Imóveis     o dinheiro e os terrenos (diretor: Edmundo Prates, Inquilino)
               └── NESTOR "GRAVATA" VALADARES  a taxa da noite na Lapa e em Santa Teresa (humano)
                     ├── Russo     cobrador; atirou em Caio
                     └── Marreco   marchand da lavagem de dinheiro com quadros
```

### 4.2 Ato 1: Nestor "Gravata" Valadares

Agiota e dono da "taxa da noite": todo bar, gafieira e ateliê entre os Arcos e o Largo dos Guimarães paga, toda semana, para "não ter problema". Usa gravata em qualquer calor, e daí o apelido. **É humano, ganancioso e pequeno.** Paga 30% do que arrecada para a **Pilar Administração**, que lava o resto comprando quadros superfaturados no Casarão das Artes e usa os terrenos que ele "desocupa" (o bonde de Santa Teresa parado é coisa da Pilar: terreno parado ao lado de trilho vale menos para quem mora e mais para quem compra).

Ele não sabe o que a Pilar é. Sabe só que, quando atrasa o repasse, alguém da firma some e volta **diferente**. Morre na oficina dos bondes (fase 4) com o celular na mão.

### 4.3 Os Inquilinos

**O que são.** Seres do Avesso. Não têm corpo próprio no nosso lado. Para existir aqui precisam **ocupar um corpo humano**, que chamam de **casca**. A pessoa original não está mais lá: a casca é um imóvel vazio com outro morador. Eles envelhecem a casca devagar, mas não morrem de velhice. Preferem cascas com poder, porque casca rica é casca protegida.

**Regras (todas visíveis de cima):**

| Regra | Na ficção | Na tela |
| --- | --- | --- |
| **Sem sombra** | O que é do Avesso não faz sombra, como o herói como espectro. | O Inquilino **não tem a sombra de contato** sob o quadril (`actor_look.gd`). De cima, a figura "flutua" no piso. É sutil no Ato 1 e óbvia quando alguém aponta (a fase 2 deixa a frase no espelho). |
| **Nunca bebe, nunca come** | A casca não precisa. | Um Inquilino **nunca usa a pose `drink`**: só `arms`, `phone` ou a nova `hold` (segura a taça sem beber). Uma garrafa na mão quer dizer gente. |
| **Sangue preto** | Por dentro, a casca é oca e escura, "nanquim". | Manchas e gotas preto-azuladas em vez de vermelhas, e **pó escuro** no lugar das vísceras no desmembramento (cores parametrizadas em `combat_effects.gd`). |
| **Veem o Avesso** | Vivem nele. | Veem o herói como espectro, como os humanos, e continuam a vê-lo com o **Véu** (Ato 2), que cega os humanos. Isso também é uma pista: quem continua mirando no espectro não é gente. |
| **A câmera pega o Avesso** | É por isso que a CAM 03 filmou o fantasma. | As câmeras de segurança (fase 6) detectam o herói até como espectro. |
| **Revelados pelo Olho do Avesso** | Do lado de lá, a casca fica transparente e mostra a coisa dobrada dentro, comprida demais e com juntas a mais. | Como espectro, depois do upgrade "Olho do Avesso", os Inquilinos ganham um contorno **violeta** (troca de `rim_color` em `figure_rim.gdshader`) e um segundo passe de material escuro e ondulante. |

**Um tiro mata a casca. O que mora dentro sai.**

Para manter "um tiro mata" sem dar pontos de vida a ninguém:
1. Qualquer acerto mata a **casca**, como mata qualquer humano: zoom, câmera lenta, corpo no chão.
2. Se a casca morreu **inteira**, o Inquilino sai como uma **chama-sombra** (o "despejado"). Ela tem 2,5 s de vida e anda a 3 m/s até o **corpo inteiro mais próximo** num raio de 6 m: outro cadáver inteiro ou, na fase 11, um paciente vivo e sedado. Se chegar, o corpo **levanta** como inimigo novo, com reação de 0,6 s. Se não achar corpo, volta ao Avesso e some da fase.
3. **Casca rasgada não serve.** Se o corpo foi desmembrado (cabeça, braço, perna ou cortado ao meio), o Inquilino sai e se desfaz na hora, sem chama-sombra.

**Por que isso funciona com o que já existe:**
- O desmembramento por arma vira **escolha tática**. A katana sempre arranca algo, então é a arma "limpa" contra Inquilinos. Escopeta e fuzil sempre desmembram. A minigun sempre corta ao meio. A pistola e a submetralhadora deixam o corpo inteiro em 55% das vezes: é aí que a chama-sombra aparece.
- A resposta à chama-sombra é a **Mão do Avesso** (fase 6): como espectro, encostar nela a destrói. É o único "ataque" permitido no espectro, e só contra o que vive no Avesso. A regra "não se pode atirar como espectro" continua valendo.
- **Ressalva técnica:** hoje o sorteio do desmembramento é só apresentação. Para a regra da casca, ele precisa ir para a simulação (seção 9).

### 4.4 Os Proprietários (Ato 2 tardio e Ato 3)

São os Inquilinos antigos, do conselho do Condomínio. Vestem "cascas de grife" (os modelos de terno `Character_29` e `Character_29_Female`, com variação de textura).

**A regra:** eles têm **o mesmo poder do herói**. Entram no Avesso por até 1,5 s, atravessam parede e bala, e **também não atiram** nesse estado. Antes de entrar, **piscam** por 0,3 s (o contorno tremula em violeta): é o aviso para o jogador. A IA usa o espectro para flanquear e para fugir quando é alvejada.

Continuam morrendo com um tiro, mas só fora do Avesso. A chama-sombra deles é mais rápida (4 m/s).

Na ficção, essa é a revelação do Ato 2: o poder de Caio é **deles**. O que ficou preso na porta naquela noite era um Inquilino, e foi o resíduo dele que ensinou o corpo de Caio a atravessar.

### 4.5 O chefe final: Álvaro Castelar, "o Síndico"

**Quem diz ser.** Álvaro Castelar, 71 anos, engenheiro, "o homem que reconstruiu o Porto", candidato ao governo do estado numa **eleição suplementar** fictícia, marcada para **13 de dezembro de 2026** depois da cassação do governador anterior (também fictício). Lidera as pesquisas desde que o Fantasma apareceu.

**Slogan:** **"ORDEM NA CASA."**
Bordão de campanha: *"Castelar: a casa é sua. A ordem é nossa."*
Plataforma: a **Operação Casa Limpa**, com "centros de triagem" para "todo suspeito de crime". Na verdade é uma fazenda de cascas: o Condomínio quer 40 mil corpos no primeiro ano, tirados de quem ninguém procura.

**O que é.** O Inquilino mais antigo do Rio. O Álvaro Castelar verdadeiro morreu num acidente de carro na Estrada do Joá em **1977**. O corpo nunca foi achado porque saiu andando. Os retratos de 1979 e as entrevistas de 1994 e 2010 mostram **o mesmo rosto** de hoje.

**Sinais na tela:**
- No palanque, a luz dos refletores bate nele e **não há sombra no chão**.
- Nos noticiários, o letreiro e os enquadramentos sempre o cortam da cintura para baixo.

**A luta (fase 12, "ÚLTIMA PROMESSA").** São três estágios numa planta só, com câmera de cima. Não há barra de vida em nenhum momento: cada acerto mata uma casca.

| Estágio | Espaço | Mecânica | Como termina |
| --- | --- | --- | --- |
| **1 — Palanque** | Salão do comício, com 24 civis (humanos) e 8 seguranças Inquilinos. | Castelar discursa. Ao primeiro tiro, os civis correm para as saídas e atrapalham as linhas de tiro (matar um civil conta como erro). Castelar é **Proprietário**: pisca, entra no Avesso, atravessa as divisórias do palco e tenta sair do campo de visão. | O primeiro acerto mata a casca de 1977. Fim da casca original. |
| **2 — A dança das cascas** | Sala de apuração, com telões e seis assessores (cascas vazias de reserva, sentados) e os corpos que sobraram do estágio 1. | Despejado, o Síndico salta **para o corpo inteiro mais próximo** em 1 s e levanta com contorno dourado (o "dono"). Toda casca que ele toma vira Proprietário. O jogador precisa: **rasgar as reservas** (katana, escopeta, fuzil ou minigun deixam o corpo inútil) **e** pegar a chama-sombra dele com a Mão do Avesso no trajeto. Se as cascas ficarem inteiras, a luta se alonga e fica mais difícil (a reação cai 0,05 s por salto). | Sem nenhum corpo inteiro ao alcance, ele foge **inteiro para o Avesso**, pelo poço do elevador, até o heliponto. |
| **3 — O Avesso** | Heliponto na cobertura, com vento, luzes de pouso e a Baía ao fundo. | O Síndico **só aparece para quem está no espectro**: fora dele, só uma distorção no ar. Ele também não ataca à distância (a regra do Avesso vale para ele). Se encostar no herói **fora do espectro**, entra nele: morte. O herói precisa entrar no espectro para vê-lo e persegui-lo, administrando o fôlego. As **luzes de pouso** recuperam 30 de mana uma vez cada (4 luzes). | **Corte de saída:** sair do espectro com a katana na mão a até 1,8 m dele dispara o corte instantâneo (seção 5). Um corte. Fim. |

Em todos os estágios, um tiro mata o herói. Os estágios são **checkpoints**: morrer no 3 recomeça no 3.

---

## 5. Sistema de upgrades narrativo

### Princípio de balanceamento

**Nada dá vida extra.** Nenhum upgrade deixa o herói aguentar um tiro. Todos mexem em **informação** (saber antes), **tempo** (fôlego, troca, recarga), **ruído** (quem ouve) ou **acesso** (o que o espectro alcança). Por isso o **COLETE IMPROVISADO** da prévia do computador **sai do jogo**: ele quebraria a regra central. No lugar dele entra a **POCHETE DE PENTES** (recarga mais rápida).

Há duas fontes:
- **História:** fixo, ganho ao terminar a fase. Toda fase dá um.
- **Encomendas da Celeste:** opcionais, pagas com **favores**. Cada pista opcional entregue vale 1 favor (veja a seção 6). Isso substitui o "R$ ---" da LapaNet: não existe dinheiro no jogo, e o pagamento é investigação.

### Armas (estante do quarto)

| Arma | Quando | Justificativa | Efeito em jogo (números de `Simulation.WEAPONS`) |
| --- | --- | --- | --- |
| **Pistola** | Início | A pistola de Russo, achada no chão do beco. | 12 tiros, 0,75 s de recarga. Corpo inteiro em 55% dos casos, então gera chama-sombra contra Inquilinos. |
| **Katana** | Início | A lâmina de Seu Bento. | Silenciosa, sempre desmembra: a arma "limpa" contra Inquilinos. |
| **Escopeta** | Depois da fase 1 | "A doze do Seu Arlindo", debaixo do balcão. | 7 chumbos, curto alcance, sempre desmembra. |
| **Submetralhadora** | Depois da fase 2 | O cofre do escritório da gafieira. | 30 tiros, espalha. Corpo inteiro em 55% dos casos. |
| **Fuzil** | Depois da fase 6 | A armaria da Guardião Segurança. | Preciso e rápido, sempre desmembra. |
| **Minigun** | Depois da fase 10 | A guarita do Condomínio no Joá ("segurança de condomínio com coisa de guerra"). | Lenta para girar, corta sempre ao meio: perfeita contra cascas e péssima para entrar escondido. |

Antes do desbloqueio, a arma aparece na estante como silhueta, com o painel mostrando "???".

### Poderes do espectro (o Avesso)

| Poder | Quando | Justificativa | Efeito (`simulation.gd`) |
| --- | --- | --- | --- |
| **Espectro** | Início | A noite do beco. | Drena 34/s (cerca de 2,94 s). Não atira. |
| **Fôlego I** | Depois da fase 3 | O caderno da escultora Iara Lessa ("o Avesso respira com você") e a tabela de apneia que a Celeste manda. | `MANA_DRAIN` 34 → 29 (cerca de 3,45 s). |
| **Olho do Avesso** | Depois da fase 5 | Caio vê a primeira chama-sombra e reconhece o frio do beco. Daí em diante, procura. | Como espectro, Inquilinos e Proprietários aparecem em violeta e as chamas-sombra ficam nítidas. |
| **Mão do Avesso** | Depois da fase 6 | Celeste: "se você atravessa o que é de lá, também pode segurar." Ele testa numa chama-sombra da Guardião. | Como espectro, o contato com uma chama-sombra a destrói. **Não afeta** humanos, Inquilinos dentro da casca, balas ou paredes. |
| **Recuperação** | Depois da fase 7 | Ele aprende a respirar entre os mergulhos. | Atraso da recuperação 0,8 → 0,5 s; recuperação 18 → 22/s. |
| **Véu** | Depois da fase 8 | Vendo os Proprietários no baile, ele aprende a "afundar mais". | Como espectro, **os humanos perdem a visão dele** (a memória deles decai como se não o vissem). Os Inquilinos continuam vendo. Na prática, revela quem é quem e permite passar por guardas humanos. |
| **Corte de saída** | Depois da fase 9 | A katana passou tempo demais no Avesso com ele. | Soltar o espectro com a katana na mão dispara um corte que acerta em **0,1 s** em vez de 0,2 s. Não há corte durante o espectro: ele acontece depois. É o golpe final do Síndico. |
| **Fôlego II** | Depois da fase 11 | O fôlego de quem já mergulhou demais. | `MANA_DRAIN` 29 → 25 (cerca de 4 s). |

### Ferramentas de investigação

| Ferramenta | Quando | Efeito |
| --- | --- | --- |
| **Celular com câmera** | Início | Fotografa cada pista coletada, e a foto vai para o quadro. É a base do sistema de pistas. |
| **Rádio-scanner** | Depois da fase 4 | O rádio do despacho dos bondes, mexido para pegar as frequências da Pilar e da Guardião. **O briefing passa a mostrar a planta da fase com a contagem de inimigos e a posição inicial deles** (lida do próprio JSON). |
| **Fita da CAM 03 (original)** | Fase 6 (obrigatória) | Toca na TV do quarto: mostra a morte de Caio e o rosto de Prates dobrando (reaproveita o plano "cctv" da abertura). |
| **Credencial de imprensa** | Depois da fase 9 | Dada por Jairo. O briefing **marca quem é Inquilino** (um ponto violeta) e quem é Proprietário (um losango). |

### Encomendas da Celeste (computador; opcionais, pagas com favores)

| Item | Custo | Disponível | Efeito |
| --- | --- | --- | --- |
| **Carregador estendido** | 1 | Ato 1 (depois da fase 2) | Pente da pistola 12 → 18 e da submetralhadora 30 → 45. |
| **Sola de borracha** (os PASSOS SILENCIOSOS da prévia) | 1 | Ato 1 | Um inimigo desprevenido que não está olhando para ele só o nota a 1,4 m (hoje é 2,1 m, na regra `distance < 2.1`). |
| **Bainha nas costas** | 1 | Ato 2 | Troca katana ↔ arma em 0,22 → 0,12 s. Também é visual: a bainha aparece no modelo. |
| **Silenciador** | 2 | Ato 2 | Tiro de pistola alerta num raio de 9,25 → 4 m. Só vale para a pistola. |
| **Pochete de pentes** (substitui o colete) | 1 | Ato 2 | Recarga −20% em todas as armas. |

Com 12 a 14 pistas opcionais no jogo, há favores para tudo, mas só para quem investiga. Quem joga só pela ação chega ao Ato 3 com o kit da história, que basta para terminar o jogo.

---

## 6. Investigação

### O que o jogador faz

1. **Na fase:** as pistas são **objetos que brilham** no cenário, com um contorno escalonado no mesmo registro da saída (`exit_marker.gd`). O herói anda até elas para coletar, **fora do espectro** (como espectro ele não toca a matéria). Algumas caem de um inimigo específico quando ele morre (o celular do Russo, o do Gravata). A coleta dá um "flash" curto: um quadro de câmera fotográfica, o nome da pista no HUD ("PISTA: CADERNO DA TAXA") e um zoom leve, mais curto que o de abate.
2. **Pista obrigatória:** uma por fase, no caminho principal ou ao lado do alvo. **A saída só acende com todos os inimigos mortos *e* a pista obrigatória coletada.** O HUD avisa: "ELIMINE TODOS", depois "PEGUE A PISTA", depois a dica de saída.
3. **Pistas opcionais:** uma ou duas por fase, nos cômodos fora do caminho. Os "cômodos de tensão" vazios que o README já descreve (o banheiro masculino da gafieira, o depósito) são lugares naturais para elas. Cada uma vale **1 favor** com a Celeste. Algumas são **PROVAS** e contam para o final.
4. **No quarto:** o quadro mostra o que foi coletado. Clicar nele **aproxima a câmera** (uma segunda pose fixa) e cada cartão vira um hotspot com o texto da pista. Os fios ligam os cartões aos rostos e locais. A linha "??? — siga os fios vermelhos" do painel atual vira o próximo destino, preenchido pela pista obrigatória.
5. **No computador:** a Celeste comenta as pistas novas em 2 ou 3 linhas e abre as encomendas.
6. **Entre os atos:** um noticiário do "Alerta Rio" (o mesmo sistema da abertura, agora lendo os dados de um arquivo) resume como a cidade está vendo o Fantasma. Entre as fases, a TV do quarto mostra uma manchete de uma linha.

### Obrigatório e opcional

| | Obrigatório | Opcional |
| --- | --- | --- |
| **Pista principal** | Sim: abre a saída e define a próxima fase. | — |
| **Pistas extras** | — | Dão favores (encomendas), cartões extras no quadro e textos extras da Celeste. |
| **PROVAS** (4 no jogo, marcadas com ★) | — | Três ou mais, somadas a **Jairo vivo** na fase 9, levam ao **Final A**. |
| **Prontuário do Ten. Souza** (fase 11) | — | Salva Souza (ele aparece como aliado no final). Sem ele, Souza é uma das cascas da sala de apuração na fase 12. |
| **Civis mortos** (fases 7, 9, 11 e 12) | — | Não reprovam a fase. O noticiário seguinte os cita ("FANTASMA MATA CONVIDADOS"), e com 3 ou mais o Final A vira um Final A amargo (a cidade acredita, mas não perdoa). |
| **Noticiários** | Os de virada de ato passam sempre, e dá para pular (Enter, como na abertura). | — |

---

## 7. Estrutura em 3 atos, fase a fase

O jogo tem **12 fases**: as 4 existentes formam o Ato 1, e cada ato novo tem 4 fases. Os títulos mantêm o padrão "ÚLTIMO/ÚLTIMA ___".

Linha do tempo:
- 12/10: a noite do beco.
- 26/10: abertura e fase 1.
- Ato 1: até o início de novembro.
- Ato 2: novembro, até o baile do dia 20.
- Ato 3: dezembro, até a véspera da eleição (13/12).

Os textos de briefing estão prontos para colar nos JSON. Os do Ato 1 substituem os atuais **sem mudar o layout**.

---

### ATO 1 — "A TAXA" (o amador)

Caio descobre o poder e segue o dinheiro do Gravata, do bar onde trabalhava até a oficina onde o chefe se esconde. Termina descobrindo que o Gravata pagava aluguel a alguém.

#### Fase 1 — Bar do Arco, Lapa (existente; tutorial)

- **Na história:** é a noite da abertura. Às 23:47, Caio entrou no bar em pânico para buscar o Seu Arlindo, **atravessou o balcão sem querer** (é o que a CAM 03 mostra) e fugiu pela parede. Agora ele volta, já sabendo um pouco mais. O bando de Russo ocupou o bar para "cobrar o atraso". Russo está no depósito, ao lado da porta do beco onde atirou em Caio.
- **Inimigos:** os 8 atuais, todos humanos. O último (`phone`, em [10.6, 5.2], no depósito) é **Russo**.
- **Pista obrigatória: CADERNO DA TAXA**, na mesa de carteado do fundo (a mesa em `[-0.45,-5.375]`, onde estão os três jogadores). Zona de coleta proposta: `[-0.6,-3.95,2.4,0.45]`. É um caderno espiral com nomes de bares, valores e as iniciais "N.V.". A última linha diz: "SÁBADO — ESTRELA — CONTAGEM".
- **Pista opcional: CELULAR DO RUSSO** (cai quando Russo morre). A última chamada é para "GRAVATA". Uma mensagem: "O DOUTOR DO TERNO QUER O GARÇOM SUMIDO DE VEZ."
- **Quadro:** já tem a polaroide do fantasma, o recorte "VIGILANTE FANTASMA" e a foto do bar (os cartões atuais). Entram a página do caderno, um post-it "N.V. = ?" e um fio vermelho do bar até a "ESTRELA".
- **Upgrade:** **Escopeta** ("a doze do Seu Arlindo"; Caio a pega debaixo do balcão ao sair).

```json
"briefing": {
  "place": "01  /  LAPA, RIO DE JANEIRO",
  "title": "ÚLTIMO GOLE",
  "body": "Faz duas semanas que me mataram no beco desse bar.\nOs oito de hoje são do mesmo bando. O Seu Arlindo tá lá dentro.\n\nUm tiro mata. Segure Shift e eu atravesso parede e bala por três segundos, mas não atiro.\nChegue por trás: a katana (F) não faz barulho.",
  "button": "ENTRAR NO BAR  →"
},
"cleared": "BAR LIMPO",
"exit_hint": "SAIA PELO BECO  →",
"mission": "01  LAPA  —  BAR DO ARCO"
```

#### Fase 2 — Gafieira Estrela, Rua do Lavradio (existente)

- **Na história:** no sábado, depois do baile, o dinheiro da taxa é contado no escritório do dono da gafieira, Seu Waldir, que foi obrigado a ceder a sala. A gafieira é vítima, não sócia.
- **Inimigos:** os 11 atuais, todos humanos. O contador é o inimigo `phone` no escritório (em [-10.6,-6.7], reação 0,7).
- **Pista obrigatória: RECIBOS DO CASARÃO**, no cofre do escritório (a escrivaninha em `[-11.0,-6.1]`, o cofre em `[-12.7,-7.3]`). Zona: `[-11.0,-4.95,2.4,0.45]`. São recibos de "compra de obra de arte" do **Casarão das Artes**: R$ 480 mil por uma tela, comprador "P.A.I.".
- **Pista opcional: O ESPELHO DO BANHEIRO.** No banheiro masculino, vazio de propósito (a pia em `[9.0,3.0]`; zona `[9.0,3.6,1.75,0.5]`), está escrito em batom no espelho: **"ELES NÃO TÊM SOMBRA."** Foi a cantora da casa, antes de sumir. É o primeiro aviso das criaturas, e o jogador ainda não entende.
- **Quadro:** uma ficha 3×4 com "NESTOR VALADARES — GRAVATA" (o "N.V." resolvido), um recibo com fio para o Casarão e, se coletado, a foto do espelho num canto, ainda sem fio.
- **Upgrade:** **Submetralhadora** (do cofre). **Evento:** o computador do quarto liga sozinho e a Celeste ("MARÉ") escreve pela primeira vez: *"Vi a fita da CAM 03. Seu corpo estava frio na imagem. Eu conheço esse frio. — C."* As encomendas são abertas.

```json
"briefing": {
  "place": "02  /  RUA DO LAVRADIO, LAPA",
  "title": "ÚLTIMA DANÇA",
  "body": "No caderno: SÁBADO — ESTRELA — CONTAGEM.\nO dinheiro da taxa é contado no escritório, atrás do palco.\nOnze homens. O baile acabou, a música não.\n\nUm tiro mata. Shift: três segundos de espectro, sem atirar.",
  "button": "ENTRAR NA GAFIEIRA  →"
},
"cleared": "SALÃO LIMPO",
"exit_hint": "←  SAIA PELO BECO",
"mission": "02  LAVRADIO  —  GAFIEIRA ESTRELA"
```

#### Fase 3 — Casarão das Artes, Santa Teresa (existente)

- **Na história:** o dinheiro sujo vira quadro "vendido" a preço de mansão. Quem conduz é **Marreco**, o marchand, que fica no fundo do ateliê (o inimigo `phone` em [-7.9,-6.2], reação 0,7). Os artistas de verdade foram expulsos. A escultora **Iara Lessa**, que trabalhava na edícula, desapareceu há um mês.
- **Inimigos:** os 12 atuais, todos humanos. Marreco é o "chefe".
- **Pista obrigatória: LIVRO DE VENDAS**, na mesa de tintas do ateliê (a bancada em `[-12.8,-4.6]`; zona `[-11.85,-4.5,0.55,1.9]`). Todas as telas foram compradas pela **PILAR ADMINISTRAÇÃO DE IMÓVEIS**, com o mesmo endereço de entrega: "ESTAÇÃO SANTA TERESA — A/C N.V.".
- **Pista opcional: CADERNO DA IARA**, na edícula, ao lado do bloco de mármore com a figura meio esculpida (`[9.4,-7.0]`; zona `[9.2,-5.95,1.6,0.45]`). Tem esboços de gente com **outra figura dobrada dentro**, comprida e com juntas demais, e uma frase: *"O Avesso respira com você. Prenda o ar e ele não te pega."* A figura de mármore, vista de cima, tem **dois rostos**.
- **Quadro:** o logotipo da Pilar, Marreco riscado, o mapa da Lapa trocado por um de "Lapa + Santa Teresa" com o fio até a estação e, se coletado, o desenho da figura dobrada perto da polaroide do fantasma, ligado a ela por um fio **azul** (o primeiro).
- **Upgrade:** **Fôlego I** (+0,5 s de espectro).

```json
"briefing": {
  "place": "03  /  RUA ALMIRANTE ALEXANDRINO, SANTA TERESA",
  "title": "ÚLTIMA DEMÃO",
  "body": "Quadro de meio milhão que ninguém pendura.\nO Marreco vende, alguém compra. Quero o livro de vendas.\nDoze homens. A Iara, escultora, sumiu daqui.\n\nUm tiro mata. Saída pelos fundos do quintal.",
  "button": "ENTRAR NO CASARÃO  →"
},
"cleared": "ATELIÊ LIMPO",
"exit_hint": "↑  SAIA PELOS FUNDOS",
"mission": "03  SANTA TERESA  —  CASARÃO DAS ARTES"
```

#### Fase 4 — Estação dos Bondes, Santa Teresa (existente; fim do Ato 1)

- **Na história:** o bonde foi "suspenso" (o letreiro da abertura). Os terrenos ao longo da linha estão sendo comprados pela Pilar. O Gravata transformou a oficina em esconderijo e depósito das telas. Ele está na oficina, ao lado do beco de saída (o inimigo `phone` em [10.8,-5.5], reação 0,7), falando ao telefone com alguém que o deixa apavorado.
- **Inimigos:** os 13 atuais, todos humanos. **Nestor "Gravata" Valadares** é o chefe.
- **Pista obrigatória: CELULAR DO GRAVATA** (cai quando ele morre). A última mensagem recebida, que aparece no HUD na hora da coleta, diz: **"O SÍNDICO AGRADECE OS SERVIÇOS. O IMÓVEL SERÁ REPASSADO."** No histórico: "REPASSE 30% — PILAR" e "CARGA DE QUINTA — CAJU".
- **Pista opcional: MAPA DA LINHA**, no despacho (a mesa em `[-5.0,-6.2]`; zona `[-5.0,-5.05,2.4,0.45]`). O mapa da linha com as paradas, cada lote vizinho ao trilho circulado em vermelho e etiquetado "PILAR".
- **Pista opcional: PASTA DO ARMÁRIO**, no armário entreaberto do vestiário (`[12.05,2.8]`; zona `[11.45,2.9,0.55,1.5]`). Contém o "CONTRATO DE ADMINISTRAÇÃO — CONDOMÍNIO", assinado por E. Prates. É a primeira vez que a palavra aparece.
- **Quadro (virada):** a foto do Gravata é riscada. **Acima dela**, Caio prende uma folha em branco com "SÍNDICO?" e "CONDOMÍNIO?", e o fio sobe da Pilar até ela. Um alfinete novo no Caju.
- **Upgrade:** **Rádio-scanner** (o rádio do despacho).

```json
"briefing": {
  "place": "04  /  ESTAÇÃO DOS BONDES, SANTA TERESA",
  "title": "ÚLTIMO BONDE",
  "body": "O bonde parou de subir faz um mês. O Gravata se escondeu no galpão.\nTreze homens. Ele fica na oficina, perto do beco.\n\nUm tiro mata. Ele também.",
  "button": "ENTRAR NA ESTAÇÃO  →"
},
"cleared": "GALPÃO LIMPO",
"exit_hint": "SAIA PELO BECO  →",
"mission": "04  SANTA TERESA  —  ESTAÇÃO DOS BONDES"
```

> **Noticiário de virada 1 → 2** (seção 8).

---

### ATO 2 — "O CONDOMÍNIO" (em formação)

Caio segue o repasse até a Pilar e descobre que **o que sobe é carne**: corpos de gente desaparecida, levados para servir de casca. Ele conhece a Celeste, aprende o que são os Inquilinos e termina vendo, num baile na Ilha Fiscal, que quase todos ali são eles, e quem os comanda.

Inimigos novos: Inquilinos a partir da fase 5, câmeras e fuzis na fase 6, civis na fase 7, Proprietários na fase 8. As reações vão de 1,1 a 0,6 s. Os briefings são **dossiês da Celeste**, assinados "— C.".

#### Fase 5 — Frigorífico da Pilar, Caju

- **Local real:** o Caju, na zona portuária, perto dos terminais de contêiner e da Baía. O frigorífico é fictício.
- **Planta (resumo):** entra-se pela **doca de caminhões** (sul). Há o escritório de expedição, o corredor de câmaras frias (três câmaras de parede grossa, com sacos pretos pendurados em trilhos, nada explícito), a sala de compressores, o vestiário e, no fundo, o píer, que é a saída. Luz branca e fria, fluorescente. Mesma escala de `bounds` das fases atuais.
- **Objetivo:** achar o destino da "carga de quinta".
- **Novidade de mecânica: os primeiros Inquilinos** e a **regra da casca**. São 12 inimigos: 8 humanos (estivadores da Pilar, poses `drink` e `phone`) e 4 Inquilinos (`arms`, sem sombra). Há um momento roteirizado: o primeiro Inquilino fica na doca, sozinho, de costas. Se morrer de pistola com o corpo inteiro, a chama-sombra sai e entra num saco pendurado, **que levanta**. Os sacos nos trilhos são corpos inteiros disponíveis: rasgá-los antes (um tiro ou corte num saco o "rasga") também é tática.
- **Pista obrigatória: GUIA DE REMESSA**, na mesa do escritório de expedição. Diz: "CASCAS — 14 UN. — DESTINO: CONDOMÍNIO — ESCOLTA: GUARDIÃO SEGURANÇA — RESP.: E. PRATES". Uma das etiquetas é "IARA LESSA, 34".
- **Pista opcional: LIVRO DE ENTRADA DO IML**, na câmara 3. São cópias de entradas do IML com a anotação "RETIRADO SEM REGISTRO". A Celeste reconhece a própria letra numa delas.
- **Quadro:** surge a camada superior, **"O AVESSO"**: o desenho da figura dobrada (ou a anotação "o que levanta depois de morto"), a lista de desaparecidos com a foto de Iara e um fio da Pilar até a Guardião.
- **Upgrade:** **Olho do Avesso**.

```json
"briefing": {
  "place": "05  /  CAJU, ZONA PORTUÁRIA",
  "title": "ÚLTIMA CARGA",
  "body": "A carga de quinta do Gravata vai para o frigorífico da Pilar.\nNo IML sumiram catorze corpos este ano. Eu vi um deles andando.\nSe alguém levantar depois de morto, rasgue o corpo.  — C.",
  "button": "ENTRAR PELA DOCA  →"
},
"cleared": "CÂMARA FRIA LIMPA",
"exit_hint": "↑  SAIA PELO PÍER",
"mission": "05  CAJU  —  FRIGORÍFICO DA PILAR"
```

#### Fase 6 — Guardião Segurança, Avenida Presidente Vargas

- **Local real:** a Avenida Presidente Vargas, no Centro. O andar fica num prédio comercial fictício.
- **Planta:** chega-se pela **escada de incêndio**. Há a recepção, a **central de monitoramento** (parede de monitores), a armaria, a sala do dono, a copa, a sala de reunião com quadro branco e o elevador (a saída, que só destrava no fim).
- **Objetivo:** recuperar a gravação original da CAM 03 e descobrir quem paga a Guardião.
- **Novidade de mecânica:**
  1. **Câmeras de segurança.** Um cone desenhado no chão, que **vê o herói até como espectro** ("a câmera pega o Avesso", como na CAM 03). Se a câmera o vir, todos ficam em alerta. Um tiro ou um corte destrói a câmera, mas o tiro faz barulho.
  2. **Inimigos com fuzil.** São os primeiros que não usam pistola: a bala é mais rápida, mas continua um tiro só.
- São 14 inimigos (2 Inquilinos). O dono, **Rufino Avelar**, é humano e espera na sala dele (reação 0,6). No quadro branco da sala de reunião está escrito **"ELE ATRAVESSA PAREDE. MIRE ONDE ELE VAI SAIR."** É a reação das vítimas: agora elas se preparam.
- **Pista obrigatória: FITA DA CAM 03**, na central. É a gravação completa de 12/10, com Caio levando o tiro e o rosto de Prates dobrando. Toca na TV do quarto (veja a seção 8).
- **Pista opcional ★ PROVA: ORDEM DE COMPRA**, na armaria: "40 FUZIS — PAGADOR: COMITÊ ORDEM NA CASA". É a primeira ligação com a campanha de Castelar.
- **Pista opcional: AGENDA DO AVELAR**, na sala dele: "20/11 — ILHA FISCAL — BAILE DO SÍNDICO" e "LEILÃO FUND. PILAR — LAGOA — LEVAR O PRATES".
- **Quadro:** a foto de **Edmundo Prates** (impressa da fita) no centro do Ato 2, ligada ao beco por um fio vermelho grosso e à Guardião. Se a prova foi coletada, o recorte de um santinho "ORDEM NA CASA" com um ponto de interrogação.
- **Upgrade:** **Fuzil** (da armaria) e **Mão do Avesso**.

```json
"briefing": {
  "place": "06  /  AV. PRESIDENTE VARGAS, CENTRO",
  "title": "ÚLTIMO TURNO",
  "body": "A Guardião escolta as cascas. Décimo quarto andar, catorze homens, fuzis.\nAs câmeras te veem até no espectro. Derrube antes.\nA central guarda a fita original da CAM 03.  — C.",
  "button": "SUBIR PELA ESCADA  →"
},
"cleared": "CENTRAL DESLIGADA",
"exit_hint": "←  DESÇA PELO ELEVADOR",
"mission": "06  CENTRO  —  GUARDIÃO SEGURANÇA"
```

#### Fase 7 — Leilão da Fundação Pilar, Fonte da Saudade

- **Local real:** a Fonte da Saudade, na beira da Lagoa Rodrigo de Freitas. A casa de festas da Fundação Pilar é fictícia.
- **Planta:** jardim com espelho d'água na entrada, salão do leilão (púlpito, cadeiras em fileiras, as **telas do Casarão das Artes** expostas), bar do champanhe, cozinha, adega, varanda para a Lagoa e um escritório no mezanino (desenhado no térreo, sem desnível).
- **Objetivo:** matar **Edmundo Prates** e pegar a chama-sombra dele.
- **Novidade de mecânica: civis.** São 16 convidados: 10 humanos e 6 Inquilinos (com mais 8 seguranças da Guardião). Os humanos **fogem** para as saídas ao primeiro tiro; os Inquilinos sacam a arma. **Matar um humano** não reprova, mas conta como erro e aparece no noticiário. Para distinguir, o jogador olha para o chão (sombra), para a mão (quem bebe champanhe é gente; quem segura a taça sem beber, pose `hold`, não é) e usa o Olho do Avesso. É o "teste" do Ato 2.
- **Pista obrigatória: CONVITE DO PRATES** (cai dele): "BAILE DO SÍNDICO — ILHA FISCAL — 20/11 — TRAJE: 1889". Junto, um broche dourado escrito "ORDEM NA CASA".
- **Pista opcional ★ PROVA: CATÁLOGO DO LEILÃO, LOTE 12**, no púlpito. É um retrato a óleo de 1979, *"Engenheiro Á. Castelar"*, e o rosto é **idêntico** ao de hoje.
- **Quadro:** Prates riscado. **Castelar aparece pela primeira vez**: um santinho de campanha com um fio até o convite. Se a prova foi coletada, o retrato de 1979 ao lado do santinho, com "IGUAL" num post-it.
- **Upgrade:** **Recuperação**.

```json
"briefing": {
  "place": "07  /  FONTE DA SAUDADE, LAGOA",
  "title": "ÚLTIMO LANCE",
  "body": "Leilão da Fundação Pilar. As telas do Casarão vão a lance.\nEdmundo Prates está lá. Foi ele no beco.\nConvidado é gente até provar o contrário. Olhe o chão.  — C.",
  "button": "ENTRAR NA FESTA  →"
},
"cleared": "LEILÃO ENCERRADO",
"exit_hint": "SAIA PELA VARANDA  →",
"mission": "07  LAGOA  —  FUNDAÇÃO PILAR"
```

#### Fase 8 — O Baile do Síndico, Ilha Fiscal (fim do Ato 2)

- **Local real:** a Ilha Fiscal, na Baía de Guanabara, palco do último baile do Império (1889). Aqui é **alugada para um evento privado fictício** que imita aquele baile. O prédio não é danificado na história.
- **Planta:** chega-se pela **ponte de acesso**. Há o torreão de entrada, o salão de baile com o chão xadrez e os lustres, a copa e a cozinha (por onde Caio entra), o salão do cerimonial, a sacada do discurso e o cais (a saída, de lancha).
- **Objetivo:** chegar à sacada durante o discurso do Síndico.
- **Novidade de mecânica:**
  1. **Disfarce de garçom.** Caio entra de dólmã branco (`hero_waiter.png`). Até o primeiro tiro ou o primeiro corpo encontrado, os inimigos o tratam como garçom: ninguém reage, mesmo vendo. A katana e o espectro mantêm o disfarce, desde que ninguém veja o corte.
  2. **Proprietários.** São três, e atravessam parede como ele (seção 4.4).
- São 15 inimigos: quase todos Inquilinos; os poucos humanos são **garçons**, colegas de profissão. Matá-los conta como erro.
- **Pista obrigatória: DISCURSO DO SÍNDICO**, no púlpito da sacada: *"Operação Casa Limpa: centros de triagem em 90 dias. Meta do primeiro ano: 40 mil."* Na margem, à mão: "cascas".
- **Pista opcional: LISTA DE CONVIDADOS**, no cerimonial. Tem os nomes do conselho do Condomínio (sete, todos fictícios). Um nome está marcado com "H" de humano: **Jairo Trovão — TeleRio**.
- **Cena de clímax:** veja "Virada 2 → 3" na seção 8. Castelar foge de lancha. O jogador não pode matá-lo aqui: ele está fora dos limites da fase, e a saída é o cais vazio.
- **Quadro:** Castelar no topo, com "SÍNDICO" escrito em cima do "?" do Ato 1. O fio sobe do Gravata, passa pela Pilar e pela Guardião e chega a ele. Se a lista foi coletada, os sete conselheiros em fileira.
- **Upgrade:** **Véu**.

```json
"briefing": {
  "place": "08  /  ILHA FISCAL, BAÍA DE GUANABARA",
  "title": "ÚLTIMO BAILE",
  "body": "O baile do Síndico, igual ao de 1889.\nVocê entra de garçom. Ninguém olha para garçom.\nQuase ninguém aqui é gente. Três atravessam parede como você.  — C.",
  "button": "SERVIR O SALÃO  →"
},
"cleared": "BAILE ENCERRADO",
"exit_hint": "↓  CORRA PARA O CAIS",
"mission": "08  ILHA FISCAL  —  BAILE DO SÍNDICO"
```

> **Noticiário de virada 2 → 3** (seção 8). No começo do Ato 3 o quarto aparece **revirado** pela Guardião, e Caio o reconstrói como sala de operações.

---

### ATO 3 — "ORDEM NA CASA" (o profissional)

A elite está tomada. Caio desmonta a narrativa (a TV), a origem (o Joá) e a fábrica (a clínica) antes de enfrentar o Síndico na véspera da eleição. Os briefings são **planos operacionais**, com a hora no `place`. As reações vão de 0,9 a 0,5 s, sem poses relaxadas.

#### Fase 9 — Estúdios TeleRio, Cidade Nova

- **Local real:** a Cidade Nova, perto do Centro. A emissora TeleRio é fictícia: é a marca da TV da abertura.
- **Planta:** reaproveita o **estúdio do "Alerta Rio" já modelado** em `assets/intro/studio.glb` (telão curvo, bancada, treliça de luz), cercado de recepção, redação, ilha de edição, arquivo de fitas, camarim do apresentador, corredor técnico com o **quadro de luz** e a saída pela garagem das unidades móveis.
- **Objetivo:** chegar à ilha de edição e **manter Jairo Trovão vivo**.
- **Novidade de mecânica:**
  1. **Quadro de luz.** Um tiro ou um corte apaga as lâmpadas da fase (`lamps`) e deixa a cena na luz da lua e dos monitores. No escuro, **os humanos enxergam a metade da distância e reagem com o dobro do tempo; os Inquilinos não mudam**, porque enxergam pelo Avesso. A escuridão ajuda contra humanos e é perigosa contra o resto.
  2. **Jairo** (um civil que deve sobreviver). Ele fica no camarim, em pânico, e não segue o herói (não há IA de escolta: ele só precisa sobreviver).
- São 14 inimigos (5 Inquilinos e 1 Proprietária, a diretora de jornalismo).
- **Pista obrigatória: ROTEIRO DO PLANTÃO DE 13/12**, na ilha de edição: *"ATENTADO DO FANTASMA CONTRA CASTELAR — GRAVAR COM DUBLÊ — DECRETAR EMERGÊNCIA."* O Condomínio vai encenar um ataque do Fantasma na véspera da eleição.
- **Pista opcional ★ PROVA: FITAS DE ARQUIVO**, no arquivo. São entrevistas de Castelar em 1994 e 2010, e o rosto não mudou.
- **Quadro:** o roteiro em destaque, ligado ao "13/12" no calendário. Jairo entra com um alfinete **verde** (aliado). Se a prova foi coletada, as fitas numeradas embaixo do retrato de 1979.
- **Upgrade:** **Corte de saída** e **Credencial de imprensa** (a credencial de Jairo, se ele sobreviveu; se morreu, Caio a tira do bolso dele, e a credencial sai do mesmo jeito, mas Jairo não está no final).

```json
"briefing": {
  "place": "09  /  CIDADE NOVA  —  23:40",
  "title": "ÚLTIMO PLANTÃO",
  "body": "ALVO: ilha de edição do Alerta Rio. 14 hostis, 6 sem sombra.\nJAIRO TROVÃO: vivo. Ele é gente.\nQUADRO DE LUZ no corredor técnico. No escuro, só eles enxergam.",
  "button": "ENTRAR NO AR  →"
},
"cleared": "SAINDO DO AR",
"exit_hint": "↓  SAIA PELA GARAGEM",
"mission": "09  CIDADE NOVA  —  ESTÚDIOS TELERIO"
```

#### Fase 10 — Condomínio Mirante do Joá, Estrada do Joá

- **Local real:** a Estrada do Joá, entre São Conrado e a Barra, com casas na encosta sobre o mar. O condomínio é fictício.
- **Planta:** a guarita e o portão (com o muro como entrada alternativa). A casa do conselho é toda de **vidro**: sala de reuniões, adega, escritório e suíte. Há uma piscina de borda infinita **que não reflete nada** (a "Porta" para o Avesso, só cenário) e a saída pela trilha da encosta.
- **Objetivo:** a escritura do Síndico.
- **Novidade de mecânica: vidro.** É um novo tipo de sólido, `"type":"glass"`: bloqueia o movimento, mas **não bloqueia a visão nem as balas**. Ele te vê, você o vê, e os dois atiram através dele. O espectro atravessa o vidro como qualquer parede. É o oposto das fases anteriores, com as linhas de tiro muito longas.
- São 15 inimigos (3 Proprietários). É a fase mais aberta do jogo, e por isso a minigun vem depois dela, não antes.
- **Pista obrigatória: ESCRITURA DA CASCA**, no cofre do escritório. É a certidão de óbito de **Álvaro Castelar, 31/03/1977, Estrada do Joá, corpo não localizado**, grampeada a uma escritura fictícia: "IMÓVEL: Á. CASTELAR — OCUPADO EM 1977 — SÍNDICO". Atrás, o endereço do QG de apuração: "EDIFÍCIO MARQUÊS, PRAÇA MAUÁ — COBERTURA".
- **Pista opcional ★ PROVA: ATA DO CONSELHO**, na sala de reuniões. Tem a assinatura dos sete conselheiros aprovando a "Casa Limpa". Com a lista de convidados da fase 8, completa o organograma.
- **Quadro:** a certidão de 1977 ao lado do retrato de 1979 e do santinho de hoje (três rostos iguais). Um alfinete na Praça Mauá.
- **Upgrade:** **Minigun**.

```json
"briefing": {
  "place": "10  /  ESTRADA DO JOÁ  —  02:10",
  "title": "ÚLTIMA VISTA",
  "body": "ALVO: casa do conselho do Condomínio. 15 hostis, 3 proprietários.\nProprietário pisca antes de atravessar.\nVIDRO para gente, não para bala.\nNo escritório: a escritura do Síndico.",
  "button": "PULAR O MURO  →"
},
"cleared": "CONDOMÍNIO DESPEJADO",
"exit_hint": "↓  DESÇA PELA TRILHA",
"mission": "10  JOÁ  —  CONDOMÍNIO MIRANTE"
```

#### Fase 11 — Clínica Santa Aurora, Botafogo

- **Local real:** Botafogo, Zona Sul. A clínica é fictícia: "rejuvenescimento e bem-estar".
- **Planta:** recepção de mármore, consultórios, o centro cirúrgico, a **ala de recuperação com leitos** e pacientes sedados, a farmácia, a sala da diretora e a saída pela emergência nos fundos.
- **Objetivo:** matar a **Dra. Vera Lis**, Proprietária e **candidata a vice de Castelar**, e impedir as "renovações" da noite.
- **Novidade de mecânica: hospedeiros vivos.** Os pacientes sedados (8, imóveis nos leitos) são **corpos inteiros e vivos**: uma chama-sombra que chegue a um deles o faz **levantar ocupado**. Matar Inquilino perto dos leitos é perigoso, e a ferramenta certa é a katana (que rasga a casca) ou a Mão do Avesso. Matar um paciente conta como erro.
- São 14 inimigos. A Dra. Vera Lis (reação 0,5) usa o modelo `Character_29_Female` com jaleco (variação de textura).
- **Pista obrigatória: LISTA DE 13/12**, na sala da diretora: *"Comitê de apuração: 30 renovações para a posse."* E a escala do QG: o Síndico sobe ao palanque à meia-noite.
- **Pista opcional (destino de Souza): PRONTUÁRIO DO TEN. ELIAS SOUZA**, na farmácia: "Consulta 12/12 — encaminhado pela Guardião". Coletar o prontuário **salva Souza** (a Celeste o avisa). Sem ele, Souza é uma das cascas na sala de apuração da fase 12.
- **Quadro:** Vera Lis riscada. Sobram, sem riscar, só o Síndico e os conselheiros que faltam. Se o prontuário foi coletado, Souza entra com alfinete verde.
- **Upgrade:** **Fôlego II**.

```json
"briefing": {
  "place": "11  /  BOTAFOGO  —  03:30",
  "title": "ÚLTIMA CONSULTA",
  "body": "ALVO: Dra. Vera Lis, vice da chapa. Proprietária.\n14 hostis. Oito pacientes sedados: corpo vivo e inteiro é casa pronta.\nPerto dos leitos, katana.",
  "button": "ENTRAR PELA EMERGÊNCIA  →"
},
"cleared": "ALTA DADA",
"exit_hint": "SAIA PELA EMERGÊNCIA  →",
"mission": "11  BOTAFOGO  —  CLÍNICA SANTA AURORA"
```

#### Fase 12 — QG da campanha, Edifício Marquês, Praça Mauá (chefe final)

- **Local real:** a Praça Mauá, de frente para a Baía. O Edifício Marquês é fictício.
- **Planta:** são três áreas ligadas, uma para cada estágio (seção 4.5):
  1. o **salão do comício**, com palanque, telões e plateia;
  2. a **sala de apuração**, com mesas, telões, seis assessores sentados e o poço do elevador;
  3. o **heliponto**, aberto, com quatro luzes de pouso.

  A câmera e a regra do plano do chão são as mesmas das outras fases. A passagem entre as áreas é uma "entrada a pé" curta (`entrance`) com checkpoint.
- **Objetivo:** chegar antes do "atentado" encenado e acabar com o Síndico.
- **Novidade de mecânica:** a luta em três estágios (seção 4.5). Se Jairo está vivo, a fase acontece **ao vivo**: um "REC" no canto do HUD lembra que tudo está sendo transmitido.
- **Pista obrigatória:** nenhuma. A prova é o próprio corpo do Síndico no chão, sem sombra, sob as luzes do palanque.

```json
"briefing": {
  "place": "12  /  PRAÇA MAUÁ  —  VÉSPERA DA ELEIÇÃO",
  "title": "ÚLTIMA PROMESSA",
  "body": "ALVO: Álvaro Castelar. Síndico. Nessa casca desde 1977.\nUm tiro derruba a casca. Ele pula para o corpo inteiro mais perto.\nRasgue as cascas. Pegue ele no Avesso.",
  "button": "SUBIR AO PALANQUE  →"
},
"cleared": "ORDEM NA CASA",
"exit_hint": "↑  SUBA AO HELIPONTO",
"mission": "12  PRAÇA MAUÁ  —  O SÍNDICO"
```

#### Resumo das fases

| # | Ato | Local | Título | Inimigos | Novidade | Upgrade ganho |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 1 | Bar do Arco, Lapa | ÚLTIMO GOLE | 8 | Tutorial (já existe) | Escopeta |
| 2 | 1 | Gafieira Estrela, Lavradio | ÚLTIMA DANÇA | 11 | Rotas de flanco (já existe) | Submetralhadora, Celeste |
| 3 | 1 | Casarão das Artes, Santa Teresa | ÚLTIMA DEMÃO | 12 | Jardim e quintal (já existe) | Fôlego I |
| 4 | 1 | Estação dos Bondes, Santa Teresa | ÚLTIMO BONDE | 13 | Chefe com pista no corpo | Rádio-scanner |
| 5 | 2 | Frigorífico, Caju | ÚLTIMA CARGA | 12 (4 Inq.) | Inquilinos e regra da casca | Olho do Avesso |
| 6 | 2 | Guardião, Presidente Vargas | ÚLTIMO TURNO | 14 (2 Inq.) | Câmeras e fuzis inimigos | Fuzil, Mão do Avesso |
| 7 | 2 | Fundação Pilar, Lagoa | ÚLTIMO LANCE | 14 + 10 civis | Civis e discernimento | Recuperação |
| 8 | 2 | Ilha Fiscal | ÚLTIMO BAILE | 15 (3 Prop.) | Disfarce e Proprietários | Véu |
| 9 | 3 | TeleRio, Cidade Nova | ÚLTIMO PLANTÃO | 14 + Jairo | Quadro de luz e civil a proteger | Corte de saída, credencial |
| 10 | 3 | Mirante do Joá | ÚLTIMA VISTA | 15 (3 Prop.) | Vidro | Minigun |
| 11 | 3 | Santa Aurora, Botafogo | ÚLTIMA CONSULTA | 14 + 8 pacientes | Hospedeiros vivos | Fôlego II |
| 12 | 3 | Edifício Marquês, Praça Mauá | ÚLTIMA PROMESSA | chefe + 14 + civis | Chefe em 3 estágios | — |

---

## 8. Cenas-chave

### Abertura (usa o noticiário existente)

O "Alerta Rio" passa como está: o plantão, o apresentador (que agora tem nome, **Jairo Trovão**), a CAM 03 com o fantasma atravessando o balcão às 23:47, a testemunha ("ELE PASSOU PELA PAREDE, MOÇO! TAVA TODO AZUL!"), o **Ten. Souza** e "NÃO SAI DE CASA!". A sala escura da TV é o **quarto de Caio**. Quando a TV desliga, entra um plano curto e novo (3 s, sem diálogo): no reflexo da tela apagada aparece Caio sentado na cama, ofegante, com a camisa branca furada e manchada. A mão dele **ainda está translúcida e ciano**, e volta ao normal enquanto ele olha. Ele pega o pano em cima do guarda-roupa, desenrola a katana e sai. Na tela, em VT323: **"26 DE OUTUBRO. CATORZE DIAS DEPOIS DO BECO."** Depois vem o briefing da fase 1.

Assim, a CAM 03 deixa de ser só manchete: ela mostra **a descoberta involuntária do poder**, a primeira vez que ele atravessou alguma coisa, em pânico. A fase 1 é a volta, de propósito.

### Virada 1 → 2: "O Síndico agradece"

Na oficina dos bondes, o Gravata morre com o celular na mão. A tela acende no chão, ao lado do sangue: **"O SÍNDICO AGRADECE OS SERVIÇOS. O IMÓVEL SERÁ REPASSADO."** Quando Caio sai pelo beco, as luzes do bonde 17, parado na plataforma, acendem sozinhas por um segundo e apagam. Não há explicação.

No noticiário especial que se segue, o "Alerta Rio" mostra "AGIOTA DA LAPA ENCONTRADO MORTO EM OFICINA DE BONDES". Depois, pela primeira vez, entra uma entrevista coletiva de **Álvaro Castelar**: de terno claro, enquadrado da cintura para cima, ele diz *"Eu vou caçar esse fantasma e cada bandido dessa cidade. ORDEM NA CASA."* O letreiro: "BONDE DE SANTA TERESA VOLTA A CIRCULAR • FUNDAÇÃO PILAR ANUNCIA LEILÃO BENEFICENTE • ELEIÇÃO SUPLEMENTAR: CASTELAR LIDERA". No quarto, o computador liga, e a Celeste manda a imagem de uma câmera do IML: um corpo de saco aberto andando pelo corredor, sem sombra no piso branco.

### A fita da CAM 03 (meio do Ato 2)

Depois da fase 6, a TV do quarto toca a fita original. É o mesmo plano "cctv" da abertura, em outra hora: "26/10" vira "**12/10 00:31**", no beco. Caio, de avental, com o saco de lixo. O homem de terno. O rosto dele **desliza**, numa animação de 3 quadros que sai do lugar como textura mal encaixada. O tiro. Caio cai. Três minutos de imagem parada (acelerada, com o relógio correndo). O corpo fica azul e **afunda na parede**. Não há legenda. Corta para Caio no quarto, de costas para a TV.

### Virada 2 → 3: "Boa noite, inquilino"

Na sacada da Ilha Fiscal, Castelar discursa para o salão. Caio entra no espectro **e o mundo inteiro fica violeta**: todos os convidados têm a coisa dobrada dentro. A de Castelar é tão grande que o contorno dela **ocupa a sacada inteira**, saindo da casca como um casaco largo demais. Castelar para de falar e olha **direto para ele, no Avesso**, coisa que nenhum outro fez. Uma legenda curta: **"BOA NOITE, INQUILINO."** Os lustres apagam. Quando a luz volta, Castelar está na lancha, longe, e o cais está vazio.

O noticiário seguinte inverte tudo: "ATENTADO NA ILHA FISCAL: CASTELAR SOBREVIVE A ATAQUE DO FANTASMA". Jairo lê o teleprompter suando, com a voz embargada (a legenda treme). Por um quadro, a imagem da sacada mostra Castelar **sem sombra**, e logo é cortada. O letreiro: "CASTELAR: 'CASA LIMPA COMEÇA NO DIA 1' • TSE MANTÉM ELEIÇÃO SUPLEMENTAR EM 13/12 • GUARDIÃO SEGURANÇA VAI REFORÇAR POLICIAMENTO". No quarto, a porta está arrombada, o quadro está no chão e a estante, vazia. Caio pendura tudo de novo, agora em ordem. É a única cena de montagem do jogo, com 3 ou 4 cliques de câmera fixa.

### O final

Depois do corte de saída no heliponto, a casca vazia do Síndico cai sob as luzes de pouso. Na tela, a regra de sempre: **não há sombra no chão**. Corta para o quarto. Há três hotspots novos, e o jogador escolhe:

- **Final A, "Olha o chão"** (Jairo vivo, 3 ou mais provas, e o jogador clica na **TV**). O "Alerta Rio" entra ao vivo da Praça Mauá. Jairo, sem roteiro, encara a câmera: **"OLHA O CHÃO, MINHA GENTE! OLHA A SOMBRA!"** É o eco do "NÃO SAI DE CASA!" da abertura. Na praça, a multidão olha para os próprios pés sob os postes. Telões mostram as provas: o retrato de 1979, as fitas e a certidão de 1977. O letreiro: "TSE SUSPENDE ELEIÇÃO • OPERAÇÃO CASA LIMPA ARQUIVADA • BAR DO ARCO REABRE NA LAPA". No último plano, de câmera de cima, Seu Arlindo levanta a porta de aço do bar com um garçom novo. No quadro do quarto, **quatro fotos de conselheiros ainda sem risco**. Se Souza foi salvo, ele aparece na fita de isolamento, desta vez prendendo um homem de terno.
  - **Variante amarga** (3 ou mais civis mortos): o mesmo final, mas o letreiro acrescenta "FANTASMA SEGUE PROCURADO POR MORTE DE INOCENTES". A última imagem é o quarto vazio.
- **Final B, "Fantasma"** (sem as condições do A; a TV mostra a versão deles). "CANDIDATO CASTELAR ASSASSINADO PELO FANTASMA". O vice assume a chapa (se a Dra. Vera Lis morreu, é "um nome do conselho"). Começa a "Casa Limpa". O quarto é invadido pela Guardião, e a polaroide do fantasma fica caída no chão. Fim seco, com o letreiro de "PROCURA-SE".
- **Final C, "Inquilino"** (secreto; o jogador clica na **janela** em vez da TV). Caio entra no espectro e atravessa a janela para o Avesso, **e não volta**: ele vai caçar o resto do Condomínio do lado de lá. O quarto fica com o abajur aceso e **nenhuma sombra em lugar nenhum**. Meses depois, o letreiro diz: "CONSELHEIROS DO CONDOMÍNIO DESAPARECEM • MORADORES DO JOÁ RELATAM 'HOMEM AZUL NAS PAREDES'". Fica a dúvida que Castelar plantou: o que ficou preso na porta em 12 de outubro era Caio ou era *um deles*?

---

## 9. Plano de implementação

### 9.1 Já dá para fazer com o que existe (só dados e textos)

1. **Briefings do Ato 1:** troque `briefing.body` em `assets/level.json`, `level_2.json`, `level_3.json` e `level_4.json` pelos textos da seção 7. `place`, `title`, `button`, `cleared`, `exit_hint` e `mission` continuam iguais ou quase.
2. **Ritmo de entrada por ato:** acrescente `"hold"` e `"speed"` ao objeto `entrance` de cada fase. O Ato 1 é hesitante (`"hold":0.9,"speed":1.2`). `level_entrance.gd` já lê esses campos.
3. **Inimigos por ato:** a curva de `reaction` e de `pose` (sem `drink` no Ato 3) já é dado puro em `enemies`.
4. **Nomes na abertura:** em `scripts/intro.gd`, em `SHOTS`, ponha "JAIRO TROVÃO" na legenda do apresentador e "TEN. ELIAS SOUZA — POLÍCIA MILITAR". Em `TICKER`, acrescente "BAR DO ARCO: DONO HOSPITALIZADO". As constantes já existem.
5. **Textos do quarto** (`scripts/room.gd`):
   - `HOTSPOTS`: "Hotspot_pc" passa a ser "MARÉ — LAPANET" e "Mensagens e encomendas".
   - O painel `"pc"`: troque "COLETE IMPROVISADO" por "POCHETE DE PENTES" e "ESPECTRO +1 s" por "FÔLEGO I"; "PASSOS SILENCIOSOS" vira "SOLA DE BORRACHA".
   - As frases da arma em `WEAPONS`: "A pistola do Russo. Achei no beco."; "A doze do Seu Arlindo."; etc.
   - A linha "???" do painel do quadro: "05  ???  —  CAJU?".
6. **Frases de morte** (`scripts/result_screen.gd`, `DEATH_QUIPS`) e a frase da vitória ("ATÉ A PRÓXIMA."). Elas podem continuar como estão: são a voz da Lapa no Ato 1.
7. **Nada disso muda colisão, layout ou teste de jogabilidade.** `tests/levels_test.gd` só precisa continuar achando os campos.

### 9.2 Exige sistema novo

Em ordem sugerida: cada passo pode ser entregue e testado sozinho.

**A. Campanha e progresso salvo** (é a base de tudo)
- Novo `scripts/campaign.gd` (autoload). Guarda: `level`, `act`, `clues` (ids), `unlocks` (armas, poderes, ferramentas, encomendas), `favors`, `flags` (`jairo_alive`, `souza_saved`, `civilians_killed`) e `ending`. Salva em `user://campanha.json`.
- `scripts/simulation.gd`: `LEVELS` passa a ter 12 entradas. Acrescente um campo `act` em cada JSON (só leitura).
- `scripts/main.gd`: `_leave_room()` deixa de usar `% LEVELS.size()` e passa a usar `Campaign.next_level()`. Depois da 12, abre o final. `_play_intro()` toca o noticiário da virada quando `Campaign` pede.
- `requested_level()` (`--level=N`) continua valendo para depuração.

**B. Pistas**
- No JSON da fase:
  ```json
  "clues": [
    {"id":"caderno_taxa","r":[-0.6,-3.95,2.4,0.45],"required":true,"card":8,
     "title":"CADERNO DA TAXA","text":"SÁBADO — ESTRELA — CONTAGEM. Iniciais: N.V."},
    {"id":"celular_russo","from_enemy":7,"required":false,"card":9,
     "title":"CELULAR DO RUSSO","text":"Última chamada: GRAVATA."}
  ]
  ```
- `simulation.gd`: uma lista `clues` carregada em `load_level()`. A coleta acontece se `player.p` entra no retângulo e `not player.phasing`, ou se o inimigo `from_enemy` morreu e o herói passa no ponto onde ele caiu. Gera um evento `{"type":"clue","id":...}`. A regra de vitória vira `kills == enemies.size() and required_clues_done() and exit_rect.has_point(player.p)`.
- Visual: um `scripts/clue_marker.gd`, irmão de `exit_marker.gd` (o mesmo contorno escalonado, menor e pulsando).
- `hud.gd`: um aviso "PISTA: ..." e o objetivo em três passos ("ELIMINE TODOS" → "PEGUE A PISTA" → `exit_hint`).
- Testes: um `tests/clue_test.gd` e o `playthrough.gd` atualizado para coletar a pista obrigatória.

**C. Quadro dinâmico**
- `tools/build_room.py`: `t_clues` passa de 8 para 32 células (atlas de 1024×32 ou 256×128). Cada cartão é gerado como nó próprio `Clue_<id>`, e cada fio como `Yarn_<a>_<b>`. Os 12 cartões de hoje viram o estado inicial do Ato 1.
- `scripts/room.gd`: ao abrir, esconde os nós `Clue_*` e `Yarn_*` cujos ids não estão em `Campaign.clues`. O clique no quadro troca a câmera para uma pose de aproximação (`BOARD_FROM`, `BOARD_TO`), e cada `Clue_*` vira hotspot com título e texto da pista.

**D. Armas e upgrades por campanha**
- `room.gd`: a estante só equipa as armas que estão em `Campaign.unlocks`. As outras aparecem bloqueadas, com "???".
- `simulation.gd`: as constantes viram base mais modificadores, num `var mods := {}` preenchido por `Campaign`:
  - `mana_drain` (Fôlego I e II);
  - `regen_delay` e `mana_regen` (Recuperação);
  - `magazine_mult` (carregador);
  - `notice_radius` (o `2.1` do `sees`; sola de borracha);
  - `alert_radius_pistol` (o `9.25` de `shoot()`; silenciador);
  - `swap` (bainha);
  - `reload_mult` (pochete).
- **Véu:** em `sees`, `and not (player.phasing and mods.veil and e.kind == "human")`.
- **Corte de saída:** em `phase()`, ao sair do espectro com `melee` e `mods.exit_cut`, chame `slash()` com `strike` de 0,1.
- **Mão do Avesso:** como espectro, testa `segment_circle` do herói contra cada `wisp`.
- **Computador:** o painel `"pc"` lista as encomendas com custo em favores e um botão "PEDIR".

**E. Inquilinos, a regra da casca e as chamas-sombra**
- No JSON: `enemies[i].kind` = `"human"` (padrão), `"inquilino"` ou `"proprietario"`. Opcional: `enemies[i].weapon`.
- **Mudança de arquitetura obrigatória:** o sorteio do desmembramento sai de `CombatEffects.roll_gore_variant` e vai para `Simulation.kill()`, com um gerador da simulação semeado por tentativa (como o `rng` da dispersão). O resultado vai no evento `blood` (`"gore":"head"|"arm_l"|...|""`), e `combat_effects.gd` só o desenha. Sem isso, a simulação não sabe se a casca ficou inteira. É preciso atualizar `tests/gore_test.gd`.
- `simulation.gd`:
  - `wisps` (posição, alvo, vida de 2,5 s e velocidade de 3 ou 4 m/s), criadas em `kill()` quando `kind != "human"` e `gore == ""`;
  - a busca do corpo inteiro mais próximo (cadáveres com `gore == ""` e pacientes);
  - a **reanimação**: o cadáver volta a `alive = true`, com `reaction = 0.6`, `kind = "inquilino"` e `kills -= 1`, e o total de inimigos não muda;
  - a destruição pela Mão do Avesso.
- Apresentação:
  - `actor_look.gd`: um parâmetro `cast_shadow := false` para Inquilinos e um `rim_color` violeta ligado a `phasing and mods.eye`;
  - `combat_effects.gd`: as cores do sangue e dos pedaços vêm do `kind` da vítima (preto-azulado `1a1a2e` e `0e0e1a`, pó cinza no lugar das vísceras);
  - um nó novo `scripts/wisp_visual.gd` (chama escalonada PS1, violeta escura).
- **Proprietários:** uma IA de espectro curta (pisca 0,3 s, depois 1,5 s de `phasing`, sem atirar) que reaproveita `phase()` com outro dicionário de ator.

**F. Novos elementos de fase** (um por fase nova)

| Elemento | Campo JSON | Onde no código |
| --- | --- | --- |
| Inimigo com fuzil | `enemies[i].weapon` | `shoot(e,"enemy",WEAPONS[e.weapon])`; `actor_visual.set_weapon` nos inimigos |
| Câmeras | `"cameras":[{"p":[x,z],"angle":a,"fov":0.8,"range":7}]` | Detecção sem testar `phasing`; alvo de tiro e katana; evento `alarm` que põe todos em alerta |
| Civis | `"civilians":[{"p":..., "pose":"drink"|"hold", "kind":"human"}]` | IA de fuga (A* até a saída mais próxima), contador `civilians_killed` |
| Pose `hold` | `enemies[i].pose = "hold"` | `actor_visual.set_pose`: `Drink_Loop` congelado, sem `Consume` |
| Disfarce | `"disguise": true` | `sees` ignorado até o primeiro evento `shot` ou um cadáver visto |
| Quadro de luz | `"switch":{"r":[...],"kind":"lights"}` | Apaga `_setup_lamps()`; humanos com alcance de visão ×0,5 e reação ×2 |
| Vidro | `solids[i].type = "glass"` | `blocked()` o considera; `wall_hit()` e `can_see()` o ignoram. Material transparente no build |
| Hospedeiros vivos | `"patients":[{"p":...}]` | Alvos das `wisps`; corpo vivo, imóvel |
| Chefe | `"boss":{"stages":[...]}` | `scripts/boss_syndic.gd`: estados, saltos de casca, arena do Avesso, checkpoints |

**G. Noticiário de dados**
- `scripts/intro.gd`: `SHOTS`, `CAPTIONS`, `TICKER`, a data da CAM 03 e o título do plano "cctv" passam a vir de `assets/news/<id>.json`. A abertura atual vira `assets/news/abertura.json`, sem mudar nada do que se vê.
- Novos noticiários: `virada_1.json`, `fita_cam03.json`, `virada_2.json`, `final_a.json`, `final_b.json`, `final_c.json`. O apresentador e o policial já são modelos prontos. Castelar pode usar o mesmo `anchor.glb` com outra textura (terno claro, gravata branca).
- Manchete por noite: um campo `"headline"` no JSON de cada fase, mostrado na TV do quarto (o modelo de TV `room_TV_05.jpg` já está no quarto) ou no letreiro do topo.

**H. Modelos e texturas**
- **Só textura** (mesma malha `Character_01`): `hero_act1.png` (sangue e furo), `hero_act2.png` (preto e luvas), `hero_waiter.png` (dólmã), `hero_act3.png` (terno). `ActorVisual.setup()` precisa aceitar uma textura alternativa.
- **Malhas pequenas presas ao osso:** a bainha (`spine_03`) e a gravata preta (reaproveitar a gravata de `build_intro.py`).
- **Inimigos novos:** o uniforme da Guardião é textura sobre `Character_04` e `Character_08`. A elite usa `Character_29` e `Character_29_Female` exportados como inimigos por `build_characters.py` (já estão no rig UAL). A diretora da clínica usa a textura de jaleco.
- **Cenários:** oito novos `tools/build_<fase>.py` sobre o mesmo kit (`build_environment.py` → `build_lavradio.py` → `build_santa_teresa.py`). A fase 9 aproveita `assets/intro/studio.glb`.
- **Quarto por ato:** `build_room.py` gera os nós `Act1_*` (avental, garrafas), `Act2_*` (rádio, mapa do Rio) e `Act3_*` (jornais na janela, pôster de Castelar recortado), e `room.gd` liga ou desliga cada um por `Campaign.act`. O cabeçalho "4:12 DA MANHÃ" passa a vir da fase.

**I. Briefing com planta**
- `main.gd` e `hud.gd`: quando `Campaign` tem o rádio-scanner, o painel de briefing ganha um mini-mapa desenhado a partir de `solids` e `enemies` do próprio JSON (retângulos e pontos). Com a credencial, os pontos ganham cor por `kind`.

**J. Testes novos**
- `campaign_test.gd`: avanço de fase, desbloqueios, finais.
- `clue_test.gd`.
- `wisp_test.gd`: casca inteira levanta; casca rasgada não levanta; a Mão do Avesso destrói a chama.
- `glass_test.gd`: bloqueia movimento, não bloqueia tiro.
- `boss_test.gd`: os três estágios e os checkpoints.
- Atualizar `gore_test.gd` (o sorteio vai para a simulação) e `levels_test.gd` (os campos novos são opcionais: uma fase sem `clues`, `kind` ou `cameras` continua funcionando).

### 9.3 Ordem recomendada

1. **9.1 inteiro** (textos e dados): uma tarde de trabalho, já dá voz ao Ato 1.
2. **A + B + C**: campanha, pistas e quadro. A investigação começa a existir com as 4 fases atuais.
3. **D**: as armas por história e as encomendas. O quarto ganha sentido.
4. **E + G**: Inquilinos e noticiário. Abre o Ato 2 (fase 5).
5. **F** fase a fase, junto com o cenário de cada uma.
6. O **chefe** por último.
