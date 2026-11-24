"""Kas haritası şekilleri. Önizleme PNG'si ve lib/body_map_data.dart üretir.
Koordinat alanı: 200 x 440 (her görünüm için)."""
import math, os, sys
from PIL import Image, ImageDraw

def cr(points, n=10, closed=True):
    """Catmull-Rom ile yumuşatılmış nokta listesi."""
    P = points; out = []
    m = len(P)
    rng = range(m) if closed else range(m - 1)
    for i in rng:
        p0 = P[(i - 1) % m]; p1 = P[i]; p2 = P[(i + 1) % m]; p3 = P[(i + 2) % m]
        for k in range(n):
            t = k / n; t2 = t*t; t3 = t2*t
            x = 0.5*((2*p1[0]) + (-p0[0]+p2[0])*t + (2*p0[0]-5*p1[0]+4*p2[0]-p3[0])*t2 + (-p0[0]+3*p1[0]-3*p2[0]+p3[0])*t3)
            y = 0.5*((2*p1[1]) + (-p0[1]+p2[1])*t + (2*p0[1]-5*p1[1]+4*p2[1]-p3[1])*t2 + (-p0[1]+3*p1[1]-3*p2[1]+p3[1])*t3)
            out.append((round(x, 1), round(y, 1)))
    return out

def mirror(pts): return [(round(200 - x, 1), y) for x, y in pts]
def ellipse(cx, cy, rx, ry, n=36): return [(round(cx + rx*math.cos(2*math.pi*i/n), 1), round(cy + ry*math.sin(2*math.pi*i/n), 1)) for i in range(n)]

# ---------------- siluet (sol yarı, merkez x=100) ----------------
TORSO_L = [(100, 60), (90, 62), (88, 72), (72, 78), (56, 82), (47, 90), (44, 104), (52, 112), (58, 130), (60, 160), (64, 192), (64, 210),
           (60, 228), (60, 262), (62, 300), (66, 322), (64, 346), (66, 380), (70, 410), (64, 426), (84, 428), (86, 410), (86, 380), (90, 346),
           (92, 322), (96, 290), (98, 252), (100, 246)]
ARM_L = [(56, 82), (44, 86), (38, 100), (36, 124), (32, 150), (30, 178), (28, 200), (24, 230), (21, 252), (18, 266), (22, 282), (30, 280),
         (32, 262), (38, 236), (44, 210), (48, 186), (50, 166), (54, 140), (54, 118), (52, 100)]

def silhouette():
    torso = cr(TORSO_L[:-1], 8, closed=False) + [TORSO_L[-1]]
    full = torso + list(reversed(mirror(torso)))
    return [ellipse(100, 34, 19, 24), full, cr(ARM_L, 8), mirror(cr(ARM_L, 8))]

# ---------------- kaslar (sol taraf; sağ taraf aynalanır) ----------------
FRONT = {
    'shoulders': [[(64, 80), (52, 84), (44, 94), (42, 110), (48, 116), (56, 104), (66, 90)]],
    'chest': [[(97, 88), (82, 84), (66, 88), (58, 100), (58, 114), (68, 124), (84, 128), (97, 124)]],
    'biceps': [[(46, 120), (40, 138), (38, 160), (42, 178), (49, 174), (53, 154), (54, 130)]],
    'forearms': [[(39, 186), (33, 206), (28, 232), (27, 250), (33, 252), (40, 226), (46, 198)]],
    'abs': [[(97, 132), (86, 133), (85, 160), (86, 190), (90, 214), (97, 220)]],
    'obliques': [[(80, 134), (64, 132), (62, 160), (66, 190), (74, 206), (84, 206), (82, 170)]],
    'quads': [[(76, 226), (66, 246), (64, 282), (70, 314), (82, 320), (93, 300), (97, 262), (94, 236)]],
    'calves': [[(70, 340), (67, 362), (70, 392), (78, 400), (84, 380), (86, 350), (80, 336)]],
    'traps': [[(90, 66), (76, 76), (88, 80), (95, 74)]],
}
BACK = {
    'traps': [[(100, 62), (90, 66), (74, 78), (64, 84), (80, 96), (92, 120), (100, 146)]],
    'shoulders': [[(58, 84), (48, 88), (42, 100), (42, 114), (50, 110), (60, 96)]],
    'back': [[(64, 98), (56, 112), (58, 136), (68, 164), (84, 188), (93, 180), (94, 146), (88, 116), (78, 102)]],
    'lowerback': [[(100, 160), (94, 172), (90, 196), (96, 212), (100, 214)]],
    'triceps': [[(46, 118), (39, 136), (38, 162), (44, 180), (52, 166), (54, 140), (54, 122)]],
    'forearms': [[(39, 186), (33, 206), (28, 232), (27, 250), (33, 252), (40, 226), (46, 198)]],
    'glutes': [[(99, 216), (82, 216), (68, 230), (66, 254), (78, 268), (94, 266), (99, 254)]],
    'hamstrings': [[(70, 272), (66, 296), (70, 318), (84, 322), (94, 302), (96, 272), (86, 268)]],
    'calves': [[(70, 334), (64, 354), (68, 382), (78, 394), (86, 374), (88, 348), (82, 334)]],
}
CENTER = {'abs', 'lowerback', 'traps_back'}

def build(view):
    res = []
    for key, polys in view.items():
        for poly in polys:
            if view is FRONT and key == 'abs' or view is BACK and key in ('traps', 'lowerback'):
                # orta hat: yarım şekil + ayna → tek şekil
                half = cr(poly[:-1], 8, closed=False) + [poly[-1]]
                shape = half + list(reversed(mirror(half)))
                res.append((key, shape))
            else:
                s = cr(poly, 8)
                res.append((key, s)); res.append((key, mirror(s)))
    return res

# karın kası çizgileri (dekor)
ABS_LINES = [[(88, 150), (112, 150)], [(87, 168), (113, 168)], [(88, 186), (112, 186)], [(100, 134), (100, 214)]]

def preview(path, counts):
    S = 3
    W, H = 200 * 2 + 40, 440
    im = Image.new('RGB', (W*S, H*S), (16, 17, 20)); d = ImageDraw.Draw(im)
    for vi, view in enumerate((FRONT, BACK)):
        ox = vi * 240
        for poly in silhouette():
            d.polygon([((x+ox)*S, y*S) for x, y in poly], fill=(38, 40, 46))
        for key, poly in build(view):
            c = counts.get(key, 0)
            fill = None if c == 0 else ((255, 202, 40) if c == 1 else (255, 59, 48))
            d.polygon([((x+ox)*S, y*S) for x, y in poly], fill=fill, outline=(110, 114, 124))
            if fill is None:
                d.line([((x+ox)*S, y*S) for x, y in poly + [poly[0]]], fill=(110, 114, 124), width=S)
        if view is FRONT:
            for ln in ABS_LINES:
                d.line([((x+ox)*S, y*S) for x, y in ln], fill=(16, 17, 20), width=S)
    im.resize((W*2, H*2), Image.LANCZOS).save(path)

def dart_list(pts): return '[' + ', '.join(f'{x}, {y}' for x, y in pts) + ']'

def emit(path):
    L = ['// OTOMATİK ÜRETİLDİ: tools/bodymap.py — elle düzenleme.', '// Koordinatlar 200 x 440 alanında; [x0, y0, x1, y1, ...]', '',
         'class MusclePoly {', '  final String key;', '  final List<double> pts;', '  const MusclePoly(this.key, this.pts);', '}', '']
    L.append('const List<List<double>> kSilhouette = [')
    for p in silhouette(): L.append('  ' + dart_list(p) + ',')
    L.append('];\n')
    for name, view in (('kFrontMuscles', FRONT), ('kBackMuscles', BACK)):
        L.append(f'const List<MusclePoly> {name} = [')
        for key, p in build(view): L.append(f"  MusclePoly('{key}', {dart_list(p)}),")
        L.append('];\n')
    L.append('const List<List<double>> kAbsLines = [')
    for ln in ABS_LINES: L.append('  ' + dart_list(ln) + ',')
    L.append('];')
    open(path, 'w').write('\n'.join(L) + '\n')

if __name__ == '__main__':
    root = os.path.join(os.path.dirname(__file__), '..')
    preview(sys.argv[1] if len(sys.argv) > 1 else 'body_preview.png',
            {'chest': 2, 'biceps': 1, 'back': 2, 'quads': 1, 'glutes': 1, 'abs': 1, 'triceps': 2})
    emit(os.path.join(root, 'lib', 'body_map_data.dart'))
    print('ok')
