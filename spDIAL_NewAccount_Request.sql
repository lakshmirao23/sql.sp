USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_NewAccount_Request]    Script Date: 04/05/2018 09:39:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [spDIAL_NewAccount_Request] @FirstName='Lux', @LastName = 'L', @Email = 'lakshmi.rao23@gmail.com', @phone='6474478545', @AdjusterID = 17724, @debitorcode=16497

ALTER Proc [dbo].[spDIAL_NewAccount_Request] 
@FirstName varchar(30), @LastName varchar(30), @Email varchar(200), 
@Phone varchar(20), @AdjusterID bigint, @DebitorCode bigint
as
declare @Email_Address varchar(200), @EmailBody varchar(400)
DECLARE @AdjusterName varchar(200), @DebitorName varchar(200)

select @AdjusterName = DAA_FIRST_NAME + ' ' + DAA_LAST_NAME,  @DebitorName = d.DEBITOR_NAME  from DA_ADJUSTER  a (nolock)
left join DEBITORS d (nolock) on a.DEBITOR_CODE = d.DEBITOR_CODE where DAA_ENTRY_ID=@AdjusterID

if exists (SELECT Email_address FROM dbo.tblDIAL_EmailList (nolock)	
	WHERE [Description] = 'New Account Request Page')
	set @Email_Address = (SELECT top 1 Email_address FROM dbo.tblDIAL_EmailList (nolock)	
	WHERE [Description] = 'New Account Request Page')
else
	set @Email_Address = 'dialsupport@discountcar.com'

set @EmailBody = '<font face=''verdana'' size=''2''>Adjuster Name : ' + @AdjusterName + '<br><br>Parent Company Name : ' + @DebitorName + '<br><br>First Name :' + @FirstName + '<br>Last Name :' + @LastName + '<br>Email :' + @Email + '<br>Phone :' + @Phone + '</font>'
		
insert into tblDIAL_New_Acct 
(First_name, last_name, email_address, phone, entry_by, debitor_code) 
values
(@FirstName, @LastName, @Email, @Phone, @AdjusterID, @DebitorCode)

--insert into carpro_app.dbo.sendemailqueue 
--(dbname, emailaddress, emailsubject, emailbody, emailformat, entryuser, entrytime) 
--values
--('DIAL', @Email_Address, 'NEW ACCOUNT REQUEST', @EmailBody, 'HTML', @AdjusterID, getdate())

insert into carpro_app.dbo.sendemailqueue 
(dbname, emailaddress, emailsubject, emailbody, emailformat, entryuser, entrytime, EmailfromAddress) 
values
('DIAL3.0', @Email_Address, 'New Account Request from DIAL3.0', @EmailBody, 'HTML', @AdjusterID, getdate(), 'noreply@discountcar.com')



	