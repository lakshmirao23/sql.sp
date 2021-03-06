USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_GetAdjusters_Admin]    Script Date: 04/05/2018 09:36:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<LAKSHMI RAO>
-- Create date: <JANUARY 25, 2013>
-- Description:	<To populate Adjusters for the selected Debitor for MyFiles>
-- =============================================

--  EXEC [spDIAL_GetAdjusters_Admin] 
--16837
ALTER PROCEDURE [dbo].[spDIAL_GetAdjusters_Admin] 
@DEBITOR_CODE INT = 0,
@SEARCH VARCHAR(50) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	select distinct (daa_first_name + ' ' + daa_last_name) AS AdjusterName, 
	daa_entry_id, a.debitor_code, p.provincienaam as AdjusterProvince, v.text as AdjusterRole, 
	u.Adjuster_Province, u.Adjuster_UserRole_Id  as Adjuster_UserRole_Id,
	e.TUSR as AdjusterUserName, e.EMP_PASSWORD as AdjusterPwd, u.Adjuster_CityCode, c.NAME as CityName 
	from dbo.da_adjuster a (nolock) 
	--inner join ADJUSTER_DEBITORS adj (nolock) on adj.ADJUSTER_ID = a.DAA_ENTRY_ID
	left join dbo.tblDIAL_AdjusterUserRoleDetails u (nolock) on u.AdjusterId = a.DAA_ENTRY_ID
	--left join dbo.debitors (nolock) d on adj.INS_COMPANY_ID = d.debitor_code	
	left join dbo.debitors (nolock) d on a.DEBITOR_CODE = d.debitor_code	
	left join  dbo.debitors_section2 s (nolock) on s.debitor_code = d.debitor_code     
	left join  dbo.provincies p (nolock) on p.provinciecode = u.Adjuster_Province
	left join dbo.CITIESAREAS (nolock) c on c.CODE = u.Adjuster_CityCode
	left join vwDIAL_AdjusterRoles v (nolock) on v.value = u.Adjuster_UserRole_Id
	inner join dbo.EMPLOYEES E(nolock) ON E.TUSR=A.EMPLOYEE_ID 
	where ltrim(rtrim(a.status)) ='A'-- and u.Status = 'A' 	
	and DAA_FIRST_NAME != '' and DAA_LAST_NAME != '' 
	and DAA_FIRST_NAME != 'UNKNOWN' and DAA_LAST_NAME != 'UNKNOWN'  
	and DAA_FIRST_NAME != '**' and DAA_LAST_NAME != '**'  
	--and d.DEBITOR_CODE > 0 and adj.INS_COMPANY_ID > 0 
	--and a.DEBITOR_CODE > 0 
	and d.DEBITOR_TYPE='O' and in_stop_list = 'a'
	AND (@SEARCH IS NULL OR  @SEARCH ='' or DAA_FIRST_NAME LIKE '%'+ @SEARCH+'%'  or DAA_LAST_NAME LIKE '%'+ @SEARCH+'%')
	AND (@debitor_code = 0 OR @DEBITOR_CODE IS NULL OR D.DEBITOR_CODE = @DEBITOR_CODE)
	order by 1  

END


--select DAA_ENTRY_ID , daa_first_name , daa_last_name from da_adjuster
--order by 2


