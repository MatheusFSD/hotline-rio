"""Santa Teresa, nights three and four, generated in Blender through the installed MCP bridge.

- ateliers.glb (assets/level_3.json): the Casarão das Artes, an old mansion of artists' studios
  on Rua Almirante Alexandrino, with a walled garden, its fountain and quaresmeiras. The way out
  climbs the stone steps behind the garden.
- bondes.glb (assets/level_4.json): the tram depot, a shed with two bondes shown cut at the walls'
  height like everything else, the workshop, the locker room and the foreman's office.

Both streets are cobbled with bonde rails; behind the block the hill climbs in casarões and
Atlantic forest. Imports build_lavradio.py (and through it build_environment.py) as a kit, so all
nights share one look. Collision comes from the level files: every interior piece is modeled
inside its solid's footprint. Runs headless or through the MCP bridge, in temporary scenes:
    blender -b --factory-startup --python "godot 3d/tools/build_santa_teresa.py"
"""
import bpy, os, math, json, importlib.util

HERE=os.path.dirname(os.path.abspath(__file__))
spec=importlib.util.spec_from_file_location('lavradio_kit',os.path.join(HERE,'build_lavradio.py'))
lav=importlib.util.module_from_spec(spec); spec.loader.exec_module(lav)
kit=lav.kit
ROOT=kit.ROOT
C,mul,mix,grain,hsh,vnoise=kit.C,kit.mul,kit.mix,kit.grain,kit.hsh,kit.vnoise
box,obox,cyl,face,local=kit.box,kit.obox,kit.cyl,kit.face,kit.local
wall_quad,floor_quad,decal,text,poster=kit.wall_quad,kit.floor_quad,kit.decal,kit.text,kit.poster
bottle,glass,chair,stool=kit.bottle,kit.glass,kit.chair,kit.stool

def load(name): return json.load(open(os.path.join(ROOT,'assets',name),encoding='utf-8'))

# ---------------------------------------------------------------- textures
def t_paralelepipedo(x,y):
    # Granite setts in staggered rows, dark joints: the cobbles of Santa Teresa's streets.
    row=y//6; ox=(x+(4 if row%2 else 0))%32
    c=mul(C('6f6c66'),.84+hsh(ox//8,row,60)*.3)
    if y%6==5 or ox%8==7: c=mul(c,.55)
    return grain(c,x,y,.07,61)

def t_ladrilho(x,y):
    # Ladrilho hidráulico: 16 px tiles with a border band and a four-petal flower.
    tx,ty=x%16,y%16
    # Tone on tone: from the camera it reads as one warm floor, up close as a tiled pattern.
    terracotta,cream,slate=C('a68a72'),C('c4b59a'),C('a39882')
    if tx==0 or ty==0: return C('978b78')
    dx,dy=abs(tx-8),abs(ty-8)
    if dx<=1 and dy<=1: c=terracotta
    elif (dx<=1 and dy<=5) or (dy<=1 and dx<=5): c=slate
    elif min(tx,16-tx)<=2 or min(ty,16-ty)<=2: c=terracotta if (tx+ty)%4<2 else slate
    else: c=cream
    return grain(c,x,y,.05,62)

def t_atelier_floor(x,y):
    # Cement floor of the studio, flecked with years of paint.
    c=kit.cement('8c8a84','74726c',seed=12)(x,y)
    for i,col in enumerate(('a0473d','b89a45','4f6f96')):
        cx,cy=hsh(i,1,63)*32,hsh(i,2,63)*32
        if math.hypot((x-cx+16)%32-16,((y-cy+16)%32-16)*1.6)<1.6: c=mix(c,C(col),.45)
    return c

def t_paintings(x,y):
    # Four 16x32 canvases: colour fields, a naive Santa Teresa hill, Volpi-like flags, a portrait.
    p=x//16; lx,ly=x%16,y
    if p==0:
        c=C('a3322b') if ly<12 else C('d98b2b') if ly<20 else C('3b2a4a')
    elif p==1:
        c=C('7fb3d5') if ly<14 else C('2e7d4f')
        if math.hypot(lx-11,ly-6)<2.6: c=C('f4d03f')
        if ly>=14 and (lx+ly)%5==0: c=C('e8dcc0')
        if 18<ly<22 and lx in (3,4,8,9): c=C('c0392b')
    elif p==2:
        c=C('e8dcc0')
        fy=(ly//6)%3; fx=(lx+(3 if (ly//6)%2 else 0))%6
        if ly%6<4 and fx<4 and not (ly%6==3 and fx in (1,2)): c=[C('c0392b'),C('2e86de'),C('e1b12c')][fy]
    else:
        c=C('2c3e50')
        if math.hypot(lx-7.5,ly-12)<4.2 or (abs(lx-7.5)<6 and ly>20): c=C('d7a37a') if ly<17 else C('8e2a2a')
    if lx==0 or lx==15 or ly in (0,31): c=C('3a2a1a')
    return grain(c,x,y,.04,64)

def t_stonewall(x,y):
    # Rubble stone retaining wall: irregular grey-brown stones in dark mortar.
    row=y//5; ox=(x+int(hsh(row,0,65)*6))%32
    cell=ox//6
    c=mix(C('77706a'),C('5a5048'),hsh(cell,row,66))
    if y%5==4 or ox%6==5: c=C('2f2b27')
    return grain(c,x,y,.08,67)

def t_oil_concrete(x,y):
    c=kit.t_concrete(x,y)
    # A few oil stains of uneven size, nothing on a grid.
    for i in range(3):
        cx,cy=hsh(i,1,68)*32,hsh(i,2,68)*32
        if math.hypot((x-cx+16)%32-16,(y-cy+16)%32-16)<2.5+hsh(i,3,68)*3+vnoise(x,y,4,8,69)*2: c=mul(c,.82)
    return c

def make_palette():
    lav.make_palette()
    for name,fn,size in [('paralelepipedo',t_paralelepipedo,32),('ladrilho',t_ladrilho,32),('atelier_floor',t_atelier_floor,32),
        ('stonewall',t_stonewall,32),('oil_concrete',t_oil_concrete,32),
        ('grass',kit.cement('41592f','2f4424',.06,13),32),('saibro',kit.cement('9a8468','806d56',.06,14),32),
        ('foliage',kit.cement('2f4a2c','223822',.08,15),16)]:
        kit.material(name,image=kit.texture(name,size,size,fn))
    kit.material('paintings',image=kit.texture('paintings',64,32,t_paintings))
    for name,color in {'rail':'8a8f92','sleeper':'4a3322','water':'2f5f72','linen':'e2d9c2','quaresmeira':'7a4a8f',
        'locker':'4f6a6a','terracotta':'9a5038','plaster_bust':'d8d2c4','bougainvillea':'c2357a'}.items():
        kit.material(name,color)

# ---------------------------------------------------------------- shared pieces
def prism_x(mat,cx,cz,hc,r,t,n=8):
    """Wheel standing in the z/height plane (axle along x), centre (cx, cz) at height hc."""
    ring=[(cz+math.cos(math.tau*i/n)*r,hc+math.sin(math.tau*i/n)*r) for i in range(n)]
    for sx,normal in ((cx-t/2,(-1,0,0)),(cx+t/2,(1,0,0))):
        face(mat,[(sx,-zz,hh) for zz,hh in ring],1,normal)
    for i in range(n):
        (z0,h0),(z1,h1)=ring[i],ring[(i+1)%n]
        mz,mh=(z0+z1)/2-cz,(h0+h1)/2-hc
        face(mat,[(cx-t/2,-z0,h0),(cx+t/2,-z0,h0),(cx+t/2,-z1,h1),(cx-t/2,-z1,h1)],1,(0,-mz,mh))

def canopy(cx,cz,h,r,mat='foliage'):
    """Low-poly crown: a wide skirt and a dome, PS1 style."""
    cyl(mat,cx,cz,r*.7,h-r*.55,h,7,r1=r,phase=.3)
    cyl(mat,cx,cz,r,h,h+r*.55,7,r1=r*.35,phase=.3)

def street(rails=True):
    """Cobbled street in front, plain stone pavement, the bonde rails along it."""
    floor_quad('paralelepipedo',-30,10.65,60,16,-.06,1.6)
    floor_quad('asphalt',-30,-26,60,36.65,-.07,2.4)
    floor_quad('pedra',-30,8.15,60,2.5,.07,1.6)
    box('stonewall',-30,10.65,60,.18,-.06,.09,.6,sides=False)
    wall_quad('stonewall',-30,30,10.83,-.06,.09)
    if rails:
        for rz in (12.25,13.35):
            box('rail',-30,rz-.035,60,.07,-.06,-.02)
        for i in range(100): box('sleeper',-30+i*.6,12.05,.16,1.5,-.065,-.055)
    for lx in (-10.5,1.5,13.0):
        cyl('iron',lx,10.95,.14,.09,.45,6); cyl('iron',lx,10.95,.06,.09,2.7,6)
        cyl('iron',lx,10.95,.16,2.7,2.74,4); cyl('bulb',lx,10.95,.11,2.74,3.0,4); cyl('iron',lx,10.95,.17,3.0,3.1,4,r1=.02)

def flank(x0=-12.25,x1=12.0):
    """Alleys either side of the lot (whose outer walls stand at x0 and x1), the strip behind it
    and the four sobrados framing the level."""
    floor_quad('concrete',-15.3,-9.6,x0+15.3,17.75,.03,1.4)
    floor_quad('concrete',x1,-9.6,15.3-x1,17.75,.03,1.4)
    floor_quad('concrete',x0,-9.6,x1-x0,1.85,.03,1.4)
    kit.sobrado(-26,-19.5,8.15,-9.6,5.2,'facade_yellow',side=True)
    kit.sobrado(-19.5,-15.4,8.15,-9.6,4.8,'facade_blue',side=True)
    kit.sobrado(15.4,20.0,8.15,-9.6,5.0,'facade_green',side=True)
    kit.sobrado(20.0,26.0,8.15,-9.6,5.6,'facade_pink',side=True)

def hill(seed,gap=None):
    """Behind the stone retaining wall the hill climbs: casarões between clumps of Atlantic forest,
    three rows, dark but for a few lit windows. `gap` (x0, x1) leaves room for a stairway."""
    paints=['facade_yellow','ochre','facade_pink','facade_blue','facade_green']
    if gap: box('stonewall',-27,-10.4,gap[0]+27,.8,0,3.2,1.2); box('stonewall',gap[1],-10.4,27-gap[1],.8,0,3.2,1.2)
    else: box('stonewall',-27,-10.4,54,.8,0,3.2,1.2)
    for r,(front,back,base) in enumerate(((-11.2,-15.0,0.0),(-16.2,-20.0,3.2),(-21.2,-25.0,6.4))):
        if base: box('stonewall',-27,front-.1,54,.5,0,base,1.2)
        x=-27.0; i=0
        while x<27:
            w=4+hsh(i,r,seed)*3.5
            if gap and r==0 and x<gap[1] and x+w>gap[0]:
                x=gap[1]; i+=1; continue
            if hsh(i,r,seed+1)>.5:
                h=4.2+1.4*hsh(i,r,seed+2)
                kit.sobrado(x,x+w,front,back,h,paints[int(hsh(i,r,seed+3)*5)],doors=False,base=base)
                n=max(1,int(w/2.2))
                for k in range(n):
                    if hsh(r*37+i,k,seed+4)>.82:
                        wx=x+w*(k+.5)/n
                        wall_quad('window_lit',wx-.32,wx+.32,front+.04,base+h-2.25,base+h-.95,1,1)
            else:
                for k in range(3):
                    cx=x+w*(k+.5)/3; cz=(front+back)/2+(hsh(i,k,seed+5)-.5)*2
                    ch=base+3.0+2.0*hsh(i,k,seed+6)
                    cyl('wood',cx,cz,.15,base,ch-.6,5)
                    canopy(cx,cz,ch,1.3+.6*hsh(i,k,seed+7),'quaresmeira' if hsh(i,k,seed+8)>.85 else 'foliage')
            x+=w; i+=1

def build_crate(x,z,w,d,h=1.2):
    """Wooden shipping crates, the top one marked FRÁGIL."""
    box('wood',x+.02,z+.02,w-.04,d-.04,0,h*.55,.6)
    box('wood',x+.12,z+.1,w*.6,d*.6,h*.55,h,.6)
    for sx in (x+.02,x+w-.08): box('sleeper',sx,z+d-.04,.06,.03,0,h*.55)
    text('red_paint','FRÁGIL',x+w/2,z+d-.005,h*.25,.12)

# ---------------------------------------------------------------- night 3: Casarão das Artes
# A real casarão: a varanda along the garden front, the front door into a hall with the staircase;
# dining room and gallery (with its own street door) to the west, the painting studio behind them,
# kitchen and storeroom on the service side; a formal garden in front, the quintal with the
# sculpture edícula behind a hedge, and the stone steps up the hill as the way out.
ROOMS3=[('atelie',-12.8,-3.4,-7.3,-1.4),('cozinha',-3.0,2.6,-7.3,-1.4),('jantar',-12.8,-3.4,-1.0,3.0),
    ('galeria',-12.8,-3.4,3.4,7.7),('hall',-3.0,2.6,-1.0,3.6),('deposito',-3.0,2.6,4.0,7.7),
    ('varanda',3.0,5.0,-1.0,7.7),('quintal',3.0,8.0,-7.3,-1.0),('quintal',8.0,12.55,-2.6,-1.4),
    ('edicula',8.4,12.55,-7.3,-3.0),('jardim',5.0,12.55,-.8,7.7)]
SKINS3={'atelie':('concrete',.3,False),'cozinha':('white_tile',1.3,False),'jantar':('azulejo',1.0,True),
    'galeria':('white',1.4,False),'hall':('wood',1.1,True),'deposito':('concrete',.35,False),
    'varanda':('facade_pink',1.4,False),'quintal':('facade_pink',1.4,False),'edicula':('whitewash',1.4,False),
    'jardim':('facade_pink',1.4,False),'outside':('stonewall',.7,False)}
# Door gaps (x, z, w, d), each with a granite sill.
DOORS3=[(8.0,7.7,1.6,.45),(-9.2,7.7,1.6,.45),(4.6,-7.75,1.4,.45),(2.6,-4.6,.4,1.4),(2.6,2.0,.4,1.4),
    (-3.4,-5.2,.4,1.4),(-3.4,1.0,.4,1.4),(-3.4,4.4,.4,1.4),(-11.2,-1.4,1.4,.4),(.6,-1.4,1.4,.4),
    (-5.4,3.0,1.4,.4),(-1.6,3.6,1.4,.4),(8.0,-5.6,.4,1.4),(10.2,-3.0,1.4,.4)]

def easel(x,z,w,d,index=0):
    cx,cz=x+w/2,z+d/2
    for lx,lz in ((cx-.3,cz+.25),(cx+.3,cz+.25),(cx,cz-.3)):
        obox('wood',lx,lz,.04,.04,0,1.35,0)
    box('wood',cx-.4,cz+.18,.8,.06,.5,.54)
    decal('paintings',cx-.36,cx+.36,cz+.22,.55,1.32,index*.25,index*.25+.25)
    obox('wood',cx+.45,cz+.3,.3,.22,.0,.04,.4)
    for i,col in enumerate(('red_paint','yellow_paint','water','white')): cyl(col,cx+.38+i*.05,cz+.3,.025,.04,.06,4)

def build_platform(x,z,w,d):
    """Model's platform: a low dais with a chaise under a velvet drape and a plaster bust."""
    box('wood',x,z,w,d,0,.3,.6)
    box('leather',x+.3,z+.4,w-.6,.7,.3,.62,.35); box('leather',x+.3,z+.3,.25,.8,.3,.95,.35)
    box('velvet',x+.7,z+.35,1.0,.8,.62,.66,.6)
    cyl('wood',x+w-.35,z+.35,.15,.3,.9,6); cyl('plaster_bust',x+w-.35,z+.35,.12,.9,1.1,6); cyl('plaster_bust',x+w-.35,z+.35,.09,1.1,1.3,6)

def build_worktable(x,z,w,d):
    box('wood',x+.05,z,w-.05,d,.85,.9,.6)
    for sz in (z+.1,z+d-.15): box('wood',x+w-.12,sz,.06,.06,0,.85); box('wood',x+.08,sz,.06,.06,0,.85)
    for i in range(6): cyl(['red_paint','yellow_paint','water','white','leaf','orange'][i],x+.25+(i%2)*.3,z+.25+(i//2)*.5,.05,.9,1.0,5)
    for i in range(3): cyl('glass',x+.55,z+1.6+i*.15,.05,.9,1.05,6); cyl('wood',x+.55,z+1.6+i*.15,.01,1.0,1.18,3)
    obox('linen',x+.35,z+1.2,.4,.3,.9,.91,.3)

def build_plinth(x,z,w,d,index=0):
    box('white',x,z,w,d,0,1.0)
    cx,cz=x+w/2,z+d/2
    if index==0:   # bronze figure
        cyl('gold',cx,cz,.08,1.0,1.4,5); cyl('gold',cx,cz,.07,1.4,1.52,5)
    elif index==1: # stacked stones
        for k in range(4): obox('stonewall',cx,cz,.22-k*.03,.18-k*.02,1.0+k*.1,1.1+k*.1,k*.6)
    else:          # iron loop
        obox('iron',cx-.08,cz,.04,.04,1.0,1.45,0); obox('iron',cx+.08,cz,.04,.04,1.0,1.45,0); obox('iron',cx,cz,.2,.04,1.41,1.45,0)

def build_dining(x,z,w,d):
    """Long jacaranda table with six chairs, a candelabrum and the plates still out."""
    tx0,tx1=x+.55,x+w-.55
    for px in (tx0+.1,tx1-.1):
        for pz in (z+.45,z+d-.45): box('wood',px-.04,pz-.04,.08,.08,0,.74)
    box('wood',tx0,z+.38,tx1-tx0,d-.76,.74,.79,.6); box('linen',tx0+.1,z+.5,tx1-tx0-.2,d-1.0,.79,.795)
    for i in range(3):
        px=tx0+.45+i*(tx1-tx0-.9)/2
        chair(px,z+.2,math.pi/2); chair(px,z+d-.2,-math.pi/2)
        for pz in (z+.62,z+d-.62): cyl('white',px,pz,.12,.795,.81,8); glass(px+.2,pz,.795,False)
    cx=(tx0+tx1)/2; cz=z+d/2
    cyl('brass',cx,cz,.09,.795,.82,6); cyl('brass',cx,cz,.02,.82,1.05,4)
    for k in (-1,0,1): cyl('cream',cx+k*.14,cz,.02,1.0,1.15,4); cyl('bulb',cx+k*.14,cz,.012,1.15,1.19,3)
    bottle(cx+.5,cz+.05,.795,2)

def build_sideboard(x,z,w,d):
    box('wood',x,z,w,d,0,.9,.6); box('marble',x-.01,z-.01,w+.02,d+.02,.9,.94,.7)
    cyl('terracotta',x+w/2,z+.4,.1,.94,1.2,6,r1=.06); canopy(x+w/2,z+.4,1.3,.14,'quaresmeira')
    for i in range(3): bottle(x+w/2,z+.9+i*.15,.94,i)

def build_canvases(x,z,w,d):
    """Canvases leaning in rows, some turned to show the paint."""
    along=w>=d
    n=int((w if along else d)/.32)
    for i in range(n):
        if along:
            px=x+.08+i*.32; box('wood',px,z+.05,.04,d-.1,0,1.0+.2*hsh(i,0,70))
            if i%3==1: decal('paintings',px-.02,px+.3,z+d-.04,.1,1.0,(i%4)*.25,(i%4)*.25+.25)
        else:
            pz=z+.08+i*.32; box('linen',x+.05,pz,w-.1,.04,0,.9+.25*hsh(i,1,70))
            box('wood',x+.05,pz+.04,w-.1,.02,0,.9+.25*hsh(i,1,70))

def build_fountain(x,z,w,d):
    cx,cz=x+w/2,z+d/2
    cyl('whitewash',cx,cz,w/2,0,.45,8,phase=math.pi/8,scale=1.2)
    cyl('water',cx,cz,w/2-.12,.4,.42,8,phase=math.pi/8)
    cyl('whitewash',cx,cz,.18,.42,.8,6); cyl('whitewash',cx,cz,.45,.8,.92,8,r1=.3)
    cyl('water',cx,cz,.38,.92,.93,8); cyl('plaster_bust',cx,cz,.06,.93,1.35,5); cyl('plaster_bust',cx,cz,.1,1.35,1.5,5)

def build_tree(x,z,w,d,index=0):
    cx,cz=x+w/2,z+d/2
    cyl('stonewall',cx,cz,w/2,0,.35,8,phase=math.pi/8)
    cyl('soil',cx,cz,w/2-.05,.35,.36,8,phase=math.pi/8)
    if index%2==0:   # imperial palm
        cyl('concrete',cx,cz,.12,.36,2.8,6)
        for i in range(7):
            a=i*math.tau/7; lx,lz=cx+math.cos(a)*.6,cz+math.sin(a)*.6
            obox('leaf',lx,lz,1.3,.24,2.65-.15*(i%2),2.75-.15*(i%2),a)
    else:            # quaresmeira in flower
        cyl('wood',cx,cz,.11,.36,1.9,5)
        canopy(cx,cz,2.3,.85,'quaresmeira')

def build_bench(x,z,w,d):
    """Garden bench of cast iron and slats, facing the fountain."""
    for pz in (z+.15,z+d-.2): box('iron',x+.1,pz,w-.2,.05,0,.45)
    for k in range(3): box('wood',x+.15+k*.14,z+.05,.1,d-.1,.42,.46)
    box('iron',x+w-.12,z+.1,.05,d-.2,.46,.9)
    for k in range(2): box('wood',x+w-.17,z+.1,.04,d-.2,.55+k*.15,.65+k*.15)

def build_stairs(x,z,w,d):
    """The hall staircase: seven wooden steps climbing west to the cut, a red runner, a turned
    banister on the open side and a newel post with a brass ball at the foot."""
    n=7; step=w/n
    for k in range(n):
        sx=x+w-(k+1)*step; h=.2*(k+1)
        box('wood',sx,z,step,d,0,h,.6)
        box('velvet',sx,z+d*.2,step,d*.6,h,h+.01,.6)
    box('cap',x-.01,z-.01,step+.02,d+.02,1.4,1.43,sides=False)
    for k in range(int(w/.25)):
        bx=x+w-.12-k*.25; h=.2*min(n,int((x+w-bx)/step)+1)
        top=min(h+.8,1.4)
        if top-h > .1: cyl('wood',bx,z+d-.06,.02,h,top,4)
        box('wood',bx-.13,z+d-.09,.26,.06,top-.04,top)
    cyl('wood',x+w-.06,z+d-.06,.06,0,1.0,6); cyl('brass',x+w-.06,z+d-.06,.06,1.0,1.08,6,r1=.02)

def build_balustrade(x,z,w,d):
    """Veranda railing: whitewashed base, turned balusters, a marble top rail, end posts with urns."""
    along_z=d>=w; length=d if along_z else w
    box('whitewash',x,z,w,d,0,.12,1.0)
    n=int(length/.25)
    for i in range(1,n):
        px,pz=(x+w/2,z+i*length/n) if along_z else (x+i*length/n,z+d/2)
        cyl('whitewash',px,pz,.05,.12,.45,6,r1=.03); cyl('whitewash',px,pz,.03,.45,.82,6,r1=.05)
    box('marble',x-.02,z,w+.04,d,.82,.9,.7)
    ends=((x+w/2,z+.15),(x+w/2,z+d-.15)) if along_z else ((x+.15,z+d/2),(x+w-.15,z+d/2))
    for px,pz in ends:
        box('whitewash',px-.15,pz-.15,.3,.3,0,1.0)
        cyl('terracotta',px,pz,.1,1.0,1.2,6,r1=.13); canopy(px,pz,1.28,.12,'leaf')

def build_hedge(x,z,w,d,h):
    """Box hedge on a stone curb, its top in soft lumps."""
    box('stonewall',x,z,w,d,0,.08,.8)
    box('foliage',x+.03,z+.03,w-.06,d-.06,.08,h-.12,.8)
    along=w>=d; length=w if along else d; n=max(2,int(length/.7))
    for i in range(n):
        t=(i+.5)/n
        cx,cz=(x+w*t,z+d/2) if along else (x+w/2,z+d*t)
        lw,ld=((length/n)*.95,d-.1) if along else (w-.1,(length/n)*.95)
        obox('foliage',cx,cz,lw,ld,h-.14,h-.02+.05*hsh(i,int(x*10),90),0)

def build_pergola(x,z,w,d):
    """Caramanchão: four timber posts, beams and slats, a little bougainvillea over two corners,
    an iron garden table and two chairs underneath."""
    for px,pz in ((x+.05,z+.05),(x+w-.15,z+.05),(x+.05,z+d-.15),(x+w-.15,z+d-.15)): box('wood',px,pz,.1,.1,0,2.3)
    for pz in (z+.05,z+d-.15): box('wood',x,pz,w,.1,2.25,2.33)
    for k in range(7): box('wood',x+.05+k*(w-.16)/6,z-.1,.06,d+.2,2.33,2.38)
    for cx,cz in ((x+.15,z+.15),(x+.4,z+.2),(x+w-.15,z+d-.15)): canopy(cx,cz,2.44,.26,'bougainvillea')
    cx,cz=x+w/2,z+d/2
    cyl('iron',cx,cz,.18,0,.03,6); cyl('iron',cx,cz,.04,.03,.72,5); cyl('marble',cx,cz,.4,.72,.75,8)
    chair(x+.35,cz,0.0,'iron'); chair(x+w-.35,cz,math.pi,'iron')
    glass(cx-.1,cz+.1,.75); cyl('white',cx+.12,cz-.08,.1,.75,.765,8)

def build_kiln(x,z,w,d):
    """Ceramics kiln in brick, iron door toward the yard, a chimney at the back, pots on top."""
    box('terracotta',x+.02,z,w-.04,d-.02,0,1.05,.5)
    for k in range(6): box('soil',x+.02,z+d-.03,w-.04,.012,.15*(k+1)-.02,.15*(k+1))
    box('iron',x+w/2-.25,z+d-.015,.5,.02,.25,.8); box('dark',x+w/2+.15,z+d+.005,.08,.02,.5,.56)
    box('terracotta',x+.1,z+.08,w-.2,d-.18,1.05,1.18,.5)
    box('terracotta',x+.05,z+.02,.3,.3,1.05,1.3)
    cyl('terracotta',x+w-.3,z+.5,.08,1.18,1.3,6,r1=.06); cyl('terracotta',x+w-.55,z+.55,.07,1.18,1.28,6,r1=.09)

def build_block(x,z,w,d):
    """Marble block on a pallet with a figure half out of the stone, chisel and mallet, chips."""
    for k in range(4): box('wood',x,z+k*(d-.12)/3,w,.12,0,.12)
    box('marble',x+.1,z+.1,w-.2,d-.2,.12,1.15,.7)
    cyl('plaster_bust',x+w/2,z+d/2,.15,1.15,1.28,6); cyl('plaster_bust',x+w/2,z+d/2,.09,1.28,1.4,6)
    obox('iron',x+w-.15,z+d-.1,.22,.04,.12,.15,.5); obox('wood',x+.2,z+d-.08,.25,.08,.12,.2,.2)
    for i in range(6): obox('whitewash',x-.1+hsh(i,0,91)*(w+.2),z+d+.08+hsh(i,1,91)*.3,.06,.05,0,.04,i)

def build_level3():
    data=load('level_3.json'); solids=data['solids']
    street(); flank(-13.25,13.0)
    floor_quad('atelier_floor',-12.8,-7.3,9.4,5.9,.04,3.2)    # ateliê de pintura
    floor_quad('vermelhao',-3.0,-7.3,5.6,5.9,.04,1.6)         # cozinha
    floor_quad('ladrilho',-12.8,-1.0,9.4,4.0,.04,.8)          # sala de jantar
    floor_quad('granilite',-12.8,3.4,9.4,4.3,.04,1.2)         # galeria
    floor_quad('tacos',-3.0,-1.0,5.6,4.6,.04,1.6)             # hall
    floor_quad('concrete',-3.0,4.0,5.6,3.7,.04,1.4)           # depósito
    floor_quad('ladrilho',3.0,-1.0,2.0,8.7,.05,.8)            # varanda
    floor_quad('grass',5.0,-1.4,7.55,9.1,.035,1.6)            # jardim, under the hedges too
    for r in ((8.0,5.4,1.6,2.3),(7.1,.8,3.4,4.0),(5.0,1.8,2.1,1.8),(6.4,-1.4,1.4,1.4)):
        floor_quad('saibro',*r,.045,1.2)                      # gate path, fountain ring, to the steps, hedge gate
    floor_quad('saibro',3.0,-7.3,5.0,6.3,.04,1.2)             # quintal
    floor_quad('saibro',8.0,-2.6,4.55,1.2,.04,1.2)
    floor_quad('cimento',8.4,-7.3,4.15,4.3,.04,1.6)           # edícula
    for x,z,w,d in DOORS3: floor_quad('granito',x,z,w,d,.05,.8)
    walls=kit.wall_pieces(solids)
    for x,z,w,d,h in walls: lav.build_wall(x,z,w,d,h,walls,ROOMS3,SKINS3)
    counts={}
    for s in solids:
        x,z,w,d=s['r']; kind=s['type']; i=counts.get(kind,0); counts[kind]=i+1
        if kind=='easel': easel(x,z,w,d,i)
        elif kind=='plinth': build_plinth(x,z,w,d,i%3)
        elif kind=='tree': build_tree(x,z,w,d,i)
        elif kind=='crate': build_crate(x,z,w,d)
        elif kind=='hedge': build_hedge(x,z,w,d,s['h'])
        elif kind!='wall':
            {'platform':build_platform,'worktable':build_worktable,'dining':build_dining,'sideboard':build_sideboard,
             'canvases':build_canvases,'fountain':build_fountain,'bench':build_bench,'stove':kit.build_stove,
             'prep':kit.build_prep,'stairs':build_stairs,'balustrade':build_balustrade,'pergola':build_pergola,
             'kiln':build_kiln,'block':build_block}[kind](x,z,w,d)
    back=-7.29
    # Studio: the house's name painted on a board, canvases against the wall, a big unfinished mural.
    box('dark',-10.4,-7.3,4.2,.02,1.62,2.3)
    text('yellow_paint','CASARÃO DAS ARTES',-8.3,back+.03,1.88,.32)
    text('cream','ateliês abertos',-8.3,back+.03,1.7,.12)
    for k in range(5): box('linen',-12.4+k*.35,-7.3,.3,.05,.3,1.2+.15*(k%2))
    decal('paintings',-5.0,-3.6,back+.01,1.0,2.2,.5,.75)
    # Gallery: paintings on the wall it shares with the dining room, under picture lights.
    for i,px in enumerate((-12.4,-10.8,-9.2,-7.6)):
        lav.frame(px,px+.9,3.4,.4,1.3,'linen'); decal('paintings',px+.08,px+.82,3.42,.48,1.22,(i%4)*.25,(i%4)*.25+.25)
        box('brass',px+.35,3.4,.2,.12,1.3,1.36)
    # Dining room: a portrait and a clock on the wall it shares with the studio.
    decal('paintings',-12.6,-11.8,-.99,.45,1.32,.75,1.0)
    decal('dark',-7.4,-7.0,-.99,.8,1.25); decal('white',-7.35,-7.05,-.98,.85,1.2)
    # Storeroom: a roll of canvas on the floor.
    obox('linen',1.4,7.3,1.6,.25,0,.25,0)
    # The street gate: iron leaves open into the garden between pillars with globe lamps, the number in azulejo.
    for px in (7.8,9.6): box('whitewash',px,7.65,.2,.55,0,1.3); cyl('white',px+.1,7.92,.13,1.3,1.5,6)
    for px,yaw in ((8.0,-1.2),(9.6,math.pi+1.2)):   # swung in, toward the garden
        cx,cz=local(px,7.92,yaw,.4,0); obox('iron',cx,cz,.8,.04,.05,1.2,yaw)
    decal('azulejo',7.2,7.6,8.17,.7,1.1); text('water','118',7.4,8.18,.82,.14)
    box('facade_pink',-6.8,8.15,5.2,.04,.3,1.0); text('cream','CASARÃO DAS ARTES',-4.2,8.2,.58,.28)
    text('yellow_paint','ATELIÊS  •  GALERIA  •  CAFÉ',-4.2,8.2,.4,.1)
    text('cream','GALERIA',-11.2,8.2,.6,.2)
    # The hedge gate into the quintal, its two iron leaves swung into the garden.
    for px,yaw in ((6.4,1.35),(7.8,math.pi-1.35)):
        cx,cz=local(px,-1.1,yaw,.35,0); obox('iron',cx,cz,.7,.04,.05,1.0,yaw)
    # Garden lights strung across the garden, flower beds along the walls.
    for x0,z0,x1,z1 in ((3.0,-.9,11.9,-.3),(3.0,6.6,11.9,7.1)):
        n=12
        for i in range(n+1):
            t=i/n; px,pz=x0+(x1-x0)*t,z0+(z1-z0)*t; sag=.18*math.sin(math.pi*t)
            cyl(['bulb','bulb_red','bulb','bulb_green'][i%4],px,pz,.04,2.2-sag,2.27-sag,4)
    for bx,bz in ((12.2,4.6),(12.2,5.6),(10.2,7.35),(7.4,7.35),(7.7,-6.95),(12.2,-2.0)):
        canopy(bx,bz,.45,.35)
    # Quintal: the edícula's name on the back fence, a clothesline clear of the way out.
    text('dark','ATELIÊ DE ESCULTURA',10.2,back,1.2,.1)
    for px in (3.4,7.6): cyl('iron',px,-6.9,.03,0,1.9,4)
    box('iron',3.4,-6.91,4.2,.02,1.85,1.87)
    for px,mat in ((3.7,'linen'),(7.0,'sequin_teal')): box(mat,px-.25,-6.92,.5,.02,1.2,1.85)
    # Behind the yard: the stone steps climbing toward the upper street, the exit.
    for k in range(14):
        box('pedra',4.6,-10.0-k*.4,1.4,.4,0,.22*(k+1),.8)
    for sx in (4.35,6.0): box('stonewall',sx,-15.6,.25,5.6,0,3.4,1.0)
    box('iron',4.45,-15.6,.04,5.6,1.0,1.05); box('iron',6.1,-15.6,.04,5.6,1.0,1.05)
    hill(80,gap=(4.2,6.4))

# ---------------------------------------------------------------- night 4: Oficina dos Bondes
# Passenger side: the street door into the ticket hall (bilheteria, roletas) and the platform where
# bonde 17 boards on the station track. Staff side: dispatch and the stationmaster over the
# platform, the shed with bondes 10 and 14 and the inspection pit, then the workshop, storeroom and
# locker room, each with its own door; the workshop's back door is the only way to the exit.
ROOMS4=[('linha',-12.8,-9.2,-7.3,7.7),('plataforma',-9.2,-6.4,-7.3,3.0),('saguao',-9.2,-1.6,3.0,7.7),
    ('despacho',-6.0,-1.6,-7.3,-3.4),('chefia',-6.0,-1.6,-3.0,3.0),('galpao',-1.2,7.0,-7.3,7.7),
    ('oficina',7.4,12.55,-7.3,-2.2),('almoxarifado',7.4,12.55,-1.8,2.2),('vestiario',7.4,12.55,2.6,7.7)]
SKINS4={'linha':('stonewall',.7,False),'plataforma':('azulejo',1.2,True),'saguao':('azulejo',1.0,True),
    'despacho':('wood',1.0,True),'chefia':('wood',1.2,True),'galpao':('green_paint',1.2,False),
    'oficina':('green_paint',1.2,False),'almoxarifado':('concrete',.5,False),'vestiario':('white_tile',1.3,False),
    'outside':('stonewall',.7,False)}
# Door gaps (x, z, w, d), each with a granite sill; the last is the free passage beside the roletas.
DOORS4=[(-12.3,7.7,2.6,.45),(-6.6,7.7,1.6,.45),(4.0,7.7,1.4,.45),(12.55,-6.9,.45,1.4),(-6.4,-5.2,.4,1.4),
    (-3.4,-3.4,1.4,.4),(-5.6,3.0,1.4,.4),(-1.6,-6.4,.4,1.4),(-1.6,.8,.4,1.4),(7.0,-5.0,.4,1.4),
    (7.0,-.6,.4,1.4),(7.0,4.0,.4,1.4),(8.8,-2.2,1.4,.4),(8.0,2.2,1.4,.4),(-7.8,3.0,1.4,.5)]

def build_bonde(x,z,w,d,number='10'):
    """Open Santa Teresa bonde shown cut at the walls' height: yellow side boards, crosswise wooden
    benches, a dashboard and headlamp at each end, the number toward the camera."""
    cx=x+w/2
    for bz in (z+1.3,z+d-1.3):
        box('iron',x+.3,bz-.6,w-.6,1.2,.1,.35)
        for wz in (bz-.4,bz+.4):
            for sx in (x+.24,x+w-.24): prism_x('black',sx,wz,.27,.25,.08)
    box('sleeper',x,z,w,d,.35,.45,.6)
    box('bonde',x-.02,z,.06,d,.28,.45); box('bonde',x+w-.04,z,.06,d,.28,.45)
    for sx in (x,x+w-.05): box('bonde',sx,z+.55,.05,d-1.1,.45,.92)
    n=6
    for i in range(n):
        pz=z+.55+i*(d-1.1)/(n-1)
        for sx in (x+.025,x+w-.025): cyl('bonde',sx,pz,.03,.92,1.4,4); cyl('cap',sx,pz,.035,1.4,1.42,4)
    k=int((d-1.5)/.72)
    for i in range(k):
        bz=z+.85+i*.72
        box('wood',x+.1,bz,w-.2,.34,.8,.85); box('wood',x+.1,bz-.04,w-.2,.05,.85,1.2)
        for sx in (x+.12,x+w-.18): box('iron',sx,bz,.06,.34,.45,.8)
    for end,front in ((z+.05,False),(z+d-.45,True)):
        box('bonde',x+.1,end,w-.2,.4,.45,1.15); box('sleeper',x+.08,end-.02,w-.16,.44,1.15,1.19)
        hz=end+(.405 if front else -.005)
        cyl('bulb',cx,hz,.07,.98,1.08,6) if front else cyl('bulb_red',cx,hz,.05,.98,1.05,4)
        cyl('iron',x+.35,end+(-.15 if front else .55),.08,.45,1.1,6); cyl('brass',x+.35,end+(-.15 if front else .55),.1,1.1,1.13,6)
    text('black',number,cx+.55,z+d-.04,.62,.24)
    text('red_paint','SANTA TERESA',cx-.15,z+d-.04,.52,.075)

def rails_along_z(cx,z0,z1):
    for rx in (cx-.55,cx+.55): box('rail',rx-.035,z0,.07,z1-z0,.04,.075)
    n=int((z1-z0)/.6)
    for i in range(n): box('sleeper',cx-.75,z0+.1+i*.6,1.5,.16,.04,.05)

def build_workbench(x,z,w,d):
    """Workbench with a vice, tools laid out and red toolboxes under it."""
    along=w>=d
    box('wood',x,z,w,d,.85,.92,.6)
    for px,pz in ((x+.06,z+.06),(x+w-.12,z+.06),(x+.06,z+d-.12),(x+w-.12,z+d-.12)): box('iron',px,pz,.06,.06,0,.85)
    box('iron',x+.05,z+.05,w-.1,d-.1,.2,.24)
    for k in range(2): box('red_paint',x+.2+(k*.8 if along else 0),z+.2+(0 if along else k*.9),.5,.3,.24,.5)
    vx,vz=(x+w-.4,z+d/2) if along else (x+w/2,z+d-.4)
    box('iron',vx-.1,vz-.12,.2,.24,.92,1.08); box('dark',vx-.04,vz-.2,.08,.4,1.0,1.04)
    for k in range(5):
        px,pz=(x+.3+k*.35,z+d/2) if along else (x+w/2,z+.3+k*.35)
        obox('chrome',px,pz,.28,.05,.92,.94,.3*k)

def build_bogie(x,z,w,d):
    """A spare truck off its bonde: frame, two axles, four wheels."""
    box('iron',x+.15,z+.1,w-.3,d-.2,.22,.38)
    for wz in (z+.22,z+d-.22):
        obox('chrome',x+w/2,wz,w-.1,.06,.25,.31,0)
        for sx in (x+.2,x+w-.2): prism_x('black',sx,wz,.28,.26,.08)
    cyl('iron',x+w/2,z+d/2,.25,.38,.6,6)

def build_drums(x,z,w,d):
    for i,col in enumerate(('red_paint','bottle_green','car_blue','red_paint')):
        px=x+.32+(i%2)*.7; pz=z+.25+(i//2)*.4
        if pz>z+d-.2: continue
        cyl(col,px,pz,.27,0,.88,8); cyl('dark',px,pz,.28,.3,.33,8,top=False); cyl('dark',px,pz,.28,.6,.63,8,top=False)
        cyl('dark',px+.1,pz,.03,.88,.9,4)

def build_motor(x,z,w,d):
    """A traction motor on its stand, cables hanging."""
    for px in (x+.1,x+w-.18):
        for pz in (z+.1,z+d-.18): box('iron',px,pz,.08,.08,0,.5)
    box('iron',x+.05,z+.05,w-.1,d-.1,.5,.56)
    cyl('pot',x+w/2,z+d/2,.4,.56,1.0,8); cyl('dark',x+w/2,z+d/2,.42,.75,.8,8,top=False)
    for k in range(3): obox('black',x+w/2+.45,z+.3+k*.2,.5,.04,.56,.6,.2)

def build_lockers(x,z,w,d,facing=-1):
    """Row of steel lockers, vents and number plates, one door ajar. `facing` +1 opens them toward
    +x (a wall behind them on the west), -1 toward -x."""
    front=x+w if facing>0 else x-.01
    n=int(d/.42)
    for i in range(n):
        pz=z+.02+i*.42
        box('locker',x,pz,w,.4,0,1.35)
        for k in range(3): box('dark',front,pz+.1,.01,.2,1.05+k*.06,1.08+k*.06)
    obox('locker',(x+w+.18) if facing>0 else (x-.18),z+d-.3,.4,.03,0,1.3,1.1*facing)

def build_lockerbench(x,z,w,d):
    box('wood',x,z,w,d,.4,.46,.6)
    for pz in (z+.1,z+d-.16): box('iron',x+.1,pz,w-.2,.06,0,.4)
    obox('white',x+w/2,z+.6,.3,.4,.46,.5,.3)

def build_seat(x,z,w,d):
    """Back-to-back station bench: cast-iron frames, wooden slats on both sides, a shared backrest."""
    along_z=d>=w; length=d if along_z else w; depth=w if along_z else d
    def part(mat,a0,a1,b0,b1,h0,h1):   # a along the bench, b across it
        if along_z: box(mat,x+b0,z+a0,b1-b0,a1-a0,h0,h1)
        else: box(mat,x+a0,z+b0,a1-a0,b1-b0,h0,h1)
    for a in (.05,length/2-.03,length-.11): part('iron',a,a+.06,.02,depth-.02,0,.42)
    for side in (0,1):
        for k in range(3):
            b0=.03+k*.085 if side==0 else depth-.03-(k+1)*.085
            part('wood',0,length,b0,b0+.07,.42,.46)
    for k in range(2): part('wood',0,length,depth/2-.03,depth/2+.03,.6+k*.18,.7+k*.18)

def build_roletas(x,z,w,d):
    """Turnstile bank: two chrome pedestals with three-arm rotors, ticket slot and coin box."""
    for k in range(2):
        px=x+.25+k*(w-.5)
        box('chrome',px-.15,z+.05,.3,d-.1,0,.95)
        box('brass',px-.05,z+d-.07,.1,.02,.82,.86); box('red_paint',px-.1,z+.1,.2,.2,.95,1.05)
        for a in range(3):
            ang=a*math.tau/3+.4
            obox('chrome',px+math.cos(ang)*.2,z+d/2+math.sin(ang)*.15,.36,.04,.88,.92,ang)
    box('white',x+w-.1,z+d-.02,.2,.02,.6,.72); text('red_paint','SAÍDA',x+w,z+d+.005,.63,.05)

def build_railing(x,z,w,d):
    """Green wrought-iron gradil: base and top rails, bars with spear tips, iron posts."""
    along_z=d>=w; length=d if along_z else w
    def at(t,h0,h1,mat,size=.03):
        if along_z: box(mat,x+w/2-size/2,z+t,size,size,h0,h1)
        else: box(mat,x+t,z+d/2-size/2,size,size,h0,h1)
    for h0,h1 in ((.08,.14),(.94,1.0)):
        if along_z: box('green_paint',x+w/2-.03,z,.06,length,h0,h1)
        else: box('green_paint',x,z+d/2-.03,length,.06,h0,h1)
    for i in range(int(length/.12)): at(.06+i*.12,.08,1.06,'green_paint',.025)
    for i in range(int(length/1.4)+1): at(min(length-.06,i*1.4),0,1.08,'iron',.08)

def build_pit(x,z,w,d):
    """Inspection pit between the rails: dark void, hazard-striped kerb, ladder, work lamp, guard
    posts and chains (why nobody walks or shoots through it)."""
    floor_quad('dark',x+.1,z+.1,w-.2,d-.2,.046,1.0)
    floor_quad('black',x+.1,z+.1,w-.2,.25,.047,1.0)
    for sx,sz,sw,sd in ((x,z,w,.1),(x,z+d-.1,w,.1),(x,z+.1,.1,d-.2),(x+w-.1,z+.1,.1,d-.2)):
        along=sw>sd; length=sw if along else sd; k=max(1,int(length/.25))
        for i in range(k):
            mat='yellow_paint' if i%2==0 else 'black'
            if along: box(mat,sx+i*length/k,sz,length/k,sd,.04,.15)
            else: box(mat,sx,sz+i*length/k,sw,length/k,.04,.15)
    for rx in (x+w/2-.2,x+w/2+.2): box('chrome',rx-.02,z+d-.35,.04,.25,.15,.6)
    for k in range(3): box('chrome',x+w/2-.2,z+d-.3+k*.08,.4,.02,.25+k*.12,.27+k*.12)
    cyl('bulb',x+w/2,z+d/2,.06,.12,.2,4)
    posts=((x+.05,z+.05),(x+w-.05,z+.05),(x+w-.05,z+d-.05),(x+.05,z+d-.05))
    for px,pz in posts: cyl('yellow_paint',px,pz,.04,0,.9,6)
    for i in range(4):
        (ax,az),(bx,bz)=posts[i],posts[(i+1)%4]
        if abs(ax-bx)<.01: box('black',ax-.01,min(az,bz),.02,abs(bz-az),.78,.8)
        else: box('black',min(ax,bx),az-.01,abs(bx-ax),.02,.78,.8)

def build_lathe(x,z,w,d):
    """Lathe along the wall: cabinet legs, bed, headstock with a chuck, tailstock, carriage, lamp."""
    for px in (x+.05,x+w-.5): box('locker',px,z+.1,.45,d-.2,0,.75)
    box('dark',x+.5,z+.15,w-1.0,d-.3,.12,.16)
    for i in range(6): obox('chrome',x+.7+i*.2,z+d/2,.12,.03,.16,.18,i)
    box('iron',x+.05,z+.15,w-.1,d-.3,.75,.9)
    box('locker',x+.05,z+.1,.5,d-.2,.9,1.25)
    prism_x('chrome',x+.6,z+d/2,1.05,.13,.08)
    box('locker',x+w-.4,z+.2,.3,d-.4,.9,1.1)
    box('iron',x+1.1,z+.12,.35,d-.24,.9,1.0); box('chrome',x+1.2,z+d/2-.05,.12,.1,1.0,1.1)
    cyl('iron',x+.3,z+.15,.02,1.25,1.5,4); obox('green_paint',x+.45,z+.2,.2,.12,1.42,1.5,.4)

def build_shelves(x,z,w,d):
    """Steel storeroom shelving with boxes, a spare headlamp and a coil of cable."""
    along_z=d>=w; length=d if along_z else w; depth=w if along_z else d
    for t in (.02,length-.06):
        for s in (.02,depth-.06):
            if along_z: box('metal',x+s,z+t,.04,.04,0,1.38)
            else: box('metal',x+t,z+s,.04,.04,0,1.38)
    for h in (.1,.5,.9,1.3):
        box('metal',x,z,w,d,h,h+.03,.5)
        t=.08; i=0
        while t<length-.25:
            bl=.2+.25*hsh(i,int(h*10),95); bh=.15+.15*hsh(i,int(h*10),96)
            mat=['crate','cream','red_paint','locker'][int(hsh(i,int(h*10),97)*4)]
            if h<1.3 or i%2:
                if along_z: box(mat,x+.05,z+t,w-.1,bl,h+.03,h+.03+bh)
                else: box(mat,x+t,z+.05,bl,d-.1,h+.03,h+.03+bh)
            t+=bl+.05; i+=1
    cx,cz=(x+w/2,z+length*.7) if along_z else (x+length*.7,z+d/2)
    cyl('bulb',cx,cz,.1,.53,.68,6); cyl('black',cx,cz,.15,.93,1.0,8)

def build_level4():
    data=load('level_4.json'); solids=data['solids']
    street(); flank(-13.25,13.0)
    floor_quad('paralelepipedo',-12.8,-7.3,3.6,15.0,.04,1.6)    # station track bed, cobbled like the street
    floor_quad('ladrilho',-9.2,-7.3,2.8,10.3,.06,.8)            # platform
    floor_quad('yellow_paint',-9.12,-7.3,.08,10.3,.065,1.0)      # safety line at the platform edge
    floor_quad('granilite',-9.2,3.0,7.6,4.7,.04,1.2)            # saguão
    floor_quad('tacos',-6.0,-7.3,4.4,3.9,.04,1.6)               # despacho
    floor_quad('tacos',-6.0,-3.0,4.4,6.0,.04,1.6)               # chefe da estação
    floor_quad('oil_concrete',-1.2,-7.3,8.2,15.0,.04,2.4)       # galpão
    floor_quad('cimento',7.4,-7.3,5.15,5.1,.04,1.6)             # oficina
    floor_quad('concrete',7.4,-1.8,5.15,4.0,.04,1.4)            # almoxarifado
    floor_quad('white_tile',7.4,2.6,5.15,5.1,.04,1.0)           # vestiário
    for x,z,w,d in DOORS4: floor_quad('granito',x,z,w,d,.05,.8)
    # Three tracks come in from the street rails: the station's, with bonde 17 boarding, and two in the shed.
    for cx in (-11.0,.8,4.6): rails_along_z(cx,-7.3,12.0)
    walls=kit.wall_pieces(solids)
    for x,z,w,d,h in walls: lav.build_wall(x,z,w,d,h,walls,ROOMS4,SKINS4)
    numbers=iter(('17','10','14'))
    for s in solids:
        x,z,w,d=s['r']; kind=s['type']
        if kind=='bonde': build_bonde(x,z,w,d,next(numbers))
        elif kind=='lockers':
            west_wall=any(o['type']=='wall' and abs(o['r'][0]+o['r'][2]-x)<.05 for o in solids)
            build_lockers(x,z,w,d,1 if west_wall else -1)
        elif kind!='wall':
            {'workbench':build_workbench,'bogie':build_bogie,'drums':build_drums,'motor':build_motor,
             'crate':build_crate,'desk':lav.build_desk,'sofa':lav.build_sofa,'bench':build_lockerbench,
             'pillar':lav.build_pillar,'ticket':lav.build_ticket,'stalls':lav.build_stalls,'seat':build_seat,
             'roletas':build_roletas,'railing':build_railing,'pit':build_pit,'lathe':build_lathe,
             'shelves':build_shelves}[kind](x,z,w,d)
    back=-7.29
    # Station: the enamel name plate over the boarding bonde and the platform clock.
    box('teal',-12.6,-7.3,5.8,.02,1.7,2.3)
    text('cream','ESTAÇÃO SANTA TERESA',-9.7,back+.03,1.9,.26)
    decal('dark',-7.6,-7.0,back+.01,1.7,2.3); decal('white',-7.55,-7.05,back+.02,1.75,2.25)
    # Dispatch: the line map with its stops.
    decal('linen',-5.6,-2.2,back+.01,1.45,2.2)
    decal('red_paint',-5.4,-2.4,back+.02,1.8,1.84)
    for k in range(5): decal('dark',-5.35+k*.72,-5.25+k*.72,back+.03,1.77,1.87)
    text('dark','CARIOCA • CURVELO • GUIMARÃES • DOIS IRMÃOS',-3.9,back+.03,1.55,.06)
    # Shed: the depot's painted name and the no-smoking plate.
    box('dark',-1.0,-7.3,6.4,.02,1.6,2.35)
    text('cream','OFICINA DOS BONDES',2.2,back+.03,1.9,.36)
    text('yellow_paint','SANTA TERESA  •  DESDE 1896',2.2,back+.03,1.7,.12)
    decal('red_paint',5.9,6.9,back+.01,1.5,1.9); text('white','PROIBIDO FUMAR',6.4,back+.02,1.64,.09)
    # Workshop: a pegboard of tools over the lathe.
    decal('sleeper',8.0,10.4,back+.01,1.45,2.1)
    for k in range(8): decal('chrome',8.15+k*.28,8.25+k*.28,back+.02,1.5+(k%2)*.25,1.95+(k%2)*.1)
    # Ticket hall: the timetable between the stationmaster's door and the booth.
    decal('linen',-4.15,-3.45,3.41,.7,1.3); text('dark','HORÁRIOS',-3.8,3.42,1.15,.08)
    # Front: gate posts, the station door and board, gate B shut, gate C half open, the depot board.
    for px in (-12.3,-9.7,4.0,5.4): box('iron',px-.06,7.62,.12,.6,0,1.35)
    for px in (-6.6,-5.07): box('wood',px,7.65,.07,.55,0,1.3)
    box('green_paint',-9.5,8.15,2.8,.04,.4,1.1); text('cream','ESTAÇÃO',-8.1,8.2,.75,.22)
    text('yellow_paint','SANTA TERESA',-8.1,8.2,.5,.1)
    box('green_paint',-.3,8.15,2.2,.06,0,1.3)
    for h in (.3,1.0): box('iron',-.3,8.21,2.2,.02,h,h+.06)
    box('green_paint',5.45,8.15,1.5,.06,0,1.3)
    box('green_paint',6.2,8.15,3.4,.04,.4,1.1); text('cream','OFICINA DOS BONDES',7.9,8.2,.62,.18)
    # The right-hand alley is shut at the street: only the workshop's back door leads to the exit.
    for i in range(int(2.1/.12)): box('iron',13.04+i*.12,8.15,.025,.03,0,1.3)
    decal('red_paint',13.6,14.5,8.17,.7,1.0); text('white','PROIBIDA A ENTRADA',14.05,8.18,.82,.06)
    for i,(bx,bz) in enumerate(((15.05,6.9),(15.1,7.5),(-15.05,1.8),(-15.1,2.5))):
        obox('black',bx,bz,.45,.42,0,.4,i*.6); cyl('black',bx,bz,.11,.4,.52,4)
    # The workshop's back door to the alley, swung toward the back, clear of the exit.
    yaw=-.55; cx,cz=local(13.0,-6.9,yaw,.6,0); obox('wood',cx,cz,1.2,.05,0,1.3,yaw)
    hill(90)

if __name__=='__main__':
    for name,builder in (('ateliers',build_level3),('bondes',build_level4)):
        with kit.workspace('SantaTeresa_'+name) as scene:
            make_palette()
            builder()
            triangles=kit.assemble(scene)
            kit.export_glb(os.path.join(ROOT,'assets/environment/%s.glb' % name))
            bpy.data.libraries.write(os.path.join(ROOT,'tools/source/%s.blend' % name),{scene},fake_user=True,compress=True)
            print('SANTA_TERESA_READY',name,len(scene.objects),'meshes',triangles,'triangles',len(kit.images),'textures')
