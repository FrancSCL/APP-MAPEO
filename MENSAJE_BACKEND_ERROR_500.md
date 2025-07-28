# Mensaje para el Equipo de Backend - Error 500 en POST /api/plantas/

## Resumen del Problema

Estamos experimentando un **Error 500 (Internal Server Error)** al intentar crear plantas a través del endpoint `POST /api/plantas/`.

## Detalles Técnicos

### Endpoint Afectado
- **URL**: `http://192.168.1.234:5000/api/plantas/`
- **Método**: POST
- **Status Code**: 500
- **Timestamp**: 18/Jul/2025 09:53:27

### Datos que se están enviando
```json
{
  "id_hilera": "string",
  "planta": integer,
  "ubicacion": "string"
}
```

### Headers enviados
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer [token]
```

## Información de Contexto

### Aplicación Frontend
- **Tecnología**: Flutter (aplicación móvil)
- **Versión**: Debug build
- **Funcionalidad**: Agregar plantas con GPS automático

### Flujo de la Aplicación
1. Usuario selecciona un cuartel
2. Usuario selecciona una hilera
3. Usuario intenta agregar una planta
4. La aplicación obtiene ubicación GPS automáticamente
5. Se envía POST request al endpoint
6. **ERROR 500** se produce en el servidor

## Logs del Servidor
```
192.168.1.234 - - [18/Jul/2025 09:53:27] "POST /api/plantas/ HTTP/1.1" 500 -
```

## Posibles Causas a Investigar

### 1. Problemas de Base de Datos
- ¿Existe la hilera en la base de datos?
- ¿Hay restricciones de clave foránea violadas?
- ¿Problemas de permisos en la tabla `plantas`?
- ¿Error en la consulta SQL de inserción?

### 2. Problemas de Validación
- ¿Los datos enviados cumplen con las validaciones del backend?
- ¿Hay campos requeridos faltantes?
- ¿El formato de las coordenadas GPS es correcto?

### 3. Problemas de Autenticación
- ¿El token de autorización es válido?
- ¿El usuario tiene permisos para crear plantas?

### 4. Problemas de Servidor
- ¿Error en el código del endpoint?
- ¿Problema de configuración del servidor?
- ¿Error de conexión a la base de datos?

## Información Adicional

### Estructura de Datos Esperada
```python
# Ejemplo de datos que deberían funcionar
{
    "id_hilera": "1",  # ID de la hilera como string
    "planta": 1,       # Número de planta como integer
    "ubicacion": "-33.7837107,-70.739615"  # Coordenadas GPS como string
}
```

### Validaciones que deberían aplicarse
1. Verificar que `id_hilera` existe en la tabla `hileras`
2. Verificar que no existe una planta con el mismo número en la misma hilera
3. Validar formato de coordenadas GPS
4. Verificar permisos del usuario

## Solicitud de Ayuda

### Necesitamos que revisen:

1. **Logs detallados del servidor** en el momento del error 500
2. **Estructura de la tabla `plantas`** y sus restricciones
3. **Código del endpoint** `POST /api/plantas/`
4. **Validaciones implementadas** en el backend
5. **Conexión a la base de datos** y permisos

### Información que sería útil:

1. **Stack trace completo** del error 500
2. **Query SQL** que se está ejecutando
3. **Datos exactos** que están llegando al servidor
4. **Validaciones que están fallando** (si las hay)

## Contacto

Por favor, proporcionen:
- Logs detallados del servidor
- Stack trace del error
- Cualquier información adicional que consideren relevante

---

**Nota**: Hemos implementado logging detallado en el frontend para capturar exactamente qué datos se están enviando. Una vez que tengamos esta información, podremos proporcionar más detalles sobre el request específico que está causando el error. 