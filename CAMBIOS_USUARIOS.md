# Cambios en la Estructura de Usuarios

## Resumen de Cambios

Se han realizado actualizaciones importantes en la estructura de la tabla `general_dim_usuario` y los endpoints relacionados. La tabla de usuarios ya no mantiene relación con una tabla de colaboradores y ahora incluye directamente los campos de nombre y apellidos.

## Cambios en la Base de Datos

### Estructura Anterior
- La tabla `general_dim_usuario` tenía un campo `id_colaborador` que referenciaba a una tabla de colaboradores
- Los datos de nombre y apellidos se almacenaban en la tabla de colaboradores

### Nueva Estructura
La tabla `general_dim_usuario` ahora incluye directamente:
- `nombre` (varchar(45))
- `apellido_paterno` (varchar(45))
- `apellido_materno` (varchar(45))

**Eliminado:**
- `id_colaborador` (ya no existe la relación con colaboradores)

## Cambios en los Endpoints

### 1. Registro de Usuarios (`POST /api/auth/register`)

**Campos requeridos actualizados:**
```json
{
  "usuario": "string",
  "correo": "string",
  "clave": "string",
  "nombre": "string",           // NUEVO - Requerido
  "apellido_paterno": "string", // NUEVO - Requerido
  "apellido_materno": "string", // NUEVO - Opcional
  "id_sucursalactiva": "int",
  "id_estado": "int",           // Opcional, default: 1
  "id_rol": "int",              // Opcional, default: 3
  "id_perfil": "int"            // Opcional, default: 1
}
```

### 2. Login (`POST /api/auth/login`)

**Respuesta actualizada:**
```json
{
  "access_token": "string",
  "usuario": "string",
  "nombre_completo": "string",  // NUEVO - Nombre completo concatenado
  "id_sucursal": "int",
  "sucursal_nombre": "string",
  "id_rol": "int",
  "id_perfil": "int"
}
```

### 3. Refresh Token (`POST /api/auth/refresh`)

**Respuesta actualizada:**
```json
{
  "access_token": "string",
  "usuario": "string",
  "nombre_completo": "string",  // NUEVO - Nombre completo concatenado
  "id_sucursal": "int",
  "sucursal_nombre": "string",
  "id_rol": "int",
  "id_perfil": "int"
}
```

### 4. Obtener Todos los Usuarios (`GET /api/usuarios/`)

**Respuesta actualizada:**
```json
[
  {
    "id": "string",
    "usuario": "string",
    "correo": "string",
    "nombre": "string",           // NUEVO
    "apellido_paterno": "string", // NUEVO
    "apellido_materno": "string", // NUEVO
    "id_sucursalactiva": "int",
    "id_estado": "int",
    "id_rol": "int",
    "id_perfil": "int",
    "fecha_creacion": "date",
    "nombre_sucursal": "string"
  }
]
```

### 5. Nuevos Endpoints

#### Obtener Perfil del Usuario (`GET /api/usuarios/perfil`)
```json
{
  "id": "string",
  "usuario": "string",
  "correo": "string",
  "nombre": "string",
  "apellido_paterno": "string",
  "apellido_materno": "string",
  "nombre_completo": "string",
  "id_sucursalactiva": "int",
  "id_estado": "int",
  "id_rol": "int",
  "id_perfil": "int",
  "fecha_creacion": "date",
  "nombre_sucursal": "string"
}
```

#### Actualizar Perfil (`PUT /api/usuarios/perfil`)
```json
// Request
{
  "nombre": "string",           // Opcional
  "apellido_paterno": "string", // Opcional
  "apellido_materno": "string", // Opcional
  "correo": "string"            // Opcional
}

// Response
{
  "message": "Perfil actualizado correctamente",
  "usuario": {
    // Datos completos del usuario actualizado
  }
}
```

## Impacto en el Frontend

### 1. Formularios de Registro
- Agregar campos para `nombre`, `apellido_paterno` y `apellido_materno`
- Hacer obligatorios `nombre` y `apellido_paterno`
- `apellido_materno` es opcional

### 2. Perfiles de Usuario
- Mostrar el `nombre_completo` en lugar de obtenerlo de una tabla separada
- Actualizar formularios de edición de perfil para incluir los nuevos campos

### 3. Listas de Usuarios
- Mostrar directamente `nombre`, `apellido_paterno` y `apellido_materno`
- Ya no es necesario hacer JOIN con tabla de colaboradores

### 4. Validaciones
- Validar que `nombre` y `apellido_paterno` no estén vacíos
- `apellido_materno` puede estar vacío

## Notas Importantes

1. **Compatibilidad:** Los cambios son compatibles hacia adelante, pero requieren actualización del frontend
2. **Migración:** Los datos existentes deben migrarse desde la tabla de colaboradores a los nuevos campos
3. **Validación:** El backend ahora valida que `nombre` y `apellido_paterno` sean proporcionados en el registro
4. **Concatenación:** El campo `nombre_completo` se genera automáticamente concatenando los campos de nombre y apellidos

## Campos Eliminados

- `id_colaborador` ya no se incluye en ninguna consulta
- No hay más referencias a la tabla de colaboradores

## Campos Nuevos

- `nombre`: Nombre del usuario
- `apellido_paterno`: Apellido paterno del usuario
- `apellido_materno`: Apellido materno del usuario (opcional)
- `nombre_completo`: Campo calculado que concatena nombre y apellidos 