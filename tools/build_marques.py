"""Praça Mauá, night twelve, generated in Blender through the installed MCP bridge.

Three scenes, one per stage of the Síndico (assets/level_12a/12b/12c.json,
docs/planejado/fase10-12.md), on the floors of the fictional Edifício Marquês facing the bay:
- marques_comicio.glb: the rally hall. A dark stage with ORDEM NA CASA screens on the back wall,
  the lectern, stacked speakers, crowd barriers, cameras, and the audience floor; the elevator
  door at the back right is where his flame runs.
- marques_apuracao.glb: the vote-count room. Rows of desks with monitors and the tally screens,
  seated aides (drawn in Godot as shells), the open elevator shaft at the back left.
- marques_heliponto.glb: the helipad on the roof. A concrete slab with the painted H and its
  circle, four amber landing lights, the machine room, and the bay at night all round.

Same kit as every night (build_telerio.py → build_lagoa.py → …). Collision comes from the level
files.
    blender -b --factory-startup --python "godot 3d/tools/build_marques.py"
"""
import bpy, os, math, importlib.util

HERE=os.path.dirname(os.path.abspath(__file__))
spec=importlib.util.spec_from_file_location('telerio_kit',os.path.join(HERE,'build_telerio.py'))
telerio=importlib.util.module_from_spec(spec); spec.loader.exec_module(telerio)
lagoa=telerio.lagoa; guardiao=lagoa.guardiao; caju=lagoa.caju; st=lagoa.st; lav=lagoa.lav; kit=lagoa.kit
ROOT=kit.ROOT
box,obox,cyl,face=kit.box,kit.obox,kit.cyl,kit.face
wall_quad,floor_quad,decal,text=kit.wall_quad,kit.floor_quad,kit.decal,kit.text

def make_palette():
    telerio.make_palette()
    kit.material('stage_floor',image=kit.texture('stage_floor',32,32,kit.cement('1e1f22','1a1b1e',.02,25)))
    kit.material('helipad',image=kit.texture('helipad',32,32,kit.cement('6e6f6c','676865',.03,27)))
    for name,color in {'campaign_green':'1f5a3a','gold_leaf':'c9a13b','steel':'b8bec2','void':'05070a'}.items(): kit.material(name,color)

def rooms(): return [('inside',-12.8,12.55,-7.3,7.7)]

# ---------------------------------------------------------------- props
def build_speaker(x,z,w,d):
    """Stacked PA cabinets, black, grilles to the room."""
    for k in range(3):
        box('black',x,z,w,d,k*.46,k*.46+.44,.5)
        box('dark',x+.15,z+d-.01,w-.3,.02,k*.46+.08,k*.46+.36)   # the grille

def build_lectern12(x,z,w,d):
    """The Síndico's lectern: dark wood, the ORDEM NA CASA crest in gold, two microphones."""
    box('wood',x+.1,z+.05,w-.2,d-.1,0,1.1,.6)
    obox('wood',x+w/2,z+d/2,w,d+.08,1.1,1.16,0)
    box('campaign_green',x+.2,z+d-.04,w-.4,.01,.55,1.0)
    text('gold_leaf','ORDEM NA CASA',x+w/2,z+d-.025,.75,.06)
    for mx in (x+.3,x+w-.3): cyl('black',mx,z+.2,.01,1.16,1.45,4); cyl('black',mx,z+.24,.025,1.43,1.5,5)

def build_counter12(x,z,w,d):
    box('white',x,z,w,d,0,.95,.6); box('marble',x-.03,z-.03,w+.06,d+.06,.95,1.0)
    along=w>=d
    for k in range(int((w if along else d)/.5)):
        t=.25+k*.5
        lagoa.flute(x+t if along else x+w/2,z+d/2 if along else z+t,1.0)

def build_pillar12(x,z,w,d):
    cx,cz=x+w/2,z+d/2
    box('concrete',x,z,w,d,0,1.4,.8); box('cap',x-.01,z-.01,w+.02,d+.02,1.4,1.43,sides=False)

def build_shaft(x,z,w,d):
    """The open elevator shaft: steel doors slid back, darkness inside, the cables hanging."""
    box('steel',x,z,w,.12,0,1.4)
    floor_quad('void',x+.1,z+.1,w-.2,d-.2,.02,1.0)
    for dx in (x,x+w-.12): box('metal',dx,z,.12,d,0,1.4)
    for k in range(3): cyl('iron',x+w*.3+k*w*.2,z+d*.5,.015,.02,2.8,4)
    box('yellow_paint',x,z+d-.05,w,.05,0,.06)

def build_counter_desk(x,z,w,d):
    """A count desk: laminate top, two monitors with the running tally, a phone."""
    lav.build_desk(x,z,w,d)
    for mx in (x+.3,x+w-.8):
        box('black',mx,z+.15,.5,.05,.8,1.15); box('tv_glow',mx+.03,z+.201,.44,.005,.83,1.12)

# ---------------------------------------------------------------- the three floors
def frame_outside(floor_mat):
    """What every stage sees around the floor plate: the building's ledge and the dark bay far below
    (Niterói's lights would sit behind the HUD from this camera, so they are left out)."""
    floor_quad(floor_mat,-15.1,-9.1,1.85,17.25,.04,1.4)
    floor_quad(floor_mat,-13.25,-9.1,28.35,1.35,.04,1.4)
    floor_quad(floor_mat,13.0,-9.1,2.1,17.25,.04,1.4)
    floor_quad(floor_mat,-15.3,8.15,30.6,2.45,.07,1.4)
    floor_quad('lagoon',-60,-60,120,45,-30,4.0)
    kit.sobrado(-27,-15.6,8.0,-9.0,6.0,'facade_yellow',doors=False,side=True)

def floor_plan(data,floor_mat,skin):
    solids=data['solids']
    floor_quad(floor_mat,-12.8,-7.3,25.35,15.0,.04,1.4)
    walls=kit.wall_pieces(solids)
    skins={'inside':skin,'outside':('concrete',1.4,False)}
    for x,z,w,d,h in walls: lav.build_wall(x,z,w,d,h,walls,rooms(),skins)
    return solids

def build_comicio():
    data=st.load('level_12a.json')
    frame_outside('pedra')
    # The square below the front: sodium posts on the Praça Mauá.
    for k in range(7): cyl('iron',-12+k*4.0,9.6,.05,.07,2.6,4); box('sodium',-12.3+k*4.0,9.45,.6,.3,2.5,2.7)
    solids=floor_plan(data,'stage_floor',('acoustic',1.4,False))
    box('wood',-8.0,-7.3,16.0,3.5,0,.35,.6)   # the stage platform under the lectern and speakers
    floor_quad('pedra',8.4,-9.1,1.8,1.4,.05,1.0)   # the way to the elevator
    for s in solids:
        x,z,w,d=s['r']; kind=s['type']
        if kind=='wall': continue
        if kind=='crate': st.build_crate(x,z,w,d,s['h'])
        else:
            {'lectern':build_lectern12,'speaker':build_speaker,'railing':st.build_railing,'pillar':build_pillar12,
             'studiocam':telerio.build_studiocam,'counter':build_counter12}[kind](x,z,w,d)
    back=-7.29
    for k in range(3):
        sx=-7.6+k*5.4
        box('black',sx,back,4.6,.04,1.5,2.45); box('campaign_green',sx+.1,back+.045,4.4,.005,1.6,2.35)
        text('gold_leaf','ORDEM NA CASA' if k!=1 else 'CASTELAR',sx+2.3,back+.06,2.0,.22 if k==1 else .16)
    for fx in (-9.8,9.0): cyl('iron',fx,-7.0,.015,0,2.4,4); box('campaign_green',fx+.02,-7.0,.6,.02,1.7,2.3)
    for k in range(6): box('iron',-7.5+k*3.0,-5.6,.1,.1,2.7,2.76); box('black',-7.5+k*3.0,-5.65,.2,.25,2.45,2.7)
    box('metal',8.5,back,1.6,.03,0,1.4); box('bulb_red',9.1,back+.04,.4,.01,1.45,1.55)   # the elevator doors

def build_apuracao():
    data=st.load('level_12b.json')
    frame_outside('concrete')
    solids=floor_plan(data,'carpete',('cream',1.2,True))
    floor_quad('concrete',9.2,-9.1,2.0,1.4,.05,1.0)
    for s in solids:
        x,z,w,d=s['r']; kind=s['type']
        if kind=='wall': continue
        {'shaft':build_shaft,'counter':build_counter12,'desk':build_counter_desk,'pillar':build_pillar12,
         'studiocam':telerio.build_studiocam}[kind](x,z,w,d)
    back=-7.29
    box('black',-7.6,back,15.6,.04,1.4,2.45)
    for k in range(4):
        box('tv_glow',-7.4+k*3.9,back+.045,3.6,.005,1.5,2.35)
        text('white','%d%%' % (38+k*7),-5.6+k*3.9,back+.06,1.9,.22)
    text('alerta_red','APURAÇÃO  —  ZONA ELEITORAL 01',0.2,back+.06,2.3,.1)

def build_heliponto():
    data=st.load('level_12c.json')
    frame_outside('helipad')
    # The roof's parapet beyond the plate and the Museu do Amanhã's white spine far below.
    for k in range(9): obox('white',16+k*2.0,-20.0+k*.6,1.6,.3,-30,-22.0+math.sin(k*.6)*2.5,.4)
    solids=floor_plan(data,'helipad',('concrete',1.4,False))
    # The painted H and its circle.
    for k in range(16):
        a=k*math.tau/16; b=(k+1)*math.tau/16
        face('yellow_paint',[(math.cos(a)*3.0,-(-.3+math.sin(a)*3.0),.045),(math.cos(b)*3.0,-(-.3+math.sin(b)*3.0),.045),
            (math.cos(b)*2.7,-(-.3+math.sin(b)*2.7),.045),(math.cos(a)*2.7,-(-.3+math.sin(a)*2.7),.045)],1,(0,0,1))
    floor_quad('white',-1.0,-1.6,.35,2.6,.046,1.0); floor_quad('white',.65,-1.6,.35,2.6,.046,1.0); floor_quad('white',-.65,-.45,1.3,.3,.046,1.0)
    for px,pz in data.get('pads',[]):
        cyl('metal',px,pz,.18,0,.12,8); cyl('bulb',px,pz,.12,.12,.2,8)
    for s in solids:
        x,z,w,d=s['r']; kind=s['type']
        if kind=='wall': continue
        {'compressor':caju.build_compressor,'tank':caju.build_tank,'pillar':build_pillar12}[kind](x,z,w,d)
    box('concrete',-12.8,3.8,4.4,3.9,0,1.4,.8)   # the stair head of the service stairs, left behind the wall

STAGES=[('Marques_comicio','marques_comicio.glb',build_comicio),('Marques_apuracao','marques_apuracao.glb',build_apuracao),
    ('Marques_heliponto','marques_heliponto.glb',build_heliponto)]

if __name__=='__main__':
    for scene_name,file_name,build in STAGES:
        with kit.workspace(scene_name) as scene:
            make_palette()
            build()
            triangles=kit.assemble(scene)
            kit.export_glb(os.path.join(ROOT,'assets/environment/'+file_name))
            bpy.data.libraries.write(os.path.join(ROOT,'tools/source/'+file_name.replace('.glb','.blend')),{scene},fake_user=True,compress=True)
            print('MARQUES_READY',file_name,len(scene.objects),'meshes',triangles,'triangles')
