"""Ilha Fiscal, night eight, generated in Blender through the installed MCP bridge.

- ilha.glb (assets/level_8.json, docs/fase8.md): the neo-gothic palace on its island in the
  Guanabara Bay, the night of the Síndico's ball, staged like the last ball of the Empire (1889).
  The caterers' boat ties up at the service quay on the front left and the kitchen door lets the
  hero in; the copa and the ceremonial room down the left; the ballroom in the middle with the
  orchestra and three lancet windows; the cloakroom and the tower hall along the front; the speech
  balcony and its antechamber on the right, the main quay below them. Around it the bay at night,
  the bridge to the Ilha das Cobras, Niterói's lights and the Rio–Niterói bridge, low and far.

Same kit as every night (build_lagoa.py → build_guardiao.py → build_caju.py → …). Collision comes
from the level file; the guests and the waiters are actors.
    blender -b --factory-startup --python "godot 3d/tools/build_ilha.py"
"""
import bpy, os, math, importlib.util

HERE=os.path.dirname(os.path.abspath(__file__))
spec=importlib.util.spec_from_file_location('lagoa_kit',os.path.join(HERE,'build_lagoa.py'))
lagoa=importlib.util.module_from_spec(spec); spec.loader.exec_module(lagoa)
guardiao=lagoa.guardiao; caju=lagoa.caju; st=lagoa.st; lav=lagoa.lav; kit=lagoa.kit
ROOT=kit.ROOT
box,obox,cyl,face=kit.box,kit.obox,kit.cyl,kit.face
wall_quad,floor_quad,decal,text=kit.wall_quad,kit.floor_quad,kit.decal,kit.text
C,grain,hsh=kit.C,kit.grain,kit.hsh

def t_parquet(x,y):
    """Wide cumaru boards in one warm tone: a thin joint every ten pixels, faint grain, no pattern."""
    c=C('7a4a2a')
    if y%10==0: c=C('5a3420')
    elif (x+(y//10)*13)%32==0: c=C('64391f')
    return grain(c,x,y,.035,63)

def make_palette():
    lagoa.make_palette()
    kit.material('parquet',image=kit.texture('parquet',32,32,t_parquet))
    for name,color in {'palace_green':'7d9488','cantaria':'8a8c88','ogive':'e6dcc4','empire_green':'2f5a3a'}.items():
        kit.material(name,color)
    kit.material('stained','e0a040',emission='d08a2a',strength=.9)

def make_exterior_palette():
    """The island's own night palette, independent of the shared interior kit."""
    for name,base,dark,seed,joint in (
        ('ilha_paving','9faaa4','89948e',101,16),('ilha_stone','87928a','6e7b75',102,16),
        ('ilha_green','6b8c7a','577564',103,0),('ilha_roof','344d54','2c414a',104,8),
        ('ilha_water','1e3744','182d3b',105,0),('ilha_warehouse','8b8d7e','70796d',106,0)):
        kit.material(name,image=kit.texture(name,32,32,kit.cement(base,dark,.025,seed,joint)))
    for name,col in {'ilha_trim':'b2b7a3','ilha_wet':'3e5955','ilha_iron':'37494f',
        'ilha_glass':'2d4550','ilha_reflection':'3a5362','ilha_boat':'b6c3bc',
        'ilha_hull':'425f64','ilha_far':'3a505d','ilha_clock':'c5bea0'}.items():
        kit.material(name,col)
    kit.material('ilha_lamp','baa67d',emission='d7b781',strength=.4)
    kit.material('ilha_window','9d946f',emission='b8a578',strength=.25)

def pointed_window(x,z,h,w=.55,height=1.15,lit=False):
    """A true pointed silhouette with stone surround, mullion and a recessed opening."""
    spring=h+height*.66
    def pane(mat,half,low,top,depth):
        face(mat,[(x-half,-depth,low),(x+half,-depth,low),
            (x+half,-depth,spring),(x+half*.58,-depth,spring+height*.19),
            (x,-depth,top),(x-half*.58,-depth,spring+height*.19),
            (x-half,-depth,spring)],1,(0,-1,0))
    pane('ilha_trim',w/2+.055,h-.055,h+height+.06,z)
    pane('ilha_window' if lit else 'ilha_glass',w/2,h,h+height,z+.015)
    box('ilha_iron',x-.018,z+.022,.036,.022,h,h+height*.88)
    box('ilha_stone',x-w/2-.08,z-.02,w+.16,.16,h-.1,h-.045)

def spire(x,z,r,h,top,sides=8):
    for k in range(sides):
        a,b=k*math.tau/sides,(k+1)*math.tau/sides
        face('ilha_roof',[(x+math.cos(a)*r,-z+math.sin(a)*r,h),
            (x+math.cos(b)*r,-z+math.sin(b)*r,h),(x,-z,top)],.8)
    cyl('ilha_iron',x,z,.025,top,top+.22,4)

def turret(x,z,base=0,body=2.3,r=.48):
    cyl('ilha_stone',x,z,r+.1,base,base+.17,8)
    cyl('ilha_green',x,z,r,base+.17,base+body,8,phase=math.pi/8)
    cyl('ilha_trim',x,z,r+.05,base+body-.16,base+body+.04,8)
    spire(x,z,r+.12,base+body+.04,base+body+1.35)
    pointed_window(x,z+r+.006,base+.55,.29,.75)

def palace_exterior():
    # Complete decorative tower BEHIND the cutaway: its silhouette identifies the
    # palace without raising any wall in the playable floor or hiding a doorway.
    x,z=.4,-11.25
    box('ilha_stone',x-1.6,z-1.5,3.2,3.0,-1.65,.3,1)
    box('ilha_green',x-1.25,z-1.15,2.5,2.3,.3,4.45,1.2)
    for h in (.32,2.45,4.38): box('ilha_trim',x-1.34,z-1.24,2.68,2.48,h,h+.13)
    for sx in (x-1.24,x+1.05): box('ilha_stone',sx,z+1.15,.19,.22,.3,4.45)
    for wx in (x-.65,x+.65): pointed_window(wx,z+1.17,.7,.48,1.2)
    # Clock disk standing in the facade plane, with hands and four main hour marks.
    cz=z+1.195; ch=3.42; radius=.53
    for mat,r,depth in (('ilha_stone',radius+.09,cz),('ilha_clock',radius,cz+.012)):
        face(mat,[(x+math.cos(i*math.tau/16)*r,-depth,ch+math.sin(i*math.tau/16)*r) for i in range(16)],1,(0,-1,0))
    for k in range(4):
        a=k*math.pi/2
        guardiao.strut('ilha_iron',(x+math.cos(a)*.4,cz+.023,ch+math.sin(a)*.4),
            (x+math.cos(a)*.46,cz+.023,ch+math.sin(a)*.46),.025)
    guardiao.strut('ilha_iron',(x,cz+.025,ch),(x-.25,cz+.025,ch+.15),.035)
    guardiao.strut('ilha_iron',(x,cz+.026,ch),(x+.12,cz+.026,ch+.37),.025)
    # Four steep roof faces and a small pinnacle crown, rather than a flat roof box.
    corners=[(x-1.36,z-1.25),(x+1.36,z-1.25),(x+1.36,z+1.25),(x-1.36,z+1.25)]
    for i,(px,pz) in enumerate(corners):
        qx,qz=corners[(i+1)%4]
        face('ilha_roof',[(px,-pz,4.58),(qx,-qz,4.58),(x,-z,6.1)],.8)
        turret(px,pz,4.5,.48,.15)
    cyl('ilha_iron',x,z,.03,6.1,6.65,4)
    # Corner turrets and buttresses belong to the perimeter, not to the combat rooms.
    for tx in (-15.8,15.8):
        cyl('ilha_stone',tx,-8.6,.65,-1.65,.06,8)
        turret(tx,-8.6,.06,2.25,.43)
    for tx in (-13.55,13.0):
        for pz in (-5.9,-2.5,1.0):
            box('ilha_stone',tx,pz,.32,.48,-.02,1.4)
            spire(tx+.16,pz+.24,.2,1.4,1.93,4)
    # Green front facade below the black cut, with stone courses and pointed openings.
    for x0,w in ((-15.1,3.7),(-10.0,23.0)):
        wall_quad('ilha_green',x0,x0+w,8.225,.09,1.28)
        box('ilha_stone',x0,8.23,w,.09,.05,.22)
        for k in range(int(w/2.1)):
            wx=x0+1.0+k*2.1
            pointed_window(wx,8.245,.35,.42,.68)
    # The entrance arch is engraved in the outside face; the opening stays clear.
    text('ilha_trim','ILHA FISCAL',.8,8.29,1.07,.15)

def island_base():
    outline=[(-14.85,-10.05),(14.85,-10.05),(15.65,-9.25),(15.65,9.05),
        (14.85,9.85),(-14.85,9.85),(-15.65,9.05),(-15.65,-9.25)]
    face('ilha_stone',[(x,-z,-.045) for x,z in outline],1.4,(0,0,1))
    for i,(x,z) in enumerate(outline):
        nx,nz=outline[(i+1)%len(outline)]
        for mat,lo,hi in (('ilha_stone',-1.65,-1.28),('ilha_wet',-1.28,-.94),('ilha_stone',-.94,-.045)):
            face(mat,[(x,-z,lo),(nx,-nz,lo),(nx,-nz,hi),(x,-z,hi)],1.4,(nz-z,nx-x,0))
    # Continuous dressed-stone apron around all four sides, with joints in the same tone.
    floor_quad('ilha_paving',-15.3,8.15,30.6,1.4,.07,1.4)
    floor_quad('ilha_paving',-15.1,-9.1,1.85,17.25,.04,1.4)
    floor_quad('ilha_paving',-13.25,-9.1,28.35,1.35,.04,1.4)
    floor_quad('ilha_paving',13.0,-9.1,2.1,17.25,.04,1.4)
    for x in (-15.35,15.15): box('ilha_trim',x,-9.1,.16,18.5,-.045,.08)
    box('ilha_trim',-15.1,-9.45,30.2,.16,-.045,.08)

def bollard(x,z,h=.07):
    cyl('ilha_iron',x,z,.15,h,h+.06,8)
    cyl('ilha_iron',x,z,.08,h+.06,h+.27,6)
    box('ilha_iron',x-.19,z-.045,.38,.09,h+.21,h+.27)

def lantern(x,z,h=.07):
    cyl('ilha_stone',x,z,.11,h,h+.15,6)
    cyl('ilha_iron',x,z,.035,h+.15,h+1.5,6)
    box('ilha_lamp',x-.065,z-.065,.13,.13,h+1.48,h+1.72)
    box('ilha_iron',x-.09,z-.09,.18,.18,h+1.45,h+1.49)
    spire(x,z,.13,h+1.72,h+1.86,4)

def quays():
    # Service dock: thick planking, pile caps, cleats and a gangway to the buffet boat.
    box('wood',-15.1,9.55,7.7,1.05,-.2,.0,1)
    for x in (-14.85,-12.8,-10.7,-8.0):
        cyl('ilha_iron',x,10.48,.075,-2.0,.12,6)
        bollard(x,9.85,0)
    for k in range(4): box('ilha_iron',-14.6+k*1.8,9.58,.08,1.0,-.29,-.21)
    # Main exit landing keeps its original position and width.
    for k in range(4): box('ilha_stone',15.1+k*.3,4.6,.3,1.4,-.35-k*.18,-.14-k*.18)
    box('wood',16.3,2.0,2.0,6.0,-.94,-.76,1)
    for z in (2.15,4.1,6.0,7.85):
        box('ilha_iron',16.22,z,2.16,.13,-1.1,-.95)
        for x in (16.4,18.2): cyl('ilha_iron',x,z,.075,-2.3,-.42,6)
    for z in (2.35,7.6): bollard(17.6,z,-.76)
    # Ropes and fenders distinguish the vacant mooring from a floating timber rectangle.
    for z in (3.0,5.5,7.0):
        guardiao.strut('ilha_iron',(18.2,z,-.5),(18.4,z,-1.03),.035)
        cyl('ilha_wet',18.4,z,.12,-1.13,-.9,8)
    for z0,z1 in ((2.15,4.1),(6.0,7.85)):
        guardiao.strut('ilha_iron',(18.2,z0,-.42),(18.2,z1,-.42),.025)
    for x,z in ((-14.6,8.6),(-8.2,8.6),(4.8,8.6),(13.7,-5),(13.7,1.8),(14.6,7.4)):
        lantern(x,z)
    # Low contrast, tapered wake, broken into short segments instead of white slabs.
    for branch in (-1,1):
        for k in range(8):
            x=19.2+k*1.4; z=5.4-k*.26+branch*(.18+k*.16)
            floor_quad('ilha_reflection',x,z,.6+k*.05,.025,-1.191)

def service_boat():
    cx,cz=-11.1,11.85
    ring=[(-2.5,-.55),(-1.9,-.8),(1.65,-.8),(2.55,0),(1.65,.8),(-1.9,.8),(-2.5,.55)]
    for i,(dx,dz) in enumerate(ring):
        ex,ez=ring[(i+1)%len(ring)]
        face('ilha_hull',[(cx+dx*.83,-cz-dz*.8,-1.1),(cx+ex*.83,-cz-ez*.8,-1.1),
            (cx+ex,-cz-ez,-.1),(cx+dx,-cz-dz,-.1)],1,(ez-dz,ex-dx,0))
    face('ilha_boat',[(cx+x,-cz-z,-.1) for x,z in ring],1,(0,0,1))
    box('ilha_boat',cx-1.9,cz-.6,1.55,1.2,-.1,.83)
    box('ilha_trim',cx-2.0,cz-.7,1.75,1.4,.83,.94)
    for z in (cz-.607,cz+.607):
        face('ilha_glass',[(cx-1.72,-z,.25),(cx-.55,-z,.25),
            (cx-.55,-z,.7),(cx-1.72,-z,.7)],1,(0,-1 if z>cz else 1,0))
    for i in range(4):
        box('crate',cx-.1+(i%2)*.55,cz-.45+(i//2)*.55,.45,.45,-.08,.3,.5)
    for x in (cx-2.1,cx+1.45):
        guardiao.strut('ilha_iron',(x,10.48,.05),(x,cz-.72,-.05),.025)
    # The service access lies outside the floor; it cannot obstruct the playable gate.
    face('wood',[(-12.8,-10.45,.02),(-12.2,-10.45,.02),(-12.2,-11.55,-.08),(-12.8,-11.55,-.08)],.5,(0,0,1))
    cyl('ilha_iron',cx-1.3,cz,.025,.94,1.3,4)
    box('empire_green',cx-1.28,cz,.35,.025,1.08,1.28)

def bridge_and_warehouse():
    # A separate stone quay and a proper long warehouse on Ilha das Cobras.
    box('ilha_stone',-34,-20,17,11,-1.65,-.06,1.4)
    box('ilha_warehouse',-33,-19,14,7,-.06,2.0,1.4)
    for z in (-19.2,-11.8):
        face('ilha_roof',[(-33.2,-z,2.0),(-18.8,-z,2.0),
            (-18.8,15.5,3.0),(-33.2,15.5,3.0)],1.4,(0,0,1))
    for x in (-31.5,-28.5,-25.5,-22.5,-20): pointed_window(x,-11.985,.35,.7,1.05)
    for x in (-32,-24,-18): lantern(x,-10.0,-.06)
    # An L-shaped bridge actually reaches both quays and has visible beams and piers.
    box('ilha_stone',-14.6,-16.9,1.45,7.1,-.2,.02)
    box('ilha_stone',-18,-16.9,3.4,1.45,-.2,.02)
    for x in (-14.55,-13.2):
        for z in (-16.3,-13.4,-10.3):
            box('ilha_iron',x,z,.05,.05,.02,.92)
            cyl('ilha_stone',x,z,.12,-2.0,-.22,6)
        guardiao.strut('ilha_iron',(x,-16.85,.92),(x,-9.8,.92),.035)
        guardiao.strut('ilha_iron',(x,-16.85,.5),(x,-9.8,.5),.025)
    for x in (-18,-16.3):
        for z in (-16.85,-15.5): box('ilha_iron',x,z,.05,.05,.02,.92)
    for z in (-16.85,-15.5): guardiao.strut('ilha_iron',(-18,z,.92),(-14.6,z,.92),.035)
    for z in (-15.0,-11.0): lantern(-14.45,z,.02)

def distant_bay():
    # The far shore and bridge use a compressed scenic scale so the complete picture
    # fits the fixed game camera. They are separated from the palace by open water.
    box('ilha_far',-3,-18.0,63,.65,-1.3,-1.0)
    for k in range(38):
        x=-2+k*1.5; h=.35+(k%5)*.13
        box('ilha_far',x,-18.2-(k%3)*.12,.65+(k%3)*.2,.55,-1.0,-1.0+h)
        if k%2==0:
            box('ilha_window',x+.12,-17.635,.08,.015,-.8,-.7)
            for j in range(3): floor_quad('ilha_reflection',x+.1,-17.35+j*.28,.06,.11,-1.193)
    # A broad central span distinguishes the Rio–Niterói bridge from a chain of boxes.
    for k in range(13):
        x=4+k*2.8; z=-15.9-k*.025
        h=.25+.5*max(0,1-abs(k-4)/3)
        nh=.25+.5*max(0,1-abs(k+1-4)/3)
        face('ilha_stone',[(x,-z,h),(x+2.8,-z+.025,nh),
            (x+2.8,-z-.3+.025,nh),(x,-z-.3,h)],1,(0,0,1))
        guardiao.strut('ilha_stone',(x,z,-1.2),(x,z,h-.03),.12)
        guardiao.strut('ilha_iron',(x,z,h+.08),(x+2.8,z-.025,nh+.08),.035)
        if k%2==0: box('ilha_lamp',x-.035,z,.07,.07,h+.12,h+.2)

def build_outside():
    make_exterior_palette()
    floor_quad('ilha_water',-65,-60,130,110,-1.2,3)
    island_base()
    bridge_and_warehouse()
    distant_bay()
    palace_exterior()
    quays()
    service_boat()
    for k in range(32):
        x=20+(k%6)*3.3; z=-10+(k//6)*3.6+math.sin(k)*.4
        floor_quad('ilha_reflection',x,z,.28+(k%3)*.23,.022,-1.192)

# ---------------------------------------------------------------- the plan
ROOMS8=[('cozinha',-12.8,-8.4,3.0,7.7),('copa',-12.8,-8.4,-2.0,2.6),('cerimonial',-12.8,-8.4,-7.3,-2.4),('baile',-8.0,5.6,-7.3,2.6),
    ('chapelaria',-8.0,-3.4,3.0,7.7),('torreao',-3.0,2.2,3.0,7.7),('sacada',6.0,12.55,-7.3,-2.8),('antessala',6.0,12.55,-2.4,2.6),
    ('varanda',2.6,12.55,3.0,7.7)]
SKINS8={'cozinha':('white_tile',1.3,False),'copa':('white_tile',1.0,False),'cerimonial':('wood',1.2,True),'baile':('palace_green',1.4,False),
    'chapelaria':('wood',1.0,True),'torreao':('stonewall',1.4,False),'sacada':('stonewall',1.4,False),'antessala':('palace_green',1.2,True),
    'varanda':('stonewall',1.4,False),'outside':('stonewall',1.4,False)}
DOORS8=[(-11.4,7.7,1.4,.45),(-12.4,2.6,1.4,.4),(-8.4,5.4,.4,1.4),(-8.4,-.4,.4,1.6),(-11.4,-2.4,1.4,.4),(-8.4,-5.6,.4,1.4),
    (-6.6,2.6,1.4,.4),(-3.4,4.6,.4,1.4),(-1.6,2.6,2.4,.4),(2.2,4.6,.4,1.4),(5.6,-.6,.4,1.6),(5.6,-5.2,.4,1.6),
    (9.4,-2.8,1.4,.4),(8.0,2.6,1.4,.4),(12.55,4.6,.45,1.4)]

# ---------------------------------------------------------------- props
def build_orchestra(x,z,w,d):
    """The orchestra on its dais against the back wall: a grand piano, a harp, chairs and stands."""
    top=.45
    box('wood',x,z,w,d,0,top,.6)
    box('brass',x-.01,z+d-.04,w+.02,.04,top-.08,top-.04)
    # Grand piano, lid up, at stage left.
    box('black',x+.2,z+.15,1.3,.75,top+.6,top+.75); box('black',x+.2,z+.15,1.0,.75,top+.75,top+.78)
    obox('black',x+.75,z+.4,1.1,.04,top+.78,top+1.2,0)
    for lx,lz in ((x+.3,z+.25),(x+1.35,z+.25),(x+.3,z+.8)): box('black',lx,lz,.06,.06,top,top+.6)
    box('ivory',x+.25,z+.88,.9,.08,top+.7,top+.72)
    # Harp at stage right, gilded.
    cyl('gold',x+w-.5,z+.5,.08,top,top+.15,6)
    obox('gold',x+w-.5,z+.45,.06,.06,top+.15,top+1.3,0); obox('gold',x+w-.25,z+.45,.3,.05,top+1.25,top+1.32,0)
    for k in range(4): box('ivory',x+w-.48+k*.06,z+.44,.005,.01,top+.2,top+1.2-k*.05)
    # Strings: chairs and music stands in a curve.
    for k in range(4):
        cx=x+1.8+k*.55; cz=z+d-.6-abs(k-1.5)*.12
        kit.chair(cx,cz,-math.pi/2,'velvet')
        cyl('iron',cx,cz-.4,.012,top,top+1.0,4); obox('iron',cx,cz-.4,.36,.03,top+.98,top+1.18,0)

def build_coatrack(x,z,w,d):
    """Cloakroom rail: tailcoats and capes in dark cloth, top hats on the shelf above."""
    for px in (x+.08,x+w-.08): cyl('brass',px,z+d/2,.025,0,1.35,4)
    box('brass',x+.05,z+d/2-.015,w-.1,.03,1.32,1.35)
    n=int((w-.3)/.2)
    for i in range(n):
        hx=x+.18+i*.2
        box(['black','dark','velvet','black'][i%4],hx,z+.08,.1,d-.16,.45+(.12 if i%3==0 else 0),1.29)
    for i in range(n//2):
        hx=x+.25+i*.4
        cyl('black',hx,z+d/2,.09,1.36,1.38,8); cyl('black',hx,z+d/2,.06,1.38,1.52,8)

def build_bust_plinth(x,z,w,d):
    """A marble plinth with a bust of D. Pedro II."""
    box('marble',x,z,w,d,0,1.0)
    cx,cz=x+w/2,z+d/2
    cyl('plaster_bust',cx,cz,.14,1.0,1.12,6); cyl('plaster_bust',cx,cz,.09,1.12,1.3,6)
    cyl('ogive',cx,cz,.1,1.2,1.3,6,r1=.06)

def build_counter8(x,z,w,d):
    """Service counter: white lacquer, marble top, trays of flutes."""
    box('white',x,z,w,d,0,.95,.6)
    box('marble',x-.03,z-.03,w+.06,d+.06,.95,1.0)
    along=w>=d; length=w if along else d
    for k in range(int(length/.45)):
        t=.25+k*.45
        px,pz=(x+t,z+d/2) if along else (x+w/2,z+t)
        cyl('chrome',px,pz,.16,1.0,1.02,8)
        for j in range(3): lagoa.flute(px+math.cos(j*2.1)*.07,pz+math.sin(j*2.1)*.07,1.02)

def build_lectern8(x,z,w,d):
    """The balcony lectern: the imperial crest under ORDEM NA CASA, the speech on it."""
    box('wood',x+.1,z+.05,w-.2,d-.1,0,1.1,.6)
    obox('wood',x+w/2,z+d/2,w,d+.08,1.1,1.16,0)
    box('empire_green',x+.2,z+d-.04,w-.4,.01,.6,1.0)
    cyl('gold',x+w/2,z+d-.03,.1,.84,.86,6)
    text('gold','ORDEM NA CASA',x+w/2,z+d-.025,.68,.05)
    obox('white',x+w/2,z+d/2,.3,.22,1.16,1.17,.1)
    cyl('black',x+w-.2,z+.2,.01,1.16,1.42,4); cyl('black',x+w-.2,z+.24,.025,1.4,1.46,5)

def build_pillar8(x,z,w,d):
    """Slim cast iron column painted cream, a gilt capital, cut at the wall height."""
    cx,cz=x+w/2,z+d/2
    cyl('cantaria',cx,cz,.2,0,.2,8,phase=math.pi/8)
    cyl('ogive',cx,cz,.11,.2,1.4,8,phase=math.pi/8)
    cyl('gold',cx,cz,.16,1.25,1.35,8,r1=.11,phase=math.pi/8)
    cyl('cap',cx,cz,.125,1.4,1.43,8,phase=math.pi/8)

# ---------------------------------------------------------------- inside
def lancet(cx,z,h0,h1,w):
    """A pointed-arch window on the back wall: cream frame, glowing amber glass."""
    pts=[]
    for i in range(7):
        a=math.pi*i/6
        pts.append((cx+math.cos(a)*w/2,-(z+.03),h1-w/2+math.sin(a)*w*.75))
    face('ogive',[(cx-w/2-.06,-(z+.02),h0-.06),(cx+w/2+.06,-(z+.02),h0-.06)]+[(px+(.06 if px>cx else -.06),y,hh+.06) for px,y,hh in pts],1,(0,1,0))
    face('stained',[(cx-w/2,-(z+.03),h0),(cx+w/2,-(z+.03),h0)]+pts,1,(0,1,0))
    box('cantaria',cx-.015,z+.035,.03,.01,h0,h1)

def decorate_inside():
    back=-7.29
    # The ballroom: three lancet windows and the 1889 monogram between them.
    for cx in (-6.0,-1.2,3.6): lancet(cx,back,1.5,2.45,1.0)
    text('gold','1889',1.2,back+.04,2.1,.18)
    # Chandeliers: gilt rings with bulbs, well above the cut.
    for cx,cz in ((-4.0,-2.6),(2.6,-2.6),(9.2,-.4)):
        for k in range(8):
            a=k*math.tau/8
            box('gold',cx+math.cos(a)*.5-.04,cz+math.sin(a)*.5-.04,.08,.08,2.7,2.74)
            cyl('bulb',cx+math.cos(a)*.5,cz+math.sin(a)*.5,.035,2.74,2.82,4)
        cyl('gold',cx,cz,.03,2.74,3.2,4)
    # The balcony: Castelar's banner and two flags.
    box('empire_green',6.6,back,5.4,.03,1.6,2.3)
    text('gold','CASTELAR — ORDEM NA CASA',9.3,back+.04,1.85,.13)
    for fx in (6.4,12.2):
        cyl('gold',fx,back+.25,.015,0,2.2,4)
        box('empire_green',fx+.02,back+.24,.45,.02,1.6,2.15); box('yellow_paint',fx+.12,back+.235,.25,.01,1.75,2.0)
    # The ceremonial room: the guest list on the desk, a portrait of the emperor.
    box('wood',-11.6,back,.8,.03,1.5,2.3); box('plaster_bust',-11.5,back+.035,.6,.005,1.6,2.2)
    # The kitchen: trays and stacked flutes on the prep table.
    for k in range(3): cyl('chrome',-9.9+k*.4,4.7,.15,1.15,1.17,8)
    # The tower hall: the clock face on the stair's wall.
    cyl('ogive',-.4,7.69,.45,1.0,1.02,12)

def build_level8():
    data=st.load('level_8.json'); solids=data['solids']
    build_outside()
    floor_quad('cimento',-12.8,-2.0,4.4,9.7,.04,1.6)
    floor_quad('tacos',-12.8,-7.3,4.4,4.9,.04,1.6)
    floor_quad('parquet',-8.0,-7.3,13.6,9.9,.04,1.6)
    floor_quad('granilite',-8.0,3.0,10.2,4.7,.04,1.2)
    floor_quad('pedra',6.0,-7.3,6.55,4.5,.04,1.4)
    floor_quad('parquet',6.0,-2.4,6.55,5.0,.04,1.6)
    floor_quad('pedra',2.6,3.0,9.95,4.7,.04,1.4)
    for x,z,w,d in DOORS8: floor_quad('granito',x,z,w,d,.05,.8)
    walls=kit.wall_pieces(solids)
    for x,z,w,d,h in walls: lav.build_wall(x,z,w,d,h,walls,ROOMS8,SKINS8)
    for i,s in enumerate(solids):
        x,z,w,d=s['r']; kind=s['type']
        if kind=='wall': continue
        if kind=='crate': st.build_crate(x,z,w,d,s['h'])
        else:
            {'stove':lagoa.build_stove7,'prep':kit.build_prep,'counter':build_counter8,'cocktail':lagoa.build_cocktail,
             'desk':lav.build_desk,'shelves':st.build_shelves,'plant':guardiao.build_plant,'stage':build_orchestra,
             'pillar':build_pillar8,'rack':build_coatrack,'stairs':st.build_stairs,'plinth':build_bust_plinth,
             'lectern':build_lectern8,'sofa':lambda x,z,w,d: lav.build_sofa(x,z,w,d,'velvet'),
             'balustrade':st.build_balustrade}[kind](x,z,w,d)
    decorate_inside()

if __name__=='__main__':
    with kit.workspace('Ilha') as scene:
        make_palette()
        build_level8()
        triangles=kit.assemble(scene)
        kit.export_glb(os.path.join(ROOT,'assets/environment/ilha.glb'))
        bpy.data.libraries.write(os.path.join(ROOT,'tools/source/ilha.blend'),{scene},fake_user=True,compress=True)
        print('ILHA_READY',len(scene.objects),'meshes',triangles,'triangles',len(kit.images),'textures')
