# 🚨 CAMBIOS API - FRONTEND

## ⚡ RESUMEN
Ya no hay tabla colaboradores. Todo está en `general_dim_usuario`.

## 🔥 CAMBIOS OBLIGATORIOS

### REGISTRO (`POST /api/auth/register`)
```json
// AGREGAR ESTOS CAMPOS:
{
  "nombre": "Juan",              // OBLIGATORIO
  "apellido_paterno": "Pérez",   // OBLIGATORIO  
  "apellido_materno": "García"   // OPCIONAL
}
```

### LOGIN (`POST /api/auth/login`)
```json
// RESPUESTA NUEVA:
{
  "nombre_completo": "Juan Pérez García"  // NUEVO
}
```

### LISTA USUARIOS (`GET /api/usuarios/`)
```json
// AHORA INCLUYE:
{
  "nombre": "Juan",              // NUEVO
  "apellido_paterno": "Pérez",   // NUEVO
  "apellido_materno": "García"   // NUEVO
}
```

## 🆕 NUEVOS ENDPOINTS
- `GET /api/usuarios/perfil` - Obtener perfil
- `PUT /api/usuarios/perfil` - Actualizar perfil

## ✅ TO-DO
- [ ] Agregar campos nombre/apellidos en registro
- [ ] Mostrar nombre_completo en login
- [ ] Actualizar listas de usuarios
- [ ] Implementar pantalla de perfil

## ❌ ELIMINADO
- `id_colaborador` ya no existe

---

**⚠️ OBLIGATORIO:** Sin estos cambios no funciona el frontend. 