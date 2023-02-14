GO  
--Создание хранимых процедур добавления и редактирования данных
--1.1 Ввод и хранение данных студента
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

go
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


go
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

go
--1.9 Формирование направления
CREATE PROCEDURE [dbo].[CreateStudentReport]
--поля направления
@idDiscipline INT,
@idReportType INT,
@idTeacher INT,
@DateReport DATE,
@DateCreate DATE,
@SemesterNumber INT,
@idGroupStudent INT
AS
--сначала проверяем, закрыта ли ведомость 
IF EXISTS(SELECT 'TRUE' FROM  
		dbo.ReportWithGroup Report INNER JOIN
		dbo.GroupStudent ON Report.idGroup=GroupStudent.idGroup 
			AND GroupStudent.idGroupStudent=@idGroupStudent
		WHERE Report.IsTheFirst=1 AND Report.IsClosed=0
				AND Report.idDiscipline=@idDiscipline 
				AND Report.idReportType=@idReportType 
				AND Report.SemesterNumber=@SemesterNumber)
 BEGIN   
      RAISERROR('Ошибка! Ведомость для данной группы по данному виду отчетности еще открыта', 16,1)
      RETURN -1
  END

--затем проверяем, чтобы еще не было положительной оценки 
IF EXISTS(SELECT 'TRUE' FROM  
		dbo.ReportWithGroup Report INNER JOIN
		dbo.Progress ON Report.idReport=Progress.idReport
			AND Progress.idGroupStudent=@idGroupStudent INNER JOIN
		dbo.Mark ON Progress.idMark=Mark.idMark AND Mark.IsPassed=1
		WHERE Report.idDiscipline=@idDiscipline 
				AND Report.idReportType=@idReportType 
				AND Report.SemesterNumber=@SemesterNumber)
 BEGIN   
      RAISERROR('Ошибка! У студента по данному виду отчетности уже есть положительная оценка', 16,1)
      RETURN -1
  END

BEGIN TRAN
BEGIN TRY
	--добавляем направление и запоминаем значение ключа
	DECLARE @idReport INT
	INSERT INTO dbo.Report(idDiscipline,idReportType,idTeacher,
DateReport,DateCreate,IsTheFirst,SemesterNumber,IsClosed)
	VALUES (@idDiscipline,@idReportType,@idTeacher,
@DateReport,@DateCreate,0,@SemesterNumber,0)
	SELECT @idReport=@@IDENTITY
	
	--добавляем успеваемость студента
	INSERT INTO dbo.Progress(idGroupStudent,idReport)
	VALUES(@idGroupStudent,@idReport)
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
RETURN @idReport

--1.10 Ввод и хранение результатов направления
CREATE PROCEDURE [dbo].[CloseStudentReport]
--поля ведомости
@idGroupStudent INT,
@idReport INT,
@idMark INT,
@Theme VARCHAR(200),
@idTeacher INT,		--преподаватель может поменяться
@DateReport DATE	--окончательная дата приема задолженности
AS
BEGIN TRAN
BEGIN TRY
	--добавляем оценку в направление 
	UPDATE dbo.Progress
	SET idMark=@idMark, Theme=@Theme
	WHERE idGroupStudent=@idGroupStudent AND idReport=@idReport
	
	--закрываем направление
	UPDATE dbo.Report
	SET IsClosed=1, DateReport=@DateReport, idTeacher=@idTeacher
	WHERE idReport=@idReport
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
RETURN @idReport
