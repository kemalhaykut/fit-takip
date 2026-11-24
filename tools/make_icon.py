"""Fit Takip ikonu: SDF ışın izleme ile gerçekçi hex dambıl (numpy)."""
import numpy as np
from PIL import Image, ImageFilter, ImageDraw
import sys, os

N = int(sys.argv[1]) if len(sys.argv) > 1 else 1024
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets')

def rot(ax, ay, az):
    cx, sx = np.cos(ax), np.sin(ax); cy, sy = np.cos(ay), np.sin(ay); cz, sz = np.cos(az), np.sin(az)
    Rx = np.array([[1,0,0],[0,cx,-sx],[0,sx,cx]]); Ry = np.array([[cy,0,sy],[0,1,0],[-sy,0,cy]])
    Rz = np.array([[cz,-sz,0],[sz,cz,0],[0,0,1]])
    return Rz @ Ry @ Rx

# nesne uzayı: dambıl x ekseni boyunca
R = rot(0.35, 0.55, 0.62)   # eğik, hafif üstten
Rinv = R.T

def sd_cyl(p, r, h):            # x ekseni boyunca kapalı silindir
    d1 = np.sqrt(p[...,1]**2 + p[...,2]**2) - r
    d2 = np.abs(p[...,0]) - h
    return np.minimum(np.maximum(d1, d2), 0) + np.sqrt(np.maximum(d1,0)**2 + np.maximum(d2,0)**2)

def sd_hex(p, r, h, round_=0.035):   # x ekseni boyunca altıgen prizma (köşeleri yuvarlatılmış)
    k = np.array([-0.8660254, 0.5, 0.57735])
    q = np.abs(p[..., [1, 2]])
    dot = np.minimum(k[0]*q[...,0] + k[1]*q[...,1], 0)
    qy = q[...,0] - 2*dot*k[0]; qz = q[...,1] - 2*dot*k[1]
    rr = r - round_
    cl = np.clip(qy, -k[2]*rr, k[2]*rr)
    d1 = np.sqrt((qy-cl)**2 + (qz-rr)**2) * np.sign(qz-rr)
    d2 = np.abs(p[...,0]) - h + round_
    return np.minimum(np.maximum(d1, d2), 0) + np.sqrt(np.maximum(d1,0)**2 + np.maximum(d2,0)**2) - round_

HEAD_X = 0.78
def scene(pw):
    p = pw @ Rinv.T
    handle = sd_cyl(p, 0.105, 0.62)
    pl = p.copy(); pl[...,0] = np.abs(pl[...,0]) - HEAD_X
    head = sd_hex(pl, 0.40, 0.26)
    pc = p.copy(); pc[...,0] = np.abs(pc[...,0]) - 0.47
    collar = sd_cyl(pc, 0.15, 0.055)
    d = np.minimum(np.minimum(handle, head), collar)
    mat = np.where(head <= d + 1e-5, 1, np.where(collar <= d + 1e-5, 2, 0))
    return d, mat, p

def normal(pw):
    e = 1e-3
    n = np.zeros_like(pw)
    for i in range(3):
        o = np.zeros(3); o[i] = e
        n[..., i] = scene(pw + o)[0] - scene(pw - o)[0]
    return n / (np.linalg.norm(n, axis=-1, keepdims=True) + 1e-12)

def render(n, transparent=False):
    ys, xs = np.mgrid[0:n, 0:n]
    u = (xs + 0.5) / n * 2 - 1; v = 1 - (ys + 0.5) / n * 2
    ro = np.array([0, 0, 3.4])
    rd = np.stack([u*0.62, v*0.62, -np.ones_like(u)*1.55], -1)
    rd /= np.linalg.norm(rd, axis=-1, keepdims=True)
    t = np.zeros(u.shape); hit = np.zeros(u.shape, bool)
    for _ in range(140):
        p = ro + rd * t[..., None]
        d, _, _ = scene(p)
        hit |= d < 1e-4
        t = np.where(hit, t, t + d * 0.9)
        if np.all(hit | (t > 7)): break
    p = ro + rd * t[..., None]
    d, mat, pl = scene(p)
    hit = d < 2e-3
    nrm = normal(p)
    L1 = np.array([-0.5, 0.8, 0.6]); L1 /= np.linalg.norm(L1)
    L2 = np.array([0.8, -0.2, -0.4]); L2 /= np.linalg.norm(L2)   # arka (rim) ışık
    V = -rd
    def spec(L, k):
        H = L + V; H /= np.linalg.norm(H, axis=-1, keepdims=True)
        return np.clip((nrm*H).sum(-1), 0, 1) ** k
    diff1 = np.clip((nrm*L1).sum(-1), 0, 1); diff2 = np.clip((nrm*L2).sum(-1), 0, 1)
    fres = (1 - np.clip((nrm*V).sum(-1), 0, 1)) ** 3
    refl = rd - 2 * (rd*nrm).sum(-1, keepdims=True) * nrm
    env = np.clip(refl[...,1] * 0.5 + 0.5, 0, 1)
    # stüdyo ortamı: üstte parlak softbox, altta koyu zemin
    envc = 0.06 + 0.9 * env**3 + 0.5*np.exp(-((refl[...,0]+0.3)**2)*8)*np.clip(refl[...,1]+0.2,0,1)
    col = np.zeros(u.shape + (3,))
    # 0: krom sap (tırtıllı)
    knurl = 0.5 + 0.5*np.sign(np.sin(pl[...,0]*160) * np.sin(np.arctan2(pl[...,2], pl[...,1])*28))
    knurl_zone = (np.abs(pl[...,0]) < 0.36)
    chrome = envc[..., None] * np.array([0.92, 0.94, 1.0]) + spec(L1, 60)[..., None]*1.2
    chrome = np.where((knurl_zone & (knurl < 0.5))[..., None], chrome*0.72, chrome)
    # 1: mat siyah kauçuk kafa
    rubber_base = np.array([0.055, 0.058, 0.066])
    rubber = rubber_base * (0.25 + 0.9*diff1[..., None]) + spec(L1, 26)[..., None]*0.16 \
             + (spec(L2, 6) * fres)[..., None]*np.array([0.70, 1.0, 0.10])*0.9 + fres[..., None]*0.05
    # kafa yan yüzü (düz uç) biraz daha parlak, üstünde ince kabartma halka
    flat = np.abs(nrm @ R[:, 0]) > 0.9
    rr = np.sqrt(pl[...,1]**2 + pl[...,2]**2)
    ring = flat & (np.abs(rr - 0.25) < 0.012)
    rubber = np.where(ring[..., None], rubber + 0.05, rubber)
    # 2: krom bilezik
    collar = envc[..., None]*np.array([0.95,0.95,0.97])*1.05 + spec(L1, 80)[..., None]
    col = np.where((mat == 0)[..., None], chrome, col)
    col = np.where((mat == 1)[..., None], rubber, col)
    col = np.where((mat == 2)[..., None], collar, col)
    # gölge yok (havada), ama kontur yumuşatma için alfa
    alpha = hit.astype(float)
    col = np.nan_to_num(np.clip(col, 0, 1))
    return col, alpha

def to_img(col, alpha):
    rgb = (col ** (1/2.2) * 255).astype(np.uint8)
    a = (alpha * 255).astype(np.uint8)
    return Image.fromarray(np.dstack([rgb, a]), 'RGBA')

SS = 2
col, alpha = render(N * SS)
fg = to_img(col, alpha).resize((N, N), Image.LANCZOS)

# --- tam ikon: koyu arka plan + volt parıltı ---
bg = Image.new('RGBA', (N, N), (14, 15, 18, 255))
ys, xs = np.mgrid[0:N, 0:N] / N
glow = np.exp(-(((xs-0.62)**2 + (ys-0.38)**2) / 0.07))
g = np.zeros((N, N, 4)); g[..., 0] = 198; g[..., 1] = 255; g[..., 2] = 0; g[..., 3] = glow * 70
bg = Image.alpha_composite(bg, Image.fromarray(g.astype(np.uint8), 'RGBA'))
# gölge
sh = fg.split()[3].filter(ImageFilter.GaussianBlur(N/40))
shadow = Image.new('RGBA', (N, N), (0, 0, 0, 0)); shadow.putalpha(sh.point(lambda x: int(x*0.7)))
full = bg.copy()
full.alpha_composite(shadow, (int(N*0.02), int(N*0.04)))
full.alpha_composite(fg)
mask = Image.new('L', (N, N), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, N-1, N-1], radius=int(N*0.22), fill=255)
full_r = Image.new('RGBA', (N, N), (0, 0, 0, 0)); full_r.paste(full, (0, 0), mask)
full.convert('RGB').save(os.path.join(OUT, 'icon.png'))
full_r.save(os.path.join(OUT, 'icon_rounded.png'))
# adaptive ön plan: güvenli alan için %62'ye küçült
fgs = Image.new('RGBA', (N, N), (0, 0, 0, 0))
k = int(N * 0.66); small = fg.resize((k, k), Image.LANCZOS)
sk = Image.new('RGBA', (N, N), (0,0,0,0)); sk.alpha_composite(shadow.resize((k,k)), ((N-k)//2+int(N*0.015), (N-k)//2+int(N*0.03)))
fgs.alpha_composite(sk); fgs.alpha_composite(small, ((N-k)//2, (N-k)//2))
fgs.save(os.path.join(OUT, 'icon_fg.png'))
print('ok')
