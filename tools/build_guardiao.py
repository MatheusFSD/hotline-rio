"""Centro, night six, generated in Blender through the installed MCP bridge.

- guardiao.glb (assets/level_6.json): the Guardião Segurança floor, fourteen storeys over the
  Avenida Presidente Vargas. The fire escape lands on the right; the locker room, the operations
  open-plan, the meeting room with its whiteboard and the reception along the front; the copa, the
  armory, the monitoring central and Rufino Avelar's office along the back; a long corridor
  between them, and the elevator out on the left. Around it nothing but lower roofs, water tanks
  and, far below, the avenue at night.

Same kit as every night (build_caju.py → build_santa_teresa.py → build_lavradio.py →
build_environment.py). Collision comes from the level file; the security cameras themselves are
drawn in Godot (scripts/camera_view.gd), since a shot or a cut breaks them.
    blender -b --factory-startup --python "godot 3d/tools/build_guardiao.py"
"""
import bpy, os, math, importlib.util
from mathutils import Vector

HERE=os.path.dirname(os.path.abspath(__file__))
spec=importlib.util.spec_from_file_location('caju_kit',os.path.join(HERE,'build_caju.py'))
caju=importlib.util.module_from_spec(spec); spec.loader.exec_module(caju)
st=caju.st; lav=caju.lav; kit=caju.kit
ROOT=kit.ROOT
box,obox,cyl,face,local=kit.box,kit.obox,kit.cyl,kit.face,kit.local
wall_quad,floor_quad,decal,text=kit.wall_quad,kit.floor_quad,kit.decal,kit.text

def make_palette():
    caju.make_palette()
    kit.material('carpete',image=kit.texture('carpete',32,32,kit.cement('4a5260','3e4552',.05,18,16)))
    # Dedicated exterior materials: night grading can keep the city readable without
    # changing the office, the shared kit, or another night's scenery.
    for name,base,dark,seed in (
        ('guardiao_facade','7b8184','656d72',81),
        ('guardiao_roof','737d83','5e6970',82),
        ('guardiao_road','454b55','343b45',83)):
        kit.material(name,image=kit.texture(name,32,32,kit.cement(base,dark,.025,seed)))
    for name,color in {'guardiao_trim':'a0a5a1','guardiao_steel':'43525e',
        'guardiao_window':'314657','guardiao_window_blue':'4d6573',
        'guardiao_marking':'b7b4a0','guardiao_car':'687c88',
        'guardiao_car_red':'745657','guardiao_tree':'344c4a'}.items():
        kit.material(name,color)
    kit.material('guardiao_window_lit','827f6c',emission='a99c79',strength=.22)
    kit.material('guardiao_lamp','b9a072',emission='ddba7e',strength=.55)

# ---------------------------------------------------------------- the plan
ROOMS6=[('avelar',-12.8,-7.6,-7.3,-2.4),('central',-7.2,2.6,-7.3,-2.4),('dvr',2.0,2.6,-3.6,-2.4),('armaria',3.0,7.6,-7.3,-2.4),
    ('copa',8.0,12.55,-7.3,-2.4),('recepcao',-12.8,-7.6,-2.0,7.7),('corredor',-7.6,12.55,-2.0,0.8),('reuniao',-7.2,-1.4,1.2,7.7),
    ('operacional',-1.0,7.8,1.2,7.7),('vestiario',8.2,12.55,1.2,7.7),('elevador',-15.1,-13.25,-1.6,0.85)]
SKINS6={'avelar':('wood',1.2,True),'central':('screen',1.4,False),'dvr':('metal',1.4,False),'armaria':('metal',1.4,False),
    'copa':('white_tile',1.3,False),'recepcao':('marble',1.2,False),'corredor':('cream',1.0,True),'reuniao':('wood',1.0,True),
    'operacional':('cream',1.0,False),'vestiario':('white_tile',1.3,False),'elevador':('chrome',1.4,False),'outside':('concrete',1.4,False)}
DOORS6=[(9.8,7.7,1.4,.45,'metal'),(-13.25,-1.2,.45,1.6,'metal'),(-10.6,-2.4,1.4,.4,'granito'),(-5.6,-2.4,1.4,.4,'granito'),
    (0.0,-2.4,1.4,.4,'granito'),(4.6,-2.4,1.4,.4,'granito'),(9.0,-2.4,1.4,.4,'granito'),(-7.6,-6.2,.4,1.4,'granito'),
    (-4.0,0.8,1.4,.4,'granito'),(2.6,0.8,1.6,.4,'granito'),(9.6,0.8,1.4,.4,'granito'),(-7.6,4.6,.4,1.4,'granito'),
    (-1.4,5.0,.4,1.4,'granito'),(7.8,4.4,.4,1.4,'granito')]

# ---------------------------------------------------------------- props
def build_console(x,z,w,d):
    """Monitoring operators' desk: laminate top, a row of small monitors facing the room, keyboards,
    a DVR stack at the east end, the operators' chairs inside the footprint."""
    top=.76
    for px in (x+.05,x+w-.1):
        for pz in (z+.05,z+.4): box('metal',px,pz,.05,.05,0,top)
    box('dark',x,z,w,.55,top,top+.04,.6)
    n=int((w-.6)/.62)
    for k in range(n):
        mx=x+.15+k*.62
        box('black',mx,z+.08,.5,.06,top+.04,top+.4)
        box('tv_glow',mx+.03,z+.141,.44,.005,top+.08,top+.36)
        box('pot',mx+.08,z+.25,.34,.12,top+.04,top+.06)   # keyboard
    box('black',x+w-.5,z+.05,.42,.45,top+.04,1.0)
    for k in range(3): box('bulb_green',x+w-.45+k*.1,z+.501,.04,.005,.88,.91)
    for k in range(n): kit.chair(x+.4+k*(w-.8)/max(n-1,1),z+d-.2,-math.pi/2,'leather')   # one chair per monitor pair

def build_gunrack(x,z,w,d):
    """Steel gun cabinet against a wall, grille doors swung open, rifles standing in their slots."""
    faces_z=w>=d
    box('metal',x,z,w,d,0,1.38,.5)
    box('cap',x,z,w,d,1.38,1.41,sides=False)
    if faces_z:
        for k in range(int((w-.2)/.18)):
            px=x+.15+k*.18
            box('iron',px,z+d,.04,.01,.15,1.25); box('black',px-.02,z+d+.005,.08,.01,.95,1.2)
        for dx in (x,x+w-.04): obox('iron',dx+(-.25 if dx==x else .29),z+d+.25,.04,.5,.1,1.3,.0)
    else:
        for k in range(int((d-.2)/.18)):
            pz=z+.15+k*.18
            box('iron',x-.01,pz,.01,.04,.15,1.25); box('black',x-.015,pz-.02,.01,.08,.95,1.2)

def build_counter(x,z,w,d):
    """Service counter: wood body, metal top. The armory's has a bar grille and the logbook; the
    reception's carries the company name on the side the camera sees."""
    box('wood',x,z,w,d,0,.92,.6)
    box('metal',x-.02,z-.02,w+.04,d+.04,.92,.97)
    box('black',x,z+d-.02,w,.03,0,.12)
    if x>0:   # armory: cautela window
        for k in range(int(w/.12)+1): box('iron',x+k*.12,z+d*.4,.02,.02,.97,1.38)
        box('iron',x,z+d*.4,w,.02,1.36,1.4)
        obox('books_b',x+w*.3,z+d*.7,.3,.22,.97,1.0,.2); obox('white',x+w*.3,z+d*.7,.26,.18,1.0,1.005,.2)
    else:
        text('brass','GUARDIÃO SEGURANÇA',x+w/2,z+d+.005,.5,.11)
        box('screen',x+.3,z+.1,.4,.05,.97,1.25); box('tv_glow',x+.32,z+.151,.36,.005,1.0,1.22)

def build_plant(x,z,w,d):
    cx,cz=x+w/2,z+d/2
    cyl('dark',cx,cz,.25,0,.5,8,r1=.22)
    cyl('soil',cx,cz,.21,.48,.5,8)
    for k in range(6):
        a=k*math.tau/6+.3
        fx,fz=cx+math.cos(a)*.18,cz+math.sin(a)*.18
        obox('leaf',fx,fz,.42,.09,.75+(k%2)*.2,.8+(k%2)*.2,a)
    cyl('leaf',cx,cz,.05,.5,1.0,4)

def build_meeting(x,z,w,d):
    """Meeting table on two pedestals, eight chairs round it, plans and a projector on top."""
    top=.74
    for pz in (z+.7,z+d-.9): box('dark',x+w/2-.15,pz,.3,.2,0,top)
    box('wood',x+.45,z+.3,w-.9,d-.6,top,top+.05,.6)
    for k in range(4):
        cz=z+.55+k*(d-1.1)/3
        kit.chair(x+.2,cz,0,'leather'); kit.chair(x+w-.2,cz,math.pi,'leather')
    obox('white',x+w/2-.2,z+d/2,.5,.36,top+.05,top+.055,.2); obox('linen',x+w/2+.15,z+d/2-.5,.45,.32,top+.05,top+.056,-.3)
    box('black',x+w/2-.12,z+d/2+.6,.24,.2,top+.05,top+.15)

# ---------------------------------------------------------------- inside
def decorate_inside():
    back=-7.29
    # Central: the wall of monitors, one of them CAM 03 in red.
    for row in range(3):
        for col in range(6):
            mx=-6.8+col*1.4; mh=1.5+row*.32
            box('black',mx,back,1.2,.04,mh,mh+.28)
            mat='bulb_red' if (row,col)==(1,4) else 'tv_glow'
            box(mat,mx+.05,back+.041,1.1,.005,mh+.03,mh+.25)
    text('cream','CAM 03',-6.8+4*1.4+.6,back+.05,1.98,.06)
    text('cream','CENTRAL DE MONITORAMENTO',-2.3,back+.03,2.42,.1)
    # Meeting room: the whiteboard on its back face.
    box('white',-7.0,1.2,2.5,.02,.7,1.35)
    text('dark','ELE ATRAVESSA PAREDE.',-5.75,1.225,1.18,.07)
    text('red_paint','MIRE ONDE ELE VAI SAIR.',-5.75,1.225,1.0,.07)
    box('red_paint',-6.4,1.225,1.3,.005,.86,.88); obox('red_paint',-5.05,1.225,.12,.005,.82,.92,.0)
    # Reception: the logo on the corridor-side wall.
    box('teal',-12.6,-1.99,1.8,.02,.75,1.3); text('cream','GUARDIÃO',-11.7,-1.97,1.05,.14); text('cream','SEGURANÇA',-11.7,-1.97,.85,.08)
    # Avelar: the ORDEM NA CASA poster and Prates' photo.
    box('cream',-12.5,back,1.0,.02,1.5,2.3); text('red_paint','ORDEM',-12.0,back+.03,2.0,.14); text('red_paint','NA CASA',-12.0,back+.03,1.78,.12)
    box('dark',-11.2,back+.02,.4,.01,1.7,2.2); box('wood',-11.17,back+.03,.34,.01,1.73,2.17)
    box('brass',-11.12,back+.04,.24,.005,1.8,2.1)
    # Armory and copa.
    text('yellow_paint','CAUTELA DE ARMAMENTO',5.3,back+.03,1.9,.11)
    box('black',8.5,back,.4,.4,1.0,1.4); box('red_paint',8.55,back+.4,.3,.005,1.25,1.32)   # coffee machine
    box('black',10.4,back,1.3,.05,1.6,2.3); box('tv_glow',10.45,back+.051,1.2,.005,1.65,2.25)
    # Elevator: doors slid open, the floor number lit.
    for dz in (-1.55,.35): box('chrome',-13.24,dz,.04,.45,0,1.4)
    box('bulb_red',-13.22,-.45,.02,.3,1.42,1.5)
    # The DVR closet's slit, glazed above the counter height.
    box('glass',2.05,-2.4,.45,.4,.9,1.4)

# ---------------------------------------------------------------- outside, fourteen storeys up
def strut(mat,a,b,width=.08):
    """A square structural member between level-space (x,z,height) endpoints."""
    a,b=Vector((a[0],-a[1],a[2])),Vector((b[0],-b[1],b[2]))
    along=(b-a).normalized()
    side=along.cross(Vector((0,0,1)) if abs(along.z)<.9 else Vector((1,0,0))).normalized()*width/2
    up=along.cross(side).normalized()*width/2
    ring=[side+up,-side+up,-side-up,side-up]
    for i in range(4):
        j=(i+1)%4
        face(mat,[tuple(a+ring[i]),tuple(a+ring[j]),tuple(b+ring[j]),tuple(b+ring[i])])
    face(mat,[tuple(a+r) for r in reversed(ring)])
    face(mat,[tuple(b+r) for r in ring])

def office_block(x,z,w,d,roof,seed,base=-42):
    """A complete commercial building: storeys, window bays and a serviced flat roof.
    Heights below the playable floor communicate the height of the Guardião tower."""
    box('guardiao_facade',x,z,w,d,base,roof,2.0)
    # Recessed, opaque window bands; sparse warm offices, never a wall of neon.
    rows=max(1,int((roof-base)/3))
    cols=max(2,int(w/1.8))
    for row in range(rows):
        h=roof-1.0-row*3
        box('guardiao_trim',x-.035,z+d,w+.07,.055,h-1.9,h-1.77)
        for k in range(cols):
            wx=x+.3+k*(w-.6)/cols
            mat='guardiao_window_lit' if (k*7+row*11+seed)%13==0 else ('guardiao_window_blue' if (k+row+seed)%4==0 else 'guardiao_window')
            wall_quad(mat,wx,wx+(w-.6)/cols-.16,z+d+.012,h-1.62,h-.12)
        for side in (x-.012,x+w+.012):
            for k in range(max(2,int(d/2))):
                pz=z+.3+k*2
                if pz+1.55>z+d: continue
                mat='guardiao_window_blue' if (k+row+seed)%5==0 else 'guardiao_window'
                # Correct outward normals on both sides of the building.
                face(mat,[(side,-pz,h-1.62),(side,-pz-1.55,h-1.62),
                    (side,-pz-1.55,h-.12),(side,-pz,h-.12)],1,(1 if side>x else -1,0,0))
    box('guardiao_roof',x-.08,z-.08,w+.16,d+.16,roof,roof+.16,2)
    for px in (x,x+w-.18): box('guardiao_trim',px,z,.18,d,roof+.16,roof+.62)
    for pz in (z,z+d-.18): box('guardiao_trim',x+.18,pz,w-.36,.18,roof+.16,roof+.62)
    # Roof access room, service path and ductwork give scale to the broad roof.
    box('guardiao_facade',x+.6,z+.65,2.2,2.0,roof+.16,roof+1.65,1.4)
    box('guardiao_trim',x+.5,z+.55,2.4,2.2,roof+1.65,roof+1.82)
    wall_quad('guardiao_steel',x+.95,x+1.65,z+2.665,roof+.18,roof+1.45)
    for k in range(2+seed%3):
        ax=x+w*.43+k*.95; az=z+d*.39+(k%2)*1.2
        box('guardiao_steel',ax,az,.72,1.0,roof+.2,roof+.68)
        cyl('guardiao_window',ax+.36,az+.5,.23,roof+.68,roof+.7,8)
    box('guardiao_trim',x+w*.53,z+2.0,.3,d*.35,roof+.2,roof+.39)
    # Raised tank and a separate lid: no coplanar caps flickering on screen.
    if seed%3!=1:
        tx,tz=x+w*.7,z+d*.76
        box('guardiao_steel',tx-.65,tz-.65,1.3,1.3,roof+.16,roof+.45)
        cyl('guardiao_steel',tx,tz,.58,roof+.45,roof+1.4,8)
        cyl('guardiao_trim',tx,tz,.62,roof+1.4,roof+1.48,8)
    else:
        # An older building's sawtooth skylight instead of a tank on every roof.
        for k in range(3):
            x0=x+w*.62; z0=z+d*.65+k*.55
            face('guardiao_window_blue',[(x0,-z0,roof+.2),(x0+1.4,-z0,roof+.2),
                (x0+1.4,-z0-.4,roof+.55),(x0,-z0-.4,roof+.55)],1,(0,-1,1))
            wall_quad('guardiao_steel',x0,x0+1.4,z0+.4,roof+.2,roof+.55)

def tower_facade():
    box('guardiao_facade',-13.85,-9.1,27.45,17.85,-42,-.12,2)
    box('guardiao_steel',-15.3,-2.05,1.45,3.35,-42,-.12)
    for row in range(14):
        h=-.55-row*3
        box('guardiao_trim',-13.9,8.75,27.55,.12,h-.35,h-.18)
        for col in range(14):
            wx=-13.45+col*1.92
            mat='guardiao_window_lit' if (row*5+col)%17==0 else 'guardiao_window'
            wall_quad(mat,wx,wx+1.48,8.763,h-2.28,h-.5)
            box('guardiao_steel',wx+.72,8.765,.035,.018,h-2.28,h-.5)
        for sx in (-13.864,13.614):
            for k in range(8):
                z=-8.6+k*2.0
                face('guardiao_window',[(sx,-z,h-2.28),(sx,-z-1.6,h-2.28),
                    (sx,-z-1.6,h-.5),(sx,-z,h-.5)],1,(1 if sx>0 else -1,0,0))
    box('guardiao_steel',-6.0,8.89,8.4,.055,-1.08,-.42)
    text('guardiao_trim','GUARDIÃO SEGURANÇA',-1.8,8.955,-.89,.25)
    for x in (-13.78,13.42): box('guardiao_trim',x,-9.1,.13,17.85,-.12,-.04)
    box('guardiao_trim',-13.85,8.67,27.45,.08,-.12,-.04)

def fire_escape():
    floor_quad('metal',8.4,8.15,4.2,2.45,.03,.5)
    # The balcony's underside, brackets and wall anchors are all visible from above.
    box('guardiao_steel',8.4,8.15,4.2,2.45,-.14,.015)
    for x in (8.5,10.5,12.5):
        box('guardiao_steel',x-.09,8.76,.18,.08,-1.6,-.2)
        strut('guardiao_steel',(x,8.8,-1.5),(x,10.5,-.14),.12)
    for x in (8.45,9.8,11.2,12.55):
        box('guardiao_steel',x,10.5,.045,.045,.03,1.0)
    box('guardiao_steel',8.4,10.5,4.2,.045,.96,1.01)
    box('guardiao_steel',8.4,10.5,4.2,.035,.48,.52)
    # A complete flight, stringers, handrails and the landing one floor below.
    for k in range(10):
        box('metal',12.6+k*.28,8.92,.28,1.5,-.27-k*.3,-.20-k*.3,.5)
    for z in (8.93,10.39):
        strut('guardiao_steel',(12.57,z,-.28),(15.42,z,-3.25),.13)
        strut('guardiao_steel',(12.57,z,1.0),(15.42,z,-2.0),.05)
        for k in (0,3,6,9):
            x=12.6+k*.28
            strut('guardiao_steel',(x,z,-.24-k*.3),(x,z,.94-k*.3),.04)
    box('guardiao_steel',13.3,8.92,2.2,3.3,-3.24,-3.12)
    for x in (13.35,15.45):
        strut('guardiao_steel',(x,8.95,-3.12),(x,8.95,-2.1),.05)
        strut('guardiao_steel',(x,8.95,-2.1),(x,12.15,-2.1),.05)
    strut('guardiao_steel',(13.55,8.75,-4.8),(15.35,10.5,-3.24),.14)
    for k in range(10): box('metal',13.3-k*.28,10.72,.28,1.5,-3.5-k*.3,-3.43-k*.3,.5)
    for z in (10.73,12.17):
        strut('guardiao_steel',(13.44,z,-3.5),(10.64,z,-6.5),.12)
        strut('guardiao_steel',(13.44,z,-2.2),(10.64,z,-5.2),.05)
    box('guardiao_lamp',11.7,8.18,.3,.09,1.62,1.78)
    text('guardiao_marking','14',12.05,8.21,1.2,.22)

def avenue():
    # 42 m below, BEHIND the tower. With this orthographic camera the old street at
    # z=+15 projected entirely below the viewport; z=-53..-34 puts it in the top band.
    floor_quad('guardiao_road',-65,-57,130,25,-42,2.4)
    for z in (-57,-34):
        floor_quad('guardiao_trim',-65,z,130,2,-41.91,1.4)
        box('guardiao_steel',-65,z,130,.15,-42,-41.7)
    for lane in (-51.0,-48.5,-44.0,-40.5):
        for k in range(31): floor_quad('guardiao_marking',-63+k*4.2,lane,1.9,.1,-41.97)
    floor_quad('guardiao_trim',-65,-46.8,130,1.6,-41.8,1.4)
    floor_quad('guardiao_tree',-65,-46.6,130,1.2,-41.77,1.4)
    for k in range(15):
        x=-58+k*8.3
        cyl('guardiao_steel',x,-46,.055,-41.77,-38.5,5)
        strut('guardiao_steel',(x,-46,-38.5),(x,-47,-38.1),.065)
        box('guardiao_lamp',x-.15,-47.15,.3,.38,-38.18,-38.08)
        # Small angular palm crowns, rather than the old large spherical tree blobs.
        if k%2==0:
            cyl('guardiao_steel',x+1.2,-46,.06,-41.77,-38.9,5)
            for j in range(5):
                a=j*math.tau/5
                face('guardiao_tree',[(x+1.2,46,-38.85),
                    (x+1.2+math.cos(a+.22)*.75,46+math.sin(a+.22)*.75,-39.03),
                    (x+1.2+math.cos(a)*1.1,46+math.sin(a)*1.1,-39.25),
                    (x+1.2+math.cos(a-.22)*.75,46+math.sin(a-.22)*.75,-39.03)],1,(0,0,1))
    for k in range(28):
        x=-57+k*4.3+(k%3)*.5; z=(-52.5,-50,-43,-39.5)[k%4]
        mat='guardiao_car_red' if k%4==0 else 'guardiao_car'
        box(mat,x,z,2.5,1.12,-41.94,-41.45)
        box('guardiao_window',x+.6,z+.08,1.25,.96,-41.45,-41.12)
        # Paired lights, subdued enough not to rival the actors or the HUD.
        for dz in (.15,.83): box('guardiao_lamp',x+(2.48 if k%4<2 else -.03),z+dz,.05,.16,-41.6,-41.49)

def build_outside():
    avenue()
    # Side frames are modern commercial buildings, with complete facades below the
    # rooftops. Their geometry never extends into the playable floor's silhouette.
    office_block(-29,-13,13.2,25,-6.0,3)
    office_block(16.0,-12,13.0,25,-8.0,8)
    # A stepped, continuous urban block replaces the two unsupported roof planes.
    for x,z,w,d,h,seed in [(-33,-26,10,7,-18,1),(-22,-27,9,7,-20,2),
        (-12,-28,8,7,-19,5),(-3,-25,10,7,-17,7),(8,-28,10,7,-21,9),(19,-26,13,7,-18,6)]:
        office_block(x,z,w,d,h,seed)
    tower_facade()
    floor_quad('concrete',-13.85,8.15,27.45,.6,0,1.4)
    floor_quad('concrete',-13.85,-9.1,.6,17.25,0,1.4)
    floor_quad('concrete',13.0,-9.1,.6,17.25,0,1.4)
    floor_quad('concrete',-13.25,-9.1,26.25,1.35,0,1.4)
    fire_escape()

def build_level6():
    data=st.load('level_6.json'); solids=data['solids']
    build_outside()
    floor_quad('tacos',-12.8,-7.3,5.2,4.9,.04,1.6)
    floor_quad('carpete',-7.2,-7.3,9.8,4.9,.04,1.4)
    floor_quad('concrete',3.0,-7.3,4.6,4.9,.04,1.4)
    floor_quad('white_tile',8.0,-7.3,4.55,4.9,.04,1.0)
    floor_quad('granilite',-12.8,-2.0,5.2,9.7,.04,1.2)
    floor_quad('granilite',-7.6,-2.0,20.15,2.8,.04,1.2)
    floor_quad('carpete',-7.2,1.2,5.8,6.5,.04,1.4)
    floor_quad('carpete',-1.0,1.2,8.8,6.5,.04,1.4)
    floor_quad('cimento',8.2,1.2,4.35,6.5,.04,1.6)
    floor_quad('metal',-15.1,-1.6,1.85,2.45,.04,.5)
    for x,z,w,d,mat in DOORS6: floor_quad(mat,x,z,w,d,.05,.8)
    walls=kit.wall_pieces(solids)
    for x,z,w,d,h in walls: lav.build_wall(x,z,w,d,h,walls,ROOMS6,SKINS6)
    for s in solids:
        x,z,w,d=s['r']; kind=s['type']
        if kind=='wall': continue
        if kind=='lockers': st.build_lockers(x,z,w,d,-1)
        elif kind=='table': kit.table_square(x,z,w,d,3)
        else:
            {'railing':st.build_railing,'bench':st.build_lockerbench,'prep':kit.build_prep,'gunrack':build_gunrack,
             'counter':build_counter,'console':build_console,'desk':lav.build_desk,'sofa':lav.build_sofa,'safe':lav.build_safe,
             'plant':build_plant,'meeting':build_meeting,'shelves':st.build_shelves}[kind](x,z,w,d)
    decorate_inside()

if __name__=='__main__':
    with kit.workspace('Guardiao') as scene:
        make_palette()
        build_level6()
        triangles=kit.assemble(scene)
        kit.export_glb(os.path.join(ROOT,'assets/environment/guardiao.glb'))
        bpy.data.libraries.write(os.path.join(ROOT,'tools/source/guardiao.blend'),{scene},fake_user=True,compress=True)
        print('GUARDIAO_READY',len(scene.objects),'meshes',triangles,'triangles',len(kit.images),'textures')
