--- STAGING

-- dq_nulls_obligatorios.sql (Staging)
-- Ej.: Cliente_Stg(IdCliente, Nombre, Email, ...)

SELECT *
FROM stg.Cliente_Stg
WHERE IdCliente IS NULL OR Nombre IS NULL;


-- dq_duplicados_pk.sql
SELECT IdCliente, COUNT(*) AS veces
FROM stg.Cliente_Stg
GROUP BY IdCliente
HAVING COUNT(*) > 1;


-- dq_rangos_campos.sql (ventas no negativas; fecha válida)
SELECT *
FROM stg.Venta_Stg
WHERE Cantidad < 0
   OR PrecioUnitario < 0
   OR FechaVenta < '2000-01-01' OR FechaVenta > GETDATE();

-- dq_integridad_referencial.sql
SELECT v.*
FROM stg.Venta_Stg v
LEFT JOIN stg.Producto_Stg p ON p.CodProducto = v.CodProducto
WHERE p.CodProducto IS NULL;  -- ventas con producto desconocido


-- dq_conteos_fuente_vs_stg.sql
-- Ajusta nombres de tablas fuente (OLTP) y STG
SELECT 'VENTAS' AS entidad,
       (SELECT COUNT(*) FROM src.Venta) AS cnt_fuente,
       (SELECT COUNT(*) FROM stg.Venta_Stg) AS cnt_stg;
