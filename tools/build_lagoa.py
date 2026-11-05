"""Fonte da Saudade, night seven, generated in Blender through the installed MCP bridge.

- lagoa.glb (assets/level_7.json, docs/fase7.md): a sixties modernist house on the Lagoa, the
  night of the Fundação Pilar auction. The service gate and the catering yard on the front left;
  the garden with its two reflecting pools along the front; the kitchen, the wine cellar with the
  "special lot" hanging in body bags, Prates' office and the champagne bar down the left; the
  auction hall with the lectern, gilded chairs and the LOTE 12 screen in the middle; the veranda
  with the pool on the right, its stairs going down to the lagoon. Behind, the dark lagoon, the
  Morro dos Cabritos and, small on top, the Cristo lit white.

Same kit as every night (build_guardiao.py → build_caju.py → build_santa_teresa.py →
build_lavradio.py → build_environment.py). Collision comes from the level file; the bags are drawn
in Godot (scripts/avesso_view.gd), the guests are actors.
    blender -b --factory-startup --python "godot 3d/tools/build_lagoa.py"
"""
import bpy, os, math, importlib.util

HERE=os.path.dirname(os.path.abspath(__file__))
spec=importlib.util.spec_from_file_location('guardiao_kit',os.path.join(HERE,'build_guardiao.py'))
guardiao=importlib.util.module_from_spec(spec); spec.loader.exec_module(guardiao)
caju=guardiao.caju; st=caju.st; lav=caju.lav; kit=caju.kit
ROOT=kit.ROOT
box,obox,cyl,face=kit.box,kit.obox,kit.cyl,kit.face
wall_quad,floor_quad,decal,text=kit.wall_quad,kit.floor_quad,kit.decal,kit.text
C,grain,hsh=kit.C,kit.grain,kit.hsh

def t_deck(x,y):
    """Smooth teak boards: one warm tone, a thin dark joint every eight pixels, faint grain."""
    c=C('8a5a36')
    if y%8==0: c=C('5e3c22')
    elif (x+(y//8)*11)%32==0: c=C('6e4628')
    return grain(c,x,y,.04,61)

def make_palette():
    guardiao.make_palette()
    kit.material('deck',image=kit.texture('deck',32,32,t_deck))
    for name,color in {'tiffany':'c9a13b','tablecloth':'efeae0','lagoon':'14232c','pool_edge':'e6e2d6',
        'concrete_raw':'9c9a92','swan':'f2f0ea','champagne':'e8d27a'}.items():
        kit.material(name,color)
    # Lit pools glow a little under the party lights; the Cristo is floodlit white.
    kit.material('pool_water','3fa0b8',emission='2a7f98',strength=.5)
    kit.material('cristo','f4f2ea',emission='e8ecf4',strength=.9)

def make_exterior_palette():
    """Night seven's own surfaces; the shared pool/deck builders keep their palette."""
    for name,base,dark,seed in (
        ('lagoa_stone','a09b8b','777b75',91),('lagoa_roof','8b9188','727e78',92),
        ('lagoa_bank','586c58','46594e',93),('lagoa_water','233c46','1b303c',94)):
        kit.material(name,image=kit.texture(name,32,32,kit.cement(base,dark,.02,seed)))
    kit.material('lagoa_deck',image=kit.texture('lagoa_deck',32,32,t_deck))
    for name,col in {'lagoa_hill':'304d47','lagoa_hill_light':'354f49','lagoa_hill_dark':'2d4743',
        'lagoa_foliage':'3e5e50','lagoa_reeds':'5d7361','lagoa_reflection':'3c5961',
        'lagoa_steel':'475e60','lagoa_glass':'304c54','lagoa_facade':'9d9c8c',
        'lagoa_car':'28383f','lagoa_basin':'203c45','lagoa_boat':'e2eae4','lagoa_hull':'668a90','lagoa_trim':'d6d9c6',
        'lagoa_far_ochre':'827b67','lagoa_far_pink':'7b6d69'}.items():
        kit.material(name,col)
    kit.material('lagoa_lamp','b4a484',emission='cfb58a',strength=.28)
    kit.material('lagoa_window','8b8a72',emission='a69c78',strength=.18)
    kit.material('lagoa_pool','377b88',emission='2a6172',strength=.18)

def build_water7(x,z,w,d):
    """Open basin: stone coping encloses recessed water, not a luminous solid block."""
    for px in (x,x+w-.15): box('lagoa_stone',px,z,.15,d,0,.3,.8)
    for pz in (z,z+d-.15): box('lagoa_stone',x+.15,pz,w-.3,.15,0,.3,.8)
    floor_quad('lagoa_basin',x+.15,z+.15,w-.3,d-.3,.07)
    floor_quad('lagoa_pool',x+.15,z+.15,w-.3,d-.3,.245)
    for k in range(max(2,int(w))):
        px=x+.3+k*(w-.6)/max(2,int(w))
        floor_quad('lagoa_reflection',px,z+d*.45,.24,min(.04,d*.02),.247)

# ---------------------------------------------------------------- the plan
ROOMS7=[('patio',-12.8,-7.6,3.6,7.7),('jardim',-7.2,12.55,3.6,7.7),('cozinha',-12.8,-8.4,-2.4,3.2),('adega',-12.8,-8.4,-7.3,-2.8),
    ('escritorio',-8.0,-3.6,-7.3,-2.8),('bar',-8.0,-3.6,-2.4,3.2),('salao',-3.2,7.2,-7.3,3.2),('varanda',7.6,12.55,-7.3,3.2)]
SKINS7={'patio':('whitewash',1.4,False),'jardim':('concrete',1.4,False),'cozinha':('white_tile',1.3,False),'adega':('stonewall',1.4,False),
    'escritorio':('wood',1.2,True),'bar':('wood',1.0,True),'salao':('whitewash',1.4,False),'varanda':('whitewash',1.4,False),
    'outside':('whitewash',1.4,False)}
DOORS7=[(-11.8,7.7,1.4,.45),(-11.2,3.2,1.4,.4),(1.0,3.2,2.4,.4),(-8.4,-.4,.4,1.4),(-11.2,-2.8,1.4,.4),(-6.6,-2.8,1.4,.4),
    (-8.4,-5.6,.4,1.4),(-3.6,-1.8,.4,1.6),(-3.6,1.0,.4,1.6),(7.2,-5.2,.4,1.6),(7.2,-.6,.4,1.6),(9.4,3.2,1.4,.4),
    (12.55,-.6,.45,1.4),(-7.6,4.4,.4,1.4)]

# ---------------------------------------------------------------- props
def flute(cx,cz,h):
    """Champagne flute: a stem and a narrow bowl, the wine pale gold."""
    cyl('glass',cx,cz,.012,h,h+.06,4)
    cyl('champagne',cx,cz,.02,h+.06,h+.14,5,r1=.014)
    cyl('glass',cx,cz,.024,h+.14,h+.17,5,top=False)

def build_water(x,z,w,d):
    """Pool or reflecting pool: a white coping round lit water, a step down at the near edge."""
    box('pool_edge',x,z,w,d,0,.3,.8)
    floor_quad('pool_water',x+.15,z+.15,w-.3,d-.3,.305,1.0)
    for k in range(int(w/1.2)): box('pool_edge',x+.4+k*1.2,z+.15,.02,d-.3,.306,.307)   # lane marks under water

def build_chairs(x,z,w,d):
    """A row of gilded Tiffany chairs facing the lectern (-z)."""
    n=int(w/.53)
    for k in range(n):
        cx=x+.27+k*w/n; cz=z+d/2
        for lx in (-.17,.17):
            for lz in (-.17,.17): box('tiffany',cx+lx-.015,cz+lz-.015,.03,.03,0,.45)
        box('tiffany',cx-.2,cz-.2,.4,.4,.45,.5)
        box('velvet',cx-.18,cz-.18,.36,.36,.5,.53)
        for k2 in range(4): box('tiffany',cx-.18+k2*.12,cz+.17,.025,.025,.5,.9)
        box('tiffany',cx-.2,cz+.16,.4,.04,.86,.9)

def build_lectern(x,z,w,d):
    """Auctioneer's lectern: wood, the FUNDAÇÃO PILAR plate to the room (+z), gavel and mic."""
    box('wood',x+.1,z+.05,w-.2,d-.1,0,1.1,.6)
    obox('wood',x+w/2,z+d/2,w,d+.08,1.1,1.16,0)
    box('brass',x+.2,z+d-.04,w-.4,.01,.72,.92)
    text('dark','FUNDAÇÃO PILAR',x+w/2,z+d-.025,.8,.06)
    box('wood',x+.25,z+.25,.18,.06,1.16,1.2); cyl('wood',x+.38,z+.28,.03,1.16,1.24,5)
    cyl('black',x+w-.25,z+.2,.01,1.16,1.42,4); cyl('black',x+w-.25,z+.24,.025,1.4,1.46,5)

def build_cocktail(x,z,w,d):
    """High round table, white cloth to the floor, flutes on top."""
    cx,cz=x+w/2,z+d/2
    cyl('tablecloth',cx,cz,w/2-.02,0,1.05,8,r1=w/2)
    cyl('tablecloth',cx,cz,w/2,1.05,1.08,8)
    for k in range(3):
        a=k*math.tau/3+.4
        flute(cx+math.cos(a)*.16,cz+math.sin(a)*.16,1.08)

def build_winerack(x,z,w,d):
    """Wooden lattice rack, bottle necks out in rows."""
    box('wood',x,z,w,d,0,1.4,.6)
    along=w>=d; length=w if along else d
    for row in range(5):
        h=.15+row*.25
        for k in range(int(length/.14)):
            t=.07+k*.14
            px,pz=(x+t,z+d+.005) if along else (x+w+.005,z+t)
            if along: box('bottle_green' if (k+row)%3 else 'black',px-.03,pz,.06,.01,h,h+.06)
            else: box('bottle_green' if (k+row)%3 else 'black',px,pz-.03,.01,.06,h,h+.06)
        if along: box('dark',x,z+d,w,.012,h+.1,h+.12)
        else: box('dark',x+w,z,.012,d,h+.1,h+.12)

def build_bar_counter(x,z,w,d):
    """The champagne bar: white lacquer body, marble top, a pyramid of flutes."""
    box('white',x,z,w,d,0,.95,.6)
    box('marble',x-.03,z-.03,w+.06,d+.06,.95,1.0)
    cx,cz=x+w/2,z+d/2
    for layer,n in enumerate((3,2,1)):
        for i in range(n):
            for j in range(n):
                flute(cx+(i-(n-1)/2)*.09,cz+(j-(n-1)/2)*.09,1.0+layer*.13)
    for k in range(3): kit.bottle(cx,z+.2+k*.18,1.0,2)

def build_tasting(x,z,w,d):
    """Cellar tasting table: plain dark wood, a decanter, glasses and a candle."""
    for sx in (.08,w-.14):
        for sz in (.08,d-.14): box('dark',x+sx,z+sz,.06,.06,0,.74)
    box('wood',x,z,w,d,.74,.79,.6)
    kit.bottle(x+w/2,z+d/2,.79,1)
    for k in range(3): flute(x+.25+k*.3,z+.25,.79)
    cyl('bulb',x+w-.2,z+d-.2,.02,.79,.9,4)

def build_stove7(x,z,w,d):
    """Catering range along the wall (the long side runs in z)."""
    box('metal',x,z,w,d,0,.86,.5); box('black',x+.02,z+.02,w-.04,d-.04,.86,.9)
    for k in range(int(d/.5)):
        cyl('iron',x+w/2,z+.3+k*.5,.12,.9,.93,6)
        if k%2: cyl('pot',x+w/2,z+.3+k*.5,.14,.93,1.15,6)
    box('metal',x,z,w,d,1.0,1.2)   # extraction hood lip

def build_pillar7(x,z,w,d):
    """Thin white piloti, cut with the walls."""
    cx,cz=x+w/2,z+d/2
    cyl('pool_edge',cx,cz,.12,0,1.4,8,phase=math.pi/8)
    cyl('cap',cx,cz,.125,1.4,1.43,8,phase=math.pi/8)

def build_safe7(x,z,w,d):
    box('dark',x,z,w,d,0,1.0,.6); box('metal',x+.05,z+d-.01,w-.1,.02,.08,.95)
    cyl('brass',x+w/2,z+d+.01,.06,.45,.5,6)

# ---------------------------------------------------------------- inside
def decorate_inside():
    back=-7.29
    # The auction: the LOTE 12 screen with Castelar's 1979 portrait, the foundation's banner.
    box('black',-.4,back,4.8,.04,1.45,2.45)
    decal('paintings',.1,1.5,back+.05,1.55,2.35,.75,1.0)
    box('cream',1.7,back+.045,2.4,.01,1.55,2.35)
    text('dark','LOTE 12',2.9,back+.06,2.1,.16)
    text('dark','ENG. Á. CASTELAR, 1979',2.9,back+.06,1.85,.07)
    text('red_paint','LANCE INICIAL R$ 2.000.000',2.9,back+.06,1.66,.06)
    box('teal',-2.9,back,9.6,.03,2.48,2.62); text('cream','FUNDAÇÃO PILAR  —  LEILÃO BENEFICENTE',1.9,back+.04,2.505,.09)
    # The office: Prates' desk lamp, a framed diploma, the bar's mirror.
    box('wood',-7.4,back,.6,.02,1.6,2.0); box('white',-7.36,back+.025,.52,.005,1.64,1.96)
    box('glass',-7.98,-2.2,.02,1.6,1.0,1.4)
    # The cellar: the rail for the special lot and its crate, stencilled.
    caju.RAILS=[((-9.4,-7.0),(-9.4,-3.2))]
    caju.build_rails()
    box('wood',-12.1,-4.4,.9,.6,0,.55,.6); text('red_paint','LOTE ESPECIAL',-11.65,-3.795,.3,.07)
    # Patio: string lights between the kitchen wall and the gate.
    for k in range(7):
        px=-12.6+k*.8
        box('iron',px,5.6+math.sin(k*.9)*.15,.8,.01,2.2-abs(k-3)*.05,2.21-abs(k-3)*.05)
        cyl('bulb',px,5.6+math.sin(k*.9)*.15,.04,2.12-abs(k-3)*.05,2.2-abs(k-3)*.05,4)
    # Garden: low path lights and stepping stones between the pools.
    for px in (-6.6,-3.4,.6,2.6,5.0,8.8,11.2):
        cyl('bulb',px,7.3,.05,0,.22,5)
    # A continuous garden path joins the hall threshold and both reflecting pools.
    floor_quad('lagoa_stone',-6.9,6.65,19.35,.65,.052,.8)
    floor_quad('lagoa_stone',1.85,3.6,.7,3.05,.052,.8)
    for k in range(25): floor_quad('lagoa_steel',-6.9+k*.78,6.65,.018,.65,.054)
    # The veranda's open glass doors, slid back along the hall wall.
    for dz in (-5.2,-.6): box('glass',7.25,dz+1.6,.06,1.1,0,1.4)

# ---------------------------------------------------------------- outside
def terrain():
    """A continuous, triangulated distant ridge, composed for the orthographic camera.
    The far shore uses a compressed scenic scale; no giant cylinder caps or floating crowns."""
    xs=[-48,-37,-28,-20,-13,-7,-1.7,5,12,20,29,38,48]
    heights=[.0,.35,.7,.85,.3,.7,1.1,.45,.8,.5,.25,.45,.0]
    # Extra ridge samples and a gently curved waterline avoid broad regular triangles
    # reading as an abstract wall. The centre summit still supports the Cristo.
    original=list(zip(xs,heights))
    points=[]
    for i in range(len(original)-1):
        x,h=original[i]; nx,nh=original[i+1]
        points.extend([(x,h),((x+nx)/2,(h+nh)/2+.08*math.sin(i*2.1))])
    points.append(original[-1])
    xs,heights=zip(*points)
    def shore(x): return -14.4-.23*math.sin(x*.19)-.12*math.sin(x*.51)
    rows=[]
    for row in range(3):
        rows.append([(x,-(shore(x) if row==0 else -16.0 if row==1 else -21.5),
            -1.1 if row==0 else heights[i] if row==1 else -.4+heights[i]*.35) for i,x in enumerate(xs)])
    for row in range(2):
        for i in range(len(xs)-1):
            a,b,c,d=rows[row][i],rows[row][i+1],rows[row+1][i+1],rows[row+1][i]
            face(['lagoa_hill','lagoa_hill_light','lagoa_hill_dark'][(row+i)%3],[a,b,c],2,(0,0,1))
            face(['lagoa_hill_dark','lagoa_hill','lagoa_hill_light'][i%3],[a,c,d],2,(0,0,1))
    # The Cristo has a tapered robe, shoulders and head; its small complete silhouette
    # sits in the upper band of the GAMEPLAY camera, not outside the scene's picture.
    x,z,h=-1.7,-16.0,1.1
    box('lagoa_stone',x-.17,z-.14,.34,.28,h,h+.12)
    cyl('cristo',x,z,.12,h+.12,h+.53,5,r1=.065)
    box('cristo',x-.37,z-.055,.74,.11,h+.5,h+.59)
    cyl('cristo',x,z,.055,h+.59,h+.72,5)
    # A low stone edge and a string of lamps on the far shore. No houses: from the orthographic
    # camera, small buildings at a distance read as boxes floating on the hill.
    for i in range(len(xs)-1):
        x,nx=xs[i],xs[i+1]; z,nz=shore(x),shore(nx)
        face('lagoa_stone',[(x,-z,-1.04),(nx,-nz,-1.04),
            (nx,-nz-.3,-1.04),(x,-z-.3,-1.04)],1,(0,0,1))
    for i in range(35):
        if i%4: continue
        x=-45+i*2.65
        cyl('lagoa_steel',x,-13.96,.018,-1.04,-.25,4)
        box('lagoa_lamp',x-.045,-14.0,.09,.09,-.25,-.16)
        for k in range(3): floor_quad('lagoa_reflection',x-.04+k*.018,-13.6+k*.45,.09,.23,-1.193)

def neighbor():
    """A modernist villa and walled garden frame the west, with brises and a roof terrace."""
    box('lagoa_facade',-29,-12,13.3,20,-.9,2.8,1.4)
    box('lagoa_roof',-29.15,-12.15,13.6,20.3,2.8,2.98,2)
    box('lagoa_stone',-29,7.9,13.3,.15,-.9,.16)
    for i in range(6):
        x=-28.5+i*2.1
        wall_quad('lagoa_glass',x,x+1.75,8.012,.3,2.45)
        for j in range(3): box('lagoa_stone',x+j*.6,8.04,.045,.45,.2,2.7)
    for z in (-10,-6,-2,2,6):
        face('lagoa_glass',[(-15.688,-z,.4),(-15.688,-z-2.8,.4),
            (-15.688,-z-2.8,2.4),(-15.688,-z,2.4)],1,(1,0,0))
        box('lagoa_stone',-15.68,z,.35,.08,.1,2.7)
    # Roof terrace: a separate access room, pergola and planted edges break up the slab.
    box('lagoa_facade',-28,-10,4.5,4.4,2.98,4.0)
    box('lagoa_roof',-28.15,-10.15,4.8,4.7,4.0,4.14)
    for x in (-22.5,-17.5):
        for z in (1.5,6.0): box('lagoa_steel',x,z,.06,.06,2.98,4.25)
    for i in range(10): box('lagoa_deck',-22.6,1.5+i*.5,5.3,.12,4.22,4.32)
    for z in (-5.0,.0,5.0):
        box('lagoa_stone',-17.2,z,1.0,2.4,2.98,3.22)
        box('lagoa_foliage',-17.1,z+.1,.8,2.2,3.22,3.52)
    # A garden strip beside the service wall, never inside the playable silhouette.
    box('lagoa_stone',-15.6,-9.6,.25,17.75,-1.2,.12)

def banks_and_pier():
    # The building and garden sit on a retaining structure, continuous with the shore.
    box('lagoa_stone',-13.25,-7.75,26.25,15.9,-1.35,-.045,1.4)
    floor_quad('grass',-15.1,-9.1,1.85,17.25,.04,1.6)
    floor_quad('grass',-13.25,-9.1,28.35,1.35,.04,1.6)
    # Continuous land between the veranda and its retaining wall, split around the
    # unchanged exit landing so no coplanar grass can flicker through its boards.
    floor_quad('grass',13.0,-9.1,2.05,7.65,.04,1.6)
    floor_quad('grass',13.0,1.6,2.05,6.55,.04,1.6)
    box('lagoa_stone',13.0,-1.45,2.05,.5,-1.35,-.02)
    box('lagoa_stone',13.0,1.1,2.05,.5,-1.35,-.02)
    box('lagoa_stone',-15.3,-9.55,30.6,.45,-1.4,-.08,1.2)
    box('lagoa_stone',15.05,-9.1,.3,17.25,-1.4,-.08,1.2)
    # A sloped bank and a narrow waterside path turn the hard lot edge into a shore.
    for z0,z1 in ((-9.1,-1.45),(1.6,8.15)):
        floor_quad('lagoa_stone',15.35,z0,.85,z1-z0,-.17,1.2)
        face('lagoa_bank',[(16.2,-z0,-.17),(16.2,-z1,-.17),
            (16.8,-z1,-1.25),(16.8,-z0,-1.25)],1.2,(1,0,1))
    for k in range(18):
        z=-8.8+k*.9
        if -1.6<z<1.8: continue
        x=16.4+math.sin(k*2.3)*.11
        for j in range(3):
            face('lagoa_reeds',[(x-.025,-z,-1.15),(x+.025,-z,-1.15),
                (x+.12*math.sin(j*2+k),-z-.09*j,-.45+(k%3)*.09)],1,(1,0,1))
    # Original exit landing and clearance are retained; the pier beyond gets volume.
    box('lagoa_deck',13.0,-.95,2.1,2.05,-.16,.04,1.0)
    for k in range(4): box('lagoa_stone',15.1+k*.3,-.95,.3,2.05,-.35-k*.18,-.14-k*.18)
    box('lagoa_deck',16.3,-1.4,1.8,9.4,-.92,-.76,1)
    box('lagoa_deck',18.1,6.4,2.5,1.6,-.92,-.76,1)
    for z in (-1.2,1.0,3.2,5.4,7.7):
        box('lagoa_steel',16.2,z,2.0,.15,-1.12,-.93)
        for x in (16.38,18.02):
            cyl('lagoa_steel',x,z,.085,-2.4,-.38,6)
        # Fasteners sit flush with the deck, not on luminous floating rectangles.
        for x in (16.52,17.85): cyl('lagoa_steel',x,z,.025,-.759,-.75,5)
    for x in (18.2,20.4): cyl('lagoa_steel',x,7.7,.085,-2.4,-.38,6)
    for z0,z1 in ((-1.2,1.0),(5.4,7.7)):
        guardiao.strut('lagoa_steel',(18.02,z0,-.36),(18.02,z1,-.36),.028)
    for z in (-5.0,4.2,7.4):
        cyl('lagoa_steel',15.7,z,.035,-.17,.58,5)
        box('lagoa_lamp',15.63,z-.07,.14,.14,.55,.64)

def boat():
    """The boat of the Ilha Fiscal (build_ilha.py service_boat), moored along the pier: 5 m long,
    hull, wheelhouse with glass, crates on deck. Its axis runs along the pier (z)."""
    cx,cz,dy=19.95,1.2,-.55
    ring=[(-2.5,-.55),(-1.9,-.8),(1.65,-.8),(2.55,0),(1.65,.8),(-1.9,.8),(-2.5,.55)]
    at=lambda u,v,h:(cx+v,-(cz+u),h+dy)   # u along the pier, v across it
    for i,(du,dv) in enumerate(ring):
        eu,ev=ring[(i+1)%len(ring)]
        face('lagoa_hull',[at(du*.83,dv*.8,-1.1),at(eu*.83,ev*.8,-1.1),at(eu,ev,-.1),at(du,dv,-.1)],1,(ev-dv,eu-du,0))
    face('lagoa_boat',[at(u,v,-.1) for u,v in ring],1,(0,0,1))
    box('lagoa_boat',cx-.6,cz-1.9,1.2,1.55,-.1+dy,.83+dy)
    box('lagoa_trim',cx-.7,cz-2.0,1.4,1.75,.83+dy,.94+dy)
    for x in (cx-.607,cx+.607):
        face('lagoa_glass',[(x,-(cz-1.72),.25+dy),(x,-(cz-.55),.25+dy),(x,-(cz-.55),.7+dy),(x,-(cz-1.72),.7+dy)],1,(1 if x>cx else -1,0,0))
    for i in range(4):
        box('crate',cx-.45+(i//2)*.55,cz-.1+(i%2)*.55,.45,.45,-.08+dy,.3+dy,.5)
    cyl('lagoa_steel',cx,cz-1.3,.025,.94+dy,1.3+dy,4)
    # The mooring line from the pier's cleat to the bow and the stern.
    for u in (-2.1,1.45):
        guardiao.strut('lagoa_steel',(18.02,cz+u,-.36),(cx-.72,cz+u,-.05+dy),.025)
    for k in range(3): floor_quad('lagoa_reflection',cx-.65-k*.12,cz+2.0+k*.18,1.3+k*.24,.025,-1.192)

def street_front():
    floor_quad('pedra',-15.3,8.15,30.6,2.45,.07,1.4)
    box('lagoa_stone',-40,10.52,80,.12,-.14,.07,1.4)
    floor_quad('asphalt',-40,10.65,80,20,-.15,2.4)
    for k in range(14): floor_quad('lagoa_stone',-36+k*5.5,14.5,2.4,.12,-.145)
    for x in (-13.8,-7.2,9.3):
        cyl('lagoa_steel',x,9.8,.045,.07,2.1,5)
        box('lagoa_lamp',x-.12,9.68,.24,.24,2.0,2.15)
    # Valet tent: pitched canvas, skirt, legs and a discreet sign.
    for x in (-1.6,1.6):
        for z in (11.2,13.4): cyl('lagoa_steel',x,z,.035,-.15,2.1,4)
    for z0 in (11.0,13.6):
        face('lagoa_roof',[(-1.8,-z0,2.1),(1.8,-z0,2.1),(1.8,-12.3,2.75),(-1.8,-12.3,2.75)],1,(0,-1 if z0==11 else 1,1))
    box('lagoa_steel',-1.8,11,3.6,.06,1.95,2.1)
    text('lagoa_stone','MANOBRISTA',0,11.07,1.98,.11)
    # Sedan with actual bonnet, sloped glazing, boot, bumpers and standing wheels.
    box('lagoa_car',4.0,11.4,4.3,1.7,.17,.69)
    box('lagoa_steel',4.0,11.38,4.3,.04,.24,.32)
    box('lagoa_car',5.2,11.55,1.45,1.4,1.15,1.2)
    for x0,x1,h0,h1 in ((4.7,5.2,.69,1.15),(6.65,7.1,1.15,.69)):
        face('lagoa_glass',[(x0,-11.55,h0),(x1,-11.55,h1),(x1,-12.95,h1),(x0,-12.95,h0)],1,(0,0,1))
    for z in (11.54,12.96):
        face('lagoa_glass',[(4.7,-z,.69),(7.1,-z,.69),(6.65,-z,1.15),(5.2,-z,1.15)],1,(0,-1 if z>12 else 1,0))
        box('lagoa_car',5.95,z,.055,.035,.69,1.15)
    for x in (4.75,7.45):
        for z in (11.38,13.12):
            ring=[(x+math.cos(i*math.tau/10)*.27,.23+math.sin(i*math.tau/10)*.27) for i in range(10)]
            face('tire',[(px,-z,h) for px,h in ring],1,(0,-1 if z>12 else 1,0))
    for z in (11.55,12.65): box('lagoa_lamp',8.3,z,.025,.26,.4,.52)

def build_outside():
    make_exterior_palette()
    floor_quad('lagoa_water',-65,-60,130,50.45,-1.2,3)
    floor_quad('lagoa_water',15.1,-9.55,50,42,-1.2,3)
    terrain()
    neighbor()
    banks_and_pier()
    boat()
    street_front()
    # Quiet stepped ripples on the open water, with room for the exit marker to lead.
    for k in range(30):
        x=20+(k%6)*3.8; z=-8+(k//6)*3.4+math.sin(k)*.5
        floor_quad('lagoa_reflection',x,z,.35+(k%3)*.24,.025,-1.193)

def build_level7():
    data=st.load('level_7.json'); solids=data['solids']
    build_outside()
    floor_quad('cimento',-12.8,3.6,5.2,4.1,.04,1.6)
    floor_quad('grass',-7.2,3.6,19.75,4.1,.04,1.6)
    floor_quad('white_tile',-12.8,-2.4,4.4,5.6,.04,1.0)
    floor_quad('vermelhao',-12.8,-7.3,4.4,4.5,.04,1.4)
    floor_quad('tacos',-8.0,-7.3,4.4,4.5,.04,1.6)
    floor_quad('granilite',-8.0,-2.4,4.4,5.6,.04,1.2)
    floor_quad('granilite',-3.2,-7.3,10.4,10.5,.04,1.2)
    floor_quad('deck',7.6,-7.3,4.95,10.5,.04,1.0)
    floor_quad('cimento',-13.25,3.2,.45,4.5,.04,1.6)
    for x,z,w,d in DOORS7: floor_quad('granito',x,z,w,d,.05,.8)
    walls=kit.wall_pieces(solids)
    for x,z,w,d,h in walls: lav.build_wall(x,z,w,d,h,walls,ROOMS7,SKINS7)
    for i,s in enumerate(solids):
        x,z,w,d=s['r']; kind=s['type']
        if kind=='wall': continue
        if kind=='easel': st.easel(x,z,w,d,i%4)
        elif kind=='plinth': st.build_plinth(x,z,w,d,i%3)
        elif kind=='hedge': st.build_hedge(x,z,w,d,s['h'])
        elif kind=='crate': st.build_crate(x,z,w,d,s['h'])
        elif kind=='table': build_tasting(x,z,w,d)
        else:
            {'pool':build_water7,'chairs':build_chairs,'lectern':build_lectern,'cocktail':build_cocktail,'winerack':build_winerack,
             'counter':build_bar_counter,'stove':build_stove7,'pillar':build_pillar7,'safe':build_safe7,
             'balustrade':st.build_balustrade,'drums':st.build_drums,'prep':kit.build_prep,'desk':lav.build_desk,
             'shelves':st.build_shelves,'sofa':lav.build_sofa,'plant':guardiao.build_plant}[kind](x,z,w,d)
    decorate_inside()

if __name__=='__main__':
    with kit.workspace('Lagoa') as scene:
        make_palette()
        build_level7()
        triangles=kit.assemble(scene)
        kit.export_glb(os.path.join(ROOT,'assets/environment/lagoa.glb'))
        bpy.data.libraries.write(os.path.join(ROOT,'tools/source/lagoa.blend'),{scene},fake_user=True,compress=True)
        print('LAGOA_READY',len(scene.objects),'meshes',triangles,'triangles',len(kit.images),'textures')
