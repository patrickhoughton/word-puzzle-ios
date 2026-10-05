import wave, numpy as np
SR=44100
rng=np.random.default_rng(7)
def save(p,x):
    x=np.clip(x,-1,1); w=wave.open(p,'wb'); w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((x*32767).astype(np.int16).tobytes()); w.close()
def biquad_bp(x,f,q):
    w0=2*np.pi*f/SR; al=np.sin(w0)/(2*q); c=np.cos(w0)
    b=np.array([al,0,-al]); a=np.array([1+al,-2*c,1-al]); b/=a[0]; a/=a[0]
    y=np.zeros_like(x); x1=x2=y1=y2=0.0
    for i,v in enumerate(x):
        o=b[0]*v+b[1]*x1+b[2]*x2-a[1]*y1-a[2]*y2; x2,x1=x1,v; y2,y1=y1,o; y[i]=o
    return y
def tick(dur, click_f, click_q, click_decay, body_f, body_decay, body_amt, noise_amt=1.0):
    n=int(SR*dur); t=np.arange(n)/SR
    nz=rng.standard_normal(n)*np.exp(-t/0.0012)            # sharp snap transient
    click=biquad_bp(nz,click_f,click_q)*noise_amt
    click+=np.sin(2*np.pi*click_f*1.07*t)*np.exp(-t/click_decay)*0.25  # plastic ring
    body=np.sin(2*np.pi*body_f*t)*np.exp(-t/body_decay)*body_amt          # peg/wheel knock
    x=click+body; x[:int(SR*0.0005)]*=np.linspace(0,1,int(SR*0.0005))
    x[-int(SR*0.003):]*=np.linspace(1,0,int(SR*0.003))
    return x/np.max(np.abs(x))
V={
 "A_plastic": tick(0.030,2600,2.5,0.004,520,0.008,0.35),
 "B_woody":   tick(0.035,1600,2.0,0.005,330,0.012,0.55),
 "C_bright":  tick(0.025,3400,3.0,0.003,700,0.006,0.25),
}
for k,x in V.items():
    save(f"tick_{k}.wav",x*0.6)
    # demo: decelerating prize-wheel spin, ~3s
    gaps=np.geomspace(0.035,0.32,28); out=[]
    for g in gaps:
        seg=np.zeros(int(SR*g)); seg[:len(x)]+=x[:len(seg)]*0.6; out.append(seg)
    save(f"demo_{k}.wav",np.concatenate(out))
clunk=tick(0.060,900,1.5,0.008,180,0.025,0.8)
save("clunk_new.wav",clunk*0.7)
print("ok")
