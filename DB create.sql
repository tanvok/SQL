
--Создание таблиц базы данных
GO
CREATE DATABASE Progress
GO
USE Progress
CREATE TABLE [dbo].[Teacher](
	[idTeacher] [int] NOT NULL,
	[TeacherName] [varchar](150) NOT NULL,
	[DateLeave] [date] NULL,
	[BirthDate] [date] NOT NULL,
 CONSTRAINT [PK_Teacher] PRIMARY KEY CLUSTERED 
(	[idTeacher] ASC))

GO
CREATE TABLE [dbo].[Student](
	[idStudent] [int] IDENTITY(1,1) NOT NULL,
	[RecordBookNumber] [char](6) NOT NULL,
	[Surname] [varchar](50) NOT NULL,
	[FirstName] [varchar](50) NOT NULL,
	[Patronymic] [varchar](50) NOT NULL,
	[SexBit] [bit] NOT NULL,
	[BirthDate] [date] NOT NULL,
	[PhoneNumber] [varchar](50) NULL,
 CONSTRAINT [PK_Student] PRIMARY KEY CLUSTERED 
(	[idStudent] ASC ),
 CONSTRAINT [U_StudentName] UNIQUE NONCLUSTERED 
(	[Surname] ASC,
	[FirstName] ASC,
	[Patronymic] ASC,
	[BirthDate] ASC ),
 CONSTRAINT [U_StudentRecordBook] UNIQUE NONCLUSTERED 
(	[RecordBookNumber] ASC ))

GO
CREATE TABLE [dbo].[ServiceInfo](
	[MaxExamRetakeCount] [int] NOT NULL,
	[StudReportValidity] [int] NOT NULL) 

GO
CREATE TABLE [dbo].[Group](
	[idGroup] [int] NOT NULL,
	[GroupName] [varchar](15) NOT NULL,
	[DateCreate] [date] NOT NULL,
	[DateClose] [date] NULL,
	[YearEnroll] [int] NOT NULL,
 CONSTRAINT [PK_Group] PRIMARY KEY CLUSTERED 
(	[idGroup] ASC),
 CONSTRAINT [U_GroupName] UNIQUE NONCLUSTERED 
(	[GroupName] ASC)) 

GO
CREATE TABLE [dbo].[EnrollmentCategory](
	[idEnrollmentCategory] [int] NOT NULL,
	[EnrollmentCategoryName] [varchar](20) NOT NULL,
 CONSTRAINT [PK_EnrollmentCategory] PRIMARY KEY CLUSTERED 
(	[idEnrollmentCategory] ASC),
 CONSTRAINT [U_EnrollmentCategoryName] UNIQUE NONCLUSTERED 
(	[EnrollmentCategoryName] ASC)) 

GO
CREATE TABLE [dbo].[Discipline](
	[idDiscipline] [int] NOT NULL,
	[DisciplineName] [varchar](150) NOT NULL,
 CONSTRAINT [PKDiscipline] PRIMARY KEY CLUSTERED 
(	[idDiscipline] ASC),
 CONSTRAINT [U_DisciplineName] UNIQUE NONCLUSTERED 
(	[DisciplineName] ASC)) 

GO
CREATE TABLE [dbo].[Prikaz](
	[idPrikaz] [int] NOT NULL,
	[PrikazNumber] [varchar](15) NOT NULL,
	[DateBegin] [date] NOT NULL,
	[DateCreate] [date] NOT NULL,
 CONSTRAINT [PK_Prikaz] PRIMARY KEY CLUSTERED 
(	[idPrikaz] ASC),
 CONSTRAINT [U_PrikazNumber] UNIQUE NONCLUSTERED 
(	[PrikazNumber] ASC,
	[DateBegin] ASC))

GO 
CREATE TABLE [dbo].[LeaveReason]([idLeaveReason] [int] NOT NULL,
	[LeaveReasonText] [varchar](100) NOT NULL,
	[IsRegistered] [bit] NULL,
 CONSTRAINT [PK_LeaveReason] PRIMARY KEY CLUSTERED 
(	[idLeaveReason] ASC),
 CONSTRAINT [U_LeaveReasonText] UNIQUE NONCLUSTERED 
(	[LeaveReasonText] ASC)) 

GO
CREATE TABLE [dbo].[GroupStudent](
	[idGroupStudent] [int] IDENTITY(1,1) NOT NULL,
	[idStudent] [int] NOT NULL,
	[idGroup] [int] NOT NULL,
	[idPrikazEnter] [int] NOT NULL,
	[idPrikazLeave] [int] NULL,
	[idEnrollmentCategory] [int] NOT NULL,
 CONSTRAINT [PK_GroupStudent] PRIMARY KEY CLUSTERED 
(	[idGroupStudent] ASC),
CONSTRAINT [U_idGroupidPrikazEnter] UNIQUE NONCLUSTERED 
(	[idGroup] ASC,
	[idStudent] ASC,
	[idPrikazEnter] ASC
),
 CONSTRAINT [U_idStudentidPrikazLeave] UNIQUE NONCLUSTERED 
(	[idStudent] ASC,
	[idGroup] ASC,
	[idPrikazLeave])) 

GO
CREATE TABLE [dbo].[Mark](
	[idMark] [int] NOT NULL,
	[MarkName] [varchar](25) NOT NULL,
	[IsPassed] [bit] NOT NULL,
	[BallCount] [int] NOT NULL,
 CONSTRAINT [PK_Mark] PRIMARY KEY CLUSTERED 
(	[idMark] ASC),
 CONSTRAINT [U_MarkName] UNIQUE NONCLUSTERED 
(	[MarkName] ASC)) 

GO
CREATE TABLE [dbo].[ReportType](
	[idReportType] [int] NOT NULL,
	[ReportTypeName] [varchar](35) NOT NULL,
	[WithTheme] [bit] NOT NULL,
 CONSTRAINT [PK_ReportType] PRIMARY KEY CLUSTERED 
(	[idReportType] ASC),
 CONSTRAINT [U_ReportTypeName] UNIQUE NONCLUSTERED 
(	[ReportTypeName] ASC)) 

GO
CREATE TABLE [dbo].[Report](
	[idReport] [int] IDENTITY(1,1) NOT NULL,
	[idDiscipline] [int] NOT NULL,
	[idReportType] [int] NOT NULL,
	[idTeacher] [int] NOT NULL,
	[DateReport] [date] NULL,
	[DateCreate] [date] NOT NULL,
	[IsTheFirst] [bit] NOT NULL,
	[SemesterNumber] [int] NOT NULL,
	[IsClosed] [bit] NOT NULL,
 CONSTRAINT [PK_Report] PRIMARY KEY CLUSTERED 
(	[idReport] ASC)) 

GO
CREATE TABLE [dbo].[Progress](
	[idGroupStudent] [int] NOT NULL,
	[idReport] [int] NOT NULL,
	[idMark] [int] NULL,
	[Theme] [varchar](200) NULL,
 CONSTRAINT [PK_Progress] PRIMARY KEY CLUSTERED 
(	[idReport] ASC,
	[idGroupStudent] ASC))
GO 



--Создание ограничений внешнего ключа
GO
ALTER TABLE [dbo].[GroupStudent]  
ADD  CONSTRAINT [FK_GroupStudent_EnrollmentCategory] 
FOREIGN KEY([idEnrollmentCategory])
REFERENCES [dbo].[EnrollmentCategory] ([idEnrollmentCategory])

GO
ALTER TABLE [dbo].[GroupStudent]  
ADD  CONSTRAINT [FK_GroupStudent_Group] 
FOREIGN KEY([idGroup])
REFERENCES [dbo].[Group] ([idGroup])

GO
ALTER TABLE [dbo].[GroupStudent]  
ADD  CONSTRAINT [FK_GroupStudent_PrikazEnter] 
FOREIGN KEY([idPrikazEnter])
REFERENCES [dbo].[Prikaz] ([idPrikaz])

GO
ALTER TABLE [dbo].[GroupStudent]  
ADD  CONSTRAINT [FK_GroupStudent_PrikazLeave] 
FOREIGN KEY([idPrikazLeave])
REFERENCES [dbo].[Prikaz] ([idPrikaz])

GO
ALTER TABLE [dbo].[GroupStudent]  
ADD  CONSTRAINT [FK_GroupStudent_LeaveReason] 
FOREIGN KEY([idLeaveReason])
REFERENCES [dbo].[LeaveReason] ([idLeaveReason])

GO
ALTER TABLE [dbo].[GroupStudent]  
ADD  CONSTRAINT [FK_GroupStudent_Student] 
FOREIGN KEY([idStudent])
REFERENCES [dbo].[Student] ([idStudent])
ON DELETE CASCADE

GO
ALTER TABLE [dbo].[Progress]  
ADD  CONSTRAINT [FK_Progress_GroupStudent] 
FOREIGN KEY([idGroupStudent])
REFERENCES [dbo].[GroupStudent] ([idGroupStudent])
ON DELETE CASCADE

GO
ALTER TABLE [dbo].[Progress]  
ADD  CONSTRAINT [FK_Progress_Mark] 
FOREIGN KEY([idMark])
REFERENCES [dbo].[Mark] ([idMark])

GO
ALTER TABLE [dbo].[Progress]  
ADD  CONSTRAINT [FK_Progress_Report] 
FOREIGN KEY([idReport])
REFERENCES [dbo].[Report] ([idReport])
ON DELETE CASCADE

GO
ALTER TABLE [dbo].[Report]  
ADD  CONSTRAINT [FK_Report_Discipline] 
FOREIGN KEY([idDiscipline])
REFERENCES [dbo].[Discipline] ([idDiscipline])

GO
ALTER TABLE [dbo].[Report]  
ADD  CONSTRAINT [FK_Report_ReportType] 
FOREIGN KEY([idReportType])
REFERENCES [dbo].[ReportType] ([idReportType])

GO
ALTER TABLE [dbo].[Report]  
ADD  CONSTRAINT [FK_Report_Teacher] 
FOREIGN KEY([idTeacher])
REFERENCES [dbo].[Teacher] ([idTeacher])
GO

--Вспомогательные запросы 
GO
--Представление - документы об отчетности с кодом группы
CREATE VIEW [dbo].[ReportWithGroup]
AS
SELECT DISTINCT Report.idReport, Report.idDiscipline, Report.IsTheFirst,
	Report.idReportType, Report.SemesterNumber, 
GroupStudent.idGroup, Report.IsClosed
FROM dbo.Report INNER JOIN
	dbo.Progress ON Report.idReport=Progress.idReport INNER JOIN
	dbo.GroupStudent 
ON Progress.idGroupStudent = GroupStudent.idGroupStudent

GO
--представление: студенты с датами зачисления и отчисления
--загруженными из соответствующих приказов
CREATE VIEW [dbo].[GroupStudentFull]
AS
SELECT dbo.GroupStudent.idGroupStudent, dbo.GroupStudent.idGroup, 
    GroupStudent.idStudent, dbo.GroupStudent.idEnrollmentCategory, 
    PrikazEnter.DateBegin as DateEnter, 
    PrikazLeave.DateBegin AS DateLeave, idLeaveReason
FROM dbo.GroupStudent 
    INNER JOIN dbo.Prikaz as PrikazEnter 
ON dbo.GroupStudent.idPrikazEnter = PrikazEnter.idPrikaz 
    LEFT JOIN dbo.Prikaz AS PrikazLeave 
ON dbo.GroupStudent.idPrikazLeave = PrikazLeave.idPrikaz


GO
--inline-фунцкция возвращает список всех текущих на переданную дату 
--студентов групп 
CREATE FUNCTION [dbo].[GetGroupStudentsForData] 
(@date DATE)
RETURNS TABLE
AS
RETURN 
(SELECT *
FROM [dbo].[GroupStudentFull]
WHERE @date>=DateEnter AND (@date<DateLeave OR DateLeave IS NULL)) 
GO  
Создание хранимых процедур добавления и редактирования данных
1.1 Ввод и хранение данных студента
CREATE PROCEDURE [dbo].[InsertStudent]
--поля студента
@Surname VARCHAR(50),
@FirstName VARCHAR(50),
@Patronymic VARCHAR(50),
@BirthDate DATE,
@SexBit BIT,
@PhoneNumber VARCHAR(50),
@RecordBookNumber CHAR(6),
--поля студента группы
@idGroup INT,
@idPrikazEnter INT,
@idEnrollmentCategory INT
AS

--сначала проверяем, чтобы номер зачетной книжки соответствовал году 
-- поступления группы:две первых цифры должны быть равны году поступления
IF EXISTS(SELECT 'TRUE' FROM  
		dbo.[Group] WHERE idGroup=@idGroup
			AND RIGHT(YearEnroll,2)<>LEFT(@RecordBookNumber,2))
 BEGIN   
      RAISERROR('Ошибка! Номер зачетной книжки не соответствует году поступления группы.', 16,1)
      RETURN -1
  END

BEGIN TRAN
BEGIN TRY
	--добавляем студента и запоминаем значение ключа
	DECLARE @idStudent INT
	INSERT INTO dbo.Student(Surname,FirstName,Patronymic,
BirthDate,SexBit,PhoneNumber,RecordBookNumber)
	VALUES (@Surname,@FirstName,@Patronymic,
@BirthDate,@SexBit,@PhoneNumber,@RecordBookNumber)
	SELECT @idStudent=@@IDENTITY
	
	--добавляем студента группы
	INSERT INTO dbo.GroupStudent(idStudent,idGroup,
idPrikazEnter,idEnrollmentCategory)
	VALUES(@idStudent,@idGroup,
@idPrikazEnter,@idEnrollmentCategory)
END TRY

BEGIN CATCH
--возвращаем ошибку, если она возникла, и откатываем транзакцию
		SELECT 
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_SEVERITY() AS ErrorSeverity,
			ERROR_STATE() as ErrorState,
			ERROR_PROCEDURE() as ErrorProcedure,
			ERROR_LINE() as ErrorLine,
			ERROR_MESSAGE() as ErrorMessage;

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
END CATCH;

--сохраняем транзакцию
	IF @@TRANCOUNT > 0
		COMMIT TRANSACTION;
RETURN @idStudent	--возвращаем код добавленного студента

--1.5 Перевод студента
CREATE PROCEDURE [dbo].[TransferStudent]
--поля для первоначальной группы 
@idFirstGroupStudent INT,
@idFirstPrikazLeave INT,
@idFirstLeaveReason INT,
--поля для новой группы
@idGroup INT,
@idPrikazEnter INT,
@idEnrollmentCategory INT
AS
BEGIN TRAN
BEGIN TRY
	--отчисляем  
	UPDATE dbo.GroupStudent
	SET idPrikazLeave=@idFirstPrikazLeave, 
idLeaveReason=@idFirstLeaveReason
	WHERE idGroupStudent=@idFirstGroupStudent
	
	--узнаем код студента для зачисления
	DECLARE @idStudent INT
	SELECT @idStudent = idStudent FROM dbo.GroupStudent
		WHERE idGroupStudent=@idFirstGroupStudent
	
	--зачисляем студента группы
	DECLARE @idGroupStudent INT
	INSERT INTO dbo.GroupStudent(idStudent,idGroup,
idPrikazEnter,idEnrollmentCategory)
	VALUES(@idStudent,@idGroup,@idPrikazEnter,@idEnrollmentCategory)
	SELECT @idGroupStudent=@@IDENTITY
END TRY

BEGIN CATCH
--возвращаем ошибку, если она возникла, и откатываем транзакцию
		SELECT 
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_SEVERITY() AS ErrorSeverity,
			ERROR_STATE() as ErrorState,
			ERROR_PROCEDURE() as ErrorProcedure,
			ERROR_LINE() as ErrorLine,
			ERROR_MESSAGE() as ErrorMessage;

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
END CATCH;

--сохраняем транзакцию
	IF @@TRANCOUNT > 0
		COMMIT TRANSACTION;
RETURN @idGroupStudent



--1.7 Формирование ведомости
CREATE PROCEDURE [dbo].[CreateFirstReport]
--поля ведомости
@idDiscipline INT,
@idReportType INT,
@idTeacher INT,
@DateReport DATE,
@DateCreate DATE,
@SemesterNumber INT,
@idGroup INT
AS
--сначала проверяем, нет ли уже такой ведомости
IF EXISTS(SELECT 'TRUE' FROM  
		dbo.ReportWithGroup Report 
		WHERE Report.IsTheFirst=1 
AND Report.idDiscipline=@idDiscipline 
				AND Report.idReportType=@idReportType 
				AND Report.SemesterNumber=@SemesterNumber 
				AND Report.idGroup=@idGroup)
 BEGIN   
      RAISERROR('Ошибка! Ведомость для данной группы по данному виду отчетности уже сформирована', 16,1)
      RETURN -1
  END

BEGIN TRAN
BEGIN TRY
	--добавляем ведомость и запоминаем значение ключа
	DECLARE @idReport INT
	INSERT INTO dbo.Report(idDiscipline,idReportType,idTeacher,
DateReport,DateCreate,IsTheFirst,SemesterNumber,IsClosed)
	VALUES (@idDiscipline,@idReportType,@idTeacher,@DateReport,
@DateCreate,1,@SemesterNumber,0)
	SELECT @idReport=@@IDENTITY
	
	--добавляем успеваемость студентов группы, используя вспом. функцию
--возвращающую всех студентов, учащихся в группе на дату ведомости
	INSERT INTO dbo.Progress(idGroupStudent,idReport)
	SELECT idGroupStudent,@idReport
	FROM [dbo].[GetGroupStudentsForData](@DateReport)
	WHERE idGroup=@idGroup
END TRY

BEGIN CATCH
--возвращаем ошибку, если она возникла, и откатываем транзакцию
		SELECT 
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_SEVERITY() AS ErrorSeverity,
			ERROR_STATE() as ErrorState,
			ERROR_PROCEDURE() as ErrorProcedure,
			ERROR_LINE() as ErrorLine,
			ERROR_MESSAGE() as ErrorMessage;

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
END CATCH;

--сохраняем транзакцию
	IF @@TRANCOUNT > 0
		COMMIT TRANSACTION;
RETURN @idReport	--возвращаем код созданного документа об отчетности
