USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Vehicle_Class_Rate]    Script Date: 04/05/2018 09:40:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--spDIAL_vehicle_class_rate 16837, 3      taking 3 sec
-- exec spDIAL_Vehicle_Class_Rate 16957, 3
ALTER Proc [dbo].[spDIAL_Vehicle_Class_Rate] @Debitor_Code bigint =16367, @Province_Code int =3
/*
1	British Columbia
2	Saskatchewan
3	Ontario
4	Quebec
5	Alberta
6	Nova Scotia
7	Manitoba
8	Northwest Territories
9	New Brunswick
10	Prince Edward Island
11	Newfoundland
12	Nunavut
13	Yukon
*/
--, @Vehicle_Class varchar(10) = 'A'
as

Declare @Rate_Count int

Declare @RateTable  table (Rate_No int)

declare @ParentDebitorName varchar(500)
select @ParentDebitorName = 'Intact' from OntarioLive..DEBITORS (nolock) where DEBITOR_CODE = @Debitor_Code and DEBITOR_NAME like '%intact%'

insert into @RateTable(Rate_No)
select distinct d.RATE_NO
from  TARIFF_RATES d(nolock)
inner join TARIFF_CODES e(nolock)
on ltrim(rtrim(d.TARIFF_CODE)) = ltrim(rtrim(e.TARIFF_CODE))
inner join DEBITORS f(nolock)
on ltrim(rtrim(e.TARIFF_CODE)) = ltrim(rtrim(f.TARIFF_CODE))
inner join DEBITORS_SECTION2 ds(nolock)
on f.DEBITOR_CODE = ds.DEBITOR_CODE
inner join RATES_SECTION_1 c(nolock)
on d.RATE_NO = c.RATE_NO
where 
f.DEBITOR_TYPE ='O'
and ds.IN_STOP_LIST ='A'
and CONVERT(varchar(8),getdate(),112) between c.FROM_DATE and c.TO_DATE
and f.DEBITOR_CODE =@Debitor_Code


if exists(
select ro.*
from
RATE_OUT_BRANCHES ro(nolock)
inner join BRANCHES h(nolock)
on ro.BRANACH_CODE = h.BRANACH_CODE
where ro.RATE_NO in (SELECT RATE_NO from @RateTable)
and h.PROVINCE_CODE =@Province_Code
)
begin
		if @ParentDebitorName = 'Intact' and @Province_Code = 3
		begin
			select distinct ltrim(rtrim(b.F_GROUP)) Car_Class, ltrim(rtrim(g.CLASS_NAME))  + ' - $' +  convert(varchar(20),convert(decimal(18,2),b.CUSTOMER_PER_DAY))  as [Description], b.CUSTOMER_PER_DAY as [Rate] 
			from RATES_SECTION_2 b(nolock) 
			inner join RATES_SECTION_1 c(nolock)
			on b.RATE_NO =c.RATE_NO 
			and b.RATE_SR_NO = c.RATE_SR_NO
			inner join TARIFF_RATES d(nolock)
			on c.RATE_NO = d.RATE_NO
			inner join TARIFF_CODES e(nolock)
			on ltrim(rtrim(d.TARIFF_CODE)) = ltrim(rtrim(e.TARIFF_CODE))
			inner join DEBITORS f(nolock)
			on ltrim(rtrim(e.TARIFF_CODE)) = ltrim(rtrim(f.TARIFF_CODE))
			inner join DEBITORS_SECTION2 ds(nolock)
			on f.DEBITOR_CODE = ds.DEBITOR_CODE
			left join [VEHICLE_CLASSES] g(nolock)
			on ltrim(rtrim(b.F_GROUP)) = ltrim(rtrim(g.CLASS)) 
			inner join RATE_OUT_BRANCHES ro(nolock)
			on d.RATE_NO =ro.RATE_NO
			inner join BRANCHES h(nolock)
			on ro.BRANACH_CODE = h.BRANACH_CODE
			where 
			--f.DEBITOR_CODE =16367 and 
			f.DEBITOR_TYPE ='O'
			and ds.IN_STOP_LIST ='A'
			and CONVERT(varchar(8),getdate(),112) between c.FROM_DATE and c.TO_DATE
			--and EXTRA_UNIT = 1
			--and b.F_GROUP =@Vehicle_Class
			and ltrim(rtrim(b.RENTAL_PACKAGE)) ='1D'
			and f.DEBITOR_CODE =@Debitor_Code
			and h.PROVINCE_CODE =@Province_Code
			and CHARINDEX(' US', c.RATE_NAME) =0 and RATE_NAME like '%ON%'
			order by 1
		end
		else
		begin
			select distinct ltrim(rtrim(b.F_GROUP)) Car_Class, ltrim(rtrim(g.CLASS_NAME))  + ' - $' +  convert(varchar(20),convert(decimal(18,2),b.CUSTOMER_PER_DAY))  as [Description], b.CUSTOMER_PER_DAY as [Rate] 
			from RATES_SECTION_2 b(nolock) 
			inner join RATES_SECTION_1 c(nolock)
			on b.RATE_NO =c.RATE_NO 
			and b.RATE_SR_NO = c.RATE_SR_NO
			inner join TARIFF_RATES d(nolock)
			on c.RATE_NO = d.RATE_NO
			inner join TARIFF_CODES e(nolock)
			on ltrim(rtrim(d.TARIFF_CODE)) = ltrim(rtrim(e.TARIFF_CODE))
			inner join DEBITORS f(nolock)
			on ltrim(rtrim(e.TARIFF_CODE)) = ltrim(rtrim(f.TARIFF_CODE))
			inner join DEBITORS_SECTION2 ds(nolock)
			on f.DEBITOR_CODE = ds.DEBITOR_CODE
			left join [VEHICLE_CLASSES] g(nolock)
			on ltrim(rtrim(b.F_GROUP)) = ltrim(rtrim(g.CLASS)) 
			inner join RATE_OUT_BRANCHES ro(nolock)
			on d.RATE_NO =ro.RATE_NO
			inner join BRANCHES h(nolock)
			on ro.BRANACH_CODE = h.BRANACH_CODE
			where 
			--f.DEBITOR_CODE =16367 and 
			f.DEBITOR_TYPE ='O'
			and ds.IN_STOP_LIST ='A'
			and CONVERT(varchar(8),getdate(),112) between c.FROM_DATE and c.TO_DATE
			--and EXTRA_UNIT = 1
			--and b.F_GROUP =@Vehicle_Class
			and ltrim(rtrim(b.RENTAL_PACKAGE)) ='1D'
			and f.DEBITOR_CODE =@Debitor_Code
			and h.PROVINCE_CODE =@Province_Code
			and CHARINDEX(' US', c.RATE_NAME) =0
			order by 1
		end

end
else
begin
select distinct ltrim(rtrim(b.F_GROUP)) Car_Class, ltrim(rtrim(g.CLASS_NAME))  + ' - $' +  convert(varchar(20),convert(decimal(18,2),b.CUSTOMER_PER_DAY))  as [Description], b.CUSTOMER_PER_DAY as [Rate] 
--,a.*
--,b.*
from RATES_SECTION_2 b(nolock) 
inner join RATES_SECTION_1 c(nolock)
on b.RATE_NO =c.RATE_NO 
and b.RATE_SR_NO = c.RATE_SR_NO
inner join TARIFF_RATES d(nolock)
on c.RATE_NO = d.RATE_NO
inner join TARIFF_CODES e(nolock)
on ltrim(rtrim(d.TARIFF_CODE)) = ltrim(rtrim(e.TARIFF_CODE))
inner join DEBITORS f(nolock)
on ltrim(rtrim(e.TARIFF_CODE)) = ltrim(rtrim(f.TARIFF_CODE))
inner join DEBITORS_SECTION2 ds(nolock)
on f.DEBITOR_CODE = ds.DEBITOR_CODE
left join [VEHICLE_CLASSES] g(nolock)
on ltrim(rtrim(b.F_GROUP)) = ltrim(rtrim(g.CLASS)) 
where 
--f.DEBITOR_CODE =16367 and 
f.DEBITOR_TYPE ='O'
and ds.IN_STOP_LIST ='A'
and CONVERT(varchar(8),getdate(),112) between c.FROM_DATE and c.TO_DATE
--and EXTRA_UNIT = 1
--and b.F_GROUP =@Vehicle_Class
and ltrim(rtrim(b.RENTAL_PACKAGE)) ='1D'
and f.DEBITOR_CODE =@Debitor_Code
order by 1
end


