# Gestor de vacaciones · POC (Misión Técnica Buk)

POC de las **Partes 1 y 2** del documento: vacaciones como **libro contable de solo inserción con lotes**.
El saldo nunca se edita; es la suma de los movimientos, y cada número se explica movimiento a movimiento.

**Stack:** Rails 7.2 (monolito) · PostgreSQL 17 · Sidekiq + sidekiq-cron + Redis · Hotwire · RSpec. Todo corre en Docker.

## Levantar

```bash
docker compose up -d --build      # web en http://localhost:3000 + sidekiq + postgres + redis
docker compose exec web bin/rails db:seed            # escenario de demo (ya cargado si usaste db:prepare + seed)
docker compose exec web bin/rails db:seed:replant    # recargar desde cero
docker compose exec web bundle exec rspec            # tests
```

No hay login: el selector **"Ver como"** (arriba a la derecha) cambia entre RRHH, jefatura y colaborador.

## Acceso externo con ngrok

La app no tiene login real ("Ver como" permite actuar como RRHH), así que al exponerla conviene activar Basic Auth:

```bash
cp .env.example .env          # completar BASIC_AUTH_USER / BASIC_AUTH_PASSWORD (y NGROK_AUTHTOKEN si usas la opción B)
docker compose up -d          # recrea web con las variables de .env
```

- **Opción A (ngrok instalado localmente):** `ngrok http 3000`
- **Opción B (contenedor):** `docker compose --profile tunnel up -d` y ver la URL pública en http://localhost:4040

`config/environments/development.rb` acepta los hosts `*.ngrok-free.app`, `*.ngrok-free.dev`, `*.ngrok.app` y `*.ngrok.io`.

## Mapa de requisitos

| Req | Dónde verlo | Implementación |
|---|---|---|
| R1 Saldo | Colaboradores → ficha → **Vacaciones** (saldo a cualquier fecha) | `Vacations::Balance` suma `ledger_entries` hasta la fecha |
| R2/R3 Aniversario + progresivas | **Procesos** → Carga de aniversarios (ejecutar 2 veces) | `Vacations::AnniversaryGrants`, clave `anniversary:employee:ID:n:N:legal` con índice único; reglas `VacationRules::*` |
| R4 Días tomados | Ficha → Vacaciones tomadas → **Agregar** | `Vacations::ApproveRequest`: días hábiles (`holidays`), lock por colaborador, FEFO, `remaining_days >= 0` |
| R5 Finiquito | Ficha → **Finiquito** | `Vacations::Settlement` = disponible + solicitados no gozados + proporcional |
| R6 Migración | **Migración Excel** (hay una planilla aprobada y otra con errores) | `OpeningBalances::Parse` (reporte de diferencias) → `Approve`; `source = excel:archivo#fila N` |
| R7 Mi saldo | Ver como colaborador → **Mi saldo** | Solo disponible + historial, sin lotes ni movimientos |
| R8 Equipo | Ver como jefatura → **Historial del equipo** | Períodos con fechas y aprobador |
| R9 Auditoría | Ficha → **Movimientos** (revertir con motivo) | `ledger_entries` solo inserción: modelo readonly **y trigger en Postgres**; `Ledger::Reverse` |
| R10 Tipos | **Tipos de días** y **Cargas** | `leave_types` (políticas como datos) + `grant_batches` con motivo, a personas / área / todos |
| R11 Vencimientos | **Procesos** → Vencimientos | `Vacations::ExpireDue`: administrativos `fixed_date 12-31`; legales `relative 2y` (vencen al entrar el 3er período) |

## Diseño

- **Service objects como única puerta de escritura:** `Ledger::Grant`, `Consume`, `Expire`, `Reverse`
  (idempotencia, lock, saldo ≥ 0). `remaining_days` del lote es caché que se actualiza en la misma transacción;
  la pestaña Movimientos verifica que cada lote cuadre con su libro.
- **Strategy:** `VacationRules::Registry` resuelve la clase vigente desde `rule_versions` por fecha.
- **Jobs:** `config/schedule.yml` (sidekiq-cron, diarios, hora Chile). Si un día no corre, el siguiente se pone al día.

## Supuestos (del documento)

- Progresivas: regla activa `ProgressiveDaysV1` = la del enunciado (10+ años totales con previos topados en 10, 3+ continuos, `floor(años_actuales / 3)`; ejemplo 3 + 9 → 3 días → 18). La lectura DT del art. 68 está escrita como `ProgressiveDaysV2`, **sin activar**, a la espera de la respuesta a la consulta: con ella el ejemplo daría 0 (su test del ejemplo está `pending`). Se activa con una fila en `rule_versions`.
- Proporcional: `1,25 × meses + 1,25 × días / 30` desde el último aniversario, solo legales.
- Días hábiles: lunes a viernes sin feriados nacionales (tabla `holidays`, cargada aprox. 2025–2027).
- Sin saldo negativo; solo un ajuste de RRHH permite adelantar días.
- Un período pasa a "tomado" cuando llega su fecha de inicio.
- Saldo legal migrado: vence un año después del próximo aniversario posterior al corte.

Fuera de scope (según el documento): flujo de solicitud/aprobación (se simula el evento "aprobada"), monto en pesos,
otros países, feriado colectivo, licencias, notificaciones, autenticación real.

## Diagramas

`docs/diagramas/` tiene el modelo de datos, la arquitectura y la infraestructura como archivos `.excalidraw`
(se abren y editan en excalidraw.com) y su PNG. Para regenerarlos:

```bash
cd docs/diagramas && python3 diagramas_excalidraw.py && python3 render_excalidraw.py
```
