USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Dominion_downloadinvoices]    Script Date: 04/05/2018 09:34:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--  exec [spDIAL_Dominion_downloadinvoices]
ALTER Proc [dbo].[spDIAL_Dominion_downloadinvoices] 
as

DECLARE @InvoiceURL VARCHAR(200)	

set @InvoiceURL = 'https://www.mydiscountdial.com/InsuranceInvoices/viewInvoice.aspx?'
		
select DAC_ENTRY_ID, 
case 
when OK_TO_BILL = 1 then @InvoiceURL+ 'c='+CONVERT(varchar(20), convert(bigint, DAC_ENTRY_ID))+'&'+case 
when DAC_ARS_WEB != 'Y' then 't=C&i='+CONVERT(varchar(20), convert(bigint, INVOICE_NO))  
when DAC_ARS_WEB = 'Y' then 't=E&i='+CONVERT(varchar(20), convert(bigint, DAC_ENTRY_ID)) end 
else '' end as URL ,
case when iswrite = 'Y' then f.AGREEMENT_NO 
else DAC_AGREEMENT_NUMBER 
end 
as DAC_AGREEMENT_NUMBER, DAC_POLICY, DAC_INS_CLAIM
,case 
		when (c.dac_ars_web = 'y')then 
			e.total
		else
			i.invoice_amount
		end 
	as invoice_total ,
	case 
		when (c.dac_ars_web = 'y')then 
			e.ENTRY_ID
		else
			i.INVOICE_NO
		end 
	as InvoiceNo, iswrite   
from tblDIAL_Zip_ftp f 
left join da_claims c on c.dac_entry_id = f.entry_id 
left join dbo.BRANCHES (nolock) B on b.BRANACH_CODE= c.DAC_LOCATION_CODE
left join dbo.vw_dial_inv i (nolock) 
on i.agreement_no = case when iswrite = 'Y' then f.Agreement_No else c.dac_agreement_number end 
left join dbo.ebilling_invoice_data e on e.entry_id = c.dac_entry_id	
where files_created = 'N'  and ((i.INVOICE_TYPE='C' and i.INV_STATUS!=9 and I.INVOICE_NO!=0) or e.TOTAL >=0)	




