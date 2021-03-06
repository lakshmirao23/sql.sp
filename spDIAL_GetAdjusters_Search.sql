USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_GetAdjusters_Search]    Script Date: 04/05/2018 09:36:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<LAKSHMI RAO>
-- Create date: <JANUARY 25, 2013>
-- Description:	<To populate Adjusters for the selected Debitor for MyFiles>
-- =============================================

--EXEC [spDIAL_GetAdjusters_Search] 17146
ALTER PROCEDURE [dbo].[spDIAL_GetAdjusters_Search] 
@DEBITOR_CODE bigint
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	declare @SuvDebitor bigint
	
	select top 1 @SuvDebitor = SUV_DEBITOR_OF from DEBITORS (nolock) where DEBITOR_CODE=@DEBITOR_CODE

	select '-- FOR ALL ADJUSTERS --' AdjusterName, -1 daa_entry_id, -1 debitor_code
	union
	select distinct (daa_first_name + ' ' + daa_last_name) AS AdjusterName, 
	daa_entry_id, a.debitor_code  
	from dbo.da_adjuster a (nolock) 
	inner join ADJUSTER_DEBITORS adj (nolock) on adj.ADJUSTER_ID = a.DAA_ENTRY_ID
	left join dbo.debitors (nolock) d on adj.INS_COMPANY_ID = d.debitor_code	
	left join  dbo.debitors_section2 s (nolock) on s.debitor_code = d.debitor_code     
	where status='a' 
	AND d.SUV_DEBITOR_OF = @SuvDebitor
	and DAA_FIRST_NAME != '' and DAA_LAST_NAME != '' 
	and d.DEBITOR_CODE > 0 and adj.INS_COMPANY_ID > 0 and a.DEBITOR_CODE > 0 
	and d.DEBITOR_TYPE='O' and in_stop_list = 'a'	
	order by 1 

END
