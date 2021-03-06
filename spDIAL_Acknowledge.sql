USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Acknowledge]    Script Date: 04/05/2018 09:32:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



--CORP TEST exec [spDIAL_Acknowledge] @EntryID=3131942, @invoiceNo=2010009537, @Acknowledge='Y', @IsDominion = 'Y'
--CORP TEST exec [spDIAL_Acknowledge] @EntryID=3131942, @invoiceNo=2010009537, @Dispute='Y', @DisputeText='Lakshmi Testing'

--FRANCHISEE TEST exec [spDIAL_Acknowledge] @EntryID=3138725, @invoiceNo=3138725, @Acknowledge='Y'
--FRANCHISEE TEST exec [spDIAL_Acknowledge] @EntryID=3138725, @invoiceNo=3138725, @Dispute='Y'

 -- CORPORATE TEST  SELECT ACKNOWLEDGE, DISPUTE FROM INVOICES WHERE INVOICE_NO=2010009537
 --FRANCHISEE TEST    SELECT ACKNOWLEDGE, DISPUTE FROM EBILLING_INVOICE_DATA WHERE ENTRY_ID = 3138725
 -- UPDATE INVOICES SET ACKNOWLEDGE='N',  DISPUTE='N' WHERE INVOICE_NO=2010009537
 -- UPDATE EBILLING_INVOICE_DATA SET DISPUTE='N', ACKNOWLEDGE='N' WHERE ENTRY_ID=3138725
 
 
 -- exec [spDIAL_Acknowledge] @EntryID=3254507, @invoiceNo=3050010819, @Acknowledge='Y', @IsDominion = 'N'
 
ALTER Proc [dbo].[spDIAL_Acknowledge]
@EntryID bigint, @invoiceNo bigint, @Acknowledge char(1) = '', 
@Dispute char(1) = '', @DisputeText varchar(300) = '', @IsDominion char(1) = 'N', @ClientIP varchar(100) = ''

as

Declare @RecordExist varchar(2) 
declare @isFranchise char(1)
declare @iAgreementNo bigint

declare @AdjusterUserName varchar(10)
DECLARE @Debitor_Code BIGINT, @InternalEmailAddress VARCHAR(200),@ADJUSTEREmail varchar(500)

declare @success varchar(1)
set @success = 'N'

declare @sucessDispute varchar(1)
set @sucessDispute = 'N'

select @iAgreementNo = dac_agreement_number from da_claims where dac_entry_id=@EntryID

SELECT @AdjusterUserName = EMPLOYEE_ID, @ADJUSTEREmail = isnull(DAA_EMAIL, 'noreply@discountcar.com')  FROM DA_ADJUSTER (nolock) 
WHERE DAA_ENTRY_ID = (SELECT DAC_COMPANY_ADJUSTER_ID from DA_CLAIMS (nolock) where DAC_ENTRY_ID=@EntryID)

SELECT @isFranchise = Ltrim(rtrim(DAC_ARS_WEB)), @Debitor_Code = DAC_INS_COMPANY_ID from DA_CLAIMS (nolock) where DAC_ENTRY_ID=@EntryID

if ISNULL(@isFranchise, '') = ''
	set @isFranchise = 'N'

select @InternalEmailAddress =  dial_pal_email_id from DEBITORS D (nolock) where DEBITOR_CODE=@Debitor_Code			
set @InternalEmailAddress = @InternalEmailAddress + ';dialsupport@discountcar.com;DIALDISPUTE@discountcar.com'		

if @Acknowledge = 'Y' and @isFranchise = 'Y'
begin
  update EBILLING_INVOICE_DATA set ACKNOWLEDGE=@Acknowledge WHERE ENTRY_ID=@EntryID
  set @success = 'Y'
end

if @Dispute = 'Y' and @isFranchise = 'Y'
begin
  update EBILLING_INVOICE_DATA set dispute = @Dispute WHERE ENTRY_ID=@EntryID
  set @sucessDispute = 'Y'
end

if @isFranchise !='Y'
begin
	if exists(select TOP 1 CLAIM_NO from dbo.AGREEMENTS (nolock) where CLAIM_NO=@EntryID)
	  SET @RecordExist = 'ON'
	else if exists (select TOP 1 CLAIM_NO from AlbertaLive.dbo.AGREEMENTS (nolock) where CLAIM_NO=@EntryID)
	  SET @RecordExist = 'AB'
	else if exists (select TOP 1 CLAIM_NO from StCatharines.dbo.AGREEMENTS (nolock) where CLAIM_NO=@EntryID)
	  SET @RecordExist = 'ST'
	else if exists (select TOP 1 CLAIM_NO from SaskatchewanLive2.dbo.AGREEMENTS (nolock) where CLAIM_NO=@EntryID)
	  SET @RecordExist = 'SA'
	else if exists (select TOP 1 CLAIM_NO from SaskatchewanLive.dbo.AGREEMENTS (nolock) where CLAIM_NO=@EntryID)
	  SET @RecordExist = 'SF'	  
	else if exists (select TOP 1 CLAIM_NO from MaritimesLive.dbo.AGREEMENTS (nolock) where CLAIM_NO=@EntryID)
	  SET @RecordExist = 'MT'
	else if exists (select TOP 1 CLAIM_NO from BcLive.dbo.AGREEMENTS (nolock) where CLAIM_NO=@EntryID)
	  SET @RecordExist = 'BC'
	else if exists (select TOP 1 CLAIM_NO from NewfoundlandLive.dbo.AGREEMENTS (nolock) where CLAIM_NO=@EntryID)
	  SET @RecordExist = 'NL'
	else if exists (select TOP 1 CLAIM_NO from NewfoundlandLive2.dbo.AGREEMENTS (nolock) where CLAIM_NO=@EntryID)
	  SET @RecordExist = 'NC'

end



if @Acknowledge = 'Y' AND @isFranchise !='Y'
begin
	if @RecordExist ='ON'
	begin
	  update dbo.INVOICES set ACKNOWLEDGE=@Acknowledge where INVOICE_NO=@invoiceNo 
	  set @success = 'Y'
	end
	else if @RecordExist= 'AB'
	begin
	  update AlbertaLive.dbo.INVOICES set ACKNOWLEDGE=@Acknowledge where INVOICE_NO=@invoiceNo
	  set @success = 'Y'
	end
	else if @RecordExist = 'ST'
	begin
	  update StCatharines.dbo.INVOICES set ACKNOWLEDGE=@Acknowledge where INVOICE_NO=@invoiceNo
	  set @success = 'Y'
	end
	else if @RecordExist ='SA'
	begin
	  update SaskatchewanLive2.dbo.INVOICES set ACKNOWLEDGE=@Acknowledge where INVOICE_NO=@invoiceNo	
	  set @success = 'Y'
	end
	else if @RecordExist ='SF'
	begin
	  update SaskatchewanLive.dbo.INVOICES set ACKNOWLEDGE=@Acknowledge where INVOICE_NO=@invoiceNo	
	  set @success = 'Y'
	end
	else if @RecordExist ='MT'
	begin
	  update MaritimesLive.dbo.INVOICES set ACKNOWLEDGE=@Acknowledge where INVOICE_NO=@invoiceNo	
	  set @success = 'Y'
	end
	else if @RecordExist ='BC'
	begin
	  update BcLive.dbo.INVOICES set ACKNOWLEDGE=@Acknowledge where INVOICE_NO=@invoiceNo	
	  set @success = 'Y'
	end
	 else if @RecordExist ='NL'
	 begin
	  update NewfoundlandLive.dbo.INVOICES set ACKNOWLEDGE=@Acknowledge where INVOICE_NO=@invoiceNo	
	  set @success = 'Y'
	end
	else if @RecordExist ='NC'
	 begin
	  update NewfoundlandLive2.dbo.INVOICES set ACKNOWLEDGE=@Acknowledge where INVOICE_NO=@invoiceNo	
	  set @success = 'Y'
	end
end



if @Dispute = 'Y' AND @isFranchise !='Y'
begin	
	if @RecordExist ='ON'
	begin
	  update dbo.INVOICES set DISPUTE=@Dispute where INVOICE_NO=@invoiceNo
	  set @sucessDispute = 'Y'
	end
	else if @RecordExist= 'AB'
	begin
	  update AlbertaLive.dbo.INVOICES set DISPUTE=@Dispute where INVOICE_NO=@invoiceNo
	  set @sucessDispute = 'Y'
	end
	else if @RecordExist = 'ST'
	begin
	  update StCatharines.dbo.INVOICES set DISPUTE=@Dispute where INVOICE_NO=@invoiceNo
	  set @sucessDispute = 'Y'
	end
	else if @RecordExist = 'SF'
	begin
	  update SaskatchewanLive.dbo.INVOICES set DISPUTE=@Dispute where INVOICE_NO=@invoiceNo
	  set @sucessDispute = 'Y'
	end
	else if @RecordExist ='SA'
	begin
	  update SaskatchewanLive2.dbo.INVOICES set DISPUTE=@Dispute where INVOICE_NO=@invoiceNo		
	  set @sucessDispute = 'Y'
	end
	else if @RecordExist ='MT'
	begin
	  update MaritimesLive.dbo.INVOICES set DISPUTE=@Dispute where INVOICE_NO=@invoiceNo		
	  set @sucessDispute = 'Y'
	end
	else if @RecordExist ='BC'
	begin
	  update BcLive.dbo.INVOICES set DISPUTE=@Dispute where INVOICE_NO=@invoiceNo		
	  set @sucessDispute = 'Y'
	end
	 else if @RecordExist ='NL'
	 begin
	  update NewfoundlandLive.dbo.INVOICES set DISPUTE=@Dispute where INVOICE_NO=@invoiceNo		
	  set @sucessDispute = 'Y'
	end
end

if @Dispute = 'Y' and @DisputeText != ''
begin
--Declare @DisputeEmailAddress varchar(200)
--set @DisputeEmailAddress = (SELECT top 1 Email_address FROM dbo.tblDIAL_EmailList (nolock)	
--WHERE [Description] = 'Dispute')

insert into carpro_app.dbo.sendemailqueue 
(dbname, emailaddress, emailsubject, emailbody, emailformat, entryuser, entrytime, EmailfromAddress) 
values
('DIAL3.0', @InternalEmailAddress, 'DISPUTE for EntryID - '+ convert(varchar(15), @EntryID)  + 'Agreement No - ' + convert(varchar(15), @iAgreementNo) , @disputetext, 'HTML', @EntryID, getdate(), @ADJUSTEREmail)
end

if @IsDominion = 'Y' and @Acknowledge = 'Y'
begin
	if not exists(select * from tblDIAL_Zip_ftp where entry_id=@EntryID)
	INSERT INTO tblDIAL_Zip_ftp (entry_id, entry_user, entry_date) VALUES (@EntryID, 'DIAL 3.0', getdate())
end

if @Acknowledge = 'Y' and @IsDominion != 'Y'
begin
	if exists(select remedy_entry_id from tblWS_Insurance_Logs where remedy_entry_id>0 and status='Successful' and isQuebec=0 and remedy_entry_id = @EntryID and requestid != '')
	begin
		declare @AgreementNo bigint
		
		if @RecordExist ='ON'
		  select @AgreementNo = agreement_no from ontariolive..INVOICES (nolock) where INVOICE_NO = @invoiceNo
		else if @RecordExist= 'AB'
		  select @AgreementNo = agreement_no from AlbertaLive..INVOICES (nolock) where INVOICE_NO = @invoiceNo
		else if @RecordExist = 'ST'
		  select @AgreementNo = agreement_no from StCatharines..INVOICES (nolock) where INVOICE_NO = @invoiceNo
		else if @RecordExist ='SA'
		  select @AgreementNo = agreement_no from SaskatchewanLive2..INVOICES (nolock) where INVOICE_NO = @invoiceNo
        else if @RecordExist ='SF'
		  select @AgreementNo = agreement_no from SaskatchewanLive..INVOICES (nolock) where INVOICE_NO = @invoiceNo		  
		else if @RecordExist ='MT'
		  select @AgreementNo = agreement_no from MaritimesLive..INVOICES (nolock) where INVOICE_NO = @invoiceNo
		else if @RecordExist ='BC'
		  select @AgreementNo = agreement_no from BCLive..INVOICES (nolock) where INVOICE_NO = @invoiceNo
		else if @RecordExist ='NL'
		  select @AgreementNo = agreement_no from NewfoundlandLive..INVOICES (nolock) where INVOICE_NO = @invoiceNo
		else if @RecordExist ='NC'
		  select @AgreementNo = agreement_no from NewfoundlandLive2..INVOICES (nolock) where INVOICE_NO = @invoiceNo
		  
		if not exists(select * from tblDIAL_intact_Zip_ftp where entry_id=@EntryID)		
			INSERT INTO tblDIAL_intact_Zip_ftp (entry_id, entry_user, entry_date, Agreement_No, invoice_no, isfranchise, requestid, province) 
			VALUES (@EntryID, 'DIAL 3.0', getdate(), @AgreementNo, @invoiceNo, case when @isFranchise ='Y' then 1 else 0 end, (select requestid from tblWS_Insurance_Logs where remedy_entry_id = @EntryID), @RecordExist )	
	end
end

	declare @myNoteIDAuth bigint	
	declare @myMessage varchar(100)
		
	declare @ReallyAcknowledged varchar(1)
	
	if @isFranchise != 'Y' and @Acknowledge = 'Y'
	begin
		if @RecordExist ='ON'
		  select @ReallyAcknowledged = ltrim(rtrim(ACKNOWLEDGE))  from OntarioLive.dbo.INVOICES where INVOICE_NO=@invoiceNo 
		else if @RecordExist= 'AB'
		  select @ReallyAcknowledged = ltrim(rtrim(ACKNOWLEDGE))  from AlbertaLive.dbo.INVOICES where INVOICE_NO=@invoiceNo 
		else if @RecordExist = 'ST'
		  select @ReallyAcknowledged = ltrim(rtrim(ACKNOWLEDGE))  from StCatharines.dbo.INVOICES where INVOICE_NO=@invoiceNo 
		else if @RecordExist ='SA'
		  select @ReallyAcknowledged = ltrim(rtrim(ACKNOWLEDGE))  from SaskatchewanLive2.dbo.INVOICES where INVOICE_NO=@invoiceNo 
		else if @RecordExist ='SF'
		  select @ReallyAcknowledged = ltrim(rtrim(ACKNOWLEDGE))  from SaskatchewanLive.dbo.INVOICES where INVOICE_NO=@invoiceNo 
		else if @RecordExist ='MT'
		  select @ReallyAcknowledged = ltrim(rtrim(ACKNOWLEDGE))  from MaritimesLive.dbo.INVOICES where INVOICE_NO=@invoiceNo 
		else if @RecordExist ='BC'
		  select @ReallyAcknowledged = ltrim(rtrim(ACKNOWLEDGE))  from BCLive.dbo.INVOICES where INVOICE_NO=@invoiceNo 
		else if @RecordExist ='NL'
		  select @ReallyAcknowledged = ltrim(rtrim(ACKNOWLEDGE))  from NewfoundlandLive.dbo.INVOICES where INVOICE_NO=@invoiceNo 
		else if @RecordExist ='NC'
		  select @ReallyAcknowledged = ltrim(rtrim(ACKNOWLEDGE))  from NewfoundlandLive2.dbo.INVOICES where INVOICE_NO=@invoiceNo 
	end
	
	if @isFranchise = 'Y' and @Acknowledge = 'Y'
	begin		
		  select @ReallyAcknowledged = ltrim(rtrim(ACKNOWLEDGE)) from OntarioLive.dbo.EBILLING_INVOICE_DATA where ENTRY_ID=@EntryID
	end	
	
	if ISNULL(@ReallyAcknowledged, '') = 'Y' and @success = 'Y'	
	begin
		select @myMessage ='Invoice Acknowledged'
		
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
		
	end
	
	if @Dispute = 'Y' and @sucessDispute = 'Y'	  
	begin
		select @myMessage ='Invoice Disputed : Reason- '+ @DisputeText
		
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
	end
	  
	if isnull(@ReallyAcknowledged, '') = 'Y' or @Dispute = 'Y'		
    begin
		insert into tblDIAL_UsersLog (Adjuster_Username, ip_address, flag, Process_Code, entry_id) 
		values (@AdjusterUserName, @ClientIp, 1, case when @Acknowledge = 'Y' then 4  when @Dispute = 'Y' then 5 end, @EntryID)
    end

--select TOP 100 * from carpro_app.dbo.sendemailqueue ORDER BY ID DESC


	






