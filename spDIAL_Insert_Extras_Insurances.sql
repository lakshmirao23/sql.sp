USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Insert_Extras_Insurances]    Script Date: 04/05/2018 09:37:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 -- exec [spdial_insert_extras_insurances] @entryid = 3145306, @code='WT', @price='5.00'

ALTER proc [dbo].[spDIAL_Insert_Extras_Insurances] 
@entryid bigint, @code varchar(4), @price float
as

declare @ilatestauthid bigint
select  @ilatestauthid = max(dca_entry_id) from  da_authorization where dca_claim_id = @entryid

if @code = 'WT' or @code = 'UF'
if not exists 
(select dae_extra_code from da_authorization_extras (nolock) where dae_auth_entry_id=@ilatestauthid and dae_extra_code=@code)
begin
	insert into	da_authorization_extras(dae_auth_entry_id, dae_extra_code, dae_price) values 
	(@ilatestauthid, @code, @price)
end

if @code = 'CDW'
if not exists 
(
select dae_insurance_code from da_authorization_insurances (nolock) where dae_auth_entry_id=@ilatestauthid and dae_insurance_code=@code
)
begin
insert into	da_authorization_insurances(dae_auth_entry_id, dae_insurance_code, dae_price) values 
(@ilatestauthid, @code, @price)
end

--select * from da_authorization_extras where dae_auth_entry_id=30713012
--select * from da_authorization_insurances where dae_auth_entry_id=30713012
--select * from da_authorization where dca_claim_id=3145306

