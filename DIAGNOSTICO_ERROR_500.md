# Diagnóstico del Error 500 - Crear Planta

## Problema
Se está produciendo un error 500 (Internal Server Error) al intentar crear una planta en el backend.

## APK Actualizada
Se ha generado una nueva APK con logging mejorado: `build\app\outputs\flutter-apk\app-debug.apk`

## Pasos para Diagnosticar

### 1. Instalar la Nueva APK
```bash
# Instalar la APK en tu dispositivo
adb install build\app\outputs\flutter-apk\app-debug.apk
```

### 2. Probar la Funcionalidad
1. Abre la aplicación
2. Inicia sesión
3. Navega hasta "Agregar Planta"
4. Intenta crear una planta

### 3. Revisar los Logs
La aplicación ahora incluye logging detallado que mostrará:

#### En la Consola de Flutter:
```
🔍 Datos a enviar:
  - Hilera ID: [ID]
  - Número planta: [NÚMERO]
  - Ubicación original: [COORDENADAS]
  - Ubicación formateada: [COORDENADAS_FORMATEADAS]
  - Cuartel ID: [ID]
  - Cuartel nombre: [NOMBRE]

🔍 Probando conexión al servidor...
📡 Conexión al servidor: OK/ERROR

🔍 Verificando estructura de la hilera...
📋 Datos de la hilera: [DATOS_JSON]

🔄 Creando planta simple con datos: [DATOS]
📡 URL: http://192.168.1.234:5000/api/plantas/
📋 Headers: [HEADERS]
🔍 Tipo de datos:
  - id_hilera: String = '[ID]'
  - planta: int = [NÚMERO]
  - ubicacion: String = '[COORDENADAS]'
📦 JSON enviado: [JSON_COMPLETO]
📡 Respuesta crear planta simple: 500
📝 Body respuesta: [RESPUESTA_ERROR]
📋 Headers respuesta: [HEADERS_RESPUESTA]
❌ Error 500 del servidor
📝 Body del error: [DETALLES_ERROR]
```

### 4. Información Necesaria para el Diagnóstico

Por favor, proporciona los siguientes logs cuando intentes crear una planta:

1. **Logs completos de la consola de Flutter** (especialmente los que empiezan con 🔍, 📡, ❌)
2. **El JSON exacto que se está enviando** (línea que empieza con 📦)
3. **La respuesta completa del servidor** (líneas que empiezan con 📝)
4. **Cualquier error parseado** (líneas que empiezan con 🔍 Error parseado)

### 5. Posibles Causas del Error 500

#### A. Problema de Base de Datos
- La hilera no existe en la base de datos
- Problema de permisos en la base de datos
- Error en la consulta SQL

#### B. Problema de Validación
- Datos en formato incorrecto
- Campos requeridos faltantes
- Restricciones de base de datos violadas

#### C. Problema de Autenticación
- Token expirado o inválido
- Problema con los headers de autorización

#### D. Problema de Servidor
- Error en el código del backend
- Problema de configuración del servidor
- Error de conexión a la base de datos

### 6. Comandos Útiles para Debugging

```bash
# Ver logs en tiempo real
flutter logs

# Ver logs específicos de la aplicación
adb logcat | grep "flutter"

# Verificar conexión al servidor
curl -X GET http://192.168.1.234:5000/api/plantas/ -H "Authorization: Bearer [TOKEN]"
```

### 7. Próximos Pasos

Una vez que tengas los logs detallados:

1. **Comparte los logs** para análisis
2. **Verifica el estado del servidor backend** (si tienes acceso)
3. **Revisa los logs del servidor** para ver el error específico
4. **Prueba con datos diferentes** para ver si el problema es específico

### 8. Información Adicional

- **URL del servidor**: http://192.168.1.234:5000/api
- **Endpoint**: POST /api/plantas/
- **Headers requeridos**: Content-Type: application/json, Authorization: Bearer [TOKEN]
- **Datos requeridos**: id_hilera (String), planta (int), ubicacion (String)

---

**Nota**: Los logs detallados nos ayudarán a identificar exactamente qué está causando el error 500 en el backend. 