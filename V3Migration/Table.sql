USE [AC-BinHanif_V3.2]

--select * from [ProjectMaster]
--select * from STS_ApprovalGroupSub
--ALTER TABLE [MenuGrouping] ADD  [ApplicationType] INT NULL
--ALTER TABLE [GroupMgtSub] ADD  [ApplicationType] INT NULL
--ALTER TABLE [MenuGrouping] ADD  [WebIcon] [nvarchar](20)NULL
--ALTER TABLE [MenuMgt] ADD  [WebIcon] [nvarchar](20)NULL
--alter table [STS_ApprovalGroupSub] alter column LedgerID int;
--ALTER TABLE [STS_ETSEffort] ADD  [ApproverLedgerID] INT NULL

--GO
--sp_rename 'ProjectMaster.PrjUniqID','ProjectUID','COLUMN';
--GO
--sp_rename 'ProjectMaster.Status','ProjectStatus','COLUMN';
--GO
--sp_rename 'STS_ApprovalGroupSub.LedgerID','ParentID','COLUMN'
--GO
--sp_rename'STS_ApprovalGroupSub.HierarchyAuth','LedgerID','COLUMN'
--GO
--sp_RENAME'[STS_ETSEffort].ProjectID','ProjectUID','COLUMN'
--GO
--SP_RENAME 'STS_ResourceAllocation.ProjectID','ProjectUID'
--GO
--SP_RENAME 'STS_ProjectSub.ProjectID','ProjectUID'
