
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


go
CREATE FUNCTION [dbo].[GetStudentState] 
(	@idStudent INT,
	@date DATE)
RETURNS @Result TABLE
   (	idStudent 		INT,
OnDate		DATE,
GroupName		VARCHAR(15),
	StateName		VARCHAR(20),
	EnrollmentCategoryName VARCHAR(20), 
	DateEnter		DATE,
	DateLeave		DATE   ) 
AS
BEGIN 
INSERT INTO @Result(idStudent, OnDate, GroupName,
EnrollmentCategoryName,DateEnter,DateLeave)
SELECT @idStudent, @date, [Group].GroupName, 
EnrollmentCategoryName,DateEnter, DateLeave
FROM [dbo].[GetLastGroupStudentsForData](@date) StudGroup 
INNER JOIN	[dbo].[Group] 
ON StudGroup.idGroup=[Group].idGroup 
INNER JOIN	dbo.EnrollmentCategory 
ON StudGroup.idEnrollmentCategory=EnrollmentCategory.idEnrollmentCategory
WHERE idStudent=@idStudent

UPDATE @Result
SET StateName='Текущий'
WHERE DateLeave IS NULL OR DateLeave>@date

UPDATE @Result
SET StateName='Отчисленный'
WHERE StateName IS NULL

RETURN
END

go
CREATE FUNCTION [dbo].[GetContingentReport] 
(	@DateBegin DATE,
	@DateEnd   DATE)
RETURNS @Result TABLE
   (idGroup			INT,
	GroupName		VARCHAR(15),
	idEnrollmentCategory INT,
	EnrollmentCategoryName VARCHAR(20), 
	BeginCount		INT,
	EndCount		INT,
	EnterCount		INT,
	LeaveCount		INT ) 
AS
BEGIN 
INSERT INTO @Result(idGroup,GroupName,idEnrollmentCategory,
	EnrollmentCategoryName,BeginCount,EndCount,EnterCount,LeaveCount)
SELECT [Group].idGroup,GroupName,BeginStudents.idEnrollmentCategory,			EnrollmentCategoryName,BeginCount,EndCount,EnterCount,LeaveCount
FROM dbo.[Group] CROSS JOIN dbo.EnrollmentCategory
	LEFT JOIN
	(SELECT idGroup,idEnrollmentCategory,COUNT(idStudent)BeginCount
	FROM [dbo].[GetGroupStudentsForData](@DateBegin)
	GROUP BY idGroup,idEnrollmentCategory) BeginStudents
	ON [Group].idGroup=BeginStudents.idGroup
		AND EnrollmentCategory.idEnrollmentCategory=BeginStudents.idEnrollmentCategory
	LEFT JOIN 
	(SELECT idGroup,idEnrollmentCategory,COUNT(idStudent)EndCount
	FROM [dbo].[GetGroupStudentsForData](@DateEnd)
	GROUP BY idGroup,idEnrollmentCategory) EndStudents
	ON [Group].idGroup=EndStudents.idGroup
		AND EndStudents.idEnrollmentCategory=EnrollmentCategory.idEnrollmentCategory
	LEFT JOIN 
	(SELECT idGroup,idEnrollmentCategory,COUNT(idStudent)EnterCount
	FROM [dbo].[GroupStudentFull]
	WHERE DateEnter BETWEEN @DateBegin AND @DateEnd
	GROUP BY idGroup,idEnrollmentCategory) EnterStudents
	ON [Group].idGroup=EnterStudents.idGroup
		AND EnrollmentCategory.idEnrollmentCategory=EnterStudents.idEnrollmentCategory
	LEFT JOIN 
	(SELECT idGroup,idEnrollmentCategory,COUNT(idStudent)LeaveCount
	FROM [dbo].[GroupStudentFull]
	WHERE DateLeave BETWEEN @DateBegin AND @DateEnd
	GROUP BY idGroup,idEnrollmentCategory) LeaveStudents
	ON [Group].idGroup=LeaveStudents.idGroup
		AND LeaveStudents.idEnrollmentCategory=EnrollmentCategory.idEnrollmentCategory
WHERE BeginCount IS NOT NULL OR EndCount IS NOT NULL
	OR EnterCount IS NOT NULL OR LeaveCount IS NOT NULL
ORDER BY GroupName,EnrollmentCategoryName

-- итоговое суммирование 
INSERT INTO @Result(idGroup,GroupName,idEnrollmentCategory,
	EnrollmentCategoryName,BeginCount,EndCount,EnterCount,LeaveCount)
SELECT idGroup,GroupName,0,			
    'Итого',SUM(BeginCount),SUM(EndCount),SUM(EnterCount),SUM(LeaveCount)
FROM @Result
GROUP BY idGroup,GroupName
	
RETURN
END


CREATE FUNCTION [dbo].[GetAverProgressByGroup] 
(	@DateBegin DATE,
	@DateEnd   DATE)
RETURNS @Result TABLE
   (idGroup			INT,
	GroupName		VARCHAR(15),
	AverMark		NUMERIC(8,2))
AS
BEGIN 
INSERT INTO @Result(idGroup, GroupName, AverMark)
SELECT [Group].idGroup, GroupName, 
AVG(CONVERT(NUMERIC(8,2),ABS(BallCount)))
FROM [dbo].[ResultProgress] as Progress
	INNER JOIN dbo.[Group]
	ON Progress.idGroup=[Group].idGroup
WHERE DateReport BETWEEN @DateBegin AND @DateEnd
	AND idReportType=5	--экзамен
GROUP BY [Group].idGroup, GroupName
ORDER BY GroupName

RETURN
END

