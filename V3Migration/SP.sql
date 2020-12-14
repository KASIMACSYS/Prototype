IF (OBJECT_ID('STS_GetLeaveRequestReport') IS NOT NULL)
  DROP PROCEDURE STS_GetLeaveRequestReport
GO
DROP TYPE [dbo].[TVP_STS_EmpLeaveRpt]
GO
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

IF (OBJECT_ID('SetAlternateEmployee') IS NOT NULL)
  DROP PROCEDURE SetAlternateEmployee
GO
DROP TYPE [dbo].[TVP_STS_AlternateEmp]
GO
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

IF (OBJECT_ID('SetProjectEffortApproval') IS NOT NULL)
  DROP PROCEDURE SetProjectEffortApproval
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
