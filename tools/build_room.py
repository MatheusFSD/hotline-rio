"""The protagonist's room between nights, generated in Blender through the installed MCP bridge.

Architecture and furniture come from the supplied packs (extract them under tools/source/room):
- "PSX modular house interior pack": walls, floor, ceiling, window and most furniture.
- "Models pack psx": the CRT monitor and the bookcase.
The weapon rack with its five guns, the investigation board and the PC tower are modeled here
with the PSX kit from build_environment.py. Clickable pieces are separate named objects
(Hotspot_*, Weapon_*) so the game can raycast them. Writes assets/room/room.glb, plus each gun
on its own in assets/weapons/<gun>.glb (grip at the origin, barrel toward Godot -Z) with the
muzzle positions in assets/weapons/weapons.json, for the hero's hand.
"""
import bpy, os, math, json, importlib.util
from mathutils import Vector, Matrix

HERE=os.path.dirname(os.path.abspath(__file__))
def module(name,file):
    spec=importlib.util.spec_from_file_location(name,os.path.join(HERE,file))
    m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m); return m
kit=module('lapa_kit','build_environment.py')
intro=module('lapa_intro','build_intro.py')
ROOT=kit.ROOT
PACKS=os.path.join(HERE,'source','room')
MODULAR=os.path.join(PACKS,'modular')
MODELS=os.path.join(PACKS,'models','Models pack psx')
C,mix,mul,grain,hsh,vnoise=kit.C,kit.mix,kit.mul,kit.grain,kit.hsh,kit.vnoise
ARCH=.75          # modular tiles are 4 m; three metres suit a small flat
BACK=4.5          # back wall plane (Blender y); the room spans x -3..3, y -1.5..4.5

# ---------------------------------------------------------------- pack imports
def _single(new):
    """Join imported meshes into one object with its transform applied, drop empties."""
    meshes=[o for o in new if o.type=='MESH']
    for o in meshes:
        world=o.matrix_world.copy(); o.parent=None; o.matrix_world=world
    for o in new:
        if o.type!='MESH': bpy.data.objects.remove(o)
    if len(meshes)>1:
        with bpy.context.temp_override(active_object=meshes[0],selected_editable_objects=meshes):
            bpy.ops.object.join()
    obj=meshes[0]
    obj.data.transform(obj.matrix_world); obj.matrix_world=Matrix.Identity(4)
    return obj

def bounds(obj):
    # Measured on the vertices: obj.bound_box goes stale after mesh.transform().
    pts=[v.co for v in obj.data.vertices]
    lo=Vector((min(p.x for p in pts),min(p.y for p in pts),min(p.z for p in pts)))
    hi=Vector((max(p.x for p in pts),max(p.y for p in pts),max(p.z for p in pts)))
    return lo,hi

def place(obj,name,at,turn=0.0,scale=1.0,anchor='bottom'):
    """Rotate about Z, scale, then move the bounding box so `at` is its bottom (or centre)."""
    obj.name=name
    m=Matrix.Rotation(turn,4,'Z')@Matrix.Scale(scale,4)
    obj.data.transform(m)
    lo,hi=bounds(obj)
    centre=(lo+hi)/2
    ref=Vector((centre.x,centre.y,lo.z if anchor=='bottom' else centre.z))
    obj.data.transform(Matrix.Translation(Vector(at)-ref))
    return obj

def prop(path,name,at,turn=0.0,scale=1.0,anchor='bottom'):
    before=set(kit.scene.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(MODULAR,path+'.glb'))
    return place(_single(set(kit.scene.objects)-before),name,at,turn,scale,anchor)

models_cache={}
def model(source,name,at,turn=0.0,height=None,width=None,anchor='bottom'):
    """Copy one object out of the big Models pack FBX, resized to a real height or width."""
    obj=models_cache[source].copy(); obj.data=models_cache[source].data.copy()
    kit.scene.collection.objects.link(obj)
    lo,hi=bounds(obj); size=hi-lo
    scale=height/size.z if height else width/size.x
    return place(obj,name,at,turn,scale,anchor)

def load_models(names):
    before=set(kit.scene.objects)
    bpy.ops.import_scene.fbx(filepath=os.path.join(MODELS,'Models','models.fbx'))
    new=set(kit.scene.objects)-before
    textures={f.lower():f for f in os.listdir(os.path.join(MODELS,'Texture'))}
    for name in names:
        # Blender appends .001 when the open file already holds an object with that name.
        obj=min((o for o in new if o.name==name or (o.name.startswith(name+'.') and o.name[len(name)+1:].isdigit())),key=lambda o:len(o.name))
        world=obj.matrix_world.copy(); obj.parent=None
        obj.data=obj.data.copy(); obj.data.transform(world); obj.matrix_world=Matrix.Identity(4)
        # The FBX points at its author's folders; relink to the pack's own textures.
        for mat in obj.data.materials:
            for node in (mat.node_tree.nodes if mat and mat.use_nodes else []):
                if node.type=='TEX_IMAGE' and node.image:
                    found=textures.get(os.path.basename(node.image.filepath).lower())
                    if found: node.image.filepath=os.path.join(MODELS,'Texture',found); node.image.reload(); node.image.pack()
                    node.interpolation='Closest'
        kit.scene.collection.objects.unlink(obj)
        models_cache[name]=obj
    for o in new:
        if o.name not in names: bpy.data.objects.remove(o)

# ---------------------------------------------------------------- kit geometry in Blender axes
def bx(mat,x0,x1,y0,y1,z0,z1,scale=.3):
    kit.box(mat,x0,-y1,x1-x0,y1-y0,z0,z1,scale)

def tube(mat,x,z,y0,y1,r,n=6,caps=True):
    """Prism along Blender Y, for barrels, tubes and pins."""
    ring=[(x+r*math.cos(math.tau*i/n),z+r*math.sin(math.tau*i/n)) for i in range(n)]
    for i in range(n):
        (ax,az),(bx_,bz)=ring[i],ring[(i+1)%n]
        kit.face(mat,[(ax,y0,az),(ax,y1,az),(bx_,y1,bz),(bx_,y0,bz)],.3,((ax+bx_)/2-x,0,(az+bz)/2-z))
    if caps:
        kit.face(mat,[(px,y1,pz) for px,pz in ring],.3,(0,1,0))
        kit.face(mat,[(px,y0,pz) for px,pz in ring],.3,(0,-1,0))

def quad(mat,pts,uv,normal):
    g=kit.geo.setdefault(mat,([],[],[])); base=len(g[0])
    if normal and _normal(pts).dot(Vector(normal))<0: pts=pts[::-1]; uv=uv[::-1]
    g[0].extend(pts); g[1].append(tuple(range(base,base+len(pts)))); g[2].extend(uv)

def _normal(pts):
    a,b,c=(Vector(p) for p in pts[:3]); return (b-a).cross(c-b)

def bake(name):
    """Everything in the kit's face buffer becomes one named object with material slots."""
    verts=[]; faces=[]; uvs=[]; slots=[]; index=[]
    for slot,(mat,(v,f,uv)) in enumerate(kit.geo.items()):
        base=len(verts); verts.extend(v); uvs.extend(uv); slots.append(kit.materials[mat])
        for face in f: faces.append(tuple(base+k for k in face)); index.append(slot)
    me=bpy.data.meshes.new(name); me.from_pydata(verts,[],faces); kit.created_meshes.append(me)
    layer=me.uv_layers.new(name='UVMap')
    for i,loop in enumerate(me.loops): layer.data[i].uv=uvs[loop.vertex_index]
    for m in slots: me.materials.append(m)
    for poly,slot in zip(me.polygons,index): poly.material_index=slot
    me.update()
    obj=bpy.data.objects.new(name,me); kit.scene.collection.objects.link(obj)
    kit.geo.clear()
    return obj

# ---------------------------------------------------------------- textures
def t_gun_metal(x,y): return grain(mix(C('2b2e31'),C('3c4044'),vnoise(x,y,4,4,60)),x,y,.08,61)
def t_polymer(x,y): return grain(C('1c1d1f'),x,y,.06,62)
def t_olive(x,y):
    c=grain(mix(C('4a5230'),C('3a4126'),vnoise(x,y,4,4,63)),x,y,.07,64)
    return mul(c,.7) if y%8==0 else c
def t_cork(x,y):
    c=mix(C('b88a52'),C('8f6537'),vnoise(x,y,2,16,65))
    return mul(c,.7) if hsh(x,y,66)>.9 else grain(c,x,y,.08,67)
def t_pegboard(x,y):
    c=grain(mix(C('5b3d25'),C('4a311d'),vnoise(x,y,8,4,68)),x,y,.05,69)
    return C('1a120c') if x%8==4 and y%8==4 else c
def t_keys(x,y):
    if y<2 or x<1 or x>30: return C('b9b29c')
    return C('8f8874') if (x%3==0 or y%3==1) else C('d8d1bb')
def t_pc_screen(x,y):
    # Retro desktop: blue field, a terminal window with green lines and a red alert.
    c=C('12306a')
    if 6<=x<58 and 6<=y<42:
        c=C('101410')
        if y<10: c=C('9aa0a8')
        elif y%4==1 and 9<x<9+int(10+hsh(y,0,70)*36): c=C('4cff6a')
        if 44<=x<54 and 30<=y<38: c=C('d81e1e')
    if y>=44: c=C('9aa0a8') if x>8 else C('2f8f3a')
    return c

CELLS=32   # 32x32 cards side by side in the clues atlas (room for act 3)

def t_clues(x,y):
    """The board's cards, 32x32 each: clipping, bar photo, ghost polaroid, map, sticky note,
    mugshot, classified file and the Arcos at night (the board as it starts), then the act 1
    clues: ledger page, phone, receipt, lipstick mirror, sales book, Iara's sketch, SÍNDICO? note;
    then act 2: the shipping manifest with its tag, the morgue intake ledger, the CAM 03 tape, the
    rifle purchase order and Avelar's diary; Prates' invitation and the auction catalogue; the
    Síndico's speech and the guest list with its one H; act 3: the 13/12 script and the archive tapes, the 1977 death certificate and the council minutes, the 13/12 list and Souza's file."""
    cell=x//32; lx,ly=x%32,y
    if cell==8:      # spiral notebook page: blue lines, a column of amounts, the last line in red
        c=C('f1ecdc')
        if ly>=29 and lx%4<2: c=C('6a6a6a')
        elif ly%4==1 and ly<27: c=C('9ab4d8')
        if ly%4==0 and 4<lx<4+int(10+hsh(ly,2,81)*14) and ly<24: c=C('2a2a5a')
        if ly in (24,25) and 4<lx<27: c=C('c41e1e')
        return grain(c,x,y,.05,72)
    if cell==9:      # phone, its screen lit with a message
        c=C('141414')
        if 9<=lx<23 and 3<=ly<29:
            c=C('1c2c44')
            if 6<=ly<24 and 11<=lx<21:
                c=C('4a8ad8') if ly%4<2 and lx<11+int(4+hsh(ly,3,91)*6) else C('203a60')
        return grain(c,x,y,.04,72)
    if cell==10:     # receipts: narrow slips, dotted totals, a red R$ stamp
        c=C('0f0f0f')
        if 6<=lx<26:
            c=C('ece8de')
            if ly%3==0 and lx%2==0: c=C('8a867c')
            if 18<=ly<26 and 9<=lx<23 and (ly in (18,25) or lx in (9,22)): c=C('c41e1e')
        return grain(c,x,y,.05,72)
    if cell==11:     # mirror with lipstick across it
        c=mix(C('b8c0c8'),C('dfe6ec'),(lx+ly)/62)
        if abs(ly-(8+lx*.3))<1.2 and 3<lx<29: c=C('d0244a')
        if abs(ly-(16+math.sin(lx*.5)*2))<1.2 and 3<lx<29: c=C('d0244a')
        if lx<2 or lx>29 or ly<2 or ly>29: c=C('5a4a3a')
        return grain(c,x,y,.03,72)
    if cell==12:     # sales book: green ledger columns
        c=C('dfe8d2')
        if lx in (8,20) or ly%3==0: c=C('7fa080')
        if ly%3==1 and 21<lx<29: c=C('2a3a2a')
        if ly<4: c=C('2e4a2e')
        return grain(c,x,y,.05,72)
    if cell==13:     # Iara's sketch: a person, and something folded inside it
        c=C('efe6cf')
        body=math.hypot(lx-16,ly-7)<4 or (ly>10 and abs(lx-16)<4+(ly-10)*.25)
        if body and not (math.hypot(lx-16,ly-7)<3 or (ly>11 and abs(lx-16)<3+(ly-11)*.25)): c=C('3a3a3a')
        if 12<ly<28 and abs((lx-16)-math.sin(ly*.9)*2)<1: c=C('6a3a9a')
        return grain(c,x,y,.05,72)
    if cell==14:     # pink note with a big question mark: SÍNDICO?
        c=C('f29ac0')
        if (math.hypot(lx-16,ly-10)<7 and math.hypot(lx-16,ly-10)>4.5 and not (lx<15 and ly>10)) or (14<=lx<18 and 14<=ly<21) or (14<=lx<18 and 24<=ly<27): c=C('3a1a2a')
        return grain(c,x,y,.04,72)
    if cell==15:     # shipping manifest: carbon-yellow form, ruled lines, PILAR stamp, a white toe tag
        c=C('efe3a8')
        if ly%4==2 and 3<lx<29 and ly<22: c=C('8a7f5a')
        if ly<3: c=C('2f6b63')
        if 6<=ly<12 and 18<=lx<28 and (ly in (6,11) or lx in (18,27)): c=C('c41e1e')
        if 22<=ly<30 and 3<=lx<13: c=C('f4f2ea') if not (ly==25 and 5<lx<11) else C('2a2a2a')
        if 22<=ly<26 and lx==13: c=C('8a8a8a')
        return grain(c,x,y,.05,72)
    if cell==16:     # morgue intake ledger: grey register, columns, red RETIRADO stamps
        c=C('d8d8d0')
        if lx in (6,20) or ly%3==0: c=C('9a9a92')
        if ly<4: c=C('3a3f46')
        if ly%6==4 and 21<lx<30: c=C('c41e1e')
        return grain(c,x,y,.05,72)
    if cell==17:     # VHS tape: black shell, two reels, a white label with CAM 03 scrawled in red
        c=C('161616')
        if 4<=ly<28 and 2<=lx<30 and (math.hypot(lx-10,ly-17)<4 or math.hypot(lx-22,ly-17)<4): c=C('3a3a3a') if (lx+ly)%3 else C('0a0a0a')
        if 5<=ly<12 and 5<=lx<27: c=C('ece8de') if not (ly in (7,8) and 8<lx<24 and lx%4<3) else C('c41e1e')
        if ly<2 or ly>29: c=C('2a2a2a')
        return grain(c,x,y,.04,72)
    if cell==18:     # purchase order: white form, green header, a big 40 and a signature
        c=C('f2f2ec')
        if ly<5: c=C('2e5a3a')
        if ly%3==0 and 3<lx<29 and 6<ly<22: c=C('a6aaa0')
        if 8<=ly<17 and 4<=lx<14 and ((lx in (4,5) and ly<13) or ly in (12,13) or lx in (10,11) or (17<=lx<23 and (lx in (17,22) or ly in (8,16)))): c=C('1a1a1a')
        if 8<=ly<17 and 17<=lx<23 and (lx in (17,22) or ly in (8,16)): c=C('1a1a1a')
        if 24<=ly<28 and abs(ly-(25+math.sin(lx*.7)*1.5))<1 and 6<lx<26: c=C('2a3aa0')
        return grain(c,x,y,.05,72)
    if cell==19:     # Avelar's diary: brown leather edge, cream page, one date ringed in red
        c=C('5a3420')
        if 3<=lx<29 and 2<=ly<30:
            c=C('efe6cf')
            if ly%4==1 and 6<lx<27: c=C('b4ac98')
            if 3<=lx<6: c=C('d8cfb8')
            if 8<math.hypot((lx-17)*.8,ly-15)*2<11: c=C('c41e1e')
        return grain(c,x,y,.05,72)
    if cell==20:     # Prates' invitation: cream card, gold border, script lines, a red wax seal
        c=C('f2ead2')
        if lx<2 or lx>29 or ly<2 or ly>29: c=C('c9a13b')
        elif ly%5==2 and 7<lx<25 and ly<18: c=C('6a5a3a')
        if math.hypot(lx-16,ly-23)<4: c=C('9a1a1a') if math.hypot(lx-16,ly-23)<3 else C('6a0e0e')
        return grain(c,x,y,.04,72)
    if cell==21:     # auction catalogue page: glossy white, an oil portrait in a gilt frame, LOTE 12
        c=C('f4f2ec')
        if 5<=lx<27 and 3<=ly<22:
            c=C('b08a3a') if (lx<7 or lx>24 or ly<5 or ly>19) else C('3a2a1e')
            if math.hypot((lx-16)*1.1,ly-11)<5: c=C('c9a07a')
            if 15<=ly<20 and abs(lx-16)<6 and not math.hypot((lx-16)*1.1,ly-11)<5: c=C('22222a')
        if ly in (25,26) and 8<lx<24: c=C('1a1a1a')
        if ly==28 and 11<lx<21: c=C('8d2a24')
        return grain(c,x,y,.04,72)
    if cell==22:     # the Síndico's speech: typed lines, 40.000 circled, a handwritten note in the margin
        c=C('f4f2ea')
        if ly%3==1 and 3<lx<23 and 3<ly<29: c=C('5a5a5a')
        if 9<math.hypot((lx-13)*.6,ly-14)*2<12: c=C('c41e1e')
        if 24<=lx<30 and abs(ly-(10+math.sin(lx*.9)*3))<1 and ly<24: c=C('2a3aa0')
        if ly<2: c=C('2f5a3a')
        return grain(c,x,y,.04,72)
    if cell==23:     # the guest list: seven names on cream, one marked with a red H
        c=C('ece2c6')
        if ly%4==2 and 5<lx<5+int(12+hsh(ly,4,93)*12) and ly<30: c=C('3a2a1a')
        if 18<=ly<25 and 24<=lx<30 and (lx in (24,25,28,29) or ly in (21,22)): c=C('c41e1e')
        if lx<2 or lx>29: c=C('c9a13b')
        return grain(c,x,y,.04,72)
    if cell==24:     # the 13/12 script: TeleRio header, typed lines, ATENTADO in red capitals
        c=C('f2f2ee')
        if ly<4: c=C('1c3a6e')
        if ly%3==0 and 4<lx<28 and 6<ly<29: c=C('5a5a5a')
        if 11<=ly<15 and 4<lx<28: c=C('c8232c') if lx%3 else C('f2f2ee')
        if 22<=ly<24 and 16<lx<28: c=C('2a3aa0')
        return grain(c,x,y,.04,72)
    if cell==25:     # archive tapes: two black U-matic cassettes, white labels 1994 and 2010
        c=C('3a3c40')
        for top in (3,17):
            if top<=ly<top+12 and 3<=lx<29:
                c=C('141414')
                if top+2<=ly<top+6 and 6<=lx<26: c=C('ece8de') if not (ly==top+4 and 9<lx<20 and lx%2) else C('c41e1e')
        return grain(c,x,y,.04,72)
    if cell==26:     # the 1977 death certificate: yellowed form, a black border, a round notary stamp
        c=C('e8dcb4')
        if lx<2 or lx>29 or ly<2 or ly>29: c=C('2a2a2a')
        elif ly%3==0 and 4<lx<27 and 4<ly<20: c=C('6a5a3a')
        if 7<math.hypot(lx-20,ly-24)*2<10: c=C('2a3aa0')
        if 22<=ly<26 and 4<lx<14: c=C('8d2a24') if lx%2 else c
        return grain(c,x,y,.05,72)
    if cell==27:     # the council minutes: typed page, seven signatures in a column
        c=C('f2f0ea')
        if ly<3: c=C('2f5a3a')
        if ly%4==1 and 3<lx<14 and 4<ly<30: c=C('5a5a5a')
        if ly%4==1 and 16<lx<29 and 4<ly<30 and abs(math.sin(lx*1.3+ly))<.6: c=C('2a3aa0')
        return grain(c,x,y,.04,72)
    if cell==28:     # the 13/12 list: a clinic letterhead, thirty short lines, the date circled
        c=C('f4f6f4')
        if ly<3: c=C('4f8f84')
        if ly%2==1 and 4<ly<30 and 3<lx<3+int(6+hsh(ly,5,95)*10): c=C('3a3a3a')
        if 7<math.hypot((lx-23)*.8,ly-7)*2<10: c=C('c41e1e')
        return grain(c,x,y,.04,72)
    if cell==29:     # Souza's file: a pale green folder, a clip, a police photo and PRIORIDADE in red
        c=C('cfe0c8')
        if ly<4 and 8<lx<24: c=C('b8c8b0')
        if 5<=ly<16 and 4<=lx<13: c=C('6a6a6a') if not (math.hypot(lx-8.5,ly-9)<2.5) else C('b07a55')
        if ly%3==0 and 15<lx<28 and 5<ly<16: c=C('5a5a5a')
        if 20<=ly<24 and 4<lx<28: c=C('c41e1e') if lx%2 else c
        if lx in (14,15) and ly<6: c=C('9a9a9a')
        return grain(c,x,y,.04,72)
    if cell>29: return C('000000')
    if cell==0:      # newspaper clipping
        c=C('e6e0cf')
        if 2<=ly<7 and 2<lx<29: c=C('1a1a1a')
        elif 9<=ly<19 and 2<lx<14: c=C('6a6a6a') if (lx+ly)%3 else C('3a3a3a')
        elif ly>8 and ly%3==0 and (lx<2 or lx>15 or ly>20) and 2<lx<29: c=C('8a8578')
    elif cell==1:    # night photo of the bar
        c=C('0e1220')
        if 12<=ly<30 and 4<lx<28: c=C('8a4a2a')
        if 14<=ly<28 and 6<lx<26 and (lx%5<2) and (ly%6<3): c=C('ffcf6a')
        if lx<1 or lx>30 or ly<1 or ly>30: c=C('f2f2f2')
    elif cell==2:    # polaroid of the ghost
        c=C('f4f2ea')
        if 2<=lx<30 and 2<=ly<24:
            c=C('0b1a2e')
            if math.hypot(lx-16,ly-8)<3.5 or (ly>11 and abs(lx-16)<3+(ly-11)*.4): c=C('6fe7ff')
        if ly in (27,28) and 6<lx<26: c=C('3050a0')
    elif cell==3:    # street map of Lapa
        c=C('e8dcb4')
        if lx%9==3 or ly%11==5 or abs(lx-ly)<1: c=C('7d9cc4')
        if 10<math.hypot(lx-19,ly-13)*2<14: c=C('d81e1e')
    elif cell==4:    # sticky note
        c=C('f2d94a')
        if ly%6==3 and 4<lx<4+int(8+hsh(ly,1,71)*18): c=C('2a2a6a')
    elif cell==5:    # mugshot
        c=C('8d9396') if ly%5 else C('6d7376')
        if math.hypot((lx-16)*1.2,ly-12)<8: c=C('b07a55')
        if ly<9 and abs(lx-16)<8 and math.hypot((lx-16)*1.2,ly-12)<9: c=C('2a1a12')
        if ly>=24: c=C('141414') if not (26<=ly<29 and 6<lx<26 and lx%3) else C('e8e8e8')
    elif cell==6:    # classified file with a red stamp
        c=C('f0ede4')
        if ly%3==0 and 3<lx<29 and ly>4: c=C('9a968c')
        if 18<=ly<26 and 8<=lx<26 and (ly in (18,25) or lx in (8,25) or 20<=ly<23): c=C('c41e1e')
    else:            # the Arcos at night
        c=C('0f1a36')
        if 14<=ly<26 and not (math.hypot((lx%8)-4,ly-20)<3 and ly<24): c=C('d8d2c4')
        if ly>=26: c=C('1a1a1a')
    return grain(c,x,y,.05,72)

def make_room_palette():
    for name,fn,w,h in [('gun_metal',t_gun_metal,16,16),('polymer',t_polymer,16,16),('olive',t_olive,16,16),
        ('cork',t_cork,32,32),('pegboard',t_pegboard,32,32),('keys',t_keys,32,16),('clues',t_clues,32*CELLS,32)]:
        kit.material(name,image=kit.texture(name,w,h,fn))
    kit.material('pc_screen',image=kit.texture('pc_screen',64,48,t_pc_screen),glow=1.6)
    kit.material('night_city',image=kit.texture('night_city',64,48,intro.t_skyline),glow=1.4)
    kit.material('beige','cfc6ae'); kit.material('yarn','c21a1a',emission='8a0c0c',strength=.6); kit.material('yarn_blue','2a6ad8',emission='0c3a8a',strength=.6)
    kit.material('pin_red','d42020'); kit.material('pin_yellow','e8c020'); kit.material('pin_blue','2050d0')
    kit.material('gun_wood_dark','5a3218')

# ---------------------------------------------------------------- weapons (muzzle toward +Y)
RACK_X=-2.84   # front face of the pegboard on the left wall

def pistol(x,y,z,rack=True):
    bx('gun_metal',x-.016,x+.016,y-.11,y+.12,z+.03,z+.075)
    bx('polymer',x-.018,x+.018,y-.11,y+.06,z,z+.035)
    bx('polymer',x-.018,x+.018,y-.12,y-.06,z-.12,z)
    bx('polymer',x-.008,x+.008,y-.06,y+.0,z-.04,z-.03)
    tube('gun_metal',x,z+.055,y+.12,y+.14,.008,5)
    if rack:   # spare magazines hang beside it
        for i in range(2): bx('gun_metal',x-.012,x+.012,y+.2+i*.05,y+.23+i*.05,z-.1,z+.02)

def smg(x,y,z,rack=True):
    bx('gun_metal',x-.024,x+.024,y-.16,y+.16,z,z+.085)
    tube('gun_metal',x,z+.045,y+.16,y+.24,.012,6)
    bx('polymer',x-.02,x+.02,y-.06,y+.0,z-.12,z)
    bx('gun_metal',x-.016,x+.016,y-.045,y-.015,z-.27,z-.12)          # magazine through the grip
    bx('polymer',x-.018,x+.018,y+.06,y+.12,z-.07,z)
    for dy in (-.36,-.17): bx('gun_metal',x-.006,x+.006,y+dy,y+dy+.19,z+.02,z+.03)   # folded wire stock
    bx('gun_metal',x-.006,x+.006,y-.36,y-.35,z-.03,z+.03)

def shotgun(x,y,z,rack=True):
    tube('gun_metal',x,z+.035,y-.12,y+.5,.013,6)
    tube('gun_metal',x,z+.005,y-.12,y+.42,.012,6)
    bx('gun_wood_dark',x-.022,x+.022,y+.12,y+.3,z-.012,z+.022)       # pump
    bx('gun_metal',x-.022,x+.022,y-.28,y-.1,z-.02,z+.06)
    bx('gun_wood_dark',x-.02,x+.02,y-.4,y-.26,z-.05,z+.04)
    bx('gun_wood_dark',x-.02,x+.02,y-.62,y-.4,z-.1,z+.045)
    bx('gun_metal',x-.006,x+.006,y-.22,y-.18,z-.06,z-.02)

def rifle(x,y,z,rack=True):
    bx('gun_metal',x-.022,x+.022,y-.2,y+.1,z,z+.075)
    bx('gun_wood_dark',x-.026,x+.026,y+.1,y+.3,z+.005,z+.065)         # handguard
    tube('gun_metal',x,z+.04,y+.3,y+.5,.009,6)
    tube('gun_metal',x,z+.085,y+.1,y+.3,.008,5)                       # gas tube
    bx('gun_metal',x-.006,x+.006,y+.46,y+.48,z+.04,z+.09)
    for i in range(3):                                                # curved magazine
        bx('gun_metal',x-.016,x+.016,y-.04-i*.035,y+.02-i*.035,z-.06*(i+1),z-.06*i)
    bx('gun_wood_dark',x-.02,x+.02,y-.25,y-.19,z-.12,z+.01)
    bx('gun_wood_dark',x-.022,x+.022,y-.6,y-.2,z-.06,z+.06)

def minigun(x,y,z,rack=True):
    axis=z+.11
    for i in range(6):
        a=math.tau*i/6
        tube('gun_metal',x+math.cos(a)*.045,axis+math.sin(a)*.045,y-.05,y+.62,.012,5,caps=True)
    for yy in (y+.18,y+.5): tube('polymer',x,axis,yy,yy+.035,.07,6)
    tube('gun_metal',x,axis,y-.3,y-.05,.085,8)
    bx('olive',x-.07,x+.07,y-.42,y-.22,z-.08,z+.04)                  # motor housing
    bx('polymer',x-.012,x+.012,y-.36,y-.12,axis+.1,axis+.13)          # carry handle
    for yy in (y-.36,y-.14): bx('polymer',x-.012,x+.012,yy-.012,yy+.012,axis+.06,axis+.1)
    for dx in (-.05,.05): bx('polymer',x+dx-.01,x+dx+.01,y-.52,y-.42,z+.0,z+.16)   # spade grips
    bx('olive',x-.09,x+.09,y-.2,y+.1,z-.33,z-.12)                   # ammo can and belt
    for i in range(8): bx('brass',x-.02,x+.02,y-.04+i*.0,y-.02,z-.12+i*.03,z-.1+i*.03)

# Mount point (y, z) of each gun on the rack, top to bottom; pegs sit just under them.
ROWS=[('pistol',pistol,1.75,2.5,(1.6,1.95)),('smg',smg,2.4,2.2,(2.1,2.75)),('shotgun',shotgun,2.15,1.84,(1.55,2.75)),
    ('rifle',rifle,2.15,1.5,(1.5,2.8)),('minigun',minigun,2.25,.96,())]
# Half thickness of each gun, so it rests against the pegboard.
DEPTH={'pistol':.035,'smg':.04,'shotgun':.04,'rifle':.042,'minigun':.11}
# In the hand: where the right hand grips (y, z) and where the barrel ends, in builder units.
GRIP={'pistol':(-.09,-.06),'smg':(-.03,-.07),'shotgun':(-.31,.0),'rifle':(-.22,-.05),'minigun':(-.47,.08)}
MUZZLE={'pistol':(.14,.055),'smg':(.24,.045),'shotgun':(.5,.035),'rifle':(.5,.04),'minigun':(.62,.11)}
# Where the animations put the body against the gun: stock butt on the shoulder, the left hand's
# grip (vertical foregrip, pump, handguard) and the magazine or loading port reached when reloading.
POINTS={'smg':{'support':(.09,-.035),'mag':(-.03,-.27)},
    'shotgun':{'stock':(-.62,-.03),'support':(.15,.005),'mag':(-.16,-.03)},
    'rifle':{'stock':(-.6,0),'support':(.14,.035),'mag':(-.09,-.13)}}
# Same exaggeration idea as the rack, milder for the top-down camera. Long guns stay life-size
# so the stock reaches the shoulder while the left hand still reaches the handguard.
HAND_SCALE={'pistol':1.25,'smg':1.1,'shotgun':1.0,'rifle':1.0,'minigun':1.25}

def export_hand_weapons(target):
    """One GLB per gun with the grip at the origin and the barrel along Blender +Y (Godot -Z)."""
    # Keep entries other tools own (build_katana.py adds the katana); only the guns are redone here.
    path=os.path.join(ROOT,'assets/weapons/weapons.json')
    manifest=json.load(open(path)) if os.path.exists(path) else {}
    for name,build,_,_,_ in ROWS:
        gy,gz=GRIP[name]
        build(0,-gy,-gz,rack=False)
        gun=bake('Gun_'+name)
        s=HAND_SCALE[name]
        gun.data.transform(Matrix.Diagonal((s,s,s,1)))
        kit.export_glb(os.path.join(ROOT,'assets/weapons',name+'.glb'))
        bpy.data.objects.remove(gun)
        godot=lambda y,z:[0,round((z-gz)*s,4),round(-(y-gy)*s,4)]
        manifest[name]={'muzzle':godot(*MUZZLE[name])}
        for key,(y,z) in POINTS.get(name,{}).items(): manifest[name][key]=godot(y,z)
    with open(path,'w') as f: json.dump(manifest,f,indent=2)
    return manifest

def build_rack():
    # Pegboard on the left wall with steel pegs; the minigun's ammo can rests on the bottom rail.
    bx('pegboard',-2.98,RACK_X,.9,3.5,.45,2.78,.6)
    bx('gun_wood_dark',-2.99,RACK_X+.01,.86,3.54,2.78,2.84); bx('gun_wood_dark',RACK_X,RACK_X+.22,.86,3.54,.4,.46)
    for _,_,_,z,pegs in ROWS:
        for py in pegs: bx('gun_metal',RACK_X,RACK_X+.1,py-.014,py+.014,z-.06,z-.03)
    bake('Rack')
    # Guns are enlarged around their pegs so they still read from the fixed camera.
    for name,build,y,z,_ in ROWS:
        build(RACK_X+DEPTH[name],y,z)
        gun=bake('Weapon_'+name)
        pivot=Vector((RACK_X,y,z))
        gun.data.transform(Matrix.Translation(pivot)@Matrix.Diagonal((1.5,1.5,1.5,1))@Matrix.Translation(-pivot))

# ---------------------------------------------------------------- investigation board
BOARD=(-2.35,-.45,1.35,2.6)   # x0, x1, z0, z1 on the back wall
CLUES=[  # cell, centre x, centre z, width, height, tilt
    (2,-1.42,1.98,.34,.4,.04),(0,-2.05,2.33,.42,.3,-.06),(5,-2.1,1.82,.24,.28,.05),(5,-1.82,1.52,.22,.26,-.08),
    (5,-.92,1.55,.22,.26,.07),(1,-.8,2.3,.36,.28,.05),(3,-.98,1.95,.34,.3,-.04),(4,-1.5,2.45,.16,.16,.12),
    (6,-1.42,1.53,.3,.24,-.03),(7,-2.1,1.53,.26,.2,.09),(4,-.62,1.72,.14,.14,-.1),(0,-1.85,2.12,.22,.16,.08)]
YARN=[(0,1),(0,2),(0,3),(0,4),(0,5),(0,6),(0,8),(5,6),(1,11),(2,9),(6,10),(3,4),(7,0)]
## Clues found in the nights, each its own object Clue_<id> that the room shows once the clue is found:
## id, cards (cell, centre x, centre z, width, height, tilt), the board card its yarn runs to
## (None: pinned on its own, like the mirror photo the hero cannot place yet) and the yarn colour.
CLUE_CARDS=[
    ('caderno_taxa',[(8,-1.12,2.42,.2,.24,-.06)],5,'yarn'),
    ('celular_russo',[(9,-1.68,2.3,.12,.2,.1)],2,'yarn'),
    ('recibos_casarao',[(10,-1.2,1.78,.2,.24,.05)],6,'yarn'),
    ('espelho_banheiro',[(11,-2.24,2.1,.18,.2,-.05)],None,'yarn'),
    ('livro_vendas',[(12,-.6,2.08,.22,.2,.06)],6,'yarn'),
    ('caderno_iara',[(13,-1.66,1.78,.2,.2,-.07)],0,'yarn_blue'),   # the first blue thread: the Avesso
    ('celular_gravata',[(9,-.58,1.45,.12,.2,-.08),(14,-.62,2.47,.14,.14,.1)],4,'yarn'),
    ('mapa_linha',[(3,-2.2,2.45,.26,.18,.04)],6,'yarn'),
    ('pasta_armario',[(6,-1.26,1.44,.22,.16,-.05)],8,'yarn'),
    # Act 2: the Caju.
    ('guia_remessa',[(15,-1.06,1.72,.2,.22,.06)],8,'yarn'),           # the Pilar to the Guardião
    ('livro_iml',[(16,-2.0,1.98,.18,.2,-.06)],0,'yarn_blue'),       # the morgue, on the Avesso thread
    ('fita_cam03',[(17,-1.38,2.27,.2,.13,-.05)],0,'yarn_blue'),     # the folding man, back to the ghost
    ('ordem_compra',[(18,-1.86,1.64,.17,.21,.06)],8,'yarn'),        # 40 rifles, onto the classified file
    ('agenda_avelar',[(19,-.8,1.8,.16,.18,-.07)],4,'yarn'),         # the auction, to a face on the board
    ('convite_prates',[(20,-1.62,1.42,.16,.16,.08)],8,'yarn'),      # the Ilha Fiscal ball, onto the classified file
    ('catalogo_lote12',[(21,-2.24,2.32,.15,.19,-.06)],0,'yarn_blue'),  # Castelar's unchanged face, on the Avesso thread
    ('discurso_sindico',[(22,-.98,2.48,.16,.2,.05)],8,'yarn'),      # Operation Clean House, onto the classified file
    ('lista_convidados',[(23,-.62,2.2,.15,.18,-.08)],5,'yarn'),     # the one H, Jairo, to the bar photo
    ('roteiro_plantao',[(24,-1.5,2.12,.17,.21,.06)],2,'yarn'),      # the staged attack, to the hero's own mugshot
    ('fitas_arquivo',[(25,-2.04,1.72,.15,.17,-.05)],0,'yarn_blue'), # the same face in 1994 and 2010
    ('escritura_casca',[(26,-1.2,2.3,.17,.2,-.04)],0,'yarn_blue'),  # 1977: the casca's own death
    ('ata_conselho',[(27,-.74,1.5,.15,.19,.07)],8,'yarn'),         # seven signatures, onto the classified file
    ('lista_1312',[(28,-1.64,1.94,.15,.2,-.06)],2,'yarn'),          # thirty renewals, to the hero's mugshot
    ('prontuario_souza',[(29,-2.26,1.36,.16,.17,.05)],5,'yarn')]   # Souza, to the bar photo where he first stood

def _card(cell,cx,cz,w,h,tilt,y,pin,pin_y):
    """One paper on the cork, and its pin; returns where the pin went."""
    c,s=math.cos(tilt),math.sin(tilt)
    corners=[(cx+dx*c-dz*s,y,cz+dx*s+dz*c) for dx,dz in ((-w/2,-h/2),(w/2,-h/2),(w/2,h/2),(-w/2,h/2))]
    u0=cell/CELLS; quad('clues',corners,[(u0,0),(u0+1/CELLS,0),(u0+1/CELLS,1),(u0,1)],(0,-1,0))
    px,pz=cx-(h/2-.03)*s,cz+(h/2-.03)*c
    tube(pin,px,pz,pin_y,pin_y+.025,.012,5)
    return px,pz

def _yarn(mat,a,b,y):
    (ax,az),(bxx,bz)=a,b
    dx,dz=bxx-ax,bz-az; length=math.hypot(dx,dz); nx,nz=-dz/length*.004,dx/length*.004
    quad(mat,[(ax-nx,y,az-nz),(bxx-nx,y,bz-nz),(bxx+nx,y,bz+nz),(ax+nx,y,az+nz)],[(0,0),(1,0),(1,1),(0,1)],(0,-1,0))

def build_board():
    face_y=BACK-.06
    x0,x1,z0,z1=BOARD
    bx('cork',x0,x1,face_y,BACK-.01,z0,z1,.8)
    for a,b,c,d in ((x0-.04,x1+.04,z1,z1+.04),(x0-.04,x1+.04,z0-.04,z0),(x0-.04,x0,z0,z1),(x1,x1+.04,z0,z1)):
        bx('gun_wood_dark',a,b,face_y-.01,BACK-.01,c,d)
    pins=[]
    for i,(cell,cx,cz,w,h,tilt) in enumerate(CLUES):
        pins.append(_card(cell,cx,cz,w,h,tilt,face_y-.002-i*.0008,['pin_red','pin_yellow','pin_blue'][i%3],face_y-.035))
    # Red wool between pins, just in front of the papers.
    for a,b in YARN: _yarn('yarn',pins[a],pins[b],face_y-.022)
    bake('Hotspot_board')
    # The clues found during act 1 go on top, each separate so the room can show only those found.
    for k,(cid,cards,to,mat) in enumerate(CLUE_CARDS):
        y=face_y-.0115-k*.0008   # in front of every starting card, behind the wool
        own=[_card(cell,cx,cz,w,h,tilt,y-j*.0004,'pin_yellow',face_y-.04) for j,(cell,cx,cz,w,h,tilt) in enumerate(cards)]
        if to is not None: _yarn(mat,own[0],pins[to],face_y-.026)
        if len(own) > 1: _yarn(mat,own[0],own[1],face_y-.026)
        bake('Clue_'+cid)

# ---------------------------------------------------------------- PC and the rest of the room
def build_pc(desk_top):
    x,y=-1.95,BACK-.42
    monitor=model('Cube.167','Monitor',(x,y,desk_top),math.pi,width=.46)
    # Glowing screen in front of the tube; position measured from the monitor's own bounds.
    mlo,mhi=bounds(monitor)
    front=mlo.y-.004
    lo,hi=mlo.z,mhi.z
    w=.3; zc=lo+(hi-lo)*.57; h=w*.75
    quad('pc_screen',[(x-w/2,front,zc-h/2),(x+w/2,front,zc-h/2),(x+w/2,front,zc+h/2),(x-w/2,front,zc+h/2)],[(0,0),(1,0),(1,1),(0,1)],(0,-1,0))
    bx('beige',x+.38,x+.58,y-.2,y+.24,desk_top,desk_top+.44)          # tower
    bx('polymer',x+.4,x+.56,y-.205,y-.2,desk_top+.3,desk_top+.36)
    kit.box('keys',x-.24,-(y-.3),.48,.17,desk_top,desk_top+.03,.48)   # keyboard
    bx('beige',x+.3,x+.37,y-.42,y-.31,desk_top,desk_top+.03)          # mouse
    bake('Hotspot_pc')

def build_window():
    # Night skyline behind the back window, glowing through the frame.
    quad('night_city',[(.2,BACK+.6,.2),(3.8,BACK+.6,.2),(3.8,BACK+.6,3.4),(.2,BACK+.6,3.4)],[(0,0),(1,0),(1,1),(0,1)],(0,-1,0))
    bake('City')

def build_room():
    for ix in (-1.5,1.5):
        for iy in (0,3):
            prop('geometry/floorWood2','Floor',(ix,iy,0),scale=ARCH)
            prop('geometry/ceilingPlaster','Ceiling',(ix,iy,3.0),math.pi,scale=ARCH,anchor='center')
    prop('geometry/wallWallpaper2','Wall_back_left',(-1.5,BACK,0),math.pi,scale=ARCH)
    prop('geometry/wallWindowWallpaper2','Wall_back_window',(1.5,BACK,0),math.pi,scale=ARCH)
    for iy in (0,3):
        prop('geometry/wallWallpaper2','Wall_left',(-3,iy,0),-math.pi/2,scale=ARCH)
    prop('geometry/wallDoorWallpaper2','Wall_right_door',(3,0,0),math.pi/2,scale=ARCH)
    prop('geometry/wallWallpaper2','Wall_right',(3,3,0),math.pi/2,scale=ARCH)
    prop('geometry/doorWood','Hotspot_door',(2.96,0,0),math.pi/2,scale=ARCH)
    # Desk with the PC under the board, bed under the window.
    desk=prop('props/table2','Desk',(-1.45,BACK-.62,0),0)
    desk_top=bounds(desk)[1].z
    prop('props/chair4','Chair',(-.75,BACK-1.35,0),math.pi-.7)   # pulled out, clear of the screen
    # Single bed with the headboard against the back wall, under the window.
    bed=prop('props/bed3','Bed',(1.45,BACK-1.25,0),-math.pi/2)
    blo,bhi=bounds(bed)
    stand=prop('props/tableSmall2','Nightstand',(bhi.x+.38,BACK-.32,0),0,.75)
    slo,shi=bounds(stand)
    # Everything on the nightstand sits on its real top, inside its footprint.
    prop('props/tableLamp','Lamp_table',(slo.x+.15,(slo.y+shi.y)/2+.04,shi.z),0)
    prop('props/radio','Radio',(shi.x-.17,(slo.y+shi.y)/2-.03,shi.z),-.35,.8)
    prop('props/lamp','Lamp_floor',(-2.55,-.45,0),0)
    box=prop('props/box','Box_ammo',(-2.5,.42,0),0)
    prop('props/box','Box_ammo_2',(-2.48,.4,bounds(box)[1].z),.3)
    prop('props/carpet2','Carpet',(.2,1.2,.015),.12)
    prop('props/trashBin','Trash',(-.3,BACK-.45,0),0,.8)
    prop('props/clock','Clock',(-2.955,4.05,2.55),0,anchor='center')
    prop('props/ceilingLight','Ceiling_light',(0,1.6,2.9),0)
    prop('props/painting3','Painting',(2.98,3.0,1.9),math.pi,anchor='center')
    model('Librero.001','Bookcase',(2.72,1.6,0),math.pi/2,height=1.55)
    # The mess of someone who lives alone and works nights.
    prop('props/pizza','Pizza',(1.3,BACK-1.9,bhi.z-.08),.4,.8)
    prop('props/remote','Remote',(1.75,BACK-1.4,bhi.z-.06),1.1)
    prop('props/cup3','Mug',(-1.1,BACK-.5,desk_top),0)
    prop('props/burger','Burger',(-.75,BACK-.75,desk_top),.6)
    prop('props/milkCarton','Milk',(-.62,BACK-.4,desk_top),.3)
    prop('props/cup','Mug_2',(shi.x-.12,slo.y+.1,shi.z),0)
    for i,(x,y,turn) in enumerate(((-.2,2.1,.3),(.5,2.75,1.9),(-1.1,1.0,2.6),(2.45,1.0,.9))):
        prop(['props/bottle','props/bottle1','props/bottle2','props/bottle'][i],'Bottle_%d' % i,(x,y,0),turn)
    prop('props/trashBag','Trash_bag',(.15,BACK-.35,0),.4)
    prop('props/trashBag2','Trash_bag_2',(2.55,.45,0),1.2)
    prop('props/paperBag','Paper_bag',(-1.6,1.6,0),.8)
    for i in range(3): prop('props/vhs','Tape_%d' % i,(.9+i*.17,.7+i*.09,.0),i*.9)
    prop('props/bookStack3','Books_floor',(-2.3,3.2,0),.5)
    build_window()
    build_board()
    build_pc(desk_top)
    build_rack()

def rebuild_hand_weapons():
    """Only the guns for the hand, without rebuilding the room."""
    with kit.workspace('Lapa_Weapons') as scene:
        kit.make_palette()
        make_room_palette()
        return export_hand_weapons(scene)

if __name__=='__main__':
    with kit.workspace('Lapa_Room') as scene:
        kit.make_palette()
        make_room_palette()
        try:
            load_models(['Cube.167','Librero.001'])
            build_room()
        finally:
            for obj in models_cache.values(): bpy.data.objects.remove(obj)
        triangles=sum(len(p.vertices)-2 for o in scene.objects if o.type=='MESH' for p in o.data.polygons)
        kit.export_glb(os.path.join(ROOT,'assets/room/room.glb'))
        print('ROOM_READY',len(scene.objects),'objects',triangles,'triangles')
        for ob in list(scene.objects): bpy.data.objects.remove(ob)
        print('WEAPONS_READY',export_hand_weapons(scene))
