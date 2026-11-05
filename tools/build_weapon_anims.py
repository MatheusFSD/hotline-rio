"""Long-gun clips for the UAL rig, posed in Blender (tuned through the MCP bridge, built headless).

The animation library only has pistol clips. Each clip here starts from the pistol idle (legs,
fingers) and re-poses the upper body around the gun: the gun is placed in character space
(stock on the shoulder, kick, reload tilt), then the right fist is solved onto its grip and the
left fist onto the support point, magazine or belt with analytic two-bone IK, and every frame
is keyed. The fist frame is measured from the finger bones, the same way scripts/actor_visual.gd
attaches the gun, so the gun sits in the palm in both places.

Character space is Blender's: the rig faces -Y, its right is -X, Z is up. Gun space is the hand
GLB's: +X right, +Y toward the muzzle, +Z up, grip at the origin. Writes
assets/animations/weapon_clips.glb (rig, hero skin and the clips as NLA tracks).
"""
import bpy, os, json, math
from mathutils import Vector, Matrix

HERE=os.path.dirname(os.path.abspath(__file__))
ROOT=os.path.dirname(HERE)
FPS=60          # bake rate: a 25-40 ms kick needs more than 24 fps to show
SOURCE_FPS=24   # rate of the library's pistol idle the clips start from
FWD,RIGHT,UP=Vector((0,-1,0)),Vector((-1,0,0)),Vector((0,0,1))
# The rig has no twist bones, so turning a palm over (a support hand under a pump is ~170 deg
# from the rest pose's palm-down) would all land on the wrist and pinch the skin. Like a real
# arm, the roll is spread out: the upper arm rolls in the shoulder before the IK (ARM_ROLL),
# then the forearm takes TWIST_SHARE of what is left at the wrist. Only bones move.
GUARD_ROLL=math.radians(80)   # upper-arm roll for the palm-up support grip
TWIST_SHARE={'r':.6,'l':.65}
with open(os.path.join(ROOT,'assets/weapons/weapons.json')) as f: MANIFEST=json.load(f)

def gun_point(gun,key):
    x,y,z=MANIFEST[gun][key]          # Godot gun space -> Blender gun space
    return Vector((x,-z,y))

def fist_frame(origin,knuckles,axis):
    """Fist frame: Y toward the knuckles, Z along the fist's hole (pinky to index), X = Y x Z."""
    a=axis.normalized(); k=(knuckles-a*knuckles.dot(a)).normalized()
    m=Matrix((k.cross(a),k,a)).transposed().to_4x4(); m.translation=origin
    return m

# Left fist orientations in gun space.
# Under the pump or handguard, palm up, index toward the muzzle, fingers closing over the right side.
GUARD=fist_frame(Vector(),Vector((1,0,.6)),Vector((0,1,0)))
VERTICAL=fist_frame(Vector(),Vector((0,1,0)),Vector((0,0,1)))   # around a vertical grip, like the right hand

def smooth(keys,t):
    """Smoothstep between (time, value) keys; values are floats or Vectors."""
    if t<=keys[0][0]: return keys[0][1]
    for (t0,v0),(t1,v1) in zip(keys,keys[1:]):
        if t<=t1:
            u=(t-t0)/(t1-t0) if t1>t0 else 1.0
            u=u*u*(3-2*u)
            return v0+(v1-v0)*u
    return keys[-1][1]

def blend(m0,m1,u):
    q=m0.to_quaternion().slerp(m1.to_quaternion(),u)
    m=q.to_matrix().to_4x4(); m.translation=m0.translation.lerp(m1.translation,u)
    return m

def gun_basis(pitch=0.,roll=0.,yaw=0.):
    """Gun pointing at the character's forward, then pitched (muzzle up), rolled and yawed."""
    base=Matrix((RIGHT,FWD,UP)).transposed()
    return (base@Matrix.Rotation(yaw,3,'Z')@Matrix.Rotation(roll,3,'Y')@Matrix.Rotation(pitch,3,'X')).to_4x4()

class Poser:
    def __init__(self,rig):
        self.rig=rig; self.pb=rig.pose.bones
        rig.animation_data_create()
        self.idle=bpy.data.actions['Pistol_Idle_Loop']
        self.idle_frames=int(round(self.idle.frame_range[1]-self.idle.frame_range[0]))
        self.base_cache={}
        self.twists=[]   # (before, after) wrist twist of every solved hand, for the report
        self.set_base(0)
        self.pistol_left=self.fist('r').inverted()@self.fist('l')   # support hand around the pistol hand
        self.hand_from_fist={s:self.fist(s).inverted()@self.pb['hand_'+s].matrix for s in 'rl'}

    def update(self): bpy.context.view_layer.update()
    def head(self,name): return self.pb[name].head.copy()

    def set_base(self,frame):
        """Pistol idle pose at a (fractional) source frame, without leaving the action assigned."""
        frame=round(frame%self.idle_frames,3)
        if frame not in self.base_cache:
            ad=self.rig.animation_data
            for t in ad.nla_tracks: t.mute=True
            ad.action=self.idle
            if hasattr(ad,'action_slot') and len(self.idle.slots): ad.action_slot=self.idle.slots[0]
            bpy.context.scene.frame_set(int(frame),subframe=frame-int(frame))
            self.base_cache[frame]={p.name:p.matrix_basis.copy() for p in self.pb}
            ad.action=None
        for p in self.pb: p.matrix_basis=self.base_cache[frame][p.name]
        self.update()

    def fist(self,s):
        c=(self.head('middle_01_'+s)+self.head('middle_03_'+s))/2
        return fist_frame(c,self.head('middle_01_'+s)-self.head('hand_'+s),self.head('index_01_'+s)-self.head('pinky_01_'+s))

    def turn(self,name,axis,angle):
        if not angle: return
        p=self.pb[name]; h=p.head.copy()
        p.matrix=Matrix.Translation(h)@Matrix.Rotation(angle,4,axis)@Matrix.Translation(-h)@p.matrix
        self.update()

    def reach(self,s,target,pole,relax=0.,roll=0.):
        """Two-bone IK: wrist to the target, elbow toward the pole, hand takes the target's rotation.
        relax blends that rotation toward the hand's own pose on the forearm (an empty hand)."""
        up,lo,hand=self.pb['upperarm_'+s],self.pb['lowerarm_'+s],self.pb['hand_'+s]
        S,E=up.head.copy(),lo.head.copy()
        if pole is None: pole=E-S   # keep the elbow where the base pose has it
        if roll:
            up.matrix=Matrix.Translation(S)@Matrix.Rotation(roll,4,(E-S).normalized())@Matrix.Translation(-S)@up.matrix
            self.update()
        W=hand.head.copy()
        a,b=(E-S).length,(W-E).length
        to=target.translation-S
        d=min(max(to.length,abs(a-b)+1e-3),a+b-1e-3)
        n=to.normalized()
        bend=(pole-n*pole.dot(n)).normalized()
        cos_a=(a*a+d*d-b*b)/(2*a*d)
        elbow=S+n*a*cos_a+bend*a*math.sqrt(max(0.,1-cos_a*cos_a))
        q=(E-S).rotation_difference(elbow-S)
        up.matrix=Matrix.Translation(S)@q.to_matrix().to_4x4()@Matrix.Translation(-S)@up.matrix
        self.update()
        E,W=lo.head.copy(),hand.head.copy()
        q=(W-E).rotation_difference(S+n*d-E)
        lo.matrix=Matrix.Translation(E)@q.to_matrix().to_4x4()@Matrix.Translation(-E)@lo.matrix
        self.update()
        rot=target.to_3x3().normalized().to_quaternion()
        if relax: rot=rot.slerp(hand.matrix.to_3x3().normalized().to_quaternion(),relax)
        m=rot.to_matrix().to_4x4(); m.translation=hand.head.copy()
        hand.matrix=m
        self.update()
        # Pronation: the forearm rolls about its own axis (the wrist stays put), the hand re-aims.
        before=self.twist('hand_'+s)
        E=lo.head.copy(); axis=(hand.head-E).normalized()
        lo.matrix=Matrix.Translation(E)@Matrix.Rotation(before*TWIST_SHARE[s],4,axis)@Matrix.Translation(-E)@lo.matrix
        self.update()
        m.translation=hand.head.copy(); hand.matrix=m
        self.update()
        self.twists.append((s,abs(self.twist('upperarm_'+s)),abs(self.twist('lowerarm_'+s)),abs(self.twist('hand_'+s))))
        return to.length-(a+b)   # > 0: the target was out of reach by this much

    def twist(self,bone):
        """Roll of a bone about its own axis relative to rest (radians, -pi..pi): where the skin twists."""
        q=self.pb[bone].matrix_basis.to_quaternion()
        if q.w<0: q.negate()
        return 2*math.atan2(q.y,q.w)

    def pose(self,clip,t):
        """Applies one clip moment; returns the gun matrix in character space."""
        self.set_base(t*SOURCE_FPS if clip.get('breathe') else 0)
        spec=clip['at'](self,t)
        for bone,axis,angle in spec.get('spine',[]): self.turn(bone,axis,angle)
        gun=spec['gun'](self)
        miss_r=self.reach('r',gun@self.hand_from_fist['r'],spec['pole_r'])
        left,relax,roll=spec['left'](gun)
        miss_l=self.reach('l',left@self.hand_from_fist['l'],spec['pole_l'],relax,roll)
        return gun,max(miss_r,miss_l)

# ---------------------------------------------------------------- stances and clips
LONG_POLE_L=Vector((0,0,-1))    # support elbow points down under the gun
LONG_SPINE=[('spine_02',UP,-.3),('spine_03',UP,-.2),('neck_01',UP,.3),('Head',UP,.2)]
SMG_SPINE=[('spine_02',UP,-.1),('neck_01',UP,.1)]

def shouldered(gun,pitch=0.,roll=0.,back=0.,drop=0.,inward=0.,yaw=0.):
    """Stock butt in the right shoulder pocket, rotating about it (kick climbs the muzzle)."""
    def place(p):
        pocket=p.head('upperarm_r')+Vector((.07,-.05,-.05))
        R=gun_basis(pitch,roll,yaw)
        m=R.copy(); m.translation=pocket-R.to_3x3()@gun_point(gun,'stock')-FWD*back-UP*drop-RIGHT*inward
        return m
    return place

def at_chest(pitch=0.,roll=0.,back=0.,drop=0.,yaw=0.):
    """SMG held out at chest height, elbows bent, rotating about the grip."""
    def place(p):
        R=gun_basis(pitch,roll,yaw)
        R.translation=p.head('upperarm_r')+Vector((.1,-.42,-.1))-FWD*back-UP*drop
        return R
    return place

# ---------------------------------------------------------------- recoil
# What the clips copy (high-speed footage and shooters' accounts):
# pistol: the grip stops the slide, so the gun rotates up about the hand (muzzle flip), the wrist
#   takes it and it snaps back; SMG: light per round, but the bolt slamming makes bursts buzz;
#   rifle (AK type): a push into the shoulder ~30-40% stronger than an AR's, little climb;
#   12 gauge: a heavy shove rather than a snap, rocking shoulder and chest back with the most muzzle
#   rise, then the pump is racked. The minigun has no per-round kick but a steady push (~68 kg
#   average); that one is live in scripts/actor_visual.gd. Times in s, angles in rad, push in m.
# The clips restart on every round, so automatic fire keeps them in the first, sharpest part.
RECOIL={
    'pistol':dict(rise=.04,recover=.16,pitch=.38,back=.025,lean=.02,shoulder=0.),
    'smg':dict(rise=.025,recover=.085,pitch=.07,back=.022,lean=.015,shoulder=.03,yaw=.015),
    'rifle':dict(rise=.035,recover=.15,pitch=.1,back=.045,lean=.05,shoulder=.08,yaw=.02),
    'shotgun':dict(rise=.06,recover=.26,pitch=.22,back=.08,lean=.14,shoulder=.14)}

def kick(t,rise,recover,**_):
    """0 to 1 fast (easing out), back over recover, settling slightly past rest."""
    if t<rise:
        u=t/rise; return 1-(1-u)*(1-u)
    u=min(1.,(t-rise)/recover); s=u*u*(3-2*u)
    return (1-s)-.12*math.sin(math.pi*s)*s

def body_rock(spine,profile,k):
    """The push rocks the chest and the right shoulder back; the neck counters so the eyes stay on target."""
    lean=profile['lean']*k
    return spine+[('spine_02',RIGHT,lean*.6),('spine_03',RIGHT,lean*.4),('clavicle_r',UP,-profile['shoulder']*k),('neck_01',RIGHT,-lean*.7)]

RELAXED=None   # an empty hand (belt, magazine on its way): keeps its own pose on the forearm

def left_hand(keys,t):
    """keys: (time, space, point, orientation); 'gun' points move with the gun, 'body' ones stay.
    Returns the fist target, how relaxed the hand is and the upper arm's roll."""
    def resolve(gun,key):
        _,space,point,orient=key
        where=gun@point if space=='gun' else point
        m=(gun.to_3x3()@(orient or GUARD).to_3x3()).to_4x4(); m.translation=where
        return m,float(orient is RELAXED),GUARD_ROLL if orient is GUARD else 0.
    def solve(gun):
        if t<=keys[0][0]: return resolve(gun,keys[0])
        for k0,k1 in zip(keys,keys[1:]):
            if t<=k1[0]:
                u=(t-k0[0])/(k1[0]-k0[0]); u=u*u*(3-2*u)
                (m0,r0,a0),(m1,r1,a1)=resolve(gun,k0),resolve(gun,k1)
                return blend(m0,m1,u),r0+(r1-r0)*u,a0+(a1-a0)*u
        return resolve(gun,keys[-1])
    return solve

def long_gun_clips(gun,label,reload):
    support=gun_point(gun,'support'); mag=gun_point(gun,'mag')
    poles=dict(pole_r=Vector((-1,.3,-.5)),pole_l=LONG_POLE_L)
    belt=lambda p: p.head('pelvis')+Vector((.17,-.14,.05))
    def idle(p,t):
        breath=math.sin(math.tau*t*SOURCE_FPS/p.idle_frames)
        return dict(spine=LONG_SPINE,gun=shouldered(gun,drop=.004*breath),left=left_hand([(0,'gun',support,GUARD)],t),**poles)
    def shoot(p,t):
        r=RECOIL[gun]; k=kick(t,**r)
        keys=[(0,'gun',support,GUARD)]; pump=0.
        if gun=='shotgun':   # rack the pump once the gun has settled
            keys=[(0,'gun',support,GUARD),(.3,'gun',support,GUARD),(.42,'gun',support-Vector((0,.1,0)),GUARD),(.54,'gun',support,GUARD)]
            pump=smooth([(0,0.),(.3,0.),(.42,1.),(.54,0.)],t)
        return dict(spine=body_rock(LONG_SPINE,r,k),left=left_hand(keys,t),**poles,
            gun=shouldered(gun,pitch=r['pitch']*k-.04*pump,back=r['back']*k,yaw=r.get('yaw',0.)*k))
    def reloading(p,t):
        tilt=reload['tilt'](t)
        keys=[(k[0],k[1],k[2](p) if callable(k[2]) else k[2],k[3]) for k in reload['left'](support,mag,belt)]
        return dict(spine=LONG_SPINE,gun=shouldered(gun,**tilt),left=left_hand(keys,t),**poles)
    return {label+'_Idle_Loop':dict(at=idle,length=40/SOURCE_FPS,breathe=True),
        label+'_Shoot':dict(at=shoot,length=.62 if gun=='shotgun' else .2),
        label+'_Reload':dict(at=reloading,length=reload['length'])}

def rifle_reload():
    def tilt(t):
        u=smooth([(0,0.),(.22,1.),(1.0,1.),(1.25,0.)],t)
        return dict(pitch=-.22*u,roll=.45*u,drop=.1*u,inward=.06*u)
    def left(support,mag,belt):
        under=mag+Vector((0,0,-.1)); bolt=Vector((.05,.16,.1)); pulled=Vector((.05,.07,.1))
        return [(0,'gun',support,GUARD),(.2,'gun',mag,RELAXED),(.3,'gun',mag,RELAXED),(.4,'gun',under,RELAXED),
            (.58,'body',belt,RELAXED),(.7,'body',belt,RELAXED),(.85,'gun',under,RELAXED),(.95,'gun',mag,RELAXED),
            (1.05,'gun',bolt,VERTICAL),(1.12,'gun',pulled,VERTICAL),(1.3,'gun',support,GUARD)]
    return dict(length=1.3,tilt=tilt,left=left)

def shotgun_reload():
    def tilt(t):
        u=smooth([(0,0.),(.18,1.),(.86,1.),(1.04,0.)],t)
        return dict(pitch=-.18*u,roll=-.55*u,drop=.12*u,inward=.08*u)
    def left(support,port,belt):
        racked=support-Vector((0,.1,0))
        return [(0,'gun',support,GUARD),(.15,'body',belt,RELAXED),(.32,'gun',port,RELAXED),(.42,'gun',port,RELAXED),
            (.56,'body',belt,RELAXED),(.74,'gun',port,RELAXED),(.84,'gun',port,RELAXED),(1.04,'gun',support,GUARD),
            (1.15,'gun',racked,GUARD),(1.27,'gun',support,GUARD)]
    return dict(length=1.35,tilt=tilt,left=left)

def smg_clips():
    support=gun_point('smg','support'); mag=gun_point('smg','mag')
    poles=dict(pole_r=Vector((-.7,.3,-1)),pole_l=Vector((.7,.3,-1)))
    belt=lambda p: p.head('pelvis')+Vector((.17,-.14,.05))
    def idle(p,t):
        breath=math.sin(math.tau*t*SOURCE_FPS/p.idle_frames)
        return dict(spine=SMG_SPINE,gun=at_chest(drop=.004*breath),left=left_hand([(0,'gun',support,VERTICAL)],t),**poles)
    def shoot(p,t):
        r=RECOIL['smg']; k=kick(t,**r)
        return dict(spine=body_rock(SMG_SPINE,r,k),left=left_hand([(0,'gun',support,VERTICAL)],t),**poles,
            gun=at_chest(pitch=r['pitch']*k,back=r['back']*k,yaw=r['yaw']*k))
    def reloading(p,t):
        u=smooth([(0,0.),(.18,1.),(.85,1.),(1.05,0.)],t)
        out=mag+Vector((0,0,-.12))
        keys=[(0,'gun',support,VERTICAL),(.18,'gun',mag,VERTICAL),(.3,'gun',out,VERTICAL),(.48,'body',belt(p),VERTICAL),
            (.6,'body',belt(p),VERTICAL),(.75,'gun',out,VERTICAL),(.86,'gun',mag,VERTICAL),(1.1,'gun',support,VERTICAL)]
        return dict(spine=SMG_SPINE,gun=at_chest(pitch=.12*u,roll=.5*u,drop=.04*u),left=left_hand(keys,t),**poles)
    return {'SMG_Idle_Loop':dict(at=idle,length=40/SOURCE_FPS,breathe=True),'SMG_Shoot':dict(at=shoot,length=.13),
        'SMG_Reload':dict(at=reloading,length=1.1)}

def pistol_clips():
    """Only the shot: idle and reload stay the library's. Both fists ride the flipping gun."""
    def shoot(p,t):
        r=RECOIL['pistol']; k=kick(t,**r)
        def place(p):
            fist=p.fist('r')
            m=(fist.to_3x3()@Matrix.Rotation(r['pitch']*k,3,'X')).to_4x4()   # flips about the grip
            m.translation=fist.translation-FWD*r['back']*k+UP*.02*k
            return m
        return dict(spine=body_rock([],r,k),gun=place,left=lambda gun:(gun@p.pistol_left,0.,0.),pole_r=None,pole_l=None)
    return {'Pistol_Kick':dict(at=shoot,length=.26)}

def all_clips():
    clips={}
    clips.update(pistol_clips())
    clips.update(smg_clips())
    clips.update(long_gun_clips('shotgun','Shotgun',shotgun_reload()))
    clips.update(long_gun_clips('rifle','Rifle',rifle_reload()))
    return clips

GUN_OF={'Pistol':'pistol','SMG':'smg','Shotgun':'shotgun','Rifle':'rifle'}

# ---------------------------------------------------------------- baking and export
def bake(poser,name,clip):
    """Keys every bone on every frame of the clip into a new action."""
    rig=poser.rig
    old=bpy.data.actions.get(name)
    if old: bpy.data.actions.remove(old)
    frames=max(2,int(round(clip['length']*FPS)))
    poses=[]; worst=0.
    for f in range(frames+1):
        t=min(f/FPS,clip['length'])
        _,miss=poser.pose(clip,t)
        worst=max(worst,miss)
        poses.append({p.name:p.matrix_basis.copy() for p in poser.pb})
    action=bpy.data.actions.new(name)
    rig.animation_data.action=action
    for f,pose in enumerate(poses):
        for p in poser.pb:
            p.matrix_basis=pose[p.name]
            for path in ('location','rotation_quaternion','scale'):
                p.keyframe_insert(path,frame=f,group=p.name)
    rig.animation_data.action=None
    return action,frames,worst

def export(poser,actions):
    rig=poser.rig
    ad=rig.animation_data
    for t in list(ad.nla_tracks): ad.nla_tracks.remove(t)
    ad.action=None
    for action in actions:
        track=ad.nla_tracks.new(); track.name=action.name
        strip=track.strips.new(action.name,0,action)
        if hasattr(strip,'action_slot') and len(action.slots): strip.action_slot=action.slots[0]
    skin=next(o for o in bpy.context.scene.objects if o.type=='MESH' and o.parent==rig)
    for o in bpy.context.scene.objects: o.select_set(o in (rig,skin))
    bpy.context.view_layer.objects.active=rig
    path=os.path.join(ROOT,'assets/animations/weapon_clips.glb')
    bpy.ops.export_scene.gltf(filepath=path,export_format='GLB',use_selection=True,export_animation_mode='NLA_TRACKS',
        export_skins=True,export_anim_slide_to_zero=True)
    return path

def load_rig(scene):
    bpy.ops.import_scene.gltf(filepath=os.path.join(ROOT,'assets/characters/hero.glb'))
    return next(o for o in scene.objects if o.type=='ARMATURE')

def build(scene):
    scene.render.fps=FPS; scene.render.fps_base=1.0   # the exporter reads frame times at the scene rate
    poser=Poser(load_rig(scene))
    report={}; actions=[]
    for name,clip in all_clips().items():
        poser.twists.clear()
        action,frames,worst=bake(poser,name,clip)
        actions.append(action)
        report[name]={'frames':frames,'reach_gap':round(worst,3),
            'twist_deg_shoulder_elbow_wrist':{s:[round(math.degrees(max(t[i] for t in poser.twists if t[0]==s))) for i in (1,2,3)] for s in 'rl'}}
    report['file']=export(poser,actions)
    return poser,report

if __name__=='__main__':
    # Headless only: blender -b --factory-startup --python tools/build_weapon_anims.py
    # Exporting the rig from a scene other than the window's crashes Blender 5.2's depsgraph
    # (as with build_intro.py), so the build runs in a throwaway Blender. The poses were tuned
    # through the MCP bridge by calling Poser.pose() in the open Blender's active scene.
    scene=bpy.context.scene
    for o in list(scene.objects): bpy.data.objects.remove(o)
    print('WEAPON_CLIPS_READY',json.dumps(build(scene)[1]))
