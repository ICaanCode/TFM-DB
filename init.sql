-- \c ETURN

-- Esquema para la gestión de catálogos
CREATE SCHEMA IF NOT EXISTS catalogo;

-- Esquema para la gestión de servicios
CREATE SCHEMA IF NOT EXISTS servicio;

-- Esquema para la gestión de turnos
CREATE SCHEMA IF NOT EXISTS turno;

-- Esquema para la gestión de usuarios y autenticación
CREATE SCHEMA IF NOT EXISTS usuario;

-- Esquema para la gestrión de pacientes
CREATE SCHEMA IF NOT EXISTS paciente;

-- Crear la tabla 'condicion' en el esquema 'catalogo'
CREATE TABLE IF NOT EXISTS catalogo.condicion (
  id_condicion SERIAL PRIMARY KEY,
  codigo INTEGER UNIQUE NOT NULL CHECK (codigo >= 20001),
  descripcion VARCHAR(255) NOT NULL,
  prioritario BOOLEAN DEFAULT FALSE,
  multiplicador DECIMAL(5,2) NOT NULL CHECK (multiplicador > 0)
);

-- Tabla de Estados de turno en el esquema catálogo
CREATE TABLE IF NOT EXISTS catalogo.estado (
  id_estado SERIAL PRIMARY KEY,
  codigo INTEGER NOT NULL UNIQUE CHECK (codigo >= 31000 AND codigo <32000),
  nombre VARCHAR(50) NOT NULL UNIQUE,
  descripcion VARCHAR(255) NOT NULL,
  activo BOOLEAN DEFAULT TRUE,
  fecha_creacion TIMESTAMP DEFAULT NOW(),
  fecha_modificacion TIMESTAMP
);

-- Tabla de Roles en el esquema catalogo
CREATE TABLE IF NOT EXISTS catalogo.rol (
  id_rol SERIAL PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  codigo INTEGER NOT NULL UNIQUE CHECK (codigo >= 10000 AND codigo < 11000),
  activo BOOLEAN DEFAULT TRUE,
  fecha_creacion TIMESTAMP DEFAULT NOW(),
  fecha_modificacion TIMESTAMP
);

-- Tabla de Servicios en el esquema catálogo
CREATE TABLE IF NOT EXISTS catalogo.servicio (
  id_servicio SERIAL PRIMARY KEY,
  codigo INTEGER NOT NULL UNIQUE CHECK (codigo >= 30000 AND codigo < 31000),
  nombre VARCHAR(50) NOT NULL UNIQUE,
  descripcion VARCHAR(255) NOT NULL,
  activo BOOLEAN DEFAULT TRUE,
  fecha_creacion TIMESTAMP DEFAULT NOW(),
  fecha_modificacion TIMESTAMP
);

-- Crear la tabla 'paciente' en el esquema 'paciente'
CREATE TABLE IF NOT EXISTS paciente.paciente (
  id_paciente UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombres VARCHAR(100) NOT NULL,
  apellidos VARCHAR(100) NOT NULL,
  fecha_nacimiento DATE NOT NULL,
  telefono VARCHAR(15),
  identificacion VARCHAR(20) UNIQUE NOT NULL,
  condicion_id INTEGER,
  CONSTRAINT fk_condicion
      FOREIGN KEY (condicion_id) 
      REFERENCES catalogo.condicion(id_condicion)
      ON DELETE SET NULL
);

-- Tabla de Turno del esquema turno
CREATE TABLE IF NOT EXISTS turno.turno (
  id_turno UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo VARCHAR(6) NOT NULL,
  paciente_id UUID NOT NULL,
  estado_id INTEGER NOT NULL,
  fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
  fecha_finalizacion TIMESTAMP,
  CONSTRAINT fk_estado FOREIGN KEY (estado_id) REFERENCES catalogo.estado(id_estado) ON DELETE RESTRICT
);

-- Tabla de Usuarios en el esquema usuario
CREATE TABLE IF NOT EXISTS usuario.usuario (
  id_usuario UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombres VARCHAR(100) NOT NULL,
  apellidos VARCHAR(100) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  identificacion VARCHAR(10) UNIQUE NOT NULL CHECK (identificacion ~ '^\d{6,10}$'),
  rol_id INTEGER NOT NULL,
  fecha_creacion TIMESTAMP DEFAULT NOW(),
  fecha_modificacion TIMESTAMP,
  CONSTRAINT fk_rol FOREIGN KEY (rol_id) REFERENCES catalogo.rol(id_rol) ON DELETE RESTRICT
);

-- Tabla de Credenciales en el esquema usuario
CREATE TABLE IF NOT EXISTS usuario.credencial (
  id_credencial UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL,
  username VARCHAR(50) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  activo BOOLEAN DEFAULT TRUE,
  fecha_creacion TIMESTAMP DEFAULT NOW(),
  fecha_modificacion TIMESTAMP,
  CONSTRAINT fk_usuario FOREIGN KEY (usuario_id) REFERENCES usuario.usuario(id_usuario) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS usuario.especialidad (
  id_especialidad UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL,
  servicio_id INTEGER NOT NULL,
  activo BOOLEAN DEFAULT TRUE,
  fecha_creacion TIMESTAMP DEFAULT NOW(),
  fecha_modificacion TIMESTAMP,
  CONSTRAINT fk_usuario FOREIGN KEY (usuario_id) REFERENCES usuario.usuario(id_usuario) ON DELETE CASCADE,
  CONSTRAINT fk_servicio FOREIGN KEY (servicio_id) REFERENCES catalogo.servicio(id_servicio) ON DELETE CASCADE
);

-- Tabla de Atención en el esquema servicio
CREATE TABLE IF NOT EXISTS servicio.atencion (
  id_atencion UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  turno_id UUID NOT NULL,
  usuario_id UUID,
  servicio_id INTEGER NOT NULL,
  prioridad INTEGER NOT NULL,
  fecha_creacion TIMESTAMP DEFAULT NOW(),
  fecha_inicio TIMESTAMP,
  fecha_finalizacion TIMESTAMP,
  CONSTRAINT fk_servicio FOREIGN KEY (servicio_id) REFERENCES catalogo.servicio(id_servicio) ON DELETE RESTRICT,
  CONSTRAINT fk_turno FOREIGN KEY (turno_id) REFERENCES turno.turno(id_turno) ON DELETE RESTRICT,
  CONSTRAINT fk_usuario FOREIGN KEY (usuario_id) REFERENCES usuario.usuario(id_usuario) ON DELETE RESTRICT
);

-- Insertar condiciones en la tabla 'catalogo.condicion'
INSERT INTO catalogo.condicion (codigo, descripcion, prioritario, multiplicador) VALUES
(20001, 'Sin condición especial', FALSE, 1.0),
(20002, 'Mayor de 65 años', TRUE, 1.5),
(20003, 'Mujer embarazada', TRUE, 1.5),
(20004, 'Persona con discapacidad', TRUE, 2.0),
(20005, 'Persona con enfermedad crónica', TRUE, 2.0),
(20006, 'Persona con movilidad reducida (temporal)', TRUE, 1.5),
(20007, 'Madre o padre con niño menor a 2 años', TRUE, 1.2),
(20008, 'Veterano de guerra o servicio militar', TRUE, 1.5);

-- Inserciones para la tabla catalogo.estado
INSERT INTO catalogo.estado (codigo, nombre, descripcion) VALUES
  (31001, 'Abierto', 'Turno registrado, atención pendiente.'),
  (31002, 'En Progreso', 'Paciente en atención activa.'),
  (31003, 'Cerrado', 'Atención finalizada con éxito.'),
  (31004, 'Abandonado', 'Paciente no completó la atención.');

-- Inserciones para la tabla catalogo.rol
INSERT INTO catalogo.rol (nombre, codigo)
VALUES 
  ('turnos', 10001),
  ('reportes', 10002),
  ('administracion', 10003);

-- Inserciones para la tabla catalogo.servicio
INSERT INTO catalogo.servicio (codigo, nombre, descripcion) VALUES
  (30001, 'Admisión', 'Registro y recepción de pacientes al ingresar a urgencias.'),
  (30002, 'Triage', 'Evaluación rápida para priorizar la atención según la gravedad.'),
  (30003, 'Consulta', 'Atención médica primaria para diagnóstico y tratamiento.'),
  (30004, 'Imágenes', 'Estudios de diagnóstico por imagen, como rayos X y ecografías.'),
  (30005, 'Laboratorio', 'Análisis clínicos para apoyar el diagnóstico médico.');

-- Insertar registros de pacientes en la tabla 'paciente.paciente'
INSERT INTO paciente.paciente (nombres, apellidos, fecha_nacimiento, telefono, identificacion, condicion_id) VALUES
('Carlos', 'Pérez', '1957-02-15', '3145678901', '123456789', 2), -- Mayor de 65 años
('Ana', 'Gómez', '1995-08-10', '3123456789', '987654321', 3), -- Mujer embarazada
('María', 'Rodríguez', '1960-04-23', '3134567890', '456123789', 2), -- Mayor de 65 años
('Luis', 'Martínez', '1983-12-05', '3148765432', '147258369', 1), -- Sin condición especial
('Carolina', 'López', '1985-07-17', '3161234567', '741963259', 3), -- Mujer embarazada
('José', 'Hernández', '1990-09-09', '3197654321', '258369741', 1), -- Sin condición especial
('Pedro', 'Fernández', '1955-01-22', '3146549870', '369258147', 2), -- Mayor de 65 años
('Laura', 'Sánchez', '2000-11-11', '3151236547', '852963741', 7), -- Madre con niño menor a 2 años
('Raúl', 'García', '1999-06-30', '3176549876', '963258741', 1), -- Sin condición especial
('Isabel', 'Paredes', '1980-03-04', '3198765432', '741852963', 1), -- Sin condición especial
('Carlos', 'Ramírez', '1998-05-20', '3129876543', '258741369', 1), -- Sin condición especial
('Sofía', 'Torres', '1975-02-18', '3163456789', '741258963', 5), -- Persona con enfermedad crónica
('Juliana', 'Vargas', '1992-10-14', '3131234567', '456987123', 3), -- Mujer embarazada
('Felipe', 'Castro', '1993-07-30', '3196543210', '789456123', 1), -- Sin condición especial
('Juan', 'Mendoza', '1985-11-02', '3143217654', '258369147', 6), -- Movilidad reducida temporal
('Lucía', 'Márquez', '1963-01-01', '3175432109', '456123987', 2), -- Mayor de 65 años
('Víctor', 'Díaz', '2003-06-09', '3149876543', '741963258', 1), -- Sin condición especial
('Felicia', 'Jiménez', '1990-04-17', '3194321678', '987654123', 1), -- Sin condición especial
('Martín', 'Suárez', '1980-12-10', '3165432109', '258741963', 2), -- Mayor de 65 años
('Santiago', 'Gutiérrez', '2001-03-15', '3137654321', '654987123', 4); -- Persona con discapacidad

-- Insertar turnos en la tabla 'turno.turno'
INSERT INTO turno.turno (codigo, paciente_id, estado_id, fecha_creacion, fecha_finalizacion)
VALUES
  ('E1', (SELECT id_paciente FROM paciente.paciente WHERE identificacion = '123456789'), 3, '2025-02-10 08:24:46.669391', '2025-02-10 09:07:51.669391'),
  ('E2', (SELECT id_paciente FROM paciente.paciente WHERE identificacion = '987654321'), 3, '2025-02-10 08:34:18.859161', '2025-02-10 09:15:22.669391'),
  ('E3', (SELECT id_paciente FROM paciente.paciente WHERE identificacion = '456123789'), 4, '2025-02-10 08:56:40.521552', '2025-02-10 09:02:00.521552'),
  ('E4', (SELECT id_paciente FROM paciente.paciente WHERE identificacion = '147258369'), 3, '2025-02-10 08:58:08.557839', '2025-02-10 09:48:54.521552'),
  ('E5', (SELECT id_paciente FROM paciente.paciente WHERE identificacion = '741963259'), 3, '2025-02-10 08:58:50.157107', '2025-02-10 10:05:28.521552'),
  ('E6', (SELECT id_paciente FROM paciente.paciente WHERE identificacion = '258369741'), 3, '2025-02-10 09:16:36.578796', '2025-02-10 10:10:21.521552'),
  ('E7', (SELECT id_paciente FROM paciente.paciente WHERE identificacion = '369258147'), 3, '2025-02-10 09:35:16.872779', '2025-02-10 10:26:37.521552');
  
INSERT INTO turno.turno (codigo, paciente_id, estado_id, fecha_creacion)
VALUES
  ('E8', (SELECT id_paciente FROM paciente.paciente WHERE identificacion = '852963741'), 2, '2025-02-10 09:40:46.778596'),
  ('E9', (SELECT id_paciente FROM paciente.paciente WHERE identificacion = '963258741'), 1, '2025-02-10 09:41:49.080095'),
  ('E10', (SELECT id_paciente FROM paciente.paciente WHERE identificacion = '741852963'), 2, '2025-02-10 09:51:45.285302'),
  ('E11', (SELECT id_paciente FROM paciente.paciente WHERE identificacion = '258741369'), 1, '2025-02-10 09:54:26.478401'),
  ('E12', (SELECT id_paciente FROM paciente.paciente WHERE identificacion = '741258963'), 2, '2025-02-10 09:55:43.183114'),
  ('E13', (SELECT id_paciente FROM paciente.paciente WHERE identificacion = '456987123'), 2, '2025-02-10 10:04:51.627350'),
  ('E14', (SELECT id_paciente FROM paciente.paciente WHERE identificacion = '789456123'), 1, '2025-02-10 10:18:57.637886'),
  ('E15', (SELECT id_paciente FROM paciente.paciente WHERE identificacion = '258369147'), 1, '2025-02-10 10:20:28.622986'),
  ('E16', (SELECT id_paciente FROM paciente.paciente WHERE identificacion = '456123987'), 1, '2025-02-10 10:22:43.161283'),
  ('E17', (SELECT id_paciente FROM paciente.paciente WHERE identificacion = '741963258'), 1, '2025-02-10 10:23:59.868850'),
  ('E18', (SELECT id_paciente FROM paciente.paciente WHERE identificacion = '987654123'), 1, '2025-02-10 10:24:52.982521'),
  ('E19', (SELECT id_paciente FROM paciente.paciente WHERE identificacion = '258741963'), 1, '2025-02-10 10:27:45.238126'),
  ('E20', (SELECT id_paciente FROM paciente.paciente WHERE identificacion = '654987123'), 1, '2025-02-10 10:40:33.553229');

-- Inserciones para la tabla usuario.usuario
INSERT INTO usuario.usuario (nombres, apellidos, email, identificacion, rol_id)
VALUES
  -- Administración
  ('Carlos', 'Ramírez', 'carlos.ramirez@example.com', '123456', (SELECT id_rol FROM catalogo.rol WHERE nombre = 'administracion')),
  ('Laura', 'González', 'laura.gonzalez@example.com', '654321', (SELECT id_rol FROM catalogo.rol WHERE nombre = 'administracion')),

  -- Reportes
  ('Ana', 'Martínez', 'ana.martinez@example.com', '789012', (SELECT id_rol FROM catalogo.rol WHERE nombre = 'reportes')),
  ('Javier', 'López', 'javier.lopez@example.com', '890123', (SELECT id_rol FROM catalogo.rol WHERE nombre = 'reportes')),
  ('Miguel', 'Torres', 'miguel.torres@example.com', '901234', (SELECT id_rol FROM catalogo.rol WHERE nombre = 'reportes')),
  ('Emma', 'Johnson', 'emma.johnson@example.com', '234567', (SELECT id_rol FROM catalogo.rol WHERE nombre = 'reportes')),
  ('Sofía', 'Díaz', 'sofia.diaz@example.com', '345678', (SELECT id_rol FROM catalogo.rol WHERE nombre = 'reportes')),

  -- Turnos
  ('Luis', 'Pérez', 'luis.perez@example.com', '456789', (SELECT id_rol FROM catalogo.rol WHERE nombre = 'turnos')),
  
  ('María', 'Fernández', 'maria.fernandez@example.com', '567890', (SELECT id_rol FROM catalogo.rol WHERE nombre = 'turnos')),
  ('John', 'Smith', 'john.smith@example.com', '678901', (SELECT id_rol FROM catalogo.rol WHERE nombre = 'turnos')),
  
  ('Elena', 'Morales', 'elena.morales@example.com', '7890123', (SELECT id_rol FROM catalogo.rol WHERE nombre = 'turnos')),
  ('David', 'Hernández', 'david.hernandez@example.com', '8901234', (SELECT id_rol FROM catalogo.rol WHERE nombre = 'turnos')),
  ('Lucía', 'Walker', 'lucia.walker@example.com', '9012345', (SELECT id_rol FROM catalogo.rol WHERE nombre = 'turnos')),
  ('José', 'Anderson', 'jose.anderson@example.com', '1234567', (SELECT id_rol FROM catalogo.rol WHERE nombre = 'turnos')),
  ('Natalia', 'García', 'natalia.garcia@example.com', '2345678', (SELECT id_rol FROM catalogo.rol WHERE nombre = 'turnos')),
  ('Daniel', 'Thompson', 'daniel.thompson@example.com', '3456789', (SELECT id_rol FROM catalogo.rol WHERE nombre = 'turnos')),
  
  ('Isabel', 'Ruiz', 'isabel.ruiz@example.com', '4567890', (SELECT id_rol FROM catalogo.rol WHERE nombre = 'turnos')),
  
  ('Mateo', 'Clark', 'mateo.clark@example.com', '5678901', (SELECT id_rol FROM catalogo.rol WHERE nombre = 'turnos'));

-- Inserciones para la tabla usuario.credencial
INSERT INTO usuario.credencial (usuario_id, username, password_hash, activo, fecha_creacion)
VALUES
  -- Administración
  ((SELECT id_usuario FROM usuario.usuario WHERE email = 'carlos.ramirez@example.com'), 'carlos.ramirez', '$2b$12$CZnC.s8aoBI8WYD7MuOZP.pLX4sKla9aqVB49S517is.Hoxnu7002', TRUE, NOW()),
  ((SELECT id_usuario FROM usuario.usuario WHERE email = 'laura.gonzalez@example.com'), 'laura.gonzalez', '$2b$12$CZnC.s8aoBI8WYD7MuOZP.pLX4sKla9aqVB49S517is.Hoxnu7002', TRUE, NOW()),

  -- Reportes
  ((SELECT id_usuario FROM usuario.usuario WHERE email = 'ana.martinez@example.com'), 'ana.martinez', '$2b$12$nSt.cpPkBjyTzZ7I2M40neVeJT8gAAGLHGP855SBjd2nWM5lHpcwm', TRUE, NOW()),
  ((SELECT id_usuario FROM usuario.usuario WHERE email = 'javier.lopez@example.com'), 'javier.lopez', '$2b$12$nSt.cpPkBjyTzZ7I2M40neVeJT8gAAGLHGP855SBjd2nWM5lHpcwm', TRUE, NOW()),
  ((SELECT id_usuario FROM usuario.usuario WHERE email = 'miguel.torres@example.com'), 'miguel.torres', '$2b$12$nSt.cpPkBjyTzZ7I2M40neVeJT8gAAGLHGP855SBjd2nWM5lHpcwm', TRUE, NOW()),
  ((SELECT id_usuario FROM usuario.usuario WHERE email = 'emma.johnson@example.com'), 'emma.johnson', '$2b$12$nSt.cpPkBjyTzZ7I2M40neVeJT8gAAGLHGP855SBjd2nWM5lHpcwm', TRUE, NOW()),
  ((SELECT id_usuario FROM usuario.usuario WHERE email = 'sofia.diaz@example.com'), 'sofia.diaz', '$2b$12$nSt.cpPkBjyTzZ7I2M40neVeJT8gAAGLHGP855SBjd2nWM5lHpcwm', TRUE, NOW()),

  -- Turnos
  ((SELECT id_usuario FROM usuario.usuario WHERE email = 'luis.perez@example.com'), 'luis.perez', '$2b$12$8.2LMKk0Odm8Bvsfvt0mK.V3pmTD7JMa3ArbGoT6XPkiSYALM5fLS', TRUE, NOW()),
  ((SELECT id_usuario FROM usuario.usuario WHERE email = 'maria.fernandez@example.com'), 'maria.fernandez', '$2b$12$8.2LMKk0Odm8Bvsfvt0mK.V3pmTD7JMa3ArbGoT6XPkiSYALM5fLS', TRUE, NOW()),
  ((SELECT id_usuario FROM usuario.usuario WHERE email = 'john.smith@example.com'), 'john.smith', '$2b$12$8.2LMKk0Odm8Bvsfvt0mK.V3pmTD7JMa3ArbGoT6XPkiSYALM5fLS', TRUE, NOW()),
  ((SELECT id_usuario FROM usuario.usuario WHERE email = 'elena.morales@example.com'), 'elena.morales', '$2b$12$8.2LMKk0Odm8Bvsfvt0mK.V3pmTD7JMa3ArbGoT6XPkiSYALM5fLS', TRUE, NOW()),
  ((SELECT id_usuario FROM usuario.usuario WHERE email = 'david.hernandez@example.com'), 'david.hernandez', '$2b$12$8.2LMKk0Odm8Bvsfvt0mK.V3pmTD7JMa3ArbGoT6XPkiSYALM5fLS', TRUE, NOW()),
  ((SELECT id_usuario FROM usuario.usuario WHERE email = 'lucia.walker@example.com'), 'lucia.walker', '$2b$12$8.2LMKk0Odm8Bvsfvt0mK.V3pmTD7JMa3ArbGoT6XPkiSYALM5fLS', TRUE, NOW()),
  ((SELECT id_usuario FROM usuario.usuario WHERE email = 'jose.anderson@example.com'), 'jose.anderson', '$2b$12$8.2LMKk0Odm8Bvsfvt0mK.V3pmTD7JMa3ArbGoT6XPkiSYALM5fLS', TRUE, NOW()),
  ((SELECT id_usuario FROM usuario.usuario WHERE email = 'natalia.garcia@example.com'), 'natalia.garcia', '$2b$12$8.2LMKk0Odm8Bvsfvt0mK.V3pmTD7JMa3ArbGoT6XPkiSYALM5fLS', TRUE, NOW()),
  ((SELECT id_usuario FROM usuario.usuario WHERE email = 'daniel.thompson@example.com'), 'daniel.thompson', '$2b$12$8.2LMKk0Odm8Bvsfvt0mK.V3pmTD7JMa3ArbGoT6XPkiSYALM5fLS', TRUE, NOW()),
  ((SELECT id_usuario FROM usuario.usuario WHERE email = 'isabel.ruiz@example.com'), 'isabel.ruiz', '$2b$12$8.2LMKk0Odm8Bvsfvt0mK.V3pmTD7JMa3ArbGoT6XPkiSYALM5fLS', TRUE, NOW()),
  ((SELECT id_usuario FROM usuario.usuario WHERE email = 'mateo.clark@example.com'), 'mateo.clark', '$2b$12$8.2LMKk0Odm8Bvsfvt0mK.V3pmTD7JMa3ArbGoT6XPkiSYALM5fLS', TRUE, NOW());

-- Inserciones de especialidades para la tabla 'usuario.especialidad'
INSERT INTO usuario.especialidad (usuario_id, servicio_id)
VALUES
  -- Admisiones
  ((SELECT id_usuario FROM usuario.usuario WHERE identificacion = '456789'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001)),
  -- Triage
  ((SELECT id_usuario FROM usuario.usuario WHERE identificacion = '567890'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30002)),
  ((SELECT id_usuario FROM usuario.usuario WHERE identificacion = '678901'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30002)), 
  -- Consulta
  ((SELECT id_usuario FROM usuario.usuario WHERE identificacion = '7890123'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30003)),
  ((SELECT id_usuario FROM usuario.usuario WHERE identificacion = '8901234'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30003)),
  ((SELECT id_usuario FROM usuario.usuario WHERE identificacion = '9012345'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30003)),
  ((SELECT id_usuario FROM usuario.usuario WHERE identificacion = '1234567'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30003)),
  ((SELECT id_usuario FROM usuario.usuario WHERE identificacion = '2345678'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30003)),
  ((SELECT id_usuario FROM usuario.usuario WHERE identificacion = '3456789'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30003)), 
  -- Imágenes
  ((SELECT id_usuario FROM usuario.usuario WHERE identificacion = '4567890'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30004)), 
  -- Laboratorio
  ((SELECT id_usuario FROM usuario.usuario WHERE identificacion = '5678901'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30005));

-- Inserciones de atención para la tabla 'servicio.atencion'
INSERT INTO servicio.atencion (turno_id, usuario_id, servicio_id, prioridad, fecha_creacion, fecha_inicio, fecha_finalizacion)
VALUES
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E1'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '456789'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001), 4, '2025-02-10 08:24:46.669391', '2025-02-10 08:24:46.669391', '2025-02-10 08:31:00.669391')
  ,
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E2'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '456789'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001), 2, '2025-02-10 08:34:18.859161', '2025-02-10 08:34:24.669391', '2025-02-10 08:42:12.669391'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E3'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '456789'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001), 1, '2025-02-10 08:56:40.521552', '2025-02-10 08:56:40.521552', '2025-02-10 09:02:00.521552'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E4'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '456789'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001), 3, '2025-02-10 08:58:08.557839', '2025-02-10 09:03:09.521552', '2025-02-10 09:09:34.521552'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E5'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '456789'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001), 4, '2025-02-10 08:58:50.157107', '2025-02-10 09:13:17.521552', '2025-02-10 09:20:31.521552'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E6'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '456789'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001), 4, '2025-02-10 09:16:36.578796', '2025-02-10 09:24:16.521552', '2025-02-10 09:30:47.521552'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E7'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '456789'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001), 4, '2025-02-10 09:35:16.872779', '2025-02-10 09:35:16.872779', '2025-02-10 09:40:38.872779'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E8'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '456789'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001), 3, '2025-02-10 09:40:46.778596', '2025-02-10 09:43:19.872779', '2025-02-10 09:49:11.872779'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E10'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '456789'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001), 2, '2025-02-10 09:51:45.285302', '2025-02-10 09:52:19.872779', '2025-02-10 09:58:58.872779'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E11'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '456789'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001), 3, '2025-02-10 09:54:26.478401', '2025-02-10 10:17:16.872779', '2025-02-10 10:22:48.872779'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E12'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '456789'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001), 2, '2025-02-10 09:55:43.183114', '2025-02-10 10:01:08.872779', '2025-02-10 10:07:21.872779'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E13'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '456789'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001), 2, '2025-02-10 10:04:51.627350', '2025-02-10 10:09:42.872779', '2025-02-10 10:16:07.872779'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E14'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '456789'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001), 2, '2025-02-10 10:18:57.637886', '2025-02-10 10:23:51.872779', '2025-02-10 10:29:59.872779'),

  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E1'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '567890'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30002), 4, '2025-02-10 08:28:28.669391', '2025-02-10 08:28:28.669391', '2025-02-10 08:48:34.669391'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E2'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '678901'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30002), 2, '2025-02-10 08:39:31.669391', '2025-02-10 08:39:31.669391', '2025-02-10 08:56:24.669391'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E4'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '567890'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30002), 3, '2025-02-10 09:07:44.521552', '2025-02-10 09:07:44.521552', '2025-02-10 09:23:23.521552'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E5'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '678901'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30002), 4, '2025-02-10 09:17:21.521552', '2025-02-10 09:17:21.521552', '2025-02-10 09:36:51.521552'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E6'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '567890'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30002), 4, '2025-02-10 09:27:08.521552', '2025-02-10 09:27:08.521552', '2025-02-10 09:43:20.521552'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E7'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '678901'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30002), 4, '2025-02-10 09:39:07.872779', '2025-02-10 09:39:42.521552', '2025-02-10 10:00:22.521552'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E8'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '567890'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30002), 3, '2025-02-10 09:46:48.872779', '2025-02-10 09:46:48.872779', '2025-02-10 10:05:43.872779'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E10'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '678901'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30002), 2, '2025-02-10 09:57:20.872779', '2025-02-10 10:01:44.521552', '2025-02-10 10:19:30.521552'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E12'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '567890'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30002), 2, '2025-02-10 10:04:06.872779', '2025-02-10 10:09:06.872779', '2025-02-10 10:28:36.872779'),

  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E1'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '7890123'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30003), 4, '2025-02-10 08:45:51.669391', '2025-02-10 08:45:51.669391', '2025-02-10 09:07:51.669391'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E2'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '8901234'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30003), 2, '2025-02-10 08:54:24.669391', '2025-02-10 08:54:24.669391', '2025-02-10 09:15:22.669391'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E4'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '9012345'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30003), 3, '2025-02-10 09:21:13.521552', '2025-02-10 09:21:13.521552', '2025-02-10 09:48:54.521552'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E5'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '7890123'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30003), 4, '2025-02-10 09:34:44.521552', '2025-02-10 09:34:44.521552', '2025-02-10 10:05:28.521552'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E6'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '8901234'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30003), 4, '2025-02-10 09:40:22.521552', '2025-02-10 09:40:22.521552', '2025-02-10 10:10:21.521552'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E7'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '9012345'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30003), 4, '2025-02-10 09:57:52.521552', '2025-02-10 09:57:52.521552', '2025-02-10 10:26:37.521552');

INSERT INTO servicio.atencion (turno_id, usuario_id, servicio_id, prioridad, fecha_creacion, fecha_inicio)
VALUES
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E13'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '678901'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30002), 2, '2025-02-10 10:13:35.872779', '2025-02-10 10:22:20.521552'),

  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E8'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '7890123'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30003), 3, '2025-02-10 10:04:10.872779', '2025-02-10 10:08:37.521552'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E10'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '8901234'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30003), 2, '2025-02-10 10:17:00.521552', '2025-02-10 10:17:00.521552'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E12'), (SELECT id_usuario FROM usuario.usuario WHERE identificacion = '9012345'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30003), 2, '2025-02-10 10:26:12.872779', '2025-02-10 10:28:12.521552');

INSERT INTO servicio.atencion (turno_id, servicio_id, prioridad, fecha_creacion)
VALUES
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E9'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001), 4, '2025-02-10 09:41:49.080095'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E15'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001), 3, '2025-02-10 10:20:28.622986'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E16'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001), 2, '2025-02-10 10:22:43.161283'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E17'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001), 3, '2025-02-10 10:23:59.868850'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E18'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001), 4, '2025-02-10 10:24:52.982521'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E19'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001), 4, '2025-02-10 10:27:45.238126'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E20'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30001), 4, '2025-02-10 10:40:33.553229'),

  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E11'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30002), 3, '2025-02-10 10:21:44.872779'),
  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E14'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30002), 2, '2025-02-10 10:28:39.872779'),

  ((SELECT id_turno FROM turno.turno WHERE codigo = 'E13'), (SELECT id_servicio FROM catalogo.servicio WHERE codigo = 30003), 2, '2025-02-10 10:37:31.521552');

