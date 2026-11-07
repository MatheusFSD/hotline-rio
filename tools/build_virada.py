"""Cast and sets for the special report that closes Act 1 ("O Síndico agradece", docs/narrativa.md).

Same PSX kit as every night (build_environment.py); the people come from the supplied PSX packs,
rebound to the UAL rig by build_intro.py's rebind. Writes assets/news/virada_1:
- castelar.glb: Álvaro Castelar (Character_Male_40, the navy suit recoloured to the "terno claro"
  of the bible), talking and pointing at the press.
- cadaver.glb: the body that walks out of the IML's drawer (Character_Male_56), UAL2's zombie walk.
- perito.glb: the forensic expert kneeling by the body at the tram workshop (Character_26_Doctor).
- press.glb: the press conference: a navy wall of "ORDEM NA CASA", the podium bristling with the
  stations' microphones, the campaign banners. Built so Castelar is only ever seen from the waist up.
- oficina.glb: night outside the tram workshop in Santa Teresa: the arched door, tram 17 on the
  rails, a police car, cones and tape, the body under a sheet with the phone still lit beside it.
- iml.glb: the IML corridor the security camera watches: refrigerated drawers, one open, a gurney
  with an empty body bag unzipped, fluorescent tubes, the doors of CÂMARA FRIA 2.
Each set is built around the origin; scripts/intro.gd places it in the newscast's world.
    blender -b --factory-startup --python "godot 3d/tools/build_virada.py"
"""
import bpy, os, math, importlib.util
import numpy as np

HERE=os.path.dirname(os.path.abspath(__file__))
spec=importlib.util.spec_from_file_location('lapa_intro',os.path.join(HERE,'build_intro.py'))
bi=importlib.util.module_from_spec(spec); spec.loader.exec_module(bi)
kit=bi.kit
C,mix,mul,grain,hsh,vnoise=kit.C,kit.mix,kit.mul,kit.grain,kit.hsh,kit.vnoise
box,obox,cyl,face,text=kit.box,kit.obox,kit.cyl,kit.face,kit.text
OUT=os.path.join(kit.ROOT,'assets','news','virada_1')
SOURCE=os.path.join(kit.ROOT,'tools','source')
TEXTURES=os.path.join(SOURCE,'Characters_psx','Textures')

# ---------------------------------------------------------------- cast
CAST=[('castelar','Male/Character_Male_40','Character_Male_40_claro',['Idle_Talking_Loop','Idle_Loop','Spell_Simple_Shoot']),
    ('cadaver','Male/Character_Male_56','Character_Male_56',['Zombie_Walk_Fwd_Loop','Zombie_Idle_Loop']),
    ('perito','Male/Character_26_Doctor','Character_26_Doctor',['Fixing_Kneeling','Idle_Loop'])]

def light_suit():
    """Castelar's suit in the pack is navy; the bible dresses him in a light one. Navy cloth
    becomes cream, the grey trousers a pale stone, everything else (face, shirt, shoes) untouched."""
    src=bpy.data.images.load(os.path.join(TEXTURES,'Character_Male_40.png'))
    w,h=src.size
    px=np.array(src.pixels[:],dtype=np.float32).reshape(h,w,4)
    r,g,b=px[...,0],px[...,1],px[...,2]
    v=np.maximum(np.maximum(r,g),b)
    navy=(b>r+.04)&(b>g+.02)&(v<.42)&(px[...,3]>.5)
    # The trousers lie on the left two thirds of the sheet; the head and hair, on the right, keep their colours.
    columns=np.arange(w)[None,:]<w*.68
    grey=(np.abs(r-g)<.04)&(np.abs(g-b)<.05)&(v>.2)&(v<.55)&~navy&columns
    lum=np.clip((r+g+b)/3/.3,0,1)[...,None]
    cream_dark,cream=np.array(C('9a917f')),np.array(C('e9e2d0'))
    px[...,:3]=np.where(navy[...,None],cream_dark+(cream-cream_dark)*lum,px[...,:3])
    stone=np.clip(px[...,:3]*1.55+np.array(C('3a3630'))*.5,0,1)
    px[...,:3]=np.where(grey[...,None],stone,px[...,:3])
    out=bpy.data.images.new('Character_Male_40_claro',w,h,alpha=True)
    out.pixels.foreach_set(px.ravel().tolist())
    out.filepath_raw=os.path.join(TEXTURES,'Character_Male_40_claro.png'); out.file_format='PNG'; out.save()
    print('SUIT',int(navy.sum()),'navy and',int(grey.sum()),'grey pixels recoloured')

def full_hands():
    """build_intro's bone map covers the index finger only, which is enough for its T-posed cast.
    These models stand in an A-pose, so every finger, the thumb and the end bones get their UAL
    bone too, or the hands would stay behind where the A-pose had them."""
    for side,suffix in [('Left','l'),('Right','r')]:
        for finger,ual in [('Thumb','thumb'),('Middle','middle'),('Ring','ring'),('Pinky','pinky'),('Index','index')]:
            for i in range(1,4): bi.mapping[side+'Hand'+finger+str(i)]=f'{ual}_0{i}_{suffix}'
            bi.mapping[side+'Hand'+finger+'4']=f'{ual}_03_{suffix}'
        bi.mapping[side+'Toe_End']='ball_'+suffix
    bi.mapping['HeadTop_End']='Head'

def build_cast():
    full_hands()
    bi.kit.scene=bpy.context.scene
    bi.OUT=OUT
    before=set(bpy.data.actions)
    bpy.ops.import_scene.gltf(filepath=os.path.join(SOURCE,'UAL1_Standard.glb'))
    rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
    rig.name='RioRig'
    for o in list(bpy.context.scene.objects):
        if o!=rig: bpy.data.objects.remove(o,do_unlink=True)
    actions={a.name.split('.')[0]:a for a in set(bpy.data.actions)-before}
    # The second library has the zombie walk; its actions drive the same bones.
    before=set(bpy.data.actions); objects=set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(SOURCE,'UAL2_Standard.glb'))
    for o in set(bpy.context.scene.objects)-objects: bpy.data.objects.remove(o,do_unlink=True)
    for a in set(bpy.data.actions)-before: actions.setdefault(a.name.split('.')[0],a)
    rig.animation_data.action=None
    for t in rig.animation_data.nla_tracks: t.mute=True
    for p in rig.pose.bones: p.matrix_basis=bi.Matrix.Identity(4)
    bpy.context.view_layer.update()
    # These packs stand 1.69 m in their files, not the first pack's 4.38: same size on the rig.
    for name,model,texture,clips in CAST: bi.rebind(rig,actions,name,model,texture,clips,scale=.36*4.38/1.69)
    bpy.data.objects.remove(rig,do_unlink=True)

# ---------------------------------------------------------------- textures
def t_backdrop(x,y):
    return grain(mix(C('15224a'),C('1d2c5c'),vnoise(x,y,8,4,70)*.5),x,y,.04,71)

def t_lino(x,y):
    """The IML's floor: plain pale linoleum, polished, a scuff here and there."""
    c=mul(C('cfd6d0'),.94+.08*vnoise(x,y,6,5,72))
    if hsh(x//3,y//3,73)>.97: c=mul(c,.9)
    return grain(c,x,y,.03,74)

def t_iml_tile(x,y):
    c=C('a9c4b4') if (x%8 and y%8) else C('8ea596')
    return grain(c,x,y,.04,75)

def t_steel(x,y):
    return grain(mix(C('9aa1a5'),C('b9c0c3'),vnoise(x*.3,y*2,3,6,76)),x,y,.05,77)

def t_brick(x,y):
    row=y//4; off=4 if row%2 else 0
    c=C('5a3a2c') if (y%4==0 or (x+off)%8==0) else mix(C('8a4a34'),C('9a5a3e'),hsh((x+off)//8,row,78))
    return grain(c,x,y,.06,79)

def materials():
    kit.make_palette()
    bi.make_intro_palette()
    for name,fn,size in [('backdrop',t_backdrop,32),('lino',t_lino,32),('iml_tile',t_iml_tile,32),('steel',t_steel,16),('brick',t_brick,32)]:
        kit.material(name,image=kit.texture(name,size,size,fn))
    for name,color in {'podium':'182650','gold':'d6b04a','cream_text':'c9c2ad','sheet':'e7e4dc','blood':'3c0a0a',
            'bag':'101114','bag_in':'3a3d42','plaster_white':'dfe0da','pole':'b9bec4','mic_red':'c4161c','mic_blue':'1f6fd6',
            'mic_yellow':'ffd21a','mic_green':'2a9d55','rail':'5a5d60','tram_grey':'6a6e72','fixture':'e8e6de'}.items():
        kit.material(name,color)
    kit.material('tube_light','f4f8ff',emission='e8f0ff',strength=2.5)
    kit.material('phone_glow','9fd4ff',emission='7fc8ff',strength=3)
    kit.material('bonde_lit','ffe9a8',emission='ffd77a',strength=1.2)

# ---------------------------------------------------------------- the press conference
def build_press():
    kit.floor_quad('concrete',-4,-2,8,5,0,1.0)
    kit.wall_quad('backdrop',-3.5,3.5,-1.4,0,3.4,1.0)
    # The slogan wall: rows of ORDEM NA CASA, staggered, and the name over his head.
    for row in range(5):
        for col in range(4):
            x=-3.0+col*2.0+(1.0 if row%2 else 0)
            text('cream_text','ORDEM NA CASA',x,-1.385,.35+row*.62,.16)
    box('backdrop',-1.3,-1.39,2.6,.02,1.75,2.75)
    text('gold','CASTELAR',0,-1.36,2.25,.42)
    text('cream_text','GOVERNADOR',0,-1.36,1.95,.16)
    # Banners on poles either side.
    for x in (-2.2,2.2):
        cyl('pole',x,-.9,.02,0,2.9,6)
        box('podium',x-.02,-.92,.5,.02,1.5,2.8)
        text('gold','ORDEM',x+.23,-.895,2.35,.12)
        text('gold','NA CASA',x+.23,-.895,2.18,.12)
        box('gold',x-.02,-.92,.5,.022,1.6,1.66)
    # The podium, the house on its front, the microphones of every station.
    box('podium',-.4,-.3,.8,.3,0,.92,.5)
    obox('podium',0,-.19,.88,.4,.92,.97,0)
    box('gold',-.4,0,.8,.012,.84,.86)
    text('gold','CASTELAR',0,.013,.5,.12)
    text('cream_text','ORDEM NA CASA',0,.013,.4,.055)
    face('gold',[(x,-z,h) for x,z,h in [(-.1,.014,.7),(.1,.014,.7),(0,.014,.79)]],1.0,(0,-1,0))
    box('gold',-.07,.008,.14,.006,.6,.7)
    mics=[('mic_red',-.24),('mic_blue',-.14),('mic_yellow',-.05),('white',.05),('mic_green',.14),('mic_red',.23)]
    for i,(mat,x) in enumerate(mics):
        mx,mz=x*.6,-.2-(.04 if i%2 else 0); tip=1.2+.03*(i%3)      # each station's mic on its own thin stand
        cyl('gloss_black',mx,mz,.006,.97,tip,4)
        cyl('gloss_black',mx,mz,.016,tip,tip+.06,6)
        obox(mat,mx,mz,.045,.04,tip-.045,tip-.005,0)

# ---------------------------------------------------------------- the tram workshop, at night
def build_oficina():
    kit.floor_quad('pedra',-10,-4,20,12,0,1.6)
    for z in (.35,1.65):                                  # the rails, into the workshop
        box('rail',-10,z-.04,20,.08,.0,.05)
    # The workshop's front: brick, the big arched door into the dark, the sign.
    for x0,x1 in ((-10,-2.2),(2.2,10)):
        box('brick',x0,-4,x1-x0,.4,0,6.5,1.2)
    box('brick',-2.2,-4,4.4,.4,3.9,6.5,1.2)
    for i in range(12):                                   # the arch over the door
        a0=math.pi*i/12; a1=math.pi*(i+1)/12
        face('brick',[(-2.2*math.cos(a0),3.6,3.3+.6*math.sin(a0)),(-2.2*math.cos(a1),3.6,3.3+.6*math.sin(a1)),(-2.2*math.cos(a1),3.6,3.9),(-2.2*math.cos(a0),3.6,3.9)],1.2,(0,-1,0))
    box('dark',-2.2,-4.2,4.4,.2,0,3.9)
    box('cream',-3.2,-3.62,6.4,.04,4.3,4.85)
    text('red_paint','OFICINA DOS BONDES',0,-3.57,4.45,.3)
    for x in (-7.5,-5.0,5.0,7.5):                         # high windows, a light left on in one
        box('bonde_lit' if x==5.0 else 'dark',x-.6,-3.61,1.2,.02,3.6,5.2)
    # Tram 17, stopped on the rails half out of the door, the lights off.
    tx0,tx1=1.2,7.8
    box('mic_yellow',tx0,-.1,tx1-tx0,2.1,.45,1.15,.8)
    for i in range(7):
        x=tx0+i*(tx1-tx0)/6
        box('mic_yellow',x-.06,-.1,.12,2.1,1.15,2.05)
    box('dark',tx0+.06,-.08,tx1-tx0-.12,2.06,1.2,2.0)
    box('tram_grey',tx0-.1,-.2,tx1-tx0+.2,2.3,2.05,2.2)
    for x in (tx0+.5,tx1-.5):
        for z in (.15,1.85): cyl('iron',x,z,.3,0,.45,8)
    text('dark','17',tx1-.8,2.012,.62,.36)
    for t in range(8):                                    # the trolley pole up to the wire
        a=t/8; b=(t+1)/8
        box('iron',tx0+2.0+2.2*a-.02,.93,.04,.04,2.2+1.6*a,2.2+1.6*b)
    # A patrol car across the street, cones, the tape round the door.
    vx,vz=-6.2,4.6
    box('police_white',vx-2.1,vz-.85,4.2,1.7,.3,.95,.8)
    obox('police_white',vx-.2,vz,2.2,1.55,.95,1.38,0)
    obox('screen',vx-.2,vz,2.0,1.57,1.0,1.33,0)
    obox('police_white',vx-.2,vz,1.7,1.4,1.38,1.46,0)
    box('police_blue',vx-2.1,vz-.87,4.2,.03,.55,.72)
    text('police_blue','POLÍCIA',vx-.2,vz-.89,.74,.24)
    obox('led_red',vx-.45,vz,.45,.9,1.46,1.58,0); obox('led_blue',vx+.05,vz,.45,.9,1.46,1.58,0)
    for wx in (-1.35,1.35):
        for wz in (-.8,.8): obox('tire',vx+wx,vz+wz,.62,.2,0,.58,0)
    posts=[(-3.4,2.6),(-1.0,3.1),(1.6,2.8),(3.6,3.2)]
    for px,pz in posts:
        cyl('cone',px,pz,.16,0,.62,6,r1=.03); cyl('white',px,pz,.105,.3,.4,6,top=False)
    for (ax,az),(bx,bz) in zip(posts,posts[1:]):
        obox('zebrada',(ax+bx)/2,(az+bz)/2,math.dist((ax,az),(bx,bz)),.02,.52,.6,math.atan2(bz-az,bx-ax),.4)
    # Nestor "Gravata" under a sheet by the door, the blood, his phone still lit on the stones.
    bx_,bz_=-2.6,-1.9
    obox('sheet',bx_,bz_,1.8,.62,0,.16,.25)
    obox('sheet',bx_-.55,bz_-.13,.5,.5,.1,.3,.25)
    obox('sheet',bx_+.3,bz_+.07,.7,.5,.1,.26,.25)
    obox('blood',bx_-.4,bz_+.5,1.1,.7,.003,.006,.6)
    obox('gloss_black',bx_+.9,bz_+.75,.08,.15,.006,.02,.9)
    obox('phone_glow',bx_+.9,bz_+.75,.065,.12,.02,.024,.9)
    # A street lamp on the corner.
    cyl('iron',4.6,3.9,.07,0,4.2,6); box('iron',4.0,3.86,.6,.08,4.1,4.18); cyl('bulb',4.05,3.9,.12,3.8,4.1,4)

# ---------------------------------------------------------------- the IML corridor
def build_iml():
    kit.floor_quad('lino',-1.6,-11,3.2,11.5,0,1.0)
    for x,facing in ((-1.6,1),(1.6,-1)):
        n=(facing,0,0)
        face('iml_tile',[(x,-.5,0),(x,11,0),(x,11,1.4),(x,-.5,1.4)],.5,n)
        face('plaster_white',[(x,-.5,1.4),(x,11,1.4),(x,11,3.0),(x,-.5,3.0)],1.0,n)
    face('plaster_white',[(-1.6,-.5,3.0),(1.6,-.5,3.0),(1.6,11,3.0),(-1.6,11,3.0)],1.5,(0,0,-1))
    for z in (-1.0,-3.6,-6.2,-8.8):
        box('fixture',-.15,z-.7,.3,1.4,2.95,3.0)
        box('tube_light',-.1,z-.65,.2,1.3,2.92,2.95)
    # The cold drawers on the left wall: three high, four along; the third of the middle row open.
    x=-1.6
    box('steel',x,-6.6,.06,4.6,.3,2.4,.4)
    for col in range(4):
        for row in range(3):
            z0=-6.5+col*1.12; h0=.38+row*.68
            if not (col==2 and row==1):
                box('steel',x+.06,z0+.04,.02,1.0,h0,h0+.6,.3)
                box('iron',x+.08,z0+.42,.03,.2,h0+.26,h0+.32)
                box('white',x+.08,z0+.08,.005,.18,h0+.44,h0+.52)
            else:
                box('dark',x+.061,z0+.04,.005,1.0,h0,h0+.6)
                box('steel',x+.06,z0+.08,.95,.92,h0+.05,h0+.12,.3)       # the tray, pulled out (to x -.59: his lane stays clear)
    # The gurney and the bag he left, unzipped, empty.
    gx,gz=.75,-3.3
    box('steel',gx-.35,gz-1.0,.7,2.0,.82,.86,.3)
    for lx in (-.3,.3):
        for lz in (-.9,.9): box('iron',gx+lx-.02,gz+lz-.02,.04,.04,0,.82)
    box('bag',gx-.3,gz-.95,.6,1.9,.86,.95)
    box('bag_in',gx-.18,gz-.85,.36,1.7,.95,.951)
    box('bag',gx-.33,gz-.95,.05,1.9,.95,1.02); box('bag',gx+.28,gz-.95,.05,1.9,.95,1.02)
    # The doors at the end, round windows, the sign.
    for side in (-1,1):
        box('steel',0 if side>0 else -1.4,-10.95,1.4,.05,0,2.3,.4)
        box('screen',side*.7-.17,-10.9,.34,.01,1.3,1.62)
    box('dark',-1.4,-10.97,2.8,.02,2.3,3.0)
    text('white','CÂMARA FRIA 2',0,-10.93,2.5,.22)

def export(name,build):
    with kit.workspace('Virada_'+name) as scene:
        materials()
        build()
        triangles=kit.assemble(scene)
        kit.export_glb(os.path.join(OUT,name+'.glb'))
        print('SET',name,triangles,'triangles')

if __name__=='__main__':
    if not bpy.app.background:
        raise RuntimeError('Run build_virada.py headless: blender -b --factory-startup --python build_virada.py')
    os.makedirs(OUT,exist_ok=True)
    light_suit()
    scene=bi.kit.scene=bpy.context.scene
    for ob in list(scene.objects): bpy.data.objects.remove(ob)
    build_cast()
    for ob in list(scene.objects): bpy.data.objects.remove(ob)
    export('press',build_press)
    export('oficina',build_oficina)
    export('iml',build_iml)
    print('VIRADA_READY')
