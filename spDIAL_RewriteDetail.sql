USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_RewriteDetail]    Script Date: 04/05/2018 09:39:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec [dbo].[spDIAL_RewriteDetail] @iAgreementNo = 1290008159, @IP_ADDRESS = '150.8.0.70'
-- exec [dbo].[spDIAL_RewriteDetail] @iAgreementNo = 1750011757, @IP_ADDRESS = '150.8.0.70'

--exec [dbo].[spDIAL_RewriteDetail] @iAgreementNo = 2160012308, @IP_ADDRESS = '150.8.0.70'
 

-- exec [dbo].[spDIAL_RewriteDetail] 1210022302, '', @AdjusterId = 18001
ALTER PROCEDURE [dbo].[spDIAL_RewriteDetail]	
@iAgreementNo bigint = null, @IP_ADDRESS VARCHAR(20) = '', @AdjusterId bigint = null
AS
BEGIN	
	SET NOCOUNT ON
	
	DECLARE @iCount int = 1, @iTotalCount int, @iParent_Agreement_No bigint, @iCurrent_Agreement_No bigint
	Declare @tblRewrite table (
	ID int,
	Parent_Agreement_No bigint,
	Current_Agreement_No bigint
	)
	
	
	Declare @tblRewriteSelect table (
	ID int,
	Parent_Agreement_No bigint,
	Current_Agreement_No bigint
	)
	
	IF EXISTS(SELECT PARENT_EXTEND_AGREEMENT_NO FROM AGREEMENTS(NOLOCK) WHERE AGREEMENT_NO = @iAgreementNo)
	BEGIN
			
			SELECT @iParent_Agreement_No = PARENT_EXTEND_AGREEMENT_NO FROM AGREEMENTS(NOLOCK) WHERE AGREEMENT_NO = @iAgreementNo
			insert into @tblRewrite(ID, Parent_Agreement_No, Current_Agreement_No )
			values(@iCount, @iParent_Agreement_No,@iAgreementNo)
			
			select @iCurrent_Agreement_No = @iParent_Agreement_No
			
			while (@iCurrent_Agreement_No >0)
			begin
			
				select @iCount = @iCount + 1
				
				SELECT @iParent_Agreement_No = PARENT_EXTEND_AGREEMENT_NO FROM AGREEMENTS(NOLOCK) WHERE AGREEMENT_NO = @iCurrent_Agreement_No
			
				if @@ROWCOUNT = 0
					break

				insert into @tblRewrite(ID, Parent_Agreement_No, Current_Agreement_No )
				values(@iCount, @iParent_Agreement_No,@iCurrent_Agreement_No)
				
				select @iCurrent_Agreement_No = @iParent_Agreement_No
			end
			
			insert into @tblRewriteSelect(ID,Parent_Agreement_No, Current_Agreement_No )
			select ROW_NUMBER()over( order by ID desc) RewriteStep, Parent_Agreement_No, Current_Agreement_No
			from @tblRewrite
			--for next.
			
			select @iParent_Agreement_No = @iAgreementNo
			
			SELECT @iCurrent_Agreement_No = AGREEMENT_NO FROM AGREEMENTS(NOLOCK) WHERE PARENT_EXTEND_AGREEMENT_NO = @iParent_Agreement_No
			
			if @iCurrent_Agreement_No >0
			begin
			
				select @iCount = @iCount + 1
			
				insert into @tblRewriteSelect(ID, Parent_Agreement_No, Current_Agreement_No )
				values(@iCount, @iParent_Agreement_No,@iCurrent_Agreement_No)
			
			end
			
			select @iParent_Agreement_No =@iCurrent_Agreement_No 
			
			while (@iParent_Agreement_No >0)
			begin
							
				select @iCount = @iCount + 1
				
				SELECT @iCurrent_Agreement_No = AGREEMENT_NO FROM AGREEMENTS(NOLOCK) WHERE PARENT_EXTEND_AGREEMENT_NO = @iParent_Agreement_No
			
			
				--if @iCurrent_Agreement_No is null
				if @@ROWCOUNT =0
					break
				
				insert into @tblRewriteSelect(ID, Parent_Agreement_No, Current_Agreement_No )
				values(@iCount, @iParent_Agreement_No,@iCurrent_Agreement_No)
				
				select 	@iParent_Agreement_No = @iCurrent_Agreement_No			
			end
			
	END
	--Alberta
	else IF EXISTS(SELECT PARENT_EXTEND_AGREEMENT_NO FROM albertalive..AGREEMENTS(NOLOCK) WHERE AGREEMENT_NO = @iAgreementNo)
	BEGIN
			
			SELECT @iParent_Agreement_No = PARENT_EXTEND_AGREEMENT_NO FROM albertalive..AGREEMENTS(NOLOCK) WHERE AGREEMENT_NO = @iAgreementNo
			insert into @tblRewrite(ID, Parent_Agreement_No, Current_Agreement_No )
			values(@iCount, @iParent_Agreement_No,@iAgreementNo)
			
			select @iCurrent_Agreement_No = @iParent_Agreement_No
			
			while (@iCurrent_Agreement_No >0)
			begin
			
				select @iCount = @iCount + 1
				
				SELECT @iParent_Agreement_No = PARENT_EXTEND_AGREEMENT_NO FROM albertalive..AGREEMENTS(NOLOCK) WHERE AGREEMENT_NO = @iCurrent_Agreement_No
			
				if @@ROWCOUNT = 0
					break

				insert into @tblRewrite(ID, Parent_Agreement_No, Current_Agreement_No )
				values(@iCount, @iParent_Agreement_No,@iCurrent_Agreement_No)
				
				select @iCurrent_Agreement_No = @iParent_Agreement_No
			end
			
			insert into @tblRewriteSelect(ID,Parent_Agreement_No, Current_Agreement_No )
			select ROW_NUMBER()over( order by ID desc) RewriteStep, Parent_Agreement_No, Current_Agreement_No
			from @tblRewrite
			--for next.
			
			select @iParent_Agreement_No = @iAgreementNo
			
			SELECT @iCurrent_Agreement_No = AGREEMENT_NO FROM albertalive..AGREEMENTS(NOLOCK) WHERE PARENT_EXTEND_AGREEMENT_NO = @iParent_Agreement_No
			
			if @iCurrent_Agreement_No >0
			begin
			
				select @iCount = @iCount + 1
			
				insert into @tblRewriteSelect(ID, Parent_Agreement_No, Current_Agreement_No )
				values(@iCount, @iParent_Agreement_No,@iCurrent_Agreement_No)
			
			end
			
			select @iParent_Agreement_No =@iCurrent_Agreement_No 
			
			while (@iParent_Agreement_No >0)
			begin
							
				select @iCount = @iCount + 1
				
				SELECT @iCurrent_Agreement_No = AGREEMENT_NO FROM albertalive..AGREEMENTS(NOLOCK) WHERE PARENT_EXTEND_AGREEMENT_NO = @iParent_Agreement_No
			
			
				--if @iCurrent_Agreement_No is null
				if @@ROWCOUNT =0
					break
				
				insert into @tblRewriteSelect(ID, Parent_Agreement_No, Current_Agreement_No )
				values(@iCount, @iParent_Agreement_No,@iCurrent_Agreement_No)
				
				select 	@iParent_Agreement_No = @iCurrent_Agreement_No			
			end
			
		
			
	END
	--MT
	else IF EXISTS(SELECT PARENT_EXTEND_AGREEMENT_NO FROM MaritimesLive..AGREEMENTS(NOLOCK) WHERE AGREEMENT_NO = @iAgreementNo)
	BEGIN
			
			SELECT @iParent_Agreement_No = PARENT_EXTEND_AGREEMENT_NO FROM MaritimesLive..AGREEMENTS(NOLOCK) WHERE AGREEMENT_NO = @iAgreementNo
			insert into @tblRewrite(ID, Parent_Agreement_No, Current_Agreement_No )
			values(@iCount, @iParent_Agreement_No,@iAgreementNo)
			
			select @iCurrent_Agreement_No = @iParent_Agreement_No
			
			while (@iCurrent_Agreement_No >0)
			begin
			
				select @iCount = @iCount + 1
				
				SELECT @iParent_Agreement_No = PARENT_EXTEND_AGREEMENT_NO FROM MaritimesLive..AGREEMENTS(NOLOCK) WHERE AGREEMENT_NO = @iCurrent_Agreement_No
			
				if @@ROWCOUNT = 0
					break

				insert into @tblRewrite(ID, Parent_Agreement_No, Current_Agreement_No )
				values(@iCount, @iParent_Agreement_No,@iCurrent_Agreement_No)
				
				select @iCurrent_Agreement_No = @iParent_Agreement_No
			end
			
			insert into @tblRewriteSelect(ID,Parent_Agreement_No, Current_Agreement_No )
			select ROW_NUMBER()over( order by ID desc) RewriteStep, Parent_Agreement_No, Current_Agreement_No
			from @tblRewrite
			--for next.
			
			select @iParent_Agreement_No = @iAgreementNo
			
			SELECT @iCurrent_Agreement_No = AGREEMENT_NO FROM MaritimesLive..AGREEMENTS(NOLOCK) WHERE PARENT_EXTEND_AGREEMENT_NO = @iParent_Agreement_No
			
			if @iCurrent_Agreement_No >0
			begin
			
				select @iCount = @iCount + 1
			
				insert into @tblRewriteSelect(ID, Parent_Agreement_No, Current_Agreement_No )
				values(@iCount, @iParent_Agreement_No,@iCurrent_Agreement_No)
			
			end
			
			select @iParent_Agreement_No =@iCurrent_Agreement_No 
			
			while (@iParent_Agreement_No >0)
			begin
							
				select @iCount = @iCount + 1
				
				SELECT @iCurrent_Agreement_No = AGREEMENT_NO FROM MaritimesLive..AGREEMENTS(NOLOCK) WHERE PARENT_EXTEND_AGREEMENT_NO = @iParent_Agreement_No
			
			
				--if @iCurrent_Agreement_No is null
				if @@ROWCOUNT =0
					break
				
				insert into @tblRewriteSelect(ID, Parent_Agreement_No, Current_Agreement_No )
				values(@iCount, @iParent_Agreement_No,@iCurrent_Agreement_No)
				
				select 	@iParent_Agreement_No = @iCurrent_Agreement_No			
			end
			
		
			
	END
	--St Cath
	else IF EXISTS(SELECT PARENT_EXTEND_AGREEMENT_NO FROM StCatharines..AGREEMENTS(NOLOCK) WHERE AGREEMENT_NO = @iAgreementNo)
	BEGIN
			
			SELECT @iParent_Agreement_No = PARENT_EXTEND_AGREEMENT_NO FROM StCatharines..AGREEMENTS(NOLOCK) WHERE AGREEMENT_NO = @iAgreementNo
			insert into @tblRewrite(ID, Parent_Agreement_No, Current_Agreement_No )
			values(@iCount, @iParent_Agreement_No,@iAgreementNo)
			
			select @iCurrent_Agreement_No = @iParent_Agreement_No
			
			while (@iCurrent_Agreement_No >0)
			begin
			
				select @iCount = @iCount + 1
				
				SELECT @iParent_Agreement_No = PARENT_EXTEND_AGREEMENT_NO FROM StCatharines..AGREEMENTS(NOLOCK) WHERE AGREEMENT_NO = @iCurrent_Agreement_No
			
				if @@ROWCOUNT = 0
					break

				insert into @tblRewrite(ID, Parent_Agreement_No, Current_Agreement_No )
				values(@iCount, @iParent_Agreement_No,@iCurrent_Agreement_No)
				
				select @iCurrent_Agreement_No = @iParent_Agreement_No
			end
			
			insert into @tblRewriteSelect(ID,Parent_Agreement_No, Current_Agreement_No )
			select ROW_NUMBER()over( order by ID desc) RewriteStep, Parent_Agreement_No, Current_Agreement_No
			from @tblRewrite
			--for next.
			
			select @iParent_Agreement_No = @iAgreementNo
			
			SELECT @iCurrent_Agreement_No = AGREEMENT_NO FROM StCatharines..AGREEMENTS(NOLOCK) WHERE PARENT_EXTEND_AGREEMENT_NO = @iParent_Agreement_No
			
			if @iCurrent_Agreement_No >0
			begin
			
				select @iCount = @iCount + 1
			
				insert into @tblRewriteSelect(ID, Parent_Agreement_No, Current_Agreement_No )
				values(@iCount, @iParent_Agreement_No,@iCurrent_Agreement_No)
			
			end
			
			select @iParent_Agreement_No =@iCurrent_Agreement_No 
			
			while (@iParent_Agreement_No >0)
			begin
							
				select @iCount = @iCount + 1
				
				SELECT @iCurrent_Agreement_No = AGREEMENT_NO FROM StCatharines..AGREEMENTS(NOLOCK) WHERE PARENT_EXTEND_AGREEMENT_NO = @iParent_Agreement_No
			
			
				--if @iCurrent_Agreement_No is null
				if @@ROWCOUNT =0
					break
				
				insert into @tblRewriteSelect(ID, Parent_Agreement_No, Current_Agreement_No )
				values(@iCount, @iParent_Agreement_No,@iCurrent_Agreement_No)
				
				select 	@iParent_Agreement_No = @iCurrent_Agreement_No			
			end
			
		
			
	END
	--Sask
	else IF EXISTS(SELECT PARENT_EXTEND_AGREEMENT_NO FROM SaskatchewanLive..AGREEMENTS(NOLOCK) WHERE AGREEMENT_NO = @iAgreementNo)
	BEGIN
			
			SELECT @iParent_Agreement_No = PARENT_EXTEND_AGREEMENT_NO FROM SaskatchewanLive..AGREEMENTS(NOLOCK) WHERE AGREEMENT_NO = @iAgreementNo
			insert into @tblRewrite(ID, Parent_Agreement_No, Current_Agreement_No )
			values(@iCount, @iParent_Agreement_No,@iAgreementNo)
			
			select @iCurrent_Agreement_No = @iParent_Agreement_No
			
			while (@iCurrent_Agreement_No >0)
			begin
			
				select @iCount = @iCount + 1
				
				SELECT @iParent_Agreement_No = PARENT_EXTEND_AGREEMENT_NO FROM SaskatchewanLive..AGREEMENTS(NOLOCK) WHERE AGREEMENT_NO = @iCurrent_Agreement_No
			
				if @@ROWCOUNT = 0
					break

				insert into @tblRewrite(ID, Parent_Agreement_No, Current_Agreement_No )
				values(@iCount, @iParent_Agreement_No,@iCurrent_Agreement_No)
				
				select @iCurrent_Agreement_No = @iParent_Agreement_No
			end
			
			insert into @tblRewriteSelect(ID,Parent_Agreement_No, Current_Agreement_No )
			select ROW_NUMBER()over( order by ID desc) RewriteStep, Parent_Agreement_No, Current_Agreement_No
			from @tblRewrite
			--for next.
			
			select @iParent_Agreement_No = @iAgreementNo
			
			SELECT @iCurrent_Agreement_No = AGREEMENT_NO FROM SaskatchewanLive..AGREEMENTS(NOLOCK) WHERE PARENT_EXTEND_AGREEMENT_NO = @iParent_Agreement_No
			
			if @iCurrent_Agreement_No >0
			begin
			
				select @iCount = @iCount + 1
			
				insert into @tblRewriteSelect(ID, Parent_Agreement_No, Current_Agreement_No )
				values(@iCount, @iParent_Agreement_No,@iCurrent_Agreement_No)
			
			end
			
			select @iParent_Agreement_No =@iCurrent_Agreement_No 
			
			while (@iParent_Agreement_No >0)
			begin
							
				select @iCount = @iCount + 1
				
				SELECT @iCurrent_Agreement_No = AGREEMENT_NO FROM SaskatchewanLive..AGREEMENTS(NOLOCK) WHERE PARENT_EXTEND_AGREEMENT_NO = @iParent_Agreement_No
			
			
				--if @iCurrent_Agreement_No is null
				if @@ROWCOUNT =0
					break
				
				insert into @tblRewriteSelect(ID, Parent_Agreement_No, Current_Agreement_No )
				values(@iCount, @iParent_Agreement_No,@iCurrent_Agreement_No)
				
				select 	@iParent_Agreement_No = @iCurrent_Agreement_No			
			end
			
		
			
	END
--BC
	else IF EXISTS(SELECT PARENT_EXTEND_AGREEMENT_NO FROM BcLive..AGREEMENTS(NOLOCK) WHERE AGREEMENT_NO = @iAgreementNo)
	BEGIN
			
			SELECT @iParent_Agreement_No = PARENT_EXTEND_AGREEMENT_NO FROM BcLive..AGREEMENTS(NOLOCK) WHERE AGREEMENT_NO = @iAgreementNo
			insert into @tblRewrite(ID, Parent_Agreement_No, Current_Agreement_No )
			values(@iCount, @iParent_Agreement_No,@iAgreementNo)
			
			select @iCurrent_Agreement_No = @iParent_Agreement_No
			
			while (@iCurrent_Agreement_No >0)
			begin
			
				select @iCount = @iCount + 1
				
				SELECT @iParent_Agreement_No = PARENT_EXTEND_AGREEMENT_NO FROM BcLive..AGREEMENTS(NOLOCK) WHERE AGREEMENT_NO = @iCurrent_Agreement_No
			
				if @@ROWCOUNT = 0
					break

				insert into @tblRewrite(ID, Parent_Agreement_No, Current_Agreement_No )
				values(@iCount, @iParent_Agreement_No,@iCurrent_Agreement_No)
				
				select @iCurrent_Agreement_No = @iParent_Agreement_No
			end
			
			insert into @tblRewriteSelect(ID,Parent_Agreement_No, Current_Agreement_No )
			select ROW_NUMBER()over( order by ID desc) RewriteStep, Parent_Agreement_No, Current_Agreement_No
			from @tblRewrite
			--for next.
			
			select @iParent_Agreement_No = @iAgreementNo
			
			SELECT @iCurrent_Agreement_No = AGREEMENT_NO FROM BcLive..AGREEMENTS(NOLOCK) WHERE PARENT_EXTEND_AGREEMENT_NO = @iParent_Agreement_No
			
			if @iCurrent_Agreement_No >0
			begin
			
				select @iCount = @iCount + 1
			
				insert into @tblRewriteSelect(ID, Parent_Agreement_No, Current_Agreement_No )
				values(@iCount, @iParent_Agreement_No,@iCurrent_Agreement_No)
			
			end
			
			select @iParent_Agreement_No =@iCurrent_Agreement_No 
			
			while (@iParent_Agreement_No >0)
			begin
							
				select @iCount = @iCount + 1
				
				SELECT @iCurrent_Agreement_No = AGREEMENT_NO FROM BcLive..AGREEMENTS(NOLOCK) WHERE PARENT_EXTEND_AGREEMENT_NO = @iParent_Agreement_No
			
			
				--if @iCurrent_Agreement_No is null
				if @@ROWCOUNT =0
					break
				
				insert into @tblRewriteSelect(ID, Parent_Agreement_No, Current_Agreement_No )
				values(@iCount, @iParent_Agreement_No,@iCurrent_Agreement_No)
				
				select 	@iParent_Agreement_No = @iCurrent_Agreement_No			
			end
			
		
			
	END
		 
	
	Declare @tblRewriteurl table (
		ID int,
		url varchar(500), 
		inv_amt decimal(18,2),
		rental_in datetime,
		rental_out datetime
		,Debitor_Code int
	)
	
	declare @myInvUrl varchar(500)
	declare @myInvAmt decimal(18,2)
	declare @myRental_In datetime
	declare @myRental_Out datetime
	declare @myDebitor_Code int

 	
		if (select COUNT(*) from @tblRewriteSelect) > 0
		begin
			select @iCount  = 1, @iTotalCount = max(id) from @tblRewriteSelect
			
			while (@iCount <= @iTotalCount )
			begin
				select @iCurrent_Agreement_No = Current_Agreement_No
				from @tblRewriteSelect
				where ID =@iCount
				
				--print convert(varchar(8), @iCount)
		
	 select @myInvUrl = null,
	 @myInvAmt =null,
	 @myRental_In = null,
	 @myRental_Out = null,
	 @myDebitor_Code=null
	
				EXEC [spDIAL_GetInvoiceNo] @AGREEMENTNO =@iCurrent_Agreement_No,@IP_ADDRESS = @IP_ADDRESS, @Invoice_url =@myInvUrl output, @Rental_In = @myRental_In output, @Rental_Out = @myRental_Out output, @Invoice_amt = @myInvAmt output, @DEBITOR_CODE =@myDebitor_Code output
				--EXEC [spDIAL_GetInvoiceNo] @AGREEMENTNO =@iCurrent_Agreement_No, @IP_ADDRESS = @IP_ADDRESS, @Invoice_url =@myInvUrl output
				--print convert(varchar(10), isnull(@myInvAmt,'mytest'))
				--print convert(varchar(10), isnull(@iCurrent_Agreement_No,'mytest'))
				

				insert into  @tblRewriteurl
				values(@iCount, @myInvUrl, @myInvAmt, @myRental_In, @myRental_Out, @myDebitor_Code)
			
				select @iCount = @iCount + 1
			end
		
		if OBJECT_ID('tempdb..#tblDebitor') is not null
			drop table #tblDebitor
	
		Create table #tblDebitor
		(
            Debitor_Name varchar(100),
            Debitor_Code int
		)

		insert into #tblDebitor
		exec spDIAL_GetDebitors @AdjusterId
		
		declare @tempurl varchar(300)
		set @tempurl = 'https://www.mydiscountdial.com/InsuranceInvoices/viewInvoice.aspx?'
			
			select a.Current_Agreement_No as AgreementNo, @tempurl + 'i='+convert(varchar(20), convert(bigint, i.INVOICE_NO))+'&t=C&c='+convert(varchar(10), convert(bigint, i.DAC_ENTRY_ID)) as InvoiceURL, i.InvoiceAmount InvoiceAmount, b.rental_out as Rental_Out, b.rental_in as Rental_In, 
--			select a.Current_Agreement_No as AgreementNo, b.url as InvoiceURL, i.InvoiceAmount InvoiceAmount, b.rental_out as Rental_Out, b.rental_in as Rental_In, 
			i.INVOICE_NO , i.ACKNOWLEDGE, i.DISPUTE  
			from @tblRewriteSelect a inner join @tblRewriteurl b on a.ID = b.ID
			left join dbo.vw_DIAL_invoices_withtype i on i.AGREEMENT_NO = a.Current_Agreement_No
			where invtype = 'C'
			and exists(
			select 1 from #tblDebitor c(nolock) where c.Debitor_Code = i.DEBITOR_NO
			)
			
			drop table #tblDebitor
		end
	
		
	
	

	
END

