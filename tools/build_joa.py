"""Estrada do Joá, night ten, generated in Blender through the installed MCP bridge.

- joa.glb (assets/level_10.json, docs/planejado/fase10-12.md): the Condomínio's council house on
  the slope over the sea, a modernist house of glass. The garden behind the wall the hero climbs
  and the guardhouse at the front; the deck with the infinity pool that reflects nothing on the
  left; the glass rooms in the middle (meeting room, office with the safe, living room, suite) round
  a stone wine cellar; the gourmet terrace on the right. The way out is the trail down the slope on
  the left. Behind it the Gávea's granite shoulder falls away to the sea, and the Elevado do Joá runs over the
water on its piers and curves round the hill out of the frame; in front the road bends with its pavement.

Same kit as every night (build_lagoa.py → build_guardiao.py → …). Collision comes from the level
file: the glass panes ("type":"glass") hold a body back but not sight or bullets.
    blender -b --factory-startup --python "godot 3d/tools/build_joa.py"
"""
import bpy, os, math, importlib.util

HERE=os.path.dirname(os.path.abspath(__file__))
spec=importlib.util.spec_from_file_location('lagoa_kit',os.path.join(HERE,'build_lagoa.py'))
lagoa=importlib.util.module_from_spec(spec); spec.loader.exec_module(lagoa)
guardiao=lagoa.guardiao; caju=lagoa.caju; st=lagoa.st; lav=lagoa.lav; kit=lagoa.kit
ROOT=kit.ROOT
box,obox,cyl,face=kit.box,kit.obox,kit.cyl,kit.face
wall_quad,floor_quad,decal,text=kit.wall_quad,kit.floor_quad,kit.decal,kit.text
C,grain=kit.C,kit.grain

def t_porcelanato(x,y):
    """Large light-grey porcelain slabs: one tone, a hairline joint every 32 pixels, no pattern."""
    c=C('c8c8c4')
    if x%32==0 or y%32==0: c=C('a8a8a4')
    return grain(c,x,y,.02,67)

def make_palette():
    lagoa.make_palette()
    kit.material('porcelanato',image=kit.texture('porcelanato',32,32,t_porcelanato))
    for name,color in {'aluminium':'1a1c1e','sheet':'f2f0ea','teak':'8a5a36','void':'05070a'}.items():
        kit.material(name,color)
    kit.material('pane','b8d6e8',alpha=.28)

def make_exterior_palette():
    for name,base,dark,seed,joint in (
        ('joa_rock','777c78','5c6866',121,0),('joa_stone','858a7e','666f65',122,16),
        ('joa_green','3f594b','30483d',123,0),('joa_green_dark','334d43','294039',124,0),
        ('joa_trail','97866c','796e5c',125,0),('joa_sea','1d3644','182d3b',126,0),
        ('joa_concrete','969e97','7e8c85',127,0),('joa_road','3d4850','303e47',128,0),
        ('joa_rock_dark','687470','566561',129,0),('joa_granite','c4c8c0','a2a9a2',132,0),('joa_granite_dark','aab0a9','8c958f',133,0),('joa_leaf','426454','355444',130,0),
        ('joa_leaf_dark','365444','2c463a',131,0)):
        size=16 if 'leaf' in name else 32
        kit.material(name,image=kit.texture(name,size,size,kit.cement(base,dark,.035,seed,joint)))
    for name,col in {'joa_steel':'3d525b','joa_trim':'b5bcac','joa_glass':'354d59',
        'joa_marking':'ada68c','joa_reflection':'4a6f7d'}.items():
        kit.material(name,col)
    kit.material('joa_lamp','b5a27b',emission='ccb18a',strength=.3)
    kit.material('joa_tail','a0453e',emission='c8453a',strength=.55)
    kit.material('joa_light','c9a25c',emission='e8a94e',strength=.5)

def ground_height(x,z):
    """Shared height field for the coastal slope and its trail: every path vertex is grounded."""
    if x<0:
        knots=[(-48,-18),(-35,-15),(-27,-8),(-22,-4),(-18,-1.3),(-15.1,-.08)]
    else:
        knots=[(15.1,-.08),(19,-.9),(25,-3.6),(32,-9),(40,-15),(52,-18)]
    for (a,ha),(b,hb) in zip(knots,knots[1:]):
        if a<=x<=b:
            h=ha+(hb-ha)*(x-a)/(b-a)
            return h+.16*math.sin(z*.43)*min(1,abs(x-(-15.1 if x<0 else 15.1))/8)
    return knots[0][1] if x<knots[0][0] else knots[-1][1]

def coastal_terrain():
    # The house sits on a slab and retaining courses above the same continuous land
    # that carries the escape trail. No detached grass plane or stacked tree cylinders.
    box('joa_stone',-13.25,-7.75,26.25,15.9,-3.1,-.65,1.4)
    box('joa_concrete',-13.42,-7.92,26.59,16.24,-.65,-.075,1.4)
    for side,xs in enumerate(([-48,-35,-27,-22,-18,-15.1],[15.1,19,25,32,40,52])):
        zs=[-13,-9,-5,-1,3,7,11,16,23]
        for i in range(len(xs)-1):
            for j in range(len(zs)-1):
                pts=[(x,-z,ground_height(x,z)) for x,z in ((xs[i],zs[j]),(xs[i+1],zs[j]),(xs[i+1],zs[j+1]),(xs[i],zs[j+1]))]
                mat='joa_green' if (i+j)%3 else 'joa_green_dark'
                face(mat,[pts[0],pts[1],pts[2]],2,(0,0,1))
                # Bedrock peeks out on the lower coast, away from the trail; there
                # are no broad rectangular rock patches beside the house.
                rock=(side==0 and i==0 and j%3==1) or (side==1 and i==4 and j%3==2)
                face('joa_rock' if rock else mat,[pts[0],pts[2],pts[3]],2,(0,0,1))
    floor_quad('grass',-15.1,-9.1,1.85,4.05,.04,1.6)
    floor_quad('grass',-15.1,-3.2,1.85,10.9,.04,1.6)
    floor_quad('grass',-13.25,-9.1,28.35,1.35,.04,1.6)
    floor_quad('grass',13.0,-9.1,2.1,17.25,.04,1.6)
    # Retaining stones and drainage details are visible along the deck's outside edge.
    for z in (-7,-3,1,5):
        box('joa_stone',-15.24,z,.13,2.5,-.65,-.02)
        box('joa_steel',-15.375,z+.8,.02,.18,-.45,-.34)

def bush(x,z,h,r):
    # Irregular triangular leaf volumes with no flat polygon caps.
    n=7
    ring=[(x+math.cos(k*math.tau/n)*r*(.85+.12*math.sin(k*2.1)),
        -z+math.sin(k*math.tau/n)*r,h+r*.22) for k in range(n)]
    for k in range(n):
        a,b=ring[k],ring[(k+1)%n]
        face('joa_leaf' if k%3 else 'joa_leaf_dark',[a,b,(x+r*.12,-z-r*.1,h+r*.95)],1.6)
        face('joa_leaf_dark',[(x,-z,h-r*.3),b,a],1.6)

def escape_trail():
    floor_quad('saibro',-15.1,-5.05,1.85,2.3,.04,1.4)
    points=[(-15.12,-4.1),(-17.3,-4.1),(-19.8,-2.6),(-18.8,-.3),
        (-22.2,1.7),(-24.7,3.5),(-25.4,6.1),(-29,7.9),(-32,6.1)]
    edges=[]
    for i,(x,z) in enumerate(points):
        a=points[max(0,i-1)]; b=points[min(len(points)-1,i+1)]
        dx,dz=b[0]-a[0],b[1]-a[1]; length=math.hypot(dx,dz)
        nx,nz=-dz/length*.58,dx/length*.58
        edges.append([(x+nx,z+nz),(x-nx,z-nz)])
    for i in range(len(points)-1):
        left,right=edges[i]; nl,nr=edges[i+1]
        quad=[(x,-z,ground_height(x,z)+.13) for x,z in (left,right,nr,nl)]
        face('joa_trail',[quad[0],quad[1],quad[2]],1,(0,0,1))
        face('joa_trail',[quad[0],quad[2],quad[3]],1,(0,0,1))
        # Stone edging follows the same surface instead of hovering beside flat steps.
        if i>0:
            for a,b in ((left,nl),(right,nr)):
                guardiao.strut('joa_stone',(a[0],a[1],ground_height(*a)+.12),
                    (b[0],b[1],ground_height(*b)+.12),.075)
        if i>=2:
            a,b=right,nr
            ha,hb=ground_height(*a),ground_height(*b)
            for (x,z),h in ((a,ha),(b,hb)):
                cyl('joa_steel',x,z,.035,h+.12,h+.9,5)
            guardiao.strut('joa_steel',(a[0],a[1],ha+.85),(b[0],b[1],hb+.85),.025)
    for i,(x,z) in enumerate([(-17,-7.1),(-19.8,-5.3),(-22.8,-2.0),(-21,4.3),(-27.2,3.1),(-28.2,10),(-33,9.0)]):
        bush(x,z,ground_height(x,z)+.1,.65+(i%3)*.18)

# What the camera can show behind the house. It looks down at 52 degrees: a point at height h and
# distance D beyond the origin sits at  .61 h + .79 D  up the screen, and the back wall of the house
# tops out at 6.97 with the frame ending at 14.7. Only that 7.7 m band is left for everything behind,
# so nothing there is a small copy of something far away. The house stands on the coast at the foot
# of the Gávea's granite shoulder, which falls away eastward to the sea; the Elevado do Joá runs over
# that water on its piers, and curves round the hill until it leaves through the top of the frame.
DECK=-5.0             # the Elevado's road surface, below the house floor
BEND=18.0             # east of here it runs straight; west of here it curves away north
HALF=3.0              # half of its two lanes

def road_z(x):
    return -19.0-.02*max(0.0,BEND-x)**2

def road_slope(x):
    return .04*max(0.0,BEND-x)

def on_road(x,off):
    """A point of the Elevado: `off` metres across it from its centre line, positive toward the camera."""
    slope=road_slope(x)
    n=math.hypot(1,slope)
    return (x-off*slope/n,road_z(x)+off/n)

def smooth(a,b,v):
    t=max(0.0,min(1.0,(v-a)/(b-a)))
    return t*t*(3-2*t)

def shore(x):
    """Where the land's edge runs behind the house: at the garden, then swinging out to the east."""
    return -9.1-3.9*smooth(5.0,15.1,x)

def hill_share(x,z):
    """How much of the hill stands here: all of it to the west, none to the east or past the road."""
    return smooth(4.0,-7.0,x)*smooth(2.0,9.0,z-(road_z(x)+HALF))

def hill_height(x,z):
    """One surface for the land behind the house: it rises as the hill, or falls to the sea."""
    z0=shore(x)
    h0=-.08 if abs(x)<=15.1 else ground_height(x,z0)+(.04 if x>0 else 0)   # just over the slope it meets
    d=max(0.0,z0-z)
    down=max(-15.6,h0-d-.26*d*d)
    wobble=(.22*math.sin(.7*x+.9*z)+.12*math.sin(1.3*x-.6*z))*min(d,6.0)/6.0
    up=h0+.72*d+.07*d*d+wobble
    return down+(up-down)*hill_share(x,z)

def granite_at(x,h,z):
    """Bare rock where the hill stands tall; its edge wanders, but in long lines, not in shards."""
    return hill_share(x,z)>.6 and h>2.4+.7*math.sin(x*.28)+.3*math.sin(x*.9)

def hillside():
    """The heightfield, broken into uneven triangles: bare granite high up, forest on its foot and
    flanks, wet rock at the waterline. Trees are crowns seen from above, as the camera sees them."""
    cols=[-46+i*2.0 for i in range(31)]+[15.1]+[16.5+i*2.5 for i in range(5)]
    cols=sorted(cols)
    rows=[-9.1,-10.2,-11.4,-12.6,-13.2,-14.2,-15.6,-17.2,-19,-21,-24,-28,-34]
    def pt(i,k):
        x,z=cols[i],rows[k]
        if k>0 and abs(x)!=15.1: x+=.22*math.sin(i*2.3+k*1.7); z+=.12*math.sin(i*1.1+k*2.9)
        return (x,z,hill_height(x,z))
    def surface(p,q,r):
        x=(p[0]+q[0]+r[0])/3; z=(p[1]+q[1]+r[1])/3; h=(p[2]+q[2]+r[2])/3
        pick=int(abs(x*3.1+z*7.3))%3
        if h<-7: return ('joa_rock','joa_rock_dark','joa_rock')[pick]
        if granite_at(x,h,z): return ('joa_granite','joa_granite','joa_granite_dark')[pick]
        return ('joa_green','joa_green_dark','joa_green')[pick]
    for i in range(len(cols)-1):
        for k in range(len(rows)-1):
            if cols[i]>=15.1 and rows[k]>-12.6: continue   # east of the lot the coastal slope is already there
            a,b,c,d=pt(i,k),pt(i+1,k),pt(i+1,k+1),pt(i,k+1)
            tris=[(a,b,c),(a,c,d)] if (i+k)%2 else [(a,b,d),(b,c,d)]
            for p,q,r in tris:
                face(surface(p,q,r),[(v[0],-v[1],v[2]) for v in (p,q,r)],2,(0,0,1))
    # Tree crowns scattered over the forest; none on the granite or over the water.
    for i in range(90):
        x=-34+((i*7.77)%50); z=-9.6-((i*3.31)%6.5)
        h=hill_height(x,z)
        if h<-.8 or granite_at(x,h,z): continue
        bush(x,z,h+.15,.7+(i%4)*.16)

def road_ribbon(mat,off0,off1,h,xs,scale=1.6):
    for x,nx in zip(xs,xs[1:]):
        a,b=on_road(x,off0),on_road(x,off1); c,d=on_road(nx,off1),on_road(nx,off0)
        face(mat,[(p[0],-p[1],h) for p in (a,b,c,d)],scale,(0,0,1))

def road_wall(mat,off,h0,h1,xs,scale=1.6):
    for x,nx in zip(xs,xs[1:]):
        a,b=on_road(x,off),on_road(nx,off)
        face(mat,[(a[0],-a[1],h0),(b[0],-b[1],h0),(b[0],-b[1],h1),(a[0],-a[1],h1)],scale,(0,-1,0))

def glow(mat,cx,cz,h,r):
    ring=[(cx+math.cos(k*math.tau/10)*r,-cz+math.sin(k*math.tau/10)*r,h) for k in range(10)]
    face(mat,ring,1,(0,0,1))

def viaduct():
    """The Elevado do Joá: two lanes on twin piers over the water, its near edge and both parapets
    following the curve, its lamps points of light in the dark."""
    xs=[-26+i*2.0 for i in range(23)]+[20+i*5.0 for i in range(11)]
    road_ribbon('joa_concrete',-HALF-.35,HALF+.35,DECK-.03,xs)
    road_ribbon('joa_road',-HALF,HALF,DECK,xs,2.4)
    road_wall('joa_concrete',HALF+.35,DECK-.9,DECK+.9,xs)      # the near fascia and parapet
    road_wall('joa_concrete',-HALF,DECK,DECK+.9,xs)            # the far parapet's inner face
    for a,b in ((HALF,HALF+.35),(-HALF-.35,-HALF)):
        road_ribbon('joa_concrete',a,b,DECK+.9,xs)
        road_ribbon('joa_steel',a+.12,b-.12,DECK+.98,xs)
    for off in (HALF-.3,-HALF+.22): road_ribbon('joa_marking',off,off+.08,DECK+.01,xs)
    dashes=[-26+i*1.0 for i in range(96)]
    for i in range(0,len(dashes)-1,4): road_ribbon('joa_marking',-.04,.04,DECK+.01,dashes[i:i+3])
    for x in (-6,3,12,21,31,41,51,61):
        px,pz=on_road(x,0)
        yaw=math.atan(road_slope(x))
        for off in (-1.9,1.9):
            qx,qz=on_road(x,off)
            cyl('joa_concrete',qx,qz,.42,-16,DECK-1.5,7)
        obox('joa_concrete',px,pz,1.2,6.8,DECK-1.5,DECK-.9,yaw)
    for x in (-3,6,15,25,35,45,55):
        qx,qz=on_road(x,HALF+.18)
        cyl('joa_steel',qx,qz,.05,DECK+.9,DECK+3.7,5)
        hx,hz=on_road(x,HALF-.7)
        box('joa_steel',hx-.05,hz,.1,.8,DECK+3.6,DECK+3.68)
        glow('joa_light',hx,hz,DECK+3.7,.3)   # the lamp itself: a point of light, seen from above
        # Its reflection, broken on the water under the road.
        wx,wz=on_road(x,HALF+4.5)
        for k in range(4): floor_quad('joa_reflection',wx-.3+k*.08,wz+k*.55,.5-k*.08,.09,-14.98)

def neighbor():
    # A contemporary house on a supported terrace replaces the unrelated colonial roof.
    x,z,w,d=17.2,-5.7,10.6,12.8
    box('joa_stone',x-.3,z-.3,w+.6,d+.6,-4.3,-.18,1.6)
    box('joa_concrete',x,z,w,d,-.18,.16,1.4)
    box('joa_glass',x+.6,z+.5,w-1.2,d-1.0,.16,2.5)
    box('joa_concrete',x+.2,z+.1,w-.4,d-.2,2.5,2.7,1.6)
    for pz in (z+1,z+4,z+7,z+10):
        box('joa_trim',x+.55,pz,.12,.12,.16,2.5)
    for px in (x+1,x+3.6,x+6.2,x+8.8):
        wall_quad('joa_glass',px,px+1.9,z+d-.48,.3,2.3)
        box('joa_steel',px,z+d-.46,.045,.035,.16,2.5)
    # Recessed roof garden and a pergola give the slab scale in the bird's eye view.
    box('joa_stone',x+6.2,z+1,2.4,3.6,2.7,2.93)
    for i in range(3): bush(x+7.3,z+1.7+i,3.0,.55)
    for px in (x+1,x+5.2):
        for pz in (z+6,z+10.4): box('joa_steel',px,pz,.05,.05,2.7,3.72)
        box('teak',px,z+6,.08,4.6,3.62,3.72)
    for i in range(9): box('teak',x+1,z+6+i*.55,4.2,.12,3.72,3.8)
    for pz in (z+.5,z+5,z+10):
        box('joa_concrete',x-.4,pz,.35,.4,-4.7,2.45)
    for i in range(5): bush(29.5,-7+i*3,ground_height(29.5,-7+i*3)+.1,.8)

KERB=10.6     # the pavement's outer edge in front of the lot, then it follows the road round the bend
def kerb(x):
    return KERB+.012*max(0.0,abs(x)-15.3)**2

def lane(x0,x1,off0,off1,h,mat,scale=1.4):
    """A strip along the kerb line, between two offsets (positive to the road side), at height h."""
    def edge(x,off):
        slope=.024*max(0.0,abs(x)-15.3)*(1 if x>0 else -1)
        n=math.hypot(1,slope)
        return (x+off*-slope/n,-(kerb(x)+off/n),h)
    a0,a1,b0,b1=edge(x0,off0),edge(x0,off1),edge(x1,off0),edge(x1,off1)
    face(mat,[a0,b0,b1,a1],scale,(0,0,1))

def approach_road():
    """The pavement and the road run from one edge of the view to the other, bending together: the
    pavement is always 2.45 m wide beside its kerb, so it never ends in the grass."""
    xs=[-60+k*3.0 for k in range(41)]
    segs=[(-15.3,15.3)]+[(a,b) for a,b in zip(xs,xs[1:]) if b<=-15.3 or a>=15.3]
    segs=[(a,b) for a,b in segs if a>=-60.01 and b<=60.01]
    # Make the outer runs start exactly where the straight frontage ends.
    left=[-15.3]+[x for x in xs if x<-15.3][::-1]; right=[15.3]+[x for x in xs if x>15.3]
    runs=[(-15.3,15.3)]+list(zip(left[1:],left))+list(zip(right,right[1:]))
    for a,b in runs:
        lo,hi=(min(a,b),max(a,b))
        lane(lo,hi,-2.45,0,.07,'pedra')                  # the pavement
        lane(lo,hi,0,.16,.07,'joa_stone')                # the kerb
        lane(lo,hi,.16,6.56,0.0,'joa_road',2.4)          # the road, two lanes
        lane(lo,hi,.16,.4,.012,'joa_marking',1.4)        # its edge lines
        lane(lo,hi,6.3,6.5,.012,'joa_marking',1.4)
        lane(lo,hi,3.3,3.38,.012,'joa_marking',1.4) if int(lo//3)%2 else None
    # The road's low side: a stone face under its outer edge, so it never floats above the slope.
    for k in range(40):
        x=-60+k*3.0
        face('joa_stone',[(x,-(kerb(x)+6.56),0),(x+3,-(kerb(x+3)+6.56),0),(x+3,-(kerb(x+3)+6.56),-5),(x,-(kerb(x)+6.56),-5)],1.6,(0,1,0))
    wall_quad('joa_stone',-8.9,8.9,8.23,.1,1.25)
    text('joa_trim','MIRANTE DO JOÁ',.4,8.27,.65,.22)
    for k in range(-7,8):
        x=k*6.0
        cyl('joa_steel',x,kerb(x)-.55,.035,.07,1.15,5)
        box('joa_lamp',x-.065,kerb(x)-.62,.13,.13,1.08,1.2)

# ---------------------------------------------------------------- the plan
ROOMS10=[('jardim',-12.8,9.0,2.6,7.7),('guarita',9.4,12.55,5.0,7.7),('deck',-12.8,-6.0,-7.3,2.6),('gourmet',8.0,12.55,-7.3,4.6),
    ('reuniao',-5.6,0.6,-7.3,-3.2),('escritorio',1.0,7.6,-7.3,-3.2),('adega',-5.6,-2.4,-2.8,2.2),('estar',-2.0,3.6,-2.8,2.2),
    ('suite',4.0,7.6,-2.8,2.2)]
SKINS10={'jardim':('whitewash',1.4,False),'guarita':('concrete',1.4,False),'deck':('whitewash',1.4,False),'gourmet':('whitewash',1.4,False),
    'reuniao':('whitewash',1.4,False),'escritorio':('whitewash',1.4,False),'adega':('stonewall',1.4,False),'estar':('whitewash',1.4,False),
    'suite':('whitewash',1.4,False),'outside':('whitewash',1.4,False)}

# ---------------------------------------------------------------- props
def build_glass(x,z,w,d):
    """A floor-to-cut glass pane in a thin black aluminium frame, mullions every 1.2 m."""
    along=w>=d; length=w if along else d
    box('pane',x+(.0 if along else w/2-.02),z+(d/2-.02 if along else 0),w if along else .04,.04 if along else d,0,1.4)
    n=max(1,round(length/1.2))
    for k in range(n+1):
        t=k*length/n
        px,pz=(x+t,z+d/2) if along else (x+w/2,z+t)
        box('aluminium',px-.025,pz-.025,.05,.05,0,1.42)
    if along:
        box('aluminium',x,z+d/2-.03,w,.06,0,.05); box('aluminium',x,z+d/2-.03,w,.06,1.38,1.42)
    else:
        box('aluminium',x+w/2-.03,z,.06,d,0,.05); box('aluminium',x+w/2-.03,z,.06,d,1.38,1.42)

def build_kingbed(x,z,w,d):
    """Low platform bed, white sheets, two pillows at the wall end, a grey throw."""
    box('dark',x,z,w,d,0,.25,.6)
    box('sheet',x+.05,z+.05,w-.1,d-.1,.25,.5,.6)
    for k in range(2): box('white',x+.2+k*(w/2-.1),z+.12,w/2-.3,.35,.5,.62)
    box('pot',x+.05,z+d*.6,w-.1,d*.3,.5,.53)

def build_lounger(x,z,w,d):
    """Teak sun lounger, the back raised at one end."""
    along_z=d>=w
    for sx,sz in ((x+.05,z+.05),(x+w-.1,z+.05),(x+.05,z+d-.1),(x+w-.1,z+d-.1)): box('teak',sx,sz,.05,.05,0,.28)
    box('teak',x,z,w,d*(.7 if along_z else 1),.28,.33)
    if along_z: obox('teak',x+w/2,z+d*.83,w,d*.32,.3,.55,0)
    box('white',x+.08,z+.1,w-.16,d*.5,.33,.36)

def build_infinity(x,z,w,d):
    """The infinity pool that reflects nothing: a white coping and black water with no shine."""
    box('pool_edge',x,z,w,d,0,.3,.8)
    floor_quad('void',x+.12,z+.12,w-.24,d-.24,.305,1.0)

# ---------------------------------------------------------------- inside
def decorate_inside():
    back=-7.29
    # The meeting room: a long abstract canvas over the table; the office: the safe's wall map.
    box('dark',-5.2,back,3.0,.02,1.5,2.3); decal('paintings',-5.1,-2.3,back+.025,1.55,2.25,.5,.75)
    box('cream',2.0,back,1.8,.02,1.5,2.3); text('red_paint','PRAÇA MAUÁ',2.9,back+.03,1.95,.1)
    box('red_paint',2.7,back+.03,.06,.01,1.7,1.8)
    # The suite: a bedside lamp; the cellar: candles on the barrels.
    cyl('bulb',4.4,-2.4,.08,.7,.85,6)
    for k in range(3): cyl('bulb',-4.4+k*.8,1.8,.02,1.0,1.08,4)
    # The guardhouse: a barrier arm and the CCTV screen.
    box('red_paint',8.0,7.4,1.4,.06,.9,.96); box('white',8.3,7.4,.3,.06,.9,.96)
    box('screen',11.0,7.69,.8,.01,1.0,1.3); box('tv_glow',11.05,7.68,.7,.005,1.03,1.27)

# ---------------------------------------------------------------- outside
def build_outside():
    make_exterior_palette()
    floor_quad('joa_sea',-70,-65,140,120,-15.0,3)
    coastal_terrain()
    hillside()
    viaduct()
    escape_trail()
    neighbor()
    approach_road()
    # Quiet stepped ripples on the water below the road.
    for k in range(46):
        x=-2+(k%9)*4.6+(k//9)*1.3; z=-34+(k//9)*2.9+((k*5)%3)*.7
        floor_quad('joa_reflection',x,z,.4+(k%3)*.34,.03,-14.99)

def build_level10():
    data=st.load('level_10.json'); solids=data['solids']
    build_outside()
    floor_quad('grass',-12.8,2.6,21.8,5.1,.04,1.6)
    floor_quad('cimento',9.4,5.0,3.15,2.7,.04,1.6)
    floor_quad('deck',-12.8,-7.3,6.8,9.9,.04,1.0)
    floor_quad('pedra',8.0,-7.3,4.55,11.9,.04,1.4)
    floor_quad('porcelanato',-6.0,-7.3,14.0,4.1,.04,1.6)
    floor_quad('porcelanato',-2.4,-3.2,10.4,5.4,.04,1.6)
    floor_quad('cimento',-5.6,-2.8,3.2,5.0,.04,1.6)
    for k in range(4): floor_quad('pedra',-9.4+k*2.6,4.1,1.0,.6,.045,.8)   # stepping stones across the lawn
    walls=kit.wall_pieces([s for s in solids if s['type']!='glass'])
    for x,z,w,d,h in walls: lav.build_wall(x,z,w,d,h,walls,ROOMS10,SKINS10)
    for i,s in enumerate(solids):
        x,z,w,d=s['r']; kind=s['type']
        if kind=='wall': continue
        if kind=='plinth': st.build_plinth(x,z,w,d,i%3)
        elif kind=='hedge': st.build_hedge(x,z,w,d,s['h'])
        else:
            {'glass':build_glass,'meeting':guardiao.build_meeting,'desk':lav.build_desk,'safe':lagoa.build_safe7,
             'shelves':st.build_shelves,'sofa':lav.build_sofa,'winerack':lagoa.build_winerack,'kingbed':build_kingbed,
             'pool':build_infinity,'lounger':build_lounger,'plant':guardiao.build_plant,'counter':lagoa.build_bar_counter,
             'cocktail':lagoa.build_cocktail}[kind](x,z,w,d)
    decorate_inside()

if __name__=='__main__':
    with kit.workspace('Joa') as scene:
        make_palette()
        build_level10()
        triangles=kit.assemble(scene)
        kit.export_glb(os.path.join(ROOT,'assets/environment/joa.glb'))
        bpy.data.libraries.write(os.path.join(ROOT,'tools/source/joa.blend'),{scene},fake_user=True,compress=True)
        print('JOA_READY',len(scene.objects),'meshes',triangles,'triangles',len(kit.images),'textures')
