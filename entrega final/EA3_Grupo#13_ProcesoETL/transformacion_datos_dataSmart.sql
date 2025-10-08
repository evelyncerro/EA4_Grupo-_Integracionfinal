/* 1) Crear el Data Mart */
IF DB_ID('jardineria_dm') IS NULL
BEGIN
    PRINT 'Creando BD jardineria_dm...';
    CREATE DATABASE jardineria_dm;
END
GO
USE jardineria_dm;
GO

/* 2) Verifica que estás en la BD correcta */
SELECT DB_NAME() AS base_actual;
GO

/* 3) Crea el esquema dm */
IF SCHEMA_ID('dm') IS NULL
    EXEC ('CREATE SCHEMA dm AUTHORIZATION dbo');
GO

/* 4) Crea una tabla mínima para validar */
IF OBJECT_ID('dm.dim_fecha','U') IS NULL
BEGIN
    CREATE TABLE dm.dim_fecha(
        fecha_sk INT IDENTITY(1,1) PRIMARY KEY,
        fecha DATE NOT NULL UNIQUE,
        anio INT, trimestre INT, mes INT, nombre_mes NVARCHAR(15),
        dia INT, dia_semana INT, nombre_dia NVARCHAR(15),
        es_festivo BIT DEFAULT 0
    );
END
GO

/* 5) Confirma que existen el esquema y la tabla */
SELECT name AS esquema FROM sys.schemas WHERE name='dm';
SELECT name AS tabla FROM sys.tables WHERE schema_id = SCHEMA_ID('dm');

/* 6) Si ves filas arriba, ya quedó. Ahora crea el resto del modelo: */

/* DIM_OFICINA */
IF OBJECT_ID('dm.dim_oficina', 'U') IS NULL
BEGIN
    CREATE TABLE dm.dim_oficina (
        oficina_sk INT IDENTITY(1,1) PRIMARY KEY,
        oficina_nk INT NOT NULL,
        descripcion NVARCHAR(100), ciudad NVARCHAR(100), region NVARCHAR(100),
        pais NVARCHAR(100), codigo_postal NVARCHAR(20), telefono NVARCHAR(50)
    );
    CREATE UNIQUE INDEX UX_dim_oficina_nk ON dm.dim_oficina(oficina_nk);
END
GO

/* DIM_EMPLEADO */
IF OBJECT_ID('dm.dim_empleado', 'U') IS NULL
BEGIN
    CREATE TABLE dm.dim_empleado (
        empleado_sk INT IDENTITY(1,1) PRIMARY KEY,
        empleado_nk INT NOT NULL,
        nombre NVARCHAR(60), apellido1 NVARCHAR(60), apellido2 NVARCHAR(60),
        email NVARCHAR(120), extension NVARCHAR(20), puesto NVARCHAR(100),
        id_jefe_nk INT, oficina_sk INT REFERENCES dm.dim_oficina(oficina_sk)
    );
    CREATE UNIQUE INDEX UX_dim_empleado_nk ON dm.dim_empleado(empleado_nk);
END
GO


/* DIM_CLIENTE */
IF OBJECT_ID('dm.dim_cliente', 'U') IS NULL
BEGIN
    CREATE TABLE dm.dim_cliente (
        cliente_sk INT IDENTITY(1,1) PRIMARY KEY,
        cliente_nk INT NOT NULL,
        nombre_cliente NVARCHAR(120), nombre_contacto NVARCHAR(120),
        apellido_contacto NVARCHAR(120), telefono NVARCHAR(50), fax NVARCHAR(50),
        ciudad NVARCHAR(100), region NVARCHAR(100), pais NVARCHAR(100), codigo_postal NVARCHAR(20),
        limite_credito DECIMAL(18,2), empleado_sk INT REFERENCES dm.dim_empleado(empleado_sk)
    );
    CREATE UNIQUE INDEX UX_dim_cliente_nk ON dm.dim_cliente(cliente_nk);
END
GO

/* DIM_PRODUCTO */
IF OBJECT_ID('dm.dim_producto', 'U') IS NULL
BEGIN
    CREATE TABLE dm.dim_producto (
        producto_sk INT IDENTITY(1,1) PRIMARY KEY,
        producto_nk INT NOT NULL,
        nombre NVARCHAR(160), categoria NVARCHAR(100),
        proveedor NVARCHAR(160), descripcion NVARCHAR(400), precio_venta DECIMAL(18,2)
    );
    CREATE UNIQUE INDEX UX_dim_producto_nk ON dm.dim_producto(producto_nk);
END
GO

/* DIM_PEDIDO */
IF OBJECT_ID('dm.dim_pedido', 'U') IS NULL
BEGIN
    CREATE TABLE dm.dim_pedido (
        pedido_sk INT IDENTITY(1,1) PRIMARY KEY,
        pedido_nk INT NOT NULL, estado NVARCHAR(30),
        fecha_pedido_sk INT REFERENCES dm.dim_fecha(fecha_sk),
        fecha_esperada_sk INT REFERENCES dm.dim_fecha(fecha_sk),
        fecha_entrega_sk INT REFERENCES dm.dim_fecha(fecha_sk)
    );
    CREATE UNIQUE INDEX UX_dim_pedido_nk ON dm.dim_pedido(pedido_nk);
END
GO

/* FACT_VENTA */
IF OBJECT_ID('dm.fact_venta', 'U') IS NULL
BEGIN
    CREATE TABLE dm.fact_venta (
        fact_venta_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_sk INT NOT NULL REFERENCES dm.dim_fecha(fecha_sk),
        cliente_sk INT NOT NULL REFERENCES dm.dim_cliente(cliente_sk),
        producto_sk INT NOT NULL REFERENCES dm.dim_producto(producto_sk),
        empleado_sk INT NULL REFERENCES dm.dim_empleado(empleado_sk),
        oficina_sk INT NULL REFERENCES dm.dim_oficina(oficina_sk),
        pedido_sk INT NOT NULL REFERENCES dm.dim_pedido(pedido_sk),
        numero_linea INT NOT NULL,
        cantidad INT NOT NULL,
        precio_unitario DECIMAL(18,2) NOT NULL,
        total_linea AS (CAST(cantidad * precio_unitario AS DECIMAL(18,2))) PERSISTED
    );
END
GO

/* Confirmación final: debe listar 6 tablas + 1 hecho */
SELECT s.name AS esquema, t.name AS tabla
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name='dm'
ORDER BY tabla;



--------------------


USE jardineria_dm;
GO
IF SCHEMA_ID('stg') IS NULL EXEC('CREATE SCHEMA stg');
GO

-- Borrar si existen (forma correcta para sinónimos)
IF EXISTS (SELECT 1 FROM sys.synonyms WHERE name='oficina'        AND schema_id=SCHEMA_ID('stg')) DROP SYNONYM stg.oficina;
IF EXISTS (SELECT 1 FROM sys.synonyms WHERE name='empleado'       AND schema_id=SCHEMA_ID('stg')) DROP SYNONYM stg.empleado;
IF EXISTS (SELECT 1 FROM sys.synonyms WHERE name='cliente'        AND schema_id=SCHEMA_ID('stg')) DROP SYNONYM stg.cliente;
IF EXISTS (SELECT 1 FROM sys.synonyms WHERE name='pedido'         AND schema_id=SCHEMA_ID('stg')) DROP SYNONYM stg.pedido;
IF EXISTS (SELECT 1 FROM sys.synonyms WHERE name='producto'       AND schema_id=SCHEMA_ID('stg')) DROP SYNONYM stg.producto;
IF EXISTS (SELECT 1 FROM sys.synonyms WHERE name='detalle_pedido' AND schema_id=SCHEMA_ID('stg')) DROP SYNONYM stg.detalle_pedido;
GO

-- Crear apuntando a TU staging real (con sufijo _stg)
CREATE SYNONYM stg.oficina        FOR jardineria_stg.dbo.oficina_stg;
CREATE SYNONYM stg.empleado       FOR jardineria_stg.dbo.empleado_stg;
CREATE SYNONYM stg.cliente        FOR jardineria_stg.dbo.cliente_stg;
CREATE SYNONYM stg.pedido         FOR jardineria_stg.dbo.pedido_stg;
CREATE SYNONYM stg.producto       FOR jardineria_stg.dbo.producto_stg;
CREATE SYNONYM stg.detalle_pedido FOR jardineria_stg.dbo.detalle_pedido_stg;
GO

-- Verifica
SELECT s.name AS esquema, sn.name AS sinonimo, sn.base_object_name
FROM sys.synonyms sn
JOIN sys.schemas s ON s.schema_id = sn.schema_id
WHERE s.name='stg';

---------------------

USE jardineria_dm;
GO
DECLARE @desde DATE = (SELECT MIN(fecha_pedido)  FROM stg.pedido);
DECLARE @hasta DATE = (SELECT MAX(fecha_entrega) FROM stg.pedido);

;WITH d AS (
  SELECT @desde AS fecha
  UNION ALL
  SELECT DATEADD(DAY,1,fecha) FROM d WHERE fecha < @hasta
)
INSERT INTO dm.dim_fecha(fecha, anio, trimestre, mes, nombre_mes, dia, dia_semana, nombre_dia, es_festivo)
SELECT fecha,
       YEAR(fecha),
       DATEPART(QUARTER, fecha),
       MONTH(fecha),
       DATENAME(MONTH, fecha),
       DAY(fecha),
       DATEPART(WEEKDAY, fecha),
       DATENAME(WEEKDAY, fecha),
       0
FROM d
WHERE fecha IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM dm.dim_fecha t WHERE t.fecha = d.fecha)
OPTION (MAXRECURSION 0);

----------------------

MERGE dm.dim_oficina AS T
USING (
  SELECT
    ID_oficina   AS oficina_nk,
    Descripcion  AS descripcion,
    ciudad, region, pais, codigo_postal, telefono
  FROM stg.oficina
) AS S
ON (T.oficina_nk = S.oficina_nk)
WHEN MATCHED THEN
  UPDATE SET descripcion=S.descripcion, ciudad=S.ciudad, region=S.region,
             pais=S.pais, codigo_postal=S.codigo_postal, telefono=S.telefono
WHEN NOT MATCHED THEN
  INSERT (oficina_nk, descripcion, ciudad, region, pais, codigo_postal, telefono)
  VALUES (S.oficina_nk, S.descripcion, S.ciudad, S.region, S.pais, S.codigo_postal, S.telefono);

  -----------------------

  MERGE dm.dim_empleado AS T
USING (
  SELECT
    e.ID_empleado AS empleado_nk,
    e.nombre, e.apellido1, e.apellido2, e.email, e.extension, e.puesto,
    e.ID_jefe     AS id_jefe_nk,
    o.oficina_sk
  FROM stg.empleado e
  LEFT JOIN dm.dim_oficina o ON o.oficina_nk = e.ID_oficina
) AS S
ON (T.empleado_nk = S.empleado_nk)
WHEN MATCHED THEN
  UPDATE SET nombre=S.nombre, apellido1=S.apellido1, apellido2=S.apellido2,
             email=S.email, extension=S.extension, puesto=S.puesto,
             id_jefe_nk=S.id_jefe_nk, oficina_sk=S.oficina_sk
WHEN NOT MATCHED THEN
  INSERT (empleado_nk, nombre, apellido1, apellido2, email, extension, puesto, id_jefe_nk, oficina_sk)
  VALUES (S.empleado_nk, S.nombre, S.apellido1, S.apellido2, S.email, S.extension, S.puesto, S.id_jefe_nk, S.oficina_sk);

----------------------------------

MERGE dm.dim_pedido AS T
USING (
  SELECT
    p.ID_pedido AS pedido_nk,
    p.estado,
    df_ped.fecha_sk    AS fecha_pedido_sk,
    df_esp.fecha_sk    AS fecha_esperada_sk,
    df_ent.fecha_sk    AS fecha_entrega_sk
  FROM stg.pedido p
  LEFT JOIN dm.dim_fecha df_ped ON df_ped.fecha = p.fecha_pedido
  LEFT JOIN dm.dim_fecha df_esp ON df_esp.fecha = p.fecha_esperada
  LEFT JOIN dm.dim_fecha df_ent ON df_ent.fecha = p.fecha_entrega
) AS S
ON (T.pedido_nk = S.pedido_nk)
WHEN MATCHED THEN
  UPDATE SET estado=S.estado, fecha_pedido_sk=S.fecha_pedido_sk,
             fecha_esperada_sk=S.fecha_esperada_sk, fecha_entrega_sk=S.fecha_entrega_sk
WHEN NOT MATCHED THEN
  INSERT (pedido_nk, estado, fecha_pedido_sk, fecha_esperada_sk, fecha_entrega_sk)
  VALUES (S.pedido_nk, S.estado, S.fecha_pedido_sk, S.fecha_esperada_sk, S.fecha_entrega_sk);

  ------------------------------
  INSERT INTO dm.fact_venta
(fecha_sk, cliente_sk, producto_sk, empleado_sk, oficina_sk, pedido_sk,
 numero_linea, cantidad, precio_unitario)
SELECT
  df.fecha_sk,
  dcli.cliente_sk,
  dprod.producto_sk,
  demp.empleado_sk,
  dofi.oficina_sk,
  dped.pedido_sk,
  dp.numero_linea,
  dp.cantidad,
  dp.precio_unidad
FROM stg.detalle_pedido dp
JOIN stg.pedido p            ON p.ID_pedido     = dp.ID_pedido
JOIN dm.dim_pedido dped      ON dped.pedido_nk  = p.ID_pedido
JOIN dm.dim_fecha  df        ON df.fecha        = p.fecha_pedido
JOIN dm.dim_cliente dcli     ON dcli.cliente_nk = p.ID_cliente
LEFT JOIN dm.dim_empleado demp ON demp.empleado_sk = dcli.empleado_sk
LEFT JOIN dm.dim_oficina  dofi  ON dofi.oficina_sk  = demp.oficina_sk
JOIN dm.dim_producto dprod   ON dprod.producto_nk = dp.ID_producto;

-----------------------------

-- Conteo staging vs hechos
SELECT (SELECT COUNT(*) FROM stg.detalle_pedido) AS detalle_stg,
       (SELECT COUNT(*) FROM dm.fact_venta)      AS fact_venta_dm;

-- Claves nulas (debe ser 0)
SELECT COUNT(*) AS fks_nulas
FROM dm.fact_venta
WHERE fecha_sk IS NULL OR cliente_sk IS NULL OR producto_sk IS NULL OR pedido_sk IS NULL;

-- Top productos
SELECT TOP 10 * FROM dm.vw_producto_top;

-------------------------------------

-- Conteo
SELECT (SELECT COUNT(*) FROM jardineria_stg.dbo.detalle_pedido_stg) AS detalle_stg,
       (SELECT COUNT(*) FROM dm.fact_venta)                         AS fact_venta_dm;

-- Claves nulas (debe dar 0)
SELECT COUNT(*) AS fks_nulas
FROM dm.fact_venta
WHERE fecha_sk IS NULL OR cliente_sk IS NULL OR producto_sk IS NULL OR pedido_sk IS NULL;

-- Vista
IF OBJECT_ID('dm.vw_producto_top','V') IS NULL
EXEC('CREATE VIEW dm.vw_producto_top AS
      SELECT TOP 10 p.nombre, p.categoria,
             SUM(f.cantidad) AS unidades, SUM(f.total_linea) AS ventas
      FROM dm.fact_venta f
      JOIN dm.dim_producto p ON p.producto_sk=f.producto_sk
      GROUP BY p.nombre, p.categoria
      ORDER BY unidades DESC, ventas DESC;');

SELECT TOP 10 * FROM dm.vw_producto_top;