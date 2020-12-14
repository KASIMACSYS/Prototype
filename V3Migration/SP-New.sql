USE [AC-BinHanif_V3.2]


/****** Object:  UserDefinedTableType [dbo].[TVP_STS_ProjectHierarchy]    Script Date: 10/28/2020 12:48:51 PM ******/
CREATE TYPE [dbo].[TVP_STS_ProjectHierarchy] AS TABLE(
	[parentid] [int] NULL,
	[level] [int] NULL,
	[ledgerid] [int] NULL
)
GO

IF (OBJECT_ID('GetSiteValues') IS NOT NULL)
  DROP PROCEDURE GetSiteValues
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetSiteValues]
	@CID				INT,
	@GroupID			VARCHAR(50),
	@UserName			nVARCHAR(50),
	@ApplicationType	INT,
	@BusinessPeriodID	INT				OUTPUT,
	@BusinessStartDate	DATE			OUTPUT
	
AS
			
	SELECT				Tag,Value 
	FROM				[ConfigParam]
	WHERE				CID = @CID
	UNION ALL
	select			'CurrencyCode',CurrencyCode 
	from			[CurrencyMaster] 
	where			CID=@CID 
	AND				BaseCurrencyFlag=1; 
								
	SELECT				@BusinessPeriodId=max(BusinessPeriodID) 
	FROM				[BusinessPeriodMaster]
	WHERE				CID = @CID;
	
	SELECT				@BusinessStartDate=StartDate 
	FROM				[BusinessPeriodMaster] 
	WHERE				CID = @CID AND BusinessPeriodID = @BusinessPeriodID;
	
	SELECT				MenuMgt.MenuID,MenuMgt.Description as CustomText, MenuMgt.Color,MenuMgt.ShortCutKey, MenuMgt.Parameters, MenuMgt.Options  
	FROM				[MenuMgt] as MenuMgt, [GroupMgtSub] as GroupPermission 
	WHERE				GroupPermission.CID = @CID AND MenuMgt.CID = @CID AND GroupPermission.GroupID = @GroupID and MenuMgt.MenuID=GroupPermission.MenuID 
						AND MenuMgt.ApplicationType = @ApplicationType AND GroupPermission.ApplicationType = @ApplicationType
	GROUP BY			MenuMgt.MenuID,MenuMgt.Description, MenuMgt.Color,MenuMgt.ShortCutKey, MenuMgt.Parameters, MenuMgt.Options;
	
	SELECT				GroupID,MenuID,Options 
	FROM				[GroupMgtSub] 
	WHERE				CID = @CID AND GroupID = @GroupID AND ApplicationType = @ApplicationType
	ORDER BY			MenuID,Options ASC;

	---------Code Change Blow code for MF--------------
	----#################################################
	
	
	SELECT				BusinessPeriodID,convert(VARCHAR,StartDate,106) as StartDate,convert(VARCHAR,EndDate,106) as EndDate,
						convert(bit,(case when (EndDate IS not Null) then 'False' else 'True' end))	as ChoosedBSPeriod 
	FROM				[BusinessPeriodMaster]
	WHERE				CID = @CID;


	SELECT				CONVERT(VARCHAR(20),LedgerID) AS LedgerID,SalesmanName
	FROM				[GroupMgtSalesMan]
	WHERE				CID = @CID AND GroupID=@GroupID 
	ORDER BY			SalesmanName;
			   
	SELECT				Tag,Value
	FROM				[GroupMgtGeneralSettings]
	WHERE				CID = @CID AND GroupID=@GroupID 
	ORDER BY			Tag;
			   
			   
	SELECT				TOP 1 LicenseDetails 
	FROM				[License]
	WHERE				CID = @CID
	ORDER BY			SlNo desc;

	DECLARE @DefaultLnge AS INT=1;
	
	SELECT @DefaultLnge=DefaultLngCode FROM [UserMgt] WHERE UserName=@userName AND CID=@CID
	
	SELECT * FROM [LanguageToken] WHERE LngCode=@DefaultLnge AND CID=@CID ORDER BY Description DESC

	SELECT * FROM [ErrorMsg] WHERE CID=@CID AND LngCode=@DefaultLnge

GO

IF (OBJECT_ID('GetMenuGrouping') IS NOT NULL)
  DROP PROCEDURE GetMenuGrouping
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetMenuGrouping] 
    @CID				INT,
    @ID					VARCHAR(10),
    @Flag				VARCHAR(20),
	@ApplicationType	INT
--UNLOCK-- WITH ENCRYPTION 
 AS 
 BEGIN
	
-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

   
	IF (@Flag='LOADTREE') ---LOAD TREE ONLY (GROUP) FROM PRODUCT GROUPING TABLE
		BEGIN  
			;WITH CTE (ID, Description, ParentID,SORT) as
				  (
					SELECT		ID, 
								Description, 
								ParentID,
								ROW_NUMBER() OVER(ORDER BY  SortID ASC) SORT
					FROM		[MenuGrouping] 
					WHERE		CID = @CID
					AND			ID = @ID
					
					UNION ALL
			       
					SELECT		A.ID, 
								A.Description, 
								A.ParentID,
								ROW_NUMBER() OVER(ORDER BY a.SortID ASC)  SORT
					FROM		[MenuGrouping] A
					INNER JOIN	CTE B 
					ON			B.ID=A.parentid
					WHERE		A.CID = @CID 
					
				  )
					SELECT		ID, 
								Description, 
								ParentID 
					FROM		CTE 
					ORDER BY	CTE.SORT ASC;
				
			
		END
	
	ELSE IF @Flag IN ('GROUPMGT','MENUGROUPING')
		BEGIN
			;WITH CTE (ID ,description,parent, SORTID, ShortCutKey, Options, Type,Icon,ApplicationType, [Parameters], WebIcon) AS
			(
				SELECT ID,Description,CAST(ParentID AS VARCHAR(20)),SortID, '', '', 'GROUP','',ApplicationType, '' as [Parameters], WebIcon FROM [MenuGrouping] 
				WHERE CID = @CID AND ApplicationType = @ApplicationType
				UNION ALL
				SELECT MenuID,Description,CAST(MenuGroupID AS VARCHAR(20)),SortID, ShortCutKey, Options, 'FORM',Icon,ApplicationType, [Parameters], WebIcon FROM [MenuMgt] MN 
				WHERE CID = @CID AND (@Flag='MENUGROUPING' OR LoadGroupMgt=1) AND ApplicationType = @ApplicationType --(ApplicationType & @ApplicationType) = @ApplicationType
			),
			CTE1 as
			(
				SELECT		CAST(CTE.ID AS VARCHAR(20)) as ID, CTE.Description ,CAST(CTE.parent AS VARCHAR(20)) AS PARENT,CTE.SORTID, 
							CTE.ShortCutKey, CTE.Options,
							CTE.Type,RIGHT(REPLICATE('0',5) + CAST(ROW_NUMBER() OVER(ORDER BY SORTID) as VARCHAR(MAX)),6) SORT,0 as [level],
							CTE.Icon,
							CTE.ApplicationType,
							CTE.Parameters,
							CTE.WebIcon
				FROM		CTE 
				WHERE		CTE.ID = @ID
				UNION ALL
				SELECT		CAST(CTE.ID AS VARCHAR(20)) as ID, CTE.Description ,CAST(CTE.PARENT AS VARCHAR(20)) AS PARENT,CTE.SORTID, 
							CTE.ShortCutKey, CTE.Options,
							CTE.Type,(CTE1.sort + RIGHT(REPLICATE('0',5) + CAST(ROW_NUMBER() 
							OVER(ORDER BY CTE.SORTID ASC) as VARCHAR(MAX)),6))  SORT, [level] + 1,
							CTE.Icon,
							CTE.ApplicationType,
							CTE.Parameters,
							CTE.WebIcon
				FROM		CTE  
				JOIN		CTE1 on CTE1.ID = CTE.parent
			)SELECT (CASE WHEN (Type='GROUP') THEN '' ELSE CAST(SortID AS VARCHAR(20)) END) as SlNo, REPLICATE('     ',CTE1.level)+ CAST(level as varchar(20))+ '.' +  CAST(sortid as varchar(20))+ '.' + 
			CTE1.Description as Description, CAST(ID AS VARCHAR(20)) AS MenuID,CTE1.Description as FormName,PARENT,SORTID, 
			ShortCutKey, Options, TYPE,SORT,level,cte1.Icon,CAST(CTE1.ApplicationType AS INT) AS ApplicationType, Parameters, WebIcon  FROM CTE1 order BY SORT;
		
		END

END

GO

IF (OBJECT_ID('STS_SetHierarchyConfig') IS NOT NULL)
  DROP PROCEDURE STS_SetHierarchyConfig
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[STS_SetHierarchyConfig]
	-- Add the parameters for the stored procedure here
  @CID			    INT,
  @AppGroupID	INT = 0,
  @Flag				VARCHAR(30),
  @ProjectUID	    INT,
  @AppGroupName     NVARCHAR(50),
  @dt               TVP_STS_ProjectHierarchy READONLY,
  @ApprovalGroupIDOUT	INT	OUTPUT,
  @ERRORNO			INT	OUTPUT,
  @ERRORDESC		VARCHAR(max) OUTPUT

  --WITH ENCRYPTION

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
    
	BEGIN TRY
	BEGIN TRANSACTION @ERRORDESC

		IF @Flag='EDIT' OR @Flag='DELETE'
			DELETE FROM [STS_ApprovalGroupSub] where CID=@CID AND ApprovalGroupID = @AppGroupID;

			IF @Flag='DELETE'
				DELETE FROM [STS_ApprovalGroup] where CID=@CID AND ApprovalGroupID = @AppGroupID;

		IF (@Flag='ADD' or @Flag='EDIT')
			BEGIN
				IF (@Flag='ADD')
					INSERT INTO		[STS_ApprovalGroup] (CID, TypeID, ApprovalGroupName, IsActive) VALUES (@CID, @ProjectUID, @AppGroupName, 1);

				ELSE IF (@Flag='EDIT')
					UPDATE [STS_ApprovalGroup]  set TypeID = @ProjectUID, ApprovalGroupName = @AppGroupName  where CID=@CID AND ApprovalGroupID = @AppGroupID;
								 
			
				SELECT @AppGroupID = ApprovalGroupID FROM [STS_ApprovalGroup] WHERE CID=@CID AND TypeID=@ProjectUID and ApprovalGroupName = @AppGroupName;	

				INSERT INTO  [STS_ApprovalGroupSub] (ApprovalGroupID,parentid,ApproveLevel,ledgerid,CID)
				SELECT        @AppGroupID, parentid, level, ledgerid, @CID from @dt
					
			END
     
		SET @ApprovalGroupIDOUT = @AppGroupID;
	COMMIT TRANSACTION
		SET @ERRORNO = 0
		--SET @DESC='Sucessfully'+''+@Flag+'ED'+''+'BOM Details'+' : '+@BOMNo		
		set @ERRORDESC = ''
		--EXEC ElogUpdate @CID,@BusinessPeriodID,@CreatedBy,@CreatedDate,'','BOM',@ERRORNO,@DESC,@ERRORDESC,7,0,4;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		set @ERRORNO = ERROR_NUMBER()
		--SET @DESC='ERROR IN '+''+@Flag+'ED'+''+'BOM Details'+' : '+@BOMNo
		set @ERRORDESC = ERROR_MESSAGE()
		--EXEC ElogUpdate @CID,@BusinessPeriodID,@CreatedBy,@CreatedDate,'','BOM',@ERRORNO,@DESC,@ERRORDESC,5,3,4;
	END CATCH
		
END

GO
IF (OBJECT_ID('GetMenuGrouping') IS NOT NULL)
  DROP PROCEDURE GetMenuGrouping
--GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetMenuGrouping] 
    @CID				INT,
    @ID					VARCHAR(10),
    @Flag				VARCHAR(20),
	@ApplicationType	INT
--UNLOCK-- WITH ENCRYPTION 
 AS 
 BEGIN
	
-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

   
	IF (@Flag='LOADTREE') ---LOAD TREE ONLY (GROUP) FROM PRODUCT GROUPING TABLE
		BEGIN  
			;WITH CTE (ID, Description, ParentID,SORT) as
				  (
					SELECT		ID, 
								Description, 
								ParentID,
								ROW_NUMBER() OVER(ORDER BY  SortID ASC) SORT
					FROM		[MenuGrouping] 
					WHERE		CID = @CID
					AND			ID = @ID
					
					UNION ALL
			       
					SELECT		A.ID, 
								A.Description, 
								A.ParentID,
								ROW_NUMBER() OVER(ORDER BY a.SortID ASC)  SORT
					FROM		[MenuGrouping] A
					INNER JOIN	CTE B 
					ON			B.ID=A.parentid
					WHERE		A.CID = @CID 
					
				  )
					SELECT		ID, 
								Description, 
								ParentID 
					FROM		CTE 
					ORDER BY	CTE.SORT ASC;
				
			
		END
	
	ELSE IF @Flag IN ('GROUPMGT','MENUGROUPING')
		BEGIN
			;WITH CTE (ID ,description,parent, SORTID, ShortCutKey, Options, Type,Icon,ApplicationType, [Parameters], WebIcon) AS
			(
				SELECT ID,Description,CAST(ParentID AS VARCHAR(20)),SortID, '', '', 'GROUP','',ApplicationType, '' as [Parameters], WebIcon FROM [MenuGrouping] 
				WHERE CID = @CID AND ApplicationType = @ApplicationType
				UNION ALL
				SELECT MenuID,Description,CAST(MenuGroupID AS VARCHAR(20)),SortID, ShortCutKey, Options, 'FORM',Icon,ApplicationType, [Parameters], WebIcon FROM [MenuMgt] MN 
				WHERE CID = @CID AND (@Flag='MENUGROUPING' OR LoadGroupMgt=1) AND ApplicationType = @ApplicationType --(ApplicationType & @ApplicationType) = @ApplicationType
			),
			CTE1 as
			(
				SELECT		CAST(CTE.ID AS VARCHAR(20)) as ID, CTE.Description ,CAST(CTE.parent AS VARCHAR(20)) AS PARENT,CTE.SORTID, 
							CTE.ShortCutKey, CTE.Options,
							CTE.Type,RIGHT(REPLICATE('0',5) + CAST(ROW_NUMBER() OVER(ORDER BY SORTID) as VARCHAR(MAX)),6) SORT,0 as [level],
							CTE.Icon,
							CTE.ApplicationType,
							CTE.Parameters,
							CTE.WebIcon
				FROM		CTE 
				WHERE		CTE.ID = @ID
				UNION ALL
				SELECT		CAST(CTE.ID AS VARCHAR(20)) as ID, CTE.Description ,CAST(CTE.PARENT AS VARCHAR(20)) AS PARENT,CTE.SORTID, 
							CTE.ShortCutKey, CTE.Options,
							CTE.Type,(CTE1.sort + RIGHT(REPLICATE('0',5) + CAST(ROW_NUMBER() 
							OVER(ORDER BY CTE.SORTID ASC) as VARCHAR(MAX)),6))  SORT, [level] + 1,
							CTE.Icon,
							CTE.ApplicationType,
							CTE.Parameters,
							CTE.WebIcon
				FROM		CTE  
				JOIN		CTE1 on CTE1.ID = CTE.parent
			)SELECT (CASE WHEN (Type='GROUP') THEN '' ELSE CAST(SortID AS VARCHAR(20)) END) as SlNo, REPLICATE('     ',CTE1.level)+ CAST(level as varchar(20))+ '.' +  CAST(sortid as varchar(20))+ '.' + 
			CTE1.Description as Description, CAST(ID AS VARCHAR(20)) AS MenuID,CTE1.Description as FormName,PARENT,SORTID, 
			ShortCutKey, Options, TYPE,SORT,level,cte1.Icon,CAST(CTE1.ApplicationType AS INT) AS ApplicationType, Parameters, WebIcon  FROM CTE1 order BY SORT;
		
		END

END

IF (OBJECT_ID('STS_GetLeaveRequestReport') IS NOT NULL)
  DROP PROCEDURE STS_GetLeaveRequestReport
GO
--DROP TYPE [dbo].[TVP_STS_EmpLeaveRpt]
--GO
/****** Object:  UserDefinedTableType [dbo].[TVP_STS_EmpLeaveRpt]    Script Date: 10/27/2020 7:55:20 PM ******/
CREATE TYPE [dbo].[TVP_STS_EmpLeaveRpt] AS TABLE(
	[LID] [int] NULL
)
GO

IF (OBJECT_ID('STS_SetLeaveApproval') IS NOT NULL)
  DROP PROCEDURE STS_SetLeaveApproval
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[STS_SetLeaveApproval]
  --Add the parameters for the stored procedure here
	@CID				VARCHAR(10),
	@Flag				VARCHAR(30),
	@LedgerID			VARCHAR(20),
	@LeaveID			VARCHAR(30),
	@LeaveType		    VARCHAR(30),
	@Comments           VARCHAR(250),
	@DayStatus          VARCHAR(10),	
	@FromDate			DATE,
	@ToDate				DATE,
	@ReturnDate			VARCHAR(20),
	@Days			    VARCHAR(2),
	@Session            VARCHAR(20),		
    @UserID				VARCHAR(20),
    @EmpUniqID			VARCHAR(20),
	@GroupID			VARCHAR(20),
	@Year				VARCHAR(10),
	@Type				VARCHAR(20),
	@ReturnValue		INT			 OUTPUT,
	@ErrorMessage	    VARCHAR(MAX) OUTPUT	
	
	--WITH ENCRYPTION
		
AS
BEGIN
	DECLARE @LeaveTypeCategory      VARCHAR(25);
	DECLARE @SQLSTRING		NVARCHAR(MAX);
    DECLARE @COUNT1		    INT;		
	DECLARE	@SUCCESS	    INT;
	DECLARE	@INTNUM		    INT;
	DECLARE	@DATECOUNT	    INT;
	DECLARE	@DATECOUNT1	    INT;
	DECLARE	@ROWCOUNT	    INT;
	DECLARE @CurrentTime	DATETIME;	
	DECLARE @DESC			VARCHAR(MAX);	
	DECLARE @MaxLeaveID		INT;
	DECLARE @MaxLeaveSubID	INT;
	DECLARE @FDATE			DATE, @TDATE  DATE,@RTNDATE   DATE;
	DECLARE @AUTHLEVEL		INT,  @MAXAUTHLEVEL INTEGER;		
	DECLARE @RtnLedgerID	INT;
	DECLARE @RtnLeaveSubID	INT;	
	DECLARE @TimezonID		INT;
	DECLARE @RtnTag			INT;
	DECLARE @RtnWeekEnd		INT;
	DECLARE	@RtnHoliday		INT;	
	DECLARE @RtnCount       INT;
	DECLARE @LateRtn		INT;
	SET     @CurrentTime	=CURRENT_TIMESTAMP;
			
 		
  SELECT @RtnLedgerID=LedgerID FROM EmployeeMaster  WHERE LedgerID=@LedgerID AND CID=@CID;											

  SELECT @TimezonID=TimeZoneID FROM [STS_EmployeeMasterSub] WHERE LedgerID=@LedgerID AND CID=@CID;	
  
  IF(@LeaveType <>'Select')  
	 SELECT @LateRtn=AllowLateReturn FROM [STS_LeaveTypeMaster] WHERE LID=@LeaveType AND CID=@CID;	
	
	IF(@LeaveType <>'Select')
     BEGIN
			SELECT  @RtnCount=COUNT(*) FROM [STS_LeaveTypeMasterSub] where Lid=@LeaveType and ISactive=1 AND CID=@CID
			
		 IF(@RtnCount =2)
			 SET @LeaveTypeCategory='Both';		
		ELSE IF(@RtnCount =1)
			BEGIN
				SELECT @LeaveTypeCategory=CategoryType FROM [STS_LeaveTypeMasterSub] where Lid=@LeaveType and ISactive=1 AND CID=@CID											 					 
			END
		ELSE
		   SET @LeaveTypeCategory='Default';			
	END					
		 
  BEGIN TRY
	BEGIN TRANSACTION	
	
  IF(@Type='1')
    BEGIN  
	  IF(@Flag='ADD')
	    BEGIN
	     SET @FDATE=@FromDate;
		 SET @TDATE=@ToDate;				 		
		 	
	    IF(@FDATE<=@TDATE)
	      BEGIN				
			SELECT	 @MAXAUTHLEVEL=MAX(AuthLevel) FROM [STS_Authoriser] 
			WHERE	 AuthGroupID IN  (SELECT	s.AuthGroupID FROM	[STS_AuthoriseGroupSub] s WHERE	s.LedgerID=@LedgerID AND CID=@CID) 
			AND		 CID=@CID		
							  	 		
							  	 
			 IF(NOT EXISTS(SELECT * FROM [STS_LeaveMgt]  WHERE  (FromDate<=@FDATE AND ToDate>=@FDATE OR FromDate<=@TDATE AND ToDate>=@TDATE) AND LedgerID= @LedgerID AND CID=@CID) )
				 BEGIN
						INSERT  INTO  [STS_LeaveMgt]
										  (
											LedgerID,
											FromDate,
											ToDate,
											StatusID,
											RequestType,
											Comments,
											ApprovedLevel,
											EntryDate,
											Mode,
											LeaveCategory,
											CreatedBy,
											CID
										   ) 
								VALUES     (
											 @LedgerID,
											 @FromDate,
											 @ToDate,
											 1,
											 @LeaveType,
											 @Comments,
										     @MAXAUTHLEVEL,
											 CURRENT_TIMESTAMP,
											 2,
											 @LeaveTypeCategory,
											 @EmpUniqID,
											 @CID
											)
					         
							SELECT	 @MaxLeaveID =ISNUll(MAX(LeaveID),1) FROM [STS_LeaveMgt] where CID=@CID
					         
                         IF(@LateRtn !=1)
						     BEGIN
							    	UPDATE		[STS_LeaveMgt] 
									SET		    RtnDate=@ToDate										
									WHERE		LeaveID=@MaxLeaveID AND CID=@CID;
							 END 

							INSERT  INTO  [STS_LeaveMgtSub]
											(
												LeaveID,
												FromDate,
												ToDate,
												StatusID,
												ApporvedType,
												DayStatus,
												SessionType,
												Comments,
												CID
											) 
									VALUES  (  
												@MaxLeaveID,
												@FromDate,
												@ToDate,
												1,
												@LeaveType,
												@DayStatus,
												@Session,
												@Comments,
												@CID
											)
										
							SELECT   @MaxLeaveSubID = MAX(LeaveSubID) FROM [STS_LeaveMgtSub] where CID=@CID
					         	
	     					 INSERT  INTO  [STS_LeaveMgtAuthorise]
											 (
												LeaveSubID,
												AuthorisedBy,
												AuthLevel,
												AuthorisedDate,
												StatusID,
												Comments,
												CID
											  ) 	     										  
									  VALUES  (
												@MaxLeaveSubID,
												@EmpUniqID,
												@MAXAUTHLEVEL,
												CURRENT_TIMESTAMP,
												1,
												@Comments,
												@CID
											   )
					        	
       					   INSERT	INTO [STS_LeaveMgtHistory]
											(
												LeaveSubID,
												FromDate,
												ToDate,
												StatusID,
												ApprovedType,
												days,
												SessionType,
												Comments,
												EntryDate,
												CID
											 ) 
									VALUES	 (
												@MaxLeaveSubID,
												@FromDate,
												@ToDate,
												1,
												@LeaveType,
												1,
												@Session,
												@Comments,
												CURRENT_TIMESTAMP,
												@CID
											 )
			       											 
	      			 SET @FDATE= DATEADD(day, -1 ,@FromDate);
	      				
	      			 SELECT @RtnHoliday=IsActive FROM [STS_LeaveTypeMasterSub] WHERE  CategoryType='PublicHolidays' AND LID=@LeaveType AND CID=@CID;
	      							      			       	
			         SELECT @RtnWeekEnd=IsActive FROM [STS_LeaveTypeMasterSub] WHERE  CategoryType='WeekEnds' AND LID=@LeaveType AND CID=@CID;
			      						      	       	
	       			 SET @SQLSTRING    ='INSERT INTO [STS_Attendance](AttendanceDate,Type,LeaveID,FullOrHalf,LedgerID,CID) 
	       												SELECT
														dt,@LeaveType, @MaxLeaveSubID,@DayStatus,@LedgerID,@CID
														FROM 
														(
														   SELECT DATEADD(d, ROW_NUMBER() OVER (ORDER BY name), @FDATE) AS dt 
														   FROM 
														   sys.columns a
														)  AS dates 
														WHERE 
														dt >= @FromDate AND dt <= @ToDate'
													  --AND dates.dt NOT IN(SELECT HolidayDate FROM [STS_Holidays] where TimeZoneID=@TimezonID AND CID=@CID)
													  --AND	datename(dw, dt) NOT IN (SELECT WeekEnds FROM [STS_WeekEnds] where TimeZoneID=@TimezonID AND CID=@CID)																													       				
	       				IF(@RtnHoliday='0')
						  BEGIN
							  SET @SQLSTRING =@SQLSTRING +' AND dates.dt NOT IN(SELECT HolidayDate FROM [STS_Holidays] WHERE TimeZoneID=@TimezonID AND CID='''+@CID+''')'
						  END  
					   IF(@RtnWeekEnd='0')
						  BEGIN
							  SET @SQLSTRING =@SQLSTRING +' AND	datename(dw, dt) NOT IN (SELECT WeekEnds FROM [STS_WeekEnds] WHERE TimeZoneID=@TimezonID AND CID='''+@CID+''')' 
						  END
					     																																		
			       		 EXECUTE sp_executesql @SQLSTRING,
			       								N'@LedgerID VARCHAR(20),@LeaveType VARCHAR(20),@MaxLeaveSubID INT,@DayStatus VARCHAR(20),@FromDate VARCHAR(20),@ToDate VARCHAR(20),@TimezonID VARCHAR(20),@FDATE DATE,@CID INT',
			       								  @LedgerID =@LedgerID,@LeaveType =@LeaveType,@MaxLeaveSubID =@MaxLeaveSubID,@DayStatus =@DayStatus,@FromDate =@FromDate,@ToDate =@ToDate,@TimezonID =@TimezonID,@FDATE =@FDATE,@CID  =@CID;

 ---- *******   LEAVE APPROVAL  MAIL PROCESS ********  ---------------

					  SELECT Tag FROM [STS_CommonConfiguration] WHERE Type='CompanyDetails' AND MenuID='STS_21' AND CID=@CID;							
									
					  SELECT Tag FROM [STS_CommonConfiguration] WHERE Type='SmtpProtocal' AND MenuID='STS_21' AND CID=@CID;							
					 					       
					  SELECT Tag FROM [STS_CommonConfiguration]  WHERE Type='Leave Approval' AND MenuID='STS_21' AND CID=@CID;				
					 	
					  SELECT EMS.PreEmail1 AS EmailID,ER.AliasName1 AS Name  
					  FROM	[EmployeeMaster] ER Inner join  [STS_EmployeeMasterSub] EMS ON ER.LedgerID=EMS.LedgerID AND ER.CID=EMS.CID                                                                                                      
					  WHERE	ER.LedgerID IN ((SELECT LM.LedgerID FROM [STS_LeaveMgt] LM WHERE LM.LedgerID=@LedgerID AND LM.CID=@CID))
					 
	                   SELECT			TOP(1)e.AliasName1 as Name,m.EntryDate AS EntryDate,LTM.LeaveType as CategoryName ,
										(CASE WHEN s.DayStatus=1 THEN 'Full Day' ELSE 'Half Day' END) as 'Days',m.FromDate AS FromDate,m.ToDate AS ToDate,
										DATEDIFF(day, m.FromDate, m.ToDate)+1 AS CalendarDay,
										CASE WHEN (m.RequestType=116) THEN (DATEDIFF(DAY, m.FromDate, m.ToDate)+s.DayStatus- dbo.fn_WorkingDays(@CID,m.FromDate,m.ToDate,@LedgerID,m.LeaveID,m.LeaveCategory))  
										ELSE dbo.fn_WorkingDays(@CID,m.FromDate,m.ToDate,@LedgerID,m.LeaveID,m.LeaveCategory)  END AS DaysRequested, 
										ls.LeaveSname AS 'Status',e.EmpID AS Email,
										(SELECT LTM.LeaveType AS CategoryName FROM	[STS_LeaveTypeMaster] 
										WHERE	LID=s.ApporvedType AND CID=s.CID) AS ApprovedType,
										m.Comments
						FROM			[STS_LeaveMgt] m 
						INNER JOIN		[STS_LeaveMgtSub] s  ON m.LeaveID=s.LeaveID and M.CID=s.CID
						INNER JOIN		[EmployeeMaster] e ON e.LedgerID=m.LedgerID AND e.CID=m.CID
						INNER JOIN		[STS_LeaveTypeMaster]LTM ON LTM.LID=m.RequestType AND LTM.CID=m.CID
						INNER JOIN		[STS_LeaveStausConfiguration] ls ON m.StatusID=ls.LeaveSID AND m.CID=ls.CID
						WHERE			 m.LedgerID=@LedgerID AND YEAR(m.EntryDate)=@Year AND m.CID=@CID ORDER BY m.LeaveID DESC;
					
					   SELECT tag  FROM [STS_CommonConfiguration]  WHERE Type='NetworkCredentialMailID'  AND MenuID='STS_21' AND CID=@CID;	    
										 
					   SELECT tag  FROM [STS_CommonConfiguration]  WHERE Type='NetworkCredentialPassword' AND MenuID='STS_21' AND CID=@CID;	    
					
					   SELECT tag  FROM [STS_CommonConfiguration]  WHERE Type='NetworkCredentialPort' AND MenuID='STS_21' AND CID=@CID;    
				

					 SELECT		 e.AliasName1 as Name,1 AS AuthLevel,s.LeaveSname as 'Status',a.Comments
					 FROM		 [EmployeeMaster] e 
					 INNER JOIN	 [STS_LeaveMgtAuthorise] a ON a.AuthorisedBy=e.LedgerID AND a.CID=e.CID
					 INNER JOIN	 [STS_LeaveStausConfiguration] s ON a.StatusID=s.LeaveSID AND a.CID=s.CID
					 WHERE		 a.LeaveSubID=(select Max(LeaveSubID) from [STS_LeaveMgtSub] where CID=@CID) 
  
				   
	       				 SET @ReturnValue =0;
						 SET @ErrorMessage='Record inserted successfully';
				   END 
				ELSE
					BEGIN
						SET @ReturnValue =2;
						SET @ErrorMessage='Record already exist';
					END
				END 		    	         
	     ELSE
		  BEGIN
			SET @ReturnValue =2;
			SET @ErrorMessage='Invalid date selection';
		  END 
	 END
   
   IF(@Flag='RETURN')	 
	 BEGIN
	       SET @TDATE=CONVERT(DATE,@ToDate,105);
		   SET @RTNDATE=CONVERT(DATE,@ReturnDate,105);	
		   DECLARE @RtnLveSubID INT;
		   DECLARE @RtnMaxLeaveSubID INT;	
		 
		  IF(@TDATE != @RTNDATE AND @RTNDATE > @TDATE AND @LateRtn =1)
		     BEGIN
			     UPDATE	[STS_LeaveMgt] SET RtnDate=CONVERT(DATE,@ReturnDate,105) WHERE LeaveID=@LeaveID AND CID=@CID;

				 SELECT @RtnLveSubID=LeaveSubID FROM [STS_LeaveMgtSub] WHERE LeaveID=@LeaveID AND CID=@CID;

				 INSERT INTO [STS_LeaveMgtSub](LeaveID,FromDate,ToDate,StatusID,ApporvedType,DayStatus,SessionType,Comments,CID) 
				 VALUES (@LeaveID, DATEADD(day,1,CONVERT(DATE,@ToDate,105)),CONVERT(DATE,@ReturnDate,105),1,@LeaveType,@DayStatus,@Session,@Comments,@CID)

				 SELECT @RtnMaxLeaveSubID=MAX(LeaveSubID) FROM [STS_LeaveMgtSub] WHERE LeaveID=@LeaveID AND CID=@CID;

				 INSERT INTO [STS_LeaveMgtAuthorise](LeaveSubID,AuthorisedBy,AuthLevel,AuthorisedDate,StatusID,Comments,CID) 	     										  
				 VALUES (@RtnMaxLeaveSubID,@EmpUniqID,1,CURRENT_TIMESTAMP,1,@Comments,@CID)
					        	
       			 INSERT	INTO [STS_LeaveMgtHistory](LeaveSubID,FromDate,ToDate,StatusID,ApprovedType,days,SessionType,Comments,EntryDate,CID) 
				  VALUES (@RtnMaxLeaveSubID,DATEADD(day,1,CONVERT(DATE,@ToDate,105)),CONVERT(DATE,@ReturnDate,105),1,@LeaveType,1,@Session,@Comments,CURRENT_TIMESTAMP,@CID)
			       											 
	      			 SET @TDATE=CONVERT(DATETIME, @ToDate,105);
	      				
	      			 SELECT @RtnHoliday=IsActive FROM [STS_LeaveTypeMasterSub] WHERE  CategoryType='PublicHolidays' AND LID=@LeaveType AND CID=@CID;
	      							      			       	
			         SELECT @RtnWeekEnd=IsActive FROM [STS_LeaveTypeMasterSub] WHERE  CategoryType='WeekEnds' AND LID=@LeaveType AND CID=@CID;
			      						      	       	
	       			 SET @SQLSTRING    ='INSERT INTO [STS_Attendance](AttendanceDate,Type,LeaveID,FullOrHalf,LedgerID,CID) 
	       												SELECT
														dt,@LeaveType, @RtnMaxLeaveSubID,@DayStatus,@LedgerID,@CID
														FROM 
														(
														   SELECT DATEADD(d, ROW_NUMBER() OVER (ORDER BY name), CAST(@TDATE AS DATETIME)) AS dt 
														   FROM 
														   sys.columns a
														)  AS dates 
														WHERE 
														dt >= CONVERT(DATE,@ToDate,105) AND dt <= CONVERT(DATE,@ReturnDate,105)'
													 																												       				
	       				IF(@RtnHoliday='0')
						  BEGIN
							  SET @SQLSTRING =@SQLSTRING +' AND dates.dt NOT IN(SELECT HolidayDate FROM [STS_Holidays] WHERE TimeZoneID=@TimezonID AND CID='''+@CID+''')'
						  END  
					   IF(@RtnWeekEnd='0')
						  BEGIN
							  SET @SQLSTRING =@SQLSTRING +' AND	datename(dw, dt) NOT IN (SELECT WeekEnds FROM [STS_WeekEnds] WHERE TimeZoneID=@TimezonID AND CID='''+@CID+''')' 
						  END
					     																																		
			       		 EXECUTE sp_executesql @SQLSTRING,
			       								N'@LedgerID VARCHAR(20),@LeaveType VARCHAR(20),@RtnMaxLeaveSubID INT,@DayStatus VARCHAR(20),@ToDate VARCHAR(20),@ReturnDate VARCHAR(20),@TimezonID VARCHAR(20),@TDATE DATE,@CID INT',
			       								  @LedgerID =@LedgerID,@LeaveType =@LeaveType,@RtnMaxLeaveSubID =@RtnMaxLeaveSubID,@DayStatus =@DayStatus,@ToDate =@ToDate,@ReturnDate =@ReturnDate,@TimezonID =@TimezonID,@TDATE =@TDATE,@CID  =@CID;
			
			       	SET @ReturnValue =0;
					SET @ErrorMessage='Record updated successfully';
			 END
       ELSE
	     BEGIN
		    UPDATE [STS_LeaveMgt] SET RtnDate=CONVERT(DATE,@ReturnDate,105) WHERE LeaveID=@LeaveID AND CID=@CID;
			
			SET @ReturnValue =0;
			SET @ErrorMessage='Record updated successfully';
		 END		     
	 END	   
  IF(@Flag='EDIT')
	   BEGIN
	
			SELECT	@RtnLeaveSubID=LeaveSubID FROM [STS_LeaveMgtSub] WHERE LeaveID=@LeaveID AND CID=@CID
			                         									   
			DELETE  FROM [STS_Attendance] WHERE LeaveID=@RtnLeaveSubID AND CID=@CID;
									   	 	    
			SET @FDATE=CONVERT(DATE,@FromDate,105);
			SET @TDATE=CONVERT(DATE,@ToDate,105);			
						
	    IF(@FDATE<=@TDATE)
	      BEGIN	
				SELECT	 @MAXAUTHLEVEL=MAX(AuthLevel) FROM [STS_Authoriser] 
				WHERE	 AuthGroupID 
				IN        (
							SELECT	s.AuthGroupID 
							FROM	[STS_AuthoriseGroupSub] s 
							WHERE	s.LedgerID=@LedgerID
							AND		CID=@CID
						  )
				AND		 CID=@CID
							  	 
				SELECT	 @AUTHLEVEL=AuthLevel FROM	 [STS_Authoriser] 
				WHERE	 LedgerID=@EmpUniqID
				AND		 AuthGroupID 
				IN		 (
							SELECT	s.AuthGroupID 
							FROM	[STS_AuthoriseGroupSub] s 
							WHERE	s.LedgerID=@LedgerID
							AND		CID=@CID
						  )
				AND		 CID=@CID
		   --IF(NOT EXISTS(SELECT * FROM LeaveMgt WHERE FromDate<=@FDATE AND ToDate>=@FDATE AND FromDate<=@TDATE AND ToDate>=@TDATE AND LedgerID= @LedgerID))
			 --BEGIN
						 UPDATE		[STS_LeaveMgt] 
						 SET		FromDate=CONVERT(DATE,@FromDate,105),
									ToDate=CONVERT(DATE,@ToDate,105),
									RequestType=@LeaveType,
									Comments=@Comments 
						 WHERE		LeaveID=@LeaveID AND CID=@CID;
																	  
						 UPDATE		[STS_LeaveMgtSub] 
						 SET		FromDate=CONVERT(DATE,@FromDate,105),
									ToDate=CONVERT(DATE,@ToDate,105),
									ApporvedType=@LeaveType,
									DayStatus=@DayStatus,
									SessionType=@Session
						 WHERE		LeaveID=@LeaveID AND CID=@CID;	    
			       									
				 SELECT  @MaxLeaveSubID = MAX(LeaveSubID)FROM [STS_LeaveMgtSub] where CID=@CID
			         	
	     		 INSERT  INTO  [STS_LeaveMgtAuthorise]
								 (
									LeaveSubID,
									AuthorisedBy,
									AuthLevel,
									AuthorisedDate,
									StatusID,
									Comments,
									CID
								  ) 	     										  
  						  VALUES  (
  						            @MaxLeaveSubID,
  						            @EmpUniqID,
  						            @MAXAUTHLEVEL,
  						            CURRENT_TIMESTAMP,
  						            1,
  						            @Comments,
  						            @CID
  						           )
	     		  						           
	       		   INSERT	INTO	[STS_LeaveMgtHistory]
	       										    (
	       												LeaveSubID,
	       												FromDate,
	       												ToDate,
	       												StatusID,
	       												ApprovedType,
	       												days,
	       												SessionType,
	       												Comments,
	       												EntryDate,
	       												CID
	       											 ) 
	       									VALUES	 (
	       												@MaxLeaveSubID,
	       												CONVERT(DATE,@FromDate,105),
	       												CONVERT(DATE,@ToDate,105),
	       												1,
	       												@LeaveType,
	       												1,
	       												@Session,
	       												@Comments,
	       												CURRENT_TIMESTAMP,
	       												@CID
	       											 )
	      			SET @FDATE=CONVERT(datetime, @FromDate,105)-1;
			      	       				       			
	       			SELECT @RtnHoliday=IsActive FROM [STS_LeaveTypeMasterSub] WHERE  CategoryType='PublicHolidays' AND LID=@LeaveType AND CID=@CID;
	      								      			       	
			        SELECT @RtnWeekEnd=IsActive FROM [STS_LeaveTypeMasterSub] WHERE  CategoryType='WeekEnds' AND LID=@LeaveType AND CID=@CID;
			      						      	       	
	       			 SET @SQLSTRING    ='INSERT INTO [STS_Attendance](AttendanceDate,Type,LeaveID,FullOrHalf,LedgerID,CID) 
	       												SELECT
														dt,@LeaveType, @RtnLeaveSubID,@DayStatus,@LedgerID,@CID
														FROM 
														(
														   SELECT DATEADD(d, ROW_NUMBER() OVER (ORDER BY name),CAST(@FDATE AS DATETIME)) AS dt 
														   FROM 
														   sys.columns a
														)  AS dates 
														WHERE 
														dt >= CONVERT(DATE,@FromDate,105) AND dt <= CONVERT(DATE,@ToDate,105)'																												       				
	       			   IF(@RtnHoliday='0')
						  BEGIN
							  SET @SQLSTRING =@SQLSTRING +' AND dates.dt NOT IN(SELECT HolidayDate FROM [STS_Holidays] WHERE TimeZoneID=@TimezonID AND CID='''+@CID+''')'
						  END  
					   IF(@RtnWeekEnd='0')
						  BEGIN
							  SET @SQLSTRING =@SQLSTRING +' AND	datename(dw, dt) NOT IN (SELECT WeekEnds FROM [STS_WeekEnds] WHERE TimeZoneID=@TimezonID AND CID='''+@CID+''')' 
						  END
					     																																		
			       		 EXECUTE sp_executesql @SQLSTRING,
			       								N'@LedgerID VARCHAR(20),@LeaveType VARCHAR(20),@RtnLeaveSubID INT,@DayStatus VARCHAR(20),@FromDate VARCHAR(20),@ToDate VARCHAR(20),@TimezonID VARCHAR(20),@FDATE DATE,@CID  INT',
			       								  @LedgerID =@LedgerID,@LeaveType =@LeaveType,@RtnLeaveSubID =@RtnLeaveSubID,@DayStatus =@DayStatus,@FromDate =@FromDate,@ToDate =@ToDate,@TimezonID =@TimezonID,@FDATE =@FDATE,@CID  =@CID;


  ---- *******   LEAVE APPROVAL EDIT MAIL PROCESS ********  -------------

					  SELECT Tag FROM [STS_CommonConfiguration] WHERE Type='CompanyDetails' AND MenuID='STS_21' AND CID=@CID;							
									
					  SELECT Tag FROM [STS_CommonConfiguration] WHERE Type='SmtpProtocal' AND MenuID='STS_21' AND CID=@CID;							
					 					       
					  SELECT Tag FROM [STS_CommonConfiguration]  WHERE Type='Leave Approval' AND MenuID='STS_21' AND CID=@CID;				
					 	
					  SELECT EMS.PreEmail1 AS EmailID,ER.AliasName1 AS Name  
					  FROM	[EmployeeMaster] ER Inner join  [STS_EmployeeMasterSub] EMS ON ER.LedgerID=EMS.LedgerID  AND ER.CID=EMS.CID                                                                                                    
					  WHERE	ER.LedgerID IN ((SELECT LM.LedgerID FROM [STS_LeaveMgt] LM WHERE LM.LedgerID=@LedgerID AND Lm.CID=@CID))
					 
	                   SELECT			TOP(1)e.AliasName1 as Name,CONVERT(VARCHAR(10),m.EntryDate,105) AS EntryDate,LTM.LeaveType as CategoryName ,
										(CASE WHEN s.DayStatus=1 THEN 'Full Day' ELSE 'Half Day' END) as 'Days',CONVERT(VARCHAR(10),m.FromDate,105) AS FromDate,CONVERT(VARCHAR(10),m.ToDate,105) AS ToDate,
										DATEDIFF(day, m.FromDate, m.ToDate)+1 AS CalendarDay,
										CASE WHEN (m.RequestType=116) THEN (DATEDIFF(DAY, m.FromDate, m.ToDate)+s.DayStatus- dbo.fn_WorkingDays(@CID,m.FromDate,m.ToDate,@LedgerID,m.LeaveID,m.LeaveCategory))  
										ELSE dbo.fn_WorkingDays(@CID,m.FromDate,m.ToDate,@LedgerID,m.LeaveID,m.LeaveCategory)  END AS DaysRequested, 
										ls.LeaveSname AS 'Status',e.EmpID AS Email,
										(SELECT LTM.LeaveType AS CategoryName FROM	[STS_LeaveTypeMaster] 
										WHERE	LID=s.ApporvedType AND CID=s.CID) AS ApprovedType,m.Comments
						FROM			[STS_LeaveMgt] m 
						INNER JOIN		[STS_LeaveMgtSub] s  ON m.LeaveID=s.LeaveID  and m.CID=s.CID
						INNER JOIN		[EmployeeMaster] e ON e.LedgerID=m.LedgerID and e.cid=m.CID
						INNER JOIN		[STS_LeaveTypeMaster]LTM ON LTM.LID=m.RequestType
						INNER JOIN		[STS_LeaveStausConfiguration] ls ON m.StatusID=ls.LeaveSID
						WHERE			 m.LedgerID=@LedgerID AND YEAR(m.EntryDate)=@Year and m.CID=@CID  ORDER BY m.LeaveID DESC;
					
					   SELECT tag  FROM [STS_CommonConfiguration]  WHERE Type='NetworkCredentialMailID' AND MenuID='STS_21' AND CID=@CID;;	    
										 
					   SELECT tag  FROM [STS_CommonConfiguration]  WHERE Type='NetworkCredentialPassword' AND MenuID='STS_21' AND CID=@CID;;	    
					
					   SELECT tag  FROM [STS_CommonConfiguration]  WHERE Type='NetworkCredentialPort' AND MenuID='STS_21' AND CID=@CID;;	    
				
					 SELECT		 e.AliasName1 as Name,1 AS AuthLevel,s.LeaveSname as 'Status',a.Comments
					 FROM		 [EmployeeMaster] e 
					 INNER JOIN	 [STS_LeaveMgtAuthorise] a ON a.AuthorisedBy=e.LedgerID AND a.CID=e.CID
					 INNER JOIN	 [STS_LeaveStausConfiguration] s ON a.StatusID=s.LeaveSID AND a.CID=s.CID
					 WHERE		 a.LeaveSubID=@RtnLeaveSubID; 

	       			SET @ReturnValue =0;
					SET @ErrorMessage='Record updated successfully';
				   END 
			--ELSE
			--	BEGIN
			--		SET @ReturnValue =2;
			--		SET @ErrorMessage='Record already exist';
			--	END
			--END 		    	         
	   ELSE
		  BEGIN
			SET @ReturnValue =2;
			SET @ErrorMessage='Invalid date selection';
		  END 
	   END
	IF(@Flag='DELETE')
	   BEGIN			

			DELETE  FROM [STS_Attendance] WHERE LeaveID IN (SELECT LeaveSubID FROM [STS_LeaveMgtSub] WHERE LeaveID=@LeaveID AND CID=@CID)  AND CID=@CID;

			DELETE  FROM [STS_LeaveMgtAuthorise] WHERE LeaveSubID IN (SELECT LeaveSubID FROM [STS_LeaveMgtSub] WHERE LeaveID=@LeaveID AND CID=@CID)  AND CID=@CID;

			DELETE  FROM [STS_LeaveMgtHistory] WHERE LeaveSubID IN (Select LeaveSubID FROM [STS_LeaveMgtSub] WHERE LeaveID=@LeaveID AND CID=@CID)  AND CID=@CID; 
		
			DELETE  FROM [STS_LeaveMgtSub] WHERE LeaveID=@LeaveID AND CID=@CID;

			DELETE  FROM [STS_LeaveMgt] WHERE LeaveID=@LeaveID  AND CID=@CID;

						                      	
			SET @ReturnValue =0;
			SET @ErrorMessage='Record deleted successfully';
	   END
    END
    
 -----------------------------------------************************** REQUEST LEAVE ***********************----------------------------------------------------------------
  ELSE 
     BEGIN
        IF(@Flag='ADD') 
			BEGIN
				SET @FDATE=CONVERT(DATE,@FromDate,105);
				SET @TDATE=CONVERT(DATE,@ToDate,105);	
				
				SELECT	@DATECOUNT =COUNT(*) FROM [STS_LeaveMgt] m INNER JOIN [STS_LeaveMgtSub] s ON m.LeaveID=s.LeaveID WHERE m.LedgerID=@LedgerID AND  m.FromDate<=@FDATE AND m.ToDate>=@FDATE AND m.LeaveID!=@LeaveID AND m.CID=@CID;
			
				SELECT	@DATECOUNT1 =COUNT(*) FROM [STS_LeaveMgt]  m INNER JOIN [STS_LeaveMgtSub] s ON m.LeaveID=s.LeaveID WHERE m.LedgerID=@LedgerID AND  m.FromDate<=@TDATE AND m.ToDate>=@TDATE AND m.LeaveID!=@LeaveID AND m.CID=@CID; 
						
				IF(@DATECOUNT=0 AND @DATECOUNT1=0)
					SET @SUCCESS=1;
				Else
					SET @SUCCESS=0;
					
				IF(@SUCCESS=1) 
							BEGIN								
									INSERT INTO		[STS_LeaveMgt] 
													(
														LedgerID,
														FromDate,
														ToDate,
														StatusID,
														RequestType,
														Comments,
														ApprovedLevel,
														EntryDate,
														Mode,
														LeaveCategory,
														CreatedBy,
														CID
													) 
								VALUES				(
														@LedgerID,
														CONVERT(DATE,@FromDate,105),
														CONVERT(DATE,@ToDate,105),
														0,
														@LeaveType,
														@Comments,
														(SELECT TOP 1 a.AuthLevel FROM [STS_Authoriser] a INNER JOIN [STS_AuthoriseGroupSub] s ON a.AuthGroupID=s.AuthGroupID WHERE s.LedgerID=@LedgerID ORDER BY a.AuthLevel ASC),
														CURRENT_TIMESTAMP,
														'',
														@LeaveTypeCategory,
														@EmpUniqID,
														@CID
													);
																			                                    
								INSERT INTO			[STS_LeaveMgtSub]
													(
														LeaveID,
														FromDate,
														ToDate,
														StatusID,
														ApporvedType,
														DayStatus,
														SessionType,
														CID
													)
								  VALUES			(
														(SELECT MAX(LeaveID*100/100) FROM [STS_LeaveMgt] ),
														CONVERT(DATE,@FromDate,105),
														CONVERT(DATE,@ToDate,105),
														0,
														@LeaveType,
														@DayStatus,
														@Session,
														@CID
													);
																
----- ***********  LEAVE REQUEST EMAIL PROCESS  ****************--------------------
								
							SELECT Tag FROM [STS_CommonConfiguration] WHERE	Type='CompanyDetails' AND MenuID='STS_21' AND CID=@CID;							
												
							SELECT	Tag FROM [STS_CommonConfiguration] 	WHERE Type='SmtpProtocal' AND MenuID='STS_21' AND CID=@CID;							
							
							SELECT Tag FROM [STS_CommonConfiguration]  WHERE Type='Leave Approval' AND MenuID='STS_21' AND CID=@CID;				
							
							SELECT      	(e.AliasName1) as Name,
											em.PreEmail1,
										    e.EmpID 
							FROM			[STS_Authoriser] a 
							INNER JOIN		[EmployeeMaster] e   
							ON				a.LedgerID=e.LedgerID AND  a.CID=e.CID
							INNER JOIN		[STS_Authoriser] au 
							ON				au.LedgerID=e.LedgerID AND au.CID=e.CID
							INNER JOIN		[STS_EmployeeMasterSub] em 
							ON				em.LedgerID=e.LedgerID AND em.CID=e.CID
							WHERE			a.AuthGroupID in (SELECT s.AuthGroupID FROM [STS_AuthoriseGroupSub] s WHERE s.LedgerID=@LedgerID AND s.CID=@CID) 
							ORDER BY		a.AuthLevel ASC;											
						
								
							SELECT		TOP(1)e.AliasName1 as Name,CONVERT(VARCHAR(10),m.EntryDate,105) AS EntryDate,LTM.LeaveType as CategoryName ,
										(CASE WHEN s.DayStatus=1 THEN 'Full Day' ELSE 'Half Day' END) as 'Days',CONVERT(VARCHAR(10),m.FromDate,105) AS FromDate,CONVERT(VARCHAR(10),m.ToDate,105) AS ToDate,
										DATEDIFF(day, m.FromDate, m.ToDate)+1 AS CalendarDay,
										CASE WHEN (m.RequestType=116) THEN (DATEDIFF(DAY, m.FromDate, m.ToDate)+s.DayStatus- dbo.fn_WorkingDays(@CID,m.FromDate,m.ToDate,@LedgerID,m.LeaveID,m.LeaveCategory))  
										ELSE dbo.fn_WorkingDays(@CID,m.FromDate,m.ToDate,@LedgerID,m.LeaveID,m.LeaveCategory)  END AS DaysRequested, 
										ls.LeaveSname AS 'Status',e.EmpID AS Email,
										(SELECT LTM.LeaveType AS CategoryName FROM	[STS_LeaveTypeMaster] 
										WHERE	LID=s.ApporvedType AND  CID=@CID) AS ApprovedType,m.Comments
						FROM			[STS_LeaveMgt] m 
						INNER JOIN		[STS_LeaveMgtSub] s  ON m.LeaveID=s.LeaveID AND m.CID=s.CID
						INNER JOIN		[EmployeeMaster] e ON e.LedgerID=m.LedgerID AND e.CID=m.CID
						INNER JOIN		[STS_LeaveTypeMaster] LTM ON LTM.LID=m.RequestType AND LTM.CID=m.CID
						INNER JOIN		[STS_LeaveStausConfiguration] ls ON m.StatusID=ls.LeaveSID AND m.CID=ls.CID
						WHERE			 m.LedgerID=@LedgerID AND YEAR(m.EntryDate)=@Year AND m.CID=@CID ORDER BY m.LeaveID DESC;
						
					    SELECT tag  FROM [STS_CommonConfiguration]  WHERE Type='NetworkCredentialMailID' AND MenuID='STS_21' AND CID=@CID;	    
												 
						SELECT tag  FROM [STS_CommonConfiguration]  WHERE Type='NetworkCredentialPassword' AND MenuID='STS_21' AND CID=@CID;	    
					
						SELECT tag  FROM [STS_CommonConfiguration]  WHERE Type='NetworkCredentialPort' AND MenuID='STS_21' AND CID=@CID;	    
										
						  SET @ReturnValue = 0;
						  SET @ErrorMessage='Record Inserted Successfully';																																	
						END				
					ELSE 
					  BEGIN
						SET @ReturnValue = 2;
						SET @ErrorMessage ='Record already exist';
					  END	
			END
	ELSE IF(@Flag='EDIT')
		BEGIN
			SET @FDATE=CONVERT(DATE,@FromDate,105);
			SET @TDATE=CONVERT(DATE,@ToDate,105);
					
		    SELECT	@DATECOUNT =COUNT(*) FROM [STS_LeaveMgt] m INNER JOIN [STS_LeaveMgtSub] s ON m.LeaveID=s.LeaveID WHERE m.LedgerID=@LedgerID AND  m.FromDate<=@FDATE AND m.ToDate>=@FDATE AND m.LeaveID!=@LeaveID AND m.CID=@CID;
			
			SELECT	@DATECOUNT1 =COUNT(*) FROM [STS_LeaveMgt] m INNER JOIN [STS_LeaveMgtSub] s ON m.LeaveID=s.LeaveID WHERE m.LedgerID=@LedgerID AND  m.FromDate<=@TDATE AND m.ToDate>=@TDATE AND m.LeaveID!=@LeaveID AND m.CID=@CID; 
						
			IF(@DATECOUNT=0 AND @DATECOUNT1=0)
				SET @SUCCESS=1;
			ELSE
				SET @SUCCESS=0;
		
			IF(@SUCCESS=1) 
					BEGIN
						 UPDATE		[STS_LeaveMgt] 
						 SET		FromDate=CONVERT(DATE,@FromDate,105),
									ToDate=CONVERT(DATE,@ToDate,105),
									RequestType=@LeaveType,
									Comments=@Comments 
						 WHERE		LeaveID=@LeaveID AND CID=@CID;
																	  
						 UPDATE		[STS_LeaveMgtSub] 
						 SET		FromDate=CONVERT(DATE,@FromDate,105),
									ToDate=CONVERT(DATE,@ToDate,105),
									ApporvedType=@LeaveType,
									DayStatus=@DayStatus,
									SessionType=@Session
						 WHERE		LeaveID=@LeaveID AND CID=@CID;
						
						 SELECT Tag FROM [STS_CommonConfiguration] WHERE Type='CompanyDetails' AND MenuID='STS_21' AND CID=@CID;							
												
						 SELECT	Tag FROM [STS_CommonConfiguration] 	WHERE Type='SmtpProtocal' AND MenuID='STS_21' AND CID=@CID;							
						
						 SELECT Tag FROM [STS_CommonConfiguration]  WHERE Type='Leave Approval' AND MenuID='STS_21' AND CID=@CID;				
							
							SELECT      	(e.AliasName1) as Name,
											em.PreEmail1,
										    e.EmpID 
							FROM			[STS_Authoriser] a 
							INNER JOIN		[EmployeeMaster] e   
							ON				a.LedgerID=e.LedgerID AND  a.CID=e.CID
							INNER JOIN		[STS_Authoriser] au 
							ON				au.LedgerID=e.LedgerID AND au.CID=e.CID
							INNER JOIN		[STS_EmployeeMasterSub] em 
							ON				em.LedgerID=e.LedgerID AND em.CID=e.CID
							WHERE			a.AuthGroupID in (SELECT s.AuthGroupID FROM [STS_AuthoriseGroupSub] s WHERE s.LedgerID=@LedgerID AND s.CID=@CID) 
							ORDER BY		a.AuthLevel ASC;											
														
							SELECT		TOP(1)e.AliasName1 as Name,CONVERT(VARCHAR(10),m.EntryDate,105) AS EntryDate,LTM.LeaveType as CategoryName ,
										(CASE WHEN s.DayStatus=1 THEN 'Full Day' ELSE 'Half Day' END) as 'Days',CONVERT(VARCHAR(10),m.FromDate,105) AS FromDate,CONVERT(VARCHAR(10),m.ToDate,105) AS ToDate,
										DATEDIFF(day, m.FromDate, m.ToDate)+1 AS CalendarDay,
										CASE WHEN (m.RequestType=116) THEN (DATEDIFF(DAY, m.FromDate, m.ToDate)+s.DayStatus- dbo.fn_WorkingDays(@CID,m.FromDate,m.ToDate,@LedgerID,m.LeaveID,m.LeaveCategory))  
										ELSE dbo.fn_WorkingDays(@CID,m.FromDate,m.ToDate,@LedgerID,m.LeaveID,m.LeaveCategory)  END AS DaysRequested, 
										ls.LeaveSname AS 'Status',e.EmpID AS Email,
										(SELECT LTM.LeaveType AS CategoryName FROM	[STS_LeaveTypeMaster] 
										WHERE	LID=s.ApporvedType AND CID=@CID) AS ApprovedType,m.Comments
						FROM			[STS_LeaveMgt] m 
						INNER JOIN		[STS_LeaveMgtSub] s  ON m.LeaveID=s.LeaveID AND m.CID=s.CID
						INNER JOIN		[EmployeeMaster] e ON e.LedgerID=m.LedgerID AND e.CID=m.CID
						INNER JOIN		[STS_LeaveTypeMaster] LTM ON LTM.LID=m.RequestType AND LTM.CID=m.CID
						INNER JOIN		[STS_LeaveStausConfiguration] ls ON m.StatusID=ls.LeaveSID AND m.CID=ls.CID
						WHERE			 m.LeaveID=@LeaveID AND YEAR(m.EntryDate)=@Year AND m.CID=@CID ORDER BY m.LeaveID DESC;
						
					    SELECT tag  FROM [STS_CommonConfiguration]  WHERE Type='NetworkCredentialMailID' AND MenuID='STS_21' AND CID=@CID;	    
												 
						SELECT tag  FROM [STS_CommonConfiguration]  WHERE Type='NetworkCredentialPassword' AND MenuID='STS_21' AND CID=@CID;	    
					
						SELECT tag  FROM [STS_CommonConfiguration]  WHERE Type='NetworkCredentialPort' AND MenuID='STS_21' AND CID=@CID;	

						SET @ReturnValue = 0;
						SET @ErrorMessage='Record Updated Successfully';												
					 END
			ELSE
			  BEGIN
				SET @ReturnValue = 2;
				SET @ErrorMessage = 'Record already exist';
			  END	
		END
	ELSE IF(@Flag='DELETE')
	  BEGIN
	  -- 	    DECLARE @RtnLeaveID INT;
			
			--SELECT @RtnLeaveID=LeaveID FROM [STS_LeaveMgtSub] WHERE LeaveSubID=@LeaveID AND CID=@CID;
			
			DELETE FROM	[STS_LeaveMgtSub] WHERE LeaveSubID=@LeaveID AND CID=@CID;
										  
			DELETE FROM	[STS_LeaveMgt] WHERE LeaveID=@LeaveID AND CID=@CID;			
										  							  
			SET @ReturnValue = 0;
			SET @ErrorMessage='Record Deleted Successfully';			
		END     
     END	   	 
	COMMIT TRANSACTION
	   IF(@ReturnValue=1)
		  BEGIN
			SET @DESC=@ErrorMessage + ' : ' + @Flag 
			--EXEC STS_SetElog @CID,@UserID,@CurrentTime,@GroupID,'Leave Approval',@ReturnValue,@DESC,@ErrorMessage,7,0,4,'';
		  END
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
				SET @ReturnValue = ERROR_NUMBER()
				SET @DESC='ERROR IN  Details' +' : '+ @Flag
				SET @ReturnValue=0;
				SET @ErrorMessage='Error Message:'+ERROR_MESSAGE();
				--EXEC STS_SetElog @CID,@UserID,@CurrentTime,@GroupID,'Leave Approval',@ReturnValue,@DESC,@ErrorMessage,5,3,4,'';							
	END CATCH	
END

IF (OBJECT_ID('GetConfigParam') IS NOT NULL)
  DROP PROCEDURE GetConfigParam
GO

/****** Object:  StoredProcedure [dbo].[GetConfigParam]    Script Date: 10/27/2020 7:05:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: <Author,,Name>
-- Create date: <Create Date,,>
-- Description: <Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetConfigParam]
-- Add the parameters for the stored procedure here
	@CID					INT
--UNLOCK-- WITH ENCRYPTION 
 AS 
 BEGIN

	SET NOCOUNT ON;	
	select tag, value from [configparam];
END

IF (OBJECT_ID('GetGroupMgt') IS NOT NULL)
  DROP PROCEDURE GetGroupMgt
GO
/****** Object:  StoredProcedure [dbo].[GetGroupMgt]    Script Date: 10/27/2020 7:09:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetGroupMgt]
	-- Add the parameters for the stored procedure here
	@Flag	 	  VARCHAR(50),
	@CID          INT,
	@GroupID      INT
	
	--WITH ENCRYPTION
	
AS
BEGIN

	IF(@Flag='LOADDETAIL')
		BEGIN
		  SELECT  GroupName as Text1,GroupLevel as Text2  FROM [GroupMgt]  WHERE  GroupID=@GroupID and CID = @CID ;
		END
	ELSE IF(@Flag='LOADGRID')	
		BEGIN
		  SELECT  GroupID ,GroupName FROM [GroupMgt] WHERE CID = @CID  ORDER BY GroupID;
		END
    ELSE IF(@Flag='LOADID')
        BEGIN
          SELECT GroupID as Text1,GroupLevel  as Text2  FROM [GroupMgt] WHERE GroupName=@GroupID and CID = @CID 
		END	
	ELSE IF(@Flag='getGroupMgtSub')
		select MenuID,Options from GroupMgtSub where CID=@CID and GroupID=@GroupID AND ApplicationType = 3;
	--	select MenuID as Text1,Description  as Text2 from MenuMgt where cid=@CID and ApplicationType=1 and MenuID in (select MenuID from GroupMgtSub where CID=@CID and GroupID=@GroupID)	
END

IF (OBJECT_ID('GetGroupFormRights') IS NOT NULL)
  DROP PROCEDURE GetGroupFormRights
GO
/****** Object:  StoredProcedure [dbo].[GetGroupFormRights]    Script Date: 10/27/2020 7:13:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetGroupFormRights] 
	-- Add the parameters for the stored procedure here
	@CID		INT,
	@MenuID		VARCHAR(50),
	@GroupID	INT
--UNLOCK-- WITH ENCRYPTION 
 AS 
 BEGIN

	SET NOCOUNT ON;

	select Options from [GroupMgtSub] where CID = @CID and MenuID = @MenuID and GroupID = @GroupID;					
   
END

IF (OBJECT_ID('GetUserGridList') IS NOT NULL)
  DROP PROCEDURE GetUserGridList
GO
/****** Object:  StoredProcedure [dbo].[GetUserGridList]    Script Date: 10/27/2020 7:15:01 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetUserGridList] 
	-- Add the parameters for the stored procedure here
	@CID		INT
--UNLOCK-- WITH ENCRYPTION 
 AS 
 BEGIN

	SET NOCOUNT ON;

	SELECT		GM.GroupID,
				GM.GroupName,
				UM.UserID,
				UM.UserName,
				(CASE WHEN (UM.Status='' OR UM.Status IS NULL) THEN (CASE WHEN (UM.InActive=0) THEN 'Active' ELSE 'InActive' END)  ELSE UM.Status END) AS Status 
	FROM		[GroupMgt] GM 
	INNER JOIN	[UserMgt]  UM 
	ON			GM.GroupID=UM.GroupID
	AND			GM.CID=UM.CID
	WHERE		GM.CID=@CID --and UserName in ('admin','kasim')
	ORDER BY	GM.GroupName ASC,UM.UserName ASC
					
   
END

IF (OBJECT_ID('sts_LoadUserMgtDetails') IS NOT NULL)
  DROP PROCEDURE sts_LoadUserMgtDetails
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sts_LoadUserMgtDetails] 
	-- Add the parameters for the stored procedure here
	@CID		INT
--UNLOCK-- WITH ENCRYPTION 
 AS 
 BEGIN

	SET NOCOUNT ON;

	SELECT GroupName, GroupID FROM [GroupMgt] WHERE CID = @CID;
	SELECT LngCode, Description FROM [LanguageMaster] WHERE CID = @CID;
	SELECT CompanyName, SiteID, 'false' as AllowAccess FROM [SiteMaster] WHERE CID = @CID AND SiteID <> @CID ORDER BY SiteID;
END

IF (OBJECT_ID('UserDelete') IS NOT NULL)
  DROP PROCEDURE UserDelete
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UserDelete] 
	-- Add the parameters for the stored procedure here
	@CID					INT,
	@UserID					INT,
	@ERRORNO				INT						OUTPUT,
	@ERRORDESC				VARCHAR(MAX)			OUTPUT
--UNLOCK-- WITH ENCRYPTION 
 AS 
 BEGIN

	SET NOCOUNT ON;

	SET		@ERRORNO	= 0
	DECLARE @RowCount	int = 0; 	
	SELECT @RowCount = COUNT(*) FROM [UserMgt] WHERE CID = @CID AND UserID = @UserID;
	IF @RowCount = 0
		BEGIN
			SET @ERRORNO = 1;
			SET @ERRORDESC = 'NO USER EXISTS';
			GOTO ErrExit;
		END

	BEGIN TRY
	BEGIN TRANSACTION @ERRORDESC		
		
			UPDATE		[UserMgt] 
			SET			Status='Deleted' 
			WHERE		CID=@CID
			AND			UserID=@UserID;

	COMMIT TRANSACTION
			 SET @ERRORNO = 0;
			 set @ERRORDESC = '';
		END TRY
	BEGIN CATCH
	
	ROLLBACK TRANSACTION
			set @ERRORNO = ERROR_NUMBER()
			set @ERRORDESC = ERROR_MESSAGE()
	END CATCH 

	ErrExit:
END

IF (OBJECT_ID('STS_GetHierarchylist') IS NOT NULL)
  DROP PROCEDURE STS_GetHierarchylist
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[STS_GetHierarchylist]
	-- Add the parameters for the stored procedure here
  @CID			    INT,
  @ERRORNO			INT	OUTPUT,
  @ERRORDESC		VARCHAR(max) OUTPUT
  --WITH ENCRYPTION

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
    
	BEGIN TRY
	BEGIN TRANSACTION @ERRORDESC
		
		SELECT ApprovalGroupID, typeid, ApprovalGroupName FROM [STS_ApprovalGroup] WHERE CID = @CID AND isactive = 1;	
		--SELECT parentid, ledgerid, approvelevel FROM [STS_ApprovalGroupSub] WHERE CID = @CID AND approvergroupid = @APPROVERGROUPID;		
       
	COMMIT TRANSACTION
		SET @ERRORNO = 0
		--SET @DESC='Sucessfully'+''+@Flag+'ED'+''+'BOM Details'+' : '+@BOMNo		
		set @ERRORDESC = ''
		--EXEC ElogUpdate @CID,@BusinessPeriodID,@CreatedBy,@CreatedDate,'','BOM',@ERRORNO,@DESC,@ERRORDESC,7,0,4;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		set @ERRORNO = ERROR_NUMBER()
		--SET @DESC='ERROR IN '+''+@Flag+'ED'+''+'BOM Details'+' : '+@BOMNo
		set @ERRORDESC = ERROR_MESSAGE()
		--EXEC ElogUpdate @CID,@BusinessPeriodID,@CreatedBy,@CreatedDate,'','BOM',@ERRORNO,@DESC,@ERRORDESC,5,3,4;
	END CATCH
		
END

IF (OBJECT_ID('STS_GetHierarchyDefaults') IS NOT NULL)
  DROP PROCEDURE STS_GetHierarchyDefaults
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[STS_GetHierarchyDefaults]
	-- Add the parameters for the stored procedure here
  @CID			    INT,
  @ERRORNO			INT	OUTPUT,
  @ERRORDESC		VARCHAR(max) OUTPUT
  --WITH ENCRYPTION

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
    
	BEGIN TRY
	BEGIN TRANSACTION @ERRORDESC
		
		Select ProjectUID AS ID, ProjectID AS ProjectName from [ProjectMaster] where CID=@CID AND ProjectStatus = 0;
		SELECT LedgerID, AliasName1 AS [name] FROM [EmployeeMaster] WHERE CID = @CID;
		
	COMMIT TRANSACTION
		SET @ERRORNO = 0
		--SET @DESC='Sucessfully'+''+@Flag+'ED'+''+'BOM Details'+' : '+@BOMNo		
		set @ERRORDESC = ''
		--EXEC ElogUpdate @CID,@BusinessPeriodID,@CreatedBy,@CreatedDate,'','BOM',@ERRORNO,@DESC,@ERRORDESC,7,0,4;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		set @ERRORNO = ERROR_NUMBER()
		--SET @DESC='ERROR IN '+''+@Flag+'ED'+''+'BOM Details'+' : '+@BOMNo
		set @ERRORDESC = ERROR_MESSAGE()
		--EXEC ElogUpdate @CID,@BusinessPeriodID,@CreatedBy,@CreatedDate,'','BOM',@ERRORNO,@DESC,@ERRORDESC,5,3,4;
	END CATCH
		
END

IF (OBJECT_ID('STS_GetHierarchylistSub') IS NOT NULL)
  DROP PROCEDURE STS_GetHierarchylistSub
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[STS_GetHierarchylistSub]
	-- Add the parameters for the stored procedure here
  @CID			    INT,
  @APPROVERGROUPID	INT,
  @ERRORNO			INT	OUTPUT,
  @ERRORDESC		VARCHAR(max) OUTPUT
  --WITH ENCRYPTION

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
    
	BEGIN TRY
	BEGIN TRANSACTION @ERRORDESC
		DECLARE @TopParent INT;
		
		select Top 1 @TopParent = ParentID from [STS_ApprovalGroupSub] WHERE CID = @CID AND ApprovalGroupID = @APPROVERGROUPID AND ApproveLevel = 1;

		select 0 as parentid, @TopParent as ledgerid, 1 as level, FirstName as [name], 'L1' as leveldesc from [EmployeeMaster] where CID = @CID and LedgerID = @TopParent
		UNION ALL
		SELECT parentid, GS.ledgerid, approvelevel+1 AS level, EM.AliasName1 as [name], 
		(CASE WHEN (approvelevel = 1) THEN 'L2' WHEN (approvelevel = 2) THEN 'L3' WHEN (approvelevel = 3) THEN 'L4' ELSE 'L5' END) leveldesc 
		FROM [STS_ApprovalGroupSub] GS INNER JOIN [EmployeeMaster] EM ON GS.ledgerid = EM.LedgerID WHERE GS.CID = @CID AND EM.CID = @CID AND ApprovalGroupID = @APPROVERGROUPID;		
       
	COMMIT TRANSACTION
		SET @ERRORNO = 0
		--SET @DESC='Sucessfully'+''+@Flag+'ED'+''+'BOM Details'+' : '+@BOMNo		
		set @ERRORDESC = ''
		--EXEC ElogUpdate @CID,@BusinessPeriodID,@CreatedBy,@CreatedDate,'','BOM',@ERRORNO,@DESC,@ERRORDESC,7,0,4;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		set @ERRORNO = ERROR_NUMBER()
		--SET @DESC='ERROR IN '+''+@Flag+'ED'+''+'BOM Details'+' : '+@BOMNo
		set @ERRORDESC = ERROR_MESSAGE()
		--EXEC ElogUpdate @CID,@BusinessPeriodID,@CreatedBy,@CreatedDate,'','BOM',@ERRORNO,@DESC,@ERRORDESC,5,3,4;
	END CATCH
		
END

IF (OBJECT_ID('GetProjects') IS NOT NULL)
  DROP PROCEDURE GetProjects
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetProjects]
	-- Add the parameters for the stored procedure here
	@CID				INT
--UNLOCK-- WITH ENCRYPTION 
 AS 
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	
	SET NOCOUNT ON;
	
	Select ProjectUID AS ID, ProjectID AS ProjectName from [ProjectMaster] where CID=@CID AND ProjectStatus = 0;
END

IF (OBJECT_ID('GetLeaveRequestReport') IS NOT NULL)
  DROP PROCEDURE GetLeaveRequestReport
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name> 
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetLeaveRequestReport]
     @CID			VARCHAR(30),
     @Flag			VARCHAR(30),
	 @EmployeeID    VARCHAR(30),
	 @Department    VARCHAR(30),
	 @LeaveType     [TVP_STS_EmpLeaveRpt] READONLY,
	 @FromDate		VARCHAR(30),
	 @ToDate		VARCHAR(30),
	 @RtnStatus		VARCHAR(5),
	 @UserID        VARCHAR(25)

	-- WITH ENCRYPTION

AS
BEGIN
	DECLARE @SQLSTRING			    NVARCHAR(MAX); 

  IF(@Flag='LOADDDL')
	   BEGIN
	    DECLARE @UserName VARCHAR(50);
		   
		SELECT SiteID,CompanyName AS SiteName FROM SiteMaster WHERE SiteID=@CID AND CID=@CID					 
		
  			--get employeename
				SELECT      LedgerID,
							EmpID+' - '+AliasName1 AS Name  
				FROM		[EmployeeMaster]
				WHERE	    InActive=0 AND CID=@CID
				ORDER BY	AliasName1
				
			 --get department
				SELECT       ComboValueMember AS DepartId,
							 ComboDisplayMember1 AS DepartName 
				FROM         [BaseDropDownList] 
				WHERE		 ComboName='Department' AND CID=@CID
				ORDER BY     DepartId	
				 
			  --get leave type
				SELECT      LID AS LeavetypeID ,
							LeaveType
				FROM        [STS_LeaveTypeMaster] 
				WHERE       IsActive=1 
				AND			CID=@CID AND LeaveType<>'Present';  
	   END
  
  IF(@Flag='LOADGRID')
     BEGIN
	      DECLARE @COUNT INT;
		  SELECT @COUNT=LID FROM @LeaveType;
	      
	      SET  @SQLSTRING		='SELECT			Em.EmpID,
													Em.AliasName1 AS EmpName,
													CONVERT(VARCHAR(10),LM.FromDate,105) AS FromDate,
												    CONVERT(VARCHAR(10),LM.ToDate,105) AS ToDate,
													DATEDIFF(day, LM.FromDate, LM.ToDate)+1 AS CalendarDay,
													--CASE WHEN (LM.RequestType=116) THEN (DATEDIFF(day, LM.FromDate, LM.ToDate)+lms.DayStatus- dbo.fn_AllEmpWorkingDays('''+@CID+''',LM.FromDate,LM.ToDate,LM.LeaveID,Lm.LeaveCategory)) 
													--ELSE dbo.fn_AllEmpWorkingDays('''+@CID+''',LM.FromDate,LM.ToDate,LM.LeaveID,Lm.LeaveCategory)  END as DaysRequested,
													LTM.LeaveType AS ReqLeaveType,
													LSC.LeaveSname AS Status,
													CONVERT(VARCHAR(10),LM.EntryDate,105) AS ReqDate,
													LM.Comments,
													DATEDIFF(DAY, LM.ToDate, LM.RtnDate) AS ExcessDays,
													CONVERT(VARCHAR(10),LM.RtnDate,105) AS RtnDate
								  FROM				[EmployeeMaster] EM 
								  INNER JOIN		[STS_LeaveMgt] LM ON Em.LedgerID=lM.LedgerID AND Em.CID=lm.CID
								  --INNER JOIN		[STS_LeaveMgtSub] LMS ON LMS.LeaveID=LM.LeaveID AND LMS.CID=LM.CID
								  INNER JOIN		[STS_LeaveTypeMaster] LTm ON LTM.LID=LM.RequestType  AND LTM.CID=LM.CID
								  INNER JOIN		[STS_LeaveStausConfiguration] LSC ON LSC.LeaveSID=LM.StatusID AND LSC.CID=LM.CID
								  WHERE				EM.LedgerID IS NOT NULL AND EM.CID='''+@CID+''''

          IF(@FromDate <>'' AND @ToDate <>'')
		        SET @SQLSTRING     = @SQLSTRING+' AND (CONVERT(DATE,LM.FromDate,105)>=CAST(CONVERT(DATE,'''+ @FromDate +''', 105) AS DATE) AND CONVERT(DATE,LM.FromDate,105)<=CAST( CONVERT(DATE,'''+ @FromDate +''', 105) AS DATE)
												 OR CONVERT(DATE,LM.ToDate,105)>=CONVERT(DATE,'''+ @Fromdate +''',105) AND CONVERT(DATE,LM.FromDate,105)<=CAST( CONVERT(DATE,'''+ @Todate +''', 105) AS DATE))'

           IF(@EmployeeID <>'')
		         SET @SQLSTRING		= @SQLSTRING +' AND Em.LedgerID='''+@EmployeeID+'''';

           IF(@Department <>'')
				 SET @SQLSTRING    = @SQLSTRING +' AND EM.Department='''+@Department+'''';

           IF(@COUNT >0)
		         --SET @SQLSTRING    = @SQLSTRING +' AND LM.RequestType in ('+@LeaveType+')';
				 SET @SQLSTRING    = @SQLSTRING +' AND LM.RequestType in (SELECT LID FROM  @LeaveType)';
        
		  IF(@RtnStatus<>'0' AND @RtnStatus=1)
		        SET @SQLSTRING    = @SQLSTRING +'  AND LM.Rtndate IS  NULL'

          IF(@RtnStatus<>'0' AND @RtnStatus=2)
		        SET @SQLSTRING    = @SQLSTRING +'  AND LM.Rtndate IS NOT NULL'
	      
		  
		    SET @SQLSTRING  = @SQLSTRING +' ORDER BY Lm.EntryDate DESC';

			--select @SQLSTRING
			 EXECUTE sp_executesql @SQLSTRING,
								 N'@LeaveType  [TVP_STS_EmpLeaveRpt] READONLY',
								 @LeaveType  =@LeaveType; 
	 END
	 
END

IF (OBJECT_ID('GetAlternateEmployee') IS NOT NULL)
  DROP PROCEDURE GetAlternateEmployee
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetAlternateEmployee]
	-- Add the parameters for the stored procedure here
	@CID		VARCHAR(5),
	@Flag		VARCHAR(25),
	@UserID	    VARCHAR(75),
	@AppGroupID	VARCHAR(20)
AS
BEGIN
	
	IF(@Flag='LOADDDL')
	   BEGIN
	     SELECT SiteID,CompanyName AS SiteName FROM SiteMaster WHERE SiteID=@CID AND CID=@CID					 
				
			  --get project    			 
				SELECT Distinct PM.ProjectID AS ProjectName,PM.ProjectUID AS ProjectID FROM  [STS_ApprovalGroup] AG INNER JOIN [ProjectMaster] PM ON PM.ProjectUID = AG.typeid
				WHERE AG.CID=@CID AND PM.ProjectStatus=0 ORDER BY PM.ProjectID
				
			  --get approval groupid					 
				select ApprovalGroupID,ApprovalGroupName from [STS_ApprovalGroup] WHERE isactive=1 AND CID=@CID;
              
			  --get authorizer name
			    Select Distinct EM.LedgerID,AGS.ApprovalGroupID,
				convert (varchar(5),case AGS.ApproveLevel When 1 then 'L1' when 2 then 'L2'when 3 then 'L3' when 4 then 'L4' when 5 then 'L5' When 6 then 'L6' when 7 then 'L7' when 8 then 'L8' End )+' - '+ Em.AliasName1 AS EmpName,AGS.ApproveLevel 
				from [STS_ApprovalGroupSub] AGS INNER JOIN [EmployeeMaster] EM on EM.LedgerID=AGS.parentid AND Em.CID=Ags.CID
				WHERE  AGS.CID=@CID order by Ags.ApprovalGroupID,AGS.ApproveLevel;
			  --AGS.approvergroupid=@AppGroupID AND
			
			   	--get employeename
				SELECT      LedgerID,
							EmpID+' - '+AliasName1 AS Name  
				FROM		[EmployeeMaster]
				WHERE	    InActive=0 AND CID=@CID
				ORDER BY	AliasName1 

				--get role
				  SELECT   EntityID,Tag FROM  [STS_Entity] WHERE  Type='Role' AND CID=@CID;     
	   END
	ELSE IF(@Flag='AUTHORIZERNAME')
       BEGIN
	     Select Distinct Em.LedgerID,
		 convert (varchar(5),case AGS.ApproveLevel When 1 then 'L1' when 2 then 'L2'when 3 then 'L3' when 4 then 'L4' when 5 then 'L5' When 6 then 'L6' when 7 then 'L7' when 8 then 'L8' End )+' - '+ Em.AliasName1 AS EmpName,AGS.ApproveLevel 
		 from [STS_ApprovalGroupSub] AGS INNER JOIN [EmployeeMaster] EM on EM.LedgerID=AGS.parentid AND Em.CID=Ags.CID
		 WHERE AGS.ApprovalGroupID=@AppGroupID AND AGS.CID=@CID order by AGS.ApproveLevel;
	   END
    ELSE IF(@Flag='GROUPNAME')
	   BEGIN
			 select ApprovalGroupID,ApprovalGroupName from [STS_ApprovalGroup] WHERE isactive=1 AND CID=@CID AND Typeid=@AppGroupID;
	   END

END
GO

IF (OBJECT_ID('SetAlternateEmployee') IS NOT NULL)
  DROP PROCEDURE SetAlternateEmployee
GO
--DROP TYPE [dbo].[TVP_STS_AlternateEmp]
--GO
/****** Object:  UserDefinedTableType [dbo].[TVP_STS_AlternateEmp]    Script Date: 10/27/2020 7:56:51 PM ******/
CREATE TYPE [dbo].[TVP_STS_AlternateEmp] AS TABLE(
	[EmpID] [int] NULL
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create DATE: <Create DATE,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SetAlternateEmployee] 
	  @CID				    VARCHAR(50),
	  @Flag					VARCHAR(100),
	  @Project				VARCHAR(50),
	  @AllotDate			VARCHAR(20),	
	  @AppGroupID			VARCHAR(10),
	  @Authorizer			VARCHAR(10),
	  @EmployeeDT			TVP_STS_AlternateEmp READONLY,
	  @Role					VARCHAR(10),     	
      @AllotHrs				VARCHAR(10),
      @ERRORNO				INT				OUTPUT,
	  @ERRORDESC			VARCHAR(MAX)	OUTPUT 	
	-- WITH ENCRYPTION

 AS 
 BEGIN

	Declare @RtnLevel					INT;
	Declare @RtnResouceAllocationID		INT;
	DECLARE @CurrentTime DATETIME
	SET     @CurrentTime = CURRENT_TIMESTAMP
	DECLARE @DESC VARCHAR(MAX)
	
 BEGIN TRY
	BEGIN TRANSACTION @ERRORDESC	
	 IF(@Flag='ALTERNATEEMP')
		BEGIN
			  DECLARE @Employee  VARCHAR(20);

			  DECLARE OUTER_CURSOR CURSOR FOR SELECT EmpID FROM @EmployeeDT 
				OPEN OUTER_CURSOR
				 FETCH NEXT FROM OUTER_CURSOR INTO @Employee
				   WHILE @@FETCH_STATUS = 0
					  BEGIN							
							 IF(NOT EXISTS(SELECT * FROM [STS_ApprovalGroupSub]  WHERE ledgerid=@Employee AND ApprovalGroupID=@AppGroupID  AND CID = @CID ))	
								BEGIN
								   SELECT @RtnLevel=ApproveLevel FROM [STS_ApprovalGroupSub] WHERE ApprovalGroupID=@AppGroupID AND parentid=@Authorizer AND CID=@CID;
								   INSERT INTO [STS_ApprovalGroupSub](ApprovalGroupID,parentid,ApproveLevel,ledgerid,CID) VALUES(@AppGroupID,@Authorizer,@RtnLevel,@Employee,@CID);
								END
							IF(NOT EXISTS(SELECT * FROM [STS_ResourceAllocation]  WHERE ProjectUID=@Project AND	RoleID=@Role AND LedgerID =@Employee AND CID = @CID ))	
								 BEGIN 
								   INSERT INTO [STS_ResourceAllocation](LedgerID,ProjectUID,RoleID,TotalHours,CID) VALUES(@Employee,@Project,@Role,0,@CID);	

								   SELECT @RtnResouceAllocationID=MAX(ResourceAllocationID) FROM [STS_ResourceAllocation] WHERE CID=@CID;

								   INSERT INTO [STS_ResourceAllocationSub](ResourceAllocationID,AllotedDate,AllotedHours,ApproveStatus,CID) VALUES(@RtnResouceAllocationID,CONVERT(DATE,@AllotDate,105),CONVERT(TIME,@AllotHrs,108),0,@CID);
				
									SET  @ERRORNO = 1;
									SET  @ERRORDESC ='Record inserted successfully'
								END  
							 ELSE 
								BEGIN
									DECLARE @ALLOCATIONID INT;
				   
									SELECT	@ALLOCATIONID=MAX(R.ResourceAllocationID)FROM [STS_ResourceAllocation] R WHERE ProjectUID=@Project AND RoleID=@Role AND LedgerID=@Employee AND CID = @CID 
			        
									INSERT INTO [STS_ResourceAllocationSub](ResourceAllocationID,AllotedDate,AllotedHours,ApproveStatus,CID) VALUES(@ALLOCATIONID,CONVERT(DATE,@AllotDate,105),CONVERT(TIME,@AllotHrs,108),0,@CID);
			
									SET  @ERRORNO = 1;
									SET  @ERRORDESC ='Record inserted successfully'
								END 
						FETCH NEXT FROM OUTER_CURSOR INTO @Employee								 
					 END
				CLOSE OUTER_CURSOR
			DEALLOCATE OUTER_CURSOR
	  END
	   COMMIT TRANSACTION                  
                 IF(@ERRORNO=1)                      
                    SET @DESC=@ERRORDESC + ' : ' + @Flag 
                 ELSE
                    SET @DESC=@ERRORDESC +' : ' + @Flag                          
            END TRY
            BEGIN CATCH
      ROLLBACK TRANSACTION
                  set @ERRORNO = ERROR_NUMBER()
                  SET @DESC='ERROR IN  Details' +' : '+ @Flag
                  set @ERRORDESC = ERROR_MESSAGE()            
      END CATCH	

END


IF (OBJECT_ID('SetProjectAllocationByWeek') IS NOT NULL)
  DROP PROCEDURE SetProjectAllocationByWeek
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SetProjectAllocationByWeek] 
	-- Add the parameters for the stored procedure here
		@CID					INT,
	@ProjectID				INT,
	@RoleID					INT,	
	@StartWeekNo			INT,
	@EndWeekNo				INT,
	@Year					INT,			
	@SetWeekEnd             INT,
	@SetHolidays			INT,
	@DT						TVPSTS_ProjectAllocationWeek_ExcelImport	READONLY,
	@GroupID				INT,
	@CreatedBy				INT,
	@CreatedDate			DateTime,
	@UpdatedBy				INT,
	@UpdatedDate			DateTime,
	@ReturnValue			INT output,
	@ReturnMessage			VARCHAR(max) OUTPUT

	--WITH ENCRYPTION

AS
BEGIN
	SET NOCOUNT ON;
	declare @LedgerID INT,@TimeZoneID int;
	DECLARE @CurrentTime DATETIME;
	--DECLARE @Week int=0,@Holidays int=0
	SET @CurrentTime = CURRENT_TIMESTAMP;
	DECLARE @DESC VARCHAR(MAX);
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
    -- Insert statements for procedure here
   -- DECLARE @getCur CURSOR;
    DECLARE @ALLOCATIONID INT=0,@ALLOTEDDATE VARCHAR(15),@ALLOTEDHOUR INT,@ResourceAllocationID INT;
			
	DECLARE getledgerdata CURSOR FOR  SELECT distinct em.LedgerID,EMS.TimeZoneID from @DT dt 
	inner join EmployeeMaster em on em.EmpID=dt.EmpID 
	INNER JOIN STS_EmployeeMasterSub EMS on EMS.LedgerID=em.LedgerID
	where em.CID=@CID;-- and em.InActive=0;

	OPEN getledgerdata
	FETCH NEXT FROM getledgerdata INTO @LedgerID,@TimeZoneID
	--SET @PrevWeekNo=0
	WHILE @@FETCH_STATUS = 0
		BEGIN

		   -- SELECT @LedgerID,@TimeZoneID;
			IF(NOT EXISTS(SELECT * FROM [STS_ResourceAllocation] WHERE ProjectUID=@ProjectID AND RoleID=@RoleID AND LedgerID=@LedgerID AND CID=@CID))
			BEGIN				
				INSERT INTO   [STS_ResourceAllocation]
									(LedgerID,
									ProjectUID,
									RoleID,
									CID) 
					VALUES        (@LedgerID,
									@ProjectID,
									@RoleID,
									@CID);
																   
					SET @ALLOCATIONID=@@IDENTITY;
					END
			ELSE
					BEGIN						
							SELECT  @ALLOCATIONID=ResourceAllocationID FROM [STS_ResourceAllocation] WHERE ProjectUID=@ProjectID AND RoleID=@RoleID AND LedgerID=@LedgerID AND CID=@CID ;
							DELETE  
							FROM      [STS_ResourceAllocationSub] 
							WHERE     ResourceAllocationID=@ResourceAllocationID 
							AND		 DATEPART(wk,AllotedDate) IN (SELECT Allotedweek FROM @DT) 
							AND       YEAR(AllotedDate)=@Year
							AND       CID=@CID;
					END
					--select * from STS_ResourceAllocationSub where ResourceAllocationID=60034
					--SELECT @ALLOCATIONID;
					if(@ALLOCATIONID!=0)
					BEGIN
							 	
						
						declare @YearNum			VARCHAR(4) 
						DECLARE @StartDate			DATE
						DECLARE @EndDate			DATE
						
						SET @YearNum=@Year;
						--SET @cid=101

						SET @StartDate=DATEADD(wk, DATEDIFF(wk, 6, '1/1/' + @YearNum) + (@StartWeekNo-1), 6) ;
						SET @EndDate=DATEADD(wk, DATEDIFF(wk, 5, '1/1/' + @YearNum) + (@EndWeekNo-1), 5) ;	
						--SELECT @StartDate,@EndDate;									
 
						
						CREATE TABLE #WeekendLeaveDays (TZID INT, date_ DATE, Leave FLOAT) --Leave (1 FullDay, 0.5 HalfDay)
						CREATE TABLE #FinalData(slno INT PRIMARY KEY,entrdate DATE,weekno INT,entryHrMins DECIMAL(5,1),OtherProjectHrMins DECIMAL(5,1), Leave FLOAT)
						CREATE TABLE #TempStartEndDate(dateEntry DATE,weekno INT,EntryHour DECIMAL(5,1))

						;WITH dates_CTE (bydate) AS 
						(
							SELECT @StartDate 
							UNION ALL
							SELECT DATEADD(day, 1, bydate)
							FROM dates_CTE
							WHERE bydate < @EndDate
						) 
						INSERT INTO #TempStartEndDate
						SELECT bydate,datepart(week, bydate) weekno,0 ledgerid FROM dates_CTE
 
						
						if(@SetWeekEnd=0)
						BEGIN
							;with cte(sDate) as 
							(
							select @StartDate
							union all
							select DATEADD(D,1,sDate) from cte where sDate < @EndDate
							)
							, cteweekSel as (
							SELECT WE.TimeZoneID,sDate,IsHalfDay FROM cte
								INNER JOIN STS_WeekEnds WE ON WE.WeekEnds=DATENAME(dw, cte.sDate)
								WHERE WE.CID=@CID and TimeZoneID=@TimeZoneID 
							)
							, CTE2 AS
							(
								SELECT TimeZoneID,sDate, min(IsHalfDay) IsHalfDay FROM cteweekSel 
								GROUP BY TimeZoneID , sDate 
							)
							INSERT INTO #WeekendLeaveDays
							select TimeZoneID,sDate,CASE WHEN (IsHalfDay=0) THEN 1 ElSE 0.5 END as fullHalf from CTE2 option (MAXRECURSION 0)
						END

						if(@SetHolidays=0)
						BEGIN
							insert into #WeekendLeaveDays
							SELECT TimeZoneID,HolidayDate,0 FROM STS_Holidays WHERE CID=@CID and year(HolidayDate)=@Year
						END

						--SELECT * FROM #TempStartEndDate;
						--SELECT * FROM #WeekendLeaveDays

						;WITH OtherProjectHours AS 
						(
							SELECT AllotedDate,ISNULL(SUM(DATEDIFF(MINUTE,  CAST('0:00' AS time),AllotedHours)),0) OtherAllotedHours FROM STS_ResourceAllocationSub 
							WHERE CID=@CID AND AllotedDate BETWEEN @StartDate AND @EndDate AND 
							ResourceAllocationID IN (SELECT ResourceAllocationID FROM STS_ResourceAllocation WHERE LedgerID=@LEDGERID AND ResourceAllocationID!=@ALLOCATIONID AND CID=@CID AND ProjectUID <> @ProjectID)
							GROUP BY AllotedDate
						)
						INSERT INTO #FinalData
						SELECT ROW_NUMBER() OVER(ORDER BY T1.dateentry ASC),T1.dateEntry,T1.weekno,0,ISNULL(T3.OtherAllotedHours,0), ISNULL(T2.Leave,0) Leave FROM #TempStartEndDate T1 
						LEFT JOIN #WeekendLeaveDays T2 ON T1.dateEntry = T2.date_ AND T2.Leave < 1
						LEFT JOIN OtherProjectHours T3 ON T1.dateEntry=T3.AllotedDate
						WHERE T1.dateEntry NOT IN (SELECT date_ FROM #WeekendLeaveDays WHERE Leave=1)


						DECLARE @entryDate		DATE
						DECLARE @WeekNo			INT
						DECLARE @PrevWeekNo		INT
						DECLARE @entryHrMins	DECIMAL(5,1)
						DECLARE	@OtherHrMins	DECIMAL(5,1)
						DECLARE @Leave			FLOAT
						DECLARE @WorkHrMins		FLOAT
						DECLARE @DailyAllotMins FLOAT

						SELECT @WorkHrMins=ISNULL(DATEDIFF(MINUTE,  CAST('0:00' AS time),WorkingHours),0)  
						FROM STS_DailyWorkingHours WHERE HoursOfDay='FullDay' AND CID=@CID AND TimeZoneID = @TimeZoneID

						DECLARE db_Cursor CURSOR FOR SELECT entrdate,weekno,OtherProjectHrMins,Leave FROM #FinalData  FOR UPDATE OF entryHrMins
						OPEN db_Cursor

						FETCH NEXT FROM db_Cursor INTO @entryDate,@WeekNo,@OtherHrMins,@Leave
						SET @PrevWeekNo=0
						WHILE @@FETCH_STATUS = 0
						BEGIN
							IF @PrevWeekNo <> @WeekNo
							BEGIN
								SELECT @entryHrMins=AllotedHour*60  FROM @DT WHERE Allotedweek=@WeekNo
								SET @PrevWeekNo=@WeekNo
							END
							SET @DailyAllotMins = IIF(@entryHrMins >= @WorkHrMins-(@Leave*@WorkHrMins)-@OtherHrMins,@WorkHrMins-(@Leave*@WorkHrMins)-@OtherHrMins, @entryHrMins)
							SET @entryHrMins= @entryHrMins-@DailyAllotMins
							UPDATE #FinalData SET entryHrMins = @DailyAllotMins WHERE CURRENT OF db_Cursor
	
							FETCH NEXT FROM db_Cursor INTO @entryDate,@WeekNo,@OtherHrMins,@Leave
						END

						CLOSE db_Cursor
						DEALLOCATE db_Cursor

						--select @WorkHrMins

						insert into STS_ResourceAllocationSub (ResourceAllocationID,AllotedDate,AllotedHours,cid) 
						select @ALLOCATIONID,entrdate,CONVERT(TIME,SUBSTRING(CONVERT(NVARCHAR, DATEADD(MINUTE, entryHrMins, ''), 108), 1, 5)),@CID from #FinalData;

						drop TAble #FinalData
						DROP TABLE #TempStartEndDate
						DROP TABLE #WeekendLeaveDays
						--DROP TABLE #EntryWeekData


						SET @ReturnValue='1';
						SET @ReturnMessage='Record Inserted Successfully';
					END			

			--SELECT @LedgerID;
			FETCH NEXT FROM getledgerdata INTO @LedgerID,@TimeZoneID
		END		
	CLOSE getledgerdata
	DEALLOCATE getledgerdata	
		
    
    COMMIT TRANSACTION
	  if(@ReturnValue=1)
		BEGIN
			SET @DESC=@ReturnMessage + ' : ' + 'ADD' 
			-- EXEC STS_SetElog @CID,@UserID,@CurrentTime,@GroupID,'Project Allocation by week Excel Import ',@ReturnValue,@DESC,@ErrorMessage,7,0,4,'';
		END
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
				SET @ReturnValue = ERROR_NUMBER()
				SET @DESC='ERROR IN  Details' +' : '+ 'ADD'
				SET @ReturnValue=0;
				SET @ReturnMessage='Error Message:'+ERROR_MESSAGE();
				--  EXEC STS_SetElog @CID,@UserID,@CurrentTime,@GroupID,'Project Allocation by week Excel Import',@ReturnValue,@DESC,@ErrorMessage,5,3,4,'';
			
				
	END CATCH

END

IF (OBJECT_ID('GetProjectEffortApproval') IS NOT NULL)
  DROP PROCEDURE GetProjectEffortApproval
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetProjectEffortApproval] 
	@CID				VARCHAR(50),
	@Flag				VARCHAR(50),
	@EmployeeID			VARCHAR(30),	
	@DType				VARCHAR(30),
	@Fromdate			VARCHAR(20),
	@ToDate				VARCHAR(20),
	@Month				VARCHAR(20),
	@Year				VARCHAR(20),
	@ProjectID			VARCHAR(20),
	@UserID				VARCHAR(20)

AS
BEGIN
    
	--SET @UserID=2508;
       --select * from [STS_ETSEffort];
  
    Declare @RtnGroupID     INT;
	Declare @RtnGroupLevel  INT;
	Declare @RtnMaxLevel    INT;
	Declare @RtnLevel       INT;
	Declare @RtnHierarchy   INT=0;

	DECLARE @CurrentTime	DATETIME;
	DECLARE @COUNT          INT;	
	DECLARE @DESC			VARCHAR(MAX);	
	DECLARE @SQLSTRING		nVARCHAR(MAX);
	DECLARE @QUERY			nVARCHAR(MAX);
	DECLARE @CONDITION		nVARCHAR(MAX);

    SET @CurrentTime		= CURRENT_TIMESTAMP;

	CREATE TABLE #Temp (ApprovalGroupID INT,LedgerID INT,ApproveLevel INT,HierachyAuth INT)
	CREATE TABLE #Temp1 (LedgerID INT,ApprovalGroupID INT,Parent INT)

 INSERT INTO #Temp
 select ApprovalGroupID,parentid,ApproveLevel,ledgerid  from [STS_ApprovalGroupSub] 
    
	
    IF(@Flag='LOADDDL')
		BEGIN		
			   DECLARE @UserName VARCHAR(50);
		   
			   SELECT @UserName=UserName FROM [UserMgt] WHERE CID=@CID AND LedgerID=@UserID;
		   
			--get company name
			  IF(EXISTS(SELECT * FROM  [UserSiteAccess] WHERE CID=@CID ))
				 BEGIN
						SELECT USA.SiteID,CompanyName AS SiteName FROM UserSiteAccess USA
						INNER JOIN SiteMaster SM ON sm.SiteID=usa.SiteID
						WHERE usa.CID=@CID AND UserName=@UserName
					 UNION
						 SELECT SiteID,CompanyName AS SiteName FROM SiteMaster WHERE SiteID=@CID AND CID=@CID					 
					END
				ELSE
					BEGIN
						SELECT          S.CompanyName AS SiteName,
										S.CID AS SiteID  
						FROM            [SiteMaster] S
						INNER JOIN      [UserMgt] UM 
						ON              UM.DefaultSite = s.CID
						WHERE           UM.UserName =  @UserName 
					
					END
	      
			--get employeename
				SELECT      LedgerID,
							EmpID+'  '+AliasName1 AS Name  
				FROM		[EmployeeMaster]
				WHERE	    InActive=0 AND CID=@CID
				ORDER BY	AliasName1 
         
		    --get project    
			  	SELECT       ProjectID ,
							 ProjectUID 
				FROM         [ProjectMaster] 
				WHERE        ProjectStatus=0 
				AND			 CID=@CID
				ORDER BY     ProjectID     
		END	
	ELSE IF(@Flag='LOADGRID')

		BEGIN
				SELECT     @Count=Count(*) 
				FROM       [STS_ApprovalGroupSub] Ags
				INNER JOIN [STS_ApprovalGroup] Ag on Ags.ApprovalGroupID=Ag.ApprovalGroupID and Ag.CID=Ags.CID  
				WHERE      Ags.parentid=@UserID 
				AND        Ag.TypeID=@ProjectID and Ags.CID=@CID;
															    
	     IF(@Count>0)	
			BEGIN				
					SELECT     @RtnGroupID=ags.ApprovalGroupID 
					FROM       [STS_ApprovalGroupSub] ags 
					INNER JOIN [STS_ApprovalGroup] ag ON ags.ApprovalGroupID=ag.ApprovalGroupID AND ags.CID=ag.CID
					WHERE      ags.parentid=@UserID and ag.TypeID=@ProjectID and ags.CID=@CID;
				
					SELECT @RtnMaxLevel=Max(ApproveLevel) FROM [STS_ApprovalGroupSub] WHERE ApprovalGroupID=@RtnGroupID and CID=@CID;

					SELECT @RtnLevel=ApproveLevel FROM [STS_ApprovalGroupSub] WHERE parentid=@UserID and ApprovalGroupID=@RtnGroupID and CID=@CID;
								
			IF(@RtnLevel!=1)
				 BEGIN							
					SELECT @SQLSTRING='WITH CTE(parentid, ApprovalGroupID, ParentAccount,SORT) AS
										(
										SELECT		parentid , ApprovalGroupID ,ledgerid,RIGHT(REPLICATE(''0'',5) + CAST(ROW_NUMBER() 
										OVER(ORDER BY  parentid ASC, ApproveLevel ASC) as VARCHAR(MAX)),6) SORT  
										FROM		[STS_ApprovalGroupSub] 
										WHERE		parentid=@UserID and ApprovalGroupID=@RtnGroupID 

										--UNION ALL									
										)  ,
										cte2 as (

										SELECT		a.parentid, a.ApprovalGroupID , a.ledgerid AS ParentAccount,(SORT + RIGHT(REPLICATE(''0'',5) +
										 CAST(ROW_NUMBER() OVER(ORDER BY a.ApproveLevel ASC) as VARCHAR(MAX)),6))  SORT 
										FROM		[STS_ApprovalGroupSub]  A 
										INNER JOIN	CTE B 
										ON			a.parentid= b.ParentAccount 

										)
										INSERT INTO #Temp1 
										SELECT  parentid, ApprovalGroupID, ParentAccount FROM CTE2
										union all
										SELECT  parentid, ApprovalGroupID, ParentAccount FROM CTE'		
														
							EXEC sp_executesql @SQLSTRING,
											 N'@RtnLevel		INT OUTPUT,
											   @UserID			VARCHAR(20),
											   @RtnGroupID		INT',
											   @RtnLevel		=@RtnLevel OUTPUT,
											   @UserID		    =@UserID,
											   @RtnGroupID		=@RtnGroupID;
						
							--select @SQLSTRING;
					END
					 --
					SET @QUERY='WITH CTE AS ( 
												SELECT      e.SlNo,
														
															r.AliasName1 AS Name,
															e.Descriptions,
															pr.ProjectID AS Project,
															
															e.EffortDate,
															ISNULL(e.StartTime,getdate()) As StartTime,
															ISNULL(e.EndTime,getdate()) As EndTime,
															ISNULL((SELECT EO.OT FROM [STS_EmployeeOT] EO WHERE EO.LedgerID=E.LedgerID AND EO.CID=E.CID AND EO.OTDate=E.EntryDate),''00:00'') as OT,
														
															e.Duration AS EffortHours,
															e.Approved,
															e.AuthStatus,
															e.LastApprovedBy,
															e.LedgerID,
															CASE WHEN AuthStatus=''O'' then ''0'' when AuthStatus=''A'' then ''1'' when AuthStatus=''P'' and @RtnLevel=Approved then ''1'' else ''0'' end as ChkStatus,
															(	
																SELECT	    ISNULL(CONVERT(VARCHAR(10) ,IsHalfDays),'''') 
																FROM		dbo.fn_LeaveDay(@CID,e.LedgerID,e.EffortDate,e.EffortDate)
																WHERE		DateValue=e.EffortDate 
																GROUP BY	IsHalfDays 
															)   AS			IsHalfDay
															

										FROM		[STS_ETSEffort] e
										
										INNER JOIN  [EmployeeMaster] r ON r.LedgerID=e.LedgerID and r.CID=e.CID 
										
										LEFT JOIN   [ProjectMaster] pr ON pr.ProjectUID=e.ProjectUID and pr.CID=e.CID
										
										WHERE		e.SlNo IS NOT NULL and e.ProjectUID=@ProjectID and e.CID=@CID )
										SELECT      SlNo,													
													Name,
													Descriptions,
													Project,												
													EffortDate,
													StartTime,
													EndTime,
													OT,
													EffortHours,
													IsHalfDay,
													AuthStatus,
													Approved,
													LastApprovedBy,
													LedgerID  ,
													ChkStatus


										FROM        CTE t where t.SlNo is not null'
--SELECT @QUERY;
				 IF(@DType='ByDate')
						BEGIN
				  
							SET @QUERY = @QUERY + ' AND  CONVERT(DATE,t.EffortDate,105)  BETWEEN CONVERT(DATE,'''+@Fromdate+''', 105) AND CONVERT(DATE,'''+@ToDate+''', 105)';
							--SET @QUERY = @QUERY + ' AND  t.EffortDate BETWEEN '''+@Fromdate+ '''AND''' +@ToDate+'';
						END
				
				
							
				IF(@RtnLevel<>1)
						BEGIN
							SET @QUERY = @QUERY + ' and t.AuthStatus in (''P'',''O'') '
			
							SELECT @RtnHierarchy= HierachyAuth FROM #Temp 
							WHERE  ApprovalGroupID IN (SELECT ApprovalGroupID FROM  [STS_ApprovalGroup]  WHERE TypeID=@ProjectID AND CID=@CID)
							AND    LedgerID=@UserID 
							AND    ApproveLevel=@RtnLevel 
							AND    ApprovalGroupID=@RtnGroupID 
							
						   IF (@RtnMaxLevel>=@RtnLevel AND @RtnHierarchy=0)
								BEGIN
									SET @QUERY = @QUERY + ' and (t.AuthStatus in (''O'') or LastApprovedBy=@UserID)' 
								END
						   IF (@RtnMaxLevel>=@RtnLevel AND @RtnHierarchy<>0)
								BEGIN

									SET @QUERY = @QUERY + ' and (t.AuthStatus not in (''A'') or t.ledgerid in (
									select distinct parentid from [STS_ApprovalGroupSub] where ApprovalGroupID=@RtnGroupID and ApproveLevel >=@RtnLevel
									Union 
									select distinct ledgerid from [STS_ApprovalGroupSub] where ApprovalGroupID=@RtnGroupID and ApproveLevel >=@RtnLevel))' 
								END
						END
						
                				
				SET @QUERY=@QUERY+'order by convert(date,effortdate) desc';
				--Select @QUERY;	
				EXEC sp_executesql @QUERY,	
									N'@CID    VARCHAR(50),
									  @ProjectID VARCHAR(20),
									  @RtnLevel int,
									  @UserID  int,
									  @RtnGroupID int,
									  @RtnHierarchy  INT OUTPUT',
									  @CID    = @CID,
									  @ProjectID = @ProjectID,
									  @RtnLevel=@RtnLevel,
									  @UserID=@UserID,
									  @RtnGroupID=@RtnGroupID,
									  @RtnHierarchy = @RtnHierarchy;
					
					--select @query;				  										 
		END	
			
	END		
		--set @ErrorMessage= @QUERY;
			   
	DROP TABLE #Temp1;	
	DROP TABLE #Temp;  
			 							
END




IF (OBJECT_ID('STS_SetTimePunch') IS NOT NULL)
  DROP PROCEDURE STS_SetTimePunch
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[STS_SetTimePunch]  
	 @CID         INT,
	 @Flag        VARCHAR(25),
	 @Time		  VARCHAR(25),
	 @Date        VARCHAR(15),
	 @SlNo        VARCHAR(25),
	 @Status	  VARCHAR(25),
	 @LedgerID    VARCHAR(25),
	 @GroupID	  VARCHAR(25),
	 @TPID		  VARCHAR(25),
	 @UserID	  VARCHAR(25),
	 @ReturnValue INT OUTPUT,
	 @ErrorMessage VARCHAR(MAX) OUTPUT

	-- WITH ENCRYPTION

AS
BEGIN
	DECLARE	  @DESC		          VARCHAR(MAX);
	DECLARE	  @CurrDateTime       DATETIME;
	DECLARE	  @RtnTPID			  VARCHAR(10);
	SET		  @CurrDateTime	=CURRENT_TIMESTAMP;
	DECLARE   @RowCnt			  INT;
	BEGIN TRY
	     BEGIN TRANSACTION
		      IF(@Flag='EDIT')
			    BEGIN
				      UPDATE [STS_EmpTimePunchSub] SET CheckedIn=CONVERT(datetime,@Time,104)  WHERE Slno=@SlNo AND CID=@CID ;
		
					  SET @ReturnValue='1';								 
					  SET @ErrorMessage='Record updated successfully';
				END
             ELSE IF(@Flag='DELETE')
			    BEGIN
				      DELETE FROM [STS_EmpTimePunchSub] WHERE Slno=@SlNo AND CID=@CID;
					
					  SET @ReturnValue='0';								 
					  SET @ErrorMessage='Record deleted successfully';
				END
			ELSE IF(@Flag='ADD')
				BEGIN				     
				
					
					SELECT  @RowCnt=COUNT(*) FROM  [STS_EmpTimePunch]  WHERE LedgerID = @LedgerID AND Date=CONVERT(DATE,@Date,105) AND CID=@CID;

				  IF(@RowCnt=0) 
				     BEGIN		
				    	 INSERT INTO  [STS_EmpTimePunch](LedgerID,Date,CID) VALUES (@LedgerID ,CONVERT(DATE,@Date,105),@CID)	
					    
						 SELECT @RtnTPID=MAX(TPID) FROM [STS_EmpTimePunch] WHERE LedgerID=@LedgerID AND Date=CONVERT(DATE,@Date,105) AND CID=@CID;

						 INSERT INTO [STS_EmpTimePunchSub] (TPID,CheckedIn,CheckedType,DeviceAppNo,CID) VALUES(@RtnTPID,CONVERT(DATETIME,@Time,104) ,@Status,9999,@CID)
				  
				         SET @ReturnValue='0';
						 SET @ErrorMessage='Record Inserted Successfully';
				     END	
				 ELSE
				     BEGIN
					    SELECT @RtnTPID=MAX(TPID) FROM [STS_EmpTimePunch] WHERE LedgerID=@LedgerID AND Date=CONVERT(DATE,@Date,105) AND CID=@CID;
					    INSERT INTO [STS_EmpTimePunchSub] (TPID,CheckedIn,CheckedType,DeviceAppNo,CID) VALUES(@RtnTPID,CONVERT(DATETIME,@Time,104) ,@Status,9999,@CID)
						
						SET @ReturnValue='0';
					 	SET @ErrorMessage='Record Inserted Successfully';
					 END
				END
		 COMMIT TRANSACTION
		   IF(@ReturnValue=1)                      
                    SET @DESC=@ErrorMessage + ' : ' + @Flag 
                 ELSE
                    SET @DESC=@ErrorMessage +' : ' + @Flag   
               
            --EXEC STS_SetElog @CID,@UserID,@CurrDateTime,@GroupID,'Time Punch',@ReturnValue,@DESC,@ErrorMessage,7,0,4,'';
	END TRY
	BEGIN CATCH
	        ROLLBACK TRANSACTION
		  	SET @ReturnValue = ERROR_NUMBER()
				SET @DESC='ERROR IN  Details' +' : '+ @Flag
				SET @ReturnValue=0;
				SET @ErrorMessage='Error Message:'+ERROR_MESSAGE();
				--EXEC STS_SetElog @CID,@UserID,@CurrDateTime,@GroupID,'Time Punch',@ReturnValue,@DESC,@ErrorMessage,5,3,4,'';	
	END CATCH

END

IF (OBJECT_ID('STS_SetTimePunch') IS NOT NULL)
  DROP PROCEDURE STS_SetTimePunch
GO

IF (OBJECT_ID('GetUserDetails') IS NOT NULL)
  DROP PROCEDURE GetUserDetails
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: <Author,,Name>
-- Create date: <Create Date,,>
-- Description: <Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetUserDetails]
-- Add the parameters for the stored procedure here
	@CID			INT,
	@UserName		nVARCHAR(20),
	@ADDomain		nVARCHAR(20)='',
	@ActiveDirectoryLogin		BIT=0,
	@ElogDate		DATE OUTPUT
--UNLOCK-- WITH ENCRYPTION 
 AS 
 BEGIN

	SET NOCOUNT ON;
	
	DECLARE @STATUS INT=0;

	IF @ActiveDirectoryLogin = 0
		BEGIN
			Select @STATUS=COUNT(InActive) from [UserMgt] where CID = @CID AND  UserName  COLLATE Latin1_General_CS_AS = @UserName AND Status<>'Deleted'
	
			IF(@STATUS=0)
				BEGIN
					RAISERROR('2',18,1) --RAISERROR('Invalid UserID',18,1)
					return -1
				END
			ELSE
				Select UserID, UserName, LedgerID, InActive, Password, GroupID, (select GroupName from [GroupMgt] where CID = @CID and GroupID=UM.GroupID) AS GroupName, DefaultLngCode, ERPMainColor,ERPSecondaryColor,
				ActiveDirectoryPath 
				from [UserMgt] UM where CID = @CID AND UserName COLLATE Latin1_General_CS_AS = @UserName;
		END

	ELSE
		BEGIN
			Select @STATUS=COUNT(InActive) from [UserMgt] where CID = @CID AND  ActiveDirectoryDomain = @ADDomain AND ActiveDirectoryUserID = @UserName and Status<>'Deleted'
	
			IF(@STATUS=0)
				BEGIN
					RAISERROR('2',18,1) --RAISERROR('Invalid UserID',18,1)
					return -1
				END
			ELSE
				Select UserID, UserName, LedgerID, InActive, Password, GroupID, (select GroupName from [GroupMgt] where CID = @CID and GroupID=UM.GroupID) AS GroupName, DefaultLngCode,ERPMainColor,ERPSecondaryColor, 
				ActiveDirectoryPath 
				from [UserMgt] UM where CID = @CID AND ActiveDirectoryDomain = @ADDomain AND ActiveDirectoryUserID = @UserName;
		END
		
	
		SELECT @ElogDate=MAX(DateTime_) FROM [Elog] WHERE CID=@CID		
	
END

GO

IF (OBJECT_ID('UserMgtUpdated') IS NOT NULL)
  DROP PROCEDURE UserMgtUpdated
GO
/****** Object:  StoredProcedure [dbo].[UserMgtUpdated]    Script Date: 10/27/2020 7:31:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UserMgtUpdated]
	-- Add the parameters for the stored procedure here
	  @CID						INT,
	  @UserID					INT,
	  @UserName					nVARCHAR(100),
	  @UserIDOld				INT,
      @Password					nVARCHAR(100), 
      @GroupID					INT, 
      @InActive					BIT,
      @DefaultSite				nVARCHAR(100), 
      @UpdatedBy				INT,
      @UpdatedDate				DATE,
      @ShowPopUp				BIT,
      @LedgerID					INT,
      @LngCode					INT,
	  @MainColor				nVARCHAR(20),
	  @SecondaryColor			nVARCHAR(20),
      @Flag						VARCHAR(50),
	  @ActiveDirectoryPath		nVARCHAR(50),
	  @ActiveDirectoryDomain	nVARCHAR(50),
	  @ActiveDirectoryUserID	nVARCHAR(50),
	  --@jsondt					NVARCHAR(MAX),
      @SiteAccessDT				[TVP_UserMgtSiteAccess] READONLY,
      @ERRORNO					INT						OUTPUT,
	  @ERRORDESC				VARCHAR(MAX)			OUTPUT,
	  @USERIDOUT				INT						OUTPUT
	  
--UNLOCK-- WITH ENCRYPTION 
 AS 
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE	@DESC					VARCHAR(MAX)	
	SET		@ERRORNO				= 0 	
	BEGIN TRY
	BEGIN TRANSACTION @ERRORDESC
  
		IF(@Flag='ADD')
			BEGIN
				SELECT @UserID = MAX(USERID) FROM usermgt;
				SET @UserID = ISNULL(@UserID,0)+1;
				SET @USERIDOUT = @UserID;

	  			INSERT INTO [UserMgt] (CID,	UserID,	UserName, ShowPopUp, HidePopUp,Password, GroupID, DefaultSite, CreatedDate, CreatedBy,	
										InActive,Status,LedgerID, DefaultLnGCode, ActiveDirectoryPath, ActiveDirectoryDomain, ActiveDirectoryUserID,ERPMainColor,ERPSecondaryColor
													) 
				VALUES  (@CID, @UserID, @UserName, @ShowPopUp, @ShowPopUp, @Password, @GroupID, @DefaultSite, @UpdatedDate,	@UpdatedBy,
						@InActive, '', @LedgerID, @LngCode, @ActiveDirectoryPath, @ActiveDirectoryDomain, @ActiveDirectoryUserID,@MainColor,@SecondaryColor)									
						
				INSERT INTO [UserSiteAccess] (CID,UserName,SiteID,Approved,UserID) 
				SELECT		@CID,@UserName,SiteID,Approved,@UserID 
				FROM		@SiteAccessDT 
				WHERE		Approved='True'
						
			END
	   			 
	   			    			 
	 IF(@Flag='EDIT')
				 BEGIN
						SET @USERIDOUT = @UserID;
						DECLARE @UserCount INT=0;
							
						SELECT		@UserCount=Count(*) 
										FROM		[Elog] 
										WHERE		CID=@CID
										AND			UserID=@UserIDOld
							
						IF (@UserID<>@UserIDOld) AND (@UserCount=0)
							BEGIN	
									UPDATE [UserMgt] 
													   SET	  UserID				= @UserID,
															  UserName				= @UserName,
															  ShowPopUp				= @ShowPopUp,
															  HidePopUp				= @ShowPopUp,
															  Password				= @Password,
															  GroupID				= @GroupID,
															  DefaultSite			= @DefaultSite,
															  LastUpdatedBy			= @UpdatedBy,
															  LastUpdatedDate		= @UpdatedDate,
															  InActive				= @InActive,
															  LedgerID				= @LedgerID,
															  DefaultLngCode		= @LngCode,
															  ActiveDirectoryPath	= @ActiveDirectoryPath, 
															  ActiveDirectoryDomain	= @ActiveDirectoryDomain, 
															  ActiveDirectoryUserID	= @ActiveDirectoryUserID,
															  ERPMainColor			= @MainColor,
															  ERPSecondaryColor		= @SecondaryColor
														WHERE CID				= @CID
														AND	  UserID			= @UserIDOld
							END
						ELSE
							BEGIN
									UPDATE [UserMgt] 
													   SET	  ShowPopUp				= @ShowPopUp,
															  HidePopUp				= @ShowPopUp,
															  Password				= @Password,
															  GroupID				= @GroupID,
															  DefaultSite			= @DefaultSite,
															  LastUpdatedBy			= @UpdatedBy,
															  LastUpdatedDate		= @UpdatedDate,
															  InActive				= @InActive,
															  LedgerID				= @LedgerID,
															  DefaultLngCode		= @LngCode,
															  ActiveDirectoryPath	= @ActiveDirectoryPath, 
															  ActiveDirectoryDomain	= @ActiveDirectoryDomain, 
															  ActiveDirectoryUserID	= @ActiveDirectoryUserID,
															  ERPMainColor			= @MainColor,
															  ERPSecondaryColor		= @SecondaryColor
														WHERE CID					= @CID
														AND	  UserID				= @UserID
							END
					  
									
														
						  
							DELETE  FROM [UserSiteAccess] 
														WHERE CID	  = @CID
														AND	 UserID		= @UserID
						
						
							INSERT INTO [UserSiteAccess] 
															(
															CID,
															UserName,
															SiteID,
															Approved,
															UserID
															)
														SELECT 
															@CID,
															@UserName,
															SiteID,
															Approved,
															@UserID 
														FROM   @SiteAccessDT 
														WHERE  Approved='True'										 
				 END
	   			 
	  IF(@Flag='DELETE')
				 BEGIN
											
							
													   UPDATE		[UserMgt] 
													   SET			Status='Deleted' 
													   WHERE		CID=@CID
													   AND			UserID=@UserID

				 END
		IF(@Flag='THEME')
				 BEGIN
											
							
													   UPDATE		[UserMgt] 
													   SET			ERPMainColor		= @MainColor,
																	ERPSecondaryColor	= @SecondaryColor 
													   WHERE		CID=@CID
													   AND			UserID=@UserID

				 END
	  
       
	COMMIT TRANSACTION
			 SET @ERRORNO = 0
			 SET @DESC='Sucessfully'+''+@Flag+'ED'+''+'UserMgt Details'+' : '+@UserName		
			 set @ERRORDESC = ''
		--EXEC sp_ElogUpdate @CID,0,@CreatedBy,@LastUpdatedDate,'','UserMgt',@ERRORNO,@DESC,@ERRORDESC,7,0,4;
		END TRY
		BEGIN CATCH
	ROLLBACK TRANSACTION
			set @ERRORNO = ERROR_NUMBER()
			SET @DESC='ERROR IN '+''+@Flag+'ED'+''+'UserMgt Details'+' : '+@UserName	
			set @ERRORDESC = ERROR_MESSAGE()
		--EXEC sp_ElogUpdate @CID,0,@CreatedBy,@LastUpdatedDate,'','UserMgt',@ERRORNO,@DESC,@ERRORDESC,5,3,4;
	END CATCH  	
	  
END

GO
IF (OBJECT_ID('STS_SetProjectWiseAttendance') IS NOT NULL)
  DROP PROCEDURE STS_SetProjectWiseAttendance
GO
DROP TYPE [dbo].[TVPSTS_ProjectwiseAtt]
GO
/****** Object:  UserDefinedTableType [dbo].[TVPSTS_ProjectwiseAtt]    Script Date: 10/27/2020 7:54:08 PM ******/
CREATE TYPE [dbo].[TVPSTS_ProjectwiseAtt] AS TABLE(
	[LedgerID] [int] NULL,
	[Attendance] [int] NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[Effort] [time](7) NULL,
	[OT] [time](7) NULL,
	[Comment] [varchar](max) NULL
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create DATE: <Create DATE,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[STS_SetProjectWiseAttendance] 
	-- Add the parameters for the stored procedure here
	  @CID				    INT,
	  @Date				    DATE,	 	
      @ProjectUID			INT,
	  @DT			        [TVPSTS_ProjectwiseAtt]	READONLY,	 
      @ERRORNO				INT						OUTPUT,
	  @ERRORDESC			VARCHAR(MAX)			OUTPUT 
	        
	 --WITH ENCRYPTION

 AS 
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- INTerfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE	@CurrentTime	DATETIME;
	
	DECLARE @UserID						VARCHAR(50)='';
	DECLARE @GroupID					VARCHAR(20)='';
	Declare @Year                       INT=year(@date)
	
	BEGIN TRY
	BEGIN TRANSACTION @ERRORDESC
	
	IF OBJECT_ID('tempdb..#Temp')is null
		CREATE TABLE #Temp (LedgerID INT,LeaveType VARCHAR(20), Comment VARCHAR(500)  COLLATE DATABASE_DEFAULT);

	
		DECLARE @LedgerID INT,@Comment VARCHAR(250),@LeaveType VARCHAR(20)
		DECLARE @RtnLeaveID INT=0;
					
			
		DELETE FROM [STS_EmployeeOT] WHERE CID=@CID AND OTDate = @Date and LedgerID IN (select LedgerID from @DT);
			         
		
		DELETE FROM [STS_ETSEffort] WHERE CID=@CID and EffortDate = @Date and ProjectUID=@ProjectUID and LedgerID IN (select LedgerID from @DT);
					
		
		
		INSERT INTO     [STS_EmployeeOT] 
						(LedgerID,
						OTDate,
						OT,
						Comment,
						Approve,
						CID)
		SELECT          LedgerID,
						@Date,
						OT,
						Comment,
						0,
						@CID
		FROM            @DT DT 
		WHERE			CONVERT(DECIMAL(18,2),REPLACE(CONVERT(varchar(5),OT), ':',  '.'))>0;
			      
			
		INSERT INTO [STS_ETSEffort] 
					(LedgerID,
					EffortDate,
					CategoryID,
					EntryDate,
					StartTime,
					EndTime,
					Duration,
					ProjectUID,
					Descriptions,
					CID)
		SELECT      LedgerID,
					@Date,
					101,
					@Date,
					StartTime,
					EndTime,
					Effort,
					@ProjectUID,
					Comment,
					@CID
		FROM        @DT DT 
		--WHERE       CONVERT(DECIMAL(18,2),Effort)>0 and CONVERT(DECIMAL(18,2),DT.StartTime)>0 and CONVERT(DECIMAL(18,2),DT.EndTime)>0;
		WHERE       CONVERT(DECIMAL(18,2),REPLACE(CONVERT(varchar(5),Effort), ':',  '.'))>0;
			
			
			
		INSERT INTO #Temp
		SELECT		DT.LedgerID,
					DT.Attendance AS LeaveType,
					DT.Comment 
		FROM		@DT DT 
		WHERE		Attendance<>101 AND Attendance<>123
					
					
		DECLARE db_cursor CURSOR FOR 
		SELECT * FROM #Temp
		OPEN db_cursor  
		FETCH NEXT FROM db_cursor INTO @LedgerID,@LeaveType,@Comment  

		WHILE @@FETCH_STATUS = 0  
		BEGIN   
				EXEC	STS_SetLeaveApproval	
						@CID                = @CID,
						@Flag				='ADD',
						@LedgerID			=@LedgerID,
						@LeaveID			='',
						@EmpUniqID		    ='',
						@LeaveType		    =@LeaveType,
						@Comments           =@Comment,
						@DayStatus          =1,	
						@FromDate			=@Date,
						@ToDate				=@Date,
						@Days			    =1,
						@Session            ='',	
						@UserID				=@UserID,
						@GroupID			=@GroupID,
						@Type				=1,	
						@ReturnValue		=1,
						@ErrorMessage	    ='',
						@Year               =@Year,
						@ReturnDate			=@Date									
														
				FETCH NEXT FROM db_cursor INTO  @LedgerID,@LeaveType,@Comment   
		END 
		CLOSE db_cursor  
		DEALLOCATE db_cursor 
				
		
	COMMIT TRANSACTION
			 SET @ERRORNO = 0
			  --SET @DESC='ERROR IN  Details' +' : '+ @Flag
			   set @ERRORDESC = ERROR_MESSAGE()
			 --SET @DESC='Sucessfully'+''+@Flag+'ED'+''+'Attendance Details'	
			 --set @ERRORDESC = ''
		
		 --EXEC STS_SetElog @CID,@UserID,@CurrentTime,@GroupID,'ProjectWise Attendance',@ERRORNO,@DESC,@ERRORDESC,5,3,4,'';
		END TRY
		BEGIN CATCH
	ROLLBACK TRANSACTION
			set @ERRORNO = ERROR_NUMBER()
			--SET @DESC='ERROR IN '+''+@Flag+'ED'+''+'BOM Details'
			set @ERRORDESC = ERROR_MESSAGE()
		
		 --EXEC STS_SetElog @CID,@UserID,@CurrentTime,@GroupID,'ProjectWise Attendance',@ERRORNO,@DESC,@ERRORDESC,5,3,4,'';
	END CATCH
	
END
GO
IF (OBJECT_ID('STS_GetTimePunchReport') IS NOT NULL)
  DROP PROCEDURE STS_GetTimePunchReport
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[STS_GetTimePunchReport]	
	-- Add the parameters for the stored procedure here
	@CID			int,
	@Flag			VARCHAR(30),
	@LedgerID		VARCHAR(30),
	@Date			VARCHAR(30),
	@Category		VARCHAR(100),
	@DType			VARCHAR(75),
	@CMonth		    VARCHAR(75),
	@ByYear         VARCHAR(75),
	@ByMonth		VARCHAR(75),
	@FromDate       VARCHAR(75),
	@ToDate			VARCHAR(75),
	@ByMonthYear	VARCHAR(75),
	@JoinType	    VARCHAR(25),
	@LeaveID		Int
AS
BEGIN
	DECLARE @SQLSTRING				 NVARCHAR(MAX);
	DECLARE @SQLSTRING1				 NVARCHAR(MAX);
	DECLARE @Duration				 NVARCHAR(MAX);
	
	Declare @RtnIN Varchar(5),@RtnOut Varchar(5);
	Declare @OThours TIME;
	Declare @DateDiff INT;
	DECLARE @Condition				 NVARCHAR(MAX);
	
	Set @SQLSTRING ='Select @RtnIN=Tag from [STS_Entity] where Tag in (''FI'',''LI'') and ReadOnlyTag = 1 AND CID=@CID'
	EXECUTE sp_executesql @SQLSTRING, 
											N'@RtnIN  Varchar(5)  Output,@CID int',
											  @RtnIN = @RtnIN Output,@CID =@CID;
	Set @SQLSTRING ='Select @RtnOut=Tag from [STS_Entity] where Tag in (''FO'',''LO'') and ReadOnlyTag = 1 AND CID=@CID'
	EXECUTE sp_executesql @SQLSTRING, 
											N'@RtnOut  Varchar(5)  Output,@CID int',
											  @RtnOut = @RtnOut Output,@CID =@CID

		Set @SQLSTRING = 'SELECT @OThours=WorkingHours FROM [STS_DailyWorkingHours] WHERE HoursOfDay=''Fullday'' AND CID=@CID'
		EXECUTE sp_executesql @SQLSTRING,
		                               N'@OThours TIME(5) OUTPUT,@CID int',
									     @OThours = @OThours OUTPUT,@CID =@CID;

create table #Temptable (TPID bigint,LedgerID bigint,CheckedIn datetime,CheckedType nvarchar(1) COLLATE DATABASE_DEFAULT);
                   

DECLARE @rCount varchar(5);
								SELECT     @SQLSTRING = 'SELECT @rCount=count(LedgerID) from [STS_EmpTimePunch] WHERE LedgerID IS NOT NULL ';

								IF(@DType='ByDate')
									BEGIN
										SET @SQLSTRING = @SQLSTRING+ ' AND CONVERT(DATE,Date,105) BETWEEN  CONVERT(DATE,'''+@FromDate+''', 105)
																	   AND CONVERT(datetime,'''+@ToDate+''', 105)';				
									END
								ELSE IF(@DType='ByMonth')
									BEGIN
										SET @SQLSTRING = @SQLSTRING +' AND DATEPART(MONTH,Date) ='+ @ByMonth +'
																	   AND DATEPART(YEAR,Date) ='+ @ByMonthYear +'';								  	
									END
								ELSE IF(@DType='ByYear')
									BEGIN
										SET @SQLSTRING = @SQLSTRING +' AND DATEPART(YEAR,Date) ='+@ByYear+'';				
									END
								ELSE IF(@DType='CurrentDate')
									BEGIN			
										SET @SQLSTRING = @SQLSTRING +' AND  CONVERT(VARCHAR(10),Date,105)='''+@Date+'''';			  
									END
							    ELSE	IF(@DType='CurrentMonth')
									BEGIN
										SET @SQLSTRING = @SQLSTRING +' AND  DATEPART(Month,Date)='+ @CMonth +' AND DATEPART(YEAR,Date) = YEAR(CURRENT_TIMESTAMP)';				
									END		

								 IF(@LedgerID!='0')
									   BEGIN
										   SET @SQLSTRING=@SQLSTRING+' AND LedgerID='+@LedgerID ;
									   END

							EXECUTE sp_executesql @SQLSTRING,
									N'@rCount varchar(5) Output',
									@rCount=@rCount output; 

									--SELECT @SQLSTRING,@rCount;

  IF(@Flag='PAGELOAD')
  BEGIN
           SELECT SiteID as CID,CompanyName as Name from SiteMaster where CID=@CID;

		    SELECT Category1,SlNo from EmpCategory where CID=@CID;


			SELECT  0 AS LedgerID,'ALL' AS Name  

			UNION ALL
			SELECT      LedgerID,
							EmpID+' - '+AliasName1 AS Name  
				FROM		[EmployeeMaster]
				WHERE	    InActive=0 AND CID=@CID
		
  END

    if(@rCount!='0')
		BEGIN
			DECLARE @NoColumns int;DECLARE @PivotString varchar(MAX)='';DECLARE @PivotColumnTable varchar(MAX)='';
			DECLARE @cnt INT = 0;

			CREATE TABLE #tempTable2 (RowNo int,TPID int,CheckedIN datetime,CheckedType varchar(5))  

			SET @SQLSTRING1    = ';with cte1 as (
			SELECT Etps.TPID,checkedtype,CheckedIn,ROW_NUMBER() Over( partition by etps.TPID order by checkedin) RowNo FROM [STS_EmpTimePunchSub] ETPS
			INNER JOIN [STS_EmpTimePunch ] ETP on etp.TPID=ETPS.TPID and ETP.CID=ETPS.CID WHERE ETP.LedgerID IS NOT NULL '

								IF(@DType='ByDate')
									BEGIN
										SET @SQLSTRING1 = @SQLSTRING1+ ' AND CONVERT(DATE,ETP.Date,105) BETWEEN  CONVERT(DATE,'''+@FromDate+''', 105)
																	   AND CONVERT(datetime,'''+@ToDate+''', 105)';				
									END
								ELSE IF(@DType='ByMonth')
									BEGIN
										SET @SQLSTRING1 = @SQLSTRING1 +' AND DATEPART(MONTH,ETP.Date) ='+ @ByMonth +'
																	   AND DATEPART(YEAR,ETP.Date) ='+ @ByMonthYear +'';								  	
									END
								ELSE IF(@DType='ByYear')
									BEGIN
										SET @SQLSTRING1 = @SQLSTRING1 +' AND DATEPART(YEAR,ETP.Date) ='+@ByYear+'';				
									END
								ELSE IF(@DType='CurrentDate')
									BEGIN			
										SET @SQLSTRING1 = @SQLSTRING1 +' AND  CONVERT(VARCHAR(10),ETP.Date,105)='''+@Date+'''';			  
									END
							    ELSE	IF(@DType='CurrentMonth')
									BEGIN
										SET @SQLSTRING1 = @SQLSTRING1 +' AND  DATEPART(Month,ETP.Date)='+ @CMonth +' AND DATEPART(YEAR,ETP.Date) = YEAR(CURRENT_TIMESTAMP)';				
									END		
								
            SET @SQLSTRING1=@SQLSTRING1+' )
			, cte2 as (
				SELECT *,
				row_number() Over( partition by tpid order by RowNo) -
				row_number() Over( partition by tpid,CheckedType order by RowNo) t1
				FROM cte1 
			 ),
			 cte3 as(
				seLECT *,
				row_number() Over( partition by tpid,CheckedType,t1 order by RowNo) val  from cte2
			 ) 
			 ,cte4 as (
				SELECT ROW_NUMBER() Over(partition by TPID order by RowNo) as RowNo, TPID, CheckedIn,case when CheckedType=1 then ''In'' else ''Out'' END CheckedType FROM cte3  where val=1 
			 )  
			 ,cteTotal as (
				SELECT 
				TPID,
				CONVERT(TIME,DATEADD(SECOND,SUM(DATEDIFF(SECOND,0,convert(time,CheckedIN))*
				(CASE WHEN Checkedtype=''In'' THEN -1 ELSE 1 END)) ,0)) TotalTime
				FROM cte4 GROUP BY TPID
			 )		
			 Insert into #tempTable2  SELECT RowNo,TPID,CheckedIn,(CheckedType+CONVERT(varchar(5),CEILING(convert(float,RowNo)/2))) as CheckedType FROM cte4 '


			 --SELECT @SQLSTRING1;

			 EXECUTE sp_executesql @SQLSTRING1,
											N'@Date			VARCHAR(30)',
											  @Date		  = @Date;
			
			 Select @NoColumns=CEILING(max(convert(float,RowNo))/2) from #tempTable2

			 While @NoColumns>@cnt
				BEGIN
					SET @cnt = @cnt + 1
					/* do some work */
					if(@cnt=1)
					BEGIN
					SET @PivotString='[In'+convert(varchar(2),@cnt)+'],[Out'+convert(varchar(2),@cnt)+']'
					SET @PivotColumnTable='[In'+convert(varchar(2),@cnt)+']  VARCHAR(10) COLLATE DATABASE_DEFAULT,[Out'+convert(varchar(2),@cnt)+'] VARCHAR(10) COLLATE DATABASE_DEFAULT'
					END
					else
					BEGIN
					SET @PivotString=@PivotString+',[In'+convert(varchar(2),@cnt)+'],[Out'+convert(varchar(2),@cnt)+']'
					SET @PivotColumnTable=@PivotColumnTable+',[In'+convert(varchar(2),@cnt)+'] VARCHAR(10) COLLATE DATABASE_DEFAULT,[Out'+convert(varchar(2),@cnt)+'] VARCHAR(10) COLLATE DATABASE_DEFAULT'
					END
				END

				CREATE TABLE #PivotData (TPID INT);
				--DECLARE @SQLSTRING nvarchar(max)
				SET @SQLSTRING = 'ALTER TABLE #PivotData ADD ';
				SET @SQLSTRING += @PivotColumnTable;
				EXEC sys.sp_executesql @SQLSTRING;

				DECLARE  @query nvarchar(MAX) ;
				set @query = 'SELECT TPID,'+ @PivotString	+'
				FROM (select TPID,Convert(varchar(5),CheckedIn,108) as Checkedin,CheckedType from 
				 #tempTable2) as SourceTable
				PIVOT
				(
				--sum(checkedin) 
				max(checkedin)
				 FOR checkedtype IN (' + @PivotString + ')
						) as p '
				INSERT INTO #PivotData
					--	SELECT @PivotColumnTable
			    execute(@query) 


		
			set @SQLSTRING='; with cteTTime as (
			SELECT  TPID,
			 CONVERT(TIME,DATEADD(SECOND,SUM(DATEDIFF(SECOND,0,convert(time,CheckedIN))*
			(CASE WHEN SUBSTRING(CheckedType,1,LEN(CheckedType)-1)=''In'' THEN -1 ELSE 1 END)) ,0)) TotalTime FROM #tempTable2 group by TPID
			) SELECT EM.LEDGERID,EM.Category,EM.EMPID,EM.AliasName1 as EmpName,ETP.date as Date,TotalTime as Hours,
			CASE WHEN	TotalTime < @OThours THEN ''00:00:00'' ELSE CONVERT(TIME,DATEADD(MS,DATEDIFF(ss,@OThours,TotalTime)*1000,0),114) END as OTHours,
			--CONVERT(TIME,DATEADD(MS,DATEDIFF(ss,@OThours,TotalTime)*1000,0),114) as OTHours,
			'+@PivotString+' FROM #PivotData p
			INNER JOIN cteTTime c ON c.TPID=p.TPID 
			INNER JOIN [STS_EmpTimePunch] ETP on ETP.TPID=P.TPID  
			INNER JOIN [EmployeeMaster] EM on EM.LedgerID=etp.LedgerID AND EM.CID=ETP.CID
			'
			IF(@LedgerID!='0')			
				SET @SQLSTRING=@SQLSTRING+' WHERE Em.LedgerID='+@LedgerID+'  order by ETP.Date';
			ELSE 
				SET @SQLSTRING=@SQLSTRING+' WHERE Em.LedgerID IS NOT NULL  order by ETP.Date';

			EXECUTE sp_executesql @SQLSTRING,
						N' @PivotString varchar(MAX),
						@OThours TIME',
						@OThours=@OThours,
						@PivotString=@PivotString;


			DROP TABLE #PivotData
			Drop Table #tempTable2
		END
		
		drop table #Temptable
END

GO
IF (OBJECT_ID('STS_GetTimePunch') IS NOT NULL)
  DROP PROCEDURE STS_GetTimePunch
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[STS_GetTimePunch]		
   @CID				INT,
   @Flag			VARCHAR(30),
   @LedgerID		VARCHAR(30),  --ledgerid
   @CDate			VARCHAR(15)   --date


AS
BEGIN	
	DECLARE @sqlstring				NVARCHAR(MAX);    
	DECLARE @TPID Varchar(20) ;
	 
			SELECT  @TPID=TPID FROM [STS_EmpTimePunch] WHERE  CONVERT(date,[date],105)= Convert (date,@CDate,105) and LedgerID=@LedgerID and CID=@CID;	
		 	
	
		BEGIN			
				SELECT	TPS.SlNo,TPS.TPID,CONVERT(VARCHAR(10),TPS.CheckedIn,105) AS Date,CONVERT(VARCHAR(5),TPS.CheckedIn,114) AS Time, TPS.CheckedType AS Status 
				FROM [STS_EmpTimePunch]  TP 
											INNER JOIN			[STS_EmpTimePunchSub] TPS ON Tp.TPID=TPS.TPID AND Tp.CID=TPS.CID
											INNER JOIN			[EmployeeMaster]  EM ON TP.LedgerID =EM.LedgerID AND TP.CID = EM.CID
											WHERE				TPS.CID=101 AND TPS.CheckedIn IS NOT NULL AND TPS.TPID=@TPID										  							
		END
		
	
END

GO

IF (OBJECT_ID('SetProjectEffortApproval') IS NOT NULL)
  DROP PROCEDURE SetProjectEffortApproval
GO

CREATE TYPE [dbo].[TVP_STS_ProjectEffortApproval] AS TABLE(
	[SlNo] [int] NOT NULL,
	[LedgerID] [int] NOT NULL,
	[EffortDate] [date] NOT NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[EffortHours] [time](7) NULL,
	[OT] [time](7) NULL,
	[Descriptions] [varchar](max) NULL,
	[ChkStatus] [int] NOT NULL,
	[AuthStatus] [varchar](1) NOT NULL,
	[LastApprovedBy] [int] NULL
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SetProjectEffortApproval]
	@CID					VARCHAR(50),
	@Flag					VARCHAR(30),	
	--@SlNo					VARCHAR(30),
	--@TicketNo				VARCHAR(30),
	--@StartTime			VARCHAR(5),
	--@EndTime				VARCHAR(5),
	--@EffortHour			VARCHAR(5),
	--@OT					VARCHAR(5),
	@Comment                VARCHAR(MAX),
	@ProjectID				VARCHAR(10),	
	@UserID					VARCHAR(30),	
	@ERRORNO				INT   OUT,
	@ERRORDESC				VARCHAR(MAX) OUT,		
	@Dt1 TVP_STS_ProjectEffortApproval READONLY

	--WITH ENCRYPTION
AS
BEGIN		
	DECLARE	@CurrentTime	DATETIME;
	DECLARE @RtnGroupID     INT;
	DECLARE @RtnGroupLevel  INT;
	DECLARE	@DESC			VARCHAR(MAX);
		
	SET		@CurrentTime	= CURRENT_TIMESTAMP;
			
 BEGIN TRY
	BEGIN TRANSACTION
	IF(@Flag='APPROVED')
		BEGIN
								  		 
	          	SELECT @RtnGroupID=AGS.ApprovalGroupID 
			    FROM   [STS_ApprovalGroupSub] AGS INNER JOIN [STS_ApprovalGroup] AG on AG.ApprovalGroupID=AGS.ApprovalGroupID AND AG.CID=AGS.CID
				WHERE  AGS.parentid=@UserID AND AGS.CID=@CID  AND AG.TypeID=@ProjectID

		         INSERT INTO    [STS_ETSEffortSub] 
								(EffortID,
								ApproveGroupID,
								Comment,
								EntryDate,
								CreatedBy,
								UpdatedBy,
								CID)
				SELECT          SlNo,
								@RtnGroupID,
								@Comment,
								GETDATE(),
								@UserID,
								@UserID,
								@CID	 
				FROM            @Dt1 where ChkStatus=1

		  --      SELECT @RtnGroupLevel=ApproveLevel 
		  --      FROM   [STS_ApprovalGroupSub] 
				--WHERE  parentid=@UserID AND CID=@CID 
 
                 SELECT @RtnGroupLevel=ApproveLevel
		        FROM   [STS_ApprovalGroupSub] AGS INNER JOIN [STS_ApprovalGroup] AG on AG.ApprovalGroupID=AGS.ApprovalGroupID AND AG.CID=AGS.CID
				WHERE  AGS.parentid=@UserID AND AGS.CID=@CID  AND AG.TypeID=@ProjectID;

	
		        UPDATE		ETS
							SET 			
							ETS.Approved=(CASE WHEN dt.ChkStatus='1' THEN @RtnGroupLevel ELSE 0 END),
							ETS.StartTime=dt.StartTime,
							ETS.EndTime=dt.EndTime,
							ETS.Duration=dt.EffortHours,						
							ETS.AuthStatus= (CASE WHEN dt.ChkStatus='1' AND @RtnGroupLevel=1 AND dt.AuthStatus='A' then 'A' 
										 WHEN dt.ChkStatus='0' and @RtnGroupLevel=1 and dt.AuthStatus='P' then 'P'
										 ELSE (CASE WHEN dt.ChkStatus='1' AND @RtnGroupLevel<>1 THEN 'P' ELSE 'O' END)  END),						
							ETS.LastApprovedBy=(CASE WHEN dt.ChkStatus='1' THEN  @UserID ELSE 0 END),
							ETS.ApproverLedgerID=@UserID
			    FROM       [STS_ETSEffort] ETS
			    INNER JOIN @Dt1 dt on dt.SlNo=ETS.SlNo 
				WHERE      ETS.CID=@CID;           
				
				DELETE FROM STS_EmployeeOT WHERE LedgerID IN (SELECT dt.LedgerID FROM @Dt1 dt) AND OTDate IN(SELECT dt.EffortDate FROM @Dt1 dt)
				
				INSERT INTO STS_EmployeeOT (Approve,CID,LedgerID,OT,OTDate) SELECT 1,@CID,dt.LedgerID,dt.OT,dt.EffortDate FROM @Dt1 dt;
					  
			SET @ERRORNO=0;
			SET @ERRORDESC='Record has been approved';
		END
	
	COMMIT TRANSACTION
	  IF(@ERRORNO=1)
		BEGIN
			SET @DESC=@ERRORDESC + ' : ' + @Flag 			
            --EXEC STS_SetElog @CID,@UserID,@CurrentTime,@GroupID,'sp_setEffortAuthorize',@ReturnValue,@DESC,@ErrorMessage,5,3,4,'';			 
		END
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
				SET @ERRORNO = ERROR_NUMBER()
				SET @DESC='ERROR IN  Details' +' : '+ @Flag
				SET @ERRORNO=0;
				SET @ERRORDESC='Error Message:'+ERROR_MESSAGE();			
              --  EXEC STS_SetElog @CID,@UserID,@CurrentTime,@GroupID,'sp_setEffortAuthorize',@ReturnValue,@DESC,@ErrorMessage,5,3,4,'';				
	END CATCH
END

IF (OBJECT_ID('GetEmployeeForProject') IS NOT NULL)
  DROP PROCEDURE GetEmployeeForProject
GO
/****** Object:  StoredProcedure [dbo].[GetEmployeeForProject]    Script Date: 11/2/2020 10:46:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<KM1007,,Kasim>
-- Create DATE: <01/09/2012>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetEmployeeForProject]
	-- Add the parameters for the stored procedure here
	  @CID					INT,
	  @ProjectUID			INT,
      @Date					DATE,
	  @LedgerID				INT
	        
--UNLOCK-- WITH ENCRYPTION 
 AS 
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets FROM
	-- INTerfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @ApproveGroupID INT;
	SELECT @ApproveGroupID = ApprovalGroupID FROM [STS_ApprovalGroup] WHERE cid=@cid and typeid = @ProjectUID;

	CREATE TABLE #Table (LedgerID INT, Name NVARCHAR(255), LID NVARCHAR(50), LeaveType NVARCHAR(50), Comment NVARCHAR(255));

	SELECT	CONVERT(VARCHAR(100),LID) as LID, LeaveType FROM [STS_LeaveTypeMaster] WHERE CID = @CID AND IsActive = 1;

	--employee who taken leave for this given date for this project and assign it into #Table
	INSERT INTO		#Table
	SELECT			EM.LedgerID, EM.AliasName1 AS Name, LID, LTM.LeaveType, '' AS Comment 
	FROM			[STS_Attendance] AT 
	INNER JOIN		[EmployeeMaster] EM ON AT.CID = EM.CID AND AT.LedgerID = EM.LedgerID 
	INNER JOIN		[STS_LeaveTypeMaster] LTM ON LTM.CID = AT.CID AND LTM.LID = AT.TYPE
	--INNER JOIN		[STS_ResourceAllocation] RA ON RA.CID = AT.CID AND AT.LedgerID = RA.LedgerID AND RA.ProjectID = @ProjectUID
	WHERE			AT.CID = @CID AND AttendanceDate=@Date;

	--Get employees for this given date and this project except who taken leave (get it by #Table)
	WITH Hierarchy(ParentId,ledgerid)
	AS
	(
		SELECT ParentId, ledgerid FROM [STS_ApprovalGroupSub] AS TF WHERE cid= @cid and ApprovalGroupID = @ApproveGroupID and ParentID=@LedgerID -- ParentId IS NULL        
		UNION ALL
		SELECT Parent.ledgerid,TS.ledgerid FROM [STS_ApprovalGroupSub] AS TS INNER JOIN Hierarchy AS Parent ON TS.CID=@CID and TS.ParentId = Parent.ledgerid AND TS.ApprovalGroupID = @ApproveGroupID
	),
	--CTESkipPassedLedger AS
	--(
	--	SELECT * FROM Hierarchy where ledgerid<>@LedgerID --OPTION(MAXRECURSION 32767)
	--),
	CTEEmployee AS
	(
		SELECT			EM.LedgerID, EM.AliasName1 AS Name, EM.EmpID AS ID, '00:00' AS BioMetric, ISNULL(EF.StartTime, @Date) AS StartTime,  ISNULL(EF.EndTime, @Date) AS EndTime, 
						ISNULL(EF.Duration,'00:00:00') AS Effort, 
						ISNULL(OT.OT,'00:00:00') AS OT, ISNULL(EF.Descriptions, '') AS Comment, 101 AS Attendance
		FROM			[sts_resourceAllocation] RA 
		INNER JOIN		[STS_ResourceAllocationSub] RAS ON RA.CID = RAS.CID AND RA.ResourceAllocationID = RAS.ResourceAllocationID
		INNER JOIN		[EmployeeMaster] EM ON EM.CID = RA.CID AND RA.LedgerID = EM.LedgerID
		LEFT JOIN		[STS_ETSEffort] EF ON EF.CID = RA.CID AND RA.LedgerID = EF.LedgerID AND EF.EffortDate = @Date
		LEFT JOIN		[STS_EmployeeOT] OT ON OT.CID = RA.CID AND RA.LedgerID = OT.LedgerID AND OT.OTDate = @Date
		WHERE			RA.CID = @CID AND RA.ProjectUID = @ProjectUID AND RAS.AllotedDate = @Date and EM.LedgerID not in (SELECT LedgerID FROM #Table)  
	)
	SELECT EM.* FROM Hierarchy H INNER JOIN CTEEmployee EM ON H.ledgerid = EM.LedgerID ORDER BY EM.LedgerID  

	
	SELECT * FROM #Table;

	DROP TABLE #Table
END
GO

--Vignesh
DROP TYPE [dbo].[TVPSTS_TimeSheet]
GO

IF (OBJECT_ID('STS_GetTimeSheet_LoadTicket') IS NOT NULL)
  DROP PROCEDURE STS_GetTimeSheet_LoadTicket
GO

IF (OBJECT_ID('STS_GetTimeSheet_EffortDetails') IS NOT NULL)
  DROP PROCEDURE STS_GetTimeSheet_EffortDetails
GO

IF (OBJECT_ID('STS_GetDynDGV') IS NOT NULL)
  DROP PROCEDURE STS_GetDynDGV
GO

IF (OBJECT_ID('STS_SetTimeSheetEffort') IS NOT NULL)
  DROP PROCEDURE STS_SetTimeSheetEffort
GO

IF (OBJECT_ID('STS_GetTimeSheet_Report') IS NOT NULL)
  DROP PROCEDURE STS_GetTimeSheet_Report
GO

IF (OBJECT_ID('STS_SetTimeSheet_CloseTask') IS NOT NULL)
  DROP PROCEDURE STS_SetTimeSheet_CloseTask
GO

CREATE TYPE [dbo].[TVP_STS_EditTimeSheet] AS TABLE(
	[EffortDate] [varchar](30) NULL,
	[Ticket] [varchar](20) NULL,
	[Category] [varchar](30) NULL,
	[Product] [varchar](30) NULL,
	[Project] [varchar](30) NULL,
	[Client] [varchar](30) NULL,
	[Hours] [varchar](10) NULL,
	[Description] [varchar](500) NULL
)
GO

CREATE TYPE [dbo].[TVP_STS_TimeSheet] AS TABLE(
	[CategoryID] [varchar](30) NULL,
	[Ticket] [varchar](20) NULL,
	[ProductID] [varchar](30) NULL,
	[ProjectID] [varchar](30) NULL,
	[ClientID] [varchar](30) NULL,
	[Hours] [varchar](10) NULL,
	[Description] [varchar](500) NULL
)
GO

IF (OBJECT_ID('GetTimesheet') IS NOT NULL)
  DROP PROCEDURE GetTimesheet
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetTimesheet] 	
		@CID		INT,
		@Flag		VARCHAR(50),
		@LedgerID	VARCHAR(50),
		@Date		VARCHAR(50),
		@FromDate   VARCHAR(50),
		@ToDate     VARCHAR(50)
AS
BEGIN	


   SELECT @LedgerID=LedgerID from [Employeemaster] where EmpID=@LedgerID AND CID=@CID; 
     

	IF(@Flag='LOADDDL')
	   BEGIN
	       --get company name
			 SELECT SiteID,CompanyName AS SiteName FROM SiteMaster WHERE SiteID=@CID AND CID=@CID

		   --get category name
		    SELECT CategoryName as Category,CategoryID FROM  [STS_Category] WHERE  CID=@CID ORDER BY CategoryName,CategoryID;
			
		   --get product name
			SELECT ProductName AS Product,ProductID FROM [STS_Product] WHERE Status=0 AND CID=@CID ORDER BY ProductName;

		   --get project name
		    SELECT ProjectID AS Project,ProjectUID AS ProjectID FROM [ProjectMaster] WHERE ProjectStatus=0 AND CID=@CID ORDER BY Project;

		  --get client name
			 SELECT LedgerID AS ClientID,MerchantName AS Client FROM  [MerchantMaster] WHERE VenActiveStatus=0 AND type='Customer' AND CID=@CID ORDER BY Client,ClientID;

		  --my task
		    SELECT       i.TaskNo AS Ticket,
                         i.Subject,
                         p.ProductName AS Product,
                         c.MerchantName AS Client,
                         s.Tag AS 'Status',
                         (SELECT  r.AliasName1 AS AliasName  FROM  [EmployeeMaster] r WHERE r.LedgerID=i.CreatedBy AND r.CID=i.CID) AS CreatedBy,
	                     (SELECT en.Tag FROM [STS_Entity] en WHERE en.EntityID=i.PriorityID AND en.CID=i.CID) AS Priority, 
	                     CONVERT(VARCHAR(10),i.CreatedDate,105) AS ReportDate,
	                     pr.ProjectID AS ProjectID
			FROM         [STS_ITSTicket] i
			LEFT JOIN    [STS_Product] p 
			ON           p.ProductID=i.ProductID AND p.CID=i.CID
			LEFT JOIN    [STS_Status] s  
			ON           s.StatusID=i.StatusID AND s.CID=i.CID
			LEFT JOIN    [MerchantMaster] c  
			ON           c.LedgerID=i.ClientID AND c.CID=i.CID
			LEFT JOIN    [EmployeeMaster] e 
			ON           e.LedgerID=i.RequestOn AND e.CID=i.CID
			LEFT JOIN    [ProjectMaster] pr 
			ON           pr.ProjectUID=i.ProjectUID AND pr.CID=i.CID
			WHERE        e.LedgerID=@LedgerID  
			AND          i.StatusID NOT IN (1) 
			AND			 i.CID=@CID
			ORDER BY     i.TaskNo DESC;	 
					
		  --common task
		    SELECT DISTINCT	   i.TaskNo AS Ticket,
							   i.Subject,
							   p.ProductName AS Product,
							   c.MerchantName AS Client,
							   s.Tag AS 'Status',
		                       (SELECT  (r.AliasName1) AS AliasName FROM  [EmployeeMaster] r WHERE r.LedgerID=i.CreatedBy AND r.CID=i.CID) as CreatedBy,
		                       (SELECT en.Tag FROM [STS_Entity] en WHERE i.PriorityID=en.EntityID AND i.CID=en.CID) as Priority,
		                       CONVERT(VARCHAR(10),i.CreatedDate,105) AS ReportDate, 
		                       pr.ProjectID AS ProjectID
		    FROM               [STS_ITSTicket] i
		    LEFT JOIN          [STS_Product] p 
		    ON                 p.ProductID=i.ProductID AND p.CID=i.CID
		    LEFT JOIN          [STS_Status] s 
		    ON                 s.StatusID=i.StatusID AND s.CID=i.CID
		    LEFT JOIN          [MerchantMaster] c 
		    ON                 c.LedgerID=i.ClientID AND c.CID=i.CID
		    LEFT JOIN          [STS_ITSCommonIssueConfig] ci 
		    ON                 ci.CategoryID=i.ClientID and ci.CID=i.CID
		    OR                 ci.CategoryID=i.ProductID and ci.CID=i.CID
		    OR                 ci.CategoryID=i.ProjectUID and ci.CID=i.CID
		    LEFT JOIN          [ProjectMaster] pr 
		    ON                 pr.ProjectUID=i.ProjectUID and pr.CID=i.CID
		    WHERE              i.RequestOn='1' 
		    AND                ci.LedgerID=@LedgerID 
		    AND                i.StatusID NOT IN (1) 
		    AND				   i.CID=@CID
		    ORDER BY           i.TaskNo DESC;	 

			Create table #Temp (Category varchar(100),Ticket varchar(100),Product varchar(100),Project varchar(100),Client varchar(100),Hours varchar(100),Description varchar(100)) 
			Select  Category, Ticket,Product,Project,Client,Hours,Description from #Temp;
			Drop table  #Temp

			--get employeename
				SELECT      LedgerID,
							EmpID+' - '+AliasName1 AS Name  
				FROM		[EmployeeMaster]
				WHERE	    InActive=0 AND CID=@CID
				ORDER BY	AliasName1

			--select Name1 as Name,case Visibility when 0 then 'false' else 'true' end as Visibility from [FormGridSettings] where MenuID='STS_24' and CID=@CID;
			select Name1 as Name, Visibility  from [FormGridSettings] where MenuID='STS_24' and CID=@CID;
	   END
  ELSE IF(@Flag='EDITEFFORT')
	   BEGIN	

	      --get category name
		    SELECT CategoryName as Category,CategoryID FROM  [STS_Category] WHERE  CID=@CID ORDER BY CategoryName,CategoryID;
			
		   --get product name
			SELECT ProductName AS Product,ProductID FROM [STS_Product] WHERE Status=0 AND CID=@CID ORDER BY ProductName;

		   --get project name
		    SELECT ProjectID AS Project,ProjectUID AS ProjectID FROM [ProjectMaster] WHERE ProjectStatus=0 AND CID=@CID ORDER BY Project;

		  --get client name
			 SELECT LedgerID AS ClientID,MerchantName AS Client FROM  [MerchantMaster] WHERE VenActiveStatus=0 AND type='Customer' AND CID=@CID ORDER BY Client,ClientID;
			 
			 		
			SELECT         
							--  e.SlNo, 
							 CONVERT(VARCHAR(10),e.EffortDate,105) AS EffortDate,	
							 I.TaskNo AS Ticket,
							 ct.CategoryID as Category,							 	
							  p.ProductID As Product,
							 pr.ProjectUID as Project,
							 c.LedgerID AS Client,						 						 													  
							 CONVERT(varchar(5),e.Duration,108) AS Hours,
							 e.Descriptions AS Description																				
				FROM         [STS_ETSEffort] e							
				LEFT JOIN    [STS_Product] p ON	 p.ProductID=e.ProductID AND p.CID=e.CID
				LEFT JOIN    [MerchantMaster] c ON c.LedgerID=e.ClientID AND c.CID=e.CID
				LEFT JOIN    [ProjectMaster] pr ON pr.ProjectUID=e.ProjectUID AND pr.CID=e.CID
				LEFT JOIN    [STS_Category] ct ON  ct.CategoryID=e.CategoryID AND ct.CID=e.CID
				LEFT JOIN	 [STS_ITSTicket] I ON  I.TicketNo = e.TicketNo	AND I.CID=e.CID
				WHERE        e.LedgerID=@LedgerID 
				AND			 e.EffortDate 
				BETWEEN		 CONVERT(date,@FromDate,105) 
				AND			 CONVERT(date,@ToDate,105) 
				AND		     e.CID=@CID
				AND			 e.Approved=0
				ORDER BY	 e.EffortDate DESC	   

	   END
END
GO

IF (OBJECT_ID('SetTimeSheetEffort') IS NOT NULL)
  DROP PROCEDURE SetTimeSheetEffort
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SetTimeSheetEffort] 
	    @Flag           VARCHAR(50),
		@CID			INT,
		@LedgerID		VARCHAR(50),
		@Date			VARCHAR(20),
		@FromDate		VARCHAR(20),
		@ToDate			VARCHAR(20),
		@dtEffort       [TVP_STS_TimeSheet] READONLY,
		@dtEditEffort	[TVP_STS_EditTimeSheet] READONLY,
		@ERRORNO		INT OUTPUT,
		@ERRORDESC		VARCHAR(MAX) OUTPUT
AS
BEGIN	
	DECLARE @CurrentTime DATETIME
	SET     @CurrentTime = CURRENT_TIMESTAMP
	DECLARE @DESC VARCHAR(MAX)
	
	 SELECT @LedgerID=LedgerID from [Employeemaster] where EmpID=@LedgerID AND CID=@CID; 

	BEGIN TRY
	BEGIN TRANSACTION @ERRORDESC
		  IF(@Flag='SETEFFORT')
			BEGIN
				 INSERT INTO [STS_ETSEffort](LedgerID,EffortDate,CategoryID,ProductID,ProjectUID,ClientID,TicketNo,EntryDate,Duration,Descriptions,CID)
				 SELECT @LedgerID,CONVERT(DATE,@Date,105),CategoryID,ProductID,ProjectID,ClientID,Ticket,CONVERT(DATETIME,GETDATE(),105),CONVERT(TIME,REPLACE(Hours,'.',':')+':00',108),Description,@CID  FROM @dtEffort
	
				 SET @ERRORNO='1';
				 SET @ERRORDESC='Record inserted successfully';
			END
		 ELSE IF(@Flag='SETEDITEFFORT')
		   BEGIN
		        DECLARE  @COUNT INT;
				SELECT @COUNT=Count(*) FROM @dtEditEffort;
             
			   IF(@COUNT > 0)
			    BEGIN
					DELETE FROM [STS_ETSEffort] WHERE  EffortDate BETWEEN CONVERT(date,@FromDate,105) AND CONVERT(date,@ToDate,105) AND CID=@CID AND Approved=0 and LedgerID=@LedgerID;
       
					INSERT INTO [STS_ETSEffort](LedgerID,EffortDate,CategoryID,ProductID,ProjectUID,ClientID,TicketNo,EntryDate,Duration,Descriptions,CID)
					SELECT @LedgerID,CONVERT(DATE,EffortDate,105),Category,Product,Project,Client,Ticket,CONVERT(DATETIME,GETDATE(),105),CONVERT(TIME,REPLACE(Hours,'.',':')+':00',108),Description,@CID  FROM @dtEditEffort
				   
				    SET @ERRORNO='1';
				    SET @ERRORDESC='Record updated successfully';
				END
			  ELSE
			   BEGIN
			        SET @ERRORNO='1';
				    SET @ERRORDESC='Record not found.please refresh page.';
			   END 
		   END
	 COMMIT TRANSACTION                  
                 IF(@ERRORNO=1)                      
                    SET @DESC=@ERRORDESC + ' : ' + @Flag 
                 ELSE
                    SET @DESC=@ERRORDESC +' : ' + @Flag                          
            END TRY
            BEGIN CATCH
      ROLLBACK TRANSACTION
                  set @ERRORNO = ERROR_NUMBER()
                  SET @DESC='ERROR IN  Details' +' : '+ @Flag
                  set @ERRORDESC = ERROR_MESSAGE()            
      END CATCH	
END

GO
IF (OBJECT_ID('GetLeaveRequestReport') IS NOT NULL)
  DROP PROCEDURE GetLeaveRequestReport
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name> 
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetLeaveRequestReport]
     @CID			VARCHAR(30),
     @Flag			VARCHAR(30),
	 @EmployeeID    VARCHAR(30),
	 @Department    VARCHAR(30),
	 @LeaveType     [TVP_STS_EmpLeaveRpt] READONLY,
	 @FromDate		VARCHAR(30),
	 @ToDate		VARCHAR(30),
	 @RtnStatus		VARCHAR(5),
	 @UserID        VARCHAR(25)

	-- WITH ENCRYPTION

AS
BEGIN
	DECLARE @SQLSTRING			    NVARCHAR(MAX); 

  IF(@Flag='LOADDDL')
	   BEGIN
	    DECLARE @UserName VARCHAR(50);
		   
			--    SELECT @UserName=UserName FROM [UserMgt] WHERE CID=@CID AND LedgerID=@UserID;

			----get company name
			--  IF(EXISTS(SELECT * FROM  [UserSiteAccess] WHERE CID=@CID ))
			--	 BEGIN
						--SELECT USA.SiteID,CompanyName AS SiteName FROM UserSiteAccess USA
						--INNER JOIN SiteMaster SM ON sm.SiteID=usa.SiteID
						--WHERE usa.CID=@CID AND UserName=@UserName
					 --UNION
						 SELECT SiteID,CompanyName AS SiteName FROM SiteMaster WHERE SiteID=@CID AND CID=@CID					 
				--	END
				--ELSE
				--	BEGIN
				--		SELECT          S.CompanyName AS SiteName,
				--						S.CID AS SiteID  
				--		FROM            [SiteMaster] S
				--		INNER JOIN      [UserMgt] UM 
				--		ON              UM.DefaultSite = s.CID
				--		WHERE           UM.UserName =  @UserName 
					
				--	END

  			--get employeename
				SELECT      LedgerID,
							EmpID+' - '+AliasName1 AS Name  
				FROM		[EmployeeMaster]
				WHERE	    InActive=0 AND CID=@CID
				ORDER BY	AliasName1
				
			 --get department
				SELECT       ComboValueMember AS DepartId,
							 ComboDisplayMember1 AS DepartName 
				FROM         [BaseDropDownList] 
				WHERE		 ComboName='Department' AND CID=@CID
				ORDER BY     DepartId	
				 
			  --get leave type
				SELECT      LID AS LeavetypeID ,
							LeaveType
				FROM        [STS_LeaveTypeMaster] 
				WHERE       IsActive=1 
				AND			CID=@CID AND LeaveType<>'Present';  
	   END
  
  IF(@Flag='LOADGRID')
     BEGIN
	      DECLARE @COUNT INT;
		  SELECT @COUNT=LID FROM @LeaveType;
	      
		    SELECT @EmployeeID=LedgerID from [Employeemaster] where EmpID=@EmployeeID AND CID=@CID; 

	      SET  @SQLSTRING		='SELECT			Em.EmpID,
													Em.AliasName1 AS EmpName,
													CONVERT(VARCHAR(10),LM.FromDate,105) AS FromDate,
												    CONVERT(VARCHAR(10),LM.ToDate,105) AS ToDate,
													DATEDIFF(day, LM.FromDate, LM.ToDate)+1 AS CalendarDay,
													--CASE WHEN (LM.RequestType=116) THEN (DATEDIFF(day, LM.FromDate, LM.ToDate)+lms.DayStatus- dbo.fn_AllEmpWorkingDays('''+@CID+''',LM.FromDate,LM.ToDate,LM.LeaveID,Lm.LeaveCategory)) 
													--ELSE dbo.fn_AllEmpWorkingDays('''+@CID+''',LM.FromDate,LM.ToDate,LM.LeaveID,Lm.LeaveCategory)  END as DaysRequested,
													LTM.LeaveType AS ReqLeaveType,
													LSC.LeaveSname AS Status,
													CONVERT(VARCHAR(10),LM.EntryDate,105) AS ReqDate,
													LM.Comments,
													DATEDIFF(DAY, LM.ToDate, LM.RtnDate) AS ExcessDays,
													CONVERT(VARCHAR(10),LM.RtnDate,105) AS RtnDate
								  FROM				[EmployeeMaster] EM 
								  INNER JOIN		[STS_LeaveMgt] LM ON Em.LedgerID=lM.LedgerID AND Em.CID=lm.CID
								  --INNER JOIN		[STS_LeaveMgtSub] LMS ON LMS.LeaveID=LM.LeaveID AND LMS.CID=LM.CID
								  INNER JOIN		[STS_LeaveTypeMaster] LTm ON LTM.LID=LM.RequestType  AND LTM.CID=LM.CID
								  INNER JOIN		[STS_LeaveStausConfiguration] LSC ON LSC.LeaveSID=LM.StatusID AND LSC.CID=LM.CID
								  WHERE				EM.LedgerID IS NOT NULL AND EM.CID='''+@CID+''''

          IF(@FromDate <>'' AND @ToDate <>'')
		        SET @SQLSTRING     = @SQLSTRING+' AND (CONVERT(DATE,LM.FromDate,105)>=CAST(CONVERT(DATE,'''+ @FromDate +''', 105) AS DATE) AND CONVERT(DATE,LM.FromDate,105)<=CAST( CONVERT(DATE,'''+ @FromDate +''', 105) AS DATE)
												 OR CONVERT(DATE,LM.ToDate,105)>=CONVERT(DATE,'''+ @Fromdate +''',105) AND CONVERT(DATE,LM.FromDate,105)<=CAST( CONVERT(DATE,'''+ @Todate +''', 105) AS DATE))'

           IF(@EmployeeID <>'')
		         SET @SQLSTRING		= @SQLSTRING +' AND Em.LedgerID='''+@EmployeeID+'''';

           IF(@Department <>'')
				 SET @SQLSTRING    = @SQLSTRING +' AND EM.Department='''+@Department+'''';

           IF(@COUNT >0)
		         --SET @SQLSTRING    = @SQLSTRING +' AND LM.RequestType in ('+@LeaveType+')';
				 SET @SQLSTRING    = @SQLSTRING +' AND LM.RequestType in (SELECT LID FROM  @LeaveType)';
        
		  IF(@RtnStatus<>'0' AND @RtnStatus=1)
		        SET @SQLSTRING    = @SQLSTRING +'  AND LM.Rtndate IS  NULL'

          IF(@RtnStatus<>'0' AND @RtnStatus=2)
		        SET @SQLSTRING    = @SQLSTRING +'  AND LM.Rtndate IS NOT NULL'
	      
		  
		    SET @SQLSTRING  = @SQLSTRING +' ORDER BY Lm.EntryDate DESC';

			--select @SQLSTRING
			 EXECUTE sp_executesql @SQLSTRING,
								 N'@LeaveType  [TVP_STS_EmpLeaveRpt] READONLY',
								 @LeaveType  =@LeaveType; 
	 END


END
GO

IF (OBJECT_ID('STS_GetProject') IS NOT NULL)
  DROP PROCEDURE STS_GetProject
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [STS_GetProject] 
	-- Add the parameters for the stored procedure here
	@CID		 VARCHAR(30),
	@Flag        VARCHAR(30),
	@ProjectID   VARCHAR(30),
	@DaysHours   VARCHAR(30)

	--WITH ENCRYPTION

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
       DECLARE @Days     varchar(30);
       DECLARE @RtnPrjID INT;
       DECLARE @Count    INT;
       declare @location  varchar(100);

       
            
	   IF(@Flag='LOADGRID') 
	    BEGIN
			  
	  							  SELECT	  P.ProjectUID as ID,
										      P.ProjectID as Name,
										     (SELECT c.MerchantName FROM [MerchantMaster] c WHERE c.LedgerID=P.MerchantID AND  c.CID=@CID) as Client,description,
										     (SELECT ProductName  FROM [STS_Product] WHERE ProductID=P.DependencyID AND CID=P.CID AND P.CID=@CID)as 'Dependency Name',
											  CASE WHEN P.ProjectStatus = 0 THEN 'Active' ELSE'Locked' END as status,
										      P.StartDate Sdate,
	  									      P.EndDate Edate,
	  									      P.ContactPerson,
	  									      P.ContactDesignation,
	  									      P.ContactEmail,
	  										  P.ContactTelephone,
	  										  P.ContactMobile,
	  										  P.DayHours ,
											  convert(int,P.MerchantID) as MerchantID,
											  Convert(int,P.ProjectStatus)as ProjectStatus
	  		                      FROM        [ProjectMaster] P
	  		                      WHERE       P.CID=@CID;
	  	
	  		  
      
							     select EntityID,Tag from [STS_Entity]  where CID=@CID and  Type='Role'

                                            
                                  
	    END
		else IF(@Flag='PROJECTDETAILS') 
	    BEGIN

			SELECT MerchantName as Name,LedgerID FROM [MerchantMaster] WHERE CID=@CID   

			SELECT LocationID,ProjectLocation FROM [projectlocation] WHERE CID=@CID   

			
					select 
					distinct  @location=
					stuff((
					select ',' + u.LocationID
					from [ProjectMastersub] u
					where u.LocationID = LocationID and ProjectID=@ProjectID AND CID=@CID
					order by u.Location
					for xml path('')
					),1,1,'') 
					from [ProjectMastersub] 
					WHERE        ProjectID=@ProjectID AND CID=@CID
					group by LocationID


				SELECT	  P.ProjectUID as ID,
							P.ProjectID as Name,
							(SELECT c.MerchantName FROM [MerchantMaster] c WHERE c.LedgerID=P.MerchantID AND  c.CID=@CID) as Client,description,
							(SELECT ProductName  FROM [STS_Product] WHERE ProductID=P.DependencyID AND CID=P.CID AND P.CID=@CID)as 'Dependency Name',
							CASE WHEN P.ProjectStatus = 0 THEN 'Active' ELSE'Locked' END as status,
							P.StartDate Sdate,
	  						P.EndDate Edate,
	  						P.ContactPerson,
	  						P.ContactDesignation,
	  						P.ContactEmail,
	  						P.ContactTelephone,
	  						P.ContactMobile,
	  						P.DayHours ,
							convert(int,P.MerchantID) as MerchantID,
							Convert(int,P.ProjectStatus)as ProjectStatus,
							@location as location
	  			FROM        [ProjectMaster] P
	  			WHERE       P.CID=@CID
				and		  ProjectUID=@ProjectID;


				 SELECT	  @Days= isnull(convert(varchar(2),WorkingHours),0)   
	  	                          FROM		  [STS_DailyWorkingHours]  
	  	                          WHERE       HoursOfDay='Fullday'
	  	                          AND		  CID=@CID;

                                  
								  SELECT      e.EntityID,
	  									      s.EstimationHours as 'Hours',
	  									     (s.EstimationHours / @Days) as 'DaysHours' 
	  	                          FROM        [ProjectMaster] P
	  	                          INNER JOIN  [STS_ProjectSub] s ON P.ProjectUID=s.ProjectUID AND p.CID=s.CID
                                  INNER JOIN  [STS_Entity] e ON s.RoleID=e.EntityID AND s.CID=e.CID
                                  WHERE       s.ProjectUID = @ProjectID 
                                  AND         e.Type='Role'
                                  AND		  e.CID=@CID;
	  							  
			  
			                 	                                         
	    END
	   ELSE IF(@Flag='DAYS HOURS')
	     BEGIN	
	        	                       
				 IF(EXISTS (SELECT Count(*) FROM [ProjectMaster] WHERE ProjectUID=@ProjectID AND CID=@CID))
						 BEGIN

							   SELECT   convert(int,@DaysHours) * (DayHours) as 'DaysHours'
							   FROM     [ProjectMaster]  
							   WHERE    ProjectUID=@ProjectID
							   AND	    CID=@CID;
				 
						 END
				ELSE
				        SELECT '0' as 'DaysHours';
         END
       ELSE IF(@Flag='DAYS')	
         BEGIN
	  
			   IF(EXISTS(SELECT Count(*) FROM [ProjectMaster]  WHERE ProjectUID=@ProjectID AND CID=@CID))
						BEGIN
			      
							SELECT   CONVERT(int,@DaysHours) /(DayHours) as 'Days'
						    FROM     [ProjectMaster]  
						    WHERE    ProjectUID=@ProjectID
						    AND		 CID=@CID;
        
						END                     
              ELSE
             
					  SELECT '0' as 'Days';
              
         END
	   
END
GO

IF (OBJECT_ID('STS_SetProject') IS NOT NULL)
  DROP PROCEDURE STS_SetProject
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [STS_SetProject]
	-- Add the parameters for the stored procedure here
	@CID				 VARCHAR(30),
	@Flag                VARCHAR(30),
	@ProjectID           VARCHAR(20),
	@ProjectName         VARCHAR(100),
	@ClientID            VARCHAR(30),
	@Description         VARCHAR(500),
	@Dependancy          VARCHAR(20),
	@DependancyID        VARCHAR(20),
	@ProjectStatus       VARCHAR(15),
	@StartDate          datetime,
	@EndDate             datetime,
	@ContactPerson       VARCHAR(30),
	@ContactDesignation  VARCHAR(30),
	@ContactEmail        VARCHAR(100),
	@ContactTel          VARCHAR(30),
	@ContactMobile       VARCHAR(15),
	@DayHrs              INT,
	@UserID              VARCHAR(5),
	@GroupID             VARCHAR(5), 
	@dtProjectSub        [TVPSTS_ProjectSub] Readonly,
	@dtProjectLocation   [TVPSTS_ProjectSubLocation] ReadOnly,
	@dtProjectSubStatus  VARCHAR(10),
	@ReturnValue         int output,
	@ErrorMessage        VARCHAR(max) output

	--WITH ENCRYPTION

AS
BEGIN

	SET NOCOUNT ON;
    DECLARE @CurrentTime DATETIME
	SET     @CurrentTime = CURRENT_TIMESTAMP
	DECLARE @DESC VARCHAR(MAX)
	DECLARE @PID int
	DECLARE @Count  INT;
	
    -- Insert statements for procedure here
    BEGIN TRY
	BEGIN TRANSACTION @ErrorMessage	
	 IF(@Flag='ADD')
	   BEGIN
				 
				    SELECT  @PID=MAX(ProjectUID) FROM [ProjectMaster] WHERE	CID=@CID;
			
	     IF(@PID IS NULL)
	       SET @PID=6000;
	     ELSE
	       SET @PID=@PID+1;
	        				                       
						IF(NOT EXISTS(SELECT * FROM [ProjectMaster] WHERE ProjectID=@ProjectName AND MerchantID=@ClientID AND CID=@CID)) 
			 BEGIN
				 
		                BEGIN
		                               
									  INSERT INTO     [ProjectMaster]
													  (ProjectID,
													   Description,
													   MerchantID,
													   ProjectStatus,
													   StartDate,
													   EndDate,  
													   Dependency,
													   DependencyID,
													   ContactPerson,
													   ContactDesignation,
													   ContactEmail,
													   ContactTelephone,
													   ContactMobile,
													   DayHours,
													   CID)
									  VALUES          (@ProjectName,
													   @Description,
													   @ClientID,
													   @ProjectStatus,
													   CONVERT(date,@StartDate,105),
													   CONVERT(date,@EndDate,105),
													   @Dependancy,
													   CASE WHEN @DependancyID='Select' THEN NULL ELSE @DependancyID END,
													   @ContactPerson,
													   @ContactDesignation,
													   @ContactEmail,
													   @ContactTel,
													   @ContactMobile,
													   @DayHrs,
													   @CID)
									  
						                        
						 IF(@dtProjectSubStatus='1')
							BEGIN			                        
									  INSERT INTO   [STS_ProjectSub](ProjectUID,RoleID,EstimationHours,CID)
									  SELECT		@PID,
													Role,
													Hours,
													@CID 
								      FROM			@dtProjectSub;
							  END
						                    
									 INSERT INTO     [ProjectMasterSub]
													(ProjectID,LocationID,Location,CID)
												     SELECT @PID,LocationID,ProjectLocation AS LocationName,@CID FROM @dtProjectLocation 
									 WHERE           LocationID<>'' or LocationID IS NOT NULL 
									 AND			 @CID=@CID;
	 				                        
						END					             
			  
	            
	            SET @ReturnValue=1;
                SET @ErrorMessage='Record Inserted Successfully';
	          END
	          ELSE
                 BEGIN
		           SET @ReturnValue=2;                  
		           SET @ErrorMessage='Record Already Exist';
		         END
	   END
	   
	   ELSE IF(@Flag='EDIT')
	     BEGIN
							  UPDATE     [ProjectMaster] 
							  SET        ProjectID=@ProjectName,
										 MerchantID=@ClientID,
										 Description=@Description,
										 Dependency=@Dependancy,
										 DependencyID=0 ,--CASE WHEN @DependancyID='Select' THEN NULL ELSE @DependancyID END,
										 ProjectStatus=@ProjectStatus,
										 --StartDate=CONVERT(date,@StartDate,105),
										 --EndDate=CONVERT(date,@EndDate,105),
										  StartDate=@StartDate,
										 EndDate=@EndDate,
										 ContactPerson=@ContactPerson,
										 ContactDesignation=@ContactDesignation,
										 ContactEmail=@ContactEmail,
										 ContactTelephone=@ContactTel,
										 ContactMobile=@ContactMobile,
										 DayHours =@DayHrs 
							  WHERE      ProjectUID=@ProjectID
							  AND		 CID=@CID;
									
					
			       
				
	           IF(@dtProjectSubStatus='1')
	              BEGIN
	                 --IF(EXISTS(SELECT * FROM ProjectSub WHERE ProjectID=@ProjectID))

					   IF(EXISTS(SELECT	Count(*) FROM [STS_ProjectSub] WHERE ProjectUID=@ProjectID AND CID=@CID))
	                   BEGIN
							DELETE    
							FROM      [STS_ProjectSub] 
							WHERE     ProjectUID=@ProjectID
							AND       CID=@CID;
		               END

							INSERT INTO	   [STS_ProjectSub]
										   (ProjectUID,
										    RoleID,
										    EstimationHours,
										    CID)
							SELECT          @ProjectID,
										    Role,
										    Hours,
										    @CID 
						    FROM            @dtProjectSub;
									     
				
				 END
				
				
					IF(EXISTS(SELECT Count(*) FROM [ProjectMasterSub] WHERE ProjectID=@ProjectID AND CID=@CID))									 
					BEGIN		                         
					     DELETE    
						 FROM      [ProjectMasterSub] 
						 WHERE     ProjectID=@ProjectID
						 AND       CID=@CID;
					END			       
		                 
					                         
					     INSERT INTO   [ProjectMasterSub]
									   (ProjectID,
									    LocationID,
									    Location,
									    CID)
						 select			@ProjectID,
										LocationID,
										ProjectLocation,
										@CID 
						from			[ProjectLocation]  
						where			CID=@CID 
						and				LocationID in( SELECT 
								        LocationID  FROM  @dtProjectLocation);
									     
					     
					      
					       
	          --END
	              
	         SET @ReturnValue=1;
	         SET @ErrorMessage='Record Updated Successfully';
	     END
	   ELSE IF(@Flag='DELETE')  
	     BEGIN
	                    DELETE FROM [ProjectMaster] WHERE ProjectUID=@ProjectID AND CID=@CID;
					    DELETE FROM [STS_ProjectSub] WHERE ProjectUID=@ProjectID AND CID=@CID;
						DELETE FROM [ProjectMasterSub] WHERE ProjectID=@ProjectID AND CID=@CID;
									      
	        SET @ReturnValue=1;
            SET @ErrorMessage='Record Deleted Successfully';
	     END
	      COMMIT TRANSACTION
                  
                 if(@ReturnValue=1)
                      
                         SET @DESC=@ErrorMessage + ' : ' + @Flag 
                 else
                         SET @DESC=@ErrorMessage +' : ' + @Flag   
               
            --EXEC STS_SetElog @CID,@UserID,@CurrentTime,@GroupID,'Project Configuration',@ReturnValue,@DESC,@ErrorMessage,7,0,4,'';
            END TRY
            BEGIN CATCH
      ROLLBACK TRANSACTION
                  set @ReturnValue = ERROR_NUMBER()
                  SET @DESC='ERROR IN  Details' +' : '+ @Flag
                  set @ErrorMessage = ERROR_MESSAGE()
            --EXEC STS_SetElog @CID,@UserID,@CurrentTime,@GroupID,'Project Configuration',@ReturnValue,@DESC,@ErrorMessage,5,3,4,'';
      END CATCH
END
GO

IF (OBJECT_ID('STS_GetLeaveApproval') IS NOT NULL)
  DROP PROCEDURE STS_GetLeaveApproval
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [STS_GetLeaveApproval]
	-- Add the parameters for the stored procedure here
	@CID		 VARCHAR(10),
	@Flag        VARCHAR(25),
	@LedgerID    VARCHAR(30),
	@LeaveID     VARCHAR(20),
	@Year		 VARCHAR(30)

	--WITH ENCRYPTION

AS
BEGIN
		DECLARE @TotApplicableLeave FLOAT,@CurMonth	FLOAT, @TotAvailLeave FLOAT,@TotTakenLeave	FLOAT,@AffortableLeave FLOAT;

	  --IF(@Year='')		
	  --   SET       @Year= YEAR(CURRENT_TIMESTAMP);
        
	   IF(@Flag='LOADLEAVE')
		 BEGIN									  	       				   				   
			SELECT      LTM.LeaveType AS  CategoryName,
									       (
									          SELECT      NoOfDays 
									          FROM        [STS_AnnualLeavePolicy] ALP 
									          INNER JOIN  [STS_EmployeeMasterSub] ER 
									          ON          ER.GradeID=ALP.ALPID AND ER.CID=ALP.CID AND ER.TimeZoneID=ALP.TimeZoneID
									          WHERE       LID 
									          NOT IN      (106,101) 
									          AND         LTM.LID=ALP.LID  AND ER.LedgerID=@LedgerID
									          AND		  ER.CID=@CID
									        ) AS Available,
									        ( 
									          SELECT     ISNULL(SUM(A.FullorHalf),0) 			
											  FROM       [STS_Attendance] A 				   
											  WHERE      A.Type=LTM.LID AND A.CID=LTM.CID
											  AND        A.LedgerID=@LedgerID 
											  AND        YEAR(A.AttendanceDate)=@Year
											  AND		 A.CID=@CID
											) AS Taken
								 FROM       [STS_LeaveTypeMaster] LTM 
								 WHERE      LTM.LID IN (select LID from [STS_LeaveTypeMaster] WHERE IsActive=1 and LID NOT IN(106,116,123) and CID=@CID)  
								 AND		LTM.IsActive=1
								 AND        LTM.LeaveType!=(SELECT CASE WHEN Gender='1' THEN 'Maternity' ELSE '' END 
								 FROM       [EmployeeMaster] 
								 WHERE      LedgerID=@LedgerID
								 AND		CID=@CID)					
							  	 AND		LTM.CID=@CID
								 
								 			      		      
								  SELECT	LTM.LeaveType AS CategoryName,
											(
												SELECT ISNULL(SUM(A.FullorHalf),0) 
												FROM   [STS_Attendance] A 
								                WHERE  A.Type=LTM.LID AND A.CID=LTM.CID AND A.LedgerID=@LedgerID AND YEAR(A.AttendanceDate)=@Year AND A.CID=@CID
								             )  AS LeaveCount  
								   FROM      [STS_LeaveTypeMaster] LTM 
								   WHERE     LTM.LID IN(116) AND LTM.CID=@CID
			             UNION			 
								   SELECT     'ApplicableLeave',
											  ANP.NoOfDays AS AnnualLeave 
								   FROM       [STS_AnnualLeavePolicy] ANP 
								   INNER JOIN [STS_EmployeeMasterSub]  ER 
								   ON         ER.GradeID=ANP.ALPID AND ER.CID=ANP.CID AND ER.TimeZoneID=ANP.TimeZoneID
								   WHERE      ER.LedgerID=@LedgerID 
								   AND        ANP.LID=106
								   AND		  ANP.CID=@CID
			             UNION
				                   SELECT     'CarryForward',
				                              ISNULL(CarryForward,0) AS CarryForward 
				                   FROM       [STS_CurYrCarryForward] 
				                   WHERE      YEAR(EntryDate)=YEAR(GETDATE()) 
				                   AND        LedgerID=@LedgerID
				                   AND		  CID=@CID
				                   
			             UNION
								   SELECT     'TotalLeave',
											  ISNULL((SELECT ISNULL(SUM(A.FullorHalf),0) 
								   FROM       [STS_Attendance] A 
								   WHERE      A.Type=116 
								   AND        A.LedgerID=ER.LedgerID AND A.CID=ER.CID
								   AND        YEAR(A.AttendanceDate)=@Year)+
								              (
												SELECT	G.NoOfDays 
												FROM    [STS_AnnualLeavePolicy] G 
												WHERE   ER.GradeID=G.ALPID AND ER.CID=G.CID AND ER.TimeZoneID=G.TimeZoneID
												AND     G.LID=106 AND G.CID=@CID
											   ) +
								               ( 
								                 SELECT  CCF.CarryForward 
								                 FROM    [STS_CurYrCarryForward] CCF 
								                 WHERE   YEAR(CCF.EntryDate)=YEAR(GETDATE()) 
								                 AND     CCF.LedgerID=ER.LedgerID AND CCF.CID=@CID),0
								                )
								   FROM         [STS_EmployeeMasterSub]  ER 
								   WHERE        ER.LedgerID=@LedgerID AND ER.CID=@CID
			              UNION
				                   SELECT      'TakenLeave',
				                               ISNULL(SUM(FullorHalf),0) 
				                   FROM        [STS_Attendance] 
				                   WHERE       LedgerID=@LedgerID 
				                   AND         YEAR(AttendanceDate)=@Year 
				                   AND         Type IN (106) AND CID=@CID
			              UNION
								   SELECT		'RemainingLeave',
												ISNULL(
												(
													SELECT	  ISNULL(SUM(A.FullorHalf),0) 
													FROM      [STS_Attendance] A 
													WHERE     A.Type=116 
													AND       A.LedgerID=ER.LedgerID AND A.CID=ER.CID
													AND       YEAR(A.AttendanceDate)=@Year AND A.CID=@CID
												 )+
												 (
												    SELECT    G.NoOfDays 
												    FROM      [STS_AnnualLeavePolicy] G 
												    WHERE     ER.GradeID=G.ALPID AND ER.CID=G.CID AND ER.TimeZoneID=G.TimeZoneID AND G.LID=106 AND G.CID=@CID
												  )+
											      (
													SELECT     CCF.CarryForward 
													FROM       [STS_CurYrCarryForward] CCF 
													WHERE      YEAR(CCF.EntryDate)=YEAR(GETDATE()) 
													AND        CCF.LedgerID=ER.LedgerID AND CCF.CID=ER.CID AND CCF.CID=@CID
												  )-
								                  (
								                    SELECT      SUM(A.FullorHalf) 
								                    FROM        [STS_Attendance] A 
								                    WHERE       A.LedgerID=ER.LedgerID AND A.CID=ER.CID
								                    AND         YEAR(A.AttendanceDate)=@Year 
								                    AND         A.Type IN (106) AND A.CID=@CID),0
								                  )
								   FROM           [STS_EmployeeMasterSub]  ER 
								   WHERE          ER.LedgerID=@LedgerID	AND ER.CID=@CID
				
		       SELECT	    l.LeaveID as LeaveID,
						   --l.LedgerID,CONVERT(VARCHAR(10),l.FromDate,105) AS FromDate,
						   --CONVERT(VARCHAR(10),l.ToDate,105) AS ToDate,
						   --CONVERT(VARCHAR(10),l.EntryDate,105) AS RequestDate,
						     l.LedgerID,l.FromDate AS FromDate,
						   l.ToDate AS ToDate,
						  l.EntryDate,105 RequestDate,
						   s.LeaveSname AS 'Status',
						   l.RequestType AS CategoryName,
						   l.Comments,
						   DATEDIFF(DAY, l.FromDate, l.ToDate)+1 AS CalendarDay,
			               dbo.fn_WorkingDays(@CID,l.FromDate,l.ToDate,@LedgerID,l.LeaveID,l.LeaveCategory)  AS DaysRequested ,
						   DATEDIFF(DAY, l.ToDate, l.RtnDate) AS ExcessDays,
						   l.RtnDate AS RtnDate,
						   ls.SessionType ,
						   ls.DayStatus,
						   LTM.LeaveType
			   FROM        [STS_LeaveMgt] l 
			   INNER JOIN  [STS_LeaveMgtSub] ls ON ls.LeaveID=l.LeaveID AND ls.CID=l.CID
			   INNER JOIN  [STS_LeaveTypeMaster] LTM 
			   ON          LTM.LID=l.RequestType AND LTM.CID=l.CID
			   INNER JOIN  [STS_LeaveStausConfiguration] s 
			   ON          s.LeaveSID=l.StatusID AND s.CID=l.CID
			   WHERE       l.LedgerID=@LedgerID 
			   AND         YEAR(l.EntryDate)=@Year 
			   AND		   l.CID=@CID
			   ORDER BY    l.FromDate DESC

			    SELECT		  @TotApplicableLeave=	ANP.NoOfDays/12.0
				FROM		  [STS_AnnualLeavePolicy] ANP 
				INNER JOIN	  [STS_EmployeeMasterSub]  ER 
				ON			  ER.GradeID=ANP.ALPID AND ER.TimeZoneID=ANP.TimeZoneID AND ER.CID=ANP.CID
				WHERE		  ER.LedgerID=@LedgerID 
				AND			  ANP.LID=106
				AND			  ANP.CID=@CID;
            	

				SELECT      @CurMonth=MONTH(Getdate())

				SELECT      @TotAvailLeave= @CurMonth*@TotApplicableLeave
				
				SELECT       @TotTakenLeave= ISNULL(SUM(FullorHalf),0) 
				FROM        [STS_Attendance] 
				WHERE       LedgerID=@LedgerID 
				AND         MOnth(AttendanceDate) between 01 and @CurMonth
				AND         Type IN (106)	
				AND			CID=@CID;
									 	
				SELECT @AffortableLeave=@TotAvailLeave-@TotTakenLeave
				select convert (decimal(18,1),@AffortableLeave)	As Affortable;	
		 END   
	IF(@Flag='PAGELOAD')
	  BEGIN	   
			SELECT SiteID as CID,CompanyName as Name from [SiteMaster] where CID=@CID;

			SELECT      LedgerID,
										EmpID+' - '+AliasName1 AS Name  
							FROM		[EmployeeMaster]
							WHERE	    InActive=0 AND CID=@CID
							ORDER BY	AliasName1
	  END 
  IF (@Flag='LEAVETYPEMASTER')
	   BEGIN	
			 SELECT * FROM [STS_LeaveTypeMaster] WHERE CID=@CID AND IsActive=1 
	   END
    IF(@Flag='LOADEMPNAME')
      BEGIN
			SELECT  LedgerID AS Name FROM [EmployeeMaster] WHERE LedgerID=@LedgerID AND CID=@CID
      END	  
    IF(@Flag='EDITDETAILS')
      BEGIN
			SELECT		TOP 1 m.LeaveID,
						m.LedgerID,
						CONVERT(VARCHAR(10),m.FromDate,105) AS FromDate,
						CONVERT(VARCHAR(10),m.ToDate,105) AS ToDate,
						CONVERT(VARCHAR(10),m.RtnDate,105) AS ReturnDate,
						s.ApporvedType AS RequestType,
						m.Comments,
						s.SessionType,
						(CASE WHEN s.DayStatus=1 THEN 8 ELSE 4 END) AS 'Days',
						m.StatusID
		   FROM         [STS_LeaveMgt] m 
		   INNER JOIN   [STS_LeaveMgtSub] s 
		   ON           m.LeaveID=s.LeaveID AND m.CID=s.CID 
		   WHERE        s.LeaveID=@LeaveID 
		   AND			M.CID=@CID
      END        		
END
GO

IF (OBJECT_ID('GetEmpAttendanceReport') IS NOT NULL)
  DROP PROCEDURE GetEmpAttendanceReport
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:        <Author,,Name>
-- Create date: <Create Date,,>
-- Description:   <Description,,>
-- =============================================
CREATE PROCEDURE [GetEmpAttendanceReport]
      -- Add the parameters for the stored procedure here
      @CID				INT,
      @Flag             VARCHAR(30),
      @LedgerID         VARCHAR(20),
      @Month            NVarchar(30),
      @Year             VARCHAR(20),
      @TimeZone         NVARCHAR(10),
      @Department       NVARCHAR(50),
      @Data             NVARCHAR(MAX),
      @UserID           INT    

	  --WITH ENCRYPTION
AS
BEGIN     
      DECLARE @sqlstring NVARCHAR(max);
      DECLARE @FirstDateOfYear DATETIME
      DECLARE @LastDateOfYear DATETIME
      DECLARE @Date Date = CONVERT(date,'01-'+@Month+'-'+@Year,105);
      DECLARE @Date1 Date = CONVERT(date,'01-01-'+@Year,105);     
      DECLARE @MinMonth INT,@MaxMonth INT,@Cmonth INT;
      DECLARE @Mname VARCHAR(15);
      DECLARE @TOTALMONTH FLOAT ;
      DECLARE @JOINDATE DATE;
      DECLARE @ENDDATE DATE;
      DECLARE @TEMPDATE DATE;
      DECLARE @cols   AS NVARCHAR(MAX),  @query  AS NVARCHAR(MAX)
      DECLARE @Lie FLOAT,@TakenLeave FLOAT,@Leave Float,@SickLeave FLOAT,@OtherPaidLeave FLOAT,@MatrnityLeave FLoat,@EscortLeave Float,@PersonalLeave Float,@NoofMonth FLOAT,@I FLOAT,@ApplicableLeave FLOAT,@TotalLeave FLOAT,@RemainingLeave FLOAT,@UnPaidLeave FLOAT,@CarryForward FLOAT,@AnnualLeave FLOAT;
      DECLARE @TotApplicableLeave FLOAT,@CurMonth	FLOAT, @TotAvailLeave FLOAT,@TotTakenLeave	FLOAT,@AffortableLeave FLOAT;
    
                       
            CREATE table #montnamelist (monname varchar(10))
            INSERT INTO #montnamelist VALUES ('January'),('February'),('March'),('April'),('May'),('June'),('July'),('August'),('September'),('October'),('November'),('December')
            
		If(@Flag ='PAGELOAD')
			BEGIN
				SELECT SiteID as CID,CompanyName as Name from [SiteMaster] where CID=@CID;

				select distinct DATEPART(year,AttendanceDate) years from [STS_Attendance]  where CID=@CID order by DATEPART(year,AttendanceDate) desc

				select LT.LID,LT.LeaveType as name,lc.ColorCode from [STS_LeaveTypeMaster] LT inner join [STS_LeaveTypeColorCode] LC ON  LT.CID=LC.CID AND LT.LID=LC.LID  where LT. CID=@CID
	
				SELECT SlNo,Category1 FROM [EmpCategory]  WHERE CID=@CID

				SELECT TZID,Country FROM [STS_TimeZone]  WHERE CID=@CID

				SELECT      LedgerID,
										EmpID+' - '+AliasName1 AS Name  
							FROM		[EmployeeMaster]
							WHERE	    InActive=0 AND CID=@CID
							ORDER BY	AliasName1
			END
	

    If(@Flag ='ALL')
            BEGIN


                  IF OBJECT_ID('tempdb..#EmpReg') is null
                        CREATE TABLE #EmpReg(LedgerID INT,CID INT)
                        
                  IF(@TimeZone <>'')
                        BEGIN
                              if(@Department<>'0')
                                    BEGIN
                                          INSERT INTO      #EmpReg 
                                                          (
                                                            LedgerID,CID
                                                          ) 
                                               SELECT        E.LedgerID,E.CID 
                                               FROM          [EmployeeMaster] E 
                                               INNER JOIN    [STS_EmployeeMasterSub] ES
                                               ON			 E.LedgerID = ES.LedgerID AND E.CID=ES.CID
                                               WHERE         E.InActive=0 
                                               AND           ES.TimeZoneID=@TimeZone
                                               AND           E.Category=@Department
                                               AND			 E.CID=@CID  order by e.EmpID  asc ;
                                    END
                              Else
                                    BEGIN
                                          INSERT INTO      #EmpReg 
                                                          (
                                                               LedgerID,CID
                                                           ) 
                                             SELECT           E.LedgerID,E.CID 
                                             FROM             [EmployeeMaster] E 
                                             INNER JOIN       [STS_EmployeeMasterSub] ES
                                             ON               E.LedgerID = ES.LedgerID AND E.CID=ES.CID
                                             WHERE            E.InActive=0 
                                             AND              ES.TimeZoneID=@TimeZone
                                             AND			  E.CID=@CID  order by e.EmpID  asc 
                                          
										                                                
                                    END
                        END
                  ELSE
                        BEGIN
								  INSERT INTO    #EmpReg 
												(
													LedgerID
												) 
                                      SELECT    LedgerID 
                                      FROM		[EmployeeMaster]
                                      WHERE		CID=@CID
                        END 
                  
                   IF OBJECT_ID('tempdb..#temp2') is null
                        CREATE TABLE #temp2(LedgerID INT,Type INT,AttendanceDate DATE)
                        
                  IF OBJECT_ID('tempdb..#temp4') is null
                        CREATE TABLE #temp4(Type INT,AttendanceDate DATE,CID INT)
                        
							INSERT INTO #temp2 (Type,AttendanceDate)    
												SELECT
															2 AS Type,
															dt AS Date
												FROM 
															(
																  SELECT            dateadd(d, row_number() over (order by name), cast(@Date1 as datetime)) as dt 
																  FROM        sys.columns a
															) as dates 
												WHERE		datename(dw, dt) in (SELECT WeekEnds FROM [STS_WeekEnds] WHERE TimeZoneID=@TimeZone And CID=@CID)
												AND         dt not in (SELECT HolidayDate FROM [STS_Holidays] WHERE YEAR(HolidayDate)=@Year AND MONTH(HolidayDate)=@Month AND TimeZoneID = @TimeZone And CID=@CID)
												AND         YEAR(dates.dt)=@Year 
												AND         MONTH(dates.dt)=@Month                                                              
                                                  
                                      INSERT INTO #temp4                 
												 SELECT
                                                              5 AS Type,
                                                              dt AS Date,
															  @CID
                                                  FROM 
                                                              (
                                                                    SELECT            dateadd(d, row_number() over (order by name), cast(@Date1 as datetime)) as dt 
                                                                    FROM        sys.columns a
                                                              ) as dates 
                                                  WHERE YEAR(dates.dt)=@Year 
                                                  AND         MONTH(dates.dt)=@Month
                                                  AND         dt NOT IN (SELECT AttendanceDate FROM #temp2) 
                                                  AND         dt NOT IN (SELECT HolidayDate FROM [STS_Holidays] WHERE YEAR(HolidayDate)=@Year AND MONTH(HolidayDate)=@Month AND TimeZoneID = @TimeZone And CID=@CID)
                                                               
                        --------------                
                   

                        IF OBJECT_ID('tempdb..#temp3') is null
                        CREATE TABLE #temp3(LedgerID INT,Type INT,AttendanceDate DATE,CID INT)
                        
                  IF(@Data='')
                              BEGIN
							 
                                    SELECT @Data = SUBSTRING((SELECT ( ',' + CONVERT(varchar,LID) )
															  FROM        [STS_leavetypeMaster] t2
															  WHERE       IsActive = 1
															  AND		  CID=@CID
															  ORDER BY    LID
															  FOR XML PATH( '' )), 3, 1000 )
                              END
                        
                              set @sqlstring = '     
														 SELECT             A.LedgerID,
                                                                            A.Type,
                                                                            A.AttendanceDate,
																			A.CID
                                                            FROM            [STS_Attendance] A
                                                            WHERE           year(A.AttendanceDate) = @Year
                                                            AND             MONTH(A.AttendanceDate) = @Month
                                                            AND             LedgerID IN (SELECT LedgerID FROM #EmpReg )
                                                            AND				A.CID=@CID
                                                            AND             [Type] IN ('+@Data+')
													UNION ALL
                                                            SELECT          ER.LedgerID,
                                                                            (CASE WHEN Description=''week off'' THEN 1 ELSE 0 END) AS Type,
                                                                            HolidayDate,
																			ER.CID
                                                            FROM            #EmpReg ER  
                                                            CROSS JOIN      [STS_Holidays] H 
                                                            WHERE           YEAR(H.HolidayDate)=@Year 
                                                            AND             MONTH(H.HolidayDate)=@Month
                                                            AND             HolidayDate NOT IN (SELECT A.AttendanceDate FROM [STS_Attendance] A WHERE A.LedgerID=ER.LedgerID  AND CID=@CID) 
                                                            AND				H.TimeZoneID = @TimeZone
                                                            AND				H.CID=@CID
													UNION ALL
                                                            SELECT          ER.LedgerID,T2.Type,
                                                                            T2.AttendanceDate,
																			ER.CID 
                                                            FROM            #EmpReg ER 
                                                            CROSS JOIN      #temp2 T2         
                                                            WHERE           T2.AttendanceDate NOT IN (SELECT A.AttendanceDate FROM [STS_Attendance] A WHERE A.LedgerID=ER.LedgerID  AND	CID=@CID) '
                                   
								
								                            
                              INSERT INTO #temp3 (LedgerID,Type,AttendanceDate,CID)

							  
                              Exec sp_executesql @sqlstring,
                                                      N'@Month            NVarchar(30),
                                                        @Year             Varchar(20),
                                                        @TimeZone         Nvarchar(10),
                                                        @Data             Nvarchar(max),
                                                        @CID			  Varchar(20)',
                                                        @month      =     @month,
                                                        @Year       =     @Year,
                                                        @TimeZone   =     @TimeZone,
                                                        @Data       =     @Data,
                                                        @CID		=	  @CID;
                  ---------------                                 
                        INSERT INTO #temp3 
                                 SELECT           ER.LedgerID,
                                                  T.Type,
                                                  T.AttendanceDate,T.Cid 
                                 FROM             #EmpReg ER 
                                 CROSS JOIN       #temp4 T 
                                 WHERE            YEAR(T.AttendanceDate)= @Year 
                                 AND              MONTH(T.AttendanceDate)= @Month AND T.CID=@CID
                             
                        ----------
				  
						------  
                            
                        
                        ;with cte as
                                                (
                                                        SELECT
                                                        LedgerID,
                                                        Type,
                                                        AttendanceDate
                                                        ,LEFT(DATENAME(MONTH,AttendanceDate),3) AS Month_Name
                                                        ,LEFT(DATENAME(WEEKDAY,AttendanceDate),1) AS Week_Name
                                                        ,DATEPART(DW,AttendanceDate) as [WeekNum(1-7)]
                                                        ,DATEDIFF(week, DATEADD(MONTH, DATEDIFF(MONTH, 0, AttendanceDate), 0), AttendanceDate) +1 as RowNumInCalendarMonth
                                                        ,DATEDIFF(week, DATEADD(MONTH, DATEDIFF(MONTH, 0, AttendanceDate), 0), AttendanceDate) * 7 + DATEPART(DW,AttendanceDate) as CellPositionNumInCalendarMonth
                                                        ,CID
                                                        from #temp3
                                                )
                                                SELECT 
                                                        Name,
														[1] as S, [2] as M, [3] as T, [4] as W, [5] as T, [6] as F, [7] as S, [8] as S, [9] as M, [10] as T, [11] as W, [12] as T, [13] as F, [14] as S,[15] as S, [16] as M, [17] as T, [18] as W, [19] as T, [20] as F, [21] as S,[22] as S, [23] as M, [24] as T, [25] as W, [26] as T, [27] as F, [28] as S,[29] as S, [30] as M, [31] as T, [32] as W, [33] as T, [34] as F, [35] as S,[36] as S, [37] as M
                                                        , [38] as T    
                                                       
                                                FROM
                                                (
                                                        SELECT
														 C.LedgerID
														,E.EmpId
														,E.EmpID+' - '+E.AliasName1  As Name
														,ml.monname AS [Month],Type, CellPositionNumInCalendarMonth 
                                                        FROM cte C INNER JOIN [EmployeeMaster] E on E.LedgerID=C.LedgerID AND E.CID=C.CID
                                                        RIGHT JOIN #montnamelist ml ON LEFT(DATENAME(MONTH,AttendanceDate),10) = ml.monname      
                                                ) as s 
                                                pivot
                                                (
                                                        max(type)
                                                        for CellPositionNumInCalendarMonth
                                                        in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23],[24],[25],[26],[27],[28],[29],[30],[31],[32],[33],[34],[35],[36],[37]
                                                        ,[38]
                                                      
                                                        )
                                                )p 

                                                WHERE 
                                            
                                                Month=LEFT(DATENAME(m, str(@Month) + '/1/2011'),10)
                                                order by 
                                                (
                                                        CASE 
                                                                  when [Month] ='January' then 1
                                                                  when [Month] ='February' then 2
                                                                  when [Month] ='March' then 3
                                                                  when [Month] ='April' then 4
                                                                  when [Month] ='May' then 5
                                                                  when [Month] ='June' then 6
                                                                  when [Month] ='July' then 7
                                                                  when [Month] ='August' then 8
                                                                  when [Month] ='September' then 9
                                                                  when [Month] ='October' then 10
                                                                  when [Month] ='November' then 11
                                                                  when [Month] ='December' then 12
                                                        END
                                                )
                              DROP TABLE #temp3
                              DROP TABLE #temp2
                              DROP TABLE #EmpReg



    --    ------------------ SUMMARY DETAILS START ---------------------------------

				  Declare @Condition VARCHAR(max)=''
                  If(@Department <> '0' and @Department <>'')
                        BEGIN
                              SET @Condition ='AND Emp.Category = @Department';
                        END

		   IF (@TimeZone <>'')
                BEGIN

				SELECT		  @TotApplicableLeave=ANP.NoOfDays/12.0
											FROM		  [STS_AnnualLeavePolicy] ANP 
											INNER JOIN	  [STS_EmployeeMasterSub]  ER 
											ON			  ER.GradeID=ANP.ALPID AND ER.TimeZoneID=ANP.TimeZoneID AND ER.CID=ANP.CID
											WHERE		  ANP.LID=106 AND ANP.CID=101;
																		
											SELECT      @CurMonth=MONTH(Getdate());
											
											SELECT      @TotAvailLeave= @CurMonth*@TotApplicableLeave;

                                                SELECT @SQLSTRING =' SELECT @cols = STUFF((SELECT '','' + ISNULL(QUOTENAME(LeaveType),0) 
                                                                     FROM [STS_LeaveTypeMaster]
                                                                     WHERE IsActive=1
                                                                     AND   CID=@CID 
                                                                     GROUP BY LeaveType
                                                                     FOR XML PATH(''''), TYPE
                                                                     ).value(''.'', ''NVARCHAR(MAX)'') 
                                                                     ,1,1,'''')'
                                                EXEC sp_executesql @SQLSTRING,
															   N'@cols     NVARCHAR(MAX) OUTPUT,
															     @CID	   Varchar(20)',
																 @cols   = @cols OUTPUT,
																 @CID	 = @CID;
                                     
                                           DECLARE @RtnAccruedLeave INT;

										   SELECT @RtnAccruedLeave=Tag FROM [STS_CommonConfiguration] WHERE MenuID='STS_15' AND Type='AccruedLeave' AND CID=@CID

										IF(@RtnAccruedLeave =1)
										   BEGIN
										        SELECT @query = N'SELECT            Name,
                                                                                    ISNULL(CarryForward,0) AS CarryForward,
                                                                                    NoofDays,
                                                                                    (ISNULL(CarryForward,0)+NoofDays+LieuDays)TotalLeave,
                                                                                    TakenLeave,
                                                                                    ((ISNULL(CarryForward,0)+NoofDays+LieuDays)-TakenLeave)RemainingLeave,
																					convert(decimal(18,2),@TotAvailLeave)-UptoCurMonth AS ''Accrued Leave'',
                                                                                    ' + @cols + ' 
                                                                 FROM               (     SELECT            Emp.LedgerID,
                                                                                                            Emp.EmpID+'' - ''+Emp.AliasName1 AS Name,
                                                                                                            CarryForward,
                                                                                                            AP.NoofDays,
                                                                                                            sum(A.FullorHalf)FullorHalf,
                                                                                                            t.LeaveType,
                                                                                                            (SELECT ISNULL(SUM(FullorHalf),0) FROM [STS_Attendance]  WHERE LedgerID=Emp.LedgerID AND Year(AttendanceDate)=@Year AND TYPE=116 And CID=@CID) as LieuDays,
                                                                                                            (SELECT ISNULL(SUM(FullorHalf),0) FROM [STS_Attendance]  WHERE LedgerID=Emp.LedgerID AND Year(AttendanceDate)=@Year AND TYPE=106 And CID=@CID) as TakenLeave,
																											(SELECT ISNULL(SUM(FullorHalf),0) FROM [STS_Attendance]  WHERE LedgerID=Emp.LedgerID AND  MOnth(AttendanceDate) between 01 and @CurMonth AND TYPE=106 AND CID=@CID) as UptoCurMonth
                                                                                          FROM        [EmployeeMaster] Emp 
                                                                                          INNER JOIN  [STS_EmployeeMasterSub] ES ON EMP.LedgerID =ES.LedgerID AND EMP.CID=ES.CID
                                                                                          LEFT JOIN   [STS_Attendance] A  ON Emp.LedgerID=A.LedgerID AND Emp.CID=A.CID  AND Year(A.AttendanceDate)=@Year
                                                                                          LEFT JOIN   [STS_LeaveTypeMaster] t ON t.LID= A.Type AND t.CID=A.CID
                                                                                          LEFT JOIN  [STS_AnnualLeavePolicy] AP ON AP.ALPID=ES.GradeID AND AP.CID=ES.CID AND AP.TimeZoneID=ES.TimeZoneID AND AP.LID=106
                                                                                          LEFT join   [STS_CurYrCarryForward] CF ON CF.LedgerID=Emp.LedgerID AND CF.CID=Emp.CID AND  Year(CF.EntryDate)=@Year 
                                                                                          where           Emp.InActive = 0 And	Emp.CID=@CID
                                                                                          AND             ES.TimeZoneID = @TimeZone
                                                                                          '+@Condition+'  
                                                                                          GROUP BY      Emp.EmpID,Emp.LedgerID,A.FullorHalf,CarryForward,AP.NoofDays,t.LeaveType,Emp.AliasName1
                                                                                    ) x
                                                                                    PIVOT 
                                                                                    (
                                                                                          SUM(FullorHalf)
                                                                                          FOR LeaveType IN (' + @cols + ')
                                                                                    ) p '

																					 SELECT 2
                                               
											   END
									ELSE
									   BEGIN
									    SELECT @query = N'SELECT            Name,
                                                                                    ISNULL(CarryForward,0) AS CarryForward,
                                                                                    NoofDays,
                                                                                    (ISNULL(CarryForward,0)+NoofDays+LieuDays)TotalLeave,
                                                                                    TakenLeave,
                                                                                    ((ISNULL(CarryForward,0)+NoofDays+LieuDays)-TakenLeave)RemainingLeave,																					
                                                                                    ' + @cols + ' 
                                                                 FROM               (     SELECT            Emp.LedgerID,
                                                                                                            Emp.EmpID+'' - ''+Emp.AliasName1 AS Name,
                                                                                                            CarryForward,
                                                                                                            AP.NoofDays,
                                                                                                            sum(A.FullorHalf)FullorHalf,
                                                                                                            t.LeaveType,
                                                                                                            (SELECT ISNULL(SUM(FullorHalf),0) FROM [STS_Attendance]  WHERE LedgerID=Emp.LedgerID AND Year(AttendanceDate)=@Year AND TYPE=116 And CID=@CID) as LieuDays,
                                                                                                            (SELECT ISNULL(SUM(FullorHalf),0) FROM [STS_Attendance]  WHERE LedgerID=Emp.LedgerID AND Year(AttendanceDate)=@Year AND TYPE=106 And CID=@CID) as TakenLeave
																											
                                                                                          FROM        [EmployeeMaster] Emp 
                                                                                          INNER JOIN  [STS_EmployeeMasterSub] ES ON EMP.LedgerID =ES.LedgerID AND EMP.CID=ES.CID
                                                                                          LEFT JOIN   [STS_Attendance] A  ON Emp.LedgerID=A.LedgerID AND Emp.CID=A.CID  AND Year(A.AttendanceDate)=@Year
                                                                                          LEFT JOIN   [STS_LeaveTypeMaster] t ON t.LID= A.Type AND t.CID=A.CID
                                                                                          LEFT JOIN  [STS_AnnualLeavePolicy] AP ON AP.ALPID=ES.GradeID AND AP.CID=ES.CID AND AP.TimeZoneID=ES.TimeZoneID AND AP.LID=106
                                                                                          LEFT join   [STS_CurYrCarryForward] CF ON CF.LedgerID=Emp.LedgerID AND CF.CID=Emp.CID AND  Year(CF.EntryDate)=@Year 
                                                                                          where           Emp.InActive = 0 And	Emp.CID=@CID
                                                                                          AND             ES.TimeZoneID = @TimeZone
                                                                                          '+@Condition+'
                                                                                          GROUP BY      Emp.EmpID,Emp.LedgerID,A.FullorHalf,CarryForward,AP.NoofDays,t.LeaveType,Emp.AliasName1
                                                                                    ) x
                                                                                    PIVOT 
                                                                                    (
                                                                                          SUM(FullorHalf)
                                                                                          FOR LeaveType IN (' + @cols + ')
                                                                                    ) p '

									   END

									      EXECUTE sp_executesql @query,
                                                                  N'@Year           Varchar(20),
                                                                    @Month          NVarchar(30),
                                                                    @TimeZone       Nvarchar(10),
                                                                    @Data           Nvarchar(max),
                                                                    @Department     Nvarchar(50),
                                                                    @CID			Varchar(20),
																	@TotAvailLeave  FLOAT,
																	@CurMonth		FLOAT',
                                                                    @Year          = @Year,
                                                                    @Month         = @Month,
                                                                    @TimeZone      = @TimeZone,
                                                                    @Data          = @Data,
                                                                    @Department    = @Department,
                                                                    @CID		   = @CID,
																	@TotAvailLeave	=@TotAvailLeave,
																	@CurMonth		=@CurMonth;     

				END

		-------------------- SUMMARY DETAILS END ---------------------------------

            END
      ELSE IF(@Flag ='By Employee')
            BEGIN
                        IF OBJECT_ID('tempdb..#temp1') is null
                        CREATE TABLE #temp1(Type INT,AttendanceDate DATE)
                        
                  IF(@Data='')
                        BEGIN
                           SELECT  @Data = SUBSTRING((SELECT ( ' , ' + CONVERT(varchar,LID) )
                                                      FROM      [STS_LeaveTypeMaster] t2
                                                      WHERE     IsActive = 1
                                                      AND		CID=@CID
                                                      ORDER BY  LID
                                                      FOR XML PATH( '' )), 3, 1000 );
                        END
                        
                        set @sqlstring =  'SELECT           Type,
                                                            AttendanceDate 
                                           FROM             [STS_Attendance] 
                                           WHERE            LedgerID=@LedgerID 
                                           AND              year(AttendanceDate) = @Year 
                                           AND				CID=@CID
                                           AND              [Type] IN ('+@Data+')
                                          
                                    UNION ALL
                                          SELECT            (CASE WHEN Description=''week off'' THEN 1 ELSE 0 END) AS Type,
                                                            HolidayDate
                                          FROM              [EmployeeMaster] ER 
                                          CROSS JOIN        [STS_Holidays]  H 
                                          WHERE             YEAR(H.HolidayDate)=@Year 
                                          AND               ER.LedgerID=@LedgerID
                                          AND               HolidayDate not in (SELECT AttendanceDate FROM [STS_Attendance] WHERE LedgerID=@LedgerID AND CID=@CID) 
                                          AND               H.TimeZoneID=(SELECT TimeZoneID FROM [STS_EmployeeMasterSub] WHERE LedgerID=@LedgerID AND CID=@CID)
                                          AND				ER.CID=@CID
                                          
                                    UNION ALL
                                          SELECT
                                                            2 AS Type,
                                                            dt AS Date
                                          FROM 
                                                            (
                                                                  SELECT 
                                                                        dateadd(d, row_number() over (order by name), cast(@Date1 as datetime)) as dt 
                                                                  FROM 
                                                                        sys.columns a
                                                            ) as dates 
                                          WHERE				datename(dw, dt) in (SELECT WeekEnds FROM [STS_WeekEnds] WHERE TimeZoneID=(select TimeZoneID FROM [STS_EmployeeMasterSub] WHERE LedgerID=@LedgerID AND CID=@CID) AND CID=@CID)
                                          AND               dt not in (SELECT AttendanceDate FROM [STS_Attendance] WHERE LedgerID=@LedgerID AND	CID=@CID)
                                          AND               dt not in (SELECT HolidayDate FROM [STS_Holidays] Where CID=@CID )
                                          AND               YEAR(dates.dt)=@Year'
                                                
                        INSERT INTO #temp1 (Type,AttendanceDate) 
                        Exec sp_executesql @sqlstring,
                                                N'  @Year               Varchar(20),
                                                      @LedgerID         Varchar(20),
                                                      @Data             Nvarchar(max),
                                                      @Date1            Date,
                                                      @CID				VARCHAR(20)',
                                                      @Year       =     @Year,
                                                      @LedgerID   =     @LedgerID,
                                                      @Data       =     @Data,
                                                      @Date1      =     @Date1,
                                                      @CID		  =     @CID;

					
                        ---------------------
							INSERT INTO #temp1  
									SELECT
                                            5 AS Type,
                                            dt AS Date
                                      FROM 
                                            (
                                              SELECT  dateadd(d, row_number() over (order by name), cast(@Date1 as datetime)) as dt 
                                              FROM        sys.columns a
                                            ) as dates 
                                      WHERE		YEAR(dates.dt)=@Year
                                      AND       dt NOT IN (SELECT AttendanceDate FROM #temp1)
                                                                
                        ---------------------
                                    
					
													;with cte as
                                                            (
                                                                    SELECT
                                                                    Type,
                                                                    AttendanceDate
                                                                    ,LEFT(DATENAME(MONTH,AttendanceDate),3) AS Month_Name
                                                                    ,LEFT(DATENAME(WEEKDAY,AttendanceDate),1) AS Week_Name
                                                                    ,DATEPART(DW,AttendanceDate) as [WeekNum(1-7)]
                                                                    ,DATEDIFF(week, DATEADD(MONTH, DATEDIFF(MONTH, 0, AttendanceDate), 0), AttendanceDate) +1 as RowNumInCalendarMonth
                                                                    ,DATEDIFF(week, DATEADD(MONTH, DATEDIFF(MONTH, 0, AttendanceDate), 0), AttendanceDate) * 7 + DATEPART(DW,AttendanceDate) as CellPositionNumInCalendarMonth
                                                                  
                                                                    from #temp1
                                                            )
                                                            SELECT 
                                                                    [Month] as Name,[1] as S, [2] as M, [3] as T, [4] as W, [5] as T, [6] as F, [7] as S, [8] as S, [9] as M, [10] as T, [11] as W, [12] as T, [13] as F, [14] as S,[15] as S, [16] as M, [17] as T, [18] as W, [19] as T, [20] as F, [21] as S,[22] as S, [23] as M, [24] as T, [25] as W, [26] as T, [27] as F, [28] as S,[29] as S, [30] as M, [31] as T, [32] as W, [33] as T, [34] as F, [35] as S,[36] as S, [37] as M
                                                                    , [38] as T
                                                                   
                                                            FROM
                                                            (
                                                                    select ml.monname AS [Month],Type, CellPositionNumInCalendarMonth 
                                                                    from cte 
                                                                    right join #montnamelist ml on LEFT(DATENAME(MONTH,AttendanceDate),10) = ml.monname          
                                                            ) as s
                                                            pivot
                                                            (
                                                                    MAX(type)
                                                                    for CellPositionNumInCalendarMonth
                                                                    in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23],[24],[25],[26],[27],[28],[29],[30],[31],[32],[33],[34],[35],[36],[37]
                                                                    ,[38]
                                                                  
                                                                    )
                                                            )p 

                                                            ORDER BY
                                                            (
                                                                    CASE 
                                                                              when [Month] ='January' then 1
                                                                              when [Month] ='February' then 2
                                                                              when [Month] ='March' then 3
                                                                              when [Month] ='April' then 4
                                                                              when [Month] ='May' then 5
                                                                              when [Month] ='June' then 6
                                                                              when [Month] ='July' then 7
                                                                              when [Month] ='August' then 8
                                                                              when [Month] ='September' then 9
                                                                              when [Month] ='October' then 10
                                                                              when [Month] ='November' then 11
                                                                              when [Month] ='December' then 12
                                                                    END
                                                            )    
															
														
                              
                              DROP TABLE #temp1


				--------------  SUMMARY DETAILS -Start  ----------------------

							  IF OBJECT_ID('tempdb..#temp9') is null
                              CREATE TABLE #temp9(LID INT,LName NVarchar(Max))
                              
                              

                                    Insert into #temp9 values (-5,'CarryForward')
                                    Insert into #temp9 values (-4,'ApplicableLeave')
                                    Insert into #temp9 values (-3,'TotalLeave')
                                    Insert into #temp9 values (-2,'TakenLeave')
                                    Insert into #temp9 values (-1,'RemainingLeave')
                                    
                                    Insert into #temp9 (LID,LName) 
												   SELECT     LID,
															  LeaveType 
												   FROM       [STS_LeaveTypeMaster] 
												   WHERE      IsActive=1
												   AND		  CID = @CID
                                   
                                                                     

                                    IF OBJECT_ID('tempdb..#temp8') is null
                                    CREATE TABLE #temp8(ID INT,LID Int,Date_ Date,DayType DECIMAL(2,1))
                                    Insert into #temp8 (ID,LID,Date_,DayType) 
                                    SELECT LedgerID,Type,AttendanceDate,FullorHalf FROM [STS_Attendance] where LedgerID=@LedgerID and Year(AttendanceDate)=@Year AND CID = @CID
                            

                                    Declare @sqlCase  as NVarchar(4000) =null
                                    Declare @sql            as NVarchar(4000)=null
                                    Declare @CrryFwd        INT;
                                    
                                    -- CARRYFORWARD ---
									  SELECT          @CrryFwd=ISNULL(CarryForward,0) 
                                      FROM            [STS_CurYrCarryForward] cr 
                                      INNER JOIN      [EmployeeMaster] Em ON Em.LedgerID=cr.LedgerID AND Em.CID=cr.CID
                                      WHERE           cr.LedgerID=@LedgerID 
                                      AND             Em.InActive=0 
                                      AND             YEAR(cr.EntryDate)=@Year
                                      AND			  Em.CID=@CID;
                                      
                                    -- APPLICABLE LEAVE---
                                    Declare @AppLeave       INT;
									  SELECT          @AppLeave=ANP.NoOfDays  
                                      FROM            [STS_AnnualLeavePolicy] ANP 
                                      INNER JOIN      [STS_EmployeeMasterSub] ER on ER.GradeID=ANP.ALPID AND ANP.TimeZoneID=ER.TimeZoneID  AND ER.CID=ANP.CID
                                      WHERE           er.LedgerID=@LedgerID 
                                      AND             ANP.LID=106
                                      AND			  ER.CID=@CID;
                                    
                                     --- YEARLY VIEW BY EMPLOYEE --- 
                                    declare @ColumnHeaders VARCHAR(MAX) , @ColumnHeaders1 VARCHAR(MAX);
                                    set @ColumnHeaders = STUFF( (SELECT  ',' + 'Sum(CASE WHEN LName=' + quotename(LName,'''') + ' THEN Daytype else 0 end ) as ' + quotename(LName,'[')  + char(10)+char(13)
                                                                              FROM #temp9 order by lid
                                                                              FOR XML PATH(''), TYPE).value('.', 'varchar(max)'), 1, 1, '');

                                    Set @sql  ='Select dt.[Month] as Name, '+   @ColumnHeaders + ' into ##temptable  from #temp8 t join #temp9 t1 on t.LID=t1.LID
                                                      right join ( Select LEFT(DATENAME(MONTH,num*28),10)  [Month], num
                                                      from (values(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12) ) t (num)) dt on Left(Datename(month,t.date_),10)=dt.[Month]
                                                      Group by dt.[Month],num order by num'

                                    EXEC(@SQL)

                                    DECLARE @COLS1 NVARCHAR(MAX),@Lieu int;
                                    DECLARE @TABLE NVARCHAR(MAX)
                                    
                                    
									  SELECT      @COLS1=LeaveType 
									  FROM        [STS_LeaveTypeMaster] 
									  WHERE       LID=106 AND CID=@CID
                                                      
									  SELECT      @Lieu=IsActive 
									  FROM        [STS_LeaveTypeMaster] 
									  WHERE       LID=116 AND CID=@CID 
									  
									DECLARE @QRY NVARCHAR(MAX)
									SET @TABLE = '##temptable'
									DECLARE @total FLOAT
									
									IF(@Lieu=1)
										Begin 
											SET @QRY = 'UPDATE '+@TABLE+' SET TakenLeave=['+@COLS1+']'
											EXEC SP_EXECUTESQL @QRY

											SET @SQLSTRING='update ##temptable SET CarryForward=case when [Name] = ''January'' then @CrryFwd Else 0 end,
																									ApplicableLeave=@AppLeave,
																									TotalLeave=@CrryFwd+@AppLeave+Lieu,
																									RemainingLeave=((case when [Month] = ''January'' then @CrryFwd Else 0 end)+@AppLeave+Lieu)-TakenLeave'
											EXECUTE sp_executesql @SQLSTRING,
																				N'@CrryFwd        Float ,
																				@AppLeave         Float',
																				@CrryFwd   =      @CrryFwd,
																				@AppLeave  = @AppLeave;

											--DECLARE @total FLOAT --,@takenLeave FLOAT
											SET @total = 0;  
											SET @takenLeave=0;
		                                                                  
											SET @SQLSTRING='UPDATE ##temptable SET ApplicableLeave = case when [Name] = ''January'' then (@AppLeave-Lieu) Else (@total-Lieu) end, @total =  (@CrryFwd+@AppLeave+Lieu - @takenLeave),
																	@takenLeave=@takenLeave+TakenLeave-Lieu'
											EXECUTE sp_executesql @SQLSTRING,
																				N'@CrryFwd        Float ,
																				@AppLeave         Float,
																				@total            Float OUTPUT,
																				@takenLeave       Float OUTPUT',
																				@CrryFwd		 = @CrryFwd,
																				@AppLeave		 = @AppLeave,
																				@total           = @total OUTPUT,
																				@takenLeave      = @takenLeave OUTPUT;


											SET @SQLSTRING='UPDATE ##temptable SET TotalLeave=CarryForward+ApplicableLeave+Lieu,RemainingLeave=(CarryForward+ApplicableLeave+Lieu)-TakenLeave'
											EXECUTE sp_executesql @SQLSTRING
		                                                                        
											select * from ##temptable
											DROP TABLE ##temptable
										END
									Else
										BEGIN
											--SET @TABLE = '##temptable'

											--DECLARE @QRY NVARCHAR(MAX)
											SET @QRY = 'UPDATE '+@TABLE+' SET TakenLeave=['+@COLS1+']'
											EXEC SP_EXECUTESQL @QRY

											SET @SQLSTRING='update ##temptable SET CarryForward=case when [Name] = ''January'' then @CrryFwd Else 0 end,
																									ApplicableLeave=@AppLeave,
																									TotalLeave=@CrryFwd+@AppLeave,
																									RemainingLeave=((case when [Name] = ''January'' then @CrryFwd Else 0 end)+@AppLeave)-TakenLeave'
											EXECUTE sp_executesql @SQLSTRING,
																				N'@CrryFwd   Float ,
																				@AppLeave    Float',
																				@CrryFwd   = @CrryFwd,
																				@AppLeave  = @AppLeave;

											 --,@takenLeave FLOAT
											SET @total = 0;  
											SET @takenLeave=0;
		                                                                  
											SET @SQLSTRING='UPDATE ##temptable SET ApplicableLeave = case when [Name] = ''January'' then (@AppLeave) Else (@total) end, @total =  (@CrryFwd+@AppLeave - @takenLeave),
																	@takenLeave=@takenLeave+TakenLeave'
											EXECUTE sp_executesql @SQLSTRING,
																				N'@CrryFwd        Float ,
																				@AppLeave         Float,
																				@total            Float OUTPUT,
																				@takenLeave       Float OUTPUT',
																				@CrryFwd		= @CrryFwd,
																				@AppLeave		= @AppLeave,
																				@total			= @total OUTPUT,
																				@takenLeave		= @takenLeave OUTPUT;


											SET @SQLSTRING='UPDATE ##temptable SET TotalLeave=CarryForward+ApplicableLeave,RemainingLeave=(CarryForward+ApplicableLeave)-TakenLeave'
											EXECUTE sp_executesql @SQLSTRING
		                                                                        
											select * from ##temptable
											DROP TABLE ##temptable
									 END          
                                    drop table #temp8
                                    drop table #temp9

		 	--------------  SUMMARY DETAILS -End  ----------------------


			select                                                  
												LTM.LID,
												LTM.LeaveType AS 'LeaveType',                                        
												ISNULL(SUM(A.FullorHalf),0) As 'Total1'
							from        [STS_LeaveTypeMaster] LTM 
							inner join  [STS_LeaveTypeColorCode] LTC on LTM.LID = LTC.LID AND LTM.CID=LTC.CID
							inner join  [STS_Attendance] A on LTM.LID = A.Type  AND LTM.CID=A.CID
							where       LTM.IsActive = 1
							And			LTM.CID=@CID
							And         Year(A.AttendanceDate)=@Year and A.LedgerID =@LedgerID 
							group by    LTM.LID,LTM.LeaveType; 

            END   
            
           
            Else IF(@Flag ='All With LeaveData')
            BEGIN
            
                  IF OBJECT_ID('tempdb..#EmpReg1') is null
                        CREATE TABLE #EmpReg1(LedgerID INT)
              
                                          set @sqlstring = 'SELECT                E.LedgerID 
                                                            FROM                  [EmployeeMaster] E 
                                                            INNER JOIN            [STS_EmployeeMasterSub] ES ON ES.LedgerID=E.LedgerID AND ES.CID=E.CID
                                                            WHERE                 E.InActive=0 
                                                            AND                   ES.TimeZoneID=@TimeZone
                                                            AND                   e.LedgerID in (SELECT LedgerID FROM [STS_Attendance] WHERE TYPE IN ('+@Data+') 
																									AND  year(AttendanceDate) = @Year
																									AND  MONTH(AttendanceDate) = @Month
																									AND	 CID = @CID) 
															
															AND  E.CID=@CID'
                                            
											     if(@Department<>'0')
												  begin
												   set @sqlstring = @sqlstring +  '  AND  E.Category = @Department';
												  end

											INSERT INTO   #EmpReg1 
                                            exec sp_executesql @sqlstring,
																N'@Timezone        Nvarchar(10),
																	@Month         NVarchar(30),
																	@Year          Varchar(20),
																	@Data          Nvarchar(max),
																	@Department    Nvarchar(50),
																	@CID		   VARCHAR(20)',
																	@Timezone      = @Timezone,
																	@Month         = @Month,
																	@Year          = @Year,
																	@Data          = @Data,
																	@Department    = @Department,
																	@CID		   = @CID;
                                    
                  
                   IF OBJECT_ID('tempdb..#temp5') is null
                        CREATE TABLE #temp5(LedgerID INT,Type INT,AttendanceDate DATE)
                        
                  IF OBJECT_ID('tempdb..#temp6') is null
                        CREATE TABLE #temp6(Type INT,AttendanceDate DATE)
							INSERT INTO #temp5 (Type,AttendanceDate)
										SELECT
                                              2 AS Type,
                                              dt AS Date
                                        FROM 
                                              (
                                                    select 
                                                          dateadd(d, row_number() over (order by name), cast(@Date1 as datetime)) as dt 
                                                          from 
                                                          sys.columns a
                                              ) as dates 
                                        WHERE 
                                        datename(dw, dt) in (select WeekEnds from [STS_WeekEnds] where TimeZoneID=@TimeZone AND CID=@CID)
                                        and  dt not in (select AttendanceDate from [STS_Attendance]Where CID=@CID)
                                        and  dt not in (select HolidayDate from [STS_Holidays] where YEAR(HolidayDate)=@Year AND MONTH(HolidayDate)=@Month and TimeZoneID = @TimeZone AND CID=@CID)
                                        and YEAR(dates.dt)=@Year and MONTH(dates.dt)=@Month 
                                       
                              
									   INSERT INTO #temp6
												SELECT
                                                      5 AS Type,
                                                      dt AS Date
                                                FROM 
                                                      (
                                                            select 
                                                                  dateadd(d, row_number() over (order by name), cast(@Date1 as datetime)) as dt 
                                                                  from 
                                                                  sys.columns a
                                                      ) as dates 
                                                WHERE 
                                                YEAR(dates.dt)=@Year AND  MONTH(dates.dt)=@Month
                                                AND dt NOT IN (SELECT AttendanceDate FROM #temp5)   
                                                AND dt not in (select HolidayDate from [STS_Holidays] where YEAR(HolidayDate)=@Year AND MONTH(HolidayDate)=@Month and TimeZoneID = @TimeZone AND CID=@CID)
    
                        --------------                
                        
                IF OBJECT_ID('tempdb..#temp7') is null
                CREATE TABLE #temp7(LedgerID INT,Type INT,AttendanceDate DATE)
                        
                  if(@Data='')
                        BEGIN
							  SELECT       @Data = SUBSTRING((SELECT ( ' , ' + CONVERT(varchar,LID) )
                              FROM        [sts_LeaveTypeMaster] t2
                              WHERE       IsActive = 1
                              AND		  CID = @CID
                              ORDER BY    LID
                              FOR XML PATH( '' )), 3, 1000 );
                        END
                        
                        
                        set @sqlstring =' SELECT    LedgerID,
													Type,
													AttendanceDate 
										  from		[STS_Attendance] 
										  where		year(AttendanceDate) = @Year
                                          AND       MONTH(AttendanceDate) = @Month
                                          AND       LedgerID IN (SELECT LedgerID FROM #EmpReg1 )
                                          AND		CID=@CID
                                          AND       [Type] IN ('+@Data+')
                                      union all
                                          SELECT  
													ER.LedgerID,
													(CASE WHEN Description=''week off'' THEN 1 ELSE 0 END) AS Type,
													HolidayDate
                                            FROM	#EmpReg1 ER cross join [STS_Holidays] H where YEAR(H.HolidayDate)=@Year 
                                            AND		MONTH(H.HolidayDate)=@Month
                                            AND		HolidayDate not in (select A.AttendanceDate from [STS_Attendance] A where A.LedgerID=ER.LedgerID  AND CID=@CID) 
                                            AND		H.TimeZoneID = @TimeZone
                                            AND		H.CID=@CID
                                      union all
                                          SELECT 
													ER.LedgerID,
													T2.Type,
													T2.AttendanceDate FROM #EmpReg1 ER 
													cross JOIN #temp5 T2          
                                          where		T2.AttendanceDate not in (select A.AttendanceDate from [STS_Attendance] A where ER.LedgerID=A.LedgerID  AND CID=@CID) '
                        INSERT INTO #temp7 (LedgerID,Type,AttendanceDate)
                        Exec sp_executesql @sqlstring,
                                            N'    @Month      NVarchar(30),
                                                  @Year       Varchar(20),
                                                  @TimeZone   Nvarchar(10),
                                                  @Data       Nvarchar(max),
                                                  @CID		  Varchar(20)',
                                                  @month    = @month,
                                                  @Year     = @Year,
                                                  @TimeZone = @TimeZone,
                                                  @Data     = @Data,
                                                  @CID		= @CID;
                       
                        ---------------                                 
                        INSERT INTO #temp7
									SELECT      ER.LedgerID,T.Type,
                                                T.AttendanceDate 
                                    FROM        #EmpReg1 ER CROSS JOIN #temp6 T 
                                    WHERE       YEAR(T.AttendanceDate)= @Year 
                                    AND         MONTH(T.AttendanceDate)= @Month
                        ----------------        
                        
                      
										;with cte as
                                            (
                                                    SELECT
                                                    LedgerID,
                                                    Type,
                                                    AttendanceDate
                                                    ,LEFT(DATENAME(MONTH,AttendanceDate),3) AS Month_Name
                                                    ,LEFT(DATENAME(WEEKDAY,AttendanceDate),1) AS Week_Name
                                                    ,DATEPART(DW,AttendanceDate) as [WeekNum(1-7)]
                                                    ,DATEDIFF(week, DATEADD(MONTH, DATEDIFF(MONTH, 0, AttendanceDate), 0), AttendanceDate) +1 as RowNumInCalendarMonth
                                                    ,DATEDIFF(week, DATEADD(MONTH, DATEDIFF(MONTH, 0, AttendanceDate), 0), AttendanceDate) * 7 + DATEPART(DW,AttendanceDate) as CellPositionNumInCalendarMonth
                                                  
                                                    from #temp7
                                            )
                                            SELECT 
                                                    Name,[1] as S, [2] as M, [3] as T, [4] as W, [5] as T, [6] as F, [7] as S, [8] as S, [9] as M, [10] as T, [11] as W, [12] as T, [13] as F, [14] as S,[15] as S, [16] as M, [17] as T, [18] as W, [19] as T, [20] as F, [21] as S,[22] as S, [23] as M, [24] as T, [25] as W, [26] as T, [27] as F, [28] as S,[29] as S, [30] as M, [31] as T, [32] as W, [33] as T, [34] as F, [35] as S,[36] as S, [37] as M
                                                    , [38] as T 
                                                  
                                            FROM
                                            (
                                                    SELECT C.LedgerID,(select E.EmpID+' - '+E.AliasName1 from [EmployeeMaster]  E where E.LedgerID=C.LedgerID And CID=@CID) AS Name,ml.monname AS [Month],Type, CellPositionNumInCalendarMonth 
                                                    FROM cte C
                                                    right join #montnamelist ml on LEFT(DATENAME(MONTH,AttendanceDate),10) = ml.monname          
                                            ) as s
                                            pivot
                                            (
                                                    max(type)
                                                    for CellPositionNumInCalendarMonth
                                                    in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23],[24],[25],[26],[27],[28],[29],[30],[31],[32],[33],[34],[35],[36],[37]
                                                    ,[38]
                                                   
                                                    )
                                            )p 

                                            WHERE                                          
                                            Month=LEFT(DATENAME(m, str(@Month) + '/1/2011'),10)
                                            order by 
                                            (
                                                    CASE 
                                                              when [Month] ='January' then 1
                                                              when [Month] ='February' then 2
                                                              when [Month] ='March' then 3
                                                              when [Month] ='April' then 4
                                                              when [Month] ='May' then 5
                                                              when [Month] ='June' then 6
                                                              when [Month] ='July' then 7
                                                              when [Month] ='August' then 8
                                                              when [Month] ='September' then 9
                                                              when [Month] ='October' then 10
                                                              when [Month] ='November' then 11
                                                              when [Month] ='December' then 12
                                                    END
                                            )
                           
                              DROP TABLE #temp7
                              DROP TABLE #temp5
                              DROP TABLE #EmpReg1


					--------------  SUMMARY DETAILS -Start  ----------------------

							   Declare @Condition1 VARCHAR(max)=''
                  If(@Department <> '0' and @Department <>'')
                        BEGIN
                              SET @Condition1 ='AND Emp.Category = @Department';
                        END

					SELECT @SQLSTRING =' SELECT @cols = STUFF((SELECT '','' + ISNULL(QUOTENAME(LeaveType),0) 
                                                               FROM [STS_LeaveTypeMaster]
                                                               WHERE IsActive=1 
                                                               AND CID=@CID
                                                               GROUP BY LeaveType
                                                               FOR XML PATH(''''), TYPE
                                                               ).value(''.'', ''NVARCHAR(MAX)'') 
                                                               ,1,1,'''')'
                                          EXEC sp_executesql @SQLSTRING,
													   N'@cols     NVARCHAR(MAX) OUTPUT,
													     @CID	   Varchar(20)',
														 @cols   = @cols OUTPUT,
														 @CID	 = @CID;
                         
                                    SELECT @query = N'SELECT            Name,
                                                                        ISNULL(CarryForward,0) AS CarryForward,
                                                                        NoofDays,
                                                                        (ISNULL(CarryForward,0)+NoofDays+LieuDays)TotalLeave,
                                                                        TakenLeave,
                                                                        ((ISNULL(CarryForward,0)+NoofDays+LieuDays)-TakenLeave)RemainingLeave,
                                                                        ' + @cols + ' 
                                                       FROM             (      SELECT           Emp.LedgerID,
                                                                                                Emp.EmpID+'' - ''+Emp.AliasName1 AS Name,
                                                                                                CarryForward,
                                                                                                AP.NoofDays,
                                                                                                sum(A.FullorHalf)FullorHalf,
                                                                                                t.LeaveType,
                                                                                                (SELECT ISNULL(SUM(FullorHalf),0) FROM [STS_Attendance]  WHERE LedgerID=Emp.LedgerID AND Year(AttendanceDate)=@Year AND TYPE=116 And CID=@CID) as LieuDays,
                                                                                                (SELECT ISNULL(SUM(FullorHalf),0) FROM [STS_Attendance]  WHERE LedgerID=Emp.LedgerID AND Year(AttendanceDate)=@Year AND TYPE=106 And CID=@CID) as TakenLeave
                                                                              FROM        [EmployeeMaster] Emp 
                                                                              INNER JOIN  [STS_EmployeeMasterSub] ES ON EMP.LedgerID =ES.LedgerID AND EMP.CID=ES.CID
                                                                              LEFT JOIN   [STS_Attendance] A  ON Emp.LedgerID=A.LedgerID AND Emp.CID=A.CID AND Year(A.AttendanceDate)=@Year
                                                                              LEFT JOIN   [STS_LeaveTypeMaster] t ON t.LID= A.Type AND t.CID=A.CID 
                                                                              LEFT JOIN  [STS_AnnualLeavePolicy] AP ON AP.ALPID=ES.GradeID AND AP.CID=ES.CID AND AP.TimeZoneID=ES.TimeZoneID AND AP.LID=106
                                                                              LEFT join   [STS_CurYrCarryForward] CF ON CF.LedgerID=Emp.LedgerID AND CF.CID=Emp.CID AND  Year(CF.EntryDate)=@Year 
                                                                              where       Emp.LedgerID in (SELECT LedgerID FROM [STS_Attendance] WHERE TYPE IN ('+@Data+')and YEAR(AttendanceDate)=@Year AND MONTH(AttendanceDate)=@Month And CID=@CID)
                                                                              AND                ES.TimeZoneID = @TimeZone And	Emp.CID=@CID
                                                                              '+@Condition1+'
                                                                              GROUP BY      Emp.EmpID,Emp.LedgerID,A.FullorHalf,CarryForward,AP.NoofDays,t.LeaveType,Emp.AliasName1
                                                                        ) x
                                                                        PIVOT 
                                                                        (
                                                                              SUM(FullorHalf)
                                                                              FOR LeaveType IN (' + @cols + ')
                                                                        ) p '
                                    EXECUTE sp_executesql @query,
                                                      N'@Year           Varchar(20),
                                                        @Month          NVarchar(30),
                                                        @TimeZone       Nvarchar(10),
                                                        @Data           Nvarchar(max),
                                                        @Department     Nvarchar(50),
                                                        @CID			Varchar(20)',
                                                        @Year           = @Year,
                                                        @Month          = @Month,
                                                        @TimeZone       = @TimeZone,
                                                        @Data           = @Data,
                                                        @Department     = @Department,
                                                        @CID			= @CID;  


			--------------  SUMMARY DETAILS -End  ----------------------
            END
          
        
            
            drop table #montnamelist
END
GO

