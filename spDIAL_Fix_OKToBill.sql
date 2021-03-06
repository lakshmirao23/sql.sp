USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Fix_OKToBill]    Script Date: 04/05/2018 09:35:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- exec spDIAL_Fix_OKToBill

ALTER procedure [dbo].[spDIAL_Fix_OKToBill]

as
begin

	select OK_TO_BILL, AGREEMENT_NO, DAC_ENTRY_ID RemedyID, DAC_STATUS RemedyStatus , STATUS_CODE as AgreementStatus, 
	DAC_AGR_OPEN_DATE RentalOpenDate, DAC_AGR_CLOSE_DATE RentalCloseDate into #tempoktoBill
	from ontariolive..DA_CLAIMS c (nolock)
	inner join ontariolive..AGREEMENTS a (nolock) on c.DAC_ENTRY_ID = a.CLAIM_NO 
	where DAC_STATUS=4 and STATUS_CODE=4 and PARENT_EXTEND_AGREEMENT_NO = 0 and OK_TO_BILL=0 and DAC_CREATE_DATE > '20140701'
	union 
	select OK_TO_BILL, AGREEMENT_NO, DAC_ENTRY_ID RemedyID, DAC_STATUS RemedyStatus , STATUS_CODE as AgreementStatus, 
	DAC_AGR_OPEN_DATE RentalOpenDate, DAC_AGR_CLOSE_DATE RentalCloseDate 
	from ontariolive..DA_CLAIMS c  (nolock)
	inner join albertalive..AGREEMENTS a (nolock) on c.DAC_ENTRY_ID = a.CLAIM_NO 
	where DAC_STATUS=4 and STATUS_CODE=4 and PARENT_EXTEND_AGREEMENT_NO = 0  and OK_TO_BILL=0 and DAC_CREATE_DATE > '20140701'
	union 
	select OK_TO_BILL, AGREEMENT_NO, DAC_ENTRY_ID RemedyID, DAC_STATUS RemedyStatus , STATUS_CODE as AgreementStatus, 
	DAC_AGR_OPEN_DATE RentalOpenDate, DAC_AGR_CLOSE_DATE RentalCloseDate 
	from ontariolive..DA_CLAIMS c (nolock)
	inner join MaritimesLive..AGREEMENTS a (nolock) on c.DAC_ENTRY_ID = a.CLAIM_NO 
	where DAC_STATUS=4 and STATUS_CODE=4 and PARENT_EXTEND_AGREEMENT_NO = 0  and OK_TO_BILL=0 and DAC_CREATE_DATE > '20140701'
	union 
	select OK_TO_BILL, AGREEMENT_NO, DAC_ENTRY_ID RemedyID, DAC_STATUS RemedyStatus , STATUS_CODE as AgreementStatus, 
	DAC_AGR_OPEN_DATE RentalOpenDate, DAC_AGR_CLOSE_DATE RentalCloseDate 
	from ontariolive..DA_CLAIMS c (nolock)
	inner join BCLive..AGREEMENTS a (nolock) on c.DAC_ENTRY_ID = a.CLAIM_NO 
	where DAC_STATUS=4 and STATUS_CODE=4 and PARENT_EXTEND_AGREEMENT_NO = 0  and OK_TO_BILL=0 and DAC_CREATE_DATE > '20140701'
	union 
	select OK_TO_BILL, AGREEMENT_NO, DAC_ENTRY_ID RemedyID, DAC_STATUS RemedyStatus , STATUS_CODE as AgreementStatus, 
	DAC_AGR_OPEN_DATE RentalOpenDate, DAC_AGR_CLOSE_DATE RentalCloseDate 
	from ontariolive..DA_CLAIMS c (nolock)
	inner join SaskatchewanLive..AGREEMENTS a (nolock) on c.DAC_ENTRY_ID = a.CLAIM_NO 
	where DAC_STATUS=4 and STATUS_CODE=4 and PARENT_EXTEND_AGREEMENT_NO = 0  and OK_TO_BILL=0 and DAC_CREATE_DATE > '20140701'
	
	select * from #tempoktoBill
	
	if exists(select count(*) from #tempoktoBill)
	begin
		update ontariolive..DA_CLAIMS set OK_TO_BILL = 1 where DAC_ENTRY_ID in (SELECT remedyid from #tempoktoBill)	
	end
	
	
	if (select COUNT(*) from #tempoktoBill) >0
	begin
	EXEC msdb..sp_send_dbmail @profile_name='AltBill',
		@recipients='lrao@discountcar.com;',
		--@recipients='dgiordmaina@discountcar.com;lrao@discountcar.com;cstpierre@discountcar.com;DMercuri@discountcar.com',
		--@recipients='dgiordmaina@discountcar.com;lrao@discountcar.com;cstpierre@discountcar.com;',
		@subject='OK To Bill Flag issue Files',
		@importance=  'high', 
		@body='See attached file.' ,
		@query ='select * from #tempoktoBill'
		,@query_result_width = 60000
		,@query_result_separator = '	', --tab	
		@attach_query_result_as_file = 1 ,
		@query_attachment_filename= 'OK_To_Bill.csv' ,
		@append_query_error = 1
	end

	
	drop table #tempoktoBill
	
	


end