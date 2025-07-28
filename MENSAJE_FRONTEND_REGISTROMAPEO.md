# 🗺️ Nueva Funcionalidad: Registro de Mapeo

## 📋 Descripción General

Se ha implementado una nueva funcionalidad para manejar el **registro de mapeo** de forma independiente a los registros normales. Esta nueva tabla permite gestionar el mapeo de temporadas y cuarteles con fechas específicas.

## 🆕 Nuevos Endpoints Disponibles

### Base URL: `/api/registromapeo`

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/registromapeo/` | Obtener todos los registros de mapeo |
| `GET` | `/api/registromapeo/{id}` | Obtener un registro específico |
| `POST` | `/api/registromapeo/` | Crear nuevo registro de mapeo |
| `PUT` | `/api/registromapeo/{id}` | Actualizar registro de mapeo |
| `DELETE` | `/api/registromapeo/{id}` | Eliminar registro de mapeo |
| `GET` | `/api/registromapeo/temporada/{id}` | Filtrar por temporada |
| `GET` | `/api/registromapeo/cuartel/{id}` | Filtrar por cuartel |
| `GET` | `/api/registromapeo/estado/{id}` | Filtrar por estado |

## 📊 Estructura de Datos

### Campos del Registro de Mapeo:

```json
{
  "id": "uuid-string",
  "id_temporada": 1,
  "id_cuartel": 5,
  "fecha_inicio": "2024-01-01",
  "fecha_termino": "2024-12-31",
  "id_estado": 1
}
```

### Tipos de Datos:
- **id**: `string` (UUID generado automáticamente)
- **id_temporada**: `number` (ID de la temporada)
- **id_cuartel**: `number` (ID del cuartel)
- **fecha_inicio**: `string` (formato: "YYYY-MM-DD")
- **fecha_termino**: `string` (formato: "YYYY-MM-DD")
- **id_estado**: `number` (ID del estado)

## 🔐 Autenticación

**IMPORTANTE**: Todos los endpoints requieren autenticación JWT. Incluir el token en el header:

```
Authorization: Bearer <tu-token-jwt>
```

## 📝 Ejemplos de Uso

### 1. Crear un nuevo registro de mapeo:

```javascript
const nuevoMapeo = {
  "id_temporada": 1,
  "id_cuartel": 5,
  "fecha_inicio": "2024-01-01",
  "fecha_termino": "2024-12-31",
  "id_estado": 1
};

fetch('/api/registromapeo/', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
  },
  body: JSON.stringify(nuevoMapeo)
});
```

### 2. Obtener todos los registros de mapeo:

```javascript
fetch('/api/registromapeo/', {
  headers: {
    'Authorization': 'Bearer ' + token
  }
});
```

### 3. Filtrar por temporada:

```javascript
fetch('/api/registromapeo/temporada/1', {
  headers: {
    'Authorization': 'Bearer ' + token
  }
});
```

## ✅ Validaciones Implementadas

### Campos Requeridos:
- `id_temporada`
- `id_cuartel`
- `fecha_inicio`
- `fecha_termino`
- `id_estado`

### Validaciones de Formato:
- **Fechas**: Deben estar en formato "YYYY-MM-DD"
- **Números**: id_temporada, id_cuartel, id_estado deben ser números válidos
- **ID**: Se genera automáticamente como UUID

## 🚨 Códigos de Respuesta

| Código | Descripción |
|--------|-------------|
| `200` | Operación exitosa |
| `201` | Recurso creado exitosamente |
| `400` | Datos inválidos o campos faltantes |
| `401` | No autorizado (token inválido) |
| `404` | Recurso no encontrado |
| `500` | Error interno del servidor |

## 🔄 Diferencias con Registros Normales

| Aspecto | Registros Normales | Registro de Mapeo |
|---------|-------------------|-------------------|
| **Tabla** | `mapeo_fact_registro` | `mapeo_fact_registromapeo` |
| **Propósito** | Registro de evaluaciones | Mapeo de temporadas/cuarteles |
| **Campos** | id_evaluador, id_planta, imagen | id_temporada, id_cuartel, fechas |
| **URL Base** | `/api/registros/` | `/api/registromapeo/` |

## 📱 Integración Frontend

### Para React/Vue/Angular:

```javascript
// Servicio para registromapeo
class RegistroMapeoService {
  constructor(token) {
    this.token = token;
    this.baseUrl = '/api/registromapeo';
  }

  async obtenerTodos() {
    const response = await fetch(this.baseUrl, {
      headers: { 'Authorization': `Bearer ${this.token}` }
    });
    return response.json();
  }

  async crear(mapeo) {
    const response = await fetch(this.baseUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.token}`
      },
      body: JSON.stringify(mapeo)
    });
    return response.json();
  }

  async actualizar(id, mapeo) {
    const response = await fetch(`${this.baseUrl}/${id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.token}`
      },
      body: JSON.stringify(mapeo)
    });
    return response.json();
  }

  async eliminar(id) {
    const response = await fetch(`${this.baseUrl}/${id}`, {
      method: 'DELETE',
      headers: { 'Authorization': `Bearer ${this.token}` }
    });
    return response.json();
  }
}
```

## 🎯 Casos de Uso Típicos

1. **Configurar mapeo de temporada**: Asignar cuarteles a una temporada específica
2. **Gestionar fechas de mapeo**: Definir períodos de inicio y fin para el mapeo
3. **Control de estados**: Seguimiento del estado del mapeo por cuartel
4. **Reportes por temporada**: Obtener todos los mapeos de una temporada
5. **Filtros por cuartel**: Ver mapeos específicos de un cuartel

## 📞 Soporte

Si tienes alguna pregunta sobre la implementación o necesitas ayuda con la integración, contacta al equipo de desarrollo.

---

**Fecha de implementación**: $(date)
**Versión**: 1.0.0
**Estado**: ✅ Activo y funcional 