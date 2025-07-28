# 🆕 Nueva Tabla: Registro de Mapeo

## 📝 Qué es
Nueva tabla separada para manejar el mapeo de temporadas y cuarteles.

## 🔗 Endpoints Nuevos
- `GET /api/registromapeo/` - Listar todos
- `POST /api/registromapeo/` - Crear nuevo
- `PUT /api/registromapeo/{id}` - Actualizar
- `DELETE /api/registromapeo/{id}` - Eliminar

## 📊 Datos que maneja
```json
{
  "id_temporada": 1,
  "id_cuartel": 5,
  "fecha_inicio": "2024-01-01",
  "fecha_termino": "2024-12-31",  // OPCIONAL
  "id_estado": 1
}
```

## ✅ Listo para usar
- Autenticación JWT requerida
- Validaciones incluidas
- IDs automáticos (UUID)

---
**Diferencia**: Esta tabla es SEPARADA de `/api/registros/` normal. 