DROP DATABASE IF EXISTS obs�uga_sklepu_z_narz�dziami;
GO
CREATE DATABASE obs�uga_sklepu_z_narz�dziami;
GO

USE obs�uga_sklepu_z_narz�dziami;
GO

DROP TABLE IF EXISTS dbo.StanSklepu;
GO
CREATE TABLE dbo.StanSklepu (
	IDNarz�dzia INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	Nazwa NVARCHAR(100) NOT NULL,
	Ilo��Jednostkowa NVARCHAR(15) NOT NULL,
	CenaNarz�dzia MONEY NOT NULL,
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
	Imi� NVARCHAR(15) NOT NULL,
	Nazwisko NVARCHAR(20) NOT NULL,
	NumerDomu NVARCHAR(10) NOT NULL,
	Ulica NVARCHAR(30) NOT NULL,
	Miasto NVARCHAR(30) NOT NULL,
	KodPocztowy NVARCHAR(10) NOT NULL,
	Kraj NVARCHAR(15) NOT NULL,
	NumerTelefonu NVARCHAR(15) NOT NULL,
	DataUrodzenia DATETIME NOT NULL,
	DataPrzyj�cia DATETIME NOT NULL,
	Stanowisko NVARCHAR(15) NOT NULL
);
GO

DROP TABLE IF EXISTS dbo.Zam�wienia
GO
CREATE TABLE dbo.Zam�wienia(
	IDZam�wienia INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	IDNarz�dzia INT NOT NULL,
	IDPracownika INT NOT NULL,
	IDKlienta INT NOT NULL,
	CenaZam�wienia MONEY NOT NULL,
	Ilo�� FLOAT NOT NULL,
	DataZam�wienia DATETIME NOT NULL
);
GO

DROP TABLE IF EXISTS dbo.Klient
GO
CREATE TABLE dbo.Klient(
	IDKlienta INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	Imi�Klienta NVARCHAR(15) NOT NULL,
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
	IDNarz�dzia INT NOT NULL,
	CenaJednostkowa MONEY NOT NULL,
	Ilo��Dostawy FLOAT NOT NULL
);
GO

ALTER TABLE Dostawy
ADD CONSTRAINT FK_IDDostawcyDostawy FOREIGN KEY (IDDostawcy) REFERENCES Dostawcy(IDDostawcy),
	CONSTRAINT FK_IDPracownikaDostawy FOREIGN KEY (IDPracownika) REFERENCES Pracownicy(IDPracownika);
GO

ALTER TABLE Zam�wienia
ADD CONSTRAINT FK_IDNarz�dziaZam�wienia FOREIGN KEY (IDNarz�dzia) REFERENCES StanSklepu(IDNarz�dzia),
	CONSTRAINT FK_IDPracownikaZam�wienia FOREIGN KEY (IDPracownika) REFERENCES Pracownicy(IDPracownika),
	CONSTRAINT FK_IDKlientaZam�wienia FOREIGN KEY (IDKlienta) REFERENCES Klient(IDKlienta);
GO

ALTER TABLE PozycjeDostawy
ADD CONSTRAINT FK_IDDostawyPozZam FOREIGN KEY (IDDostawy) REFERENCES Dostawy(IDDostawy),
	CONSTRAINT FK_IDNarz�dziaPozZam FOREIGN KEY (IDNarz�dzia) REFERENCES StanSklepu(IDNarz�dzia);
GO


ALTER TABLE StanSklepu
ADD CONSTRAINT CHK_CenaNieUjem CHECK (CenaNarz�dzia > 0),
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
	CONSTRAINT CHK_DataPrzyjecia CHECK (DataPrzyj�cia <= CAST(GETDATE() AS DATETIME));
GO

ALTER TABLE Zam�wienia
ADD CONSTRAINT CHK_CenaZamNieUjem CHECK (CenaZam�wienia > 0),
	CONSTRAINT CHK_IloscNieUjem CHECK (Ilo�� > 0),
	CONSTRAINT CHK_DataZam CHECK (DataZam�wienia <= CAST(GETDATE() AS DATETIME));
GO

ALTER TABLE PozycjeDostawy
ADD CONSTRAINT CHK_CenaJednNieUjem CHECK (CenaJednostkowa > 0),
	CONSTRAINT CHK_Ilo��DostNieUjem CHECK (Ilo��Dostawy > 0);
GO



-----------------------------------------------------------


USE [obs�uga_sklepu_z_narz�dziami];
GO

DROP TABLE IF EXISTS dbo.Braki;
GO
CREATE TABLE dbo.Braki
(
IDNarz�dzia INT NOT NULL,
NazwaNarz�dzia NVARCHAR(100) NOT NULL,
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
		(IDNarz�dzia,
		NazwaNarz�dzia,
		StanMagazynu,
		StanMinimalny
		)
		SELECT IDNarz�dzia,
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


USE [obs�uga_sklepu_z_narz�dziami]
GO
CREATE VIEW NajSprzedNarz AS
SELECT TOP 100 COUNT(z.IDNarz�dzia) 'Ilo��', s.Nazwa, z.IDNarz�dzia
FROM Zam�wienia z JOIN StanSklepu s ON z.IDNarz�dzia = s.IDNarz�dzia
GROUP BY s.Nazwa, z.IDNarz�dzia
ORDER BY COUNT(z.IDNarz�dzia) DESC;

SELECT * FROM NajSprzedNarz
DROP VIEW NajSprzedNarz

CREATE VIEW SprzedOstatniRok AS
SELECT TOP 100 COUNT(z.IDNarz�dzia) 'Ilo��', s.Nazwa, z.IDNarz�dzia
FROM Zam�wienia z JOIN StanSklepu s ON z.IDNarz�dzia = s.IDNarz�dzia
WHERE DATEDIFF(YY, z.DataZam�wienia, GETDATE()) <= 1
GROUP BY s.Nazwa, z.IDNarz�dzia
ORDER BY COUNT(z.IDNarz�dzia) DESC;

SELECT * FROM SprzedOstatniRok
DROP VIEW SprzedOstatniRok

CREATE VIEW SprzedOstatniKwarta� AS
SELECT TOP 100 COUNT(z.IDNarz�dzia) 'Ilo��', s.Nazwa, z.IDNarz�dzia
FROM Zam�wienia z JOIN StanSklepu s ON z.IDNarz�dzia = s.IDNarz�dzia
WHERE DATEDIFF(MM, z.DataZam�wienia, GETDATE()) <= 4
GROUP BY s.Nazwa, z.IDNarz�dzia
ORDER BY COUNT(z.IDNarz�dzia) DESC;

SELECT * FROM SprzedOstatniKwarta�
DROP VIEW SprzedOstatniKwarta�

CREATE VIEW SprzedOstatniMiesi�c AS
SELECT TOP 100 COUNT(z.IDNarz�dzia) 'Ilo��', s.Nazwa, z.IDNarz�dzia
FROM Zam�wienia z JOIN StanSklepu s ON z.IDNarz�dzia = s.IDNarz�dzia
WHERE DATEDIFF(MM, z.DataZam�wienia, GETDATE()) <= 1
GROUP BY s.Nazwa, z.IDNarz�dzia
ORDER BY COUNT(z.IDNarz�dzia) DESC;

SELECT * FROM SprzedOstatniMiesi�c
DROP VIEW SprzedOstatniMiesi�c

CREATE FUNCTION f_sprzedaz(@poczatek DATE, @koniec DATE)
RETURNS TABLE
AS
RETURN (SELECT TOP 100 COUNT(z.IDNarz�dzia) 'Ilo��', s.Nazwa, z.IDNarz�dzia
		FROM Zam�wienia z JOIN StanSklepu s ON z.IDNarz�dzia = s.IDNarz�dzia
		WHERE z.DataZam�wienia BETWEEN @poczatek AND @koniec
		GROUP BY s.Nazwa, z.IDNarz�dzia
		ORDER BY COUNT(z.IDNarz�dzia) DESC
	   );
SELECT * FROM f_sprzedaz('2021-05-29','2021-05-30')
DROP FUNCTION f_sprzedaz


-----------------------------------------------------------


USE [obs�uga_sklepu_z_narz�dziami]
GO

INSERT INTO StanSklepu
VALUES ('Zestaw kluczy oczkowo-p�askich', '15 szt.', 180, 20, 10, 'Klucze', 'Proxxon', 0.23);
INSERT INTO StanSklepu
VALUES ('Klucze imbusowe', '13 szt.', 80, 14, 8, 'Klucze', 'Bondhus', 0.23);
INSERT INTO StanSklepu
VALUES ('Grzechotka 1/4"', '1 szt.', 65, 15, 10, 'Klucze', 'NeoTools', 0.23);
INSERT INTO StanSklepu
VALUES ('M�otek �lusarski 500g', '1 szt.', 39.99, 20, 10, 'M�otki', 'NeoTools', 0.23);
INSERT INTO StanSklepu
VALUES ('M�otek �lusarski 1000g', '1 szt.', 49.99, 15, 10, 'M�otki', 'NeoTools', 0.23);
INSERT INTO StanSklepu
VALUES ('M�ot dwur�czny 4kg', '1 szt.', 199, 8, 5, 'M�otki', 'Fiskars', 0.23);
INSERT INTO StanSklepu
VALUES ('Zestaw wkr�tak�w', '15 szt.', 159, 12, 10, 'Wkr�taki', 'Sata', 0.23);
INSERT INTO StanSklepu
VALUES ('Zestaw wkr�tak�w', '18 szt.', 70, 15, 12, 'Wkr�taki', 'Dedra', 0.23);
INSERT INTO StanSklepu
VALUES ('Zestaw wkr�tak�w', '6 szt.', 20, 20, 25, 'Wkr�taki', 'Top Tools', 0.23);
INSERT INTO StanSklepu
VALUES ('Wkr�tak z grzechotk� i wymiennymi bitami', '1 szt.', 39, 15, 18, 'Zestaw', 'Vorel', 0.23);
INSERT INTO StanSklepu
VALUES ('Zestaw narz�dziowy', '56 szt.', 70, 12, 10, 'Zestaw', 'Sthor', 0.23);

INSERT INTO Pracownicy
VALUES ('Jurek', 'B�aszcz', '12', 'Fio�kowa', 'Bielsko-Bia�a', '43-346', 'Polska', '818-401-512', CONVERT(DATETIME,'04-09-95',5), CONVERT(DATETIME,'20-01-21',5), 'Szef');
INSERT INTO Pracownicy
VALUES ('Adam', 'Kowal', '51a', 'Fio�kowa', 'Bielsko-Bia�a', '43-346', 'Polska', '532-126-402', CONVERT(DATETIME,'21-02-93',5), CONVERT(DATETIME,'12-03-21',5), 'Zarz�dca Baz�');
INSERT INTO Pracownicy
VALUES ('Jan', 'Nowy', '3', 'Kr�ta', 'Bielsko-Bia�a', '43-346', 'Polska', '482-125-583', CONVERT(DATETIME,'02-11-95',5), CONVERT(DATETIME,'11-02-21',5), 'Kasjer');
INSERT INTO Pracownicy
VALUES ('Andrzej', 'Kowalczyk', '1', 'Fio�kowa', 'Bielsko-Bia�a', '43-346', 'Polska', '582-695-126', CONVERT(DATETIME,'15-10-98',5), CONVERT(DATETIME,'22-03-21',5), 'Kasjer-Pomocnik');

INSERT INTO Dostawcy
VALUES ('Basta', '55', 'Powsta�c�w Wielkopolskich', 'Mosina', '62-053', 'Polska', '61-813-25-84');

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
VALUES ('Mariusz', '�uk', '5a', 'Fioletowa', 'Bielsko-Bia�a', '43-346', 'Polska', '621-511-113');
INSERT INTO Klient
VALUES ('Micha�', 'Kwiat', '61', 'R�ana', 'Bielsko-Bia�a', '43-346', 'Polska', '132-652-236');
INSERT INTO Klient
VALUES ('Maciej', 'Rower', '9', 'Fio�kowa', 'Bielsko-Bia�a', '43-346', 'Polska', '851-421-961');
INSERT INTO Klient
VALUES ('Jan', 'Mak', '12', 'R�ana', 'Bielsko-Bia�a', '43-346', 'Polska', '685-513-591');

INSERT INTO Zam�wienia
VALUES (1, 3, 1, 180, 1, CONVERT(DATETIME,'29-05-21 12:46:51 PM',5));
INSERT INTO Zam�wienia
VALUES (4, 3, 2, 39.99, 1, CONVERT(DATETIME,'29-05-21 11:11:31 PM',5));
INSERT INTO Zam�wienia
VALUES (2, 3, 2, 80, 1, CONVERT(DATETIME,'29-05-21 11:11:43 PM',5));
INSERT INTO Zam�wienia
VALUES (8, 3, 2, 70, 1, CONVERT(DATETIME,'29-05-21 11:11:51 PM',5));
INSERT INTO Zam�wienia
VALUES (8, 3, 3, 70, 1, CONVERT(DATETIME,'29-05-21 13:42:12 PM',5));
INSERT INTO Zam�wienia
VALUES (6, 3, 4, 199, 1, CONVERT(DATETIME,'27-05-21 14:32:15 PM',5));
INSERT INTO Zam�wienia
VALUES (7, 3, 4, 159, 1, CONVERT(DATETIME,'27-05-21 14:32:15 PM',5));


-----------------------------------------------------------


USE [obs�uga_sklepu_z_narz�dziami];
GO
CREATE ROLE [Pracownik];
GO
GRANT INSERT, UPDATE, SELECT
ON SCHEMA :: dbo
TO Pracownik;
GO
DENY SELECT, INSERT, UPDATE
ON obs�uga_sklepu_z_narz�dziami
TO Pracownik;
GO
CREATE LOGIN [Pracownik] WITH PASSWORD='PKt2n0Y',
DEFAULT_DATABASE=[obs�uga_sklepu_z_narz�dziami],
DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
GO
CREATE USER [Pracownik] FOR LOGIN [Pracownik] WITH DEFAULT_SCHEMA=[dbo];

CREATE ROLE [Zarz�dzcaBaz�];
GO
GRANT ALL
ON SCHEMA :: dbo
TO Zarz�dzcaBaz�;
GO
CREATE LOGIN [Zarz�dzcaBaz�] WITH PASSWORD='m12CE0U',
DEFAULT_DATABASE=[obs�uga_sklepu_z_narz�dziami],
DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
GO
CREATE USER [Zarz�dzcaBaz�] FOR LOGIN [Pracownik] WITH DEFAULT_SCHEMA=[dbo];

CREATE ROLE [Szef];
GO
GRANT INSERT, UPDATE, DELETE, SELECT
ON SCHEMA :: dbo
TO Szef;
GO
CREATE LOGIN [Szef] WITH PASSWORD='tiNB85P',
DEFAULT_DATABASE=[obs�uga_sklepu_z_narz�dziami],
DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
GO
CREATE USER [Szef] FOR LOGIN [Pracownik] WITH DEFAULT_SCHEMA=[dbo];


-----------------------------------------------------------


DECLARE @Ca�aKopia VARCHAR(30);
SET @Ca�aKopia = 'Ca�aKopia' + CAST(CAST(GETDATE() AS DATE) AS NVARCHAR) + '.bak';
BACKUP DATABASE obs�uga_sklepu_z_narz�dziami
TO DISK = @Ca�aKopia;
GO

DECLARE @KopiaZmian VARCHAR(20);
SET @KopiaZmian = 'KopiaZmian' + CAST(CAST(GETDATE() AS DATE) AS NVARCHAR) + '.bak';
BACKUP DATABASE obs�uga_sklepu_z_narz�dziami
TO DISK = @KopiaZmian
WITH DIFFERENTIAL;

