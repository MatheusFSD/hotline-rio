"""Celeste's orders as objects, for the dark-web shop on the room's computer (scripts/room.gd).

One low-poly PSX model per order, built with the same kit as every night (build_environment.py):
flat faces, small nearest-sampled textures. Each goes to assets/shop/<order id>.glb, standing
upright with its base at the origin; the room spins it on a turntable.
    blender -b --factory-startup --python "godot 3d/tools/build_shop.py"
"""
import bpy, os, math, importlib.util

HERE=os.path.dirname(os.path.abspath(__file__))
spec=importlib.util.spec_from_file_location('lapa_kit',os.path.join(HERE,'build_environment.py'))
kit=importlib.util.module_from_spec(spec); spec.loader.exec_module(kit)
C,mix,mul,grain,hsh,vnoise=kit.C,kit.mix,kit.mul,kit.grain,kit.hsh,kit.vnoise
box,cyl,face=kit.box,kit.cyl,kit.face
OUT=os.path.join(kit.ROOT,'assets','shop')

# ---------------------------------------------------------------- textures
def t_blued(x,y):
    """Black-oxide steel, a little worn along the edges."""
    c=mix(C('23272b'),C('3a4046'),vnoise(x,y*3,4,4,21)*.7)
    if x in (0,15): c=mul(c,1.35)
    return grain(c,x,y,.06,22)

def t_tread(x,y):
    c=C('1e1d1c') if (y//2)%2 else C('2c2a28')
    if x in (0,15): c=C('d8d2c4')     # the white midsole line along the edge
    return grain(c,x,y,.05,23)

def t_canvas(base):
    def fn(x,y):
        c=C(base)
        if (x+y)%2: c=mul(c,.9)
        return grain(c,x,y,.06,24)
    return fn

def t_wrap(x,y):
    """The katana grip: black cord crossing over white ray skin in diamonds."""
    tx,ty=x%8,y%8
    c=C('ece6d6') if abs(tx-4)+abs(ty-4)<3 else C('141312')
    return grain(c,x,y,.05,25)

def t_lacquer(x,y):
    return grain(mix(C('1c1514'),C('3a1c18'),vnoise(x,y*6,4,4,26)*.6),x,y,.04,27)

def materials():
    kit.material('blued',image=kit.texture('blued',16,16,t_blued))
    kit.material('brass','c9a24a'); kit.material('copper','b06a3a')
    kit.material('polymer','2a2a2a'); kit.material('orange','d9702a')
    kit.material('hole','0a0a0a')
    kit.material('tread',image=kit.texture('tread',16,16,t_tread))
    kit.material('red_canvas',image=kit.texture('red_canvas',16,16,t_canvas('b0312b')))
    kit.material('white','e8e2d4'); kit.material('lace','f2eee4')
    kit.material('olive',image=kit.texture('olive',16,16,t_canvas('5d6436')))
    kit.material('olive_dark',image=kit.texture('olive_dark',16,16,t_canvas('474d29')))
    kit.material('lacquer',image=kit.texture('lacquer',16,16,t_lacquer))
    kit.material('wrap',image=kit.texture('wrap',16,16,t_wrap))
    kit.material('cord','6b1f3a'); kit.material('iron','34322f'); kit.material('strap','5a3a22')
    kit.material('steel','a6aaa8'); kit.material('can','2d3033')

# ---------------------------------------------------------------- the orders
def extended_mag():
    """A pistol magazine with its orange extension and a round on top."""
    box('blued',-.016,-.035,.032,.07,0,.18,.1)
    box('orange',-.019,-.04,.038,.08,-.06,0,.1)
    box('polymer',-.021,-.043,.042,.086,-.072,-.06,.1)
    for h in (.04,.08,.12): box('hole',-.004,.035,.008,.002,h,h+.012)
    box('brass',-.006,-.03,.012,.042,.18,.193)
    box('copper',-.005,-.042,.01,.012,.181,.192)

def rubber_soles():
    """A sneaker: a thick ribbed rubber sole under a red canvas upper with white laces."""
    for i in range(9):
        z=-.135+i*.03
        t=i/8                                  # 0 at the toe, 1 at the heel
        w=.07+.025*math.sin(math.pi*min(1,.25+t*.9))
        sole=.022+.014*t
        box('tread',-w/2,z,w,.03,0,sole,.1)
        top=sole+.025+.07*max(0,t-.25)**.8     # low over the toes, rising to the ankle
        box('red_canvas',-w/2+.006,z,w-.012,.03,sole,top,.1)
    box('white',-.04,-.14,.08,.03,.022,.04)   # toe cap
    for i in range(4): box('lace',-.026,-.03+i*.024,.052,.006,.0,.0)  # placeholder, replaced below
    kit.geo.pop('lace',None)
    for i in range(4):
        z=-.035+i*.022
        h=.022+.014*((z+.135)/.24)+.025+.07*max(0,(z+.135)/.24-.25)**.8
        box('lace',-.024,z,.048,.007,h,h+.006)

def back_sheath():
    """The katana in a black lacquer scabbard, its grip out, with a leather strap across."""
    box('brass',-.02,-.015,.04,.03,0,.03)                 # the tip cap
    box('lacquer',-.018,-.013,.036,.026,.03,.6,.2)
    box('brass',-.02,-.015,.04,.03,.6,.62)                # the mouth
    box('cord',-.02,-.015,.04,.03,.5,.52)
    cyl('iron',0,0,.042,.62,.634,8)                       # guard
    box('wrap',-.016,-.012,.032,.024,.634,.86,.08)        # grip
    box('iron',-.018,-.014,.036,.028,.86,.874)            # pommel
    for side in (-.0135,.0135):                           # the strap, both faces
        y=-side
        face('strap',[(-.1,y,.21),(.1,y,.37),(.1,y,.405),(-.1,y,.245)],.1,(0,-1 if side<0 else 1,0))
    box('steel',-.022,-.016,.044,.032,.3,.33)             # its buckle

def suppressor():
    """A suppressor: a matte can with two bands, the bright thread and the bore at the front."""
    cyl('steel',0,0,.011,-.026,0,8)
    cyl('can',0,0,.019,0,.17,8)
    for h in (.028,.14): cyl('iron',0,0,.0205,h,h+.008,8)
    cyl('steel',0,0,.0195,.17,.177,8)
    cyl('hole',0,0,.006,.177,.1775,6)

def mag_pouch():
    """An olive canvas pouch on a belt loop, two magazines standing in it."""
    box('olive',-.05,-.022,.1,.044,0,.11,.1)
    for h in (.025,.055): box('olive_dark',-.05,.0225,.1,.004,h,h+.012)
    box('olive_dark',-.03,-.032,.06,.012,.02,.12)          # the belt loop behind
    for x in (-.036,.006):
        box('blued',x,-.017,.03,.034,.08,.155,.1)
        box('brass',x+.009,-.012,.012,.024,.155,.164)
    box('polymer',-.052,-.024,.104,.048,-.006,0)

ITEMS={'extended_mag':extended_mag,'rubber_soles':rubber_soles,'back_sheath':back_sheath,
       'suppressor':suppressor,'mag_pouch':mag_pouch}

if __name__=='__main__':
    for name,build in ITEMS.items():
        with kit.workspace('Shop_'+name) as scene:
            materials()
            build()
            triangles=kit.assemble(scene)
            kit.export_glb(os.path.join(OUT,name+'.glb'))
            print('SHOP_ITEM',name,triangles,'triangles')
    print('SHOP_READY')
