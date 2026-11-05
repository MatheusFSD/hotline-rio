"""Botafogo, night eleven, generated in Blender through the installed MCP bridge.

- clinica.glb (assets/level_11.json, docs/planejado/fase10-12.md): the Clínica Santa Aurora,
  "rejuvenation and well-being", where the Condomínio renews its cascas. The emergency entrance on
  the front left with a stretcher; the marble reception and two consulting rooms along the front;
  the corridor across; the recovery ward with its eight sedated patients on the left, the operating
  theatre in the middle, the pharmacy, and Dra. Vera Lis' office on the right. The way out is the
  emergency exit on the right. Outside, a Botafogo street at night, an ambulance, and the Pão de
  Açúcar low in the distance.

Same kit as every night (build_lagoa.py → build_guardiao.py → …). Collision comes from the level
file; the patients under their sheets are drawn in Godot (scripts/patient_view.gd).
    blender -b --factory-startup --python "godot 3d/tools/build_clinica.py"
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
    kit.material('vinil',image=kit.texture('vinil',32,32,kit.cement('8fbfb4','86b5aa',.03,23)))
    for name,color in {'aqua_paint':'9cc9be','steel':'b8bec2','mattress':'dfe6ea','scrub':'4f8f84','pill':'e8e2d0','van_white':'e8e8e2'}.items():
        kit.material(name,color)
    kit.material('surgical_light','f4f8ff',emission='eaf2ff',strength=2.5)
    kit.material('cross_green','3ad07a',emission='2ab060',strength=2.5)

def make_exterior_palette():
    """Night eleven's own urban palette, independent of beds, patients and surgery."""
    for name,base,dark,seed,joint in (
        ('c11_stone','9da79b','828f83',141,16),('c11_paving','b3b3a4','979f93',142,16),
        ('c11_road','3d4850','303c46',143,0),('c11_facade','90a99b','768e81',144,0),
        ('c11_roof','77867f','5e736b',145,0),
        ('c11_ochre','9a9380','7f816f',149,0)):
        kit.material(name,image=kit.texture(name,32,32,kit.cement(base,dark,.03,seed,joint)))
    for name,col in {'c11_steel':'455e62','c11_glass':'365260','c11_trim':'b9c4b7',
        'c11_mint':'477c69','c11_white':'b6c4c0','c11_tire':'232d33',
        'c11_marking':'ada88d','c11_reflection':'3a5862','c11_red':'895958'}.items():
        kit.material(name,col)
    kit.material('c11_lamp','b3aa8a',emission='cab68f',strength=.3)
    kit.material('c11_door','d9c79a',emission='e8cf92',strength=.55)
    kit.material('c11_window','6f6448',emission='6e5c36',strength=.12)
    kit.material('c11_beacon_red','a16662',emission='bb6861',strength=.45)
    kit.material('c11_beacon_blue','718fa1',emission='7197b6',strength=.4)

def clinic_facade():
    # The frontage ends below the existing black wall cut; entrance and exit remain open.
    for x,w in ((-15.1,4.1),(-9.0,24.1)):
        wall_quad('c11_facade',x,x+w,8.235,.15,1.25)
        box('c11_stone',x,8.24,w,.08,.05,.24)
        box('c11_trim',x,8.25,w,.055,1.18,1.27)
    box('c11_mint',-5.4,8.27,12.6,.045,.47,1.13)
    text('c11_trim','CLÍNICA SANTA AURORA',.9,8.335,.7,.22)
    text('c11_trim','EMERGÊNCIA',-13.0,8.335,.68,.12)
    # A restrained green medical cross and two slender door jambs identify the arrival.
    box('c11_mint',-14.4,8.34,.45,.035,.7,.85)
    box('c11_mint',-14.25,8.34,.15,.035,.55,1.0)
    for x in (-11.08,-9.0): box('c11_trim',x,8.15,.08,.15,.1,1.35)
    for x in (8.1,10.4,12.7):
        wall_quad('c11_glass',x,x+1.25,8.285,.4,1.05)
        box('c11_trim',x,8.31,.035,.025,.39,1.08)
        for h in (.58,.78,.98): box('c11_steel',x,8.315,1.25,.02,h,h+.018)
    # Clinic foundations and continuous paving give the side emergency approach a base.
    box('c11_stone',-13.25,-7.75,26.25,15.9,-.4,-.05,1.4)
    # The pavement runs the whole street, in front of the wing and the old houses too.
    floor_quad('pedra',-60,8.15,120,2.45,.07,1.4)
    box('c11_stone',-60,10.5,120,.14,-.25,.07)

def ambulance():
    """A high-roof ambulance with a distinct cab, glazing, wheels and medical livery."""
    x,z=-13.1,11.25
    box('c11_white',x,z,3.15,1.88,.32,1.58)
    box('c11_white',x+.06,z+.04,3.0,1.8,1.58,1.79)
    box('c11_roof',x-.04,z-.025,3.18,1.93,.25,.36)
    for pz in (z-.012,z+1.892):
        box('c11_mint',x,pz,3.15,.025,.65,.84)
        face('c11_glass',[(x+.16,-pz,1.04),(x+1.12,-pz,1.04),
            (x+1.12,-pz,1.4),(x+.16,-pz,1.4)],1,(0,-1 if pz>z else 1,0))
    # Two rear doors and the line where they meet are visible on the cabin's back face.
    box('c11_steel',x-.012,z+.91,.018,.045,.4,1.54)
    box('c11_white',x+3.15,z,1.52,1.88,.32,.87)
    box('c11_white',x+3.15,z+.09,.9,1.7,.87,1.36)
    face('c11_glass',[(x+4.05,-z-.09,1.36),(x+4.67,-z-.09,.87),
        (x+4.67,-z-1.79,.87),(x+4.05,-z-1.79,1.36)],1,(1,0,1))
    for pz in (z-.012,z+1.892):
        face('c11_glass',[(x+3.25,-pz,.91),(x+4.48,-pz,.91),
            (x+4.0,-pz,1.31),(x+3.25,-pz,1.31)],1,(0,-1 if pz>z else 1,0))
        box('c11_mint',x+3.15,pz,1.5,.025,.65,.84)
    for px in (x+.65,x+3.76):
        for pz in (z-.025,z+1.905):
            ring=[(px+math.cos(k*math.tau/12)*.31,.3+math.sin(k*math.tau/12)*.31) for k in range(12)]
            face('c11_tire',[(cx,-pz,h) for cx,h in ring],1,(0,-1 if pz>z else 1,0))
            face('c11_steel',[(px+math.cos(k*math.tau/10)*.13,-pz-(.003 if pz>z else -.003),.3+math.sin(k*math.tau/10)*.13) for k in range(10)],1,(0,-1 if pz>z else 1,0))
    # The top cross reads from the game's camera; the light bar is a small, quiet accent.
    box('c11_mint',x+1.25,z+.4,.22,1.05,1.792,1.8)
    box('c11_mint',x+.85,z+.8,1.02,.22,1.792,1.8)
    box('c11_steel',x+2.72,z+.29,.28,1.3,1.79,1.87)
    box('c11_beacon_red',x+2.73,z+.3,.26,.51,1.87,1.94)
    box('c11_beacon_blue',x+2.73,z+1.07,.26,.51,1.87,1.94)
    box('c11_roof',x+.3,z+.28,.54,.45,1.79,1.87)
    text('c11_mint','SANTA AURORA',x+1.75,z+1.93,1.06,.12)
    for dz in (.17,1.43): box('c11_lamp',x+4.67,z+dz,.025,.25,.53,.67)

def rear_block(x,w,h,seed):
    """A Botafogo apartment building at its real size, behind the clinic's service alley: from this
    camera its street face fills the band above the back wall, with its roof just in the frame."""
    z=-11.0; d=14.0
    box('c11_ochre' if seed%2 else 'c11_facade',x,z-d,w,d,-.15,h,1.4)
    floors=int(h/2.8); cols=max(2,int(w/2.3))
    for row in range(floors):
        h0=.75+row*2.8
        for k in range(cols):
            wx=x+.6+k*(w-1.0)/cols
            mat='c11_window' if (row*5+k*3+seed)%7==0 else 'c11_glass'
            wall_quad(mat,wx,wx+1.3,z+.012,h0,h0+1.5)
            box('c11_trim',wx-.05,z+.015,1.4,.05,h0-.08,h0)
        box('c11_stone',x,z+.02,w,.06,h0+1.72,h0+1.82)
    box('c11_roof',x-.06,z-d,w+.12,d+.06,h,h+.12,1.6)
    box('c11_stone',x-.06,z-.1,w+.12,.14,h+.12,h+.5)

def neighborhood():
    # The service alley behind the clinic, and the street of real buildings beyond it.
    floor_quad('c11_roof',-60,-11,120,3.25,-.03,1.4)
    for x,w,h,seed in ((-46,11,9.0,1),(-34.6,9,8.4,2),(-25.2,12,9.4,3),(-12.8,10,8.4,4),(-2.4,13,9.2,5),(11,10,8.4,6),(21.4,12,9.4,7),(33.8,11,8.4,8)):
        rear_block(x,w,h,seed)
    # Historic frontage on the left of the emergency door.
    kit.sobrado(-28,-22,8,-8.5,4.4,'facade_green',doors=False,side=True)
    kit.sobrado(-21.7,-15.7,8,-9,5.0,'facade_pink',doors=False,side=True)
    # Rear ventilation for the clinic's everyday use.
    for k in range(3):
        x=-11.8+k*1.4
        box('c11_steel',x,-10.2,1.0,.7,-.02,.65)
        cyl('c11_glass',x+.5,-9.85,.23,.65,.67,8)
    # The clinic does not end at the night's map: its other wing stands against the exit corridor.
    kit.glued_wing(15.1,-7.75,8.15,8.2,(1.0,2.4),'c11_facade','c11_roof','c11_glass','c11_window','c11_trim','c11_door')
    box('c11_mint',15.5,8.2,5.9,.05,5.2,6.05)
    text('c11_trim','SANTA AURORA  ALA B',18.45,8.26,5.42,.45)
    for x,z in ((16.6,-5.0),(19.6,-5.0),(17.6,2.5)):
        box('c11_steel',x,z,2.0,1.5,8.2,9.1)
        cyl('c11_glass',x+1.0,z+.75,.42,9.1,9.14,8)
    cyl('c11_steel',18.0,-1.0,.7,8.2,9.8,8)
    cyl('c11_trim',18.0,-1.0,.74,9.8,9.92,8)

def street_front():
    # A grounded street, the ambulance bay and crossing continue beyond the playable pavement.
    floor_quad('c11_road',-60,-13.4,120,56.6,-.12,2.4)
    box('c11_stone',-55,-13.48,110,.08,-1.45,-.12,1.4)
    for k in range(18): floor_quad('c11_marking',-42+k*5,15.7,2.2,.1,-.115)
    for z in (10.88,13.37): floor_quad('c11_marking',-13.7,z,5.9,.07,-.114)
    floor_quad('c11_marking',-13.7,10.88,.07,2.49,-.114)
    for k in range(5): floor_quad('c11_stone',-5.6,11.0+k*.68,3.2,.32,-.114)
    for x in (-21.6,-14.4,-7.2,3.0,10.8,18.0,25.2):
        cyl('c11_steel',x,10.8,.035,-.12,1.9,5)
        box('c11_lamp',x-.09,10.71,.18,.18,1.82,1.95)
    ambulance()

# ---------------------------------------------------------------- the plan
ROOMS11=[('emergencia',-12.8,-6.4,3.4,7.7),('recepcao',-6.0,3.0,3.4,7.7),('consult1',3.4,7.8,3.4,7.7),('consult2',8.2,12.55,3.4,7.7),
    ('corredor',-12.8,12.55,0.4,3.0),('ala',-12.8,-4.8,-7.3,0.0),('cirurgico',-4.4,3.2,-7.3,0.0),('farmacia',3.6,7.4,-7.3,0.0),
    ('diretora',7.8,12.55,-7.3,0.0)]
SKINS11={'emergencia':('white_tile',1.3,False),'recepcao':('marble',1.2,False),'consult1':('aqua_paint',1.1,False),'consult2':('aqua_paint',1.1,False),
    'corredor':('aqua_paint',1.0,True),'ala':('aqua_paint',1.2,False),'cirurgico':('white_tile',1.4,False),'farmacia':('white_tile',1.3,False),
    'diretora':('wood',1.2,True),'outside':('whitewash',1.4,False)}

# ---------------------------------------------------------------- props
def build_bed(x,z,w,d,head=-1):
    """Hospital bed: steel frame on castors, rails, a mattress and pillow, an IV stand at the head.
    The long side runs along the longer axis; the pillow sits at the head end (-1: -z or -x, 1: +z or +x)."""
    along_z=d>=w
    for sx,sz in ((x+.06,z+.06),(x+w-.1,z+.06),(x+.06,z+d-.1),(x+w-.1,z+d-.1)):
        box('steel',sx,sz,.04,.04,.08,.6); cyl('black',sx+.02,sz+.02,.05,0,.08,5)
    box('steel',x,z,w,d,.6,.68,.5)
    box('mattress',x+.04,z+.04,w-.08,d-.08,.68,.82,.6)
    if along_z:
        box('white',x+.12,z+.1 if head<0 else z+d-.45,w-.24,.35,.82,.9)
        for rx in (x-.02,x+w-.01): box('steel',rx,z+d*.3 if head<0 else z+d*.25,.03,d*.45,.82,.95)
        hx,hz=x+w+.08,z+.15 if head<0 else z+d-.15
    else:
        box('white',x+.1,z+.12,.35,d-.24,.82,.9)
        for rz in (z-.02,z+d-.01): box('steel',x+w*.3,rz,w*.45,.03,.82,.95)
        hx,hz=x+.15,z-.08
    cyl('steel',hx,hz,.015,0,1.6,4); obox('steel',hx,hz,.3,.02,1.58,1.6,0)
    box('glass',hx-.06,hz-.03,.12,.06,1.3,1.52)

def build_optable(x,z,w,d):
    """Operating table on its column, a green drape, the surgical light on an arm above."""
    cx,cz=x+w/2,z+d/2
    box('steel',cx-.3,cz-.2,.6,.4,0,.08); cyl('steel',cx,cz,.1,.08,.8,6)
    box('scrub',x+.05,z+.15,w-.1,d-.3,.8,.92,.6)
    cyl('steel',x+w+.2,cz,.04,0,2.2,4)
    obox('steel',cx+.4,cz,1.2,.06,2.15,2.2,0)
    cyl('surgical_light',cx,cz,.35,1.95,2.05,8,r1=.25)
    for k in range(3): box('steel',x+.1+k*.35,z+d+.25,.3,.2,.9,.92)   # instrument tray

def build_clinic_counter(x,z,w,d):
    """Reception or nurses' counter: white lacquer, marble top, SANTA AURORA in green."""
    box('white',x,z,w,d,0,.95,.6)
    box('marble',x-.03,z-.03,w+.06,d+.06,.95,1.0)
    along=w>=d
    if along:
        box('scrub',x,z+d-.01,w,.02,.3,.55); text('white','SANTA AURORA',x+w/2,z+d+.01,.4,.09)
    else:
        box('scrub',x+w-.01,z,.02,d,.3,.55)
    box('screen',x+.1,z+.1,.35 if along else .05,.05 if along else .35,1.0,1.25)
    for k in range(3): box('pill',x+w*.5+k*.12,z+d*.4,.08,.06,1.0,1.08)

def build_pharmacy(x,z,w,d):
    """Pharmacy shelving: white boxes of medicine in rows, a few red and green labels."""
    box('white',x,z,w,d,0,1.4,.5)
    along=w>=d; length=w if along else d
    for row in range(5):
        h=.1+row*.27
        for k in range(int(length/.16)):
            t=.08+k*.16
            mat=['pill','white','red_paint','pill','scrub'][(k*3+row)%5]
            if along: box(mat,x+t-.06,z+d+.003,.12,.01,h,h+.16)
            else: box(mat,x+w+.003,z+t-.06,.01,.12,h,h+.16)

# ---------------------------------------------------------------- inside
def decorate_inside():
    back=-7.29
    # The ward: the clinic's motto over the beds; the theatre: a viewing panel of monitors.
    box('aqua_paint',-12.6,back,7.6,.02,1.7,2.2); text('scrub','RENOVAR É VIVER  —  CLÍNICA SANTA AURORA',-8.8,back+.03,1.88,.12)
    box('black',-3.6,back,6.4,.04,1.5,2.3)
    for k in range(4): box('tv_glow',-3.4+k*1.55,back+.045,1.4,.005,1.6,2.2)
    # Vera Lis' office: the campaign poster with her face beside Castelar's.
    box('cream',8.2,back,2.4,.02,1.5,2.35); text('red_paint','CASTELAR / VERA LIS',9.4,back+.03,2.1,.12)
    text('dark','ORDEM NA CASA',9.4,back+.03,1.75,.09)
    # The emergency entrance's lit green cross and the corridor's handrails.
    box('cross_green',-12.79,5.2,.02,.5,1.6,1.75); box('cross_green',-12.79,5.38,.02,.14,1.45,1.9)
    box('steel',-12.8,.42,25.3,.03,.85,.88); box('steel',-12.8,2.97,25.3,.03,.85,.88)

# ---------------------------------------------------------------- outside
def build_outside():
    make_exterior_palette()
    floor_quad('c11_roof',-15.1,-9.1,1.85,17.25,.04,1.4)
    floor_quad('c11_roof',-13.25,-9.1,28.35,1.35,.04,1.4)
    floor_quad('c11_roof',13.0,-9.1,2.1,17.25,.04,1.4)
    clinic_facade()
    neighborhood()
    street_front()

def build_level11():
    data=st.load('level_11.json'); solids=data['solids']
    build_outside()
    floor_quad('vinil',-12.8,3.4,6.4,4.3,.04,1.4)
    floor_quad('marble',-6.0,3.4,9.0,4.3,.04,1.2)
    floor_quad('vinil',3.4,3.4,9.15,4.3,.04,1.4)
    floor_quad('granilite',-12.8,.4,25.35,2.6,.04,1.2)
    floor_quad('vinil',-12.8,-7.3,8.0,7.3,.04,1.4)
    floor_quad('vinil',-4.4,-7.3,7.6,7.3,.04,1.4)
    floor_quad('white_tile',3.6,-7.3,3.8,7.3,.04,1.0)
    floor_quad('tacos',7.8,-7.3,4.75,7.3,.04,1.6)
    floor_quad('concrete',13.0,.55,2.1,2.3,.045,1.4)
    walls=kit.wall_pieces(solids)
    for x,z,w,d,h in walls: lav.build_wall(x,z,w,d,h,walls,ROOMS11,SKINS11)
    for s in solids:
        x,z,w,d=s['r']; kind=s['type']
        if kind=='wall': continue
        if kind=='bed' and d>w and z>-7.0:   # the front row of the ward lies with the head toward the corridor
            build_bed(x,z,w,d,1)
            continue
        {'counter':build_clinic_counter,'bed':build_bed,'sofa':lav.build_sofa,'plant':guardiao.build_plant,
         'desk':lav.build_desk,'optable':build_optable,'prep':kit.build_prep,'shelves':build_pharmacy}[kind](x,z,w,d)
    decorate_inside()

if __name__=='__main__':
    with kit.workspace('Clinica') as scene:
        make_palette()
        build_level11()
        triangles=kit.assemble(scene)
        kit.export_glb(os.path.join(ROOT,'assets/environment/clinica.glb'))
        bpy.data.libraries.write(os.path.join(ROOT,'tools/source/clinica.blend'),{scene},fake_user=True,compress=True)
        print('CLINICA_READY',len(scene.objects),'meshes',triangles,'triangles',len(kit.images),'textures')
