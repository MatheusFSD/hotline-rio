# Hotline Rio — Lapa 3D

Versão independente em **Godot 4**, renderizador **Compatibility**, validada no Godot 4.7.2. Abra o `project.godot` desta pasta e pressione **F5**. Os recursos GLB já estão prontos: não é necessário instalar o Blender para jogar.

Quatro fases à noite, duas na Lapa e duas em Santa Teresa. Na primeira, um bar: calçada de pedra portuguesa, entrada, salão, cozinha, depósito e beco. Elimine os oito inimigos e saia pelo beco à direita, onde a saída se acende quando o bar fica limpo. Na segunda, uma gafieira na Rua do Lavradio, sem os Arcos (veja [Fase 2](#fase-2--gafieira-estrela-rua-do-lavradio)). Depois, em Santa Teresa, um casarão de ateliês e a oficina dos bondes (veja [Fases 3 e 4](#fases-3-e-4--santa-teresa)). Câmera ortográfica elevada, modelos PSX com aproximadamente 870–900 triângulos e cenário low poly PSX com cerca de 21 mil triângulos e texturas de 16–64 px com filtro nearest. Efeitos de combate feitos com geometria simples: sangue, desmembramentos aleatórios, rastros, clarões, cápsulas, fragmentos de impacto, tremor de câmera e, a cada inimigo eliminado, uma sequência fixa: o zoom entra (0,08 s), a câmera lenta começa com o zoom no máximo (30% da velocidade por 0,4 s, voltando suavemente no final), e só depois que ela termina o zoom sai (0,35 s). Um novo abate durante a sequência reinicia a câmera lenta sem soltar o zoom. Quando o protagonista morre, a câmera fecha forte sobre ele (38% do enquadramento em 0,22 s). Em seguida vêm 2 s de câmera lenta (20% da velocidade), com a câmera ainda avançando e girando 5°. Só então entra a tela de morte. Enter recomeça a qualquer momento. A câmera lenta afeta simulação, animações e efeitos; câmera, mira e interface seguem em tempo real. O único áudio é a trilha do menu (veja [Menu principal](#menu-principal)); o único efeito de tela cheia fica nas telas de morte e de fim de fase.

### Cenário

As paredes são cortadas como numa planta baixa, com o topo do corte em preto puro. O corte tem a mesma altura em todas (1,4 m); só a parede do fundo, com o neon BAR DO ARCO, sobe inteira (2,5 m). Os encontros seguem a modelagem do SketchUp: juntas de topo alinhadas pelos vértices externos, sem sobreposição. A parede mais alta é dona dos cantos, e as demais terminam na face dela (`wall_pieces` em `tools/build_environment.py`). Os retângulos de colisão em `assets/level.json` continuam os mesmos. Os pisos são de cor única, sem estampas nem xadrez, com as juntas das placas marcadas num tom mais escuro da mesma cor: cimento queimado vermelho (vermelhão) no salão, granilite bege na entrada, cimento queimado cinza na cozinha, concreto no depósito e nos becos, soleiras de granito, calçada de pedra portuguesa lisa e rua de asfalto.

O Bar do Arco tem barrado de azulejo português e rodameio de madeira. O balcão em L tem tampo de mármore, banquetas estofadas, chopeira, caixa registradora, estufa de salgados e freezer de cerveja. Atrás dele fica a cristaleira com garrafas. Há mesas de boteco com toalha xadrez, mesas de mármore com pé de ferro e cadeiras, uma bancada estofada com mesinhas, jukebox e palmeira, neon na parede, cartazes, TV e relógio. A entrada tem piso xadrez e cardápio de giz.

A cozinha tem fogão industrial de seis bocas, fritadeira, pia dupla, bancada de preparo e azulejo branco. O depósito tem engradados amarelos, barris de chopp e estante.

**Fase 1 como tutorial.** O mesmo subagente arquiteto e game designer das outras fases repensou o bar como fase de adaptação. A fachada, a entrada, o balcão, as mesas, a bancada e a saída continuam no lugar, assim como o noticiário de abertura. O que mudou foi a sequência de combate:
- **Um por vez:** o primeiro inimigo está sozinho na entrada, de costas, lendo o cardápio ao telefone. Só nota o herói a uns 2 m, a distância da katana.
- **Depois uma dupla:** dois inimigos estão no salão da frente, junto à jukebox, separados do salão por uma mureta-jardineira (azulejo, tampo de mármore, folhagem abaixo de 1,35 m para ninguém se esconder atrás).
- **Depois um grupo pequeno:** três inimigos parados em volta da mesa de carteado, no fundo, vindo de uma direção só.
- **Por fim, o cozinheiro e o último homem no depósito,** ao lado da porta do beco.
- **Espectro:** a divisória da entrada fica logo atrás da dupla, e a da cozinha ao lado da mesa de carteado. Atravessá-las com Shift leva o herói às costas deles, mas o uso não é obrigatório.
- **Reações e rotas:** as reações caem de 1,4 s a 1,0 s, na ordem do encontro. Uma porta nova liga o salão da frente ao depósito, formando um circuito. A bancada da cozinha esconde o cozinheiro da porta do salão, e a passagem da cozinha para o depósito foi deslocada para não abrir linha de tiro.
- **Fogo cruzado:** só 20 de cerca de 2.050 células do piso ficam à vista de três ou mais inimigos (antes eram 300).
- **Briefing:** lembra que a katana é silenciosa.

Do lado de fora há gambiarra de lâmpadas coloridas, postes coloniais, um Fusca e sobrados coloridos com sacadas e telhados. Um muro caiado e contínuo fecha o fundo do quarteirão de ponta a ponta; os dois becos terminam nele, e o da direita tem grafite. Do outro lado da rua, afastados do bar, ficam os Arcos da Lapa em dois níveis com o bonde amarelo, e atrás deles a escadaria de mosaico. Como o HUD não tem barras, o primeiro nível dos Arcos aparece no alto da tela. Todos os móveis com colisão ficam dentro dos retângulos de `assets/level.json`. Luzes quentes no salão, na cozinha e na calçada são definidas no próprio `assets/level.json` (`"lamps"`).

### Legibilidade

Da câmera afastada, os personagens são pequenos, então o cenário fica um passo atrás deles. Nada disso altera jogabilidade, colisão ou animação.

- **Gradação seletiva do cenário** (`scripts/scenery_grade.gd`): ao carregar a fase, cada material listado em `GRADES` tem sua textura ajustada em memória. Os parâmetros são saturação, contraste das juntas, ruído entre as juntas e brilho. Os PNGs e o `lapa.glb` não mudam, e tirar um material da tabela devolve o original.
  - Vermelhão do salão: −24% de croma e −36% de contraste nas juntas. Continua vermelho.
  - Cimento da cozinha e concreto dos becos ficam com as juntas mais suaves.
  - Os telhados dos sobrados, fora da área de jogo, têm a textura de telha bem mais calma.
  - **Sobrados laterais como moldura:** os quatro sobrados ao lado do bar usam materiais próprios (`Lapa_side_*`, criados em `tools/build_environment.py`), com as mesmas cores e texturas. Assim dá para recuá-los sem mexer nas mesmas cores dentro do bar.
    - Fachadas, telhado, frisos, venezianas e ferro ficam menos saturados, mais escuros e com bem menos manchas na textura.
    - As cores tendem levemente a um azul-acinzentado de anoitecer: cada casa continua azul, amarela, rosa ou verde, só apagada.
    - A fachada ficou mais gráfica: as janelas perderam o montante escuro e as sacadas perderam os balaústres, ficando só laje e corrimão.
    - Medido na tela, no enquadramento de jogo: −18% de brilho, −20% de contraste e −38% de croma. Nas fachadas, −21%, −26% e −37%.
  - Ficam intactos: toalhas xadrez, estofados, mosaico Selarón, fachadas e o padrão dos azulejos (só −10% de saturação).
  - O tamanho de 32 px e o filtro nearest são mantidos.
- **Destaque dos vivos** (`scripts/actor_look.gd`, só na fase):
  - Uma luz direcional suave, que só alcança a camada dos personagens vivos, ilumina cabeça, ombros e arma sem clarear o piso.
  - Uma borda tênue, em faixas no estilo PS1, aparece na silhueta (shader `shaders/figure_rim.gdshader`): fria no protagonista, quente nos inimigos.
  - Uma sombra de contato escalonada fica sob o quadril. A do protagonista tem uma franja ciano muito leve, o resíduo do espectro.
  - Como espectro, a sombra quase some. Mortos perdem luz, borda e sombra e se acomodam no cenário, deixando o sangue em primeiro plano.
- **Sombreamento PS1 sem polígonos a mais** (`shaders/scenery_shade.gdshader`, aplicado por `SceneryGrade.shade`): um único passe multiplicativo sobre o cenário. Ele só escurece, e os materiais e lâmpadas por baixo continuam iguais.
  - **Volumes por face:** topos ficam com a luz cheia, faces voltadas para a câmera a 80%, laterais a 68% e fundos a 62%. Caixas, balcões, barris e paredes passam a ler como volumes, e não como manchas de uma cor só.
  - **Sombras de contato:** `scripts/contact_shadows.gd` gera, ao carregar a fase, um mapa de 8 texels por metro a partir dos retângulos sólidos de `assets/level.json`. Ele é desfocado (~0,4 m) e cortado em 5 faixas, com bordas escalonadas como os blobs do PS1. Escurece o piso sob e ao redor de mesas, balcão, bancada, fogão, pia e engradados, e na base das paredes. Também escurece os pés de tudo o que fica a até 35 cm do chão.
  - **Aterramento:** faces verticais escurecem em 4 degraus nos últimos 60 cm até o chão.
  - **Personagens:** a sombra deles segue o mesmo desenho, com um núcleo firme sob os pés e degraus mais claros para fora.
- **Moldura noturna** (no mesmo passe): o bar é o palco iluminado, e a noite engole o que está fora dele. Um passe multiplicativo no cenário escurece e esfria para azul-noite tudo o que fica além dos limites jogáveis (`bounds` em `assets/level.json`), numa transição de 3 m. Tudo acima de 3 m de altura também escurece, porque a luz da rua não alcança os telhados.
  - Os sobrados vizinhos viram uma moldura noturna que não compete com a ação.
  - Os Arcos ficam iluminados por refletores, como o monumento real: um tom quente e atenuado, em vez de sumirem com as casas (`NIGHT_EXCEPTIONS`).
  - As fachadas guardam a cor só no térreo, como lojas iluminadas pela rua.
  - Lâmpadas, neon, vidro e o corte preto das paredes não são afetados.
  - O muro dos fundos não é parede cortada, então tem topo de caiação, não preto. A caiação dele é escurecida para não brigar com a parede do fundo do bar.
- **Saída** (`scripts/exit_marker.gd` e `shaders/exit_light.gdshader`): não fica pintada no chão. Fica invisível enquanto houver inimigos e só se acende quando o bar está limpo:
  - um contorno de luz escalonado no chão em volta do retângulo da saída, no mesmo registro da franja do protagonista;
  - uma cortina de luz que sobe do chão em faixas, com partículas subindo;
  - uma luz real que banha o beco.
  - Ela surge do chão com rebote e clarão, depois pulsa devagar. A regra de vitória continua na simulação, e a luz só mostra onde fica a saída.

## Fase 2 — Gafieira Estrela, Rua do Lavradio

A segunda noite se passa numa gafieira fictícia num sobrado da Rua do Lavradio, sem os Arcos da Lapa. O prédio é 1 m mais largo de cada lado que o bar. O herói entra pela porta da frente vindo pela calçada. Ele sai pela porta lateral da copa, no beco da esquerda, que se acende quando o salão fica limpo. São onze inimigos. As reações ficam em 1,15 s na entrada, perto de 1,0 s nos salões públicos e entre 0,9 e 0,7 s no camarim, na copa e no escritório. Depois da limpeza, o HUD aponta para a esquerda.

A planta foi refeita com um subagente no papel de arquiteto e game designer. Ela segue a circulação de uma casa de baile real:

- **Rota do público:** porta da rua → foyer com bilheteria → porta dupla para o salão. Um pilar logo depois da porta serve de cobertura. Do foyer também se chega à sinuca, que abre para o salão.
- **Rota de serviço:** um corredor no lado direito atende os banheiros e leva ao camarim e à coxia direita do palco. O escritório do dono e a copa ficam junto à coxia esquerda. A copa tem a porta para o beco, que é a saída, e liga ao depósito.
- **Banheiros fechados:** feminino e masculino, cada um com uma única porta para o corredor. Não ficam em nenhum caminho de passagem.
- **Voltas, para flanquear:**
  - foyer → salão → sinuca → foyer;
  - foyer → corredor → coxia → salão;
  - salão → escritório → copa → salão;
  - sinuca → depósito → copa;
  - por fora, pelo beco até a porta da copa.
- **Combate:** o salão é grande, com linhas de tiro longas, palco, balcão, quatro colunas e mesas como cobertura. Os cômodos médios e pequenos dão confronto de perto. As portas ficam desencontradas, criando ângulos de emboscada em vez de corredores de tiro. Logo depois da porta da rua ninguém vê o herói; o porteiro só o nota depois de uns 2 m dentro do foyer. O banheiro masculino e o depósito ficam vazios de propósito, como cômodos de tensão.

- **Salão de baile:** piso de tacos, quatro colunas de ferro cortadas na altura das paredes e uma estrela de madeira no centro da pista. O palco tem cortina de veludo, sanefa com franja dourada, neon GAFIEIRA ESTRELA, estrelas de neon, piano de armário, bateria, cadeiras e estantes dos metais, microfones e ribalta. Há um balcão com prateleira de garrafas, mesas de mármore e barrado verde a óleo nas paredes.
- **Escritório do dono:** mesa com abajur de banqueiro, telefone, maços de dinheiro e papéis, cofre, sofá, estante de livros, quadro e tapete.
- **Copa e depósito:** bancada de preparo, engradados e barris.
- **Sinuca:** mesa com feltro verde, bolas e taco, porta-tacos e marcador na parede, sofá, lambri de madeira.
- **Foyer:** bilheteria vermelha envidraçada de frente para a porta, banco estofado, foto emoldurada e palmeiras.
- **Corredor:** barrado amarelo, telefone público e os nomes DAMAS e HOMENS no chão diante de cada porta.
- **Banheiros:** duas pias de coluna com espelhos e três cabines de aço pintado em cada um.
- **Camarim:** penteadeira com espelhos cercados de lâmpadas, peruca no suporte e arara de figurinos de paetê.
- **Fora:** fachada com letreiro e estrelas de neon, lanternas na porta, lampiões na calçada, uma Kombi estacionada, a porta da copa aberta para o beco e o muro dos fundos com grafite. Atrás do muro, as casas do morro sobem em três fileiras rumo a Santa Teresa, escuras, com poucas janelas acesas. Os sobrados que ladeiam a gafieira usam os mesmos materiais `side_*` de moldura da fase 1.

O cenário é gerado por `tools/build_lavradio.py`, que importa `tools/build_environment.py` como kit (texturas, materiais, sobrados e paredes com juntas de topo). O resultado fica em `assets/environment/lavradio.glb`, com cerca de 26 mil triângulos. As paredes seguem a regra da fase 1: corte de 1,4 m em todas, e só a parede do fundo, a do palco, sobe inteira. Cada lado de parede recebe o revestimento do cômodo para o qual está voltado, mesmo quando a parede atravessa vários cômodos. As texturas novas são tacos, veludo e feltro; os tacos entram na gradação do cenário (`scripts/scenery_grade.gd`), como o vermelhão.

**Fases como dados.** Cada fase é um arquivo: `assets/level.json`, `assets/level_2.json`, `assets/level_3.json` e `assets/level_4.json`. Ele traz:

- cena e briefing;
- título da vitória (`"cleared"`) e dica de saída do HUD (`"exit_hint"`);
- linha do quadro de missões;
- lâmpadas, limites, início, entrada e saída;
- sólidos e inimigos.

`Simulation.LEVELS` define a ordem. Em `main.gd`, `load_level()` troca cenário, lâmpadas, colisões, elenco e saída; câmera, luz da lua, HUD e telas são os mesmos em todas as fases. Depois de vencer, o quarto leva à fase seguinte, que abre no próprio briefing; depois da última, volta a primeira. Para abrir direto numa fase: `godot --path . -- --level=3` (de 1 a 4). A abertura do noticiário só passa na fase 1.

## Fases 3 e 4 — Santa Teresa

As duas noites em Santa Teresa têm rua de paralelepípedo com trilhos de bonde, lampiões e, atrás do quarteirão, um muro de arrimo de pedra. Acima dele, a encosta sobe em três fileiras de casarões e mata atlântica com quaresmeiras floridas, escura, com poucas janelas acesas. Os sobrados vizinhos usam os materiais `side_*` de moldura.

**Fase 3 — Última Demão (Casarão das Artes, Rua Almirante Alexandrino).** Um casarão fictício de ateliês de artistas, com jardim e quintal; o terreno é 1 m mais largo de cada lado que o bar. São doze inimigos. O herói entra pelo portão de ferro do jardim e sai pela abertura no muro do quintal, onde uma escadaria de pedra sobe o morro. O HUD mostra "↑ SAIA PELOS FUNDOS".

A planta foi refeita pelo mesmo subagente arquiteto e game designer da gafieira, com a circulação de um casarão real. A porta da frente abre da varanda para um hall com escada. A ala social (sala de jantar e galeria, que tem porta própria para a rua) fica a oeste. O ateliê de pintura fica nos fundos, e a cozinha e o depósito no lado de serviço. Na frente há um jardim formal; atrás de uma cerca viva com portão fica o quintal, com a edícula de escultura e a saída.

- **Voltas, para flanquear:**
  - portão → jardim → varanda → hall → jantar → galeria → depósito → hall;
  - hall → cozinha → ateliê → jantar;
  - jardim → portão da cerca viva → quintal → porta dos fundos da cozinha;
  - varanda → quintal;
  - por fora, da rua até a porta da galeria.
- **Combate:**
  - Cômodos médios com duas a quatro portas e a varanda comprida como corredor de tiro.
  - Cobertura em cercas vivas, balaústres, escada, mesa de jantar, pedestais, caixotes, forno e bloco de mármore. As árvores ficam nos cantos, longe dos confrontos.
  - As reações vão de 1,15 s no jardim a 0,7 s no chefe, no fundo do ateliê.
  - Logo depois do portão ninguém vê o herói; o guarda do chafariz está de costas e só nota quando ele contorna a cerca viva.

- **Jardim:** gramado com caminhos de saibro, cerca viva baixa escondendo o chafariz, caramanchão com buganvília, mesa e cadeiras de ferro, banco, palmeira e quaresmeira nos cantos, gambiarra de lâmpadas.
- **Varanda:** piso de ladrilho, balaústre caiado com corrimão de mármore e vasos de terracota nas pontas.
- **Hall:** escada de madeira com passadeira vermelha, corrimão torneado e pilar com bola de latão.
- **Sala de jantar:** ladrilho hidráulico em tom sobre tom, barrado de azulejo, mesa comprida com seis cadeiras e candelabro, aparador, retrato e relógio.
- **Galeria:** paredes brancas, quadros com luminárias e esculturas em pedestais.
- **Ateliê:** piso de cimento respingado de tinta, cavaletes com telas, estrado com divã e busto de gesso, mesa de tintas e pincéis, telas encostadas e o letreiro pintado CASARÃO DAS ARTES.
- **Cozinha:** fogão industrial e bancada de preparo.
- **Depósito:** telas em estantes e caixotes marcados FRÁGIL.
- **Quintal e edícula de escultura:** caixotes, varal, forno de cerâmica de tijolo, bloco de mármore com uma figura meio esculpida e um pedestal.

Os quadros são de um atlas de 64×32 px com quatro telas: campos de cor, o morro em estilo naïf, bandeirinhas à maneira de Volpi e um retrato.

**Fase 4 — Último Bonde (Estação dos Bondes).** A estação e oficina dos bondes de Santa Teresa, com o terreno 1 m mais largo de cada lado que o bar. São treze inimigos. O herói entra pela porta da estação, vindo pela calçada. A saída fica no beco da direita, agora fechado na rua e nos fundos: só se chega a ela pela porta dos fundos da oficina, atravessando o depósito. O HUD mostra "SAIA PELO BECO →".

A planta foi refeita pelo mesmo subagente arquiteto e game designer das fases 2 e 3. Ela separa o lado dos passageiros do lado de serviço.

- **Passageiros:** do saguão, com a bilheteria de frente para a porta, há três caminhos até a plataforma:
  - pelas roletas, que formam o gargalo, com uma passagem livre ao lado;
  - de volta à rua e pelo portão A, subindo pelo leito do trilho (o caminho de quem pula a catraca);
  - pela sala do chefe da estação e pelo despacho.

  Na plataforma o bonde 17 espera, com colunas de ferro e bancos de encosto duplo no meio.
- **Serviço:**
  - O despacho dá para a plataforma e para o galpão.
  - No galpão ficam o bonde 10, com o fosso de inspeção na frente, e o bonde 14, mais adiante, desencontrado para fazer um zigue-zague de cobertura. O portão C, entreaberto, é uma segunda entrada pela rua; o portão B está fechado.
  - Oficina, almoxarifado e vestiário têm cada um a própria porta para o galpão e ligam-se entre si.
- **Combate:**
  - As reações vão de 1,15 s na estação a 0,7 s no chefe, na oficina junto à saída.
  - Logo depois da porta da rua ninguém vê o herói. O homem na fila da bilheteria está de costas e só o nota depois de uns 2 m.

- **Plataforma e linha:** leito de paralelepípedo com trilho, faixa amarela na borda, colunas de ferro verdes, bancos de encosto duplo, placa esmaltada ESTAÇÃO SANTA TERESA e relógio.
- **Saguão:** bilheteria, roletas cromadas com rotor de três braços e placa SAÍDA, gradil de ferro verde, banco e quadro de horários.
- **Despacho e chefe da estação:** mesas, sofá e o mapa da linha com as paradas.
- **Galpão:** três trilhos vindos da rua, os bondes 10 e 14 em corte (tábuas laterais, colunas cortadas a 1,4 m com topo preto, bancos de madeira, painéis com farol e lanterna, rodas e truques), o fosso de inspeção, um truque reserva, tambores de óleo, caixote, motor de tração e o letreiro OFICINA DOS BONDES. O fosso tem borda listrada de amarelo e preto, escada, luminária e postes com correntes; ele bloqueia passagem e tiros como os outros móveis.
- **Oficina:** torno mecânico, motor no cavalete, bancada com morsa e painel de ferramentas.
- **Almoxarifado:** estantes de aço com caixas, farol reserva e rolo de cabo.
- **Vestiário:** armários de aço (um entreaberto), banco e cabines sanitárias.
- **Fora:** placa da estação, porta de madeira, portão B fechado, portão C entreaberto, placa da oficina e o beco da direita trancado com grade e aviso PROIBIDA A ENTRADA.

O cenário das duas é gerado por `tools/build_santa_teresa.py` (`assets/environment/ateliers.glb`, cerca de 21 mil triângulos, e `bondes.glb`, cerca de 29 mil). Ele importa `build_lavradio.py`, que por sua vez importa `build_environment.py`, e reaproveita as paredes com revestimento por cômodo, os sobrados, a mesa, o sofá e as molduras. As texturas novas são:

- paralelepípedo;
- ladrilho hidráulico;
- cimento de ateliê;
- grama e saibro;
- pedra de arrimo;
- concreto com manchas de óleo;
- folhagem;
- o atlas de quadros.

Os pisos novos entram na gradação do cenário, e os móveis novos têm força própria nas sombras de contato.

## Menu principal

O jogo abre no menu (`scenes/menu.tscn`, `scripts/main_menu.gd`), no estilo de *Não confie em ninguém* e *Retraite de Russie*.
- **Fundo:** uma cena 3D roda atrás (`scripts/menu_backdrop.gd`). É a Lapa à noite, vista do outro lado da rua, com o Bar do Arco isolado pela fita da polícia, os Arcos ao fundo e o herói na calçada olhando a porta. A cena é renderizada em um terço da resolução e ampliada sem suavizar. A câmera respira devagar, a sirene alterna vermelho e azul nas fachadas e, a cada 9 s, o herói vira espectro por um instante.
- **Coluna discreta à esquerda,** sobre uma sombra em degradê: lugar em ciano, o título HOTLINE RIO na fonte do HUD com sombra neon que treme de vez em quando, um fio rosa e uma linha de tom.
- **Opções só em texto:** NOVO JOGO, CARREGAR JOGO, IDIOMAS e SAIR, com barra rosa na opção em foco. Setas ou mouse movem, Enter escolhe, e as opções entram deslizando uma depois da outra.
- **Novo jogo:** passa pelo noticiário e abre a fase 1.
- **Carregar jogo:** abre direto no card da noite salva, com a arma salva. O número da noite aparece ao lado da opção, que fica apagada sem save.

**Trilha** (`tools/build_music.py`, `assets/audio/menu_theme.ogg`): 40 s em laço contínuo, 16 compassos a 96 BPM em lá menor, sintetizados no Python do Blender (numpy) e codificados em OGG pelo módulo de áudio do Blender, como no *Não confie em ninguém*. Sem licença de terceiros.
- **Harmonia e ritmo:** acordes de bossa (Am9 · Fmaj7 · Dm9 · E7♭9 · Am9 · Fmaj7 · Bm7♭5 · E7♯5) num pad desafinado que afunda a cada batida, como no synthwave. Baixo em levada de partido-alto, com cromatismo para o próximo acorde.
- **Bateria discreta:** só o ganzá nos 4 primeiros compassos; depois surdo, tamborim e palma no 2 e no 4.
- **Melodia:** arpejo de piano elétrico (FM) e, na segunda metade, uma melodia com eco em colcheia pontuada.
- **Ambiente:** uma sirene ao longe, que conversa com a luz da viatura no fundo do menu, e o chiado da cidade.
- **Laço sem emenda:** tudo o que soa além do fim volta para o começo, e filtros e reverb trabalham no laço inteiro (FFT circular).
- **Volume:** entra devagar ao abrir o menu (−40 → −6 dB em 3 s) e sai junto com o fade ao começar o jogo.
- **Saída limpa:** sair pelo SAIR ou pelo X da janela para a música alguns quadros antes de fechar.
- **Regerar:** `blender -b --factory-startup --python tools/build_music.py`.

**Save:** a campanha inteira (veja [Campanha, pistas e upgrades](#campanha-pistas-e-upgrades)).

**Idiomas** (`scripts/lang.gd`): português e inglês.
- O português é o texto-fonte em todo lugar, inclusive nos JSON das fases. O inglês fica em `assets/lang/en.json`, com o texto em português como chave.
- Rótulos e botões do Godot se traduzem sozinhos quando o texto é uma chave, então o código só chama `tr()` onde junta pedaços (arma no HUD, linhas do quarto, título da tela de fim de fase, letreiro do noticiário).
- A escolha fica em `user://settings.cfg`; sem escolha, vale o idioma do computador. O idioma de reserva do projeto é o português (`internationalization/locale/fallback`), para que uma linha sem tradução apareça no original.
- Os testes não carregam as tabelas e sempre leem português.
- Para traduzir uma fase nova, acrescente suas linhas ao `en.json`; `tests/menu_test.gd` acusa as que faltarem.

**Tela da missão** (`scripts/mission_screen.gd`): substitui a caixa do briefing. Sobre a própria fase, um véu escuro entra pela esquerda. Na sequência:
1. o lugar se digita em ciano;
2. o título entra deslizando, com a sombra neon tremendo;
3. o fio rosa se desenha;
4. o objetivo se digita;
5. surgem a ação de entrar (com cursor piscando) e uma linha discreta de controles.

O campo `tip` do JSON, com as regras, só aparece na fase 1. A pausa usa a mesma tela, com CONTINUAR e MENU PRINCIPAL. Enter entra a qualquer momento.

### Seletor de fases (ferramenta de desenvolvimento)

A opção **FASES** do menu abre qualquer fase direto na cartela, sem o noticiário. A campanha fica como se todas as fases anteriores tivessem sido vencidas, com todas as pistas, recompensas e liberações. Jogando a partir daqui o save não é gravado; NOVO JOGO e CARREGAR JOGO voltam a gravar.

Para tirar do jogo, apague `scripts/level_select.gd` e `tests/level_select_test.gd`. O menu só mostra FASES enquanto o primeiro existir; o resto do código continua funcionando sem ele.

## Campanha, pistas e upgrades

A base do sistema descrito em [docs/narrativa.md](docs/narrativa.md), seções 5, 6 e 9.

**Campanha** (`scripts/campaign.gd`): guarda a próxima noite, a arma na mão, as pistas achadas, os desbloqueios (armas, poderes, ferramentas, encomendas), os favores e as noites concluídas.
- Fica em estado estático, compartilhado por menu, `main.gd` e quarto.
- É gravada em `user://campaign.json` ao vencer uma noite, ao pedir uma encomenda e ao sair do quarto. Só lançamentos reais gravam; os testes nunca deixam save.
- O menu usa esse arquivo para CARREGAR JOGO.

**Pistas** (campo `clues` no JSON da fase): cada uma tem `id`, `title`, `text`, `required` e um retângulo `r` no chão ou `from_enemy` (o índice do inimigo que a carrega).
- Andar sobre a pista a pega, nunca como espectro, porque o espectro não toca a matéria.
- A de um inimigo aparece no corpo dele depois que ele cai.
- **A saída só acende com todos mortos e a pista obrigatória pega** (`Simulation.cleared()`). O HUD passa de ELIMINE TODOS para PEGUE A PISTA (em amarelo) e depois para a dica de saída.
- Pegar uma pista dispara um flash de foto e mostra no alto da tela "PISTA", o título e o texto por 4 s.
- No chão, a pista tem um brilho âmbar escalonado, na mesma voz da saída, e um cartão de papel girando (`scripts/clue_marker.gd`). Não tem luz própria: as fases já usam as 8 luzes que um objeto aceita.
- Cada pista opcional achada pela primeira vez vale **1 favor** da Celeste. Repetir a fase não rende nada.

| Fase | Obrigatória | Opcionais | Recompensa |
| --- | --- | --- | --- |
| 1 | Caderno da taxa (mesa de carteado) | Celular do Russo (cai dele) | Escopeta |
| 2 | Recibos do Casarão (cofre do escritório) | O espelho do banheiro | Submetralhadora |
| 3 | Livro de vendas (mesa de tintas) | Caderno da Iara (edícula) | Fôlego I |
| 4 | Celular do Gravata (cai dele) | Mapa da linha, Pasta do armário | Rádio-scanner |

**Upgrades valendo nas regras** (`Simulation.mods`, preenchido por `Campaign.mods()` a cada fase). Nenhum dá vida extra: todos mexem em informação, tempo, ruído ou alcance.

| Upgrade | Origem | Efeito |
| --- | --- | --- |
| Fôlego I | Fase 3 | Espectro drena 29/s em vez de 34/s (cerca de 3,4 s) |
| Carregador estendido | Encomenda, 1 favor, depois da fase 2 | Pistola 12 → 18, submetralhadora 30 → 45 |
| Sola de borracha | Encomenda, 1 favor, depois da fase 2 | Quem está de costas só nota o herói a 1,4 m (era 2,1 m) |
| Bainha nas costas | Encomenda, 1 favor, fim do Ato 1 | Troca katana ↔ arma em 0,12 s (era 0,22 s) |
| Silenciador | Encomenda, 2 favores, fim do Ato 1 | Tiro de pistola alerta a 4 m (era 9,25 m) |
| Pochete de pentes | Encomenda, 1 favor, fim do Ato 1 | Recarga 20% mais rápida |

O "colete improvisado" da prévia saiu, porque daria uma vida extra. O rádio-scanner já é guardado como desbloqueio, mas seu efeito (a planta da fase no briefing) é um passo seguinte.

**Tipo de inimigo** (campo `kind`): `human` (padrão), `inquilino` ou `proprietario`. Vai no evento de sangue. O que vive no Avesso sangra preto-azulado e não faz sombra de contato. As 4 fases atuais só têm humanos.

**Desmembramento como regra:** o sorteio saiu dos efeitos e foi para `Simulation.kill()` (`gore_variant`), com um gerador semeado por tentativa. O resultado fica no corpo (`e.gore`) e vai no evento de sangue; `combat_effects.gd` só desenha. Assim a simulação sabe se uma casca ficou inteira, o que é a base da regra dos Inquilinos, e a mesma tentativa desmembra sempre do mesmo jeito.

Testes: `tests/campaign_test.gd` (36 verificações). `tests/clue_capture.gd` grava o marcador, o HUD pedindo a pista, o flash e o quarto depois de duas noites em `.qa/clues`.

### Ato 1 — "A Taxa", de ponta a ponta

As quatro fases contam o Ato 1 de [docs/narrativa.md](docs/narrativa.md). Caio Bento, garçom do Bar do Arco morto no beco e de volta com o espectro, segue o dinheiro do agiota Nestor "Gravata" até descobrir que ele pagava aluguel a alguém.
- **Voz de amador:** os briefings são o diário dele, em primeira pessoa, com frases curtas e nervosas. A dica de regras da fase 1 também está na voz dele.
- **Entrada hesitante:** em todas as fases ele para na porta (`"hold": 0.9`) e entra devagar (`"speed": 1.2`).
- **Abertura:**
  - o "Alerta Rio" ganhou os nomes do elenco: "COM JAIRO TROVÃO" no selo e "TEN. ELIAS SOUZA";
  - o letreiro ganhou "BAR DO ARCO: DONO HOSPITALIZADO";
  - o telejornal é um flash-forward: quando a TV desliga, uma cartela digita "26 DE OUTUBRO, 21:50. / DUAS HORAS ANTES." e a fase 1 é o tiroteio de que a notícia falava.
- **Quarto:**
  - **Armas:** as frases do arsenal contam a história ("A pistola do Russo. Achei no chão do beco.").
  - **Celeste:** escreve no computador a partir da segunda noite (MARÉ), com mensagens que dependem das noites vencidas e das pistas opcionais (`Campaign.CELESTE`).
  - **Quadro 3D:** ganha um cartão por pista achada, com alfinete e fio até o cartão relacionado. O caderno da Iara usa o primeiro fio azul, o do Avesso; o celular do Gravata traz junto um bilhete rosa "?" (o Síndico). Cada pista é um objeto `Clue_<id>` em `room.glb` (`CLUE_CARDS` em `tools/build_room.py`), e o quarto mostra só os achados. O atlas de cartões passou de 8 para 16 células.
  - **Próximo destino:** a última linha do painel do quadro vem da pista mais recente que aponta para algum lugar (campo `lead`). Depois da fase 4: "05 ??? — CARGA DE QUINTA — CAJU?".
- **Fim do ato** (campo `act_end` da fase 4): depois do quarto da estação, a tela da missão sobre fundo preto diz "FIM DO ATO 1 / A TAXA", "O SÍNDICO AGRADECE" e "ATO 2 — O CONDOMÍNIO · EM BREVE" (`scripts/act_card.gd`). Num lançamento real, depois vem o noticiário e então o menu, e CARREGAR JOGO recomeça na fase 1 com tudo o que foi conquistado.
- **Noticiário da virada** (campo `act_end.broadcast`): a virada 1 → 2 já é 3D, na TV do quarto (veja [Plantão especial do Ato 1](#plantão-especial-do-ato-1)). As outras viradas e os finais (campo `act_end.news`) ainda são o **esboço 2D** de `scripts/news_card.gd`. Usa o grafismo do "Alerta Rio" da abertura (selo, AO VIVO, tarja, letreiro e legendas) sobre planos pintados, num tubo com o shader CRT, que liga e desliga. Os dados vêm de `assets/news/virada_1.json`: relógio, selo, letreiro e segmentos (plano, quem fala, manchete, legenda, duração). Assim a versão 3D poderá ler o mesmo arquivo. Na virada 1 → 2, Jairo dá "AGIOTA DA LAPA ENCONTRADO MORTO EM OFICINA DE BONDES", e Castelar promete "ORDEM NA CASA". Enter pula. `tests/news_capture.gd` grava os dois segmentos em `.qa/news`.

Ficam para depois: a textura do herói com a mancha de sangue do Ato 1 e o quarto bagunçado do Ato 1.

### A regra da casca (Inquilinos)

É a base do Ato 2 (seção 4.3 de [docs/narrativa.md](docs/narrativa.md)). Toda a regra vive em `scripts/simulation.gd`, e a apresentação fica em `scripts/avesso_view.gd`, `actor_visual.gd`, `actor_look.gd` e `combat_effects.gd`.
- **Casca inteira:** um inimigo com `kind` diferente de `"human"` que morre com o corpo inteiro (`gore == ""`) solta uma **chama-sombra**. Ela voa a 3 m/s (4 m/s para o Proprietário) até o **corpo inteiro mais próximo** num raio de 6 m, **atravessando paredes**: um saco ou cadáver do outro lado da parede também serve. A chama aparece sempre nítida, com um brilho violeta no chão, para o jogador ver para onde ela vai. Ao chegar, o corpo levanta como Inquilino: reação de 0,6 s, já em alerta, e 0,9 s levantando sem andar nem atirar. A animação de levantar é `Death01` tocada ao contrário. A chama nunca volta para a casca de onde saiu. Sem corpo no alcance, ela some em 0,6 s.
- **Casca rasgada:** se o corpo foi desmembrado, não sai chama, só um pó escuro (evento `unravel`). A katana, a escopeta, o fuzil e a minigun sempre rasgam. A pistola e a submetralhadora deixam o corpo inteiro em 55% das vezes.
- **Sacos pendurados** (campo `shells` da fase: `p` e `angle`): sacos de corpo pendurados no trilho, com zíper e etiqueta voltados para a câmera, balançando de leve no gancho. São corpos inteiros de reserva. Rasgado ou usado, o saco fica aberto no chão. A chama levanta um saco como um **inimigo novo**, que entra no fim da contagem. Um tiro ou um corte rasga o saco, que então não serve mais.
- **A saída** espera todas as chamas no ar: `cleared()` exige `wisps.is_empty()`.
- **Mão do Avesso** (`mods.hand`, desbloqueio `mao_avesso`): como espectro, encostar na chama a apaga.
- **Olho do Avesso** (`mods.eye`, desbloqueio `olho_avesso`): como espectro, os Inquilinos ganham contorno violeta (`e.revealed`).
- **Ao recomeçar:** os sacos voltam inteiros, as chamas somem e os inimigos que saíram dos sacos deixam a cena.

Testes: `tests/wisp_test.gd` (29 verificações). `tests/wisp_capture.gd` encena tudo no bar, em `.qa/wisp`: a chama, o corpo levantando, os sacos e o Olho do Avesso.

## Fase 5 — Frigorífico da Pilar, Caju (abre o Ato 2)

É um frigorífico dos anos 70 na zona portuária. A planta foi feita pelo subagente arquiteto e validada com as regras da simulação: caminhos, visão dos inimigos e alcance de cada Inquilino.
- **Planta:**
  - Entra-se pelo pátio dos caminhões, por duas das três baias da doca; a terceira está ocupada por um caminhão frigorífico.
  - O escritório de expedição fica no canto oeste da doca, com o vestiário e os chuveiros atrás.
  - A antecâmara leva às três câmaras frias, de paredes de isopainel de 0,6 m e com os sacos pendurados no trilho de carne.
  - A casa de máquinas tem compressores de amônia e o reservatório NH3.
  - O píer, nos fundos, é a saída, com a lancha PILAR II atracada.
  - Na rua, contêineres, condensadores e dois armazéns antigos fazem a moldura.
- **Inimigos:** 12 no total, sendo 8 humanos e 4 Inquilinos (pose `arms`, parados, sem sombra). A reação vai de 1,1 s na entrada a 0,6 s na porta do píer.
  - O primeiro Inquilino fica sozinho na doca, de costas, com dois sacos a menos de 3 m: é o tutorial da regra da casca.
  - O da câmara 2 fica entre três sacos.
  - O do vestiário não tem saco por perto, mas tem quatro homens a menos de 6 m: ensina que cadáver inteiro também conta.
  - O da casa de máquinas guarda a saída.
- **Sacos:** 11 (campo `shells`), quase todos dentro das câmaras.
- **Pistas:**
  - **GUIA DE REMESSA**, obrigatória, na mesa do escritório. Aponta para "GUARDIÃO SEGURANÇA — PRES. VARGAS?".
  - **LIVRO DE ENTRADA DO IML**, opcional, no palete de arquivos da câmara 3.
- **Recompensa:** o **Olho do Avesso**.
- **Quarto:** o quadro ganha os cartões da guia de remessa (fio vermelho até a Pilar) e do livro do IML (fio azul, o do Avesso). Depois do Caju, a Celeste escreve sobre a Guardião; com o livro do IML, também admite que a rubrica é dela.
- **Fim do Ato 1 atualizado:** a cartela agora diz "CONTINUAR" e leva, depois do noticiário, direto para a fase 5.

O cenário é gerado por `tools/build_caju.py`, que reaproveita o kit das outras fases e acrescenta:
- os tipos novos `pallet`, `forklift`, `compressor`, `tank`, `chamberdoor` e `truck`;
- os trilhos aéreos de 2,7 m;
- os materiais `isopainel`, `frost`, `bay` e os contêineres.

Gera `assets/environment/caju.glb`:
```powershell
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup --python tools/build_caju.py
```
`godot --path . --script res://tests/level_capture.gd -- 5` grava as vistas em `.qa/level5`.


## Fase 6 — Guardião Segurança, Av. Presidente Vargas

É o 14º andar da firma que escolta as cascas. A planta foi feita pelo mesmo subagente arquiteto da fase 5, retomado com o contexto anterior.
- **Planta:**
  - Sobe-se pela escada de incêndio, à direita.
  - Na frente ficam o vestiário, a área operacional, a sala de reunião (com o quadro branco "ELE ATRAVESSA PAREDE. MIRE ONDE ELE VAI SAIR.") e a recepção.
  - No fundo ficam a copa, a armaria, a central de monitoramento (parede de monitores, um deles a CAM 03) e a sala de Rufino Avelar.
  - Um corredor de 20 m liga tudo até o elevador, à esquerda, que é a saída.
  - Em volta, telhados mais baixos, caixas d'água e, lá embaixo, a avenida.
- **Inimigos:** 14, sendo 12 guardas e 2 Inquilinos. 5 deles têm fuzil. Avelar, com reação de 0,6 s, carrega a agenda.
- **Câmeras** (campo `cameras`: `p`, `angle`, `fov` como meio-ângulo, `range`, `sweep`, `period`):
  - Veem o herói **até como espectro**. Quando veem, todos os inimigos vivos ficam sabendo onde ele está.
  - O cone é desenhado no chão, cortado pelos sólidos: âmbar enquanto vigia, vermelho quando vê.
  - Um tiro quebra a câmera, mas é ouvido; a katana quebra em silêncio. Recomeçar a fase conserta todas.
  - São 4 na fase: a do corredor varre, a do armário do DVR olha por uma fresta e só cai a tiro, a da central e a da recepção.
  - Código em `scripts/simulation.gd` (`cameras`, `camera_sees`, `break_camera`) e `scripts/camera_view.gd`.
- **Fuzis** (`enemies[i].weapon = "rifle"`): o guarda segura um fuzil e a bala voa a 46 m/s, contra 29 da pistola. Continua sendo um tiro só.
- **Pistas:**
  - **FITA DA CAM 03**, obrigatória, na central.
  - **ORDEM DE COMPRA**, opcional, na armaria.
  - **AGENDA DO AVELAR**, opcional, com o próprio Avelar.
- **Recompensa:** a **Mão do Avesso**, que também libera o fuzil (campo `unlocks` da recompensa).
- **Quarto:** o quadro ganha os cartões da fita da CAM 03 (fio azul, até o fantasma), da ordem de compra e da agenda do Avelar. Depois da Guardião, a Celeste escreve sobre o Prates e o leilão; com a ordem de compra ou a agenda, uma mensagem a mais para cada.

O cenário é gerado por `tools/build_guardiao.py`, que importa o kit do Caju. Gera `assets/environment/guardiao.glb`.

**Exterior do 14º andar.** A planta fica sobre um corpo de edifício que desce 42 m, com faixas de janelas, juntas de laje e o nome da firma na fachada. A escada de incêndio tem espessura, mãos-francesas, longarinas, corrimãos e um patamar inferior com a segunda descida. Dois prédios comerciais laterais e seis volumes mais baixos nos fundos têm fachadas completas, parapeitos, casas de máquinas, dutos, exaustores, claraboias ou caixas-d'água. A avenida continua 42 m abaixo, mas foi posicionada atrás do prédio para aparecer na faixa superior da câmera ortográfica, com pistas, carros, canteiro central, palmeiras e postes. Os prédios dos fundos são baixos o bastante para deixar essa faixa visível. São cerca de 27,6 mil triângulos no cenário inteiro, com texturas de 16–32 px. Os materiais `Lapa_guardiao_*` recebem ajustes noturnos próprios em `scenery_grade.gd`; o interior e os materiais das outras fases mantêm os ajustes anteriores. O JSON da fase e as regras de combate permanecem iguais.

`tests/guardiao_exterior_capture.gd` grava a visão normal, o exterior, a avenida, a escada e o zoom máximo na entrada, nos fundos e na saída em `.qa/guardiao_exterior/`. Execute com renderização gráfica: `godot --path . --script res://tests/guardiao_exterior_capture.gd`.

Testes: `tests/camera_test.gd` (17 verificações). `tests/camera_capture.gd` grava o andar, os cones e uma câmera vendo o herói em `.qa/cameras`.

O bot de `tests/playthrough.gd` atira primeiro nas câmeras que enxerga e espera fora dos cones, mas ainda perde a fase 6. Ele fica parado no vão da porta do vestiário, exposto ao corredor e à armaria. Isso é uma limitação do bot, que não sabe usar cobertura.


## Fase 7 — Fonte da Saudade, Lagoa

É o leilão beneficente da Fundação Pilar numa casa modernista dos anos 60 à beira da Lagoa. A planta, a mecânica, as pistas e os textos são do subagente arquiteto (o mesmo das fases 5 e 6); o projeto completo está em `docs/fase7.md`.
- **Planta:**
  - Entra-se pelo portão de serviço, na frente à esquerda, no pátio do bufê, onde ninguém olha.
  - À esquerda ficam a cozinha, a adega (com o "lote especial": três sacos), o escritório do Prates e o bar de champanhe.
  - No meio fica o salão do leilão, com o púlpito, as cadeiras douradas e o telão do LOTE 12.
  - Na frente fica o jardim, com dois espelhos d'água; à direita, a varanda com a piscina.
  - A saída é a escada da varanda, à direita, que desce para o píer na Lagoa.
  - Ao fundo, a Lagoa escura, o Morro dos Cabritos e o Cristo aceso, pequeno.
- **Inimigos:** 14, sendo 8 guardas da Guardião (3 com fuzil) e 6 Inquilinos.
  - 5 dos Inquilinos se passam por convidados: roupa de festa, taça na mão e sem arma à vista até serem alertados. Eles seguram a taça sem beber (pose `hold`, o `Drink_Loop` parado) e, como todo Inquilino, não fazem sombra.
  - O Prates (inimigo 13) é Inquilino, está ao telefone no escritório e carrega o convite. Os três sacos da adega ficam a pouco mais de 4 m dele, através da parede: se ele morrer inteiro, levanta de novo num saco. Dá para agarrar a chama dele como espectro (Mão do Avesso), cortá-lo com a katana, que rasga, ou rasgar os sacos antes.
- **Mecânica nova: civis** (campo `civilians`, com `p`, `angle` e `pose`; campo `flee`, com os pontos de fuga):
  - São 10 convidados, que bebem champanhe e fazem sombra. Não contam como inimigos nem para limpar a fase.
  - O primeiro tiro da casa, de qualquer lado, faz todos fugirem. Uma morte a até 5 m, à vista, assusta só quem viu.
  - Na fuga correm a 2,6 m/s até o ponto de fuga mais próximo e saem de cena.
  - As balas e a katana do herói matam convidados. Isso nunca reprova a noite, mas aparece na tela de resultado ("CONVIDADOS MORTOS") e fica guardado na campanha (`civilians_killed`). As balas dos guardas atravessam os convidados.
  - Um convidado morto inteiro é corpo para as chamas-sombra, como um saco: a chama o veste e ele levanta como inimigo, com a mesma roupa.
  - Código em `scripts/simulation.gd` (`civilians`, `panic`, `kill_civilian`, `_update_civilians`); os convidados são `ActorVisual` com `dress()` e a pose `champagne`, em `main.gd` (`guests`).
- **Pistas:**
  - **CONVITE DO PRATES**, obrigatória, com o Prates: Baile do Síndico, Ilha Fiscal, 20/11.
  - **CATÁLOGO DO LEILÃO, LOTE 12**, opcional, no púlpito: o retrato de 1979 do Castelar, com o rosto de hoje.
- **Recompensa:** **Recuperação**. O fôlego do espectro volta depois de 0,5 s (eram 0,8 s) e a 22 por segundo (eram 18).

O cenário é gerado por `tools/build_lagoa.py`, que importa o kit da Guardião. Gera `assets/environment/lagoa.glb`.

**Exterior da Lagoa.** O terreno, a fundação e os muros de arrimo formam uma margem contínua, com gramado ao lado da varanda, caminho de pedra, talude e vegetação baixa junto à água. O píer tem tablado com espessura, vigas, estacas, amarração, patamar em L e o barco do bufê da Ilha Fiscal atracado ao lado, preso por cabos. Os espelhos d'água e a piscina têm bordas abertas de pedra e água abaixo do acabamento; o caminho do jardim liga a porta do salão aos dois espelhos. Na rua, há meio-fio, postes, cobertura inclinada do manobrista e um sedã com vidros inclinados. A casa vizinha é modernista, com brises, terraço, pergolado e floreiras. O fundo usa relevo contínuo triangulado e uma escala cenográfica comprimida: a outra margem, sem casas (de cima, prédios distantes viram caixas flutuantes), com a orla de pedra, o colar de luzes e a silhueta do Cristo aparecem na câmera de jogo. A água tem textura de 32 px, reflexos discretos e pequenas ondulações. São cerca de 21,6 mil triângulos no cenário inteiro. Os materiais `Lapa_lagoa_*` têm ajustes noturnos próprios; os construtores e materiais compartilhados de piscinas e terrenos das outras fases seguem independentes. A planta e as regras continuam definidas pelo mesmo `assets/level_7.json`.

`tests/lagoa_exterior_capture.gd` grava a visão normal, a margem e o píer, o jardim, a paisagem e o zoom máximo na entrada, nos fundos e na saída em `.qa/lagoa_exterior/`. Execute com renderização gráfica: `godot --path . --script res://tests/lagoa_exterior_capture.gd`.

Testes: `tests/civilian_test.gd` (27 verificações). `tests/lagoa_capture.gd` grava a casa, o salão, o bar com a adega, o jardim e o pânico depois de um tiro em `.qa/lagoa`.

O bot de `tests/playthrough.gd` também perde esta fase, pelo mesmo motivo da 6.

O quadro do quarto ganha os cartões do convite do Prates (fio vermelho) e do catálogo do LOTE 12 (fio azul, o do Avesso).

## Fase 8 — Ilha Fiscal, o Baile do Síndico (fim do Ato 2)

É o baile do Síndico no palácio neogótico da Ilha Fiscal, encenado como o último baile do Império (1889). A planta, a mecânica, as pistas, os textos e o noticiário são do subagente arquiteto; o projeto completo está em `docs/fase8.md`.
- **Planta:**
  - Chega-se com o barco do bufê, no cais de serviço à esquerda, e entra-se pela porta da cozinha.
  - À esquerda ficam a cozinha, a copa e a sala do cerimonial.
  - No meio fica o salão de baile, com a orquestra, os três vitrais e os lustres.
  - Na frente ficam a chapelaria e o hall do torreão; à direita, a sacada do discurso e a antessala.
  - A saída é o cais principal, à direita.
- **Inimigos:** 15, todos Inquilinos ou Proprietários; não há nenhum inimigo humano.
  - 3 são Proprietários: o anfitrião no salão, o mestre de cerimônias e o homem do Castelar na sacada.
  - Dos 12 Inquilinos, 8 estão de convidados (pose `hold`) e 4 são guardas, 3 deles com fuzil.
  - 8 civis: garçons e uma cozinheira.
- **Mecânica nova: o Proprietário** (`"kind":"proprietario"`, constante `PROPRIETOR`):
  - Quando o herói atira a até 9,25 m dele, ou logo depois de ele mesmo atirar, ele pisca em violeta por 0,3 s. Nesse piscar fica parado, não atira e pode ser morto.
  - Depois entra no Avesso por 1,5 s. Atravessa paredes e balas, não atira e vai a 3,2 m/s para um ponto a 3,5 m do herói, do lado oposto à mira.
  - Quando sai, só pode repetir depois de 4 s.
  - A chama dele voa a 4 m/s, e o corpo que ela veste levanta como Proprietário.
  - No Avesso ele aparece translúcido em violeta, onde o herói aparece em ciano.
  - Código em `scripts/simulation.gd` (`blink`, `flank_goal`, `_update_proprietor`).
- **Castelar** não é inimigo. O discurso fica no púlpito da sacada.
- **Pistas:**
  - **DISCURSO DO SÍNDICO**, obrigatória: Operação Casa Limpa, 40 mil, transmissão da TeleRio.
  - **LISTA DE CONVIDADOS**, opcional: sete nomes no conselho e um H, de humano, ao lado de Jairo Trovão.
- **Recompensa:** o **Véu**. Como espectro, inimigos humanos não veem o herói; câmeras, Inquilinos e Proprietários continuam vendo.
- **Fim do Ato 2:** a cartela "BOA NOITE, INQUILINO". Depois dela vem o noticiário `virada_2.json`, e o jogo segue para a fase 9.
  - O noticiário tem três segmentos. O do meio depende da campanha: "FANTASMA MATA CONVIDADOS E GARÇONS" se algum convidado morreu, ou "GARÇONS ESCAPAM ILESOS" se nenhum morreu.
  - O campo novo `"when"` de cada segmento (`"civilians"` ou `"clean"`) é filtrado por `NewsCard.load_news`.
- **Quarto:** o quadro ganha os cartões do discurso e da lista. A Celeste escreve depois do baile, com uma mensagem a mais para cada pista.

O cenário é gerado por `tools/build_ilha.py`, que importa o kit da Lagoa. Gera `assets/environment/ilha.glb`.

**Exterior da Ilha Fiscal.** A ilha tem base contínua de cantaria com cantos chanfrados, faixa escura na linha da água, passeio de pedra e arremates nas bordas. Uma torre de relógio completa fica atrás do corte do salão, com cobertura íngreme, quatro pináculos, molduras e janelas ogivais; os torreões laterais ficam fora da faixa de circulação, sobre bases que descem até a água. O verde do palácio aparece na fachada da frente, abaixo do corte preto. O cais de serviço tem estacas, cabeços, amarrações e passagem até um barco remodelado com casco, cabine e carga; o cais de fuga tem vigas, estacas e defensas, com uma esteira discreta na água. A ponte em L chega a um cais separado na Ilha das Cobras, com armazém e lanternas. A ponte Rio–Niterói e a outra margem usam escala cenográfica comprimida para aparecer na faixa superior da câmera normal. Água, pedras e coberturas têm novas texturas de 32 px e materiais `Lapa_ilha_*` com ajustes noturnos próprios. São cerca de 18,7 mil triângulos no cenário inteiro. O mesmo `assets/level_8.json` continua definindo a circulação, o combate, as pistas e as saídas.

`tests/ilha_exterior_capture.gd` grava a visão normal, a torre, os dois cais, a ponte e o zoom máximo na entrada, nos fundos e na saída em `.qa/ilha_exterior/`. Execute com renderização gráfica: `godot --path . --script res://tests/ilha_exterior_capture.gd`.

Testes: `tests/proprietor_test.gd` (22 verificações: piscar, Avesso, paredes, chama, Véu e noticiário). `tests/ilha_capture.gd` grava o palácio, o salão, a ala esquerda, a sacada e a fuga dos garçons em `.qa/ilha`.

## Fase 9 — Estúdios TeleRio, Cidade Nova (abre o Ato 3)

São os estúdios do "Alerta Rio" na noite em que o roteiro de 13/12 está sendo preparado. A planta, as mecânicas, as pistas e os textos são do subagente arquiteto; o projeto completo está em `docs/fase9.md`.
- **Planta:**
  - Entra-se pela recepção, na frente à esquerda.
  - À esquerda fica o corredor técnico, com o quadro de luz; ele leva ao camarim do Jairo e ao arquivo de fitas.
  - No meio ficam a redação, na frente, e o estúdio, atrás, com o telão curvo, a bancada do Alerta Rio e a treliça de luz.
  - À direita ficam a ilha de edição, onde está a diretora de jornalismo (a Proprietária) e o roteiro, e a garagem das unidades móveis, que é a saída.
- **Inimigos:** 14, sendo 8 humanos (4 com fuzil), 5 Inquilinos e 1 Proprietária. As reações vão de 0,9 a 0,5 s e ninguém está bebendo.
- **Mecânica nova: o quadro de luz** (campo `breaker`, constante `DARK`):
  - Um tiro (a até 0,25 m) ou um corte de katana no quadro apaga o prédio até o retry. O tiro é ouvido normalmente.
  - No escuro, os inimigos humanos enxergam a metade (9,75 → 4,875 m) e reagem com o dobro do tempo. O raio de 2,1 m em que sempre notam, o cone de visão e a audição não mudam.
  - Inquilinos, Proprietários e câmeras enxergam igual.
  - Na tela, as lâmpadas da fase tremem e apagam, a lua fica azul e fraca e o ambiente escurece; ficam os monitores e a luz da saída.
- **Mecânica nova: Jairo** (`civilians[i].vip = "jairo"`):
  - Fica no camarim, ao telefone, e não foge no pânico.
  - É o único civil que as balas dos guardas acertam. Bala perdida mata.
  - A morte dele não reprova a noite, mas fica na campanha (`jairo_dead`) e muda a mensagem da Celeste.
- **Pistas:**
  - **ROTEIRO DO PLANTÃO DE 13/12**, obrigatória, na ilha de edição: o atentado do Fantasma contra Castelar, gravado com dublê.
  - **FITAS DE ARQUIVO**, opcional (prova), no arquivo: Castelar com o mesmo rosto em 1994 e 2010.
- **Recompensa:** o **Corte de saída**. Ao soltar o espectro com a katana na mão, sai um corte que acerta 0,1 s depois (em vez de 0,2 s). Também libera a **credencial** de imprensa, por enquanto só como item desbloqueado.
- **Quadro do quarto:** os cartões do roteiro e das fitas. O atlas do quadro foi ampliado para 32 cartões.

O cenário é gerado por `tools/build_telerio.py`, que importa o kit da Lagoa. Gera `assets/environment/telerio.glb`.

**Exterior da TeleRio.** A antena é uma torre treliçada triangular vermelha e branca em tamanho real, com diagonais, escada, cabos de ancoragem e parabólica; ela sai pelo topo do quadro. Atrás do estúdio há um pátio de piso liso com ventilação, dutos e abrigo de equipamentos e, do outro lado dele, o Teleporto em tamanho real: torres de escritórios com embasamento, saguão aceso e fachada de vidro, que saem do quadro, alternadas com prédios baixos cuja cobertura aparece. À direita, colado à garagem, fica o Estúdio B, o outro prédio da TeleRio (`kit.glued_wing`): o corredor de saída entra nele e termina na luz de uma porta, para mostrar que a emissora continua além do que se joga, com banheiros e outras salas que não aparecem. As paredes são retas, de três andares, e o telhado tem chillers, claraboia e parabólica. A calçada corre contínua por toda a rua, inclusive em frente ao Estúdio B. A rua tem meio-fio, postes e uma viatura de reportagem com cabine, rodas e parabólica modeladas. A fachada azul identifica os estúdios, e dois sobrados menores formam a frente de Cidade Nova à esquerda. Os materiais `Lapa_t9_*` têm texturas novas de 32 px e ajustes noturnos próprios, continuando sujeitos à redução da luz ambiente quando o disjuntor é desligado. São cerca de 22 mil triângulos no cenário inteiro. O mesmo `assets/level_9.json` define combate, circulação, pistas e apagão.

`tests/telerio_exterior_capture.gd` grava a visão normal, a antena, os fundos, o Estúdio B, a rua, o zoom máximo na entrada, nos fundos e na saída, além do apagão, em `.qa/telerio_exterior/`. Execute com renderização gráfica: `godot --path . --script res://tests/telerio_exterior_capture.gd`.

Testes: `tests/telerio_test.gd` (22 verificações: quadro de luz, visão e reação no escuro, Jairo, mensagens da Celeste, Corte de saída e as luzes na tela). `tests/telerio_capture.gd` grava o andar aceso, o estúdio, o corredor, a garagem e o apagão em `.qa/telerio`.

## Fase 10 — Condomínio Mirante do Joá

É a casa do conselho do Condomínio, toda de vidro, na encosta sobre o mar. O projeto das fases 10 a 12 foi feito pelo subagente arquiteto antes da produção e está em `docs/planejado/`; esta é a primeira produzida.
- **Planta:**
  - Pula-se o muro do jardim, na frente à esquerda; a guarita fica na frente à direita.
  - À esquerda fica o deck, com a piscina de borda infinita que não reflete nada (a "Porta" para o Avesso, só cenário).
  - No meio ficam as salas de vidro, a de reunião, o escritório com o cofre, o estar e a suíte, em volta de uma adega de pedra.
  - À direita fica o terraço gourmet.
  - A saída é a trilha que desce a encosta, à esquerda.
  - Embaixo passa o Elevado do Joá; ao fundo, a Pedra da Gávea.
- **Inimigos:** 15, sendo 6 humanos (4 com fuzil), 6 Inquilinos e 3 Proprietários.
- **Mecânica nova: vidro** (`"type":"glass"` nos sólidos):
  - Bloqueia o movimento, do herói e dos inimigos, e as rotas o contornam.
  - Não bloqueia a visão nem as balas de nenhum dos lados: eles te veem e atiram através dele, e você neles.
  - O espectro passa o vidro como qualquer parede.
  - Na simulação, `solids` continua tendo tudo; `opaque` tem só o que bloqueia visão e balas. `wall_hit(a,b,margin,glass)` usa `glass = true` quando um corpo percorre a linha.
- **Pistas:**
  - **ESCRITURA DA CASCA**, obrigatória, no cofre do escritório: a certidão de óbito de Álvaro Castelar, de 1977, com o endereço do QG e o nome da clínica.
  - **ATA DO CONSELHO**, opcional (prova), na mesa de reunião: sete assinaturas aprovando a Casa Limpa.
- **Recompensa:** a **minigun**, que vai para a estante do quarto.
- **Quarto:** os cartões da certidão e da ata. A Celeste escreve depois do Joá, com uma mensagem a mais pela ata.

O cenário é gerado por `tools/build_joa.py`, que importa o kit da Lagoa. Gera `assets/environment/joa.glb`.

**Exterior do Joá.** A casa fica sobre laje e muros de arrimo, na costa, no pé do ombro de granito da Pedra da Gávea. A câmera só mostra uma faixa de 7,7 m atrás da casa, então nada ali é uma cópia pequena de algo distante. O terreno atrás da casa é uma superfície única: à esquerda sobe como morro, com granito no alto e mata no pé, em copas de árvore vistas de cima; à direita desce até o mar. O Elevado do Joá corre sobre a água em pilares duplos, em tamanho real, com duas faixas, muretas e postes com um ponto de luz; ele entra pela direita e faz uma curva em volta do morro até sair pelo topo do quadro. A trilha em zigue-zague usa o mesmo campo de alturas do terreno. A casa vizinha é contemporânea, sobre terraço sustentado, com vidro, jardim na cobertura e pergolado. Na frente, a rua faz uma curva suave depois do lote, e a calçada de 2,45 m e o meio-fio a acompanham de ponta a ponta; a rua tem faixas e uma face de pedra sob a borda externa. Os materiais `Lapa_joa_*` usam texturas de 16–32 px e ajustes noturnos próprios. O vidro, a piscina preta sem reflexos e o mesmo `assets/level_10.json` mantêm suas regras.

`tests/joa_exterior_capture.gd` grava a visão normal, o morro, a trilha, o elevado, a encosta e o zoom máximo na entrada, nos fundos e na saída em `.qa/joa_exterior/`. Execute com renderização gráfica: `godot --path . --script res://tests/joa_exterior_capture.gd`.

Testes: `tests/glass_test.gd` (12 verificações: movimento, rota, visão, balas dos dois lados, espectro, minigun e Celeste). `tests/joa_capture.gd` grava a casa, as salas de vidro, o deck, o terraço e um tiro através do vidro em `.qa/joa`.

## Fase 11 — Clínica Santa Aurora, Botafogo

É a clínica de "rejuvenescimento e bem-estar" onde o Condomínio renova as cascas. O projeto está em `docs/planejado/`.
- **Planta:**
  - Entra-se pela emergência, na frente à esquerda; na frente ficam também a recepção de mármore e dois consultórios.
  - Um corredor atravessa o andar.
  - No fundo ficam a ala de recuperação com os oito pacientes sedados, à esquerda, o centro cirúrgico, a farmácia e a sala da Dra. Vera Lis, à direita.
  - A saída é a porta da emergência, à direita. Lá fora, uma rua de Botafogo, uma ambulância e o Pão de Açúcar ao fundo.
- **Inimigos:** 14, sendo 7 humanos (3 com fuzil), 6 Inquilinos e a Dra. Vera Lis, Proprietária e candidata a vice.
- **Mecânica nova: pacientes sedados** (campo `patients`, com `p` e `angle`, cada um dentro de um leito):
  - São corpos vivos e inteiros. Balas e katana não os alcançam.
  - Uma chama-sombra pode vestir um deles: o paciente sai do leito ocupado, como um corpo que cai do saco.
  - Matar o paciente que levantou conta como civil morto (evento `patient_down`).
  - O retry devolve todos aos leitos.
  - Na tela, cada um é um corpo sob o lençol que respira devagar (`scripts/patient_view.gd`). Quem levanta deixa o leito vazio e sai de camisola azul-clara.
- **Pistas:**
  - **LISTA DE 13/12**, obrigatória, na sala da diretora: 30 renovações para a posse; o Síndico sobe ao palanque à meia-noite.
  - **PRONTUÁRIO DO TEN. ELIAS SOUZA**, opcional, na farmácia. Pegá-lo salva Souza (`Campaign.souza_saved()`), que muda a fase 12 e o final.
- **Recompensa:** o **Fôlego II**: o espectro gasta 25 de fôlego por segundo (eram 29 com o Fôlego I), quase quatro segundos.
- **Quarto:** os cartões da lista e do prontuário. A Celeste escreve depois da clínica, com uma mensagem a mais pelo prontuário.

O cenário é gerado por `tools/build_clinica.py`, que importa o kit da Lagoa. Gera `assets/environment/clinica.glb`.

**Exterior de Botafogo.** A Santa Aurora tem fachada verde-clara e pedra, identificação da clínica, cruz médica, emergência e esquadrias abaixo do corte das paredes. A saída da fase não leva para fora: o corredor entra na Ala B e termina na luz de uma porta. A ala é um bloco reto de 8,2 m e três andares, colado à direita (`kit.glued_wing`), com telhado, janelas e placa, para mostrar que o prédio continua além do que se joga, com banheiros e outras salas que não aparecem. A calçada corre pela rua toda, em frente à ala e aos sobrados. A ambulância tem cabine separada, para-brisa inclinado, vidros, rodas, portas, faixa verde, cruz na cobertura e uma barra de sinalização discreta. Atrás da clínica há um beco de serviço e uma fileira de prédios em tamanho real, de três andares, cuja fachada preenche a faixa acima da parede dos fundos; não há morros ao longe, que não caberiam nessa câmera. Os leitos, pacientes e regras de combate continuam definidos pelos mesmos sistemas e pelo mesmo `assets/level_11.json`.

`tests/clinica_exterior_capture.gd` grava a visão normal, a ambulância, a rua dos fundos, a Ala B e o zoom máximo na entrada, nos fundos e na saída em `.qa/clinica_exterior/`. Execute com renderização gráfica: `godot --path . --script res://tests/clinica_exterior_capture.gd`.

Testes: `tests/patient_test.gd` (15 verificações: leitos, katana, chama, paciente que levanta, morte contada, retry, Fôlego II, Souza e a tela). `tests/clinica_capture.gd` grava o andar, a ala, o centro cirúrgico, a sala da diretora e um paciente fora do leito em `.qa/clinica`.

## Fase 12 — Edifício Marquês, Praça Mauá: o Síndico (fim do jogo)

É o QG da campanha de Castelar na véspera da eleição. O projeto está em `docs/planejado/`.

**Três etapas encadeadas.** A noite 12 são três arquivos, `level_12a`, `level_12b` e `level_12c`:
- Todos têm `"night": 12`, que numera o briefing e a missão.
- As duas primeiras têm `"chain": true`: ao vencer, a próxima etapa carrega direto, sem tela de resultado nem quarto.
- Morrer recomeça só a etapa atual, que funciona como checkpoint.
- A campanha só registra a noite no fim da 12c.
- Se o Jairo está vivo, a noite vai ao ar: "● REC" pisca no canto do HUD.

**O Síndico** é o inimigo marcado `"sindico": true`, com contorno dourado. A regra de cada etapa vem de `layout.boss`:
- **12a, o comício:**
  - Palco com telões "ORDEM NA CASA", o púlpito, caixas de som, grades e a plateia (14 civis), além de 8 guardas Inquilinos.
  - O Síndico é um Proprietário, com a regra normal de piscar e atravessar.
  - Quando a casca dele cai, rasgada ou não, a chama sai atravessando paredes até o elevador e some. A Mão do Avesso não a segura.
- **12b, a apuração:**
  - Mesas com monitores e telões de contagem, com sete assessores caídos sobre as mesas. São cascas no estilo `"seated"`, com as regras do saco.
  - Entre eles está o Souza, de farda, só se o prontuário dele não foi pego (`"unless_clue"`).
  - Quando o Síndico morre, a chama vai a 6 m/s ao corpo inteiro mais próximo a até 8 m. Ele levanta em 1 s, com a reação 0,05 s mais rápida a cada vez (o mínimo é 0,4 s).
  - A Mão do Avesso pega a chama e acaba com ele. Sem corpo ao alcance, ele foge pelo poço do elevador.
- **12c, o heliponto:**
  - A laje com o H, quatro luzes de pouso e a casa de máquinas.
  - O Síndico não tem casca e só aparece com o herói no espectro.
  - Depois de 1,5 s, anda reto até o herói a 2,4 m/s, atravessando tudo. Não atira e as balas o atravessam.
  - O toque dele mata o herói fora do espectro. No espectro, nada acontece.
  - Só a katana o mata, e a noite é vencida na hora (`"win_on_clear"`).
  - Cada luz de pouso devolve 30 de fôlego uma vez e apaga.

**Os finais:**
- Depois do heliponto vem a cartela "SEM SOMBRA" e, então, o quarto em modo final: só a TV e a janela respondem.
- A TV mostra o Final A se o Jairo está vivo e pelo menos 3 das 4 provas foram achadas (ordem de compra, catálogo do LOTE 12, fitas de arquivo e ata do conselho). Senão, mostra o Final B. A regra está em `Campaign.ending()`.
- A janela mostra o Final C.
- Os noticiários `final_a`, `final_b` e `final_c` usam os segmentos condicionais (`"when"`):
  - "souza": o prontuário foi pego;
  - "bitter": 3 ou mais civis mortos;
  - "civilians" ou "clean".
- Depois do noticiário, o jogo volta ao menu.

O cenário é gerado por `tools/build_marques.py`, que importa o kit da TeleRio. Gera as três cenas `assets/environment/marques_comicio.glb`, `marques_apuracao.glb` e `marques_heliponto.glb`.

Testes: `tests/sindico_test.gd` (29 verificações: as três etapas, Souza, Mão do Avesso, toque, katana, luzes de pouso, finais, REC e o quarto final). `tests/marques_capture.gd` grava o comício, a apuração, os assessores, o heliponto com e sem espectro e o quarto final em `.qa/marques`.

## Música

Tudo sintetizado por código em `tools/music_kit.py` (sem samples nem licença de terceiros), em loops sem emenda. O menu tem `build_music.py`. Cada fase aponta seu arquivo no campo `music` do JSON; fase sem o campo fica em silêncio. Hoje têm música a noite 1 e a noite 12.

- **Noite 1, `build_music_lapa.py`:** bossa em ré menor a 124 BPM. Violão de nylon, baixo pulsando, bumbo e caixa dos anos 80, arpejo, piano de fita gasta, trompete com surdina, cuíca, murmúrio do bar e copos.
- **Noite 12, `build_music_sindico.py`:** a mesma música em dó menor a 138 BPM, em três mixagens de mesmo tamanho: comício (marcha, bateria, metais e o coro ORDEM NA CASA), apuração (teletipos, telefones, vinheta do plantão) e heliponto (vento, rotor, navio e a bossa fantasma). O trompete retoma a melodia da noite 1. Ao trocar de etapa, a mixagem nova continua do mesmo ponto.

A música começa quando a noite começa e desce quando a noite acaba. Quando o herói morre, ela afunda como uma fita acabando durante a câmera lenta e fica em espera; ao fim da câmera lenta, junto com a tela de morte, entra a música de morte (`build_music_death.py`, 29 s em loop). Ao tentar de novo, a música da noite volta de onde parou. `tools/build_music_cues.py` faz o resto: `entrance.ogg`, a música da entrada, em loop enquanto o herói anda; `entrance_hit.ogg`, a batida final quando ele para e a câmera recua, antes de a música da noite entrar; `night_clear.ogg`, a conclusão, com 3 s, quase um efeito sonoro; e, em `sfx/`, o tique dos números subindo e as batidas do título e da nota nas telas de vitória e de morte, além do woosh da katana.

Para mexer: `blender -b --factory-startup --python tools/build_music_lapa.py`; o script imprime o nível de cada instrumento.

## Sons de combate

`tools/build_sfx.py` corta as gravações de `../sounds` em sons curtos em OGG mono (`assets/audio/sfx`), cada um começando no próprio ataque. Das rajadas sai só o último tiro, o único com cauda natural. `scripts/sound_board.gd` toca os tiros de todos (os dos inimigos 6 dB abaixo), o impacto quando uma bala atinge qualquer pessoa, a katana, com um som só por golpe, decidido quando a lâmina chega (a gravação da espada entrando na carne quando acerta alguém ou um saco, o woosh quando corta só o ar) e a recarga, em dois tempos rápidos logo ao apertar. A pistola tem o corpo do tiro desde a primeira amostra, com o estalo sobreposto; a gravação original só soltava o grave 75 ms depois. Tudo segue o tempo do mundo: na câmera lenta das mortes, o que está soando e o que começa nela ficam arrastados e graves. Quando a câmera lenta da morte do herói acaba, o que ainda soa é cortado.

## Abertura

Ao iniciar o jogo, uma TV de tubo numa sala escura liga e mostra o "Alerta Rio", um plantão policial fictício no estilo dos programas policiais da TV aberta (cerca de 32 s). Enter, qualquer tecla ou clique desliga a TV. Um segundo toque sai na hora.

**Onde se assiste:** no quarto do Caio (`assets/room/room.glb`), à noite, na TV de tubo da escrivaninha, a mesma que depois serve de computador. Ela vem do "Models pack psx" (`tools/source/room`), como no quarto. O telejornal passa no mesmo vidro onde depois aparece o site da MARÉ (a superfície `pc_screen`):
- **O quarto em 26 de outubro:** só a pistola do beco na parede, janela fechada; a luz é a da tela, na cor de cada plano (vermelho no PLANTÃO, verde na câmera de segurança, azul na rua), mais o luar da janela. A TV não é iluminada pela própria tela.
- **O Caio:** sentado na cadeira da escrivaninha, de frente para a TV, assistindo à notícia sobre ele mesmo (`assets/intro/caio.glb`, o herói com as animações de sentar do UAL1, gerado por `build_intro.py`). A cadeira do quarto é puxada para baixo dele.
- **A imagem:** o telejornal é renderizado em 640×480 e passa pelo filtro de tubo numa segunda SubViewport; o resultado é a textura do vidro (`shaders/tv_glass.gdshader`). O filtro deixa a tela curva e acrescenta scanlines, máscara RGB, cor vazando, imagem fantasma, barra rolante, chuvisco nos cortes e o efeito de ligar e desligar.
- **A câmera:** começa na vista normal do quarto, com o Caio de costas, e entre 3,0 s e 4,1 s passa pelo ombro esquerdo dele até ficar de frente para o vidro, com a imagem ocupando dois terços da altura; depois se aproxima devagar até a TV desligar.
- **O reflexo:** quando a TV desliga, a câmera chega mais perto do vidro escuro, que reflete o Caio. É uma câmera espelhada pelo plano do vidro, com um frustum fora do eixo do tamanho exato da tela, renderizada só nesse trecho. Ele está ofegante e ergue a mão direita sobre a escrivaninha (`TwoBoneIK3D` no braço, `LookAtModifier3D` na cabeça). A mão ainda brilha ciano, resto do Avesso, e o brilho apaga enquanto ele olha. Corta para a cartela.
- **A cartela:** "26 DE OUTUBRO, 21:50. / DUAS HORAS ANTES." O telejornal é um flash-forward: a fase 1 é o tiroteio no bar de que ele falava, e por isso a CAM 03 marca 21:52, as notícias falam de "8 HOMENS ARMADOS MORTOS" e o tenente, de "OITO CORPOS LÁ DENTRO. NINGUÉM VIU O ATIRADOR". Os tempos estão em `plantao.json` ("after").

O telejornal é 3D, renderizado em 640×480:
1. **Vinheta de PLANTÃO:** o apresentador entra no estúdio. O estúdio tem telão curvo com sirene, skyline do Rio e mosaico de câmeras, bancada com logo e treliça de luz.
2. **Apresentador falando:** planos médios e closes com zoom nervoso.
3. **Câmera de segurança do bar:** o fantasma atravessa o balcão e a parede. Nas fases, as paredes do bar são cortadas a 1,4 m para o jogo ser visto de cima; para as câmeras do telejornal, `assets/intro/bar_shell.glb` (`tools/build_intro_bar.py`) fecha o bar de novo: paredes até o teto, vergas sobre as portas, forro com luminárias, platibanda e cornija na fachada, letreiro sobre a porta e o varal de lâmpadas subido para baixo dele. Só a abertura carrega esse arquivo.
4. **Testemunha:** rosto em mosaico, com a viatura piscando ao fundo.
5. **Tenente na fita de isolamento.**
6. **Close final:** o apresentador aponta para a câmera ("NÃO SAI DE CASA!").
7. **"VOLTAMOS A QUALQUER MOMENTO".**

Logo, tarja, relógio, "AO VIVO" e letreiro rolante completam o visual.

**Roteiro único.** `assets/intro/plantao.json` guarda a ordem dos planos, as manchetes, o letreiro, as falas (início, fim, quem fala e o texto) e o nome de cada falante. A cena e o som leem o mesmo arquivo, então mudar um tempo ali muda os dois; depois disso, gere o som de novo.

**Legendas.** Ficam fora da TV, embaixo da imagem: o nome de quem fala em amarelo (JAIRO TROVÃO, TESTEMUNHA, TEN. ELIAS SOUZA) e a fala em branco. Texto e nome passam por `tr()`, com as traduções em `assets/lang/en.json` como o resto do jogo; uma língua nova só precisa das mesmas chaves. A tarja, o letreiro e o selo dentro da TV também são traduzidos.

**Som.** `tools/build_intro_audio.py` sintetiza tudo, sem gravações, em `assets/audio/intro`:
- `plantao.ogg`: o som da TV do clique de ligar até ela desligar, saindo do alto-falante dela. Tem o estalo e o desmagnetizador, o chiado do tubo esquentando, a vinheta do PLANTÃO (três ataques de metais subindo e o acorde sobre rufar de tímpano) e a trilha tensa sob o estúdio, mais baixa sob a câmera de segurança. Tem também o chuvisco em cada corte, a rua (sirene passando, curiosos atrás da fita, rádio da polícia), o golpe de orquestra no zoom de "8 homens armados mortos" e a vinheta do VOLTAMOS.
- `tv_off.ogg`: o tubo se fechando num ponto e estalando ao esfriar.
- `room.ogg`: o quarto em loop, com trânsito ao longe, grilos e geladeira.
- `after.ogg`: depois que a TV desliga, a respiração ofegante dele, acalmando enquanto o brilho sai da mão.

O som segue o relógio da cena: se o jogo engasgar, ele é reposicionado. Pular desliga a TV na hora, com o som de desligar.

**Falas inventadas.** Ninguém na TV fala uma língua. Como no The Sims, cada um fala sílabas sem sentido com o ritmo e a melodia da legenda:
- cada palavra em português vira uma palavra inventada com o mesmo número de sílabas, e sempre a mesma ("CORTA PRA MIM" duas vezes soa igual duas vezes);
- a sílaba tônica fica onde o português a põe, as vírgulas e pontos viram respiros, exclamações sobem e afirmações descem;
- a voz é síntese de formantes: um zumbido de cordas vocais filtrado por quatro ressonâncias que deslizam de vogal em vogal, ruído para s, ch, f e o estalo das consoantes;
- o apresentador grita, a testemunha fala ofegante e mais aguda, o tenente lê uma nota sem emoção;
- cada fala começa junto com a legenda e cabe no tempo dela.

Os personagens usam modelos dos pacotes PSX fornecidos, adaptados ao rig UAL com as animações de fala, caminhada e gesto:
- apresentador: `Character_29`, com gravata vermelha presa ao osso do peito;
- testemunha: `Character_29_Female`;
- policial: `Character_17_Police`.

Os arquivos ficam em `assets/intro`. Estúdio, viatura, cones e fita são gerados por `tools/build_intro.py`, que reaproveita as texturas e a geometria de `build_environment.py`; o bar fechado, por `tools/build_intro_bar.py`. A abertura só toca no lançamento real do jogo; os testes que instanciam a cena diretamente não a exibem.

## Plantão especial do Ato 1

Depois do cartão "O SÍNDICO AGRADECE" (fim da fase 4), o noticiário especial passa na mesma TV do quarto da abertura, com o Caio na cadeira, o quarto como a campanha está (armas conquistadas na parede, pistas no quadro) e a mesma câmera que vai até a tela. Ele vem de `assets/news/virada_1_tv.json`, no formato do `plantao.json`, e é tocado por `scripts/intro.gd`, que agora toca qualquer programa nesse formato: cada um diz os planos que usa e só os cenários desses planos são montados. O campo `act_end.broadcast` da fase aponta o programa; sem ele, vale o esboço 2D do `act_end.news`.

1. **PLANTÃO** e **Jairo Trovão** no estúdio, com o selo "PLANTÃO ESPECIAL" e o relógio 23:10: "AGIOTA DA LAPA ENCONTRADO MORTO EM OFICINA DE BONDES".
2. **Oficina dos bondes, à noite:** fachada de tijolo com a porta em arco, o bonde 17 nos trilhos, a viatura piscando, cones e fita. O corpo do Gravata está sob um lençol, com o sangue e o celular ainda aceso. O perito está ajoelhado ao lado e o **Ten. Souza** fala na fita. Tarja: "TREZE MORTOS NA ESTAÇÃO DOS BONDES".
3. **Coletiva de Álvaro Castelar:** a parede azul de "ORDEM NA CASA", o púlpito com os microfones das emissoras, os flashes. Ele usa o terno claro da bíblia e é **sempre enquadrado da cintura para cima**, para o chão nunca mostrar que não tem sombra. No close, aponta para as câmeras: "ORDEM NA CASA."
4. **VOLTAMOS**, e então **o computador liga sozinho**. O vidro mostra o LOKI e a página da MARÉ com a **câmera 2 do IML**, de 01/11 às 03:12: um homem sai andando pelo corredor das gavetas, passa pela gaveta aberta e pela maca com o saco aberto e vazio, e para debaixo da câmera, olhando para ela. As luminárias do teto fazem sombra (a bandeja, a maca); ele não faz nenhuma. A MARÉ digita: "OLHA O CHÃO DEBAIXO DELE. NÃO TEM SOMBRA.  — C."

**Elenco, dos pacotes PSX:**
- **Castelar:** `Character_Male_40`, com o terno azul-marinho recolorido para claro por `build_virada.py`. O rosto parece mais novo que 71 anos, e isso combina com um Inquilino que não envelhece.
- **O corpo do IML:** `Character_Male_56`, com o andar de zumbi do UAL2.
- **O perito:** `Character_26_Doctor`, com o `Fixing_Kneeling` do UAL1.

Esses pacotes estão em tamanho real nos arquivos (1,69 m), ao contrário do primeiro (4,38 m). Por isso o `rebind` de `build_intro.py` ganhou o parâmetro `scale`, que no elenco antigo continua 0,36. `build_virada.py` também mapeia todos os dedos, porque esses modelos estão em pose A.

Arquivos em `assets/news/virada_1` (`castelar.glb`, `cadaver.glb`, `perito.glb`, `press.glb`, `oficina.glb`, `iml.glb`), gerados por `tools/build_virada.py`. O som, `assets/audio/intro/virada_1.ogg`, sai do mesmo `build_intro_audio.py`, que monta a trilha de cada programa pelos tipos de plano:
- **Estúdio:** a trilha tensa.
- **Rua:** sirene, curiosos e rádio.
- **Coletiva:** obturadores, murmúrio e aplausos no "ORDEM NA CASA".
- **Computador:** o bipe de ligar, o disco e a MARÉ digitando.

O Castelar tem voz própria: grave, lenta, segura. As legendas (JAIRO TROVÃO, ÁLVARO CASTELAR, MARÉ) passam por `tr()` como as da abertura.

Teste: `tests/virada_test.gd` (23 verificações: cenários e elenco, quarto da campanha, legendas e traduções, Castelar nunca com o chão no quadro, LOKI só no fim, o corpo sem sombra, e o fim do Ato 1 tocando o programa em 3D). `tests/virada_capture.gd` grava cada plano, na TV e na imagem crua, em `.qa/virada`.

**O mundo responde.** `tools/build_sfx_world.py` sintetiza os sons menores, sem gravações, e `scripts/sound_board.gd` acerta os volumes: bala na parede (os sete bagos de uma escopeta valem um som só, e a bala do inimigo soa mais baixa), cápsula do protagonista caindo cerca de 0,6 s depois do tiro, passos alternados a cada 1,45 m (em modo espectro não há passos), troca entre katana e arma, o disjuntor, a câmera quebrando, a bala em madeira, em metal, em estofado ou em planta, o vidro trincando e o alerta de quem vê o protagonista (um toque só, mesmo que a sala inteira o veja).

## Sensação de impacto

- **Sangue que fica:** cada mancha é uma instância de `MultiMesh`, com limite de 6.000, e as poças só somem ao tentar de novo. Antes, o limite de 128 apagava as primeiras poças por volta da 6ª morte.
- **Congelamento no golpe:** toda morte causada pelo protagonista segura o mundo por 45 ms (70 ms na katana, 60 ms na escopeta), em tempo real, antes do zoom e da câmera lenta. O som e a câmera não param. Depois de um congelamento há 0,14 s de folga, para a minigun não engasgar.
- **Marcas que ficam:** a bala que para em algo deixa um buraco com borda lascada, na face que acertou, e solta lascas do material: pó e faísca na alvenaria, farpas na madeira, faíscas no metal, fiapos no estofado e nas plantas, que não ficam marcados (`Simulation.SURFACES`). Buracos e trincas ficam até tentar de novo.
- **Vidro:** a bala atravessa o vidro como antes, mas ele trinca onde ela passou, e caem cacos.
- **Inimigo que vê:** quando um inimigo passa a perseguir o protagonista, um "!" amarelo salta sobre a cabeça dele por 0,65 s.
- **Mira:** abre a cada tiro, gira durante a recarga e volta ao lugar; cada morte deixa um X vermelho sobre o corpo por 0,45 s.
- **Último inimigo:** congela 0,16 s, mais que qualquer morte, com uma pancada grave; a música cai, fica abafada por meio segundo e volta abrindo.
- **Música na câmera lenta:** a música da fase passa por um barramento próprio, `Music`, com um passa-baixa que a abafa na câmera lenta das mortes e na da morte do protagonista.
- **Empurrão da câmera:** o tiro do protagonista empurra a câmera contra a mira, na medida do `kick` de cada arma, e a morte a empurra na direção do corpo. O empurrão não mexe na mira.

`tests/feel_test.gd` verifica todos esses. `tests/feel_capture.gd` grava em `.qa/feel/` o chão da primeira fase depois de todas as mortes.

## Katana

Além da arma escolhida no quarto, o protagonista sempre leva uma katana. **F** troca entre as duas.

- **Troca:** leva 0,22 s. A arma guarda as balas que tinha, e uma recarga em andamento é cancelada. A escolha continua ao tentar de novo.
- **Golpe:** cada clique é um corte, um a cada 0,45 s, e segurar o botão repete. O corte acerta 0,2 s depois do clique, no instante mais rápido da lâmina.
- **Alcance:** mata todos os inimigos vivos num arco de ±65° à frente e até 1,8 m, desde que não haja parede no meio. Não gasta bala e não funciona como espectro.
- **Silêncio:** diferente do tiro, o corte não alerta os inimigos por perto.
- **Gore:** a lâmina sempre arranca algo. Cabeça em 30%, braço em 30%, perna em 15%, e corta ao meio em 25%.
- **Animações:** do UAL2.
  - A guarda (lâmina para frente, fio para baixo, mão no quadril direito) é o primeiro quadro dos cortes.
  - Os cortes `Sword_Regular_A` e `Sword_Regular_B` vêm emendados nas suas recuperações e se alternam a cada clique.
  - Andando, as pernas seguem o passo e o tronco mantém a guarda.
- **Efeito:** um arco de luz escalonado, na altura do peito, acende quando a lâmina acerta e some em 0,2 s.
- **HUD:** mostra "KATANA" e, acima, a arma guardada com o pente ("F  PISTOLA 12/12").

**Modelo:** `tools/build_katana.py` gera a katana pelo Blender MCP, na cena "Katana", com 51 faces e 1,02 m.

- **Partes:** cabo hexagonal com textura de amarração em losangos de 8×32 px, pomo, guarda octogonal logo acima do indicador, colar dourado e lâmina de seção triangular com leve curvatura.
- **Encaixe:** a origem é o centro do punho direito e a lâmina sai pelo lado do indicador, na mesma convenção das armas. Por isso ela usa o mesmo encaixe de punho das armas.
- **Arquivos:** o resultado fica em `assets/weapons/katana.glb`, e o script acrescenta a entrada `katana` em `weapons.json`.

```text
exec(open(r"godot 3d/tools/build_katana.py").read())   # no console Python do Blender ou pelo MCP
```

## Armas

A arma equipada no quarto aparece na mão do protagonista e muda o tiro. Segurar o botão dispara na cadência de cada arma. Os inimigos continuam com pistola.

| Arma | Pente | Recarga | Cadência | Tiro |
| --- | --- | --- | --- | --- |
| Pistola | 12 | 0,75 s | 231/min | preciso |
| Submetralhadora | 30 | 1,1 s | 800/min | espalha |
| Escopeta | 6 | 1,35 s | 86/min | 7 chumbos em leque, alcance curto |
| Fuzil | 20 | 1,3 s | 462/min | preciso, bala mais rápida e longa |
| Minigun | 120 | 2,6 s | 1333/min | precisa girar 0,55 s antes de atirar; girando, você anda até 45% mais devagar |

O tremor de câmera também varia por arma. Os números ficam em `WEAPONS`, em `scripts/simulation.gd`. A dispersão usa um gerador próprio da simulação, então cada tentativa é reproduzível.

A Universal Animation Library Standard só traz animações de pistola: Idle, Shoot, Reload e três poses de mira. Nenhum dos pacotes fornecidos tem animações de submetralhadora, escopeta, fuzil ou minigun. Por isso os clipes delas foram animados no Blender por `tools/build_weapon_anims.py`, sobre o mesmo rig, e ficam em `assets/animations/weapon_clips.glb`:

| Arma | Parado | Tiro | Recarga |
| --- | --- | --- | --- |
| Submetralhadora | junto ao peito, mão esquerda na empunhadura frontal | coice curto, recomeça a cada bala | tira o carregador por baixo, pega outro no cinto, encaixa e bate |
| Escopeta | coronha no ombro, mão esquerda na telha | coice forte e a mão puxa a telha | abaixa a arma e põe dois cartuchos do cinto, depois arma a telha |
| Fuzil | coronha no ombro, mão esquerda no guarda-mão | coice curto, recomeça a cada bala | inclina a arma, troca o carregador pelo do cinto e puxa o ferrolho |

O coice de cada arma segue o comportamento real (filmagens em câmera rápida e relatos de atiradores). Sobe rápido e volta suave, passando um pouco do ponto antes de assentar. O empurrão leva o tronco e o ombro direito para trás, e o pescoço compensa para a mira ficar no alvo:

| Arma | Pico | Duração | Comportamento |
| --- | --- | --- | --- |
| Pistola | boca sobe 22°, 3 cm para trás | 0,26 s | a mão trava o ferrolho e a arma gira para cima no punho; o pulso absorve e volta rápido. Vale também para os inimigos |
| Submetralhadora | 3°, 2,4 cm | 0,13 s | coice leve; em rajada o clipe recomeça a cada bala e a arma trepida |
| Fuzil | 5,7°, 5,6 cm | 0,2 s | empurrão no ombro (tipo AK, ~30–40% mais forte que um AR), pouca subida; trepida em rajada |
| Escopeta | 12°, 12 cm com o tronco | 0,62 s | empurrão pesado, não estalo: ombro e peito vão para trás, a boca sobe mais; depois a mão puxa a telha |
| Minigun | vibração e 3 cm de empurrão contínuo | enquanto atira | sem coice por bala: força constante (~68 kg em média num M134) que o atirador compensa inclinando o tronco para a arma; ao girar sem atirar ela só vibra de leve. Feito ao vivo em `ActorVisual._hold_at_hip` |

Os perfis ficam em `RECOIL`, em `tools/build_weapon_anims.py`. O clipe de tiro entra sem transição, senão a mistura engoliria o pico, e os clipes são gravados a 60 quadros por segundo.

O script posiciona a arma no espaço do personagem e resolve os dois braços por IK até a empunhadura, o apoio, o carregador ou o cinto, a cada quadro. O tronco gira para o lado da arma. A mão esquerda pega a telha e o guarda-mão por baixo, palma para cima, com o cotovelo para baixo. Isso pede ~170° de giro em relação à pose de descanso, e o rig não tem ossos de torção, então o giro é dividido como no braço de verdade: o braço gira 80° no ombro e o antebraço absorve 65% do que sobra no pulso (cerca de 80°, 40° e 40°). Quando a mão vai ao cinto ou ao carregador ela fica solta, na pose natural do antebraço. Assim a pele do pulso não afina. Só o esqueleto é animado; a malha não muda. As pernas e os dedos vêm do repouso de pistola, e ao andar as pernas seguem a caminhada. A recarga é tocada na velocidade que cabe no tempo de recarga de cada arma.

A arma fica dentro do punho fechado. O centro e o eixo do punho são medidos nos ossos dos dedos, tanto no jogo (`ActorVisual.fist_frame`) quanto no script de animação, então as mãos caem nas empunhaduras nos dois lados. Os pontos de apoio de cada arma (coronha, apoio da mão esquerda, carregador) saem de `tools/build_room.py` junto com o cano, em `assets/weapons/weapons.json`. Pistola e minigun ficam na escala 1,25 da estante; submetralhadora 1,1; escopeta e fuzil em tamanho real, para a coronha encostar no ombro com a mão esquerda alcançando o guarda-mão.

A minigun é carregada na cintura: ActorVisual._hold_at_hip inclina o tronco para trás e resolve os braços por IK de dois ossos sobre a pose de pistola, com a mão direita no punho traseiro e a esquerda na alça de cima. Na recarga, a mão esquerda vai à caixa de munição. Os modelos de mão saem de `tools/build_room.py`, das mesmas peças da estante, em `assets/weapons`.

## Entrada na fase

Cada noite começa com o protagonista chegando a pé: ele anda 1,5 s pela calçada até o ponto inicial com a câmera perto dele, vira para dentro da fase, e a câmera abre suavemente até o enquadramento de jogo. Só então o controle é liberado; até lá os inimigos ficam parados e o cronômetro não corre. Enter, Esc ou um clique pulam a entrada. Ela toca ao entrar no bar e ao sair do quarto para a próxima noite, mas não ao tentar de novo depois de morrer.

A entrada é genérica (`scripts/level_entrance.gd`) e cada fase a descreve no próprio layout, em `assets/level.json`:

```json
"entrance": {"path": [[-11.0, 9.2]]}
```

`path` lista os pontos por onde ele passa antes do ponto inicial (`start`). Também aceita `speed` (m/s, padrão 1,4, ritmo de caminhada), `close` (tamanho da câmera perto dele, padrão 7,5), `hold` (segundos parado antes de a câmera abrir, padrão 0,45) e `pull_back` (duração da abertura, padrão 1,6 s). Uma fase sem `entrance` começa direto. A câmera perto dele nunca mostra além do cenário carregado.

## HUD

O HUD (`scripts/hud.gd`) fala a mesma língua das telas de morte e de fim de fase: Bungee e VT323 flutuando sobre a noite, com contorno de tinta grosso e sombra neon, sem barras nem painéis. Só fica o que importa no meio do tiroteio:

- **Canto superior esquerdo:** inimigos eliminados (`02/08`) e o cronômetro. O contador fica ciano quando o bar está limpo.
- **Canto superior direito:** o objetivo, "ELIMINE TODOS", que vira "SAIA PELO BECO →" piscando quando o último cai.
- **Canto inferior esquerdo:** a arma, as balas e um pente em blocos estilo PS1. Com um quarto do pente ou menos, as balas ficam vermelhas e piscam. Na recarga aparece "RECARREGANDO", e o pente se enche em ciano.
- **Canto inferior direito:** a carga do espectro em blocos ciano. Fica "ESPECTRO ATIVO" piscando quando está em uso, e "ESPECTRO ESGOTADO" em vermelho quando falta carga.

Cada mudança tem impacto:

- uma eliminação faz o contador pular e inclinar, e o HUD inteiro treme;
- um tiro faz as balas pularem;
- o fim dos inimigos joga o novo objetivo na tela grande e com tremor forte.

O HUD some suavemente durante a entrada a pé, o briefing e a sequência de morte. Nome do jogo, local e controles saíram da tela de jogo; os controles ficam listados no briefing e na pausa, que usam o mesmo visual.

## Telas de morte e de fim de fase

Sair do bar, ou morrer (depois da sequência de zoom e câmera lenta), abre uma tela própria (`scripts/result_screen.gd`), no lugar do painel do briefing:

- O título é arremessado na tela como uma placa: entra grande e torto, assenta com rebote, ondula letra por letra e troca de cor sem parar. Na morte, alterna vermelho-sangue e branco-osso. No fim de fase, alterna as cores dos neons do bar.
- **Fontes:** Bungee, de letreiro urbano, nos títulos e na nota, e VT323, de dígitos de terminal, nas contagens. Ambas têm licença SIL OFL e ficam em `assets/fonts` com as licenças.
- Uma frase de efeito é digitada letra por letra. Na morte, sai uma aleatória, como "DEU RUIM." ou "FOI DE ARRASTA.".
- As linhas da contagem entram deslizando e os números rolam até o valor real. Cada passo dá um tranco na tela e um pulo no número.
- No fim de fase, depois de eliminados, tempo e tentativa, vêm os pontos e uma nota (S, A, B, C, D) que bate com clarão. Os pontos são 1000 por eliminação mais 100 por segundo abaixo de um minuto. São só exibidos e não mexem no jogo.
- **Efeito de tela** (`shaders/result_fx.gdshader`): a cena atrás é tingida (vermelho na morte, roxo no fim de fase), separada em RGB, varrida por listras diagonais e linhas de varredura, e rasgada em faixas a cada impacto.
- **Na morte:** Enter tenta de novo na hora, mesmo no meio da animação. Um clique só vale depois de 0,45 s, para o dedo ainda no gatilho não recomeçar sem querer.
- **No fim de fase:** o primeiro Enter ou clique completa a contagem, e o segundo vai para o quarto.

## Quarto do protagonista

Depois de cada noite vencida, o botão "IR PRO QUARTO" (ou Enter) leva ao apartamento do protagonista na Rua do Lavradio. É uma cena 3D com câmera parada e point-and-click, renderizada em 640×400 com filtro nearest, iluminada pelo abajur, pela luminária, pela tela do CRT e pelo luar da janela, com o skyline do Rio. Passar o mouse sobre um objeto clicável faz ele brilhar e mostra uma etiqueta:

- **Computador:** um clique leva a câmera até o monitor em 1,5 s; ao chegar, o tubo acende e mostra a página da MARÉ na dark web, um endereço .onion aberto no navegador **LOKI**. As encomendas da Celeste, pagas com favores (veja [Campanha](#campanha-pistas-e-upgrades)), aparecem em cartões, cada uma com seu modelo 3D PSX girando, o custo e o botão PEDIR, CHEGOU ou EM BREVE; passar o mouse num cartão mostra na barra de status o que a encomenda faz. Ao lado ficam os favores e, embaixo, as duas últimas mensagens da MARÉ. A página é uma cena 2D desenhada no próprio vidro do monitor (a superfície `pc_screen` do quarto), e o clique no vidro é levado até ela; enquanto a tela está aberta o quarto é renderizado no dobro da resolução, para o texto ficar legível. O X da janela, Esc ou um clique fora do monitor voltam a câmera em 0,8 s.
- **Estante de armas:** pistola, submetralhadora, escopeta, fuzil e minigun. Só ficam na parede as já conquistadas; as outras nem aparecem. Com o mouse em cima, a etiqueta mostra nome, tiros por minuto, pente, recarga (e chumbos, na escopeta), a frase da arma e se ela está na mão; um clique a leva para a próxima noite, sem painel, e ela fica com um brilho verde fraco. Os números já incluem as encomendas (pente, recarga). O topo do quarto mostra a arma equipada.
- **Quadro de investigação:** cada missão com seu estado e as pistas dela, com título e texto, ou "???" enquanto não forem achadas. O quadro em 3D tem recortes de jornal, fotos, a polaroide do fantasma, fichas, mapa da Lapa, post-its, alfinetes e fios de lã vermelha.
- **Janela:** sobre a cama, com batente, caixilho de madeira verde com duas folhas de vidraças pequenas, bandeira e peitoril; lá fora, sobrados com janelas acesas e, ao fundo, Santa Teresa, a lua e os Arcos. No quarto do final, de onde ele pode ir embora pela janela, as folhas ficam abertas para a rua (`Sashes_open` em vez de `Sashes_closed`, em `tools/build_room.py`).
- **Relatório da noite:** no topo, à direita, as pistas fotografadas, os favores ganhos e o que a noite desbloqueou.
- **Porta, "PRÓXIMA NOITE" ou Enter:** começa a noite seguinte.

O quarto é gerado por `tools/build_room.py` pelo Blender MCP:
- **Arquitetura e móveis:** vêm do *PSX modular house interior pack* (paredes, piso, teto, cama, mesa, cadeira, tapete, luminárias, rádio, relógio e outros) e do *Models pack psx* (monitor CRT e estante de livros). Os dois pacotes ficam extraídos em `tools/source/room`.
- **Modelados com o kit PSX do projeto:** a estante de armas, as cinco armas, o quadro, o gabinete, o teclado e a tela do PC.
- **Clique:** os objetos clicáveis se chamam `Hotspot_*` e `Weapon_*`, e o clique é testado nos triângulos de cada um.
- **Arquivo:** o resultado fica em `assets/room/room.glb`.
- **Encomendas:** `tools/build_shop.py` modela as cinco no mesmo kit PSX (carregador com extensão, tênis de sola de borracha, katana na bainha com alça, silenciador e pochete com dois pentes) e grava cada uma em `assets/shop/<encomenda>.glb`.

## Controles

| Controle | Ação |
| --- | --- |
| Enter / botão da tela | Começar, continuar ou tentar novamente |
| R, depois de morrer | Tentar novamente, a partir de 0,3 s após a morte |
| WASD / setas | Mover na direção da tela |
| Mouse | Mirar no corpo do alvo |
| Botão esquerdo, pode segurar | Atirar, ou cortar com a katana |
| F | Trocar entre a katana e a arma |
| Roda do mouse | Zoom: aproxima até 57% da visão inteira e afasta até ela, que é o máximo |
| R | Recarregar o pente da arma; reserva ilimitada |
| Shift / Q / botão direito, segure | Modo espectro |
| Esc | Pausar / continuar |
| G | Modo deus: liga e desliga, a qualquer momento |

**Zoom.** A roda do mouse aproxima e afasta em passos suaves. A visão inteira da fase é o mais longe; o mais perto é o tamanho 15 contra 26,5, cerca de 57% da área. Esse limite fica longe o bastante para não expor de perto as costuras dos modelos e texturas PS1. A visão aproximada segue o herói, mas desliza nas bordas para nunca mostrar algo que a visão inteira não mostra. O zoom de cada abate, a entrada na fase e a sequência de morte partem do zoom escolhido. O zoom vale entre tentativas e fases. A troca de arma ficou só no F. A regra fica em `main.gd` (`zoom_view`, `_view_focus`, `PLAYER_ZOOM_MIN`). O teste é `tests/zoom_test.gd`, e `tests/zoom_capture.gd` grava longe, meio e perto no bar e no casarão em `.qa/zoom`.

**Modo deus.** As balas continuam acertando o herói, mas ricocheteiam em faíscas e ele não morre. Todo o resto funciona igual: inimigos, abates, espectro, saída e vitória. O modo vale entre tentativas e fases até ser desligado. O HUD mostra MODO DEUS sob o relógio, e o contorno do herói fica dourado no lugar do ciano. A regra fica em `Simulation.toggle_god()` e `die()`. O teste é `tests/god_test.gd`, e `tests/god_capture.gd` grava o herói sob fogo em `.qa/god`.

No modo espectro o corpo fica translúcido em ciano, com tremulação em degraus no estilo PS1 que se intensifica quando a energia está acabando. Uma silhueta fraca continua visível dentro de paredes e móveis. O movimento deixa rastros fantasmas na pose congelada, um anel se expande no chão ao entrar e ao sair, e a tela perde saturação sob um leve tom ciano.

Um tiro mata o protagonista ou um inimigo. Paredes e móveis bloqueiam movimento, visão e tiros. Inimigos patrulham, investigam disparos e contornam obstáculos; eles precisam de um intervalo de reação antes de disparar. O modo espectro dura cerca de três segundos por carga, atravessa obstáculos e balas e impede disparos e recarga. A energia recupera após 0,8 s fora do poder. Ao esgotar, é necessário soltar o botão para ativar novamente. Se acabar dentro de um obstáculo, o personagem retorna ao ponto livre mais próximo. Perder o foco pausa automaticamente.

As regras seguem a versão `godot v2`: pistola, recarga e modo espectro. As versões anteriores permanecem em suas próprias pastas.

## Modelos e animações

Preparados usando a ponte local do **Blender MCP** instalada no computador. Não houve download de personagens externos:

- Protagonista: `Character_01.fbx`, do arquivo fornecido `Characters_psx (1).rar`.
- Inimigos: `Character_04.fbx` e `Character_08.fbx`, do mesmo arquivo.
- Movimentos: `UAL1_Standard.glb`, do ZIP fornecido **Universal Animation Library [Standard]**, por **Quaternius**, licença **CC0**. O texto da licença está em `tools/source/License.txt`.
- Animações aplicadas aos três modelos: repouso armado, caminhada, corrida, disparo, recarga e morte. A patrulha lenta usa `Walk_Loop`; a perseguição usa `Jog_Fwd_Loop`. A escolha e a cadência usam a velocidade real, incluindo colisões. Tiro e recarga conservam a animação de caminhada ou corrida das pernas.
- A biblioteca Standard fornecida tem 43 animações. Foram criadas **caminhada e corrida para trás** a partir de `Walk_Loop` e `Jog_Fwd_Loop`: o ciclo das pernas é invertido, a oscilação vertical do quadril é reduzida e uma pequena inclinação é adicionada. Os recursos editáveis estão em `assets/animations/walk_backward.tres` e `run_backward.tres`. A seleção compara a velocidade real com a direção da mira, com uma margem para evitar trocas rápidas nas diagonais. O torso continua mirando; recuar funciona também durante tiro e recarga.
- **Andar em qualquer direção.** Nenhuma das bibliotecas (UAL1 e UAL2) tem passo lateral; elas só trazem marchas para frente e, geradas aqui, para trás. Por isso as pernas não ficam presas à mira. O quadril, e as pernas com ele, gira na direção em que o corpo se desloca, ou na direção oposta na marcha para trás, até 92° (`LEG_TWIST_MAX` em `scripts/actor_visual.gd`). A coluna desgira o mesmo ângulo, dividido entre `spine_01`, `spine_02` e `spine_03`, e assim peito, braços e arma continuam na mira. A torção entra e sai suavemente, e o quadril volta para baixo do peito quando o personagem para. Vale para o herói e para os inimigos. `tests/strafe_test.gd` confere, em 8 direções, andando e correndo, que os pés pisam ao longo do deslocamento (0° de desvio; sem a torção, eram até 90°) e que peito e arma ficam na mira. `tests/strafe_capture.gd` grava o herói correndo de lado e nas diagonais em `.qa/strafe`.

### Universal Animation Library 2

Do ZIP **Universal Animation Library 2 [Standard]**, também do Quaternius e com licença CC0, vêm as poses dos inimigos, a morte por arremesso e os cortes da katana (ver **Katana**). Ele usa o mesmo esqueleto de 65 ossos do UAL 1, com os mesmos nomes e na mesma ordem, então as animações encaixam direto nos personagens. `tools/extract_ual2_clips.gd` lê `tools/source/UAL2_Standard.glb` e grava só os clipes usados em `assets/animations/ual2_clips.res`:

```powershell
godot --headless --path . --script res://tools/extract_ual2_clips.gd
```

**Inimigos desprevenidos.** Cada inimigo tem uma pose do dia a dia no `assets/level.json` (`"pose"`). Enquanto não viu o jogador, ele a faz com o tronco, por cima da caminhada da patrulha. A IA, as rotas e os tempos não mudam.

| Pose | Clipe | Mão | Arma |
| --- | --- | --- | --- |
| `drink` | `Consume` + 3 s segurando a garrafa (`Drink_Loop`) | garrafa na esquerda | continua na mão direita |
| `phone` | `Idle_TalkingPhone_Loop` | celular na direita, no ouvido | guardada |
| `arms` | `Idle_FoldArms_Loop` (leão de chácara na entrada) | — | guardada |

- Cada inimigo começa num ponto diferente do ciclo, para o bar não beber em sincronia.
- Quando ele vê o jogador, solta a pose na hora e volta à postura armada. Quando esquece o jogador, volta à pose.
- Garrafa e celular são peças mínimas (um cilindro de 6 lados e uma caixa) presas ao punho, como as armas.

**Arremesso por escopeta e fuzil.** Quando a morte é por escopeta ou fuzil e o corpo não é cortado ao meio:

- `Hit_Knockback` substitui o `Death01`. O corpo vira de frente para quem atirou, desliza 0,8 m para trás na direção do tiro e cai de costas.
- O deslize para antes de qualquer parede (`wall_hit` da simulação) e deixa um rastro de sangue no chão.
- O desmembramento sorteado continua acontecendo junto.
- Pistola, submetralhadora e os tiros dos inimigos mantêm o `Death01`.

É só apresentação: a posição do inimigo na simulação não muda.

### Variações nos acertos fatais

O desmembramento depende da arma que matou. A bala leva a arma que a disparou até o evento de morte:

| Arma | Corpo inteiro | Cabeça | Braço | Perna | Cortado no meio |
| --- | --- | --- | --- | --- | --- |
| Pistola e submetralhadora (e os inimigos) | 55% | 15% | 15% | 15% | — |
| Escopeta e fuzil | — | 25% | 25% | 25% | 25% |
| Minigun | — | — | — | — | 100% |

Cortado no meio, o corpo se divide na cintura. Tudo acima do quadril (peito, cabeça e braços) vira uma peça sólida e texturizada, com uma tampa vermelha no corte. Ela é lançada na direção do tiro, girando para trás, e assenta deitada ao longo da coluna. O quadril e as pernas continuam no esqueleto: ficam em pé por 0,35 s e então caem com a animação original `Death01`. As duas pontas do corte esguicham sangue em pulsos que enfraquecem por cerca de um segundo, e alguns pedaços de vísceras voam. As duas metades ficam no chão como cadáver até reiniciar e nunca são removidas pelo limite de partículas.

Nos tiros de pistola e submetralhadora, cada acerto fatal tem 55% de chance de manter o corpo completo, 15% de fragmentar a cabeça, 15% de separar um dos braços e 15% de separar uma das pernas. A escolha é visual e usa um gerador aleatório próprio; não muda precisão, dano, colisões, IA ou condições de vitória. Funciona no protagonista e nos inimigos. Reiniciar restaura todas as partes.

As partes conservam a textura do personagem, são lançadas com o impacto e assentam no chão. A cabeça se divide em fragmentos. A malha que permanece no corpo continua ligada ao mesmo esqueleto e executa **a animação original `Death01`, com os mesmos movimentos e duração**. Os arquivos originais dos personagens e a animação de morte não são modificados. Fragmentos soltos são removidos após 12 segundos e entram no limite de partículas da cena.

Os personagens PSX têm rig Mixamo com uma pose corretiva no FBX. `tools/build_characters.py` amostra a malha e os ossos nessa pose, adapta a malha ao rig UAL, transfere os pesos e exporta três GLBs com animações e texturas. O cenário foi criado no Blender MCP por `tools/build_environment.py`, que também gera as texturas procedurais. A fonte editável está em `tools/source/lapa.blend`. A montagem completa com os nove personagens está em `tools/source/hotline_rio_3d.blend`.

## Estrutura

- `assets/level.json` e `assets/level_2.json`: uma fase cada, com mapa em metros, obstáculos, início, saída, patrulhas, lâmpadas e textos. São a fonte comum para cenário e simulação.
- `scripts/simulation.gd`: movimento no plano XZ, colisões, navegação A*, projéteis contínuos, IA, recarga, espectro, morte e vitória. Não depende da renderização.
- `scripts/actor_visual.gd`: modelos, materiais, arma presa ao punho da mão direita, clipes por arma e reprodução de animações.
- `scripts/backward_gait.gd`: criação dos ciclos para trás a partir dos movimentos originais.
- `scripts/body_parts.gd`: separação dos triângulos por região, remoção visual de membros, cortes e captura da geometria animada para fragmentos rígidos.
- `scripts/combat_effects.gd`: rastros que terminam na colisão, sangue no chão, gotas, cápsulas, fragmentos e tremor. Clarões e luz curta ficam presos ao cano da arma no visual do personagem.
- `scripts/main.gd`: cena 3D, luz noturna e lâmpadas, câmera com zoom ao eliminar, controles e interface.
- `scripts/scenery_grade.gd`, `scripts/contact_shadows.gd` e `scripts/actor_look.gd`: gradação do cenário, sombreamento PS1 com sombras de contato, moldura noturna e destaque dos personagens vivos (só apresentação).
- `scripts/result_screen.gd`: telas de morte e de fim de fase.
- `scripts/hud.gd`: HUD de combate; o briefing e a pausa ficam pendurados nele.
- `assets/characters` e `assets/environment`: recursos prontos para importação pelo Godot.

O jogo não tem salto nem desníveis: combate e navegação usam o plano do chão. Os obstáculos também recebem formas `StaticBody3D` correspondentes na cena. Os rastros usam os pontos reais da trajetória e param na primeira colisão. Sangue fica no cenário até reiniciar, com limites de manchas e partículas para evitar acúmulo sem fim. Pausar congela efeitos e animações; reiniciar limpa os efeitos. O tremor afeta apenas a imagem, mantendo a mira lógica estável.

## Reconstruir com Blender MCP

Com o add-on **Blender MCP** ativo na porta local 9876 e Node.js disponível, execute na raiz deste repositório:

```powershell
node 'godot 3d/tools/mcp_call.cjs' 'godot 3d/tools/build_characters.py'
node 'godot 3d/tools/mcp_call.cjs' 'godot 3d/tools/build_environment.py'
node 'godot 3d/tools/mcp_call.cjs' 'godot 3d/tools/build_lavradio.py'
node 'godot 3d/tools/mcp_call.cjs' 'godot 3d/tools/build_santa_teresa.py'
```

Os scripts usam os arquivos extraídos em `tools/source`. `build_characters.py` trabalha na cena aberta, então não o execute sobre um trabalho não salvo no Blender. `build_environment.py` monta o cenário numa cena temporária e a remove depois de exportar, deixando o arquivo aberto como estava. Reimporte os GLBs no Godot após reconstruir. Para alterar colisões ou layout, edite o JSON da fase e reconstrua o cenário dela. Os cenários das fases 2 a 4 também rodam headless, por exemplo `blender -b --factory-startup --python 'godot 3d/tools/build_santa_teresa.py'`.

A abertura não passa pelo MCP. Exportar personagens com esqueleto a partir de uma cena temporária derruba o depsgraph do Blender 5.2, então `build_intro.py` roda num Blender headless descartável, sem tocar no arquivo aberto:

```powershell
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup --python 'godot 3d/tools/build_intro.py'
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup --python 'godot 3d/tools/build_intro_bar.py'
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup --python 'godot 3d/tools/build_virada.py'
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup --python 'godot 3d/tools/build_intro_audio.py'
```

`build_intro_bar.py` e `build_intro_audio.py` não precisam dos pacotes de personagens; o som leva cerca de 1 min. `build_virada.py` precisa dos FBX de `Character_Male_40`, `Character_Male_56` e `Character_26_Doctor` (pasta `Rig` do `Characters_psx_02`) copiados para `tools/source/Characters_psx/Models/Male`, e das texturas deles em `Textures`.

Os clipes das armas longas seguem o mesmo caminho pelo mesmo motivo. As poses foram ajustadas pelo MCP, chamando `Poser.pose()` na cena ativa do Blender aberto; a exportação roda headless. O script lê `assets/characters/hero.glb` e `assets/weapons/weapons.json`, então rode depois de `build_room.py` se as armas mudarem:

```powershell
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup --python 'godot 3d/tools/build_weapon_anims.py'
```

Depois de reimportar os personagens, os ciclos derivados podem ser reconstruídos na pasta do projeto com `godot --headless --path . --script res://tools/make_backward_gaits.gd`. Isso gera somente os dois recursos de movimento para trás.

## Verificação

Na pasta deste projeto, com o executável do Godot disponível como `godot`:

```powershell
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tests/simulation_test.gd
godot --headless --path . --script res://tests/visual_test.gd
godot --headless --path . --script res://tests/runtime_test.gd
godot --headless --path . --script res://tests/effects_test.gd
godot --headless --path . --script res://tests/gore_test.gd
godot --headless --path . --script res://tests/playthrough.gd
godot --headless --path . --script res://tests/playthrough.gd -- --level=2
godot --headless --path . --script res://tests/playthrough.gd -- --level=3
godot --headless --path . --script res://tests/playthrough.gd -- --level=4
godot --headless --path . --script res://tests/playthrough.gd -- --level=5
godot --headless --path . --script res://tests/intro_test.gd
godot --headless --path . --script res://tests/room_test.gd
godot --headless --path . --script res://tests/entrance_test.gd
godot --headless --path . --script res://tests/look_test.gd
godot --headless --path . --script res://tests/result_test.gd
godot --headless --path . --script res://tests/hud_test.gd
godot --headless --path . --script res://tests/pose_test.gd
godot --headless --path . --script res://tests/katana_test.gd
godot --headless --path . --script res://tests/levels_test.gd
godot --headless --path . --script res://tests/strafe_test.gd
godot --headless --path . --script res://tests/god_test.gd
godot --headless --path . --script res://tests/zoom_test.gd
godot --headless --path . --script res://tests/menu_test.gd
godot --headless --path . --script res://tests/campaign_test.gd
godot --headless --path . --script res://tests/wisp_test.gd
godot --headless --path . --script res://tests/camera_test.gd
godot --headless --path . --script res://tests/level_select_test.gd
godot --headless --path . --script res://tests/civilian_test.gd
godot --headless --path . --script res://tests/proprietor_test.gd
godot --headless --path . --script res://tests/telerio_test.gd
godot --headless --path . --script res://tests/glass_test.gd
godot --headless --path . --script res://tests/patient_test.gd
godot --headless --path . --script res://tests/sindico_test.gd
godot --headless --path . --script res://tests/music_test.gd
godot --headless --path . --script res://tests/sound_test.gd
godot --headless --path . --script res://tests/feel_test.gd
```

`tests/menu_capture.gd` grava o menu, a página de idiomas, a tela da missão (digitando e completa) e a pausa, em português e inglês, em `.qa/menu`.

`tests/result_capture.gd` grava quadros das telas de morte e de fim de fase em `.qa/results`. `tests/beat_capture.gd` grava a saída se acendendo e a sequência de morte em `.qa/beat`. `tests/katana_capture.gd` grava a katana na mão (guarda, os dois cortes, a empunhadura de lado e de frente, um corte que mata e o HUD) em `.qa/katana`. `tests/pose_capture.gd` grava as três poses (paradas, andando e depois do alerta) e uma morte por escopeta em `.qa/poses`. `tests/shade_capture.gd` grava o enquadramento de jogo e vistas próximas de mesas, balcão, bancada, cozinha e depósito em `.qa/<pasta>`, para comparar o sombreamento antes e depois. `tests/hud_capture.gd` grava o HUD (briefing, combate, munição baixa, bar limpo) em `.qa/hud`. `tests/level_capture.gd` faz o mesmo para qualquer fase, com os quatro quadrantes de perto: `godot --path . --script res://tests/level_capture.gd -- 3` grava em `.qa/level3`.

`tests/look_capture.gd` grava o mesmo enquadramento de jogo e recortes ampliados do salão, da cozinha e do balcão em `.qa/<pasta>`, para comparar antes e depois: `godot --path . --script res://tests/look_capture.gd -- depois`.

`tests/room_capture.gd` grava o quarto, um objeto em destaque e o painel do arsenal em `.qa/`. `tests/weapons_capture.gd` grava as cinco armas na mão e um disparo de escopeta.

`tests/intro_capture.gd` grava um quadro de cada plano da abertura, como aparece na TV da sala, em `.qa/`.

O teste de partida completa usa somente os controles de movimento, mira, tiro e espectro, com as regras normais e os oito inimigos originais. Os testes de animação conferem pesos distribuídos pelo corpo, escolha de caminhada/corrida e cadência, ciclos para trás derivados dos originais, mira durante o recuo, movimentos dos ossos, recarga em movimento, pausa e queda ao chão. Os testes de efeitos verificam colisão dos rastros, sangue, clarão, cápsulas, pausa, limpeza e limites de recursos. Os testes de desmembramento verificam as seis regiões dos três modelos, captura de geometria texturizada, distribuição aleatória, restauração, assentamento no chão e preservação dos quadros e do relógio de `Death01`. `tests/capture.gd`, `tests/effects_capture.gd`, `tests/gore_capture.gd` e `tests/phase_capture.gd` capturam o jogo com renderização real para inspeção visual; requerem interface gráfica.

Referências técnicas: [animação e retargeting no Godot](https://godotengine.org/article/animation-retargeting-in-godot-4-0/) e [amostragem de trilhas de animação](https://docs.godotengine.org/en/4.4/classes/class_animation.html).
