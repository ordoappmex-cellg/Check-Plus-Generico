-- ============================================================================
-- LIMEN — SQL MAESTRO CONSOLIDADO (regenerado 17 ago 2026)
-- ============================================================================
-- Fusión de los .sql que existen en el repo, en orden de dependencia. NO
-- ejecutar contra la base actual (ya está aplicado en Supabase) — este
-- archivo es la fuente de verdad en repo para clonar un proyecto Supabase
-- nuevo desde cero, y para auditar qué se ha corrido.
--
-- CONTENIDO Y ORDEN (cada uno incluido COMPLETO y sin modificar):
--   1) setup_v56.sql — base Diamante (Check Plus): user_profiles y las ~46
--      tablas de RH/Kanban/Desarrollos/Soporte/Diseño/Dirección/GP/OKRs/
--      Evaluaciones/CRM Clientify legacy, RLS histórica, 6 buckets de
--      Storage, publicación Realtime, datos seed.
--   2) hb_schema_base_reconstruido.sql — las 8 tablas hb_* (hb_config,
--      hb_proveedores, hb_crm_formularios, hb_crm_empresas,
--      hb_crm_prospectos, hb_crm_seguimientos, hb_crm_documentos,
--      hb_crm_tareas). NUEVO respecto al consolidado anterior: estas tablas
--      nunca tuvieron CREATE TABLE en ningún archivo del repo — se
--      reconstruyeron columna por columna desde information_schema.columns
--      en producción real. Va ANTES de limen_master_sesion_13ago.sql porque
--      ese archivo les agrega columnas/políticas/triggers vía ALTER, y
--      DESPUÉS de setup_v56.sql porque sus FK a user_profiles(user_id)
--      necesitan que esa tabla ya exista.
--   3) BLOQUE FINANCIERO (17 ago 2026) — las 10 tablas hb_clientes,
--      hb_operaciones, hb_servicios, hb_facturas_proveedor,
--      hb_facturas_cliente, hb_pagos_proveedor, hb_pagos_cliente,
--      hb_comisiones, hb_operaciones_cambios, hb_vendedores_config.
--      Reconstruidas con PK/FK/índices verificados 1:1 contra
--      information_schema/pg_indexes de producción real — creadas y vacías,
--      sin UI todavía (módulo pendiente, ver CLAUDE.md deuda #7/#8). Va
--      DESPUÉS de hb_schema_base_reconstruido.sql (FK a hb_proveedores,
--      hb_crm_prospectos) y ANTES de limen_master_sesion_13ago.sql (sin
--      dependencia real en ese sentido, solo se agrupa el bloque financiero
--      antes del CRM). Sin RLS: no está verificado que esté enabled en
--      producción, no se inventaron policies.
--   4) limen_master_sesion_13ago.sql — sesión del 13 ago 2026: seguridad de
--      Storage de cotizaciones, motivos de pérdida, helpers hb_current_role/
--      hb_is_admin/hb_normaliza, RLS por vendedor, deduplicación de leads.
--      Su crm_captar_lead() fue REEMPLAZADA en línea por la versión final de
--      limen_master_sesion_13ago_parte2.sql (ver punto 5) — no queda
--      duplicada en este archivo.
--   5) limen_master_sesion_13ago_parte2.sql — Landings (hb_crm_landings +
--      policies de bucket landing-images), atribución UTM/geo en
--      prospectos, crm_landing_config(), hb_crm_visitas, hb_crm_linkbio +
--      crm_linkbio_config(), crm_registrar_visita(), la versión final de
--      crm_captar_lead() (fusionada en el punto 4, no repetida aquí),
--      Realtime de hb_crm_prospectos, seeds de app_config
--      (instance_profile, paleta_colores).
--   6) limen_master_sesion_14ago_parte3.sql — 6 columnas de drift de
--      Gestión de Proyectos (gp_proyectos.visible_roadmap/fecha_cierre/
--      tipo_tarea, gp_tareas.hito_id/tipo_tarea/asignados).
--
-- VERIFICACIÓN DE DEPENDENCIAS (pedida explícitamente): revisé, en orden,
-- cada CREATE TABLE/ALTER/FK de los archivos 2-6 contra lo que ya existe
-- creado por lo anterior. Todas las FK resuelven:
--   • hb_schema_base_reconstruido.sql → user_profiles(user_id): la crea
--     setup_v56.sql (línea 417 de ese archivo). Internamente el archivo ya
--     ordena sus propias 8 tablas por dependencia (formularios y empresas
--     antes de prospectos; prospectos antes de seguimientos/documentos/
--     tareas).
--   • BLOQUE FINANCIERO → hb_proveedores, hb_crm_prospectos (archivo 2),
--     user_profiles (archivo 1): todas ya existen. Internamente ordena sus
--     propias 10 tablas por dependencia (clientes → operaciones → servicios
--     → facturas → pagos; comisiones y cambios dependen de operaciones;
--     vendedores_config depende solo de user_profiles).
--   • limen_master_sesion_13ago.sql → hb_crm_prospectos/seguimientos/
--     documentos/tareas/empresas, hb_config, user_profiles: todas ya existen
--     tras el archivo 2. Sus propios "CREATE TABLE IF NOT EXISTS
--     hb_crm_tareas"/"hb_crm_empresas" y varios "ALTER ... ADD COLUMN IF NOT
--     EXISTS" (vendedor_id, empresa_id, bucket) son redundantes con columnas
--     que hb_schema_base_reconstruido.sql ya deja creadas de una vez — no es
--     una contradicción, es que ambos archivos describen el mismo estado
--     final por caminos distintos (create-desde-cero vs. alter-incremental)
--     y las guardas IF NOT EXISTS hacen que correr ambos en este orden sea
--     un no-op seguro, sin error.
--   • parte2 → hb_crm_formularios, hb_crm_prospectos, hb_crm_empresas,
--     hb_normaliza() (archivos 2/4): todas ya existen. hb_crm_landings y
--     hb_crm_visitas se crean dentro de este mismo bloque antes de que
--     crm_landing_config()/crm_registrar_visita() las usen.
--   • parte3 → gp_proyectos, gp_tareas: las crea setup_v56.sql (archivo 1).
-- No encontré ninguna sentencia que dependa de algo que no quede creado por
-- lo que la precede en este orden.
--
-- DECISIONES DE CONSOLIDACIÓN QUE SE MANTIENEN DEL CONSOLIDADO ANTERIOR:
--   • setup.sql (raíz) — EXCLUIDO: supersedido por setup_v56.sql (su propio
--     encabezado lo dice), incluir ambos duplicaría ~46 tablas/políticas.
--   • sql/schema.sql — EXCLUIDO: no es SQL ejecutable, es un volcado UTF-16
--     de un resultado de consulta (snapshot de auditoría del 05/07/2026),
--     no un script pensado para correrse.
--
-- GAP QUE SIGUE ABIERTO (sin cambios respecto a la versión anterior de este
-- archivo — no se tocó en esta fusión):
--   • crm_form_config() — la función de solo-lectura que usa form.html para
--     traer la config de un formulario público — NO aparece en ningún
--     archivo del repo. Un clon que corra solo este consolidado tendría
--     crm_captar_lead()/crm_landing_config() pero le faltaría
--     crm_form_config() — form.html no podría cargar el formulario. No se
--     inventó su contenido.
--
-- Nota de ubicación: hb_schema_base_reconstruido.sql, limen_master_sesion_
-- 13ago.sql, limen_master_sesion_13ago_parte2.sql y limen_master_sesion_
-- 14ago_parte3.sql viven en la RAÍZ del repo, no en sql/ — se leyeron de ahí.
-- El bloque financiero no tiene archivo propio en el repo (se recibió como
-- adjunto verificado 1:1 contra producción); vive solo dentro de este
-- consolidado.
--
-- Ningún archivo original fue borrado ni modificado — este consolidado es
-- un archivo NUEVO, adicional, y se regenera completo cada vez.
-- ============================================================================


-- ============================================
-- UMBRAL (Check Plus) · SETUP MAESTRO v56
-- Ejecutar completo en el SQL Editor de un proyecto Supabase NUEVO.
-- Recrea desde cero toda la base de datos que index.html (v56) espera
-- encontrar. SUPERSEDE a setup.sql — usar este archivo, no el anterior.
--
-- Generado por auditoría exhaustiva de index.html v56 (sbGetAll/sbUpsert/
-- sbDelete/disenoSbUpsert/disenoSbDelete, fetch directos a /rest/v1/, canal
-- Realtime 'checkplus-live' en startRealtime(), y subidas a
-- /storage/v1/object/). Resultado de la auditoría: las 46 tablas y 6 buckets
-- de storage.sql YA estaban completos y correctos para v56 (verificado
-- columna por columna contra los payloads reales de guardado en el código,
-- p.ej. gpTareaSaveSB/kbSaveCardSB) — no se encontró ninguna tabla, columna
-- ni bucket usado en el código que faltara en setup.sql.
--
-- LO QUE SÍ FALTABA Y ES NUEVO EN ESTE ARCHIVO: SECCIÓN 4 — la suscripción
-- Realtime del canal 'checkplus-live' nunca se agregó a la publicación
-- supabase_realtime. Un proyecto Supabase nuevo, aunque tenga la publicación
-- 'supabase_realtime' de fábrica, NO emite eventos postgres_changes de NINGUNA
-- tabla hasta que se agrega explícitamente con ALTER PUBLICATION ... ADD TABLE.
-- Sin esto, sb.channel('checkplus-live').on('postgres_changes', ...) nunca
-- recibe eventos y el estado que ve el usuario en consola es CHANNEL_ERROR /
-- reintentos infinitos — la app funciona, pero sin actualizaciones en vivo.
--
-- DECISIONES DE DISEÑO (heredadas de setup.sql, sin cambios):
--  1. Todos los IDs son TEXT, no UUID — la app genera sus propios IDs con
--     uid9() ('c'+timestamp+random). DEFAULT gen_random_uuid()::text queda
--     solo como red de seguridad para las pocas tablas donde el cliente
--     nunca manda id explícito (vacaciones, documentos, solicitudes,
--     seguimientos, seg_tareas, audit_log).
--  2. Foreign keys: SOLO se crean las 5 que son indispensables para que
--     PostgREST resuelva el nested select de dbLoad():
--       sb.from('empleados').select('*, vacaciones(*), documentos(*),
--         solicitudes(*), seguimientos(*, seg_tareas(*))')
--     Todas las demás relaciones padre-hijo (eval_pilares→eval_plantillas,
--     direccion_hitos→direccion_proyectos, gp_tareas→gp_proyectos, etc.)
--     se comprobó en el código que la propia app borra los hijos a mano
--     antes que el padre (ver disenoEliminarProyecto / evalDeletePilar) —
--     nunca dependen de ON DELETE CASCADE — así que añadir esas FKs no
--     aporta nada y sí puede estorbar en restauraciones de backup.
--
-- IMPORTANTE — lo que este script NO puede hacer (vive en index.html, no en
-- la base de datos, y esta tarea tiene prohibido tocar ese archivo):
--  - SUPABASE_URL / SUPABASE_KEY (líneas ~4851-4852) siguen apuntando al
--    proyecto Supabase actual de Check Plus. Para un cliente nuevo en un
--    proyecto Supabase nuevo, ESTE SCRIPT NO ES SUFICIENTE por sí solo —
--    alguien debe además actualizar esas dos constantes en index.html para
--    que el frontend apunte a la base de datos que este script crea.
--  - Los nombres de apps internas de Check Plus ('Check Plus','Check In',
--    'HR +','Obras Plus') están escritos directamente en el HTML/JS de
--    Desarrollos y Soporte (listas hardcoded, no vienen de una tabla) — un
--    cliente distinto los vería tal cual salvo que alguien edite el código.
-- ============================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================
-- SECCIÓN 1: TABLAS
-- ============================================

-- ── EMPLEADOS Y MÓDULOS ANIDADOS ─────────────────────
CREATE TABLE IF NOT EXISTS empleados (
  id             text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  emp_id         text,
  nombre         text,
  apellidos      text,
  cargo          text,
  departamento   text,
  ingreso_date   text,
  bday           text,
  contrato       text,
  email          text,
  tel            text,
  curp           text,
  rfc            text,
  direccion      text,
  estado_civil   text,
  salario        numeric DEFAULT 0,
  banco          text,
  clabe          text,
  estado         text DEFAULT 'activo',
  color          text DEFAULT 'blue',
  foto_url       text,
  acceso_activo  boolean DEFAULT false,
  doc_folders    jsonb DEFAULT '[]'::jsonb,
  created_at     timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS vacaciones (
  id           text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  empleado_id  text REFERENCES empleados(id) ON DELETE CASCADE,
  start_date   text,
  end_date     text,
  dias         numeric DEFAULT 0,
  notas        text,
  estado       text DEFAULT 'programado',
  doc_url      text,
  doc_nombre   text,
  created_at   timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS documentos (
  id           text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  empleado_id  text REFERENCES empleados(id) ON DELETE CASCADE,
  tipo         text,
  nombre       text,
  notas        text,
  fecha        text,
  doc_url      text,
  folder_id    text,
  created_at   timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS solicitudes (
  id           text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  empleado_id  text REFERENCES empleados(id) ON DELETE CASCADE,
  tipo         text,
  start_date   text,
  end_date     text,
  descripcion  text,
  estado       text DEFAULT 'pendiente',
  created_at   timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS seguimientos (
  id           text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  empleado_id  text REFERENCES empleados(id) ON DELETE CASCADE,
  fecha        text,
  proximo      text,
  titulo       text,
  notas        text,
  estado       text,
  archivos     jsonb DEFAULT '[]'::jsonb,
  created_at   timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS seg_tareas (
  id               text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  seguimiento_id   text REFERENCES seguimientos(id) ON DELETE CASCADE,
  texto            text,
  done             boolean DEFAULT false,
  prioridad        text DEFAULT 'normal',
  created_at       timestamptz DEFAULT now()
);

-- ── KANBAN ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS kb_boards (
  id          text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  nombre      text,
  tipo        text DEFAULT 'compartido',
  owner_id    text,
  members     jsonb DEFAULT '[]'::jsonb,
  columns     jsonb DEFAULT '[]'::jsonb,
  categories  jsonb DEFAULT '[]'::jsonb,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS kb_cards (
  id              text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  board_id        text,
  titulo          text,
  descripcion     text,
  categoria       text,
  prio            text,
  due             text,
  assignee_id     text,
  subtasks        jsonb DEFAULT '[]'::jsonb,
  adjunto_url     text,
  adjunto_nombre  text,
  column_id       text,
  order_idx       numeric DEFAULT 0,
  done            boolean DEFAULT false,
  archived        boolean DEFAULT false,
  history         jsonb DEFAULT '[]'::jsonb,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

-- ── CLIENTES / PRODUCTOS ──────────────────────────────
CREATE TABLE IF NOT EXISTS clientes (
  id                 text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  nombre             text,
  rfc                text,
  email              text,
  tel                text,
  contacto           text,
  direccion          text,
  notas              text,
  status             text,
  color              text,
  foto_url           text,
  venc_contrato      text,
  alerta_dias        numeric DEFAULT 30,
  facturacion        jsonb DEFAULT '[]'::jsonb,
  productos          jsonb DEFAULT '[]'::jsonb,
  documentos         jsonb DEFAULT '[]'::jsonb,
  tipo_pago          text,
  fecha_inicio       text,
  fecha_inicio_demo  text,
  fecha_fin_demo     text,
  responsable_id     text,
  responsable_libre  text,
  created_at         timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS productos (
  id           text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  nombre       text,
  descripcion  text,
  color        text DEFAULT '#7B2FF7',
  created_at   timestamptz DEFAULT now()
);

-- ── DESARROLLOS (pipeline de 10 etapas) ───────────────
CREATE TABLE IF NOT EXISTS desarrollos (
  id                       text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  titulo                   text,
  descripcion              text,
  observaciones            text,
  tipo                     text DEFAULT 'mejora',
  stage                    text DEFAULT 'solicitud',
  prio                     text DEFAULT 'media',
  aspect                   text,
  app                      text,
  cliente_id               text,
  stage_data               jsonb DEFAULT '{}'::jsonb,
  stage_log                jsonb DEFAULT '[]'::jsonb,
  fecha_cierre             text,
  fecha_entrega_productivo text,
  cp_complexity            text,
  nl_difficulty            text,
  fecha_solicitud          text,
  fecha_inicio             text,
  fecha_testing            text,
  fecha_productivo         text,
  horas_est                numeric DEFAULT 0,
  horas_real               numeric DEFAULT 0,
  tarifa                   numeric DEFAULT 0,
  costo                    numeric DEFAULT 0,
  resp_nelumbo             jsonb DEFAULT '[]'::jsonb,
  resp_cp                  jsonb DEFAULT '[]'::jsonb,
  subtasks                 jsonb DEFAULT '[]'::jsonb,
  files                    jsonb DEFAULT '[]'::jsonb,
  versions                 jsonb DEFAULT '[]'::jsonb,
  reprocesos               jsonb DEFAULT '[]'::jsonb,
  created_at               timestamptz DEFAULT now()
);

-- ── ORGANIGRAMA ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS org_depts (
  id          text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  nombre      text,
  color       text,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS org_nodes (
  id          text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  tipo        text,
  colab_id    text,
  nombre      text,
  cargo       text,
  email       text,
  tel         text,
  dept_id     text,
  parent_id   text,
  color       text,
  foto_url    text,
  pos_x       numeric DEFAULT 0,
  pos_y       numeric DEFAULT 0,
  funciones   jsonb,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cargos (
  id                text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  nombre            text,
  descripcion       text,
  nivel             text,
  permisos          jsonb,
  dept_id           text,
  headcount_target  numeric DEFAULT 0,
  funciones         jsonb DEFAULT '[]'::jsonb,
  kpis              jsonb DEFAULT '[]'::jsonb,
  color             text,
  created_at        timestamptz DEFAULT now()
);

-- ── MARKETING ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS mkt_agencias (
  id          text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  nombre      text,
  contacto    text,
  email       text,
  tel         text,
  notas       text,
  tarifa      numeric DEFAULT 0,
  tipo        text,
  status      text,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS mkt_campanas (
  id              text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  nombre          text,
  objetivo        text,
  observaciones   text,
  stage           text,
  prio            text,
  canales         jsonb DEFAULT '[]'::jsonb,
  agencia_id      text,
  responsable_id  text,
  fecha_inicio    text,
  fecha_fin       text,
  presupuesto     numeric DEFAULT 0,
  costo_real      numeric DEFAULT 0,
  imp_obj         numeric DEFAULT 0,
  leads_obj       numeric DEFAULT 0,
  conv_obj        numeric DEFAULT 0,
  imp_real        numeric DEFAULT 0,
  leads_real      numeric DEFAULT 0,
  conv_real       numeric DEFAULT 0,
  subtasks        jsonb DEFAULT '[]'::jsonb,
  files           jsonb DEFAULT '[]'::jsonb,
  created_at      timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS mkt_proyectos (
  id            text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  tipo          text DEFAULT 'proyecto',
  nombre        text,
  descripcion   text,
  stage         text,
  agencia_id    text,
  resp_id       text,
  fecha_inicio  text,
  fecha_fin     text,
  presupuesto   numeric DEFAULT 0,
  subtasks      jsonb DEFAULT '[]'::jsonb,
  files         jsonb DEFAULT '[]'::jsonb,
  created_at    timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS mkt_docs (
  id          text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  nombre      text,
  categoria   text,
  version     text,
  doc_base64  text,
  doc_nombre  text,
  fecha       text,
  created_at  timestamptz DEFAULT now()
);

-- ── REPOSITORIO ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS repo_carpetas (
  id          text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  nombre      text,
  parent_id   text,
  orden       numeric DEFAULT 0,
  color       text,
  icono       text,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS repositorio (
  id           text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  nombre       text,
  tipo         text,
  url          text,
  descripcion  text,
  cliente_id   text,
  tags         jsonb DEFAULT '[]'::jsonb,
  fecha        text,
  subido_por   text,
  size         numeric DEFAULT 0,
  carpeta_id   text,
  created_at   timestamptz DEFAULT now()
);

-- ── SOPORTE TÉCNICO ───────────────────────────────────
CREATE TABLE IF NOT EXISTS sp_tickets (
  id                text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  folio             text,
  tipo_id           text,
  titulo            text,
  detalle           text,
  estado_id         text,
  prio              text,
  app               text,
  apps              jsonb DEFAULT '[]'::jsonb,
  version           text,
  cliente_id        text,
  cliente_nombre    text,
  cliente_libre     text,
  tecnico_id        text,
  tecnico_nombre    text,
  tecnicos          jsonb DEFAULT '[]'::jsonb,
  fecha_inicio      text,
  fecha_fin         text,
  fecha_cierre      text,
  horas_invertidas  numeric DEFAULT 0,
  solucion          text,
  tags              jsonb DEFAULT '[]'::jsonb,
  files             jsonb DEFAULT '[]'::jsonb,
  cerrado           boolean DEFAULT false,
  created_at        timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sp_config (
  id           text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  config_json  jsonb DEFAULT '{}'::jsonb,
  created_at   timestamptz DEFAULT now()
);

-- ── SISTEMA: USUARIOS, AUDITORÍA, CONFIG, SECRETOS ────
CREATE TABLE IF NOT EXISTS user_profiles (
  user_id          text PRIMARY KEY,
  display_name     text,
  email            text,
  role             text DEFAULT 'usuario',
  modules_allowed  jsonb DEFAULT '{}'::jsonb,
  created_at       timestamptz DEFAULT now(),
  updated_at       timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS audit_log (
  id             text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  usuario_id     text,
  usuario_nombre text,
  accion         text,
  tabla          text,
  registro_id    text,
  detalle        text,
  fecha          timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS app_config (
  id          text PRIMARY KEY,
  config      jsonb DEFAULT '{}'::jsonb,
  updated_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS app_secrets (
  clave       text PRIMARY KEY,
  valor       text,
  updated_at  timestamptz DEFAULT now()
);

-- ── CRM (Clientify) ───────────────────────────────────
CREATE TABLE IF NOT EXISTS crm_leads (
  id                  text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  nombre              text,
  apellidos           text,
  empresa             text,
  cargo               text,
  email               text,
  telefono            text,
  estado              text,
  propietario         text,
  origen              text,
  etapa_oportunidad   text,
  lead_scoring        text,
  etiquetas           text,
  observaciones       text,
  descripcion         text,
  importe_ganadas     numeric DEFAULT 0,
  importe_perdidas    numeric DEFAULT 0,
  creado              text,
  ultimo_contacto     text,
  num_colaboradores   text,
  raw_data            jsonb DEFAULT '{}'::jsonb,
  imported_at         timestamptz DEFAULT now()
);

-- ── OKRs ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS okrs (
  id              text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  titulo          text,
  descripcion     text,
  tipo            text DEFAULT 'empresa',
  visibilidad     text DEFAULT 'empresa',
  members         jsonb DEFAULT '[]'::jsonb,
  area            text,
  estado          text DEFAULT 'activo',
  periodo         text,
  responsable_id  text,
  owner_id        text,
  fecha_inicio    text,
  fecha_fin       text,
  created_at      timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS okr_krs (
  id              text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  okr_id          text,
  titulo          text,
  descripcion     text,
  tipo_metrica    text DEFAULT 'porcentaje',
  valor_inicial   numeric DEFAULT 0,
  valor_actual    numeric DEFAULT 0,
  valor_meta      numeric DEFAULT 100,
  unidad          text,
  responsable_id  text,
  checkins        jsonb DEFAULT '[]'::jsonb,
  orden           numeric DEFAULT 0,
  fecha_inicio    text,
  fecha_fin       text,
  observaciones   text,
  created_at      timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS okr_checkins (
  id              text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  kr_id           text,
  fecha           text,
  valor_nuevo     numeric DEFAULT 0,
  progreso_pct    numeric DEFAULT 0,
  estado          text,
  comentario      text,
  proxima_accion  text,
  user_id         text,
  user_nombre     text,
  created_at      timestamptz DEFAULT now()
);

-- ── EVALUACIONES DE DESEMPEÑO ─────────────────────────
CREATE TABLE IF NOT EXISTS eval_plantillas (
  id           text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  nombre       text,
  descripcion  text,
  activa       boolean DEFAULT true,
  created_by   text,
  created_at   timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS eval_pilares (
  id            text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  plantilla_id  text,
  nombre        text,
  orden         numeric DEFAULT 0
);

CREATE TABLE IF NOT EXISTS eval_criterios (
  id           text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  pilar_id     text,
  subgrupo     text,
  detalle      text,
  descripcion  text,
  orden        numeric DEFAULT 0
);

CREATE TABLE IF NOT EXISTS eval_evaluaciones (
  id            text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  plantilla_id  text,
  empleado_id   text,
  evaluador_id  text,
  tipo          text DEFAULT 'jefe',
  estado        text DEFAULT 'borrador',
  fecha_inicio  text,
  fecha_cierre  text,
  created_at    timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS eval_respuestas (
  id             text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  evaluacion_id  text,
  criterio_id    text,
  calificacion   numeric DEFAULT 0,
  observacion    text,
  created_at     timestamptz DEFAULT now()
);

-- ── DISEÑO ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS diseno_proyectos (
  id                 text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  titulo             text,
  descripcion        text,
  cliente_id         text,
  estado             text,
  prioridad          text,
  fecha_inicio       text,
  fecha_entrega      text,
  aplicacion         text,
  tipo_trabajo       text,
  solicitante        text,
  solicitante_libre  text,
  archivos           jsonb DEFAULT '[]'::jsonb,
  created_by         text,
  orden_manual       numeric,
  created_at         timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS diseno_tareas (
  id                 text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  proyecto_id        text,
  titulo             text,
  descripcion        text,
  asignado_a         text,
  estado             text,
  prioridad          text,
  fecha_entrega      text,
  tipo_trabajo       text,
  fecha_completada   text,
  comentarios        jsonb DEFAULT '[]'::jsonb,
  archivos           jsonb DEFAULT '[]'::jsonb,
  created_by         text,
  unidades_total     numeric,
  unidades_avance    numeric DEFAULT 0,
  orden              numeric,
  created_at         timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS diseno_publicaciones (
  id                text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  fecha             text,
  red_social        text,
  estado            text,
  link_publicacion  text,
  nota              text,
  autor_id          text,
  autor_nombre      text,
  confirmado_at     text,
  created_at        timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS diseno_calendario_notas (
  id            text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  fecha         text,
  nota          text,
  autor_id      text,
  autor_nombre  text,
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now()
);

-- ── DIRECCIÓN (admin-only, tracker estratégico) ───────
CREATE TABLE IF NOT EXISTS direccion_proyectos (
  id               text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  titulo           text,
  descripcion      text,
  area             text,
  estado           text DEFAULT 'activo',
  prioridad        text DEFAULT 'media',
  implicados       jsonb DEFAULT '[]'::jsonb,
  fecha_inicio     text,
  fecha_fin        text,
  visible_roadmap  boolean DEFAULT true,
  orden_manual     numeric,
  archivos         jsonb DEFAULT '[]'::jsonb,
  created_by       text,
  created_at       timestamptz DEFAULT now(),
  updated_at       timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS direccion_hitos (
  id              text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  proyecto_id     text,
  titulo          text,
  fecha_objetivo  text,
  estado          text DEFAULT 'pendiente',
  nota            text,
  orden           numeric DEFAULT 0,
  cumplido_at     text,
  responsable     text,
  created_at      timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS direccion_tareas (
  id                text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  proyecto_id       text,
  hito_id           text,
  titulo            text,
  descripcion       text,
  estado            text,
  prioridad         text,
  fecha_entrega     text,
  unidades_total    numeric,
  unidades_avance   numeric DEFAULT 0,
  archivos          jsonb DEFAULT '[]'::jsonb,
  fecha_completada  text,
  asignado_a        text,
  orden             numeric,
  created_at        timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS direccion_bitacora (
  id            text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  proyecto_id   text,
  tipo          text,
  texto         text,
  autor_id      text,
  autor_nombre  text,
  fecha_evento  text,
  created_at    timestamptz DEFAULT now()
);

-- ── GESTIÓN DE PROYECTOS (abierto a todos los roles) ──
CREATE TABLE IF NOT EXISTS gp_proyectos (
  id                 text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  titulo             text,
  descripcion        text,
  area               text,
  estado             text DEFAULT 'activo',
  prioridad          text DEFAULT 'media',
  implicados         jsonb DEFAULT '[]'::jsonb,
  fecha_inicio       text,
  fecha_fin          text,
  orden_manual       numeric,
  archivos           jsonb DEFAULT '[]'::jsonb,
  created_by         text,
  created_by_nombre  text,
  created_at         timestamptz DEFAULT now(),
  updated_at         timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS gp_tareas (
  id                 text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  proyecto_id        text,
  titulo             text,
  descripcion        text,
  estado             text,
  prioridad          text,
  asignado_a         text,
  fecha_entrega      text,
  unidades_total     numeric,
  unidades_avance    numeric DEFAULT 0,
  archivos           jsonb DEFAULT '[]'::jsonb,
  created_by         text,
  created_by_nombre  text,
  fecha_completada   text,
  orden              numeric,
  created_at         timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS gp_bitacora (
  id            text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  proyecto_id   text,
  tipo          text,
  texto         text,
  autor_id      text,
  autor_nombre  text,
  fecha_evento  text,
  created_at    timestamptz DEFAULT now()
);

-- ============================================
-- SECCIÓN 2: ROW LEVEL SECURITY
-- ============================================
-- Patrón general: cualquier usuario autenticado puede hacer todo (SELECT/
-- INSERT/UPDATE/DELETE). El control de "quién puede ver/editar qué módulo"
-- vive en user_profiles.modules_allowed y se aplica en el cliente (canView/
-- canEdit en index.html) — la app nunca esperó RLS granular por módulo.
-- Excepciones reales encontradas en el código: user_profiles (política
-- permisiva simple, sin subqueries — evita el deadlock que ya se vio en
-- producción), audit_log (lectura solo admin) y app_secrets (escritura solo
-- admin; lectura abierta porque el chat de IA la necesita para todos).

ALTER TABLE empleados ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS empleados_all ON empleados;
CREATE POLICY empleados_all ON empleados FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE vacaciones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS vacaciones_all ON vacaciones;
CREATE POLICY vacaciones_all ON vacaciones FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE documentos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS documentos_all ON documentos;
CREATE POLICY documentos_all ON documentos FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE solicitudes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS solicitudes_all ON solicitudes;
CREATE POLICY solicitudes_all ON solicitudes FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE seguimientos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS seguimientos_all ON seguimientos;
CREATE POLICY seguimientos_all ON seguimientos FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE seg_tareas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS seg_tareas_all ON seg_tareas;
CREATE POLICY seg_tareas_all ON seg_tareas FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE kb_boards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS kb_boards_all ON kb_boards;
CREATE POLICY kb_boards_all ON kb_boards FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE kb_cards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS kb_cards_all ON kb_cards;
CREATE POLICY kb_cards_all ON kb_cards FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS clientes_all ON clientes;
CREATE POLICY clientes_all ON clientes FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE productos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS productos_all ON productos;
CREATE POLICY productos_all ON productos FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE desarrollos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS desarrollos_all ON desarrollos;
CREATE POLICY desarrollos_all ON desarrollos FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE org_depts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS org_depts_all ON org_depts;
CREATE POLICY org_depts_all ON org_depts FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE org_nodes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS org_nodes_all ON org_nodes;
CREATE POLICY org_nodes_all ON org_nodes FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE cargos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS cargos_all ON cargos;
CREATE POLICY cargos_all ON cargos FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE mkt_agencias ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mkt_agencias_all ON mkt_agencias;
CREATE POLICY mkt_agencias_all ON mkt_agencias FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE mkt_campanas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mkt_campanas_all ON mkt_campanas;
CREATE POLICY mkt_campanas_all ON mkt_campanas FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE mkt_proyectos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mkt_proyectos_all ON mkt_proyectos;
CREATE POLICY mkt_proyectos_all ON mkt_proyectos FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE mkt_docs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mkt_docs_all ON mkt_docs;
CREATE POLICY mkt_docs_all ON mkt_docs FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE repo_carpetas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS repo_carpetas_all ON repo_carpetas;
CREATE POLICY repo_carpetas_all ON repo_carpetas FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE repositorio ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS repositorio_all ON repositorio;
CREATE POLICY repositorio_all ON repositorio FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE sp_tickets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS sp_tickets_all ON sp_tickets;
CREATE POLICY sp_tickets_all ON sp_tickets FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE sp_config ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS sp_config_all ON sp_config;
CREATE POLICY sp_config_all ON sp_config FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS app_config_all ON app_config;
CREATE POLICY app_config_all ON app_config FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE crm_leads ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS crm_leads_all ON crm_leads;
CREATE POLICY crm_leads_all ON crm_leads FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE okrs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS okrs_all ON okrs;
CREATE POLICY okrs_all ON okrs FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE okr_krs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS okr_krs_all ON okr_krs;
CREATE POLICY okr_krs_all ON okr_krs FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE okr_checkins ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS okr_checkins_all ON okr_checkins;
CREATE POLICY okr_checkins_all ON okr_checkins FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE eval_plantillas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS eval_plantillas_all ON eval_plantillas;
CREATE POLICY eval_plantillas_all ON eval_plantillas FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE eval_pilares ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS eval_pilares_all ON eval_pilares;
CREATE POLICY eval_pilares_all ON eval_pilares FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE eval_criterios ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS eval_criterios_all ON eval_criterios;
CREATE POLICY eval_criterios_all ON eval_criterios FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE eval_evaluaciones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS eval_evaluaciones_all ON eval_evaluaciones;
CREATE POLICY eval_evaluaciones_all ON eval_evaluaciones FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE eval_respuestas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS eval_respuestas_all ON eval_respuestas;
CREATE POLICY eval_respuestas_all ON eval_respuestas FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE diseno_proyectos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS diseno_proyectos_all ON diseno_proyectos;
CREATE POLICY diseno_proyectos_all ON diseno_proyectos FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE diseno_tareas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS diseno_tareas_all ON diseno_tareas;
CREATE POLICY diseno_tareas_all ON diseno_tareas FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE diseno_publicaciones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS diseno_publicaciones_all ON diseno_publicaciones;
CREATE POLICY diseno_publicaciones_all ON diseno_publicaciones FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE diseno_calendario_notas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS diseno_calendario_notas_all ON diseno_calendario_notas;
CREATE POLICY diseno_calendario_notas_all ON diseno_calendario_notas FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE direccion_proyectos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS direccion_proyectos_all ON direccion_proyectos;
CREATE POLICY direccion_proyectos_all ON direccion_proyectos FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE direccion_hitos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS direccion_hitos_all ON direccion_hitos;
CREATE POLICY direccion_hitos_all ON direccion_hitos FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE direccion_tareas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS direccion_tareas_all ON direccion_tareas;
CREATE POLICY direccion_tareas_all ON direccion_tareas FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE direccion_bitacora ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS direccion_bitacora_all ON direccion_bitacora;
CREATE POLICY direccion_bitacora_all ON direccion_bitacora FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE gp_proyectos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS gp_proyectos_all ON gp_proyectos;
CREATE POLICY gp_proyectos_all ON gp_proyectos FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE gp_tareas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS gp_tareas_all ON gp_tareas;
CREATE POLICY gp_tareas_all ON gp_tareas FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE gp_bitacora ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS gp_bitacora_all ON gp_bitacora;
CREATE POLICY gp_bitacora_all ON gp_bitacora FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- user_profiles: política permisiva simple — NUNCA usar subqueries
-- restrictivas aquí (ya causaron un deadlock en producción).
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS auth_all_profiles ON user_profiles;
CREATE POLICY auth_all_profiles ON user_profiles FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- audit_log: cualquiera puede insertar (auditLog() se llama en cada acción
-- de cualquier usuario); solo admin puede leer el historial completo.
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS audit_log_insert ON audit_log;
CREATE POLICY audit_log_insert ON audit_log FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS audit_log_select_admin ON audit_log;
CREATE POLICY audit_log_select_admin ON audit_log FOR SELECT TO authenticated USING (
  EXISTS (SELECT 1 FROM user_profiles up WHERE up.user_id = auth.uid()::text AND up.role = 'admin')
);

-- app_secrets: la key de IA es compartida por todo el equipo — cualquier
-- usuario autenticado la puede LEER (la necesita el chat de IA), pero solo
-- un admin puede escribirla (saveAiKeyToSB muestra "Solo un administrador
-- puede configurar la key" cuando RLS lo rechaza).
ALTER TABLE app_secrets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS app_secrets_select ON app_secrets;
CREATE POLICY app_secrets_select ON app_secrets FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS app_secrets_admin_insert ON app_secrets;
CREATE POLICY app_secrets_admin_insert ON app_secrets FOR INSERT TO authenticated WITH CHECK (
  EXISTS (SELECT 1 FROM user_profiles up WHERE up.user_id = auth.uid()::text AND up.role = 'admin')
);
DROP POLICY IF EXISTS app_secrets_admin_update ON app_secrets;
CREATE POLICY app_secrets_admin_update ON app_secrets FOR UPDATE TO authenticated USING (
  EXISTS (SELECT 1 FROM user_profiles up WHERE up.user_id = auth.uid()::text AND up.role = 'admin')
) WITH CHECK (
  EXISTS (SELECT 1 FROM user_profiles up WHERE up.user_id = auth.uid()::text AND up.role = 'admin')
);
DROP POLICY IF EXISTS app_secrets_admin_delete ON app_secrets;
CREATE POLICY app_secrets_admin_delete ON app_secrets FOR DELETE TO authenticated USING (
  EXISTS (SELECT 1 FROM user_profiles up WHERE up.user_id = auth.uid()::text AND up.role = 'admin')
);

-- ============================================
-- SECCIÓN 3: STORAGE BUCKETS
-- ============================================
-- 6 buckets encontrados en index.html vía /storage/v1/object/ (constantes
-- EMP_DOC_STORAGE_BUCKET, COMPROBANTE_STORAGE_BUCKET, DISENO_STORAGE_BUCKET,
-- DIRECCION_STORAGE_BUCKET, GP_STORAGE_BUCKET, y sb.storage.from('repositorio')).
-- Todos menos 'repositorio' se suben con x-upsert y se leen por URL pública
-- directa (SUPABASE_URL + '/storage/v1/object/public/<bucket>/<path>'), así
-- que deben ser públicos. 'repositorio' es la única excepción: usa
-- sb.storage.from('repositorio').createSignedUrl(...) — el propio comentario
-- del código dice "for private bucket" — así que se crea con public=false.

INSERT INTO storage.buckets (id, name, public)
VALUES
  ('documentos-empleados', 'documentos-empleados', true),
  ('comprobantes-pago',    'comprobantes-pago',    true),
  ('diseno-archivos',      'diseno-archivos',      true),
  ('direccion-archivos',   'direccion-archivos',   true),
  ('gp-archivos',          'gp-archivos',          true),
  ('repositorio',          'repositorio',          false)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

-- Buckets públicos: lectura pública + escritura/actualización/borrado para
-- cualquier usuario autenticado. Se incluye UPDATE (no pedido explícitamente
-- pero necesario) porque las subidas usan header 'x-upsert: true', y Storage
-- exige la política UPDATE para sobrescribir un objeto existente.
DO $$
DECLARE
  b text;
BEGIN
  FOREACH b IN ARRAY ARRAY['documentos-empleados','comprobantes-pago','diseno-archivos','direccion-archivos','gp-archivos']
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', 'pub_select_'||b);
    EXECUTE format('CREATE POLICY %I ON storage.objects FOR SELECT TO public USING (bucket_id = %L)', 'pub_select_'||b, b);

    EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', 'auth_insert_'||b);
    EXECUTE format('CREATE POLICY %I ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = %L)', 'auth_insert_'||b, b);

    EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', 'auth_update_'||b);
    EXECUTE format('CREATE POLICY %I ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = %L) WITH CHECK (bucket_id = %L)', 'auth_update_'||b, b, b);

    EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', 'auth_delete_'||b);
    EXECUTE format('CREATE POLICY %I ON storage.objects FOR DELETE TO authenticated USING (bucket_id = %L)', 'auth_delete_'||b, b);
  END LOOP;
END $$;

-- Bucket privado 'repositorio': sin SELECT público — solo autenticados
-- (createSignedUrl funciona para cualquier rol con permiso de SELECT).
DROP POLICY IF EXISTS auth_select_repositorio ON storage.objects;
CREATE POLICY auth_select_repositorio ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'repositorio');
DROP POLICY IF EXISTS auth_insert_repositorio ON storage.objects;
CREATE POLICY auth_insert_repositorio ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'repositorio');
DROP POLICY IF EXISTS auth_update_repositorio ON storage.objects;
CREATE POLICY auth_update_repositorio ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'repositorio') WITH CHECK (bucket_id = 'repositorio');
DROP POLICY IF EXISTS auth_delete_repositorio ON storage.objects;
CREATE POLICY auth_delete_repositorio ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'repositorio');

-- ============================================
-- SECCIÓN 4: REALTIME PUBLICATION  ── NUEVO en v56 ──
-- ============================================
-- CRITICAL FIX: startRealtime() (index.html) abre un único canal
-- 'checkplus-live' y se suscribe con postgres_changes a estas 17 tablas.
-- Un proyecto Supabase nuevo trae la publicación 'supabase_realtime' vacía
-- de fábrica — sin este bloque, CADA una de esas suscripciones queda muda:
-- no truena en el cliente de forma obvia, pero el canal nunca emite eventos
-- y termina en CHANNEL_ERROR / reintento infinito con backoff (ver
-- _realtimeReconnectDelay en el código). Este bloque es idempotente: se
-- puede volver a correr sobre un proyecto que ya tiene algunas tablas
-- publicadas sin error, a diferencia de un ALTER PUBLICATION suelto (que sí
-- truena si la tabla ya es miembro).
DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'empleados',
    'vacaciones',
    'kb_cards',
    'desarrollos',
    'sp_tickets',
    'clientes',
    'diseno_proyectos',
    'diseno_tareas',
    'diseno_publicaciones',
    'diseno_calendario_notas',
    'direccion_proyectos',
    'direccion_hitos',
    'direccion_tareas',
    'direccion_bitacora',
    'gp_proyectos',
    'gp_tareas',
    'gp_bitacora'
  ]
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = t
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', t);
    END IF;
  END LOOP;
END $$;

-- ============================================
-- SECCIÓN 5: DATOS SEED
-- ============================================
-- Sin datos de Check Plus: nada de empleados, clientes, productos, nombres
-- ni correos reales. Solo configuración/plantillas que la app espera
-- encontrar (o que ya trae como fallback en memoria, pero es mejor tener
-- la fila real en la base para que Configuración pueda editarla).

-- ── Plantilla de evaluación por defecto (5 pilares, 37 criterios) ─────
-- Copiado literal de seedDefaultEvalTemplate() + EVAL_DESCS en index.html.
INSERT INTO eval_plantillas (id, nombre, descripcion, activa)
VALUES ('pl-default', 'Evaluación de Desempeño General', 'Plantilla estándar por competencias con 5 pilares clave', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO eval_pilares (id, plantilla_id, nombre, orden) VALUES
  ('pil-adaptabilidad', 'pl-default', 'Adaptabilidad', 0),
  ('pil-comunicacion',  'pl-default', 'Comunicación Efectiva', 1),
  ('pil-confianza',     'pl-default', 'Confianza', 2),
  ('pil-comercial',     'pl-default', 'Espíritu Comercial', 3),
  ('pil-analitico',     'pl-default', 'Pensamiento Analítico', 4)
ON CONFLICT (id) DO NOTHING;

INSERT INTO eval_criterios (id, pilar_id, subgrupo, detalle, descripcion, orden) VALUES
  ('crit-01', 'pil-adaptabilidad', 'Liderazgo', 'Adaptabilidad', 'Se ajusta a cambios organizacionales o procesos de manera positiva.', 0),
  ('crit-02', 'pil-adaptabilidad', 'Liderazgo', 'Autoregulación emocional', 'Maneja sus emociones de manera adecuada, especialmente en situaciones de estrés o conflicto.', 1),
  ('crit-03', 'pil-adaptabilidad', 'Liderazgo', 'Redefinición estratégica', 'Evalúa rápidamente el impacto del cambio y define estrategias alternativas para asegurar el cumplimiento de metas.', 2),
  ('crit-04', 'pil-adaptabilidad', 'Liderazgo', 'Resiliencia', 'Busca oportunidades de aprendizaje en situaciones imprevistas en lugar de resistirse al cambio.', 3),
  ('crit-05', 'pil-adaptabilidad', 'Liderazgo', 'Adaptación sin pérdida de calidad', 'Se adapta de manera ágil y efectiva a cambios en procesos, objetivos o prioridades sin comprometer la calidad de su trabajo.', 4),

  ('crit-06', 'pil-comunicacion', 'Comunicación', 'Comunicación asertiva', 'Explica ideas con claridad y respeto. Da instrucciones claras y comprensibles.', 5),
  ('crit-07', 'pil-comunicacion', 'Comunicación', 'Verificación del mensaje', 'Escucha de Manera activa y se asegura de estar recibiendo la información correcta del emisor, confirmando lo entendido.', 6),
  ('crit-08', 'pil-comunicacion', 'Comunicación', 'Adaptación del lenguaje', 'Utiliza un lenguaje claro y conciso, ajustándolo al nivel de la audiencia, contexto y canal de comunicación.', 7),
  ('crit-09', 'pil-comunicacion', 'Comunicación', 'Aseguramiento de la comprensión', 'Comunica sus ideas de manera oportuna, asegurando que sus interlocutores comprendan correctamente lo expuesto y en caso contrario aclara dudas.', 8),
  ('crit-10', 'pil-comunicacion', 'Liderazgo', 'Feedback constructivo', 'Ofrece retroalimentación de manera clara, respetuosa y enfocada en el desarrollo del equipo. Ofrece retroalimentación transparente y sincera.', 9),

  ('crit-11', 'pil-confianza', 'Liderazgo', 'Bienestar del equipo', 'Fomenta un ambiente de trabajo saludable y promueve el bienestar emocional del equipo.', 10),
  ('crit-12', 'pil-confianza', 'Liderazgo', 'Clima de trabajo positivo', 'Fomenta un ambiente de confianza donde los miembros del equipo se sienten seguros para compartir ideas y dar su opinión.', 11),
  ('crit-13', 'pil-confianza', 'Trabajo en equipo', 'Aporte y actitud en reuniones', 'Participa activamente y fomenta un ambiente constructivo en reuniones.', 12),
  ('crit-14', 'pil-confianza', 'Trabajo en equipo', 'Apoyo a otros procesos', 'Brinda ayuda a otros líderes o áreas cuando es necesario.', 13),
  ('crit-15', 'pil-confianza', 'Trabajo en equipo', 'Fomento de la colaboración', 'Incentiva la colaboración entre diferentes áreas y miembros del equipo.', 14),
  ('crit-16', 'pil-confianza', 'Trabajo en equipo', 'Gestión de conflictos', 'Maneja de forma efectiva los conflictos dentro del equipo, promoviendo la resolución pacífica.', 15),
  ('crit-17', 'pil-confianza', 'Trabajo en equipo', 'Relacionamiento', 'Mantiene una actitud positiva y promueve relaciones saludables.', 16),
  ('crit-18', 'pil-confianza', 'Rendimiento', 'Responsabilidad', 'Se hace cargo de sus tareas sin necesidad de recordatorios constantes.', 17),

  ('crit-19', 'pil-comercial', 'Comunicación', 'Escucha activa', 'Escucha activamente las necesidades y expectativas de los clientes internos, externos y compañeros, ofreciendo soluciones adecuadas a dichas necesidades. Se muestra empático ante la situación.', 18),
  ('crit-20', 'pil-comercial', 'Liderazgo', 'Empatía', 'Se pone en el lugar de los demás, comprendiendo sus emociones y necesidades para ofrecer apoyo adecuado.', 19),
  ('crit-21', 'pil-comercial', 'Liderazgo', 'Reconocimiento de logros', 'Reconoce y celebra los logros individuales y del equipo, fortaleciendo la moral y el compromiso.', 20),
  ('crit-22', 'pil-comercial', 'Liderazgo', 'Pensamiento sistémico', 'Actúa con iniciativa anticipándose a las necesidades de los clientes internos y externos.', 21),

  ('crit-23', 'pil-analitico', 'Liderazgo', 'Gestión del tiempo', 'Planifica y organiza su tiempo de manera eficiente. Es consciente del uso de elementos distractores.', 22),
  ('crit-24', 'pil-analitico', 'Liderazgo', 'Proactividad', 'Toma la iniciativa para resolver problemas y mejorar procesos, sin esperar a que surjan problemas.', 23),
  ('crit-25', 'pil-analitico', 'Liderazgo', 'Seguimiento de proyectos', 'Supervisa el avance de los proyectos en tiempo real, asegurando que se cumplan los plazos y que se mantenga la calidad esperada.', 24),
  ('crit-26', 'pil-analitico', 'Planificación y proyectos', 'Gestión de plazos', 'Asegura que los proyectos se entreguen dentro de los plazos establecidos.', 25),
  ('crit-27', 'pil-analitico', 'Planificación y proyectos', 'Implementación de mejoras', 'Ejecuta cambios y mejoras en los procesos de trabajo para incrementar el rendimiento del proceso.', 26),
  ('crit-28', 'pil-analitico', 'Planificación y proyectos', 'Planificación de proyectos', 'Desarrolla planes claros para el logro de los objetivos del área.', 27),
  ('crit-29', 'pil-analitico', 'Planificación y proyectos', 'Priorización de tareas', 'Organiza y establece prioridades para el cumplimiento de metas a corto y largo plazo.', 28),
  ('crit-30', 'pil-analitico', 'Rendimiento', 'Eficiencia operativa', 'Busca constantemente formas de optimizar los procesos.', 29),
  ('crit-31', 'pil-analitico', 'Rendimiento', 'Gestión de indicadores', 'Monitorea los KPIs de rendimiento y ajusta las estrategias si es necesario.', 30),
  ('crit-32', 'pil-analitico', 'Rendimiento', 'Resolución de problemas', 'Identifica y resuelve problemas de manera efectiva, manteniendo el flujo de trabajo.', 31),
  ('crit-33', 'pil-analitico', 'Rendimiento', 'Toma de decisiones', 'Toma decisiones rápidas y efectivas basadas en datos y contexto.', 32),
  ('crit-34', 'pil-analitico', 'Rendimiento', 'Análisis de clientes', 'Analiza tendencias del mercado y las necesidades de los clientes internos y externos para detectar áreas de crecimiento, mejora o innovación y propone iniciativas en consecuencia.', 33),
  ('crit-35', 'pil-analitico', 'Rendimiento', 'Solución basada en datos', 'Genera diferentes alternativas viables basadas en el análisis de datos, priorizando las soluciones sostenibles y alineadas con los objetivos organizacionales, para que las áreas interesadas tomen las mejores decisiones.', 34),
  ('crit-36', 'pil-analitico', 'Rendimiento', 'Análisis cuantitativo y cualitativo', 'Recolecta información precisa de las diferentes fuentes, identifica patrones y utiliza datos cuantitativos y cualitativos para comprender el problema.', 35),
  ('crit-37', 'pil-analitico', 'Rendimiento', 'Análisis de causa raíz', 'Descompone problemas complejos para identificar sus causas subyacentes utilizando las herramientas idóneas para el problema.', 36)
ON CONFLICT (id) DO NOTHING;

-- ── app_config: valores por defecto que el código ya trae hardcoded como
-- fallback en memoria (DEFAULT_DASH_SECTIONS, DIRECCION_*_DEFAULT,
-- GP_*_DEFAULT, disenoTipos) — se siembran como fila real para que se
-- puedan editar desde Configuración sin depender del fallback del cliente.
INSERT INTO app_config (id, config) VALUES
  ('dashboard', '{"sections":[
    {"id":"calendario","label":"Calendario","order":0,"visibleRoles":["admin","editor","viewer"]},
    {"id":"ventas","label":"Ventas CRM","order":1,"visibleRoles":["admin","editor"]},
    {"id":"clientes","label":"Clientes","order":2,"visibleRoles":["admin"]},
    {"id":"soporte","label":"Soporte","order":3,"visibleRoles":["admin","editor"]},
    {"id":"okrs","label":"OKRs","order":4,"visibleRoles":["admin","editor","viewer"]}
  ]}'::jsonb),
  ('facturacion_config', '{"ivaPct":16}'::jsonb),
  ('diseno_tipos', '{"tipos":["Sitio Web","Redes Sociales","Material Interno","Identidad Visual","Video","Presentación","Otro"]}'::jsonb),
  ('direccion_config', '{
    "areas":[
      {"id":"comercial","nombre":"Comercial","color":"#3B6BF5","activo":true},
      {"id":"producto","nombre":"Producto","color":"#7B2FF7","activo":true},
      {"id":"direccion","nombre":"Dirección","color":"#0F0A1E","activo":true},
      {"id":"financiero","nombre":"Financiero","color":"#10C080","activo":true},
      {"id":"rrhh","nombre":"RRHH","color":"#F5A623","activo":true}
    ],
    "tipos_bitacora":[
      {"id":"reunion","nombre":"Reunión","color":"#3B6BF5","activo":true},
      {"id":"decision","nombre":"Decisión","color":"#7B2FF7","activo":true},
      {"id":"nota","nombre":"Nota","color":"#94A0BB","activo":true},
      {"id":"acuerdo","nombre":"Acuerdo","color":"#10C080","activo":true},
      {"id":"negociacion","nombre":"Negociación","color":"#F5A623","activo":true},
      {"id":"pendiente","nombre":"Pendiente","color":"#EF4444","activo":true}
    ]
  }'::jsonb),
  ('gp_config', '{
    "areas":[
      {"id":"comercial","nombre":"Comercial","color":"#3B6BF5","activo":true},
      {"id":"soporte","nombre":"Soporte","color":"#10C080","activo":true},
      {"id":"diseno","nombre":"Diseño","color":"#7B2FF7","activo":true},
      {"id":"administrativo","nombre":"Administrativo","color":"#F5A623","activo":true},
      {"id":"general","nombre":"General","color":"#94A0BB","activo":true}
    ],
    "tipos_bitacora":[
      {"id":"reunion","nombre":"Reunión","color":"#3B6BF5","activo":true},
      {"id":"decision","nombre":"Decisión","color":"#7B2FF7","activo":true},
      {"id":"nota","nombre":"Nota","color":"#94A0BB","activo":true},
      {"id":"acuerdo","nombre":"Acuerdo","color":"#10C080","activo":true},
      {"id":"pendiente","nombre":"Pendiente","color":"#F5A623","activo":true}
    ]
  }'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- ── company_info: nombre/ciudad/descripción del cliente que se muestra en
-- el Asistente IA y en el título por defecto del organigrama. Editable desde
-- Configuración → Empresa (Admin).
INSERT INTO public.app_config (id, config) VALUES ('company_info', '{"nombre":"Umbral","ciudad":"","descripcion":"plataforma de gestión operativa","logoDataUrl":null}'::jsonb) ON CONFLICT (id) DO NOTHING;

-- ── sp_config: tipos y estados de soporte por defecto (espejo exacto de
-- spCfgDefaults() en index.html — el código NO los auto-siembra, solo los
-- usa como fallback en memoria si la tabla está vacía; sembrarlos aquí deja
-- una fila real editable desde Soporte → Configuración).
INSERT INTO sp_config (id, config_json) VALUES
  ('sp_cfg_1', '{
    "estados":[
      {"id":"e1","nombre":"Nuevo reporte","color":"#EF4444"},
      {"id":"e2","nombre":"Asignado","color":"#F59E0B"},
      {"id":"e3","nombre":"En atención","color":"#3B6BF5"},
      {"id":"e4","nombre":"Pendiente cliente","color":"#7B2FF7"},
      {"id":"e5","nombre":"Resuelto","color":"#10C080"},
      {"id":"e6","nombre":"Cerrado","color":"#6B7280"}
    ],
    "tipos":[
      {"id":"t1","nombre":"Bug / Falla","prefix":"BUG","color":"#EF4444"},
      {"id":"t2","nombre":"Demo","prefix":"DEMO","color":"#3B6BF5"},
      {"id":"t3","nombre":"Capacitación","prefix":"CAP","color":"#10C080"},
      {"id":"t4","nombre":"Mock / Prototipo","prefix":"MOCK","color":"#7B2FF7"},
      {"id":"t5","nombre":"Desarrollo puntual","prefix":"DEV","color":"#F59E0B"},
      {"id":"t6","nombre":"Soporte general","prefix":"SP","color":"#6B7280"}
    ]
  }'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- Nota: no se siembra ningún empleado, cliente, producto, ticket ni lead —
-- esos son datos reales del negocio de cada cliente, no de la plantilla.

-- ============================================
-- SECCIÓN 6: NOTIFY
-- ============================================
NOTIFY pgrst, 'reload schema';


-- ============================================================================
-- FIN de setup_v56.sql — INICIO de hb_schema_base_reconstruido.sql (13 ago 2026)
-- ============================================================================

-- ============================================================================
-- LIMEN — ESQUEMA BASE REAL, RECONSTRUIDO (13 ago 2026)
-- ============================================================================
-- Origen: information_schema.columns consultado directamente en producción
-- (pg_dump no pudo conectar por un problema de resolución DNS/IPv6 de la
-- conexión directa de Supabase desde esta red — no bloqueante, se resolvió
-- por esta vía). Refleja tipos y defaults EXACTOS de columna, tal como existen
-- hoy en Supabase. Los FK (references) están documentados según el
-- comportamiento ya confirmado de la app (cascades verificados antes vía
-- pg_constraint) — no se re-verificaron en esta pasada específica.
--
-- Estas 8 tablas nunca tuvieron un CREATE TABLE guardado en ningún archivo del
-- repo (se crearon directo en el SQL Editor en sesiones anteriores a este
-- chat) — este archivo cierra ese hueco de forma fiel a la realidad.
--
-- Va PRIMERO en el maestro consolidado — las tablas deben existir antes de que
-- limen_master_sesion_13ago.sql les agregue columnas/políticas/triggers.
-- ============================================================================

create table if not exists hb_config (
  clave text primary key,
  valor jsonb not null,
  descripcion text,
  updated_at timestamptz not null default now()
);

create table if not exists hb_proveedores (
  id text primary key default (gen_random_uuid())::text,
  nombre text not null,
  tipo_servicio text,
  moneda_default char(3) not null default 'MXN',
  tc_default numeric(12,6),
  contacto text,
  datos_pago jsonb,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists hb_crm_formularios (
  id text primary key default (gen_random_uuid())::text,
  nombre text not null,
  slug text not null unique,
  campos jsonb not null default '[]'::jsonb,
  canal_id text,
  redirect_url text,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists hb_crm_empresas (
  id text primary key,
  nombre text not null,
  nombre_normalizado text not null,
  giro text,
  created_at timestamptz not null default now()
);
create unique index if not exists hb_crm_empresas_nombre_norm_idx on hb_crm_empresas(nombre_normalizado);

create table if not exists hb_crm_prospectos (
  id text primary key default (gen_random_uuid())::text,
  nombre text not null,
  contacto_tel text,
  contacto_mail text,
  canal_entrada text,
  -- NOTA: en producción el default real de esta columna es 'prospecto', que
  -- NO es un id válido del catálogo crm_etapas. Corrección recomendada:
  --   alter table hb_crm_prospectos alter column estado set default 'nuevo';
  -- Aquí se documenta ya corregido a 'nuevo' para que un clon nuevo nazca bien.
  estado text not null default 'nuevo',
  vendedor_id text references user_profiles(user_id),
  notas text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  valor_estimado numeric(14,2),
  empresa text,
  temperatura text,
  cargo text,
  foto_url text,
  giro text,
  formulario_id text references hb_crm_formularios(id),
  motivo_perdida_id text,
  empresa_id text references hb_crm_empresas(id),
  posible_duplicado_de text references hb_crm_prospectos(id),
  duplicado_revisado boolean not null default false
);

create table if not exists hb_crm_seguimientos (
  id text primary key default (gen_random_uuid())::text,
  prospecto_id text not null references hb_crm_prospectos(id) on delete cascade,
  fecha timestamptz not null default now(),
  tipo text,
  nota text,
  proximo_paso text,
  proximo_paso_fecha date,
  usuario_id text references user_profiles(user_id),
  created_at timestamptz not null default now(),
  vendedor_id text references user_profiles(user_id)
);

create table if not exists hb_crm_documentos (
  id text primary key default (gen_random_uuid())::text,
  prospecto_id text not null references hb_crm_prospectos(id) on delete cascade,
  etapa_id text,
  nombre text,
  url text not null,
  tipo text,
  size integer,
  usuario_id text references user_profiles(user_id),
  created_at timestamptz not null default now(),
  bucket text not null default 'crm-documentos',
  vendedor_id text references user_profiles(user_id)
);

create table if not exists hb_crm_tareas (
  id text primary key,
  prospecto_id text not null references hb_crm_prospectos(id) on delete cascade,
  titulo text not null,
  descripcion text,
  fecha_vence timestamptz,
  tipo text,
  completada boolean not null default false,
  completada_en timestamptz,
  usuario_id text references user_profiles(user_id),
  vendedor_id text references user_profiles(user_id),
  created_at timestamptz not null default now()
);

-- ============================================================================
-- FIN. Reconstruido columna por columna desde information_schema.columns en
-- producción real, 13 de agosto de 2026.
-- ============================================================================


-- ============================================================================
-- FIN de hb_schema_base_reconstruido.sql — INICIO de BLOQUE FINANCIERO (17 ago 2026)
-- ============================================================================

-- ============================================================================
-- BLOQUE 3 — TABLAS FINANCIERAS (hb_clientes, hb_operaciones, hb_servicios,
-- hb_facturas_proveedor, hb_facturas_cliente, hb_pagos_proveedor,
-- hb_pagos_cliente, hb_comisiones, hb_operaciones_cambios,
-- hb_vendedores_config)
-- ============================================================================
-- Reconstruido columna por columna, con PK/FK/índices, vía
-- information_schema.columns + table_constraints + pg_indexes consultados
-- directamente en producción (17 ago 2026). Creadas y vacías en Supabase,
-- sin UI todavía — este bloque solo asegura que un clon nuevo NAZCA con
-- ellas; el módulo (pendiente #5) se construye aparte.
--
-- VA DESPUÉS de setup_v56.sql (user_profiles, app_config) y
-- hb_schema_base_reconstruido.sql (hb_proveedores, hb_crm_prospectos) —
-- ambos son dependencia de FK aquí. VA ANTES de limen_master_sesion_13ago.sql
-- (parte 1) — no hay dependencia en ese sentido, pero mantiene el bloque
-- financiero agrupado y anterior al CRM en el consolidado.
--
-- RLS: NO se habilita en este bloque. Coincide con el estado real (no
-- verificado como enabled) y con la deuda ya documentada en CLAUDE.md
-- ("Sigue permisiva ... y toda tabla financiera futura — decidir cuando se
-- construya el módulo"). No inventar policies aquí.
-- ============================================================================

-- ── 1. hb_clientes ────────────────────────────────────────────────────────
create table if not exists hb_clientes (
  id                text primary key default (gen_random_uuid())::text,
  crm_prospecto_id  text references hb_crm_prospectos(id) on delete set null,
  razon_social      text not null,
  nombre_comercial  text,
  rfc               text,
  requiere_factura  boolean not null default false,
  tipo_cuenta       text not null default 'normal',
  datos_fiscales    jsonb,
  moneda_preferida  char(3) not null default 'MXN',
  activo            boolean not null default true,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- ── 2. hb_operaciones ────────────────────────────────────────────────────
create table if not exists hb_operaciones (
  id                text primary key default (gen_random_uuid())::text,
  folio_interno     text unique,
  cliente_id        text not null references hb_clientes(id),
  vendedor_id       text references user_profiles(user_id) on delete set null,
  estado            text not null default 'cotizada',
  fecha_operacion   date not null default current_date,
  fecha_servicio    date,
  total_venta_mxn   numeric(14,2) not null default 0,
  total_costo_mxn   numeric(14,2) not null default 0,
  utilidad_mxn      numeric(14,2) not null default 0,
  notas             text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index if not exists hb_operaciones_cliente_idx on hb_operaciones(cliente_id);
create index if not exists hb_operaciones_estado_idx  on hb_operaciones(estado);
create index if not exists hb_operaciones_fecha_idx   on hb_operaciones(fecha_servicio);

-- ── 3. hb_servicios ───────────────────────────────────────────────────────
create table if not exists hb_servicios (
  id                      text primary key default (gen_random_uuid())::text,
  operacion_id            text not null references hb_operaciones(id) on delete cascade,
  proveedor_id            text references hb_proveedores(id),
  tipo_servicio           text,
  descripcion             text,
  fecha_servicio          date,
  venta_monto_original    numeric(14,2) not null default 0,
  venta_moneda_original   char(3) not null default 'MXN',
  venta_tc_aplicado       numeric(12,6) not null default 1,
  venta_mxn               numeric(14,2) not null default 0,
  costo_monto_original    numeric(14,2) not null default 0,
  costo_moneda_original   char(3) not null default 'MXN',
  costo_tc_aplicado       numeric(12,6) not null default 1,
  costo_mxn               numeric(14,2) not null default 0,
  utilidad_mxn            numeric(14,2) not null default 0,
  activo                  boolean not null default true,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);
create index if not exists hb_servicios_operacion_idx on hb_servicios(operacion_id);
create index if not exists hb_servicios_proveedor_idx on hb_servicios(proveedor_id);

-- ── 4. hb_facturas_proveedor ──────────────────────────────────────────────
create table if not exists hb_facturas_proveedor (
  id                text primary key default (gen_random_uuid())::text,
  servicio_id       text not null references hb_servicios(id) on delete cascade,
  proveedor_id      text references hb_proveedores(id),
  folio_factura     text,
  fecha_factura     date,
  monto_original    numeric(14,2) not null,
  moneda_original   char(3) not null default 'MXN',
  tc_aplicado       numeric(12,6) not null default 1,
  monto_mxn         numeric(14,2) not null,
  saldo_mxn         numeric(14,2) not null default 0,
  estado_pago       text not null default 'pendiente',
  comprobante_url   text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index if not exists hb_fp_estado_idx   on hb_facturas_proveedor(estado_pago);
create index if not exists hb_fp_servicio_idx on hb_facturas_proveedor(servicio_id);

-- ── 5. hb_facturas_cliente ────────────────────────────────────────────────
create table if not exists hb_facturas_cliente (
  id                text primary key default (gen_random_uuid())::text,
  operacion_id      text not null references hb_operaciones(id) on delete cascade,
  folio_factura     text,
  fecha_factura     date,
  monto_original    numeric(14,2) not null,
  moneda_original   char(3) not null default 'MXN',
  tc_aplicado       numeric(12,6) not null default 1,
  monto_mxn         numeric(14,2) not null,
  saldo_mxn         numeric(14,2) not null default 0,
  estado_pago       text not null default 'pendiente',
  comprobante_url   text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index if not exists hb_fc_estado_idx    on hb_facturas_cliente(estado_pago);
create index if not exists hb_fc_operacion_idx on hb_facturas_cliente(operacion_id);

-- ── 6. hb_pagos_proveedor ─────────────────────────────────────────────────
create table if not exists hb_pagos_proveedor (
  id                text primary key default (gen_random_uuid())::text,
  factura_id        text not null references hb_facturas_proveedor(id) on delete cascade,
  fecha_pago        date not null default current_date,
  monto_original    numeric(14,2) not null,
  moneda_original   char(3) not null default 'MXN',
  tc_aplicado       numeric(12,6) not null default 1,
  monto_mxn         numeric(14,2) not null,
  metodo            text,
  referencia        text,
  comprobante_url   text,
  created_at        timestamptz not null default now()
);
create index if not exists hb_pp_factura_idx on hb_pagos_proveedor(factura_id);

-- ── 7. hb_pagos_cliente ───────────────────────────────────────────────────
create table if not exists hb_pagos_cliente (
  id                text primary key default (gen_random_uuid())::text,
  factura_id        text not null references hb_facturas_cliente(id) on delete cascade,
  fecha_pago        date not null default current_date,
  monto_original    numeric(14,2) not null,
  moneda_original   char(3) not null default 'MXN',
  tc_aplicado       numeric(12,6) not null default 1,
  monto_mxn         numeric(14,2) not null,
  metodo            text,
  referencia        text,
  comprobante_url   text,
  created_at        timestamptz not null default now()
);
create index if not exists hb_pc_factura_idx on hb_pagos_cliente(factura_id);

-- ── 8. hb_comisiones ──────────────────────────────────────────────────────
create table if not exists hb_comisiones (
  id                    text primary key default (gen_random_uuid())::text,
  operacion_id          text not null unique references hb_operaciones(id) on delete cascade,
  vendedor_id           text references user_profiles(user_id) on delete set null,
  base_calculo_mxn      numeric(14,2) not null,
  base_tipo             text not null default 'utilidad',
  porcentaje_aplicado   numeric(6,3) not null,
  monto_comision_mxn    numeric(14,2) not null,
  estado                text not null default 'calculada',
  fecha                 date not null default current_date,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);
create index if not exists hb_comisiones_estado_idx   on hb_comisiones(estado);
create index if not exists hb_comisiones_vendedor_idx on hb_comisiones(vendedor_id);

-- ── 9. hb_operaciones_cambios ─────────────────────────────────────────────
create table if not exists hb_operaciones_cambios (
  id                  text primary key default (gen_random_uuid())::text,
  operacion_id        text not null references hb_operaciones(id) on delete cascade,
  servicio_id         text references hb_servicios(id) on delete set null,
  campo_modificado    text,
  valor_anterior      text,
  valor_nuevo         text,
  motivo              text not null,
  usuario_id          text references user_profiles(user_id) on delete set null,
  created_at          timestamptz not null default now()
);
create index if not exists hb_oc_operacion_idx on hb_operaciones_cambios(operacion_id);

-- ── 10. hb_vendedores_config ──────────────────────────────────────────────
create table if not exists hb_vendedores_config (
  user_id         text primary key references user_profiles(user_id) on delete cascade,
  comision_pct    numeric(6,3),
  activo          boolean not null default true,
  updated_at      timestamptz not null default now()
);

-- ============================================================================
-- FIN bloque 3. 10 tablas, orden de creación respeta dependencias de FK
-- (clientes → operaciones → servicios → facturas → pagos; comisiones y
-- cambios dependen de operaciones; vendedores_config depende solo de
-- user_profiles). Verificado 1:1 contra columnas/constraints/índices reales
-- de producción — cero columnas inventadas.
-- ============================================================================

-- ============================================================================
-- FIN de BLOQUE FINANCIERO — INICIO de limen_master_sesion_13ago.sql (13 ago 2026)
-- ============================================================================

-- ============================================================================
-- LIMEN — MAESTRO DE ESTA SESIÓN (13 ago 2026)
-- ============================================================================
-- Alcance: TODO lo que se ejecutó vía SQL Editor directamente en esta sesión de
-- chat (seguridad, RLS por vendedor, Empresas, deduplicación). Representa el
-- ESTADO FINAL, no el historial de cambios intermedios (ej. las políticas
-- "_all" permisivas que existían antes de RLS por vendedor NO aparecen aquí,
-- porque ya fueron reemplazadas).
--
-- FUERA de alcance (no tocado en esta sesión, no está aquí):
--   - setup_v56.sql (base Diamante) — sin cambios, no hubo drift ahí.
--   - limen_schema.sql, limen_crm1..7.sql, limen_capt1..2.sql — anteriores a
--     esta sesión de chat, ya existen como archivos en el repo.
--   - crm_form_config() — sin cambios en esta sesión.
--
-- Uso: Code debe fundir este archivo con los .sql existentes del repo en UN
-- solo maestro consolidado (ver prompt adjunto). Idempotente: correrlo dos
-- veces no rompe nada.
-- ============================================================================


-- ── 1. STORAGE — bucket privado de cotizaciones ──────────────────────────
drop policy if exists "crm_cotizaciones_select" on storage.objects;
create policy "crm_cotizaciones_select"
on storage.objects for select to authenticated
using (bucket_id = 'crm-cotizaciones');

drop policy if exists "crm_cotizaciones_insert" on storage.objects;
create policy "crm_cotizaciones_insert"
on storage.objects for insert to authenticated
with check (bucket_id = 'crm-cotizaciones');

drop policy if exists "crm_cotizaciones_update" on storage.objects;
create policy "crm_cotizaciones_update"
on storage.objects for update to authenticated
using (bucket_id = 'crm-cotizaciones');

drop policy if exists "crm_cotizaciones_delete" on storage.objects;
create policy "crm_cotizaciones_delete"
on storage.objects for delete to authenticated
using (bucket_id = 'crm-cotizaciones');

alter table hb_crm_documentos
  add column if not exists bucket text not null default 'crm-documentos';

comment on column hb_crm_documentos.bucket is
  'Bucket donde vive el archivo. crm-documentos = público, url guardada tal cual. crm-cotizaciones = privado, url guarda el PATH, requiere createSignedUrl al descargar.';


-- ── 2. Motivos de pérdida ─────────────────────────────────────────────────
alter table hb_crm_prospectos
  add column if not exists motivo_perdida_id text;

insert into hb_config (clave, valor) values
  ('crm_motivos_perdida', '[
    {"id":"precio","nombre":"Precio muy alto","orden":1},
    {"id":"competencia","nombre":"Eligió otra empresa","orden":2},
    {"id":"sin_respuesta","nombre":"Dejó de responder","orden":3},
    {"id":"no_calificado","nombre":"No calificaba / no era el momento","orden":4},
    {"id":"presupuesto","nombre":"Se canceló el proyecto/presupuesto","orden":5},
    {"id":"otro","nombre":"Otro","orden":6}
  ]'::jsonb)
on conflict (clave) do nothing;


-- ── 3. Helpers de rol (evitan el patrón de subquery que causó deadlock) ──
create or replace function hb_current_role()
returns text
language sql security definer stable set search_path = public
as $$ select role from user_profiles where user_id = auth.uid()::text limit 1; $$;

create or replace function hb_is_admin()
returns boolean
language sql security definer stable set search_path = public
as $$ select coalesce((select role from user_profiles where user_id = auth.uid()::text limit 1) = 'admin', false); $$;

create or replace function hb_normaliza(txt text)
returns text language sql immutable as $$ select lower(trim(coalesce(txt,''))); $$;


-- ── 4. hb_crm_tareas (tabla + vendedor_id + trigger de herencia) ─────────
create table if not exists hb_crm_tareas (
  id text primary key,
  prospecto_id text not null references hb_crm_prospectos(id) on delete cascade,
  titulo text not null,
  descripcion text,
  fecha_vence timestamptz,
  tipo text,
  completada boolean not null default false,
  completada_en timestamptz,
  usuario_id text references user_profiles(user_id),
  vendedor_id text references user_profiles(user_id),
  created_at timestamptz not null default now()
);

alter table hb_crm_tareas enable row level security;

create or replace function hb_hereda_vendedor_de_prospecto()
returns trigger language plpgsql as $$
begin
  if new.vendedor_id is null then
    select vendedor_id into new.vendedor_id from hb_crm_prospectos where id = new.prospecto_id;
  end if;
  return new;
end $$;

drop trigger if exists trg_hb_tarea_hereda_vendedor on hb_crm_tareas;
create trigger trg_hb_tarea_hereda_vendedor
before insert on hb_crm_tareas
for each row execute function hb_hereda_vendedor_de_prospecto();


-- ── 5. vendedor_id denormalizado en seguimientos y documentos ───────────
alter table hb_crm_seguimientos add column if not exists vendedor_id text references user_profiles(user_id);
alter table hb_crm_documentos add column if not exists vendedor_id text references user_profiles(user_id);

update hb_crm_seguimientos s set vendedor_id = p.vendedor_id
from hb_crm_prospectos p where s.prospecto_id = p.id and s.vendedor_id is distinct from p.vendedor_id;

update hb_crm_documentos d set vendedor_id = p.vendedor_id
from hb_crm_prospectos p where d.prospecto_id = p.id and d.vendedor_id is distinct from p.vendedor_id;

update hb_crm_tareas t set vendedor_id = p.vendedor_id
from hb_crm_prospectos p where t.prospecto_id = p.id and t.vendedor_id is distinct from p.vendedor_id;

drop trigger if exists trg_hb_seg_hereda_vendedor on hb_crm_seguimientos;
create trigger trg_hb_seg_hereda_vendedor
before insert on hb_crm_seguimientos
for each row execute function hb_hereda_vendedor_de_prospecto();

drop trigger if exists trg_hb_doc_hereda_vendedor on hb_crm_documentos;
create trigger trg_hb_doc_hereda_vendedor
before insert on hb_crm_documentos
for each row execute function hb_hereda_vendedor_de_prospecto();

-- Propagación: si el lead cambia de vendedor, se propaga a sus 3 tablas hijas
create or replace function hb_prospecto_propaga_vendedor_tareas()
returns trigger language plpgsql as $$
begin
  if new.vendedor_id is distinct from old.vendedor_id then
    update hb_crm_tareas set vendedor_id = new.vendedor_id where prospecto_id = new.id;
    update hb_crm_seguimientos set vendedor_id = new.vendedor_id where prospecto_id = new.id;
    update hb_crm_documentos set vendedor_id = new.vendedor_id where prospecto_id = new.id;
  end if;
  return new;
end $$;

drop trigger if exists trg_hb_prospecto_propaga_vendedor on hb_crm_prospectos;
create trigger trg_hb_prospecto_propaga_vendedor
after update on hb_crm_prospectos
for each row execute function hb_prospecto_propaga_vendedor_tareas();


-- ── 6. RLS por vendedor — 4 tablas núcleo, políticas granulares ──────────
drop policy if exists hb_crm_tareas_all on hb_crm_tareas;
create policy hb_crm_tareas_select on hb_crm_tareas for select to authenticated
using (hb_is_admin() or vendedor_id is null or vendedor_id = auth.uid()::text);
create policy hb_crm_tareas_insert on hb_crm_tareas for insert to authenticated with check (true);
create policy hb_crm_tareas_update on hb_crm_tareas for update to authenticated
using (hb_is_admin() or vendedor_id is null or vendedor_id = auth.uid()::text);
create policy hb_crm_tareas_delete on hb_crm_tareas for delete to authenticated
using (hb_is_admin());

drop policy if exists hb_crm_prospectos_all on hb_crm_prospectos;
create policy hb_crm_prospectos_select on hb_crm_prospectos for select to authenticated
using (hb_is_admin() or vendedor_id is null or vendedor_id = auth.uid()::text);
create policy hb_crm_prospectos_insert on hb_crm_prospectos for insert to authenticated with check (true);
create policy hb_crm_prospectos_update on hb_crm_prospectos for update to authenticated
using (hb_is_admin() or vendedor_id is null or vendedor_id = auth.uid()::text);
create policy hb_crm_prospectos_delete on hb_crm_prospectos for delete to authenticated
using (hb_is_admin());

drop policy if exists hb_crm_seguimientos_all on hb_crm_seguimientos;
create policy hb_crm_seguimientos_select on hb_crm_seguimientos for select to authenticated
using (hb_is_admin() or vendedor_id is null or vendedor_id = auth.uid()::text);
create policy hb_crm_seguimientos_insert on hb_crm_seguimientos for insert to authenticated with check (true);
create policy hb_crm_seguimientos_update on hb_crm_seguimientos for update to authenticated
using (hb_is_admin() or vendedor_id is null or vendedor_id = auth.uid()::text);
create policy hb_crm_seguimientos_delete on hb_crm_seguimientos for delete to authenticated
using (hb_is_admin() or vendedor_id is null or vendedor_id = auth.uid()::text);

drop policy if exists hb_crm_documentos_all on hb_crm_documentos;
create policy hb_crm_documentos_select on hb_crm_documentos for select to authenticated
using (hb_is_admin() or vendedor_id is null or vendedor_id = auth.uid()::text);
create policy hb_crm_documentos_insert on hb_crm_documentos for insert to authenticated with check (true);
create policy hb_crm_documentos_update on hb_crm_documentos for update to authenticated
using (hb_is_admin() or vendedor_id is null or vendedor_id = auth.uid()::text);
create policy hb_crm_documentos_delete on hb_crm_documentos for delete to authenticated
using (hb_is_admin() or vendedor_id is null or vendedor_id = auth.uid()::text);


-- ── 7. Flag "es vendedor CRM" ─────────────────────────────────────────────
alter table user_profiles add column if not exists es_vendedor_crm boolean not null default false;


-- ── 8. Entidad Empresas ───────────────────────────────────────────────────
create table if not exists hb_crm_empresas (
  id text primary key,
  nombre text not null,
  nombre_normalizado text not null,
  giro text,
  created_at timestamptz not null default now()
);
create unique index if not exists hb_crm_empresas_nombre_norm_idx on hb_crm_empresas(nombre_normalizado);

alter table hb_crm_empresas enable row level security;
do $$ begin
  if not exists (select 1 from pg_policies where tablename='hb_crm_empresas' and policyname='hb_crm_empresas_all') then
    create policy hb_crm_empresas_all on hb_crm_empresas for all to authenticated using (true) with check (true);
  end if;
end $$;

alter table hb_crm_prospectos add column if not exists empresa_id text references hb_crm_empresas(id);

insert into hb_crm_empresas (id, nombre, nombre_normalizado)
select 'emp'||substr(md5(random()::text||clock_timestamp()::text),1,12),
       min(empresa), hb_normaliza(empresa)
from hb_crm_prospectos
where empresa is not null and trim(empresa) <> ''
group by hb_normaliza(empresa)
on conflict (nombre_normalizado) do nothing;

update hb_crm_prospectos p
set empresa_id = e.id
from hb_crm_empresas e
where hb_normaliza(p.empresa) = e.nombre_normalizado
  and p.empresa_id is null and p.empresa is not null and trim(p.empresa) <> '';


-- ── 9. Deduplicación de leads ─────────────────────────────────────────────
alter table hb_crm_prospectos add column if not exists posible_duplicado_de text references hb_crm_prospectos(id);
alter table hb_crm_prospectos add column if not exists duplicado_revisado boolean not null default false;


-- ── 10. crm_captar_lead — VERSIÓN FINAL (reemplaza la de este mismo maestro)
-- SUPERSEDIDA por limen_master_sesion_13ago_parte2.sql: esta es ya la
-- versión final de parte2 (agrega captura de UTM/geo), fusionada en línea
-- aquí mismo para no dejar dos definiciones de la misma función en el
-- archivo. La versión parte2 no se repite en la sección 5 más abajo.
create or replace function public.crm_captar_lead(p_slug text, p_datos jsonb, p_honeypot text default null::text)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_form   hb_crm_formularios%rowtype;
  v_nombre text;
  v_lead_id text;
  v_tel text;
  v_mail text;
  v_empresa_raw text;
  v_empresa_id text;
  v_dup_id text;
  v_utm_source text;
  v_utm_medium text;
  v_utm_campaign text;
  v_geo_pais text;
  v_geo_ciudad text;
  v_geo_lat numeric;
  v_geo_lng numeric;
begin
  if p_honeypot is not null and length(trim(p_honeypot)) > 0 then
    return jsonb_build_object('status','ok');
  end if;

  select * into v_form from hb_crm_formularios
    where slug = p_slug and activo = true;
  if not found then
    return jsonb_build_object('status','error','msg','Formulario no disponible');
  end if;

  v_nombre := trim(coalesce(p_datos->>'nombre',''));
  if v_nombre = '' then
    return jsonb_build_object('status','error','msg','El nombre es obligatorio');
  end if;

  v_tel := nullif(trim(coalesce(p_datos->>'contacto_tel','')),'');
  v_mail := nullif(trim(coalesce(p_datos->>'contacto_mail','')),'');
  v_empresa_raw := nullif(trim(coalesce(p_datos->>'empresa','')),'');
  v_utm_source := nullif(trim(coalesce(p_datos->>'utm_source','')),'');
  v_utm_medium := nullif(trim(coalesce(p_datos->>'utm_medium','')),'');
  v_utm_campaign := nullif(trim(coalesce(p_datos->>'utm_campaign','')),'');
  v_geo_pais := nullif(trim(coalesce(p_datos->>'geo_pais','')),'');
  v_geo_ciudad := nullif(trim(coalesce(p_datos->>'geo_ciudad','')),'');
  begin v_geo_lat := (p_datos->>'geo_lat')::numeric; exception when others then v_geo_lat := null; end;
  begin v_geo_lng := (p_datos->>'geo_lng')::numeric; exception when others then v_geo_lng := null; end;

  if v_tel is not null or v_mail is not null then
    select id into v_dup_id from hb_crm_prospectos
    where (v_tel is not null and regexp_replace(contacto_tel,'\D','','g') = regexp_replace(v_tel,'\D','','g'))
       or (v_mail is not null and lower(trim(contacto_mail)) = lower(trim(v_mail)))
    limit 1;
  end if;

  if v_empresa_raw is not null then
    select id into v_empresa_id from hb_crm_empresas where nombre_normalizado = hb_normaliza(v_empresa_raw);
    if not found then
      insert into hb_crm_empresas (id, nombre, nombre_normalizado)
      values ('emp'||substr(md5(random()::text||clock_timestamp()::text),1,12), v_empresa_raw, hb_normaliza(v_empresa_raw))
      on conflict (nombre_normalizado) do nothing;
      select id into v_empresa_id from hb_crm_empresas where nombre_normalizado = hb_normaliza(v_empresa_raw);
    end if;
  end if;

  v_lead_id := 'c' || extract(epoch from now())::bigint::text || floor(random()*100000)::text;

  insert into hb_crm_prospectos
    (id, nombre, empresa, empresa_id, contacto_tel, contacto_mail, cargo, giro,
     notas, canal_entrada, formulario_id, estado, posible_duplicado_de,
     utm_source, utm_medium, utm_campaign, geo_pais, geo_ciudad, geo_lat, geo_lng,
     created_at, updated_at)
  values
    (v_lead_id, v_nombre, v_empresa_raw, v_empresa_id, v_tel, v_mail,
     nullif(trim(coalesce(p_datos->>'cargo','')),''),
     nullif(trim(coalesce(p_datos->>'giro','')),''),
     nullif(trim(coalesce(p_datos->>'mensaje','')),''),
     v_form.canal_id, v_form.id, 'nuevo', v_dup_id,
     v_utm_source, v_utm_medium, v_utm_campaign, v_geo_pais, v_geo_ciudad, v_geo_lat, v_geo_lng,
     now(), now());

  return jsonb_build_object('status','ok','redirect', v_form.redirect_url);

exception when others then
  return jsonb_build_object('status','error','msg','No se pudo procesar el formulario.');
end$function$;

-- ============================================================================
-- FIN de limen_master_sesion_13ago.sql — INICIO de
-- limen_master_sesion_13ago_parte2.sql (13 ago 2026, tramo 2)
-- ============================================================================
-- Peldaño 2 (Landings), Peldaño 3 (Visitas/UTM/geo), Peldaño 4 (Link en
-- bio), Realtime, paleta de colores. Su sección 7 (crm_captar_lead) YA fue
-- fusionada en línea más arriba, reemplazando la versión de parte1 — no se
-- repite aquí para no dejar dos definiciones de la misma función.
-- ============================================================================

-- ── 1. Landing pages (Peldaño 2) ─────────────────────────────────────────
create table if not exists hb_crm_landings (
  id text primary key,
  slug text not null unique,
  plantilla text not null default 'simple',
  nombre text not null,
  titulo text not null,
  subtitulo text,
  imagen_portada_url text,
  bloques jsonb not null default '[]'::jsonb,
  formulario_id text references hb_crm_formularios(id),
  meta_titulo text,
  meta_descripcion text,
  og_imagen_url text,
  gracias_titulo text default '¡Gracias!',
  gracias_texto text default 'Te contactaremos muy pronto.',
  precio_desde numeric(14,2),
  precio_unidad text,
  testimonio_texto text,
  testimonio_autor text,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table hb_crm_landings enable row level security;
do $$ begin
  if not exists (select 1 from pg_policies where tablename='hb_crm_landings' and policyname='hb_crm_landings_all') then
    create policy hb_crm_landings_all on hb_crm_landings for all to authenticated using (true) with check (true);
  end if;
end $$;

-- Bucket landing-images: créalo primero en Storage → New bucket (público) antes de
-- correr esto — la creación del bucket en sí no es SQL, solo sus policies lo son.
drop policy if exists "landing_images_select" on storage.objects;
create policy "landing_images_select" on storage.objects for select to public
using (bucket_id = 'landing-images');

drop policy if exists "landing_images_insert" on storage.objects;
create policy "landing_images_insert" on storage.objects for insert to authenticated
with check (bucket_id = 'landing-images');

drop policy if exists "landing_images_update" on storage.objects;
create policy "landing_images_update" on storage.objects for update to authenticated
using (bucket_id = 'landing-images');

drop policy if exists "landing_images_delete" on storage.objects;
create policy "landing_images_delete" on storage.objects for delete to authenticated
using (bucket_id = 'landing-images');


-- ── 2. Atribución y geo en prospectos (Peldaño 3) ────────────────────────
alter table hb_crm_prospectos add column if not exists utm_source text;
alter table hb_crm_prospectos add column if not exists utm_medium text;
alter table hb_crm_prospectos add column if not exists utm_campaign text;
alter table hb_crm_prospectos add column if not exists geo_pais text;
alter table hb_crm_prospectos add column if not exists geo_ciudad text;
alter table hb_crm_prospectos add column if not exists geo_lat numeric(9,6);
alter table hb_crm_prospectos add column if not exists geo_lng numeric(9,6);

-- Corrección de deuda documentada (verificar si ya se aplicó a producción;
-- es idempotente correrla de nuevo si ya estaba puesta):
alter table hb_crm_prospectos alter column estado set default 'nuevo';


-- ── 3. crm_landing_config — VERSIÓN CORREGIDA (faltaban 4 campos) ───────
create or replace function public.crm_landing_config(p_slug text)
returns jsonb
language plpgsql security definer set search_path to 'public'
as $function$
declare
  v_land hb_crm_landings%rowtype;
  v_form hb_crm_formularios%rowtype;
  v_form_json jsonb := null;
begin
  select * into v_land from hb_crm_landings where slug = p_slug and activo = true;
  if not found then return null; end if;

  if v_land.formulario_id is not null then
    select * into v_form from hb_crm_formularios where id = v_land.formulario_id and activo = true;
    if found then
      v_form_json := jsonb_build_object('slug', v_form.slug, 'campos', v_form.campos, 'redirect_url', v_form.redirect_url);
    end if;
  end if;

  return jsonb_build_object(
    'titulo', v_land.titulo,
    'subtitulo', v_land.subtitulo,
    'plantilla', v_land.plantilla,
    'imagen_portada_url', v_land.imagen_portada_url,
    'bloques', v_land.bloques,
    'meta_titulo', v_land.meta_titulo,
    'meta_descripcion', v_land.meta_descripcion,
    'og_imagen_url', v_land.og_imagen_url,
    'gracias_titulo', v_land.gracias_titulo,
    'gracias_texto', v_land.gracias_texto,
    'precio_desde', v_land.precio_desde,
    'precio_unidad', v_land.precio_unidad,
    'testimonio_texto', v_land.testimonio_texto,
    'testimonio_autor', v_land.testimonio_autor,
    'formulario', v_form_json
  );
end$function$;


-- ── 4. hb_crm_visitas (Peldaño 3) ─────────────────────────────────────────
create table if not exists hb_crm_visitas (
  id text primary key default (gen_random_uuid())::text,
  tipo text not null,
  referencia text not null,
  utm_source text,
  utm_medium text,
  utm_campaign text,
  geo_pais text,
  geo_ciudad text,
  geo_lat numeric(9,6),
  geo_lng numeric(9,6),
  created_at timestamptz not null default now()
);

alter table hb_crm_visitas enable row level security;
do $$ begin
  if not exists (select 1 from pg_policies where tablename='hb_crm_visitas' and policyname='hb_crm_visitas_select') then
    create policy hb_crm_visitas_select on hb_crm_visitas for select to authenticated using (true);
  end if;
end $$;
-- Sin policy de insert a propósito: solo se escribe vía crm_registrar_visita.


-- ── 5. hb_crm_linkbio (Peldaño 4) ─────────────────────────────────────────
create table if not exists hb_crm_linkbio (
  id text primary key default (gen_random_uuid())::text,
  nombre text not null,
  slug text not null unique,
  titulo text not null,
  bio_texto text,
  avatar_url text,
  enlaces jsonb not null default '[]'::jsonb,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table hb_crm_linkbio enable row level security;
do $$ begin
  if not exists (select 1 from pg_policies where tablename='hb_crm_linkbio' and policyname='hb_crm_linkbio_all') then
    create policy hb_crm_linkbio_all on hb_crm_linkbio for all to authenticated using (true) with check (true);
  end if;
end $$;

create or replace function public.crm_linkbio_config(p_slug text)
returns jsonb
language plpgsql security definer set search_path to 'public'
as $function$
declare v_lb hb_crm_linkbio%rowtype;
begin
  select * into v_lb from hb_crm_linkbio where slug = p_slug and activo = true;
  if not found then return null; end if;
  return jsonb_build_object('titulo', v_lb.titulo, 'bio_texto', v_lb.bio_texto,
    'avatar_url', v_lb.avatar_url, 'enlaces', v_lb.enlaces);
end$function$;


-- ── 6. crm_registrar_visita — VERSIÓN FINAL (geo + 3 tipos) ──────────────
create or replace function public.crm_registrar_visita(
  p_tipo text, p_referencia text,
  p_utm_source text default null, p_utm_medium text default null, p_utm_campaign text default null,
  p_geo_pais text default null, p_geo_ciudad text default null,
  p_geo_lat numeric default null, p_geo_lng numeric default null
) returns void
language plpgsql security definer set search_path to 'public'
as $function$
begin
  if p_tipo not in ('form','landing','linkbio') then return; end if;
  insert into hb_crm_visitas (tipo, referencia, utm_source, utm_medium, utm_campaign,
    geo_pais, geo_ciudad, geo_lat, geo_lng)
  values (p_tipo, p_referencia,
    nullif(trim(coalesce(p_utm_source,'')),''),
    nullif(trim(coalesce(p_utm_medium,'')),''),
    nullif(trim(coalesce(p_utm_campaign,'')),''),
    nullif(trim(coalesce(p_geo_pais,'')),''),
    nullif(trim(coalesce(p_geo_ciudad,'')),''),
    p_geo_lat, p_geo_lng);
exception when others then
  return;
end$function$;

revoke all on function public.crm_registrar_visita from public;
grant execute on function public.crm_registrar_visita to anon, authenticated;


-- ── 8. Realtime en Prospectos ─────────────────────────────────────────────
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='hb_crm_prospectos'
  ) then
    alter publication supabase_realtime add table hb_crm_prospectos;
  end if;
end $$;


-- ── 9. app_config: filas semilla que faltaban en el primer maestro ──────
insert into app_config (id, config) values (
  'instance_profile', '{"modules_disabled":[]}'::jsonb
) on conflict (id) do nothing;

insert into app_config (id, config) values (
  'paleta_colores',
  '{"paletteId":"morado","accentColor":"#7B2FF7","accentColorMid":"#9B5FF8","accentColorDark":"#6020D0","accentGradientEnd":"#C83CB4","sidebarBg":"#0F0A1E"}'::jsonb
) on conflict (id) do nothing;

-- ============================================================================
-- FIN de limen_master_sesion_13ago_parte2.sql — INICIO de
-- limen_master_sesion_14ago_parte3.sql (14 ago 2026)
-- ============================================================================
-- Drift de esquema de Gestión de Proyectos: 6 columnas, ninguna había
-- quedado en ningún archivo hasta ahora. Idempotente, seguro de correr de
-- nuevo. gp_proyectos y gp_tareas ya existen (creadas por setup_v56.sql).
-- ============================================================================

-- Omisiones del clon (ya existían en direccion_proyectos/direccion_tareas,
-- GP las había perdido al clonarse):
alter table gp_proyectos add column if not exists visible_roadmap boolean default true;
alter table gp_tareas add column if not exists hito_id text;

-- Capacidad genuina y nueva SOLO de GP, sin equivalente en Dirección:
alter table gp_proyectos add column if not exists fecha_cierre timestamptz;
alter table gp_proyectos add column if not exists tipo_tarea text;
alter table gp_tareas add column if not exists tipo_tarea text;
alter table gp_tareas add column if not exists asignados jsonb default '[]'::jsonb;

-- ============================================================================
-- FIN. Consolidado fundido completo: setup_v56 + hb_schema_base_reconstruido
-- + bloque financiero + limen_master_sesion_13ago (parte1) +
-- limen_master_sesion_13ago_parte2 + limen_master_sesion_14ago_parte3.
-- Regenerado 17 ago 2026.
-- ============================================================================
