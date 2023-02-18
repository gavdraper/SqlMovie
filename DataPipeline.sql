DROP TABLE IF EXISTS Professions
DROP TABLE IF EXISTS Cast
DROP TABLE IF EXISTS CastProfession
DROP TABLE IF EXISTS CastTitle

--Professions
CREATE TABLE Professions
(
    Id INT NOT NULL IDENTITY,
    Name NVARCHAR(60),
    CONSTRAINT pk_professions_id PRIMARY KEY CLUSTERED(Id),
)

INSERT INTO Professions(Name)
SELECT DISTINCT
    x.[value]
FROM
    master.dbo.[Cast]
    CROSS APPLY STRING_SPLIT(primaryProfession, ',') x

UPDATE Professions
SET Name = REPLACE(
    STUFF( 
        (SELECT' '+ LTRIM(RTRIM(UPPER(SUBSTRING(value, 1,1))+LOWER(SUBSTRING(value, 2, LEN(value)))))
         FROM STRING_SPLIT([Name], '_')
         FOR XML PATH('')
         ), 1, 1, ''
   ), ' ', '') 

--Cast
CREATE TABLE Cast
(
    Id INT NOT NULL,
    Name NVARCHAR(150),
    BirthYear SMALLINT,
    DeathYear SMALLINT,
    CONSTRAINT pk_cast_id PRIMARY KEY CLUSTERED(Id),
)

INSERT INTO Cast
SELECT 
    CAST(REPLACE(nconst,'nm','') AS INT) Id,
    CAST(primaryName AS NVARCHAR(150)) [Name],
    CAST(REPLACE(birthYear,'\N','') AS SMALLINT) BirthYear,
    CAST(REPLACE(deathYear,'\N','') AS SMALLINT) DeathYear
FROM
    master.dbo.[Cast]

UPDATE Cast SET DeathYear = NULL WHERE DeathYear =0
UPDATE CAST SET BirthYear = NULL WHERE BirthYear = 0


SELECT TOP 100 * FROM master.dbo.Cast

--CastProfessions
CREATE TABLE CastProfession
(
    CastId INT,
    ProfessionId INT
)
INSERT INTO CastProfession
SELECT 
    CastId,
   p.Id ProfessionId
FROM
(
    SELECT 
        CAST(REPLACE(nconst,'nm','') AS INT) CastId,
        x.VALUE Profession
    FROM Master.Dbo.Cast
        CROSS APPLY STRING_SPLIT(primaryProfession, ',') x
)x
INNER JOIN Professions p ON p.Name = REPLACE(
    STUFF( 
        (SELECT' '+ LTRIM(RTRIM(UPPER(SUBSTRING(value, 1,1))+LOWER(SUBSTRING(value, 2, LEN(value)))))
         FROM STRING_SPLIT([profession], '_')
         FOR XML PATH('')
         ), 1, 1, ''
   ), ' ', '') 


--CastProfessions
CREATE TABLE CastTitle
(
    CastId INT,
    TitleId INT
)

INSERT INTO CastTitle
SELECT
    CAST(REPLACE(nconst,'nm','') AS INT) CastId,
    CAST(REPLACE(REPLACE(x.VALUE,'tt',''),'\N','') AS INT) TitleId
 FROM master.dbo.Cast
    CROSS APPLY STRING_SPLIT(knownForTitles,',') x
