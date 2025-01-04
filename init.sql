\c ETURN

-- CREACIÓN DE LAS ENTIDADES DE USUARIO:

CREATE SCHEMA IF NOT EXISTS usuario;

CREATE TABLE IF NOT EXISTS usuario.usuario (
    id_usuario BIGSERIAL PRIMARY KEY,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    numero_identificacion VARCHAR(15) UNIQUE NOT NULL,
    correo_electronico VARCHAR(100) UNIQUE NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION actualizar_fecha_actualizacion()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER actualizar_fecha_trigger
BEFORE UPDATE ON usuario.usuario
FOR EACH ROW
EXECUTE FUNCTION actualizar_fecha_actualizacion();

CREATE INDEX idx_numero_identificacion ON usuario.usuario (numero_identificacion);

CREATE TABLE usuario.rol (
    id_rol SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE usuario.usuario_rol (
    id_usuario_rol SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL,
    rol_id INT NOT NULL,
    fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (usuario_id) REFERENCES usuario.usuario(id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (rol_id) REFERENCES usuario.rol(id_rol) ON DELETE CASCADE,
    UNIQUE (usuario_id, rol_id)
);

CREATE TABLE usuario.credencial (
    id_credencial SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuario.usuario(id_usuario) ON DELETE CASCADE
);

INSERT INTO usuario.usuario (nombres, apellidos, numero_identificacion, correo_electronico, activo)
VALUES 
('Carlos', 'Terán', '87654321', 'carlosandres.teran136@comunidadunir.net', TRUE),
('Marcos', 'Vásquez', '12345678', 'marcosalejandro.vasquez835@comunidadunir.net', TRUE),
('Administrador', 'General', '00000001', '95carlos.teran@gmail.com', TRUE);

INSERT INTO usuario.rol (nombre, descripcion)
VALUES 
    ('Administrador', 'Gestión completa del sistema y configuración avanzada.'),
    ('Atencion', 'Gestión de turnos y atención al cliente en tiempo real.'),
    ('Auditoria', 'Revisión de eventos y auditoría del sistema.'),
    ('Estadisticas', 'Acceso a reportes y estadísticas del sistema.'),
    ('Mantenimiento', 'Soporte técnico y mantenimiento del sistema.');

INSERT INTO usuario.usuario_rol (usuario_id, rol_id, fecha_asignacion, activo)
VALUES 
    (1, (SELECT id_rol FROM usuario.rol WHERE nombre = 'Mantenimiento'), CURRENT_TIMESTAMP, TRUE),
    (2, (SELECT id_rol FROM usuario.rol WHERE nombre = 'Mantenimiento'), CURRENT_TIMESTAMP, TRUE),
    (3, (SELECT id_rol FROM usuario.rol WHERE nombre = 'Administrador'), CURRENT_TIMESTAMP, TRUE);

INSERT INTO usuario.credencial (usuario_id, username, password_hash, fecha_creacion)
VALUES
    (1, 'admin_general', '$2a$12$examplehashforadmin', CURRENT_TIMESTAMP), 
    (2, 'user_mantenimiento', '$2a$12$examplehashformaint', CURRENT_TIMESTAMP),
    (3, 'user_atencion', '$2a$12$examplehashforcare', CURRENT_TIMESTAMP);

-- CREACION DE LAS ENTIDADES DE PACIENTE

CREATE SCHEMA IF NOT EXISTS paciente;

CREATE TABLE IF NOT EXISTS paciente.paciente (
    id_paciente SERIAL PRIMARY KEY,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    numero_identificacion int UNIQUE NOT NULL,    
    fecha_nacimiento DATE NOT NULL,
    telefono VARCHAR(20),
    correo_electronico VARCHAR(100),
    fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER actualizar_fecha_trigger
BEFORE UPDATE ON paciente.paciente
FOR EACH ROW
EXECUTE FUNCTION actualizar_fecha_actualizacion();

CREATE INDEX idx_numero_identificacion ON paciente.paciente (numero_identificacion);

INSERT INTO paciente.paciente (nombres, apellidos, numero_identificacion, fecha_nacimiento, telefono, correo_electronico) VALUES
('Juan', 'Pérez', 1013646445, '1985-06-15', '555-1234', 'juan.perez@email.com'),
('Ana', 'Gómez', 1013646446, '1990-09-20', '555-5678', 'ana.gomez@email.com'),
('Carlos', 'López', 1013646447, '1978-03-25', '555-8765', 'carlos.lopez@email.com');

-- CREACIÓN DE LAS ENTIDADES DE TURNO:

CREATE SCHEMA IF NOT EXISTS turno;

CREATE TABLE IF NOT EXISTS turno.servicio (
    id_servicio SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    descripcion VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS turno.turno (
    id_turno SERIAL PRIMARY KEY,
    paciente_id INT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) DEFAULT 'Pendiente',
    FOREIGN KEY (paciente_id) REFERENCES paciente.paciente(id_paciente)
);

CREATE TABLE IF NOT EXISTS turno.prestacion (
    id_prestacion SERIAL PRIMARY KEY,
    turno_id INT NOT NULL,
    servicio_id INT NOT NULL,
    usuario_id BIGINT NOT NULL,
    prioridad INT NOT NULL,
    hora_inicio TIMESTAMP,
    hora_llamada TIMESTAMP,
    hora_cierre TIMESTAMP,
    FOREIGN KEY (turno_id) REFERENCES turno.turno(id_turno),
    FOREIGN KEY (servicio_id) REFERENCES turno.servicio(id_servicio),
    FOREIGN KEY (usuario_id) REFERENCES usuario.usuario(id_usuario)
);

INSERT INTO turno.servicio (nombre, descripcion) VALUES
('Admisión', 'Recepción y registro inicial del paciente en urgencias.'),
('Triage', 'Clasificación de pacientes según la gravedad de su condición.'),
('Consulta', 'Atención médica primaria para evaluación y diagnóstico.'),
('Toma de muestras', 'Recolección de muestras biológicas para análisis.'),
('Imagen diagnóstica', 'Obtención de imágenes médicas para diagnóstico.');

INSERT INTO turno.turno (paciente_id, fecha_creacion, estado) VALUES
(1, '2024-11-27 08:00:00', 'Pendiente'),
(2, '2024-11-27 08:30:00', 'Pendiente'),
(3, '2024-11-27 09:00:00', 'Pendiente');

INSERT INTO turno.prestacion (turno_id, servicio_id, usuario_id, prioridad, hora_inicio, hora_llamada, hora_cierre) VALUES
(1, 1, 1, 1, '2024-11-27 08:00:00', '2024-11-27 08:28:00', '2024-11-27 08:30:00'),
(1, 2, 2, 2, '2024-11-27 08:35:00', '2024-11-27 08:40:00', '2024-11-27 08:50:00'),
(1, 3, 3, 3, '2024-11-27 09:00:00', '2024-11-27 09:10:00', '2024-11-27 09:20:00');
