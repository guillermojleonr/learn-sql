------------------------------------------
			-- FUNCTIONS
------------------------------------------


CREATE FUNCTION Calculate_national_id_verifier (rut INT) -- NO funciona correctamente por motivos desconocidos.
	RETURNS CHAR(1)
BEGIN
	DECLARE digito INT;
	DECLARE contador INT;
	DECLARE multiplo INT;
	DECLARE acumulador INT;
	DECLARE ret CHAR;
	SET contador = 2;
	SET acumulador = 0;
   WHILE rut <> 0 DO
      SET multiplo = (rut % 10) * contador; 
      SET acumulador = acumulador + multiplo;
      SET rut = rut / 10;
      SET contador = contador + 1; -- 3
      IF (contador = 8) THEN
          SET contador = 2;
      END IF;
   END WHILE;
   SET digito = 11 - (acumulador % 11);
   IF (digito = 10) THEN
      RETURN ('K');
   ELSEIF (digito = 11) THEN
      RETURN ('0');
   ELSE
   	  RETURN (digito);
   END IF;
END;


SELECT Calculate_national_id_verifier (3066256)
DROP FUNCTION Calculate_national_id_verifier 


-- Para SQL Server - TSQL - funciona correctamente.
  CREATE FUNCTION [dbo].[CalculaDigitoRut] 
(
    @rut int
)
RETURNS char(1)
AS
BEGIN
   DECLARE @digito int
   DECLARE @contador int
   DECLARE @multiplo int
   DECLARE @acumulador int
   DECLARE @ret char
   set @contador = 2
   set @acumulador = 0
   while (@rut <> 0)
   begin
      set @multiplo = (@Rut % 10) * @contador
      set @acumulador = @acumulador + @multiplo 
      set @rut = @rut / 10 
      set @contador = @contador + 1 
      if (@contador = 8) 
         set @contador = 2 
   end
   set @digito = 11 - (@acumulador % 11) 
   if (@digito = 10)
      return ('K')
   if (@digito = 11)
      return ('0')
   return (@digito)
END