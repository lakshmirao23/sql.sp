USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_SendEmailAlerts]    Script Date: 04/05/2018 09:40:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec spDIAL_SendEmailAlerts

ALTER Proc [dbo].[spDIAL_SendEmailAlerts]
as 
	declare @ToEmailAddress varchar(300), @Subject varchar(200), @PolicyNumber varchar(50), @ClaimNo varchar(50), @sEmailBody varchar (2000), @isDIAL varchar(1)	
	
	IF OBJECT_ID('tempdb.. #MySendEmailQueue') IS NOT NULL DROP TABLE  #MySendEmailQueue 
  
	CREATE TABLE #MySendEmailQueue(
	[MyID] [int] IDENTITY(1,1) NOT NULL,
	[Entry_ID] bigint,
	[type] varchar(1) NULL,
	) 	
	
	insert into #MySendEmailQueue(
		[Entry_ID],	
		[Type]
		)		
		select 
		entry_id,
		min(type) [type]
		from Carpro_App..tblDIAL_AuthNoteFinalAuthEmail(nolock) 
		where isprocessed =0	
		group by entry_id
	
	
	if (select COUNT(*) from #MySendEmailQueue) > 0
	begin
		
		declare @intCount int, @intCountTotal int
		declare --@ID [int] ,
			@EntryID bigint ,
			@Type [varchar](1), @isDominion varchar(1)	
		
		select @intCount =1, @intCountTotal =COUNT(*) from #MySendEmailQueue
		
		while (@intCount <= @intCountTotal)
		begin
			
			select
			--@ID =MyID ,
			@EntryID = Entry_ID,
			@Type = type 			
			from #MySendEmailQueue
			where MyID =@intCount		
			
			select @ToEmailAddress = dial_pal_email_id, @PolicyNumber=DAC_POLICY, @ClaimNo=DAC_INS_CLAIM 
			from DEBITORS d (nolock) 
			left join DA_CLAIMS c (nolock) on c.DAC_INS_COMPANY_ID = d.DEBITOR_CODE 
			where DAC_ENTRY_ID = @EntryID				
			
		
			--select @ToEmailAddress = dial_pal_email_id, @PolicyNumber=DAC_POLICY, @ClaimNo=DAC_INS_CLAIM ,
			--@isDominion = case when p.debitor_code = d.DEBITOR_CODE  then 'Y' else 'N' end  
			----from DEBITORS d (nolock) 
			----left join DA_CLAIMS c (nolock) on c.DAC_INS_COMPANY_ID = d.DEBITOR_CODE 
			----left join PORTAL_DEBITOR_SETUP p (nolock) on p.DEBITOR_CODE = d.DEBITOR_CODE
			----where DAC_ENTRY_ID = @EntryID	
			
			if @Type = 'F' 
			  set @Subject = 'Adjuster Authorization (''Note'' ''Auth'' ''Final'')'
			else if @Type = 'I' 
			  set @Subject = 'Adjuster Authorization (''Note'' ''Auth'')'
			else if @Type = 'N' 
			  set @Subject = 'Note has been added for Entry Id' + convert(varchar(20),CONVERT(bigint, @EntryID)) + ', Policy Number' + @PolicyNumber+', Claim Number' + @ClaimNo			  
			  
			  select @sEmailBody =  '<font face=''verdana'' size=''2''>Claim ID: ' + convert(varchar(20),CONVERT(bigint, dac_entry_id)) + '<br><br>' 
			+  'Claim Number: ' + DAC_INS_CLAIM + '<br><br>' +  'Policy Number:' + DAC_POLICY + '<br><br>'  
			+ 'Client Name: ' + DAC_CLIENT_FIRST_NAME + ' ' + DAC_CLIENT_LAST_NAME + '<br><br>' +  'DRP Shop: ' + DAC_DRP_SHOP + '<br><br>'  
			+ 'Garage Name:' + DAC_GARAGE_NAME + '<br><br>'  
			+  'Policy Max: ' + convert(varchar(20), DAC_MAX_ALLOW) + '<br><br>' 
			+  'Collision Deductible: ' + DAC_COLLISION_COVERAGE + '<br><br>'
			 +  'Comp Deductible:' + convert(varchar(20),DAC_DEDUC_COLLISION) + '<br><br>' 
			 + 'Authorized To Date:' + convert(varchar(20),  dbo.convertToDate(t.DCA_AUTHOR_TO_DATE))  + '<br><br>' 
			 +  'Additional Days Authorized: ' + convert(varchar(10), t.dca_a_days) + '<br><br>' + 
			 'Authorized Rate:' + convert(varchar(20), t.DCA_AUTHOR_RATE) + '<br><br>'  +
			'Final Auth: ' + t.FINAL_AUTH + '<br><br>' + 
			case when ltrim(rtrim(notesc.Notes)) != ltrim(rtrim(t.DCA_AUTH_NOTES)) then
			'Notes:' + notesc.Notes + '  ' + t.DCA_AUTH_NOTES  +  '<br><br></font>'
			else
			'Notes:' + notesc.Notes +  '<br><br></font>'
			end
			--case when @Type = 'N' then
			-- 'Notes:' + notesc.Notes + '<br><br>' 
			--else
			-- 'Notes:' + t.DCA_AUTH_NOTES + '<br><br>' 
			--end 
			from DA_CLAIMS c (nolock) 			
			LEFT OUTER JOIN (SELECT da.DCA_CLAIM_ID,ISNULL(AVG(VAT_PER),0)VAT_PER,ISNULL(SUM(dca_a_days),0) dca_a_days,ISNULL(AVG(DCA_AUTHOR_RATE),0) DCA_AUTHOR_RATE,
																MAX(DA.DCA_AUTHOR_TO_DATE) DCA_AUTHOR_TO_DATE
																,SUM(DCA_TOTAL_RENTAL) as DCA_TOTAL_RENTAL
																, MAX(DA.DCA_ENTRY_ID) Last_Auth_ID, max(ltrim(rtrim(FINAL_AUTH))) as FinalAuth_fromAuth
																  from DA_AUTHORIZATION da(NOLOCK) where DCA_BILL_TO=1 and (left(DCA_AUTHOR_TO_DATE, 4) > '2000' or DCA_AUTHOR_TO_DATE = '00000000') GROUP BY da.DCA_CLAIM_ID )
																  AS dauth ON c.DAC_ENTRY_ID = dauth.DCA_CLAIM_ID
			left join DA_AUTHORIZATION t(nolock) on dauth.Last_Auth_ID =t.DCA_ENTRY_ID
			LEFT OUTER JOIN 
			(select top 1 (DCN_NOTES) as Notes, DCN_CLAIM_ID notesClaimID
			from  DA_NOTES_HISTORY N (NOLOCK) where N.DCN_CLAIM_ID = @EntryID 
			order by DCN_DATE desc, DCN_TIME desc) notesc on c.DAC_ENTRY_ID = notesc.notesClaimID
			where DAC_ENTRY_ID = @EntryID  
			
			select @isDIAL = case when DAC_SUBMITTER = 'DIAL' then 'Y' else 'N' end from DA_CLAIMS (nolock) where DAC_ENTRY_ID=@EntryID
			
			if @isDIAL = 'Y'					
			begin
			
			EXEC msdb..sp_send_dbmail @profile_name='AltBill',
                              @recipients = @ToEmailAddress,
                              --@recipients = 'lrao@discountcar.com',
                              @blind_copy_recipients ='dialsupport@discountcar.com', 
                              @from_address  =  'noreply@discountcar.com',
                              @subject=@Subject,                             
                              @body=@sEmailBody,
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
			Values ('DIAL3.0', @ToEmailAddress+';dialsupport@discountcar.com','noreply@discountcar.com',@Subject, @sEmailBody ,'html', getdate(),'DIAL3.0', GETDATE())
			
			
			declare @DaysExtended int, @AdjusterEmailAddress varchar(400), @AdjusterName varchar(150)
			declare @AdjusterSubject varchar(200) , @AdjusterBody varchar(2000), @SubmitDate datetime, @submitTime varchar(10)			
			
			set @DaysExtended = 0
			
			select  top 1 @DaysExtended = DCA_A_DAYS from DA_AUTHORIZATION (nolock) 
			where DCA_CLAIM_ID=@EntryID and DCA_SUBMITTER='DIAL' order by DCA_ENTRY_ID desc
			
			--select @DaysExtended = DCA_A_DAYS from DA_AUTHORIZATION (nolock) 
			--where DCA_CLAIM_ID=@EntryID and DCA_SUBMITTER='DIAL'
			
			--select @DaysExtended
						
			IF @DaysExtended > 0 
			BEGIN			
			
			select @AdjusterEmailAddress = daa_email, @AdjusterName = DAA_FIRST_NAME + ' ' +DAA_LAST_NAME			 
			from DA_ADJUSTER  a (nolock) 
			inner join da_claims (nolock) c on a.DAA_ENTRY_ID = c.DAC_COMPANY_ADJUSTER_ID
			where DAC_ENTRY_ID = @EntryID
			
			set @AdjusterSubject = 'Discount Rental authorization confirmation'
			
			select @AdjusterBody = '<font face=''verdana'' size=''2''>This email confirms that your rental authorization has been submitted successfully on ' +  convert(varchar(20), DATEADD(SECOND,DAC_MODIFIED_TIME, convert(datetime, convert(varchar(8),DAC_MODIFIED_DATE,112) )))  
			+ '<br><br>' + 'Adjuster’s Name: ' + @AdjusterName 
			+ '<br><br>' + 'Reservation / Entry ID # OR Agreement #: ' +  case when DAC_AGREEMENT_NUMBER > 0 then  convert(varchar(20), convert(bigint, DAC_AGREEMENT_NUMBER)) else convert(varchar(20), convert(bigint, DAC_ENTRY_ID)) end
			+ '<br><br>' + 'Location: ' + DAC_LOCATION_NAME + ' ' + DAC_LOCATION_ADDRESS + ' ' 
			+ DAC_LOCATION_CITY  + ' ' + DAC_LOCATION_POSTAL_CODE + ' ' + DAC_LOCATION_PHONE
			+ '<br><br>' + 'Claim No: ' + DAC_INS_CLAIM
			+ '<br><br>' + 'Policy Number: ' + DAC_POLICY
			+ '<br><br>' + 'Insured’s Name: ' + DAC_CLIENT_FIRST_NAME + ' ' + DAC_CLIENT_LAST_NAME
			+ '<br><br>' + 'Insured’s Phone #: ' + DAC_CLIENT_PHONE
			+ '<br><br>' + 'Total Days Authorized: ' + convert(varchar(10), dauth.dca_a_days) +	'<br><br>' + 
			--+ '<br><br>' + 'NOTES: ' + t.DCA_AUTH_NOTES	
			case when ltrim(rtrim(notesc.Notes)) != ltrim(rtrim(t.DCA_AUTH_NOTES)) then
			'Notes:' + notesc.Notes + '  ' + t.DCA_AUTH_NOTES  +  '<br><br></font>'
			else
			'Notes:' + notesc.Notes +  '<br><br></font>'
			end
			from DA_CLAIMS c (nolock) 
			LEFT OUTER JOIN 
			(SELECT da.DCA_CLAIM_ID,ISNULL(AVG(VAT_PER),0)VAT_PER,
			ISNULL(SUM(dca_a_days),0) dca_a_days,ISNULL(AVG(DCA_AUTHOR_RATE),0) DCA_AUTHOR_RATE,
			MAX(DA.DCA_AUTHOR_TO_DATE) DCA_AUTHOR_TO_DATE
			,SUM(DCA_TOTAL_RENTAL) as DCA_TOTAL_RENTAL
			, MAX(DA.DCA_ENTRY_ID) Last_Auth_ID, max(ltrim(rtrim(FINAL_AUTH))) as FinalAuth_fromAuth
			from DA_AUTHORIZATION da(NOLOCK) where DCA_BILL_TO=1 and (left(DCA_AUTHOR_TO_DATE, 4) > '2000' or DCA_AUTHOR_TO_DATE = '00000000') GROUP BY da.DCA_CLAIM_ID )
			AS dauth ON c.DAC_ENTRY_ID = dauth.DCA_CLAIM_ID
			left join DA_AUTHORIZATION t(nolock) on dauth.Last_Auth_ID =t.DCA_ENTRY_ID
			LEFT OUTER JOIN 
			(select top 1 (DCN_NOTES) as Notes, DCN_CLAIM_ID notesClaimID
			from  DA_NOTES_HISTORY N (NOLOCK) where N.DCN_CLAIM_ID = @EntryID 
			order by DCN_DATE desc, DCN_TIME desc) notesc on c.DAC_ENTRY_ID = notesc.notesClaimID
			where DAC_ENTRY_ID = @EntryID  		
			
			if @Type = 'I'  or @Type = 'F'
			begin
			
			EXEC msdb..sp_send_dbmail @profile_name='AltBill',
                              @recipients = @AdjusterEmailAddress,                              
                              @blind_copy_recipients = 'dialsupport@discountcar.com', 
                              @from_address  =  'noreply@discountcar.com',
                              @subject=@AdjusterSubject,                             
                              @body=@AdjusterBody,
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
			Values ('DIAL3.0', @AdjusterEmailAddress+';dialsupport@discountcar.com','noreply@discountcar.com',@AdjusterSubject, @AdjusterBody ,'html', getdate(),'DIAL3.0', GETDATE())
			--Values ('DIAL3.0', 'lrao@discountcar.com','dctr@discountcar.com',@AdjusterSubject, @AdjusterBody + @AdjusterEmailAddress,'html', getdate(),'DIAL3.0')
			end
			END
			  
			end
		
		select @intCount = @intCount + 1
	end
	
	
	update a 
	set isprocessed = 1 
	from Carpro_App..tblDIAL_AuthNoteFinalAuthEmail a
	inner join #MySendEmailQueue b
	on a.entry_id = b.Entry_ID		
		
	end

	drop table #MySendEmailQueue
-- select top 100 * FROM Carpro_App.dbo.[SendEmailQueue] ORDER BY ID DESC

--SELECT * FROM Carpro_App..tblDIAL_AuthNoteFinalAuthEmail order by createdate desc









