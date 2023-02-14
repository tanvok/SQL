ALTER TABLE dbo.Student
ADD CONSTRAINT CH_StudentRecordBookNumber CHECK (LEN(RecordBookNumber)=6)

go
ALTER TABLE dbo.Student
ADD CONSTRAINT CH_StudentBirthDate CHECK 
((DATEADD(yy,16,BirthDate)<GETDATE()) AND (DATEADD(yy,100,BirthDate)>GETDATE()))


go
ALTER TABLE [dbo].[Report]
ADD CONSTRAINT CH_ReportSemesterNumber 
CHECK (([SemesterNumber]>0) AND ([SemesterNumber]<13))


  go
  ALTER TABLE [dbo].[Report]
ADD CONSTRAINT CH_ReportDateReport CHECK 
(((DATEADD(dd,3,[DateCreate])>=[DateReport]) AND IsTheFirst=0)
	OR (IsTheFirst=1) AND ([DateReport]>=[DateCreate]))

go
--ФИО
ALTER TABLE dbo.Student
ADD StudentFullName AS (Surname+' '+FirstName+' '+Patronymic)  
go
--Фамилия и инициалы:
ALTER TABLE dbo.Student
ADD StudentShortName AS 
(Surname+' '+LEFT(FirstName,1)+'.'+LEFT(Patronymic,1)+'.')

go
CREATE NONCLUSTERED INDEX [IX_idGroupStudent] ON [dbo].[Progress] 
(	[idGroupStudent] ASC)
go
CREATE NONCLUSTERED INDEX [IX_idPrikazEnter] ON [dbo].[GroupStudent] 
(	[idPrikazEnter] ASC)
go
CREATE NONCLUSTERED INDEX [IX_idPrikazLeave] ON [dbo].[GroupStudent] 
(	[idPrikazLeave] ASC)


--triggers
go
CREATE    TRIGGER [dbo].[GroupStudentPrikazLeave]
 ON dbo.GroupStudent
  FOR INSERT, UPDATE
AS 
  IF EXISTS(SELECT 'TRUE' FROM  
	INSERTED INNER JOIN dbo.GroupStudentFull 
ON INSERTED.idGroupStudent=GroupStudentFull.idGroupStudent
		WHERE INSERTED.idPrikazLeave IS NOT NULL
		AND GroupStudentFull.DateLeave<=GroupStudentFull.DateEnter)
  BEGIN   
      RAISERROR('Ошибка! Дата отчисления студента меньше даты зачисления', 16,1)
      ROLLBACK TRAN 
  END

  
  go
  CREATE    TRIGGER [dbo].[OnlyForOneGroup]
 ON dbo.Progress
  FOR INSERT, UPDATE
AS 
  IF EXISTS(SELECT 'TRUE' FROM INSERTED INNER JOIN
	dbo.GroupStudent InsertedGroupStudent 
		ON INSERTED.idGroupStudent=InsertedGroupStudent.idGroupStudent 
INNER JOIN	dbo.ReportWithGroup Report 
ON Report.idReport=INSERTED.idReport 
			AND InsertedGroupStudent.idGroup<>Report.idGroup)
  BEGIN   
      RAISERROR('Ошибка! В ведомость включен студент из другой группы', 16,1)
      ROLLBACK TRAN 
  END

  
  go
  CREATE    TRIGGER [dbo].[ThemeOnlyForKP]
 ON dbo.Progress
  FOR INSERT, UPDATE
AS 

  IF EXISTS(SELECT 'TRUE' FROM  
		INSERTED INNER JOIN
		dbo.Report ON INSERTED.idReport=Report.idReport INNER JOIN
		dbo.ReportType ON Report.idReportType=ReportType.idReportType
		WHERE INSERTED.Theme IS NOT NULL AND ReportType.WithTheme=0)
  BEGIN   
      RAISERROR('Ошибка! B данной ведомости не нужно заполнять темы 
работ', 16,1)
      ROLLBACK TRAN 
  END

  
  go
  CREATE    TRIGGER [dbo].[OnlyOpenReport]
 ON dbo.Progress
  FOR INSERT, UPDATE
AS 
  IF EXISTS(SELECT 'TRUE' FROM  
		INSERTED INNER JOIN
		dbo.Report ON INSERTED.idReport=Report.idReport 
		WHERE Report.IsClosed=1)
  BEGIN   
      RAISERROR('Ошибка! Нельзя редактировать закрытую ведомость', 16,1)
      ROLLBACK TRAN 
  END

  
  go
  CREATE    TRIGGER [dbo].[OnlyOpenReportDelete]
 ON dbo.Progress
  FOR DELETE
AS 
  IF EXISTS(SELECT 'TRUE' FROM  
		DELETED INNER JOIN
		dbo.Report ON DELETED.idReport=Report.idReport 
		WHERE Report.IsClosed=1)
  BEGIN   
      RAISERROR('Ошибка! Нельзя удалять данные из закрытой ведомости', 16,1)
      ROLLBACK TRAN 
  END

  
  go
 /* По одной отчетности по дисциплине для одного студента можно создать максимум 3 направления.
При реализации данного ограничения, чтобы избежать жестко заданного количества направлений (может быть, в следующем году их будет 5), создадим таблицу со служебными данными. В ней будет одна строка и несколько столбцов, которые будут добавляться по мере 
  необходимости. Первый столбец будет MaxExamRetakeCount со значением 3.*/
CREATE TABLE [dbo].[ServiceInfo](
	[MaxExamRetakeCount] [int] NOT NULL --макс кол-во направлений)
INSERT INTO [dbo].[ServiceInfo]
           ([MaxExamRetakeCount])
     VALUES (3)
	
	go
--После этого создадим триггер FOR INSERT:
CREATE    TRIGGER [dbo].[MaxCountForStudent]
 ON dbo.Progress  FOR INSERT
AS 
  IF EXISTS(SELECT InsertedReport.idDiscipline, 
InsertedReport.idReportType, InsertedReport.SemesterNumber,
		COUNT(OtherReports.idReport) FROM  
		INSERTED INNER JOIN
		dbo.Report InsertedReport ON InsertedReport.IsTheFirst=0
			AND INSERTED.idReport=InsertedReport.idReport INNER JOIN
		dbo.Report OtherReports ON OtherReports.IsTheFirst=0
		AND InsertedReport.idDiscipline=OtherReports.idDiscipline 
		AND InsertedReport.idReportType=OtherReports.idReportType 
		AND InsertedReport.SemesterNumber=OtherReports.SemesterNumber 
INNER JOIN
dbo.Progress ON Progress.idReport=OtherReports.idReport
			AND Progress.idGroupStudent=INSERTED.idGroupStudent
		GROUP BY InsertedReport.idDiscipline, 
InsertedReport.idReportType,			
InsertedReport.SemesterNumber
		HAVING COUNT(OtherReports.idReport)>
(SELECT MaxExamRetakeCount FROM dbo.ServiceInfo))
  BEGIN   
      RAISERROR('Ошибка! Вы превысили максимальное число направлений 
одному студенту по одной дисциплине', 16,1)
      ROLLBACK TRAN 
  END



