USE [AC-BinHanif_V3.2]

--update [MenuGrouping] set applicationType=1
--update [GroupMgtSub] set applicationtype=1
----@SiteID
--insert into [ConfigParam] (CID, Tag, Value, CustomTag) values (101, 'gridpagesize', 7, 'gridpagesize')
--update [STS_ETSEffort] set ApproverLedgerID=0

insert into [MenuGrouping] (CID, ID, Description, ParentID, SortID, Reserved, CreatedBy, CreatedDate, LastUpdatedBy, LastUpdatedDate, ApplicationType, WebIcon) Values 
(101, 1, 'MenuGroup', 0, 1, 1, 'Admin', GETDATE(), 'Admin', GETDATE(), 3, 'av_timer')
insert into [MenuGrouping] (CID, ID, Description, ParentID, SortID, Reserved, CreatedBy, CreatedDate, LastUpdatedBy, LastUpdatedDate, ApplicationType, WebIcon) Values 
(101, 30, 'File', 1, 1, 1, 'Admin', GETDATE(), 'Admin', GETDATE(), 3, 'av_timer')
insert into [MenuGrouping] (CID, ID, Description, ParentID, SortID, Reserved, CreatedBy, CreatedDate, LastUpdatedBy, LastUpdatedDate, ApplicationType, WebIcon) Values 
(101, 31, 'Company Settings', 30, 1, 1, 'Admin', GETDATE(), 'Admin', GETDATE(), 3, 'av_timer')
insert into [MenuGrouping] (CID, ID, Description, ParentID, SortID, Reserved, CreatedBy, CreatedDate, LastUpdatedBy, LastUpdatedDate, ApplicationType, WebIcon) Values 
(101, 32, 'Master', 1, 2, 1, 'Admin', GETDATE(), 'Admin', GETDATE(), 3, 'av_timer')
insert into [MenuGrouping] (CID, ID, Description, ParentID, SortID, Reserved, CreatedBy, CreatedDate, LastUpdatedBy, LastUpdatedDate, ApplicationType, WebIcon) Values 
(101, 33, 'Project', 32, 1, 1, 'Admin', GETDATE(), 'Admin', GETDATE(), 3, 'av_timer')
insert into [MenuGrouping] (CID, ID, Description, ParentID, SortID, Reserved, CreatedBy, CreatedDate, LastUpdatedBy, LastUpdatedDate, ApplicationType, WebIcon) Values 
(101, 34, 'Project', 1, 3, 1, 'Admin', GETDATE(), 'Admin', GETDATE(), 3, 'av_timer')
insert into [MenuGrouping] (CID, ID, Description, ParentID, SortID, Reserved, CreatedBy, CreatedDate, LastUpdatedBy, LastUpdatedDate, ApplicationType, WebIcon) Values 
(101, 35, 'HR', 1, 4, 1, 'Admin', GETDATE(), 'Admin', GETDATE(), 3, 'av_timer')


insert into [MenuMgt] (CID, MenuGroupID, SortID, MenuID, Description, ShortCutKey, Color, Reserved, LoadGroupMgt, ApplicationType, Parameters, Options, MenuIndex, Icon, WebIcon)
values (101,31,	1, 'ERP_103', 'User Management', '', 'Color [A=255, R=176, G=196, B=222]', 0, 1, 3, '[]', '[{"Options":"Add"},{"Options":"Edit"},{"Options":"Delete"},{"Options":"View"}]', NULL,	'0x', 'chevron_right')

insert into [MenuMgt] (CID, MenuGroupID, SortID, MenuID, Description, ShortCutKey, Color, Reserved, LoadGroupMgt, ApplicationType, Parameters, Options, MenuIndex, Icon, WebIcon)
values (101,31,	2, 'ERP_104', 'Group Management', '', 'Color [A=255, R=176, G=196, B=222]', 0, 1, 3, '[]', '[{"Options":"Add"},{"Options":"Edit"},{"Options":"Delete"},{"Options":"View"}]', NULL,	'0x', 'chevron_right')

insert into [MenuMgt] (CID, MenuGroupID, SortID, MenuID, Description, ShortCutKey, Color, Reserved, LoadGroupMgt, ApplicationType, Parameters, Options, MenuIndex, Icon, WebIcon)
values (101,33,	1, 'ERP_128', 'Project Master', '', 'Color [A=255, R=176, G=196, B=222]', 0, 1, 3, '[]', '[{"Options":"Add"},{"Options":"Edit"},{"Options":"Delete"},{"Options":"View"}]', NULL,	'0x', 'chevron_right')

insert into [MenuMgt] (CID, MenuGroupID, SortID, MenuID, Description, ShortCutKey, Color, Reserved, LoadGroupMgt, ApplicationType, Parameters, Options, MenuIndex, Icon, WebIcon)
values (101,35,	1, 'STS_11', 'LeaveRequest', '', 'Color [A=255, R=176, G=196, B=222]', 0, 1, 3, '[]', '[{"Options":"Add"},{"Options":"Edit"},{"Options":"Delete"},{"Options":"View"}]', NULL,	'0x', 'chevron_right')

insert into [MenuMgt] (CID, MenuGroupID, SortID, MenuID, Description, ShortCutKey, Color, Reserved, LoadGroupMgt, ApplicationType, Parameters, Options, MenuIndex, Icon, WebIcon)
values (101,35,	2, 'STS_15', 'Attendance Report', '', 'Color [A=255, R=176, G=196, B=222]', 0, 1, 3, '[]', '[{"Options":"Add"},{"Options":"Edit"},{"Options":"Delete"},{"Options":"View"}]', NULL,	'0x', 'chevron_right')

insert into [MenuMgt] (CID, MenuGroupID, SortID, MenuID, Description, ShortCutKey, Color, Reserved, LoadGroupMgt, ApplicationType, Parameters, Options, MenuIndex, Icon, WebIcon)
values (101,35,	3, 'STS_21', 'LeaveApproval', '', 'Color [A=255, R=176, G=196, B=222]', 0, 1, 3,'[]', '[{"Options":"Add"},{"Options":"Edit"},{"Options":"Delete"},{"Options":"View"}]', NULL,	'0x', 'chevron_right')

insert into [MenuMgt] (CID, MenuGroupID, SortID, MenuID, Description, ShortCutKey, Color, Reserved, LoadGroupMgt, ApplicationType, Parameters, Options, MenuIndex, Icon, WebIcon)
values (101,35,	5, 'STS_54', 'TimePunchReport', '', 'Color [A=255, R=176, G=196, B=222]', 0, 1, 3,'[]', '[{"Options":"Add"},{"Options":"Edit"},{"Options":"Delete"},{"Options":"View"}]', NULL,	'0x', 'chevron_right')

insert into [MenuMgt] (CID, MenuGroupID, SortID, MenuID, Description, ShortCutKey, Color, Reserved, LoadGroupMgt, ApplicationType, Parameters, Options, MenuIndex, Icon, WebIcon)
values (101,34,	1, 'STS_63', 'Allocation By Week', '', 'Color [A=255, R=176, G=196, B=222]', 0, 1, 3, '[]', '[{"Options":"Add"},{"Options":"Edit"},{"Options":"Delete"},{"Options":"View"}]', NULL,	'0x', 'chevron_right')

insert into [MenuMgt] (CID, MenuGroupID, SortID, MenuID, Description, ShortCutKey, Color, Reserved, LoadGroupMgt, ApplicationType, Parameters, Options, MenuIndex, Icon, WebIcon)
values (101,35,	4, 'STS_77', 'Leave Request Report', '', 'Color [A=255, R=176, G=196, B=222]', 0, 1, 3, '[]', '[{"Options":"Add"},{"Options":"Edit"},{"Options":"Delete"},{"Options":"View"}]', NULL,	'0x', 'chevron_right')

insert into [MenuMgt] (CID, MenuGroupID, SortID, MenuID, Description, ShortCutKey, Color, Reserved, LoadGroupMgt, ApplicationType, Parameters, Options, MenuIndex, Icon, WebIcon)
values (101,34,	2, 'STS_90', 'HierarchyConfig', '', 'Color [A=255, R=176, G=196, B=222]', 0, 1, 3, '[]', '[{"Options":"Add"},{"Options":"Edit"},{"Options":"Delete"},{"Options":"View"}]', NULL,	'0x', 'chevron_right')

insert into [MenuMgt] (CID, MenuGroupID, SortID, MenuID, Description, ShortCutKey, Color, Reserved, LoadGroupMgt, ApplicationType, Parameters, Options, MenuIndex, Icon, WebIcon)
values (101,34,	3, 'STS_91', 'Effort Approve', '', 'Color [A=255, R=176, G=196, B=222]', 0, 1, 3, '[]', '[{"Options":"Add"},{"Options":"Edit"},{"Options":"Delete"},{"Options":"View"}]', NULL,	'0x', 'chevron_right')

insert into [MenuMgt] (CID, MenuGroupID, SortID, MenuID, Description, ShortCutKey, Color, Reserved, LoadGroupMgt, ApplicationType, Parameters, Options, MenuIndex, Icon, WebIcon)
values (101,34,	4, 'STS_92', 'Attendance', '', 'Color [A=255, R=176, G=196, B=222]', 0, 1, 3, '[]', '[{"Options":"Add"},{"Options":"Edit"},{"Options":"Delete"},{"Options":"View"}]', NULL,	'0x', 'chevron_right')

insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'ERP_103', 'Add', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'ERP_103', 'Eeit', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'ERP_103', 'View', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'ERP_103', 'Delete', 3)

insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'ERP_104', 'Add', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'ERP_104', 'Eeit', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'ERP_104', 'View', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'ERP_104', 'Delete', 3)

insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'ERP_128', 'Add', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'ERP_128', 'Eeit', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'ERP_128', 'View', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'ERP_128', 'Delete', 3)

insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_11', 'Add', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_11', 'Eeit', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_11', 'View', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_11', 'Delete', 3)

insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_15', 'Add', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_15', 'Eeit', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_15', 'View', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_15', 'Delete', 3)

insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_21', 'Add', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_21', 'Eeit', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_21', 'View', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_21', 'Delete', 3)

insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_63', 'Add', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_63', 'Eeit', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_63', 'View', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_63', 'Delete', 3)

insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_77', 'Add', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_77', 'Eeit', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_77', 'View', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_77', 'Delete', 3)

insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_90', 'Add', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_90', 'Eeit', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_90', 'View', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_90', 'Delete', 3)

insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_91', 'Add', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_91', 'Eeit', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_91', 'View', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_91', 'Delete', 3)

insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_92', 'Add', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_92', 'Eeit', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_92', 'View', 3)
insert into [GroupMgtSub] (CID, GroupID, MenuID, Options, ApplicationType) values (101, 101, 'STS_92', 'Delete', 3)

--Vignesh
GO
sp_RENAME '[STS_ITSTicket].ProjectID','ProjectUID','COLUMN'
GO
delete from [FormGridSettings] where MenuID='STS_24' and CID=101

INSERT INTO [FormGridSettings](CID,MenuID,GridID,DBFieldName,Name1,Name2,Position,Width,ReadOnly,Alignment,Visibility,CellStyleFormat,DataType,ControlType,DefaultValue) Values(101,'STS_24',1,'TicketNo','Ticket','Ticket',2,80,0,16,1,0,'System.Int32','Combo',0)
INSERT INTO [FormGridSettings](CID,MenuID,GridID,DBFieldName,Name1,Name2,Position,Width,ReadOnly,Alignment,Visibility,CellStyleFormat,DataType,ControlType,DefaultValue) Values(101,'STS_24',1,'ProductID','Product','Product',2,80,0,16,1,0,'System.Int32','Combo',0)
INSERT INTO [FormGridSettings](CID,MenuID,GridID,DBFieldName,Name1,Name2,Position,Width,ReadOnly,Alignment,Visibility,CellStyleFormat,DataType,ControlType,DefaultValue) Values(101,'STS_24',1,'ProjectUID','Project','Project',2,80,0,16,1,0,'System.Int32','Combo',0)
INSERT INTO [FormGridSettings](CID,MenuID,GridID,DBFieldName,Name1,Name2,Position,Width,ReadOnly,Alignment,Visibility,CellStyleFormat,DataType,ControlType,DefaultValue) Values(101,'STS_24',1,'ClientID','Client','Client',2,80,0,16,1,0,'System.Int32','Combo',0)

update [GroupMgtSub] set ApplicationType=3 where MenuID like 'STS%'
update [EmployeeMaster] set AliasName1=FirstName, AliasName2 = FirstName where AliasName1 is null
update [EmployeeMaster] set AliasName2 = FirstName where AliasName2 is null

INSERT [dbo].[MenuMgt] ([CID], [MenuGroupID], [SortID], [MenuID], [Description],      [ShortCutKey], [Color], 
[Reserved], [LoadGroupMgt], [ApplicationType], [Parameters], [Options], [MenuIndex], [Icon], [WebIcon])  
VALUES (101, N'35', 6, N'STS_24', N'Timesheet', N'', N'Color [A=255, R=176, G=196, B=222]', 0, 1, 3, N'[]',  
N'[{"Options":"Add"},{"Options":"Edit"},{"Options":"Delete"}]', NULL, 0x, N'chevron_right')

if not exists (select * from [STS_Category])
begin
	INSERT [dbo].[STS_Category] ([CategoryID], [CategoryName], [Description], [CateGroupID], [CateActivityID], [Reason], [Chargeable], [CID]) VALUES (101, N'Development Application', N'Development Application', NULL, NULL, NULL, NULL, 101)
	INSERT [dbo].[STS_Category] ([CategoryID], [CategoryName], [Description], [CateGroupID], [CateActivityID], [Reason], [Chargeable], [CID]) VALUES (102, N'Marketing', N'Marketing', NULL, NULL, NULL, NULL, 101)
	INSERT [dbo].[STS_Category] ([CategoryID], [CategoryName], [Description], [CateGroupID], [CateActivityID], [Reason], [Chargeable], [CID]) VALUES (103, N'Sales', N'Sales', NULL, NULL, NULL, NULL, 101)
end

if not exists (select * from [STS_Product])
begin
	INSERT [dbo].[STS_Product] ([ProductID], [ProductName], [Description], [Status], [RegisterSince], [CID]) VALUES (5001, N'STS', N'STS', 0, CAST(N'2019-02-12T00:00:00.000' AS DateTime), 101)
	INSERT [dbo].[STS_Product] ([ProductID], [ProductName], [Description], [Status], [RegisterSince], [CID]) VALUES (5002, N'ERP', N'ERP', 0, CAST(N'2019-02-12T00:00:00.000' AS DateTime), 101)
	INSERT [dbo].[STS_Product] ([ProductID], [ProductName], [Description], [Status], [RegisterSince], [CID]) VALUES (5003, N'EazyPres', N'EazyPres', 0, CAST(N'2019-02-12T00:00:00.000' AS DateTime), 101)
	INSERT [dbo].[STS_Product] ([ProductID], [ProductName], [Description], [Status], [RegisterSince], [CID]) VALUES (5004, N'Ancestry', N'Ancestry', 0, CAST(N'2019-02-12T00:00:00.000' AS DateTime), 101)
end

update [GroupMgtSub] set ApplicationType=3 where MenuID='STS_54' and CID=101
--Powsul

insert into GroupMgtSub (CID,GroupID,MenuID,Options,ApplicationType)
select CID,GroupID,MenuID,Options,3 From GroupMgtSub where ApplicationType=1 and GroupID=108 

insert into GroupMgtSub (CID,GroupID,MenuID,Options,ApplicationType)
select CID,GroupID,MenuID,Options,3 From GroupMgtSub where ApplicationType=1 and GroupID=120 

insert into GroupMgtSub (CID,GroupID,MenuID,Options,ApplicationType)
select CID,GroupID,MenuID,Options,3 From GroupMgtSub where ApplicationType=1 and GroupID=118

insert into GroupMgtSub (CID,GroupID,MenuID,Options,ApplicationType)
select CID,GroupID,MenuID,Options,3 From GroupMgtSub where ApplicationType=1 and GroupID=104

insert into GroupMgtSub (CID,GroupID,MenuID,Options,ApplicationType)
select CID,GroupID,MenuID,Options,3 From GroupMgtSub where ApplicationType=1 and GroupID=109

-- dont run below script
--select * from [MenuMgt] where MenuID='STS_54'
--INSERT [MenuMgt] ([CID], [MenuGroupID], [SortID], [MenuID], [Description], [ShortCutKey], [Color], [Reserved], [LoadGroupMgt], [ApplicationType], [Parameters], [Options], [MenuIndex], [Icon], [WebIcon])
--VALUES (101, N'7', 4, N'STS_77', N'Leave Request Report', N'', N'Color [A=255, R=176, G=196, B=222]', 0, 1, 3, N'[]', N'[{"Options":"Refresh"}]', NULL, 0x, N'chevron_right')

--INSERT [dbo].[MenuMgt] ([CID], [MenuGroupID], [SortID], [MenuID], [Description], [ShortCutKey], [Color], [Reserved], [LoadGroupMgt], [ApplicationType], [Parameters], [Options], [MenuIndex], [Icon], [WebIcon]) 
--VALUES (101, N'7', 5, N'STS_54', N'TimePunchReport', N'', N'Color [A=255, R=176, G=196, B=222]', 0, 1, 3, N'[]', N'[{"Options":"Refresh"},{"Options":"Add"}]', NULL, 0x, N'chevron_right')


