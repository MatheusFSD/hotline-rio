# Fase 8 — Ilha Fiscal: o Baile do Síndico (fim do Ato 2)

Projeto do subagente arquiteto (o mesmo das fases 5 a 7). A planta está em `assets/level_8.json`; o noticiário, em `assets/news/virada_2.json`.

## Mecânica nova: Proprietário (`"kind":"proprietario"`)
Mesmo inimigo de sempre (vê, mira, reação, um tiro mata), com o poder do herói.
- Constante: `PROPRIETOR := {"blink":.3,"phase":1.5,"cooldown":4.0,"flank":3.5,"speed":3.2}`. Estado por inimigo: `phase_state` (""|"blink"|"phasing"), `phase_t`, `phase_cd` (começa em 1,0), `phase_goal`, `phasing`.
- Disparo (vivo, alertado, sem `rising`, `phase_state==""`, `phase_cd<=0`): (a) o herói atira a até 9,25 m dele; ou (b) logo depois de ele mesmo atirar.
- Piscar, 0,3 s: parado, não atira, **pode ser morto**. Evento `{"type":"blink","victim":id+1}`; o contorno tremula em violeta.
- Avesso, 1,5 s: `phasing=true`. Vai reto a 3,2 m/s até `phase_goal`, ignorando sólidos (preso em `bounds.grow(-RADIUS)`). Balas do herói e katana o ignoram; ele não atira; continua vendo e lembrando pela regra normal.
- `phase_goal` = posição do herói + 3,5 m na perpendicular da linha herói→inimigo, do lado mais longe da mira do herói. Se esse ponto estiver bloqueado ou fora dos limites, o outro lado. Se os dois falharem, 2 m atrás da posição atual, afastando-se do herói.
- Fim: `p = nearest_free(p)`, `phasing=false`, `phase_cd = 4.0`, `windup = 0`.
- Morte: só fora do Avesso. Corpo inteiro solta chama de 4 m/s; o corpo que ela levanta vira Proprietário. A Mão do Avesso pega a chama.
- Visual: no Avesso, translúcido violeta (o efeito de espectro do herói, em violeta). O Olho do Avesso já o revela.

## Castelar e o fim do ato
Castelar não é inimigo. O discurso fica no púlpito da sacada; o `act_end` conta a virada: ele olha para o herói no Avesso, os lustres apagam, a lancha some. O disfarce de garçom é só história.

## Recompensa `veu`
Campaign.mods: `m.veil = true`. Como espectro, inimigos humanos não veem o herói. Câmeras, Inquilinos e Proprietários continuam vendo.

## Noticiário (virada_2.json)
Campo opcional por segmento: `"when"`. `"civilians"` aparece só se `Campaign.state.civilians_killed > 0`; `"clean"` só se `== 0`; sem o campo, sempre. Filtrado em `NewsCard.load_news`.

## Celeste (depois da 8)
- "Ele te viu no Avesso, garoto. Nenhum deles tinha visto. Fique longe da janela por uns dias. — C."
- com discurso_sindico: "Quarenta mil. Ele diz triagem e eu leio necrotério. E a TeleRio vai transmitir como programa de governo. — C."
- com lista_convidados: "Sete nomes no conselho e um H. Jairo Trovão é gente. Gente com medo fala. — C."

## Cenário (tools/build_ilha.py → assets/environment/ilha.glb)
Palácio neogótico verde-acinzentado (`stonewall` frio, cantaria cinza, ogivas creme), torreão central com relógio.
ROOMS8=[('cozinha',-12.8,-8.4,3.0,7.7),('copa',-12.8,-8.4,-2.0,2.6),('cerimonial',-12.8,-8.4,-7.3,-2.4),('baile',-8.0,5.6,-7.3,2.6),('chapelaria',-8.0,-3.4,3.0,7.7),('torreao',-3.0,2.2,3.0,7.7),('sacada',6.0,12.55,-7.3,-2.8),('antessala',6.0,12.55,-2.4,2.6),('varanda',2.6,12.55,3.0,7.7)]
SKINS8: cozinha white_tile 1.3 | copa white_tile 1.0 | cerimonial wood 1.2 (friso) | baile green_paint 1.4 | chapelaria wood 1.0 | torreao stonewall 1.4 | sacada stonewall 1.4 | antessala green_paint 1.2 (friso) | varanda stonewall 1.4 | outside stonewall 1.4.
Pisos lisos, sem xadrez: baile e antessala `parquet` (tábuas largas de cumaru em tom único); cerimonial tacos; torreão e chapelaria granilite; cozinha e copa cimento; sacada, varanda e cais pedra lisa.
Portas (soleira granito): (-11.4,7.7,1.4,.45), (-12.4,2.6,1.4,.4), (-8.4,5.4,.4,1.4), (-8.4,-0.4,.4,1.6), (-11.4,-2.4,1.4,.4), (-8.4,-5.6,.4,1.4), (-6.6,2.6,1.4,.4), (-3.4,4.6,.4,1.4), (-1.6,2.6,2.4,.4), (2.2,4.6,.4,1.4), (5.6,-0.6,.4,1.6), (5.6,-5.2,.4,1.6), (9.4,-2.8,1.4,.4), (8.0,2.6,1.4,.4), escada do cais (12.55,4.6,.45,1.4).
Decoração: três vitrais ogivais âmbar com o monograma "1889" no fundo do baile; lustres dourados a 2,7 m; faixa "CASTELAR — ORDEM NA CASA" e bandeiras na sacada; bandejas e taças na cozinha.
Exterior: a Baía à noite em volta; cais de serviço à esquerda com o barco do bufê; cais principal à direita com o rastro de espuma da lancha; ponte para a Ilha das Cobras com lampiões atrás à esquerda; colar de luzes de Niterói e a Ponte Rio–Niterói baixa ao fundo à direita; armazém da Marinha (`kit.sobrado(...,side=True)`) à esquerda.
