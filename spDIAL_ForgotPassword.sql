USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_ForgotPassword]    Script Date: 04/05/2018 09:35:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--grant exec on [spDIAL_ForgotPassword] to crystal

-- exec [spDIAL_ForgotPassword] @Email = 'BLMACART@travelers.com'

ALTER Proc [dbo].[spDIAL_ForgotPassword]
@Email varchar(250),
@ipAddress varchar(15) = '127.0.0.1'
as
begin

	declare @Message varchar(100), @Error int

	if exists
	(
		select DAA_FIRST_NAME, DAA_LAST_NAME, DAA_EMAIL, e.EMPLOYEE_ID from DA_ADJUSTER a
		inner join EMPLOYEES e on a.EMPLOYEE_ID = e.TUSR
		where DAA_EMAIL = @Email
	)
	begin
		declare @EmailBody varchar(2000), @Subject varchar(250), @Name varchar(250), @UserID varchar(100), @Password varchar(100)
		
		select @Name = DAA_FIRST_NAME + ' ' + DAA_LAST_NAME, @UserID = a.EMPLOYEE_ID, @Password = e.EMP_PASSWORD 
		from DA_ADJUSTER a
		inner join EMPLOYEES e on a.EMPLOYEE_ID = e.TUSR
		where DAA_EMAIL = @Email
		
		
		select @Subject = 'DIAL Insurance Password Recovery Details'
    
		select @EmailBody = '<font face=''verdana'' size=''2''><br><br> ' 		
						
			+ '-------------------------------------------------------<br><br>'			
			+ 'UserName' + ' - ' +  isnull(@UserID, '') + ' <br><br>'			
			+ 'Password' + ' - ' +  isnull(@Password, '') + ' <br><br><br><br>'
			+ 'Website URL' + 'http://ins.mydiscountdial.com' + ' <br><br>'			
			+ '-------------------------------------------------------<br><br>'			
			
    
		insert into Carpro_App.dbo.sendemailqueue 
		(dbname, emailaddress, emailsubject, emailbody, emailformat, entryuser, entrytime, EmailfromAddress) 
		values
		('DIAL30', @Email, @Subject, @EmailBody, 'HTML', @Email, getdate(), @Name + ' <' + @Email + '>')
		
		select @Error = 0
	end
	else		
	begin
		select @Error = 1
		
		select @Message = 'Email address is not found in our system. Please contact DIALSupport@discountcar.com for further assistance. Thank you'
	end
		
	insert into tblDIAL_UsersLog (Adjuster_Username, ip_address, flag, Process_Code) 
	values (@Email, @ipAddress, @Error, 0)
	
end	
	
