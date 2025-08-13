-- Script para crear la tabla de estados de hileras
-- Esta tabla permite manejar el estado individual de cada hilera en un registro de mapeo

CREATE TABLE IF NOT EXISTS mapeo_fact_estado_hilera (
    id VARCHAR(36) PRIMARY KEY,
    id_registro_mapeo VARCHAR(36) NOT NULL,
    id_hilera INT NOT NULL,
    estado ENUM('pendiente', 'en_progreso', 'pausado', 'completado') DEFAULT 'pendiente',
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    id_usuario VARCHAR(36),
    observaciones TEXT,
    
    -- Índices para mejorar rendimiento
    INDEX idx_registro_hilera (id_registro_mapeo, id_hilera),
    INDEX idx_estado (estado),
    INDEX idx_fecha_actualizacion (fecha_actualizacion),
    
    -- Clave foránea al registro de mapeo
    FOREIGN KEY (id_registro_mapeo) REFERENCES mapeo_fact_registromapeo(id) ON DELETE CASCADE,
    
    -- Clave foránea a la hilera
    FOREIGN KEY (id_hilera) REFERENCES general_dim_hilera(id) ON DELETE CASCADE,
    
    -- Clave foránea al usuario (opcional)
    FOREIGN KEY (id_usuario) REFERENCES general_dim_usuario(id) ON DELETE SET NULL,
    
    -- Restricción única para evitar duplicados
    UNIQUE KEY unique_registro_hilera (id_registro_mapeo, id_hilera)
);

-- Insertar algunos datos de ejemplo (opcional)
-- INSERT INTO mapeo_fact_estado_hilera (id, id_registro_mapeo, id_hilera, estado, id_usuario) VALUES
-- (UUID(), 'registro-uuid-1', 1, 'en_progreso', 'usuario-uuid-1'),
-- (UUID(), 'registro-uuid-1', 2, 'pendiente', 'usuario-uuid-1'),
-- (UUID(), 'registro-uuid-1', 3, 'completado', 'usuario-uuid-1');
