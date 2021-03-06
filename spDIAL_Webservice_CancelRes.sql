USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Webservice_CancelRes]    Script Date: 04/05/2018 09:41:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER procedure [dbo].[spDIAL_Webservice_CancelRes]
@RemedyEntryID bigint,
@EmailAddress varchar(500) = '',
@ClientIp varchar(100) = '',
@ICCEmailAddress varchar(200) = '',
@WS_User varchar(100) = '',
@FinalAuth varchar(1) = '',
@InsCompanyID varchar(20)  = '',
@MontrealEmailAddress varchar(200) = ''
as

	Declare @Subject varchar(200)
	Declare @EmailBody varchar(8000)
	Declare @DebitorName varchar(300)
	
	SELECT @DebitorName = isnull(ltrim(rtrim(DEBITOR_NAME)), '') FROM DEBITORS (NOLOCK) WHERE DEBITOR_CODE = (SELECT dac_ins_company_id from DA_CLAIMS (nolock) where DAC_ENTRY_ID = @RemedyEntryID)
 
	set @Subject = 'Reservation Cancellation submitted by '+ @DebitorName +' (webservice) : '+ cast(cast(@RemedyEntryID as bigint) as varchar(10))
	
	set @EmailBody = '<font face=''verdana'' size=''2''>A new Reservation Cancellation was submitted BY '+ @DebitorName +' through the Discount Webservice.<br><br>' 
				+ 'Entry ID: '+ cast(cast(@RemedyEntryID as bigint) as varchar(10))+ '<br><br>' 						

	if @ICCEmailAddress != ''	
		set @EmailAddress = @ICCEmailAddress 
	else
		set @EmailAddress = 'lrao@discountcar.com;dgiordmaina@discountcar.com;spatel@discountcar.com'
		
	if @InsCompanyID = 'OTT15'	
	begin
		set @Subject = 'Reservation Cancellation submitted by '+ @DebitorName +' (webservice) for Montreal office : '+ cast(cast(@RemedyEntryID as bigint) as varchar(10)) + ' - ' +  @InsCompanyID		
		set @EmailAddress = @EmailAddress + ';' + @MontrealEmailAddress
	end
	
	declare @AgreementNo bigint	
	select @AgreementNo = DAC_AGREEMENT_NUMBER from OntarioLive..DA_CLAIMS where DAC_ENTRY_ID = @RemedyEntryID	
	
	if @AgreementNo = 0 
	begin
		update OntarioLive..DA_CLAIMS set DAC_STATUS = 5 where DAC_ENTRY_ID = @RemedyEntryID		
	end	

	EXEC msdb..sp_send_dbmail @profile_name='Altbill',
	@recipients=@EmailAddress,
	@from_address  = 'iccinternal@discountcar.com',
	@subject=@Subject,
	@body=@EmailBody,
	@body_format = 'HTML'

	insert into carpro_app.dbo.sendemailqueue 
	(dbname, emailaddress, emailsubject, emailbody, emailformat, entryuser, entrytime, EmailfromAddress, EmailSentTime) 
	values
	('REMEDY-WEBSERVICE', @EmailAddress, @Subject, @EmailBody, 'HTML', @WS_User, getdate(), 'norely@discountcar.com', getdate())

	insert into tblDIAL_UsersLog (Adjuster_Username, ip_address, flag, Process_Code, entry_id) 
	values (@WS_User, '100.100.100.100', 1, 15, @RemedyEntryID)
	
	



