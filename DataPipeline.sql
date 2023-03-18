--Professions
DROP TABLE IF EXISTS Profession
CREATE TABLE Profession
(
    Id INT NOT NULL IDENTITY,
    Name NVARCHAR(60),
    CONSTRAINT pk_profession_id PRIMARY KEY CLUSTERED(Id),
)

INSERT INTO Profession(Name)
SELECT DISTINCT
    x.[value]
FROM
    [raw].[Person]
    CROSS APPLY STRING_SPLIT(primaryProfession, ',') x

UPDATE Profession
SET Name = REPLACE(
    STUFF( 
        (SELECT' '+ LTRIM(RTRIM(UPPER(SUBSTRING(value, 1,1))+LOWER(SUBSTRING(value, 2, LEN(value)))))
         FROM STRING_SPLIT([Name], '_')
         FOR XML PATH('')
         ), 1, 1, ''
   ), ' ', '') 

--Cast
DROP TABLE IF EXISTS Person
CREATE TABLE Person
(
    Id INT NOT NULL,
    Name NVARCHAR(150),
    BirthYear SMALLINT,
    DeathYear SMALLINT,
    CONSTRAINT pk_cast_id PRIMARY KEY CLUSTERED(Id),
)

INSERT INTO Person
SELECT 
    CAST(REPLACE(nconst,'nm','') AS INT) Id,
    CAST(primaryName AS NVARCHAR(150)) [Name],
    CAST(REPLACE(birthYear,'\N','') AS SMALLINT) BirthYear,
    CAST(REPLACE(deathYear,'\N','') AS SMALLINT) DeathYear
FROM
    [raw].[Person]

UPDATE Person SET DeathYear = NULL WHERE DeathYear =0
UPDATE Person SET BirthYear = NULL WHERE BirthYear = 0


--CastProfessions
DROP TABLE IF EXISTS PersonProfession
CREATE TABLE PersonProfession
(
    PersonId INT,
    ProfessionId INT
)
INSERT INTO PersonProfession
SELECT 
    PersonId,
   p.Id ProfessionId
FROM
(
    SELECT 
        CAST(REPLACE(nconst,'nm','') AS INT) PersonId,
        x.VALUE Profession
    FROM raw.Person
        CROSS APPLY STRING_SPLIT(primaryProfession, ',') x
)x
INNER JOIN Profession p ON p.Name = REPLACE(
    STUFF( 
        (SELECT' '+ LTRIM(RTRIM(UPPER(SUBSTRING(value, 1,1))+LOWER(SUBSTRING(value, 2, LEN(value)))))
         FROM STRING_SPLIT([profession], '_')
         FOR XML PATH('')
         ), 1, 1, ''
   ), ' ', '') 


--TitleType
DROP TABLE IF EXISTS TitleType
CREATE TABLE TitleType
(
    Id INT NOT NULL IDENTITY,
    [Name] NVARCHAR(40),
    CONSTRAINT pk_Title_Type PRIMARY KEY CLUSTERED(Id),
)
INSERT INTO TitleType(Name)
SELECT DISTINCT TitleType FROM Raw.Title

--Genre
DROP TABLE IF EXISTS Genre
CREATE TABLE Genre
(
    Id INT NOT NULL IDENTITY,
    [Name] NVARCHAR(50),
    CONSTRAINT pk_Genre PRIMARY KEY CLUSTERED(Id)
)
INSERT INTO Genre(Name)
SELECT DISTINCT
    x.Value
FROM Raw.Title
CROSS APPLY STRING_SPLIT(Genres,',') x
WHERE x.[value] <> '\N'


--Titles
DROP TABLE IF EXISTS Title
CREATE TABLE Title
(
    Id INT NOT NULL,
    TitleTypeId INT,
    [Name] NVARCHAR(500),
    OriginalName NVARCHAR(500),
    IsAdult BIT,
    StartYear SMALLINT,
    EndYear SMALLINT,
    RunTimeMinutes INT
)
INSERT INTO Title
SELECT 
    CAST(REPLACE(tconst,'tt','') AS INT) Id ,
    tt.Id TitleTypeId,
    PrimaryTitle Name,
    OriginalTitle [OriginalName],
    CAST(IsAdult AS BIT) IsAdult,
    CASE WHEN StartYear = '\N' THEN NULL ELSE CAST(StartYear AS SMALLINT) END StartYear,
    CASE WHEN EndYEar = '\N' THEN NULL ELSE CAST(EndYear AS SMALLINT) END EndYear,
    CASE WHEN RuntimeMinutes = '\N' THEN NULL ELSE CAST(RuntimeMinutes AS INT) END RuntimeMinutes
FROM Raw.Title    
LEFT JOIN TitleType tt ON tt.Name = Raw.Title.TitleType

--TitleGenre
DROP TABLE IF EXISTS TitleGenre
CREATE TABLE TitleGenre
(
    TitleId INT,
    GenreId INT
)
INSERT INTO TitleGenre
SELECT
    CAST(REPLACE(tconst,'tt','') AS INT) TitleId ,
    g.Id GenreId
FROM Raw.Title
    CROSS APPLY STRING_SPLIT(Genres,',') x
    LEFT JOIN Genre g ON g.Name = x.Value
WHERE Genres <> '\N'

--CastTitle
DROP TABLE IF EXISTS Cast
CREATE TABLE Cast
(
    PersonId INT,
    TitleId INT,
    Category NVARCHAR(80),
    Job NVARCHAR(650),
    Characters NVARCHAR(4000)
)
INSERT INTO Cast
SELECT 
    CAST(REPLACE(nconst,'nm','') AS INT) PersonId ,
    CAST(REPLACE(tconst,'tt','') AS INT) TitleId ,
    CASE WHEN Category = '\N' THEN NULL ELSE category END [Category],
    CASE WHEN Job = '\N' THEN NULL ELSE job END [Job],
    CASE WHEN Characters = '\N' THEN NULL ELSE characters END [Characters]
FROM    
    Raw.Cast

--Episodes
DROP TABLE Episode
SELECT 
   CAST(REPLACE(tconst,'tt','') AS INT) EpisodeId ,
   CAST(REPLACE(parenttconst,'tt','') AS INT) TitleId ,
   CAST(CASE WHEN SeasonNumber = '\N' THEN 0 ELSE SeasonNumber END AS SMALLINT) [SeasonNumber], 
   CAST(CASE WHEN EpisodeNumber = '\N' THEN 0 ELSE EpisodeNumber END AS INT) [EpisodeNumber]
INTO Episode   
FROM Raw.Episode

--Ratings
DROP TABLE IF EXISTS Rating
CREATE TABLE Rating
(
    TitleId INT,
    AverageRating INT,
    TotalVotes INT
)
INSERT INTO Rating
SELECT 
    CAST(REPLACE(tconst,'tt','') AS INT) TitleId ,
    AverageRating,
    NumVotes
FROM    
    Raw.Rating



/*    Keys and Indexes */
CREATE CLUSTERED INDEX ndx_cast_person_title ON cast(PersonId, TitleId)
CREATE NONCLUSTERED INDEX ndx_cast_title ON Cast(TitleId)
CREATE CLUSTERED INDEX ndx_personprofession_person ON PersonProfession(PersonId)
CREATE CLUSTERED INDEX ndx_title_id ON Title(Id)
CREATE CLUSTERED INDEX ndx_titlegenre_title ON TitleGenre(TitleId,GenreId)
CREATE CLUSTERED INDEX ndx_episode_id ON Episode(EpisodeId)
CREATE  INDEX ndx_episode_title ON Episode(TitleId)