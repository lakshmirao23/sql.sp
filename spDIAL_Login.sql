USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Login]    Script Date: 04/05/2018 09:37:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--  select  * from DA_ADJUSTER where DAA_ENTRY_ID=17724

-- exec [spDIAL_Login] 
ALTER Proc [dbo].[spDIAL_Login]
@UserName varchar(30) = 'Rentaldesk', @password varchar(30) = '17724', 
@ipAddress varchar(15) = '127.0.0.1'
as

	SELECT distinct FIRST_NAME , LAST_NAME, d.debitor_name as DAA_INS_COMPANY_NAME, 
	a.debitor_code as DebitorCode, DAA_ENTRY_ID as AdjusterId, A.EMPLOYEE_ID,
	u.Adjuster_UserRole_Id, u.Adjuster_Province , u.adjuster_citycode, rtrim(ltrim(c.name)) as CityName , rtrim(ltrim(pv.provincienaam)) as ProvinceName,  
	case 
	when p.debitor_code = a.DEBITOR_CODE  then
	'Y'   
	else
	'N'
	end as 'Dominion', t.Total_Tax_rate as TotalTax, isnull(d.DAYS_CALC_LOGIC, 'D') as CompanyType
	FROM dbo.DA_ADJUSTER A(nolock)
	INNER JOIN EMPLOYEES E(nolock) ON E.TUSR=A.EMPLOYEE_ID 
	left join [tblDIAL_AdjusterUserRoleDetails] u (nolock)  on u.AdjusterId = a.DAA_ENTRY_ID
	left join CITIESAREAS c (nolock) on c.code = u.adjuster_citycode 
	left join provincies pv (nolock)  on pv.provinciecode = u.Adjuster_Province
	left join tblDIAL_Province_Tax t (nolock)  on t.province_code = u.Adjuster_Province
	left join PORTAL_DEBITOR_SETUP p (nolock) on p.DEBITOR_CODE = a.DEBITOR_CODE
	left join debitors d (nolock) on d.DEBITOR_CODE = a.DEBITOR_CODE
	WHERE  A.EMPLOYEE_ID = @UserName and e.EMP_PASSWORD= @password --and e.EMP_STATUS = '1' 
	and a.STATUS='A'
	
	declare @count int
	declare @flag bit
	
	select @count = COUNT(*) 
	FROM dbo.DA_ADJUSTER A(nolock)
	INNER JOIN EMPLOYEES E(nolock) ON E.TUSR=A.EMPLOYEE_ID 
	WHERE  e.TUSR = @UserName and e.EMP_PASSWORD= @password and e.EMP_STATUS = '1'	
	
	if @count >= 1
		set @flag = 1
	else
		set @flag = 0
	
	insert into tblDIAL_UsersLog (Adjuster_Username, ip_address, flag, Process_Code) 
	values (@UserName, @ipAddress, @flag, 0)
	
	--Process_Code = 0 Means LoggedIn
	

	--  select * from [tblDIAL_AdjusterUserRoleDetails]
	-- select * from tblDIAL_UsersLog
	-- select * from tblDIAL_Province_Tax
	
	
