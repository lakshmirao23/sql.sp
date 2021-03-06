USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_LossType_Reports_Excel_all]    Script Date: 04/05/2018 09:38:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--grant exec on [spDIAL_LossType_Reports_Excel_all] to crystal


-- =============================================
-- author:		<lakshmi rao>
-- create date: <jan 24, 2013>
-- description:	<insurance reports>
-- =============================================
--exec [spDIAL_LossType_Reports_Excel_all] @fromdate = '06/01/2015', @todate = '06/30/2015'
ALTER procedure [dbo].[spDIAL_LossType_Reports_Excel_all]
@fromdate datetime, @todate datetime, @debitorlist varchar(8000) = null 
as
begin
  set nocount on;
  
  -- 1. Temp table to hold multiple Debitor Codes
	DECLARE 
    @tblDebitor TABLE (DebitorCode int)	
	
	insert into @tblDebitor 
	select * from Carpro_App.dbo.ufn_String_To_Table(@debitorlist)
	
	--select * from @tblDebitor	
  
  	SELECT c.DAC_ENTRY_ID as Ref#, UPPER(provincienaam) AS Province,DAC_AGREEMENT_NUMBER as [Agreement#],d.DEBITOR_NAME as [Ins Company Name],
	D.DEBITOR_CODE as [Ins Company ID], (DAC_COMPANY_ADJ_FIRST_NAME + ' ' + DAC_COMPANY_ADJ_LAST_NAME) as [Adjuster Full Name], 
	DAC_RENTAL_CONTROLLED_BY as [CONTROLLED_BY], b.NAME as [Referral Source], rm.[RM_DESCRIPTION] as [Referral Method],
	Case when DAC_Claim_Type = 0 then 'Collision' 
	when DAC_Claim_Type = 1 then 'Comprehensive'when DAC_Claim_Type = 2 
	then 'Theft' End as [Claim Type], 
	case when DAC_TOTAL_LOSS ='Y' or DAC_Claim_Type =2 then 'Y' else 'N' end as [Theft or Total Loss],
	round(ISNULL(AuthorRate,c.DAC_AUTHORIZED_RATE), 2) as Author_Rate, 
	case when ISNULL(MYAUTHORIZATION.DCA_A_Days,c.DAC_AUTHOR_DAYS) > 
	Carpro_App.dbo.fn_Cal_hourly_RentalDays_agreementno(d.DAYS_CALC_LOGIC,dateadd(SECOND,DAC_AGR_OPEN_TIME,convert(datetime,convert(varchar,DAC_AGR_Open_Date,112))),
	dateadd(SECOND,DAC_AGR_CLOSE_TIME,convert(datetime,convert(varchar,DAC_AGR_CLOSE_DATE,112))), agreement.sold_days) 
	then Carpro_App.dbo.fn_Cal_hourly_RentalDays_agreementno(d.DAYS_CALC_LOGIC, DateAdd(Second, DAC_AGR_OPEN_TIME, 
	Convert(DateTime, Convert(varchar, DAC_AGR_Open_Date, 112))), DateAdd(Second, DAC_AGR_CLOSE_TIME, 
	Convert(datetime, Convert(varchar, DAC_AGR_CLOSE_DATE, 112))), agreement.sold_days) else ISNULL(MYAUTHORIZATION.DCA_A_Days,c.DAC_AUTHOR_DAYS) end as Author_Days, 
	case when ISNULL(MYAUTHORIZATION.DCA_A_Days,c.DAC_AUTHOR_DAYS) > 
	Carpro_App.dbo.fn_Cal_hourly_RentalDays_agreementno(d.DAYS_CALC_LOGIC,dateadd(SECOND,DAC_AGR_OPEN_TIME,convert(datetime,convert(varchar,DAC_AGR_Open_Date,112))),
	dateadd(SECOND,DAC_AGR_CLOSE_TIME,convert(datetime,convert(varchar,DAC_AGR_CLOSE_DATE,112))), agreement.sold_days) 
	then Carpro_App.dbo.fn_Cal_hourly_RentalDays_agreementno(d.DAYS_CALC_LOGIC, DateAdd(Second, DAC_AGR_OPEN_TIME, 
	Convert(DateTime, Convert(varchar, DAC_AGR_Open_Date, 112))), DateAdd(Second, DAC_AGR_CLOSE_TIME, Convert(datetime, Convert(varchar, DAC_AGR_CLOSE_DATE, 112))), 
	agreement.sold_days) else ISNULL(MYAUTHORIZATION.DCA_A_Days,c.DAC_AUTHOR_DAYS) end * round(ISNULL(AuthorRate,c.DAC_AUTHORIZED_RATE), 2) as Total, 
	case when DAC_AGR_Open_Date ='00000000' then null else dateadd(SECOND,DAC_AGR_OPEN_TIME,convert(datetime,convert(varchar,DAC_AGR_Open_Date,112))) end as Contract_Open, 
	case when DAC_AGR_Close_Date ='00000000' then null else dateadd(SECOND,DAC_AGR_Close_TIME,convert(datetime,convert(varchar,DAC_AGR_Close_Date,112))) end as Contract_Closed, 
	DAC_DRIVABLE [Drivable], DAC_LOCATION_CODE as [Location Code], DAC_LOCATION_NAME as [Location Name], DAC_LOCATION_ADDRESS as [Location Address], 
	DAC_RENTAL_COMP_NAME as [Rental Comp Name], 
	case when DAC_DATE_OF_LOSS ='00000000' or ltrim(DAC_DATE_OF_LOSS) ='' or DAC_DATE_OF_LOSS is null 
	then null else right(left(DAC_DATE_OF_LOSS,6),2) + '/'+ right(DAC_DATE_OF_LOSS,2)+'/' +left(DAC_DATE_OF_LOSS,4) end as DATE_OF_LOSS,
	DAC_GARAGE_NAME as Garage_Name,DAC_GARAGE_ADDRESS as Garage_Address,DAC_MAKE as ICCMake, DAC_Model as ICCModel, DAC_Year as Veh_Year, 
	Category_Vehicle as Category_Vehicle, DAC_Rental_Make as Make,DAC_Rental_Unit_No as Unit_Num, DAC_Rental_Model as Model,
	DAC_Rental_Year as Year,DAC_INVOICE_DATE as InvDate,dac_ins_claim as Ins_Claim_No,dac_policy as Policy_No,
	case when dac_create_date ='00000000' then null else convert(datetime,convert(varchar,dac_create_date,112)) end as [Create Date], 
	AUDATEX_ID 
	FROM .DA_CLAIMS C WITH (NOLOCK) 
	LEFT JOIN DBO.DEBITORS D with(nolock) ON C.DAC_INS_COMPANY_ID = D.DEBITOR_CODE 
	left join dbo.BUSINESS_SOURCE b(nolock) on c.DAC_Referral_Source_ID = b.CODE 
	left join dbo.Garages g(nolock) on c.DAC_GARAGE_ID = g.GARAGE_NO 
	left join dbo.[REFERRAL_METHOD] rm (nolock) on c.DAC_REFERRAL_METHOD_ID = rm.[RM_ID] 
	Left join (select DCA_CLAIM_ID, SUM(DCA_A_Days) DCA_A_Days, SUM(dac_final_total) as dac_final_total, avg(DCA_AUTHOR_RATE) as AuthorRate 
	from dbo.DA_AUTHORIZATION(nolock) where DCA_BILL_TO = 1 group by DCA_CLAIM_ID) MYAUTHORIZATION on c.DAC_ENTRY_ID = MYAUTHORIZATION.DCA_CLAIM_ID 
	LEFT JOIN (
	SELECT AGREEMENT_NO, SOLD_DAYS, CHECK_OUT_DATE, CHECK_OUT_TIME,CHECK_IN_DATE,CHECK_IN_TIME, CHECK_OUT_BRANACH, STATUS_CODE 
	FROM .AGREEMENTS(NOLOCK) 
	UNION SELECT AGREEMENT_NO, SOLD_DAYS, CHECK_OUT_DATE, CHECK_OUT_TIME,CHECK_IN_DATE,CHECK_IN_TIME, CHECK_OUT_BRANACH, STATUS_CODE 
	FROM ALBERTALIVE..AGREEMENTS(NOLOCK)
	UNION SELECT AGREEMENT_NO, SOLD_DAYS, CHECK_OUT_DATE, CHECK_OUT_TIME,CHECK_IN_DATE,CHECK_IN_TIME, CHECK_OUT_BRANACH, STATUS_CODE 
	FROM StCatharines..AGREEMENTS(NOLOCK)
	UNION SELECT AGREEMENT_NO, SOLD_DAYS, CHECK_OUT_DATE, CHECK_OUT_TIME,CHECK_IN_DATE,CHECK_IN_TIME, CHECK_OUT_BRANACH, STATUS_CODE 
	FROM SaskatchewanLive..AGREEMENTS(NOLOCK)
	UNION SELECT AGREEMENT_NO, SOLD_DAYS, CHECK_OUT_DATE, CHECK_OUT_TIME,CHECK_IN_DATE,CHECK_IN_TIME, CHECK_OUT_BRANACH, STATUS_CODE 
	FROM SaskatchewanLive2..AGREEMENTS(NOLOCK)
	UNION SELECT AGREEMENT_NO, SOLD_DAYS, CHECK_OUT_DATE, CHECK_OUT_TIME,CHECK_IN_DATE,CHECK_IN_TIME, CHECK_OUT_BRANACH, STATUS_CODE 
	FROM NewfoundlandLive..AGREEMENTS(NOLOCK)
	UNION SELECT AGREEMENT_NO, SOLD_DAYS, CHECK_OUT_DATE, CHECK_OUT_TIME,CHECK_IN_DATE,CHECK_IN_TIME, CHECK_OUT_BRANACH, STATUS_CODE 
	FROM MaritimesLive..AGREEMENTS(NOLOCK)
	UNION SELECT AGREEMENT_NO, SOLD_DAYS, CHECK_OUT_DATE, CHECK_OUT_TIME,CHECK_IN_DATE,CHECK_IN_TIME, CHECK_OUT_BRANACH, STATUS_CODE 
	FROM BcLive..AGREEMENTS(NOLOCK)
	) AGREEMENT ON C.DAC_AGREEMENT_NUMBER = AGREEMENT.AGREEMENT_NO 
	LEFT JOIN DBO.BRANCHES BRANCHES(NOLOCK) ON CASE WHEN C.DAC_LOCATION_CODE>0 THEN C.DAC_LOCATION_CODE ELSE AGREEMENT.CHECK_OUT_BRANACH END =BRANCHES.BRANACH_CODE 
	LEFT JOIN DBO.PROVINCIES PROVINCIES ON BRANCHES.PROVINCE_CODE = PROVINCIES.PROVINCIECODE 
	WHERE DAC_AGREEMENT_NUMBER > 0 AND C.DAC_AGR_CLOSE_DATE!='00000000' AND C.DAC_AGR_OPEN_DATE != '00000000' AND DAC_STATUS = 4 
	and (@debitorlist is null OR d.SUV_DEBITOR_OF in (select * from @tblDebitor))	 
	and (
	LTRIM(RTRIM(DAC_TOTAL_LOSS)) = 'Y' or LTRIM(RTRIM(DAC_DRIVABLE)) = 'Y' or LTRIM(RTRIM(DAC_DRIVABLE)) = 'N' or LTRIM(RTRIM(DAC_DRIVABLE)) is null 
	or LTRIM(RTRIM(DAC_DRIVABLE)) = '' or  DAC_CLAIM_TYPE = 2)	
	AND ISNULL(MYAUTHORIZATION.DCA_A_Days,c.DAC_AUTHOR_DAYS) > 0 AND D.DEBITOR_CODE <> '' 
	AND PROVINCIES.PROVINCIECODE IS NOT NULL AND ISNULL(AuthorRate,c.DAC_AUTHORIZED_RATE) > 0 
	AND C.DAC_AGR_CLOSE_DATE!='00000000' 
	and dateadd(second,dac_agr_close_time,convert(datetime,convert(varchar,dac_agr_close_date,112))) 
	between convert(datetime,@fromdate) and convert(datetime,@todate + '23:59:59') 	
	ORDER BY 2 
	

  
end







