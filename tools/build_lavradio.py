"""Second night: the Gafieira Estrela, a dance hall in a sobrado on Rua do Lavradio, Lapa.

No Arcos this time: behind the block the houses of the hill climb toward Santa Teresa. Imports
build_environment.py as a kit for its PSX textures, materials and mesh helpers, so both levels
share one look. Collision comes from assets/level_2.json: every interior piece is modeled inside
its solid's footprint. Runs headless or through the MCP bridge, in a temporary scene:
    blender -b --factory-startup --python "godot 3d/tools/build_lavradio.py"
"""
import bpy, os, math, json, importlib.util

HERE=os.path.dirname(os.path.abspath(__file__))
spec=importlib.util.spec_from_file_location('lapa_kit',os.path.join(HERE,'build_environment.py'))
kit=importlib.util.module_from_spec(spec); spec.loader.exec_module(kit)
ROOT=kit.ROOT
layout=json.load(open(os.path.join(ROOT,'assets/level_2.json'),encoding='utf-8'))
C,mul,mix,grain,hsh,vnoise=kit.C,kit.mul,kit.mix,kit.grain,kit.hsh,kit.vnoise
box,obox,cyl,face,local=kit.box,kit.obox,kit.cyl,kit.face,kit.local
wall_quad,floor_quad,decal,text,poster=kit.wall_quad,kit.floor_quad,kit.decal,kit.text,kit.poster
bottle,glass,chair,stool=kit.bottle,kit.glass,kit.chair,kit.stool

# ---------------------------------------------------------------- textures
def t_tacos(x,y):
    # Taco floor: 8 px blocks of four short strips, each block turned 90 degrees from its neighbours.
    bx,by,lx,ly=x//8,y//8,x%8,y%8
    across=(bx+by)%2
    strip=(ly if across else lx)//2
    c=mul(C('714528'),.86+hsh(bx*4+strip,by,40)*.24)
    c=mul(c,.95+.06*math.sin((lx if across else ly)*1.4+strip*2.3))
    if lx==0 or ly==0: c=mul(c,.66)
    return grain(c,x,y,.04,41)

def t_velvet(x,y):
    # Stage curtain: deep red velvet hanging in soft vertical folds.
    fold=abs(math.sin((x+vnoise(x,y,8,4,42)*2.5)*math.pi/8))
    return grain(mul(C('7a1426'),.55+.55*fold),x,y,.04,43)

def make_palette():
    kit.make_palette()
    kit.material('tacos',image=kit.texture('tacos',32,32,t_tacos))
    kit.material('velvet',image=kit.texture('velvet',32,32,t_velvet))
    kit.material('felt',image=kit.texture('felt',16,16,kit.cement('2f7a52','24663f',seed=9)))
    for name,color in {'gold':'c9a13b','porcelain':'e9e6dc','ivory':'e8dcc0','chrome':'aeb4b6','money':'6f8f5a',
        'sequin_red':'b3263a','sequin_gold':'d9b03a','sequin_teal':'2a9a9a','inlay':'74502f','books_a':'6b2a2a',
        'books_b':'2c4a5e','books_c':'b08d4a','ball_blue':'2f6fb0','rug':'4a2a2a'}.items():
        kit.material(name,color)
    kit.material('neon_yellow','ffe066',emission='ffd23f',strength=4)
    # A few windows still lit up the hill: warm and dim, never brighter than the hall itself.
    kit.material('window_lit','c98a3a',emission='e09a4a',strength=.55)

# ---------------------------------------------------------------- walls
# Rooms of the gafieira (x0, x1, z0, z1) and the skin each one paints on its walls:
# material, height and whether a wooden rail tops it.
# Public route: street door → foyer (bilheteria) → salão, or round through the sinuca. Service
# route: the corridor behind the bathrooms to the camarim and the stage's right wing; the office
# and the copa off the left wing, the copa's side door to the alley.
ROOMS=[('salao',-7.2,6.4,-7.3,2.6),('escritorio',-12.8,-7.6,-7.3,-2.4),('copa',-12.8,-7.6,-2.0,2.6),
    ('deposito',-12.8,-7.6,3.0,7.7),('sinuca',-7.2,-0.6,3.0,7.7),('foyer',-0.2,6.4,3.0,7.7),
    ('corredor',6.8,8.6,-7.3,7.7),('camarim',9.0,12.55,-7.3,-2.2),('banheiro_f',9.0,12.55,-1.8,2.6),
    ('banheiro_m',9.0,12.55,3.0,7.7)]
SKINS={'salao':('green_paint',1.0,True),'escritorio':('wood',1.2,True),'copa':('white_tile',1.3,False),
    'deposito':('concrete',.9,False),'sinuca':('wood',1.0,True),'foyer':('azulejo',1.0,True),
    'corredor':('facade_yellow',.9,True),'camarim':('facade_pink',.9,False),
    'banheiro_f':('white_tile',1.3,False),'banheiro_m':('white_tile',1.3,False),'outside':('concrete',.35,False)}
# Door gaps (x, z, w, d), each with a granite sill.
DOORS=[(3.8,7.7,1.6,.45),(-13.25,-1.6,.45,1.4),(-7.6,-6.8,.4,1.4),(-7.6,.8,.4,1.4),(-7.6,3.4,.4,1.4),
    (-10.6,-2.4,1.4,.4),(-12.2,2.6,1.4,.4),(-4.6,2.6,1.4,.4),(1.2,2.6,2.0,.4),(-.6,3.4,.4,1.4),
    (6.4,-6.8,.4,1.4),(6.4,4.6,.4,1.4),(8.6,-4.6,.4,1.4),(8.6,.8,.4,1.4),(8.6,6.0,.4,1.4)]

def room(x,z,rooms=None):
    for name,x0,x1,z0,z1 in rooms or ROOMS:
        if x0<x<x1 and z0<z<z1: return name
    return 'outside'

def build_wall(x,z,w,d,h,walls,rooms=None,skins=None):
    """Wall cut at `h` with a black cap. `rooms` and `skins` default to the gafieira's; other levels
    built with this kit pass their own."""
    rooms=rooms or ROOMS; skins=skins or SKINS
    box('plaster',x,z,w,d,0,h,1.2)
    box('cap',x-.01,z-.01,w+.02,d+.02,h,h+.03,sides=False)
    # Each face is split where the rooms beside it change, so a long wall wears every room's skin.
    for nx,nz in ((1,0),(-1,0),(0,1),(0,-1)):
        a,b=(z,z+d) if nx else (x,x+w)
        cuts=sorted({a,b}|{v for r in rooms for v in ((r[3],r[4]) if nx else (r[1],r[2])) if a<v<b})
        for a0,a1 in zip(cuts,cuts[1:]):
            mid=(a0+a1)/2
            px,pz=(x+w/2+nx*(w/2+.3),mid) if nx else (mid,z+d/2+nz*(d/2+.3))
            qx,qz=(x+w/2+nx*(w/2+.02),mid) if nx else (mid,z+d/2+nz*(d/2+.02))
            if any(wx<=qx<=wx+ww and wz<=qz<=wz+wd for wx,wz,ww,wd,_ in walls): continue
            mat,top,rail=skins[room(px,pz,rooms)]
            top=min(h,top); t=.012
            if nx: box(mat,x+(w if nx>0 else -t),a0,t,a1-a0,0,top,.5)
            else: box(mat,a0,z+(d if nz>0 else -t),a1-a0,t,0,top,.5)
            if rail and h>1.1:
                if nx: box('wood',x+(w if nx>0 else -.03),a0,.03,a1-a0,top,top+.06)
                else: box('wood',a0,z+(d if nz>0 else -.03),a1-a0,.03,top,top+.06)

# ---------------------------------------------------------------- props
def star(mat,cx,z,h,r,inner=.42):
    """Five-pointed star standing on a wall, facing the camera."""
    pts=[]
    for i in range(10):
        a=math.pi/2+i*math.pi/5; rr=r if i%2==0 else r*inner
        pts.append((cx+math.cos(a)*rr,-z,h+math.sin(a)*rr))
    face(mat,pts[1::2],1,(0,-1,0))
    for i in range(5): face(mat,[pts[2*i-1],pts[2*i],pts[(2*i+1)%10]],1,(0,-1,0))

def floor_star(mat,cx,cz,r,h,inner=.42):
    pts=[]
    for i in range(10):
        a=-math.pi/2+i*math.pi/5; rr=r if i%2==0 else r*inner
        pts.append((cx+math.cos(a)*rr,-(cz+math.sin(a)*rr),h))
    face(mat,pts[1::2],1,(0,0,1))
    for i in range(5): face(mat,[pts[2*i-1],pts[2*i],pts[(2*i+1)%10]],1,(0,0,1))

def palm(px,pz):
    cyl('red_paint',px,pz,.17,0,.42,6,r1=.2); cyl('soil',px,pz,.18,.42,.43,6)
    cyl('wood',px,pz,.03,.43,.9,4)
    for i in range(6):
        a=i*math.tau/6; lx,lz=px+math.cos(a)*.22,pz+math.sin(a)*.22
        obox('leaf',lx,lz,.5,.12,.88-i%2*.08,.92-i%2*.08,a)

def frame(x0,x1,z,h0,h1,inside='cream'):
    decal('wood',x0,x1,z+.005,h0,h1); decal(inside,x0+.04,x1-.04,z+.015,h0+.04,h1-.04)

def build_stage(x,z,w,d):
    """Band stand against the back wall: plank platform, footlights, an upright piano, the drum
    kit, two horn chairs with music stands and the singer's microphones."""
    top=.45
    box('wood',x,z,w,d,0,top,.6)
    box('red_paint',x-.01,z+d-.04,w+.02,.05,.05,top-.05)
    for i in range(9): cyl(['bulb','bulb_red','bulb'][i%3],x+.35+i*(w-.7)/8,z+d-.12,.05,top,top+.07,4)
    # Upright piano, stage left, and its bench.
    px,pz=x+.25,z+.12
    box('black',px,pz,1.45,.55,top,top+1.2)
    box('black',px-.02,pz+.55,1.49,.28,top+.62,top+.72)
    box('ivory',px+.05,pz+.6,1.39,.2,top+.72,top+.735)
    for k in range(12): box('black',px+.12+k*.11,pz+.6,.05,.12,top+.735,top+.75)
    box('wood',px+.35,pz+.95,.8,.32,top,top+.46)
    # Drum kit in the middle, bass drum facing the room.
    dx,dz=x+w/2+.2,z+.6
    obox('red_paint',dx,dz,.5,.38,top+.04,top+.54,0)
    wall_quad('white',dx-.2,dx+.2,dz+.195,top+.09,top+.49,1,1)
    cyl('chrome',dx-.5,dz+.3,.012,top,top+.55,4); cyl('white',dx-.5,dz+.3,.16,top+.55,top+.68,8)
    cyl('white',dx+.05,dz-.18,.13,top+.58,top+.74,8)
    cyl('red_paint',dx+.55,dz+.25,.19,top,top+.45,8); cyl('white',dx+.55,dz+.25,.19,top+.45,top+.46,8)
    for cx,cz in ((dx-.7,dz-.2),(dx+.75,dz-.3)):
        cyl('chrome',cx,cz,.012,top,top+1.0,4); cyl('gold',cx,cz,.16,top+1.0,top+1.02,8)
    cyl('iron',dx,dz-.55,.13,top,top+.5,6); cyl('leather',dx,dz-.55,.15,top+.5,top+.56,8,scale=.4)
    # Horns, stage right: two chairs, stands with sheet music, a saxophone resting on a seat.
    for i in range(2):
        cx=x+w-1.95+i*.8
        chair(cx,z+.75,math.pi/2)
        cyl('iron',cx,z+1.25,.012,top,top+1.0,4)
        obox('iron',cx,z+1.25,.42,.03,top+.98,top+1.2,0); wall_quad('white',cx-.17,cx+.17,z+1.27,top+1.0,top+1.18,1,1)
    cyl('brass',x+w-1.15,z+.72,.05,top+.5,top+.85,6); cyl('brass',x+w-1.15,z+.72,.09,top+.85,top+.92,6)
    # Microphones at the front, and the amplifiers at both ends.
    for mx in (x+w/2-.9,x+w/2+.9):
        cyl('iron',mx,z+d-.42,.12,top,top+.02,6); cyl('iron',mx,z+d-.42,.015,top,top+1.45,4)
        cyl('black',mx,z+d-.46,.04,top+1.43,top+1.53,4)
    for ax in (x+w-.55,):
        box('black',ax,z+.1,.5,.42,top,top+.8); wall_quad('dark',ax+.06,ax+.44,z+.525,top+.08,top+.7,1,1)
    box('black',x+1.85,z+.1,.42,.36,top,top+.65)

def build_curtain(x0,x1,z):
    """Velvet curtain on the back wall behind the stage, a valance with a gold fringe, the hall's
    name in neon and two neon stars."""
    wall_quad('velvet',x0,x1,z+.01,.45,2.42,.8,1)
    for px in (x0-.2,x1-.3): box('velvet',px,z,.5,.18,0,2.42,.6)
    box('velvet',x0-.2,z,x1-x0+.4,.24,2.18,2.45,.6)
    box('gold',x0-.2,z+.24,x1-x0+.4,.02,2.15,2.2)
    cx=(x0+x1)/2
    text('neon_pink','GAFIEIRA ESTRELA',cx,z+.27,1.82,.3)
    text('neon_cyan','baile desde 1931',cx,z+.27,1.66,.12)
    for sx in (cx-2.75,cx+2.75): star('neon_yellow',sx,z+.27,1.92,.17)

def build_pillar(x,z,w,d):
    """Cast iron column of the old sobrado, cut at the same height as the walls."""
    cx,cz=x+w/2,z+d/2
    cyl('iron',cx,cz,.2,0,.24,8,phase=math.pi/8)
    cyl('green_paint',cx,cz,.12,.24,1.4,8,phase=math.pi/8)
    cyl('brass',cx,cz,.135,.9,.97,8,top=False,phase=math.pi/8)
    cyl('cap',cx,cz,.125,1.4,1.43,8,phase=math.pi/8)

def build_bar(x,z,w,d):
    """Counter along the left wall: bottles on the back shelf, the bartender's mat, a painted
    counter with a marble top, and stools on the dance-floor side."""
    x1=x+w
    box('wood',x,z,.32,d,0,.95,.6); box('marble',x-.01,z,.34,d,.95,.99,.7)
    box('wood',x,z,.26,d,1.07,1.11,.6)
    zz=z+.15; k=0
    while zz<z+d-.1:
        bottle(x+.13+(.04 if k%3==1 else 0),zz,1.11,k*7%5); zz+=.17+.03*(k%3); k+=1
    floor_quad('rubber',x+.32,z,.55,d,.055,.5)
    box('teal',x1-.92,z+.1,.6,d-.2,0,1.02,.6)
    box('marble',x1-.98,z+.05,.72,d-.1,1.02,1.08,.7)
    box('brass',x1-.3,z+.2,.04,d-.4,.18,.22)
    for i in range(4): stool(x1-.14,z+.6+i*1.25)
    h=1.08
    obox('cream',x1-.65,z+.45,.38,.34,h,h+.18,.2); obox('dark',x1-.65,z+.45,.3,.28,h+.18,h+.3,.2)
    for i in range(4): glass(x1-.5,z+1.4+i*.15,h,i%2==0)
    for i in range(3): bottle(x1-.7,z+2.6+i*.13,h,i+1)
    cyl('white',x1-.55,z+3.6,.12,h,h+.06,8)
    for i in range(5): cyl('lime',x1-.55+math.cos(i)*.05,z+3.6+math.sin(i)*.05,.035,h+.04,h+.09,5)

def build_pool(x,z,w,d):
    """Sinuca: wooden table on four legs, green felt, pockets, the balls mid-game and a cue."""
    for sx in (.15,w-.25):
        for sz in (.15,d-.25): box('wood',x+sx,z+sz,.1,.1,0,.62)
    box('wood',x+.05,z+.05,w-.1,d-.1,.62,.78,.6)
    box('felt',x+.17,z+.17,w-.34,d-.34,.78,.8,.8)
    for zz in (z+.05,z+d-.17): box('wood',x+.05,zz,w-.1,.12,.78,.86,.6)
    for xx in (x+.05,x+w-.17): box('wood',xx,z+.17,.12,d-.34,.78,.86,.6)
    for px in (x+.17,x+w/2,x+w-.17):
        for pz in (z+.17,z+d-.17): cyl('black',px,pz,.06,.86,.865,6)
    balls=['white','yellow_paint','red_paint','ball_blue','black','orange','bottle_green','sequin_red']
    for i,mat in enumerate(balls):
        bx=x+.45+hsh(i,1,44)*(w-.9); bz=z+.35+hsh(i,2,44)*(d-.7)
        cyl(mat,bx,bz,.032,.8,.86,6)
    obox('wood',x+w*.6,z+d*.42,1.45,.025,.84,.86,.35)
    obox('ball_blue',x+.3,z+.12,.03,.03,.86,.89,0)

def build_vanity(x,z,w,d):
    """Dressing table against the wall: three mirrors framed by bulbs, make-up, a wig on its stand."""
    box('wood',x,z,w,d,0,.76,.6); box('cream',x-.02,z,w+.04,d+.03,.76,.8)
    n=3; mw=(w-.3)/n
    for i in range(n):
        mx=x+.15+i*mw
        decal('wood',mx+.02,mx+mw-.02,z+.005,.84,1.37); decal('screen',mx+.08,mx+mw-.08,z+.015,.9,1.3)
        for k in range(4): cyl('bulb',mx+.12+k*(mw-.24)/3,z+.05,.035,1.31,1.37,4)
        for hh in (1.0,1.15): cyl('bulb',mx+.06,z+.05,.03,hh,hh+.05,4); cyl('bulb',mx+mw-.06,z+.05,.03,hh,hh+.05,4)
        h=.8
        cyl('red_paint',mx+.25,z+.35,.018,h,h+.07,4); cyl('gold',mx+.35,z+.38,.05,h,h+.025,6)
        cyl('glass',mx+.55,z+.3,.03,h,h+.12,6); cyl('white',mx+.7,z+.4,.045,h,h+.03,6)
    cyl('ivory',x+w-.4,z+.3,.03,.8,1.0,4); cyl('ivory',x+w-.4,z+.3,.09,1.0,1.18,6)
    cyl('sequin_gold',x+w-.4,z+.3,.1,1.12,1.22,6)
    for i in range(2): stool(x+.7+i*1.6,z+d-.08)

def build_rack(x,z,w,d):
    """Costume rail: chrome stand with sequinned dresses and feathered capes hanging."""
    for px in (x+.08,x+w-.08):
        cyl('chrome',px,z+d/2,.025,0,1.35,4); obox('chrome',px,z+d/2,.06,.5,0,.04,0)
    box('chrome',x+.05,z+d/2-.015,w-.1,.03,1.32,1.35)
    colours=['sequin_red','sequin_gold','sequin_teal','velvet','sequin_red','white','sequin_gold','sequin_teal']
    n=int((w-.3)/.19)
    for i in range(n):
        hx=x+.18+i*.19
        box(colours[i%len(colours)],hx,z+.08,.08,d-.16,.5+(.15 if i%3==0 else 0),1.29)

def build_sofa(x,z,w,d,mat='leather'):
    """Tufted sofa with its back to the nearest wall: the long side decides which way it faces."""
    if w>=d:
        box('wood',x,z,w,d,0,.12)
        box(mat,x+.02,z+.22,w-.04,d-.24,.12,.44,.35)
        box(mat,x,z,w,.24,.12,.86,.35)
        for ax in (x,x+w-.16): box(mat,ax,z+.2,.16,d-.2,.12,.62,.35)
    else:
        box('wood',x,z,w,d,0,.12)
        box(mat,x+.22,z+.02,w-.24,d-.04,.12,.44,.35)
        box(mat,x,z,.24,d,.12,.86,.35)
        for az in (z,z+d-.16): box(mat,x+.2,az,w-.2,.16,.12,.62,.35)

def build_desk(x,z,w,d):
    """The boss's desk facing the door: pedestals, a banker's lamp, the phone and the money."""
    top=.76
    box('wood',x,z+.3,.5,d-.3,0,top); box('wood',x+w-.5,z+.3,.5,d-.3,0,top)
    box('wood',x+.5,z+d-.08,w-1.0,.04,.3,top)
    box('wood',x-.03,z+.27,w+.06,d-.24,top,top+.04,.6)
    chair(x+w/2,z+.12,math.pi/2,'leather')
    h=top+.04
    cyl('brass',x+.35,z+.55,.07,h,h+.03,6); cyl('brass',x+.35,z+.55,.012,h,h+.32,4)
    obox('green_paint',x+.35,z+.58,.32,.14,h+.3,h+.38,0)
    obox('black',x+w-.45,z+.6,.22,.17,h,h+.07,.3); obox('black',x+w-.45,z+.6,.24,.05,h+.07,h+.1,.3)
    for i in range(5): obox('money',x+.95+i*.17,z+.7,.15,.07,h,h+.03+.03*(i%2),.08*i)
    obox('white',x+1.55,z+.5,.25,.32,h,h+.006,.2); obox('white',x+1.62,z+.55,.25,.32,h+.006,h+.012,.45)
    cyl('glass',x+1.95,z+.45,.06,h,h+.02,6)

def build_safe(x,z,w,d):
    box('iron',x+.05,z,w-.1,d-.05,0,1.05,.5)
    box('pot',x+.12,z+d-.06,w-.24,.02,.12,.95)
    obox('brass',x+w/2,z+d-.035,.16,.03,.52,.68,0)
    box('brass',x+w/2+.2,z+d-.04,.04,.03,.4,.62)
    for i in range(2): obox('money',x+.3+i*.2,z+.35,.16,.08,1.05,1.09,.2*i)

def build_stalls(x,z,w,d):
    """Three toilet cubicles against the right wall: painted steel partitions and doors, the last
    door ajar."""
    n=3; depth=d/n
    for i in range(n+1):
        if 0<i: box('teal',x,z+i*depth-.02,w,.04,.12,1.3)
    for i in range(n):
        z0=z+i*depth; tz=z0+depth/2
        box('porcelain',x+w-.2,tz-.22,.18,.44,.4,.75)
        cyl('porcelain',x+w-.42,tz,.17,0,.42,8); cyl('white',x+w-.42,tz,.18,.42,.45,8)
        if i<n-1: box('teal',x,z0+.08,.04,depth-.16,.12,1.3)
        else:
            hx,hz=x,z0+.08; yaw=math.pi/2-.9; cx,cz=local(hx,hz,yaw,(depth-.16)/2,0)
            obox('teal',cx,cz,depth-.16,.04,.12,1.3,yaw)
    cyl('yellow_paint',x-.25,z+d+.1-.3,.14,0,.3,6); cyl('iron',x-.25,z+d-.2,.012,.3,1.05,4)

def build_basins(x,z,w,d):
    """Pedestal washbasins under their mirrors along the wall behind them, as many as fit."""
    n=max(1,int(w/.85)); pitch=w/n
    for i in range(n):
        bx=x+pitch*(i+.5)
        cyl('porcelain',bx,z+.25,.08,0,.72,6)
        box('porcelain',bx-.28,z+.02,.56,.46,.72,.86)
        box('screen',bx-.2,z+.08,.4,.32,.86,.862)
        cyl('chrome',bx,z+.08,.02,.86,1.0,4); obox('chrome',bx,z+.15,.03,.14,.97,1.0,0)
        decal('chrome',bx-.31,bx+.31,z+.005,.98,1.37); decal('screen',bx-.27,bx+.27,z+.015,1.02,1.33)
    obox('white',x+w-.15,z+.3,.18,.3,.0,.5,0)

def build_ticket(x,z,w,d):
    """Bilheteria: a red booth by the door, glazed on top, its name toward the street."""
    box('red_paint',x,z,w,d,0,1.0,.6)
    box('wood',x-.04,z-.02,w+.06,d+.04,1.0,1.04)
    box('glass',x+.03,z+.03,w-.06,d-.06,1.04,1.3)
    for px,pz in ((x,z+d-.05),(x+w-.05,z+d-.05),(x,z)):
        box('gold',px,pz,.05,.05,1.04,1.3)
    box('wood',x-.02,z-.02,w+.04,d+.04,1.3,1.34)
    text('cream','BILHETERIA',x+w/2,z+d+.012,.6,.13)
    stool(x+w/2+.25,z+.55)
    obox('cream',x+.4,z+.5,.3,.24,1.04,1.12,0); cyl('white',x+.75,z+.9,.05,1.04,1.1,6)

def build_hill():
    """Behind the back muro the houses climb the hill toward Santa Teresa, row above row, dark
    but for a few windows still lit."""
    rows=[(-11.2,-15.5,0.0,[(-27,-20,4.8,'facade_yellow'),(-20,-13,5.6,'ochre'),(-13,-7,4.6,'facade_pink'),(-7,0,5.4,'facade_blue'),
            (0,6,5.0,'facade_green'),(6,13,5.8,'facade_pink'),(13,20,4.6,'ochre'),(20,27,5.2,'facade_blue')]),
        (-16.6,-20.6,3.0,[(-27,-19,4.6,'facade_green'),(-19,-12,5.2,'facade_pink'),(-12,-4,4.4,'ochre'),(-4,3,5.0,'facade_yellow'),
            (3,11,4.6,'facade_blue'),(11,18,5.4,'facade_green'),(18,27,4.8,'facade_yellow')]),
        (-21.8,-25.8,6.0,[(-27,-17,5.0,'facade_blue'),(-17,-9,4.4,'facade_yellow'),(-9,0,5.2,'facade_pink'),(0,8,4.6,'ochre'),
            (8,17,5.0,'facade_green'),(17,27,4.4,'facade_pink')])]
    for r,(front,back,base,houses) in enumerate(rows):
        if base: box('concrete',-27,front-.1,54,.5,0,base,1.2)   # retaining wall under the row
        for i,(x0,x1,h,paint) in enumerate(houses):
            kit.sobrado(x0,x1,front,back,h,paint,doors=False,base=base)
            n=max(1,int((x1-x0)/2.2))
            for k in range(n):
                if hsh(r*31+i,k,45)>.84:
                    wx=x0+(x1-x0)*(k+.5)/n
                    wall_quad('window_lit',wx-.32,wx+.32,front+.04,base+h-2.25,base+h-.95,1,1)

def build():
    solids=layout['solids']
    # Ground: asphalt street, stone pavement, both alleys, the strip behind the block, interiors.
    floor_quad('asphalt',-30,-26,60,52,-.06,2.4)
    floor_quad('pedra',-30,8.15,60,2.5,.07,1.6)
    box('concrete',-30,10.65,60,.18,-.06,.09,.6,sides=False)
    wall_quad('concrete',-30,30,10.83,-.06,.09)
    floor_quad('concrete',-15.3,-9.6,2.05,17.75,.03,1.4)      # left alley
    floor_quad('concrete',13.0,-9.6,2.3,17.75,.03,1.4)        # right alley
    floor_quad('concrete',-13.25,-9.6,26.25,1.85,.03,1.4)     # strip behind the block
    floor_quad('pedra',-15.3,-11.2,30.6,1.6,.03,1.6)
    floor_quad('tacos',-7.2,-7.3,13.6,9.9,.04,1.6)            # salão
    floor_quad('tacos',-12.8,-7.3,5.2,4.9,.04,1.6)            # escritório
    floor_quad('cimento',-12.8,-2.0,5.2,4.6,.04,1.6)          # copa
    floor_quad('concrete',-12.8,3.0,5.2,4.7,.04,1.4)          # depósito
    floor_quad('vermelhao',-7.2,3.0,6.6,4.7,.04,1.6)          # sinuca
    floor_quad('granito',-0.2,3.0,6.6,4.7,.04,1.2)            # foyer
    floor_quad('granilite',6.8,-7.3,1.8,15.0,.04,1.2)         # corridor
    floor_quad('tacos',9.0,-7.3,3.55,5.1,.04,1.6)             # camarim
    floor_quad('cimento',9.0,-1.8,3.55,4.4,.04,1.6)           # ladies'
    floor_quad('cimento',9.0,3.0,3.55,4.7,.04,1.6)            # gents'
    for x,z,w,d in DOORS: floor_quad('granito',x,z,w,d,.045,.8)
    floor_quad('rubber',3.9,6.8,1.4,.7,.05,.5)                # doormat
    floor_star('inlay',-0.4,-1.0,1.15,.045)                   # the dance floor's star, inside the pillars
    floor_quad('rug',-11.4,-5.2,3.4,2.2,.045,.8)              # office rug
    walls=kit.wall_pieces(solids)
    for x,z,w,d,h in walls: build_wall(x,z,w,d,h,walls)
    builders={'stage':build_stage,'pillar':build_pillar,'bar':build_bar,'pool':build_pool,'vanity':build_vanity,
        'rack':build_rack,'sofa':build_sofa,'desk':build_desk,'safe':build_safe,'stalls':build_stalls,
        'basin':build_basins,'ticket':build_ticket,'prep':kit.build_prep,
        'crate':lambda x,z,w,d:(kit.build_crates if d>w else kit.build_kegs)(x,z,w,d)}
    tables=0
    for s in solids:
        x,z,w,d=s['r']; kind=s['type']
        if kind=='table':
            (kit.table_square if x<-5 or z>5 else kit.table_round)(x,z,w,d,tables); tables+=1
        elif kind in builders: builders[kind](x,z,w,d)
    decorate_inside()
    build_outside()

def decorate_inside():
    back=-7.29
    build_curtain(-4.1,3.3,-7.3)
    # Salão: the bar's neon and an old band photo in the left wing, posters and the clock in the
    # right wing, sconces either side of the stage.
    text('neon_cyan','BAR',-5.7,back+.03,1.65,.36)
    frame(-7.05,-6.45,back,1.45,2.0)
    for index,px in enumerate((4.0,4.7)): poster(index,px,back,1.1,2.1)
    decal('dark',5.6,6.0,back+.01,1.6,2.0); decal('white',5.64,5.96,back+.02,1.64,1.96)
    for px in (-4.8,3.68):
        box('brass',px,-7.3,.12,.12,1.9,1.94); cyl('bulb',px+.06,-7.24,.06,1.94,2.04,4)
    # Office: bookcase and a painting over the safe on the back wall.
    x0,width=-9.15,1.45
    box('wood',x0,-7.3,width,.25,0,2.2,.6)
    for k,h in enumerate((.3,.8,1.3,1.8)):
        box('wood',x0+.02,-7.3,width-.04,.24,h-.03,h)
        x=x0+.1; i=0
        while x<x0+width-.15:
            bw=.06+.04*hsh(i,k,48); bh=.3+.12*hsh(i,k,49)
            box(['books_a','books_b','books_c','cream'][int(hsh(i,k,50)*4)],x,-7.27,bw,.2,h,h+bh); x+=bw+.01; i+=1
    frame(-12.6,-11.2,back,1.35,2.15,'sequin_teal'); decal('yellow_paint',-12.2,-11.6,back+.025,1.6,1.9)
    text('cream','CONTABILIDADE',-8.42,back+.03,2.3,.11)
    # Pool room: cue rack and score beads on the wall it shares with the hall.
    decal('wood',-6.9,-6.1,3.01,.3,1.32)
    for i in range(4): box('wood',-6.82+i*.2,3.02,.03,.03,.1,1.3)
    decal('wood',-2.9,-1.5,3.01,1.0,1.3)
    for row in range(2):
        for i in range(9): decal('white' if (i+row)%3 else 'red_paint',-2.8+i*.14,-2.72+i*.14,3.02,1.08+row*.12,1.15+row*.12)
    # Foyer: a photograph between the hall door and the booth, palms by the corridor door.
    frame(3.3,3.85,3.0,.98,1.36,'ivory')
    for px,pz in ((6.05,3.4),(6.05,7.35)): palm(px,pz)
    # Corridor: the bathrooms' names on the floor at their doors, a payphone in the nook by the
    # foyer, a samba poster over the dressing table.
    text('cream','DAMAS',7.7,1.5,.05,.2,flat=True)
    text('cream','HOMENS',7.7,6.7,.05,.2,flat=True)
    box('orange',8.25,7.1,.35,.5,1.0,1.35); box('dark',8.4,7.2,.2,.3,1.05,1.3)
    poster(0,11.6,back,1.5,2.3)

def build_outside():
    # Front facade: painted name board, two neon stars, lanterns flanking the door.
    box('red_paint',-6.2,8.15,6.4,.04,.3,1.08)
    text('cream','GAFIEIRA ESTRELA',-3.0,8.2,.6,.3)
    text('yellow_paint','BAILE  •  SAMBA  •  CHORO',-3.0,8.2,.4,.11)
    for sx in (-6.75,.75): star('neon_yellow',sx,8.2,.72,.26)
    for px in (3.65,5.55):
        box('iron',px-.03,8.15,.06,.12,1.0,1.04); cyl('bulb',px,8.27,.06,1.04,1.22,4); cyl('iron',px,8.27,.08,1.22,1.28,4,r1=.02)
    for px in (3.8,5.4): box('wood',px-.07 if px>4.6 else px,7.65,.07,.55,0,1.3)
    # The copa's side door to the alley, swung open toward the back, clear of the exit.
    for pz in (-1.65,-0.2): box('wood',-13.3,pz,.55,.05,0,1.3)
    yaw=math.pi+.55; cx,cz=local(-13.25,-1.6,yaw,.6,0)
    obox('wood',cx,cz,1.2,.05,0,1.3,yaw)
    # Lampposts with lanterns along Rua do Lavradio, a Kombi parked across the street.
    for lx in (-10.0,1.0,12.8):
        cyl('iron',lx,10.95,.14,.09,.45,6); cyl('iron',lx,10.95,.06,.09,2.7,6)
        cyl('iron',lx,10.95,.16,2.7,2.74,4); cyl('bulb',lx,10.95,.11,2.74,3.0,4); cyl('iron',lx,10.95,.17,3.0,3.1,4,r1=.02)
    fx,fz=-5.0,12.7
    box('red_paint',fx-2.1,fz-.85,4.2,1.7,.3,1.02,.8)
    box('white',fx-2.1,fz-.85,4.2,1.7,1.02,1.85,.8)
    for i in range(5): wall_quad('screen',fx-1.85+i*.75,fx-1.25+i*.75,fz+.86,1.15,1.6,1,1)
    box('white',fx-2.15,fz-.8,.06,1.6,.35,.5); box('white',fx+2.09,fz-.8,.06,1.6,.35,.5)
    for wx in (-1.4,1.4):
        for wz in (-.8,.8): obox('tire',fx+wx,fz+wz,.6,.22,0,.55,0)
    # Trash bags against the alley walls, clear of the side door.
    for i,(bx,bz) in enumerate(((15.05,6.9),(15.1,7.5),(-15.05,4.3),(-15.1,5.0),(-15.0,-4.2))):
        obox('black',bx,bz,.45,.42,0,.4,i*.6); cyl('black',bx,bz,.11,.4,.52,4)
    # The back muro closes the block; the graffiti faces the camera at the end of the left alley.
    box('whitewash',-27,-10.4,54,.8,0,3.2,1.2)
    decal('graffiti',-15.7,-11.6,-9.59,.1,2.9)
    # Exit: scripts/exit_marker.gd lights it up once the hall is clear.
    kit.sobrado(-26,-19.5,8.15,-9.6,5.0,'facade_green',side=True)
    kit.sobrado(-19.5,-15.4,8.15,-9.6,4.6,'facade_pink',side=True)
    kit.sobrado(15.4,20.0,8.15,-9.6,4.8,'facade_blue',side=True)
    kit.sobrado(20.0,26.0,8.15,-9.6,5.4,'facade_yellow',side=True)
    build_hill()

if __name__=='__main__':
    with kit.workspace('Lavradio_PSX') as scene:
        make_palette()
        build()
        triangles=kit.assemble(scene)
        kit.export_glb(os.path.join(ROOT,'assets/environment/lavradio.glb'))
        bpy.data.libraries.write(os.path.join(ROOT,'tools/source/lavradio.blend'),{scene},fake_user=True,compress=True)
        print('LAVRADIO_READY',len(scene.objects),'meshes',triangles,'triangles',len(kit.images),'textures')
