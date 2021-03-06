USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Acknowledge_ForRewrite]    Script Date: 04/05/2018 09:32:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- exec [dbo].[spDIAL_Acknowledge_ForRewrite] @AgreementNo = 3530017941, @invoiceNo = '', @Acknowledge = '', @Dispute = '', @DisputeText = '', @IsDominion = 'N', @IP_ADDRESS = '150.8.0.70', @AdjusterID = 17724, @EntryID = null
-- exec [dbo].[spDIAL_Acknowledge_ForRewrite] @AgreementNo = 1720008269, @invoiceNo = 1720004842, @Acknowledge = 'N', @Dispute = 'Y', @DisputeText = 'Dispute test for rewrite 2175635-12002-2', @IsDominion = 'Y', @IP_ADDRESS = '150.8.0.70', @AdjusterID = 17724, @EntryID = 3098534

 
ALTER Proc [dbo].[spDIAL_Acknowledge_ForRewrite]
@AgreementNo bigint,@invoiceNo bigint, @Acknowledge char(1) = '', 
@Dispute char(1) = '', @DisputeText varchar(300) = '', @IsDominion char(1) = 'N', @IP_ADDRESS VARCHAR(20), 
@AdjusterID bigint = 17724, @EntryID bigint

as

Declare @RecordExist varchar(2) 
declare @AdjusterUserName varchar(10)
DECLARE @Debitor_Code BIGINT, @InternalEmailAddress VARCHAR(200)

SELECT @AdjusterUserName = EMPLOYEE_ID FROM DA_ADJUSTER (nolock) 
WHERE DAA_ENTRY_ID = (SELECT DAC_COMPANY_ADJUSTER_ID from DA_CLAIMS (nolock) where DAC_ENTRY_ID=@EntryID)

SELECT @Debitor_Code = DAC_INS_COMPANY_ID from DA_CLAIMS (nolock) where DAC_ENTRY_ID=@EntryID

select @InternalEmailAddress =  dial_pal_email_id from DEBITORS D (nolock) where DEBITOR_CODE=@Debitor_Code			
set @InternalEmailAddress = @InternalEmailAddress + ';dialsupport@discountcar.com' + ';DIALDISPUTE@discountcar.com'	

begin
	if exists(select TOP 1 agreement_no from dbo.AGREEMENTS (nolock) where AGREEMENT_NO=@AgreementNo)
	  SET @RecordExist = 'ON'
	else if exists (select TOP 1 agreement_no from AlbertaLive.dbo.AGREEMENTS (nolock) where AGREEMENT_NO=@AgreementNo)
	  SET @RecordExist = 'AB'
	else if exists (select TOP 1 agreement_no from StCatharines.dbo.AGREEMENTS (nolock) where AGREEMENT_NO=@AgreementNo)
	  SET @RecordExist = 'ST'
	else if exists (select TOP 1 agreement_no from SaskatchewanLive.dbo.AGREEMENTS (nolock) where AGREEMENT_NO=@AgreementNo)
	  SET @RecordExist = 'SA'
	else if exists (select TOP 1 agreement_no from MaritimesLive.dbo.AGREEMENTS (nolock) where AGREEMENT_NO=@AgreementNo)
	  SET @RecordExist = 'MT'
	else if exists (select TOP 1 agreement_no from BcLive.dbo.AGREEMENTS (nolock) where AGREEMENT_NO=@AgreementNo)
	  SET @RecordExist = 'BC'  
	else if exists (select TOP 1 agreement_no from NewfoundlandLive.dbo.AGREEMENTS (nolock) where AGREEMENT_NO=@AgreementNo)
	  SET @RecordExist = 'NL'  
	  
	 
end

if @Acknowledge = 'Y'
begin
	if @RecordExist ='ON'
	  update dbo.INVOICES set ACKNOWLEDGE=@Acknowledge where INVOICE_NO=@invoiceNo 
	else if @RecordExist= 'AB'
	  update AlbertaLive.dbo.INVOICES set ACKNOWLEDGE=@Acknowledge where INVOICE_NO=@invoiceNo
	else if @RecordExist = 'ST'
	  update StCatharines.dbo.INVOICES set ACKNOWLEDGE=@Acknowledge where INVOICE_NO=@invoiceNo
	else if @RecordExist ='SA'
	  update SaskatchewanLive.dbo.INVOICES set ACKNOWLEDGE=@Acknowledge where INVOICE_NO=@invoiceNo	
	else if @RecordExist ='MT'
	  update MaritimesLive.dbo.INVOICES set ACKNOWLEDGE=@Acknowledge where INVOICE_NO=@invoiceNo	
	else if @RecordExist ='BC'
	  update BcLive.dbo.INVOICES set ACKNOWLEDGE=@Acknowledge where INVOICE_NO=@invoiceNo	  
	else if @RecordExist ='NL'
	  update NewfoundlandLive.dbo.INVOICES set ACKNOWLEDGE=@Acknowledge where INVOICE_NO=@invoiceNo	  
end

if @Dispute = 'Y'
begin	
	if @RecordExist ='ON'
	  update dbo.INVOICES set DISPUTE=@Dispute where INVOICE_NO=@invoiceNo
	else if @RecordExist= 'AB'
	  update AlbertaLive.dbo.INVOICES set DISPUTE=@Dispute where INVOICE_NO=@invoiceNo
	else if @RecordExist = 'ST'
	  update StCatharines.dbo.INVOICES set DISPUTE=@Dispute where INVOICE_NO=@invoiceNo
	else if @RecordExist ='SA'
	  update SaskatchewanLive.dbo.INVOICES set DISPUTE=@Dispute where INVOICE_NO=@invoiceNo		
	else if @RecordExist ='MT'
	  update MaritimesLive.dbo.INVOICES set DISPUTE=@Dispute where INVOICE_NO=@invoiceNo		
	else if @RecordExist ='BC'
	  update BcLive.dbo.INVOICES set DISPUTE=@Dispute where INVOICE_NO=@invoiceNo		
	else if @RecordExist ='NL'
	  update NewfoundlandLive.dbo.INVOICES set DISPUTE=@Dispute where INVOICE_NO=@invoiceNo		
end

if @Dispute = 'Y' and @DisputeText != ''
begin
--Declare @DisputeEmailAddress varchar(200)
--set @DisputeEmailAddress = (SELECT top 1 Email_address FROM dbo.tblDIAL_EmailList (nolock)	
--WHERE [Description] = 'Dispute')

insert into carpro_app.dbo.sendemailqueue 
(dbname, emailaddress, emailsubject, emailbody, emailformat, entryuser, entrytime,  EmailfromAddress) 
values
('DIAL3.0', @InternalEmailAddress, 'DISPUTE for AgreementNo '+ convert(varchar(15), @AgreementNo) + '  EntryID '+ convert(varchar(15), @EntryID), @disputetext, 'HTML', @AdjusterID, getdate(), 'noreply@DISCOUNTCAR.COM')
end



if @IsDominion = 'Y' and @Acknowledge = 'Y'
begin
	if not exists(select * from tblDIAL_Zip_ftp where entry_id=@EntryID and agreement_no = @AgreementNo)
	INSERT INTO tblDIAL_Zip_ftp (entry_id, agreement_no, entry_user, entry_date, iswrite, province) VALUES (@EntryID, @AgreementNo , 'DIAL 3.0', getdate(), 'Y', @RecordExist)
end

if @Acknowledge = 'Y' and @IsDominion != 'Y'
begin
	if exists(select remedy_entry_id from tblWS_Insurance_Logs where remedy_entry_id>0 and status='Successful' and isQuebec=0 and remedy_entry_id = @EntryID and requestid != '')
	begin		
		
		if @RecordExist ='ON'
		  select @AgreementNo = agreement_no from ontariolive..INVOICES (nolock) where INVOICE_NO = @invoiceNo
		else if @RecordExist= 'AB'
		  select @AgreementNo = agreement_no from AlbertaLive..INVOICES (nolock) where INVOICE_NO = @invoiceNo
		else if @RecordExist = 'ST'
		  select @AgreementNo = agreement_no from StCatharines..INVOICES (nolock) where INVOICE_NO = @invoiceNo
		else if @RecordExist ='SA'
		  select @AgreementNo = agreement_no from SaskatchewanLive..INVOICES (nolock) where INVOICE_NO = @invoiceNo
		else if @RecordExist ='MT'
		  select @AgreementNo = agreement_no from MaritimesLive..INVOICES (nolock) where INVOICE_NO = @invoiceNo
		else if @RecordExist ='BC'
		  select @AgreementNo = agreement_no from BCLive..INVOICES (nolock) where INVOICE_NO = @invoiceNo
		else if @RecordExist ='NL'
		  select @AgreementNo = agreement_no from NewfoundlandLive..INVOICES (nolock) where INVOICE_NO = @invoiceNo
		  
		if not exists(select * from tblDIAL_intact_Zip_ftp where entry_id=@EntryID)		
			INSERT INTO tblDIAL_intact_Zip_ftp (entry_id, entry_user, entry_date, Agreement_No, invoice_no, isfranchise, requestid, province) 
			VALUES (@EntryID, 'DIAL 3.0', getdate(), @AgreementNo, @invoiceNo, 0, (select requestid from tblWS_Insurance_Logs where remedy_entry_id = @EntryID), @RecordExist )	
	end
end


declare @myNoteIDAuth bigint	
declare @myMessage varchar(100)
	
if @Acknowledge = 'Y'
	select @myMessage ='Invoice Acknowledged'
		
if @Dispute = 'Y'
	select @myMessage ='Invoice Disputed : Reason- '+ @DisputeText
	
	declare @ReallyAcknowledged varchar(1)
	
	if  @Acknowledge = 'Y'
	begin
		if @RecordExist ='ON'
		  select @ReallyAcknowledged = ltrim(rtrim(ACKNOWLEDGE))  from OntarioLive.dbo.INVOICES where INVOICE_NO=@invoiceNo 
		else if @RecordExist= 'AB'
		  select @ReallyAcknowledged = ltrim(rtrim(ACKNOWLEDGE))  from AlbertaLive.dbo.INVOICES where INVOICE_NO=@invoiceNo 
		else if @RecordExist = 'ST'
		  select @ReallyAcknowledged = ltrim(rtrim(ACKNOWLEDGE))  from StCatharines.dbo.INVOICES where INVOICE_NO=@invoiceNo 
		else if @RecordExist ='SA'
		  select @ReallyAcknowledged = ltrim(rtrim(ACKNOWLEDGE))  from SaskatchewanLive.dbo.INVOICES where INVOICE_NO=@invoiceNo 
		else if @RecordExist ='MT'
		  select @ReallyAcknowledged = ltrim(rtrim(ACKNOWLEDGE))  from MaritimesLive.dbo.INVOICES where INVOICE_NO=@invoiceNo 
		else if @RecordExist ='BC'
		  select @ReallyAcknowledged = ltrim(rtrim(ACKNOWLEDGE))  from BCLive.dbo.INVOICES where INVOICE_NO=@invoiceNo 
		else if @RecordExist ='NL'
		  select @ReallyAcknowledged = ltrim(rtrim(ACKNOWLEDGE))  from NewfoundlandLive.dbo.INVOICES where INVOICE_NO=@invoiceNo 
	end
	
	
if isnull(@ReallyAcknowledged, '') = 'Y' or @Dispute = 'Y'		
begin	
	select @myNoteIDAuth = max(DCN_ID) + 1 from DA_NOTES_HISTORY(nolock) 
	if not exists 
		(select DCN_ID from DA_NOTES_HISTORY (nolock) where DCN_ID=@myNoteIDAuth) and @myNoteIDAuth is not null
	begin try
		Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
		Values(@myNoteIDAuth, @EntryID,@myMessage,1,@AdjusterUserName,CONVERT(varchar(8), getdate(),112), 
		DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')	
	end try
	
	begin catch
		Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
		Values(@myNoteIDAuth+1, @EntryID,@myMessage,1,@AdjusterUserName,CONVERT(varchar(8), getdate(),112), 
		DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')	
	end catch


	select @myNoteIDAuth = max(DCN_ID) + 1 from DA_NOTES_HISTORY(nolock) 
	if not exists 
		(select DCN_ID from DA_NOTES_HISTORY (nolock) where DCN_ID=@myNoteIDAuth) and @myNoteIDAuth is not null
	begin try
		Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
		Values(@myNoteIDAuth, @EntryID,@myMessage,3,@AdjusterUserName,CONVERT(varchar(8), getdate(),112), 
		DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')	
	end try
	
	begin catch
		Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
		Values(@myNoteIDAuth+1, @EntryID,@myMessage,3,@AdjusterUserName,CONVERT(varchar(8), getdate(),112), 
		DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')	
	end catch
	
	insert into tblDIAL_UsersLog (Adjuster_Username, ip_address, flag, Process_Code, entry_id) 
	values (@AdjusterUserName, @IP_ADDRESS, 1, case when @Acknowledge = 'Y' then 4  when @Dispute = 'Y' then 5 end, @EntryID)
end

--select * from carpro_app.dbo.sendemailqueue




	






