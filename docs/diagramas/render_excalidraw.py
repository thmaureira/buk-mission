"""Exporta cada .excalidraw a PNG con el renderer oficial (@excalidraw/utils) en Chrome headless."""
import json, subprocess, sys, pathlib
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
PAD = 30
here = pathlib.Path(__file__).parent
for name in sys.argv[1:] or ["modelo_datos", "arquitectura", "infraestructura"]:
    doc = json.loads((here / f"{name}.excalidraw").read_text())
    html = here / f".{name}.html"
    html.write_text(f"""<!doctype html><meta charset="utf-8">
<style>html,body{{margin:0;background:#fff}} svg{{display:block}}</style>
<script src="https://unpkg.com/@excalidraw/utils@0.1.2/dist/excalidraw-utils.min.js"></script>
<body><script>
const doc = {json.dumps(doc, ensure_ascii=False)};
ExcalidrawUtils.exportToSvg({{elements: doc.elements, appState: {{exportBackground: true, viewBackgroundColor: "#ffffff"}}, exportPadding: {PAD}}})
  .then(svg => {{
    const w = parseFloat(svg.getAttribute("width")), h = parseFloat(svg.getAttribute("height"));
    svg.setAttribute("viewBox", `0 0 ${{w}} ${{h}}`);
    svg.setAttribute("width", w * 2); svg.setAttribute("height", h * 2);
    document.body.appendChild(svg); document.title = w + "x" + h;
  }});
</script>""")
    # 1ª pasada: medir el tamaño real del SVG
    dom = subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--virtual-time-budget=8000", "--dump-dom", html.as_uri()],
                         capture_output=True, text=True).stdout
    import re
    w, h = map(lambda v: int(float(v)) + 1, re.search(r"<title>([\d.]+)x([\d.]+)</title>", dom).groups())
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                    "--virtual-time-budget=10000", f"--window-size={w * 2},{h * 2}", f"--screenshot={here / (name + '.png')}", html.as_uri()],
                   capture_output=True)
    html.unlink()
    print(name, w, h)
