USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_GetInvoiceNo]    Script Date: 04/05/2018 09:36:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
declare @myInvUrl varchar(500)
declare @myInvAmt decimal(18,2)
declare @myRental_In datetime
declare @myRental_Out datetime

 EXEC [spDIAL_GetInvoiceNo] @AGREEMENTNO =3530017367,@IP_ADDRESS = '150.21.12.12', @Invoice_url =@myInvUrl output, @Rental_In = @myRental_In output, @Rental_Out = @myRental_Out output, @Invoice_amt = @myInvAmt output
 select @myInvUrl, @myInvAmt, @myRental_In, @myRental_Out
 */
ALTER PROCEDURE [dbo].[spDIAL_GetInvoiceNo] 
	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
	@AGREEMENTNO VARCHAR(15),
	@IP_ADDRESS VARCHAR(20),
	@Invoice_url varchar(500) output,
	@Rental_In datetime output,
	@Rental_Out datetime output,
	@Invoice_amt decimal(18,2) output
	,@DEBITOR_CODE int	output	
AS
BEGIN
	SET NOCOUNT ON;
		
	BEGIN
	
		declare @InvoiceURL varchar(300)	
		declare @RemedyEntryID bigint	
		
		set @remedyEntryId = 0
		
		select @RemedyEntryID = claim_no from ontariolive..agreements (nolock) where agreement_no =  @AGREEMENTNO
		
		if isnull(@RemedyEntryID, 0)  = 0	
		select @RemedyEntryID = claim_no from albertalive..agreements (nolock) where agreement_no =  @AGREEMENTNO	
		
		if isnull(@RemedyEntryID, 0)  = 0	
		select @RemedyEntryID = claim_no from MaritimesLive..agreements (nolock) where agreement_no =  @AGREEMENTNO	
		
		if isnull(@RemedyEntryID, 0)  = 0	
		select @RemedyEntryID = claim_no from SaskatchewanLive..agreements (nolock) where agreement_no =  @AGREEMENTNO	
		
		if isnull(@RemedyEntryID, 0)  = 0	
		select @RemedyEntryID = claim_no from BCLive..agreements (nolock) where agreement_no =  @AGREEMENTNO			
		
		set @InvoiceURL = 'https://www.mydiscountdial.com/InsuranceInvoices/viewInvoice.aspx'
					
		
		select @Invoice_url = Inv_Url, @Invoice_amt = Inv_Amt, @Rental_Out = dbo.convertToDate(Rental_Out),  @Rental_In = dbo.convertToDate(Rental_In)
		,@DEBITOR_CODE =DEBITOR_CODE
		from
		(
		SELECT @InvoiceURL+'?i='+ CONVERT(varchar(20), convert(bigint,INVOICE_NO))+'&t=C'+'&c='+CONVERT(varchar(20), convert(bigint,@RemedyEntryID)) as Inv_Url
		,INVOICE_AMOUNT as Inv_Amt, c.CHECK_OUT_DATE as Rental_Out, c.CHECK_IN_DATE  as Rental_In, A.DEBITOR_NO DEBITOR_CODE
        FROM INVOICES A (NOLOCK) 
        left join branches  b (nolock) on b.BRANACH_CODE = left(cast(cast(A.Agreement_No as bigint) as varchar(15)), 3) 
        left join debitors d (nolock) on d.debitor_code = a.DEBITOR_NO
        left join AGREEMENTS c (nolock) on c.AGREEMENT_NO = a.AGREEMENT_NO
        WHERE a.INVOICE_TYPE = 'C' --AND DEBITOR_NO=@DEBITOR_CODE  
        AND LTRIM(RTRIM(D.DEBITOR_TYPE)) = 'O'
        AND a.AGREEMENT_NO=@AGREEMENTNO 
        AND 
        NOT EXISTS(
        SELECT 1
        FROM INVOICES B (NOLOCK) 
        WHERE INVOICE_TYPE = 'C' --AND DEBITOR_NO=@DEBITOR_CODE 
        AND A.INVOICE_NO = B.APPLY_TO_INVOICE_NO
        )
        AND A.APPLY_TO_INVOICE_NO =0
        UNION
        SELECT @InvoiceURL+'?i='+ CONVERT(varchar(20), convert(bigint,INVOICE_NO))+'&t=C'+'&c='+CONVERT(varchar(20), convert(bigint,@RemedyEntryID)) as Inv_Url
        ,INVOICE_AMOUNT as Inv_Amt, c.CHECK_OUT_DATE as Rental_Out, c.CHECK_IN_DATE  as Rental_In, A.DEBITOR_NO DEBITOR_CODE
        FROM albertalive..INVOICES A (NOLOCK) 
        left join albertalive..branches  b (nolock) on b.BRANACH_CODE = left(cast(cast(A.Agreement_No as bigint) as varchar(15)), 3) 
        left join albertalive..debitors d (nolock) on d.debitor_code = a.DEBITOR_NO 
        left join albertalive..AGREEMENTS c (nolock) on c.AGREEMENT_NO = a.AGREEMENT_NO
        WHERE a.INVOICE_TYPE = 'C' --AND DEBITOR_NO=@DEBITOR_CODE 
        AND LTRIM(RTRIM(D.DEBITOR_TYPE)) = 'O'
        AND a.AGREEMENT_NO=@AGREEMENTNO 
        AND 
        NOT EXISTS(
        SELECT 1
        FROM albertalive..INVOICES B (NOLOCK) 
        WHERE INVOICE_TYPE = 'C' --AND DEBITOR_NO=@DEBITOR_CODE 
        AND A.INVOICE_NO = B.APPLY_TO_INVOICE_NO
        )
        AND A.APPLY_TO_INVOICE_NO =0
        UNION
        SELECT @InvoiceURL+'?i='+ CONVERT(varchar(20), convert(bigint,INVOICE_NO))+'&t=C'+'&c='+CONVERT(varchar(20), convert(bigint,@RemedyEntryID)) as Inv_Url
        ,INVOICE_AMOUNT as Inv_Amt, c.CHECK_OUT_DATE as Rental_Out, c.CHECK_IN_DATE  as Rental_In, A.DEBITOR_NO DEBITOR_CODE
        FROM MaritimesLive..INVOICES A (NOLOCK) 
        left join MaritimesLive..branches  b (nolock) on b.BRANACH_CODE = left(cast(cast(A.Agreement_No as bigint) as varchar(15)), 3) 
        left join MaritimesLive..debitors d (nolock) on d.debitor_code = a.DEBITOR_NO 
        left join MaritimesLive..AGREEMENTS c (nolock) on c.AGREEMENT_NO = a.AGREEMENT_NO
        WHERE a.INVOICE_TYPE = 'C' --AND DEBITOR_NO=@DEBITOR_CODE 
        AND LTRIM(RTRIM(D.DEBITOR_TYPE)) = 'O'
        AND a.AGREEMENT_NO=@AGREEMENTNO 
        AND 
        NOT EXISTS(
        SELECT 1
        FROM MaritimesLive..INVOICES B (NOLOCK) 
        WHERE INVOICE_TYPE = 'C' --AND DEBITOR_NO=@DEBITOR_CODE 
        AND A.INVOICE_NO = B.APPLY_TO_INVOICE_NO
        )
        AND A.APPLY_TO_INVOICE_NO =0
        UNION
        SELECT @InvoiceURL+'?i='+ CONVERT(varchar(20), convert(bigint,INVOICE_NO))+'&t=C'+'&c='+CONVERT(varchar(20), convert(bigint,@RemedyEntryID)) as Inv_Url
        ,INVOICE_AMOUNT as Inv_Amt, c.CHECK_OUT_DATE as Rental_Out, c.CHECK_IN_DATE  as Rental_In, A.DEBITOR_NO DEBITOR_CODE
        FROM StCatharines..INVOICES A (NOLOCK) 
        left join StCatharines..branches  b (nolock) on b.BRANACH_CODE = left(cast(cast(A.Agreement_No as bigint) as varchar(15)), 3) 
        left join StCatharines..debitors d (nolock) on d.debitor_code = a.DEBITOR_NO 
        left join StCatharines..AGREEMENTS c (nolock) on c.AGREEMENT_NO = a.AGREEMENT_NO
        WHERE a.INVOICE_TYPE = 'C' --AND DEBITOR_NO=@DEBITOR_CODE 
        AND LTRIM(RTRIM(D.DEBITOR_TYPE)) = 'O'
        AND a.AGREEMENT_NO=@AGREEMENTNO 
        AND 
        NOT EXISTS(
        SELECT 1
        FROM StCatharines..INVOICES B (NOLOCK) 
        WHERE INVOICE_TYPE = 'C' --AND DEBITOR_NO=@DEBITOR_CODE 
        AND A.INVOICE_NO = B.APPLY_TO_INVOICE_NO
        )
        AND A.APPLY_TO_INVOICE_NO =0
        UNION
        SELECT @InvoiceURL+'?i='+ CONVERT(varchar(20), convert(bigint,INVOICE_NO))+'&t=C'+'&c='+CONVERT(varchar(20), convert(bigint,@RemedyEntryID)) as Inv_Url
        ,INVOICE_AMOUNT as Inv_Amt, c.CHECK_OUT_DATE as Rental_Out, c.CHECK_IN_DATE  as Rental_In, A.DEBITOR_NO DEBITOR_CODE
        FROM SaskatchewanLive..INVOICES A (NOLOCK) 
        left join SaskatchewanLive..branches  b (nolock) on b.BRANACH_CODE = left(cast(cast(A.Agreement_No as bigint) as varchar(15)), 3) 
        left join SaskatchewanLive..debitors d (nolock) on d.debitor_code = a.DEBITOR_NO 
        left join SaskatchewanLive..AGREEMENTS c (nolock) on c.AGREEMENT_NO = a.AGREEMENT_NO
        WHERE a.INVOICE_TYPE = 'C' --AND DEBITOR_NO=@DEBITOR_CODE 
        AND LTRIM(RTRIM(D.DEBITOR_TYPE)) = 'O'
        AND a.AGREEMENT_NO=@AGREEMENTNO 
        AND 
        NOT EXISTS(
        SELECT 1
        FROM SaskatchewanLive..INVOICES B (NOLOCK) 
        WHERE INVOICE_TYPE = 'C' --AND DEBITOR_NO=@DEBITOR_CODE 
        AND A.INVOICE_NO = B.APPLY_TO_INVOICE_NO
        )
        AND A.APPLY_TO_INVOICE_NO =0
        
        ) t
	END 
END

