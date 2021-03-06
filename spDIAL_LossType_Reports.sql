USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_LossType_Reports]    Script Date: 04/05/2018 09:37:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- author:		<lakshmi rao>
-- create date: <jan 24, 2013>
-- description:	<insurance reports>
-- =============================================
--exec [spDIAL_LossType_Reports] @fromdate = '10/01/2012', @todate = '10/31/2012', @view = 'PARENT'
ALTER procedure [dbo].[spDIAL_LossType_Reports]
@fromdate datetime, @todate datetime, @debitorlist varchar(8000) = null , 
@debitorCode int = null, @view varchar(50)
as
begin
  set nocount on;
  
  -- 1. Temp table to hold multiple Debitor Codes
	DECLARE 
    @tblDebitor TABLE (DebitorCode int)	
	
	insert into @tblDebitor 
	select * from Carpro_App.dbo.ufn_String_To_Table(@debitorlist)
	
	--select * from @tblDebitor	
  
    create table #insdata(
	  region varchar(50),
      ins_companyname varchar(200),  
      adjuster_name varchar(100),  
      agreement_no varchar(20),
      claim_no varchar(30),
      policy_no varchar(30),
      no_of_files int,
      no_of_days int,
      average_days FLOAT,
      average_rate FLOAT,   
      average_cost FLOAT,
      total float, 
      Drivable char(1), 
      Total_Loss char(1),
      Theft INT,
      ins_company_id float  
                       
)
	insert into #insdata  
    select upper(provincienaam) as region, d.debitor_name as ins_companyname,(c.dac_company_adj_first_name + ' ' + dac_company_adj_last_name)  as adjuster_name,
    cast(cast(c.dac_agreement_number as bigint) as varchar(15)) as agreement_no,c.dac_ins_claim as claim_no, c.dac_policy as policy_no,
    count(1) as #_of_files, 
	--sum(case when isnull(authday,c.dac_author_days) > 
	--carpro_app.dbo.fn_cal_hourly_rentaldays_agreementno(d.days_calc_logic,dateadd(second,dac_agr_open_time,convert(datetime,convert(varchar,dac_agr_open_date,112))),
	--dateadd(second,dac_agr_close_time,convert(smalldatetime,convert(varchar,dac_agr_close_date,112))), agreement.sold_days) 
	--then carpro_app.dbo.fn_cal_hourly_rentaldays_agreementno(d.days_calc_logic,dateadd(second,dac_agr_open_time,convert(datetime,convert(varchar,dac_agr_open_date,112))),
	--dateadd(second,dac_agr_close_time,convert(smalldatetime,convert(varchar,dac_agr_close_date,112))), agreement.sold_days) else isnull(authday,c.dac_author_days) end ) 
	isnull(sum(agreement.SOLD_DAYS), 0) as #_of_days , 	
	0 as average_days, 
	round(sum(isnull(authorrate,c.dac_authorized_rate))/count(1), 2) as [average rate] ,
	0 as average_cost,
	0 as total, DAC_DRIVABLE , DAC_TOTAL_LOSS , DAC_Claim_Type , DAC_INS_COMPANY_ID  
	from da_claims c with (nolock) left join dbo.debitors d with(nolock) on c.dac_ins_company_id = d.debitor_code 
	left join (select dca_claim_id, sum(dca_a_days) as authday, sum(dac_final_total) as dac_final_total, avg(dca_author_rate) as authorrate 
	from da_authorization (nolock) where dca_bill_to = 1 group by dca_claim_id ) a on c.dac_entry_id = a.dca_claim_id 
	left join 
	(select agreement_no, sold_days, check_out_date, check_out_time,check_in_date,check_in_time,check_out_branach, status_code from agreements(nolock) 
	union 
	select agreement_no, sold_days, check_out_date, check_out_time,check_in_date,check_in_time,check_out_branach, status_code from albertalive..agreements(nolock)
	union 
	select agreement_no, sold_days, check_out_date, check_out_time,check_in_date,check_in_time,check_out_branach, status_code from stcatharines..agreements(nolock)
	union 
	select agreement_no, sold_days, check_out_date, check_out_time,check_in_date,check_in_time,check_out_branach, status_code from saskatchewanlive..agreements(nolock)
	union 
	select agreement_no, sold_days, check_out_date, check_out_time,check_in_date,check_in_time,check_out_branach, status_code from MaritimesLive..agreements(nolock)
	union 
	select agreement_no, sold_days, check_out_date, check_out_time,check_in_date,check_in_time,check_out_branach, status_code from BcLive..agreements(nolock)
	) 
	agreement on c.dac_agreement_number = agreement.agreement_no 
	left join dbo.branches branches(nolock) on case when c.dac_location_code>0 then c.dac_location_code 
	else agreement.check_out_branach end =branches.branach_code 
	left join dbo.provincies provincies 
	on branches.province_code = provincies.provinciecode where dac_agreement_number > 0 
	and dac_status not in (5,6) 
	and (@debitorlist is null or d.debitor_code in (select * from @tblDebitor))	
	and provincies.provinciecode is not null  --and d.DEBITOR_CODE > 0 
	and isnull(authday,c.dac_author_days) > 0 --and c.dac_agr_close_date!='00000000' and c.dac_agr_open_date != '00000000' 
	and c.dac_agr_close_date!='00000000' 
	--and dateadd(second,dac_agr_close_time,convert(smalldatetime,convert(varchar,dac_agr_close_date,112))) 
	--between convert(smalldatetime,@fromdate) and convert(smalldatetime,@todate + '23:59:59') 
	--and convert(varchar,dac_agr_close_date)
	--between convert(datetime,@fromdate) and convert(datetime,@todate) 
	and c.DAC_AGR_OPEN_DATE between '2010' and '2049'
    and c.dac_agr_close_date between '2010' and '2049'
    AND (LEFT(DAC_AGR_OPEN_DATE,4) > '2000' AND LEFT(DAC_AGR_CLOSE_DATE,4) > '2000')
    and dac_agr_close_date between @fromdate and @todate
	group by provincienaam , d.debitor_name, c.dac_company_adj_first_name, c.dac_company_adj_last_name, c.dac_ins_claim, 
	c.dac_policy, c.dac_agreement_number, DAC_DRIVABLE, DAC_TOTAL_LOSS , DAC_Claim_Type, DAC_INS_COMPANY_ID
	order by 1 
	
	update #insdata set average_days = ROUND(no_of_days/no_of_files,2)
	update #insdata set average_cost = ROUND(average_days * average_rate,2)	
	update #insdata set total = ROUND(average_cost * no_of_files,2)	
	
	--SELECT *,  ROUND(CONVERT(FLOAT,[AVERAGE_DAYS]*[AVERAGE_RATE]),2)  AS [AVERAGE_COST]
	--, ROUND(CONVERT(FLOAT,ROUND(CONVERT(FLOAT,[AVERAGE_DAYS]*[AVERAGE_RATE]),2)* NO_OF_FILES),2) AS TOTAL	
	--FROM	
	--(
	--SELECT REGION, 
	--SUM(NO_OF_FILES) AS [NO_OF_FILES], 
	--SUM(NO_OF_DAYS) AS [NO_OF_DAYS], 
	--ROUND(CONVERT(FLOAT,AVG(NO_OF_DAYS*1.0)),2) AS [AVERAGE_DAYS],
	--ROUND(AVG(AVERAGE_RATE),2) AS [AVERAGE_RATE]	
	--FROM #INSDATA
	--GROUP BY REGION 
	--) T1
	--ORDER BY 1	
	
	declare @Drivable table
	(
	ins_companyname varchar(200),
	ins_company_id float,
	Vehicle_Condition varchar(50),
	agreement_no varchar(20),
	no_of_days int,
    average_days FLOAT,
    average_rate FLOAT,   
    average_cost FLOAT,
    total float  
	)
	
	declare @NonDrivable table
	(
	ins_companyname varchar(200),
	ins_company_id float,
	Vehicle_Condition varchar(50),
	agreement_no varchar(20),
	no_of_days int,
    average_days FLOAT,
    average_rate FLOAT,   
    average_cost FLOAT,
    total float  
	)
	
	declare @NoConditionSpecified table
	(
	ins_companyname varchar(200),
	ins_company_id float,
	Vehicle_Condition varchar(50),
	agreement_no varchar(20),
	no_of_days int,
    average_days FLOAT,
    average_rate FLOAT,   
    average_cost FLOAT,
    total float  
	)
	
	declare @TotalLoss table
	(
	ins_companyname varchar(200),
	ins_company_id float,
	Vehicle_Condition varchar(50),
	agreement_no varchar(20),
	no_of_days int,
    average_days FLOAT,
    average_rate FLOAT,   
    average_cost FLOAT,
    total float  
	)
	
	declare @Theft table
	(
	ins_companyname varchar(200),
	ins_company_id float,
	Vehicle_Condition varchar(50),
	agreement_no varchar(20),
	no_of_days int,
    average_days FLOAT,
    average_rate FLOAT,   
    average_cost FLOAT,
    total float  
	)
		
	INSERT INTO @Drivable
	select ins_companyname, ins_company_id, 'DRIVABLE', agreement_no, no_of_days, average_days, average_rate, average_cost, total 
	from #insdata 
	where Drivable = 'Y'	
	group by ins_companyname, ins_company_id, agreement_no, no_of_files, no_of_days, average_days, average_rate, average_cost, total
	
	INSERT INTO @NonDrivable
	select ins_companyname, ins_company_id, 'NON DRIVABLE', agreement_no, no_of_days, average_days, average_rate, average_cost, total 
	from #insdata 
	where Drivable = 'N'	
	group by ins_companyname, ins_company_id, agreement_no, no_of_files, no_of_days, average_days, average_rate, average_cost, total
	
	INSERT INTO @NoConditionSpecified
	select ins_companyname, ins_company_id, 'NO CONDITION SPECIFIED', agreement_no, no_of_days, average_days, average_rate, average_cost, total 
	from #insdata 
	where Drivable IS NULL or Drivable = ''
	group by ins_companyname, ins_company_id, agreement_no, no_of_files, no_of_days, average_days, average_rate, average_cost, total
	
	INSERT INTO @TotalLoss
	select ins_companyname, ins_company_id, 'TOTAL LOSS', agreement_no, no_of_days, average_days, average_rate, average_cost, total 
	from #insdata 
	where Total_Loss = 'Y'
	group by ins_companyname, ins_company_id, agreement_no, no_of_files, no_of_days, average_days, average_rate, average_cost, total
	
	INSERT INTO @Theft
	select ins_companyname, ins_company_id, 'THEFT', agreement_no, no_of_days, average_days, average_rate, average_cost, total 
	from #insdata 
	where Theft = 2
	group by ins_companyname, ins_company_id, agreement_no, no_of_files, no_of_days, average_days, average_rate, average_cost, total
	
	declare @LossType table
	(	 
	 ins_company_name varchar(200),
	 ins_comp_id float,
	 vehiclecondition varchar(50),
	 agreement_no varchar(20),
	 no_of_days int,
     average_days FLOAT,
     average_rate FLOAT,   
     average_cost FLOAT,
     total float
	)
	
	insert into @LossType (ins_company_name, ins_comp_id, vehiclecondition, agreement_no, no_of_days, average_days, average_rate, average_cost, total)
	select distinct ins_companyname, ins_company_id, Vehicle_Condition, agreement_no, no_of_days, average_days, average_rate, average_cost, total from @Drivable	
	union
	select distinct ins_companyname, ins_company_id, Vehicle_Condition, agreement_no, no_of_days, average_days, average_rate, average_cost, total from @NonDrivable	
	union
	select distinct ins_companyname, ins_company_id, Vehicle_Condition, agreement_no, no_of_days, average_days, average_rate, average_cost, total from @NoConditionSpecified	
	union
	select distinct ins_companyname, ins_company_id, Vehicle_Condition, agreement_no, no_of_days, average_days, average_rate, average_cost, total from @TotalLoss	
	union
	select distinct ins_companyname, ins_company_id, Vehicle_Condition, agreement_no, no_of_days, average_days, average_rate, average_cost, total from @Theft	
	
	if @view = 'PARENT'
	BEGIN		
		select distinct ins_company_name, ins_comp_id
		from @LossType		
		order by ins_company_name
	END
	
	if @view = 'CHILD'
	begin
		SELECT *,  ROUND(CONVERT(FLOAT,[AVERAGE_DAYS]*[AVERAGE_RATE]),2)  AS [AVERAGE_COST]
		, ROUND(CONVERT(FLOAT,ROUND(CONVERT(FLOAT,[AVERAGE_DAYS]*[AVERAGE_RATE]),2)* NO_OF_FILES),2) AS TOTAL	
		FROM	
		(
		select ins_company_name, ins_comp_id, vehiclecondition, count(agreement_no)as no_of_files, 
		sum(no_of_days) as no_of_days, 
		ROUND(CONVERT(FLOAT,AVG(NO_OF_DAYS*1.0)),2) AS [AVERAGE_DAYS],
		ROUND(AVG(AVERAGE_RATE),2) AS [AVERAGE_RATE]	
		from @LossType WHERE ins_comp_id = @debitorCode
		group by vehiclecondition, ins_company_name, ins_comp_id 
		) T1	
		order by ins_company_name, vehiclecondition
	end
	
	
	
drop table #insdata;
  
end