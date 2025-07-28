# 🚨 IMPORTANTE: Cambios en la API de Usuarios

## Resumen Ejecutivo

La estructura de la tabla de usuarios ha cambiado significativamente. **Ya no hay relación con la tabla de colaboradores** y ahora los datos de nombre y apellidos están directamente en la tabla de usuarios.

## 🔄 Cambios Críticos que Requieren Actualización del Frontend

### 1. **Registro de Usuarios** (`POST /api/auth/register`)

**ANTES:**
```json
{
  "usuario": "juan123",
  "correo": "juan@email.com",
  "clave": "password123",
  "id_sucursalactiva": 1
}
```

**AHORA:**
```json
{
  "usuario": "juan123",
  "correo": "juan@email.com",
  "clave": "password123",
  "nombre": "Juan",              // ⚠️ NUEVO - OBLIGATORIO
  "apellido_paterno": "Pérez",   // ⚠️ NUEVO - OBLIGATORIO
  "apellido_materno": "García",  // ⚠️ NUEVO - OPCIONAL
  "id_sucursalactiva": 1
}
```

### 2. **Login y Refresh** (`POST /api/auth/login` y `POST /api/auth/refresh`)

**Respuesta actualizada:**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "usuario": "juan123",
  "nombre_completo": "Juan Pérez García",  // ⚠️ NUEVO
  "id_sucursal": 1,
  "sucursal_nombre": "Sucursal Central",
  "id_rol": 3,
  "id_perfil": 1
}
```

### 3. **Lista de Usuarios** (`GET /api/usuarios/`)

**Respuesta actualizada:**
```json
[
  {
    "id": "uuid-123",
    "usuario": "juan123",
    "correo": "juan@email.com",
    "nombre": "Juan",              // ⚠️ NUEVO
    "apellido_paterno": "Pérez",   // ⚠️ NUEVO
    "apellido_materno": "García",  // ⚠️ NUEVO
    "id_sucursalactiva": 1,
    "id_estado": 1,
    "id_rol": 3,
    "id_perfil": 1,
    "fecha_creacion": "2024-01-15",
    "nombre_sucursal": "Sucursal Central"
  }
]
```

## 🆕 Nuevos Endpoints Disponibles

### 4. **Obtener Perfil del Usuario** (`GET /api/usuarios/perfil`)
```json
{
  "id": "uuid-123",
  "usuario": "juan123",
  "correo": "juan@email.com",
  "nombre": "Juan",
  "apellido_paterno": "Pérez",
  "apellido_materno": "García",
  "nombre_completo": "Juan Pérez García",
  "id_sucursalactiva": 1,
  "id_estado": 1,
  "id_rol": 3,
  "id_perfil": 1,
  "fecha_creacion": "2024-01-15",
  "nombre_sucursal": "Sucursal Central"
}
```

### 5. **Actualizar Perfil** (`PUT /api/usuarios/perfil`)
```json
// Request
{
  "nombre": "Juan Carlos",        // Opcional
  "apellido_paterno": "Pérez",    // Opcional
  "apellido_materno": "García",   // Opcional
  "correo": "nuevo@email.com"     // Opcional
}

// Response
{
  "message": "Perfil actualizado correctamente",
  "usuario": {
    // Datos completos del usuario actualizado
  }
}
```

## ⚠️ Acciones Requeridas en el Frontend

### 1. **Formularios de Registro**
- ✅ Agregar campo `nombre` (obligatorio)
- ✅ Agregar campo `apellido_paterno` (obligatorio)
- ✅ Agregar campo `apellido_materno` (opcional)
- ✅ Actualizar validaciones

### 2. **Pantallas de Login**
- ✅ Mostrar `nombre_completo` en lugar de solo `usuario`
- ✅ Actualizar el manejo de la respuesta del login

### 3. **Perfiles de Usuario**
- ✅ Usar el nuevo endpoint `GET /api/usuarios/perfil`
- ✅ Mostrar campos separados de nombre y apellidos
- ✅ Implementar formulario de edición con `PUT /api/usuarios/perfil`

### 4. **Listas de Usuarios**
- ✅ Mostrar `nombre`, `apellido_paterno` y `apellido_materno`
- ✅ Ya no necesitas hacer JOIN con tabla de colaboradores

### 5. **Validaciones**
- ✅ Validar que `nombre` y `apellido_paterno` no estén vacíos
- ✅ `apellido_materno` puede estar vacío

## 🗑️ Campos Eliminados

- ❌ `id_colaborador` ya no existe
- ❌ No más referencias a tabla de colaboradores

## 📋 Checklist de Implementación

- [ ] Actualizar formulario de registro
- [ ] Actualizar manejo de respuesta de login
- [ ] Actualizar pantallas de perfil de usuario
- [ ] Actualizar listas de usuarios
- [ ] Implementar nuevos endpoints de perfil
- [ ] Actualizar validaciones
- [ ] Probar todos los flujos

## 🚀 Beneficios de los Cambios

1. **Simplificación:** Ya no hay JOINs complejos con tabla de colaboradores
2. **Rendimiento:** Consultas más rápidas al tener todo en una tabla
3. **Mantenimiento:** Menos complejidad en el código
4. **Flexibilidad:** Más fácil agregar/modificar campos de usuario

## 📞 Soporte

Si tienes dudas sobre la implementación, revisa el archivo `CAMBIOS_USUARIOS.md` para documentación detallada.

---

**⚠️ IMPORTANTE:** Estos cambios son **obligatorios** para que el frontend funcione correctamente con la nueva estructura de la API. 