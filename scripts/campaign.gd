extends RefCounted
## The campaign between nights (docs/narrativa.md, sections 5 and 6): the next night and the gun in
## hand, the clues found, what is unlocked (guns, spectre powers, tools, orders) and the favours
## owed by Celeste. Nothing here gives the hero an extra life: every unlock changes information,
## time, noise or reach. Kept as static state so the menu, main.gd and the room share it; written
## to user://campaign.json by real launches only (`persist`), so tests never leave a save behind.
const PATH := "user://campaign.json"
const START_UNLOCKS := ["pistol","katana"]
## Celeste's orders on the computer: cost in favours, nights cleared before she can get it.
const ORDERS := {
	"extended_mag":{"title":"CARREGADOR ESTENDIDO","text":"Pistola 12 → 18 tiros, submetralhadora 30 → 45.","cost":1,"after":2},
	"rubber_soles":{"title":"SOLA DE BORRACHA","text":"Quem está de costas só te nota a 1,4 m (era 2,1 m).","cost":1,"after":2},
	"back_sheath":{"title":"BAINHA NAS COSTAS","text":"Troca katana ↔ arma em 0,12 s (era 0,22 s).","cost":1,"after":4},
	"suppressor":{"title":"SILENCIADOR","text":"Tiro de pistola alerta a 4 m (era 9,25 m).","cost":2,"after":4},
	"mag_pouch":{"title":"POCHETE DE PENTES","text":"Recarga 20% mais rápida em todas as armas.","cost":1,"after":4}}
## What Celeste (MARÉ on the LapaNet) writes on the computer: after that many nights cleared and,
## for some, only if that clue was found. She first writes after the gafieira.
const CELESTE := [
	{"after":2,"text":"Vi a fita da CAM 03. Seu corpo estava frio na imagem. Eu conheço esse frio. — C."},
	{"after":2,"clue":"espelho_banheiro","text":"Batom no espelho? Guarde. Sombra é a primeira coisa que eu olho num corpo. — C."},
	{"after":3,"text":"Pilar Administração: CNPJ de 1978, sede num prédio que não existe. Quem compra quadro assim não quer quadro. — C."},
	{"after":3,"clue":"caderno_iara","text":"A Iara desenhou o que eu nunca tive coragem de escrever no laudo. Prenda o ar, garoto. — C."},
	{"after":4,"text":"A câmera do IML gravou isso ontem: um saco aberto andando no corredor. Sem sombra no piso. — C."},
	{"after":4,"clue":"pasta_armario","text":"E. Prates. Essa assinatura está nos laudos que sumiram da minha gaveta. — C."},
	{"after":5,"text":"Catorze cascas numa guia, escolta da Guardião. Eles têm um andar inteiro na Presidente Vargas. — C."},
	{"after":5,"clue":"livro_iml","text":"Aquela rubrica é minha. Eu assinei a entrada deles sem saber para onde iam. Desculpa, garoto. — C."},
	{"after":6,"text":"A fita é verdadeira. O homem de terno é Edmundo Prates, o perito dos meus laudos. Sábado ele vai a um leilão na Fonte da Saudade. — C."},
	{"after":6,"clue":"ordem_compra","text":"Comitê Ordem na Casa pagando fuzil? Isso é a campanha do Castelar. Não diga esse nome em voz alta. — C."},
	{"after":6,"clue":"agenda_avelar","text":"Ilha Fiscal, 20/11, Baile do Síndico. Eu achava que era piada de gente rica. — C."},
	{"after":7,"text":"Pelo que você contou, o Prates morreu duas vezes. A segunda valeu. Agora é a Ilha Fiscal. — C."},
	{"after":7,"clue":"catalogo_lote12","text":"Retrato de 1979, o mesmo rosto de hoje. O Castelar não envelhece porque não é mais ele. — C."},
	{"after":8,"text":"Ele te viu no Avesso, garoto. Nenhum deles tinha visto. Fique longe da janela por uns dias. — C."},
	{"after":8,"clue":"discurso_sindico","text":"Quarenta mil. Ele diz triagem e eu leio necrotério. E a TeleRio vai transmitir como programa de governo. — C."},
	{"after":8,"clue":"lista_convidados","text":"Sete nomes no conselho e um H. Jairo Trovão é gente. Gente com medo fala. — C."},
	{"after":9,"text":"Um atentado com dublê na véspera da eleição. O dublê vai ter a sua cara, garoto. — C."},
	{"after":9,"if":"jairo_alive","text":"O Jairo me ligou chorando. Disse que viu a sua sombra e a dos outros não. Ele vai falar. — C."},
	{"after":9,"if":"jairo_dead","text":"O Jairo não saiu do camarim. A credencial dele está com você. Use bem. — C."},
	{"after":9,"clue":"fitas_arquivo","text":"1994, 2010, hoje: o mesmo rosto. O Castelar de verdade morreu na Estrada do Joá em 1977. Eu tenho a ficha. — C."},
	{"after":10,"text":"A certidão é de 1977 e o legista que assinou morreu em 1978. Essa casca tem quarenta e nove anos, garoto. — C."},
	{"after":10,"clue":"ata_conselho","text":"Sete assinaturas. Com a lista do baile eu tenho o conselho inteiro, e quatro ainda andam por aí. — C."},
	{"after":11,"text":"Trinta renovações para a posse. Ele quer o palácio cheio de casca nova. Praça Mauá, meia-noite. — C."},
	{"after":11,"clue":"prontuario_souza","text":"Mandei a foto do prontuário para o Souza. Ele não acreditou até ver a assinatura. Ele vai estar na praça, do nosso lado. — C."}]

static var state := fresh()
## Off while a night is played from the level select (scripts/level_select.gd): the save stays as it was.
static var saving := true

## Celeste's messages so far, oldest first.
static func messages(of: Dictionary = state) -> Array:
	return CELESTE.filter(func(m): return _written(m,of)).map(func(m): return m.text)

## After enough nights; for some, only with that clue found, or with Jairo alive or dead ("if").
static func _written(m: Dictionary,of: Dictionary) -> bool:
	if of.cleared.size() < int(m.after): return false
	if m.has("clue") and not m.clue in of.clues: return false
	if m.has("if") and (m.get("if") == "jairo_dead") != bool(of.get("jairo_dead",false)): return false
	return true

static func fresh() -> Dictionary:
	return {"level":0,"weapon":"pistol","clues":[],"unlocks":START_UNLOCKS.duplicate(),"favors":0,"cleared":[],"civilians_killed":0,"jairo_dead":false}

static func exists() -> bool:
	return FileAccess.file_exists(PATH)

static func new_game(persist := true) -> void:
	state = fresh()
	saving = true
	if persist: save()

static func load_saved() -> bool:
	if not exists(): return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(data) != TYPE_DICTIONARY: return false
	saving = true
	state = fresh()
	state.merge(data,true)
	state.level = int(state.level)
	state.favors = int(state.favors)
	state.civilians_killed = int(state.civilians_killed)
	state.cleared = state.cleared.map(func(v): return int(v))   # JSON numbers come back as floats
	return true

static func save() -> void:
	if not saving: return
	var file := FileAccess.open(PATH,FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(state,"\t"))

## The four proofs (★) that, with Jairo alive, put the truth on air (Final A).
const PROVAS := ["ordem_compra","catalogo_lote12","fitas_arquivo","ata_conselho"]

## The ending the TV shows: "a" with Jairo alive and three proofs or more, else "b".
static func ending(of: Dictionary = state) -> String:
	var proofs := PROVAS.filter(func(id): return id in of.clues).size()
	return "a" if not bool(of.get("jairo_dead",false)) and proofs >= 3 else "b"

## Souza is on our side at the end if his file was taken at the clinic.
static func souza_saved(of: Dictionary = state) -> bool:
	return "prontuario_souza" in of.clues

static func has(id: String) -> bool:
	return id in state.unlocks

## A night won: its clues go on the board (each optional one found for the first time is a favour
## from Celeste), its story unlock is earned and the next night comes up. Returns what changed,
## for the room to show.
static func complete(index: int,layout: Dictionary,taken: Array,next: int,weapon: String,persist := false) -> Dictionary:
	var report := {"clues":[],"favors":0,"reward":{}}
	for entry in layout.get("clues",[]):
		if not entry.id in taken: continue
		var first: bool = not entry.id in state.clues
		report.clues.append({"title":entry.title,"text":entry.get("text",""),"required":entry.get("required",false),"new":first})
		if first:
			state.clues.append(entry.id)
			if not entry.get("required",false):
				state.favors += 1
				report.favors += 1
	var reward: Dictionary = layout.get("reward",{})
	if not reward.is_empty() and not has(reward.id):
		state.unlocks.append(reward.id)
		report.reward = reward
	for extra in reward.get("unlocks",[]):   # what else the night hands over (a gun from the armory)
		if not has(extra): state.unlocks.append(extra)
	if not index in state.cleared: state.cleared.append(index)
	state.level = next
	state.weapon = weapon
	if persist: save()
	return report

static func available(id: String) -> bool:
	return state.cleared.size() >= int(ORDERS[id].after)

## Orders one of Celeste's items, if it is on offer, not owned yet and the favours cover it.
static func order(id: String,persist := false) -> bool:
	var item: Dictionary = ORDERS[id]
	if has(id) or not available(id) or state.favors < int(item.cost): return false
	state.favors -= int(item.cost)
	state.unlocks.append(id)
	if persist: save()
	return true

## The simulation's modifiers for what is unlocked (Simulation.mods).
static func mods(unlocks: Array = state.unlocks) -> Dictionary:
	var m := {}
	if "folego_1" in unlocks: m.mana_drain = 29.0
	if "folego_2" in unlocks: m.mana_drain = 25.0   # the spectre lasts about four seconds
	if "extended_mag" in unlocks: m.magazine = {"pistol":18,"smg":45}
	if "rubber_soles" in unlocks: m.notice = 1.4
	if "back_sheath" in unlocks: m.swap = .12
	if "suppressor" in unlocks: m.pistol_alert = 4.0
	if "mag_pouch" in unlocks: m.reload_mult = .8
	if "olho_avesso" in unlocks: m.eye = true    # as a spectre, what lives in a casca shows violet
	if "mao_avesso" in unlocks: m.hand = true    # as a spectre, touching a shadow-flame ends it
	if "recuperacao" in unlocks:   # the breath comes back sooner (.8 → .5 s) and faster (18 → 22 /s)
		m.regen_delay = .5
		m.mana_regen = 22.0
	if "veu" in unlocks: m.veil = true   # as a spectre, people lose sight of the hero
	if "corte_saida" in unlocks: m.exit_cut = true   # releasing the spectre, katana in hand, cuts at once
	return m
