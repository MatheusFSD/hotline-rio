# Fases 10 a 12 — projeto do arquiteto (todas já produzidas)

Projeto do subagente arquiteto (o mesmo das fases 5 a 9), feito antes da produção. Nada aqui está em `Simulation.LEVELS` nem é carregado pelo jogo ou pelos testes. Para produzir uma fase, os arquivos dela vão para `assets/` e o código pedido em `fase10-12.md` é implementado.

| Arquivo | Fase | Mecânica nova |
| --- | --- | --- |
| `level_10.json` | 10, Mirante do Joá, "ÚLTIMA VISTA" — **produzida** (cópia em `assets/level_10.json`) | vidro (`"type":"glass"`) |
| `level_11.json` | 11, Clínica Santa Aurora, "ÚLTIMA CONSULTA" — **produzida** (cópia em `assets/level_11.json`) | pacientes sedados (`"patients"`) |
| `level_12a.json`, `level_12b.json`, `level_12c.json` | 12, o Síndico, em três etapas encadeadas — **produzida** (cópias em `assets/`) | regra do Síndico (`"boss"`), `"chain"`, `"night"` |
| `news/final_a.json`, `final_b.json`, `final_c.json` | os três finais — **produzidos** (cópias em `assets/news/`) | tokens `"bitter"` e `"souza"` em `"when"` |
| `fase10-12.md` | mecânicas, recompensas, Celeste, finais e cenários | |

Ordem: 10, depois 11, depois 12. A cartela "CONTINUA" anda junto: sai da fase 9 quando a 10 entrar, e da 10 quando a 11 entrar; a 12c a troca pelo final.

O validador do arquiteto passou nas cinco plantas (sem sobreposição, tudo alcançável, ninguém vê a entrada).
