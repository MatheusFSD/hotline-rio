"""Caju, night five, generated in Blender through the installed MCP bridge.

- caju.glb (assets/level_5.json): the Frigorífico da Pilar, a 1970s cold store on the port. The
  truck yard and three dock bays in front; the shipping office and the loading dock; the cold
  corridor with three chambers of insulated panel, bodies in black bags hanging from the meat
  rail; the locker room and showers; the compressor room; behind it all the pier on the bay,
  with the launch PILAR II moored, the way out.

Same kit as every night (build_santa_teresa.py → build_lavradio.py → build_environment.py), so
the cutaway walls, the floors and the shading match. Collision comes from the level file: every
interior piece is modeled inside its solid's footprint. The meat rails are decoration at 2.7 m;
the bags themselves are drawn in Godot (scripts/avesso_view.gd), since a shot or a cut tears them.
Runs headless or through the MCP bridge, in a temporary scene:
    blender -b --factory-startup --python "godot 3d/tools/build_caju.py"
"""
import bpy, os, math, importlib.util

HERE=os.path.dirname(os.path.abspath(__file__))
spec=importlib.util.spec_from_file_location('santa_teresa_kit',os.path.join(HERE,'build_santa_teresa.py'))
st=importlib.util.module_from_spec(spec); spec.loader.exec_module(st)
lav=st.lav
kit=st.kit
ROOT=kit.ROOT
C,mul,mix,grain,hsh=kit.C,kit.mul,kit.mix,kit.grain,kit.hsh
box,obox,cyl,face,local=kit.box,kit.obox,kit.cyl,kit.face,kit.local
wall_quad,floor_quad,decal,text=kit.wall_quad,kit.floor_quad,kit.decal,kit.text

# ---------------------------------------------------------------- textures
def t_isopainel(x,y):
    """Insulated sandwich panel: off-white steel, shallow ribs, a dark seam per panel."""
    c=mul(C('dfe3e1'),1.04 if x%4==1 else 1.0)
    if x%16==0: c=C('9ea6a6')
    return grain(c,x,y,.025,71)

def t_frost(x,y):
    """Grey epoxy floor flecked with frost."""
    c=kit.cement('aab2b6','8f989d',.05,16,16)(x,y)
    return mix(c,C('eef4f6'),.6) if hsh(x,y,72)>.93 else c

def t_container(base):
    return lambda x,y: grain(mul(C(base),.8 if x%4==0 else 1.05 if x%4==2 else 1.0),x,y,.04,73)

def make_palette():
    st.make_palette()
    kit.material('isopainel',image=kit.texture('isopainel',32,32,t_isopainel))
    kit.material('frost',image=kit.texture('frost',32,32,t_frost))
    kit.material('bay',image=kit.texture('bay',32,32,kit.cement('1d3646','16293a',seed=17)))
    for name,base in {'container_red':'8d3a2a','container_blue':'2f5d8a','container_green':'3f6b4a','container_grey':'8a8f92'}.items():
        kit.material(name,image=kit.texture(name,32,32,t_container(base)))
    kit.material('cardboard','a8865a')
    kit.material('shrink','d8e4e8',alpha=.3)
    kit.material('chainlink','5a6066',alpha=.45)
    kit.material('sodium','ffb050',emission='ffb050',strength=3)

# ---------------------------------------------------------------- the plan
ROOMS5=[('escritorio',-12.8,-8.4,3.6,7.7),('doca',-8.0,12.55,3.6,7.7),('vestiario',-12.8,-8.4,-3.0,3.2),
    ('chuveiros',-12.8,-8.6,-7.3,-3.4),('antecamara',-8.0,6.6,0.0,3.2),('camara',-8.0,-3.6,-7.3,-0.6),
    ('camara',-3.0,1.4,-7.3,-0.6),('camara',2.0,6.4,-7.3,-0.6),('compressores',7.0,12.55,-7.3,3.2)]
SKINS5={'escritorio':('wood',1.1,True),'doca':('concrete',.9,False),'vestiario':('white_tile',1.3,False),
    'chuveiros':('white_tile',1.4,False),'antecamara':('isopainel',1.4,False),'camara':('isopainel',1.4,False),
    'compressores':('green_paint',1.1,False),'outside':('whitewash',1.4,False)}
# Door gaps (x, z, w, d, sill material).
DOORS5=[(-6.2,7.7,2.0,.45,'metal'),(-1.2,7.7,2.0,.45,'metal'),(3.2,7.7,2.0,.45,'metal'),(-10.0,3.2,1.4,.4,'granito'),
    (-6.0,3.2,1.6,.4,'granito'),(3.4,3.2,1.6,.4,'granito'),(9.0,3.2,1.4,.4,'granito'),(-8.4,4.4,.4,1.4,'granito'),
    (-8.4,1.2,.4,1.4,'granito'),(6.6,1.0,.4,1.4,'granito'),(-6.5,-0.6,1.4,.6,'metal'),(-1.5,-0.6,1.4,.6,'metal'),
    (3.5,-0.6,1.4,.6,'metal'),(1.4,-6.4,.6,1.4,'metal'),(-11.2,-3.4,1.4,.4,'granito'),(9.2,-7.75,1.8,.45,'metal')]
# Overhead meat rails at 2.62-2.72 m: truck bay 3 → dock → corridor → each chamber, bags under them.
RAILS=[((4.2,7.6),(4.2,-1.2)),((-5.8,1.6),(4.2,1.6)),((-5.8,1.6),(-5.8,-1.2)),((-0.8,1.6),(-0.8,-1.2)),
    ((-7.2,-1.2),(-4.4,-1.2)),((-7.2,-1.2),(-7.2,-6.6)),((-4.4,-1.2),(-4.4,-6.6)),
    ((-2.2,-1.2),(0.6,-1.2)),((-2.2,-1.2),(-2.2,-6.6)),((0.6,-1.2),(0.6,-6.6)),
    ((2.8,-1.2),(5.6,-1.2)),((2.8,-1.2),(2.8,-6.6)),((5.6,-1.2),(5.6,-6.6))]
CHAMBERS=((-5.8,'1'),(-0.8,'2'),(4.2,'3'))   # centre x and number

# ---------------------------------------------------------------- props
def along(x,z,w,d):
    """(long axis is z, length, depth) for pieces laid along their rect's longer side."""
    return (d>=w, d if d>=w else w, w if d>=w else d)

def part(x,z,w,d,on_z,mat,a0,a1,b0,b1,h0,h1):
    """Box in a piece's own frame: a along its long axis, b across it."""
    if on_z: box(mat,x+b0,z+a0,b1-b0,a1-a0,h0,h1)
    else: box(mat,x+a0,z+b0,a1-a0,b1-b0,h0,h1)

def build_pallet(x,z,w,d,h,index):
    """Shrink-wrapped pallet of meat boxes; the seventh, in chamber 3, holds the IML archive."""
    on_z,length,depth=along(x,z,w,d)
    for b in (.05,depth/2-.05,depth-.15): part(x,z,w,d,on_z,'wood',0,length,b,b+.1,0,.1)
    for k in range(int(length/.2)): part(x,z,w,d,on_z,'wood',.02+k*.2,.14+k*.2,0,depth,.1,.14)
    top=h-.04
    if index==6:
        # Three archive boxes stencilled IML, the ledger open on the last one.
        for k in range(3):
            bx=x+.08+k*(w-.16)/3
            box('cream',bx,z+.1,(w-.16)/3-.04,d-.2,.14,.14+.32*(1+k%2))
            text('dark','IML',bx+((w-.16)/3-.04)/2,z+d-.1+.005,.25,.08)
        lx,lz=x+w-.35,z+d/2
        obox('books_a',lx,lz,.4,.3,.78,.8,.15); obox('white',lx-.09,lz,.18,.27,.8,.81,.15); obox('white',lx+.1,lz,.18,.27,.8,.81,.15)
        return
    mat='foam' if index%2 else 'cardboard'
    layers=2 if h<1.3 else 3
    lh=(top-.14)/layers
    for layer in range(layers):
        h0=.14+layer*lh
        for k in range(2):
            for j in range(2):
                if h>=1.4 and layer==layers-1 and k==1 and j==1: continue   # a stepped top
                part(x,z,w,d,on_z,mat,.03+k*(length-.06)/2,.03+(k+1)*(length-.06)/2-.03,.03+j*(depth-.06)/2,.03+(j+1)*(depth-.06)/2-.03,h0,h0+lh-.02)
    box('shrink',x+.01,z+.01,w-.02,d-.02,.12,top-(lh if h>=1.4 else 0)+.01)
    box('white',x+w/2-.18,z+d,.36,.01,top/2-.08,top/2+.08)
    text('red_paint','PILAR',x+w/2,z+d+.012,top/2-.03,.07)

def build_forklift(x,z,w,d):
    """Counterbalance forklift, yellow, forks toward the back wall (-z)."""
    cx=x+w/2
    for side in (-.25,.25): box('iron',cx+side-.06,z,.12,.7,.05,.12)
    box('dark',cx-.4,z+.62,.8,.1,0,1.3)                  # mast
    box('yellow_paint',x+.08,z+.72,w-.16,d-1.07,.25,.95)  # body
    box('black',cx-.25,z+1.15,.5,.45,.95,1.05)             # seat
    for px in (x+.1,x+w-.15):
        for pz in (z+.8,z+1.75): box('black',px,pz,.05,.05,.95,1.3)
    box('black',x+.1,z+.8,w-.2,1.0,1.26,1.3,sides=False)
    cyl('dark',cx,z+d-.2,.5,.25,.95,6)                     # counterweight
    box('dark',x+.08,z+d-.38,w-.16,.3,.25,.95)
    for wz in (z+.95,z+d-.45):
        for wx in (x+.06,x+w-.06): st.prism_x('tire',wx,wz,.22,.22,.14)
    cyl('orange',cx+.3,z+1.6,.06,1.3,1.38,6)

def build_compressor(x,z,w,d):
    """Ammonia screw compressor on its skid: motor, coupling guard, block, oil separator, frosted pipes."""
    on_z,length,depth=along(x,z,w,d)
    box('iron',x,z,w,d,0,.15)
    mx,mz=(x+w/2,z+d*.72) if on_z else (x+w*.72,z+d/2)
    cyl('green_paint',mx,mz,.35,.15,1.0,8)
    part(x,z,w,d,on_z,'yellow_paint',length*.42,length*.52,depth*.25,depth*.75,.15,.8)
    part(x,z,w,d,on_z,'pot',.1,length*.42,.1,depth-.1,.15,1.0)
    sx,sz=(x+w-.25,z+.25)
    cyl('pot',sx,sz,.18,.15,1.3,8)
    for k in range(2):
        px,pz=(x+.3+k*.35,z+.5) if on_z else (x+.5,z+.3+k*.35)
        cyl('pot',px,pz,.05,1.0,1.3,6); cyl('white',px,pz,.065,.9,1.3,6)
    obox('white',x+w/2-.3,z+d+.01,.14,.01,.64,.78)   # gauge and emergency stop on the camera side
    box('red_paint',x+w/2+.15,z+d,.1,.02,.8,.9)

def build_tank(x,z,w,d):
    """Horizontal ammonia receiver on two saddles, the end cap facing the camera marked NH3."""
    on_z,length,depth=along(x,z,w,d)
    cx=x+w/2
    for a in (.35,length-.55): part(x,z,w,d,on_z,'iron',a,a+.2,.1,depth-.1,0,.45)
    r=min(.45,depth/2)
    n=8
    ring=[(math.cos(math.tau*i/n)*r,math.sin(math.tau*i/n)*r) for i in range(n)]
    # The drum lies along z: faces between z and z+d around the axis at height .65.
    for i in range(n):
        (a0,b0),(a1,b1)=ring[i],ring[(i+1)%n]
        face('white',[(cx+a0,-z,.65+b0),(cx+a1,-z,.65+b1),(cx+a1,-(z+d),.65+b1),(cx+a0,-(z+d),.65+b0)],1,(a0+a1,0,b0+b1))
    face('white',[(cx+a,-(z+d),.65+b) for a,b in ring],1,(0,-1,0))
    obox('yellow_paint',cx,z+d+.01,.3,.02,.5,.8,0)
    text('dark','NH3',cx,z+d+.02,.6,.08)
    box('glass',cx+r,z+.6,.04,.6,.4,.9)
    cyl('red_paint',cx,z+d/2,.05,1.05,1.2,6)

def build_chamberdoor(x,z,w,d,handle_west):
    """Insulated sliding door leaf parked open beside its doorway, on a chrome guide rail."""
    box('isopainel',x,z+.04,w,.12,0,1.4,.6)
    box('cap',x,z+.04,w,.12,1.4,1.43,sides=False)
    for h0,h1 in ((0,.04),(1.36,1.4)): box('chrome',x,z+.16,w,.01,h0,h1)
    hx=x+.1 if handle_west else x+w-.14
    box('chrome',hx,z+.17,.04,.04,.5,1.2)
    box('chrome',x-1.4 if handle_west else x,z,w+1.4,.04,1.36,1.4)

def build_truck(x,z,w,d):
    """The refrigerated truck backed into bay 3: everything up to 1.4 m cut like the bondes; the
    cab, off the bottom of the screen, stands whole."""
    x0,x1=x,x+w
    box('black',x0+.35,8.25,.25,6.4,.45,.7); box('black',x1-.6,8.25,.25,6.4,.45,.7)
    for k in range(int(w/.25)): box('yellow_paint' if k%2 else 'black',x0+k*.25,8.15,.25,.1,.45,.7)
    for wz in (9.3,10.5,15.9):
        for wx in (x0+.25,x1-.25): st.prism_x('tire',wx,wz,.5,.5,.3)
    box('metal',x0+.05,8.15,w-.1,6.45,1.15,1.2)
    box('white',x0,8.15,.06,6.45,.7,1.4); box('white',x1-.06,8.15,.06,6.45,.7,1.4)
    box('white',x0,14.54,w,.06,.7,1.4)
    for bx in (x0,x1-.06): box('cap',bx,8.15,.06,6.45,1.4,1.43,sides=False)
    box('white',x0-.06,8.15,.06,1.2,.7,1.4); box('white',x1,8.15,.06,1.2,.7,1.4)   # rear doors swung flat
    for k in range(3): box('foam',x0+.2+k*.7,12.8,.6,1.5,1.2,1.2+.35*(1+k%2))
    box('metal',x0+.3,14.3,w-.6,.3,1.2,2.2)
    box('white',x0,14.8,w,2.4,.7,2.6)
    box('screen',x0+.15,17.2,w-.3,.02,1.6,2.4)

def build_rails():
    for (ax,az),(bx,bz) in RAILS:
        x0,x1=min(ax,bx),max(ax,bx); z0,z1=min(az,bz),max(az,bz)
        box('rail',x0-.025,z0-.025,x1-x0+.05,z1-z0+.05,2.62,2.72)
        length=max(x1-x0,z1-z0); n=int(length/1.6)
        for k in range(n+1):
            t=k/max(n,1)
            hx,hz=ax+(bx-ax)*t,az+(bz-az)*t
            box('iron',hx-.02,hz-.02,.04,.04,2.72,2.95)
    for p in {pt for seg in RAILS for pt in seg}: box('iron',p[0]-.06,p[1]-.06,.12,.12,2.72,2.76)

# ---------------------------------------------------------------- outside
def container(x0,z0,x1,z1,h0,mat,mark=None):
    box(mat,x0,z0,x1-x0,z1-z0,h0,h0+2.55,1.0)
    for dx in (x0+.25,(x0+x1)/2-.02,x1-.29): box('dark',dx,z1,.04,.01,h0+.2,h0+2.35)   # door seams and bars
    if mark: text('white',mark,(x0+x1)/2,z1+.01,h0+1.6,.35)

def armazem(x0,x1,z0,z1,height,paint,number):
    """Old port warehouse framing the level: plaster walls, a gable roof ridged along z, two big doors."""
    box('side_'+paint,x0,z0,x1-x0,z1-z0,0,height,1.4)
    mid=(x0+x1)/2; ridge=height+1.6
    face('side_roof',[(x0-.2,-z0-.3,height-.1),(x0-.2,-z1+.3,height-.1),(mid,-z1+.3,ridge),(mid,-z0-.3,ridge)],1.2,(-1,0,1))
    face('side_roof',[(x1+.2,-z1+.3,height-.1),(x1+.2,-z0-.3,height-.1),(mid,-z0-.3,ridge),(mid,-z1+.3,ridge)],1.2,(1,0,1))
    face('side_'+paint,[(x0,-z1,height),(x1,-z1,height),(mid,-z1,ridge)],1.4,(0,-1,0))
    box('side_cream',x0-.05,z1,x1-x0+.1,.08,height-.25,height)
    for k in range(2):
        dx=x0+(x1-x0)*(k+1)/3
        wall_quad('side_cream',dx-1.0,dx+1.0,z1+.02,0,3.3,1,1)
        wall_quad('side_teal',dx-.9,dx+.9,z1+.03,0,3.2,1,1)
    text('side_cream',number,mid,z1+.04,height-.8,.4)

def build_outside():
    # The bay behind the pier, and the pier itself.
    floor_quad('asphalt',-30,-12.75,60,42.75,-.07,2.4)
    floor_quad('bay',-30,-30,60,17.25,-.45,3.0)
    floor_quad('concrete',-30,-12.75,60,5.0,.03,1.4)
    box('yellow_paint',-30,-12.75,60,.15,0,.12)
    for k in range(25): box('tire',-28.9+k*2.4,-12.95,.24,.2,-.4,0)   # fenders off the edge
    for bx in (-11.0,-5.5,0.0,5.5,13.8):
        cyl('iron',bx,-12.2,.2,0,.12,8); cyl('iron',bx,-12.2,.14,.12,.5,8); cyl('iron',bx,-12.2,.2,.5,.58,8)
    # PILAR II, moored, a line to the bollard.
    box('black',-9.5,-15.2,8.0,2.2,-.45,.5)
    box('red_paint',-9.5,-13.02,8.0,.02,.1,.25)
    box('wood',-9.4,-15.1,7.8,2.0,.5,.52)
    box('white',-5.0,-14.8,2.2,1.4,.5,2.3)
    box('screen',-4.8,-13.4,1.8,.02,1.6,2.1)
    cyl('dark',-3.9,-14.1,.04,2.3,3.8,4)
    text('white','PILAR II',-7.6,-12.99,.25,.18)
    box('cream',-5.55,-13.05,.04,.85,.3,.34)
    cyl('bulb_green',8.0,-16.0,.18,-.4,.3,6)
    # The truck yard: chain-link fence with its gate, the street beyond, the sodium lamp.
    floor_quad('oil_concrete',-15.3,8.15,30.6,2.6,.03,2.4)
    for k in range(16):
        px=-15.0+k*2.0
        if -9<px<-5 or 2.6<px<5.8: continue
        box('iron',px-.04,10.71,.08,.08,0,1.8)
    for x0,x1 in ((-15.0,-9.0),(-5.0,2.6),(5.8,15.0)): box('chainlink',x0,10.73,x1-x0,.02,.05,1.75)
    for gx,yaw in ((-9.0,.9),(-5.0,math.pi-.9)):
        cx,cz=local(gx,10.75,yaw,1.0,0); obox('chainlink',cx,cz,2.0,.03,.05,1.75,yaw)
    for k in range(20): box('yellow_paint',-29+k*3.0,13.37,1.5,.06,-.055,-.05)
    cyl('iron',-3.0,10.95,.08,0,3.2,6); box('iron',-3.05,10.2,.1,.8,3.15,3.22)
    box('sodium',-3.2,10.15,.4,.2,3.05,3.15)
    # Dock face: bumpers, the striped edge, painted bay numbers, the company board.
    for bx in (-6.2,-1.2,3.2):
        box('black',bx-.2,8.15,.2,.16,.2,.75); box('black',bx+2.0,8.15,.2,.16,.2,.75)
        floor_quad('metal',bx+.1,8.15,1.8,.35,.04,.5)
    for k in range(int(30/.4)): box('yellow_paint' if k%2 else 'black',-15.1+k*.4,8.15,.4,.02,.0,.12)
    text('white','1',-5.2,9.4,.035,.6,flat=True); text('white','2',-0.2,9.4,.035,.6,flat=True)
    box('teal',-12.9,8.15,6.4,.05,.3,1.15)
    text('cream','FRIGORÍFICO DA PILAR',-9.7,8.21,.68,.26)
    text('yellow_paint','PILAR ADMINISTRAÇÃO  •  CÂMARAS FRIAS  •  CAJU',-9.7,8.21,.42,.09)
    box('bottle_green',12.2,8.5,2.4,1.1,0,1.2)
    for k in range(3): box('wood',7.0,8.5,1.2,1.0,k*.2,k*.2+.14)
    # Flanks: containers and condensers, then the old warehouses framing it all.
    floor_quad('concrete',-15.3,-7.75,2.05,15.9,.03,1.4)
    floor_quad('concrete',13.0,-7.75,2.3,15.9,.03,1.4)
    for k,mat in enumerate(('container_red','container_blue')): container(-18.9,-7.0,-16.46,-.94,k*2.6,mat)
    for k,mat in enumerate(('container_blue','container_grey','container_green')):
        container(-18.9,-.6,-16.46,5.46,k*2.6,mat,'PILAR' if k==2 else None)
    for z0 in (-6.0,-2.6):
        box('metal',15.6,z0,2.6,3.2,0,2.6)
        for k in range(2): cyl('dark',16.9,z0+.8+k*1.6,.55,2.6,2.65,8,top=False)
    for h,pz in ((1.1,-2.2),(1.25,-1.6)): box('pot',13.0,pz,2.6,.08,h,h+.08)
    for k,mat in enumerate(('container_green','container_red','container_grey')): container(15.9,1.2,18.34,7.26,k*2.6,mat)
    armazem(-26,-19.4,-7.0,8.15,5.0,'facade_yellow','ARMAZÉM 7')
    armazem(19.4,26,-7.0,8.15,5.0,'facade_blue','ARMAZÉM 8')

# ---------------------------------------------------------------- inside
def decorate_inside():
    back=-7.29
    # Office: the shipping board over the desk.
    decal('linen',-12.6,-10.4,3.61,.85,1.35); text('dark','EXPEDIÇÃO — SAÍDAS',-11.5,3.62,1.22,.08)
    for k in range(6): box('dark',-12.4,3.62,1.4+.3*(k%2),.005,1.1-k*.04,1.11-k*.04)
    obox('red_paint',-10.6,4.3,.08,.06,.84,.9,.3)
    # Dock: stencils, the floor scale, hazard stripes round the pillars.
    text('yellow_paint','DOCA DE EXPEDIÇÃO',-1.0,3.62,1.1,.16)
    text('yellow_paint','CÂMARAS →',2.2,3.62,.85,.1)
    floor_quad('metal',-0.9,6.0,1.4,1.0,.05,.5)
    for bx,bz,bw,bd in ((-0.9,6.0,1.4,.05),(-0.9,6.95,1.4,.05),(-0.9,6.0,.05,1.0),(0.45,6.0,.05,1.0)): floor_quad('yellow_paint',bx,bz,bw,bd,.055,1.0)
    text('dark','BALANÇA 1500 KG',-0.2,6.5,.06,.1,flat=True)
    for px,pz in ((-3.4,4.2),(8.4,4.2)):
        for k in range(3): box('yellow_paint' if k%2==0 else 'black',px-.06,pz-.06,.52,.52,k*.06,k*.06+.06)
    # Corridor: chamber numbers on the floor, temperature readouts beside each door, the rail scale.
    for cx,n in CHAMBERS:
        text('yellow_paint','CÂMARA '+n,cx,.7,.05,.16,flat=True)
    for px in (-7.6,-2.6,5.5):
        box('dark',px-.2,.0,.4,.01,1.0,1.25); text('bulb_red','-18°C',px,.011,1.07,.08)
    cyl('metal',1.0,1.6,.18,2.2,2.3,6); cyl('iron',1.0,1.6,.02,2.3,2.62,4)
    # Chambers: name, temperature and the evaporator on the full-height back wall.
    for cx,n in CHAMBERS:
        text('dark','CÂMARA '+n,cx,back+.02,1.95,.3)
        text('bulb_red','-21°C',cx+1.2,back+.02,1.6,.12)
        box('white',cx-1.0,-7.3,2.0,.5,1.7,2.3)
        for k in range(3): cyl('dark',cx-.6+k*.6,-6.8,.2,1.69,1.7,8)
    # Showers: pipe, heads, drains, towels.
    box('chrome',-12.6,-7.3,2.2,.04,1.95,1.99)
    for hx in (-12.4,-11.6,-10.8):
        box('chrome',hx-.02,-7.3,.04,.2,1.85,1.95); cyl('chrome',hx,-7.1,.08,1.8,1.85,6)
        floor_quad('dark',hx-.08,-6.68,.16,.16,.05,1.0)
    for k,col in enumerate(('white','teal','red_paint')): box(col,-12.6+k*.4,-3.42,.32,.02,.7,1.25)
    # Compressor room: the electrical panel, the ammonia warning, frosted pipes.
    box('green_paint',7.4,-7.3,3.0,.06,1.4,2.3)
    text('cream','CASA DE MÁQUINAS',8.9,-7.23,2.1,.12)
    for k in range(4): cyl('white',7.8+k*.6,-7.23,.09,1.65,1.66,8)
    obox('yellow_paint',11.8,-7.25,.55,.02,1.6,2.2,0)
    text('dark','PERIGO — AMÔNIA',11.8,-7.22,1.85,.06)
    for h in (1.9,2.1): box('white',7.0,-7.3,2.2,.08,h,h+.08)
    # The pier door, swung open flat on the pier side.
    obox('metal',8.1,-7.86,1.8,.12,0,2.3)

def build_level5():
    data=st.load('level_5.json'); solids=data['solids']
    build_outside()
    floor_quad('granilite',-12.8,3.6,4.4,4.1,.04,1.2)        # office
    floor_quad('oil_concrete',-8.0,3.6,20.55,4.1,.04,2.4)    # dock
    floor_quad('white_tile',-12.8,-3.0,4.4,6.2,.04,1.0)      # locker room
    floor_quad('white_tile',-12.8,-7.3,4.2,3.9,.04,.8)       # showers
    floor_quad('cimento',-8.0,0.0,14.6,3.2,.04,1.6)          # cold corridor
    for cx,_ in CHAMBERS: floor_quad('frost',cx-2.2,-7.3,4.4,6.7,.04,1.4)
    floor_quad('concrete',7.0,-7.3,5.55,10.5,.04,1.4)        # compressor room
    floor_quad('yellow_paint',-8.0,7.25,20.55,.08,.045,1.0)
    for lz in (.35,2.85): floor_quad('yellow_paint',-8.0,lz,14.6,.06,.045,1.0)
    for x,z,w,d,mat in DOORS5: floor_quad(mat,x,z,w,d,.05,.8)
    walls=kit.wall_pieces(solids)
    for x,z,w,d,h in walls: lav.build_wall(x,z,w,d,h,walls,ROOMS5,SKINS5)
    pallets=iter(range(99)); doors=iter((True,True,False))
    for s in solids:
        x,z,w,d=s['r']; kind=s['type']; h=s['h']
        if kind=='wall': continue
        if kind=='pallet': build_pallet(x,z,w,d,h,next(pallets))
        elif kind=='chamberdoor': build_chamberdoor(x,z,w,d,next(doors))
        elif kind=='lockers':
            west_wall=any(o['type']=='wall' and abs(o['r'][0]+o['r'][2]-x)<.05 for o in solids)
            st.build_lockers(x,z,w,d,1 if west_wall else -1)
        else:
            {'truck':build_truck,'desk':lav.build_desk,'shelves':st.build_shelves,'pillar':lav.build_pillar,
             'forklift':build_forklift,'bench':st.build_lockerbench,'stalls':lav.build_stalls,
             'compressor':build_compressor,'tank':build_tank,'workbench':st.build_workbench,
             'drums':st.build_drums}[kind](x,z,w,d)
    build_rails()
    decorate_inside()

if __name__=='__main__':
    with kit.workspace('Caju') as scene:
        make_palette()
        build_level5()
        triangles=kit.assemble(scene)
        kit.export_glb(os.path.join(ROOT,'assets/environment/caju.glb'))
        bpy.data.libraries.write(os.path.join(ROOT,'tools/source/caju.blend'),{scene},fake_user=True,compress=True)
        print('CAJU_READY',len(scene.objects),'meshes',triangles,'triangles',len(kit.images),'textures')
