# 🔄 Cambios en Campo id_planta - BIGINT

## Resumen
Se cambió el tipo de dato del campo `id_planta` en la tabla `mapeo_fact_registro` de `int` a `bigint`.

## Cambios Realizados

### 1. **blueprints/registros.py**
- ✅ Cambiado parámetro `<int:planta_id>` a `<string:planta_id>` en endpoint `/planta/<planta_id>`
- ✅ Esto permite manejar valores bigint correctamente

### 2. **blueprints/plantas.py**
- ✅ Cambiado parámetro `<int:planta_id>` a `<string:planta_id>` en endpoints:
  - `GET /<planta_id>` - Obtener planta
  - `PUT /<planta_id>` - Actualizar planta  
  - `DELETE /<planta_id>` - Eliminar planta

## Impacto

### ✅ Beneficios
- **Mayor rango**: Los IDs de plantas pueden ser números más grandes
- **Compatibilidad**: Mejor compatibilidad con sistemas que usan bigint
- **Escalabilidad**: Permite más plantas sin problemas de overflow

### ⚠️ Consideraciones Frontend
- Los IDs de plantas ahora pueden ser números más grandes
- El frontend debe manejar estos valores como strings en las URLs
- No hay cambios en las respuestas JSON (siguen siendo números)

## Endpoints Afectados

### Registros
- `GET /api/registros/planta/{planta_id}` - Ahora acepta bigint

### Plantas  
- `GET /api/plantas/{planta_id}` - Ahora acepta bigint
- `PUT /api/plantas/{planta_id}` - Ahora acepta bigint
- `DELETE /api/plantas/{planta_id}` - Ahora acepta bigint

## Nota Importante
Los cambios son **compatibles hacia adelante**. El frontend no necesita cambios adicionales ya que los IDs se siguen enviando como números en las respuestas JSON. 