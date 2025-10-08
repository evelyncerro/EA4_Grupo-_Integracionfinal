-- dq_orfanos_hechos_vs_dim.sql
-- Productos
SELECT COUNT(*) AS huérfanos_producto
FROM dm.FactVentas f
LEFT JOIN dm.DimProducto d ON d.ProductoKey = f.ProductoKey
WHERE d.ProductoKey IS NULL;

-- Clientes
SELECT COUNT(*) AS huérfanos_cliente
FROM dm.FactVentas f
LEFT JOIN dm.DimCliente d ON d.ClienteKey = f.ClienteKey
WHERE d.ClienteKey IS NULL;

-- Sucursal
SELECT COUNT(*) AS huérfanos_sucursal
FROM dm.FactVentas f
LEFT JOIN dm.DimSucursal d ON d.SucursalKey = f.SucursalKey
WHERE d.SucursalKey IS NULL;



SELECT 'DimProducto' AS tabla, COUNT(*) total, COUNT(DISTINCT ProductoKey) distintos
FROM dm.DimProducto;

-- código de negocio
SELECT CodProducto, COUNT(*) veces
FROM dm.DimProducto
GROUP BY CodProducto
HAVING COUNT(*) > 1; 


DECLARE @minDate DATE = (SELECT MIN(Fecha) FROM dm.FactVentas);
DECLARE @maxDate DATE = (SELECT MAX(Fecha) FROM dm.FactVentas);

SELECT d.Fecha
FROM dm.DimTiempo d
WHERE d.Fecha BETWEEN @minDate AND @maxDate
EXCEPT
SELECT d.Fecha
FROM dm.DimTiempo d
JOIN dm.FactVentas f ON f.FechaKey = d.FechaKey;



SELECT
  SUM(src.Cantidad) AS qty_fuente,
  SUM(src.Cantidad * src.PrecioUnitario) AS monto_fuente,
  SUM(dm.Cantidad) AS qty_dm,
  SUM(dm.Importe)  AS monto_dm
FROM src.Venta src
JOIN dm.FactVentas dm
  ON dm.CodVenta = src.CodVenta;


  -- dq_consistencia_codigos.sql
SELECT f.*
FROM dm.FactVentas f
LEFT JOIN dm.DimProducto p ON p.ProductoKey = f.ProductoKey
WHERE p.CodProducto IS NULL OR p.CodProducto = '';
