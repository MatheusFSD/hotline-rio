"""Cidade Nova, night nine, generated in Blender through the installed MCP bridge.

- telerio.glb (assets/level_9.json, docs/fase9.md): the TeleRio studios, home of "Alerta Rio",
  the night before the script of 13/12 goes on air. The lobby on the front left; the technical
  corridor with the breaker, Jairo's dressing room and the tape archive down the left; the newsroom
  at the front and the studio behind it, with the curved screen, the anchor desk and the lighting
  truss; the editing suite on the right and the garage of the OB vans, its shutter open to the
  street. Outside, Cidade Nova at night: the avenue, the red and white TeleRio mast, the
  Studio B, TeleRio's other building, against the exit, and the Teleporto district at its real size.

Same kit as every night (build_ilha.py → build_lagoa.py → build_guardiao.py → …). Collision comes
from the level file; the lamps the breaker puts out are Godot lights (scripts/main.gd).
    blender -b --factory-startup --python "godot 3d/tools/build_telerio.py"
"""
import bpy, os, math, importlib.util

HERE=os.path.dirname(os.path.abspath(__file__))
spec=importlib.util.spec_from_file_location('lagoa_kit',os.path.join(HERE,'build_lagoa.py'))
lagoa=importlib.util.module_from_spec(spec); spec.loader.exec_module(lagoa)
guardiao=lagoa.guardiao; caju=lagoa.caju; st=lagoa.st; lav=lagoa.lav; kit=lagoa.kit
ROOT=kit.ROOT
box,obox,cyl,face=kit.box,kit.obox,kit.cyl,kit.face
wall_quad,floor_quad,decal,text=kit.wall_quad,kit.floor_quad,kit.decal,kit.text

def make_palette():
    lagoa.make_palette()
    kit.material('studio_floor',image=kit.texture('studio_floor',32,32,kit.cement('3a3c40','34363a',.03,21)))
    for name,color in {'telerio_blue':'1c3a6e','alerta_red':'c8232c','van_white':'e8e8e2','acoustic':'2a2c32'}.items():
        kit.material(name,color)
    kit.material('on_air','ff4a3a',emission='ff2a1a',strength=3)

def make_exterior_palette():
    """Surfaces belonging to night nine only; the broadcast interior keeps its palette."""
    for name,base,dark,seed,joint in (
        ('t9_concrete','868f94','727e85',111,0),('t9_paving','adb0a3','949c94',112,16),
        ('t9_road','3b454e','303b45',113,0),('t9_yard','626e75','5a666d',114,0),
        ('t9_roof','69787d','53686e',115,0)):
        kit.material(name,image=kit.texture(name,32,32,kit.cement(base,dark,.025,seed,joint)))
    for name,col in {'t9_blue':'2c4b6d','t9_steel':'455964','t9_trim':'a5b0aa',
        't9_glass':'2c4354','t9_glass_blue':'435c6c','t9_red':'934e51',
        't9_white':'a8b5b5','t9_seat':'6b8590','t9_marking':'afa890',
        't9_dish':'a1b0b3','t9_tire':'242e35'}.items():
        kit.material(name,col)
    kit.material('t9_office_lit','5f5540',emission='5c4c2e',strength=.08)
    kit.material('t9_door','d9c79a',emission='e8cf92',strength=.55)
    kit.material('t9_lamp','b3a789',emission='d1b888',strength=.32)
    kit.material('t9_warning','a75b56',emission='bc584f',strength=.45)

def dish(x,z,h,r=.45):
    """Faceted shallow satellite dish, tilted toward the sky, on a real pedestal."""
    cyl('t9_steel',x,z,.05,h-.3,h,6)
    rim=[]
    for k in range(12):
        a=k*math.tau/12
        rim.append((x+math.cos(a)*r,-z+math.sin(a)*r*.7,h+math.sin(a)*r*.7+.12))
    for k in range(12):
        face('t9_dish',[(x,-z,h),rim[k],rim[(k+1)%12]],1,(0,-.7,.7))
        a,b=rim[k],rim[(k+1)%12]
        guardiao.strut('t9_steel',(a[0],-a[1],a[2]),(b[0],-b[1],b[2]),.018)
    guardiao.strut('t9_steel',(x,z,h),(x,z-.3,h+.4),.025)
    cyl('t9_steel',x,z-.3,.045,h+.37,h+.45,6)

def mast():
    """The station's red and white lattice at a real mast's size: from this camera its foot stands in
    the yard and it runs out of the top of the frame, as anything that tall must."""
    x,z=3.8,-11.4; top=24.0; step=2.4
    box('t9_concrete',x-1.3,z-1.25,2.6,2.5,-.18,.12)
    for level in range(int(top/step)):
        h=.12+level*step; r=.82-level*.042; nr=r-.042
        mat='t9_red' if level%2==0 else 't9_white'
        low=[(x+math.cos(k*math.tau/3)*r,z+math.sin(k*math.tau/3)*r,h) for k in range(3)]
        high=[(x+math.cos(k*math.tau/3)*nr,z+math.sin(k*math.tau/3)*nr,h+step) for k in range(3)]
        for k in range(3):
            j=(k+1)%3
            guardiao.strut(mat,low[k],high[k],.065)
            guardiao.strut(mat,low[k],low[j],.05)
            guardiao.strut(mat,low[k],high[j],.035)
            guardiao.strut(mat,low[j],high[k],.035)
    for dx in (-3.6,3.6):
        box('t9_concrete',x+dx-.2,z+1.0,.4,.4,-.12,.14)
        guardiao.strut('t9_steel',(x,z,top*.6),(x+dx,z+1.2,.14),.02)
    dish(x+.5,z+.4,5.2,.5)
    # Ladder and cable tray at a person's scale.
    for h in range(40):
        box('t9_steel',x-.2,z+.32,.4,.03,.3+h*.35,.33+h*.35)
    for dx in (-.2,.2): box('t9_steel',x+dx,z+.32,.03,.03,.3,14.3)
    box('t9_steel',x-.1,-10.7,.2,1.5,.05,.14)

def rear_block(x,w,h,seed):
    """A low Cidade Nova building at its real size, across the yard: its street face fills the band
    above the station's back wall, with the parapet of its roof just inside the frame."""
    z=-13.0; d=14.0
    box('t9_white' if seed%2 else 't9_concrete',x,z-d,w,d,-.12,h,1.4)
    cols=max(2,int(w/2.4))
    for row in range(int(h/2.8)):
        h0=.8+row*2.8
        for k in range(cols):
            wx=x+.6+k*(w-1.0)/cols
            mat='t9_office_lit' if (row*5+k*3+seed)%7==0 else 't9_glass'
            wall_quad(mat,wx,wx+1.4,z+.012,h0,h0+1.5)
            box('t9_trim',wx-.05,z+.015,1.5,.05,h0-.08,h0)
    box('t9_roof',x-.06,z-d,w+.12,d+.06,h,h+.12,1.6)
    box('t9_trim',x-.06,z-.1,w+.12,.14,h+.12,h+.5)

def rear_tower(x,w,seed):
    """A Teleporto office tower at its real size: a stone podium with a lit lobby, then the curtain wall
    of ordinary 3.4 m floors, running out of the top of the frame."""
    z=-13.0; d=18.0; h=40.0; podium=3.6
    box('t9_glass',x,z-d,w,d,-.12,h)
    box('t9_concrete',x-.2,z-.3,w+.4,.5,-.12,podium,1.4)
    for k in range(int((w-1.0)/3.2)):
        lobby=x+.9+k*3.2
        wall_quad('t9_office_lit',lobby,lobby+2.6,z+.21,.25,2.9)
        for m in (.86,1.72): box('t9_steel',lobby+m,z+.22,.06,.03,.25,2.9)
    panes=int(w/1.6)
    for row in range(5):
        h0=podium+.25+row*3.4
        for k in range(panes):
            px=x+.08+k*w/panes
            mat='t9_office_lit' if (row*5+k*3+seed)%13==0 else 't9_glass_blue'
            wall_quad(mat,px,px+w/panes-.12,z+.012,h0,h0+2.5)
        box('t9_steel',x,z+.015,w,.05,h0+2.5,h0+3.4)
    for k in range(panes+1): box('t9_steel',x+k*w/panes-.05,z+.02,.1,.06,podium,podium+.25+5*3.4)

def rear_yard():
    floor_quad('t9_yard',-60,-14.2,120,6.45,-.02,1.6)
    # The Teleporto across the yard: low buildings between the towers, none of them a smaller copy.
    for x,w,seed,h in ((-46,11,1,6.6),(-24.6,11.6,3,6.2),(-.8,9.6,5,6.6),(21,10,7,6.2)):
        rear_block(x,w,h,seed)
    for x,w,seed in ((-34.6,10,2),(-12.6,11.4,4),(9,11.6,6),(31.2,12,8)):
        rear_tower(x,w,seed)
    # Mechanical yard behind the archive: vents, service doors and ducts, all outside the floor.
    for k in range(3):
        x=-11.6+k*1.4; z=-10.6-(k%2)*.8
        box('t9_steel',x,z,1.1,.8,.03,.65)
        cyl('t9_glass',x+.55,z+.4,.25,.65,.675,8)
        for j in range(4): box('t9_trim',x+.1+j*.24,z+.805,.03,.012,.18,.53)
    box('t9_concrete',-6.7,-12.0,2.7,1.5,-.02,.75)
    box('t9_roof',-6.8,-12.1,2.9,1.7,.75,.86)
    wall_quad('t9_steel',-5.8,-5.1,-10.485,.02,.62)
    box('t9_steel',-8.4,-9.45,5.2,.28,.04,.22)
    mast()

def annex():
    """Studio B: TeleRio's other building, against the garage's exit corridor. The night's plan is only
    the part of the station we go through: dressing rooms, toilets and the rest lie beyond that door."""
    kit.glued_wing(15.1,-7.75,8.15,8.2,(1.6,4.4),'t9_concrete','t9_roof','t9_glass_blue','t9_office_lit','t9_trim','t9_door')
    box('t9_blue',15.5,8.2,5.9,.05,5.2,6.05)
    text('t9_trim','TELERIO  ESTÚDIO B',18.45,8.26,5.42,.45)
    for x,z in ((16.6,-5.0),(19.8,-5.0),(17.4,3.0)):
        box('t9_steel',x,z,2.0,1.4,8.2,9.1)
        cyl('t9_glass',x+1.0,z+.7,.4,9.1,9.16,8)
    box('t9_glass',16.4,-2.2,4.2,2.4,8.2,8.5)
    dish(19.6,3.4,8.2,.6)

def front_facade():
    for x,w in ((-15.1,4.5),(-9.2,24.3)):
        wall_quad('t9_blue',x,x+w,8.23,.18,1.25)
        box('t9_trim',x,8.24,w,.065,.12,.22)
    box('t9_blue',-5.3,8.25,6.9,.06,.3,1.13)
    text('t9_trim','TELERIO',-1.85,8.325,.62,.33)
    text('t9_trim','ESTÚDIOS  •  CIDADE NOVA',6.0,8.32,.69,.11)
    for x in (-10.7,-9.2): box('t9_trim',x,8.15,.09,.16,.1,1.35)
    # Garage shutter rolled ABOVE the side opening, never across its clear approach.
    for z in (1.12,4.43): box('t9_steel',13.02,z,.1,.07,0,1.42)

def news_van():
    x,z=4.5,11.6
    box('t9_white',x,z,3.0,1.8,.28,1.35)
    box('t9_blue',x,z-.01,3.0,.025,.55,.78)
    box('t9_blue',x,z+1.79,3.0,.025,.55,.78)
    box('t9_white',x+3,z,1.4,1.8,.28,.77)
    box('t9_white',x+3,z+.08,.85,1.64,.77,1.14)
    face('t9_glass',[(x+3.85,-z-.08,1.14),(x+4.4,-z-.08,.77),
        (x+4.4,-z-1.72,.77),(x+3.85,-z-1.72,1.14)],1,(1,0,1))
    for pz in (z-.012,z+1.812):
        face('t9_glass',[(x+3.1,-pz,.79),(x+4.25,-pz,.79),
            (x+3.85,-pz,1.1),(x+3.1,-pz,1.1)],1,(0,-1 if pz>z else 1,0))
    for px in (x+.65,x+3.55):
        for pz in (z-.025,z+1.825):
            face('t9_tire',[(px+math.cos(i*math.tau/10)*.28,-pz,.28+math.sin(i*math.tau/10)*.28) for i in range(10)],1,(0,-1 if pz>z else 1,0))
    text('t9_trim','TELERIO',x+1.5,z+1.83,.88,.18)
    dish(x+1.1,z+.9,1.67,.48)
    box('t9_roof',x+2.15,z+.5,.6,.8,1.35,1.52)

def street_front():
    floor_quad('t9_paving',-45,8.15,90,2.45,.07,1.4)
    box('t9_concrete',-40,10.5,80,.14,-.25,.07,1.4)
    for k in range(17): floor_quad('t9_marking',-39+k*4.8,15,2.3,.1,-.115)
    for x in (-13.5,-6.5,3,10.5,18.5,26.5):
        cyl('t9_steel',x,9.9,.04,.07,2.1,6)
        box('t9_lamp',x-.1,9.8,.2,.2,2.0,2.12)
    news_van()
    # Finer-grained Cidade Nova frontage replaces a single very broad roof.
    kit.sobrado(-28,-22.1,8,-8,4.0,'facade_blue',doors=False,side=True)
    kit.sobrado(-21.7,-15.7,8,-9,4.8,'facade_yellow',doors=False,side=True)
    box('t9_blue',-20.9,8.09,4.4,.05,.65,1.3)
    text('t9_trim','OFICINA',-18.7,8.16,.9,.2)
    for x in (-25.5,-19.2):
        box('t9_concrete',x,8.08,.7,.35,2.0,2.35)
        for j in range(4): box('t9_steel',x+.08+j*.14,8.44,.025,.012,2.07,2.28)

# ---------------------------------------------------------------- the plan
ROOMS9=[('recepcao',-12.8,-5.6,3.4,7.7),('redacao',-5.2,4.6,3.4,7.7),('corredor',-8.0,-5.6,-7.3,3.0),('camarim',-12.8,-8.4,-2.4,3.0),
    ('arquivo',-12.8,-8.4,-7.3,-2.8),('estudio',-5.2,4.6,-7.3,3.0),('edicao',5.0,12.55,-7.3,-2.8),('garagem',5.0,12.55,-2.4,7.7)]
SKINS9={'recepcao':('white',1.4,False),'redacao':('cream',1.0,False),'corredor':('concrete',1.4,False),'camarim':('wood',1.2,True),
    'arquivo':('metal',1.4,False),'estudio':('acoustic',1.4,False),'edicao':('screen',1.4,False),'garagem':('concrete',.9,False),
    'outside':('concrete',1.4,False)}
DOORS9=[(-10.6,7.7,1.4,.45),(-7.6,3.0,1.6,.4),(-1.4,3.0,2.0,.4),(-5.6,4.6,.4,1.4),(-8.4,.4,.4,1.4),(-8.4,-5.6,.4,1.4),
    (-5.6,-2.0,.4,1.4),(4.6,-5.4,.4,1.4),(4.6,-.4,.4,1.6),(4.6,4.6,.4,1.4),(6.0,-2.8,1.4,.4),(12.55,1.6,.45,2.8)]

# ---------------------------------------------------------------- props
def build_anchordesk(x,z,w,d):
    """The Alerta Rio anchor desk: a curved front in red and navy, two monitors set in the top."""
    n=7
    for k in range(n):
        t0,t1=k/n,(k+1)/n
        a0,a1=math.pi*(1-t0),math.pi*(1-t1)
        x0,x1=x+w/2+math.cos(a0)*w/2,x+w/2+math.cos(a1)*w/2
        z0,z1=z+d*.3+math.sin(a0)*d*.7,z+d*.3+math.sin(a1)*d*.7
        face('telerio_blue',[(x0,-z0,0),(x1,-z1,0),(x1,-z1,.95),(x0,-z0,.95)],1,(math.cos((a0+a1)/2),-math.sin((a0+a1)/2),0))
        face('alerta_red',[(x0,-z0-.0,.55),(x1,-z1,.55),(x1,-z1,.7),(x0,-z0,.7)],1,(math.cos((a0+a1)/2),-math.sin((a0+a1)/2),0))
    box('acoustic',x+.1,z,w-.2,d*.5,0,.95)
    box('white',x,z,w,d*.75,.95,1.0,.6)
    for mx in (x+w*.25,x+w*.65): box('black',mx,z+.15,.4,.05,1.0,1.25); box('tv_glow',mx+.02,z+.201,.36,.005,1.03,1.22)
    text('white','ALERTA RIO',x+w/2,z+d+.01,.62,.12)

def build_studiocam(x,z,w,d):
    """Studio camera on a pedestal: tripod base, column, body with a red tally, cable on the floor."""
    cx,cz=x+w/2,z+d/2
    for k in range(3):
        a=k*math.tau/3+.3
        obox('iron',cx+math.cos(a)*.18,cz+math.sin(a)*.18,.36,.05,0,.08,a)
    cyl('metal',cx,cz,.05,.08,1.05,6)
    box('black',cx-.16,cz-.3,.32,.55,1.05,1.32)
    cyl('black',cx,cz-.38,.07,1.12,1.25,6)
    box('on_air',cx-.05,cz+.24,.1,.02,1.28,1.32)
    for k in range(5): obox('black',cx+.2+k*.08,cz+.3+math.sin(k)*.1,.12,.03,0,.02,k*.6)

def build_van(x,z,w,d):
    """OB van, cut like the tram at 1.4 m: white body, blue stripe, folded dish, TELERIO on the side."""
    along_z=d>=w
    box('van_white',x,z,w,d,.3,1.4,.6)
    box('van_white',x-.01,z-.01,w+.02,d+.02,1.4,1.43,sides=False)   # the roof seen from above, white
    box('telerio_blue',x+w*.1,z+d*.1,w*.8,d*.8,1.43,1.44,sides=False)
    for wx,wz in ((x+.05,z+.4),(x+w-.15,z+.4),(x+.05,z+d-.8),(x+w-.15,z+d-.8)) if along_z else ((x+.4,z+.05),(x+.4,z+d-.15),(x+w-.8,z+.05),(x+w-.8,z+d-.15)):
        box('tire',wx,wz,.1 if along_z else .45,.45 if along_z else .1,0,.45)
    if along_z:
        box('telerio_blue',x-.005,z,.01,d,.75,.95); box('telerio_blue',x+w-.005,z,.01,d,.75,.95)
        box('glass',x+.1,z+.05,w-.2,.6,1.0,1.39)
        cyl('white',x+w/2,z+d*.6,.45,1.43,1.5,8); cyl('metal',x+w/2,z+d*.6,.05,1.5,1.7,4)
    else:
        box('telerio_blue',x,z+d-.005,w,.01,.75,.95)
        text('white','TELERIO',x+w/2,z+d+.01,.98,.18)
        box('glass',x+w-.6,z+.1,.55,d-.2,1.0,1.39)
        cyl('white',x+w*.4,z+d/2,.5,1.43,1.5,8); cyl('metal',x+w*.4,z+d/2,.05,1.5,1.7,4)
        for k in range(2): obox('van_white',x+.2,z+d+.25,.05,.6,.3,1.35,k*.4)   # back doors swung open

def build_tapes(x,z,w,d):
    """Archive shelving packed with U-matic tapes, white spines and handwritten years."""
    box('metal',x,z,w,d,0,1.4,.5)
    along=w>=d; length=w if along else d
    for row in range(5):
        h=.1+row*.27
        for k in range(int(length/.12)):
            t=.06+k*.12
            mat='white' if (k+row)%4 else 'black'
            if along: box(mat,x+t-.04,z+d+.003,.08,.01,h,h+.2)
            else: box(mat,x+w+.003,z+t-.04,.01,.08,h,h+.2)

def build_reception(x,z,w,d):
    box('white',x,z,w,d,0,.95,.6)
    box('telerio_blue',x-.02,z-.02,w+.04,d+.04,.95,1.0)
    box('telerio_blue',x,z+d-.01,w,.02,.2,.5)
    text('white','TELERIO',x+w/2,z+d+.01,.6,.12)
    box('screen',x+.4,z+.1,.4,.05,1.0,1.25); box('tv_glow',x+.42,z+.151,.36,.005,1.03,1.22)

# ---------------------------------------------------------------- inside
def decorate_inside():
    back=-7.29
    # The studio: the curved screen with the Alerta Rio sting, the lighting truss above.
    for k in range(7):
        a=(k-3)*.12
        cx=-.4+(k-3)*1.25
        obox('black',cx,back+.12+abs(k-3)*.12,1.24,.04,1.3,2.45,a)
        obox('tv_glow',cx,back+.15+abs(k-3)*.12,1.18,.01,1.35,2.4,a)
    text('alerta_red','ALERTA RIO',-.4,back+.5,2.05,.3)
    for tz in (-5.6,-2.4):
        box('iron',-4.8,tz,9.0,.06,2.7,2.76); box('iron',-4.8,tz+.25,9.0,.06,2.7,2.76)
        for k in range(6): box('black',-4.4+k*1.6,tz,.2,.3,2.45,2.7)
    box('on_air',-1.0,2.99,1.2,.02,1.6,1.85); text('white','NO AR',-.4,3.0,1.66,.12)
    # The editing suite: the grid of monitors.
    for row in range(2):
        for col in range(5):
            box('black',5.4+col*1.4,back,1.2,.04,1.5+row*.45,1.88+row*.45)
            box('tv_glow' if (row+col)%3 else 'on_air',5.45+col*1.4,back+.041,1.1,.005,1.54+row*.45,1.84+row*.45)
    # The archive: the years on the shelves.
    text('red_paint','1994',-12.3,back+.03,1.75,.14); text('red_paint','2010',-10.0,back+.03,1.75,.14)
    # The breaker on the corridor's west wall: a grey box, its lever and the PERIGO plate.
    box('metal',-8.0,-3.7,.15,.6,.85,1.38,.5)
    box('black',-7.86,-3.45,.04,.1,1.0,1.25)
    box('yellow_paint',-7.855,-3.65,.01,.5,1.28,1.36); text('black','PERIGO',-7.84,-3.4,1.29,.05)
    # The lobby's logo and the newsroom's clocks.
    box('telerio_blue',-12.8,7.69,4.0,.01,.9,1.35); text('white','TELERIO  —  ALERTA RIO',-10.8,7.68,1.05,.14)
    for k,city in enumerate(('RIO','BRASÍLIA','SÃO PAULO')):
        cyl('white',-3.8+k*2.6,7.69,.22,1.05,1.07,10); text('cream',city,-3.8+k*2.6,7.68,.75,.07)

# ---------------------------------------------------------------- outside
def build_outside():
    make_exterior_palette()
    # One continuous urban ground, not isolated roofs hanging in the clear colour.
    floor_quad('t9_road',-60,-45,120,90,-.12,2.4)
    box('t9_concrete',-13.25,-7.75,26.25,15.9,-.35,-.04,1.4)
    floor_quad('t9_yard',13.0,-9.1,2.1,17.25,.04,1.4)
    floor_quad('t9_yard',-15.1,-9.1,1.85,17.25,.04,1.4)
    floor_quad('t9_yard',-13.25,-9.1,28.35,1.35,.04,1.4)
    rear_yard()
    annex()
    front_facade()
    street_front()

def build_level9():
    data=st.load('level_9.json'); solids=data['solids']
    build_outside()
    floor_quad('granilite',-12.8,3.4,7.2,4.3,.04,1.2)
    floor_quad('carpete',-5.2,3.4,9.8,4.3,.04,1.4)
    floor_quad('cimento',-8.0,-7.3,2.4,10.3,.04,1.6)
    floor_quad('tacos',-12.8,-2.4,4.4,5.4,.04,1.6)
    floor_quad('concrete',-12.8,-7.3,4.4,4.5,.04,1.4)
    floor_quad('studio_floor',-5.2,-7.3,9.8,10.3,.04,1.4)
    floor_quad('carpete',5.0,-7.3,7.55,4.5,.04,1.4)
    floor_quad('oil_concrete',5.0,-2.4,7.55,10.1,.04,1.4)
    for x,z,w,d in DOORS9: floor_quad('granito',x,z,w,d,.05,.8)
    walls=kit.wall_pieces(solids)
    for x,z,w,d,h in walls: lav.build_wall(x,z,w,d,h,walls,ROOMS9,SKINS9)
    for s in solids:
        x,z,w,d=s['r']; kind=s['type']
        if kind=='wall': continue
        if kind=='crate': st.build_crate(x,z,w,d,s['h'])
        else:
            {'counter':build_reception,'sofa':lav.build_sofa,'plant':guardiao.build_plant,'desk':lav.build_desk,
             'anchordesk':build_anchordesk,'studiocam':build_studiocam,'shelves':build_tapes,'vanity':lav.build_vanity,
             'console':guardiao.build_console,'van':build_van}[kind](x,z,w,d)
    decorate_inside()

if __name__=='__main__':
    with kit.workspace('TeleRio') as scene:
        make_palette()
        build_level9()
        triangles=kit.assemble(scene)
        kit.export_glb(os.path.join(ROOT,'assets/environment/telerio.glb'))
        bpy.data.libraries.write(os.path.join(ROOT,'tools/source/telerio.blend'),{scene},fake_user=True,compress=True)
        print('TELERIO_READY',len(scene.objects),'meshes',triangles,'triangles',len(kit.images),'textures')
