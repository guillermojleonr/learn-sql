----------------------------------------
-- SQL Server Sample Project
----------------------------------------


----------------------------------------
--    Creaci�n de la Base de Datos    --
----------------------------------------
CREATE DATABASE Academia;




---------------------------------
--    Usar la Base de Datos    --
---------------------------------
USE Academia;




/*-----------------------------------------
Tabla de Paises
	-- Restricci�n de Nulabilidad
	-- Restricci�n de Chequeo de Valores
	-- Restricci�n de Unicidad
	-- Llave Primaria
------------------------------------------*/
CREATE TABLE Paises
(
  --Creamos la Restricci�n en la misma definic�n de la Columna
  Cod_Pais char(2) PRIMARY KEY CHECK (LEN(Cod_Pais)=2), 
  Nombre varchar(50) NOT NULL,							
  Cod_ISO3 char(3) NOT NULL UNIQUE CHECK (LEN(Cod_ISO3)=3),
  Cod_Telefonico smallint
);





/*-----------------------------------------
Tabla de Estados
	-- Llave For�nea
	   -- Acciones sobre la Relaci�n
------------------------------------------*/
CREATE TABLE Estados
(
  Cod_Estado char(2) PRIMARY KEY,
  --Creamos la Restricci�n como un Objeto separado y le damos nombre.
  CONSTRAINT Len_Estado CHECK (LEN(Cod_Estado)=2), 
  Cod_Pais char(2) FOREIGN KEY REFERENCES Paises (Cod_Pais)
                   ON UPDATE CASCADE
                   ON DELETE CASCADE,
  Nombre varchar(50) NOT NULL,
  Cod_Telefonico smallint
);





/*-----------------------------------------
Tabla de Academias
	-- Campos Auto-Generados
------------------------------------------*/
CREATE TABLE Academias
(
  Cod_Acad tinyint IDENTITY (1,1) PRIMARY KEY,
  Nombre varchar(50) NOT NULL,
  Fec_Fundacion Date NOT NULL,
  Numero varchar(10) NOT NULL,
  Calle varchar(30) NOT NULL,
  Ciudad varchar(30) NOT NULL,
  Estado char(2) NULL 
  --Si deseamos Agregar un Nombre 
	CONSTRAINT FK_Academias_Estados FOREIGN KEY  
									REFERENCES Estados (Cod_Estado)
										ON UPDATE CASCADE
										ON DELETE SET NULL,
  Cod_Postal varchar(10)
);





/*---------------------------------------------
Tabla de Departamentos
	-- Referencia a una tabla que no existe
---------------------------------------------*/
CREATE TABLE Departamentos
(
  Cod_Dpto Smallint IDENTITY (1,1) PRIMARY KEY,
  Academia tinyint NOT NULL 
			FOREIGN KEY REFERENCES Academias (Cod_Acad)
				ON UPDATE CASCADE
				ON DELETE CASCADE,
  Nombre varchar(30) NOT NULL,
  Director smallint  NOT NULL DEFAULT (-1)
			--La Tabla Profesores aun no existe
			FOREIGN KEY REFERENCES Profesores (Cod_Prof) 
				ON UPDATE NO ACTION
				ON DELETE NO ACTION,
  Fec_Inicio Date NOT NULL
);





/*-----------------------------------------
Tabla de Profesores
------------------------------------------*/
CREATE TABLE Profesores
(
  Cod_Prof smallint IDENTITY (1,1) PRIMARY KEY,
  SSN varchar(11) UNIQUE CHECK (LEN(SSN)=11),
  Nombre varchar(30) NOT NULL,
  Apellido varchar(30) NOT NULL,
  Numero varchar(10) NOT NULL,
  Calle varchar(30) NOT NULL,
  Ciudad varchar(30) NOT NULL,
  Estado char(2) FOREIGN KEY REFERENCES Estados (Cod_Estado)
                   ON UPDATE CASCADE
                   ON DELETE SET NULL,
  Cod_Postal varchar(10) NOT NULL,
  Telefono varchar(15),
  Sueldo money DEFAULT (0)
);





/*---------------------------------------------
Tabla de Departamentos
	-- Ahora si existe la Referencia
---------------------------------------------*/
CREATE TABLE Departamentos
(
  Cod_Dpto Smallint IDENTITY (1,1) PRIMARY KEY,
  Academia tinyint NOT NULL 
			FOREIGN KEY REFERENCES Academias (Cod_Acad)
				ON UPDATE CASCADE
				ON DELETE CASCADE,
  Nombre varchar(30) NOT NULL,
  Director smallint  NOT NULL DEFAULT (-1)
			FOREIGN KEY REFERENCES Profesores (Cod_Prof)
				ON UPDATE NO ACTION
				ON DELETE NO ACTION,
  Fec_Inicio Date NOT NULL
);




/*---------------------------------------------------
Tabla de Relaci�n entre Departamentos y Profesores
   --Falla en la Creaci�n de la Llave For�nea 
     con Departamentos
---------------------------------------------------*/
CREATE TABLE Dptos_Profesores
(
  Cod_Dpto Smallint NOT NULL
	FOREIGN KEY REFERENCES Departamentos (Cod_Dpto)
	    ON UPDATE CASCADE
		ON DELETE CASCADE,
  Cod_Prof smallint NOT NULL
	FOREIGN KEY REFERENCES Profesores (Cod_Prof)
	    ON UPDATE CASCADE
		ON DELETE CASCADE
);





/*---------------------------------------------------
   Eliminamos los eventos en Cascada
---------------------------------------------------*/
CREATE TABLE Dptos_Profesores
(
  Cod_Dpto Smallint NOT NULL
	FOREIGN KEY REFERENCES Departamentos (Cod_Dpto),
  Cod_Prof smallint NOT NULL
	FOREIGN KEY REFERENCES Profesores (Cod_Prof)
	    ON UPDATE CASCADE
		ON DELETE CASCADE
);













/*-----------------------------------------------------
   Manejamos el Comportamiento deseado con un trigger
-----------------------------------------------------*/
CREATE TRIGGER trg_Borrar_Dptos_Profesores
   ON  Departamentos
   FOR DELETE --->Borrado de Departamentos
AS 
BEGIN

	DELETE	Dptos_Profesores
	WHERE	Cod_Dpto IN (
						SELECT	Cod_Dpto
						FROM	DELETED
						);
END;






/*--------------------------------------------
       La situaci�n de modificaci�n 
       es m�s complicada 
--------------------------------------------*/
CREATE TRIGGER trg_Modificar_Dptos_Profesores
   ON  Departamentos
   FOR UPDATE --->Modificaci�n de Departamentos
AS 
BEGIN

	UPDATE	Dptos_Profesores
	SET		Cod_Dpto = A.Cod_Nuevo -->Actualicemos al Nuevo C�digo
	FROM	(
				SELECT	D.Cod_Dpto AS Cod_Anterior,
						I.Cod_Dpto AS Cod_Nuevo
				FROM	DELETED D ---> Datos Antes de la Modificaci�n
						JOIN 
						INSERTED I ---> Datos Despu�s de la Modificaci�n 
						ON 
						D.Cod_Dpto = I.Cod_Dpto -->Del mismo Departamento
			) A
	WHERE	Cod_Dpto = A.Cod_Anterior; -->Las filas que tengan el C�digo Anterior de cada Dpto
END;






/*---------------------------------------------------
Tabla de Materias
   --Falla en la Creaci�n de la Restricci�n.
     No se puede usar un campo del mismo registro 
---------------------------------------------------*/
CREATE TABLE Materias
(
  Cod_Materia Smallint IDENTITY (1,1) PRIMARY KEY,
  Nombre varchar(30) NOT NULL,
  Electiva bit NOT NULL DEFAULT (0),
  Peso tinyint CHECK ( Peso > 0 AND 
					   Peso < (CASE Electiva 
					              WHEN 0 THEN 6 
								  ELSE 2 
							   END)
				     )
);






/*---------------------------------------------------
  Creamos la tabla sin la Restricci�n
---------------------------------------------------*/
CREATE TABLE Materias
(
  Cod_Materia Smallint IDENTITY (1,1) PRIMARY KEY,
  Nombre varchar(30) NOT NULL,
  Electiva bit NOT NULL DEFAULT (0),
  Peso tinyint NOT NULL DEFAULT (1) CHECK (Peso > 0) 
  --Una Restricci�n
);




/*---------------------------------------------------
  Creamos la Restricci�n, pero a nivel de la Tabla
  y no del campo Peso
---------------------------------------------------*/
ALTER TABLE Materias
 ADD CONSTRAINT CheckPesoMateria
	CHECK ( Peso <= (CASE Electiva WHEN 0 THEN 6 ELSE 2 END));






/*---------------------------------------------------
Tabla de Cursos
	--Campo Calculado
---------------------------------------------------*/
CREATE TABLE Cursos
(
  Cod_Curso int IDENTITY (1,1) PRIMARY KEY,
  Cod_Prof smallint
	FOREIGN KEY REFERENCES Profesores (Cod_Prof)
		ON DELETE SET NULL,
  Cod_Materia Smallint
    FOREIGN KEY REFERENCES Materias (Cod_Materia)
		ON DELETE CASCADE,
  Aula int NOT NULL,
  Hora_Inicio time NOT NULL,
  Hora_Fin time NOT NULL,
  Duracion_Mins AS (DATEDIFF(MINUTE, Hora_Inicio, Hora_Fin)) 
  --No se define el Tipo del Dato
);





/*---------------------------------------------------
  Creamos Restricci�n a nivel de la Tabla
---------------------------------------------------*/
ALTER TABLE Cursos
 ADD CONSTRAINT CheckHoras
	CHECK (Hora_Inicio < Hora_Fin);






/*---------------------------------------------------
  Agreguemos un nuevo campo a la Tabla
---------------------------------------------------*/
ALTER TABLE Cursos
  ADD Activo BIT NOT NULL DEFAULT (1);






/*---------------------------------------------------
  Funci�n para chequear si un Aula est� ocupada
---------------------------------------------------*/
CREATE FUNCTION fn_Aula_Ocupada 
(
	----Par�metros:
	-- Datos del Registro que se est� Insertando
	@ID  INT, 
	@Aula INT, 
	@Inicio Time, 
	@Fin Time
)
RETURNS bit --La funci�n retornar� un bit (0 / 1)
AS
BEGIN
	DECLARE @AulaOcupada BIT = 0; --Asumamos de una vez que el Aula NO est� ocupada

	-- EXISTS (conjunto) devuelve 0 si el conjunto es vac�o y 1 si existe almenos 1 elemento.
	--    En realidad el SELECT que define al conjunto, NO se ejecuta, simplemente se revisa
	--	  si existe almenos 1 registro que cumpla con las condiciones suministradas
	IF EXISTS	(
				SELECT	*						-- Seleccionemos
				FROM	Cursos					-- los cursos que cumplan con las siguientes condiciones:
				WHERE	Cod_Curso <> @ID AND	-- 1) No es el curso que estamos tratando de Insertar
						Aula = @Aula AND		-- 2) El curso se dicta en la misma Aula
						Activo = 1 AND			-- 3) y es un curso Activo
						(
							-- 4) El curso se est� dictando en el momento que inicia el curso que queremos Insertar
							@Inicio BETWEEN Hora_Inicio AND Hora_Fin OR
							-- 5) El curso se est� dictando en el momento que finaliza el curso que queremos Insertar
							@Fin BETWEEN Hora_Inicio AND Hora_Fin OR
							-- 5) El curso se est� dictando mintras se debe dictar el curso que queremos Insertar
							(@Inicio <= Hora_Inicio AND @Fin >= Hora_Fin)
						)
				)
		SET @AulaOcupada = 1; --Si existe alg�n curso que cumpla las condiciones establecidas,
							  --entonces el aula est� ocupada.

	RETURN @AulaOcupada; -- Retornemos el valor resultante.
END;





/*-----------------------------------------------------------
  Creamos la Restricci�n
  --S�lo se pueden crear cursos, si el aula est� disponible
-----------------------------------------------------------*/
ALTER TABLE Cursos
 ADD CONSTRAINT CheckAulaOcupada
	CHECK (dbo.fn_Aula_Ocupada (Cod_Curso,Aula,Hora_Inicio,Hora_Fin)=0);





/*---------------------------------------------------
Tabla de Libros
---------------------------------------------------*/
CREATE TABLE Libros
(
  Cod_Libro int IDENTITY (1,1) PRIMARY KEY,
  ISBN char(13) NOT NULL UNIQUE CHECK (LEN(ISBN)=13 AND ISNUMERIC(ISBN)=1),
  Titulo varchar(100) NOT NULL,
  Autor varchar(100) NOT NULL,
  A�o smallint,
  Edicion char(3),
  Editorial varchar(100),
  Paginas smallint
);





/*---------------------------------------------------
Tabla de Relaci�n Cursos y Libros
---------------------------------------------------*/
CREATE TABLE Cursos_Libros
(
  Cod_Curso int NOT NULL
		FOREIGN KEY REFERENCES Cursos (Cod_Curso)
		    ON UPDATE CASCADE
			ON DELETE CASCADE,
  Cod_Libro int NOT NULL
		FOREIGN KEY REFERENCES Libros (Cod_Libro)
		    ON UPDATE CASCADE
			ON DELETE CASCADE
);





/*---------------------------------------------------
Tabla de Alumnos
---------------------------------------------------*/
CREATE TABLE Alumnos
(
  Cod_Alumno int IDENTITY (1,1) PRIMARY KEY,
  SSN varchar(11) UNIQUE CHECK (LEN(SSN)=11),
  Nombre varchar(30) NOT NULL,
  Apellido varchar(30) NOT NULL,
  Numero varchar(10) NOT NULL,
  Calle varchar(30) NOT NULL,
  Ciudad varchar(30) NOT NULL,
  Estado char(2) FOREIGN KEY REFERENCES Estados (Cod_Estado)
                   ON UPDATE CASCADE
                   ON DELETE SET NULL,
  Cod_Postal varchar(10) NOT NULL,
  Telefono varchar(15),
  Fecha_Nac Date,
  Lugar_Nac varchar(50)
);





/*---------------------------------------------------
Tabla de Relaci�n Cursos y Alumnos
	--Llave Primaria Compuesta
---------------------------------------------------*/
CREATE TABLE Cursos_Alumnos
(
  Cod_Alumno int
	FOREIGN KEY REFERENCES Alumnos (Cod_Alumno)
                   ON UPDATE CASCADE
                   ON DELETE CASCADE,  
  Cod_Curso int
	FOREIGN KEY REFERENCES Cursos (Cod_Curso)
                   ON UPDATE CASCADE
                   ON DELETE CASCADE,  
  PRIMARY KEY (Cod_Alumno, Cod_Curso),
  Calificacion tinyint,
  Fecha_Insc Date,
  Ausencias tinyint
);




-----Creemos el Diagrama-----


