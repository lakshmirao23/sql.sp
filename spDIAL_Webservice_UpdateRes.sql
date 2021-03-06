USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Webservice_UpdateRes]    Script Date: 04/05/2018 09:41:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- exec [spDIAL_Webservice_UpdateRes]

ALTER PROCEDURE [dbo].[spDIAL_Webservice_UpdateRes] 	
@RemedyEntryID bigint = 3276565       , 
@AdjusterID bigint = 32482 ,  
@RentalControlledBy varchar(30) = 'Rental Desk', 
@GarageName varchar(200) = '', 
@GarageAddress varchar(300) = '',
@GaragePhone varchar(20) = '',
@GarageCity varchar(50) = '', 
@GaragePostalCode varchar(30) = '', 
@TotalLoss varchar(1) = 'N', 
@ClaimType int = 0,
@PolicyMax decimal (18, 2) = 0.00,
@UpgradeRequested int = 0, 
@ClientIp varchar(100) = '',
@WS_User varchar(100) = 'Economical_WS', 
@ICCEmailAddress varchar(600) = '',
@InsCompanyID varchar(20)  = '4001',
@MontrealEmailAddress varchar(200) = ''

AS

BEGIN	

	SET NOCOUNT ON;	
	declare @LoggedInUserName varchar(100) = 'Supervisor'
	
	Declare @ModyorCreatedDate varchar(8), @ModyorCreateTime int
	Declare @Subject varchar(300)
	Declare @EmailBody varchar(8000)
	Declare @DebitorName varchar(300)
	Declare @EmailAddress varchar(600)
		
	set @ModyorCreatedDate = CONVERT(varchar(8), GETDATE(), 112)
	set @ModyorCreateTime = DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate())	
	
	--if @InsCompanyID != 'OTT15'		
	BEGIN
		UPDATE DA_CLAIMS SET  
		DAC_SUBMITTER = @LoggedInUserName ,	
		DAC_MODIFIED_DATE = @ModyorCreatedDate ,
		DAC_MODIFIED_TIME = @ModyorCreateTime ,
		DAC_LAST_MODIFIED_BY = @LoggedInUserName ,
		DAC_UPGRADE_REQUESTED = isnull(@UpgradeRequested, ''),		
		DAC_RENTAL_CONTROLLED_BY = isnull(@RentalControlledBy , ''),
		DAC_MAX_ALLOW = isnull(@PolicyMax, 0),		
		DAC_TOTAL_LOSS = isnull(@TotalLoss, ''),
		DAC_CLAIM_TYPE = isnull(@ClaimType, 0),	
		DAC_GARAGE_NAME = isnull(@GarageName, ''),
		DAC_GARAGE_ADDRESS = isnull(@GarageAddress, ''),
		DAC_GARAGE_PHONE = isnull(@GaragePhone, ''),
		DAC_GARAGE_CITY = isnull(@GarageCity, ''),	
		DAC_GARAGE_POSTAL_CODE = isnull(@GaragePostalCode, '')	,
		DAC_REFERRAL_METHOD_ID =5		
		WHERE DAC_ENTRY_ID = @RemedyEntryId		
	END
	
	SELECT @DebitorName = isnull(ltrim(rtrim(DEBITOR_NAME)), ''),  @EmailAddress = dial_pal_email_id FROM DEBITORS (NOLOCK) 
	WHERE DEBITOR_CODE = (SELECT dac_ins_company_id from DA_CLAIMS (nolock) where DAC_ENTRY_ID=@RemedyEntryID)	
	
	if isnull(@DebitorName, '') = '' and @WS_User = 'ECONOMICAL_WS'
		set @DebitorName  = 'ECONOMICAL INSURANCE'
	
	
	Declare @PolicyNo varchar(30), @ClaimNo varchar(30) = '', @AdjusterFirstName varchar(200), @AdjusterLastName varchar(200), @Insured_FirstName varchar(200), @Insured_LastName varchar(200), 
	@Authorizedrate decimal(18,2) = 0.00, @TelePhoneNo varchar(20), @AlternatePhone varchar(20), @sTextCellNumber varchar(20),  @AuthNotes varchar(500), @LocAddress varchar(300), @LocPhone varchar(20),
	@Transferable_Coverage varchar(20), @TaxPaidByDesc varchar(100)	
	
	select @PolicyNo = DAC_POLICY, @ClaimNo = DAC_INS_CLAIM , @AdjusterFirstName = DAC_COMPANY_ADJ_FIRST_NAME , @AdjusterLastName = DAC_COMPANY_ADJ_LAST_NAME , @Insured_FirstName = DAC_INSURED_FIRST_NAME , 
	@Insured_LastName = DAC_INSURED_NAME, @Authorizedrate = DAC_AUTHORIZED_RATE , @TelePhoneNo = DAC_CLIENT_PHONE , @AlternatePhone = DAC_CLIENT_BUS , @sTextCellNumber = DAC_CUST_ALT_PHONE ,
	@LocAddress = DAC_LOCATION_ADDRESS, @LocPhone = DAC_LOCATION_PHONE
	from da_claims (nolock) where DAC_ENTRY_ID=@RemedyEntryID
	
	declare @ClaimTypeDesc varchar(100)
	declare @UpgradeRequesteddesc varchar(100)
	
	if @ClaimType = 0
		set @ClaimTypeDesc = 'Collision'
	else if @ClaimType = 1
		set @ClaimTypeDesc = 'Comprehension'
	else if @ClaimType = 2
		set @ClaimTypeDesc = 'Theft'			
	
	if @UpgradeRequested = 1
		set @UpgradeRequesteddesc = 'Yes'
	else if @UpgradeRequested = 0
		set @UpgradeRequesteddesc = 'No'		
	
	set @EmailBody = '<font face=''verdana'' size=''2''>An update to a reservation was submitted by '+ isnull(@DebitorName, '') +' through the Discount Webservice.<br><br>' 
			+ 'EntryID: '+ cast(cast(@RemedyEntryID as bigint) as varchar(10))+ '<br><br>' 
			+ 'Policy number:' + isnull(@PolicyNo, '') + '<br><br>'
			+ 'Claim number: ' + isnull(@ClaimNo, '') + '<br><br>' 
			+ 'Repair location: ' + ISNULL(@GarageName, '') + '<br><br>'
			+ 'Repair location phone: ' + ISNULL(@GaragePhone, '') + '<br><br>'
			+ 'Repair location address: ' + ISNULL(@GarageAddress, '') + '<br><br>'
			+ 'Repair location postal code: ' + ISNULL(@GaragePostalCode, '') + '<br><br>'	
			+ 'Total loss: ' + isnull(convert(varchar(20), @TotalLoss), '')	+ '<br><br>' 
			+ 'Claim type: ' + isnull(@ClaimTypeDesc, '') + '<br><br>' 			
			+ 'Policy max: ' + isnull(convert(varchar(20), @PolicyMax), '')	+ '<br><br>' 
			+ 'Rental controlled by: ' + ISNULL(@RentalControlledBy, '') + '<br><br>'		
			+ 'Upgrade requested: '+ ISNULL(@UpgradeRequesteddesc, '')
			+ '</font>'	  	  	  
	
set @Subject = 'Update submitted by '+ isnull(@DebitorName, '') +' (webservice) : '+ cast(cast(@RemedyEntryID as bigint) as varchar(10))

if @ICCEmailAddress != ''	
	set @EmailAddress = @ICCEmailAddress + ';dgiordmaina@discountcar.com'
else
	set @EmailAddress = 'spatel@discountcar.com;lrao@discountcar.com; dgiordmaina@discountcar.com'
	
if @InsCompanyID = 'OTT15'	
begin
	set @Subject = 'Update submitted by '+ @DebitorName +' (webservice) for Montreal : '+ cast(cast(@RemedyEntryID as bigint) as varchar(10)) + '-' + @InsCompanyID
	set @EmailAddress = @EmailAddress + ';' + @MontrealEmailAddress	
end
	
--select @EmailAddress 
--select @Subject
--select @EmailBody
	
EXEC msdb..sp_send_dbmail @profile_name='Altbill',
@recipients=@EmailAddress,
@from_address  = 'iccinternal@discountcar.com',
@subject=@Subject,
@body=@EmailBody,
@body_format = 'HTML'

insert into carpro_app.dbo.sendemailqueue 
(dbname, emailaddress, emailsubject, emailbody, emailformat, entryuser, entrytime, EmailfromAddress, EmailSentTime) 
values
('REMEDY-WEBSERVICE', @EmailAddress, @Subject, @EmailBody, 'HTML', @WS_User, getdate(), 'noreply@discountcar.com', getdate())

insert into tblDIAL_UsersLog (Adjuster_Username, ip_address, flag, Process_Code, entry_id) 
values (@WS_User, '100.100.100.100', 1, 16, @RemedyEntryID)
	
	
END
	
	
   
















