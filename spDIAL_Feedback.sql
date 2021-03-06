USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Feedback]    Script Date: 04/05/2018 09:35:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [spDIAL_Feedback] @Feedback='TEST by Lakshmi', @AdjusterID = 17724

ALTER Proc [dbo].[spDIAL_Feedback] 
@AdjusterID bigint, @Feedback varchar(1000)
as

declare @Email_Address varchar(200), @EmailBody varchar(1000)
DECLARE @AdjusterName varchar(200), @DebitorName varchar(200), @ADJUSTEREmail varchar(500)

select @AdjusterName = DAA_FIRST_NAME + ' ' + DAA_LAST_NAME,  @DebitorName = d.DEBITOR_NAME , 
@ADJUSTEREmail = isnull(DAA_EMAIL, 'noreply@discountcar.com') from DA_ADJUSTER  a (nolock)
left join DEBITORS d (nolock) on a.DEBITOR_CODE = d.DEBITOR_CODE where DAA_ENTRY_ID=@AdjusterID

if exists (SELECT Email_address FROM dbo.tblDIAL_EmailList (nolock)	
	WHERE [Description] = 'Feedback')
	set @Email_Address = (SELECT top 1 Email_address FROM dbo.tblDIAL_EmailList (nolock)	
	WHERE [Description] = 'Feedback')
else
	set @Email_Address = 'dialsupport@discountcar.com'
		
insert into tblDIAL_Feedback 
(Comments,Adjuster_Id, EntryDate) 
values
(@Feedback, @AdjusterID, GETDATE())

if @ADJUSTEREmail = '' 
  set @ADJUSTEREmail = 'noreply@discountcar.com'


set @EmailBody = '<font face=''verdana'' size=''2''>Adjuster Name : ' + isnull(@AdjusterName, '') + '<br><br>Parent Company Name : ' + isnull(@DebitorName, '') + '<br><br>Feedback : ' + isnull(@Feedback, '') +'</font>' 

insert into carpro_app.dbo.sendemailqueue 
(dbname, emailaddress, emailsubject, emailbody, emailformat, entryuser, entrytime, EmailfromAddress) 
values
('DIAL3.0', @Email_Address, 'Feedback from DIAL3.0', @EmailBody, 'HTML', @AdjusterID, getdate(), @ADJUSTEREmail)

--select * from carpro_app.dbo.sendemailqueue where emailsubject='Feedback from DIAL3.0' order by ID desc


-- select * from tblDIAL_Feedback order by id desc


