USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_MyFiles_SearchAll]    Script Date: 04/05/2018 09:38:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






-- exec spDIAL_MyFiles  @Action = null, @AdjusterID = 32409, @ClientLastName = null, @sPolicy_Claim_No = null, @iAgreementNo = null, @iDebitorCode=null, @iExpiringInDay = null, @iStatus = 2, @ddAdjusterID=null

--select * from DA_ADJUSTER where DAA_FIRST_NAME = 'Aaron'

-- exec spDIAL_MyFiles 'TODO', 17724, null, null, null, 16837, null, null
-- exec spDIAL_MyFiles  @Action = null, @AdjusterID = 17724, @ClientLastName = 'ri', @sPolicy_Claim_No = null, @iAgreementNo = null, @iDebitorCode=null, @iExpiringInDay = null, @iStatus = null, @ddAdjusterID=null
-- exec spDIAL_MyFiles  @Action = null, @AdjusterID = 17724, @sPolicy_Claim_No = null, @ClientLastName = null, @iAgreementNo = null, @iDebitorCode= null, @iExpiringInDay = 2, @iStatus = null
-- exec spDIAL_MyFiles  @Action = null, @AdjusterID = 17724, @ClientLastName = null, @sPolicy_Claim_No = null, @iAgreementNo = null, @iDebitorCode=null, @iExpiringInDay = null, @iStatus = 2, @ddAdjusterID=null

-- =============================================
-- Create date: <Jan 21, 2013 spDIAL_MyFiles>
-- Description:	<My Files (To Do, Completed, Invoices, Unassigned)>
-- =============================================
--EXEC spDIAL_MyFiles 'TODO' ,'17724' 
--EXEC spDIAL_MyFiles @Action='TODO' ,@AdjusterID='17724',@iExpiringInDay =0
--EXEC spDIAL_MyFiles 'Completed', '17724'
--EXEC spDIAL_MyFiles 'Invoices' ,'17724'
--EXEC spDIAL_MyFiles @Action='Invoices' ,@AdjusterID='17724',@iExpiringInDay =0
--EXEC spDIAL_MyFiles 'UNASSIGNED', '17724'
--EXEC spDIAL_MyFiles @Action='UNASSIGNED' ,@AdjusterID='17724',@iExpiringInDay =0
--EXEC spDIAL_MyFiles @Action = null, @sPolicy_Claim_No = '3146860' , @AdjusterID ='17724', @iExpiringInDay =0
--0 - NEW, 1-BOOKED, 2-ACTIVE, 3-EXPIRED, 4-INACTIVE, 5-CANCELLED, 6-ABEND	 
ALTER PROCEDURE [dbo].[spDIAL_MyFiles_SearchAll]	
@Action varchar(15), @AdjusterID INT =null
, @sPolicy_Claim_No varchar(30) = null,
@ClientLastName varchar(70) = null, 
@iAgreementNo bigint = null,
@iDebitorCode int = null, 
@iExpiringInDay int =null
,@iStatus int =null
,@Ip_Address varchar(20) = null,
@ddAdjusterID int  = 0

--@AgrFromDate datetime = null, @AgrToDate datetime = null, 
--@InvoiceFromDate datetime  = null, @InvoiceToDate datetime  = null,
--@debitorName varchar(200) = '', @AdjusterLastName varchar(70) = '',
--@LocCode int = 0, @ReservationNo varchar(12) = ''
AS
BEGIN	
	SET NOCOUNT ON;
	
	declare @InvoiceURL varchar(1000)	
	
	Declare @AdjName as varchar(100)
		
--	select @AdjName = (select top 1 DAC_COMPANY_ADJ_FIRST_NAME + ' ' + DAC_COMPANY_ADJ_LAST_NAME from DA_CLAIMS (nolock) where DAC_COMPANY_ADJUSTER_ID=@AdjusterID and ltrim(rtrim(DAC_COMPANY_ADJ_FIRST_NAME)) !='' and ltrim(rtrim(DAC_COMPANY_ADJ_LAST_NAME)) !='' )

    select @AdjName = (select top 1 DAA_FIRST_NAME + ' ' + DAA_LAST_NAME from DA_ADJUSTER (nolock) where DAA_ENTRY_ID=@AdjusterID)
	
	if @Action is not null 
		set @Action = LTRIM(rtrim(@Action))
	
	if @sPolicy_Claim_No is not null 
		set @sPolicy_Claim_No = LTRIM(rtrim(@sPolicy_Claim_No))
		
	if @ClientLastName is not null 
		set @ClientLastName = LTRIM(rtrim(@ClientLastName))
		
	if @Ip_Address is not null 
		set @Ip_Address = LTRIM(rtrim(@Ip_Address))	
		
	if left(@Ip_Address, 3) = '150' or left(@Ip_Address, 3) = '127' or @Ip_Address = '98.143.109.68' or @Ip_Address = '206.186.78.76'
		--set @InvoiceURL = 'https://150.8.111.247/Setup/PrintInvoiceForEntryId.dpp?entryId='
		--set @InvoiceURL='https://dial.discountcar.com/Setup/PrintInvoiceForEntryId.dpp?entryId='
		set @InvoiceURL='http://150.8.111.246:8080/Setup/PrintInvoiceForEntryId.dpp?entryId='
	else
		set @InvoiceURL	= 'http://98.143.109.78:8080/Setup/PrintInvoiceForEntryId.dpp?entryId='
		--set @InvoiceURL = 'https://150.8.111.247/Setup/PrintInvoiceForEntryId.dpp?entryId='
		--set @InvoiceURL='https://dial.discountcar.com/Setup/PrintInvoiceForEntryId.dpp?entryId='
		--set @InvoiceURL='http://150.8.111.246:8080/Setup/PrintInvoiceForEntryId.dpp?entryId='
		
	if @ddAdjusterID> 0 	
		select @AdjusterID = @ddAdjusterID	
		
	declare @Parent_Debitor_Code bigint
		
	select @Parent_Debitor_Code = d.SUV_DEBITOR_OF  
    from dbo.debitors d (nolock) 
    left join ADJUSTER_DEBITORS adj (nolock) on (adj.INS_COMPANY_ID = d.SUV_DEBITOR_OF or adj.INS_COMPANY_ID = d.DEBITOR_CODE)
    left join  dbo.debitors_section2 s (nolock) on s.debitor_code = d.debitor_code 
    where debitor_type = 'o' and in_stop_list = 'a' 
    and adj.ADJUSTER_ID = @AdjusterId    
		
	--to do means 1. more auth 2. acknoledge and pay for the file.
	if @Action = 'TODO'
	--if rewrite, ok_to_bill should be 0 if current agreement still open(agreement status 0,1,2) 
	BEGIN
	
		--SELECT D.OK_TO_BILL AS okToBill,ISNULL(R.STATUS_CODE,0) AS dacRentalAgrStatus,ISNULL(ISNULL(V.ACKNOWLEDGE,EB.ACKNOWLEDGE),'N') AS acknowledge  , ISNULL(ISNULL(V.DISPUTE,EB.DISPUTE),'N') AS dispute,ISNUll((SELECT TOP 1 'Y' FROM EBILLING_INVOICE_DATA E WHERE E.ENTRY_ID=DAC_ENTRY_ID),'N') AS ebillrecPresent,
		select 
		case 
		when isRewrite = 1 and STATUS_CODE in (4) then 'Invoice'
		when isRewrite = 1 and STATUS_CODE in (0,1,2,3) then 'Expired' 		
		when isRewrite =1 and rentaldays > dacAuthorDays then 'Expired'
		when dacRentalAgrStatus = 3 then 'Expired' when dacRentalAgrStatus =4 then 'Invoice' 
		end [Status_desc]		
		, dacRentalAgrStatus [Status], isnull(dacClientFirstName,'') + ' ' + ISNULL(dacClientLastName,0) [Client Name]
		, dacAgreementNumber [Agreement No]
		, dacinsclaim [Claim #]
		, dacPolicy [Policy #]
		, dbo.fn_ConvertYYYYMMDDtoDIAL(dacAgreementOpenDate) [Rental Out]
		, dbo.fn_ConvertYYYYMMDDtoDIAL(dacAgreementCloseDate) [Rental In]
		,case when rentaldays < 0 then 0 else rentaldays end as [Rental Days]
		,convert(decimal(18,2),dacAuthorizedRate) [Auth Rate]
		, dacAuthorDays [Auth Days]
		,[Auth Total]
		,convert(decimal(18,2),case when totalRental < 0 then 0 else totalRental end) as [Total Rental (incl. Tax)]
		, isnull(dacCompanyAdjFirstName,'') + ' ' + isnull(dacCompanyAdjLastName,'') [Adjuster Name]
		,0  [HasNotes] --??
		--, case when dacAgreementNumber = 0 then null else [ExpiringinDays] end as [ExpiringinDays]
		---- added by Lakshmi to exclude invoices turning yellow
		,
		case 
			when isRewrite = 1 and STATUS_CODE in (4) then null
			when isRewrite = 1 and STATUS_CODE in (0,1,2,3) then [ExpiringinDays]  		
			when isRewrite =1 and rentaldays > dacAuthorDays then [ExpiringinDays] 								
			when okToBill = 1 then null			
			else
			[ExpiringinDays] end as [ExpiringinDays] 		
		, case 
			when isRewrite = 1 and STATUS_CODE in (4) then 1
			when isRewrite = 1 and STATUS_CODE in (0,1,2,3) then 0 
			when isRewrite = 1  and rentaldays > dacAuthorDays then 0 
			else okToBill 
			end OkToBill
		, case when isRewrite = 1 then '' else acknowledge end Acknowledge
		, case when isRewrite = 1 then '' else Dispute end Dispute
		,ebillrecPresent EbillingPresent
		,dacReservationNo ReservationNo
		,dacTaxPaidBy TaxPaidBy
		,dacLocationName BranchName
		,dacMake InsuredVehicleMake
		,dacModel InsuredVehicleModel
		,dacYear InsuredVehicleYear
		,dacRentalMake RentalMake
		,dacRentalModel RentalModel
		,dacRentalYear RentalYear
		,dacEquivalentGroup VehicleEquivalentClass
		,dacArsWeb IsFranchise
		,dacEntryId ClaimEntryId
		,dacInsCompanyName InsCompanyName
		,invoiceNo InvoiceNo
		, LocationName
		, FinalAuth,
		case when okToBill = 1 and not (isRewrite = 1 and STATUS_CODE in (0,1,2)) then @InvoiceURL+CONVERT(varchar(20), convert(bigint, dacEntryId))
		else '' end as InvoiceLink
		, isRewrite
		from
		(
		SELECT D.OK_TO_BILL AS okToBill,d.DAC_STATUS AS dacRentalAgrStatus,ISNULL(ISNULL(V.ACKNOWLEDGE,EB.ACKNOWLEDGE),'N') AS acknowledge  , ISNULL(ISNULL(V.DISPUTE,EB.DISPUTE),'N') AS dispute, case when EB.Entry_ID IS not null  then 'Y' else 'N' end  AS ebillrecPresent,
                  CASE 
            WHEN r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=0 OR R.STATUS_CODE=4)  THEN 
                   Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.[Agreement_Open_Time],CONVERT(DATETIME,CONVERT(VARCHAR,rw.[Agreement_Open_Date],112))), DATEADD(SECOND,R.CHECK_IN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,R.CHECK_IN_DATE,112))))
            WHEN r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=1 OR R.STATUS_CODE=2)  THEN 
                  Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.[Agreement_Open_Time],CONVERT(DATETIME,CONVERT(VARCHAR,rw.[Agreement_Open_Date],112))), GETDATE())
            WHEN D.DAC_ARS_WEB != 'Y' AND (R.STATUS_CODE=0 OR R.STATUS_CODE=4 ) AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000'
            THEN ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))))
            WHEN D.DAC_ARS_WEB != 'Y' AND (R.STATUS_CODE=0 OR R.STATUS_CODE=4 ) 
            THEN ISNULL(R.SOLD_DAYS,0)
                        WHEN R.STATUS_CODE IN (1,2)
			THEN ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()), 0)
            WHEN D.DAC_STATUS IN(3,4) AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000' --EXPIRED AND CLOSED
            THEN Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))
            
            WHEN D.DAC_STATUS <= 3 AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000'  THEN --OPEN CONTRACT THEN 
                  ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()), 0)
			ELSE NULL
                  --ISNULL(DATEDIFF(DAY,dbo.convertToDate(D.DAC_AGR_OPEN_DATE),GETDATE()),0) 
            END AS rentaldays ,
                 CASE 
							when r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=0 OR R.STATUS_CODE=4)  --previous closed and preclosed amount plus current open to date amount including extra, insurance and tax
							THEN                              
								isnull(rw.Rental_Amount,0.0) 
							when r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=1 OR R.STATUS_CODE=2)  --previous closed and preclosed amount plus current open to date amount including extra, insurance and tax
							THEN                              
								isnull(rw.Rental_Amount,0.0) +  (Carpro_App.dbo.fn_Min_Values(rw.Rate,dauth.DCA_AUTHOR_RATE) +  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0))*Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.[Agreement_Current_Open_TIME],CONVERT(DATETIME,CONVERT(VARCHAR,rw.[Agreement_Current_Open_Date],112))), GETDATE()) * (1.0+ ISNULL(dauth.VAT_PER,0.0)/100.0)   
                            WHEN D.DAC_ARS_WEB!='Y' AND  R.STATUS_CODE=4
                            THEN V.INVOICE_AMOUNT
                            WHEN D.DAC_ARS_WEB!='Y' AND  R.STATUS_CODE=0
                            THEN R.Debitor_Total
                            WHEN D.DAC_ARS_WEB ='Y' AND  D.DAC_STATUS=4
							THEN	EB.TOTAL
							WHEN D.DAC_ARS_WEB ='Y' AND  D.DAC_STATUS=3 AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000' AND (ISNULL(DAUTH.DCA_AUTHOR_RATE,0)=0 OR ISNULL(DAUTH.dca_a_days,0)=0)  --EXPIRED
							THEN	
								ROUND((ISNULL(Carpro_App.dbo.fn_Max_Values(D.DAC_RENTAL_RATE_OUT, D.DAC_RATE_OUT),0)+  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0)) * Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))) * (1.0 +ISNULL(dauth.VAT_PER,0.0)/100.0) ,2)
								
							WHEN D.DAC_ARS_WEB ='Y' AND  D.DAC_STATUS=3 AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND (ISNULL(DAUTH.DCA_AUTHOR_RATE,0)=0 OR ISNULL(DAUTH.dca_a_days,0)=0)  --EXPIRED
							THEN	
								ROUND((ISNULL(Carpro_App.dbo.fn_Max_Values(D.DAC_RENTAL_RATE_OUT, D.DAC_RATE_OUT),0)+  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0)) * Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), Getdate()) * (1.0 +ISNULL(dauth.VAT_PER,0.0)/100.0) ,2)							
							WHEN D.DAC_ARS_WEB ='Y' AND  D.DAC_STATUS=3 AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000' --EXPIRED
							THEN	
								ROUND((ISNULL(dauth.DCA_AUTHOR_RATE,0)+  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0)) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))) * (1.0 +ISNULL(dauth.VAT_PER,0.0)/100.0) ,2)
                            --Corp                            
							WHEN D.DAC_ARS_WEB !='Y' AND  D.DAC_STATUS=3 AND R.STATUS_CODE IN (1,2)   --EXPIRED
							THEN
								ROUND((ISNULL(Carpro_App.dbo.fn_min_Values(D.DAC_RENTAL_RATE_OUT, dauth.DCA_AUTHOR_RATE), 0) +  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0)) * Carpro_App.dbo.fn_Cal_hourly_RentalDays(b.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), Getdate()) * (1.0 +ISNULL(dauth.VAT_PER,0.0)/100.0) ,2)                          	
								--ROUND( R.Debitor_Total,2)                            
                            WHEN  D.DAC_STATUS <= 3 AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000'  --OPEN CONTRACT
							THEN	ROUND((ISNULL(dauth.DCA_AUTHOR_RATE,0)+  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0)) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE())) * (1.0 +ISNULL(dauth.VAT_PER,0.0)/100.0) ,2)
                            ELSE NULL      
            end AS totalRental ,
            ISNULL(dauth.dca_a_days,0) AS dacAuthorDays,
            D.DAC_RESERVATION_NO AS dacReservationNo,
            D.DAC_AGREEMENT_NUMBER AS dacAgreementNumber,
            D.DAC_CLIENT_LAST_NAME AS dacClientLastName,
            D.DAC_CLIENT_FIRST_NAME AS dacClientFirstName,
            CASE
				WHEN r.PARENT_EXTEND_AGREEMENT_NO>0 THEN
					rw.[Agreement_Open_Date]
				ELSE D.DAC_AGR_OPEN_DATE 
            END  AS dacAgreementOpenDate,
            CASE 
                  WHEN ((D.DAC_ARS_WEB!='Y' AND R.STATUS_CODE=0 or R.STATUS_CODE=4) OR      (D.DAC_ARS_WEB='Y' AND D.DAC_AGR_CLOSE_DATE >'00000000')) and D.DAC_AGR_CLOSE_DATE >'00000000' THEN D.DAC_AGR_CLOSE_DATE
                  WHEN ((D.DAC_ARS_WEB!='Y' AND R.STATUS_CODE=0 or R.STATUS_CODE=4) ) and R.CHECK_IN_DATE > '00000000' THEN R.CHECK_IN_DATE
                  ELSE '00000000'
            END   AS dacAgreementCloseDate,
            ISNULL(dauth.DCA_AUTHOR_RATE,0) AS dacAuthorizedRate,
            D.DAC_TAX_PAID_BY AS dacTaxPaidBy,            
            DA.DAA_LAST_NAME AS dacCompanyAdjLastName,
            DA.DAA_FIRST_NAME AS dacCompanyAdjFirstName,
            D.DAC_POLICY AS dacPolicy,
            D.DAC_INS_CLAIM AS dacInsClaim,
            D.DAC_LOCATION_NAME AS dacLocationName,
            D.DAC_MAKE AS dacMake,
            D.DAC_MODEL AS dacModel,
            D.DAC_YEAR AS dacYear,
            D.DAC_RENTAL_MAKE AS dacRentalMake,
            D.DAC_RENTAL_MODEL AS dacRentalModel,
            D.DAC_RENTAL_YEAR AS dacRentalYear,
            D.DAC_EQUIVALENT_GROUP AS dacEquivalentGroup,
            D.DAC_STATUS AS dacStatus,
            D.DAC_ARS_WEB AS dacArsWeb,
            D.DAC_ENTRY_ID AS dacEntryId,
            D.DAC_INVOICE_DATE AS  dacInvoiceDate,            
            DB1.DEBITOR_NAME AS dacInsCompanyName,
            ISNULL(V.INVOICE_NO,0) AS invoiceNo
            , Case             
            when dauth.DCA_AUTHOR_TO_DATE >'00000000' and r.STATUS_CODE = 0 then 
            datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112))) 
			-- when D.DAC_STATUS= 4 then null -- Lakshmi commented on 28june 2013			
			when dauth.DCA_AUTHOR_TO_DATE >'00000000' 
			then datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112))) 			
			when D.DAC_STATUS= 3 and  DAC_AGR_OPEN_DATE > '00000000' then 
				case
					when  convert(varchar(8), GETDATE(),112) = d.DAC_AGR_OPEN_DATE and datediff(day, convert(date,getdate()), dateadd(day, isnull(dauth.dca_a_days, 0),  convert(datetime, convert(varchar(8), d.DAC_AGR_OPEN_DATE,112)))) =0
					then -1
					else datediff(day, convert(date,getdate()), dateadd(day, isnull(dauth.dca_a_days, 0),  convert(datetime, convert(varchar(8), d.DAC_AGR_OPEN_DATE,112)))) 					
					end 
		  -- Lakshmi commented on 28june 2013
            else  null end [ExpiringinDays]
            --48 Hour query also includes status =2, therefore, not in this query
    --        case when dauth_time.DCA_AUTHOR_TO_DATE > '00000000' then DATEDIFF(HOUR, GETDATE(), DATEADD(SECOND, dauth_time.DAC_AUTHOR_TO_TIME,convert(datetime,dauth_time.DCA_AUTHOR_TO_DATE,112)))
				--else null end
    --        as AuthDuebyHour
	, D.DAC_LOCATION_NAME LocationName
		, D.FINAL_AUTH FinalAuth
--, CASE WHEN NH.DCN_CLAIM_ID is not null THEN 1 ELSE 0 END HasNotes
, isnull(dauth.DCA_TOTAL_RENTAL,d.DAC_AUTHORIZED_RATE*d.DAC_AUTHOR_DAYS)  AS [Auth Total]
, CASE WHEN R.PARENT_EXTEND_AGREEMENT_NO>0 THEN 1 ELSE 0 END isRewrite
, R.STATUS_CODE
            FROM DA_CLAIMS D(NOLOCK)
                  LEFT OUTER JOIN RemedeyAgr_Rewrite R(NOLOCK) ON R.AGREEMENT_NO = D.DAC_AGREEMENT_NUMBER
                  left join DEBITORS b(nolock) on D.DAC_INS_COMPANY_ID = b.DEBITOR_CODE
                  left join Carpro_App..tblDial_RewriteWarehouse rw(nolock) on rw.Current_Agreement_No = D.DAC_AGREEMENT_NUMBER
                  LEFT OUTER JOIN Vw_Dial_Inv V(NOLOCK) ON V.AGREEMENT_NO = D.DAC_AGREEMENT_NUMBER AND V.INVOICE_TYPE = 'C' AND V.INV_STATUS != 9 AND D.DAC_INS_COMPANY_ID = v.DEBITOR_NO
                  LEFT OUTER JOIN EBILLING_INVOICE_DATA EB(NOLOCK) on EB.Entry_ID = D.DAC_ENTRY_ID
                  LEFT OUTER JOIN (SELECT da.DCA_CLAIM_ID,ISNULL(AVG(VAT_PER),0)VAT_PER,ISNULL(SUM(dca_a_days),0) dca_a_days,ISNULL(AVG(DCA_AUTHOR_RATE),0) DCA_AUTHOR_RATE,
													MAX(DA.DCA_AUTHOR_TO_DATE) DCA_AUTHOR_TO_DATE
													,SUM(DCA_TOTAL_RENTAL) as DCA_TOTAL_RENTAL
													, MAX(DA.DCA_ENTRY_ID) Last_Auth_ID, max(ltrim(rtrim(FINAL_AUTH))) as FinalAuth_fromAuth
                                                      from DA_AUTHORIZATION da(NOLOCK) where DCA_BILL_TO=1 and (left(DCA_AUTHOR_TO_DATE, 4) > '2000' or DCA_AUTHOR_TO_DATE = '00000000') GROUP BY da.DCA_CLAIM_ID )
                                                      AS dauth ON D.DAC_ENTRY_ID = dauth.DCA_CLAIM_ID
                  Left join (select DAE_AUTH_ENTRY_ID, sum(DAE_PRICE) Auth_Extra_PerDay from [dbo].[DA_AUTHORIZATION_extraS](nolock)
							group by DAE_AUTH_ENTRY_ID	
                  ) AuthExtra on AuthExtra.DAE_AUTH_ENTRY_ID = dauth.Last_Auth_ID
                  Left join (select DAE_AUTH_ENTRY_ID, sum(DAE_PRICE) Auth_Ins_PerDay from [dbo].DA_AUTHORIZATION_INSURANCES(nolock)
							group by DAE_AUTH_ENTRY_ID	
                  ) AuthIns on AuthIns.DAE_AUTH_ENTRY_ID = dauth.Last_Auth_ID              
                              LEFT JOIN DEBITORS DB1(NOLOCK)
                              ON D.DAC_INS_COMPANY_ID = DB1.DEBITOR_CODE
                              LEFT JOIN DA_ADJUSTER DA(NOLOCK)
                              ON D.DAC_COMPANY_ADJUSTER_ID = DA.DAA_ENTRY_ID
                   --LEFT JOIN (
                   --SELECT DCN_CLAIM_ID FROM DA_NOTES_HISTORY(NOLOCK)
                   --WHERE DCN_NOTES_TYPE not in (8)
                   --GROUP BY DCN_CLAIM_ID ) NH
                   --ON 
                   --D.DAC_ENTRY_ID = NH.DCN_CLAIM_ID
                  WHERE 
                  D.[DAC_CREATE_DATE]> CONVERT(VARCHAR(8), GETDATE()-365,112) AND                 
                 --Tim add below for rewrite
                 (
					( r.PARENT_EXTEND_AGREEMENT_NO>0 and  
						(	( R.STATUS_CODE in (0,4) and rw.ACKNOWLEDGE != 'Y' AND rw.DISPUTE != 'Y' AND v.INVOICE_TYPE='C' AND v.INV_STATUS!=9 and (v.BALANCE >0 and v.ACKNOWLEDGE != 'Y') ) --either v.BALANCE=0 or v.Acknoledge ='Y' should not show
							or
							(
								R.STATUS_CODE in (1,2) and dauth.FinalAuth_fromAuth != 'Y' and left(rw.Agreement_Open_Date,4) >'2010' and ISNULL(dauth.dca_a_days,0) < DATEDIFF(DAY,dbo.convertToDate(rw.Agreement_Open_Date),dbo.convertToDate(rw.Agreement_Close_Date)) --modify from R.STATUS_CODE !=9 to R.STATUS_CODE in (1,2). means sometime invoice paid but agent doesn't have final auth
							)
						) 
                  )
					or --below not for rewrtie
                  (          
			 (  D.DAC_STATUS=4 and D.DAC_ARS_WEB!='Y' and (V.ACKNOWLEDGE != 'Y' AND v.DISPUTE != 'Y'  and v.BALANCE > 0 AND v.INVOICE_TYPE='C' AND v.INV_STATUS!=9 ))
			or ( D.DAC_STATUS=4 and D.DAC_ARS_WEB='Y' and EB.DISPUTE != 'Y'    AND EB.ACKNOWLEDGE !='Y'  )
			or ( D.DAC_STATUS=3 and D.DAC_ARS_WEB !='Y' AND (R.STATUS_CODE=0 OR R.STATUS_CODE=4) and ISNULL(dauth.dca_a_days,0) < (DATEDIFF(DAY,dbo.convertToDate(D.dac_agr_open_date),dbo.convertToDate(D.dac_agr_close_date))))
			or ( D.DAC_STATUS=3 and D.DAC_ARS_WEB='Y' AND D.DAC_AGR_CLOSE_DATE > '00000000' and ISNULL(dauth.dca_a_days,0) < (DATEDIFF(DAY,dbo.convertToDate(D.dac_agr_open_date),dbo.convertToDate(D.dac_agr_close_date))))
			or ( D.DAC_STATUS=3 AND dbo.convertToDate(D.DAC_AGR_OPEN_DATE) = CONVERT (CHAR(8),GETDATE(),112) and ISNULL(dauth.dca_a_days,0) < (DATEDIFF(DAY,dbo.convertToDate(D.dac_agr_open_date),GETDATE()+1 )))
			or ( D.DAC_STATUS=3 AND dbo.convertToDate(D.DAC_AGR_OPEN_DATE) != CONVERT (CHAR(8),GETDATE(),112) and ISNULL(dauth.dca_a_days,0) < (DATEDIFF(DAY,dbo.convertToDate(D.dac_agr_open_date),GETDATE() )))
				) 
			)
                        --AND D.DAC_STATUS in(3,4) 
                        and (D.DAC_STATUS =4 or ( D.DAC_STATUS =3  and (FinalAuth_fromAuth is null  or ltrim(rtrim(FinalAuth_fromAuth)) != 'Y')))              
                        and charindex('UNKNOWN',D.DAC_COMPANY_ADJ_FIRST_NAME) =0
                         and charindex('UNKNOWN',D.DAC_COMPANY_ADJ_LAST_NAME) =0
                        AND D.DAC_COMPANY_ADJUSTER_ID > 0
                        --)
                  --)
                 -- AND (@AdjusterID=0 OR D.DAC_COMPANY_ADJUSTER_ID = @AdjusterID)
                  AND ((@ddAdjusterID >= 0 and D.DAC_COMPANY_ADJUSTER_ID = @AdjusterID) 
                  OR (@ddAdjusterID = -1 and D.DAC_COMPANY_ADJUSTER_ID in 
                  (select distinct ADJUSTER_ID from dbo.ADJUSTER_DEBITORS (nolock) 
                  where INS_COMPANY_ID in (SELECT  distinct DEBITOR_CODE FROM debitors where suv_debitor_of =  @Parent_Debitor_Code)))) 
                  --adjuster controled company. 20130618
                  --and (@ddAdjusterID =0 and D.DAC_COMPANY_ADJUSTER_ID in (select ADJUSTER_ID from [ADJUSTER_DEBITORS] (nolock)	where INS_COMPANY_ID= @iDebitorCode)) 
      --            and DAC_INS_COMPANY_ID in (SELECT  		
						--[INS_COMPANY_ID]
						--FROM [dbo].[ADJUSTER_DEBITORS] (nolock)						
						--where (@AdjusterID is null or @AdjusterID = 0 or ADJUSTER_ID = @AdjusterID))
				and DAC_INS_COMPANY_ID in (select distinct debitor_code from dbo.debitors (nolock) where SUV_DEBITOR_OF = @Parent_Debitor_Code)
               	And ( ( @sPolicy_Claim_No IS NULL OR  ((ltrim(rtrim(d.DAC_POLICY)) like + '%' + @sPolicy_Claim_No + '%') or (ltrim(rtrim(d.DAC_INS_CLAIM)) like + '%' + @sPolicy_Claim_No + '%')  or (ltrim(rtrim(d.DAC_ENTRY_ID)) = @sPolicy_Claim_No)))
		        and (@ClientLastName is null or d.DAC_CLIENT_LAST_NAME like +'%' + @ClientLastName + '%' )
				and (@iDebitorCode is null or d.DAC_INS_COMPANY_ID =@iDebitorCode)
			--and (@ddAdjusterID is null or @ddAdjusterID = 0 or d.DAC_COMPANY_ADJUSTER_ID =@ddAdjusterID)		
				and  (@iStatus is null or DAC_STATUS =@iStatus) )
                  ) ttt
                  where 
                  --(@iExpiringInDay is null or not ([ExpiringinDays]is null) )
                  (@iExpiringInDay is null or (@iExpiringInDay =0  and [ExpiringinDays] <= 0 ) or (@iExpiringInDay >0   and [ExpiringinDays] = @iExpiringInDay ))
                  --and Not (STATUS_CODE =0 and  rentaldays <=dacAuthorDays )
                  order by okToBill, dacAgreementNumber
    END 
	
	IF @Action = 'COMPLETED'	
	BEGIN
	
	
			select case 
			when finalAuth = 'Y' then 'Final Auth'
			when rentaldays <= dacAuthorDays then 'Current'
			when dacAgreementNumber > 0 then 'Current'
			else 'Reservation' 
			end [Status_desc],  DACSTATUS [Status], isnull(dacClientFirstName,'') + ' ' + ISNULL(dacClientLastName,0) [Client Name]
		, dacAgreementNumber [Agreement No]
		, dacinsclaim [Claim #]
		, dacPolicy [Policy #]
		, dbo.fn_ConvertYYYYMMDDtoDIAL(dacAgreementOpenDate) [Rental Out]
		, dbo.fn_ConvertYYYYMMDDtoDIAL(dacAgreementCloseDate) [Rental In]
		,case when rentaldays < 0 then 0 else rentaldays end as [Rental Days]
		,convert(decimal(18,2),dacAuthorizedRate) [Auth Rate]
		, dacAuthorDays [Auth Days]
		,[Auth Total]
		,convert(decimal(18,2),case when totalRental < 0 then 0 else totalRental end) as [Total Rental (incl. Tax)]
		, isnull(dacCompanyAdjFirstName,'') + ' ' + isnull(dacCompanyAdjLastName,'') [Adjuster Name]
		,0 [HasNotes] --??
		, case 
		when dacAgreementNumber = 0 then null 
		when finalAuth = 'Y' or (rentaldays = dacAuthorDays) then null
		else [ExpiringinDays] end as [ExpiringinDays]
		--, case when invoiceno is null then 0 else OkToBill end as OkToBill
		, 0 as OkToBill
		, null Acknowledge
		, Null Dispute
		,null EbillingPresent
		,dacReservationNo ReservationNo
		,dacTaxPaidBy TaxPaidBy
		,dacLocationName BranchName
		,dacMake InsuredVehicleMake
		,dacModel InsuredVehicleModel
		,dacYear InsuredVehicleYear
		,dacRentalMake RentalMake
		,dacRentalModel RentalModel
		,dacRentalYear RentalYear
		,dacEquivalentGroup VehicleEquivalentClass
		,dacArsWeb IsFranchise
		,dacEntryId ClaimEntryId
		,dacInsCompanyName InsCompanyName
		,Null InvoiceNo
		, dacLocationName LocationName
		, finalAuth FinalAuth
		,case when okToBill = 1 then @InvoiceURL+CONVERT(varchar(20), convert(bigint, dacEntryId))
		else '' end as InvoiceLink
		, isRewrite
		,Modified_Datetime
		from
		(		
	  SELECT D.OK_TO_BILL AS okToBill,              
      CASE 
			WHEN r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=0 OR R.STATUS_CODE=4)  THEN 
                   Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.[Agreement_Open_Time],CONVERT(DATETIME,CONVERT(VARCHAR,rw.[Agreement_Open_Date],112))), DATEADD(SECOND,R.CHECK_IN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,R.CHECK_IN_DATE,112))))
            WHEN r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=1 OR R.STATUS_CODE=2)  THEN 
                  Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.[Agreement_Open_Time],CONVERT(DATETIME,CONVERT(VARCHAR,rw.[Agreement_Open_Date],112))), GETDATE())
            WHEN D.DAC_ARS_WEB != 'Y' AND (R.STATUS_CODE=0 OR R.STATUS_CODE=4 ) AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000'
            THEN ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))))
            WHEN D.DAC_ARS_WEB != 'Y' AND (R.STATUS_CODE=0 OR R.STATUS_CODE=4 ) 
            THEN ISNULL(R.SOLD_DAYS,0)
            WHEN D.DAC_ARS_WEB = 'Y' and D.DAC_STATUS =4 and LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000' THEN 
				Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))
			WHEN D.DAC_STATUS IN(3) AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000' --EXPIRED AND CLOSED
            THEN Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))
            WHEN D.DAC_STATUS = 3 AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000'  THEN --OPEN CONTRACT THEN 
				ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()), 0)	  
			 WHEN D.DAC_STATUS=1 AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000' THEN 
				ISNULL(RR.SOLD_DAYS, Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,RR.CHECK_OUT_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,RR.CHECK_OUT_DATE,112))), DATEADD(SECOND,RR.CHECK_IN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,RR.CHECK_IN_DATE,112)))))
			WHEN D.DAC_AGR_OPEN_DATE >'00000000' THEN
				ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()), 0)
			ELSE NULL      
		END AS rentaldays ,     
                    
      CASE 
              when r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=0 OR R.STATUS_CODE=4)  --previous closed and preclosed amount plus current open to date amount including extra, insurance and tax
							THEN                              
								isnull(rw.Rental_Amount,0.0) 
							when r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=1 OR R.STATUS_CODE=2)  --previous closed and preclosed amount plus current open to date amount including extra, insurance and tax
							THEN                              
								isnull(rw.Rental_Amount,0.0) +  (Carpro_App.dbo.fn_Min_Values(rw.Rate,dauth.DCA_AUTHOR_RATE) +  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0))*Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.[Agreement_Current_Open_TIME],CONVERT(DATETIME,CONVERT(VARCHAR,rw.[Agreement_Current_Open_Date],112))), GETDATE()) * (1.0+ ISNULL(dauth.VAT_PER,0.0)/100.0)   
                            WHEN D.DAC_ARS_WEB!='Y' AND  R.STATUS_CODE=4
                            THEN V.INVOICE_AMOUNT
                            WHEN D.DAC_ARS_WEB!='Y' AND  R.STATUS_CODE=0
                            THEN R.Debitor_Total
                            WHEN D.DAC_ARS_WEB ='Y' AND  D.DAC_STATUS=4
							THEN	EB.TOTAL
							WHEN D.DAC_ARS_WEB ='Y' AND  D.DAC_STATUS=2 AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000' --EXPIRED
							THEN	
								ROUND((ISNULL(dauth.DCA_AUTHOR_RATE,0)+  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0)) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))) * (1.0 +ISNULL(dauth.VAT_PER,0.0)/100.0) ,2)
                            WHEN LEFT(DAC_AGR_OPEN_DATE,4) > '2000' --AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000' --OPEN CONTRACT
							THEN	ROUND((ISNULL(dauth.DCA_AUTHOR_RATE,0)+  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0)) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE())) * (1.0 +ISNULL(dauth.VAT_PER,0.0)/100.0) ,2)
                              
                            ELSE NULL   
                              END AS totalRental ,                               
       --                       WHEN D.DAC_STATUS=4 or R.STATUS_CODE=4   THEN 
       --                             ROUND(dauth.DCA_AUTHOR_RATE * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))))  +
       --                             (ISNULL(dauth.DCA_AUTHOR_RATE,0) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))) * ISNULL(dauth.VAT_PER,0)/100),2)
                                    
							--WHEN D.DAC_STATUS=1   THEN  --FOR RESERVATION
       --                             ROUND(dauth.DCA_AUTHOR_RATE * ISNULL(RR.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,RR.CHECK_OUT_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,RR.CHECK_OUT_DATE,112))), DATEADD(SECOND,RR.CHECK_IN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,RR.CHECK_IN_DATE,112)))))  +
       --                             (ISNULL(dauth.DCA_AUTHOR_RATE,0) *  ISNULL(RR.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,RR.CHECK_OUT_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,RR.CHECK_OUT_DATE,112))), DATEADD(SECOND,RR.CHECK_IN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,RR.CHECK_IN_DATE,112))))) * ISNULL(dauth.VAT_PER,0)/100),2)                                    
                              
       --                     WHEN D.DAC_AGR_OPEN_DATE >'00000000' THEN
       --                             ISNULL(dauth.DCA_AUTHOR_RATE,0) * ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()),0) + 
       --                             ((ISNULL(dauth.DCA_AUTHOR_RATE,0)* ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()),0)) * ISNULL(dauth.VAT_PER,0)/100)
                  ISNULL(dauth.dca_a_days,0) AS dacAuthorDays,
                  D.DAC_RESERVATION_NO AS dacReservationNo,
                  D.DAC_AGREEMENT_NUMBER AS dacAgreementNumber,
                  D.DAC_CLIENT_LAST_NAME AS dacClientLastName,
                  D.DAC_CLIENT_FIRST_NAME AS dacClientFirstName,
                CASE
                WHEN r.PARENT_EXTEND_AGREEMENT_NO>0 THEN
					rw.[Agreement_Open_Date]
				ELSE
					D.DAC_AGR_OPEN_DATE  
				END
                  AS dacAgreementOpenDate,
             CASE 
                  WHEN ((D.DAC_ARS_WEB!='Y' AND R.STATUS_CODE = 0 OR R.STATUS_CODE = 4) OR D.DAC_ARS_WEB = 'Y') AND D.DAC_AGR_CLOSE_DATE > '00000000'  THEN D.DAC_AGR_CLOSE_DATE
                  WHEN ((D.DAC_ARS_WEB!='Y' AND R.STATUS_CODE=0 or R.STATUS_CODE=4) ) and R.CHECK_IN_DATE > '00000000' THEN R.CHECK_IN_DATE
                  ELSE '00000000'   END   AS dacAgreementCloseDate,
                  ISNULL(dauth.DCA_AUTHOR_RATE,0) AS dacAuthorizedRate,
                  D.DAC_TAX_PAID_BY AS dacTaxPaidBy,                  
                  ISNULL(DA.DAA_LAST_NAME,'')AS dacCompanyAdjLastName,
                  ISNULL(DA.DAA_FIRST_NAME ,'') AS dacCompanyAdjFirstName, 
                  D.DAC_POLICY AS dacPolicy,
                  D.DAC_INS_CLAIM AS dacInsClaim,
                  D.DAC_LOCATION_NAME AS dacLocationName,
                  D.DAC_MAKE AS dacMake,
                  D.DAC_MODEL AS dacModel,
                  D.DAC_YEAR AS dacYear,
                  D.DAC_RENTAL_MAKE AS dacRentalMake,
                  D.DAC_RENTAL_MODEL AS dacRentalModel,
                  D.DAC_RENTAL_YEAR AS dacRentalYear,
                  D.DAC_EQUIVALENT_GROUP AS dacEquivalentGroup,
                  D.DAC_STATUS AS dacStatus,
                  D.DAC_ARS_WEB AS dacArsWeb,
                  D.DAC_ENTRY_ID AS dacEntryId,
            CASE D.DAC_INVOICE_DATE
                  WHEN '00000000' THEN ''
                  ELSE D.DAC_INVOICE_DATE END AS  dacInvoiceDate,                  
                  DB1.DEBITOR_NAME AS dacInsCompanyName,
                  dauth.FinalAuth_fromAuth AS finalAuth 
                  --, Case when dauth.DCA_AUTHOR_TO_DATE !='00000000' then datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112))) else  null end [ExpiringinDays]
                , Case 
                  when  r.STATUS_CODE = 0 and r.SOLD_DAYS <= dauth.dca_a_days
					then 0
                  when dauth.DCA_AUTHOR_TO_DATE >'00000000'  and (left( dauth.DCA_AUTHOR_TO_DATE, 4) > '2000' or  dauth.DCA_AUTHOR_TO_DATE = '00000000') and r.STATUS_CODE = 0  and  left(r.CHECK_IN_DATE,4)>'2000'
                then datediff(day, dbo.convertToDate(r.CHECK_IN_DATE), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112))) 
                WHEN D.DAC_AGREEMENT_NUMBER = 0  AND D.DAC_STATUS IN (0,1) THEN NULL
				when D.DAC_STATUS= 4 then null
				when dauth.DCA_AUTHOR_TO_DATE >'00000000'  and left(dauth.DCA_AUTHOR_TO_DATE,4) >'2000' 
				then datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112))) 
				else  null end 
				[ExpiringinDays]
                  --, CASE WHEN NH.DCN_CLAIM_ID is not null THEN 1 ELSE 0 END HasNotes
                  , isnull(dauth.DCA_TOTAL_RENTAL,d.DAC_AUTHORIZED_RATE*d.DAC_AUTHOR_DAYS)  AS [Auth Total]
                  , CASE WHEN R.PARENT_EXTEND_AGREEMENT_NO>0 THEN 1 ELSE 0 END isRewrite, DATEADD(SECOND,DAC_MODIFIED_TIME, convert(datetime, convert(varchar(8),d.DAC_MODIFIED_DATE,112) )) Modified_Datetime
                  , case when v.INVOICE_NO is not null then v.INVOICE_NO
                  when eb.ENTRY_ID is not null then eb.ENTRY_ID
                  end invoiceno
            FROM DA_CLAIMS D(nolock)
            LEFT OUTER JOIN RemedeyAgr_Rewrite R(nolock) ON R.AGREEMENT_NO = D.DAC_AGREEMENT_NUMBER
            Left join Carpro_App..tblDial_RewriteWarehouse rw(nolock) on rw.Current_Agreement_No = D.DAC_AGREEMENT_NUMBER
            LEFT OUTER JOIN (SELECT da.DCA_CLAIM_ID,ISNULL(AVG(VAT_PER),0)VAT_PER,ISNULL(sum(dca_a_days),0) dca_a_days,
                                    ROUND(ISNULL(AVG(DCA_AUTHOR_RATE),0),2) DCA_AUTHOR_RATE, max(DCA_AUTHOR_TO_DATE) DCA_AUTHOR_TO_DATE 
                                    ,SUM(DCA_TOTAL_RENTAL) as DCA_TOTAL_RENTAL
                                    , MAX(DA.DCA_ENTRY_ID) Last_Auth_ID, max(FINAL_AUTH) as FinalAuth_fromAuth
                                    FROM DA_AUTHORIZATION da(nolock) 
                                    WHERE DCA_BILL_TO = 1 GROUP BY da.DCA_CLAIM_ID )AS dauth ON D.DAC_ENTRY_ID = dauth.DCA_CLAIM_ID    
              Left join (select DAE_AUTH_ENTRY_ID, sum(DAE_PRICE) Auth_Extra_PerDay from [dbo].[DA_AUTHORIZATION_extraS](nolock)
							group by DAE_AUTH_ENTRY_ID	
                  ) AuthExtra on AuthExtra.DAE_AUTH_ENTRY_ID = dauth.Last_Auth_ID
                  Left join (select DAE_AUTH_ENTRY_ID, sum(DAE_PRICE) Auth_Ins_PerDay from [dbo].DA_AUTHORIZATION_INSURANCES(nolock)
							group by DAE_AUTH_ENTRY_ID	
                  ) AuthIns on AuthIns.DAE_AUTH_ENTRY_ID = dauth.Last_Auth_ID  
             LEFT JOIN DA_ADJUSTER DA(NOLOCK) ON DA.DAA_ENTRY_ID = D.DAC_COMPANY_ADJUSTER_ID
             LEFT JOIN DEBITORS DB1(NOLOCK)
             ON DB1.DEBITOR_CODE = D.DAC_INS_COMPANY_ID
             LEFT JOIN [RemedeyRes] RR(NOLOCK)
             ON D.[DAC_RESERVATION_NO] = RR.[RESERVATION_NO]
              LEFT OUTER JOIN Vw_Dial_Inv V(NOLOCK) ON V.AGREEMENT_NO = D.DAC_AGREEMENT_NUMBER AND V.INVOICE_TYPE = 'C' AND V.INV_STATUS != 9 AND D.DAC_INS_COMPANY_ID = v.DEBITOR_NO
              LEFT OUTER JOIN EBILLING_INVOICE_DATA EB(NOLOCK) on EB.Entry_ID = D.DAC_ENTRY_ID
              --LEFT JOIN (
              --     SELECT DCN_CLAIM_ID FROM DA_NOTES_HISTORY(NOLOCK)
              --     WHERE DCN_NOTES_TYPE not in (8)
              --     GROUP BY DCN_CLAIM_ID ) NH
              --     ON 
              --     D.DAC_ENTRY_ID = NH.DCN_CLAIM_ID
            WHERE
            ( @sPolicy_Claim_No IS NULL OR  ((ltrim(rtrim(d.DAC_POLICY)) like + '%' + @sPolicy_Claim_No + '%') or (ltrim(rtrim(d.DAC_INS_CLAIM)) like + '%' + @sPolicy_Claim_No + '%')  or (ltrim(rtrim(d.DAC_ENTRY_ID)) = @sPolicy_Claim_No)))
        and (@ClientLastName is null or d.DAC_CLIENT_LAST_NAME like +'%' + @ClientLastName + '%' )
		--and (@iAgreementNo is null or d.DAC_AGREEMENT_NUMBER = @iAgreementNo)
		and (@iDebitorCode is null or d.DAC_INS_COMPANY_ID =@iDebitorCode)
		--and (@ddAdjusterID is null or @ddAdjusterID = 0 or  d.DAC_COMPANY_ADJUSTER_ID =@ddAdjusterID)		
		and  (@iStatus is null or DAC_STATUS =@iStatus) 
		  AND 
            
            (
                         (
                              (     
									rw.Current_Agreement_No is null AND --FOR NOT REWRITE
									(
										(	(D.DAC_ARS_WEB!='Y' AND D.FINAL_AUTH='Y' and v.INVOICE_NO is null) --no invoice
											OR
											(D.DAC_ARS_WEB='Y' AND D.FINAL_AUTH='Y' AND EB.Entry_ID IS NULL)
										)
										OR 
										dauth.dca_a_days >=      (DATEDIFF(DAY,dbo.convertToDate(D.DAC_AGR_OPEN_DATE),
                                                                              CASE
                                                                                    WHEN (D.DAC_ARS_WEB != 'Y' AND R.STATUS_CODE = 0 OR R.STATUS_CODE = 4) OR (D.DAC_ARS_WEB='Y' AND D.DAC_AGR_CLOSE_DATE>'00000000') 
                                                                                    THEN dbo.convertToDate(D.DAC_AGR_CLOSE_DATE)
                                                                                    ELSE GETDATE() 
																				 END)
																	)
                                                                              
                                   )
                                    
                              )
                              OR
                             (( r.PARENT_EXTEND_AGREEMENT_NO>0 and left(rw.Agreement_Open_Date,4) >'2010' 
                             and 
                             (ISNULL(dauth.dca_a_days,0) >= DATEDIFF(DAY,dbo.convertToDate(rw.Agreement_Open_Date),dbo.convertToDate(rw.Agreement_Close_Date)) 
                             or ltrim(rtrim(FinalAuth_fromAuth)) = 'Y'	)							
                              )
                              or 
                              (rw.Current_Agreement_No is null and dauth.dca_a_days >= (DATEDIFF(DAY,dbo.convertToDate(D.dac_agr_open_date),
                                                                        CASE
                                                                        WHEN (D.DAC_ARS_WEB != 'Y' AND R.STATUS_CODE = 0 OR R.STATUS_CODE = 4) OR (D.DAC_ARS_WEB = 'Y' AND D.DAC_AGR_CLOSE_DATE > '00000000') 
                                                                        THEN 
                                                                              dbo.convertToDate(D.DAC_AGR_CLOSE_DATE)
                                                                        ELSE 
                                                                              CASE 
                                                                                    WHEN dbo.convertToDate(D.DAC_AGR_OPEN_DATE) = CONVERT (CHAR(8),GETDATE(),112)
                                                                                    THEN GETDATE()+1 
                                                                                    ELSE GETDATE() 
                                                                                    END 
                                                                        END   )
                                                                        )
                                                                        )
                              AND (
                                          (D.DAC_ARS_WEB != 'Y' AND R.STATUS_CODE = 1 OR R.STATUS_CODE = 2 OR D.DAC_AGREEMENT_NUMBER = 0) 
                                          OR (D.DAC_ARS_WEB='Y' AND (D.DAC_AGR_CLOSE_DATE='00000000' OR D.DAC_AGREEMENT_NUMBER=0) )
                                    )
                              --and dac_status in (2,3,4) and ltrim(rtrim(FinalAuth_fromAuth)) = 'Y'
                              ) and (ltrim(rtrim(FinalAuth_fromAuth)) = 'Y' or CONVERT(varchar(8), getdate(),112) <= dauth.DCA_AUTHOR_TO_DATE)
                               OR --Lakshmi added on 20130124
                              (
								D.DAC_STATUS IN (0,1) -- BOOK SINCE NEW DOESN'T HAVE START_DATE ON RESERVATION
								--AND dauth.dca_a_days >0
								--and RR.CHECK_OUT_DATE <= CONVERT(VARCHAR(8),DATEADD(WEEK,2, GETDATE()),112)  --ONLY SHOW WITHIN TWO WEEKS DATA FOR RESERVATION
								--AND DAC_MODIFIED_DATE >=  CONVERT(VARCHAR(8),DATEADD(DAY, -14, GETDATE()),112)
							  )		
                        )
                and d.dac_status < 5                
                and charindex('UNKNOWN',D.DAC_COMPANY_ADJ_FIRST_NAME) =0
                and charindex('UNKNOWN',D.DAC_COMPANY_ADJ_LAST_NAME) =0
                AND D.DAC_COMPANY_ADJUSTER_ID>0
                AND ((d.DAC_AGR_OPEN_DATE >'00000000'                 
                AND D.DAC_STATUS IN (1,2,4)) OR (d.DAC_AGR_OPEN_DATE >='00000000' AND D.DAC_STATUS IN (0, 1) ))
                AND dac_create_date>'20120101'
                  )
                 -- AND (@AdjusterID=0 OR D.DAC_COMPANY_ADJUSTER_ID = @AdjusterID)                  
     --             AND (D.DAC_INS_COMPANY_ID IN                   
					--(SELECT  
					--	[INS_COMPANY_ID]
					--	FROM [dbo].[ADJUSTER_DEBITORS] (nolock)
					--	where ADJUSTER_ID =@AdjusterID
					--)
     --             ) 
     
       AND ((@ddAdjusterID >= 0 and D.DAC_COMPANY_ADJUSTER_ID = @AdjusterID) 
       OR (@ddAdjusterID = -1 and D.DAC_COMPANY_ADJUSTER_ID in 
      (select distinct ADJUSTER_ID from dbo.ADJUSTER_DEBITORS (nolock) 
       where INS_COMPANY_ID in (SELECT  distinct DEBITOR_CODE FROM debitors where suv_debitor_of =  @Parent_Debitor_Code)))) 
       and DAC_INS_COMPANY_ID in (select distinct debitor_code from dbo.debitors (nolock) where SUV_DEBITOR_OF = @Parent_Debitor_Code) 
       	And ( ( @sPolicy_Claim_No IS NULL OR  ((ltrim(rtrim(d.DAC_POLICY)) like + '%' + @sPolicy_Claim_No + '%') or (ltrim(rtrim(d.DAC_INS_CLAIM)) like + '%' + @sPolicy_Claim_No + '%')  or (ltrim(rtrim(d.DAC_ENTRY_ID)) = @sPolicy_Claim_No)))
		        and (@ClientLastName is null or d.DAC_CLIENT_LAST_NAME like +'%' + @ClientLastName + '%' )
				and (@iDebitorCode is null or d.DAC_INS_COMPANY_ID =@iDebitorCode))
				
                  AND 
                  DAC_MODIFIED_DATE >=  CONVERT(VARCHAR(8),DATEADD(WEEK, -2, GETDATE()),112)   
                  ) tt
                  where
                   --(@iExpiringInDay is null or not ([ExpiringinDays]is null) )
                   (@iExpiringInDay is null or (@iExpiringInDay =0  and [ExpiringinDays] <= 0 ) or (@iExpiringInDay >0   and [ExpiringinDays] = @iExpiringInDay ))
                  order by Modified_Datetime desc
	END
	
	IF @Action = 'INVOICES'	
	BEGIN
	
                  
		select 'Invoice' [Status_desc], DAC_STATUS [Status], isnull(DAC_CLIENT_FIRST_NAME,'') + ' ' + ISNULL(DAC_CLIENT_LAST_NAME,0) [Client Name]
		, DAC_AGREEMENT_NUMBER [Agreement No]
		, DAC_INS_CLAIM [Claim #]
		, DAC_POLICY [Policy #]
		, dbo.fn_ConvertYYYYMMDDtoDIAL(dacAgreementOpenDate) [Rental Out]
		, dbo.fn_ConvertYYYYMMDDtoDIAL(dacAgreementCloseDate) [Rental In]
		,case when rentaldays < 0 then 0 else rentaldays end as [Rental Days]
		,convert(decimal(18,2),DCA_AUTHOR_RATE) [Auth Rate]
		, dca_a_days [Auth Days]
		,[Auth Total]
		,convert(decimal(18,2), case when totalRental < 0 then 0 else totalRental end) as [Total Rental (incl. Tax)] 
		,  isnull(dacCompanyAdjFirstName,'') + ' ' + isnull(dacCompanyAdjLastName,'')  [Adjuster Name]
		,0 [HasNotes]
		--, case when DAC_AGREEMENT_NUMBER = 0 then null else [ExpiringinDays] end as [ExpiringinDays] 
		, null [ExpiringinDays] 
		, OkToBill OkToBill --
		, acknowledge Acknowledge 
		, DISPUTE Dispute 
		,EbillingPresent EbillingPresent
		,null ReservationNo
		,null TaxPaidBy
		,null BranchName
		,null InsuredVehicleMake
		,null InsuredVehicleModel
		,null InsuredVehicleYear
		,null RentalMake
		,null RentalModel
		,null RentalYear
		,null VehicleEquivalentClass
		,DAC_ARS_WEB IsFranchise
		,dacEntryId ClaimEntryId
	--	,InvoiceDate InvoiceDate
		,dacInsCompanyName InsCompanyName
		,INVOICE_NO InvoiceNo
		, null LocationName
		, FINAL_AUTH FinalAuth
		,case when OkToBill = 1 then @InvoiceURL+CONVERT(varchar(20), convert(bigint, dacEntryId))
		else '' end as InvoiceLink
		, isRewrite
		, Modified_Datetime
		from
		(	
		SELECt   CASE
                WHEN r.PARENT_EXTEND_AGREEMENT_NO>0 THEN
					rw.[Agreement_Open_Date]
				WHEN 
                  LEFT(D.DAC_AGR_OPEN_DATE,4) > '2000' THEN D.DAC_AGR_OPEN_DATE
                  ELSE '' END AS dacAgreementOpenDate,
             CASE 
                  WHEN ((D.DAC_ARS_WEB!='Y' AND R.STATUS_CODE = 0 OR R.STATUS_CODE = 4) OR D.DAC_ARS_WEB = 'Y') AND D.DAC_AGR_CLOSE_DATE > '00000000'  THEN D.DAC_AGR_CLOSE_DATE
                  WHEN ((D.DAC_ARS_WEB!='Y' AND R.STATUS_CODE=0 or R.STATUS_CODE=4) ) and R.CHECK_IN_DATE > '00000000' THEN R.CHECK_IN_DATE
                  ELSE '00000000'   END   AS dacAgreementCloseDate,
      CASE 
		WHEN r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=0 OR R.STATUS_CODE=4)  THEN 
                   Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.[Agreement_Open_Time],CONVERT(DATETIME,CONVERT(VARCHAR,rw.[Agreement_Open_Date],112))), DATEADD(SECOND,R.CHECK_IN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,R.CHECK_IN_DATE,112))))
            WHEN r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=1 OR R.STATUS_CODE=2)  THEN 
                  Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.[Agreement_Open_Time],CONVERT(DATETIME,CONVERT(VARCHAR,rw.[Agreement_Open_Date],112))), GETDATE())
            WHEN D.DAC_ARS_WEB != 'Y' AND (R.STATUS_CODE=0 OR R.STATUS_CODE=4 ) AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000'
            THEN ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))))
            WHEN D.DAC_ARS_WEB != 'Y' AND (R.STATUS_CODE=0 OR R.STATUS_CODE=4 ) 
            THEN ISNULL(R.SOLD_DAYS,0)
            WHEN D.DAC_ARS_WEB = 'Y' and D.DAC_STATUS =4 and LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000' THEN 
				Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))
			WHEN D.DAC_AGR_OPEN_DATE >'00000000' THEN
			ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()), 0)
		ELSE NULL      
      END AS rentaldays ,                   
		dauth.dca_a_days
,         dauth.DCA_AUTHOR_RATE 
,      CASE 
               when r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=0 OR R.STATUS_CODE=4)  --previous closed and preclosed amount plus current open to date amount including extra, insurance and tax
							THEN                              
								isnull(rw.Rental_Amount,0.0) 
							when r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=1 OR R.STATUS_CODE=2)  --previous closed and preclosed amount plus current open to date amount including extra, insurance and tax
							THEN                              
								isnull(rw.Rental_Amount,0.0) +  (Carpro_App.dbo.fn_Min_Values(rw.Rate,dauth.DCA_AUTHOR_RATE) +  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0))*Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.[Agreement_Current_Open_TIME],CONVERT(DATETIME,CONVERT(VARCHAR,rw.[Agreement_Current_Open_Date],112))), GETDATE()) * (1.0+ ISNULL(dauth.VAT_PER,0.0)/100.0)   
                            WHEN D.DAC_ARS_WEB!='Y' AND  R.STATUS_CODE=4
                            THEN DIAL_INVOICES.INVOICE_AMOUNT
                            WHEN D.DAC_ARS_WEB!='Y' AND  R.STATUS_CODE=0
                            THEN R.Debitor_Total
                            WHEN D.DAC_ARS_WEB ='Y' AND  D.DAC_STATUS=4
							THEN	DIAL_INVOICES.INVOICE_AMOUNT                             
                            ELSE NULL   
                            --  WHEN D.DAC_STATUS=4 or R.STATUS_CODE=4   THEN 
                            --        ROUND(dauth.DCA_AUTHOR_RATE * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))))  +
                            --        (ISNULL(dauth.DCA_AUTHOR_RATE,0) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))) * ISNULL(dauth.VAT_PER,0)/100),2)
                       
                            --WHEN D.DAC_AGR_OPEN_DATE >'00000000' THEN
                            --        ISNULL(dauth.DCA_AUTHOR_RATE,0) * ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()),0) + 
                            --        ((ISNULL(dauth.DCA_AUTHOR_RATE,0)* ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()),0)) * ISNULL(dauth.VAT_PER,0)/100)
                            --ELSE NULL   
                              END AS totalRental 
                ,ISNULL(DA.DAA_LAST_NAME,'')AS dacCompanyAdjLastName,
                  ISNULL(DA.DAA_FIRST_NAME ,'') AS dacCompanyAdjFirstName
                  , case when DIAL_INVOICES.INV_FROM ='E' then 'Y' else 'N' end  EbillingPresent  
                  ,d.OK_TO_BILL  as OkToBill
                  ,d.FINAL_AUTH
                  , DIAL_INVOICES.DISPUTE  
                  , DIAL_INVOICES.acknowledge acknowledge
                  , db1.DEBITOR_NAME dacInsCompanyName 
                  , DIAL_INVOICES.INVOICE_NO
                  --, d.DAC_STATUS
                  ,CASE
                  WHEN D.DAC_ARS_WEB !='Y' AND R.STATUS_CODE =4 THEN 4 --INACTIVE MEAN AGREEMENT STATUS =4						
				  WHEN D.DAC_ARS_WEB !='Y' AND R.STATUS_CODE =0 THEN 3 --EXPIRED MEAN AGREEMENT STATUS =0							
                  ELSE d.DAC_STATUS 
                  END DAC_STATUS
                  , d.DAC_CLIENT_FIRST_NAME
                  , d.DAC_CLIENT_LAST_NAME
                  ,  DAC_AGREEMENT_NUMBER 
				  , d.DAC_INS_CLAIM 
				  , d.DAC_POLICY
				  , D.DAC_ARS_WEB
					,D.DAC_ENTRY_ID as  dacEntryId
	            --, Case when dauth.DCA_AUTHOR_TO_DATE !='00000000' then datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112))) else  null end [ExpiringinDays]
	            ,Case 
	            when dauth.DCA_AUTHOR_TO_DATE >'00000000' and r.STATUS_CODE in (0,4 )
	            then datediff (day, dbo.convertToDate(R.CHECK_IN_DATE) , dbo.convertToDate(dauth.DCA_AUTHOR_TO_DATE)) 
	            
					when D.DAC_STATUS= 4 then null
					when dauth.DCA_AUTHOR_TO_DATE >'00000000' then datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112))) 
					else  null end [ExpiringinDays]
				--, CASE WHEN NH.DCN_CLAIM_ID is not null THEN 1 ELSE 0 END HasNotes
               -- ,  *
               , isnull(dauth.DCA_TOTAL_RENTAL,d.DAC_AUTHORIZED_RATE*d.DAC_AUTHOR_DAYS)  AS [Auth Total]
               , CASE WHEN R.PARENT_EXTEND_AGREEMENT_NO>0 THEN 1 ELSE 0 END isRewrite,  DATEADD(SECOND,DAC_MODIFIED_TIME, convert(datetime, convert(varchar(8),d.DAC_MODIFIED_DATE,112) )) Modified_Datetime
		FROM DA_CLAIMS D(nolock) inner join vw_DIAL_INVOICES DIAL_INVOICES(nolock) 
		on D.DAC_ENTRY_ID = DIAL_INVOICES.DAC_ENTRY_ID
		Left join Carpro_App..tblDial_RewriteWarehouse rw(nolock) on rw.Current_Agreement_No = D.DAC_AGREEMENT_NUMBER
		    LEFT OUTER JOIN RemedeyAgr_Rewrite R(nolock) ON R.AGREEMENT_NO = D.DAC_AGREEMENT_NUMBER
            LEFT OUTER JOIN (SELECT da.DCA_CLAIM_ID,ISNULL(AVG(VAT_PER),0)VAT_PER,ISNULL(sum(dca_a_days),0) dca_a_days,
                                    ROUND(ISNULL(AVG(DCA_AUTHOR_RATE),0),2) DCA_AUTHOR_RATE, max(DCA_AUTHOR_TO_DATE) DCA_AUTHOR_TO_DATE 
                                    ,SUM(DCA_TOTAL_RENTAL) as DCA_TOTAL_RENTAL
                                    ,MAX(DA.DCA_ENTRY_ID) Last_Auth_ID
                                    FROM DA_AUTHORIZATION da(nolock) 
                                    WHERE DCA_BILL_TO = 1 GROUP BY da.DCA_CLAIM_ID )AS dauth ON D.DAC_ENTRY_ID = dauth.DCA_CLAIM_ID    
              Left join (select DAE_AUTH_ENTRY_ID, sum(DAE_PRICE) Auth_Extra_PerDay from [dbo].[DA_AUTHORIZATION_extraS](nolock)
							group by DAE_AUTH_ENTRY_ID	
                  ) AuthExtra on AuthExtra.DAE_AUTH_ENTRY_ID = dauth.Last_Auth_ID
                  Left join (select DAE_AUTH_ENTRY_ID, sum(DAE_PRICE) Auth_Ins_PerDay from [dbo].DA_AUTHORIZATION_INSURANCES(nolock)
							group by DAE_AUTH_ENTRY_ID	
                  ) AuthIns on AuthIns.DAE_AUTH_ENTRY_ID = dauth.Last_Auth_ID                         
             LEFT JOIN DA_ADJUSTER DA(NOLOCK) ON DA.DAA_ENTRY_ID = D.DAC_COMPANY_ADJUSTER_ID
             LEFT JOIN DEBITORS DB1(NOLOCK)
             ON DB1.DEBITOR_CODE = DIAL_INVOICES.DEBITOR_NO
             --LEFT JOIN (
             --      SELECT DCN_CLAIM_ID FROM DA_NOTES_HISTORY(NOLOCK)
             --      WHERE DCN_NOTES_TYPE not in (8)
             --      GROUP BY DCN_CLAIM_ID ) NH
             --      ON 
             --      D.DAC_ENTRY_ID = NH.DCN_CLAIM_ID
		WHERE  
	  ( @sPolicy_Claim_No IS NULL OR  ((ltrim(rtrim(d.DAC_POLICY)) like + '%' + @sPolicy_Claim_No + '%') or (ltrim(rtrim(d.DAC_INS_CLAIM)) like + '%' + @sPolicy_Claim_No + '%')  or (ltrim(rtrim(d.DAC_ENTRY_ID)) = @sPolicy_Claim_No)))
        and (@ClientLastName is null or d.DAC_CLIENT_LAST_NAME like +'%' + @ClientLastName + '%' )
		--and (@iAgreementNo is null or d.DAC_AGREEMENT_NUMBER = @iAgreementNo)
		and (@iDebitorCode is null or d.DAC_INS_COMPANY_ID =@iDebitorCode)
		--and (@ddAdjusterID is null or @ddAdjusterID = 0 or d.DAC_COMPANY_ADJUSTER_ID =@ddAdjusterID)		
		and  (@iStatus is null or DAC_STATUS =@iStatus) 
		  AND 
		  INVOICE_DATE BETWEEN CONVERT(VARCHAR(8),DATEADD(WEEK,-4,GETDATE()),112) AND CONVERT(VARCHAR(8),GETDATE(),112)   --DISPLAY ONLY 2 WEEK PRIOR TODAY				  		 
		  AND (DEBITOR_NO IN (
		  --(SELECT  
				--		[INS_COMPANY_ID]
				--		FROM [dbo].[ADJUSTER_DEBITORS] (nolock)
				--		where ADJUSTER_ID =@AdjusterID
				select distinct debitor_code from dbo.debitors (nolock) where SUV_DEBITOR_OF = @Parent_Debitor_Code
					)
		 -- AND (@AdjusterID=0 OR D.DAC_COMPANY_ADJUSTER_ID = @AdjusterID)    
		   AND ((@ddAdjusterID >= 0 and D.DAC_COMPANY_ADJUSTER_ID = @AdjusterID) 
                  OR (@ddAdjusterID = -1 and D.DAC_COMPANY_ADJUSTER_ID in 
                  (select distinct ADJUSTER_ID from dbo.ADJUSTER_DEBITORS (nolock)))) 
                  
            	And ( ( @sPolicy_Claim_No IS NULL OR  ((ltrim(rtrim(d.DAC_POLICY)) like + '%' + @sPolicy_Claim_No + '%') or (ltrim(rtrim(d.DAC_INS_CLAIM)) like + '%' + @sPolicy_Claim_No + '%')  or (ltrim(rtrim(d.DAC_ENTRY_ID)) = @sPolicy_Claim_No)))
		        and (@ClientLastName is null or d.DAC_CLIENT_LAST_NAME like +'%' + @ClientLastName + '%' )
				and (@iDebitorCode is null or d.DAC_INS_COMPANY_ID =@iDebitorCode) )
		 
		  )	
		   and ( (D.DAC_ARS_WEB !='Y' and R.STATUS_CODE =4 ) OR (D.DAC_ARS_WEB ='Y' and d.DAC_STATUS =4))
		   
		  ) t1
		  where 
		  --(@iExpiringInDay is null or not ([ExpiringinDays]is null) )	 
		  (@iExpiringInDay is null or (@iExpiringInDay =0  and [ExpiringinDays] <= 0 ) or (@iExpiringInDay >0   and [ExpiringinDays] = @iExpiringInDay ))	 
		  
			order by Modified_Datetime desc		
	END
	
	
	IF @Action = 'UNASSIGNED'	
	BEGIN
	
		select --'Unassigned' 
		case
		when 
		dacRentalAgrStatus =3 then 'Expired'
		else 'Reservation' 
			end
		[Status_desc], dacRentalAgrStatus [Status], isnull(dacClientFirstName,'') + ' ' + ISNULL(dacClientLastName,0) [Client Name]
		, dacAgreementNumber [Agreement No]
		, dacinsclaim [Claim #]
		, dacPolicy [Policy #]
		, dbo.fn_ConvertYYYYMMDDtoDIAL(dacAgreementOpenDate) [Rental Out]
		, dbo.fn_ConvertYYYYMMDDtoDIAL(dacAgreementCloseDate) [Rental In]
		,case when rentaldays < 0 then 0 else rentaldays end as [Rental Days]
		,convert(decimal(18,2),dacAuthorizedRate) [Auth Rate]
		, dacAuthorDays [Auth Days]
		,[Auth Total]
		,convert(decimal(18,2),case when totalRental < 0 then 0 else totalRental end) as [Total Rental (incl. Tax)]
		, isnull(dacCompanyAdjFirstName,'') + ' ' + isnull(dacCompanyAdjLastName,'') [Adjuster Name]
		,0 [HasNotes] --??
		, case when dacAgreementNumber = 0 then null else [ExpiringinDays] end as [ExpiringinDays]
		, okToBill OkToBill
		, acknowledge Acknowledge
		, dispute Dispute
		,ebillrecPresent EbillingPresent
		,dacReservationNo ReservationNo
		,dacTaxPaidBy TaxPaidBy
		,dacLocationName BranchName
		,dacMake InsuredVehicleMake
		,dacModel InsuredVehicleModel
		,dacYear InsuredVehicleYear
		,dacRentalMake RentalMake
		,dacRentalModel RentalModel
		,dacRentalYear RentalYear
		,dacEquivalentGroup VehicleEquivalentClass
		,dacArsWeb IsFranchise
		,dacEntryId ClaimEntryId
		--,dacInvoiceDate InvoiceDate
		,dacInsCompanyName InsCompanyName
		,invoiceNo InvoiceNo
		, LocationName
		, FinalAuth
		,'' as InvoiceLink
		, isRewrite
		, Modified_Datetime
		from
		(
		SELECT D.OK_TO_BILL AS okToBill,d.DAC_STATUS AS dacRentalAgrStatus,ISNULL(ISNULL(V.ACKNOWLEDGE,EB.ACKNOWLEDGE),'N') AS acknowledge  , ISNULL(ISNULL(V.DISPUTE,EB.DISPUTE),'N') AS dispute,case when EB.Entry_ID IS not null  then 'Y' else 'N' end AS ebillrecPresent,
                  CASE 
                   WHEN r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=0 OR R.STATUS_CODE=4)  THEN 
                   Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.[Agreement_Open_Time],CONVERT(DATETIME,CONVERT(VARCHAR,rw.[Agreement_Open_Date],112))), DATEADD(SECOND,R.CHECK_IN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,R.CHECK_IN_DATE,112))))
            WHEN r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=1 OR R.STATUS_CODE=2)  THEN 
                  Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.[Agreement_Open_Time],CONVERT(DATETIME,CONVERT(VARCHAR,rw.[Agreement_Open_Date],112))), GETDATE())
            WHEN D.DAC_ARS_WEB != 'Y' AND (R.STATUS_CODE=0 OR R.STATUS_CODE=4 ) AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000'
            THEN ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))))
            WHEN D.DAC_ARS_WEB != 'Y' AND (R.STATUS_CODE=0 OR R.STATUS_CODE=4 ) 
            THEN ISNULL(R.SOLD_DAYS,0)
            WHEN D.DAC_STATUS IN(3,4) AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000' --EXPIRED AND CLOSED
            THEN Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))
  				else null
            END AS rentaldays ,
                 CASE 
                    when r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=0 OR R.STATUS_CODE=4)  --previous closed and preclosed amount plus current open to date amount including extra, insurance and tax
							THEN                              
								isnull(rw.Rental_Amount,0.0) 
							when r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=1 OR R.STATUS_CODE=2)  --previous closed and preclosed amount plus current open to date amount including extra, insurance and tax
							THEN                              
								isnull(rw.Rental_Amount,0.0) +  (Carpro_App.dbo.fn_Min_Values(rw.Rate,dauth.DCA_AUTHOR_RATE) +  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0))*Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.[Agreement_Current_Open_TIME],CONVERT(DATETIME,CONVERT(VARCHAR,rw.[Agreement_Current_Open_Date],112))), GETDATE()) * (1.0+ ISNULL(dauth.VAT_PER,0.0)/100.0)   
                            WHEN D.DAC_ARS_WEB!='Y' AND  R.STATUS_CODE=4
                            THEN V.INVOICE_AMOUNT
                            WHEN D.DAC_ARS_WEB!='Y' AND  R.STATUS_CODE=0
                            THEN R.Debitor_Total
                            WHEN D.DAC_ARS_WEB ='Y' AND  D.DAC_STATUS=4
							THEN	EB.TOTAL
							WHEN D.DAC_ARS_WEB ='Y' AND  D.DAC_STATUS=3 AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000' --EXPIRED
							THEN	
								ROUND((ISNULL(dauth.DCA_AUTHOR_RATE,0)+  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0)) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))) * (1.0 +ISNULL(dauth.VAT_PER,0.0)/100.0) ,2)
                            WHEN LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000' --OPEN CONTRACT
							THEN	ROUND((ISNULL(dauth.DCA_AUTHOR_RATE,0)+  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0)) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE())) * (1.0 +ISNULL(dauth.VAT_PER,0.0)/100.0) ,2)
                              
                            ELSE NULL   
                              --WHEN D.DAC_STATUS=4 or R.STATUS_CODE=4   THEN 
                              --      ROUND(dauth.DCA_AUTHOR_RATE * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))))  +
                              --      (ISNULL(dauth.DCA_AUTHOR_RATE,0) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))) * ISNULL(dauth.VAT_PER,0)/100),2)
                              --WHEN DAC_AGR_OPEN_DATE > '00000000'   and   DAC_AGR_OPEN_DATE <= CONVERT(varchar(8), getdate(),112)    THEN
                              --      ISNULL(dauth.DCA_AUTHOR_RATE,0) * ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()),0) + 
                              --      ((ISNULL(dauth.DCA_AUTHOR_RATE,0)* ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()),0)) * ISNULL(dauth.VAT_PER,0)/100)
                              --ELSE NULL      
            end AS totalRental ,
            ISNULL(dauth.dca_a_days,0) AS dacAuthorDays,
            D.DAC_RESERVATION_NO AS dacReservationNo,
            D.DAC_AGREEMENT_NUMBER AS dacAgreementNumber,
            D.DAC_CLIENT_LAST_NAME AS dacClientLastName,
            D.DAC_CLIENT_FIRST_NAME AS dacClientFirstName,
             CASE
                WHEN r.PARENT_EXTEND_AGREEMENT_NO>0 THEN
					rw.[Agreement_Open_Date]
				WHEN LEFT(D.DAC_AGR_OPEN_DATE,4)>'2000' THEN D.DAC_AGR_OPEN_DATE
				ELSE '' END
            AS dacAgreementOpenDate,
            CASE 
                  WHEN ((D.DAC_ARS_WEB!='Y' AND R.STATUS_CODE = 0 OR R.STATUS_CODE = 4) OR D.DAC_ARS_WEB = 'Y') AND D.DAC_AGR_CLOSE_DATE > '00000000'  THEN D.DAC_AGR_CLOSE_DATE
                  WHEN ((D.DAC_ARS_WEB!='Y' AND R.STATUS_CODE=0 or R.STATUS_CODE=4) ) and R.CHECK_IN_DATE >'00000000' THEN R.CHECK_IN_DATE
                  ELSE '00000000'   END  AS dacAgreementCloseDate,
            ISNULL(dauth.DCA_AUTHOR_RATE,0) AS dacAuthorizedRate,
            D.DAC_TAX_PAID_BY AS dacTaxPaidBy,            
            DA.DAA_LAST_NAME AS dacCompanyAdjLastName,
            DA.DAA_FIRST_NAME AS dacCompanyAdjFirstName,
            D.DAC_POLICY AS dacPolicy,
            D.DAC_INS_CLAIM AS dacInsClaim,
            D.DAC_LOCATION_NAME AS dacLocationName,
            D.DAC_MAKE AS dacMake,
            D.DAC_MODEL AS dacModel,
            D.DAC_YEAR AS dacYear,
            D.DAC_RENTAL_MAKE AS dacRentalMake,
            D.DAC_RENTAL_MODEL AS dacRentalModel,
            D.DAC_RENTAL_YEAR AS dacRentalYear,
            D.DAC_EQUIVALENT_GROUP AS dacEquivalentGroup,
            D.DAC_STATUS AS dacStatus,
            D.DAC_ARS_WEB AS dacArsWeb,
            D.DAC_ENTRY_ID AS dacEntryId,
            D.DAC_INVOICE_DATE AS  dacInvoiceDate,            
            DB1.DEBITOR_NAME AS dacInsCompanyName,
            ISNULL(V.INVOICE_NO,0) AS invoiceNo
            --, Case when dauth.DCA_AUTHOR_TO_DATE !='00000000' then datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112))) else  null end [ExpiringinDays]
            ,Case when dauth.DCA_AUTHOR_TO_DATE >'00000000' and r.STATUS_CODE = 0 then datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112))) 
				when D.DAC_STATUS= 4 then null
				when dauth.DCA_AUTHOR_TO_DATE >'00000000' then datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112))) 
            else  null end [ExpiringinDays]
            --48 Hour query also includes status =2, therefore, not in this query
    --        case when dauth_time.DCA_AUTHOR_TO_DATE > '00000000' then DATEDIFF(HOUR, GETDATE(), DATEADD(SECOND, dauth_time.DAC_AUTHOR_TO_TIME,convert(datetime,dauth_time.DCA_AUTHOR_TO_DATE,112)))
				--else null end
    --        as AuthDuebyHour
	, D.DAC_LOCATION_NAME LocationName
		, D.FINAL_AUTH FinalAuth
		--, CASE WHEN NH.DCN_CLAIM_ID is not null THEN 1 ELSE 0 END HasNotes
		, isnull(dauth.DCA_TOTAL_RENTAL,d.DAC_AUTHORIZED_RATE*d.DAC_AUTHOR_DAYS)  AS [Auth Total]
		, CASE WHEN R.PARENT_EXTEND_AGREEMENT_NO > 0 THEN 1 ELSE 0 END isRewrite, DATEADD(SECOND,DAC_MODIFIED_TIME, convert(datetime, convert(varchar(8),d.DAC_MODIFIED_DATE,112) )) Modified_Datetime
            FROM DA_CLAIMS D(NOLOCK)
					Left join Carpro_App..tblDial_RewriteWarehouse rw(nolock) on rw.Current_Agreement_No = D.DAC_AGREEMENT_NUMBER
                  LEFT OUTER JOIN RemedeyAgr_Rewrite R(NOLOCK) ON R.AGREEMENT_NO = D.DAC_AGREEMENT_NUMBER
                  LEFT OUTER JOIN Vw_Dial_Inv V(NOLOCK) ON V.AGREEMENT_NO = D.DAC_AGREEMENT_NUMBER AND V.INVOICE_TYPE = 'C' AND V.INV_STATUS != 9 AND D.DAC_INS_COMPANY_ID = v.DEBITOR_NO
                  LEFT OUTER JOIN EBILLING_INVOICE_DATA EB(NOLOCK) on EB.Entry_ID = D.DAC_ENTRY_ID
                  LEFT OUTER JOIN (SELECT da.DCA_CLAIM_ID,ISNULL(AVG(VAT_PER),0)VAT_PER,ISNULL(SUM(dca_a_days),0) dca_a_days,ISNULL(AVG(DCA_AUTHOR_RATE),0) DCA_AUTHOR_RATE,
													MAX(DA.DCA_AUTHOR_TO_DATE) DCA_AUTHOR_TO_DATE
													,SUM(DCA_TOTAL_RENTAL) as DCA_TOTAL_RENTAL
													, MAX(DA.DCA_ENTRY_ID) Last_Auth_ID
                                                      from DA_AUTHORIZATION da(NOLOCK) where DCA_BILL_TO=1 and (left(DCA_AUTHOR_TO_DATE, 4) > '2000' or DCA_AUTHOR_TO_DATE = '00000000') GROUP BY da.DCA_CLAIM_ID )
                                                      AS dauth ON D.DAC_ENTRY_ID = dauth.DCA_CLAIM_ID
                              Left join (select DAE_AUTH_ENTRY_ID, sum(DAE_PRICE) Auth_Extra_PerDay from [dbo].[DA_AUTHORIZATION_extraS](nolock)
							group by DAE_AUTH_ENTRY_ID	
                  ) AuthExtra on AuthExtra.DAE_AUTH_ENTRY_ID = dauth.Last_Auth_ID
                  Left join (select DAE_AUTH_ENTRY_ID, sum(DAE_PRICE) Auth_Ins_PerDay from [dbo].DA_AUTHORIZATION_INSURANCES(nolock)
							group by DAE_AUTH_ENTRY_ID	
                  ) AuthIns on AuthIns.DAE_AUTH_ENTRY_ID = dauth.Last_Auth_ID  
                              LEFT JOIN DEBITORS DB1(NOLOCK)
                              ON D.DAC_INS_COMPANY_ID = DB1.DEBITOR_CODE
                              LEFT JOIN DA_ADJUSTER DA(NOLOCK)
                              ON D.DAC_COMPANY_ADJUSTER_ID = DA.DAA_ENTRY_ID
                  --LEFT JOIN (
                  -- SELECT DCN_CLAIM_ID FROM DA_NOTES_HISTORY(NOLOCK)
                  -- WHERE DCN_NOTES_TYPE not in (8)
                  -- GROUP BY DCN_CLAIM_ID ) NH
                  -- ON 
                  -- D.DAC_ENTRY_ID = NH.DCN_CLAIM_ID
                  WHERE 
                  	  ( @sPolicy_Claim_No IS NULL OR  ((ltrim(rtrim(d.DAC_POLICY)) like + '%' + @sPolicy_Claim_No + '%') or (ltrim(rtrim(d.DAC_INS_CLAIM)) like + '%' + @sPolicy_Claim_No + '%')  or (ltrim(rtrim(d.DAC_ENTRY_ID)) = @sPolicy_Claim_No)))
        and (@ClientLastName is null or d.DAC_CLIENT_LAST_NAME like +'%' + @ClientLastName + '%' )
		--and (@iAgreementNo is null or d.DAC_AGREEMENT_NUMBER = @iAgreementNo)
		and (@iDebitorCode is null or d.DAC_INS_COMPANY_ID =@iDebitorCode)
		--and (@ddAdjusterID is null or @ddAdjusterID = 0 or d.DAC_COMPANY_ADJUSTER_ID =@ddAdjusterID)		
		and  (@iStatus is null or DAC_STATUS =@iStatus) 
		AND D.DAC_STATUS < 4
					and ((d.dac_company_adj_first_name like '%unknown%' or d.dac_company_adj_last_name like '%unknown%') or DAC_COMPANY_ADJUSTER_ID = 0)
				--and d.DAC_INS_COMPANY_ID in (SELECT  
				--		[INS_COMPANY_ID]
				--		FROM [dbo].[ADJUSTER_DEBITORS] (nolock)
				--		where ADJUSTER_ID = @AdjusterID)
				and DAC_INS_COMPANY_ID in (select distinct debitor_code from dbo.debitors (nolock) where SUV_DEBITOR_OF = @Parent_Debitor_Code)
						AND (D.DAC_AGR_OPEN_DATE ='00000000' OR DAC_AGR_OPEN_DATE >'20120101')
			) t4
			where (@iExpiringInDay is null or (@iExpiringInDay =0  and [ExpiringinDays] <= 0 ) or (@iExpiringInDay >0   and [ExpiringinDays] = @iExpiringInDay ))
			order by Modified_Datetime desc
	/*
		select DAC_COMPANY_ADJUSTER_ID, ISNULL(DAC_CLIENT_FIRST_NAME,'') + ' ' + ISNULL(DAC_CLIENT_LAST_NAME,'') AS [Client Name], DAC_CLIENT_PHONE CLIENT_PHONE
		,DAC_POLICY POLICY_NO, DAC_INS_CLAIM AS CLAIM_NO
		from da_claims(nolock)
		where DAC_STATUS < 4
--		AND dac_create_date >'20120101' 
		and ((dac_company_adj_first_name like '%unknown%' or dac_company_adj_last_name like '%unknown%') or DAC_COMPANY_ADJUSTER_ID = 0)
				and DAC_INS_COMPANY_ID in (SELECT  
						[INS_COMPANY_ID]
						FROM [dbo].[ADJUSTER_DEBITORS] (nolock)
						where ADJUSTER_ID = @AdjusterID)
	*/
	END
	    
	IF @Action is null
	BEGIN
		
		Declare @sMessage_EmptySearchReturn varchar(max)
		
		if @iExpiringInDay is null
		begin	
	
		select 		
		case
		when dacStatus = 4 then  'Invoice'
		when dacStatus = 3 then  'Expired'
		when dacStatus = 2 then  'Current'
		when dacArsWeb != 'Y'  and STATUS_CODE=4 then 	'Invoice'
		when dacArsWeb != 'Y'  and STATUS_CODE=0 then 	'Expired'
		when dacArsWeb != 'Y'  and STATUS_CODE=1 then 	'Current'
		when dacRentalAgrStatus=4 and invoiceNo > 0  then 'Invoice'
		when FinalAuth_fromAuth	='Y' then 'Final Auth'		
	    when isRewrite =1 and (rentaldays > dacAuthorDays) and (FinalAuth_fromAuth is null OR FinalAuth_fromAuth !='Y') then 'Expired'
	    when isRewrite =1 and rentaldays < dacAuthorDays then 'Current'		
		when dacRentalAgrStatus=0 then 'Reservation'
		when dacRentalAgrStatus=1 then 'Reservation'
		when dacRentalAgrStatus=2 and  FinalAuth_fromAuth	='Y'  then 'Final Auth'
		when dacRentalAgrStatus=2 then 'Current'		
		when dacRentalAgrStatus=3 then 'Expired'
		end as [Status_desc],  dacRentalAgrStatus [Status], isnull(dacClientFirstName,'') + ' ' + ISNULL(dacClientLastName,0) [Client Name]
		, dacAgreementNumber [Agreement No]
		, dacinsclaim [Claim #]
		, dacPolicy [Policy #]
		, dbo.fn_ConvertYYYYMMDDtoDIAL(dacAgreementOpenDate) [Rental Out]
		, dbo.fn_ConvertYYYYMMDDtoDIAL(dacAgreementCloseDate) [Rental In]
		,case when rentaldays < 0 then 0 else rentaldays end as [Rental Days]
		,convert(decimal(18,2),dacAuthorizedRate) [Auth Rate]
		, dacAuthorDays [Auth Days]
		,[Auth Total]
		,convert(decimal(18,2),case when totalRental < 0 then 0 else totalRental end) as [Total Rental (incl. Tax)] 
		, isnull(dacCompanyAdjFirstName,'') + ' ' + isnull(dacCompanyAdjLastName,'') [Adjuster Name]
		,0 [HasNotes] --??
		, case 
		when dacStatus = 4 then null 
		--when dacStatus = 2 then null 
		when (dacStatus = 2 and [ExpiringinDays] <= 0) then null 
		when dacAgreementNumber = 0 then null else [ExpiringinDays] end as [ExpiringinDays]
		, case when isRewrite = 1 and STATUS_CODE in (0,1,2) then 0 else okToBill end OkToBill
		, acknowledge Acknowledge
		, dispute Dispute
		,ebillrecPresent EbillingPresent
		,dacReservationNo ReservationNo
		,dacTaxPaidBy TaxPaidBy
		,dacLocationName BranchName
		,dacMake InsuredVehicleMake
		,dacModel InsuredVehicleModel
		,dacYear InsuredVehicleYear
		,dacRentalMake RentalMake
		,dacRentalModel RentalModel
		,dacRentalYear RentalYear
		,dacEquivalentGroup VehicleEquivalentClass
		,dacArsWeb IsFranchise
		,dacEntryId ClaimEntryId
		,dacInsCompanyName InsCompanyName
		,invoiceNo InvoiceNo
		, LocationName
		, FinalAuth
		,case when OkToBill = 1 and not (isRewrite = 1 and STATUS_CODE in (0,1,2)) then @InvoiceURL+CONVERT(varchar(20), convert(bigint, dacEntryId))
		else '' end as InvoiceLink
		, isRewrite
		, Modified_Datetime
		,FinalAuth_fromAuth
		from
		(
		SELECT convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112),112) expiringday,
		datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112),112)) expiringday1,
		 D.OK_TO_BILL AS okToBill,d.DAC_STATUS AS dacRentalAgrStatus
		,ISNULL(ISNULL(V.ACKNOWLEDGE,EB.ACKNOWLEDGE),'N') AS acknowledge  , ISNULL(ISNULL(V.DISPUTE,EB.DISPUTE),'N') AS dispute 
		,  case when EB.Entry_ID IS not null  then 'Y' else 'N' end AS ebillrecPresent,
		CASE 
             WHEN r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=0 OR R.STATUS_CODE=4)  THEN 
                   Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.[Agreement_Open_Time],CONVERT(DATETIME,CONVERT(VARCHAR,rw.[Agreement_Open_Date],112))), DATEADD(SECOND,R.CHECK_IN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,R.CHECK_IN_DATE,112))))
            WHEN r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=1 OR R.STATUS_CODE=2)  THEN 
                  Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.[Agreement_Open_Time],CONVERT(DATETIME,CONVERT(VARCHAR,rw.[Agreement_Open_Date],112))), GETDATE())
            WHEN D.DAC_ARS_WEB != 'Y' AND (R.STATUS_CODE=0 OR R.STATUS_CODE=4 ) AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000'
            THEN ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))))
            WHEN D.DAC_ARS_WEB != 'Y' AND (R.STATUS_CODE=0 OR R.STATUS_CODE=4 ) 
            THEN ISNULL(R.SOLD_DAYS,0)
            WHEN D.DAC_STATUS IN(3,4) AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000' --EXPIRED AND CLOSED
            THEN Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))            
            WHEN D.DAC_STATUS <= 3 AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000'  THEN --OPEN CONTRACT THEN 
                  ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()), 0)
            WHEN LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000'       
            THEN Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))
            WHEN LEFT(DAC_AGR_OPEN_DATE,4) > '2000' 
            THEN Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE())
            else null
            END AS rentaldays ,
                 CASE 
                           when r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=0 OR R.STATUS_CODE=4)  --previous closed and preclosed amount plus current open to date amount including extra, insurance and tax
							THEN                              
								isnull(rw.Rental_Amount,0.0) 
							when r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=1 OR R.STATUS_CODE=2)  --previous closed and preclosed amount plus current open to date amount including extra, insurance and tax
							THEN                              
								isnull(rw.Rental_Amount,0.0) +  (Carpro_App.dbo.fn_Min_Values(rw.Rate,dauth.DCA_AUTHOR_RATE) +  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0))*Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.[Agreement_Current_Open_TIME],CONVERT(DATETIME,CONVERT(VARCHAR,rw.[Agreement_Current_Open_Date],112))), GETDATE()) * (1.0+ ISNULL(dauth.VAT_PER,0.0)/100.0)   
                            WHEN D.DAC_ARS_WEB!='Y' AND  R.STATUS_CODE=4
                            THEN V.INVOICE_AMOUNT
                            WHEN D.DAC_ARS_WEB!='Y' AND  R.STATUS_CODE=0
                            THEN R.Debitor_Total
                            WHEN D.DAC_ARS_WEB ='Y' AND  D.DAC_STATUS=4
							THEN	EB.TOTAL
							WHEN D.DAC_ARS_WEB ='Y' AND  D.DAC_STATUS=3 AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000' --EXPIRED
							THEN	
								ROUND((ISNULL(dauth.DCA_AUTHOR_RATE,0)+  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0)) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))) * (1.0 +ISNULL(dauth.VAT_PER,0.0)/100.0) ,2)
                            WHEN LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000' --OPEN CONTRACT
							THEN	ROUND((ISNULL(dauth.DCA_AUTHOR_RATE,0)+  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0)) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE())) * (1.0 +ISNULL(dauth.VAT_PER,0.0)/100.0) ,2)
                              
                            ELSE NULL 
                              --WHEN D.DAC_STATUS=4 or R.STATUS_CODE=4   THEN 
                              --      ROUND(dauth.DCA_AUTHOR_RATE * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))))  +
                              --      (ISNULL(dauth.DCA_AUTHOR_RATE,0) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))) * ISNULL(dauth.VAT_PER,0)/100),2)
                              --WHEN DAC_AGR_OPEN_DATE > '00000000' THEN
                              --      ISNULL(dauth.DCA_AUTHOR_RATE,0) * ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()),0) + 
                              --      ((ISNULL(dauth.DCA_AUTHOR_RATE,0)* ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()),0)) * ISNULL(dauth.VAT_PER,0)/100)
                              --ELSE NULL      
            end AS totalRental ,
            ISNULL(dauth.dca_a_days,0) AS dacAuthorDays,
            D.DAC_RESERVATION_NO AS dacReservationNo,
            D.DAC_AGREEMENT_NUMBER AS dacAgreementNumber,
            D.DAC_CLIENT_LAST_NAME AS dacClientLastName,
            D.DAC_CLIENT_FIRST_NAME AS dacClientFirstName,
            CASE
                WHEN r.PARENT_EXTEND_AGREEMENT_NO>0 THEN
					rw.[Agreement_Open_Date]
				WHEN LEFT(D.DAC_AGR_OPEN_DATE,4) >'2000' THEN
				D.DAC_AGR_OPEN_DATE 
				ELSE
				NULL
            END
            AS dacAgreementOpenDate,
            CASE 
                  WHEN ((D.DAC_ARS_WEB!='Y' AND R.STATUS_CODE = 0 OR R.STATUS_CODE = 4) OR D.DAC_ARS_WEB = 'Y') AND D.DAC_AGR_CLOSE_DATE > '00000000'  THEN D.DAC_AGR_CLOSE_DATE
                  WHEN ((D.DAC_ARS_WEB!='Y' AND R.STATUS_CODE=0 or R.STATUS_CODE=4) ) and R.CHECK_IN_DATE >'00000000' THEN R.CHECK_IN_DATE
                  ELSE '00000000'   END   AS dacAgreementCloseDate,
            ISNULL(dauth.DCA_AUTHOR_RATE,0) AS dacAuthorizedRate,
            D.DAC_TAX_PAID_BY AS dacTaxPaidBy,            
            DA.DAA_LAST_NAME AS dacCompanyAdjLastName,
            DA.DAA_FIRST_NAME AS dacCompanyAdjFirstName,
            D.DAC_POLICY AS dacPolicy,
            D.DAC_INS_CLAIM AS dacInsClaim,
            D.DAC_LOCATION_NAME AS dacLocationName,
            D.DAC_MAKE AS dacMake,
            D.DAC_MODEL AS dacModel,
            D.DAC_YEAR AS dacYear,
            D.DAC_RENTAL_MAKE AS dacRentalMake,
            D.DAC_RENTAL_MODEL AS dacRentalModel,
            D.DAC_RENTAL_YEAR AS dacRentalYear,
            D.DAC_EQUIVALENT_GROUP AS dacEquivalentGroup,
            D.DAC_STATUS AS dacStatus,
            D.DAC_ARS_WEB AS dacArsWeb,
            D.DAC_ENTRY_ID AS dacEntryId,
            D.DAC_INVOICE_DATE AS  dacInvoiceDate,            
            DB1.DEBITOR_NAME AS dacInsCompanyName,
            case when v.INVOICE_NO is not null then v.INVOICE_NO
                  when eb.ENTRY_ID is not null then eb.ENTRY_ID
                  end invoiceNo
           -- , Case when dauth.DCA_AUTHOR_TO_DATE !='00000000' then datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112))) else  null end [ExpiringinDays]
           , Case 
           when dauth.FinalAuth_fromAuth='Y' then null
           when r.STATUS_CODE =0  and  dauth.DCA_AUTHOR_TO_DATE is null then -1
           when D.DAC_STATUS= 3  and  dauth.DCA_AUTHOR_TO_DATE is null then -1
           when r.STATUS_CODE =4 then null
           when dauth.DCA_AUTHOR_TO_DATE >'00000000' and r.STATUS_CODE = 0 then datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112))) 
		   when D.DAC_STATUS= 4 then null
		   when dauth.DCA_AUTHOR_TO_DATE >'00000000' then datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112))) 
				
            else  null end [ExpiringinDays]
	, D.DAC_LOCATION_NAME LocationName
		, D.FINAL_AUTH FinalAuth 
		--, CASE WHEN NH.DCN_CLAIM_ID is not null THEN 1 ELSE 0 END HasNotes
		, isnull(dauth.DCA_TOTAL_RENTAL,d.DAC_AUTHORIZED_RATE*d.DAC_AUTHOR_DAYS)  AS [Auth Total]
		, CASE WHEN R.PARENT_EXTEND_AGREEMENT_NO > 0 THEN 1 ELSE 0 END isRewrite, r.STATUS_CODE,  DATEADD(SECOND,DAC_MODIFIED_TIME, convert(datetime, convert(varchar(8),d.DAC_MODIFIED_DATE,112) )) Modified_Datetime
		,FinalAuth_fromAuth
            FROM DA_CLAIMS D(NOLOCK)
                  LEFT OUTER JOIN RemedeyAgr_Rewrite R(NOLOCK) ON R.AGREEMENT_NO = D.DAC_AGREEMENT_NUMBER
                  left join Carpro_App..tblDial_RewriteWarehouse rw(nolock) on rw.Current_Agreement_No = D.DAC_AGREEMENT_NUMBER
                  LEFT OUTER JOIN Vw_Dial_Inv V(NOLOCK) ON V.AGREEMENT_NO = D.DAC_AGREEMENT_NUMBER AND V.INVOICE_TYPE = 'C' AND V.INV_STATUS != 9 AND D.DAC_INS_COMPANY_ID = v.DEBITOR_NO
                  LEFT OUTER JOIN EBILLING_INVOICE_DATA EB(NOLOCK) on EB.Entry_ID = D.DAC_ENTRY_ID
                 LEFT OUTER JOIN (SELECT da.DCA_CLAIM_ID,ISNULL(AVG(VAT_PER),0)VAT_PER,ISNULL(SUM(dca_a_days),0) dca_a_days,ISNULL(AVG(DCA_AUTHOR_RATE),0) DCA_AUTHOR_RATE,
													MAX(DA.DCA_AUTHOR_TO_DATE) DCA_AUTHOR_TO_DATE
													,SUM(DCA_TOTAL_RENTAL) as DCA_TOTAL_RENTAL
													, MAX(DA.DCA_ENTRY_ID) Last_Auth_ID
													, max(ltrim(rtrim(FINAL_AUTH))) as FinalAuth_fromAuth
                                                      from DA_AUTHORIZATION da(NOLOCK) where DCA_BILL_TO=1  and (left(DCA_AUTHOR_TO_DATE, 4) > '2000' or DCA_AUTHOR_TO_DATE = '00000000') GROUP BY da.DCA_CLAIM_ID )
                                                      AS dauth ON D.DAC_ENTRY_ID = dauth.DCA_CLAIM_ID
                  Left join (select DAE_AUTH_ENTRY_ID, sum(DAE_PRICE) Auth_Extra_PerDay from [dbo].[DA_AUTHORIZATION_extraS](nolock)
							group by DAE_AUTH_ENTRY_ID	
                  ) AuthExtra on AuthExtra.DAE_AUTH_ENTRY_ID = dauth.Last_Auth_ID
                  Left join (select DAE_AUTH_ENTRY_ID, sum(DAE_PRICE) Auth_Ins_PerDay from [dbo].DA_AUTHORIZATION_INSURANCES(nolock)
							group by DAE_AUTH_ENTRY_ID	
                  ) AuthIns on AuthIns.DAE_AUTH_ENTRY_ID = dauth.Last_Auth_ID                
                              LEFT JOIN DEBITORS DB1(NOLOCK)
                              ON D.DAC_INS_COMPANY_ID = DB1.DEBITOR_CODE
                              LEFT JOIN DA_ADJUSTER DA(NOLOCK)
                              ON D.DAC_COMPANY_ADJUSTER_ID = DA.DAA_ENTRY_ID
                 --LEFT JOIN (
                 --  SELECT DCN_CLAIM_ID FROM DA_NOTES_HISTORY(NOLOCK)
                 --  WHERE DCN_NOTES_TYPE not in (8)
                 --  GROUP BY DCN_CLAIM_ID ) NH
                 --  ON 
                 --  D.DAC_ENTRY_ID = NH.DCN_CLAIM_ID
        WHERE ( @sPolicy_Claim_No IS NULL OR  ((ltrim(rtrim(d.DAC_POLICY)) like + '%' + @sPolicy_Claim_No + '%') or (ltrim(rtrim(d.DAC_INS_CLAIM)) like + '%' + @sPolicy_Claim_No + '%')  or (ltrim(rtrim(d.DAC_ENTRY_ID)) = @sPolicy_Claim_No)))
        and (@ClientLastName is null or DAC_CLIENT_LAST_NAME like +'%' + @ClientLastName + '%' )
		and (@iAgreementNo is null or DAC_AGREEMENT_NUMBER = @iAgreementNo)
		and (@iDebitorCode is null or DAC_INS_COMPANY_ID =@iDebitorCode)
		--and (@ddAdjusterID is null or @ddAdjusterID = 0 or DAC_COMPANY_ADJUSTER_ID =@ddAdjusterID)		
		and  (@iStatus is null or DAC_STATUS =@iStatus) 
		and DAC_STATUS < 5 
		--and  (@iExpiringInDay is null or (dauth.DCA_AUTHOR_TO_DATE between '20120101' and '20990101'))
		--and ( @iExpiringInDay is null or (dauth.DCA_AUTHOR_TO_DATE between '20120101' and '20140101' and  (( @iExpiringInDay =0 and datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112),112)) < =0 )
		--or (  @iExpiringInDay >0 and datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112),112)) =@iExpiringInDay ) )))
		--and dauth.DCA_AUTHOR_TO_DATE between '20120101' and '20140101' and  (  datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112),112)) < =0 )
		--and DAC_INS_COMPANY_ID in (SELECT  
		
		--				[INS_COMPANY_ID]
		--				FROM [dbo].[ADJUSTER_DEBITORS] (nolock)						
		--				where (@AdjusterID is null or @AdjusterID = 0 or ADJUSTER_ID = @AdjusterID))
		and DAC_INS_COMPANY_ID in (select distinct debitor_code from dbo.debitors (nolock) where SUV_DEBITOR_OF = @Parent_Debitor_Code)
		and dac_create_date >='20120101'
		) tt2
		order by Modified_Datetime desc
		
				--Send email to alina
		if @@ROWCOUNT =0
		begin
			select @sMessage_EmptySearchReturn = 'The search conditions are Adjuster ID:' + convert(varchar(20),ISNULL(@AdjusterID , '')) + '  Adjuster Name:' + convert(varchar(100),ISNULL(@AdjName , ''))
+'   Policy or Claim_No:'+ convert(varchar(20),ISNULL(@sPolicy_Claim_No , ''))
+'   Client LastName:'+ convert(varchar(20),ISNULL(@ClientLastName , ''))
+'   AgreementNo:'+ convert(varchar(20),ISNULL(@iAgreementNo , ''))
+'   DebitorCode:'+ convert(varchar(20),ISNULL(@iDebitorCode , ''))
+'   ExpiringInDay:'+ convert(varchar(20),ISNULL(@iExpiringInDay , ''))
	
	if @AdjusterID > 0 	
	EXEC msdb..sp_send_dbmail @profile_name='AltBill',
						@recipients='aluztono@discountcar.com;lrao@discountcar.com',
						--@recipients='lrao@discountcar.com',
						@from_address  = 'lrao@discountcar.com',
						@subject='Dial 3.0: No Search Results',
						@body=@sMessage_EmptySearchReturn
					
	
	--	insert into Carpro_App.dbo.[SendEmailQueue]([dbName],[EmailAddress]
 --     ,[EmailfromAddress]
 --     ,[EmailSubject]
 --     ,[EmailBody]
 --     ,[EmailRecipientName]
 --     ,[EntryTime]
 --     ,[EntryUser])
	--Values ('DIAL3.0','dialsupport@discountcar.com','dctr@discountcar.com','DIAL 3.0: No Search Results', @sMessage_EmptySearchReturn ,'DCTR', getdate(), @AdjusterID)
		
	end
				
		end
		else --@iExpiringInDay is not null
		begin
		select *
		into #mytemp
		from
		(
		SELECT convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112),112) expiringday,
		datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112),112)) expiringday1,
		D.OK_TO_BILL AS okToBill,
		 d.DAC_STATUS AS dacRentalAgrStatus
		,ISNULL(ISNULL(V.ACKNOWLEDGE,EB.ACKNOWLEDGE),'N') AS acknowledge  , ISNULL(ISNULL(V.DISPUTE,EB.DISPUTE),'N') AS dispute 
		,  case when EB.Entry_ID IS not null  then 'Y' else 'N' end AS ebillrecPresent,
                  CASE
            WHEN r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=0 OR R.STATUS_CODE=4)  THEN 
                   Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.[Agreement_Open_Time],CONVERT(DATETIME,CONVERT(VARCHAR,rw.[Agreement_Open_Date],112))), DATEADD(SECOND,R.CHECK_IN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,R.CHECK_IN_DATE,112))))
            WHEN r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=1 OR R.STATUS_CODE=2)  THEN 
                  Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.[Agreement_Open_Time],CONVERT(DATETIME,CONVERT(VARCHAR,rw.[Agreement_Open_Date],112))), GETDATE())
            WHEN D.DAC_ARS_WEB != 'Y' AND (R.STATUS_CODE=0 OR R.STATUS_CODE=4 ) AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000'
            THEN ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))))
            WHEN D.DAC_ARS_WEB != 'Y' AND (R.STATUS_CODE=0 OR R.STATUS_CODE=4 ) 
            THEN ISNULL(R.SOLD_DAYS,0)
            WHEN D.DAC_STATUS IN(3,4) AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000' --EXPIRED AND CLOSED
            THEN Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))            
            WHEN D.DAC_STATUS <= 3 AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000'  THEN --OPEN CONTRACT THEN 
                  ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()), 0)
            WHEN LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000'       
            THEN Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))
            WHEN LEFT(DAC_AGR_OPEN_DATE,4) > '2000' 
            THEN Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE())
            else null
            END AS rentaldays ,
                 CASE 
                           when r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=0 OR R.STATUS_CODE=4)  --previous closed and preclosed amount plus current open to date amount including extra, insurance and tax
							THEN                              
								isnull(rw.Rental_Amount,0.0) 
							when r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=1 OR R.STATUS_CODE=2)  --previous closed and preclosed amount plus current open to date amount including extra, insurance and tax
							THEN                              
								isnull(rw.Rental_Amount,0.0) +  (Carpro_App.dbo.fn_Min_Values(rw.Rate,dauth.DCA_AUTHOR_RATE) +  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0))*Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.[Agreement_Current_Open_TIME],CONVERT(DATETIME,CONVERT(VARCHAR,rw.[Agreement_Current_Open_Date],112))), GETDATE()) * (1.0+ ISNULL(dauth.VAT_PER,0.0)/100.0)   
                            WHEN D.DAC_ARS_WEB!='Y' AND  R.STATUS_CODE=4
                            THEN V.INVOICE_AMOUNT
                            WHEN D.DAC_ARS_WEB!='Y' AND  R.STATUS_CODE=0
                            THEN R.Debitor_Total
                            WHEN D.DAC_ARS_WEB ='Y' AND  D.DAC_STATUS=4
							THEN	EB.TOTAL
							WHEN D.DAC_ARS_WEB ='Y' AND  D.DAC_STATUS=3 AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000' --EXPIRED
							THEN	
								ROUND((ISNULL(dauth.DCA_AUTHOR_RATE,0)+  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0)) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))) * (1.0 +ISNULL(dauth.VAT_PER,0.0)/100.0) ,2)
                            WHEN LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000' --OPEN CONTRACT
							THEN	ROUND((ISNULL(dauth.DCA_AUTHOR_RATE,0)+  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0)) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE())) * (1.0 +ISNULL(dauth.VAT_PER,0.0)/100.0) ,2)
                              
                            ELSE NULL 
                              --WHEN D.DAC_STATUS=4 or R.STATUS_CODE=4   THEN 
                              --      ROUND(dauth.DCA_AUTHOR_RATE * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))))  +
                              --      (ISNULL(dauth.DCA_AUTHOR_RATE,0) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))) * ISNULL(dauth.VAT_PER,0)/100),2)
                              --WHEN DAC_AGR_OPEN_DATE > '00000000' THEN
                              --      ISNULL(dauth.DCA_AUTHOR_RATE,0) * ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()),0) + 
                              --      ((ISNULL(dauth.DCA_AUTHOR_RATE,0)* ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()),0)) * ISNULL(dauth.VAT_PER,0)/100)
                              --ELSE NULL      
            end AS totalRental ,
            ISNULL(dauth.dca_a_days,0) AS dacAuthorDays,
            D.DAC_RESERVATION_NO AS dacReservationNo,
            D.DAC_AGREEMENT_NUMBER AS dacAgreementNumber,
            D.DAC_CLIENT_LAST_NAME AS dacClientLastName,
            D.DAC_CLIENT_FIRST_NAME AS dacClientFirstName,
			CASE
                WHEN r.PARENT_EXTEND_AGREEMENT_NO>0 THEN
					rw.[Agreement_Open_Date]
				WHEN LEFT(D.DAC_AGR_OPEN_DATE,4) >'2000' THEN
					D.DAC_AGR_OPEN_DATE 
				ELSE
					NULL
				END
            AS dacAgreementOpenDate,
            CASE 
                  WHEN ((D.DAC_ARS_WEB!='Y' AND R.STATUS_CODE = 0 OR R.STATUS_CODE = 4) OR D.DAC_ARS_WEB = 'Y') AND D.DAC_AGR_CLOSE_DATE > '00000000'  THEN D.DAC_AGR_CLOSE_DATE
                  WHEN ((D.DAC_ARS_WEB!='Y' AND R.STATUS_CODE=0 or R.STATUS_CODE=4) ) and R.CHECK_IN_DATE >'00000000' THEN R.CHECK_IN_DATE
                  ELSE '00000000'   END   AS dacAgreementCloseDate,
            ISNULL(dauth.DCA_AUTHOR_RATE,0) AS dacAuthorizedRate,
            D.DAC_TAX_PAID_BY AS dacTaxPaidBy,            
            DA.DAA_LAST_NAME AS dacCompanyAdjLastName,
            DA.DAA_FIRST_NAME AS dacCompanyAdjFirstName,
            D.DAC_POLICY AS dacPolicy,
            D.DAC_INS_CLAIM AS dacInsClaim,
            D.DAC_LOCATION_NAME AS dacLocationName,
            D.DAC_MAKE AS dacMake,
            D.DAC_MODEL AS dacModel,
            D.DAC_YEAR AS dacYear,
            D.DAC_RENTAL_MAKE AS dacRentalMake,
            D.DAC_RENTAL_MODEL AS dacRentalModel,
            D.DAC_RENTAL_YEAR AS dacRentalYear,
            D.DAC_EQUIVALENT_GROUP AS dacEquivalentGroup,
            D.DAC_STATUS AS dacStatus,
            D.DAC_ARS_WEB AS dacArsWeb,
            D.DAC_ENTRY_ID AS dacEntryId,
            D.DAC_INVOICE_DATE AS  dacInvoiceDate,            
            DB1.DEBITOR_NAME AS dacInsCompanyName,
            case when v.INVOICE_NO is not null then v.INVOICE_NO
                  when eb.ENTRY_ID is not null then eb.ENTRY_ID
                  end invoiceno
                        --, Case when dauth.DCA_AUTHOR_TO_DATE !='00000000' then datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112))) else  null end [ExpiringinDays]
            ,Case 
            when dauth.FinalAuth_fromAuth='Y' then null
            when r.STATUS_CODE =0  and  dauth.DCA_AUTHOR_TO_DATE is null then -1
			when D.DAC_STATUS= 3  and  dauth.DCA_AUTHOR_TO_DATE is null then -1
            when r.STATUS_CODE =4 then null
            when dauth.DCA_AUTHOR_TO_DATE >'00000000' and r.STATUS_CODE = 0 then datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112))) 
				when D.DAC_STATUS= 4 then null
				when dauth.DCA_AUTHOR_TO_DATE >'00000000' then datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112))) 
            else  null end [ExpiringinDays]
            --48 Hour query also includes status =2, therefore, not in this query
    --        case when dauth_time.DCA_AUTHOR_TO_DATE > '00000000' then DATEDIFF(HOUR, GETDATE(), DATEADD(SECOND, dauth_time.DAC_AUTHOR_TO_TIME,convert(datetime,dauth_time.DCA_AUTHOR_TO_DATE,112)))
				--else null end
    --        as AuthDuebyHour
	, D.DAC_LOCATION_NAME LocationName
		, D.FINAL_AUTH FinalAuth 
		--, CASE WHEN NH.DCN_CLAIM_ID is not null THEN 1 ELSE 0 END HasNotes
		, isnull(dauth.DCA_TOTAL_RENTAL,d.DAC_AUTHORIZED_RATE*d.DAC_AUTHOR_DAYS)  AS [Auth Total]
		, CASE WHEN R.PARENT_EXTEND_AGREEMENT_NO > 0 THEN 1 ELSE 0 END isRewrite
		, R.STATUS_CODE,  DATEADD(SECOND,DAC_MODIFIED_TIME, convert(datetime, convert(varchar(8),d.DAC_MODIFIED_DATE,112) )) Modified_Datetime
		,FinalAuth_fromAuth
            FROM DA_CLAIMS D(NOLOCK)
                  LEFT OUTER JOIN RemedeyAgr_Rewrite R(NOLOCK) ON R.AGREEMENT_NO = D.DAC_AGREEMENT_NUMBER
                  left join Carpro_App..tblDial_RewriteWarehouse rw(nolock) on rw.Current_Agreement_No = D.DAC_AGREEMENT_NUMBER
                  LEFT OUTER JOIN Vw_Dial_Inv V(NOLOCK) ON V.AGREEMENT_NO = D.DAC_AGREEMENT_NUMBER AND V.INVOICE_TYPE = 'C' AND V.INV_STATUS != 9 AND D.DAC_INS_COMPANY_ID = v.DEBITOR_NO
                  LEFT OUTER JOIN EBILLING_INVOICE_DATA EB(NOLOCK) on EB.Entry_ID = D.DAC_ENTRY_ID
                 LEFT OUTER JOIN (SELECT da.DCA_CLAIM_ID,ISNULL(AVG(VAT_PER),0)VAT_PER,ISNULL(SUM(dca_a_days),0) dca_a_days,ISNULL(AVG(DCA_AUTHOR_RATE),0) DCA_AUTHOR_RATE,
													MAX(DA.DCA_AUTHOR_TO_DATE) DCA_AUTHOR_TO_DATE
													,SUM(DCA_TOTAL_RENTAL) as DCA_TOTAL_RENTAL
													, MAX(DA.DCA_ENTRY_ID) Last_Auth_ID
													, max(ltrim(rtrim(FINAL_AUTH))) as FinalAuth_fromAuth
                                                      from DA_AUTHORIZATION da(NOLOCK) where DCA_BILL_TO=1 and (left(DCA_AUTHOR_TO_DATE, 4) > '2000' or DCA_AUTHOR_TO_DATE = '00000000') GROUP BY da.DCA_CLAIM_ID )
                                                      AS dauth ON D.DAC_ENTRY_ID = dauth.DCA_CLAIM_ID
                  Left join (select DAE_AUTH_ENTRY_ID, sum(DAE_PRICE) Auth_Extra_PerDay from [dbo].[DA_AUTHORIZATION_extraS](nolock)
							group by DAE_AUTH_ENTRY_ID	
                  ) AuthExtra on AuthExtra.DAE_AUTH_ENTRY_ID = dauth.Last_Auth_ID
                  Left join (select DAE_AUTH_ENTRY_ID, sum(DAE_PRICE) Auth_Ins_PerDay from [dbo].DA_AUTHORIZATION_INSURANCES(nolock)
							group by DAE_AUTH_ENTRY_ID	
                  ) AuthIns on AuthIns.DAE_AUTH_ENTRY_ID = dauth.Last_Auth_ID  
                              LEFT JOIN DEBITORS DB1(NOLOCK)
                              ON D.DAC_INS_COMPANY_ID = DB1.DEBITOR_CODE
                              LEFT JOIN DA_ADJUSTER DA(NOLOCK)
                              ON D.DAC_COMPANY_ADJUSTER_ID = DA.DAA_ENTRY_ID
					--LEFT JOIN (
     --              SELECT DCN_CLAIM_ID FROM DA_NOTES_HISTORY(NOLOCK)
     --              WHERE DCN_NOTES_TYPE not in (8)
     --              GROUP BY DCN_CLAIM_ID ) NH
     --              ON 
     --              D.DAC_ENTRY_ID = NH.DCN_CLAIM_ID
        WHERE --( @sPolicy_Claim_No IS NULL OR  (ltrim(rtrim(d.DAC_POLICY)) =@sPolicy_Claim_No or ltrim(rtrim(d.DAC_INS_CLAIM)) =@sPolicy_Claim_No ))
        ( @sPolicy_Claim_No IS NULL OR  ((ltrim(rtrim(d.DAC_POLICY)) like + '%' + @sPolicy_Claim_No + '%') or (ltrim(rtrim(d.DAC_INS_CLAIM)) like + '%' + @sPolicy_Claim_No + '%')))
        and (@ClientLastName is null or DAC_CLIENT_LAST_NAME like +'%' + @ClientLastName + '%' )
		and (@iAgreementNo is null or DAC_AGREEMENT_NUMBER = @iAgreementNo)
		and (@iDebitorCode is null or DAC_INS_COMPANY_ID =@iDebitorCode)
		--and (@ddAdjusterID is null or @ddAdjusterID = 0 or DAC_COMPANY_ADJUSTER_ID =@ddAdjusterID)
		and  (@iStatus is null or DAC_STATUS =@iStatus)
		and  (@iExpiringInDay is null or (dauth.DCA_AUTHOR_TO_DATE between '20120101' and '20990101' or dauth.DCA_AUTHOR_TO_DATE is null) )
		--and ( @iExpiringInDay is null or (dauth.DCA_AUTHOR_TO_DATE between '20120101' and '20140101' and  (( @iExpiringInDay =0 and datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112),112)) < =0 )
		--or (  @iExpiringInDay >0 and datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112),112)) =@iExpiringInDay ) )))
		--and dauth.DCA_AUTHOR_TO_DATE between '20120101' and '20140101' and  (  datediff(day, convert(date,getdate()), convert(datetime, convert(varchar(8), dauth.DCA_AUTHOR_TO_DATE,112),112)) < =0 )
		--and DAC_INS_COMPANY_ID in (SELECT  [INS_COMPANY_ID] FROM [dbo].[ADJUSTER_DEBITORS] (nolock) where ADJUSTER_ID = @AdjusterID)
		and DAC_INS_COMPANY_ID in (select distinct debitor_code from dbo.debitors (nolock) where SUV_DEBITOR_OF = @Parent_Debitor_Code)
		and dac_create_date >='20120101' 
		and DAC_STATUS < 5
		) tt2
		--where  (@iExpiringInDay is null or tt2.expiringday1 <=0)	    
		
	select  case 
		when dacStatus = 4 then  'Invoice'
		when dacStatus = 3 then  'Expired'
		when dacStatus = 2 then  'Current'
		when dacArsWeb != 'Y'  and STATUS_CODE=4 then 	'Invoice'
		when dacArsWeb != 'Y'  and STATUS_CODE=0 then 	'Expired'
		when dacArsWeb != 'Y'  and STATUS_CODE=1 then 	'Current'
		when dacRentalAgrStatus=4 and invoiceNo > 0  then 'Invoice'
		when FinalAuth_fromAuth	='Y' then 'Final Auth'
	    when isRewrite =1 and (rentaldays > dacAuthorDays) and (FinalAuth_fromAuth is null OR FinalAuth_fromAuth !='Y') then 'Expired'
	    when isRewrite =1 and rentaldays < dacAuthorDays then 'Current'
		
		when dacRentalAgrStatus=0 then 'Reservation'
		when dacRentalAgrStatus=1 then 'Reservation'
		when dacRentalAgrStatus=2 and  FinalAuth_fromAuth	='Y'  then 'Final Auth'
		when dacRentalAgrStatus=2 then 'Current'		
		when dacRentalAgrStatus=3 then 'Expired'
		end as [Status_desc], 
		dacRentalAgrStatus [Status], isnull(dacClientFirstName,'') + ' ' + ISNULL(dacClientLastName,0) [Client Name]
		, dacAgreementNumber [Agreement No]
		, dacinsclaim [Claim #]
		, dacPolicy [Policy #]
		, dbo.fn_ConvertYYYYMMDDtoDIAL(dacAgreementOpenDate)    [Rental Out]
		,dbo.fn_ConvertYYYYMMDDtoDIAL(dacAgreementCloseDate)     [Rental In]
		,case when rentaldays < 0 then 0 else rentaldays end as [Rental Days]
		,convert(decimal(18,2),dacAuthorizedRate) [Auth Rate]
		, dacAuthorDays [Auth Days]
		,[Auth Total]
		,convert(decimal(18,2),case when totalRental < 0 then 0 else totalRental end) as [Total Rental (incl. Tax)] 
		, isnull(dacCompanyAdjFirstName,'') + ' ' + isnull(dacCompanyAdjLastName,'') [Adjuster Name]
		,0 [HasNotes] --??
		, case when dacStatus = 4 then null 
		--when dacStatus = 3 then null 
		when (dacStatus = 2 and [ExpiringinDays] <= 0) then null 
		 when dacAgreementNumber = 0 then null  else [ExpiringinDays] end as [ExpiringinDays]
		,case when isRewrite = 1 and STATUS_CODE in (0,1,2) then 0 else okToBill end OkToBill
		--, okToBill OkToBill
		, acknowledge Acknowledge
		, dispute Dispute
		,ebillrecPresent EbillingPresent
		,dacReservationNo ReservationNo
		--,dacAgreementOpenDate AgreementOpenDate
		--,dacAgreementCloseDate AgreementCloseDate
		,dacTaxPaidBy TaxPaidBy
		--, isnull(dacCompanyAdjFirstName,'') + ' ' + isnull(dacCompanyAdjLastName,'')  AdjsterName
		,dacLocationName BranchName
		,dacMake InsuredVehicleMake
		,dacModel InsuredVehicleModel
		,dacYear InsuredVehicleYear
		,dacRentalMake RentalMake
		,dacRentalModel RentalModel
		,dacRentalYear RentalYear
		,dacEquivalentGroup VehicleEquivalentClass
		,dacArsWeb IsFranchise
		,dacEntryId ClaimEntryId
		--,dacInvoiceDate InvoiceDate
		,dacInsCompanyName InsCompanyName
		,invoiceNo InvoiceNo
		, LocationName
		, FinalAuth
		,case when OkToBill = 1 and not(isRewrite = 1 and STATUS_CODE in (0,1,2)) then @InvoiceURL+CONVERT(varchar(20), convert(bigint, dacEntryId))
		else '' end as InvoiceLink
		, isRewrite
		, Modified_Datetime
		from
		(
		select * from #mytemp
		where  
		(@iExpiringInDay is null or (@iExpiringInDay =0  and dacStatus=3 ) and dacRentalAgrStatus not in (0,1) or (@iExpiringInDay >0   and [ExpiringinDays] = @iExpiringInDay  and dacRentalAgrStatus not in (0,1)) )	--expired data not include reservation  
		
		--(@iExpiringInDay is null or (@iExpiringInDay =0  and [ExpiringinDays] <= 0 ) and dacRentalAgrStatus not in (0,1) or (@iExpiringInDay >0   and [ExpiringinDays] = @iExpiringInDay  and dacRentalAgrStatus not in (0,1)) )	--expired data not include reservation  
		) ttt
		
		order by Modified_Datetime desc
		
		--Send email to alina
		if @@ROWCOUNT =0
		begin
			select @sMessage_EmptySearchReturn = 'The search conditions are Adjuster Name: '+ @AdjName +', Adjuster ID:' + convert(varchar(20),ISNULL(@AdjusterID , ''))
+', @Policy_Claim_No:'+ convert(varchar(20),ISNULL(@sPolicy_Claim_No , ''))
+', @ClientLastName:'+ convert(varchar(20),ISNULL(@ClientLastName , ''))
+', @AgreementNo:'+ convert(varchar(20),ISNULL(@iAgreementNo , ''))
+', @DebitorCode:'+ convert(varchar(20),ISNULL(@iDebitorCode , ''))
+', @ExpiringInDay:'+ convert(varchar(20),ISNULL(@iExpiringInDay , ''))


			
			if @AdjusterID > 0 
			EXEC msdb..sp_send_dbmail @profile_name='AltBill',
						@recipients='lrao@discountcar.com',
						@from_address  = 'lrao@discountcar.com',
						@subject='MyDial: No Search Results',
						@body=@sMessage_EmptySearchReturn
						
	--	insert into Carpro_App.dbo.[SendEmailQueue]([dbName],[EmailAddress]
 --     ,[EmailfromAddress]
 --     ,[EmailSubject]
 --     ,[EmailBody]
 --     ,[EmailRecipientName]
 --     ,[EntryTime]
 --     ,[EntryUser])
	--Values ('DIAL 3.0','dialsupport@discountcar.com','dctr@discountcar.com','DIAL 3.0: No Search Results', @sMessage_EmptySearchReturn ,'DIAL', getdate(),@AdjusterID)
		
		end
		drop table #mytemp
		end
	END	    
END



















