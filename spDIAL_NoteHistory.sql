USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_NoteHistory]    Script Date: 04/05/2018 09:39:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec spDIAL_NoteHistory 3165007, @pagetype = 'List'
-- exec spDIAL_NoteHistory 3165007, @pagetype = 'Entry'
ALTER Proc [dbo].[spDIAL_NoteHistory] @ClaimEntryID bigint, @pagetype varchar(20)
as
--	WHEN DCN_NOTES_TYPE =1 THEN 'Notes To Discount Location'
--WHEN DCN_NOTES_TYPE =2 THEN 'Internal ICC Notes'
--WHEN DCN_NOTES_TYPE =3 THEN 'Authorization Notes'
--WHEN DCN_NOTES_TYPE =4 THEN 'Notes To Adjuster'
--WHEN DCN_NOTES_TYPE =6 THEN 'Notes From Adjuster '

	
  --Note history
  if @pagetype ='Entry'
  begin
	--select CONVERT( date, CONVERT(varchar(8),dcn_date,112) ) [Date]
	select dbo.fn_ConvertYYYYMMDDtoDIAL(dcn_date) [Date]
  					,CONVERT( time, dateadd(second,DCN_TIME, '01/01/2000') ) [Time]
  					,DCN_NOTES Comments
  					,case 
  						  when DCN_NOTES_TYPE =1 then 'Notes to Discount Location' 
  						  when DCN_NOTES_TYPE =3 then 'Authorization' 
  						  when DCN_NOTES_TYPE =4 then 'Request' 
  						  when DCN_NOTES_TYPE =5 then 'Notes To BodyShop' 
						  WHEN DCN_NOTES_TYPE =6 THEN 'Notes From Adjuster'
						  when DCN_NOTES_TYPE =7 then 'Notes From Bodyshop'
  					end
  					as [Type]
  					,b.FIRST_NAME + ' ' + b.LAST_NAME [User]
  					--,* 
  					FROM DA_NOTES_HISTORY a(nolock)
  					left join EMPLOYEES b(nolock) on ltrim(rtrim(a.dcn_user_id)) =ltrim(rtrim(b.TUSR))   					
					--WHERE  DCN_CLAIM_ID =    3144752 
					WHERE  DCN_CLAIM_ID = @ClaimEntryID
					and DCN_NOTES_TYPE in (1,3,4)
					ORDER BY DCN_DATE DESC,DCN_TIME Desc					
	--union	
	--	select  dbo.fn_ConvertYYYYMMDDtoDIAL(DCA_MODIFIED_DATE) [Date]
 -- 					,'' [Time]
 -- 					,dca_auth_notes Comments
 -- 					,'Authorization' as [Type]
 -- 					,b.FIRST_NAME + ' ' + b.LAST_NAME [User] from DA_AUTHORIZATION (nolock) a 
 -- 					left join EMPLOYEES b(nolock) on ltrim(rtrim(a.dca_submitter)) =ltrim(rtrim(b.TUSR))   					
 -- 					where DCA_CLAIM_ID=@ClaimEntryID and LTRIM(rtrim(dca_auth_notes)) !=''				
  					
		
	end
	else if @pagetype ='List'  --need to modify --also not show discount branch location note. Show all other.
	begin
	--select CONVERT( date, CONVERT(varchar(8),dcn_date,112) ) [Date]
	select dbo.fn_ConvertYYYYMMDDtoDIAL(dcn_date) [Date]
  					,CONVERT( time, dateadd(second,DCN_TIME, '01/01/2000') ) [Time]
  					,DCN_NOTES Comments
  					,case 
  						  when DCN_NOTES_TYPE =1 then 'Notes to Discount Location' 
  						  when DCN_NOTES_TYPE =3 then 'Authorization' 
  						  when DCN_NOTES_TYPE =4 then 'Request' 
  						  when DCN_NOTES_TYPE =5 then 'Notes To BodyShop' 
						  WHEN DCN_NOTES_TYPE =6 THEN 'Notes From Adjuster'
						  when DCN_NOTES_TYPE =7 then 'Notes From Bodyshop'

-- WHEN DCN_NOTES_TYPE =1 THEN 'Notes To Discount Location'
--WHEN DCN_NOTES_TYPE =2 THEN 'Internal ICC Notes'
--WHEN DCN_NOTES_TYPE =3 THEN 'Authorization Notes'
--WHEN DCN_NOTES_TYPE =4 THEN 'Notes To Adjuster'
--WHEN DCN_NOTES_TYPE =6 THEN 'Notes From Adjuster '
 
  					end
  					as [Type]
  					,b.FIRST_NAME + ' ' + b.LAST_NAME [User]
  					--,* 
  					FROM DA_NOTES_HISTORY a(nolock)
  					left join EMPLOYEES b(nolock)
  					on ltrim(rtrim(a.dcn_user_id)) =ltrim(rtrim(b.TUSR))  					
					--WHERE  DCN_CLAIM_ID =    3144752 
					WHERE  DCN_CLAIM_ID = @ClaimEntryID
					and DCN_NOTES_TYPE not in (2,8,9,10,11,12,13)
					ORDER BY DCN_DATE DESC,DCN_TIME Desc
				
--union	
--		select  dbo.fn_ConvertYYYYMMDDtoDIAL(DCA_MODIFIED_DATE) [Date]
--  					,'' [Time]
--  					,dca_auth_notes Comments
--  					,'Authorization' as [Type]
--  					,b.FIRST_NAME + ' ' + b.LAST_NAME [User] from DA_AUTHORIZATION (nolock) a 
--  					left join EMPLOYEES b(nolock) on ltrim(rtrim(a.dca_submitter)) =ltrim(rtrim(b.TUSR))   					
--  					where DCA_CLAIM_ID=@ClaimEntryID and LTRIM(rtrim(dca_auth_notes)) !=''			
  							
	
	
	end
	
	
--1 -  To Discount Location
--2 -  Internal ICC Notes
--3 -  Auth Notes
--4 -  To Adjuster
--5 -  To Bodyshop
--6 -   From  Adjuster
--7 -   From Bodyshop
--8 -   From Discount Location
--9 -   From Claim
--10-  To Claim
--11-  Claim Department
--12 - Reservation Notes
--13 - Agreement Notes




