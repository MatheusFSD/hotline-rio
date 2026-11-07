"""Cast and sets for the opening newscast, generated in Blender through the installed MCP bridge.

Imports build_environment.py as a kit for its PSX textures, materials and mesh helpers. Runs
in its own headless Blender (see the bottom of this file). Writes assets/intro:
- anchor.glb, witness.glb, cop.glb: PSX people rebound to the UAL rig with talking clips.
- caio.glb: the hero, sitting, getting up and walking, for the room the newscast is watched in.
- studio.glb: the fictional "Alerta Rio" police-news studio, built around the origin.
- street.glb: police car, cones and tape in the bar's level coordinates, for the report.
"""
import bpy, os, math, importlib.util
from mathutils import Vector, Matrix

HERE=os.path.dirname(os.path.abspath(__file__))
spec=importlib.util.spec_from_file_location('lapa_kit',os.path.join(HERE,'build_environment.py'))
kit=importlib.util.module_from_spec(spec); spec.loader.exec_module(kit)
ROOT=kit.ROOT
SOURCE=os.path.join(ROOT,'tools/source')
OUT=os.path.join(ROOT,'assets/intro')
C,mix,mul,grain,hsh,vnoise=kit.C,kit.mix,kit.mul,kit.grain,kit.hsh,kit.vnoise
box,obox,cyl,text,floor_quad=kit.box,kit.obox,kit.cyl,kit.text,kit.floor_quad

# ---------------------------------------------------------------- cast
CAST=[('anchor','Male/Character_29','Character_29',['Idle_Talking_Loop','Walk_Formal_Loop','Spell_Simple_Shoot','Interact','Idle_Loop']),
    ('witness','Female/Character_29_Female','Character_29_Female',['Idle_Talking_Loop','Idle_Loop']),
    ('cop','Male/Character_17_Police','Character_17_Police',['Idle_Loop','Idle_Talking_Loop']),
    # Caio himself, in the shirt he died in, watching the news about himself from his desk chair.
    ('caio','Male/Character_01','Character_01',['Sitting_Idle_Loop','Sitting_Exit','Walk_Loop','Idle_Loop'])]

# Same Mixamo-to-UAL retarget as build_characters.py.
mapping={'Hips':'pelvis','Spine':'spine_01','Spine1':'spine_02','Spine2':'spine_03','Neck':'neck_01','Head':'Head'}
for side,suffix in [('Left','l'),('Right','r')]:
    for old,new in [('Shoulder','clavicle'),('Arm','upperarm'),('ForeArm','lowerarm'),('Hand','hand'),('UpLeg','thigh'),('Leg','calf'),('Foot','foot'),('ToeBase','ball')]:
        mapping[side+old]=new+'_'+suffix
    for i in range(1,4): mapping[side+'HandIndex'+str(i)]=f'index_0{i}_{suffix}'

def frame(head,tail):
    y=(tail-head).normalized()
    ref=Vector((0,-1,0))
    if abs(y.dot(ref))>.92: ref=Vector((0,0,1))
    x=y.cross(ref).normalized()
    z=x.cross(y).normalized()
    m=Matrix((x,y,z)).transposed().to_4x4(); m.translation=head
    return m

def rebind(rig,actions,name,model,texture,clips,scale=.36):
    # `scale` brings the pack's units to the UAL rig's: .36 for the first pack, whose people are
    # 4.4 m tall in their files; the later packs (Characters_psx_02, Extras) are near real size.
    before=set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=os.path.join(SOURCE,'Characters_psx/Models',model+'.fbx'))
    imported=set(bpy.data.objects)-before
    oldrig=next(o for o in imported if o.type=='ARMATURE')
    mesh=next(o for o in imported if o.type=='MESH')
    weights=[[(g.group,g.weight) for g in v.groups] for v in mesh.data.vertices]
    kit.scene.frame_set(1)
    bpy.context.view_layer.update()
    data=bpy.data.meshes.new_from_object(mesh.evaluated_get(bpy.context.evaluated_depsgraph_get()))
    transformed={}
    for group in mesh.vertex_groups:
        short=group.name.replace('mixamorig:','')
        if short not in mapping: continue
        p=oldrig.pose.bones[group.name]
        old=frame(oldrig.matrix_world@p.head,oldrig.matrix_world@p.tail)
        b=rig.data.bones[mapping[short]]
        new=frame(rig.matrix_world@b.head_local,rig.matrix_world@b.tail_local)
        transformed[group.index]=new@Matrix.Scale(scale,4)@old.inverted()
    world=mesh.matrix_world.copy()
    for v in data.vertices:
        original=world@v.co; total=0.; result=Vector()
        for index,weight in weights[v.index]:
            if index in transformed:
                result+=(transformed[index]@original)*weight; total+=weight
        v.co=result/total if total else original*scale
    visual=bpy.data.objects.new(name,data); kit.scene.collection.objects.link(visual)
    visual.vertex_groups.clear()
    for group in mesh.vertex_groups:
        visual.vertex_groups.new(name=mapping.get(group.name.replace('mixamorig:',''),group.name))
    for index,groups in enumerate(weights):
        for group,weight in groups: visual.vertex_groups[group].add([index],weight,'REPLACE')
    visual.parent=rig
    visual.modifiers.new('UAL skin','ARMATURE').object=rig
    for poly in data.polygons: poly.use_smooth=False
    mat=bpy.data.materials.new(name+'_palette'); mat.use_nodes=True
    bsdf=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    bsdf.inputs['Roughness'].default_value=1
    image=bpy.data.images.load(os.path.join(SOURCE,'Characters_psx/Textures',texture+'.png'),check_existing=False)
    image.pack()
    tex=mat.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=image; tex.interpolation='Closest'
    mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
    data.materials.clear(); data.materials.append(mat)
    for o in imported: bpy.data.objects.remove(o,do_unlink=True)
    for t in list(rig.animation_data.nla_tracks): rig.animation_data.nla_tracks.remove(t)
    rig.animation_data.action=None
    for label in clips:
        action=actions[label]
        t=rig.animation_data.nla_tracks.new(); t.name=label
        strip=t.strips.new(label,1,action)
        if hasattr(strip,'action_slot') and len(action.slots): strip.action_slot=action.slots[0]
    bpy.ops.object.select_all(action='DESELECT')
    rig.select_set(True); visual.select_set(True); bpy.context.view_layer.objects.active=rig
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,name+'.glb'),export_format='GLB',use_selection=True,export_animation_mode='NLA_TRACKS',export_skins=True,export_anim_slide_to_zero=True)
    print('CAST',name,len(data.vertices),'vertices',sum(len(p.vertices)-2 for p in data.polygons),'triangles')
    bpy.data.objects.remove(visual,do_unlink=True)

def build_cast():
    before=set(bpy.data.actions)
    bpy.ops.import_scene.gltf(filepath=os.path.join(SOURCE,'UAL1_Standard.glb'))
    rig=next(o for o in kit.scene.objects if o.type=='ARMATURE')
    rig.name='RioRig'
    for o in list(kit.scene.objects):
        if o!=rig: bpy.data.objects.remove(o,do_unlink=True)
    # Names may carry a .001 suffix when the open file already has actions with the same name.
    actions={a.name.split('.')[0]:a for a in set(bpy.data.actions)-before}
    rig.animation_data.action=None
    for t in rig.animation_data.nla_tracks: t.mute=True
    for p in rig.pose.bones: p.matrix_basis=Matrix.Identity(4)
    bpy.context.view_layer.update()
    for name,model,texture,clips in CAST: rebind(rig,actions,name,model,texture,clips)
    bpy.data.objects.remove(rig,do_unlink=True)

# ---------------------------------------------------------------- studio textures
def t_studio_floor(x,y):
    c=grain(mix(C('101826'),C('0a0f18'),vnoise(x,y,8,4,40)),x,y,.05,41)
    return C('22406a') if x%16==0 or y%16==0 else c

def t_sirene(x,y):
    # Red sunburst with a yellow core: the plantão alarm graphic.
    a=math.atan2(y-24,x-32); d=math.hypot(x-32,(y-24)*1.2)
    c=C('c4161c') if int((a+math.pi)/(math.tau/16))%2 else C('7d0b10')
    if d<9: c=C('ffd21a')
    elif d<11: c=C('1a0a0a')
    if x<1 or y<1 or x>62 or y>46: c=C('1a0a0a')
    return c

def t_skyline(x,y):
    # Night sky over Rio: Corcovado with the statue, Sugarloaf humps and city blocks.
    c=mix(C('3a0a14'),C('d2461c'),y/47)
    ground=40-(int(hsh(x//4,0,42)*6) if x<40 or x>58 else 0)
    corcovado=24+abs(x-16)*1.1
    sugar=min(math.hypot(x-50,y-30)-9,math.hypot(x-60,y-36)-6)
    if y>corcovado or sugar<0 or y>ground: c=C('120608')
    if 15<=x<=17 and 13<=y<=24: c=C('120608')       # Cristo
    if 12<=x<=20 and 16<=y<=17: c=C('120608')
    if y>ground and hsh(x,y,43)>.86: c=C('ffcf6a')   # lit windows
    return c

def t_grade(x,y):
    # Wall of monitors: blue security feeds, one red alert screen.
    tx,ty=x%16,y%16
    if tx<1 or ty<1 or tx>14 or ty>14: return C('050608')
    cell=(x//16)+(y//16)*4
    if cell==6: return C('d81e1e') if (tx+ty)%6 else C('ffd21a')
    n=vnoise(x,y,4,16,44+cell)
    return mix(C('0d2a52'),C('6fb8ff'),n*.8) if (ty%3) else C('0a1c38')

def t_fantasma(x,y):
    # Spectral silhouette on a dark feed, as on the studio's side screen.
    c=C('06101e') if (y%3) else C('0b1a2e')
    head=math.hypot(x-16,y-14)<5
    body=y>19 and abs(x-16)<4+(y-19)*.45 and y<44
    if head or body: c=mix(C('2fc8ff'),C('bff4ff'),hsh(x,y,45)*.5)
    if (head or body) and hsh(x//2,y,46)>.85: c=C('06101e')
    return c

def t_zebrada(x,y):
    return C('f2c616') if ((x+y)//4)%2 else C('141414')

def panel(mat,a,b,h0,h1):
    """Upright quad from level point a to b with the whole image mapped across it."""
    g=kit.geo.setdefault(mat,([],[],[])); base=len(g[0])
    g[0].extend([(a[0],-a[1],h0),(b[0],-b[1],h0),(b[0],-b[1],h1),(a[0],-a[1],h1)])
    g[1].append(tuple(range(base,base+4))); g[2].extend([(0,0),(1,0),(1,1),(0,1)])

def make_intro_palette():
    kit.material('studio_floor',image=kit.texture('studio_floor',32,32,t_studio_floor))
    kit.material('tela_sirene',image=kit.texture('tela_sirene',64,48,t_sirene),glow=2.2)
    kit.material('tela_skyline',image=kit.texture('tela_skyline',64,48,t_skyline),glow=1.8)
    kit.material('tela_grade',image=kit.texture('tela_grade',64,48,t_grade),glow=1.8)
    kit.material('tela_fantasma',image=kit.texture('tela_fantasma',32,48,t_fantasma),glow=2.2)
    kit.material('zebrada',image=kit.texture('zebrada',16,16,t_zebrada))
    kit.material('logo_yellow','ffd21a',emission='ffc400',strength=3)
    kit.material('logo_red','e01c1c',emission='d0101a',strength=2.5)
    kit.material('led_red','ff2a2a',emission='ff1010',strength=4)
    kit.material('led_blue','3a6bff',emission='2050ff',strength=4)
    kit.material('desk_red','a3121a')
    kit.material('gloss_black','0b0c0f')
    kit.material('police_white','e9ecef')
    kit.material('police_blue','1d3f8f')
    kit.material('cone','e2561c')
    kit.material('paper','f1efe6')

# ---------------------------------------------------------------- studio
def build_studio():
    floor_quad('studio_floor',-9,-7,18,13,0,2.0)
    # Curved video wall: seven panels on an arc facing the presenter.
    feeds=['tela_grade','tela_skyline','tela_sirene','tela_sirene','tela_sirene','tela_skyline','tela_grade']
    radius,cz=7.0,2.6
    angles=[math.radians(-36+i*12) for i in range(8)]
    points=[(math.sin(a)*radius,cz-math.cos(a)*radius) for a in angles]
    for i,feed in enumerate(feeds):
        a,b=points[i],points[i+1]
        panel(feed,a,b,.35,3.15)
        mx,mz=(a[0]+b[0])/2,(a[1]+b[1])/2; yaw=math.atan2(b[1]-a[1],b[0]-a[0])
        obox('gloss_black',mx,mz-.04,math.dist(a,b)+.06,.06,3.15,3.3,yaw)
        obox('gloss_black',mx,mz-.04,math.dist(a,b)+.06,.06,0,.35,yaw)
    for a in points:
        obox('gloss_black',a[0],a[1]-.04,.08,.08,0,3.3,0)
    # Program logo across the centre panels.
    # The logo floats a little in front of the arc so its ends clear the curving panels.
    text('logo_yellow','ALERTA RIO',0,-3.95,2.05,.62)
    text('logo_red','PLANTÃO POLICIAL',0,-3.95,1.62,.26)
    # News desk with a red LED strip and the logo on its front.
    dx,dz=1.9,-.9
    box('desk_red',dx-1.25,dz-.4,2.5,.8,0,.95,1)
    box('gloss_black',dx-1.32,dz-.47,2.64,.94,.95,1.0)
    box('led_red',dx-1.25,dz+.4,2.5,.02,.12,.18)
    text('logo_yellow','ALERTA RIO',dx,dz+.43,.45,.26)
    for i,(px,pz,yaw) in enumerate(((dx-.6,dz-.1,.2),(dx-.35,dz+.05,-.1))):
        obox('paper',px,pz,.3,.21,1.0,1.006+i*.004,yaw)
    cyl('white',dx+.7,dz,.05,1.0,1.11,6); cyl('dark',dx+.7,dz,.045,1.1,1.111,6)
    obox('gloss_black',dx+.25,dz-.25,.5,.04,1.0,1.32,0); obox('screen',dx+.25,dz-.23,.46,.01,1.03,1.29,0)
    # Side screen with the ghost silhouette, on a black stand.
    sx,sz=-3.6,-1.6
    panel('tela_fantasma',(sx-.75,sz-.5),(sx+.75,sz+.5),.9,3.2)
    obox('gloss_black',sx,sz-.03,1.9,.06,.8,3.3,math.atan2(1,1.5))
    obox('gloss_black',sx,sz,.12,.12,0,.9,0)
    # Lighting truss with spotlights, a floor fill light and a studio camera.
    for z in (-2.6,1.4):
        box('iron',-6,z-.06,12,.12,4.2,4.32)
        for i in range(6):
            x=-5+i*2
            cyl('iron',x,z,.03,3.9,4.2,4); cyl('gloss_black',x,z,.14,3.6,3.9,6)
            cyl('logo_yellow' if i%2 else 'white',x,z,.1,3.58,3.6,6)
    for px,pz in ((-5.5,1.8),(5.6,1.6)):
        cyl('iron',px,pz,.03,0,1.6,4); obox('gloss_black',px,pz,.4,.3,1.6,1.95,0)
    cx,cz2=4.6,3.4
    cyl('iron',cx,cz2,.4,0,.08,6); cyl('iron',cx,cz2,.06,.08,1.3,4)
    obox('gloss_black',cx,cz2,.35,.6,1.3,1.62,0); obox('iron',cx,cz2-.42,.16,.24,1.38,1.54,0)
    obox('led_red',cx+.1,cz2+.31,.05,.02,1.55,1.58,0)

# ---------------------------------------------------------------- street props for the report
def build_street():
    # Police car parked by the curb with its light bar.
    vx,vz=-12.2,12.45
    box('police_white',vx-2.1,vz-.85,4.2,1.7,.3,.95,.8)
    obox('police_white',vx-.2,vz,2.2,1.55,.95,1.38,0)
    obox('screen',vx-.2,vz,2.0,1.57,1.0,1.33,0)
    obox('police_white',vx-.2,vz,1.7,1.4,1.38,1.46,0)
    box('police_blue',vx-2.1,vz+.84,4.2,.03,.55,.72)
    box('police_blue',vx-2.1,vz-.87,4.2,.03,.55,.72)
    text('police_blue','POLÍCIA',vx-.2,vz+.88,.74,.24)
    obox('led_red',vx-.45,vz,.45,.9,1.46,1.58,0); obox('led_blue',vx+.05,vz,.45,.9,1.46,1.58,0)
    for wx in (-1.35,1.35):
        for wz in (-.8,.8): obox('tire',vx+wx,vz+wz,.62,.2,0,.58,0)
    # Cones and tape closing the bar entrance.
    posts=[(-10.9,8.75),(-9.2,9.1),(-7.4,8.75)]
    for px,pz in posts:
        cyl('cone',px,pz,.16,0,.62,6,r1=.03); cyl('white',px,pz,.105,.3,.4,6,top=False)
        box('cone',px-.2,pz-.2,.4,.4,0,.04)
    for (ax,az),(bx,bz) in zip(posts,posts[1:]):
        mx,mz=(ax+bx)/2,(az+bz)/2
        obox('zebrada',mx,mz,math.dist((ax,az),(bx,bz)),.02,.52,.6,math.atan2(bz-az,bx-ax),.4)

# ---------------------------------------------------------------- export
if __name__=='__main__':
    # Exporting skinned characters from a temporary scene override crashes Blender 5.2's
    # depsgraph, so this script owns a throwaway headless Blender instead:
    #   blender -b --factory-startup --python "godot 3d/tools/build_intro.py"
    if not bpy.app.background:
        raise RuntimeError('Run build_intro.py headless: blender -b --factory-startup --python build_intro.py')
    scene=kit.scene=bpy.context.scene
    for ob in list(scene.objects): bpy.data.objects.remove(ob)
    os.makedirs(OUT,exist_ok=True)
    build_cast()
    kit.make_palette()
    make_intro_palette()
    build_studio()
    studio=kit.assemble(scene)
    kit.export_glb(os.path.join(OUT,'studio.glb'))
    for ob in list(scene.objects): bpy.data.objects.remove(ob)
    build_street()
    street=kit.assemble(scene)
    kit.export_glb(os.path.join(OUT,'street.glb'))
    print('INTRO_READY studio',studio,'triangles; street',street,'triangles')
