USE [CHARACTER_01_DBF]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_item_count_guild_bank]    Script Date: 02/05/2020 17:56:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fn_item_count_guild_bank] (
	@im_idGuild		CHAR(7),
	@iserverindex	CHAR(2),
	@idItem			CHAR(10)
)
RETURNS INT
AS
BEGIN
		/*
			L'inventaire du joueur est represente de la sorte
			Exemples
			1)
				0,23,0,0,,1,0,7200000,0,0,0,-1776504854,0,0,0,0,0/$
				23 == ID ITEM (Wooden Sword)
				1 == Nombre de Wooden Sword
			2)
				43,2534,0,0,,99,0,-1,0,0,0,1812566099,0,0,0,0,0/$
				2534 == ID ITEM (popo mana)
				99 == Nomre de popo mana
			
			Chaque case de l'inventaire et separer par un '/', la string finit toujours par '$'
		*/
		DECLARE @count INT;
		DECLARE @item VARCHAR(500);
		DECLARE @itemCount INT;

		SET @count = 0;
		SET @itemCount = 0;

		-- Get item inventory
		DECLARE @inventory VARCHAR(500);
		DECLARE @line_inv VARCHAR(500);

		-- Recuperation de l'inventaire brute du joueur
		SET @inventory = (SELECT m_GuildBank FROM dbo.GUILD_BANK_TBL WHERE m_idGuild=@im_idGuild AND serverindex=@iserverindex);

		-- Loop sur l'inventaire avec un split sur '/'
		DECLARE curseur_inventory
		CURSOR FOR
			SELECT * FROM dbo.my_split_string_sep(@inventory, '/')   -- permet de split sur '/' 
			OPEN curseur_inventory
			FETCH curseur_inventory INTO @line_inv

			-- loop sur chaque element separer par `my_split_string_sep`
			WHILE @@FETCH_STATUS = 0
				BEGIN
					-- Check si `idItem` est present dans l'inventaire du joueur
					SET @item = (SELECT * FROM (
									SELECT ROW_NUMBER() OVER (ORDER BY Name desc) AS Rownumber
									FROM dbo.my_split_string_sep(@line_inv, ',')
									WHERE (Name != '$' AND Name=@idItem)
								) results
								WHERE results.Rownumber = 1);					
					IF @item = '1' -- L'item est present
						BEGIN
							-- Recuperation du nombre d'item present dans l'inventaire
							SET @itemCount = (SELECT Name FROM (
								SELECT *, ROW_NUMBER() OVER (ORDER BY ( SELECT   NULL)) AS Rownumber
									FROM dbo.my_split_string_sep(@line_inv, ',')
									WHERE (Name != '$')
							) results WHERE results.Rownumber = 6);
							SET @count = @count + @itemCount
						END    
					FETCH curseur_inventory INTO @line_inv
				END

		CLOSE curseur_inventory
		DEALLOCATE curseur_inventory

		RETURN @count;
END