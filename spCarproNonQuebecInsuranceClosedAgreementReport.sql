USE [Carpro_App]
GO
/****** Object:  StoredProcedure [dbo].[spCarproNonQuebecInsuranceClosedAgreementReport]    Script Date: 04/05/2018 09:43:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
? For close agreement, Invoice Year
Invoice Month
Invoice Date
*/

-- grant exec on [spCarproNonQuebecInsuranceClosedAgreementReport] to crystal

-- exec spCarproNonQuebecInsuranceClosedAgreementReport @FromDate = '20170401', @ToDate = '20170430',@DebitorCodes='21594'


ALTER Proc [dbo].[spCarproNonQuebecInsuranceClosedAgreementReport] 
@FromDate varchar(8)='2010501', 
@ToDate varchar(8) ='20150531',
@DebitorCodes varchar(MAX) = 'ALL'
as
BEGIN
	DECLARE
	@BEGIN datetime, --'10/01/2011'
	@END  datetime--'12/01/2011'
	
	SET   @BEGIN = CONVERT(VARCHAR, CONVERT(DATETIME, @FromDate), 101)
	SET   @END = CONVERT(VARCHAR, CONVERT(DATETIME, @ToDate), 101)
	SET   @END = DATEADD(SECOND, 24*60*60-1, @END)
	
	Select SUV_DEBITOR_OF, DEBITOR_NAME into #temp_debitors from OntarioLive..DEBITORS where DEBITOR_CODE in 
	(select distinct SUV_DEBITOR_OF from 
	 (
	 select distinct (SUV_DEBITOR_OF) from ONTARIOLIVE..DEBITORS a(nolock)
	 INNER JOIN ONTARIOLIVE..DEBITORS_SECTION2 b (nolock) on a.DEBITOR_CODE = b.DEBITOR_CODE 
	 where SUV_DEBITOR_OF > 0 and b.IN_STOP_LIST='A' and DEBITOR_TYPE='O'
	 ) 
	 t1)
	 Order by DEBITOR_NAME
   		      
    SELECT DISTINCT 'From_Remedy' Source,
    case  when C.DAC_ARS_WEB ='N' then DS.PROVINCE when C.DAC_ARS_WEB = 'Y' then B.State else DS.PROVINCE end PROVINCE,
    Case when C.DAC_Claim_Type = 0 then 'Collision'	when C.DAC_Claim_Type = 1 then 'Comprehensive' when C.DAC_Claim_Type = 2 then 'Theft' end ClaimType,
    case when CHARINDEX('Stolen' ,DAC_GARAGE_NAME)> 0 OR CHARINDEX('Theft',DAC_GARAGE_NAME)> 0 Or CHARINDEX('Loss',DAC_GARAGE_NAME)> 0 Or CHARINDEX('Write',DAC_GARAGE_NAME)> 0  then DAC_GARAGE_NAME when DAC_TOTAL_LOSS ='Y' then  'OTAL_LOSS' when  DAC_Claim_Type =2 then 'Theft' else '' END ExtentOfLoss,
	case when a1.GARAGE_NAME IS Not null then a1.GARAGE_NAME when a2.GARAGE_NAME IS Not null then a2.GARAGE_NAME when a3.GARAGE_NAME IS Not null then a3.GARAGE_NAME when a4.GARAGE_NAME IS Not null then a4.GARAGE_NAME when a5.GARAGE_NAME IS Not null then a5.GARAGE_NAME when a6.GARAGE_NAME IS Not null then a6.GARAGE_NAME when a7.GARAGE_NAME IS Not null then a7.GARAGE_NAME when a8.GARAGE_NAME IS Not null then a8.GARAGE_NAME end as Garage_Name,
	(Select top 1 Debitor_Name from #temp_debitors where #temp_debitors.SUV_DEBITOR_OF = d.SUV_DEBITOR_OF) as ParentInsurerName,
	D.DEBITOR_NAME AS [INS COMPANY NAME],
	case when cast(AG.PARENT_EXTEND_AGREEMENT_NO as bigint) > 0 then 'Y' else 'N' end as IsRewrite,
	cast(cast(ISNULL( AG.AGREEMENT_NO, C.DAC_AGREEMENT_NUMBER) as bigint) as varchar(15))  as AgreementNo, 	
	cast(cast( AG.PARENT_EXTEND_AGREEMENT_NO as bigint) as varchar(15))  as ParentAgreementNo, 	
	case when i.INVOICE_DATE between '20100101' and '20491231' then  convert(varchar(10),CONVERT(datetime, i.INVOICE_DATE,112),120) when DAC_INVOICE_DATE between '20100101' and '20491231' then  convert(varchar(10),CONVERT(datetime, C.DAC_INVOICE_DATE,112),120) end InvoiceDate,
	i.INVOICE_NO InvoiceNo,
    C.DAC_INS_CLAIM as CLAIM_NO,
    C.DAC_POLICY as POLICY_NO,
    C.DAC_CLIENT_FIRST_NAME + ' ' + C.DAC_CLIENT_LAST_NAME as Renter_Name,
    case  when C.DAC_ARS_WEB ='N' and AG.SOLD_DAYS != 0 then cast(round(i.RENTAL/AG.SOLD_DAYS,2) as numeric(36,2)) when c.DAC_ARS_WEB ='Y' and (DAC_AGR_OPEN_DATE between '20100101' and '20491231') and  (DAC_AGR_CLOSE_DATE between '20100101' and '20491231') and Carpro_App.dbo.fn_Cal_hourly_RentalDays(d.DAYS_CALC_LOGIC, DATEADD(SECOND,c.DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR, C.DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,C.DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,C.DAC_AGR_CLOSE_DATE,112)))) != 0 then cast(round(h.RATE_CHARGED/Carpro_App.dbo.fn_Cal_hourly_RentalDays(d.DAYS_CALC_LOGIC, DATEADD(SECOND,c.DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR, C.DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,C.DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,C.DAC_AGR_CLOSE_DATE,112)))),2) as numeric(36,2)) else case when C.DAC_AGREEMENT_NUMBER > 0 then cast(round(i.RENTAL/AG.SOLD_DAYS,2) as numeric(36,2)) end  end  AvgRate,
    case  when C.DAC_ARS_WEB ='N' then AG.SOLD_DAYS when C.DAC_ARS_WEB ='Y' and DAC_AGR_OPEN_DATE between '20100101' and '20491231' and  DAC_AGR_CLOSE_DATE between '20100101' and '20491231' then Carpro_App.dbo.fn_Cal_hourly_RentalDays(d.DAYS_CALC_LOGIC, DATEADD(SECOND,C.DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,C.DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,C.DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,C.DAC_AGR_CLOSE_DATE,112)))) else AG.SOLD_DAYS end  Rental_Days, 
    case  when C.DAC_ARS_WEB ='N' then i.RENTAL when C.DAC_ARS_WEB = 'Y' then h.RATE_CHARGED else i.RENTAL end Rental_Sum,
    case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.TFFS,0) else ISNULL(VLI.AMOUNT,0) end AS VehicleLicenseFee,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(o.OTHER_CHARGES,0)  else ISNULL(WT.AMOUNT,0) end AS  WinterTireFee,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.KILOMETERS,0) else ISNULL(i.KM,0) end AS  KilometerCharges,
	ISNULL(i.DROF_OFF,0) AS DropFees,
	ISNULL(CDW.AMOUNT,0) AS CollisionDamageWaiver,
	ISNULL(PAP.AMOUNT,0) AS PracticleAssistanceProgram,
	case  when C.DAC_ARS_WEB ='Y' then h.SUB_TOTAL else i.SUBTOTAL end AS SubTotal,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.PST,0) else ISNULL(i.SERVICE_FEE,0) end ProvincialTaxes,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.GST+ h.HST,0) else ISNULL(i.VAT,0) end FederalTaxes,
	case when C.DAC_ARS_WEB ='Y' then h.TOTAL else i.INVOICE_AMOUNT end TotalFees,
	i.AMOUNT_PID as Paid_Amount,
	i.BALANCE as Balance,
	case when DAC_DATE_OF_LOSS between '20100101' and '20491231' then convert(varchar(10),CONVERT(datetime, C.DAC_DATE_OF_LOSS,112),120) end DateOfLoss,
	case when DAC_AGR_CLOSE_DATE between '20100101' and '20491231'  then (SELECT DATENAME(DW, CAST(C.DAC_AGR_CLOSE_DATE AS datetime))) end Day_of_Week,
	case when DAC_AGR_CLOSE_DATE between '20100101' and '20491231'  then (SELECT DATENAME(month, CAST(C.DAC_AGR_CLOSE_DATE AS datetime))) end Month,
	case when adj.DAA_FULL_NAME IS NULL then 'UNKNOWN' else adj.DAA_FULL_NAME end AdjusterName,
	ISNULL(AUTHDAY, 0) AS [TOTAL AUTHOR DAYS], 
	ISNULL(A.AUTHORRATE, 0) As AuthRate,
	Case when C.DAC_AGR_OPEN_DATE = AG.CHECK_OUT_DATE then DATEADD(SECOND, C.DAC_AGR_OPEN_TIME, CONVERT(datetime,CONVERT(VARCHAR,C.DAC_AGR_OPEN_DATE,112))) else DATEADD(SECOND, AG.CHECK_OUT_TIME, CONVERT(datetime,CONVERT(VARCHAR, AG.CHECK_OUT_DATE,112))) end as Rental_Out,
	Case when C.DAC_AGR_CLOSE_DATE = AG.CHECK_IN_DATE then DATEADD(SECOND, C.DAC_AGR_CLOSE_TIME, CONVERT(datetime,CONVERT(VARCHAR,C.DAC_AGR_CLOSE_DATE,112))) else DATEADD(SECOND, AG.CHECK_IN_TIME, CONVERT(datetime,CONVERT(VARCHAR, AG.CHECK_IN_DATE,112))) end as Rental_In,
	--DATEADD(SECOND, C.DAC_AGR_OPEN_TIME, CONVERT(datetime,CONVERT(VARCHAR,C.DAC_AGR_OPEN_DATE,112))) as Rental_Out,
	--DATEADD(SECOND, C.DAC_AGR_CLOSE_TIME, CONVERT(datetime,CONVERT(VARCHAR,C.DAC_AGR_CLOSE_DATE,112))) as Rental_In,
	DAC_DRIVABLE AS DRIVABLE, 
	C.DAC_MAKE as ICC_Make, 
	C.DAC_MODEL as ICC_Model, 
	C.DAC_YEAR as ICC_Vehicle_Year,
	C.DAC_RENTAL_MAKE as CarManufacturer,
    C.DAC_RENTAL_MODEL as CarModel,
    C.DAC_RENTAL_YEAR as VehicleYear,
    ISNULL(ISNULL(C.DAC_RENTAL_CAR_GROUP, C.VEHICLE_CLASS), C.VEHICLE_CLASS) as ICC_Category,
    C.DAC_RENTAL_CAR_CLASS as Category,
    SAG.Unit_No as CarCategory,
    case when C.DAC_RENTAL_CHECK_OUT_BRANCH_CODE > 0 then C.DAC_RENTAL_CHECK_OUT_BRANCH_CODE else DAC_LOCATION_CODE end BranchCode,
    B.BRANACH_NAME as BranchName,
    B.CITY as BranchCity,
    B.STATE as BranchState,
    case when vb1.BannerName IS Not null then vb1.BannerName when vb2.BannerName IS Not null then vb2.BannerName when vb3.BannerName IS Not null then vb3.BannerName when vb4.BannerName IS Not null then vb4.BannerName when vb5.BannerName IS Not null then vb5.BannerName when vb6.BannerName IS Not null then vb6.BannerName when vb7.BannerName IS Not null then vb7.BannerName when vb8.BannerName IS Not null then vb8.BannerName end as BannerName,
    Case when YN1.PREFERRED_YN IS Not Null and YN1.PREFERRED_YN = 1 then 'YES' when YN2.PREFERRED_YN IS Not Null and YN2.PREFERRED_YN = 1 then 'YES' when YN3.PREFERRED_YN IS Not Null and YN3.PREFERRED_YN = 1 then 'YES' when YN4.PREFERRED_YN IS Not Null and YN4.PREFERRED_YN = 1 then 'YES' when YN5.PREFERRED_YN IS Not Null and YN5.PREFERRED_YN = 1 then 'YES' when YN6.PREFERRED_YN IS Not Null and YN6.PREFERRED_YN = 1 then 'YES' when YN7.PREFERRED_YN IS Not Null and YN7.PREFERRED_YN = 1 then 'YES' when YN8.PREFERRED_YN IS Not Null and YN8.PREFERRED_YN = 1 then 'YES' else 'NO' end Preferred_Garages,
	BRANACH_NAME AS [LOCATION NAME], B.STREET [LOCATION ADDRESS], 
	DAC_GARAGE_ADDRESS AS [GARAGE ADDRESS]
	into #tempDataRemedy
	FROM [ONTARIOLIVE].DBO.DA_CLAIMS C (NOLOCK) 	
	left join OntarioLive..EBILLING_INVOICE_DATA H(nolock) on C.DAC_ENTRY_ID = H.ENTRY_ID
	LEFT JOIN ONTARIOLIVE.DBO.BRANCHES  B (NOLOCK) ON C.DAC_LOCATION_CODE = B.BRANACH_CODE 
	LEFT JOIN ONTARIOLIVE.DBO.DEBITORS  D (NOLOCK) ON C.DAC_INS_COMPANY_ID = D.DEBITOR_CODE 
	LEFT JOIN ONTARIOLIVE.DBO.DATABASE_SETUP S (NOLOCK) ON C.DAC_COMPANY_CODE = S.DATABASE_ID
	LEFT JOIN DBO.VW_DataBase_SetUp DS (NOLOCK) ON DS.DATABASE_NAME = S.DATABASE_NAME 
	Left join OntarioLive..DA_ADJUSTER adj (NOLOCK) on C.DAC_COMPANY_ADJUSTER_ID = adj.DAA_ENTRY_ID
	
	LEFT JOIN OntarioLive..GARAGES a1(nolock) on a1.GARAGE_NO =C.DAC_GARAGE_ID  and b.STATE IN ('Ontario','ON') and RTRIM(a1.GARAGE_NAME) = RTRIM(C.DAC_GARAGE_NAME)
	left join Carpro_App..GARAGES_PREFERRED_YN YN1
	on d.SUV_DEBITOR_OF = YN1.DEBITOR_CODE and a1.GARAGE_NO = YN1.GARAGE_CODE 
	and YN1.Province = case when B.STATE IN ('Ontario','ON') then 'ON' end
	Left Join Carpro_App..vwBanner vb1(nolock)
	on a1.GARAGES_ACCOUNT_GROUP = vb1.BannerCode

	LEFT JOIN AlbertaLive..GARAGES a2(nolock) on a2.GARAGE_NO =C.DAC_GARAGE_ID  and  b.STATE IN ('Alberta','AB')  and RTRIM(a2.GARAGE_NAME) = RTRIM(C.DAC_GARAGE_NAME)
	left join Carpro_App..GARAGES_PREFERRED_YN YN2
	on d.SUV_DEBITOR_OF = YN2.DEBITOR_CODE and a2.GARAGE_NO = YN2.GARAGE_CODE 
	and YN2.Province = case when B.STATE IN ('Alberta','AB') then 'AB' end
	Left Join Carpro_App..vwBanner vb2(nolock)
	on a2.GARAGES_ACCOUNT_GROUP = vb2.BannerCode


	LEFT JOIN NewfoundlandLive..GARAGES a3(nolock) on a3.GARAGE_NO =C.DAC_GARAGE_ID  and  b.STATE IN ('NF','Newfoundland')  and RTRIM(a3.GARAGE_NAME) = RTRIM(C.DAC_GARAGE_NAME)
	left join Carpro_App..GARAGES_PREFERRED_YN YN3
	on d.SUV_DEBITOR_OF = YN2.DEBITOR_CODE and a3.GARAGE_NO = YN3.GARAGE_CODE 
	and YN3.Province = case when B.STATE IN ('NF','Newfoundland') then 'NL' end
	Left Join Carpro_App..vwBanner vb3(nolock)
	on a3.GARAGES_ACCOUNT_GROUP = vb3.BannerCode


	LEFT JOIN SaskatchewanLive..GARAGES a4(nolock) on a4.GARAGE_NO =C.DAC_GARAGE_ID  and  b.STATE IN ('Saskatchewan','Sask')  and RTRIM(a4.GARAGE_NAME) = RTRIM(C.DAC_GARAGE_NAME)
	left join Carpro_App..GARAGES_PREFERRED_YN YN4
	on d.SUV_DEBITOR_OF = YN4.DEBITOR_CODE and a1.GARAGE_NO = YN4.GARAGE_CODE 
	and YN4.Province = case when B.STATE IN ('Saskatchewan','Sask') then 'SK' end
	Left Join Carpro_App..vwBanner vb4(nolock)
	on a4.GARAGES_ACCOUNT_GROUP = vb4.BannerCode

	LEFT JOIN MaritimesLive..GARAGES a5(nolock) on a5.GARAGE_NO =C.DAC_GARAGE_ID  and  b.STATE IN ('NS','NOVA SCOTIA','New Brunswick','NB', 'Prince Edward I')  and RTRIM(a5.GARAGE_NAME) = RTRIM(C.DAC_GARAGE_NAME)
	left join Carpro_App..GARAGES_PREFERRED_YN YN5
	on d.SUV_DEBITOR_OF = YN5.DEBITOR_CODE and a1.GARAGE_NO = YN5.GARAGE_CODE 
	and YN5.Province = case when B.STATE IN ('NS','NOVA SCOTIA','New Brunswick','NB', 'Prince Edward I') then 'MT' end
	Left Join Carpro_App..vwBanner vb5(nolock)
	on a5.GARAGES_ACCOUNT_GROUP = vb5.BannerCode

	LEFT JOIN BCLive..GARAGES a6(nolock) on a6.GARAGE_NO =C.DAC_GARAGE_ID  and  b.STATE IN ('BRITISH COLUMBIA','BC')  and RTRIM(a6.GARAGE_NAME) = RTRIM(C.DAC_GARAGE_NAME)
	left join Carpro_App..GARAGES_PREFERRED_YN YN6
	on d.SUV_DEBITOR_OF = YN6.DEBITOR_CODE and a1.GARAGE_NO = YN6.GARAGE_CODE 
	and YN6.Province = case when B.STATE IN ('BRITISH COLUMBIA','BC') then 'BC' end
	Left Join Carpro_App..vwBanner vb6(nolock)
	on a6.GARAGES_ACCOUNT_GROUP = vb6.BannerCode

	LEFT JOIN NewfoundlandLive2..GARAGES a7(nolock) on a7.GARAGE_NO =C.DAC_GARAGE_ID  and  b.STATE IN ('NF','Newfoundland')  and RTRIM(a7.GARAGE_NAME) = RTRIM(C.DAC_GARAGE_NAME)
	left join Carpro_App..GARAGES_PREFERRED_YN YN7
	on d.SUV_DEBITOR_OF = YN7.DEBITOR_CODE and a1.GARAGE_NO = YN7.GARAGE_CODE 
	and YN7.Province = case when B.STATE IN ('NF','Newfoundland') then 'NL' end
	Left Join Carpro_App..vwBanner vb7(nolock)
	on a7.GARAGES_ACCOUNT_GROUP = vb7.BannerCode

	LEFT JOIN SaskatchewanLive2..GARAGES a8(nolock) on a8.GARAGE_NO =C.DAC_GARAGE_ID  and  b.STATE IN ('Saskatchewan','Sask')  and RTRIM(a8.GARAGE_NAME) = RTRIM(C.DAC_GARAGE_NAME)
	left join Carpro_App..GARAGES_PREFERRED_YN YN8
	on d.SUV_DEBITOR_OF = YN8.DEBITOR_CODE and a1.GARAGE_NO = YN8.GARAGE_CODE 
	and YN8.Province = case when B.STATE IN ('Saskatchewan','Sask') then 'SK' end
	Left Join Carpro_App..vwBanner vb8(nolock)
	on a8.GARAGES_ACCOUNT_GROUP = vb8.BannerCode
	--left join OntarioLive..VEHICLE_CLASSES v(nolock) on v.CLASS = case when C.DAC_RENTAL_CAR_CLASS > '' then C.DAC_RENTAL_CAR_CLASS else C.VEHICLE_CLASS END
	LEFT JOIN (
		Select Agreement_No, PARENT_EXTEND_AGREEMENT_NO, SOLD_DAYS, CHECK_OUT_DATE, CHECK_OUT_TIME, CHECK_IN_DATE, CHECK_IN_TIME from Ontariolive..Agreements (NOLOCK)
		union 
		Select Agreement_No, PARENT_EXTEND_AGREEMENT_NO, SOLD_DAYS, CHECK_OUT_DATE, CHECK_OUT_TIME, CHECK_IN_DATE, CHECK_IN_TIME from ALBERTALIVE..Agreements (NOLOCK)
		union 
		Select Agreement_No, PARENT_EXTEND_AGREEMENT_NO, SOLD_DAYS, CHECK_OUT_DATE, CHECK_OUT_TIME, CHECK_IN_DATE, CHECK_IN_TIME from MaritimesLive..Agreements (NOLOCK)
		union 
		Select Agreement_No, PARENT_EXTEND_AGREEMENT_NO, SOLD_DAYS, CHECK_OUT_DATE, CHECK_OUT_TIME, CHECK_IN_DATE, CHECK_IN_TIME from BCLive..Agreements (NOLOCK)
		union 
		Select Agreement_No, PARENT_EXTEND_AGREEMENT_NO, SOLD_DAYS, CHECK_OUT_DATE, CHECK_OUT_TIME, CHECK_IN_DATE, CHECK_IN_TIME from SaskatchewanLive2..Agreements (NOLOCK)
		union 
		Select Agreement_No, PARENT_EXTEND_AGREEMENT_NO, SOLD_DAYS, CHECK_OUT_DATE, CHECK_OUT_TIME, CHECK_IN_DATE, CHECK_IN_TIME from NewfoundlandLive2..Agreements (NOLOCK)
		union
		Select Agreement_No, PARENT_EXTEND_AGREEMENT_NO, SOLD_DAYS, CHECK_OUT_DATE, CHECK_OUT_TIME, CHECK_IN_DATE, CHECK_IN_TIME from SaskatchewanLive..Agreements (NOLOCK)
		union 
		Select Agreement_No, PARENT_EXTEND_AGREEMENT_NO, SOLD_DAYS, CHECK_OUT_DATE, CHECK_OUT_TIME, CHECK_IN_DATE, CHECK_IN_TIME from NewfoundlandLive..Agreements (NOLOCK)
	) AG ON AG.AGREEMENT_NO = C.DAC_AGREEMENT_NUMBER
	LEFT JOIN (
		Select Top 1 * from (
			Select FATHER_AGREEMENT_NO, SON_AGREEMENT_NUMBER, UNIT_NO from OntarioLive..SUBAGREEMENTS (NOLOCK)
			union 
			Select FATHER_AGREEMENT_NO, SON_AGREEMENT_NUMBER, UNIT_NO from ALBERTALIVE..SUBAGREEMENTS (NOLOCK)
			union 
			Select FATHER_AGREEMENT_NO, SON_AGREEMENT_NUMBER, UNIT_NO from MaritimesLive..SUBAGREEMENTS (NOLOCK)
			union 
			Select FATHER_AGREEMENT_NO, SON_AGREEMENT_NUMBER, UNIT_NO from BCLive..SUBAGREEMENTS (NOLOCK)
			union 
			Select FATHER_AGREEMENT_NO, SON_AGREEMENT_NUMBER, UNIT_NO from SaskatchewanLive2..SUBAGREEMENTS (NOLOCK)
			union 
			Select FATHER_AGREEMENT_NO, SON_AGREEMENT_NUMBER, UNIT_NO from NewfoundlandLive2..SUBAGREEMENTS (NOLOCK)
			union
			Select FATHER_AGREEMENT_NO, SON_AGREEMENT_NUMBER, UNIT_NO from SaskatchewanLive..SUBAGREEMENTS (NOLOCK)
			union 
			Select FATHER_AGREEMENT_NO, SON_AGREEMENT_NUMBER, UNIT_NO from NewfoundlandLive..SUBAGREEMENTS (NOLOCK)
		) SAG order by SON_AGREEMENT_NUMBER desc
	) SAG ON SAG.FATHER_AGREEMENT_NO = C.DAC_AGREEMENT_NUMBER 
	LEFT JOIN (
		SELECT DCA_CLAIM_ID, AGREEMENT_NO, SUM(DCA_A_DAYS) AS AUTHDAY, 
		SUM(DAC_FINAL_TOTAL) AS DAC_FINAL_TOTAL, AVG(DCA_AUTHOR_RATE) AS AUTHORRATE 
		FROM ONTARIOLIVE..DA_AUTHORIZATION (NOLOCK) DA
		WHERE DCA_BILL_TO = 1  and DCA_AUTHOR_FROM_DATE >= '20100101' and DCA_AUTHOR_TO_DATE <= '20501231'
		GROUP BY DCA_CLAIM_ID, AGREEMENT_NO 
	) A ON C.DAC_ENTRY_ID = A.DCA_CLAIM_ID and A.AGREEMENT_NO = AG.AGREEMENT_NO
	LEFT join (
	select INVOICE_NO,INVOICE_DATE ,DEBITOR_NO, AGREEMENT_NO,INV_STATUS, INVOICE_TYPE,RENTAL,DROF_OFF,SERVICE_FEE,VAT,INVOICE_AMOUNT, AMOUNT_PID, BALANCE, SUBTOTAL, KM from OntarioLive..INVOICES (nolock) 
	union
	select INVOICE_NO,INVOICE_DATE , DEBITOR_NO, AGREEMENT_NO,INV_STATUS, INVOICE_TYPE,RENTAL,DROF_OFF,SERVICE_FEE,VAT,INVOICE_AMOUNT, AMOUNT_PID, BALANCE, SUBTOTAL, KM from AlbertaLive..INVOICES (nolock) 
	union
	select INVOICE_NO,INVOICE_DATE , DEBITOR_NO, AGREEMENT_NO,INV_STATUS, INVOICE_TYPE,RENTAL,DROF_OFF,SERVICE_FEE,VAT,INVOICE_AMOUNT, AMOUNT_PID, BALANCE, SUBTOTAL, KM from BCLive..INVOICES (nolock) 
	union
	select INVOICE_NO,INVOICE_DATE , DEBITOR_NO, AGREEMENT_NO,INV_STATUS, INVOICE_TYPE,RENTAL,DROF_OFF,SERVICE_FEE,VAT,INVOICE_AMOUNT, AMOUNT_PID, BALANCE, SUBTOTAL, KM from MaritimesLive..INVOICES (nolock) 
	union
	select INVOICE_NO,INVOICE_DATE , DEBITOR_NO, AGREEMENT_NO,INV_STATUS, INVOICE_TYPE,RENTAL,DROF_OFF,SERVICE_FEE,VAT,INVOICE_AMOUNT, AMOUNT_PID, BALANCE, SUBTOTAL, KM from SaskatchewanLive..INVOICES (nolock) 
	union
	select INVOICE_NO,INVOICE_DATE , DEBITOR_NO, AGREEMENT_NO,INV_STATUS, INVOICE_TYPE,RENTAL,DROF_OFF,SERVICE_FEE,VAT,INVOICE_AMOUNT, AMOUNT_PID, BALANCE, SUBTOTAL, KM from SaskatchewanLive2..INVOICES (nolock) 
	union
	select INVOICE_NO,INVOICE_DATE , DEBITOR_NO, AGREEMENT_NO,INV_STATUS, INVOICE_TYPE,RENTAL,DROF_OFF,SERVICE_FEE,VAT,INVOICE_AMOUNT, AMOUNT_PID, BALANCE, SUBTOTAL, KM from NewfoundlandLive..INVOICES (nolock) 
	union
	select INVOICE_NO,INVOICE_DATE , DEBITOR_NO, AGREEMENT_NO,INV_STATUS, INVOICE_TYPE,RENTAL,DROF_OFF,SERVICE_FEE,VAT,INVOICE_AMOUNT, AMOUNT_PID, BALANCE, SUBTOTAL, KM from NewfoundlandLive2..INVOICES (nolock) 
	) i on  ISNULL( AG.AGREEMENT_NO, C.DAC_AGREEMENT_NUMBER)= i.AGREEMENT_NO and D.DEBITOR_CODE = I.DEBITOR_NO and I.INV_STATUS !=9 and i.INVOICE_TYPE = 'C'
	LEFT OUTER JOIN(
		SELECT SUM(AMOUNT) AMOUNT, INVOICE_NO FROM Ontariolive..INVOICE_DETAILS(nolock) WHERE ELEMENT_TYPE = 70 AND SUB_ELEMENT_TYPE IN ('VL' ,'VLI') GROUP BY INVOICE_NO
		union
		SELECT SUM(AMOUNT) AMOUNT, INVOICE_NO FROM AlbertaLive..INVOICE_DETAILS(nolock) WHERE ELEMENT_TYPE = 70 AND SUB_ELEMENT_TYPE IN ('VL' ,'VLI') GROUP BY INVOICE_NO
		union
		SELECT SUM(AMOUNT) AMOUNT, INVOICE_NO FROM BCLive..INVOICE_DETAILS(nolock) WHERE ELEMENT_TYPE = 70 AND SUB_ELEMENT_TYPE IN ('VL' ,'VLI') GROUP BY INVOICE_NO
		union
		SELECT SUM(AMOUNT) AMOUNT, INVOICE_NO FROM MaritimesLive..INVOICE_DETAILS(nolock) WHERE ELEMENT_TYPE = 70 AND SUB_ELEMENT_TYPE IN ('VL' ,'VLI') GROUP BY INVOICE_NO
		union
		SELECT SUM(AMOUNT) AMOUNT, INVOICE_NO FROM SaskatchewanLive..INVOICE_DETAILS(nolock) WHERE ELEMENT_TYPE = 70 AND SUB_ELEMENT_TYPE IN ('VL' ,'VLI') GROUP BY INVOICE_NO
		union
		SELECT SUM(AMOUNT) AMOUNT, INVOICE_NO FROM SaskatchewanLive2..INVOICE_DETAILS(nolock) WHERE ELEMENT_TYPE = 70 AND SUB_ELEMENT_TYPE IN ('VL' ,'VLI') GROUP BY INVOICE_NO
		union
		SELECT SUM(AMOUNT) AMOUNT, INVOICE_NO FROM NewfoundlandLive..INVOICE_DETAILS(nolock) WHERE ELEMENT_TYPE = 70 AND SUB_ELEMENT_TYPE IN ('VL' ,'VLI') GROUP BY INVOICE_NO
		union
		SELECT SUM(AMOUNT) AMOUNT, INVOICE_NO FROM NewfoundlandLive2..INVOICE_DETAILS(nolock) WHERE ELEMENT_TYPE = 70 AND SUB_ELEMENT_TYPE IN ('VL' ,'VLI') GROUP BY INVOICE_NO
		) VLI ON i.INVOICE_NO = VLI.INVOICE_NO -- For VL/AC Fee
		LEFT OUTER JOIN 
		(
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from Ontariolive..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from AlbertaLive..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from BCLive..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from MaritimesLive..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from SaskatchewanLive..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from SaskatchewanLive2..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from NewfoundlandLive..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from NewfoundlandLive2..INVOICE_DETAILS (nolock)
			
		) CDW ON i.INVOICE_NO = CDW.INVOICE_NO AND CDW.ELEMENT_TYPE = 60 AND CDW.SUB_ELEMENT_TYPE = 'CDW' -- For CDW
		LEFT OUTER JOIN (
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from Ontariolive..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from AlbertaLive..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from BCLive..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from MaritimesLive..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from SaskatchewanLive..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from SaskatchewanLive2..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from NewfoundlandLive..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from NewfoundlandLive2..INVOICE_DETAILS (nolock)
		) PAP ON i.INVOICE_NO = PAP.INVOICE_NO AND PAP.ELEMENT_TYPE = 60 AND PAP.SUB_ELEMENT_TYPE = 'PAP' -- For CDW
		LEFT OUTER JOIN (
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from Ontariolive..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from AlbertaLive..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from BCLive..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from MaritimesLive..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from SaskatchewanLive..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from SaskatchewanLive2..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from NewfoundlandLive..INVOICE_DETAILS (nolock)
			union
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from NewfoundlandLive2..INVOICE_DETAILS (nolock)
		) WT ON i.INVOICE_NO = WT.INVOICE_NO AND WT.ELEMENT_TYPE = 70 AND WT.SUB_ELEMENT_TYPE = 'WT' -- For CDW
	left join OntarioLive..EBILLING_INVOICE_DATA o(nolock) on C.DAC_ENTRY_ID = o.ENTRY_ID and o.OTHER_CHARGES_DESC like '%tire%'
	WHERE DAC_AGREEMENT_NUMBER > 0 AND DAC_STATUS = 4 and C.DAC_INS_COMPANY_ID > 0
	and ((@DebitorCodes = 'ALL') or (d.SUV_DEBITOR_OF in (Select Data from dbo.SplitByDelimiter(@DebitorCodes,',') where Data != 'ALL')))
	AND DATEADD(SECOND, C.DAC_AGR_CLOSE_TIME, CONVERT(datetime,CONVERT(VARCHAR,C.DAC_AGR_CLOSE_DATE,112))) BETWEEN @BEGIN AND @END
	AND C.DAC_AGR_CLOSE_DATE!='00000000';
	
	
	with tbParentON as
	(
	   select * from OntarioLive..AGREEMENTS (Nolock) 
	   where AGREEMENT_NO in (select AgreementNo from #tempDataRemedy  where cast(ParentAgreementNo as bigint) > 0)
	   union all
	   select AGREEMENTS.* from OntarioLive..AGREEMENTS (Nolock) join tbParentON  on AGREEMENTS.AGREEMENT_NO=tbParentON.PARENT_EXTEND_AGREEMENT_NO
	)
	
	SELECT * into #tempDataRewriteON FROM  tbParentON a option (maxrecursion 0);
	
	with tbParentAB as
	(
	   select * from AlbertaLive..AGREEMENTS (Nolock)
	   where AGREEMENT_NO in (select AgreementNo from #tempDataRemedy  where cast(ParentAgreementNo as bigint) > 0)
	   union all
	   select AGREEMENTS.* from AlbertaLive..AGREEMENTS (Nolock) join tbParentAB  on AGREEMENTS.AGREEMENT_NO=tbParentAB.PARENT_EXTEND_AGREEMENT_NO
	)

	SELECT * into #tempDataRewriteAB FROM  tbParentAB a option (maxrecursion 0);
	
	with tbParentBC as
	(
	   select * from BCLive..AGREEMENTS  (Nolock)
	   
	   where AGREEMENT_NO in (select AgreementNo from #tempDataRemedy  where cast(ParentAgreementNo as bigint) > 0)
	   union all
	   select AGREEMENTS.* from BCLive..AGREEMENTS (Nolock) join tbParentBC  on AGREEMENTS.AGREEMENT_NO=tbParentBC.PARENT_EXTEND_AGREEMENT_NO
	)

	SELECT * into #tempDataRewriteBC FROM  tbParentBC a option (maxrecursion 0);
	
	with tbParentSK as
	(
	   select * from SaskatchewanLive..AGREEMENTS (Nolock)
	   
	   where AGREEMENT_NO in (select AgreementNo from #tempDataRemedy  where cast(ParentAgreementNo as bigint) > 0)
	   union all
	   select AGREEMENTS.* from SaskatchewanLive..AGREEMENTS (Nolock) join tbParentSK  on AGREEMENTS.AGREEMENT_NO=tbParentSK.PARENT_EXTEND_AGREEMENT_NO
	)

	SELECT * into #tempDataRewriteSK FROM  tbParentSK a option (maxrecursion 0);
	
	with tbParentSK2 as
	(
	   select * from SaskatchewanLive2..AGREEMENTS (Nolock)
	   
	   where AGREEMENT_NO in (select AgreementNo from #tempDataRemedy  where cast(ParentAgreementNo as bigint) > 0)
	   union all
	   select AGREEMENTS.* from SaskatchewanLive2..AGREEMENTS (Nolock) join tbParentSK2  on AGREEMENTS.AGREEMENT_NO=tbParentSK2.PARENT_EXTEND_AGREEMENT_NO
	)

	SELECT * into #tempDataRewriteSK2 FROM  tbParentSK2 a option (maxrecursion 0);
	
	with tbParentNL as
	(
	   select * from NewfoundlandLive..AGREEMENTS (Nolock)
	   
	   where AGREEMENT_NO in (select AgreementNo from #tempDataRemedy  where cast(ParentAgreementNo as bigint) > 0)
	   union all
	   select AGREEMENTS.* from NewfoundlandLive..AGREEMENTS (Nolock) join tbParentNL  on AGREEMENTS.AGREEMENT_NO=tbParentNL.PARENT_EXTEND_AGREEMENT_NO
	)

	SELECT * into #tempDataRewriteNL FROM  tbParentNL a option (maxrecursion 0);
	
	with tbParentNC as
	(
	   select * from NewfoundlandLive2..AGREEMENTS (Nolock)
	   
	   where AGREEMENT_NO in (select AgreementNo from #tempDataRemedy  where cast(ParentAgreementNo as bigint) > 0)
	   union all
	   select AGREEMENTS.* from NewfoundlandLive2..AGREEMENTS (Nolock) join tbParentNC  on AGREEMENTS.AGREEMENT_NO=tbParentNC.PARENT_EXTEND_AGREEMENT_NO
	)

	SELECT * into #tempDataRewriteNC FROM  tbParentNC a option (maxrecursion 0);
	
	with tbParentMT as
	(
	   select * from MaritimesLive..AGREEMENTS (Nolock)
	   
	   where AGREEMENT_NO in (select AgreementNo from #tempDataRemedy  where cast(ParentAgreementNo as bigint) > 0)
	   union all
	   select AGREEMENTS.* from MaritimesLive..AGREEMENTS (Nolock) join tbParentMT  on AGREEMENTS.AGREEMENT_NO=tbParentMT.PARENT_EXTEND_AGREEMENT_NO
	)

	SELECT * into #tempDataRewriteMT FROM  tbParentMT a option (maxrecursion 0);
	
	
	SELECT DISTINCT 'From_RMS' Source,
	'ON' as PROVINCE, 
	Case when C.DAC_Claim_Type = 0 then 'Collision'	when C.DAC_Claim_Type = 1 then 'Comprehensive' when C.DAC_Claim_Type = 2 then 'Theft' end ClaimType,
	case when CHARINDEX('Stolen' ,DAC_GARAGE_NAME)> 0 OR CHARINDEX('Theft',DAC_GARAGE_NAME)> 0 Or CHARINDEX('Loss',DAC_GARAGE_NAME)> 0 Or CHARINDEX('Write',DAC_GARAGE_NAME)> 0  then DAC_GARAGE_NAME when DAC_TOTAL_LOSS ='Y' then  'OTAL_LOSS' when  DAC_Claim_Type =2 then 'Theft' else '' END ExtentOfLoss,
	ltrim(rtrim(G.GARAGE_NAME)) as GARAGE_NAME, --, GARAGE_NO 
	(Select top 1 Debitor_Name from #temp_debitors where #temp_debitors.SUV_DEBITOR_OF = d.SUV_DEBITOR_OF) as ParentInsurerName,
	D.DEBITOR_NAME AS [INS COMPANY NAME],
	case when cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) > 0 then 'Y' else 'N' end as IsRewrite,
    cast(cast(A.Agreement_No as bigint) as varchar(15)) as AgreementNo,
    cast(cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) as varchar(15))  as ParentAgreementNo, 
	case when i.INVOICE_DATE between '20100101' and '20491231' then  convert(varchar(10),CONVERT(datetime, i.INVOICE_DATE,112),120) when DAC_INVOICE_DATE between '20100101' and '20491231' then  convert(varchar(10),CONVERT(datetime, C.DAC_INVOICE_DATE,112),120) end InvoiceDate,
	i.INVOICE_NO InvoiceNo,
    C.DAC_INS_CLAIM as CLAIM_NO,
    C.DAC_POLICY as POLICY_NO,
    A.DRIVER_FIRST_NAME + ' ' + A.DRIVER_LAST_NAME as Renter_Name,
    case when A.SOLD_DAYS != 0 then cast(round(i.RENTAL/A.SOLD_DAYS,2) as numeric(36,2)) end  AvgRate,
    A.SOLD_DAYS AS [RENTAL_DAYS], 
    i.RENTAL as Rental_Sum, 
    case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.TFFS,0) else ISNULL(VLI.AMOUNT,0) end AS VehicleLicenseFee,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(o.OTHER_CHARGES,0)  else ISNULL(WT.AMOUNT,0) end AS  WinterTireFee,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.KILOMETERS,0) else ISNULL(i.KM,0) end AS  KilometerCharges,
	ISNULL(i.DROF_OFF,0) AS DropFees,
	ISNULL(CDW.AMOUNT,0) AS CollisionDamageWaiver,
	ISNULL(PAP.AMOUNT,0) AS PracticleAssistanceProgram,
	case  when C.DAC_ARS_WEB ='Y' then h.SUB_TOTAL else i.SUBTOTAL end AS SubTotal,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.PST,0) else ISNULL(i.SERVICE_FEE,0) end ProvincialTaxes,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.GST+ h.HST,0) else ISNULL(i.VAT,0) end FederalTaxes,
	case when C.DAC_ARS_WEB ='Y' then h.TOTAL else i.INVOICE_AMOUNT end TotalFees,
	i.AMOUNT_PID as Paid_Amount,
	i.BALANCE as Balance,
	case when DAC_DATE_OF_LOSS between '20100101' and '20491231' then convert(varchar(10),CONVERT(datetime, C.DAC_DATE_OF_LOSS,112),120) end DateOfLoss,
	case when A.CHECK_IN_DATE between '20100101' and '20491231'  then (SELECT DATENAME(DW, CAST(A.CHECK_IN_DATE AS datetime))) end Day_of_Week,
	case when A.CHECK_IN_DATE between '20100101' and '20491231'  then (SELECT DATENAME(month, CAST(A.CHECK_IN_DATE AS datetime))) end Month,
	case when adj.DAA_FULL_NAME IS NULL then 'UNKNOWN' else adj.DAA_FULL_NAME end AdjusterName,
	ISNULL(AUTHDAY, 0) AS [TOTAL AUTHOR DAYS], 
	ISNULL(Auth.AUTHORRATE, 0) As AuthRate,
	DATEADD(SECOND, A.CHECK_OUT_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_OUT_DATE,112))) as Rental_Out,
	DATEADD(SECOND, A.CHECK_IN_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_IN_DATE,112))) as Rental_In,
	DAC_DRIVABLE AS DRIVABLE, 
	C.DAC_MAKE as ICC_Make, 
	C.DAC_MODEL as ICC_Model, 
	C.DAC_YEAR as ICC_Vehicle_Year,
	C.DAC_RENTAL_MAKE as CarManufacturer,
    C.DAC_RENTAL_MODEL as CarModel,
    C.DAC_RENTAL_YEAR as VehicleYear,
    ISNULL(ISNULL(C.DAC_RENTAL_CAR_GROUP, C.VEHICLE_CLASS), C.VEHICLE_CLASS) as ICC_Category,
    C.DAC_RENTAL_CAR_CLASS as Category,
    SB.Unit_No as CarCategory,
    case when C.DAC_RENTAL_CHECK_OUT_BRANCH_CODE > 0 then C.DAC_RENTAL_CHECK_OUT_BRANCH_CODE else DAC_LOCATION_CODE end BranchCode,
    B.BRANACH_NAME as BranchName,
    B.CITY as BranchCity,
    B.STATE as BranchState,
    ISNULL(VB.BannerName,'') as BannerName,
    case when YN.PREFERRED_YN IS NOT NULL and YN.PREFERRED_YN = 1 then 'YES' else 'NO' end as Preferred_Garages, 
	BRANACH_NAME AS [LOCATION NAME], B.STREET [LOCATION ADDRESS], 
	DAC_GARAGE_ADDRESS AS [GARAGE ADDRESS]
	INTO #tempDataAgreements
	FROM [ONTARIOLIVE].DBO.AGREEMENTS A (NOLOCK) 
	LEFT JOIN (
		Select top 1 * from (
			Select FATHER_AGREEMENT_NO, SON_AGREEMENT_NUMBER, UNIT_NO from OntarioLive..SUBAGREEMENTS SB (NOLOCK) 
		) SB order by SON_AGREEMENT_NUMBER desc
	)  SB on SB.FATHER_AGREEMENT_NO = A.Agreement_No
	INNER JOIN #tempDataRewriteON rw on rw.AGREEMENT_NO = a.AGREEMENT_NO	
	LEFT JOIN OntarioLive.DBO.BRANCHES B (NOLOCK) ON B.BRANACH_CODE = A.CHECK_OUT_BRANACH 
	LEFT JOIN OntarioLive..DEBITORS D (NOLOCK) ON D.DEBITOR_CODE = A.DEBITOR_CODE 
	LEFT JOIN [ONTARIOLIVE].DBO.REPAIRED_AT R (NOLOCK) ON A.AGREEMENT_NO = R.AGREEMENT_NO and R.BODY_SHOP > 0
	LEFT JOIN [ONTARIOLIVE].DBO.GARAGES G (NOLOCK) ON G.GARAGE_NO = R.BODY_SHOP 	
	LEFT JOIN Carpro_App..vwBanner VB (NOLOCK) ON VB.BannerCode = G.GARAGES_ACCOUNT_GROUP
	left join Carpro_App..GARAGES_PREFERRED_YN YN on D.SUV_DEBITOR_OF = YN.DEBITOR_CODE and G.GARAGE_NO = YN.GARAGE_CODE 
	LEFT JOIN OntarioLive..DA_CLAIMS C (NOLOCK) ON C.DAC_AGREEMENT_NUMBER = A.AGREEMENT_NO
	Left join OntarioLive..EBILLING_INVOICE_DATA H(nolock) on C.DAC_ENTRY_ID = H.ENTRY_ID
	Left join OntarioLive..DA_ADJUSTER adj (NOLOCK) on C.DAC_COMPANY_ADJUSTER_ID = adj.DAA_ENTRY_ID
	LEFT JOIN (
		SELECT DCA_CLAIM_ID, AGREEMENT_NO, SUM(DCA_A_DAYS) AS AUTHDAY, 
		SUM(DAC_FINAL_TOTAL) AS DAC_FINAL_TOTAL, AVG(DCA_AUTHOR_RATE) AS AUTHORRATE 
		FROM ONTARIOLIVE..DA_AUTHORIZATION (NOLOCK)  WHERE DCA_BILL_TO = 1  and DCA_AUTHOR_FROM_DATE >= '20100101' and DCA_AUTHOR_TO_DATE <= '20501231'
		GROUP BY DCA_CLAIM_ID, AGREEMENT_NO
	) Auth ON C.DAC_ENTRY_ID = Auth.DCA_CLAIM_ID and Auth.AGREEMENT_NO = A.AGREEMENT_NO
	--left join OntarioLive..VEHICLE_CLASSES v(nolock) on v.CLASS = case when C.DAC_RENTAL_CAR_CLASS > '' then C.DAC_RENTAL_CAR_CLASS else C.VEHICLE_CLASS END
	LEFT join OntarioLive..INVOICES (nolock) i on ISNULL( A.AGREEMENT_NO, C.DAC_AGREEMENT_NUMBER)= i.AGREEMENT_NO and D.DEBITOR_CODE = I.DEBITOR_NO and I.INV_STATUS !=9 and i.INVOICE_TYPE = 'C'
	LEFT OUTER JOIN
		(
			SELECT SUM(AMOUNT) AMOUNT, INVOICE_NO FROM Ontariolive..INVOICE_DETAILS(nolock) WHERE ELEMENT_TYPE = 70 AND SUB_ELEMENT_TYPE IN ('VL' ,'VLI') GROUP BY INVOICE_NO
		) VLI ON i.INVOICE_NO = VLI.INVOICE_NO -- For VL/AC Fee
	LEFT OUTER JOIN 
		(
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from Ontariolive..INVOICE_DETAILS (nolock)
			
		) CDW ON i.INVOICE_NO = CDW.INVOICE_NO AND CDW.ELEMENT_TYPE = 60 AND CDW.SUB_ELEMENT_TYPE = 'CDW' -- For CDW
	LEFT OUTER JOIN (
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from Ontariolive..INVOICE_DETAILS (nolock)
		) PAP ON i.INVOICE_NO = PAP.INVOICE_NO AND PAP.ELEMENT_TYPE = 60 AND PAP.SUB_ELEMENT_TYPE = 'PAP' -- For CDW
	LEFT OUTER JOIN (
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from Ontariolive..INVOICE_DETAILS (nolock)
		) WT ON i.INVOICE_NO = WT.INVOICE_NO AND WT.ELEMENT_TYPE = 70 AND WT.SUB_ELEMENT_TYPE = 'WT' -- For CDW
	left join OntarioLive..EBILLING_INVOICE_DATA o(nolock) on C.DAC_ENTRY_ID = o.ENTRY_ID and o.OTHER_CHARGES_DESC like '%tire%'
	WHERE 	
	A.STATUS_CODE = 4 AND A.DEBITOR_CODE > 0 
	and ((@DebitorCodes = 'ALL') or (d.SUV_DEBITOR_OF in (Select Data from dbo.SplitByDelimiter(@DebitorCodes,',') where Data != 'ALL')))
	AND DATEADD(SECOND, A.CHECK_IN_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_IN_DATE,112))) BETWEEN @BEGIN AND @End
	AND A.CHECK_IN_DATE!='00000000' 
	UNION 	
	SELECT DISTINCT 'From_RMS' Source, 'AB' as PROVINCE, 
	Case when C.DAC_Claim_Type = 0 then 'Collision'	when C.DAC_Claim_Type = 1 then 'Comprehensive' when C.DAC_Claim_Type = 2 then 'Theft' end ClaimType,
	case when CHARINDEX('Stolen' ,DAC_GARAGE_NAME)> 0 OR CHARINDEX('Theft',DAC_GARAGE_NAME)> 0 Or CHARINDEX('Loss',DAC_GARAGE_NAME)> 0 Or CHARINDEX('Write',DAC_GARAGE_NAME)> 0  then DAC_GARAGE_NAME when DAC_TOTAL_LOSS ='Y' then  'OTAL_LOSS' when  DAC_Claim_Type =2 then 'Theft' else '' END ExtentOfLoss,
	ltrim(rtrim(G.GARAGE_NAME)) as GARAGE_NAME, --, GARAGE_NO 
	(Select top 1 Debitor_Name from #temp_debitors where #temp_debitors.SUV_DEBITOR_OF = d.SUV_DEBITOR_OF) as ParentInsurerName,
	D.DEBITOR_NAME AS [INS COMPANY NAME],
	case when cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) > 0 then 'Y' else 'N' end as IsRewrite,
    cast(cast(A.Agreement_No as bigint) as varchar(15)) as AgreementNo,
    cast(cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) as varchar(15))  as ParentAgreementNo, 
	case when i.INVOICE_DATE between '20100101' and '20491231' then  convert(varchar(10),CONVERT(datetime, i.INVOICE_DATE,112),120) when DAC_INVOICE_DATE between '20100101' and '20491231' then  convert(varchar(10),CONVERT(datetime, C.DAC_INVOICE_DATE,112),120) end InvoiceDate,
	i.INVOICE_NO InvoiceNo,
    C.DAC_INS_CLAIM as CLAIM_NO,
    C.DAC_POLICY as POLICY_NO,
    A.DRIVER_FIRST_NAME + ' ' + A.DRIVER_LAST_NAME as Renter_Name,
    case when A.SOLD_DAYS != 0 then cast(round(i.RENTAL/A.SOLD_DAYS,2) as numeric(36,2)) end  AvgRate,
    A.SOLD_DAYS AS [RENTAL_DAYS], 
    i.RENTAL as Rental_Sum, 
    case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.TFFS,0) else ISNULL(VLI.AMOUNT,0) end AS VehicleLicenseFee,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(o.OTHER_CHARGES,0)  else ISNULL(WT.AMOUNT,0) end AS  WinterTireFee,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.KILOMETERS,0) else ISNULL(i.KM,0) end AS  KilometerCharges,
	ISNULL(i.DROF_OFF,0) AS DropFees,
	ISNULL(CDW.AMOUNT,0) AS CollisionDamageWaiver,
	ISNULL(PAP.AMOUNT,0) AS PracticleAssistanceProgram,
	case  when C.DAC_ARS_WEB ='Y' then h.SUB_TOTAL else i.SUBTOTAL end AS SubTotal,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.PST,0) else ISNULL(i.SERVICE_FEE,0) end ProvincialTaxes,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.GST+ h.HST,0) else ISNULL(i.VAT,0) end FederalTaxes,
	case when C.DAC_ARS_WEB ='Y' then h.TOTAL else i.INVOICE_AMOUNT end TotalFees,
	i.AMOUNT_PID as Paid_Amount,
	i.BALANCE as Balance,
	case when DAC_DATE_OF_LOSS between '20100101' and '20491231' then convert(varchar(10),CONVERT(datetime, C.DAC_DATE_OF_LOSS,112),120) end DateOfLoss,
	case when A.CHECK_IN_DATE between '20100101' and '20491231'  then (SELECT DATENAME(DW, CAST(A.CHECK_IN_DATE AS datetime))) end Day_of_Week,
	case when A.CHECK_IN_DATE between '20100101' and '20491231'  then (SELECT DATENAME(month, CAST(A.CHECK_IN_DATE AS datetime))) end Month,
	case when adj.DAA_FULL_NAME IS NULL then 'UNKNOWN' else adj.DAA_FULL_NAME end AdjusterName,
	ISNULL(AUTHDAY, 0) AS [TOTAL AUTHOR DAYS], 
	ISNULL(Auth.AUTHORRATE, 0) As AuthRate, 
	DATEADD(SECOND, A.CHECK_OUT_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_OUT_DATE,112))) as Rental_Out,
	DATEADD(SECOND, A.CHECK_IN_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_IN_DATE,112))) as Rental_In,
	DAC_DRIVABLE AS DRIVABLE, 
	C.DAC_MAKE as ICC_Make, 
	C.DAC_MODEL as ICC_Model, 
	C.DAC_YEAR as ICC_Vehicle_Year,
	C.DAC_RENTAL_MAKE as CarManufacturer,
    C.DAC_RENTAL_MODEL as CarModel,
    C.DAC_RENTAL_YEAR as VehicleYear,
    ISNULL(ISNULL(C.DAC_RENTAL_CAR_GROUP, C.VEHICLE_CLASS), C.VEHICLE_CLASS) as ICC_Category,
    C.DAC_RENTAL_CAR_CLASS as Category,
    SB.Unit_No as CarCategory,
    case when C.DAC_RENTAL_CHECK_OUT_BRANCH_CODE > 0 then C.DAC_RENTAL_CHECK_OUT_BRANCH_CODE else DAC_LOCATION_CODE end BranchCode,
    B.BRANACH_NAME as BranchName,
    B.CITY as BranchCity,
    B.STATE as BranchState,
    ISNULL(VB.BannerName,'') as BannerName,
    case when YN.PREFERRED_YN IS NOT NULL and YN.PREFERRED_YN = 1 then 'YES' else 'NO' end as Preferred_Garages, 
	BRANACH_NAME AS [LOCATION NAME], B.STREET [LOCATION ADDRESS], 
	DAC_GARAGE_ADDRESS AS [GARAGE ADDRESS]
	FROM [ALBERTALIVE].DBO.AGREEMENTS A (NOLOCK) 
	LEFT JOIN (
		Select top 1 * from (
			Select FATHER_AGREEMENT_NO, SON_AGREEMENT_NUMBER, UNIT_NO from [ALBERTALIVE]..SUBAGREEMENTS SB (NOLOCK) 
		) SB order by SON_AGREEMENT_NUMBER desc
	)  SB on SB.FATHER_AGREEMENT_NO = A.Agreement_No
	INNER JOIN #tempDataRewriteAB rw on rw.AGREEMENT_NO = a.AGREEMENT_NO	
	LEFT JOIN [ALBERTALIVE].DBO.BRANCHES B (NOLOCK) ON B.BRANACH_CODE = A.CHECK_OUT_BRANACH 
	LEFT JOIN [ALBERTALIVE]..DEBITORS D (NOLOCK) ON D.DEBITOR_CODE = A.DEBITOR_CODE  
	LEFT JOIN [ALBERTALIVE].DBO.REPAIRED_AT R (NOLOCK) ON A.AGREEMENT_NO = R.AGREEMENT_NO and R.BODY_SHOP > 0
	LEFT JOIN [ALBERTALIVE].DBO.GARAGES G (NOLOCK) ON G.GARAGE_NO = R.BODY_SHOP 	
	LEFT JOIN Carpro_App..vwBanner VB (NOLOCK) ON VB.BannerCode = G.GARAGES_ACCOUNT_GROUP
	left join Carpro_App..GARAGES_PREFERRED_YN YN on D.SUV_DEBITOR_OF = YN.DEBITOR_CODE and G.GARAGE_NO = YN.GARAGE_CODE 
	LEFT JOIN OntarioLive..DA_CLAIMS C (NOLOCK) ON C.DAC_AGREEMENT_NUMBER = A.AGREEMENT_NO
	Left join OntarioLive..EBILLING_INVOICE_DATA H(nolock) on C.DAC_ENTRY_ID = H.ENTRY_ID
	Left join OntarioLive..DA_ADJUSTER adj (NOLOCK) on C.DAC_COMPANY_ADJUSTER_ID = adj.DAA_ENTRY_ID
	LEFT JOIN (
		SELECT DCA_CLAIM_ID, AGREEMENT_NO, SUM(DCA_A_DAYS) AS AUTHDAY, 
		SUM(DAC_FINAL_TOTAL) AS DAC_FINAL_TOTAL, AVG(DCA_AUTHOR_RATE) AS AUTHORRATE 
		FROM ONTARIOLIVE..DA_AUTHORIZATION (NOLOCK)  WHERE DCA_BILL_TO = 1  and DCA_AUTHOR_FROM_DATE >= '20100101' and DCA_AUTHOR_TO_DATE <= '20501231'
		GROUP BY DCA_CLAIM_ID, AGREEMENT_NO
	) Auth ON C.DAC_ENTRY_ID = Auth.DCA_CLAIM_ID and Auth.AGREEMENT_NO = A.AGREEMENT_NO
	--left join ALBERTALIVE..VEHICLE_CLASSES v(nolock) on v.CLASS = case when C.DAC_RENTAL_CAR_CLASS > '' then C.DAC_RENTAL_CAR_CLASS else C.VEHICLE_CLASS END
	LEFT join ALBERTALIVE..INVOICES (nolock) i on ISNULL( A.AGREEMENT_NO, C.DAC_AGREEMENT_NUMBER)= i.AGREEMENT_NO and D.DEBITOR_CODE = I.DEBITOR_NO and I.INV_STATUS !=9 and i.INVOICE_TYPE = 'C'
	LEFT OUTER JOIN
		(
			SELECT SUM(AMOUNT) AMOUNT, INVOICE_NO FROM ALBERTALIVE..INVOICE_DETAILS(nolock) WHERE ELEMENT_TYPE = 70 AND SUB_ELEMENT_TYPE IN ('VL' ,'VLI') GROUP BY INVOICE_NO
		) VLI ON i.INVOICE_NO = VLI.INVOICE_NO -- For VL/AC Fee
	LEFT OUTER JOIN 
		(
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from ALBERTALIVE..INVOICE_DETAILS (nolock)
			
		) CDW ON i.INVOICE_NO = CDW.INVOICE_NO AND CDW.ELEMENT_TYPE = 60 AND CDW.SUB_ELEMENT_TYPE = 'CDW' -- For CDW
	LEFT OUTER JOIN (
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from ALBERTALIVE..INVOICE_DETAILS (nolock)
		) PAP ON i.INVOICE_NO = PAP.INVOICE_NO AND PAP.ELEMENT_TYPE = 60 AND PAP.SUB_ELEMENT_TYPE = 'PAP' -- For CDW
	LEFT OUTER JOIN (
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from ALBERTALIVE..INVOICE_DETAILS (nolock)
		) WT ON i.INVOICE_NO = WT.INVOICE_NO AND WT.ELEMENT_TYPE = 70 AND WT.SUB_ELEMENT_TYPE = 'WT' -- For CDW
	left join ALBERTALIVE..EBILLING_INVOICE_DATA o(nolock) on C.DAC_ENTRY_ID = o.ENTRY_ID and o.OTHER_CHARGES_DESC like '%tire%'
	WHERE 	
	A.STATUS_CODE = 4 AND A.DEBITOR_CODE > 0 
	and ((@DebitorCodes = 'ALL') or (d.SUV_DEBITOR_OF in (Select Data from dbo.SplitByDelimiter(@DebitorCodes,',') where Data != 'ALL')))
	AND DATEADD(SECOND, A.CHECK_IN_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_IN_DATE,112))) BETWEEN @BEGIN AND @End
	AND A.CHECK_IN_DATE!='00000000'  	
	UNION 	
	SELECT DISTINCT 'From_RMS' Source, 'MT' as PROVINCE, 
	Case when C.DAC_Claim_Type = 0 then 'Collision'	when C.DAC_Claim_Type = 1 then 'Comprehensive' when C.DAC_Claim_Type = 2 then 'Theft' end ClaimType,
	case when CHARINDEX('Stolen' ,DAC_GARAGE_NAME)> 0 OR CHARINDEX('Theft',DAC_GARAGE_NAME)> 0 Or CHARINDEX('Loss',DAC_GARAGE_NAME)> 0 Or CHARINDEX('Write',DAC_GARAGE_NAME)> 0  then DAC_GARAGE_NAME when DAC_TOTAL_LOSS ='Y' then  'OTAL_LOSS' when  DAC_Claim_Type =2 then 'Theft' else '' END ExtentOfLoss,
	ltrim(rtrim(G.GARAGE_NAME)) as GARAGE_NAME, --, GARAGE_NO 
	(Select top 1 Debitor_Name from #temp_debitors where #temp_debitors.SUV_DEBITOR_OF = d.SUV_DEBITOR_OF) as ParentInsurerName,
	D.DEBITOR_NAME AS [INS COMPANY NAME],
	case when cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) > 0 then 'Y' else 'N' end as IsRewrite,
    cast(cast(A.Agreement_No as bigint) as varchar(15)) as AgreementNo,
    cast(cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) as varchar(15))  as ParentAgreementNo, 
	case when i.INVOICE_DATE between '20100101' and '20491231' then  convert(varchar(10),CONVERT(datetime, i.INVOICE_DATE,112),120) when DAC_INVOICE_DATE between '20100101' and '20491231' then  convert(varchar(10),CONVERT(datetime, C.DAC_INVOICE_DATE,112),120) end InvoiceDate,
	i.INVOICE_NO InvoiceNo,
    C.DAC_INS_CLAIM as CLAIM_NO,
    C.DAC_POLICY as POLICY_NO,
    A.DRIVER_FIRST_NAME + ' ' + A.DRIVER_LAST_NAME as Renter_Name,
    case when A.SOLD_DAYS != 0 then cast(round(i.RENTAL/A.SOLD_DAYS,2) as numeric(36,2)) end  AvgRate,
    A.SOLD_DAYS AS [RENTAL_DAYS], 
    i.RENTAL as Rental_Sum, 
    case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.TFFS,0) else ISNULL(VLI.AMOUNT,0) end AS VehicleLicenseFee,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(o.OTHER_CHARGES,0)  else ISNULL(WT.AMOUNT,0) end AS  WinterTireFee,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.KILOMETERS,0) else ISNULL(i.KM,0) end AS  KilometerCharges,
	ISNULL(i.DROF_OFF,0) AS DropFees,
	ISNULL(CDW.AMOUNT,0) AS CollisionDamageWaiver,
	ISNULL(PAP.AMOUNT,0) AS PracticleAssistanceProgram,
	case  when C.DAC_ARS_WEB ='Y' then h.SUB_TOTAL else i.SUBTOTAL end AS SubTotal,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.PST,0) else ISNULL(i.SERVICE_FEE,0) end ProvincialTaxes,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.GST+ h.HST,0) else ISNULL(i.VAT,0) end FederalTaxes,
	case when C.DAC_ARS_WEB ='Y' then h.TOTAL else i.INVOICE_AMOUNT end TotalFees,
	i.AMOUNT_PID as Paid_Amount,
	i.BALANCE as Balance,
	case when DAC_DATE_OF_LOSS between '20100101' and '20491231' then convert(varchar(10),CONVERT(datetime, C.DAC_DATE_OF_LOSS,112),120) end DateOfLoss,
	case when A.CHECK_IN_DATE between '20100101' and '20491231'  then (SELECT DATENAME(DW, CAST(A.CHECK_IN_DATE AS datetime))) end Day_of_Week,
	case when A.CHECK_IN_DATE between '20100101' and '20491231'  then (SELECT DATENAME(month, CAST(A.CHECK_IN_DATE AS datetime))) end Month,
	case when adj.DAA_FULL_NAME IS NULL then 'UNKNOWN' else adj.DAA_FULL_NAME end AdjusterName,
	ISNULL(AUTHDAY, 0) AS [TOTAL AUTHOR DAYS], 
	ISNULL(Auth.AUTHORRATE, 0) As AuthRate,
	DATEADD(SECOND, A.CHECK_OUT_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_OUT_DATE,112))) as Rental_Out,
	DATEADD(SECOND, A.CHECK_IN_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_IN_DATE,112))) as Rental_In,
	DAC_DRIVABLE AS DRIVABLE, 
	C.DAC_MAKE as ICC_Make, 
	C.DAC_MODEL as ICC_Model, 
	C.DAC_YEAR as ICC_Vehicle_Year,
	C.DAC_RENTAL_MAKE as CarManufacturer,
    C.DAC_RENTAL_MODEL as CarModel,
    C.DAC_RENTAL_YEAR as VehicleYear,
    ISNULL(ISNULL(C.DAC_RENTAL_CAR_GROUP, C.VEHICLE_CLASS), C.VEHICLE_CLASS) as ICC_Category,
    C.DAC_RENTAL_CAR_CLASS as Category,
    SB.Unit_No as CarCategory,
    case when C.DAC_RENTAL_CHECK_OUT_BRANCH_CODE > 0 then C.DAC_RENTAL_CHECK_OUT_BRANCH_CODE else DAC_LOCATION_CODE end BranchCode,
    B.BRANACH_NAME as BranchName,
    B.CITY as BranchCity,
    B.STATE as BranchState,
    ISNULL(VB.BannerName,'') as BannerName,
    case when YN.PREFERRED_YN IS NOT NULL and YN.PREFERRED_YN = 1 then 'YES' else 'NO' end as Preferred_Garages, 
	BRANACH_NAME AS [LOCATION NAME], B.STREET [LOCATION ADDRESS], 
	DAC_GARAGE_ADDRESS AS [GARAGE ADDRESS]
	FROM MaritimesLive.DBO.AGREEMENTS A (NOLOCK) 
	LEFT JOIN (
		Select top 1 * from (
			Select FATHER_AGREEMENT_NO, SON_AGREEMENT_NUMBER, UNIT_NO from MaritimesLive..SUBAGREEMENTS SB (NOLOCK) 
		) SB order by SON_AGREEMENT_NUMBER desc
	)  SB on SB.FATHER_AGREEMENT_NO = A.Agreement_No
	INNER JOIN #tempDataRewriteMT rw on rw.AGREEMENT_NO = a.AGREEMENT_NO	
	LEFT JOIN MaritimesLive.DBO.BRANCHES B (NOLOCK) ON B.BRANACH_CODE = A.CHECK_OUT_BRANACH 
	LEFT JOIN MaritimesLive..DEBITORS D (NOLOCK) ON D.DEBITOR_CODE = A.DEBITOR_CODE
	LEFT JOIN MaritimesLive.DBO.REPAIRED_AT R (NOLOCK) ON A.AGREEMENT_NO = R.AGREEMENT_NO and R.BODY_SHOP > 0
	LEFT JOIN MaritimesLive.DBO.GARAGES G (NOLOCK) ON G.GARAGE_NO = R.BODY_SHOP 
	LEFT JOIN Carpro_App..vwBanner VB (NOLOCK) ON VB.BannerCode = G.GARAGES_ACCOUNT_GROUP
	left join Carpro_App..GARAGES_PREFERRED_YN YN on D.SUV_DEBITOR_OF = YN.DEBITOR_CODE and G.GARAGE_NO = YN.GARAGE_CODE 
	LEFT JOIN OntarioLive..DA_CLAIMS C (NOLOCK) ON C.DAC_AGREEMENT_NUMBER = A.AGREEMENT_NO	
	Left join OntarioLive..EBILLING_INVOICE_DATA H(nolock) on C.DAC_ENTRY_ID = H.ENTRY_ID
	Left join OntarioLive..DA_ADJUSTER adj (NOLOCK) on C.DAC_COMPANY_ADJUSTER_ID = adj.DAA_ENTRY_ID
	LEFT JOIN (
		SELECT DCA_CLAIM_ID, AGREEMENT_NO, SUM(DCA_A_DAYS) AS AUTHDAY, 
		SUM(DAC_FINAL_TOTAL) AS DAC_FINAL_TOTAL, AVG(DCA_AUTHOR_RATE) AS AUTHORRATE 
		FROM ONTARIOLIVE..DA_AUTHORIZATION (NOLOCK)  WHERE DCA_BILL_TO = 1  and DCA_AUTHOR_FROM_DATE >= '20100101' and DCA_AUTHOR_TO_DATE <= '20501231'
		GROUP BY DCA_CLAIM_ID, AGREEMENT_NO
	) Auth ON C.DAC_ENTRY_ID = Auth.DCA_CLAIM_ID and Auth.AGREEMENT_NO = A.AGREEMENT_NO
	--left join MaritimesLive..VEHICLE_CLASSES v(nolock) on v.CLASS = case when C.DAC_RENTAL_CAR_CLASS > '' then C.DAC_RENTAL_CAR_CLASS else C.VEHICLE_CLASS END
	LEFT join MaritimesLive..INVOICES (nolock) i on ISNULL( A.AGREEMENT_NO, C.DAC_AGREEMENT_NUMBER)= i.AGREEMENT_NO and D.DEBITOR_CODE = I.DEBITOR_NO and I.INV_STATUS !=9 and i.INVOICE_TYPE = 'C'
	LEFT OUTER JOIN
		(
			SELECT SUM(AMOUNT) AMOUNT, INVOICE_NO FROM MaritimesLive..INVOICE_DETAILS(nolock) WHERE ELEMENT_TYPE = 70 AND SUB_ELEMENT_TYPE IN ('VL' ,'VLI') GROUP BY INVOICE_NO
		) VLI ON i.INVOICE_NO = VLI.INVOICE_NO -- For VL/AC Fee
	LEFT OUTER JOIN 
		(
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from MaritimesLive..INVOICE_DETAILS (nolock)
			
		) CDW ON i.INVOICE_NO = CDW.INVOICE_NO AND CDW.ELEMENT_TYPE = 60 AND CDW.SUB_ELEMENT_TYPE = 'CDW' -- For CDW
	LEFT OUTER JOIN (
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from MaritimesLive..INVOICE_DETAILS (nolock)
		) PAP ON i.INVOICE_NO = PAP.INVOICE_NO AND PAP.ELEMENT_TYPE = 60 AND PAP.SUB_ELEMENT_TYPE = 'PAP' -- For CDW
	LEFT OUTER JOIN (
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from MaritimesLive..INVOICE_DETAILS (nolock)
		) WT ON i.INVOICE_NO = WT.INVOICE_NO AND WT.ELEMENT_TYPE = 70 AND WT.SUB_ELEMENT_TYPE = 'WT' -- For CDW
	left join MaritimesLive..EBILLING_INVOICE_DATA o(nolock) on C.DAC_ENTRY_ID = o.ENTRY_ID and o.OTHER_CHARGES_DESC like '%tire%'
	WHERE 	
	A.STATUS_CODE = 4 AND A.DEBITOR_CODE > 0 
	and ((@DebitorCodes = 'ALL') or (d.SUV_DEBITOR_OF in (Select Data from dbo.SplitByDelimiter(@DebitorCodes,',') where Data != 'ALL')))
	AND DATEADD(SECOND, A.CHECK_IN_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_IN_DATE,112))) BETWEEN @BEGIN AND @End
	AND A.CHECK_IN_DATE!='00000000'  	
	UNION 	
	SELECT DISTINCT 'From_RMS' Source, 'BC' as PROVINCE, 
	Case when C.DAC_Claim_Type = 0 then 'Collision'	when C.DAC_Claim_Type = 1 then 'Comprehensive' when C.DAC_Claim_Type = 2 then 'Theft' end ClaimType,
	case when CHARINDEX('Stolen' ,DAC_GARAGE_NAME)> 0 OR CHARINDEX('Theft',DAC_GARAGE_NAME)> 0 Or CHARINDEX('Loss',DAC_GARAGE_NAME)> 0 Or CHARINDEX('Write',DAC_GARAGE_NAME)> 0  then DAC_GARAGE_NAME when DAC_TOTAL_LOSS ='Y' then  'OTAL_LOSS' when  DAC_Claim_Type =2 then 'Theft' else '' END ExtentOfLoss,
	ltrim(rtrim(G.GARAGE_NAME)) as GARAGE_NAME, --, GARAGE_NO 
	(Select top 1 Debitor_Name from #temp_debitors where #temp_debitors.SUV_DEBITOR_OF = d.SUV_DEBITOR_OF) as ParentInsurerName,
	D.DEBITOR_NAME AS [INS COMPANY NAME],
	case when cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) > 0 then 'Y' else 'N' end as IsRewrite,
    cast(cast(A.Agreement_No as bigint) as varchar(15)) as AgreementNo,
    cast(cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) as varchar(15))  as ParentAgreementNo, 
	case when i.INVOICE_DATE between '20100101' and '20491231' then  convert(varchar(10),CONVERT(datetime, i.INVOICE_DATE,112),120) when DAC_INVOICE_DATE between '20100101' and '20491231' then  convert(varchar(10),CONVERT(datetime, C.DAC_INVOICE_DATE,112),120) end InvoiceDate,
	i.INVOICE_NO InvoiceNo,
    C.DAC_INS_CLAIM as CLAIM_NO,
    C.DAC_POLICY as POLICY_NO,
    A.DRIVER_FIRST_NAME + ' ' + A.DRIVER_LAST_NAME as Renter_Name,
    case when A.SOLD_DAYS != 0 then cast(round(i.RENTAL/A.SOLD_DAYS,2) as numeric(36,2)) end  AvgRate,
    A.SOLD_DAYS AS [RENTAL_DAYS], 
    i.RENTAL as Rental_Sum, 
    case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.TFFS,0) else ISNULL(VLI.AMOUNT,0) end AS VehicleLicenseFee,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(o.OTHER_CHARGES,0)  else ISNULL(WT.AMOUNT,0) end AS  WinterTireFee,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.KILOMETERS,0) else ISNULL(i.KM,0) end AS  KilometerCharges,
	ISNULL(i.DROF_OFF,0) AS DropFees,
	ISNULL(CDW.AMOUNT,0) AS CollisionDamageWaiver,
	ISNULL(PAP.AMOUNT,0) AS PracticleAssistanceProgram,
	case  when C.DAC_ARS_WEB ='Y' then h.SUB_TOTAL else i.SUBTOTAL end AS SubTotal,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.PST,0) else ISNULL(i.SERVICE_FEE,0) end ProvincialTaxes,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.GST+ h.HST,0) else ISNULL(i.VAT,0) end FederalTaxes,
	case when C.DAC_ARS_WEB ='Y' then h.TOTAL else i.INVOICE_AMOUNT end TotalFees,
	i.AMOUNT_PID as Paid_Amount,
	i.BALANCE as Balance,
	case when DAC_DATE_OF_LOSS between '20100101' and '20491231' then convert(varchar(10),CONVERT(datetime, C.DAC_DATE_OF_LOSS,112),120) end DateOfLoss,
	case when A.CHECK_IN_DATE between '20100101' and '20491231'  then (SELECT DATENAME(DW, CAST(A.CHECK_IN_DATE AS datetime))) end Day_of_Week,
	case when A.CHECK_IN_DATE between '20100101' and '20491231'  then (SELECT DATENAME(month, CAST(A.CHECK_IN_DATE AS datetime))) end Month,
	case when adj.DAA_FULL_NAME IS NULL then 'UNKNOWN' else adj.DAA_FULL_NAME end AdjusterName,
	ISNULL(AUTHDAY, 0) AS [TOTAL AUTHOR DAYS], 
	ISNULL(Auth.AUTHORRATE, 0) As AuthRate,
	DATEADD(SECOND, A.CHECK_OUT_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_OUT_DATE,112))) as Rental_Out,
	DATEADD(SECOND, A.CHECK_IN_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_IN_DATE,112))) as Rental_In,
	DAC_DRIVABLE AS DRIVABLE, 
	C.DAC_MAKE as ICC_Make, 
	C.DAC_MODEL as ICC_Model, 
	C.DAC_YEAR as ICC_Vehicle_Year,
	C.DAC_RENTAL_MAKE as CarManufacturer,
    C.DAC_RENTAL_MODEL as CarModel,
    C.DAC_RENTAL_YEAR as VehicleYear,
    ISNULL(ISNULL(C.DAC_RENTAL_CAR_GROUP, C.VEHICLE_CLASS), C.VEHICLE_CLASS) as ICC_Category,
    C.DAC_RENTAL_CAR_CLASS as Category,
    SB.Unit_No as CarCategory,
    case when C.DAC_RENTAL_CHECK_OUT_BRANCH_CODE > 0 then C.DAC_RENTAL_CHECK_OUT_BRANCH_CODE else DAC_LOCATION_CODE end BranchCode,
    B.BRANACH_NAME as BranchName,
    B.CITY as BranchCity,
    B.STATE as BranchState,
    ISNULL(VB.BannerName,'') as BannerName,
    case when YN.PREFERRED_YN IS NOT NULL and YN.PREFERRED_YN = 1 then 'YES' else 'NO' end as Preferred_Garages, 
	BRANACH_NAME AS [LOCATION NAME], B.STREET [LOCATION ADDRESS], 
	DAC_GARAGE_ADDRESS AS [GARAGE ADDRESS]
	FROM BCLive.DBO.AGREEMENTS A (NOLOCK) 
	LEFT JOIN (
		Select top 1 * from (
			Select FATHER_AGREEMENT_NO, SON_AGREEMENT_NUMBER, UNIT_NO from BCLive..SUBAGREEMENTS SB (NOLOCK) 
		) SB order by SON_AGREEMENT_NUMBER desc
	)  SB on SB.FATHER_AGREEMENT_NO = A.Agreement_No
	INNER JOIN #tempDataRewriteBC rw on rw.AGREEMENT_NO = a.AGREEMENT_NO	
	LEFT JOIN BCLive.DBO.BRANCHES B (NOLOCK) ON B.BRANACH_CODE = A.CHECK_OUT_BRANACH 
	LEFT JOIN BCLive..DEBITORS D (NOLOCK) ON D.DEBITOR_CODE = A.DEBITOR_CODE
	LEFT JOIN BCLive.DBO.REPAIRED_AT R (NOLOCK) ON A.AGREEMENT_NO = R.AGREEMENT_NO and R.BODY_SHOP > 0
	LEFT JOIN BCLive.DBO.GARAGES G (NOLOCK) ON G.GARAGE_NO = R.BODY_SHOP 	
	LEFT JOIN Carpro_App..vwBanner VB (NOLOCK) ON VB.BannerCode = G.GARAGES_ACCOUNT_GROUP
	left join Carpro_App..GARAGES_PREFERRED_YN YN on D.SUV_DEBITOR_OF = YN.DEBITOR_CODE and G.GARAGE_NO = YN.GARAGE_CODE 
	LEFT JOIN OntarioLive..DA_CLAIMS C (NOLOCK) ON C.DAC_AGREEMENT_NUMBER = A.AGREEMENT_NO
	Left join OntarioLive..EBILLING_INVOICE_DATA H(nolock) on C.DAC_ENTRY_ID = H.ENTRY_ID
	Left join OntarioLive..DA_ADJUSTER adj (NOLOCK) on C.DAC_COMPANY_ADJUSTER_ID = adj.DAA_ENTRY_ID
	LEFT JOIN (
		SELECT DCA_CLAIM_ID, AGREEMENT_NO, SUM(DCA_A_DAYS) AS AUTHDAY, 
		SUM(DAC_FINAL_TOTAL) AS DAC_FINAL_TOTAL, AVG(DCA_AUTHOR_RATE) AS AUTHORRATE 
		FROM ONTARIOLIVE..DA_AUTHORIZATION (NOLOCK)  WHERE DCA_BILL_TO = 1  and DCA_AUTHOR_FROM_DATE >= '20100101' and DCA_AUTHOR_TO_DATE <= '20501231'
		GROUP BY DCA_CLAIM_ID, AGREEMENT_NO 
	) Auth ON C.DAC_ENTRY_ID = Auth.DCA_CLAIM_ID and Auth.AGREEMENT_NO = A.AGREEMENT_NO
	--left join BCLive..VEHICLE_CLASSES v(nolock) on v.CLASS = case when C.DAC_RENTAL_CAR_CLASS > '' then C.DAC_RENTAL_CAR_CLASS else C.VEHICLE_CLASS END
	LEFT join BCLive..INVOICES (nolock) i on ISNULL( A.AGREEMENT_NO, C.DAC_AGREEMENT_NUMBER)= i.AGREEMENT_NO and D.DEBITOR_CODE = I.DEBITOR_NO and I.INV_STATUS !=9 and i.INVOICE_TYPE = 'C'
	LEFT OUTER JOIN
		(
			SELECT SUM(AMOUNT) AMOUNT, INVOICE_NO FROM BCLive..INVOICE_DETAILS(nolock) WHERE ELEMENT_TYPE = 70 AND SUB_ELEMENT_TYPE IN ('VL' ,'VLI') GROUP BY INVOICE_NO
		) VLI ON i.INVOICE_NO = VLI.INVOICE_NO -- For VL/AC Fee
	LEFT OUTER JOIN 
		(
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from BCLive..INVOICE_DETAILS (nolock)
			
		) CDW ON i.INVOICE_NO = CDW.INVOICE_NO AND CDW.ELEMENT_TYPE = 60 AND CDW.SUB_ELEMENT_TYPE = 'CDW' -- For CDW
	LEFT OUTER JOIN (
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from BCLive..INVOICE_DETAILS (nolock)
		) PAP ON i.INVOICE_NO = PAP.INVOICE_NO AND PAP.ELEMENT_TYPE = 60 AND PAP.SUB_ELEMENT_TYPE = 'PAP' -- For CDW
	LEFT OUTER JOIN (
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from Ontariolive..INVOICE_DETAILS (nolock)
		) WT ON i.INVOICE_NO = WT.INVOICE_NO AND WT.ELEMENT_TYPE = 70 AND WT.SUB_ELEMENT_TYPE = 'WT' -- For CDW
	left join OntarioLive..EBILLING_INVOICE_DATA o(nolock) on C.DAC_ENTRY_ID = o.ENTRY_ID and o.OTHER_CHARGES_DESC like '%tire%'
	WHERE 	
	A.STATUS_CODE = 4 AND A.DEBITOR_CODE > 0 
	and ((@DebitorCodes = 'ALL') or (d.SUV_DEBITOR_OF in (Select Data from dbo.SplitByDelimiter(@DebitorCodes,',') where Data != 'ALL')))
	AND DATEADD(SECOND, A.CHECK_IN_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_IN_DATE,112))) BETWEEN @BEGIN AND @End
	AND A.CHECK_IN_DATE!='00000000' 
	UNION 	
	SELECT DISTINCT 'From_RMS' Source, 'SK' as PROVINCE, 
	Case when C.DAC_Claim_Type = 0 then 'Collision'	when C.DAC_Claim_Type = 1 then 'Comprehensive' when C.DAC_Claim_Type = 2 then 'Theft' end ClaimType,
	case when CHARINDEX('Stolen' ,DAC_GARAGE_NAME)> 0 OR CHARINDEX('Theft',DAC_GARAGE_NAME)> 0 Or CHARINDEX('Loss',DAC_GARAGE_NAME)> 0 Or CHARINDEX('Write',DAC_GARAGE_NAME)> 0  then DAC_GARAGE_NAME when DAC_TOTAL_LOSS ='Y' then  'OTAL_LOSS' when  DAC_Claim_Type =2 then 'Theft' else '' END ExtentOfLoss,
	ltrim(rtrim(G.GARAGE_NAME)) as GARAGE_NAME, --, GARAGE_NO 
	(Select top 1 Debitor_Name from #temp_debitors where #temp_debitors.SUV_DEBITOR_OF = d.SUV_DEBITOR_OF) as ParentInsurerName,
	D.DEBITOR_NAME AS [INS COMPANY NAME],
	case when cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) > 0 then 'Y' else 'N' end as IsRewrite,
    cast(cast(A.Agreement_No as bigint) as varchar(15)) as AgreementNo,
    cast(cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) as varchar(15))  as ParentAgreementNo, 
	case when i.INVOICE_DATE between '20100101' and '20491231' then  convert(varchar(10),CONVERT(datetime, i.INVOICE_DATE,112),120) when DAC_INVOICE_DATE between '20100101' and '20491231' then  convert(varchar(10),CONVERT(datetime, C.DAC_INVOICE_DATE,112),120) end InvoiceDate,
	i.INVOICE_NO InvoiceNo,
    C.DAC_INS_CLAIM as CLAIM_NO,
    C.DAC_POLICY as POLICY_NO,
    A.DRIVER_FIRST_NAME + ' ' + A.DRIVER_LAST_NAME as Renter_Name,
    case when A.SOLD_DAYS != 0 then cast(round(i.RENTAL/A.SOLD_DAYS,2) as numeric(36,2)) end  AvgRate,
    A.SOLD_DAYS AS [RENTAL_DAYS], 
    i.RENTAL as Rental_Sum, 
    case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.TFFS,0) else ISNULL(VLI.AMOUNT,0) end AS VehicleLicenseFee,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(o.OTHER_CHARGES,0)  else ISNULL(WT.AMOUNT,0) end AS  WinterTireFee,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.KILOMETERS,0) else ISNULL(i.KM,0) end AS  KilometerCharges,
	ISNULL(i.DROF_OFF,0) AS DropFees,
	ISNULL(CDW.AMOUNT,0) AS CollisionDamageWaiver,
	ISNULL(PAP.AMOUNT,0) AS PracticleAssistanceProgram,
	case  when C.DAC_ARS_WEB ='Y' then h.SUB_TOTAL else i.SUBTOTAL end AS SubTotal,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.PST,0) else ISNULL(i.SERVICE_FEE,0) end ProvincialTaxes,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.GST+ h.HST,0) else ISNULL(i.VAT,0) end FederalTaxes,
	case when C.DAC_ARS_WEB ='Y' then h.TOTAL else i.INVOICE_AMOUNT end TotalFees,
	i.AMOUNT_PID as Paid_Amount,
	i.BALANCE as Balance,
	case when DAC_DATE_OF_LOSS between '20100101' and '20491231' then convert(varchar(10),CONVERT(datetime, C.DAC_DATE_OF_LOSS,112),120) end DateOfLoss,
	case when A.CHECK_IN_DATE between '20100101' and '20491231'  then (SELECT DATENAME(DW, CAST(A.CHECK_IN_DATE AS datetime))) end Day_of_Week,
	case when A.CHECK_IN_DATE between '20100101' and '20491231'  then (SELECT DATENAME(month, CAST(A.CHECK_IN_DATE AS datetime))) end Month,
	case when adj.DAA_FULL_NAME IS NULL then 'UNKNOWN' else adj.DAA_FULL_NAME end AdjusterName,
	ISNULL(AUTHDAY, 0) AS [TOTAL AUTHOR DAYS], 
	ISNULL(Auth.AUTHORRATE, 0) As AuthRate,
	DATEADD(SECOND, A.CHECK_OUT_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_OUT_DATE,112))) as Rental_Out,
	DATEADD(SECOND, A.CHECK_IN_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_IN_DATE,112))) as Rental_In,
	DAC_DRIVABLE AS DRIVABLE, 
	C.DAC_MAKE as ICC_Make, 
	C.DAC_MODEL as ICC_Model, 
	C.DAC_YEAR as ICC_Vehicle_Year,
	C.DAC_RENTAL_MAKE as CarManufacturer,
    C.DAC_RENTAL_MODEL as CarModel,
    C.DAC_RENTAL_YEAR as VehicleYear,
    ISNULL(ISNULL(C.DAC_RENTAL_CAR_GROUP, C.VEHICLE_CLASS), C.VEHICLE_CLASS) as ICC_Category,
    C.DAC_RENTAL_CAR_CLASS as Category,
    SB.Unit_No as CarCategory,
    case when C.DAC_RENTAL_CHECK_OUT_BRANCH_CODE > 0 then C.DAC_RENTAL_CHECK_OUT_BRANCH_CODE else DAC_LOCATION_CODE end BranchCode,
    B.BRANACH_NAME as BranchName,
    B.CITY as BranchCity,
    B.STATE as BranchState,
    ISNULL(VB.BannerName,'') as BannerName,
    case when YN.PREFERRED_YN IS NOT NULL and YN.PREFERRED_YN = 1 then 'YES' else 'NO' end as Preferred_Garages, 
	BRANACH_NAME AS [LOCATION NAME], B.STREET [LOCATION ADDRESS], 
	DAC_GARAGE_ADDRESS AS [GARAGE ADDRESS]
	FROM SaskatchewanLive2.DBO.AGREEMENTS A (NOLOCK) 
	LEFT JOIN (
		Select top 1 * from (
			Select FATHER_AGREEMENT_NO, SON_AGREEMENT_NUMBER, UNIT_NO from SaskatchewanLive2..SUBAGREEMENTS SB (NOLOCK) 
		) SB order by SON_AGREEMENT_NUMBER desc
	)  SB on SB.FATHER_AGREEMENT_NO = A.Agreement_No
	INNER JOIN #tempDataRewriteSK rw on rw.AGREEMENT_NO = a.AGREEMENT_NO	
	LEFT JOIN SaskatchewanLive2.DBO.BRANCHES B (NOLOCK) ON B.BRANACH_CODE = A.CHECK_OUT_BRANACH 
	LEFT JOIN SaskatchewanLive2..DEBITORS D (NOLOCK) ON D.DEBITOR_CODE = A.DEBITOR_CODE
	LEFT JOIN SaskatchewanLive2.DBO.REPAIRED_AT R (NOLOCK) ON A.AGREEMENT_NO = R.AGREEMENT_NO and R.BODY_SHOP > 0
	LEFT JOIN SaskatchewanLive2.DBO.GARAGES G (NOLOCK) ON G.GARAGE_NO = R.BODY_SHOP
	LEFT JOIN Carpro_App..vwBanner VB (NOLOCK) ON VB.BannerCode = G.GARAGES_ACCOUNT_GROUP
	left join Carpro_App..GARAGES_PREFERRED_YN YN on D.SUV_DEBITOR_OF = YN.DEBITOR_CODE and G.GARAGE_NO = YN.GARAGE_CODE 
	LEFT JOIN OntarioLive..DA_CLAIMS C (NOLOCK) ON C.DAC_AGREEMENT_NUMBER = A.AGREEMENT_NO
	Left join OntarioLive..EBILLING_INVOICE_DATA H(nolock) on C.DAC_ENTRY_ID = H.ENTRY_ID
	Left join OntarioLive..DA_ADJUSTER adj (NOLOCK) on C.DAC_COMPANY_ADJUSTER_ID = adj.DAA_ENTRY_ID
	LEFT JOIN (
		SELECT DCA_CLAIM_ID, AGREEMENT_NO, SUM(DCA_A_DAYS) AS AUTHDAY, 
		SUM(DAC_FINAL_TOTAL) AS DAC_FINAL_TOTAL, AVG(DCA_AUTHOR_RATE) AS AUTHORRATE 
		FROM ONTARIOLIVE..DA_AUTHORIZATION (NOLOCK)  WHERE DCA_BILL_TO = 1  and DCA_AUTHOR_FROM_DATE >= '20100101' and DCA_AUTHOR_TO_DATE <= '20501231'
		GROUP BY DCA_CLAIM_ID, AGREEMENT_NO
	) Auth ON C.DAC_ENTRY_ID = Auth.DCA_CLAIM_ID and Auth.AGREEMENT_NO = A.AGREEMENT_NO
	--left join SaskatchewanLive2..VEHICLE_CLASSES v(nolock) on v.CLASS = case when C.DAC_RENTAL_CAR_CLASS > '' then C.DAC_RENTAL_CAR_CLASS else C.VEHICLE_CLASS END
	LEFT join SaskatchewanLive2..INVOICES (nolock) i on ISNULL( A.AGREEMENT_NO, C.DAC_AGREEMENT_NUMBER)= i.AGREEMENT_NO and D.DEBITOR_CODE = I.DEBITOR_NO and I.INV_STATUS !=9 and i.INVOICE_TYPE = 'C'
	LEFT OUTER JOIN
		(
			SELECT SUM(AMOUNT) AMOUNT, INVOICE_NO FROM SaskatchewanLive2..INVOICE_DETAILS(nolock) WHERE ELEMENT_TYPE = 70 AND SUB_ELEMENT_TYPE IN ('VL' ,'VLI') GROUP BY INVOICE_NO
		) VLI ON i.INVOICE_NO = VLI.INVOICE_NO -- For VL/AC Fee
	LEFT OUTER JOIN 
		(
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from SaskatchewanLive2..INVOICE_DETAILS (nolock)
			
		) CDW ON i.INVOICE_NO = CDW.INVOICE_NO AND CDW.ELEMENT_TYPE = 60 AND CDW.SUB_ELEMENT_TYPE = 'CDW' -- For CDW
	LEFT OUTER JOIN (
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from SaskatchewanLive2..INVOICE_DETAILS (nolock)
		) PAP ON i.INVOICE_NO = PAP.INVOICE_NO AND PAP.ELEMENT_TYPE = 60 AND PAP.SUB_ELEMENT_TYPE = 'PAP' -- For CDW
	LEFT OUTER JOIN (
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from SaskatchewanLive2..INVOICE_DETAILS (nolock)
		) WT ON i.INVOICE_NO = WT.INVOICE_NO AND WT.ELEMENT_TYPE = 70 AND WT.SUB_ELEMENT_TYPE = 'WT' -- For CDW
	left join SaskatchewanLive2..EBILLING_INVOICE_DATA o(nolock) on C.DAC_ENTRY_ID = o.ENTRY_ID and o.OTHER_CHARGES_DESC like '%tire%'
	WHERE 	
	A.STATUS_CODE = 4 AND A.DEBITOR_CODE > 0 
	and ((@DebitorCodes = 'ALL') or (d.SUV_DEBITOR_OF in (Select Data from dbo.SplitByDelimiter(@DebitorCodes,',') where Data != 'ALL')))
	AND DATEADD(SECOND, A.CHECK_IN_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_IN_DATE,112))) BETWEEN @BEGIN AND @End
	AND A.CHECK_IN_DATE!='00000000'  	
	UNION 	
	SELECT DISTINCT 'From_RMS' Source, 'NL' as PROVINCE, 
	Case when C.DAC_Claim_Type = 0 then 'Collision'	when C.DAC_Claim_Type = 1 then 'Comprehensive' when C.DAC_Claim_Type = 2 then 'Theft' end ClaimType,
	case when CHARINDEX('Stolen' ,DAC_GARAGE_NAME)> 0 OR CHARINDEX('Theft',DAC_GARAGE_NAME)> 0 Or CHARINDEX('Loss',DAC_GARAGE_NAME)> 0 Or CHARINDEX('Write',DAC_GARAGE_NAME)> 0  then DAC_GARAGE_NAME when DAC_TOTAL_LOSS ='Y' then  'OTAL_LOSS' when  DAC_Claim_Type =2 then 'Theft' else '' END ExtentOfLoss,
	ltrim(rtrim(G.GARAGE_NAME)) as GARAGE_NAME, --, GARAGE_NO
	(Select top 1 Debitor_Name from #temp_debitors where #temp_debitors.SUV_DEBITOR_OF = d.SUV_DEBITOR_OF) as ParentInsurerName, 
	D.DEBITOR_NAME AS [INS COMPANY NAME],
	case when cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) > 0 then 'Y' else 'N' end as IsRewrite,
    cast(cast(A.Agreement_No as bigint) as varchar(15)) as AgreementNo,
    cast(cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) as varchar(15))  as ParentAgreementNo, 
	case when i.INVOICE_DATE between '20100101' and '20491231' then  convert(varchar(10),CONVERT(datetime, i.INVOICE_DATE,112),120) when DAC_INVOICE_DATE between '20100101' and '20491231' then  convert(varchar(10),CONVERT(datetime, C.DAC_INVOICE_DATE,112),120) end InvoiceDate,
	i.INVOICE_NO InvoiceNo,
    C.DAC_INS_CLAIM as CLAIM_NO,
    C.DAC_POLICY as POLICY_NO,
    A.DRIVER_FIRST_NAME + ' ' + A.DRIVER_LAST_NAME as Renter_Name,
    case when A.SOLD_DAYS != 0 then cast(round(i.RENTAL/A.SOLD_DAYS,2) as numeric(36,2)) end  AvgRate,
    A.SOLD_DAYS AS [RENTAL_DAYS], 
    i.RENTAL as Rental_Sum, 
    case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.TFFS,0) else ISNULL(VLI.AMOUNT,0) end AS VehicleLicenseFee,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(o.OTHER_CHARGES,0)  else ISNULL(WT.AMOUNT,0) end AS  WinterTireFee,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.KILOMETERS,0) else ISNULL(i.KM,0) end AS  KilometerCharges,
	ISNULL(i.DROF_OFF,0) AS DropFees,
	ISNULL(CDW.AMOUNT,0) AS CollisionDamageWaiver,
	ISNULL(PAP.AMOUNT,0) AS PracticleAssistanceProgram,
	case  when C.DAC_ARS_WEB ='Y' then h.SUB_TOTAL else i.SUBTOTAL end AS SubTotal,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.PST,0) else ISNULL(i.SERVICE_FEE,0) end ProvincialTaxes,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.GST+ h.HST,0) else ISNULL(i.VAT,0) end FederalTaxes,
	case when C.DAC_ARS_WEB ='Y' then h.TOTAL else i.INVOICE_AMOUNT end TotalFees,
	i.AMOUNT_PID as Paid_Amount,
	i.BALANCE as Balance,
	case when DAC_DATE_OF_LOSS between '20100101' and '20491231' then convert(varchar(10),CONVERT(datetime, C.DAC_DATE_OF_LOSS,112),120) end DateOfLoss,
	case when A.CHECK_IN_DATE between '20100101' and '20491231'  then (SELECT DATENAME(DW, CAST(A.CHECK_IN_DATE AS datetime))) end Day_of_Week,
	case when A.CHECK_IN_DATE between '20100101' and '20491231'  then (SELECT DATENAME(month, CAST(A.CHECK_IN_DATE AS datetime))) end Month,
	case when adj.DAA_FULL_NAME IS NULL then 'UNKNOWN' else adj.DAA_FULL_NAME end AdjusterName,
	ISNULL(AUTHDAY, 0) AS [TOTAL AUTHOR DAYS], 
	ISNULL(Auth.AUTHORRATE, 0) As AuthRate,
	DATEADD(SECOND, A.CHECK_OUT_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_OUT_DATE,112))) as Rental_Out,
	DATEADD(SECOND, A.CHECK_IN_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_IN_DATE,112))) as Rental_In,
	DAC_DRIVABLE AS DRIVABLE, 
	C.DAC_MAKE as ICC_Make, 
	C.DAC_MODEL as ICC_Model, 
	C.DAC_YEAR as ICC_Vehicle_Year,
	C.DAC_RENTAL_MAKE as CarManufacturer,
    C.DAC_RENTAL_MODEL as CarModel,
    C.DAC_RENTAL_YEAR as VehicleYear,
    ISNULL(ISNULL(C.DAC_RENTAL_CAR_GROUP, C.VEHICLE_CLASS), C.VEHICLE_CLASS) as ICC_Category,
    C.DAC_RENTAL_CAR_CLASS as Category,
    SB.Unit_No as CarCategory,
    case when C.DAC_RENTAL_CHECK_OUT_BRANCH_CODE > 0 then C.DAC_RENTAL_CHECK_OUT_BRANCH_CODE else DAC_LOCATION_CODE end BranchCode,
    B.BRANACH_NAME as BranchName,
    B.CITY as BranchCity,
    B.STATE as BranchState,
    ISNULL(VB.BannerName,'') as BannerName,
    case when YN.PREFERRED_YN IS NOT NULL and YN.PREFERRED_YN = 1 then 'YES' else 'NO' end as Preferred_Garages, 
	BRANACH_NAME AS [LOCATION NAME], B.STREET [LOCATION ADDRESS], 
	DAC_GARAGE_ADDRESS AS [GARAGE ADDRESS]
	FROM NewfoundlandLive2.DBO.AGREEMENTS A (NOLOCK) 
	LEFT JOIN (
		Select top 1 * from (
			Select FATHER_AGREEMENT_NO, SON_AGREEMENT_NUMBER, UNIT_NO from NewfoundlandLive2..SUBAGREEMENTS SB (NOLOCK) 
		) SB order by SON_AGREEMENT_NUMBER desc
	)  SB on SB.FATHER_AGREEMENT_NO = A.Agreement_No
	INNER JOIN #tempDataRewriteNL rw on rw.AGREEMENT_NO = a.AGREEMENT_NO	
	LEFT JOIN NewfoundlandLive2.DBO.BRANCHES B (NOLOCK) ON B.BRANACH_CODE = A.CHECK_OUT_BRANACH 
	LEFT JOIN NewfoundlandLive2..DEBITORS D (NOLOCK) ON D.DEBITOR_CODE = A.DEBITOR_CODE
	LEFT JOIN NewfoundlandLive2.DBO.REPAIRED_AT R (NOLOCK) ON A.AGREEMENT_NO = R.AGREEMENT_NO and R.BODY_SHOP > 0
	LEFT JOIN NewfoundlandLive2.DBO.GARAGES G (NOLOCK) ON G.GARAGE_NO = R.BODY_SHOP 
	LEFT JOIN Carpro_App..vwBanner VB (NOLOCK) ON VB.BannerCode = G.GARAGES_ACCOUNT_GROUP
	left join Carpro_App..GARAGES_PREFERRED_YN YN on D.SUV_DEBITOR_OF = YN.DEBITOR_CODE and G.GARAGE_NO = YN.GARAGE_CODE 
	LEFT JOIN OntarioLive..DA_CLAIMS C (NOLOCK) ON C.DAC_AGREEMENT_NUMBER = A.AGREEMENT_NO	
	Left join OntarioLive..EBILLING_INVOICE_DATA H(nolock) on C.DAC_ENTRY_ID = H.ENTRY_ID
	Left join OntarioLive..DA_ADJUSTER adj (NOLOCK) on C.DAC_COMPANY_ADJUSTER_ID = adj.DAA_ENTRY_ID
	LEFT JOIN (
		SELECT DCA_CLAIM_ID, AGREEMENT_NO, SUM(DCA_A_DAYS) AS AUTHDAY, 
		SUM(DAC_FINAL_TOTAL) AS DAC_FINAL_TOTAL, AVG(DCA_AUTHOR_RATE) AS AUTHORRATE 
		FROM ONTARIOLIVE..DA_AUTHORIZATION (NOLOCK)  WHERE DCA_BILL_TO = 1  and DCA_AUTHOR_FROM_DATE >= '20100101' and DCA_AUTHOR_TO_DATE <= '20501231'
		GROUP BY DCA_CLAIM_ID, AGREEMENT_NO 
	) Auth ON C.DAC_ENTRY_ID = Auth.DCA_CLAIM_ID and Auth.AGREEMENT_NO = A.AGREEMENT_NO
	--left join NewfoundlandLive2..VEHICLE_CLASSES v(nolock) on v.CLASS = case when C.DAC_RENTAL_CAR_CLASS > '' then C.DAC_RENTAL_CAR_CLASS else C.VEHICLE_CLASS END
	LEFT join NewfoundlandLive2..INVOICES (nolock) i on ISNULL( A.AGREEMENT_NO, C.DAC_AGREEMENT_NUMBER)= i.AGREEMENT_NO and D.DEBITOR_CODE = I.DEBITOR_NO and I.INV_STATUS !=9 and i.INVOICE_TYPE = 'C'
	LEFT OUTER JOIN
		(
			SELECT SUM(AMOUNT) AMOUNT, INVOICE_NO FROM NewfoundlandLive2..INVOICE_DETAILS(nolock) WHERE ELEMENT_TYPE = 70 AND SUB_ELEMENT_TYPE IN ('VL' ,'VLI') GROUP BY INVOICE_NO
		) VLI ON i.INVOICE_NO = VLI.INVOICE_NO -- For VL/AC Fee
	LEFT OUTER JOIN 
		(
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from NewfoundlandLive2..INVOICE_DETAILS (nolock)
			
		) CDW ON i.INVOICE_NO = CDW.INVOICE_NO AND CDW.ELEMENT_TYPE = 60 AND CDW.SUB_ELEMENT_TYPE = 'CDW' -- For CDW
	LEFT OUTER JOIN (
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from NewfoundlandLive2..INVOICE_DETAILS (nolock)
		) PAP ON i.INVOICE_NO = PAP.INVOICE_NO AND PAP.ELEMENT_TYPE = 60 AND PAP.SUB_ELEMENT_TYPE = 'PAP' -- For CDW
	LEFT OUTER JOIN (
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from NewfoundlandLive2..INVOICE_DETAILS (nolock)
		) WT ON i.INVOICE_NO = WT.INVOICE_NO AND WT.ELEMENT_TYPE = 70 AND WT.SUB_ELEMENT_TYPE = 'WT' -- For CDW
	left join NewfoundlandLive2..EBILLING_INVOICE_DATA o(nolock) on C.DAC_ENTRY_ID = o.ENTRY_ID and o.OTHER_CHARGES_DESC like '%tire%'
	WHERE 	
	A.STATUS_CODE = 4 AND A.DEBITOR_CODE > 0 
	and ((@DebitorCodes = 'ALL') or (d.SUV_DEBITOR_OF in (Select Data from dbo.SplitByDelimiter(@DebitorCodes,',') where Data != 'ALL')))
	AND DATEADD(SECOND, A.CHECK_IN_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_IN_DATE,112))) BETWEEN @BEGIN AND @End
	AND A.CHECK_IN_DATE!='00000000'  	
	UNION 	
	SELECT DISTINCT 'From_RMS' Source, 'SK' as PROVINCE, 
	Case when C.DAC_Claim_Type = 0 then 'Collision'	when C.DAC_Claim_Type = 1 then 'Comprehensive' when C.DAC_Claim_Type = 2 then 'Theft' end ClaimType,
	case when CHARINDEX('Stolen' ,DAC_GARAGE_NAME)> 0 OR CHARINDEX('Theft',DAC_GARAGE_NAME)> 0 Or CHARINDEX('Loss',DAC_GARAGE_NAME)> 0 Or CHARINDEX('Write',DAC_GARAGE_NAME)> 0  then DAC_GARAGE_NAME when DAC_TOTAL_LOSS ='Y' then  'OTAL_LOSS' when  DAC_Claim_Type =2 then 'Theft' else '' END ExtentOfLoss,
	ltrim(rtrim(G.GARAGE_NAME)) as GARAGE_NAME, --, GARAGE_NO 
	(Select top 1 Debitor_Name from #temp_debitors where #temp_debitors.SUV_DEBITOR_OF = d.SUV_DEBITOR_OF) as ParentInsurerName,
	D.DEBITOR_NAME AS [INS COMPANY NAME],
	case when cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) > 0 then 'Y' else 'N' end as IsRewrite,
    cast(cast(A.Agreement_No as bigint) as varchar(15)) as AgreementNo,
    cast(cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) as varchar(15))  as ParentAgreementNo, 
	case when i.INVOICE_DATE between '20100101' and '20491231' then  convert(varchar(10),CONVERT(datetime, i.INVOICE_DATE,112),120) when DAC_INVOICE_DATE between '20100101' and '20491231' then  convert(varchar(10),CONVERT(datetime, C.DAC_INVOICE_DATE,112),120) end InvoiceDate,
	i.INVOICE_NO InvoiceNo,
    C.DAC_INS_CLAIM as CLAIM_NO,
    C.DAC_POLICY as POLICY_NO,
    A.DRIVER_FIRST_NAME + ' ' + A.DRIVER_LAST_NAME as Renter_Name,
    case when A.SOLD_DAYS != 0 then cast(round(i.RENTAL/A.SOLD_DAYS,2) as numeric(36,2)) end  AvgRate,
    A.SOLD_DAYS AS [RENTAL_DAYS], 
    i.RENTAL as Rental_Sum, 
    case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.TFFS,0) else ISNULL(VLI.AMOUNT,0) end AS VehicleLicenseFee,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(o.OTHER_CHARGES,0)  else ISNULL(WT.AMOUNT,0) end AS  WinterTireFee,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.KILOMETERS,0) else ISNULL(i.KM,0) end AS  KilometerCharges,
	ISNULL(i.DROF_OFF,0) AS DropFees,
	ISNULL(CDW.AMOUNT,0) AS CollisionDamageWaiver,
	ISNULL(PAP.AMOUNT,0) AS PracticleAssistanceProgram,
	case  when C.DAC_ARS_WEB ='Y' then h.SUB_TOTAL else i.SUBTOTAL end AS SubTotal,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.PST,0) else ISNULL(i.SERVICE_FEE,0) end ProvincialTaxes,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.GST+ h.HST,0) else ISNULL(i.VAT,0) end FederalTaxes,
	case when C.DAC_ARS_WEB ='Y' then h.TOTAL else i.INVOICE_AMOUNT end TotalFees,
	i.AMOUNT_PID as Paid_Amount,
	i.BALANCE as Balance,
	case when DAC_DATE_OF_LOSS between '20100101' and '20491231' then convert(varchar(10),CONVERT(datetime, C.DAC_DATE_OF_LOSS,112),120) end DateOfLoss,
	case when A.CHECK_IN_DATE between '20100101' and '20491231'  then (SELECT DATENAME(DW, CAST(A.CHECK_IN_DATE AS datetime))) end Day_of_Week,
	case when A.CHECK_IN_DATE between '20100101' and '20491231'  then (SELECT DATENAME(month, CAST(A.CHECK_IN_DATE AS datetime))) end Month,
	case when adj.DAA_FULL_NAME IS NULL then 'UNKNOWN' else adj.DAA_FULL_NAME end AdjusterName,
	ISNULL(AUTHDAY, 0) AS [TOTAL AUTHOR DAYS], 
	ISNULL(Auth.AUTHORRATE, 0) As AuthRate,
	DATEADD(SECOND, A.CHECK_OUT_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_OUT_DATE,112))) as Rental_Out,
	DATEADD(SECOND, A.CHECK_IN_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_IN_DATE,112))) as Rental_In,
	DAC_DRIVABLE AS DRIVABLE, 
	C.DAC_MAKE as ICC_Make, 
	C.DAC_MODEL as ICC_Model, 
	C.DAC_YEAR as ICC_Vehicle_Year,
	C.DAC_RENTAL_MAKE as CarManufacturer,
    C.DAC_RENTAL_MODEL as CarModel,
    C.DAC_RENTAL_YEAR as VehicleYear,
    ISNULL(ISNULL(C.DAC_RENTAL_CAR_GROUP, C.VEHICLE_CLASS), C.VEHICLE_CLASS) as ICC_Category,
    C.DAC_RENTAL_CAR_CLASS as Category,
    SB.Unit_No as CarCategory,
    case when C.DAC_RENTAL_CHECK_OUT_BRANCH_CODE > 0 then C.DAC_RENTAL_CHECK_OUT_BRANCH_CODE else DAC_LOCATION_CODE end BranchCode,
    B.BRANACH_NAME as BranchName,
    B.CITY as BranchCity,
    B.STATE as BranchState,
    ISNULL(VB.BannerName,'') as BannerName,
    case when YN.PREFERRED_YN IS NOT NULL and YN.PREFERRED_YN = 1 then 'YES' else 'NO' end as Preferred_Garages, 
	BRANACH_NAME AS [LOCATION NAME], B.STREET [LOCATION ADDRESS], 
	DAC_GARAGE_ADDRESS AS [GARAGE ADDRESS]
	FROM SaskatchewanLive.DBO.AGREEMENTS A (NOLOCK) 
	LEFT JOIN (
		Select top 1 * from (
			Select FATHER_AGREEMENT_NO, SON_AGREEMENT_NUMBER, UNIT_NO from SaskatchewanLive..SUBAGREEMENTS SB (NOLOCK) 
		) SB order by SON_AGREEMENT_NUMBER desc
	)  SB on SB.FATHER_AGREEMENT_NO = A.Agreement_No
	INNER JOIN #tempDataRewriteSK2 rw on rw.AGREEMENT_NO = a.AGREEMENT_NO	
	LEFT JOIN SaskatchewanLive.DBO.BRANCHES B (NOLOCK) ON B.BRANACH_CODE = A.CHECK_OUT_BRANACH 
	LEFT JOIN SaskatchewanLive..DEBITORS D (NOLOCK) ON D.DEBITOR_CODE = A.DEBITOR_CODE
	LEFT JOIN SaskatchewanLive.DBO.REPAIRED_AT R (NOLOCK) ON A.AGREEMENT_NO = R.AGREEMENT_NO and R.BODY_SHOP > 0
	LEFT JOIN SaskatchewanLive.DBO.GARAGES G (NOLOCK) ON G.GARAGE_NO = R.BODY_SHOP
	LEFT JOIN Carpro_App..vwBanner VB (NOLOCK) ON VB.BannerCode = G.GARAGES_ACCOUNT_GROUP
	left join Carpro_App..GARAGES_PREFERRED_YN YN on D.SUV_DEBITOR_OF = YN.DEBITOR_CODE and G.GARAGE_NO = YN.GARAGE_CODE 
	LEFT JOIN OntarioLive..DA_CLAIMS C (NOLOCK) ON C.DAC_AGREEMENT_NUMBER = A.AGREEMENT_NO
	Left join OntarioLive..EBILLING_INVOICE_DATA H(nolock) on C.DAC_ENTRY_ID = H.ENTRY_ID
	Left join OntarioLive..DA_ADJUSTER adj (NOLOCK) on C.DAC_COMPANY_ADJUSTER_ID = adj.DAA_ENTRY_ID
	LEFT JOIN (
		SELECT DCA_CLAIM_ID, AGREEMENT_NO, SUM(DCA_A_DAYS) AS AUTHDAY, 
		SUM(DAC_FINAL_TOTAL) AS DAC_FINAL_TOTAL, AVG(DCA_AUTHOR_RATE) AS AUTHORRATE 
		FROM ONTARIOLIVE..DA_AUTHORIZATION (NOLOCK)  WHERE DCA_BILL_TO = 1  and DCA_AUTHOR_FROM_DATE >= '20100101' and DCA_AUTHOR_TO_DATE <= '20501231'
		GROUP BY DCA_CLAIM_ID, AGREEMENT_NO
	) Auth ON C.DAC_ENTRY_ID = Auth.DCA_CLAIM_ID and Auth.AGREEMENT_NO = A.AGREEMENT_NO
	--left join SaskatchewanLive..VEHICLE_CLASSES v(nolock) on v.CLASS = case when C.DAC_RENTAL_CAR_CLASS > '' then C.DAC_RENTAL_CAR_CLASS else C.VEHICLE_CLASS END
	LEFT join SaskatchewanLive..INVOICES (nolock) i on ISNULL( A.AGREEMENT_NO, C.DAC_AGREEMENT_NUMBER)= i.AGREEMENT_NO and D.DEBITOR_CODE = I.DEBITOR_NO and I.INV_STATUS !=9 and i.INVOICE_TYPE = 'C'
	LEFT OUTER JOIN
		(
			SELECT SUM(AMOUNT) AMOUNT, INVOICE_NO FROM SaskatchewanLive..INVOICE_DETAILS(nolock) WHERE ELEMENT_TYPE = 70 AND SUB_ELEMENT_TYPE IN ('VL' ,'VLI') GROUP BY INVOICE_NO
		) VLI ON i.INVOICE_NO = VLI.INVOICE_NO -- For VL/AC Fee
	LEFT OUTER JOIN 
		(
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from SaskatchewanLive..INVOICE_DETAILS (nolock)
			
		) CDW ON i.INVOICE_NO = CDW.INVOICE_NO AND CDW.ELEMENT_TYPE = 60 AND CDW.SUB_ELEMENT_TYPE = 'CDW' -- For CDW
	LEFT OUTER JOIN (
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from SaskatchewanLive..INVOICE_DETAILS (nolock)
		) PAP ON i.INVOICE_NO = PAP.INVOICE_NO AND PAP.ELEMENT_TYPE = 60 AND PAP.SUB_ELEMENT_TYPE = 'PAP' -- For CDW
	LEFT OUTER JOIN (
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from SaskatchewanLive..INVOICE_DETAILS (nolock)
		) WT ON i.INVOICE_NO = WT.INVOICE_NO AND WT.ELEMENT_TYPE = 70 AND WT.SUB_ELEMENT_TYPE = 'WT' -- For CDW
	left join SaskatchewanLive..EBILLING_INVOICE_DATA o(nolock) on C.DAC_ENTRY_ID = o.ENTRY_ID and o.OTHER_CHARGES_DESC like '%tire%'
	WHERE 	
	A.STATUS_CODE = 4 AND A.DEBITOR_CODE > 0 
	and ((@DebitorCodes = 'ALL') or (d.SUV_DEBITOR_OF in (Select Data from dbo.SplitByDelimiter(@DebitorCodes,',') where Data != 'ALL')))
	AND DATEADD(SECOND, A.CHECK_IN_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_IN_DATE,112))) BETWEEN @BEGIN AND @End
	AND A.CHECK_IN_DATE!='00000000'  	
	UNION 	
	SELECT DISTINCT 'From_RMS' Source, 'NL' as PROVINCE, 
	Case when C.DAC_Claim_Type = 0 then 'Collision'	when C.DAC_Claim_Type = 1 then 'Comprehensive' when C.DAC_Claim_Type = 2 then 'Theft' end ClaimType,
	case when CHARINDEX('Stolen' ,DAC_GARAGE_NAME)> 0 OR CHARINDEX('Theft',DAC_GARAGE_NAME)> 0 Or CHARINDEX('Loss',DAC_GARAGE_NAME)> 0 Or CHARINDEX('Write',DAC_GARAGE_NAME)> 0  then DAC_GARAGE_NAME when DAC_TOTAL_LOSS ='Y' then  'OTAL_LOSS' when  DAC_Claim_Type =2 then 'Theft' else '' END ExtentOfLoss,
	ltrim(rtrim(G.GARAGE_NAME)) as GARAGE_NAME, --, GARAGE_NO 
	(Select top 1 Debitor_Name from #temp_debitors where #temp_debitors.SUV_DEBITOR_OF = d.SUV_DEBITOR_OF) as ParentInsurerName,
	D.DEBITOR_NAME AS [INS COMPANY NAME],
	case when cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) > 0 then 'Y' else 'N' end as IsRewrite,
    cast(cast(A.Agreement_No as bigint) as varchar(15)) as AgreementNo,
    cast(cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) as varchar(15))  as ParentAgreementNo, 
	case when i.INVOICE_DATE between '20100101' and '20491231' then  convert(varchar(10),CONVERT(datetime, i.INVOICE_DATE,112),120) when DAC_INVOICE_DATE between '20100101' and '20491231' then  convert(varchar(10),CONVERT(datetime, C.DAC_INVOICE_DATE,112),120) end InvoiceDate,
	i.INVOICE_NO InvoiceNo,
    C.DAC_INS_CLAIM as CLAIM_NO,
    C.DAC_POLICY as POLICY_NO,
    A.DRIVER_FIRST_NAME + ' ' + A.DRIVER_LAST_NAME as Renter_Name,
    case when A.SOLD_DAYS != 0 then cast(round(i.RENTAL/A.SOLD_DAYS,2) as numeric(36,2)) end  AvgRate,
    A.SOLD_DAYS AS [RENTAL_DAYS], 
    i.RENTAL as Rental_Sum, 
    case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.TFFS,0) else ISNULL(VLI.AMOUNT,0) end AS VehicleLicenseFee,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(o.OTHER_CHARGES,0)  else ISNULL(WT.AMOUNT,0) end AS  WinterTireFee,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.KILOMETERS,0) else ISNULL(i.KM,0) end AS  KilometerCharges,
	ISNULL(i.DROF_OFF,0) AS DropFees,
	ISNULL(CDW.AMOUNT,0) AS CollisionDamageWaiver,
	ISNULL(PAP.AMOUNT,0) AS PracticleAssistanceProgram,
	case  when C.DAC_ARS_WEB ='Y' then h.SUB_TOTAL else i.SUBTOTAL end AS SubTotal,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.PST,0) else ISNULL(i.SERVICE_FEE,0) end ProvincialTaxes,
	case  when C.DAC_ARS_WEB ='Y' then ISNULL(h.GST+ h.HST,0) else ISNULL(i.VAT,0) end FederalTaxes,
	case when C.DAC_ARS_WEB ='Y' then h.TOTAL else i.INVOICE_AMOUNT end TotalFees,
	i.AMOUNT_PID as Paid_Amount,
	i.BALANCE as Balance,
	case when DAC_DATE_OF_LOSS between '20100101' and '20491231' then convert(varchar(10),CONVERT(datetime, C.DAC_DATE_OF_LOSS,112),120) end DateOfLoss,
	case when A.CHECK_IN_DATE between '20100101' and '20491231'  then (SELECT DATENAME(DW, CAST(A.CHECK_IN_DATE AS datetime))) end Day_of_Week,
	case when A.CHECK_IN_DATE between '20100101' and '20491231'  then (SELECT DATENAME(month, CAST(A.CHECK_IN_DATE AS datetime))) end Month,
	case when adj.DAA_FULL_NAME IS NULL then 'UNKNOWN' else adj.DAA_FULL_NAME end AdjusterName,
	ISNULL(AUTHDAY, 0) AS [TOTAL AUTHOR DAYS], 
	ISNULL(Auth.AUTHORRATE, 0) As AuthRate,
	DATEADD(SECOND, A.CHECK_OUT_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_OUT_DATE,112))) as Rental_Out,
	DATEADD(SECOND, A.CHECK_IN_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_IN_DATE,112))) as Rental_In,
	DAC_DRIVABLE AS DRIVABLE, 
	C.DAC_MAKE as ICC_Make, 
	C.DAC_MODEL as ICC_Model, 
	C.DAC_YEAR as ICC_Vehicle_Year,
	C.DAC_RENTAL_MAKE as CarManufacturer,
    C.DAC_RENTAL_MODEL as CarModel,
    C.DAC_RENTAL_YEAR as VehicleYear,
    ISNULL(ISNULL(C.DAC_RENTAL_CAR_GROUP, C.VEHICLE_CLASS), C.VEHICLE_CLASS) as ICC_Category,
    C.DAC_RENTAL_CAR_CLASS as Category,
    SB.Unit_No as CarCategory,
    case when C.DAC_RENTAL_CHECK_OUT_BRANCH_CODE > 0 then C.DAC_RENTAL_CHECK_OUT_BRANCH_CODE else DAC_LOCATION_CODE end BranchCode,
    B.BRANACH_NAME as BranchName,
    B.CITY as BranchCity,
    B.STATE as BranchState,
    ISNULL(VB.BannerName,'') as BannerName,
    case when YN.PREFERRED_YN IS NOT NULL and YN.PREFERRED_YN = 1 then 'YES' else 'NO' end as Preferred_Garages, 
	BRANACH_NAME AS [LOCATION NAME], B.STREET [LOCATION ADDRESS], 
	DAC_GARAGE_ADDRESS AS [GARAGE ADDRESS]
	FROM NewfoundlandLive.DBO.AGREEMENTS A (NOLOCK) 
	LEFT JOIN (
		Select top 1 * from (
			Select FATHER_AGREEMENT_NO, SON_AGREEMENT_NUMBER, UNIT_NO from SaskatchewanLive..SUBAGREEMENTS SB (NOLOCK) 
		) SB order by SON_AGREEMENT_NUMBER desc
	)  SB on SB.FATHER_AGREEMENT_NO = A.Agreement_No
	INNER JOIN #tempDataRewriteNL rw on rw.AGREEMENT_NO = a.AGREEMENT_NO	
	LEFT JOIN NewfoundlandLive.DBO.BRANCHES B (NOLOCK) ON B.BRANACH_CODE = A.CHECK_OUT_BRANACH 
	LEFT JOIN NewfoundlandLive..DEBITORS D (NOLOCK) ON D.DEBITOR_CODE = A.DEBITOR_CODE
	LEFT JOIN NewfoundlandLive.DBO.REPAIRED_AT R (NOLOCK) ON A.AGREEMENT_NO = R.AGREEMENT_NO and R.BODY_SHOP > 0
	LEFT JOIN NewfoundlandLive.DBO.GARAGES G (NOLOCK) ON G.GARAGE_NO = R.BODY_SHOP 	
	LEFT JOIN Carpro_App..vwBanner VB (NOLOCK) ON VB.BannerCode = G.GARAGES_ACCOUNT_GROUP
	left join Carpro_App..GARAGES_PREFERRED_YN YN on D.SUV_DEBITOR_OF = YN.DEBITOR_CODE and G.GARAGE_NO = YN.GARAGE_CODE 
	LEFT JOIN OntarioLive..DA_CLAIMS C (NOLOCK) ON C.DAC_AGREEMENT_NUMBER = A.AGREEMENT_NO
	Left join OntarioLive..EBILLING_INVOICE_DATA H(nolock) on C.DAC_ENTRY_ID = H.ENTRY_ID
	Left join OntarioLive..DA_ADJUSTER adj (NOLOCK) on C.DAC_COMPANY_ADJUSTER_ID = adj.DAA_ENTRY_ID
	LEFT JOIN (
		SELECT DCA_CLAIM_ID, AGREEMENT_NO, SUM(DCA_A_DAYS) AS AUTHDAY, 
		SUM(DAC_FINAL_TOTAL) AS DAC_FINAL_TOTAL, AVG(DCA_AUTHOR_RATE) AS AUTHORRATE 
		FROM ONTARIOLIVE..DA_AUTHORIZATION (NOLOCK)  WHERE DCA_BILL_TO = 1  and DCA_AUTHOR_FROM_DATE >= '20100101' and DCA_AUTHOR_TO_DATE <= '20501231'
		GROUP BY DCA_CLAIM_ID, AGREEMENT_NO
	) Auth ON C.DAC_ENTRY_ID = Auth.DCA_CLAIM_ID and Auth.AGREEMENT_NO = A.AGREEMENT_NO
	--left join NewfoundlandLive..VEHICLE_CLASSES v(nolock) on v.CLASS = case when C.DAC_RENTAL_CAR_CLASS > '' then C.DAC_RENTAL_CAR_CLASS else C.VEHICLE_CLASS END
	LEFT join NewfoundlandLive..INVOICES (nolock) i on ISNULL( A.AGREEMENT_NO, C.DAC_AGREEMENT_NUMBER)= i.AGREEMENT_NO and D.DEBITOR_CODE = I.DEBITOR_NO and I.INV_STATUS !=9 and i.INVOICE_TYPE = 'C'
	LEFT OUTER JOIN
		(
			SELECT SUM(AMOUNT) AMOUNT, INVOICE_NO FROM NewfoundlandLive..INVOICE_DETAILS(nolock) WHERE ELEMENT_TYPE = 70 AND SUB_ELEMENT_TYPE IN ('VL' ,'VLI') GROUP BY INVOICE_NO
		) VLI ON i.INVOICE_NO = VLI.INVOICE_NO -- For VL/AC Fee
	LEFT OUTER JOIN 
		(
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from NewfoundlandLive..INVOICE_DETAILS (nolock)
			
		) CDW ON i.INVOICE_NO = CDW.INVOICE_NO AND CDW.ELEMENT_TYPE = 60 AND CDW.SUB_ELEMENT_TYPE = 'CDW' -- For CDW
	LEFT OUTER JOIN (
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from NewfoundlandLive..INVOICE_DETAILS (nolock)
		) PAP ON i.INVOICE_NO = PAP.INVOICE_NO AND PAP.ELEMENT_TYPE = 60 AND PAP.SUB_ELEMENT_TYPE = 'PAP' -- For CDW
	LEFT OUTER JOIN (
			select INVOICE_NO, ELEMENT_TYPE, SUB_ELEMENT_TYPE,AMOUNT from NewfoundlandLive..INVOICE_DETAILS (nolock)
		) WT ON i.INVOICE_NO = WT.INVOICE_NO AND WT.ELEMENT_TYPE = 70 AND WT.SUB_ELEMENT_TYPE = 'WT' -- For CDW
	left join NewfoundlandLive..EBILLING_INVOICE_DATA o(nolock) on C.DAC_ENTRY_ID = o.ENTRY_ID and o.OTHER_CHARGES_DESC like '%tire%'
	WHERE 	
	A.STATUS_CODE = 4 AND A.DEBITOR_CODE > 0 
	and ((@DebitorCodes = 'ALL') or (d.SUV_DEBITOR_OF in (Select Data from dbo.SplitByDelimiter(@DebitorCodes,',') where Data != 'ALL')))
	AND DATEADD(SECOND, A.CHECK_IN_TIME, CONVERT(datetime,CONVERT(VARCHAR,A.CHECK_IN_DATE,112))) BETWEEN @BEGIN AND @End
	AND A.CHECK_IN_DATE!='00000000'  
	
	
	Delete from #tempDataRemedy where cast(ParentAgreementNo as bigint) > 0 
	
	select * into #tempData from #tempDataAgreements a where a.InvoiceNo > 0 
	Union
	Select * from #tempDataRemedy r where r.InvoiceNo > 0 
	
	
	Select 'Discount' as Supplier,'Insurance' as InsurerType, MAX(InvoiceDate) as InvoiceDate, ParentInsurerName as ParentInsurerName, [INS COMPANY NAME] as InsurerName, MAX(ClaimType) as ClaimType, 
	MAX(ExtentOfLoss) as ExtentOfLoss, '' as RepairType, MAX(DRIVABLE) as Drivability, MAX(CLAIM_NO) as InsuredClaimNumber, MAX(POLICY_NO) as InsuredPolicyNumber, 
	AgreementNo as VendorContractNumber, cast(round(MAX(AuthRate), 2)  as numeric(36,2)) as AuthRate, cast(round(SUM(Rental_Sum)/SUM(RENTAL_DAYS),2) as numeric(36,2)) as AvgRate, SUM(Rental_Sum) as BaseRentalFee,
	SUM(VehicleLicenseFee) as VehicleLicenseFee, SUM(WinterTireFee) as WinterTireFee,SUM(KilometerCharges) as KilometerCharges, '' as GeographicSurcharge, SUM(DropFees)as DropFees, 0 as DiscountDeductibleCoverage,
	SUM(CollisionDamageWaiver) as CollisionDamageWaiver,SUM(PracticleAssistanceProgram) as PracticleAssistanceProgram,SUM(SubTotal) as SubTotal, SUM(ProvincialTaxes) as ProvincialTaxes, SUM(FederalTaxes) as FederalTaxes, SUM(TotalFees) as TotalFees,
	SUM(RENTAL_DAYS) as RentalDays, SUM([TOTAL AUTHOR DAYS]) as AuthorizedDays, MAX(DateOfLoss) as DateOfIncident, (SELECT DATENAME(month, MAX(Rental_In))) as Month,
	MAX(Rental_Out) as RentalStartDate,MAX(Rental_In) as RentalEndDate,
	MAX(ICC_Make) as ICC_Make, MAX(ICC_Model) as ICC_Model, MAX(ICC_Vehicle_Year) as ICC_Vehicle_Year, MAX(ICC_Category) as ICC_Category, 
	MAX(CarManufacturer) as CarManufacturer,MAX(CarModel) as CarModel, MAX(Category) as Category, MAX(CarCategory) as CarCategory, MAX(VehicleYear) as VehicleYear,MAX(BranchCode) as BranchCode,
	MAX(BranchName) as BranchName,MAX(BranchCity) as BranchCity,MAX(BranchState) as BranchState,'Canada' as BranchCountry,
	GARAGE_NAME as GarageName, MAX([GARAGE ADDRESS]) as GarageAddress, MAX(BannerName) as BannerName,
	MIN(AdjusterName) as AdjusterName, '' as CatastrophyFlag, MAX(Preferred_Garages) as Preferred_Garages
	from #tempData
	group by AgreementNo, Renter_Name, GARAGE_NAME, PROVINCE, [INS COMPANY NAME], ParentInsurerName
	order by ParentInsurerName, InvoiceDate
	
	
	drop table #tempDataRemedy
	drop table #tempDataRewriteON
	drop table #tempDataRewriteAB
	drop table #tempDataRewriteBC
	drop table #tempDataRewriteMT
	drop table #tempDataRewriteNL
	drop table #tempDataRewriteNC
	drop table #tempDataRewriteSK
	drop table #tempDataRewriteSK2
	drop table #tempDataAgreements
	drop table #tempData
	drop table #temp_debitors 
END