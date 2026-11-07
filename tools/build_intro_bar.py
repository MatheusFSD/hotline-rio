"""The bar the security camera films in the opening newscast, closed again.

The playable bar (build_environment.py) has its walls cut at 1.4 m so the nights can be seen from
above. For the cameras of the news (scripts/intro.gd) this adds what the cut leaves out: the walls
up to a ceiling, lintels over the doors, the ceiling with its fluorescent tubes, a parapet and a
cornice on the street side, a sign over the door and the string of bulbs moved up under it. Same
PSX kit as every night. Writes assets/intro/bar_shell.glb; only the opening loads it.
    blender -b --factory-startup --python "godot 3d/tools/build_intro_bar.py"
"""
import bpy, os, math, importlib.util

HERE=os.path.dirname(os.path.abspath(__file__))
spec=importlib.util.spec_from_file_location('lapa_kit',os.path.join(HERE,'build_environment.py'))
kit=importlib.util.module_from_spec(spec); spec.loader.exec_module(kit)
C,mix,mul,grain,hsh,vnoise=kit.C,kit.mix,kit.mul,kit.grain,kit.hsh,kit.vnoise
box,cyl,face,text=kit.box,kit.cyl,kit.face,kit.text
OUT=os.path.join(kit.ROOT,'assets','intro')

# Level metres throughout: x right, z toward the street, h up. Blender gets (x, -z, h).
def B(x,z,h): return (x,-z,h)

# ---------------------------------------------------------------- textures
def t_ceiling(x,y):
    """The bar's ceiling: old paint, a water stain, the grime of fifty years of cigarettes."""
    c=mul(C('d9cfb6'),.9+.12*vnoise(x,y,6,5,57))
    stain=math.hypot(x-20,y-11)
    if stain<7: c=mix(c,C('a8955f'),.35*(1-stain/7))
    return grain(c,x,y,.04,58)

def materials():
    kit.make_palette()
    kit.material('bar_ceiling',image=kit.texture('bar_ceiling',32,32,t_ceiling))
    kit.material('fixture','e8e6de')
    kit.material('tube_light','f4f8ff',emission='e8f0ff',strength=2.5)

# ---------------------------------------------------------------- the bar, closed
CEIL=2.9
PARAPET=3.35
DOOR_TOP=2.1
# The doorways in the bar's walls (assets/level.json), as (x0, z0, x1, z1) footprints.
DOORS=[(-10.075,7.7,-7.75,8.15),(-9.75,3.2,-7.75,3.6),(3.6,-2.6,4.05,-.35),(3.6,3.4,4.05,4.8),(4.6,2.3,6.4,2.7),(11.55,4.7,12.0,6.75)]

def build_bar_shell():
    walls=kit.wall_pieces(kit.layout['solids'])
    t=.012   # a hair thicker than the level's walls, so their black caps are buried
    for x,z,w,d,h in walls:
        outer=x<=-12.2 or x>=11.5 or z>=7.65 or z<=-7.7
        box('plaster',x-t,z-t,w+2*t,d+2*t,h,PARAPET if outer else CEIL,1.2)
    for x0,z0,x1,z1 in DOORS:
        outer=z0>=7.65 or x0>=11.5
        box('plaster',x0,z0-t,x1-x0,z1-z0+2*t,DOOR_TOP,PARAPET if outer else CEIL,1.2)
        box('wood',x0,z0-t,x1-x0,z1-z0+2*t,DOOR_TOP-.06,DOOR_TOP)
    # Ceiling seen from inside; the roof slab over it.
    x0,z0,x1,z1=-12.25,-7.75,12.0,8.15
    face('bar_ceiling',[B(x0,z0,CEIL),B(x1,z0,CEIL),B(x1,z1,CEIL),B(x0,z1,CEIL)],1.5,(0,0,-1))
    face('concrete',[B(x0,z0,PARAPET-.3),B(x1,z0,PARAPET-.3),B(x1,z1,PARAPET-.3),B(x0,z1,PARAPET-.3)],2.0,(0,0,1))
    # Fluorescent tubes over the counter and the tables.
    for x,z in ((-9.2,-2.6),(-9.2,1.2),(-4.6,-4.6),(-1.0,-4.6),(-4.6,-.4),(-1.0,-.4),(7.8,-2.5)):
        box('fixture',x-.65,z-.08,1.3,.16,CEIL-.06,CEIL)
        box('tube_light',x-.6,z-.03,1.2,.06,CEIL-.09,CEIL-.06)
    # The street side: a cornice, a sign over the door, the string of bulbs hung under it.
    box('cream',-12.3,8.15,24.35,.12,2.62,2.72)
    box('cream',-12.3,8.15,24.35,.16,PARAPET-.08,PARAPET)
    box('green_paint',-10.2,8.15,2.6,.05,2.2,2.55)
    text('cream','BAR DO ARCO',-8.9,8.205,2.29,.19)
    bulbs=['bulb','bulb_red','bulb_green','bulb','bulb_blue']
    for seg,(a,b) in enumerate(((-12.25,-10.3),(-7.6,11.9))):
        n=int((b-a)/.5)
        for i in range(n+1):
            x=a+(b-a)*i/n
            sag=.12*math.sin(math.pi*((x-a)%2.0)/2.0)
            box('black',x-.25,8.24,.5,.015,2.5-sag,2.515-sag)
            cyl(bulbs[(i+seg)%len(bulbs)],x,8.26,.05,2.42-sag,2.5-sag,4)

if __name__=='__main__':
    with kit.workspace('Intro_bar') as scene:
        materials()
        build_bar_shell()
        bar=kit.assemble(scene)
        kit.export_glb(os.path.join(OUT,'bar_shell.glb'))
    print('INTRO_BAR_READY',bar,'triangles')
