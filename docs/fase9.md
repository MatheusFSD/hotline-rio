# Fase 9 — Estúdios TeleRio, Cidade Nova (Ato 3, noite 1)

Projeto do subagente arquiteto (o mesmo das fases 5 a 8). A planta está em `assets/level_9.json`.

## 1. Quadro de luz (`"breaker":{"p":[x,z],"angle":a}`)
- Montagem: a até 0,5 m da face de uma parede, fora de sólidos. Não é sólido. `angle` só orienta o modelo.
- Acerto: bala do herói passando a até 0,25 m de `p` (mesmo teste das câmeras), ou corte de katana com `p` a até `KATANA.reach + RADIUS` (2,1 m), dentro do arco e com linha livre (mesmo teste dos sacos). O tiro é ouvido normalmente.
- Efeito: `sim.dark = true`, evento `{"type":"blackout","p":p}`. Sem volta até o retry (`reset()` zera `dark`).
- No escuro, só para inimigos `kind == "human"`: alcance de visão 9,75 → 4,875 m; reação × 2.
- Sem mudança: o raio de 2,1 m de "sempre nota", o cone de ±1,1 rad, a audição de 9,25 m, Inquilinos, Proprietários e câmeras.
- Godot: apaga as luzes das `lamps` em 0,15 s, com tremida. Ficam a luz da saída, os emissivos (monitores, letreiros) e uma lua azul fraca.

## 2. Jairo (`civilians[i].vip = "jairo"`)
- Não foge: no pânico fica no lugar, ao telefone.
- É o único civil que as balas inimigas acertam. Tiro e katana do herói o matam como a qualquer civil.
- Morte: não reprova. Evento `vip_down`; entra em `civilians_killed`; `Campaign.state.jairo_dead = true` ao fim da noite. O retry o devolve vivo.
- A credencial sai do mesmo jeito, vivo ou morto.

## 3. Recompensa `corte_saida` (+ unlock `credencial`)
- Campaign.mods: `m.exit_cut = true`.
- Ao soltar o espectro (solto ou sem fôlego), com a katana na mão e sem recarga de golpe, sai um corte que acerta 0,1 s depois, em vez de 0,2 s. Nada de corte durante o espectro.
- `credencial`: só o id de unlock por enquanto. Futuro: no briefing com planta, ponto violeta em quem é `inquilino` e losango em quem é `proprietario`.

## 4. Celeste (depois da 9)
- "Um atentado com dublê na véspera da eleição. O dublê vai ter a sua cara, garoto. — C."
- Jairo vivo: "O Jairo me ligou chorando. Disse que viu a sua sombra e a dos outros não. Ele vai falar. — C."
- Jairo morto: "O Jairo não saiu do camarim. A credencial dele está com você. Use bem. — C."
- com fitas_arquivo: "1994, 2010, hoje: o mesmo rosto. O Castelar de verdade morreu na Estrada do Joá em 1977. Eu tenho a ficha. — C."

## 5. Atos
L8 fecha o Ato 2 (cartela e noticiário virada_2) e agora segue para a fase 9. L9 leva o card provisório "CONTINUA" (`menu:true`, tip "10  —  JOÁ  ·  EM BREVE"). A cena do quarto revirado fica de fora.

## 6. Cenário (tools/build_telerio.py → assets/environment/telerio.glb)
Paleta: azul-marinho TeleRio, vermelho "Alerta Rio", cinza chumbo, branco frio dos monitores. O espírito de `assets/intro/studio.glb`: telão curvo, bancada, treliça de luz.
ROOMS9=[('recepcao',-12.8,-5.6,3.4,7.7),('redacao',-5.2,4.6,3.4,7.7),('corredor',-8.0,-5.6,-7.3,3.0),('camarim',-12.8,-8.4,-2.4,3.0),('arquivo',-12.8,-8.4,-7.3,-2.8),('estudio',-5.2,4.6,-7.3,3.0),('edicao',5.0,12.55,-7.3,-2.8),('garagem',5.0,12.55,-2.4,7.7)]
Pisos lisos, sem xadrez: recepção granilite, redação e edição carpete, estúdio `studio_floor` (cinza-chumbo fosco), corredor cimento, camarim tacos, arquivo concrete, garagem oil_concrete.
Tipos novos: anchordesk (bancada curva do Alerta Rio), studiocam (câmera de estúdio em pedestal, tally vermelho), van (unidade móvel branca com faixa azul e parabólica). Reaproveitados: counter, sofa, plant, desk, shelves, vanity, console, crate.
Decoração: telão curvo "ALERTA RIO" e treliça de luz no estúdio; grade de monitores na edição; etiquetas "1994" e "2010" no arquivo; o quadro de luz com a placa "PERIGO" no corredor.
Exterior: avenida e calçada na frente; mastro vermelho e branco da TeleRio; o Estúdio B (outro prédio da TeleRio) colado à direita, onde a saída da garagem termina numa porta; o Teleporto em tamanho real atrás do pátio, com torres que saem do quadro; sobrados antigos à esquerda.
