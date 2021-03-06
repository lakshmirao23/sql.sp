USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Default_Extras]    Script Date: 04/05/2018 09:34:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [dbo].[spDIAL_Default_Extras] 16367 , 'A'
ALTER Proc [dbo].[spDIAL_Default_Extras] @Debitor_Code bigint =16367 
, @Vehicle_Class varchar(10) = 'A'
as

select distinct a.EXTRAS_CODE as Extras_Code , NAME as Extras_Name 
, b.UNIT_PRICE,b.F_GROUP, a.EXTRA_UNIT
--,a.*
--,b.*
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
where 
--f.DEBITOR_CODE =16367 and 
f.DEBITOR_TYPE ='O'
and ds.IN_STOP_LIST ='A'
and CONVERT(varchar(8),getdate(),112) between c.FROM_DATE and c.TO_DATE
--and EXTRA_UNIT = 1
and b.F_GROUP =@Vehicle_Class
and a.EXTRAS_CODE in ('UF','DF','WT') --UNDER AGE FEE, DROP FEE, WINTER TIRE 
order by 1,2,4

