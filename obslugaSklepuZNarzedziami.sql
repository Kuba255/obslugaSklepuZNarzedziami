DROP DATABASE IF EXISTS obs³uga_sklepu_z_narzêdziami;
GO
CREATE DATABASE obs³uga_sklepu_z_narzêdziami;
GO

USE obs³uga_sklepu_z_narzêdziami;
GO

DROP TABLE IF EXISTS dbo.StanSklepu;
GO
CREATE TABLE dbo.StanSklepu (
	IDNarzêdzia INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	Nazwa NVARCHAR(100) NOT NULL,
	IloœæJednostkowa NVARCHAR(15) NOT NULL,
	CenaNarzêdzia MONEY NOT NULL,
	StanMagazynu FLOAT NOT NULL,
	StanMinimalny FLOAT NOT NULL,
	Kategoria NVARCHAR(30) NULL,
	Marka NVARCHAR(30) NULL,
	VAT FLOAT NOT NULL
);
GO

DROP TABLE IF EXISTS dbo.Dostawcy
GO
CREATE TABLE dbo.Dostawcy(
	IDDostawcy INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	NazwaDostawcy NVARCHAR(40) NOT NULL,
	NumerDomu NVARCHAR(40) NOT NULL,
	Ulica NVARCHAR(30) NOT NULL,
	Miasto NVARCHAR(30) NOT NULL,
	KodPocztowy NVARCHAR(10) NOT NULL,
	Kraj NVARCHAR(15) NULL,
	NumerTelefonu NVARCHAR(15) NOT NULL
);
GO

DROP TABLE IF EXISTS dbo.Dostawy
GO
CREATE TABLE dbo.Dostawy(
	IDDostawy INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	IDDostawcy INT NOT NULL,
	IDPracownika INT NOT NULL,
	CenaDostawy MONEY NOT NULL,
	DataZlecenia DATETIME NOT NULL,
	DataDostawy DATETIME NOT NULL
);
GO

DROP TABLE IF EXISTS dbo.Pracownicy
GO
CREATE TABLE dbo.Pracownicy(
	IDPracownika INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	Imiê NVARCHAR(15) NOT NULL,
	Nazwisko NVARCHAR(20) NOT NULL,
	NumerDomu NVARCHAR(10) NOT NULL,
	Ulica NVARCHAR(30) NOT NULL,
	Miasto NVARCHAR(30) NOT NULL,
	KodPocztowy NVARCHAR(10) NOT NULL,
	Kraj NVARCHAR(15) NOT NULL,
	NumerTelefonu NVARCHAR(15) NOT NULL,
	DataUrodzenia DATETIME NOT NULL,
	DataPrzyjêcia DATETIME NOT NULL,
	Stanowisko NVARCHAR(15) NOT NULL
);
GO

DROP TABLE IF EXISTS dbo.Zamówienia
GO
CREATE TABLE dbo.Zamówienia(
	IDZamówienia INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	IDNarzêdzia INT NOT NULL,
	IDPracownika INT NOT NULL,
	IDKlienta INT NOT NULL,
	CenaZamówienia MONEY NOT NULL,
	Iloœæ FLOAT NOT NULL,
	DataZamówienia DATETIME NOT NULL
);
GO

DROP TABLE IF EXISTS dbo.Klient
GO
CREATE TABLE dbo.Klient(
	IDKlienta INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	ImiêKlienta NVARCHAR(15) NOT NULL,
	NazwiskoKlienta NVARCHAR(20) NOT NULL,
	NumerDomu NVARCHAR(10) NOT NULL,
	Ulica NVARCHAR(30) NOT NULL,
	Miasto NVARCHAR(30) NOT NULL,
	KodPocztowy NVARCHAR(10) NOT NULL,
	Kraj NVARCHAR(15) NOT NULL,
	Telefon NVARCHAR(15) NOT NULL
);
GO

DROP TABLE IF EXISTS dbo.PozycjeDostawy
GO
CREATE TABLE dbo.PozycjeDostawy(
	IDDostawy INT NOT NULL,
	IDNarzêdzia INT NOT NULL,
	CenaJednostkowa MONEY NOT NULL,
	IloœæDostawy FLOAT NOT NULL
);
GO

ALTER TABLE Dostawy
ADD CONSTRAINT FK_IDDostawcyDostawy FOREIGN KEY (IDDostawcy) REFERENCES Dostawcy(IDDostawcy),
	CONSTRAINT FK_IDPracownikaDostawy FOREIGN KEY (IDPracownika) REFERENCES Pracownicy(IDPracownika);
GO

ALTER TABLE Zamówienia
ADD CONSTRAINT FK_IDNarzêdziaZamówienia FOREIGN KEY (IDNarzêdzia) REFERENCES StanSklepu(IDNarzêdzia),
	CONSTRAINT FK_IDPracownikaZamówienia FOREIGN KEY (IDPracownika) REFERENCES Pracownicy(IDPracownika),
	CONSTRAINT FK_IDKlientaZamówienia FOREIGN KEY (IDKlienta) REFERENCES Klient(IDKlienta);
GO

ALTER TABLE PozycjeDostawy
ADD CONSTRAINT FK_IDDostawyPozZam FOREIGN KEY (IDDostawy) REFERENCES Dostawy(IDDostawy),
	CONSTRAINT FK_IDNarzêdziaPozZam FOREIGN KEY (IDNarzêdzia) REFERENCES StanSklepu(IDNarzêdzia);
GO


ALTER TABLE StanSklepu
ADD CONSTRAINT CHK_CenaNieUjem CHECK (CenaNarzêdzia > 0),
	CONSTRAINT CHK_StanMagNieUjem CHECK (StanMagazynu >= 0),
	CONSTRAINT CHK_StanMinNieUjem CHECK (StanMinimalny > 0),
	CONSTRAINT CHK_VatNieUjem CHECK (VAT > 0);
GO

ALTER TABLE Dostawy
ADD CONSTRAINT CHK_CenaDostNieUjem CHECK (CenaDostawy > 0),
	CONSTRAINT CHK_DataZlecenia CHECK (DataZlecenia <= CAST(GETDATE() AS DATETIME)),
	CONSTRAINT CHK_DataDostawy CHECK (DataDostawy >= CAST(GETDATE() AS DATETIME));
GO

ALTER TABLE Pracownicy
ADD CONSTRAINT CHK_DataUrodzenia CHECK (DATEDIFF(YY, CAST(DataUrodzenia AS DATE), CAST(GETDATE() AS DATE))>=18),
	CONSTRAINT CHK_DataPrzyjecia CHECK (DataPrzyjêcia <= CAST(GETDATE() AS DATETIME));
GO

ALTER TABLE Zamówienia
ADD CONSTRAINT CHK_CenaZamNieUjem CHECK (CenaZamówienia > 0),
	CONSTRAINT CHK_IloscNieUjem CHECK (Iloœæ > 0),
	CONSTRAINT CHK_DataZam CHECK (DataZamówienia <= CAST(GETDATE() AS DATETIME));
GO

ALTER TABLE PozycjeDostawy
ADD CONSTRAINT CHK_CenaJednNieUjem CHECK (CenaJednostkowa > 0),
	CONSTRAINT CHK_IloœæDostNieUjem CHECK (IloœæDostawy > 0);
GO



-----------------------------------------------------------


USE [obs³uga_sklepu_z_narzêdziami];
GO

DROP TABLE IF EXISTS dbo.Braki;
GO
CREATE TABLE dbo.Braki
(
IDNarzêdzia INT NOT NULL,
NazwaNarzêdzia NVARCHAR(100) NOT NULL,
StanMagazynu FLOAT NOT NULL,
StanMinimalny FLOAT NOT NULL
)

DROP TRIGGER IF EXISTS dbo.tr_Braki;
GO
CREATE TRIGGER dbo.tr_Braki
ON dbo.StanSklepu
FOR UPDATE
AS
BEGIN
	DECLARE @CzasBraku AS DATETIME
	IF EXISTS (SELECT * FROM StanSklepu WHERE StanMagazynu <= StanMinimalny)
		BEGIN
		INSERT INTO dbo.Braki
		(IDNarzêdzia,
		NazwaNarzêdzia,
		StanMagazynu,
		StanMinimalny
		)
		SELECT IDNarzêdzia,
		Nazwa,
		StanMagazynu,
		StanMinimalny
		FROM StanSklepu
		WHERE StanMagazynu <= StanMinimalny
		EXCEPT
		SELECT *
		FROM Braki
		END
END;
GO


-----------------------------------------------------------


USE [obs³uga_sklepu_z_narzêdziami]
GO
CREATE VIEW NajSprzedNarz AS
SELECT TOP 100 COUNT(z.IDNarzêdzia) 'Iloœæ', s.Nazwa, z.IDNarzêdzia
FROM Zamówienia z JOIN StanSklepu s ON z.IDNarzêdzia = s.IDNarzêdzia
GROUP BY s.Nazwa, z.IDNarzêdzia
ORDER BY COUNT(z.IDNarzêdzia) DESC;

SELECT * FROM NajSprzedNarz
DROP VIEW NajSprzedNarz

CREATE VIEW SprzedOstatniRok AS
SELECT TOP 100 COUNT(z.IDNarzêdzia) 'Iloœæ', s.Nazwa, z.IDNarzêdzia
FROM Zamówienia z JOIN StanSklepu s ON z.IDNarzêdzia = s.IDNarzêdzia
WHERE DATEDIFF(YY, z.DataZamówienia, GETDATE()) <= 1
GROUP BY s.Nazwa, z.IDNarzêdzia
ORDER BY COUNT(z.IDNarzêdzia) DESC;

SELECT * FROM SprzedOstatniRok
DROP VIEW SprzedOstatniRok

CREATE VIEW SprzedOstatniKwarta³ AS
SELECT TOP 100 COUNT(z.IDNarzêdzia) 'Iloœæ', s.Nazwa, z.IDNarzêdzia
FROM Zamówienia z JOIN StanSklepu s ON z.IDNarzêdzia = s.IDNarzêdzia
WHERE DATEDIFF(MM, z.DataZamówienia, GETDATE()) <= 4
GROUP BY s.Nazwa, z.IDNarzêdzia
ORDER BY COUNT(z.IDNarzêdzia) DESC;

SELECT * FROM SprzedOstatniKwarta³
DROP VIEW SprzedOstatniKwarta³

CREATE VIEW SprzedOstatniMiesi¹c AS
SELECT TOP 100 COUNT(z.IDNarzêdzia) 'Iloœæ', s.Nazwa, z.IDNarzêdzia
FROM Zamówienia z JOIN StanSklepu s ON z.IDNarzêdzia = s.IDNarzêdzia
WHERE DATEDIFF(MM, z.DataZamówienia, GETDATE()) <= 1
GROUP BY s.Nazwa, z.IDNarzêdzia
ORDER BY COUNT(z.IDNarzêdzia) DESC;

SELECT * FROM SprzedOstatniMiesi¹c
DROP VIEW SprzedOstatniMiesi¹c

CREATE FUNCTION f_sprzedaz(@poczatek DATE, @koniec DATE)
RETURNS TABLE
AS
RETURN (SELECT TOP 100 COUNT(z.IDNarzêdzia) 'Iloœæ', s.Nazwa, z.IDNarzêdzia
		FROM Zamówienia z JOIN StanSklepu s ON z.IDNarzêdzia = s.IDNarzêdzia
		WHERE z.DataZamówienia BETWEEN @poczatek AND @koniec
		GROUP BY s.Nazwa, z.IDNarzêdzia
		ORDER BY COUNT(z.IDNarzêdzia) DESC
	   );
SELECT * FROM f_sprzedaz('2021-05-29','2021-05-30')
DROP FUNCTION f_sprzedaz


-----------------------------------------------------------


USE [obs³uga_sklepu_z_narzêdziami]
GO

INSERT INTO StanSklepu
VALUES ('Zestaw kluczy oczkowo-p³askich', '15 szt.', 180, 20, 10, 'Klucze', 'Proxxon', 0.23);
INSERT INTO StanSklepu
VALUES ('Klucze imbusowe', '13 szt.', 80, 14, 8, 'Klucze', 'Bondhus', 0.23);
INSERT INTO StanSklepu
VALUES ('Grzechotka 1/4"', '1 szt.', 65, 15, 10, 'Klucze', 'NeoTools', 0.23);
INSERT INTO StanSklepu
VALUES ('M³otek œlusarski 500g', '1 szt.', 39.99, 20, 10, 'M³otki', 'NeoTools', 0.23);
INSERT INTO StanSklepu
VALUES ('M³otek œlusarski 1000g', '1 szt.', 49.99, 15, 10, 'M³otki', 'NeoTools', 0.23);
INSERT INTO StanSklepu
VALUES ('M³ot dwurêczny 4kg', '1 szt.', 199, 8, 5, 'M³otki', 'Fiskars', 0.23);
INSERT INTO StanSklepu
VALUES ('Zestaw wkrêtaków', '15 szt.', 159, 12, 10, 'Wkrêtaki', 'Sata', 0.23);
INSERT INTO StanSklepu
VALUES ('Zestaw wkrêtaków', '18 szt.', 70, 15, 12, 'Wkrêtaki', 'Dedra', 0.23);
INSERT INTO StanSklepu
VALUES ('Zestaw wkrêtaków', '6 szt.', 20, 20, 25, 'Wkrêtaki', 'Top Tools', 0.23);
INSERT INTO StanSklepu
VALUES ('Wkrêtak z grzechotk¹ i wymiennymi bitami', '1 szt.', 39, 15, 18, 'Zestaw', 'Vorel', 0.23);
INSERT INTO StanSklepu
VALUES ('Zestaw narzêdziowy', '56 szt.', 70, 12, 10, 'Zestaw', 'Sthor', 0.23);

INSERT INTO Pracownicy
VALUES ('Jurek', 'B³aszcz', '12', 'Fio³kowa', 'Bielsko-Bia³a', '43-346', 'Polska', '818-401-512', CONVERT(DATETIME,'04-09-95',5), CONVERT(DATETIME,'20-01-21',5), 'Szef');
INSERT INTO Pracownicy
VALUES ('Adam', 'Kowal', '51a', 'Fio³kowa', 'Bielsko-Bia³a', '43-346', 'Polska', '532-126-402', CONVERT(DATETIME,'21-02-93',5), CONVERT(DATETIME,'12-03-21',5), 'Zarz¹dca Baz¹');
INSERT INTO Pracownicy
VALUES ('Jan', 'Nowy', '3', 'Krêta', 'Bielsko-Bia³a', '43-346', 'Polska', '482-125-583', CONVERT(DATETIME,'02-11-95',5), CONVERT(DATETIME,'11-02-21',5), 'Kasjer');
INSERT INTO Pracownicy
VALUES ('Andrzej', 'Kowalczyk', '1', 'Fio³kowa', 'Bielsko-Bia³a', '43-346', 'Polska', '582-695-126', CONVERT(DATETIME,'15-10-98',5), CONVERT(DATETIME,'22-03-21',5), 'Kasjer-Pomocnik');

INSERT INTO Dostawcy
VALUES ('Basta', '55', 'Powstañców Wielkopolskich', 'Mosina', '62-053', 'Polska', '61-813-25-84');

INSERT INTO Dostawy
VALUES (1, 4, 875, CONVERT(DATETIME,'27-05-21 14:22:00 PM',5), CONVERT(DATETIME,'03-06-21 00:00:00',5));
INSERT INTO Dostawy
VALUES (1, 4, 454, CONVERT(DATETIME,'28-05-21 14:22:00 PM',5), CONVERT(DATETIME,'02-06-21 00:00:00',5));
INSERT INTO Dostawy
VALUES (1, 3, 636, CONVERT(DATETIME,'21-05-21 10:51:00 PM',5), CONVERT(DATETIME,'01-06-21 00:00:00',5));
INSERT INTO Dostawy
VALUES (1, 4, 936, CONVERT(DATETIME,'28-05-21 09:12:00 PM',5), CONVERT(DATETIME,'09-06-21 00:00:00',5));

INSERT INTO PozycjeDostawy
VALUES (1, 1, 160, 2);
INSERT INTO PozycjeDostawy
VALUES (1, 6, 185, 3);
INSERT INTO PozycjeDostawy
VALUES (2, 4, 30, 5);
INSERT INTO PozycjeDostawy
VALUES (2, 5, 45, 4);
INSERT INTO PozycjeDostawy
VALUES (2, 11, 62, 2);
INSERT INTO PozycjeDostawy
VALUES (3, 7, 153, 2);
INSERT INTO PozycjeDostawy
VALUES (3, 8, 60, 3);
INSERT INTO PozycjeDostawy
VALUES (3, 9, 15, 10);
INSERT INTO PozycjeDostawy
VALUES (4, 2, 74, 7);
INSERT INTO PozycjeDostawy
VALUES (4, 3, 60, 3);
INSERT INTO PozycjeDostawy
VALUES (4, 10, 34, 7);

INSERT INTO Klient
VALUES ('Mariusz', '£uk', '5a', 'Fioletowa', 'Bielsko-Bia³a', '43-346', 'Polska', '621-511-113');
INSERT INTO Klient
VALUES ('Micha³', 'Kwiat', '61', 'Ró¿ana', 'Bielsko-Bia³a', '43-346', 'Polska', '132-652-236');
INSERT INTO Klient
VALUES ('Maciej', 'Rower', '9', 'Fio³kowa', 'Bielsko-Bia³a', '43-346', 'Polska', '851-421-961');
INSERT INTO Klient
VALUES ('Jan', 'Mak', '12', 'Ró¿ana', 'Bielsko-Bia³a', '43-346', 'Polska', '685-513-591');

INSERT INTO Zamówienia
VALUES (1, 3, 1, 180, 1, CONVERT(DATETIME,'29-05-21 12:46:51 PM',5));
INSERT INTO Zamówienia
VALUES (4, 3, 2, 39.99, 1, CONVERT(DATETIME,'29-05-21 11:11:31 PM',5));
INSERT INTO Zamówienia
VALUES (2, 3, 2, 80, 1, CONVERT(DATETIME,'29-05-21 11:11:43 PM',5));
INSERT INTO Zamówienia
VALUES (8, 3, 2, 70, 1, CONVERT(DATETIME,'29-05-21 11:11:51 PM',5));
INSERT INTO Zamówienia
VALUES (8, 3, 3, 70, 1, CONVERT(DATETIME,'29-05-21 13:42:12 PM',5));
INSERT INTO Zamówienia
VALUES (6, 3, 4, 199, 1, CONVERT(DATETIME,'27-05-21 14:32:15 PM',5));
INSERT INTO Zamówienia
VALUES (7, 3, 4, 159, 1, CONVERT(DATETIME,'27-05-21 14:32:15 PM',5));


-----------------------------------------------------------


USE [obs³uga_sklepu_z_narzêdziami];
GO
CREATE ROLE [Pracownik];
GO
GRANT INSERT, UPDATE, SELECT
ON SCHEMA :: dbo
TO Pracownik;
GO
DENY SELECT, INSERT, UPDATE
ON obs³uga_sklepu_z_narzêdziami
TO Pracownik;
GO
CREATE LOGIN [Pracownik] WITH PASSWORD='PKt2n0Y',
DEFAULT_DATABASE=[obs³uga_sklepu_z_narzêdziami],
DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
GO
CREATE USER [Pracownik] FOR LOGIN [Pracownik] WITH DEFAULT_SCHEMA=[dbo];

CREATE ROLE [Zarz¹dzcaBaz¹];
GO
GRANT ALL
ON SCHEMA :: dbo
TO Zarz¹dzcaBaz¹;
GO
CREATE LOGIN [Zarz¹dzcaBaz¹] WITH PASSWORD='m12CE0U',
DEFAULT_DATABASE=[obs³uga_sklepu_z_narzêdziami],
DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
GO
CREATE USER [Zarz¹dzcaBaz¹] FOR LOGIN [Pracownik] WITH DEFAULT_SCHEMA=[dbo];

CREATE ROLE [Szef];
GO
GRANT INSERT, UPDATE, DELETE, SELECT
ON SCHEMA :: dbo
TO Szef;
GO
CREATE LOGIN [Szef] WITH PASSWORD='tiNB85P',
DEFAULT_DATABASE=[obs³uga_sklepu_z_narzêdziami],
DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
GO
CREATE USER [Szef] FOR LOGIN [Pracownik] WITH DEFAULT_SCHEMA=[dbo];


-----------------------------------------------------------


DECLARE @Ca³aKopia VARCHAR(30);
SET @Ca³aKopia = 'Ca³aKopia' + CAST(CAST(GETDATE() AS DATE) AS NVARCHAR) + '.bak';
BACKUP DATABASE obs³uga_sklepu_z_narzêdziami
TO DISK = @Ca³aKopia;
GO

DECLARE @KopiaZmian VARCHAR(20);
SET @KopiaZmian = 'KopiaZmian' + CAST(CAST(GETDATE() AS DATE) AS NVARCHAR) + '.bak';
BACKUP DATABASE obs³uga_sklepu_z_narzêdziami
TO DISK = @KopiaZmian
WITH DIFFERENTIAL;

