SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [CreateFormApproval] 
	-- Add the parameters for the stored procedure here
	  @CID				    INT,
	  @MenuID				VARCHAR(20),
	  @BusinessPeriodID		INT,
      @VouNo				NVARCHAR(30),
	  @CreatedBy			NVARCHAR(50),
	  @CreatedDate			DATETIME,
      @ERRORNO				INT OUTPUT,
	  @ERRORDESC			nVARCHAR(MAX)			OUTPUT 
--UNLOCK-- WITH ENCRYPTION 
 AS 
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets FROM
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		
    DECLARE @DESC				VARCHAR(MAX)
	--DECLARE @BusinessPeriodID	INT=0;

	BEGIN TRY
	BEGIN TRANSACTION @ERRORDESC
	
	INSERT INTO [FormApproval]			
	SELECT		ARS.CID, ARS.MenuID, @VouNo,  ARC.ApproverLevel, ARS.RuleID, ARC.Condition, 0  
	FROM		[ApprovalRuleSetup] ARS 
	INNER JOIN	[ApprovalRuleCondition] ARC 
	ON			ARS.RuleID	= ARC.RuleID 
	WHERE		ARS.CID		= @CID 
	AND			ARC.CID		= @CID 
	AND			ARS.MenuID	= @MenuID;
			
    COMMIT TRANSACTION
			 SET @ERRORNO = 0
			 SET @DESC='Sucessfully Added'+''+'FORM APPROVAL DETAILS'+' : '+ @VouNo	
			 SET @ERRORDESC = ''
		EXEC ElogUpdate @CID,@BusinessPeriodID,@CreatedBy,@CreatedDate,'','CI',@ERRORNO,@DESC,@ERRORDESC,7,0,4;
		END TRY
		BEGIN CATCH
	ROLLBACK TRANSACTION
			SET @ERRORNO = ERROR_NUMBER()
			SET @DESC='ERROR ADDING'+''+'FORM APPROVAL DETAILS'+' : '+@VouNo	
			SET @ERRORDESC = ERROR_MESSAGE()
		EXEC ElogUpdate @CID,@BusinessPeriodID,@CreatedBy,@CreatedDate,'','CI',@ERRORNO,@DESC,@ERRORDESC,5,3,4;
	END CATCH
	
			
END
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
CREATE PROCEDURE [CreateFormApprovalSub] 
	-- Add the parameters for the stored procedure here
	  @CID				    INT,
	  @MenuID				VARCHAR(20),
      @VouNo				NVARCHAR(30),
	  @Approverlevel		INT,
	  @CreatedBy			NVARCHAR(50),
	  @CreatedDate			DATETIME,
	  @ApprovedStatus		BIT,
      @ERRORNO				INT OUTPUT,
	  @ERRORDESC			nVARCHAR(MAX)			OUTPUT 
--UNLOCK-- WITH ENCRYPTION 
 AS 
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets FROM
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		
    DECLARE @DESC				VARCHAR(MAX)
	DECLARE @BusinessPeriodID	INT=0;
	DECLARE @RuleID				NVARCHAR(30);
	DECLARE @GroupID			NVARCHAR(30);

	BEGIN TRY
	BEGIN TRANSACTION @ERRORDESC
	
	SELECT @RuleID = RuleID FROM [ApprovalRuleSetup] WHERE CID = @CID AND MenuID = @MenuID;
	SELECT @GroupID = Condition FROM [FormApproval] WHERE CID = @CID AND MenuID = @MenuID AND VouNo = @VouNo AND ApproverLevel = @Approverlevel;

	INSERT INTO [FormApprovalSub] (CID, MenuID, VouNo, ApproverLevel, RuleID, ApprovedBy, ApprovedDate, ApprovedStatus)			
	VALUES (@CID, @MenuID, @VouNo, @Approverlevel, @RuleID, @CreatedBy, @CreatedDate, @ApprovedStatus);
			
	--EXEC UpdateFormApprovalStatus
	--		@CID				= @CID,
	--		@MenuID				= @MenuID,
	--		@VouNo				= @VouNo,
	--		@Approverlevel		= @Approverlevel,
	--		@RuleID				= @RuleID,
	--		@GroupID			= @GroupID,
	--		@ERRORNO			= @ERRORNO OUTPUT,
	--		@ERRORDESC			= @ERRORDESC OUTPUT 

    COMMIT TRANSACTION
			 SET @ERRORNO = 0
			 SET @DESC='Sucessfully Added'+''+'FORM APPROVAL DETAILS'+' : '+ @VouNo	
			 SET @ERRORDESC = ''
		EXEC ElogUpdate @CID,@BusinessPeriodID,@CreatedBy,@CreatedDate,'','CI',@ERRORNO,@DESC,@ERRORDESC,7,0,4;
		END TRY
		BEGIN CATCH
	ROLLBACK TRANSACTION
			SET @ERRORNO = ERROR_NUMBER()
			SET @DESC='ERROR ADDING'+''+'FORM APPROVAL DETAILS'+' : '+@VouNo	
			SET @ERRORDESC = ERROR_MESSAGE()
		EXEC ElogUpdate @CID,@BusinessPeriodID,@CreatedBy,@CreatedDate,'','CI',@ERRORNO,@DESC,@ERRORDESC,5,3,4;
	END CATCH
	
			
END
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
CREATE PROCEDURE [GetFormApproval] 
	-- Add the parameters for the stored procedure here
	  @CID				    INT,
	  @MenuID				VARCHAR(20),
      @VouNo				NVARCHAR(30)
--UNLOCK-- WITH ENCRYPTION 
 AS 
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets FROM
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		
	DECLARE @RuleID				NVARCHAR(30);

	SELECT @RuleID = RuleID FROM [ApprovalRuleSetup] WHERE CID = @CID AND MenuID = @MenuID;

	SELECT GroupID, UserList, NoOfApprovals, ApproverLevel , (SELECT dbo.GroupApprovalMatched(101,RuleID, GroupID, approverlevel, NoOfApprovals)) GroupApproval from [ApprovalRulesUsers] where CID = @CID and RuleID = @RuleID
	--SELECT GroupID, UserList, NoOfApprovals FROM [ApprovalRulesUsers] where CID = @CID AND RuleID = @RuleID;
	SELECT Top 1 ApproverLevel, Condition, Status FROM [FormApproval] WHERE CID = @CID AND MenuID = @MenuID  AND VouNo = @VouNo AND RuleID = @RuleID AND Status=0 ORDER BY ApproverLevel DESC;
    SELECT ApproverLevel, ApprovedBy, ApprovedStatus FROM [FormApprovalSub] WHERE CID = @CID AND MenuID = @MenuID AND VouNo = @VouNo AND RuleID = @RuleID;
END
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
CREATE PROCEDURE [UpdateFormApprovalStatus] 
	-- Add the parameters for the stored procedure here
	  @CID				    INT,
	  @MenuID				VARCHAR(20),
      @VouNo				NVARCHAR(30),
	  @Approverlevel		INT,
      @ERRORNO				INT OUTPUT,
	  @ERRORDESC			nVARCHAR(MAX)			OUTPUT 
--UNLOCK-- WITH ENCRYPTION 
 AS 
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets FROM
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		
    DECLARE @DESC				VARCHAR(MAX)
	DECLARE @BusinessPeriodID	INT=0;
	DECLARE @RuleID				NVARCHAR(30);

	BEGIN TRY
	BEGIN TRANSACTION @ERRORDESC
	
	SELECT @RuleID = RuleID FROM [ApprovalRuleSetup] WHERE CID = @CID AND MenuID = @MenuID;
	UPDATE [FormApproval] SET Status = 1 WHERE CID = @CID AND MenuID = @MenuID AND VouNo = @VouNo AND RuleID = @RuleID AND ApproverLevel = @Approverlevel;
			
    COMMIT TRANSACTION
			 SET @ERRORNO = 0
			 SET @DESC='Sucessfully Added'+''+'FORM APPROVAL DETAILS'+' : '+ @VouNo	
			 SET @ERRORDESC = ''
		--EXEC ElogUpdate @CID,@BusinessPeriodID,@CreatedBy,@CreatedDate,'','CI',@ERRORNO,@DESC,@ERRORDESC,7,0,4;
		END TRY
		BEGIN CATCH
	ROLLBACK TRANSACTION
			SET @ERRORNO = ERROR_NUMBER()
			SET @DESC='ERROR ADDING'+''+'FORM APPROVAL DETAILS'+' : '+@VouNo	
			SET @ERRORDESC = ERROR_MESSAGE()
		--EXEC ElogUpdate @CID,@BusinessPeriodID,@CreatedBy,@CreatedDate,'','CI',@ERRORNO,@DESC,@ERRORDESC,5,3,4;
	END CATCH
	
			
END
GO
