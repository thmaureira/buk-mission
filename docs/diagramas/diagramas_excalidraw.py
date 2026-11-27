"""Genera los diagramas del documento como .excalidraw. Uso: python3 diagramas_excalidraw.py"""
from excalidraw_lib import Scene
from modelo_datos_data import ENTS, COLS

BLUE, YELLOW, GREEN, GRAY, WHITE, VIOLET = "#a5d8ff", "#ffec99", "#b2f2bb", "#e9ecef", "#ffffff", "#d0bfff"

# ---------------------------------------------------------------- modelo de datos
def modelo_datos():
    s = Scene(); W = 520; RH = 22; HH = 44; gap = 60; X = [0, 700, 1400]
    pos = {}
    for c, names in COLS.items():
        y = 0
        for n in names:
            h = HH + RH * len(ENTS[n][2]) + 14
            pos[n] = (X[c], y, W, h); y += h + gap
    color = {"#9fd3ff": BLUE, "#fde9a8": YELLOW, "#e6e8ee": GRAY, "#ffffff": WHITE}
    for n, (title, fill, fields) in ENTS.items():
        x, y, w, h = pos[n]
        s.rect(x, y, w, h, bg=color[fill])
        s.text(x + 16, y + 10, title, size=20)
        s.line([(x + 12, y + HH), (x + w - 12, y + HH)], sw=1)
        for i, (k, name, typ) in enumerate(fields):
            yy = y + HH + 6 + RH * i
            if k == "+":
                s.rect(x + 8, yy - 2, w - 16, RH, bg=GREEN, sw=1, round_=True, stroke="#2f9e44", rough=0)
            s.text(x + 16, yy, "NEW" if k == "+" else k, size=14, family=3, color="#2f9e44" if k == "+" else "#1e1e1e")
            s.text(x + 80, yy, name, size=14, family=3)
            s.text(x + w - 16 - len(typ) * 8.4, yy, typ, size=14, family=3, color="#495057")

    def a(n, side, f):
        x, y, w, h = pos[n]
        return {"r": (x + w, y + h * f), "l": (x, y + h * f), "t": (x + w * f, y), "b": (x + w * f, y + h)}[side]

    rels = [("employees", "r", .3, "leave_grants", "l", .3, "1 : 0..N"), ("employees", "b", .5, "leave_periods", "t", .5, "1 : 0..N"),
            ("leave_types", "l", .4, "leave_grants", "r", .4, "1 : 0..N"), ("leave_types", "b", .5, "grant_batches", "t", .5, "1 : 0..N"),
            ("grant_batches", "l", .5, "leave_grants", "r", .8, "0..1 : 1..N"), ("leave_grants", "b", .5, "ledger_entries", "t", .5, "1 : 1..N"),
            ("leave_periods", "r", .5, "ledger_entries", "l", .35, "0..1 : 1..N"), ("imports", "b", .5, "rows", "t", .5, "1 : 1..N")]
    for p, sp, fp, q, sq, fq, lab in rels:
        x1, y1 = a(p, sp, fp); x2, y2 = a(q, sq, fq)
        if sp in "lr":
            mx = (x1 + x2) / 2
            s.arrow([(x1, y1), (mx, y1), (mx, y2), (x2, y2)], lab, (mx - 40, min(y1, y2) - 26))
        else:
            s.arrow([(x1, y1), (x2, y2)], lab, (x1 + 10, (y1 + y2) / 2 - 10))
    x, y, w, h = pos["ledger_entries"]
    s.arrow([(x + w, y + h * .3), (x + w + 40, y + h * .3), (x + w + 40, y + h * .6), (x + w, y + h * .6)], "revierte\n0..1", (x + w + 48, y + h * .4))
    ly = max(p[1] + p[3] for p in pos.values()) + 40
    s.rect(0, ly, 36, 22, bg=GREEN, sw=1, stroke="#2f9e44", rough=0); s.text(48, ly, "campo agregado respecto del diagrama anterior", size=18)
    s.rect(700, ly, 36, 22, bg=YELLOW, sw=1); s.text(748, ly, "tablas de migración (R6)", size=18)
    s.rect(1400, ly, 36, 22, bg=BLUE, sw=1); s.text(1448, ly, "núcleo del libro", size=18)
    return s

# ---------------------------------------------------------------- arquitectura
def box(s, x, y, w, h, title, body="", bg=WHITE, style="solid", tsize=20, bsize=16):
    s.rect(x, y, w, h, bg=bg, style=style)
    s.text(x + w / 2, y + 14, title, size=tsize, align="center")
    if body:
        s.text(x + w / 2, y + 22 + tsize * 1.3, body, size=bsize, align="center")

def arquitectura():
    s = Scene()
    box(s, 0, 0, 640, 70, "Portal RRHH", "colaboradores · tipos · cargas · migración · procesos")
    box(s, 720, 0, 600, 70, "Vista colaborador y jefatura", "mi saldo · historial del equipo")
    box(s, 0, 120, 1320, 60, "API Rails: controladores, autenticación y permisos por rol")
    s.arrow([(320, 70), (320, 120)]); s.arrow([(1020, 70), (1020, 120)])
    s.arrow([(660, 180), (660, 240)])
    # módulo
    s.rect(0, 240, 1320, 470, bg="#f8f9fa", style="dashed")
    s.text(20, 252, "Módulo de vacaciones (monolito Rails)", size=20)
    box(s, 30, 300, 380, 130, "Solicitudes aprobadas", "períodos tomados y anulados\nconteo de días hábiles")
    box(s, 470, 300, 380, 130, "Libro de vacaciones", "lotes y movimientos (solo inserción)\núnica vía de escritura:\nGrant · Consume · Expire · Reverse", bg=BLUE)
    box(s, 910, 300, 380, 130, "Motor de reglas", "Strategy por fecha de vigencia\nlegales · proporcional\nprogresivas: V1 activa / V2 pendiente")
    box(s, 30, 520, 380, 150, "Calendario", "feriados nacionales\ny regionales")
    box(s, 470, 520, 380, 150, "Tipos y vencimientos", "(Parte 2)\nbolsa de consumo y política\nde vencimiento por tipo")
    box(s, 910, 520, 380, 150, "Migración Excel", "reporte de diferencias por fila\naprobación RRHH → apertura", bg=YELLOW)
    s.arrow([(410, 365), (470, 365)])
    s.arrow([(220, 430), (220, 520)])
    s.arrow([(660, 430), (660, 520)], "lee", (672, 485))
    s.arrow([(910, 375), (850, 375)], "calcula", (848, 340))
    s.arrow([(1100, 520), (1100, 475), (800, 475), (800, 430)], "escribe apertura", (880, 445))
    # externos
    s.rect(1400, 240, 420, 220, bg="#f1f3f5", style="dashed")
    s.text(1420, 252, "Módulos existentes de Buk", size=20)
    box(s, 1430, 300, 360, 130, "Colaboradores", "fecha de ingreso\nantigüedad previa con respaldo", bg=GRAY)
    s.arrow([(1290, 365), (1430, 365)], "lee", (1340, 335))
    s.rect(1400, 500, 420, 120, bg="#f1f3f5", style="dashed")
    box(s, 1430, 520, 360, 80, "Flujo de solicitudes", "evento: solicitud aprobada", bg=GRAY)
    s.arrow([(1430, 560), (1360, 560), (1360, 495), (150, 495), (150, 430)], "solicitud aprobada", (1150, 500), style="dashed")
    # procesos
    box(s, 0, 770, 1320, 90, "Procesos programados (Sidekiq-cron, diarios e idempotentes)", "aniversarios (R2, R3) · vencimientos (R11) · paso a tomadas (R4)", bg=YELLOW)
    s.arrow([(660, 770), (660, 710)], "usan el Motor y escriben en el Libro", (680, 728))
    return s

# ---------------------------------------------------------------- infraestructura
def infraestructura():
    s = Scene()
    s.rect(200, 0, 1240, 560, bg="#f8f9fa", style="dashed")
    s.text(220, 14, "AWS (región única, Multi-AZ)", size=20)
    box(s, 0, 220, 160, 80, "Usuarios", "web y móvil")
    box(s, 260, 220, 180, 80, "Balanceador", "ALB")
    box(s, 520, 80, 300, 120, "Rails web", "ECS · API y vistas", bg=BLUE)
    box(s, 520, 380, 260, 120, "Redis", "ElastiCache · colas", bg=WHITE)
    box(s, 860, 380, 280, 120, "Sidekiq + sidekiq-cron", "procesos diarios\nmismo código Rails", bg=YELLOW)
    box(s, 1180, 70, 230, 300, "PostgreSQL", "RDS Multi-AZ\nbackups diarios\nréplica para reportes\n\ntrigger: ledger_entries\nsolo inserción", bg=GREEN)
    s.arrow([(160, 260), (260, 260)])
    s.arrow([(440, 260), (480, 260), (480, 140), (520, 140)])
    s.arrow([(820, 140), (1180, 140)], "lee y escribe", (930, 110))
    s.arrow([(620, 200), (620, 380)], "encola", (630, 280))
    s.arrow([(780, 440), (860, 440)], "toma", (796, 405))
    s.arrow([(1140, 440), (1260, 440), (1260, 370)], "escribe en el Libro", (1150, 450))
    s.text(220, 520, "Alertas (CloudWatch): proceso diario que no corrió · conciliación con diferencias", size=16, color="#495057")
    return s

if __name__ == "__main__":
    import json
    out = {}
    for name, fn in [("modelo_datos", modelo_datos), ("arquitectura", arquitectura), ("infraestructura", infraestructura)]:
        out[name] = fn().save(f"{name}.excalidraw")
    print(json.dumps(out))
