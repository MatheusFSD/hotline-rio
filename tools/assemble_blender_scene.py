"""Leave a complete, editable scene in Blender via the local MCP bridge."""
import bpy, os, math, json
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
for ob in list(bpy.data.objects): bpy.data.objects.remove(ob,do_unlink=True)
for action in list(bpy.data.actions): bpy.data.actions.remove(action)
bpy.ops.import_scene.gltf(filepath=os.path.join(ROOT,'assets/environment/lapa.glb'))
layout=json.load(open(os.path.join(ROOT,'assets/level.json')))
spawns=[{'p':layout['start'],'angle':-math.pi/2}]+layout['enemies']
gun_mat=bpy.data.materials.new('Gunmetal'); gun_mat.diffuse_color=(.09,.11,.12,1)
for i,entry in enumerate(spawns):
    before=set(bpy.data.objects); actions_before=set(bpy.data.actions)
    name='hero' if i==0 else ('enemy_a' if i%2 else 'enemy_b')
    bpy.ops.import_scene.gltf(filepath=os.path.join(ROOT,'assets/characters',name+'.glb'))
    imported=set(bpy.data.objects)-before
    rig=next(ob for ob in imported if ob.type=='ARMATURE')
    if rig.animation_data:
        for track in rig.animation_data.nla_tracks: track.mute=True
        idle=next(a for a in set(bpy.data.actions)-actions_before if a.name.startswith('Pistol_Idle'))
        rig.animation_data.action=idle
        if idle.slots: rig.animation_data.action_slot=idle.slots[0]
    group=bpy.data.objects.new('Protagonist' if i==0 else f'Enemy_{i:02d}',None)
    bpy.context.collection.objects.link(group)
    for ob in imported:
        if ob.parent not in imported: ob.parent=group
    bpy.context.scene.frame_set(1); bpy.context.view_layer.update()
    # Rigid pistol follows the animated right hand.
    p=rig.matrix_world@rig.pose.bones['hand_r'].head
    for dims,offset in [((.08,.32,.085),(0,-.12,.025)),((.075,.085,.15),(0,0,-.065))]:
        bpy.ops.mesh.primitive_cube_add(size=1,location=p+Vector(offset))
        ob=bpy.context.object; ob.name='Pistol'; ob.dimensions=dims
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        ob.data.materials.append(gun_mat)
        world=ob.matrix_world.copy()
        ob.parent=rig; ob.parent_type='BONE'; ob.parent_bone='hand_r'
        bpy.context.view_layer.update(); ob.matrix_world=world
    group.location=(entry['p'][0],-entry['p'][1],0)
    group.rotation_euler.z=math.pi/2-entry['angle']
bpy.ops.object.camera_add(location=(0,-23.7,33))
camera=bpy.context.object; camera.name='Gameplay overview'
camera.rotation_euler=(Vector((0,1.8,0))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.type='ORTHO'; camera.data.ortho_scale=42.4
bpy.context.scene.camera=camera
bpy.ops.object.light_add(type='SUN',location=(0,0,15))
bpy.context.object.rotation_euler=(math.radians(30),math.radians(-25),math.radians(-30))
bpy.context.object.data.energy=2
bpy.context.scene.render.resolution_x=1280
bpy.context.scene.render.resolution_y=800
bpy.context.scene.render.resolution_percentage=100
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':
        area.spaces.active.region_3d.view_perspective='CAMERA'
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'tools/source/hotline_rio_3d.blend'))
print('BLENDER_SCENE_READY',len(spawns),'animated characters')
