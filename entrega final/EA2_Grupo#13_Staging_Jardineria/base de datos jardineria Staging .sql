-- crea la base de datos Staging 
IF DB_ID('jardineria_stg') IS NULL
BEGIN
    EXEC('CREATE DATABASE jardineria_stg');
END
GO

--crear las tablas
-- oficina
CREATE TABLE dbo.oficina_stg(
  ID_oficina       INT            NOT NULL,
  Descripcion      VARCHAR(10)    NOT NULL,
  ciudad           VARCHAR(30)    NOT NULL,
  pais             VARCHAR(50)    NOT NULL,
  region           VARCHAR(50)    NULL,
  codigo_postal    VARCHAR(10)    NOT NULL,
  telefono         VARCHAR(20)    NOT NULL,
  linea_direccion1 VARCHAR(50)    NOT NULL,
  linea_direccion2 VARCHAR(50)    NULL,
  ETL_LoadDate     DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
  ETL_Source       VARCHAR(50)    NOT NULL DEFAULT 'jardineria'
  CONSTRAINT PK_oficina_stg PRIMARY KEY (ID_oficina)
);

-- empleado
CREATE TABLE dbo.empleado_stg(
  ID_empleado   INT          NOT NULL,
  nombre        VARCHAR(50)  NOT NULL,
  apellido1     VARCHAR(50)  NOT NULL,
  apellido2     VARCHAR(50)  NULL,
  extension     VARCHAR(10)  NOT NULL,
  email         VARCHAR(100) NOT NULL,
  ID_oficina    INT          NOT NULL,
  ID_jefe       INT          NULL,
  puesto        VARCHAR(50)  NULL,
  ETL_LoadDate  DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  ETL_Source    VARCHAR(50)  NOT NULL DEFAULT 'jardineria',
  CONSTRAINT PK_empleado_stg PRIMARY KEY (ID_empleado)
);

-- Categoria_producto
CREATE TABLE dbo.Categoria_producto_stg(
  Id_Categoria      INT           NOT NULL,
  Desc_Categoria    VARCHAR(50)   NOT NULL,
  descripcion_texto TEXT          NULL,
  descripcion_html  TEXT          NULL,
  imagen            VARCHAR(256)  NULL,
  ETL_LoadDate      DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
  ETL_Source        VARCHAR(50)   NOT NULL DEFAULT 'jardineria',
  CONSTRAINT PK_Categoria_producto_stg PRIMARY KEY (Id_Categoria)
);

-- cliente
CREATE TABLE dbo.cliente_stg(
  ID_cliente                INT           NOT NULL,
  nombre_cliente            VARCHAR(50)   NOT NULL,
  nombre_contacto           VARCHAR(30)   NULL,
  apellido_contacto         VARCHAR(30)   NULL,
  telefono                  VARCHAR(15)   NOT NULL,
  fax                       VARCHAR(15)   NOT NULL,
  linea_direccion1          VARCHAR(50)   NOT NULL,
  linea_direccion2          VARCHAR(50)   NULL,
  ciudad                    VARCHAR(50)   NOT NULL,
  region                    VARCHAR(50)   NULL,
  pais                      VARCHAR(50)   NULL,
  codigo_postal             VARCHAR(10)   NULL,
  ID_empleado_rep_ventas    INT           NULL,
  limite_credito            NUMERIC(15,2) NULL,
  ETL_LoadDate              DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
  ETL_Source                VARCHAR(50)   NOT NULL DEFAULT 'jardineria',
  CONSTRAINT PK_cliente_stg PRIMARY KEY (ID_cliente)
);

-- pedido
CREATE TABLE dbo.pedido_stg(
  ID_pedido     INT           NOT NULL,
  fecha_pedido  DATE          NOT NULL,
  fecha_esperada DATE         NOT NULL,
  fecha_entrega DATE          NULL,
  estado        VARCHAR(15)   NOT NULL,
  comentarios   TEXT          NULL,
  ID_cliente    INT           NOT NULL,
  ETL_LoadDate  DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
  ETL_Source    VARCHAR(50)   NOT NULL DEFAULT 'jardineria',
  CONSTRAINT PK_pedido_stg PRIMARY KEY (ID_pedido)
);

-- producto
CREATE TABLE dbo.producto_stg(
  ID_producto      VARCHAR(15)   NOT NULL,
  nombre           VARCHAR(70)   NOT NULL,
  Categoria        INT           NOT NULL,
  dimensiones      VARCHAR(25)   NULL,
  proveedor        VARCHAR(50)   NULL,
  descripcion      TEXT          NULL,
  cantidad_en_stock SMALLINT     NOT NULL,
  precio_venta     NUMERIC(15,2) NOT NULL,
  precio_proveedor NUMERIC(15,2) NULL,
  ETL_LoadDate     DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
  ETL_Source       VARCHAR(50)   NOT NULL DEFAULT 'jardineria',
  CONSTRAINT PK_producto_stg PRIMARY KEY (ID_producto)
);

-- detalle_pedido
CREATE TABLE dbo.detalle_pedido_stg(
  ID_pedido     INT            NOT NULL,
  ID_producto   VARCHAR(15)    NOT NULL,
  cantidad      INT            NOT NULL,
  precio_unidad NUMERIC(15,2)  NOT NULL,
  numero_linea  SMALLINT       NOT NULL,
  ETL_LoadDate  DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
  ETL_Source    VARCHAR(50)    NOT NULL DEFAULT 'jardineria',
  CONSTRAINT PK_detalle_pedido_stg PRIMARY KEY (ID_pedido, ID_producto)
);

-- pago
CREATE TABLE dbo.pago_stg(
  ID_cliente   INT            NOT NULL,
  forma_pago   VARCHAR(40)    NOT NULL,
  id_transaccion VARCHAR(50)  NOT NULL,
  fecha_pago   DATE           NOT NULL,
  total        NUMERIC(15,2)  NOT NULL,
  ETL_LoadDate DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
  ETL_Source   VARCHAR(50)    NOT NULL DEFAULT 'jardineria',
  CONSTRAINT PK_pago_stg PRIMARY KEY (ID_cliente, id_transaccion)
);

-- FOREIGN KEYS
ALTER TABLE [dbo].[empleado_stg]
  ADD CONSTRAINT FK_empleado_oficina_stg
      FOREIGN KEY (ID_oficina) REFERENCES dbo.oficina_stg(ID_oficina);

ALTER TABLE dbo.empleado_stg
  ADD CONSTRAINT FK_empleado_jefe_stg
      FOREIGN KEY (ID_jefe) REFERENCES dbo.empleado_stg(ID_empleado);

ALTER TABLE dbo.cliente_stg
  ADD CONSTRAINT FK_cliente_repventas_stg
      FOREIGN KEY (ID_empleado_rep_ventas) REFERENCES dbo.empleado_stg(ID_empleado);

ALTER TABLE dbo.pedido_stg
  ADD CONSTRAINT FK_pedido_cliente_stg
      FOREIGN KEY (ID_cliente) REFERENCES dbo.cliente_stg(ID_cliente);

ALTER TABLE dbo.producto_stg
  ADD CONSTRAINT FK_producto_categoria_stg
      FOREIGN KEY (Categoria) REFERENCES dbo.Categoria_producto_stg(Id_Categoria);

ALTER TABLE dbo.detalle_pedido_stg
  ADD CONSTRAINT FK_detalle_pedido_pedido_stg
      FOREIGN KEY (ID_pedido) REFERENCES dbo.pedido_stg(ID_pedido);

ALTER TABLE dbo.detalle_pedido_stg
  ADD CONSTRAINT FK_detalle_pedido_producto_stg
      FOREIGN KEY (ID_producto) REFERENCES dbo.producto_stg(ID_producto);

ALTER TABLE dbo.pago_stg
  ADD CONSTRAINT FK_pago_cliente_stg
      FOREIGN KEY (ID_cliente) REFERENCES dbo.cliente_stg(ID_cliente);

-- almacenar los datos de una tabla a otra

INSERT INTO dbo.oficina_stg (ID_oficina, Descripcion, ciudad, pais, region, codigo_postal, telefono, linea_direccion1, linea_direccion2)
SELECT ID_oficina, Descripcion, ciudad, pais, region, codigo_postal, telefono, linea_direccion1, linea_direccion2
FROM jardineria.dbo.oficina;

INSERT INTO dbo.Categoria_producto_stg (Id_Categoria, Desc_Categoria, descripcion_texto, descripcion_html, imagen)
SELECT Id_Categoria, Desc_Categoria, descripcion_texto, descripcion_html, imagen
FROM jardineria.dbo.Categoria_producto;

-- desactivamos TEMPORALMENTE la self-FK del jefe
ALTER TABLE dbo.empleado_stg NOCHECK CONSTRAINT FK_empleado_jefe_stg;

INSERT INTO dbo.empleado_stg (ID_empleado, nombre, apellido1, apellido2, extension, email, ID_oficina, ID_jefe, puesto)
SELECT e.ID_empleado, e.nombre, e.apellido1, e.apellido2, e.extension, e.email, e.ID_oficina, e.ID_jefe, e.puesto
FROM jardineria.dbo.empleado e
WHERE EXISTS (SELECT 1 FROM dbo.oficina_stg o WHERE o.ID_oficina = e.ID_oficina);

ALTER TABLE dbo.empleado_stg WITH CHECK CHECK CONSTRAINT FK_empleado_jefe_stg;

INSERT INTO dbo.cliente_stg (ID_cliente, nombre_cliente, nombre_contacto, apellido_contacto, telefono, fax, linea_direccion1, linea_direccion2,
                             ciudad, region, pais, codigo_postal, ID_empleado_rep_ventas, limite_credito)
SELECT c.ID_cliente, c.nombre_cliente, c.nombre_contacto, c.apellido_contacto, c.telefono, c.fax, c.linea_direccion1, c.linea_direccion2,
       c.ciudad, c.region, c.pais, c.codigo_postal, c.ID_empleado_rep_ventas, c.limite_credito
FROM jardineria.dbo.cliente c
WHERE c.ID_empleado_rep_ventas IS NULL
   OR EXISTS (SELECT 1 FROM dbo.empleado_stg e WHERE e.ID_empleado = c.ID_empleado_rep_ventas);

INSERT INTO dbo.pedido_stg (ID_pedido, fecha_pedido, fecha_esperada, fecha_entrega, estado, comentarios, ID_cliente)
SELECT p.ID_pedido, p.fecha_pedido, p.fecha_esperada, p.fecha_entrega, p.estado, p.comentarios, p.ID_cliente
FROM jardineria.dbo.pedido p
WHERE EXISTS (SELECT 1 FROM dbo.cliente_stg c WHERE c.ID_cliente = p.ID_cliente);

INSERT INTO dbo.producto_stg (ID_producto, nombre, Categoria, dimensiones, proveedor, descripcion, cantidad_en_stock, precio_venta, precio_proveedor)
SELECT pr.ID_producto, pr.nombre, pr.Categoria, pr.dimensiones, pr.proveedor, pr.descripcion, pr.cantidad_en_stock, pr.precio_venta, pr.precio_proveedor
FROM jardineria.dbo.producto pr
WHERE EXISTS (SELECT 1 FROM dbo.Categoria_producto_stg cp WHERE cp.Id_Categoria = pr.Categoria);

INSERT INTO dbo.detalle_pedido_stg (ID_pedido, ID_producto, cantidad, precio_unidad, numero_linea)
SELECT dp.ID_pedido, dp.ID_producto, dp.cantidad, dp.precio_unidad, dp.numero_linea
FROM jardineria.dbo.detalle_pedido dp
WHERE EXISTS (SELECT 1 FROM dbo.pedido_stg  p  WHERE p.ID_pedido  = dp.ID_pedido)
  AND EXISTS (SELECT 1 FROM dbo.producto_stg pr WHERE pr.ID_producto = dp.ID_producto);

INSERT INTO dbo.pago_stg (ID_cliente, forma_pago, id_transaccion, fecha_pago, total)
SELECT pa.ID_cliente, pa.forma_pago, pa.id_transaccion, pa.fecha_pago, pa.total
FROM jardineria.dbo.pago pa
WHERE EXISTS (SELECT 1 FROM dbo.cliente_stg c WHERE c.ID_cliente = pa.ID_cliente);

-- validamos la data
SELECT 'oficina'         AS tabla, (SELECT COUNT(*) FROM jardineria.dbo.oficina),         (SELECT COUNT(*) FROM jardineria_stg.dbo.oficina_stg)
UNION ALL SELECT 'empleado',       (SELECT COUNT(*) FROM jardineria.dbo.empleado),        (SELECT COUNT(*) FROM jardineria_stg.dbo.empleado_stg)
UNION ALL SELECT 'Categoria_prod', (SELECT COUNT(*) FROM jardineria.dbo.Categoria_producto), (SELECT COUNT(*) FROM jardineria_stg.dbo.Categoria_producto_stg)
UNION ALL SELECT 'cliente',        (SELECT COUNT(*) FROM jardineria.dbo.cliente),         (SELECT COUNT(*) FROM jardineria_stg.dbo.cliente_stg)
UNION ALL SELECT 'pedido',         (SELECT COUNT(*) FROM jardineria.dbo.pedido),          (SELECT COUNT(*) FROM jardineria_stg.dbo.pedido_stg)
UNION ALL SELECT 'producto',       (SELECT COUNT(*) FROM jardineria.dbo.producto),        (SELECT COUNT(*) FROM jardineria_stg.dbo.producto_stg)
UNION ALL SELECT 'detalle_pedido', (SELECT COUNT(*) FROM jardineria.dbo.detalle_pedido),  (SELECT COUNT(*) FROM jardineria_stg.dbo.detalle_pedido_stg)
UNION ALL SELECT 'pago',           (SELECT COUNT(*) FROM jardineria.dbo.pago),            (SELECT COUNT(*) FROM jardineria_stg.dbo.pago_stg);

SELECT c.ID_cliente, c.ID_empleado_rep_ventas
FROM jardineria_stg.dbo.cliente_stg c
LEFT JOIN jardineria_stg.dbo.empleado_stg e ON e.ID_empleado = c.ID_empleado_rep_ventas
WHERE c.ID_empleado_rep_ventas IS NOT NULL AND e.ID_empleado IS NULL;

-- pedidos sin cliente
SELECT p.ID_pedido, p.ID_cliente
FROM jardineria_stg.dbo.pedido_stg p
LEFT JOIN jardineria_stg.dbo.cliente_stg c ON c.ID_cliente = p.ID_cliente
WHERE c.ID_cliente IS NULL;

-- productos sin categoría
SELECT pr.ID_producto, pr.Categoria
FROM jardineria_stg.dbo.producto_stg pr
LEFT JOIN jardineria_stg.dbo.Categoria_producto_stg cp ON cp.Id_Categoria = pr.Categoria
WHERE cp.Id_Categoria IS NULL;

-- detalle sin pedido o sin producto
SELECT dp.ID_pedido, dp.ID_producto
FROM jardineria_stg.dbo.detalle_pedido_stg dp
LEFT JOIN jardineria_stg.dbo.pedido_stg p ON p.ID_pedido = dp.ID_pedido
LEFT JOIN jardineria_stg.dbo.producto_stg pr ON pr.ID_producto = dp.ID_producto
WHERE p.ID_pedido IS NULL OR pr.ID_producto IS NULL;

-- pagos sin cliente
SELECT pa.ID_cliente, pa.id_transaccion
FROM jardineria_stg.dbo.pago_stg pa
LEFT JOIN jardineria_stg.dbo.cliente_stg c ON c.ID_cliente = pa.ID_cliente
WHERE c.ID_cliente IS NULL;

-- FK habilitadas y confiables
SELECT f.name AS FK, OBJECT_NAME(f.parent_object_id) AS tabla, f.is_disabled, f.is_not_trusted
FROM sys.foreign_keys f
WHERE f.name LIKE '%_stg'
ORDER BY tabla, FK;