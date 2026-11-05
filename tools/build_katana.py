"""The hero's katana, built through the Blender MCP bridge and exported to assets/weapons/katana.glb.

Same convention as the guns (tools/build_room.py): the origin is the centre of the right fist and
Blender +Y is the gun's forward (Godot -Z). The blade rises along Blender +Z (Godot +Y: out of the
fist on the index-finger side), edge toward +Y, so it cuts where a gun would point. The guard sits
just above the index finger and the handle runs down past the pinky. PS1 budget: flat-shaded
prisms, a triangular blade with a little curve, a tiny diamond-wrap texture on the handle.
Built in its own scene, "Katana", which is left open for viewing; the weapons manifest gets a
"katana" entry. Run inside Blender (MCP): exec(open(path).read())
"""
import bpy, bmesh, math, os, json

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))) if '__file__' in globals() else r"C:\Users\Matheus\Documents\hotline rio\godot 3d"
GUARD = .056      # tsuba just above the index finger (fist centre to guard)
HANDLE = .27      # tsuka below the guard, room for a second hand
BLADE = .70       # nagasa
WIDTH = .031      # edge to spine
THICK = .0075
SORI = .022       # curvature: the tip bends back toward the spine
SEGMENTS = 5

def material(name, color, image=None):
    m = bpy.data.materials.get('Katana_' + name) or bpy.data.materials.new('Katana_' + name)
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Roughness'].default_value = 1
    if image:
        tex = m.node_tree.nodes.new('ShaderNodeTexImage')
        tex.image = image
        tex.interpolation = 'Closest'
        m.node_tree.links.new(tex.outputs['Color'], bsdf.inputs['Base Color'])
    return m

def wrap_texture():
    # Tsuka-ito: dark cord crossing over pale same skin, in 8 x 32 pixels.
    img = bpy.data.images.get('Katana_wrap') or bpy.data.images.new('Katana_wrap', 8, 32, alpha=False)
    px = []
    for y in range(32):
        for x in range(8):
            d = abs(x % 8 - 3.5) + abs(y % 8 - 3.5)
            c = (.84, .80, .70) if d < 2.6 else (.07, .07, .09)
            px += [*c, 1]
    img.pixels.foreach_set(px)
    img.pack()
    return img

def rgb(h): return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))

def prism(bm, slot, uv, rx, ry, z0, z1, sides, v_repeat=1.0):
    """Closed prism around the Z axis, elliptical section; UVs run around (u) and along (v)."""
    ring0 = [bm.verts.new((math.cos(a) * rx, math.sin(a) * ry, z0)) for a in (math.tau * (i + .5) / sides for i in range(sides))]
    ring1 = [bm.verts.new((v.co.x, v.co.y, z1)) for v in ring0]
    for i in range(sides):
        j = (i + 1) % sides
        f = bm.faces.new((ring0[i], ring0[j], ring1[j], ring1[i]))
        f.material_index = slot
        for loop, (u, v) in zip(f.loops, ((i / sides, 0), ((i + 1) / sides, 0), ((i + 1) / sides, v_repeat), (i / sides, v_repeat))):
            loop[uv].uv = (u, v)
    for ring, flip in ((ring0, True), (ring1, False)):
        f = bm.faces.new(ring[::-1] if flip else ring)
        f.material_index = slot

def blade(bm, slot):
    """Triangular section (edge toward +Y, spine toward -Y), tapering and curving back to the tip."""
    z0 = GUARD + .008
    rings = []
    for k in range(SEGMENTS + 1):
        t = k / SEGMENTS
        z = z0 + BLADE * t
        bend = -SORI * t * t
        w = WIDTH * (1 - .22 * t)
        th = THICK * (1 - .35 * t)
        rings.append([bm.verts.new((0, w / 2 + bend, z)),
                      bm.verts.new((-th / 2, -w / 2 + bend, z)),
                      bm.verts.new((th / 2, -w / 2 + bend, z))])
    # Kissaki: the point leans toward the spine, like a real katana tip.
    tip = bm.verts.new((0, -SORI - WIDTH * .2, z0 + BLADE + .045))
    for k in range(SEGMENTS):
        a, b = rings[k], rings[k + 1]
        for i in range(3):
            j = (i + 1) % 3
            bm.faces.new((a[i], a[j], b[j], b[i])).material_index = slot
    last = rings[-1]
    for i in range(3):
        bm.faces.new((last[i], last[(i + 1) % 3], tip)).material_index = slot
    bm.faces.new((rings[0][2], rings[0][1], rings[0][0])).material_index = slot

def build(scene):
    mats = [material('steel', rgb('cfd6de')), material('wrap', (1, 1, 1), wrap_texture()),
            material('iron', rgb('2c2a26')), material('brass', rgb('b08a3a'))]
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new('UVMap')
    blade(bm, 0)
    bottom = GUARD - HANDLE
    prism(bm, 1, uv, .0135, .0165, bottom + .012, GUARD - .002, 6, v_repeat=HANDLE / .045)   # tsuka
    prism(bm, 2, uv, .0145, .0175, bottom, bottom + .012, 6)                                  # kashira
    prism(bm, 2, uv, .036, .042, GUARD - .002, GUARD + .008, 8)                               # tsuba
    prism(bm, 3, uv, .006, .019, GUARD + .008, GUARD + .032, 4)                               # habaki
    mesh = bpy.data.meshes.new('Katana')
    bm.to_mesh(mesh)
    bm.free()
    for m in mats: mesh.materials.append(m)
    for p in mesh.polygons: p.use_smooth = False
    ob = bpy.data.objects.new('Katana', mesh)
    scene.collection.objects.link(ob)
    return ob

def run():
    window = bpy.context.window or bpy.context.window_manager.windows[0]
    scene = bpy.data.scenes.get('Katana')
    if scene:
        for ob in list(scene.objects): bpy.data.objects.remove(ob)
    else:
        scene = bpy.data.scenes.new('Katana')
    window.scene = scene   # export from the window's own scene
    ob = build(scene)
    path = os.path.join(ROOT, 'assets', 'weapons', 'katana.glb')
    with bpy.context.temp_override(window=window, scene=scene):
        bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_active_scene=True,
                                  export_animations=False, export_lights=False, export_cameras=False)
    # Manifest in Godot gun space: Blender (x, y, z) -> (x, z, -y).
    manifest_path = os.path.join(ROOT, 'assets', 'weapons', 'weapons.json')
    manifest = json.load(open(manifest_path))
    tip_y, tip_z = -SORI - WIDTH * .2, GUARD + .008 + BLADE + .045
    manifest['katana'] = {'muzzle': [0, round(tip_z, 4), round(-tip_y, 4)], 'guard': [0, GUARD, 0]}
    json.dump(manifest, open(manifest_path, 'w'), indent=2)
    print('KATANA_READY', path, len(ob.data.polygons), 'faces', [round(v, 3) for v in ob.dimensions])

run()
