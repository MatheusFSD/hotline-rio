"""PSX Lapa bar cutaway, generated in Blender through the installed MCP bridge.

Collision still comes from assets/level.json: every interior piece is modeled inside its
solid's footprint, so the simulation and the picture agree. Textures are tiny procedural
images sampled with nearest filtering. The build happens in a temporary scene, leaving
whatever is open in Blender untouched; the editable source is written to tools/source.
"""
import bpy, math, os, json, contextlib

ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
layout=json.load(open(os.path.join(ROOT,'assets/level.json')))

# ---------------------------------------------------------------- textures
def hsh(x,y,s=0):
    n=(x*374761393+y*668265263+s*1442695041)&0xffffffff
    n=((n^(n>>13))*1274126177)&0xffffffff
    return ((n^(n>>16))&0xffff)/65535.0

def vnoise(x,y,cell,period,s=0):
    # Tileable value noise: lattice wraps at `period` cells.
    gx,gy=x/cell,y/cell; ix,iy=int(gx),int(gy); fx,fy=gx-ix,gy-iy
    def v(a,b): return hsh(a%period,b%period,s)
    top=v(ix,iy)*(1-fx)+v(ix+1,iy)*fx
    bot=v(ix,iy+1)*(1-fx)+v(ix+1,iy+1)*fx
    return top*(1-fy)+bot*fy

def C(h): h=h.lstrip('#'); return tuple(int(h[i:i+2],16)/255 for i in (0,2,4))
def mul(c,k): return tuple(v*k for v in c)
def mix(a,b,t): return tuple(a[i]*(1-t)+b[i]*t for i in range(3))
def grain(c,x,y,amount=.07,s=0): return mul(c,1+(hsh(x,y,s)-.5)*2*amount)

images=[]
def texture(name,w,h,fn):
    img=bpy.data.images.new('Lapa_'+name,w,h,alpha=False)
    px=[0.0]*(w*h*4)
    for y in range(h):
        for x in range(w):
            r,g,b=fn(x,y)
            i=((h-1-y)*w+x)*4  # pattern functions use a top-left origin
            px[i:i+4]=(min(1,max(0,r)),min(1,max(0,g)),min(1,max(0,b)),1.0)
    img.pixels.foreach_set(px); img.pack(); images.append(img)
    return img

def cement(base,dark,speckle=0.0,seed=0,joint=0):
    """Single-colour floor: mottled like burnt cement, optionally with faint terrazzo chips
    and expansion joints every `joint` pixels, drawn in a darker shade of the same colour."""
    def fn(x,y):
        c=mix(C(base),C(dark),vnoise(x,y,8,4,10+seed)*.8)
        if speckle and hsh(x,y,30+seed)>1-speckle: c=mul(c,1.12 if hsh(x,y,31) > .5 else .88)
        c=grain(c,x,y,.05,8+seed)
        if joint and (x%joint==0 or y%joint==0): c=mul(c,.78)
        return c
    return fn

def t_wood(x,y):
    plank=y//8; tone=.82+hsh(plank,0,5)*.3
    c=mul(C('6b3d22'),tone)
    c=mul(c,.9+.12*math.sin(x*.55+plank*2.1+vnoise(x,y,4,8,6)*3))
    if y%8==0: c=mul(c,.45)
    if (x+plank*11)%32==3 and y%8==4: c=C('2a1a12')
    return grain(c,x,y,.05,2)

def plaster(base,stain='6f6047'):
    def fn(x,y):
        n=vnoise(x,y,8,4,7)*.65+vnoise(x,y,4,8,8)*.35
        c=mix(C(base),C(stain),max(0,n-.55)*1.3)
        if hsh(x//2,y//3,9)>.985: c=mul(c,.6)
        return grain(c,x,y,.05,3)
    return fn

def t_azulejo(x,y):
    tx,ty=x%16,y%16
    blue,light,white=C('1f3f86'),C('6f8fc7'),C('e6e3d6')
    if tx==0 or ty==0: return C('9a978c')
    dx,dy=abs(tx-8),abs(ty-8)
    if dx+dy<=2: c=blue
    elif dx+dy in (5,6): c=blue
    elif dx==dy and dx<4: c=light
    elif min(tx,16-tx)<3.5 and min(ty,16-ty)<3.5: c=blue
    else: c=white
    return grain(c,x,y,.05,4)

def t_concrete(x,y):
    n=vnoise(x,y,8,4,10)
    c=mix(C('77756e'),C('4c4a45'),n)
    if vnoise(x,y,16,2,11)>.72: c=mul(c,.72)  # damp patches
    c=grain(c,x,y,.07,8)
    return mul(c,.72) if x%16==0 or y%16==0 else c  # slab joints

def t_white_tile(x,y):
    if x%8==0 or y%8==0: return C('8f948f')
    return grain(mix(C('e9ebe4'),C('b7b49d'),vnoise(x,y,8,4,13)*.35),x,y,.03,10)

def t_metal(x,y):
    return grain(mul(C('8e9696'),.9+vnoise(x,y*4,4,4,14)*.2),x,y,.05,11)

def t_leather(x,y):
    tx,ty=x%8,y%8
    c=C('8f2a24')
    if (tx,ty) in ((4,4),(0,0)): c=C('3b100e')
    elif abs(tx-ty)==0 or abs(tx+ty-8)==0: c=mul(c,.78)
    return grain(c,x,y,.06,12)

def t_marble(x,y):
    v=abs(math.sin((x+y)*.28+vnoise(x,y,8,4,15)*5))
    c=mix(C('e4e1d8'),C('8d8b86'),max(0,.25-v)*3)
    return grain(c,x,y,.03,13)

def t_gingham(x,y):
    a,b=(x//4)%2,(y//4)%2
    c=C('b42f2f') if a and b else C('e0b2a6') if a or b else C('efe8dd')
    return grain(c,x,y,.04,14)

def t_crate(x,y):
    c=C('d6a21e')
    if y%8 in (2,3,5) and 2<x%16<14: c=C('5b4310')
    if y%8==0: c=mul(c,.75)
    return grain(c,x,y,.06,15)

def t_roof(x,y):
    row=y//4; ox=(x+(3 if row%2 else 0))%32
    c=mul(C('a1502e'),.82+hsh(ox//6,row,16)*.3)
    if y%4==3: c=mul(c,.55)
    elif ox%6==0: c=mul(c,.75)
    if vnoise(x,y,8,4,17)>.7: c=mix(c,C('4b4a3a'),.35)  # moss
    return grain(c,x,y,.05,16)

def t_mosaic(x,y):
    # Selarón steps: little glazed tiles in red, yellow, green and blue.
    palette=[C('c42d2a'),C('d9a521'),C('1f7a3d'),C('1f4fa0'),C('c42d2a'),C('e8e2d0')]
    if x%4==0 or y%4==0: return C('d8d2c4')
    return grain(palette[int(hsh(x//4,y//4,18)*len(palette))%len(palette)],x,y,.08,17)

def t_posters(x,y):
    # Four 16x32 bills: samba night, beer, a sun and a choro trio.
    p=x//16; lx,ly=x%16,y
    bg=[C('d8b04a'),C('a92e2b'),C('2b5c7a'),C('e4dccb')][p]
    ink=[C('2a1a14'),C('f2e6c8'),C('f0c24a'),C('9c2b23')][p]
    c=bg
    if ly<2 or ly>29 or lx<1 or lx>14: c=mul(bg,.7)
    elif p==0 and math.hypot(lx-7.5,ly-12)<5: c=ink
    elif p==1 and 5<lx<11 and 8<ly<22: c=C('d39a2a') if ly>11 else C('f5f1e8')
    elif p==2 and math.hypot(lx-7.5,ly-10)<4: c=ink
    elif p==3 and ly in (9,10) and 2<lx<13: c=ink
    elif p==3 and 12<ly<20 and lx%4==2: c=C('3a2a20')
    elif ly in (24,26) and 2<lx<13 and hsh(lx,ly,p)>.25: c=ink
    return grain(c,x,y,.05,19)

def t_graffiti(x,y):
    c=plaster('8b8a84','55534c')(x,y)
    for cx,cy,r,col in ((12,16,9,'d6366b'),(28,13,8,'3aa7d1'),(45,18,10,'f1c232'),(56,9,5,'5fbf5a')):
        d=math.hypot(x-cx,(y-cy)*1.3)
        if d<r-1.5: c=C(col)
        elif d<r: c=C('141414')
    if 26<y<29 and hsh(x//3,0,20)>.4: c=C('141414')
    return c

def t_chalk(x,y):
    c=grain(C('23302b'),x,y,.05,21)
    if y%5==2 and 3<x<29 and hsh(x//2,y,22)>.3: c=C('d7d6cc')
    if y<1 or y>30 or x<1 or x>30: c=C('6b4426')
    return c

# ---------------------------------------------------------------- materials
materials={}
def material(name,color='ffffff',image=None,emission=None,alpha=None,strength=2.5,glow=0.0):
    """`glow` also drives emission from the image, for screens and video walls."""
    m=bpy.data.materials.new('Lapa_'+name); m.use_nodes=True
    tree=m.node_tree; node=next(n for n in tree.nodes if n.type=='BSDF_PRINCIPLED')
    node.inputs['Base Color'].default_value=(*C(color),1)
    node.inputs['Roughness'].default_value=1
    node.inputs['Metallic'].default_value=0
    if image:
        tex=tree.nodes.new('ShaderNodeTexImage'); tex.image=image; tex.interpolation='Closest'
        tree.links.new(tex.outputs['Color'],node.inputs['Base Color'])
        if glow:
            tree.links.new(tex.outputs['Color'],node.inputs['Emission Color'])
            node.inputs['Emission Strength'].default_value=glow
    if emission:
        node.inputs['Emission Color'].default_value=(*C(emission),1)
        node.inputs['Emission Strength'].default_value=strength
    if alpha is not None:
        node.inputs['Alpha'].default_value=alpha
        try: m.surface_render_method='BLENDED'
        except Exception: m.blend_method='BLEND'
    m.diffuse_color=(*C(color),1 if alpha is None else alpha)
    materials[name]=m
    return name

def make_palette():
    # Rio floors in a single colour each: burnt red cement, terrazzo, grey cement, granite sills,
    # plain Portuguese stone and asphalt. No printed patterns or checkerboards.
    for name,fn,size in [('vermelhao',cement('8a3a2b','6b2b21',seed=1,joint=16),32),('granilite',cement('c9bfab','c0b6a1',.06,2,16),32),
        ('cimento',cement('a3a49e','86877f',seed=3,joint=16),32),('granito',cement('4d4b48','3a3937',.05,4),32),
        ('pedra',cement('d8d4c8','bdb8aa',.04,5),32),('asphalt',cement('3b3c3e','2d2e30',seed=6),32),
        ('rubber',cement('2c2e30','222325',seed=7),16),('wood',t_wood,32),
        ('plaster',plaster('cdbb92'),32),('azulejo',t_azulejo,32),
        ('concrete',t_concrete,32),('white_tile',t_white_tile,32),
        ('metal',t_metal,16),('leather',t_leather,16),('marble',t_marble,32),('gingham',t_gingham,16),
        ('crate',t_crate,16),('roof',t_roof,32),('mosaic',t_mosaic,32),
        ('whitewash',plaster('e2dccb','8f877a'),32),('arcos',plaster('e2dccb','8f877a'),32),('facade_blue',plaster('3f6f93','2b3f52'),32),
        ('facade_pink',plaster('c7727b','6d3a3f'),32),('facade_yellow',plaster('d7aa45','7a5a26'),32),
        ('facade_green',plaster('4f8467','2f4b3c'),32),('ochre',plaster('b9772f','5e3c1a'),32)]:
        material(name,image=texture(name,size,size,fn))
    # The four sobrados flanking the bar get their own copies of everything they wear, so the
    # level can step them back as a frame (scripts/scenery_grade.gd) without touching the same
    # colours inside the bar. Same images, same colours here: the grading happens in Godot.
    for name in ('facade_blue','facade_pink','facade_yellow','facade_green','roof'):
        material('side_'+name,image=bpy.data.images['Lapa_'+name])
    material('posters',image=texture('posters',64,32,t_posters))
    material('graffiti',image=texture('graffiti',64,32,t_graffiti))
    material('chalk',image=texture('chalk',32,32,t_chalk))
    for name,color in {'cap':'000000','dark':'22262a','iron':'2b2d2b','brass':'b08a3a','cream':'e2d7b8',
        'teal':'2f6b63','green_paint':'2e5a45','red_paint':'8d2a24','yellow_paint':'d9b02a','white':'e8e6de',
        'black':'111214','amber':'7a4313','bottle_green':'2d5a2a','bottle_clear':'b9c7c2','label':'d8cfae',
        'lime':'7fb03a','food':'c98a37','pot':'5d6266','leaf':'356b32','soil':'3b2a1d','tire':'1b1b1b',
        'car_blue':'3e7fb0','bonde':'e0b52a','screen':'1d2b3a','foam':'f0ead4','orange':'d26a2a'}.items():
        material(name,color)
    # Trims, shutters and balconies of the side sobrados (same colours as cream, teal, red_paint, iron).
    for name,color in {'cream':'e2d7b8','teal':'2f6b63','red_paint':'8d2a24','iron':'2b2d2b'}.items():
        material('side_'+name,color)
    material('glass','b8d6dc',alpha=.35)
    material('neon_pink','ff5ca8',emission='ff4a9e',strength=4)
    material('neon_cyan','6fe7ff',emission='54dcff',strength=4)
    material('bulb','ffe2a0',emission='ffcf73',strength=3)
    material('bulb_red','ff7a6a',emission='ff5040',strength=3)
    material('bulb_green','8cff8a',emission='5cff5a',strength=3)
    material('bulb_blue','8ab4ff',emission='5a8cff',strength=3)
    material('jukebox_glow','ffb347',emission='ff9a2a',strength=3)
    material('tv_glow','7ec8e3',emission='5fb0d6',strength=1.6)
    material('exit_paint','2f8f75',emission='1f6e58',strength=.6)

# ---------------------------------------------------------------- geometry
# Builders take level metres (x, z = toward the street, h = up). Blender gets (x, -z, h);
# the glTF exporter then turns Blender's Z-up into Godot's Y-up with level z intact.
geo={}
def face(mat,pts,scale=1.0,normal=None):
    """pts are Blender coordinates; UVs come from a box projection in metres."""
    ax,ay=pts[1][0]-pts[0][0],pts[1][1]-pts[0][1]; az=pts[1][2]-pts[0][2]
    bx,by,bz=(pts[2][i]-pts[1][i] for i in range(3))
    n=(ay*bz-az*by,az*bx-ax*bz,ax*by-ay*bx)
    if normal and n[0]*normal[0]+n[1]*normal[1]+n[2]*normal[2]<0:
        pts=pts[::-1]; n=tuple(-v for v in n)
    k=max(range(3),key=lambda i:abs(n[i]))
    if k==2: uv=[(p[0]/scale,p[1]/scale) for p in pts]
    elif k==0: uv=[(p[1]/scale*(1 if n[0]>0 else -1),p[2]/scale) for p in pts]
    else: uv=[(p[0]/scale*(-1 if n[1]>0 else 1),p[2]/scale) for p in pts]
    g=geo.setdefault(mat,([],[],[]))
    base=len(g[0]); g[0].extend(pts); g[1].append(tuple(range(base,base+len(pts)))); g[2].extend(uv)

def obox(mat,cx,cz,w,d,h0,h1,yaw=0.0,scale=1.0,bottom=False,sides=True):
    """Box centred on (cx,cz), w along the yaw direction and d across it."""
    c,s=math.cos(-yaw),math.sin(-yaw)
    def P(lx,ly,h): return (cx+lx*c-ly*s,-cz+lx*s+ly*c,h)
    x0,x1,y0,y1=-w/2,w/2,-d/2,d/2
    face(mat,[P(x0,y0,h1),P(x1,y0,h1),P(x1,y1,h1),P(x0,y1,h1)],scale)
    if bottom: face(mat,[P(x0,y1,h0),P(x1,y1,h0),P(x1,y0,h0),P(x0,y0,h0)],scale)
    if sides:
        face(mat,[P(x1,y0,h0),P(x1,y1,h0),P(x1,y1,h1),P(x1,y0,h1)],scale)
        face(mat,[P(x0,y1,h0),P(x0,y0,h0),P(x0,y0,h1),P(x0,y1,h1)],scale)
        face(mat,[P(x1,y1,h0),P(x0,y1,h0),P(x0,y1,h1),P(x1,y1,h1)],scale)
        face(mat,[P(x0,y0,h0),P(x1,y0,h0),P(x1,y0,h1),P(x0,y0,h1)],scale)

def box(mat,x,z,w,d,h0,h1,scale=1.0,**kw):
    obox(mat,x+w/2,z+d/2,w,d,h0,h1,0,scale,**kw)

def cyl(mat,cx,cz,r,h0,h1,n=6,r1=None,scale=1.0,top=True,phase=0.0):
    r1=r if r1 is None else r1
    ring=[(math.cos(phase+math.tau*i/n),math.sin(phase+math.tau*i/n)) for i in range(n)]
    for i in range(n):
        a,b=ring[i],ring[(i+1)%n]
        face(mat,[(cx+a[0]*r,-cz+a[1]*r,h0),(cx+b[0]*r,-cz+b[1]*r,h0),(cx+b[0]*r1,-cz+b[1]*r1,h1),(cx+a[0]*r1,-cz+a[1]*r1,h1)],scale)
    if top and r1>0: face(mat,[(cx+a*r1,-cz+b*r1,h1) for a,b in ring],scale)

def local(cx,cz,yaw,f,r):
    """Point `f` metres along the facing direction and `r` to its right, in level x/z."""
    return cx+math.cos(yaw)*f-math.sin(yaw)*r,cz+math.sin(yaw)*f+math.cos(yaw)*r

def wall_quad(mat,x0,x1,z,h0,h1,scale=1.0,facing=1):
    """Vertical rectangle in the x/h plane facing +z (toward the camera) or -z."""
    face(mat,[(x0,-z,h0),(x1,-z,h0),(x1,-z,h1),(x0,-z,h1)],scale,normal=(0,-facing,0))

def glued_wing(x0,z0,z1,h,door,wall,roof,glass,lit,trim,door_mat,far=45.0):
    """The rest of a building, standing square against the level's edge at x0: the exit's corridor ends
    at its door, so the night's plan is plainly only a part of the place. The camera looks straight up
    the z axis, so the west wall is edge-on and the door in it cannot show: what reads is the corridor
    running into the building, and the door's light on its threshold and on the corridor's north wall.
    `door` is (z from, z to), the corridor's width."""
    face(wall,[(x0,-z1,0),(x0,-z0,0),(x0,-z0,h),(x0,-z1,h)],1.4,(-1,0,0))
    face(wall,[(x0,-z1,0),(far,-z1,0),(far,-z1,h),(x0,-z1,h)],1.4,(0,-1,0))
    face(roof,[(x0,-z1,h),(far,-z1,h),(far,-z0,h),(x0,-z0,h)],1.6,(0,0,1))
    # Floors on the street face: a sill line and a row of windows.
    floors=max(2,round(h/2.8))
    for f in range(floors):
        h0=.9+f*h/floors; h1=h0+1.25
        box(trim,x0,z1+.01,far-x0,.05,h0-.12,h0-.04)
        k=0; x=x0+.5
        while x+1.5<far:
            mat=lit if (f*3+k*5)%7==2 else glass
            wall_quad(mat,x,x+1.5,z1+.015,h0,h1)
            x+=2.6; k+=1
    # The door at the end of the exit's corridor.
    a,b=door; out=.3
    face(door_mat,[(x0-out,-a-.015,.05),(x0,-a-.015,.05),(x0,-a-.015,1.38),(x0-out,-a-.015,1.38)],1,(0,-1,0))
    floor_quad(door_mat,x0-out,a,out,b-a,.055)
    # A parapet round the roof.
    box(trim,x0,z1-.12,far-x0,.12,h,h+.4)
    box(trim,x0,z0,far-x0,.12,h,h+.4)
    box(trim,x0,z0,.12,z1-z0,h,h+.4)

def floor_quad(mat,x,z,w,d,h,scale=1.0):
    face(mat,[(x,-z-d,h),(x+w,-z-d,h),(x+w,-z,h),(x,-z,h)],scale,normal=(0,0,1))

def decal(mat,x0,x1,z,h0,h1,u0=0.0,u1=1.0):
    """Camera-facing picture with its whole image (or a horizontal slice of an atlas)."""
    g=geo.setdefault(mat,([],[],[])); base=len(g[0])
    g[0].extend([(x0,-z,h0),(x1,-z,h0),(x1,-z,h1),(x0,-z,h1)])
    g[1].append(tuple(range(base,base+4))); g[2].extend([(u0,0),(u1,0),(u1,1),(u0,1)])

def poster(index,x0,z,h0,h1):
    decal('posters',x0,x0+.6,z,h0,h1,index*.25,index*.25+.25)

texts=[]
def text(mat,value,x,z,h,size,flat=False,align='CENTER'):
    """Font converted to polygons, standing on a wall facing the camera or lying flat."""
    curve=bpy.data.curves.new('Lapa_text','FONT'); curve.body=value; curve.align_x=align; curve.size=size
    ob=bpy.data.objects.new('Lapa_text',curve); scene.collection.objects.link(ob)
    ob.location=(x,-z,h); ob.rotation_euler=(0 if flat else math.pi/2,0,0)
    layer=scene.view_layers[0]; layer.update()
    ev=ob.evaluated_get(layer.depsgraph); mesh=ev.to_mesh()
    want=(0,0,1) if flat else (0,-1,0)
    for poly in mesh.polygons:
        face(mat,[tuple(ob.matrix_world@mesh.vertices[i].co) for i in poly.vertices],1.0,want)
    ev.to_mesh_clear(); bpy.data.objects.remove(ob); bpy.data.curves.remove(curve)

# ---------------------------------------------------------------- furniture
def bottle(cx,cz,h,kind=0):
    mat=['amber','bottle_green','bottle_clear','amber'][kind%4]
    cyl(mat,cx,cz,.035,h,h+.17,6)
    cyl(mat,cx,cz,.035,h+.17,h+.21,6,r1=.014,top=False)
    cyl(mat,cx,cz,.014,h+.21,h+.27,4)
    if kind%2==0: cyl('label',cx,cz,.037,h+.05,h+.11,6,top=False)

def glass(cx,cz,h,full=True):
    cyl('glass',cx,cz,.033,h,h+.11,6)
    if full: cyl('amber',cx,cz,.028,h,h+.08,6); cyl('foam',cx,cz,.03,h+.08,h+.1,6)

def chair(cx,cz,facing,mat='wood'):
    """Boteco chair at (cx,cz) whose seat faces `facing` radians."""
    yaw=facing
    obox(mat,cx,cz,.42,.42,.44,.49,yaw,.6)
    for f,r in ((.17,.17),(.17,-.17),(-.17,.17),(-.17,-.17)):
        px,pz=local(cx,cz,yaw,f,r); obox(mat,px,pz,.045,.045,0,.44,yaw)
    for r in (.17,-.17):
        px,pz=local(cx,cz,yaw,-.19,r); obox(mat,px,pz,.045,.045,.49,.98,yaw)
    for h in (.66,.88):
        px,pz=local(cx,cz,yaw,-.19,0); obox(mat,px,pz,.05,.4,h,h+.07,yaw,.6)

def table_square(x,z,w,d,seed):
    """Wooden boteco table under a gingham cloth, two chairs, beer and petiscos."""
    cx,cz=x+w/2,z+d/2
    for sx in (-.42,.42):
        for sz in (-.32,.32): box('wood',cx+sx-.025,cz+sz-.025,.05,.05,0,.72)
    box('wood',cx-.5,cz-.4,1.0,.8,.72,.76,.6)
    box('gingham',cx-.56,cz-.46,1.12,.92,.76,.775,.5)
    for side in (-1,1):
        wall_quad('gingham',cx-.56,cx+.56,cz+side*.46,.58,.775,.5,side)
    chair(cx-.79,cz+(.06 if seed%2 else -.04),0.0+(.12 if seed%2 else 0))
    chair(cx+.79,cz,math.pi-(.18 if seed==2 else 0))
    h=.775
    bottle(cx-.18,cz-.2,h,seed); bottle(cx+.24,cz+.17,h,seed+1)
    glass(cx-.05,cz-.25,h); glass(cx+.2,cz-.12,h,seed%2==0); glass(cx-.28,cz+.15,h)
    cyl('white',cx+.04,cz+.08,.13,h,h+.015,8)
    for i in range(5): obox('food',cx+.04+math.cos(i*1.3)*.06,cz+.08+math.sin(i*1.3)*.06,.05,.035,h+.015,h+.045,i*.7)
    cyl('dark',cx+.33,cz-.27,.055,h,h+.025,6)
    obox('metal',cx-.36,cz+.29,.1,.06,h,h+.1,.3)

def table_round(x,z,w,d,seed):
    """Marble bistro table on a cast iron pedestal, three bentwood chairs, caipirinhas."""
    cx,cz=x+w/2,z+d/2
    cyl('iron',cx,cz,.24,0,.04,8); cyl('iron',cx,cz,.045,.04,.7,6); cyl('iron',cx,cz,.16,.68,.72,8)
    cyl('iron',cx,cz,.47,.72,.74,8,phase=math.pi/8); cyl('marble',cx,cz,.45,.74,.765,8,phase=math.pi/8,scale=.7)
    chair(cx-.8,cz+.05,0.05,'iron' if seed%2 else 'wood')
    chair(cx+.8,cz-.05,math.pi+.1,'wood')
    chair(cx+.1,cz-.52,math.pi/2,'wood' if seed%2 else 'iron')
    h=.765
    for i,(gx,gz) in enumerate(((-.18,.12),(.16,.18),(.05,-.2))):
        cyl('glass',cx+gx,cz+gz,.036,h,h+.09,6); cyl('lime',cx+gx,cz+gz,.03,h,h+.04,6)
        obox('lime',cx+gx,cz+gz,.03,.03,h+.04,h+.07,i)
    cyl('red_paint',cx-.22,cz-.14,.055,h,h+.19,6); cyl('amber',cx-.22,cz-.14,.035,h+.19,h+.27,6,r1=.015)
    cyl('white',cx+.18,cz-.04,.11,h,h+.015,8)
    for i in range(3): obox('yellow_paint',cx+.18+(i-1)*.06,cz-.04,.05,.12,h+.015,h+.05,.4)
    cyl('white',cx-.02,cz+.02,.02,h,h+.08,4)

def stool(cx,cz):
    cyl('iron',cx,cz,.16,0,.025,6); cyl('iron',cx,cz,.035,.025,.7,4)
    cyl('brass',cx,cz,.13,.3,.33,6,top=False)
    cyl('leather',cx,cz,.18,.7,.78,8,scale=.4)

def build_bar(long_rect,short_rect):
    lx,lz,lw,ld=long_rect; sx,sz,sw,sd=short_rect
    front=lx+lw-.4          # customer edge of the long counter; stools sit inside the solid
    # Back bar: cabinet and shelves in the narrow strip against the side wall.
    box('wood',-11.8,-7.3,.45,sz-(-7.3),0,.95,.6)
    box('marble',-11.82,-7.3,.49,sz-(-7.3),.95,.99,.7)
    # One shelf of bottles: everything against the side wall stays under the 1.4 m cut.
    for h in (1.11,):
        box('wood',-11.8,-7.3,.3,sz-(-7.3),h-.04,h,.6)
        z=-7.15; k=0
        while z<sz-.1:
            bottle(-11.66+(.06 if k%3==1 else 0),z,h,k*7%5); z+=.17+.03*(k%3); k+=1
    for z in (-6.9,-4.2,-1.5):
        box('wood',-11.8,z,.3,.06,.99,1.38)
    # Bartender aisle with rubber matting.
    floor_quad('rubber',-11.35,lz,front-.25-(-11.35),sz-lz,.055,.5)
    # Long counter: wooden body, azulejo kick, marble top with a brass foot rail.
    box('wood',front-.6,lz,.6,ld-.4,0,1.04,.6)
    box('azulejo',front-.02,lz+.02,.03,ld-.44,.04,.32,.5)
    box('marble',front-.68,lz-.05,.8,ld-.35,1.04,1.1,.7)
    box('brass',front+.15,lz+.1,.04,ld-.6,.18,.22)
    for i in range(6): stool(front+.3,lz+.55+i*1.08)
    # Short counter closing the bar, with the beer chest and the salgado display.
    box('wood',sx+.6,sz,sw-.6,.6,0,1.04,.6)
    box('marble',sx+.55,sz-.06,sw-.5,.7,1.04,1.1,.7)
    box('white',sx+1.8,sz+.62,1.7,.24,0,.9); box('red_paint',sx+1.8,sz+.62,1.7,.24,.9,.95)
    decal('red_paint',sx+1.9,sx+3.4,sz+.87,.5,.8)
    text('white','CERVEJA',sx+2.65,sz+.88,.58,.18)
    h=1.1
    # Chopeira tower with three taps and a drip tray.
    box('metal',front-.55,-2.3,.35,.5,h,h+.02)
    box('metal',front-.5,-2.2,.2,.3,h,h+.42)
    for i in range(3): box('brass',front-.32,-2.15+i*.1,.1,.03,h+.25,h+.36)
    # Cash register where the two counters meet.
    obox('cream',sx+1.0,sz+.3,.4,.36,h,h+.18,.4); obox('dark',sx+1.0,sz+.3,.3,.28,h+.18,h+.3,.4)
    # Salgado display case: glass box with coxinhas and pastéis.
    ex,ez=sx+2.6,sz+.08
    box('metal',ex,ez,.9,.42,h,h+.04)
    for i in range(6): cyl('food',ex+.12+i*.13,ez+.12,.045,h+.04,h+.13,5,r1=.0)
    for i in range(4): obox('yellow_paint',ex+.18+i*.18,ez+.3,.14,.08,h+.04,h+.075,.2)
    box('glass',ex,ez,.9,.42,h+.04,h+.34)
    # Glasses, limes and a cachaça row along the long counter.
    for i in range(5): glass(front-.32,lz+.5+i*.14,h,False)
    cyl('white',front-.35,-3.9,.12,h,h+.06,8)
    for i in range(5): cyl('lime',front-.35+math.cos(i)*.05,-3.9+math.sin(i)*.05,.035,h+.04,h+.09,5)
    for i in range(4): bottle(front-.42,-0.9+i*.12,h,i+1)

def build_booth(x,z,w,d):
    """Single-sided banquette facing the street, a jukebox and a potted palm."""
    # Jukebox at the left end.
    jx=x+.05
    box('wood',jx,z+.15,.65,.55,0,.95,.6)
    box('jukebox_glow',jx+.08,z+.69,.49,.02,.25,.85)
    for i,(ww,hh) in enumerate(((.65,.95),(.55,1.08),(.4,1.18))):
        box('wood' if i%2==0 else 'brass',jx+(.65-ww)/2,z+.15,ww,.55,hh-.13 if i else .95,hh)
    decal('chalk',jx+.12,jx+.53,z+.715,.12,.24)
    bays=[(x+.75,2.5),(x+3.25,2.5)]
    for bx,bw in bays:
        box('wood',bx,z,bw,.18,0,1.25,.6)                  # backrest frame
        box('leather',bx+.06,z+.18,bw-.12,.12,.48,1.15,.35)  # tufted back cushion
        box('wood',bx,z+.18,bw,.52,0,.42,.6)                # seat base
        box('leather',bx+.04,z+.2,bw-.08,.48,.42,.52,.35)
        for side in (bx,bx+bw-.06): box('wood',side,z,.06,.72,0,1.0)  # dividers
        # Two small tables in front of the seat.
        for tx in (bx+.35,bx+1.35):
            box('iron',tx+.38,z+.98,.05,.05,0,.72); box('wood',tx,z+.78,.8,.4,.72,.76,.6)
            box('marble',tx+.02,z+.8,.76,.36,.76,.775,.7)
            bottle(tx+.2,z+.95,.775,int(tx*3)); glass(tx+.45,z+.9,.775); glass(tx+.6,z+1.03,.775,False)
            cyl('cream',tx+.68,z+.88,.03,.775,.86,5)
            cyl('bulb',tx+.68,z+.88,.018,.86,.9,4)
    # Potted palm at the right end.
    px,pz=x+w-.2,z+.6
    cyl('red_paint',px,pz,.17,0,.42,6,r1=.2); cyl('soil',px,pz,.18,.42,.43,6)
    cyl('wood',px,pz,.03,.43,.9,4)
    for i in range(6):
        a=i*math.tau/6; lx,lz=px+math.cos(a)*.22,pz+math.sin(a)*.22
        obox('leaf',lx,lz,.5,.12,.88-i%2*.08,.92-i%2*.08,a)

def build_stove(x,z,w,d):
    # Six-burner industrial range, a fryer and a steel bench with pots.
    box('metal',x,z,2.4,d,0,.86,.5); box('black',x+.02,z+.02,2.36,d-.04,.86,.9)
    for i in range(3):
        for j in range(2):
            bx,bz=x+.4+i*.8,z+.3+j*.5
            cyl('iron',bx,bz,.17,.9,.93,6,top=False)
            obox('iron',bx,bz,.36,.04,.93,.95,0); obox('iron',bx,bz,.04,.36,.93,.95,0)
    cyl('pot',x+.4,z+.3,.16,.95,1.18,8); cyl('dark',x+.4,z+.3,.14,1.18,1.181,8)
    cyl('pot',x+1.2,z+.8,.2,.95,1.05,8); cyl('black',x+2.0,z+.3,.17,.95,.99,8)
    obox('wood',x+2.25,z+.3,.3,.04,.97,1.0,0)
    for i in range(6): cyl('black',x+.25+i*.38,z+d-.03,.03,.6,.66,4)
    box('metal',x+2.45,z,.8,d,0,.9,.5); box('food',x+2.52,z+.08,.66,.45,.9,.92)
    box('glass',x+2.52,z+.6,.66,.4,.9,.92)
    box('metal',x+3.3,z,w-3.3,d,0,.9,.5); box('metal',x+3.3,z,w-3.3,d,.9,.94,.5)
    for i in range(3): cyl('pot',x+3.6+i*.6,z+.5,.14,.94,1.2,6)
    box('metal',x,z-.6,w,.08,1.55,1.6)                      # pot shelf on the back wall
    for i in range(7): cyl('pot' if i%2 else 'red_paint',x+.3+i*.75,z-.56,.1,1.6,1.75,6)

def build_sink(x,z,w,d):
    box('metal',x,z,w,d,0,.88,.5); box('metal',x-.02,z-.02,w+.04,d+.04,.88,.92,.5)
    for j in range(2):
        sz=z+.8+j*1.3
        box('dark',x+.15,sz,w-.3,1.0,.9,.921)
        cyl('metal',x+w-.12,sz+.5,.03,.92,1.2,4); obox('metal',x+w-.25,sz+.5,.26,.04,1.18,1.22,0)
    for i in range(6): cyl('white',x+.45,z+3.6+i*.12,.13,.93,.96,8)
    for i in range(4): glass(x+.3+(i%2)*.25,z+4.6+(i//2)*.25,.92,False)

def build_prep(x,z,w,d):
    for sx in (.08,w-.12):
        for sz in (.08,d-.12): box('metal',x+sx,z+sz,.05,.05,0,.9)
    box('metal',x+.05,z+.05,w-.1,d-.1,.25,.29,.5)
    box('metal',x,z,w,d,.9,.94,.5)
    box('wood',x+.4,z+.25,.7,.45,.94,.97,.6)
    obox('metal',x+.8,z+.4,.3,.04,.97,.98,.3)
    for i in range(5): obox('cream',x+.55+(i%3)*.12,z+.6+(i//3)*.08,.06,.06,.97,1.02,i)
    for i in range(3): cyl('white',x+1.6+i*.45,z+.55,.17,.94,1.04,8,r1=.2); cyl('food' if i!=1 else 'lime',x+1.6+i*.45,z+.55,.15,1.0,1.03,8)
    obox('crate',x+w-.35,z+.5,.4,.3,.29,.6,0)

def build_crates(x,z,w,d):
    """Stacks of yellow beer crates, the top layer showing bottle caps."""
    cols=max(1,int(w/.5)); rows=max(1,int(d/.38))
    for i in range(cols):
        for j in range(rows):
            cx,cz=x+(i+.5)*w/cols,z+(j+.5)*d/rows
            layers=3 if (i+j)%3 else 2
            for k in range(layers):
                obox('crate',cx,cz,w/cols-.04,d/rows-.04,k*.4,k*.4+.38,.02*((i+j+k)%3-1),.5)
            for a in range(3):
                for b in range(2):
                    cyl('amber',cx-.12+a*.12,cz-.07+b*.14,.03,layers*.4-.15,layers*.4+.04,5)

def build_planter(x,z,w,d):
    """Mureta-jardineira between the front lounge and the salão: tiled masonry with a marble cap
    and a soil bed. Every plant stays under 1.35 m so nobody hides behind the leaves."""
    box('plaster',x,z,w,d,0,.85,1.2)
    for fz,t in ((z-.012,.012),(z+d,.012)): box('azulejo',x+.03,fz,w-.06,t,.05,.7,.5)
    box('marble',x-.02,z-.02,w+.04,d+.04,.85,.9,.7)
    box('soil',x+.06,z+.06,w-.12,d-.12,.9,.905,sides=False)
    box('leaf',x+.5,z+.08,w-1.0,d-.16,.9,.98,.6)  # low bed of foliage
    # Bushy rosettes along the bed: short leaves radiating from each centre, uneven heights.
    for i in range(int((w-1.0)/.45)):
        cx,cz=x+.72+i*.45,z+d/2+((i*7)%3-1)*.04
        for k in range(7):
            a=k*math.tau/7+i*.9; r=.11+(k%2)*.04
            obox('leaf',cx+math.cos(a)*r,cz+math.sin(a)*r*.6,.24,.08,.96,1.04+((i+k)%3)*.05,a)
    for px in (x+.25,x+w-.25):  # terracotta pots at each end
        cyl('red_paint',px,z+d/2,.16,.9,1.12,6,r1=.2); cyl('soil',px,z+d/2,.17,1.12,1.13,6)
        for k in range(7):
            a=k*math.tau/7+.3
            obox('leaf',px+math.cos(a)*.13,z+d/2+math.sin(a)*.1,.26,.08,1.1,1.2+(k%3)*.05,a)

def build_kegs(x,z,w,d):
    for i in range(3):
        cx=x+.27+i*.5
        cyl('metal',cx,z+.48,.24,0,.62,8); cyl('dark',cx,z+.48,.25,.6,.64,8,top=False)
        cyl('iron',cx,z+.48,.06,.64,.72,4)
    cyl('red_paint',x+w-.15,z+.3,.12,0,.9,6); cyl('iron',x+w-.15,z+.3,.05,.9,1.0,4)

# ---------------------------------------------------------------- the level
def room(x,z):
    if 4.05<x<11.55 and -7.3<z<2.3: return 'kitchen'
    if 4.05<x<11.55 and 2.3<z<7.7: return 'storage'
    if -11.8<x<11.55 and -7.3<z<7.7: return 'inside'
    return 'outside'

def wall_pieces(solids):
    """Walls joined like a SketchUp model: butt joints that meet at the corner vertices, never
    overlapping. Taller walls are laid first and own their corners (the back wall runs full
    width); every later wall is trimmed to stop at the faces already built. Returns
    (x,z,w,d,h) pieces; the collision rectangles in level.json are left as they are."""
    def subtract(r,o):
        x0,z0,x1,z1=r; a0,b0,a1,b1=o
        if a0>=x1-1e-6 or a1<=x0+1e-6 or b0>=z1-1e-6 or b1<=z0+1e-6: return [r]
        out=[]
        if z0<b0: out.append((x0,z0,x1,b0))
        if b1<z1: out.append((x0,b1,x1,z1))
        m0,m1=max(z0,b0),min(z1,b1)
        if x0<a0: out.append((x0,m0,a0,m1))
        if a1<x1: out.append((a1,m0,x1,m1))
        return [p for p in out if p[2]-p[0]>1e-4 and p[3]-p[1]>1e-4]
    placed=[]; pieces=[]
    for s in sorted([s for s in solids if s['type']=='wall'],key=lambda s:-s['h']):
        x,z,w,d=s['r']; rect=(x,z,x+w,z+d); parts=[rect]
        for o in placed: parts=[p for q in parts for p in subtract(q,o)]
        pieces+=[(x0,z0,x1-x0,z1-z0,s['h']) for x0,z0,x1,z1 in parts]
        placed.append(rect)
    return pieces

def build_wall(x,z,w,d,h,walls=()):
    box('plaster',x,z,w,d,0,h,1.2)
    box('cap',x-.01,z-.01,w+.02,d+.02,h,h+.03,sides=False)
    # Each face gets a skin chosen by the room it looks into, unless another wall is butted there.
    for nx,nz in ((1,0),(-1,0),(0,1),(0,-1)):
        px,pz=x+w/2+nx*(w/2+.3),z+d/2+nz*(d/2+.3)
        qx,qz=x+w/2+nx*(w/2+.02),z+d/2+nz*(d/2+.02)
        if any(a<=qx<=a+b and c<=qz<=c+e for a,c,b,e,_ in walls): continue
        kind=room(px,pz)
        mat,top={'kitchen':('white_tile',min(h,1.5)),'storage':('concrete',.5),'inside':('azulejo',min(h,1.0)),'outside':('green_paint',.35)}[kind]
        t=.012
        if nx: box(mat,x+(w if nx>0 else -t),z,t,d,0,top,.5)
        else: box(mat,x,z+(d if nz>0 else -t),w,t,0,top,.5)
        if kind=='inside' and h>1.1:  # wooden chair rail on top of the tiles
            if nx: box('wood',x+(w if nx>0 else -.03),z,.03,d,top,top+.06)
            else: box('wood',x,z+(d if nz>0 else -.03),w,.03,top,top+.06)

def build():
    # Ground: asphalt street, plain stone pavement, side passages and interior floors.
    floor_quad('asphalt',-30,-26,60,52,-.06,2.4)
    floor_quad('pedra',-30,8.15,60,2.5,.07,1.6)
    box('concrete',-30,10.65,60,.18,-.06,.09,.6,sides=False)
    wall_quad('concrete',-30,30,10.83,-.06,.09)
    floor_quad('concrete',-15.3,-9.6,3.05,17.75,.03,1.4)
    floor_quad('concrete',12.0,-9.6,3.3,17.75,.03,1.4)
    floor_quad('pedra',-15.3,-11.2,30.6,1.6,.03,1.6)
    floor_quad('vermelhao',-11.8,-7.3,15.4,10.5,.04,1.6)
    floor_quad('vermelhao',-6.15,3.2,9.75,4.5,.04,1.6)
    floor_quad('granilite',-11.8,3.2,5.65,4.5,.04,1.2)
    floor_quad('cimento',4.05,-7.3,7.5,9.6,.04,1.6)
    floor_quad('concrete',4.05,2.3,7.5,5.4,.04,1.2)
    floor_quad('granito',3.6,-7.3,.45,15.0,.04,.8)        # granite sills under the door gaps
    floor_quad('concrete',11.55,-7.3,.45,15.45,.035,1.4)
    floor_quad('granito',-10.075,7.7,2.325,.45,.045,.8)
    floor_quad('rubber',-9.6,6.6,1.4,.8,.05,.5)   # doormat
    # Walls and collision furniture.
    walls=wall_pieces(layout['solids'])
    for x,z,w,d,h in walls: build_wall(x,z,w,d,h,walls)
    tables=0
    for s in layout['solids']:
        x,z,w,d=s['r']; kind=s['type']
        if kind=='table':
            (table_round if tables%2 else table_square)(x,z,w,d,tables); tables+=1
        elif kind=='booth': build_booth(x,z,w,d)
        elif kind=='planter': build_planter(x,z,w,d)
        elif kind=='stove': build_stove(x,z,w,d)
        elif kind=='sink': build_sink(x,z,w,d)
        elif kind=='prep': build_prep(x,z,w,d)
        elif kind=='crate': (build_crates if d>w else build_kegs)(x,z,w,d)
    bars=[s['r'] for s in layout['solids'] if s['type']=='bar']
    build_bar(*sorted(bars,key=lambda r:-r[3]))
    decorate_inside()
    build_outside()

def decorate_inside():
    back=-7.29  # just in front of the back wall's inner face
    # Neon sign above the tables, framed photos, posters, a clock and a television.
    box('dark',-5.0,-7.3,4.6,.02,1.55,2.4)
    text('neon_pink','BAR DO ARCO',-2.7,back+.03,1.75,.5)
    text('neon_cyan','desde 1958',-2.7,back+.03,1.58,.16)
    for index,px in enumerate((-8.6,-7.7,0.6,1.4)): poster(index,px,back,1.08,2.1)
    decal('dark',2.48,2.92,back+.01,1.6,2.04); decal('white',2.52,2.88,back+.02,1.64,2.0)
    decal('black',2.69,2.71,back+.03,1.8,1.97); decal('black',2.69,2.84,back+.03,1.81,1.83)
    box('iron',-9.4,-7.3,.08,.25,2.0,2.06)
    box('black',-9.85,-7.3,.95,.12,1.65,2.25); decal('tv_glow',-9.8,-8.95,-7.17,1.7,2.2)
    text('neon_cyan','CHOPP',-10.6,back+.03,1.6,.32)
    for px in (-6.6,-0.1,3.2):
        decal('wood',px,px+.35,back+.005,1.3,1.75); decal('cream',px+.04,px+.31,back+.015,1.35,1.7)
    # Wall sconces with warm bulbs.
    for px in (-7.2,0.35):
        box('brass',px,-7.3,.12,.12,1.9,1.94); cyl('bulb',px+.06,-7.24,.06,1.94,2.04,4)
    # Kitchen: neon sign above the pot shelf and an extractor fan.
    text('neon_pink','COZINHA',7.8,back+.03,2.0,.28)
    decal('dark',5.2,5.8,back+.005,1.85,2.35)
    for i in range(5): decal('iron',5.24,5.76,back+.015,1.9+i*.1,1.93+i*.1)
    # Vestibule: chalkboard menu and a samba poster on the partition facing the door.
    decal('chalk',-11.7,-10.3,3.625,.45,1.3)
    text('cream','CARDÁPIO',-11.0,3.64,1.12,.12)
    poster(3,-7.6,3.625,.45,1.3)
    # Storage: steel shelving with boxes against the partition facing the camera.
    for h in (.3,.75,1.2):
        box('metal',7.2,2.7,2.7,.32,h,h+.03)
        for i in range(5): obox('cream' if i%2 else 'food',7.5+i*.52,2.86,.36,.26,h+.03,h+.3,.05*(i-2))
    for sx in (7.2,9.86): box('metal',sx,2.7,.04,.32,0,1.35)

def sobrado(x0,x1,front,back,height,paint,doors=True,side=False,base=0.0):
    """Neighbouring sobrado: painted facade with shutters and balconies, tiled gable roof. `base`
    lifts the whole house, for rows climbing a hillside.
    side: one of the sobrados framing the level. It wears its own side_* materials and a graphic
    version of the facade (shutters without mullions, balconies as slab and rail), read as a mass
    with openings rather than a list of details."""
    m=(lambda name:'side_'+name) if side else (lambda name:name)
    b=base
    box(m(paint),x0,back,x1-x0,front-back,b,b+height,1.4)
    ridge=b+height+1.4; mid=(back+front)/2
    for z0,z1 in ((back-.3,mid),(front+.3,mid)):
        face(m('roof'),[(x0-.2,-z0,b+height-.1),(x1+.2,-z0,b+height-.1),(x1+.2,-z1,ridge),(x0-.2,-z1,ridge)],1.2,(0,1 if z0<z1 else -1,1))
    box(m('cream'),x0-.05,front,x1-x0+.1,.08,b+height-.25,b+height)
    n=max(1,int((x1-x0)/2.2))
    for i in range(n):
        wx=x0+(x1-x0)*(i+.5)/n
        openings=[(.2,2.2),(height-2.4,height-.8)] if doors else [(height-2.4,height-.8)]
        for level in openings:
            wall_quad(m('cream'),wx-.6,wx+.6,front+.02,b+level[0]-.1,b+level[1]+.12,1,1)
            wall_quad(m('teal' if paint!='facade_green' else 'red_paint'),wx-.5,wx+.5,front+.03,b+level[0],b+level[1],1,1)
            if not side: wall_quad('dark',wx-.03,wx+.03,front+.04,b+level[0],b+level[1],1,1)
        box(m('iron'),wx-.75,front,1.5,.45,b+height-2.45,b+height-2.38)
        if not side:
            for k in range(7): box('iron',wx-.72+k*.24,front+.42,.02,.02,b+height-2.38,b+height-1.6)
        box(m('iron'),wx-.75,front+.42,1.5,.03,b+height-1.62,b+height-1.58)

def build_outside():
    # Front facade of the bar: painted name board and festive string lights.
    box('green_paint',-5.0,8.15,6.0,.04,.3,1.05)
    text('cream','BAR DO ARCO',-2.0,8.2,.55,.34)
    text('yellow_paint','PETISCOS  •  CHOPP  •  SAMBA',-2.0,8.2,.38,.11)
    bulbs=['bulb','bulb_red','bulb_green','bulb','bulb_blue']
    for seg,(x0,x1) in enumerate(((-12.25,-10.075),(-7.75,11.9))):
        n=int((x1-x0)/.5)
        for i in range(n+1):
            x=x0+(x1-x0)*i/n
            sag=.12*math.sin(math.pi*((x-x0)%2.0)/2.0)   # hangs just above the 1.4 m wall cut
            box('black',x-.25,7.9,.5,.015,1.63-sag,1.645-sag)
            cyl(bulbs[(i+seg)%len(bulbs)],x,7.92,.05,1.55-sag,1.63-sag,4)
    # Door frame at the entrance.
    for px in (-10.15,-7.75): box('wood',px,7.65,.07,.55,0,1.3)
    # Street lamps, a parked Fusca, trash bags and a dumpster outside the playable area.
    for lx in (-13.6,-3.0,7.5):
        cyl('iron',lx,10.95,.07,.09,2.9,6); cyl('iron',lx,10.95,.14,.09,.4,6)
        box('iron',lx-.04,10.95-.5,.08,.5,2.85,2.9); cyl('bulb',lx,10.45,.12,2.45,2.75,4); cyl('iron',lx,10.45,.17,2.75,2.85,4,r1=.02)
    fx,fz=3.0,12.6
    box('car_blue',fx-1.95,fz-.8,3.9,1.6,.3,.85,.8)
    obox('car_blue',fx-.1,fz,2.1,1.45,.85,1.25,0)
    obox('screen',fx-.12,fz,1.9,1.47,.92,1.18,0)
    obox('car_blue',fx-.1,fz,1.6,1.3,1.25,1.42,0)
    for wx in (-1.25,1.25):
        for wz in (-.75,.75): obox('tire',fx+wx,fz+wz,.6,.22,0,.55,0)
    box('white',fx-2.0,fz-.75,.06,1.5,.32,.45); box('white',fx+1.94,fz-.75,.06,1.5,.32,.45)
    # Trash bags hug the alley walls.
    for i,(bx,bz) in enumerate(((15.05,6.9),(15.1,7.5),(15.05,-1.0),(-15.05,-2.4),(-15.1,-1.7))):
        obox('black',bx,bz,.45,.42,0,.4,i*.6); cyl('black',bx,bz,.11,.4,.52,4)
    # One whitewashed muro closes the back of the block from side to side; both alleys end at it
    # and the graffiti faces the camera at the right one. A whole wall, not a cut one: no black cap.
    box('whitewash',-27,-10.4,54,.8,0,3.2,1.2)
    decal('graffiti',11.6,15.7,-9.59,.1,2.9)
    # The exit is not painted on the ground: scripts/exit_marker.gd lights it up once the bar is clear.
    # Neighbouring sobrados: painted facades with windows and balconies, tiled gable roofs.
    sobrado(-26,-19.5,8.15,-9.6,5.2,'facade_blue',side=True)
    sobrado(-19.5,-15.4,8.15,-9.6,4.6,'facade_yellow',side=True)
    sobrado(15.4,20.0,8.15,-9.6,4.8,'facade_pink',side=True)
    sobrado(20.0,26.0,8.15,-9.6,5.6,'facade_green',side=True)
    # The Arcos and everything behind them stand across the street, well back from the bar: far
    # enough to breathe, close enough that the first tier still shows above the back muro.
    dz=-2.3
    # Behind the Arcos: more houses and the Selarón steps climbing toward Santa Teresa.
    for i,(x0,x1,h,p) in enumerate(((-11,-5,5.0,'facade_pink'),(-5,1,6.2,'ochre'),(1,7,5.4,'facade_blue'),(7,13,6.0,'facade_yellow'),(13,19,5.0,'facade_green'),(19,26,5.6,'facade_pink'))):
        sobrado(x0,x1,-14.0+dz,-22.0+dz,h,p,doors=False)
    for k in range(14):
        z=-13.6+dz-k*.6; h=k*.3
        box('whitewash',-19.5,z-.6,6.5,.6,0,h+.3,1)
        wall_quad('mosaic',-19.5,-13.0,z,h,h+.3,.6,1)
    box('mosaic',-20.1,-22.0+dz,.6,8.4,0,4.4,.6); box('mosaic',-13.0,-22.0+dz,.6,8.4,0,4.4,.6)
    # Arcos da Lapa: two tiers of whitewashed arches with the yellow bonde on top.
    def arcade(x0,x1,z0,z1,base,spring,radius,top,bay):
        n=int((x1-x0)/bay)
        for i in range(n):
            cx=x0+bay*(i+.5)
            pts=[(cx+math.cos(math.pi*j/8)*radius,spring+math.sin(math.pi*j/8)*radius) for j in range(9)]
            for zz,sign in ((z1,1),(z0,-1)):
                for j in range(8):
                    (ax,ah),(bx,bh)=pts[j],pts[j+1]
                    face('arcos',[(ax,-zz,ah),(bx,-zz,bh),(bx,-zz,top),(ax,-zz,top)],1.2,(0,-sign,0))
                for side,(px,ph) in ((-1,pts[-1]),(1,pts[0])):
                    edge=cx+side*bay/2
                    face('arcos',[(px,-zz,base),(edge,-zz,base),(edge,-zz,top),(px,-zz,top)],1.2,(0,-sign,0))
            for j in range(8):
                (ax,ah),(bx,bh)=pts[j],pts[j+1]
                inward=(cx-(ax+bx)/2,0,spring-(ah+bh)/2)
                face('arcos',[(ax,-z0,ah),(ax,-z1,ah),(bx,-z1,bh),(bx,-z0,bh)],1.2,inward)
            for px in (cx-radius,cx+radius):
                face('arcos',[(px,-z0,base),(px,-z1,base),(px,-z1,spring),(px,-z0,spring)],1.2,(1 if px<cx else -1,0,0))
            box('arcos',cx-bay/2,z0-.05,bay,z1-z0+.1,top-.12,top,1)
    arcade(-27,27,-12.3+dz,-11.5+dz,0,2.5,1.15,4.3,3.0)
    arcade(-27,27,-12.2+dz,-11.6+dz,4.3,5.1,.8,6.6,3.0)
    box('arcos',-27,-12.35+dz,54,.12,6.6,7.0); box('arcos',-27,-11.57+dz,54,.12,6.6,7.0)
    box('iron',-27,-12.1+dz,54,.05,6.6,6.66,sides=False); box('iron',-27,-11.85+dz,54,.05,6.6,6.66,sides=False)
    bx=5.5
    box('bonde',bx,-12.25+dz,3.4,.75,6.75,7.75,.6)
    for i in range(6): wall_quad('screen',bx+.2+i*.52,bx+.6+i*.52,-11.49+dz,7.2,7.6,1,1)
    box('dark',bx-.1,-12.3+dz,3.6,.85,7.75,7.82); box('iron',bx+1.5,-11.95+dz,.04,.04,7.82,8.4)
    box('red_paint',bx,-12.25+dz,3.4,.75,6.66,6.75,.6)

# ---------------------------------------------------------------- assemble and export
# The helpers above double as a small kit: tools/build_intro.py imports this file as a module.
created_meshes=[]
def assemble(target):
    """Turn the accumulated faces into one object per material in `target`; returns triangles."""
    triangles=0
    for name,(verts,faces,uvs) in geo.items():
        me=bpy.data.meshes.new('Lapa_'+name); me.from_pydata(verts,[],faces); created_meshes.append(me)
        layer=me.uv_layers.new(name='UVMap')
        for i,loop in enumerate(me.loops): layer.data[i].uv=uvs[loop.vertex_index]
        me.materials.append(materials[name])
        me.validate(); me.update()
        triangles+=sum(len(p.vertices)-2 for p in me.polygons)
        target.collection.objects.link(bpy.data.objects.new('Lapa_'+name,me))
    geo.clear()
    return triangles

def export_glb(path):
    os.makedirs(os.path.dirname(path),exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=path,export_format='GLB',use_active_scene=True,export_animations=False,export_lights=False,export_cameras=False)

@contextlib.contextmanager
def workspace(name):
    """Temporary scene; afterwards the open Blender file is left exactly as it was."""
    global scene
    # Also runs headless (blender -b), where there is no window to switch.
    windows=bpy.context.window_manager.windows
    win=bpy.context.window or (windows[0] if len(windows) else None)
    previous=win.scene if win else None
    scene=bpy.data.scenes.new(name)
    override={'scene':scene,'view_layer':scene.view_layers[0]}
    if win:
        win.scene=scene
        override['window']=win
    try:
        with bpy.context.temp_override(**override):
            yield scene
    finally:
        if win: win.scene=previous
        for ob in list(scene.objects): bpy.data.objects.remove(ob)
        bpy.data.scenes.remove(scene)
        for me in created_meshes: bpy.data.meshes.remove(me)
        for m in materials.values(): bpy.data.materials.remove(m)
        for img in images: bpy.data.images.remove(img)
        created_meshes.clear(); materials.clear(); images.clear(); geo.clear()

if __name__=='__main__':
    with workspace('Lapa_PSX') as scene:
        make_palette()
        build()
        triangles=assemble(scene)
        export_glb(os.path.join(ROOT,'assets/environment/lapa.glb'))
        bpy.data.libraries.write(os.path.join(ROOT,'tools/source/lapa.blend'),{scene},fake_user=True,compress=True)
        print('LAPA_READY',len(scene.objects),'meshes',triangles,'triangles',len(images),'textures')
