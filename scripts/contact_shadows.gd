extends RefCounted
## Baked contact shadows for the level floor, built from the solid rectangles in level.json when
## the level loads: no extra polygons, just a coarse texture sampled nearest. Each piece of
## furniture (and each wall) darkens the floor under and around it; the darkness is softened by
## a box blur, then cut into a few flat bands so the edges stay stepped, like a PS1 blob shadow.
## shaders/scenery_shade.gdshader multiplies it into everything near the ground.
const TEXELS := 8          # per metre: one texel is 12.5 cm
const MARGIN := 1.5        # metres of floor kept around the playable bounds
const BLUR := 3            # box blur radius in texels, applied twice (~0.4 m of falloff)
const BANDS := 5           # flat steps between full light and the darkest shade
## How dark each kind of solid makes the floor at its heart (0 none, 1 black).
const STRENGTH := {"wall":.42,"table":.5,"bar":.5,"booth":.55,"planter":.45,"stove":.45,"sink":.4,"prep":.45,"crate":.55,
	"stage":.4,"pillar":.5,"pool":.5,"vanity":.45,"rack":.45,"desk":.5,"safe":.55,"sofa":.5,"stalls":.4,"basin":.4,"ticket":.5,
	"platform":.45,"easel":.35,"worktable":.45,"plinth":.45,"dining":.5,"sideboard":.45,"canvases":.45,"fountain":.45,"tree":.4,
	"bench":.4,"bonde":.55,"workbench":.45,"bogie":.45,"drums":.5,"motor":.45,"cabinet":.45,"lockers":.45,
	"stairs":.45,"balustrade":.35,"hedge":.4,"pergola":.35,"kiln":.55,"block":.5,
	"seat":.4,"roletas":.45,"railing":.3,"pit":.3,"lathe":.5,"shelves":.45}

static func build(solids: Array,bounds: Array) -> Dictionary:
	## Returns {texture, origin (x, z of texel 0), size (metres covered)}.
	var origin := Vector2(bounds[0]-MARGIN,bounds[1]-MARGIN)
	var size := Vector2(bounds[2]+MARGIN*2,bounds[3]+MARGIN*2)
	var w := int(ceil(size.x*TEXELS))
	var h := int(ceil(size.y*TEXELS))
	var shade := PackedFloat32Array()
	shade.resize(w*h)
	for s in solids:
		var strength: float = STRENGTH.get(s.type,.45)
		var r: Array = s.r
		var x0 := clampi(int(floor((r[0]-origin.x)*TEXELS)),0,w)
		var x1 := clampi(int(ceil((r[0]+r[2]-origin.x)*TEXELS)),0,w)
		var z0 := clampi(int(floor((r[1]-origin.y)*TEXELS)),0,h)
		var z1 := clampi(int(ceil((r[1]+r[3]-origin.y)*TEXELS)),0,h)
		for z in range(z0,z1):
			for x in range(x0,x1): shade[z*w+x] = maxf(shade[z*w+x],strength)
	for i in 2:
		shade = _blur(shade,w,h,true)
		shade = _blur(shade,w,h,false)
	var image := Image.create(w,h,false,Image.FORMAT_L8)
	var peak: float = STRENGTH.values().max()
	for z in h:
		for x in w:
			var dark := roundf(shade[z*w+x]/peak*BANDS)/BANDS*peak
			image.set_pixel(x,z,Color(1.0-dark,1.0-dark,1.0-dark))
	return {"texture":ImageTexture.create_from_image(image),"origin":origin,"size":Vector2(w,h)/float(TEXELS)}

static func _blur(source: PackedFloat32Array,w: int,h: int,horizontal: bool) -> PackedFloat32Array:
	## Running-sum box blur along one axis; outside the map counts as open floor.
	var out := PackedFloat32Array()
	out.resize(w*h)
	var lines := h if horizontal else w
	var length := w if horizontal else h
	var span := float(BLUR*2+1)
	for line in lines:
		var sum := 0.0
		for i in range(-BLUR,BLUR+1): sum += _at(source,w,line,i,horizontal,length)
		for i in length:
			out[line*w+i if horizontal else i*w+line] = sum/span
			sum += _at(source,w,line,i+BLUR+1,horizontal,length)-_at(source,w,line,i-BLUR,horizontal,length)
	return out

static func _at(source: PackedFloat32Array,w: int,line: int,i: int,horizontal: bool,length: int) -> float:
	if i < 0 or i >= length: return 0.0
	return source[line*w+i] if horizontal else source[i*w+line]
