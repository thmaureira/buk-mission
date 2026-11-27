"""Mini generador de archivos .excalidraw (abribles y editables en excalidraw.com)."""
import json, random

class Scene:
    def __init__(self):
        self.els = []
        self.rng = random.Random(42)

    def _base(self, kind, x, y, w, h, **kw):
        el = {
            "id": f"{kind}-{len(self.els)}", "type": kind, "x": x, "y": y, "width": w, "height": h,
            "angle": 0, "strokeColor": kw.get("stroke", "#1e1e1e"), "backgroundColor": kw.get("bg", "transparent"),
            "fillStyle": kw.get("fill", "solid"), "strokeWidth": kw.get("sw", 2), "strokeStyle": kw.get("style", "solid"),
            "roughness": kw.get("rough", 1), "opacity": 100, "groupIds": [], "frameId": None,
            "seed": self.rng.randint(1, 2**31), "version": 1, "versionNonce": self.rng.randint(1, 2**31),
            "isDeleted": False, "boundElements": None, "updated": 1, "link": None, "locked": False,
        }
        self.els.append(el)
        return el

    def rect(self, x, y, w, h, bg="transparent", style="solid", sw=2, round_=True, stroke="#1e1e1e", rough=1):
        el = self._base("rectangle", x, y, w, h, bg=bg, style=style, sw=sw, stroke=stroke, rough=rough)
        el["roundness"] = {"type": 3} if round_ else None
        el["strokeSharpness"] = "round" if round_ else "sharp"
        return el

    def text(self, x, y, s, size=20, family=1, align="left", color="#1e1e1e", w=None):
        # Una línea por elemento: el renderer de @excalidraw/utils 0.1.x desalinea textos multilínea.
        if "\n" in s:
            for i, line in enumerate(s.split("\n")):
                self.text(x, y + i * size * 1.25, line, size, family, align, color, w)
            return None
        lines = [s]
        cw = 0.6 if family == 3 else 0.55
        width = w or max(len(l) for l in lines) * size * cw
        height = len(lines) * size * 1.25
        if align == "center" and w is None:
            x -= width / 2
        el = self._base("text", x, y, width, height, stroke=color)
        el.update({"text": s, "originalText": s, "fontSize": size, "fontFamily": family, "textAlign": align,
                   "verticalAlign": "top", "baseline": int(size * 0.9), "containerId": None, "lineHeight": 1.25})
        return el

    def line(self, pts, style="solid", sw=1, arrow=False, stroke="#1e1e1e"):
        x0, y0 = pts[0]
        rel = [[px - x0, py - y0] for px, py in pts]
        xs = [p[0] for p in rel]; ys = [p[1] for p in rel]
        el = self._base("arrow" if arrow else "line", x0, y0, max(xs) - min(xs), max(ys) - min(ys),
                        style=style, sw=sw, stroke=stroke)
        el.update({"points": rel, "lastCommittedPoint": None, "startBinding": None, "endBinding": None,
                   "startArrowhead": None, "endArrowhead": "arrow" if arrow else None})
        el["roundness"] = None
        return el

    def arrow(self, pts, label=None, label_at=None, size=16, style="solid"):
        # Codos como segmentos rectos: el renderer suaviza las flechas de varios puntos en curvas.
        for a, b in zip(pts[:-2], pts[1:-1]):
            self.line([a, b], style=style, sw=2)
        self.line(pts[-2:], style=style, sw=2, arrow=True)
        if label:
            lx, ly = label_at or ((pts[0][0] + pts[-1][0]) / 2 + 6, (pts[0][1] + pts[-1][1]) / 2)
            self.text(lx, ly, label, size=size)

    def bounds(self):
        xs, ys, xe, ye = [], [], [], []
        for e in self.els:
            if "points" in e:
                px = [e["x"] + p[0] for p in e["points"]]; py = [e["y"] + p[1] for p in e["points"]]
                xs.append(min(px)); xe.append(max(px)); ys.append(min(py)); ye.append(max(py))
            else:
                xs.append(e["x"]); ys.append(e["y"]); xe.append(e["x"] + e["width"]); ye.append(e["y"] + e["height"])
        return min(xs), min(ys), max(xe), max(ye)

    def save(self, path):
        doc = {"type": "excalidraw", "version": 2, "source": "https://excalidraw.com", "elements": self.els,
               "appState": {"viewBackgroundColor": "#ffffff", "gridSize": None}, "files": {}}
        json.dump(doc, open(path, "w"), ensure_ascii=False, indent=1)
        return self.bounds()
