USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Default_Extras_Insurance]    Script Date: 04/05/2018 09:34:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



--SELECT * FROM DEBITORS D (NOLOCK) 
--LEFT JOIN DEBITORS_SECTION2 S (NOLOCK) ON  S.DEBITOR_CODE = D.DEBITOR_CODE
-- WHERE DEBITOR_NAME LIKE '%intact%' AND IN_STOP_LIST='A' AND DEBITOR_TYPE='O'



--exec [dbo].[spDIAL_Default_Extras_Insurance] 16957 , 3,   'f'
ALTER Proc [dbo].[spDIAL_Default_Extras_Insurance] @Debitor_Code bigint = 16957, @Province_Code int =3 
, @Vehicle_Class varchar(10) = 'A'
as

select distinct b.INSURANCE_CODE as Extra_or_Insurance_Code --, NAME as Extras_Name 
, b.INSURANCE_RATE Rate, b.F_GROUP Car_Group
--,a.*
--,b.*
from RATE_INSURANCES b(nolock) 
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
inner join RATE_OUT_BRANCHES ro(nolock) on d.RATE_NO =ro.RATE_NO
		inner join BRANCHES h(nolock) on ro.BRANACH_CODE = h.BRANACH_CODE
where 
--f.DEBITOR_CODE =16367 and 
f.DEBITOR_TYPE ='O'
and ds.IN_STOP_LIST ='A'
and CONVERT(varchar(8),getdate(),112) between c.FROM_DATE and c.TO_DATE
--and EXTRA_UNIT = 1
and b.F_GROUP =@Vehicle_Class
and ltrim(rtrim(b.INSURANCE_CODE)) ='CDW'
and ltrim(rtrim(RENTAL_PACKAGE)) ='1D'
and f.DEBITOR_CODE =@Debitor_Code
and h.PROVINCE_CODE =@Province_Code
union
select distinct a.EXTRAS_CODE as Extras_Code --, NAME as Extras_Name 
, b.UNIT_PRICE,b.F_GROUP
from EXTRAS a(nolock)
inner join RATE_EXTRAS b(nolock) on 
ltrim(rtrim(a.EXTRAS_CODE)) = ltrim(rtrim(b.EXTRAS_CODE))
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
inner join RATE_OUT_BRANCHES ro(nolock) on d.RATE_NO =ro.RATE_NO
		inner join BRANCHES h(nolock) on ro.BRANACH_CODE = h.BRANACH_CODE
where 
--f.DEBITOR_CODE =16367 and 
f.DEBITOR_TYPE ='O'
and f.DEBITOR_CODE =@Debitor_Code
and ds.IN_STOP_LIST ='A'
and CONVERT(varchar(8),getdate(),112) between c.FROM_DATE and c.TO_DATE
--and EXTRA_UNIT = 1
and ltrim(rtrim(b.F_GROUP)) =@Vehicle_Class
and ltrim(rtrim(a.EXTRAS_CODE)) in ('UF','DF','WT') --UNDER AGE FEE, DROP FEE, WINTER TIRE 
and h.PROVINCE_CODE =@Province_Code
--order by 1,2,4




