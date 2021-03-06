USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Reauthorize]    Script Date: 04/05/2018 09:39:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



--select * from DA_AUTHORIZATION where DCA_CLAIM_ID=3184431

--exec spDIAL_Reauthorize 3218825 

--select * from DA_CLAIMS where DAC_AGREEMENT_NUMBER=96074

-- authori
--exec spDIAL_Reauthorize 4170014484
-- exec spDIAL_Reauthorize 3184431     --LIVE DATA
-- exec spDIAL_Reauthorize 3152796 --LIVE DATA
-- exec spDIAL_Reauthorize 3140324 --entryid 
-- exec spDIAL_Reauthorize 3120164 --entryid acknowledge status
-- exec spDIAL_Reauthorize 3137209 --entryid acknowledge status
-- select * from da_claims where dac_entry_id= 3137363

--exec spDIAL_Reauthorize 3786967  

-- exec [spDIAL_Reauthorize_02_11_2017] 3712316

ALTER Proc [dbo].[spDIAL_Reauthorize] @Entry_ID bigint --@iAgreementNo bigint
as

SET NOCOUNT ON

select 
ok_to_bill,
DAC_RESERVATION_NO as [Reservation No.]
,DAC_ENTRY_ID AS Reference  --Also for second Information page
, DAC_AGREEMENT_NUMBER [Agreement No]
, case 
when DAC_AGREEMENT_NUMBER = 0 and dauth.DCA_AUTHOR_TO_DATE != '00000000'
then  datediff(d, dauth.dca_a_days, convert(datetime,convert(varchar(8),dauth.DCA_AUTHOR_TO_DATE,112))) 
when R.PARENT_EXTEND_AGREEMENT_NO > 0 and a.DAC_ARS_WEB != 'Y'  
then  DATEADD(SECOND, RW.Agreement_Open_Time, convert(datetime,convert(varchar(8),RW.Agreement_Open_Date,112)))
when  a.DAC_ARS_WEB != 'Y'  
then  DATEADD(SECOND, R.CHECK_OUT_time, convert(datetime,convert(varchar(8),R.CHECK_OUT_DATE,112)))
when DAC_AGR_OPEN_DATE > '00000000' 
then  DATEADD(SECOND,DAC_AGR_OPEN_TIME, convert(datetime,convert(varchar(8),A.DAC_AGR_OPEN_DATE,112)) )
else null
end as [Contract Open Date]
, case 
when R.PARENT_EXTEND_AGREEMENT_NO > 0 and a.DAC_ARS_WEB != 'Y' and r.STATUS_CODE = 4 
then  DATEADD(SECOND, R.CHECK_in_time, convert(datetime,convert(varchar(8),R.CHECK_IN_DATE,112)))--DATEADD(SECOND, RW.Agreement_Close_Time, convert(datetime,convert(varchar(8),RW.Agreement_Close_Date,112)))
when  a.DAC_ARS_WEB != 'Y'  and (r.STATUS_CODE = 4 OR r.STATUS_CODE = 0)
then  DATEADD(SECOND, R.CHECK_in_time, convert(datetime,convert(varchar(8),R.CHECK_IN_DATE,112)))
when a.DAC_ARS_WEB = 'Y' and DAC_AGR_CLOSE_DATE > '00000000' 
then  DATEADD(SECOND,DAC_AGR_CLOSE_TIME, convert(datetime,convert(varchar(8),A.DAC_AGR_CLOSE_DATE,112)) )
else null 
end as [Contract Close Date]
,[DAC_INSURED_FIRST_NAME] [Insured First Name]
,[DAC_INSURED_NAME] [Insured Last Name]
,DAC_CLIENT_LAST_NAME [Driver Last Name]
,DAC_CLIENT_FIRST_NAME [Driver First Name]
,DAC_POLICY [Policy No]
,DAC_INS_CLAIM [Claim No]
,DAC_INS_COMPANY_ID [Insurance Company ID]
, b.DEBITOR_NAME  [Insurance Company Name]
, DAC_COMPANY_ADJUSTER_ID
, c.DAA_FULL_NAME , 
DAC_RENTAL_CAR_CLASS [RENTAL CAR CLASS], 
ltrim(rtrim(EQUIVALENT_CLASS)) as [INSURED CAR CLASS]
, case when isnull(ltrim(rtrim(dauth.DCA_AUTH_VEHICLE)), '') != '' then ltrim(rtrim(dauth.DCA_AUTH_VEHICLE)) else ltrim(rtrim(EQUIVALENT_CLASS)) end as [Auth Class]
,a.[DAC_YEAR] [Insured Vehicle Year]  --in Authorization Info. Section
,a.DAC_MAKE [Insured Vehicle Make]
,DAC_MODEL [Insured Vehicle Model]
,a.DAC_RENTAL_MAKE [Renter Vehicle Make]  
,a.DAC_RENTAL_MODEL [Renter Vehicle Model]
,DAC_RENTAL_YEAR [Renter Vehicle Year]
,dbo.converttodate(dauth.DCA_AUTHOR_TO_DATE ) as [Last Auth Upto Date]
, dbo.fn_ShowTimeStamp_fromSecSinceMidnight(dauth.DAC_AUTHOR_TO_TIME) as [Last Auth UpTo Time]
,dauth.DCA_AUTHOR_RATE as AuthRate
,isnull(AuthExtra.Auth_Extra_PerDay,0.0) as Auth_Extra_PerDay
,isnull(AuthIns.Auth_Ins_PerDay,0.0) as Auth_Ins_PerDay
, dauth.dca_a_days as [Total Auth Days]
--,case when OK_TO_BILL = 1 then dauth.dca_a_days 
--else '' end as [Total Auth Days]
--, dauth.DAC_FINAL_TOTAL [Final Auth Total]
--,round(convert(decimal(18,2),dauth.DCA_Rental_TOTAL + (dauth.DCA_Rental_TOTAL *  ((SERVICE_FEE + NATIONAL_VAT)*.01))), 2) [Final Auth Total]
,round(convert(decimal(18,2),dauth.DCA_Rental_TOTAL), 2) [Final Auth Total]
--,Case 
--when DAC_AGR_OPEN_DATE > '00000000' then 
-- round(convert(decimal(18,2), dauth.DCA_AUTHOR_RATE*DATEDIFF(DAY, convert(datetime,convert(varchar(8),DAC_AGR_OPEN_DATE,112)) ,GETDATE()+1) + (dauth.DCA_AUTHOR_RATE*DATEDIFF(DAY, convert(datetime,convert(varchar(8),DAC_AGR_OPEN_DATE,112)) ,GETDATE()+1)*((dc.SERVICE_FEE + NATIONAL_VAT)*.01))), 2)
--else null end as [Total Rental Amount as of Today] ,

, CASE 
			when r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=0 OR R.STATUS_CODE=4)  --previous closed and preclosed amount plus current open to date amount including extra, insurance and tax
			THEN                              
				isnull(rw.Rental_Amount,0.0) 
			when r.PARENT_EXTEND_AGREEMENT_NO>0 and ( R.STATUS_CODE=1 OR R.STATUS_CODE=2)  --previous closed and preclosed amount plus current open to date amount including extra, insurance and tax
			THEN                              
				isnull(rw.Rental_Amount,0.0) +  (Carpro_App.dbo.fn_Min_Values(rw.Rate,dauth.DCA_AUTHOR_RATE) +  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0))*Carpro_App.dbo.fn_Cal_hourly_RentalDays(b.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.[Agreement_Current_Open_TIME],CONVERT(DATETIME,CONVERT(VARCHAR,rw.[Agreement_Current_Open_Date],112))), GETDATE()) * case when myAuth.DAC_TAXES_PAID_BY != 2 then (1.0 +ISNULL(dauth.VAT_PER,0.0)/100.0) else 1 end  
			WHEN a.DAC_ARS_WEB!='Y' AND  R.STATUS_CODE=4
			THEN V.INVOICE_AMOUNT
			WHEN a.DAC_ARS_WEB!='Y' AND  R.STATUS_CODE=0
			THEN ROUND((ISNULL(dauth.DCA_AUTHOR_RATE,0)+  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0)) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(b.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))) * case when myAuth.DAC_TAXES_PAID_BY != 2 then (1.0 +ISNULL(dauth.VAT_PER,0.0)/100.0) else 1 end ,2)
			--THEN R.Debitor_Total
			WHEN a.DAC_ARS_WEB ='Y' AND  a.DAC_STATUS=4
			THEN	EB.TOTAL
			WHEN A.DAC_ARS_WEB ='Y' AND  a.DAC_STATUS=3 AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000' AND (ISNULL(DAUTH.DCA_AUTHOR_RATE,0)=0 OR ISNULL(DAUTH.dca_a_days,0)=0)  --EXPIRED
			THEN	
				ROUND((ISNULL(case when Carpro_App.dbo.fn_min_Values(A.DAC_RENTAL_RATE_OUT, A.DAC_RATE_OUT) > 0 then Carpro_App.dbo.fn_min_Values(A.DAC_RENTAL_RATE_OUT, A.DAC_RATE_OUT) else Carpro_App.dbo.fn_Max_Values(A.DAC_RENTAL_RATE_OUT, A.DAC_RATE_OUT) end,0)+  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0)) * Carpro_App.dbo.fn_Cal_hourly_RentalDays(b.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))) * case when myAuth.DAC_TAXES_PAID_BY != 2 then (1.0 +ISNULL(dauth.VAT_PER,0.0)/100.0) else 1 end,2)
				
			WHEN a.DAC_ARS_WEB ='Y' AND  a.DAC_STATUS=3 AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND (ISNULL(DAUTH.DCA_AUTHOR_RATE,0)=0 OR ISNULL(DAUTH.dca_a_days,0)=0)  --EXPIRED
			THEN	
				ROUND((ISNULL(case when Carpro_App.dbo.fn_min_Values(A.DAC_RENTAL_RATE_OUT, a.DAC_RATE_OUT) > 0 then Carpro_App.dbo.fn_min_Values(A.DAC_RENTAL_RATE_OUT, a.DAC_RATE_OUT) else Carpro_App.dbo.fn_Max_Values(A.DAC_RENTAL_RATE_OUT, a.DAC_RATE_OUT) end,0)+  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0)) * Carpro_App.dbo.fn_Cal_hourly_RentalDays(b.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), Getdate()) * case when myAuth.DAC_TAXES_PAID_BY != 2 then (1.0 +ISNULL(dauth.VAT_PER,0.0)/100.0) else 1 end,2)							
			WHEN a.DAC_ARS_WEB ='Y' AND  a.DAC_STATUS=3 AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000' --EXPIRED
			THEN	
				ROUND((ISNULL(dauth.DCA_AUTHOR_RATE,0)+  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0)) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(b.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))) * case when myAuth.DAC_TAXES_PAID_BY != 2 then (1.0 +ISNULL(dauth.VAT_PER,0.0)/100.0) else 1 end ,2)
			--Corp  
			WHEN a.DAC_ARS_WEB !='Y' AND  a.DAC_STATUS in (2,3) AND R.STATUS_CODE IN (1, 2)   --EXPIRED
			THEN
				--ROUND( R.Debitor_Total,2)                            
				ROUND((ISNULL(case when Carpro_App.dbo.fn_min_Values(A.DAC_RENTAL_RATE_OUT, dauth.DCA_AUTHOR_RATE) > 0 then Carpro_App.dbo.fn_min_Values(A.DAC_RENTAL_RATE_OUT, dauth.DCA_AUTHOR_RATE) else Carpro_App.dbo.fn_Max_Values(A.DAC_RENTAL_RATE_OUT, dauth.DCA_AUTHOR_RATE) end, 0) +  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0)) * Carpro_App.dbo.fn_Cal_hourly_RentalDays(b.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), Getdate()) * case when myAuth.DAC_TAXES_PAID_BY != 2 then (1.0 +ISNULL(dauth.VAT_PER,0.0)/100.0) else 1 end ,2)                          
			WHEN  a.DAC_STATUS <= 3 AND LEFT(DAC_AGR_OPEN_DATE,4) > '2000'  --OPEN CONTRACT
			THEN ROUND((ISNULL(dauth.DCA_AUTHOR_RATE,0)+  isnull(AuthExtra.Auth_Extra_PerDay,0.0) + isnull(AuthIns.Auth_Ins_PerDay,0.0)) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(b.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE())) * case when myAuth.DAC_TAXES_PAID_BY != 2 then (1.0 +ISNULL(dauth.VAT_PER,0.0)/100.0) else 1 end,2)
			ELSE NULL      
            end AS  [Total Rental Amount as of Today],
            
Case 
when R.PARENT_EXTEND_AGREEMENT_NO > 0 and a.DAC_ARS_WEB != 'Y' and R.status_code in (0, 4) then 
ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(b.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.Agreement_Open_Time,CONVERT(DATETIME,CONVERT(VARCHAR,rw.Agreement_Open_Date,112))), DATEADD(SECOND,R.CHECK_IN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,r.CHECK_IN_DATE,112)))), 0)
when R.PARENT_EXTEND_AGREEMENT_NO > 0 and a.DAC_ARS_WEB != 'Y' and R.status_code in (1, 2) then 
ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(b.DAYS_CALC_LOGIC, DATEADD(SECOND,rw.Agreement_Open_Time,CONVERT(DATETIME,CONVERT(VARCHAR,rw.Agreement_Open_Date,112))), GETDATE()), 0)
when a.DAC_ARS_WEB != 'Y' and R.status_code in (0, 4) then 
ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(b.DAYS_CALC_LOGIC, DATEADD(SECOND,r.CHECK_OUT_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,r.CHECK_OUT_DATE,112))), DATEADD(SECOND,R.CHECK_IN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,r.CHECK_IN_DATE,112)))), 0)
when a.DAC_ARS_WEB != 'Y' and R.status_code in (1, 2) then 
ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(b.DAYS_CALC_LOGIC, DATEADD(SECOND,r.CHECK_OUT_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,r.CHECK_OUT_DATE,112))), GETDATE()), 0)
when a.DAC_ARS_WEB = 'Y' and  left(DAC_AGR_OPEN_DATE,4) >'2000' and left(DAC_AGR_CLOSE_DATE,4)>'2000' then 
ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(b.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))), 0)
when DAC_AGR_OPEN_DATE > '00000000' then  ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(b.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()), 0)
else null 
end as [Rental Days (To Date)]   
,dauth.[FINAL_AUTH] [Final Authorization: no other follow-up needed from Discount]
--Total Amount include taxes extras insurance
,round(convert(decimal(18,2), dauth.DAC_FINAL_TOTAL), 2)  [Total Amount] 
--,dauth.DCA_AUTHOR_RATE [Authorized Rate]
, [DAC_COLLISION_COVERAGE] [Transferable Coverage]
, DAC_LOSS_OF_USE [Loss Of Use]--in forth section
, [DAC_AT_FAULT] [At Fault] 
,[DAC_THIRD_PARTY] [Third Party]
, DAC_DRIVABLE [Drivable]
, [DAC_PAID_BY] [Transferable Coverage Paid By]
,myAuth.DAC_TAXES_PAID_BY [Taxes Paid By]
--,DAC_TAX_PAID_BY [Taxes Paid By]
, [DAC_TOTAL_LOSS] [Total Loss], --in fifth section
--, Case when DAC_Claim_Type = 0 then 'Collision'
--		when DAC_Claim_Type = 1 then 'Comprehensive'
--		when DAC_Claim_Type = 2 then 'Theft'
--		end as 
--[Claim Type]
DAC_Claim_Type as [Claim Type]
,[DRP_ASSIGNED_RENTAL] [DRP Assigned Rental]
,LTRIM(RTRIM(DAC_GARAGE_NAME)) + ', ' + LTRIM(RTRIM(DAC_GARAGE_ADDRESS)) + ', ' + LTRIM(RTRIM(DAC_GARAGE_POSTAL_CODE)) + ', ' +  LTRIM(RTRIM(DAC_GARAGE_PHONE)) as [Garage Information]
,LTRIM(RTRIM(DAC_GARAGE_ID)) [Garage ID]
, DAC_MAX_ALLOW [Policy Max]
, [DAC_TOTAL_LOSS] [Total Loss],
case when DAC_DATE_OF_LOSS > '00000000' then DBO.CONVERTTODATE(DAC_DATE_OF_LOSS) else null end [Date_of_Loss]
, ISNULL(lr.Estimated_Repair_Hours,0) as Estimated_Repair_Hours
, ISNULL(lr.Estimated_Amount,0) as Estimated_Repair_Amount
, ISNULL(lr.Estimated_Repair_Days,0) as Estimated_Repair_Days
, DAC_LOCATION_CODE as [Discount_Location_Code]
--, br.BRANACH_NAME + ' ' + br.STREET + ', ' +  br.city  + ', ' + br.POSTAL_NO + ' Phone No - ' + br.TELEPHONE1 as [Discount_Location_Name]
, br.STREET + ', ' +  br.city  + ', ' + br.POSTAL_NO +'.  ' + br.TELEPHONE1 as [Discount_Location_Name]
--Information Page
--,* 
, (DAC_CLIENT_FIRST_NAME + ' ' + DAC_CLIENT_LAST_NAME) as [RenterName]
, DAC_CLIENT_ADDRESS as [RenterAddress]
,DAC_CLIENT_CITY  as [RenterCity]
,DAC_CLIENT_PHONE as [RenterPhone], DAC_CLIENT_EMAIL as [RenterEmail], 
DAC_CUST_ALT_PHONE as [RenterAlternate], s.text  as [Status],
case 
when VAT_BY_BRANCHES_YN = 'N' then 
	dc.SERVICE_FEE 
else
	br.service_fee
end as [PST],
case 
when VAT_BY_BRANCHES_YN = 'N' then 
	dc.INTERNATIONAL_VAT
else
	br.VAT_PERCENT
end as [GST/HST]
--,dc.SERVICE_FEE as PST, NATIONAL_VAT as [GST/HST]
, 
case 
WHEN a.DAC_ARS_WEB!='Y' AND r.STATUS_CODE = 0 then 1
--when a.DAC_ARS_WEB = 'Y' and a.DAC_STATUS = 4 then 1
else 0 end as Agreement_Status, isnull(BR.PROVINCE_CODE, 0) AS PROVINCECODE
from DA_CLAIMS a(nolock)
LEFT OUTER JOIN Vw_Dial_Inv V(NOLOCK) ON V.AGREEMENT_NO = A.DAC_AGREEMENT_NUMBER AND V.INVOICE_TYPE = 'C' AND V.INV_STATUS != 9 AND A.DAC_INS_COMPANY_ID = v.DEBITOR_NO
LEFT OUTER JOIN EBILLING_INVOICE_DATA EB(NOLOCK) on EB.Entry_ID = A.DAC_ENTRY_ID
left join BRANCHES br(nolock) on a.DAC_LOCATION_CODE = br.BRANACH_CODE
left join DEBITORS b(nolock) on a.DAC_INS_COMPANY_ID = b.DEBITOR_CODE
left join DA_ADJUSTER c(nolock) ON a.DAC_COMPANY_ADJUSTER_ID = c.DAA_ENTRY_ID
left join GARAGES g (nolock) on g.GARAGE_NO= DAC_GARAGE_ID
left join carpro_app..tblDial_RewriteWarehouse rw (nolock) on rw.Current_Agreement_No = a.DAC_AGREEMENT_NUMBER
left join RemedeyAgr_Rewrite R (nolock) on R.AGREEMENT_NO = a.DAC_AGREEMENT_NUMBER
left join 
(
		SELECT da.DCA_CLAIM_ID,ISNULL(AVG(VAT_PER),0)VAT_PER,
		ISNULL(SUM(dca_a_days),0) dca_a_days,ISNULL(max(DCA_AUTHOR_RATE),0) DCA_AUTHOR_RATE,
		MAX(DA.DCA_AUTHOR_TO_DATE) DCA_AUTHOR_TO_DATE,
		MAX(DCA_AUTH_VEHICLE)  DCA_AUTH_VEHICLE,
		MAX(DCA_MODIFIED_DATE)  DCA_MODIFIED_DATE,
		MAX(DAC_AUTHOR_TO_TIME)  DAC_AUTHOR_TO_TIME,
		MAX(FINAL_AUTH)  [FINAL_AUTH],
		--just rental total before tax and extras
		sum(DCA_TOTAL_RENTAL)  DCA_Rental_TOTAL,
		--includes extras, total rental, insurance and also taxes
		sum(DAC_FINAL_TOTAL)  DAC_FINAL_TOTAL,
		--min(DAC_TAXES_PAID_BY) Auth_DAC_TAXES_PAID_BY
		max(DCA_ENTRY_ID) as MaxAuthID 
		from DA_AUTHORIZATION da(NOLOCK) 
        where DCA_BILL_TO=1  and (left(DCA_AUTHOR_TO_DATE, 4) > '2000' or DCA_AUTHOR_TO_DATE = '00000000')
        GROUP BY da.DCA_CLAIM_ID)
	AS dauth ON a.DAC_ENTRY_ID = dauth.DCA_CLAIM_ID
	 Left join (select DAE_AUTH_ENTRY_ID, sum(DAE_PRICE) Auth_Extra_PerDay from [dbo].[DA_AUTHORIZATION_extraS](nolock)
							group by DAE_AUTH_ENTRY_ID	
                  ) AuthExtra on AuthExtra.DAE_AUTH_ENTRY_ID = dauth.MaxAuthID
                  Left join (select DAE_AUTH_ENTRY_ID, sum(DAE_PRICE) Auth_Ins_PerDay from [dbo].DA_AUTHORIZATION_INSURANCES(nolock)
							group by DAE_AUTH_ENTRY_ID	
                  ) AuthIns on AuthIns.DAE_AUTH_ENTRY_ID = dauth.MaxAuthID   
 left join [VEHICLE_CLASSES] f (nolock) on a.[CATEGORY_VEHICLE] = f.CLASS 
 left join vwDIAL_ClaimStatus s on DAC_STATUS = value  
 LEFT JOIN EXTERNAL_MAKE_MODEL (nolock)  ON ltrim(rtrim(make)) = DAC_MAKE and ltrim(rtrim(model)) = DAC_MODEL
 left join DEFAULT_CONTROL dc on dc.COMPANY_NO = DAC_COMPANY_CODE
 left join DA_AUTHORIZATION myAuth(nolock) on dauth.DCA_CLAIM_ID = myAuth.DCA_CLAIM_ID and dauth.MaxAuthID = myAuth.DCA_ENTRY_ID
 Left Join Carpro_App..tblDial_Labor_Hours lr (nolock) on a.DAC_ENTRY_ID = lr.ClaimEntryID
where DAC_ENTRY_ID = @Entry_ID