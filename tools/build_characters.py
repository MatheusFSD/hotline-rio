"""Run through Blender MCP. Rebind supplied PSX meshes to the UAL skeleton.
The FBX contains a corrective T-pose action; sample its evaluated mesh and
bone frames together before transferring weights. Originals stay intact.
"""
import bpy, os, json
from mathutils import Vector, Matrix
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE=os.path.join(ROOT,'tools/source')
OUT=os.path.join(ROOT,'assets/characters')
os.makedirs(OUT,exist_ok=True)
for o in list(bpy.data.objects): bpy.data.objects.remove(o,do_unlink=True)
for a in list(bpy.data.actions): bpy.data.actions.remove(a)
bpy.ops.import_scene.gltf(filepath=os.path.join(SOURCE,'UAL1_Standard.glb'))
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
rig.name='RioRig'
for o in list(bpy.context.scene.objects):
    if o!=rig: bpy.data.objects.remove(o,do_unlink=True)
rig.animation_data.action=None
for t in rig.animation_data.nla_tracks: t.mute=True
for p in rig.pose.bones: p.matrix_basis=Matrix.Identity(4)
bpy.context.view_layer.update()
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
report={}
for number,name in [(1,'hero'),(4,'enemy_a'),(8,'enemy_b')]:
    before=set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=os.path.join(SOURCE,f'Characters_psx/Models/Male/Character_{number:02d}.fbx'))
    imported=set(bpy.data.objects)-before
    oldrig=next(o for o in imported if o.type=='ARMATURE')
    mesh=next(o for o in imported if o.type=='MESH')
    weights=[[(g.group,g.weight) for g in v.groups] for v in mesh.data.vertices]
    bpy.context.scene.frame_set(1)
    bpy.context.view_layer.update()
    evaluated=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
    data=bpy.data.meshes.new_from_object(evaluated)
    # new_from_object preserves vertex group indices, UVs and the evaluated pose.
    transformed={}
    for group in mesh.vertex_groups:
        short=group.name.replace('mixamorig:','')
        if short not in mapping: continue
        target=mapping[short]
        p=oldrig.pose.bones[group.name]
        old=frame(oldrig.matrix_world@p.head,oldrig.matrix_world@p.tail)
        b=rig.data.bones[target]
        new=frame(rig.matrix_world@b.head_local,rig.matrix_world@b.tail_local)
        transformed[group.index]=(target,new@Matrix.Scale(.36,4)@old.inverted())
    world=mesh.matrix_world.copy()
    for v in data.vertices:
        original=world@v.co; total=0.; result=Vector()
        for index,weight in weights[v.index]:
            if index in transformed:
                result+=(transformed[index][1]@original)*weight; total+=weight
        v.co=result/total if total else original*.36
    visual=bpy.data.objects.new(name,data); bpy.context.collection.objects.link(visual)
    visual.vertex_groups.clear()
    for group in mesh.vertex_groups:
        short=group.name.replace('mixamorig:','')
        visual.vertex_groups.new(name=mapping.get(short,group.name))
    for index,groups in enumerate(weights):
        for group,weight in groups:
            visual.vertex_groups[group].add([index],weight,'REPLACE')
    visual.parent=rig
    mod=visual.modifiers.new('UAL skin','ARMATURE'); mod.object=rig
    print('SKIN',name,[(g.index,g.name) for g in list(visual.vertex_groups)[:4]],sum(len(v.groups) for v in data.vertices))
    for poly in data.polygons: poly.use_smooth=False
    # Replace absolute source image paths with a packed, portable material.
    mat=bpy.data.materials.new(name+'_palette'); mat.use_nodes=True
    bsdf=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
    if bsdf is None:
        bsdf=mat.node_tree.nodes.new('ShaderNodeBsdfPrincipled')
        output=mat.node_tree.nodes.new('ShaderNodeOutputMaterial')
        mat.node_tree.links.new(bsdf.outputs[0],output.inputs['Surface'])
    bsdf.inputs['Roughness'].default_value=1
    image=bpy.data.images.load(os.path.join(SOURCE,f'Characters_psx/Textures/Character_{number:02d}.png'),check_existing=True)
    image.pack()
    tex=mat.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=image; tex.interpolation='Closest'
    mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
    data.materials.clear(); data.materials.append(mat)
    for o in imported: bpy.data.objects.remove(o,do_unlink=True)
    keep=['Pistol_Idle_Loop','Walk_Loop','Jog_Fwd_Loop','Pistol_Shoot','Pistol_Reload','Death01']
    for t in list(rig.animation_data.nla_tracks): rig.animation_data.nla_tracks.remove(t)
    rig.animation_data.action=None
    for label in keep:
        action=bpy.data.actions.get(label)
        t=rig.animation_data.nla_tracks.new(); t.name=label
        strip=t.strips.new(label,1,action)
        if hasattr(strip,'action_slot') and len(action.slots): strip.action_slot=action.slots[0]
    bpy.ops.object.select_all(action='DESELECT')
    rig.select_set(True); visual.select_set(True); bpy.context.view_layer.objects.active=rig
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,name+'.glb'),export_format='GLB',use_selection=True,export_animation_mode='NLA_TRACKS',export_skins=True,export_anim_slide_to_zero=True)
    report[name]={'vertices':len(data.vertices),'triangles':sum(len(p.vertices)-2 for p in data.polygons),'clips':keep,'bones':len(rig.data.bones)}
    bpy.data.objects.remove(visual,do_unlink=True)
with open(os.path.join(OUT,'manifest.json'),'w') as f: json.dump(report,f,indent=2)
print('CHARACTERS_READY',json.dumps(report))
