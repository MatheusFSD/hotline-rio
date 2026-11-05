"""Lines up every PSX character from the two extracted packs in the open Blender, for browsing.

Characters_psx_1.2 (No-Rig models) and Characters_Extras_01 (Extras_01 models), extracted next
to their zips in the repository root. The Extras are also bundled in Characters_psx 1.2 under the
same names, so each character appears once: the 24 Extras in their own row, the rest by group.
Textures are relinked by file name (the FBX files point at the pack author's disk) and sampled
nearest. Run inside a fresh Blender: blender --python tools/character_lineup.py
"""
import bpy, os, math

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PSX = os.path.join(ROOT, 'Characters_psx_1.2', 'Characters_psx_02')
EXTRAS = os.path.join(ROOT, 'Characters_Extras_01')
SPACING = 1.1      # metres between characters in a row
PER_ROW = 20
ROW_GAP = 2.4      # metres between rows, stacked downward like a contact sheet
FACE = math.radians(-90)   # the packs face +X; turn them toward the front view (-Y)

def fbx_in(folder):
    return sorted(os.path.join(folder, f) for f in os.listdir(folder) if f.lower().endswith('.fbx'))

def textures():
    found = {}
    for folder in (os.path.join(PSX, 'Textures'), os.path.join(EXTRAS, 'Textures')):
        for f in os.listdir(folder):
            if f.lower().endswith('.png'): found.setdefault(f.lower(), os.path.join(folder, f))
    return found

def groups():
    extras = fbx_in(os.path.join(EXTRAS, 'Models', 'Extras_01', 'Male')) + fbx_in(os.path.join(EXTRAS, 'Models', 'Extras_01', 'Female'))
    taken = {os.path.basename(p) for p in extras}
    def psx(kind): return [p for p in fbx_in(os.path.join(PSX, 'Models', 'No-Rig', kind)) if os.path.basename(p) not in taken]
    return [('Masculino', psx('Male')), ('Feminino', psx('Female')), ('Killers e Monstros', psx('Killer_M')), ('Extras_01', extras)]

def label(text, location, size, collection):
    curve = bpy.data.curves.new('Label', 'FONT')
    curve.body = text
    curve.size = size
    curve.align_x = 'CENTER'
    ob = bpy.data.objects.new('Label_' + text, curve)
    ob.location = location
    ob.rotation_euler = (math.radians(90), 0, 0)   # standing, facing the front view
    collection.objects.link(ob)
    return ob

def build():
    scene = bpy.context.scene
    for ob in list(scene.objects): bpy.data.objects.remove(ob)   # the startup cube, light and camera
    scene.name = 'Personagens_PSX'
    pngs = textures()
    ink = bpy.data.materials.new('Label_ink')
    ink.diffuse_color = (.05, .05, .06, 1)
    z = 0.0
    total = 0
    for name, paths in groups():
        group = bpy.data.collections.new(name)
        scene.collection.children.link(group)
        title = label('%s  (%d)' % (name.upper(), len(paths)), (-1.2, 0, z + .8), .32, group)
        title.data.align_x = 'RIGHT'
        title.data.materials.append(ink)
        for i, path in enumerate(paths):
            col, row = i % PER_ROW, i // PER_ROW
            x, zz = col * SPACING, z - row * ROW_GAP
            before = set(bpy.data.objects)
            bpy.ops.import_scene.fbx(filepath=path)
            for ob in set(bpy.data.objects) - before:
                for c in list(ob.users_collection): c.objects.unlink(ob)
                group.objects.link(ob)
                if ob.parent is None:
                    ob.location = (x, 0, zz)
                    ob.rotation_euler = (0, 0, FACE)
            short = os.path.splitext(os.path.basename(path))[0].replace('Character_', '')
            tag = label(short, (x, -.3, zz - .12 - .1 * (col % 2)), .075, group)
            tag.data.materials.append(ink)
            total += 1
        z -= math.ceil(len(paths) / PER_ROW) * ROW_GAP + 1.0
    # The packs point at the author's disk: relink every image to the extracted Textures by name.
    missing = []
    for image in bpy.data.images:
        path = pngs.get(os.path.basename(image.filepath.replace('\\', '/')).lower())
        if path:
            image.filepath = path
            image.reload()
        elif image.filepath: missing.append(image.name)
    for mat in bpy.data.materials:
        if mat.node_tree:
            for node in mat.node_tree.nodes:
                if node.type == 'TEX_IMAGE': node.interpolation = 'Closest'
    print('LINEUP_READY', total, 'characters; textures missing:', missing)

def frame():
    # Textured solid shading, everything in view.
    for window in bpy.context.window_manager.windows:
        for area in window.screen.areas:
            if area.type != 'VIEW_3D': continue
            space = area.spaces.active
            space.shading.type = 'SOLID'
            space.shading.color_type = 'TEXTURE'
            space.clip_end = 500
            region = next(r for r in area.regions if r.type == 'WINDOW')
            with bpy.context.temp_override(window=window, area=area, region=region):
                bpy.ops.view3d.view_axis(type='FRONT')
                bpy.ops.view3d.view_all()
    return None

build()
bpy.app.timers.register(frame, first_interval=1.0)
