SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ApprovalRuleCondition](
	[CID] [int] NOT NULL,
	[RuleID] [int] NOT NULL,
	[ApproverLevel] [int] NOT NULL,
	[Condition] [nvarchar](50) NULL,
 CONSTRAINT [PK_ApprovalRuleCondition] PRIMARY KEY CLUSTERED 
(
	[CID] ASC,
	[RuleID] ASC,
	[ApproverLevel] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ApprovalRuleSetup](
	[CID] [int] NOT NULL,
	[MenuID] [nvarchar](30) NOT NULL,
	[RuleID] [int] NOT NULL,
	[Condition] [nvarchar](50) NULL,
 CONSTRAINT [PK_ApprovalRuleSetup] PRIMARY KEY CLUSTERED 
(
	[CID] ASC,
	[MenuID] ASC,
	[RuleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ApprovalRulesMaster](
	[RuleID] [int] NOT NULL,
	[Description] [nvarchar](50) NOT NULL,
	[Status] [int] NOT NULL,
	[CreatedBy] [nvarchar](30) NULL
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ApprovalRulesUsers](
	[CID] [int] NOT NULL,
	[RuleID] [int] NOT NULL,
	[GroupID] [nvarchar](5) NOT NULL,
	[UserList] [nvarchar](100) NOT NULL,
	[NoOfApprovals] [int] NOT NULL,
	[ApproverLevel] [int] NOT NULL
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [FormApproval](
	[CID] [int] NOT NULL,
	[MenuID] [varchar](10) NOT NULL,
	[VouNo] [varchar](50) NOT NULL,
	[ApproverLevel] [int] NOT NULL,
	[RuleID] [int] NOT NULL,
	[Condition] [nvarchar](50) NULL,
	[Status] [bit] NULL,
 CONSTRAINT [PK_FormApproval] PRIMARY KEY CLUSTERED 
(
	[CID] ASC,
	[MenuID] ASC,
	[VouNo] ASC,
	[ApproverLevel] ASC,
	[RuleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [FormApprovalSub](
	[CID] [int] NOT NULL,
	[MenuID] [varchar](10) NOT NULL,
	[VouNo] [varchar](50) NOT NULL,
	[ApproverLevel] [int] NOT NULL,
	[RuleID] [int] NOT NULL,
	[ApprovedBy] [int] NULL,
	[ApprovedDate] [datetime] NULL,
	[ApprovedStatus] [bit] NOT NULL
) ON [PRIMARY]
GO
INSERT [ApprovalRuleCondition] ([CID], [RuleID], [ApproverLevel], [Condition]) VALUES (101, 1001, 1, N'G1')
GO
INSERT [ApprovalRuleCondition] ([CID], [RuleID], [ApproverLevel], [Condition]) VALUES (101, 1001, 2, N'G2')
GO
INSERT [ApprovalRuleCondition] ([CID], [RuleID], [ApproverLevel], [Condition]) VALUES (101, 1001, 3, N'([G3-1] AND [G3-2]) OR [G3-3]')
GO
INSERT [ApprovalRuleCondition] ([CID], [RuleID], [ApproverLevel], [Condition]) VALUES (101, 1002, 1, N'G1')
GO
INSERT [ApprovalRuleCondition] ([CID], [RuleID], [ApproverLevel], [Condition]) VALUES (101, 1002, 2, N'G2')
GO
INSERT [ApprovalRuleCondition] ([CID], [RuleID], [ApproverLevel], [Condition]) VALUES (101, 1002, 3, N'([G3_1] AND [G3_2]) OR [G3_3]')
GO
INSERT [ApprovalRuleSetup] ([CID], [MenuID], [RuleID], [Condition]) VALUES (101, N'ERP_157', 1002, N'')
GO
INSERT [ApprovalRuleSetup] ([CID], [MenuID], [RuleID], [Condition]) VALUES (101, N'ERP_176', 1001, N'')
GO
INSERT [ApprovalRulesMaster] ([RuleID], [Description], [Status], [CreatedBy]) VALUES (1001, N'Amount>1000', 1, N'Kasim')
GO
INSERT [ApprovalRulesUsers] ([CID], [RuleID], [GroupID], [UserList], [NoOfApprovals], [ApproverLevel]) VALUES (101, 1001, N'G1', N'[{"User":"1"}]', 1, 1)
GO
INSERT [ApprovalRulesUsers] ([CID], [RuleID], [GroupID], [UserList], [NoOfApprovals], [ApproverLevel]) VALUES (101, 1001, N'G2', N'[{"User":"2"},{"User":"3"},{"User":"4"},{"User":"5"}]', 2, 2)
GO
INSERT [ApprovalRulesUsers] ([CID], [RuleID], [GroupID], [UserList], [NoOfApprovals], [ApproverLevel]) VALUES (101, 1001, N'G3-1', N'[{"User":"6"},{"User":"7"},{"User":"8"},{"User":"9"}]', 2, 3)
GO
INSERT [ApprovalRulesUsers] ([CID], [RuleID], [GroupID], [UserList], [NoOfApprovals], [ApproverLevel]) VALUES (101, 1001, N'G3-2', N'[{"User":"13"}]', 1, 3)
GO
INSERT [ApprovalRulesUsers] ([CID], [RuleID], [GroupID], [UserList], [NoOfApprovals], [ApproverLevel]) VALUES (101, 1001, N'G3-3', N'[{"User":"14"},{"User":"15"},{"User":"16"},{"User":"17"}]', 2, 3)
GO
INSERT [ApprovalRulesUsers] ([CID], [RuleID], [GroupID], [UserList], [NoOfApprovals], [ApproverLevel]) VALUES (101, 1002, N'G1', N'[{"User":"1"}]', 1, 1)
GO
INSERT [ApprovalRulesUsers] ([CID], [RuleID], [GroupID], [UserList], [NoOfApprovals], [ApproverLevel]) VALUES (101, 1002, N'G2', N'[{"User":"2"},{"User":"3"},{"User":"4"},{"User":"5"}]', 2, 2)
GO
INSERT [ApprovalRulesUsers] ([CID], [RuleID], [GroupID], [UserList], [NoOfApprovals], [ApproverLevel]) VALUES (101, 1002, N'G3_1', N'[{"User":"6"},{"User":"7"},{"User":"8"},{"User":"9"}]', 2, 3)
GO
INSERT [ApprovalRulesUsers] ([CID], [RuleID], [GroupID], [UserList], [NoOfApprovals], [ApproverLevel]) VALUES (101, 1002, N'G3_2', N'[{"User":"13"}]', 1, 3)
GO
INSERT [ApprovalRulesUsers] ([CID], [RuleID], [GroupID], [UserList], [NoOfApprovals], [ApproverLevel]) VALUES (101, 1002, N'G3_3', N'[{"User":"14"},{"User":"15"},{"User":"16"},{"User":"17"}]', 2, 3)
GO
INSERT [FormApproval] ([CID], [MenuID], [VouNo], [ApproverLevel], [RuleID], [Condition], [Status]) VALUES (101, N'ERP_157', N'DO/40526', 1, 1002, N'G1', 0)
GO
INSERT [FormApproval] ([CID], [MenuID], [VouNo], [ApproverLevel], [RuleID], [Condition], [Status]) VALUES (101, N'ERP_157', N'DO/40526', 2, 1002, N'G2', 1)
GO
INSERT [FormApproval] ([CID], [MenuID], [VouNo], [ApproverLevel], [RuleID], [Condition], [Status]) VALUES (101, N'ERP_157', N'DO/40526', 3, 1002, N'([G3_1] AND [G3_2]) OR [G3_3]', 1)
GO
INSERT [FormApproval] ([CID], [MenuID], [VouNo], [ApproverLevel], [RuleID], [Condition], [Status]) VALUES (101, N'ERP_176', N'31290', 1, 1001, N'G1', 0)
GO
INSERT [FormApproval] ([CID], [MenuID], [VouNo], [ApproverLevel], [RuleID], [Condition], [Status]) VALUES (101, N'ERP_176', N'31290', 2, 1001, N'G2', 0)
GO
INSERT [FormApproval] ([CID], [MenuID], [VouNo], [ApproverLevel], [RuleID], [Condition], [Status]) VALUES (101, N'ERP_176', N'31290', 3, 1001, N'(G3-1 and G3-2) or G3-3 ', 0)
GO
INSERT [FormApprovalSub] ([CID], [MenuID], [VouNo], [ApproverLevel], [RuleID], [ApprovedBy], [ApprovedDate], [ApprovedStatus]) VALUES (101, N'ERP_157', N'DO/40526', 3, 1002, 14, CAST(N'2020-12-09T16:30:11.783' AS DateTime), 1)
GO
INSERT [FormApprovalSub] ([CID], [MenuID], [VouNo], [ApproverLevel], [RuleID], [ApprovedBy], [ApprovedDate], [ApprovedStatus]) VALUES (101, N'ERP_157', N'DO/40526', 3, 1002, 13, CAST(N'2020-12-09T16:32:15.480' AS DateTime), 1)
GO
INSERT [FormApprovalSub] ([CID], [MenuID], [VouNo], [ApproverLevel], [RuleID], [ApprovedBy], [ApprovedDate], [ApprovedStatus]) VALUES (101, N'ERP_157', N'DO/40526', 3, 1002, 17, CAST(N'2020-12-09T16:34:49.023' AS DateTime), 1)
GO
INSERT [FormApprovalSub] ([CID], [MenuID], [VouNo], [ApproverLevel], [RuleID], [ApprovedBy], [ApprovedDate], [ApprovedStatus]) VALUES (101, N'ERP_157', N'DO/40526', 2, 1002, 4, CAST(N'2020-12-09T16:38:59.593' AS DateTime), 1)
GO
INSERT [FormApprovalSub] ([CID], [MenuID], [VouNo], [ApproverLevel], [RuleID], [ApprovedBy], [ApprovedDate], [ApprovedStatus]) VALUES (101, N'ERP_157', N'DO/40526', 2, 1002, 2, CAST(N'2020-12-09T16:37:55.053' AS DateTime), 1)
GO
ALTER TABLE [ApprovalRulesMaster] ADD  CONSTRAINT [DF_ApprovalRules_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [ApprovalRulesUsers] ADD  CONSTRAINT [DF_ApprovalRulesUsers_NoOfApprovals]  DEFAULT ((1)) FOR [NoOfApprovals]
GO
ALTER TABLE [FormApproval] ADD  CONSTRAINT [DF_FormApproval_CID]  DEFAULT ((101)) FOR [CID]
GO
ALTER TABLE [FormApproval] ADD  CONSTRAINT [DF_FormApproval_Status]  DEFAULT ((0)) FOR [Status]
GO
ALTER TABLE [FormApprovalSub] ADD  CONSTRAINT [DF_FormApprovalSub_CID]  DEFAULT ((101)) FOR [CID]
GO
ALTER TABLE [FormApprovalSub] ADD  CONSTRAINT [DF_Table_1_Status]  DEFAULT ((0)) FOR [ApprovedDate]
GO
ALTER TABLE [FormApprovalSub] ADD  CONSTRAINT [DF_FormApprovalSub_ApprovedStatus]  DEFAULT ((0)) FOR [ApprovedStatus]
GO
