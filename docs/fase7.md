# Fase 7 — Fonte da Saudade (Lagoa): leilão da Fundação Pilar

Projeto do subagente arquiteto (o mesmo das fases 5 e 6). A planta está em `assets/level_7.json`.

## Mecânica nova: civis (e a pose `hold`)
Layout: `"civilians":[{"p":[x,z],"angle":a,"pose":"drink"}]`, `"flee":[[x,z],...]`. Não entram em `enemies`, `kills` nem `cleared()`.
- reset(): `civilians[i] = actor(p,angle)` + `{"id":i,"pose":pose,"state":"calm","route":[],"repath":0.0,"gore":"","used":false}`.
- Pânico: todo evento `shot` (qualquer time) põe todos os civis `calm` em `flee` (evento `panic` uma vez). Uma morte (inimigo ou civil) a até 5 m de um civil `calm`, com `can_see`, põe só esse civil em fuga.
- Fuga: 2,6 m/s até o ponto de `flee` mais próximo (distância reta), pela rota `path()` com repath de 0,45 s, como os inimigos. A menos de 0,4 m: `state="gone"`, `alive=false`, sai de cena (evento `civilian_escaped`).
- Acerto: as balas do herói testam civis vivos com `segment_circle(r 0.30)`, como inimigos; `_strike()` da katana também. `kill_civilian(c,dir,gun)`: `alive=false`, `gore=gore_variant(gun)`, `civilians_killed += 1`, evento `blood` com `"civilian":true,"kind":"human"`. As balas inimigas atravessam civis.
- Civis não veem, não alertam ninguém, não são sólidos e não colidem.
- Regra da casca: um civil morto inteiro (`gore==""`, `not used`) é corpo para as chamas. `_nearest_body` percorre `enemies+shells+civilians`. `_rise` num civil segue o caminho do saco: `used=true`, novo inimigo anexado em `nearest_free(p)`, o cadáver some.
- Fim de fase: `civilians_killed` vai para o resumo da noite e para a campanha (`Campaign.state.civilians_killed`). Nunca reprova.
- Pose `hold`: Inquilino disfarçado de convidado segura a taça sem beber (`Drink_Loop` congelado). Sem sombra, como todo Inquilino.
- Visual: civis com roupa de convidado (terno, vestido), com sombra e taça.

## Prates (inimigo 13)
Inquilino, reação 0,6, ao telefone no escritório do mezanino, virado para a porta do bar. Carrega o `convite_prates`. Os três sacos da adega (o "lote especial") ficam a 4,1–4,5 m dele, através da parede. Morto inteiro, a chama dele veste um saco e ele levanta de novo, "dobrando como papel molhado". Respostas: agarrar a chama como espectro (Mão do Avesso), katana pelo lado da adega (65 pontos cegos), ou rasgar os sacos antes. Se levantar num saco, o convite fica no primeiro corpo.

## Recompensa
`recuperacao` — Campaign.mods: `m.regen_delay = .5; m.mana_regen = 22.0`. O fôlego volta mais cedo e mais rápido.

## Celeste (Campaign.CELESTE)
- after 6: "A fita é verdadeira. O homem de terno é Edmundo Prates, o perito dos meus laudos. Sábado ele vai a um leilão na Fonte da Saudade. — C."
- after 6, ordem_compra: "Comitê Ordem na Casa pagando fuzil? Isso é a campanha do Castelar. Não diga esse nome em voz alta. — C."
- after 6, agenda_avelar: "Ilha Fiscal, 20/11, Baile do Síndico. Eu achava que era piada de gente rica. — C."
- after 7: "Pelo que você contou, o Prates morreu duas vezes. A segunda valeu. Agora é a Ilha Fiscal. — C."
- after 7, catalogo_lote12: "Retrato de 1979, o mesmo rosto de hoje. O Castelar não envelhece porque não é mais ele. — C."

## Fim de ato
O `act_end` "CONTINUA" sai do level_6.json e vai para o level_7.json: "Prates dobrou duas vezes e não levantou mais. / No bolso dele, um convite: Ilha Fiscal, 20 de novembro, traje de 1889." Tip: "08  —  ILHA FISCAL  ·  EM BREVE".

## Cenário (tools/build_lagoa.py → assets/environment/lagoa.glb)
Casa modernista dos anos 60: pilotis brancos, concreto aparente, painéis de madeira, vidro (visto cortado a 1,4 m).
ROOMS7=[('patio',-12.8,-7.6,3.6,7.7),('jardim',-7.2,12.55,3.6,7.7),('cozinha',-12.8,-8.4,-2.4,3.2),('adega',-12.8,-8.4,-7.3,-2.8),('escritorio',-8.0,-3.6,-7.3,-2.8),('bar',-8.0,-3.6,-2.4,3.2),('salao',-3.2,7.2,-7.3,3.2),('varanda',7.6,12.55,-7.3,3.2)]
SKINS7: patio whitewash 1.4 | jardim concrete 1.4 | cozinha white_tile 1.3 | adega stonewall 1.4 | escritorio wood 1.2 (friso) | bar wood 1.0 (friso) | salao whitewash 1.4 | varanda whitewash 1.4 | outside whitewash 1.4.
Pisos lisos, sem xadrez: pátio cimento, jardim grass com caminhos em pedra, cozinha white_tile, adega vermelhão liso, escritório tacos, bar e salão granilite, varanda deck (tábuas de teca lisas), piscina e espelhos d'água com água e borda branca.
Portas (soleira granito): portão de serviço (-11.8,7.7,1.4,.45), cozinha↔pátio (-11.2,3.2,1.4,.4), porta principal (1.0,3.2,2.4,.4), bar↔cozinha (-8.4,-0.4,.4,1.4), adega↔cozinha (-11.2,-2.8,1.4,.4), escritório↔bar (-6.6,-2.8,1.4,.4), adega↔escritório (-8.4,-5.6,.4,1.4), bar↔salão (-3.6,-1.8,.4,1.6) e (-3.6,1.0,.4,1.6), salão↔varanda, portas de vidro abertas (7.2,-5.2,.4,1.6) e (7.2,-0.6,.4,1.6), jardim↔varanda (9.4,3.2,1.4,.4), escada da lagoa (12.55,-0.6,.45,1.4), vão da sebe (-7.6,4.4,.4,1.4).
Tipos novos:
- pool (h 0,3): borda branca, água.
- chairs: fileira de cadeiras Tiffany douradas viradas para o púlpito (-z), h 0,9.
- lectern: púlpito de madeira com plaqueta FUNDAÇÃO PILAR virada para +z, martelo e microfone, h 1,2.
- cocktail: mesa alta redonda, toalha branca, taças, h 1,1.
- winerack: treliça de madeira com garrafas, h 1,4.
Reaproveitados: hedge, plinth, easel, counter e plant (L6), sofa, desk, shelves, safe, stove, prep, table, crate, drums, pillar (variante branca), balustrade (parapeito de concreto branco com corrimão de aço).
Decoração: telão "LOTE 12" com o retrato do Castelar de 1979 e a faixa "FUNDAÇÃO PILAR — LEILÃO BENEFICENTE" no fundo do salão; torre de champanhe no balcão do bar; trilho da adega [[-9.4,-7.0],[-9.4,-3.2]] a 2,7 m com os três sacos e caixa "LOTE ESPECIAL"; luzes de chão no jardim; luminárias de fio no pátio de serviço.
Exterior: lagoa à direita (x > 15) e atrás (z < -9.6), água escura com um colar de luzes na orla; píer com o barco do bufê (o mesmo da fase 8) atracado, sem pedalinho; Morro dos Cabritos escuro atrás com a silhueta acesa do Cristo; casarão vizinho à esquerda (`kit.sobrado(...,side=True)`); rua, calçada, sedã preto e tenda de manobrista na frente.
