USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_SendEmail]    Script Date: 04/05/2018 09:40:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [spDIAL_SendEmail] 

ALTER Proc [dbo].[spDIAL_SendEmail] 
@AdjusterID bigint = 17724, 
@Email_Address varchar(300) = 'lrao@discountcar.com', 
@EntryID bigint = 3163058
as
Declare @Subject varchar(200)
Declare @EmailBody varchar(600)
declare @CustomerName varchar(200)
declare @CompanyName varchar(200)
declare @LocAddress varchar(300), @LocCode bigint, @LocPhoneNo varchar(20)

select @CustomerName = DAC_CLIENT_FIRST_NAME from DA_CLAIMS (nolock) where DAC_ENTRY_ID = @EntryID
select @CompanyName = debitor_name from DA_CLAIMS c (nolock) left join DEBITORS d (nolock) on d.DEBITOR_CODE = c.DAC_INS_COMPANY_ID where DAC_ENTRY_ID = @EntryID
select @LocCode = dac_location_code from DA_CLAIMS (nolock) where DAC_ENTRY_ID = @EntryID
	
if @LocCode > 0 
	begin
	  select @LocAddress = ltrim(rtrim(street)) + ', ' + ltrim(rtrim(city)) + ', ' + ltrim(rtrim(postal_no)) from BRANCHES (nolock) where BRANACH_CODE = @LocCode
	  select @LocPhoneNo = ltrim(rtrim(telephone1)) from BRANCHES (nolock) where BRANACH_CODE = @LocCode	  
	  set @EmailBody = '<font face=''verdana'' face=''2''>Hello ' + @CustomerName + '<br><br>' + 'Your Claims adjuster has arranged a rental vehicle for you with Discount Car and Truck Rentals.' + '<br><br>' + 'Your Reference # '+ cast(cast(@EntryID as bigint) as varchar(10)) + '<br><br>' + 'Discount Location: '+ @LocAddress + '<br><br>Discount Location Phone #:' + @LocPhoneNo + '<br><br>' + 'You will be contacted shortly by one of our friendly agents.' + '<br><br>' + 'If you have any questions, you may reach us at 1-800-404-4142</font>'	  	  	  
	end
else if @LocCode = 0
	begin
    	set @EmailBody = '<font face=''verdana'' face=''2''>Hello ' + @CustomerName + '<br><br>' + 'Your Claims adjuster has arranged a rental vehicle for you with Discount Car and Truck Rentals.' + '<br><br>' + 'Your Reference # '+ cast(cast(@EntryID as bigint) as varchar(10)) + '<br><br>' + 'You will be contacted shortly by one of our friendly agents.' + '<br><br>' + 'If you have any questions, you may reach us at 1-800-404-4142</font>'	  	  	  
	end	

set @Subject = 'Discount Rental Reference # '+ cast(cast(@EntryID as bigint) as varchar(10)) 

	EXEC msdb..sp_send_dbmail @profile_name='AltBill',
                              @recipients = @Email_Address,
                              --@recipients = 'lrao@discountcar.com',
                              @blind_copy_recipients ='dialsupport@discountcar.com', 
                              @from_address  =  'noreply@discountcar.com',
                              @subject=@Subject,                             
                              @body=@EmailBody,
                              @body_format = 'html'

			insert into Carpro_App.dbo.[SendEmailQueue](
				  [dbName]
				  ,[EmailAddress]
				  ,[EmailfromAddress]
				  ,[EmailSubject]
				  ,[EmailBody]   
				  ,EmailFormat
				  ,[EntryTime]
				  ,[EntryUser], EmailSentTime)
			Values ('DIAL3.0', @Email_Address+';dialsupport@discountcar.com','noreply@discountcar.com',@Subject, @EmailBody ,'html', getdate(),'DIAL3.0', GETDATE())

--insert into carpro_app.dbo.sendemailqueue 
--(dbname, emailaddress, emailsubject, emailbody, emailformat, entryuser, entrytime, EmailfromAddress) 
--values
--('DIAL3.0', @Email_Address, @Subject, '<font face=''verdana'' face=''2''>'+@EmailBody+'</font>', 'HTML', @AdjusterID, getdate(), 'noreply@discountcar.com')

-- select * from carpro_app.dbo.sendemailqueue order by 1 desc


