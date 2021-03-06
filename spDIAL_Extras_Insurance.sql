USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Extras_Insurance]    Script Date: 04/05/2018 09:35:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec spDIAL_Extras_Insurance 3193158  , 16837, 3, 'F'

--select * from [tblDIAL_InsuranceExtra_Default] where VEHICLE_CLASS = 'G'
-- exec [dbo].[spDIAL_Extras_Insurance] @Claim_Entry_ID = 3188320 
-- exec [dbo].[spDIAL_Extras_Insurance] @Claim_Entry_ID = 3154113
--exec [dbo].[spDIAL_Extras_Insurance] @Claim_Entry_ID = 3156033
-- exec [dbo].[spDIAL_Extras_Insurance] @Claim_Entry_ID = 3154251
-- exec [dbo].[spDIAL_Extras_Insurance] @Claim_Entry_ID = 3154335
-- exec [dbo].[spDIAL_Extras_Insurance] @Debitor_Code  = 16369, @Province_Code  =3 , @Vehicle_Class  = 'A'
--exec [dbo].[spDIAL_Extras_Insurance] @Debitor_Code  = 16957, @Province_Code  =3 , @Vehicle_Class  = 'A'
--According to lakshmi: if there is no [DAC_RENTAL_CHECK_OUT_BRANCH_CODE],[DAC_LOCATION_CODE], using ontario province.
--exec spDIAL_Extras_Insurance 3183127, 16837, 3, 'C'
ALTER Proc [dbo].[spDIAL_Extras_Insurance] @Claim_Entry_ID bigint = null,
@Debitor_Code bigint = 16957, @Province_Code int =3 , @Vehicle_Class varchar(10) = 'A'
as

--Tim modify 20130711 as Lashimi mentioned always has province code and vehicle class input
--For CDW just look for rate_insurance
--for UF and WT, if not found, then looking default value for tblDial_InsuranceExtra_Default table
declare @tblExtra table  (
Extras_type varchar(1),
Extras_Description varchar(150),
Extra_or_Insurance_Code varchar(10),
Rate float,
Car_Group Varchar(10),
IsSelected bit default(0)
)

declare @sRentalClass varchar(10), @sAuthClass varchar(10), @sInsuredClass varchar(10), @sFinalClass varchar(10)
,  @iProvince_Code int, @iBranch_Code int, @iDebitor_Code bigint, @bIsRateOutBranchUsed bit = 1

Insert into @tblExtra (Extras_type, Extra_or_Insurance_Code, Extras_Description)
Select 'I', 'CDW', 'Collision Damage Waiver'
--union
--Select 'DF'
union
Select 'E','UF', 'UnderAge Fee'
union
Select 'E','WT', 'Winter Tire'

if @Claim_Entry_ID is not null
begin
--Need to know Rental Vehicle Car class, auth class and insured class,  
--First find Auth Class
--	select @sRentalClass = DAC_RENTAL_CAR_GROUP, @sInsuredClass = case  when NOT (InsuredClass IS null OR LTRIM(rtrim(InsuredClass))='')  then InsuredClass else EQUIVALENT_CLASS end
--	, @iBranch_Code = case when [DAC_RENTAL_CHECK_OUT_BRANCH_CODE] !=0 then [DAC_RENTAL_CHECK_OUT_BRANCH_CODE] else [DAC_LOCATION_CODE] end
--	, @iDebitor_Code =DAC_INS_COMPANY_ID
--	from
--	(
--	select DAC_RENTAL_CAR_GROUP,
--	case when VEHICLE_CLASS IS null or ltrim(rtrim(VEHICLE_CLASS)) = '' then  DAC_EQUIVALENT_GROUP
--	else VEHICLE_CLASS end InsuredClass
--	, b.EQUIVALENT_CLASS 
--	, [DAC_RENTAL_CHECK_OUT_BRANCH_CODE]
--	,[DAC_LOCATION_CODE]
--	, DAC_INS_COMPANY_ID
--	from DA_CLAIMS a(nolock) Left join
--	EXTERNAL_MAKE_MODEL b (nolock)
--	on a.DAC_MAKE = b.MAKE
--	and a.DAC_MODEL = b.MODEL
--	where DAC_ENTRY_ID = @Claim_Entry_ID
--	) t

----latest auth vehicle class
--	select @sAuthClass = case when not (MYAUTHORIZATION.DCA_AUTH_VEHICLE IS null or ltrim(rtrim(MYAUTHORIZATION.DCA_AUTH_VEHICLE)) ='') then MYAUTHORIZATION.DCA_AUTH_VEHICLE else FIRST_CHARGE_GROUP end
--	from
--	(
--	select aa.DCA_CLAIM_ID,  bb.DAC_VEH_EQUIV, bb.DCA_AUTH_VEHICLE,bb.FIRST_CHARGE_GROUP
--	from (
--	select DCA_CLAIM_ID, MAX(dca_entry_id) as MaxEntryID
--	from dbo.DA_AUTHORIZATION(nolock) 
--	where DCA_BILL_TO =1 -- 1 for insurance 2 for Driver
--	--where DCA_CLAIM_ID =1723462
--	--group by DCA_CLAIM_ID
--	  group by DCA_CLAIM_ID
--	  ) aa inner join dbo.DA_AUTHORIZATION bb(nolock) 
--	  on aa.MaxEntryID = bb.DCA_ENTRY_ID
--	) MYAUTHORIZATION 
--	where  MYAUTHORIZATION.DCA_CLAIM_ID =@Claim_Entry_ID

--	select @sRentalClass = ltrim(rtrim(@sRentalClass)),  @sAuthClass = ltrim(rtrim(@sAuthClass)), @sInsuredClass = ltrim(rtrim(@sInsuredClass))
--	,@iProvince_Code = case when @iBranch_Code = 0 then 3  --default Ontario
--	else 
--		PROVINCE_CODE
--	end
--	from BRANCHES(nolock)
--	where BRANACH_CODE =@iBranch_Code

--select @sRentalClass ,  @sAuthClass ,@sInsuredClass 

	--if @sRentalClass =  @sAuthClass and LEN(@sAuthClass) >0 and  LEN(@sRentalClass) >0 
	--	select @sFinalClass= @sAuthClass
	--else  if len(@sRentalClass) =  0 and LEN(@sAuthClass) = 0 and LEN(@sInsuredClass) >0
	--	select @sFinalClass= @sInsuredClass
	--else  if len(@sRentalClass) >  0 and LEN(@sAuthClass) = 0 
	--	select @sFinalClass= @sRentalClass
	--else  if len(@sRentalClass) =  0 and LEN(@sAuthClass) > 0 
	--	select @sFinalClass= @sAuthClass

--print 	@sRentalClass
--print  @sAuthClass
	--if @sRentalClass !=  @sAuthClass and LEN(@sAuthClass) >0 and  LEN(@sRentalClass) >0 	--need to see which class rate is lower
	--begin	
	
	--	if ((select [Rate] from [dbo].[tblDIAL_InsuranceExtra_Default] (nolock)
	--		where [Vehicle_Class] =@sRentalClass and Insurance_Extra_Code ='CDW' and Province_Code = @Province_Code) >=
	--		(select [Rate] from [dbo].[tblDIAL_InsuranceExtra_Default] (nolock)
	--		where [Vehicle_Class] =@sAuthClass  and Insurance_Extra_Code ='CDW' and Province_Code = @Province_Code))
	--	select @sFinalClass =@sAuthClass
	--	else
	--	select @sFinalClass =@sRentalClass				
	--end
--Default value

--CDW
	select @sFinalClass= @Vehicle_Class
	
	update a
	set Rate =t1.Rate, Car_Group = t1.Vehicle_Class
	from @tblExtra a inner join [dbo].[tblDIAL_InsuranceExtra_Default] t1
	--on a.Car_Group =t1.Vehicle_Class
	on a.Extra_or_Insurance_Code = t1.Insurance_Extra_Code
	where t1.Vehicle_Class =@sFinalClass 
	--and t1.Province_Code = @iProvince_Code
	and t1.Province_Code = @Province_Code
	and t1.Insurance_Extra_Code ='CDW'	

	--WT, UF

	update a
	set Rate =b.Rate, Car_Group =@sFinalClass
	from @tblExtra a inner join 
	[dbo].[tblDIAL_InsuranceExtra_Default] b(nolock)
	on a.Extra_or_Insurance_Code = b.Insurance_Extra_Code
	where ltrim(rtrim(a.Extra_or_Insurance_Code)) in ('UF','WT') --UNDER AGE FEE, DROP FEE, WINTER TIRE 

	--According Lashmi 20130425, if not in setup, don't show it

	Declare @iLatestAuthID bigint

	select  @iLatestAuthID = max(DCA_ENTRY_ID) from  DA_AUTHORIZATION where DCA_CLAIM_ID = @Claim_Entry_ID

	--print convert(varchar(20),@iLatestAuthID)

	update a
	set IsSelected = case when t1.PRICE >0 then 1 else 0 end, rate =PRICE
	from @tblExtra a inner join 
	(
	select distinct [DAE_AUTH_ENTRY_ID] Claim_Entry_ID
		  ,[DAE_EXTRA_CODE] EXTRA_CODE
		  ,[DAE_PRICE] PRICE 
	FROM [dbo].[DA_AUTHORIZATION_EXTRAS](nolock)
	where [DAE_AUTH_ENTRY_ID] =@iLatestAuthID
	and DAE_EXTRA_CODE  in ('UF','WT') --UNDER AGE FEE, DROP FEE, WINTER TIRE 
	union
	select [DAE_AUTH_ENTRY_ID]
		  ,[DAE_INSURANCE_CODE]
		  ,[DAE_PRICE]
	FROM [dbo].[DA_AUTHORIZATION_INSURANCES](nolock)
	where [DAE_AUTH_ENTRY_ID] =@iLatestAuthID
	and ltrim(rtrim([DAE_INSURANCE_CODE])) ='CDW'
	) t1
	on a.Extra_or_Insurance_Code = t1.EXTRA_CODE

	select Extras_type,Extra_or_Insurance_Code, round(Rate,2) Rate, Car_Group, IsSelected,Extras_Description from @tblExtra where rate is not null

end 
else -- @Claim_Entry_ID is null
begin

--CDW


	update a
	set Rate =t1.Rate, Car_Group = t1.Vehicle_Class
	from @tblExtra a inner join [dbo].[tblDIAL_InsuranceExtra_Default] t1
	--on a.Car_Group =t1.Vehicle_Class
	on a.Extra_or_Insurance_Code = t1.Insurance_Extra_Code
	where t1.Vehicle_Class =@Vehicle_Class 
	and t1.Province_Code = @Province_Code
	and t1.Insurance_Extra_Code ='CDW'	

	--WT, UF

	update a
	set Rate =b.Rate, Car_Group =@Vehicle_Class
	from @tblExtra a inner join 
	[dbo].[tblDIAL_InsuranceExtra_Default] b(nolock)
	on a.Extra_or_Insurance_Code = b.Insurance_Extra_Code
	where ltrim(rtrim(a.Extra_or_Insurance_Code)) in ('UF','WT') --UNDER AGE FEE, DROP FEE, WINTER TIRE 


select Extras_type, Extra_or_Insurance_Code, round(Rate,2) Rate, Car_Group, IsSelected, Extras_Description from @tblExtra where rate is not null

end




