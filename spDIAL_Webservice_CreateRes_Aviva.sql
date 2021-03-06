USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Webservice_CreateRes_Aviva]    Script Date: 04/05/2018 09:41:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec [spDIAL_Webservice_CreateRes_Aviva]
--grant exec on [spDIAL_Webservice_CreateRes_Aviva] to crystal

ALTER procedure [dbo].[spDIAL_Webservice_CreateRes_Aviva]
@username varchar(50) =  'aviva',
@password varchar(50) =  'webservice',
@requestID varchar(50) =  'CC:a15d5e3b-7921-46d4-adf2-e949dc4585f9',
@action varchar(50) =  'insert',
@entry_id varchar(10) =  '',
@ins_company_ID varchar(30) =  '16367',
@adjuster_user_name varchar(10) =  'Test Adjuster Auto_1',
@adjuster_first_name varchar(69) =  'Test Adjuster',
@adjuster_last_name varchar(69) =  'Auto_1',
@adjuster_phone_number varchar(20) =  '(818) 446-1100 x561212',
@referral_adjuster_name varchar(10) =  'Test Adjuster Auto_1',
@insured_first_name varchar(69) =  'MARIA (UAT TESTING)',
@insured_last_name varchar(69) =  'MENDICINO',
@insured_telephone varchar(20) =  '(416) 701-4371',
@insured_business_number varchar(20) =  '',
@insured_address varchar(255) =  '311 HARVIE AVENUE, null',
@insured_city varchar(60) =  'TORONTO',
@insured_postal_code varchar(40) =  'M6E 4L2',
@client_email varchar(100) =  'maria_mendicino@avivacanada.com',
@policy_number varchar(30) =  'A12601646PLA',
@claim_number varchar(30) =  '35006790',
@additional_driver_name varchar(100) =  '',
@alternate_phone varchar(20) =  '',
@repair_location varchar(200) =  'Fix Auto Oshawa',
@repair_location_phone varchar(20) =  '',
@repair_location_address varchar(300) =  '970 Nelson St, null, Oshawa, ON L1H 8L6',
@repair_location_postal_code varchar(30) =  'L1H 8L6',
@repair_location_city varchar(50) =  'Oshawa',
@discount_location varchar(50) =  '1975 Eglinton Ave E, Scarborough, ON',
@date_of_loss varchar(12) =  '2013-12-04',
@taxes_paid_by varchar(20) =  'insurance',--customer, insurance
@total_loss varchar(3) =  'no',
@claim_type varchar(50) =  'collision', --collision, comp, theft
@policy_max varchar(50) =  '0',
@transferable_coverage varchar(50) =  'no',--yes, no
@third_party varchar(50) =  'no', --yes, no
@transferable_coverage_paid_by varchar(50) =  'insurance', --customer, insurance
@vehicle_year varchar(50) =  '2003',
@insured_vehicle_make varchar(50) =  'DODGE',
@insured_vehicle_model varchar(50) =  'CARAVAN SE/SP/SXT',
@authorized_rate varchar(50) =  '29.99',
@pickup_date varchar(50) =  '2013-12-10', -- mm/dd/yyyy
@authorized_to_date varchar(12) =  '2013-12-16',
@days_authorized varchar(50) =  '5',
@note varchar(325) =  '',
@final_authorization varchar(50) =  'yes', --yes, no
@rental_controlled_by varchar(50) =  'Claims Adjuster', --Claims Adjuster, Rental Desk, DRVP
@alternate_driver varchar(50) =  '', --yes, no
@alternate_driver_name varchar(100) =  '',
@alternate_driver_phone varchar(20) =  '',
@alternate_driver_address varchar(255) =  '',
@alternate_driver_city varchar(60) =  '',
@alternate_driver_postal_code varchar(50) =  '',
@estimate_repair_hours varchar(50) =  '0',
@estimate_rental_period varchar(50) =  '6',
@upgrade_requested varchar(50) =  'no',
@existing_discount_rental varchar(50) =  'no',
@contract_number varchar(50) =  ''

as

begin

declare @LoggedInUserName varchar(100) = 'Supervisor'
Declare @myEntryID bigint, @myAuthEntryID bigint
Declare @AdjusterLastName varchar(30),@AdjusterFirstName varchar(30), @AdjusterTelephoneNo varchar(20), @TP_Ins_PhoneNo varchar(20), @DebitorPhone varchar(20)
Declare @LocName varchar(200), @LocAddress varchar(300), @LocArea varchar(20), @LocCity varchar(50), @LocPostalCode varchar(30), @LocPhone varchar(200), @LocFax varchar(200)
Declare @InsuredEquivClass varchar(3) = ''
declare @dFinalTotal decimal(18,2), @dTotalExtras decimal(18,2), @dTotalInsurances decimal(18,2), @dTotalTaxes decimal(18,2)
Declare @myNoteID bigint, @ModyorCreatedByUser varchar(30), @ModyorCreatedDate varchar(8), @ModyorCreateTime int, @AuthFromDate varchar(8)
declare @RATE_SR_NO int, @PST decimal(18,2), @GSTorHST decimal(18, 2), @CompanyCode int=1
declare @RATE_DET_SR_NO int, @Rental_Package varchar(10) ='1D', @DAC_Status int, @TotalRental decimal(18,2)
declare @ClaimDesc varchar(30) = '', @TaxPaidByDesc varchar(30) = ''
declare @ProvinceCode int
Declare @VLI_Rate decimal(18,2) = 0
declare @DB varchar(30), @DebitorName varchar(300)
declare @Authorizedrate decimal(18,2) 
declare @AdjusterID bigint, @DebitorCode bigint
declare @bFlag as bit = 0
declare @ErrorMsg as varchar(500)
declare @ErrorCode as int
declare @TaxPaidByVal as int
declare @IntDaysAuthorized int
declare @DecPolicyMax decimal(18,2)
declare @ClaimTypeVal int	
declare @transferrable_coverage_val varchar(1)	
declare @transferrable_coverage_paid_by_Desc varchar(100), @transferrable_coverage_paid_by_val int, @AdjusterEmailAddress varchar(1000)

declare @date_of_loss_CP varchar(8)
declare @authorized_to_date_CP varchar(8)
declare @pickup_date_CP varchar(8)
		
select @TaxPaidByVal = code from vwDIAL_PaidBy where value=@taxes_paid_by	
select @transferrable_coverage_paid_by_val = code from vwDIAL_PaidBy where code= @transferable_coverage_paid_by		
select @ClaimTypeVal = isnull(value, 2) from vwDIAL_ClaimType where text=@claim_type

set @DebitorCode = @ins_company_ID

if ISNUMERIC(@days_authorized) = 1  
begin
	set @IntDaysAuthorized = @days_authorized	
end
else
begin
	set @IntDaysAuthorized = 0	
end	

if ISNUMERIC(@policy_max) = 1  
begin
	set @DecPolicyMax = @policy_max	
end
else
begin
	set @DecPolicyMax = 0	
end	


if isdate(convert(datetime, @date_of_loss)) = 1  
begin
	select @date_of_loss_CP =convert(varchar(8), convert(datetime, @date_of_loss), 112)
end
else
begin
	select @date_of_loss_CP = '00000000'	
end	

if isdate(convert(datetime, @authorized_to_date)) = 1  
begin
	set @authorized_to_date_CP = CONVERT(varchar(8), convert(datetime, @authorized_to_date), 112)
end
else
begin
	set @authorized_to_date_CP = '00000000'	
end	

if isdate(convert(datetime, @pickup_date)) = 1  
begin
	set @pickup_date_CP = CONVERT(varchar(8), convert(datetime, @pickup_date), 112)
end
else
begin
	set @pickup_date_CP = '00000000'	
end	


set @bFlag = 0

--if @bFlag = 0
--begin
--	if isnull(@action,'') = '' 
--	begin
--		set @bFlag = 1
--		set @ErrorMsg = 'Action is undefined'
--		set @ErrorCode = '2004'
--	end
--end

--if @bFlag = 0
--begin
--	if isnull(@action,'') != 'insert'  and isnull(@action,'') != 'update' and isnull(@action,'') != 'cancel'
--	begin
--		set @bFlag = 1
--		set @ErrorMsg = 'Invalid Action'
--		set @ErrorCode = '2005'
--	end
--end

--if @bFlag = 0
--begin
--	if isnull(@RequestID, '') = ''
--	begin
--		set @bFlag = 1
--		set @ErrorMsg = 'RequestID is undefined'
--		set @ErrorCode = '2006'
--	end
--end

--if @bFlag = 0
--begin
--	if exists (select requestid from tblAviva_GW_Logs (nolock) where requestid=@RequestID)
--	begin
--		set @bFlag = 1
--		set @ErrorMsg = 'RequestID is not Unique'
--		set @ErrorCode = '2007'
--	end
--end

--if @bFlag = 0 
--begin
--	if isnull(@claim_number, '') = '' and isnull(@policy_number, '') = ''
--	begin
--		set @bFlag = 1
--		set @ErrorMsg = 'Claim No and Policy No are blank'
--		set @ErrorCode = '2016'
--	end
--end

--if @bFlag = 0
--begin
--	if not exists (select value from dbo.vwDIAL_PaidBy (nolock) where value=@taxes_paid_by)
--	begin
--		set @bFlag = 1
--		set @ErrorMsg = 'Invalid Taxes Paid By.'
--		set @ErrorCode = '2017'
--	end
--end


--if @bFlag = 0
--begin
--	if isnull(@transferable_coverage, '') = '' 
--	begin
--		set @bFlag = 1
--		set @ErrorMsg = 'Transferable Coverage is undefined.'
--		set @ErrorCode = '2018'
--	end
--end

--if @bFlag = 0
--begin
--	if isnull(@transferable_coverage, '') != 'yes'  and  isnull(@transferable_coverage, '') != 'no'
--	begin
--		set @bFlag = 1
--		set @ErrorMsg = 'Invalid Transferable Coverage'
--		set @ErrorCode = '2019'
--	end
--end

--if @bFlag = 0
--begin
--	if isnull(@transferable_coverage, '') = 'NO' and ISNULL(@transferable_coverage_paid_by, '') = ''
--	begin
--		set @bFlag = 1
--		set @ErrorMsg = 'Transferable Coverage Paid By is undefined.'
--		set @ErrorCode = '2020'
--	end
--end

--if @bFlag = 0
--begin
--	if isnull(@transferable_coverage, '') = 'NO' 
--	begin
--		if not exists (select value from dbo.vwDIAL_PaidBy (nolock) where value=@transferable_coverage_paid_by)
--		begin
--			set @bFlag = 1
--			set @ErrorMsg = 'Invalid Transferable Coverage Paid By.'
--			set @ErrorCode = '2021'
--		end
--	end
--end

if @bFlag = 0
begin	

	if not exists (SELECT employee_id FROM DA_ADJUSTER (nolock) WHERE EMPLOYEE_ID = @adjuster_user_name)
	begin	
		SELECT @adjuster_user_name = EMPLOYEE_ID, @AdjusterEmailAddress = DAA_EMAIL 
		FROM DA_ADJUSTER (nolock) WHERE DAA_FIRST_NAME = @adjuster_first_name and DAA_LAST_NAME = @adjuster_last_name
	end
	else
	begin
		if @DebitorCode = 16373
			SELECT @adjuster_first_name = DAA_FIRST_NAME , @adjuster_last_name = DAA_LAST_NAME, @AdjusterEmailAddress = DAA_EMAIL 
			from DA_ADJUSTER (nolock) where EMPLOYEE_ID='QC_AVIVA'
		else
			SELECT @adjuster_first_name = DAA_FIRST_NAME , @adjuster_last_name = DAA_LAST_NAME, @AdjusterEmailAddress = DAA_EMAIL 
			from DA_ADJUSTER (nolock) where EMPLOYEE_ID='ON_AVIVA'
	end		

	SELECT @DebitorPhone = phone1, @DebitorName = isnull(ltrim(rtrim(DEBITOR_NAME)), '') FROM DEBITORS (NOLOCK) WHERE DEBITOR_CODE = @DebitorCode

	select top 1 @InsuredEquivClass =  ltrim(rtrim(EQUIVALENT_CLASS)) from EXTERNAL_MAKE_MODEL (nolock) 
	where ltrim(rtrim(make)) = @insured_vehicle_make and ltrim(rtrim(model)) like '%'+@insured_vehicle_model+'%' 

	select @myEntryID = DND_DOCUMENT_NUMBER+1 from DOCUMENT_NUMBERS_DISCOUNT(nolock)
	WHERE DND_COMPANY_CODE = 0 AND DND_BRANCH_CODE = 0 AND DND_DOCUMENT_TYPE = 84		
		
	UPDATE DOCUMENT_NUMBERS_DISCOUNT SET  DND_DOCUMENT_NUMBER = @myEntryID 
	WHERE DND_COMPANY_CODE = 0 AND DND_BRANCH_CODE = 0 AND DND_DOCUMENT_TYPE = 84

	select @myAuthEntryID = DND_DOCUMENT_NUMBER+1
	from DOCUMENT_NUMBERS_DISCOUNT(nolock)
	WHERE DND_COMPANY_CODE = 0 AND DND_BRANCH_CODE = 0 AND DND_DOCUMENT_TYPE = 90		
		
	UPDATE DOCUMENT_NUMBERS_DISCOUNT SET  DND_DOCUMENT_NUMBER = @myAuthEntryID 
	WHERE DND_COMPANY_CODE = 0 AND DND_BRANCH_CODE = 0 AND DND_DOCUMENT_TYPE = 90

	set @ModyorCreatedByUser = @LoggedInUserName
	set @ModyorCreatedDate = CONVERT(varchar(8), GETDATE(), 112)
	set @ModyorCreateTime = DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate())

		if LEFT( @authorized_to_date_cp, 4) >= '2013'
			set @AuthFromDate = convert(varchar(8), DATEADD(d, -@IntDaysAuthorized, convert(varchar(8), @authorized_to_date_cp, 112)), 112)
		else
			set @AuthFromDate = convert(varchar(8), convert(varchar(8), GETDATE(), 112))
			set @authorized_to_date_cp =  convert(varchar(8), DATEADD(d, @IntDaysAuthorized, convert(varchar(8), @AuthFromDate, 112)), 112)	

			set @CompanyCode = 1			
			
			select @GSTorHST = national_vat, @PST=SERVICE_FEE from DEFAULT_CONTROL (nolock) where COMPANY_NO=@CompanyCode

			select @RATE_SR_NO = rs.RATE_SR_NO, @RATE_DET_SR_NO = rs.RATE_DET_SR_NO, @Authorizedrate = rs.CUSTOMER_PER_DAY from DEBITORS d (nolock) 
			inner join TARIFF_RATES t (nolock) on d.TARIFF_CODE = t.TARIFF_CODE 
			inner join RATES_SECTION_2 rs (nolock) on t.RATE_NO = rs.RATE_NO
			where d.DEBITOR_CODE = @DebitorCode and rs.F_GROUP = @InsuredEquivClass
			and rs.RENTAL_PACKAGE =	@Rental_Package	
				
			if @@ROWCOUNT >1
			select @RATE_SR_NO = rs.RATE_SR_NO, @RATE_DET_SR_NO = rs.RATE_DET_SR_NO, @Authorizedrate = rs.CUSTOMER_PER_DAY from DEBITORS d (nolock) 
			inner join TARIFF_RATES t (nolock) on d.TARIFF_CODE = t.TARIFF_CODE 
			inner join RATES_SECTION_2 rs (nolock) on t.RATE_NO = rs.RATE_NO
			INNER JOIN RATES_SECTION_1 r1 (nolock) on r1.RATE_NO = rs.RATE_NO
			where d.DEBITOR_CODE = @DebitorCode and rs.F_GROUP = @InsuredEquivClass
			and rs.RENTAL_PACKAGE =	@Rental_Package	
			and r1.RATE_NAME like '%within%'	
				
			select @VLI_Rate = ISNULL(UNIT_PRICE, 0) from RATE_EXTRAS where ltrim(rtrim(EXTRAS_CODE))='VLI' and F_GROUP =@InsuredEquivClass 
			and RATE_SR_NO =@RATE_SR_NO
			
			if @VLI_Rate = 0
				select @VLI_Rate = RATE_PER_UNIT  from EXTRAS_SECTION_2(nolock) WHERE ltrim(rtrim(CODE)) ='VLI'
					
			SET @dFinalTotal = (@Authorizedrate + isnull(@VLI_Rate, 0))  * @IntDaysAuthorized 
			SET @dTotalExtras = (isnull(@VLI_Rate, 0))* @IntDaysAuthorized  
			SET @dTotalInsurances = 0.0  		

			if @TaxPaidByVal = 1
			begin
			  SET @dTotalTaxes = @dFinalTotal * ((@GSTorHST + @PST)* .01)
			  SET @dFinalTotal = @dFinalTotal + @dTotalTaxes
			end  
			else if @TaxPaidByVal = 2
			begin	   	  
			  SET @dTotalTaxes = 0.00
			end	
		  
		  set @TotalRental = @Authorizedrate * @IntDaysAuthorized  

		if @myEntryID < (select  MAX(DAC_ENTRY_ID)+1 from da_claims(nolock))
		begin	
			select @myEntryID = MAX(DAC_ENTRY_ID)+1 from da_claims(nolock)
			
			UPDATE DOCUMENT_NUMBERS_DISCOUNT SET  DND_DOCUMENT_NUMBER = @myEntryID 
			WHERE DND_COMPANY_CODE = 0 AND DND_BRANCH_CODE = 0 AND DND_DOCUMENT_TYPE = 84	
		end
			
	begin try
			insert into DA_CLAIMS(
			DAC_ENTRY_ID,
			DAC_SUBMITTER,
			DAC_CREATE_DATE,
			DAC_TRANS_BRANCH_CODE,
			DAC_LAST_MODIFIED_BY,
			DAC_MODIFIED_DATE,
			DAC_STATUS,
			DAC_POLICY,
			DAC_INS_CLAIM,
			DAC_AGREEMENT_NUMBER,
			DAC_CLIENT_PHONE,
			DAC_ICC_CODE,
			DAC_REFERRAL_SOURCE_ID,
			DAC_REFERRAL_METHOD_ID,
			DAC_REF_INS_COMPANY_ID,
			DAC_REFERRAL_ADJUSTER_ID,
			DAC_IND_ADJ_COMPANY_ID,
			DAC_INDEPENDENT_ADJUSTER_ID,
			DAC_INDEPENDENT_ADJUSTER_PHONE,
			DAC_SAME_AS_REFERRAL_COMP,
			DAC_INS_COMPANY_ID,
			DAC_INS_COMPANY_PHONE,
			DAC_COMPANY_ADJUSTER_ID,
			DAC_COMPANY_ADJ_LAST_NAME,
			DAC_COMPANY_ADJ_FIRST_NAME,
			DAC_ADJUSTER_PHONE_NUMBER,
			DAC_THIRD_PARTY,
			DAC_DRIVABLE,
			DAC_TOTAL_LOSS,
			DAC_DATE_OF_LOSS,
			DAC_COLLISION_COVERAGE,
			DAC_DEDUC_COLLISION,
			DAC_CLAIM_TYPE,
			DAC_RECOVERED,
			DAC_DEDUC_COMPREHENSIVE,
			DAC_PAID_BY,
			DAC_MAX_ALLOW,
			DAC_INVOICE_DATE,
			DAC_LOSS_OF_USE,
			DAC_BILL_INDEPD_ADJ,
			DAC_THEFT_WAIVER,
			DAC_TAX_PAID_BY,
			DAC_TP_INS_CO,
			DAC_TP_INS_COMPANY_PHONE,
			DAC_TP_ADJUSTER_ID,
			DAC_TP_ADJUSTER_LAST_NAME,
			DAC_TP_ADJUSTER_FIRST_NAME,
			DAC_TP_ADJUSTER_PHONE_NO,
			DAC_TP_POLICY_NAME,
			DAC_TP_INS_POLICY,
			DAC_TP_CLAIM,
			DAC_TP_MAX_ALLOW,
			DAC_INSURED_CODE,
			DAC_INSURED_NAME,
			DAC_INSURED_FIRST_NAME,
			DAC_SAME_AS_INS_NAME,
			DAC_CLIENT_CODE,
			DAC_CLIENT_ADDRESS,
			DAC_CLIENT_CITY,
			DAC_CLIENT_BUS,
			DAC_POSTAL_CODE,
			DAC_CLIENT_EMAIL,
			DAC_CUST_ALT_PHONE,
			DAC_ADDITIONAL_DRIVER,
			DAC_MAKE,
			DAC_MODEL,
			DAC_YEAR,
			DAC_EQUIVALENT_GROUP,
			DAC_GARAGE_ID,
			DAC_GARAGE_SECOND_NAME,
			DAC_GARAGE_NAME,
			DAC_GARAGE_ADDRESS,
			DAC_GARAGE_PHONE,
			DAC_GARAGE_CITY,
			DAC_GARAGE_COMMENTS
			,DAC_GARAGE_POSTAL_CODE
			,DAC_GARAGE_EMAIL,
			DAC_DATE_OF_REPAIR,
			DAC_LOCATION_CODE,
			DAC_LOCATION_NAME,
			DAC_LOCATION_ADDRESS,
			DAC_LOCATION_CITY,
			DAC_LOCATION_AREA,
			DAC_LOCATION_POSTAL_CODE,
			DAC_LOCATION_PHONE,
			DAC_LOCATION_FAX,
			DAC_LOCATION_COMMENTS,
			DAC_RENTAL_COMP_NAME,
			DAC_ASSIGNEEGROUP,
			DAC_CLIENT_FIRST_NAME,
			DAC_CLIENT_LAST_NAME,
			DAC_RESERVATION_NO,
			DAC_REQ_FIELD,
			VEHICLE_CLASS,
			DAC_COMPANY_CODE,
			DAC_DRP_SHOP,
			DAC_DRP_PAY,
			DAC_PREFERED_BODY_SHOP,
			DAC_AGR_OPEN_DATE,
			DAC_AGR_CLOSE_DATE,
			DAC_AGR_OPEN_TIME,
			DAC_AGR_CLOSE_TIME,
			DAC_RENTAL_MAKE,
			DAC_RENTAL_MODEL,
			DAC_RENTAL_YEAR,
			DAC_RENTAL_AGR_STATUS,
			DAC_RENTAL_CHECK_OUT_BRANCH_CODE,
			DAC_RENTAL_CHECK_IN_BRANCH_CODE,
			DAC_RENTAL_RATE_OUT,
			DAC_RENTAL_UNIT_NO,
			DAC_RENTAL_CAR_CLASS,
			DAC_RENTAL_CAR_GROUP,
			DAC_RENTAL_LICENSE_NO,
			DAC_BILL_STATUS,
			FINAL_AUTH,
			DAC_COMMERCIAL_POLICY,
			DAC_REFERENCE_ENTRY_ID,
			APPOINTMENT_DATE,
			SPLIT_BILL,
			EST_REPAIRE_HOURS,
			GARAGE_SHOP_NO,
			B1,
			B2,
			B3,
			B4,
			ASSIGNED_AGENT,
			DAC_ARS_WEB,
			DAC_PROT_THEFT_WAIVER,
			DAC_OLD_RENTAL_AGREEMENTNO,
			DAC_ALTERNATE_DRIVER,
			DAC_ALTERNATE_DRIVER_NAME,
			DIFF_DRIVER_FIRST_NAME,
			DAC_ALTERNATE_DRIVER_PHONE,
			DAC_ALTERNATE_DRIVER_ADDR,
			DAC_ALTERNATE_DRIVER_CITY,
			DAC_ALTERNATE_DRV_POSTAL_CODE,
			DAC_ESTIMATED_RENTAL_PERIOD,
			ESTIMATED_REPAIR_HOURS,
			DAC_UPGRADE_REQUESTED,
			DAC_EXISTING_DISCOUNT_RENTAL,
			DAC_PARENT_INS_COMP_ADJ,
			DAC_RENTAL_CONTROLLED_BY,
			OK_TO_BILL,
			CREATION_SOURCE,
			DAC_AUTHORIZED_RATE,
			DAC_CREATE_TIME,
			DAC_MODIFIED_TIME,
			DISPUTE,
			DAC_AUTHOR_DAYS	,
			CATEGORY_VEHICLE
			) 

			select 
			DAC_ENTRY_ID = @myEntryID,
			DAC_SUBMITTER = @ModyorCreatedByUser,
			DAC_CREATE_DATE = CONVERT(VARCHAR(8), GETDATE(), 112),
			DAC_TRANS_BRANCH_CODE = 0,
			DAC_LAST_MODIFIED_BY = @ModyorCreatedByUser,
			DAC_MODIFIED_DATE = CONVERT(VARCHAR(8), GETDATE(), 112),
			DAC_STATUS = 0,
			DAC_POLICY = upper(isnull(@policy_number, '')),
			DAC_INS_CLAIM = upper(isnull(@claim_number, '')),
			DAC_AGREEMENT_NUMBER = 0,
			DAC_CLIENT_PHONE = isnull(left(@insured_telephone, 20), ''),
			DAC_ICC_CODE = '',
			DAC_REFERRAL_SOURCE_ID = 1,
			DAC_REFERRAL_METHOD_ID = 2,
			DAC_REF_INS_COMPANY_ID = isnull(@DebitorCode, 0),
			DAC_REFERRAL_ADJUSTER_ID = 0,
			DAC_IND_ADJ_COMPANY_ID = 0,
			DAC_INDEPENDENT_ADJUSTER_ID = 0,
			DAC_INDEPENDENT_ADJUSTER_PHONE = '',
			DAC_SAME_AS_REFERRAL_COMP = 0,
			DAC_INS_COMPANY_ID = isnull(@DebitorCode, 0),
			DAC_INS_COMPANY_PHONE = isnull(@DebitorPhone, ''),
			DAC_COMPANY_ADJUSTER_ID = isnull(@AdjusterID, 0),
			DAC_COMPANY_ADJ_LAST_NAME = upper(isnull(@AdjusterLastName, '')),
			DAC_COMPANY_ADJ_FIRST_NAME = upper(isnull(@AdjusterFirstName, '')),
			DAC_ADJUSTER_PHONE_NUMBER = isnull(left(@adjuster_phone_number, 20), @AdjusterTelephoneNo),
			DAC_THIRD_PARTY = case when upper(isnull(@third_party, '')) = 'yes' then 'Y' when upper(isnull(@third_party, '')) = 'no' then 'N' else '' end,
			DAC_DRIVABLE = '',
			DAC_TOTAL_LOSS = case when upper(isnull(@total_loss, '')) = 'yes'  then 'Y' when upper(isnull(@total_loss, '')) = 'no' then 'N' else '' end,
			DAC_DATE_OF_LOSS = convert(varchar(8), @date_of_loss_CP, 112),
			DAC_COLLISION_COVERAGE = case when upper(isnull(@transferable_coverage, '')) = 'yes' then 'Y' when upper(isnull(@transferable_coverage, '')) = 'no' then 'N' else '' end,
			DAC_DEDUC_COLLISION = 0.00,
			DAC_CLAIM_TYPE = isnull(@ClaimTypeVal, ''),
			DAC_RECOVERED = '',
			DAC_DEDUC_COMPREHENSIVE = 0.00,
			DAC_PAID_BY = isnull(@transferrable_coverage_paid_by_val, ''),
			DAC_MAX_ALLOW = isnull(@DecPolicyMax, 0),
			DAC_INVOICE_DATE = '00000000',
			DAC_LOSS_OF_USE = '',
			DAC_BILL_INDEPD_ADJ = '',
			DAC_THEFT_WAIVER = 0,
			DAC_TAX_PAID_BY = isnull(@TaxPaidByVal, ''),
			DAC_TP_INS_CO = '',
			DAC_TP_INS_COMPANY_PHONE =  '',
			DAC_TP_ADJUSTER_ID = 0,
			DAC_TP_ADJUSTER_LAST_NAME = '',
			DAC_TP_ADJUSTER_FIRST_NAME = '',
			DAC_TP_ADJUSTER_PHONE_NO = '',
			DAC_TP_POLICY_NAME = '',
			DAC_TP_INS_POLICY = '',
			DAC_TP_CLAIM = '',
			DAC_TP_MAX_ALLOW = 0.00,
			DAC_INSURED_CODE = 0,
			DAC_INSURED_NAME = upper(isnull(@Insured_Last_Name, '')),
			DAC_INSURED_FIRST_NAME = upper(isnull(@Insured_First_Name, '')),
			DAC_SAME_AS_INS_NAME = 0,
			DAC_CLIENT_CODE = 0,
			DAC_CLIENT_ADDRESS = upper(isnull(@Insured_Address, '')),
			DAC_CLIENT_CITY = upper(isnull(@Insured_City, '')),
			DAC_CLIENT_BUS = upper(isnull(@insured_business_number, '')),
			DAC_POSTAL_CODE = upper(isnull(@insured_postal_code, '')),
			DAC_CLIENT_EMAIL = upper(isnull(@client_email, '')),
			DAC_CUST_ALT_PHONE = ISNULL(left(@insured_telephone, 20), ''),
			DAC_ADDITIONAL_DRIVER = upper(ISNULL(@additional_driver_name, '')),
			DAC_MAKE = upper(isnull(@insured_vehicle_make, '')),
			DAC_MODEL = upper(isnull(@insured_vehicle_model, '')),
			DAC_YEAR = isnull(@vehicle_year, ''),
			DAC_EQUIVALENT_GROUP = upper(isnull(@InsuredEquivClass,'')),
			DAC_GARAGE_ID = 0,
			DAC_GARAGE_SECOND_NAME = '',
			DAC_GARAGE_NAME = upper(isnull(@repair_location, '')),
			DAC_GARAGE_ADDRESS = upper(isnull(@repair_location_address, '')),
			DAC_GARAGE_PHONE = isnull(left(@repair_location_phone, 20), ''),
			DAC_GARAGE_CITY = upper(isnull(@repair_location_city, '')),
			DAC_GARAGE_COMMENTS = '',
			DAC_GARAGE_POSTAL_CODE = upper(isnull(@repair_location_postal_code, '')),
			DAC_GARAGE_EMAIL = '',
			DAC_DATE_OF_REPAIR = '00000000',
			DAC_LOCATION_CODE = 0,
			DAC_LOCATION_NAME = upper(isnull(@LocName, '')),
			DAC_LOCATION_ADDRESS = upper(isnull(@LocAddress, '')),
			DAC_LOCATION_CITY = upper(isnull(@LocCity, '')),
			DAC_LOCATION_AREA = upper(isnull(@LocArea, '')),
			DAC_LOCATION_POSTAL_CODE = upper(isnull(@LocPostalCode, '')),
			DAC_LOCATION_PHONE = isnull(left(@LocPhone, 20), ''),
			DAC_LOCATION_FAX = isnull(@LocFax, ''),
			DAC_LOCATION_COMMENTS = '',
			DAC_RENTAL_COMP_NAME = '',
			DAC_ASSIGNEEGROUP = '',
			DAC_CLIENT_FIRST_NAME = upper(isnull(@Insured_First_Name, '')),
			DAC_CLIENT_LAST_NAME = upper(isnull(@Insured_Last_Name, '')),
			DAC_RESERVATION_NO = '',
			DAC_REQ_FIELD = '',
			VEHICLE_CLASS = upper(isnull(@InsuredEquivClass, '')),
			DAC_COMPANY_CODE = 1,
			DAC_DRP_SHOP = '',
			DAC_DRP_PAY = '',
			DAC_PREFERED_BODY_SHOP = '',
			DAC_AGR_OPEN_DATE = '00000000',
			DAC_AGR_CLOSE_DATE = '00000000',
			DAC_AGR_OPEN_TIME = 0,
			DAC_AGR_CLOSE_TIME = 0,
			DAC_RENTAL_MAKE = '',
			DAC_RENTAL_MODEL = '',
			DAC_RENTAL_YEAR = '',
			DAC_RENTAL_AGR_STATUS = '',
			DAC_RENTAL_CHECK_OUT_BRANCH_CODE = 0,
			DAC_RENTAL_CHECK_IN_BRANCH_CODE = 0,
			DAC_RENTAL_RATE_OUT = 0.00,
			DAC_RENTAL_UNIT_NO = '',
			DAC_RENTAL_CAR_CLASS = '',
			DAC_RENTAL_CAR_GROUP = '',
			DAC_RENTAL_LICENSE_NO = '',
			DAC_BILL_STATUS = 1,
			FINAL_AUTH = 'N',
			DAC_COMMERCIAL_POLICY = '',
			DAC_REFERENCE_ENTRY_ID = '',
			APPOINTMENT_DATE  = '00000000',
			SPLIT_BILL = '',
			EST_REPAIRE_HOURS = '',
			GARAGE_SHOP_NO = 0,
			B1 =  0.00000,
			B2 =  0.00000,
			B3 =  0.00000,
			B4 =  0.00000,
			ASSIGNED_AGENT = '',
			DAC_ARS_WEB = '' ,
			DAC_PROT_THEFT_WAIVER = 'N',
			DAC_OLD_RENTAL_AGREEMENTNO = '',
			DAC_ALTERNATE_DRIVER = '',
			DAC_ALTERNATE_DRIVER_NAME = upper(isnull(@additional_driver_name, '')),
			DIFF_DRIVER_FIRST_NAME = '',
			DAC_ALTERNATE_DRIVER_PHONE = '',
			DAC_ALTERNATE_DRIVER_ADDR = '',
			DAC_ALTERNATE_DRIVER_CITY = '',
			DAC_ALTERNATE_DRV_POSTAL_CODE = '',
			DAC_ESTIMATED_RENTAL_PERIOD = '',
			ESTIMATED_REPAIR_HOURS = '',
			DAC_UPGRADE_REQUESTED = '',
			DAC_EXISTING_DISCOUNT_RENTAL = '',
			DAC_PARENT_INS_COMP_ADJ = 0,
			DAC_RENTAL_CONTROLLED_BY = ISNULL(@rental_controlled_by, ''),
			OK_TO_BILL = 0,
			CREATION_SOURCE = 1,
			DAC_AUTHORIZED_RATE = isnull(@Authorizedrate, 0),
			DAC_CREATE_TIME = @ModyorCreateTime,
			DAC_MODIFIED_TIME = @ModyorCreateTime,
			DISPUTE='',
			DAC_AUTHOR_DAYS = CASE WHEN @IntDaysAuthorized > 0 and @Authorizedrate>0 and @InsuredEquivClass != '' THEN  @IntDaysAuthorized ELSE 0 END,
			CATEGORY_VEHICLE = upper(isnull(@InsuredEquivClass,''))
			
			if @myAuthEntryID < (select  MAX(dca_entry_id)+1 from da_authorization(nolock))
			begin		
				select @myAuthEntryID = MAX(dca_entry_id)+1 from da_authorization(nolock)
								
				UPDATE DOCUMENT_NUMBERS_DISCOUNT SET  DND_DOCUMENT_NUMBER = @myAuthEntryID 
				WHERE DND_COMPANY_CODE = 0 AND DND_BRANCH_CODE = 0 AND DND_DOCUMENT_TYPE = 90	
			end

			if @IntDaysAuthorized > 0
			begin 
				INSERT INTO DA_AUTHORIZATION(
				DCA_ENTRY_ID,
				DCA_CLAIM_ID,
				DCA_SUBMITTER,
				DCA_CREATE_DATE,
				DCA_LAST_MODIFIED_BY,
				DCA_MODIFIED_DATE,
				DCA_AUTHOR_FROM_DATE,
				DCA_AUTHOR_TO_DATE,
				DCA_AUTHOR_RATE,
				DCA_AUTHOR_AGENT_ID,
				DCA_A_DAYS,
				DCA_AUTH_NOTES,
				DCA_BILL_TO,
				DCA_AUTH_VEHICLE,
				DAC_AUTHOR_FROM_TIME,
				DAC_AUTHOR_TO_TIME,
				DAC_VEH_EQUIV,
				DAC_PACKAGE,
				FINAL_AUTH,
				RATE_SR_NO,
				RATE_DET_SR_NO,
				DAC_TAXES_PAID_BY,
				DAC_FINAL_TOTAL,
				DCA_TOTAL_EXTRAS,
				DCA_TOTAL_INSURANCES,
				DCA_TOTAL_TAXES,
				DCA_TOTAL_RENTAL,
				VAT_PER,
				SERVICE_PER,
				FIRST_CHARGE_GROUP,
				FIRST_NO_OF_DAYS,
				FIRST_RENTAL_PACKAGE,
				FIRST_RATE_SR_NO,
				FIRST_RATE_DET_SR_NO,
				FIRST_PER_DAY_PRICE,
				AGREEMENT_NO,
				BODY_SHOP_DIFF_FLAT_AMT,
				BODY_SHOP_DIFF_DAYS
				)
				select 
				DCA_ENTRY_ID = @myAuthEntryID,
				DCA_CLAIM_ID = @myEntryID,
				DCA_SUBMITTER = @ModyorCreatedByUser,
				DCA_CREATE_DATE = CONVERT(VARCHAR(8), GETDATE(), 112),
				DCA_LAST_MODIFIED_BY = @ModyorCreatedByUser,
				DCA_MODIFIED_DATE = CONVERT(VARCHAR(8), GETDATE(), 112),				
				DCA_AUTHOR_FROM_DATE =  @AuthFromDate,
				DCA_AUTHOR_TO_DATE =  CASE WHEN left(@authorized_to_date_cp,4) >= '2013' THEN @authorized_to_date_cp ELSE '00000000' END,
				DCA_AUTHOR_RATE = isnull(@Authorizedrate, 0.00),
				DCA_AUTHOR_AGENT_ID = '',
				DCA_A_DAYS = @IntDaysAuthorized,
				DCA_AUTH_NOTES = upper(isnull(@note, '')),
				DCA_BILL_TO = 1,
				DCA_AUTH_VEHICLE = upper(isnull(@InsuredEquivClass, '')),
				DAC_AUTHOR_FROM_TIME = 60,
				DAC_AUTHOR_TO_TIME = 60,
				DAC_VEH_EQUIV = upper(isnull(@InsuredEquivClass, '')),
				DAC_PACKAGE = @Rental_Package,
				FINAL_AUTH = 'N',
				RATE_SR_NO = ISNULL(@RATE_SR_NO, 0),
				RATE_DET_SR_NO = ISNULL(@RATE_DET_SR_NO, 0),
				DAC_TAXES_PAID_BY = @TaxPaidByVal,
				DAC_FINAL_TOTAL = isnull(@dFinalTotal, 0),
				DCA_TOTAL_EXTRAS = isnull(@dTotalExtras, 0) ,
				DCA_TOTAL_INSURANCES = isnull(@dTotalInsurances, 0),
				DCA_TOTAL_TAXES = isnull(@dTotalTaxes, 0),
				DCA_TOTAL_RENTAL = isnull(@TotalRental, 0) ,
				VAT_PER = isnull(@GSTorHST, 0),
				SERVICE_PER = isnull(@PST, 0),
				FIRST_CHARGE_GROUP = isnull(@InsuredEquivClass, ''),
				FIRST_NO_OF_DAYS = isnull(@IntDaysAuthorized, 0),
				FIRST_RENTAL_PACKAGE = @Rental_Package,
				FIRST_RATE_SR_NO = ISNULL(@RATE_SR_NO, 0),
				FIRST_RATE_DET_SR_NO = ISNULL(@RATE_DET_SR_NO, 0),
				FIRST_PER_DAY_PRICE = isnull(@Authorizedrate, 0),
				AGREEMENT_NO = 0,
				BODY_SHOP_DIFF_FLAT_AMT = 0,
				BODY_SHOP_DIFF_DAYS = 0
						
				
				if @VLI_Rate > 0 
					begin
					if not exists 
					(select dae_extra_code from da_authorization_extras (nolock) where dae_auth_entry_id=@myAuthEntryID and dae_extra_code='VLI')
					begin
						insert into	da_authorization_extras(dae_auth_entry_id, dae_extra_code, dae_price) values 
						(@myAuthEntryID, 'VLI', @VLI_Rate)
					end	
				end			
				
				--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
				--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Process','','Authorization Create', @myEntryID)

				--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
				--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'From Date','',left(@AuthFromDate, 20), @myEntryID)

				--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
				--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'To Date','',left(@authorized_to_date_cp, 20), @myEntryID)

				--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
				--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Authorization Days','',left(@IntDaysAuthorized, 20),  @myEntryID)

				--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
				--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Authorization Rate','',@Authorizedrate, @myEntryID)

				--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
				--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Authorization Category','',@InsuredEquivClass, @myEntryID)

				--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
				--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Vehicle Equivalent','',ISNULL(@InsuredEquivClass, @InsuredEquivClass), @myEntryID)

				--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
				--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Tax Paid By','',@TaxPaidByVal, @myEntryID)

				--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
				--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Bill To','','1', @myEntryID)	
			end	
				
			--	INSERT INTO REMEDY_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO)
			--	VALUES(@myEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Process','','Create')
				 
			--	INSERT INTO REMEDY_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO)
			--	VALUES(@myEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Referral Ins. Company','',@DebitorCode)
				 
			--	INSERT INTO REMEDY_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO)
			--	VALUES(@myEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Insurance Company','',@DebitorCode)
				 
			--	INSERT INTO REMEDY_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO)
			--	VALUES(@myEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Insured Last Name','',left(@Insured_Last_Name, 20))
				 
			--	INSERT INTO REMEDY_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO)
			--	VALUES(@myEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Insured First Name','',left(@Insured_First_Name,20))
				
			--if @insured_vehicle_make != '' 
			--	INSERT INTO REMEDY_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO)
			--	VALUES(@myEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Car Make','',left(@insured_vehicle_make, 20))
			 
			--if @insured_vehicle_model != '' 
			--	INSERT INTO REMEDY_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO)
			--	VALUES(@myEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Car Model','',left(@insured_vehicle_model, 20))	

				INSERT INTO CLAIM_ABEND_INFO(CLAIM_NO,LAST_AGREEMENT_NO,LAST_RESERVATION_NO)VALUES(@myEntryID, 0,'')	
			 
			 if isnull(LTRIM(RTRIM(@note)), '') ='' 
			   set @note = '*** NEW RESERVATION ***'
			   
			 --if @third_party = 'Y' or @third_party = 'Yes'  
			 --  set @note = @note + ' ***   THIRD PARTY RENTAL – CUST RESP FOR CDW CHARGES   ***'
			
			 if @TaxPaidByVal = 2	
			   set @note = @note + ' ***   H.S.T. IS TO BE BILLED TO THE CUSTOMER  ***'		   
			 
			 if @note != ''
				declare @myNoteIDAuth bigint	
				select @myNoteIDAuth = max(DCN_ID) + 1 from DA_NOTES_HISTORY(nolock) 
				if not exists 
					(select DCN_ID from DA_NOTES_HISTORY (nolock) where DCN_ID=@myNoteIDAuth) and @myNoteIDAuth is not null
				begin 
					begin try		
						Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
						Values(@myNoteIDAuth, @myEntryID,isnull(@note, ''),1,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
						DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')			
					end try		
					begin catch		
						Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
						Values(@myNoteIDAuth+1, @myEntryID,isnull(@note, ''),1,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
						DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')	
					end catch
				end	
				
	DECLARE @EmailAddress VARCHAR(1000), @ICCEmailAddress varchar(500)
	declare @EmailBody varchar(8000)
		
	select @ICCEmailAddress = dial_pal_email_id from DEBITORS D (nolock) where DEBITOR_CODE = @DebitorCode
	
	declare @UpgradeRequesteddesc varchar(100), @Subject varchar(200), @InsCompanyID varchar(100), @MontrealEmailAddress varchar(200)
	declare @WS_User varchar(200)		
	set @WS_User = 'Aviva_WS'
				
	end try
	begin catch
		set @bFlag = 1
		set @ErrorMsg = 'Database error'
		set @ErrorCode = '2022'	
	end catch

	set @EmailBody = '<font face=''verdana'' size=''2''>A new reservation was submitted by '+ @DebitorName +' through the Discount Webservice.<br><br>' 
			+ 'EntryID: '+ cast(cast(@myEntryID as bigint) as varchar(10))+ '<br><br>' 			
				+ 'Request ID: '+ isnull(@RequestID, '')+ '<br><br>' 			
				+ 'Action: '+ isnull(@Action, '')+ '<br><br>' 			
				+ 'Insurance company ID: '+ cast(cast(@DebitorCode as bigint) as varchar(10))+ '<br><br>' 							
				+ 'Adjuster username: ' + isnull(@adjuster_user_name, '') + '<br><br>' 							
				+ 'Adjuster first name: ' + isnull(@AdjusterFirstName, '') + '<br><br>' 							
				+ 'Adjuster last name: ' + isnull(@AdjusterLastName, '') + '<br><br>' 							
				+ 'Adjuster phone number: ' + isnull(@adjuster_phone_number, '') + '<br><br>' 							
				+ 'Referral adjuster name: ' + isnull(@referral_adjuster_name, '') + '<br><br>' 							
				+ 'Insured first name: ' + isnull(@insured_first_name, '') + '<br><br>' 				
				+ 'Insured last name: ' + isnull(@insured_last_name, '') + '<br><br>' 				
				+ 'Insured telephone: ' + isnull(@insured_telephone, '') + '<br><br>' 				
				+ 'Insured business number: ' + isnull(@insured_business_number, '') + '<br><br>' 				
				+ 'Insured address: ' + isnull(@insured_address, '') + '<br><br>' 				
				+ 'Insured city: ' + isnull(@insured_city, '') + '<br><br>' 				
				+ 'Insured postal code: ' + isnull(@insured_postal_code, '') + '<br><br>' 				
				+ 'Client email: ' + isnull(@client_email, '') + '<br><br>' 								
				+ 'Policy number:' + isnull(@policy_number, '') + '<br><br>' 
				+ 'Claim number: ' + isnull(@claim_number, '') + '<br><br>' 				
				+ 'Additional driver name: ' + isnull(@additional_driver_name, '') 	+ '<br><br>' 
				+ 'Alternate phone: ' + isnull(@alternate_driver_phone, '') 	+ '<br><br>' 				
				+ 'Repair location: ' + isnull(@repair_location, '') 	+ '<br><br>' 				
				+ 'Repair location phone: ' + isnull(@repair_location_phone, '') 	+ '<br><br>' 				
				+ 'Repair location address: ' + isnull(@repair_location_address, '') 	+ '<br><br>' 				
				+ 'Repair location postal code: ' + isnull(@repair_location_postal_code, '') 	+ '<br><br>' 				
				+ 'Repair location city: ' + isnull(@repair_location_postal_code, '') 	+ '<br><br>' 				
				+ 'Discount location: <br><br>' 				
				+ 'Date of loss: ' + isnull(@date_of_loss_CP, '00000000') 	+ '<br><br>' 				
				+ 'Taxes paid by: ' + isnull(@TaxPaidByDesc, '') 	+ '<br><br>' 				
				+ 'Total loss: ' + isnull(@total_loss, '') 	+ '<br><br>' 				
				+ 'Claim type: ' + isnull(@ClaimDesc, '') 	+ '<br><br>' 				
				+ 'Policy max: ' + ISNULL(convert(varchar(20), isnull(@policy_max, 0)), '') 	+ '<br><br>' 				
				+ 'Transferable coverage: ' + isnull(@Transferable_Coverage, '') 	+ '<br><br>' 				
				+ 'Third party: ' + isnull(@third_party, '') 	+ '<br><br>' 				
				+ 'Transferable coverage paid by: ' + ISNULL(@transferrable_coverage_paid_by_Desc, '') 	+ '<br><br>' 		
				+ 'Vehicle year: ' + ISNULL(@vehicle_year, '') 	+ '<br><br>' 	
				+ 'Insured vehicle make: ' + ISNULL(@insured_vehicle_make, '') 	+ '<br><br>' 	
				+ 'Insured vehicle model: ' + ISNULL(@insured_vehicle_model, '') 	+ '<br><br>' 					
				+ 'Authorized rate: ' + ISNULL(convert(varchar(20), isnull(@Authorizedrate, 0)), '') + '<br><br>' 	
				+ 'Insurance authorized rate: ' + ISNULL(convert(varchar(20), isnull(@authorized_rate, 0)), '') + '<br><br>' 						
				+ 'Pickup date: ' + isnull(convert(varchar(20),  dbo.convertToDate(@pickup_date_CP)) , '') + '<br><br>' 							
				+ 'Authorized to date: ' + isnull(convert(varchar(20),  dbo.convertToDate(@authorized_to_date_CP)) , '') + '<br><br>' 
				+ 'Days authorized: ' + ISNULL(convert(varchar(20), isnull(@days_authorized, 0)), '') + '<br><br>' 			
				+ 'Note: ' + isnull(@note, '')+ '<br><br>' 
				+ 'Final authorization: ' + isnull(@final_authorization, '')+ '<br><br>' 			
				+ 'Rental controlled by: ' + isnull(@rental_controlled_by, '')+ '<br><br>' 			
				+ 'Alternate driver: ' + isnull(@alternate_driver, '') 	+ '<br><br>' 				
				+ 'Alternate driver name: ' + isnull(@additional_driver_name, '') 	+ '<br><br>' 
				+ 'Alternate driver phone: ' + isnull(@alternate_driver_phone, '') 	+ '<br><br>' 
				+ 'Alternate driver address: ' + isnull(@alternate_driver_address, '') 	+ '<br><br>' 
				+ 'Alternate driver city: ' + isnull(@alternate_driver_city, '') 	+ '<br><br>' 
				+ 'Alternate driver postal code: ' + isnull(@alternate_driver_postal_code, '') 	+ '<br><br>' 
				+ 'Estimate repair hours: ' +  ISNULL(convert(varchar(20), isnull(@estimate_repair_hours, 0)), '') 	+ '<br><br>' 
				+ 'Estimate rental period: ' + ISNULL(convert(varchar(20), isnull(@estimate_rental_period, 0)), '')  	+ '<br><br>' 
				+ 'Upgrade requested: ' + isnull(@UpgradeRequesteddesc, '') 	+ '<br><br>' 
				+ 'Existing discount rental: ' + isnull(@existing_discount_rental, '') 	+ '<br><br>' 
				+ 'Contract number: ' + isnull(@contract_number, '') 	+ '<br><br>' 
				+ 'Insured vehicle compclass: ' + isnull(@InsuredEquivClass, '') 	+ '<br><br>'  		
				+ '</font>'	  	  	  
			
		set @Subject = 'New Reservation submitted by '+ @DebitorName +' (webservice) : '+ cast(cast(@myEntryID as bigint) as varchar(10)) 	
		set @EmailAddress = 'lrao@discountcar.com;selhallak@discountcar.ca;dgiordmaina@discountcar.com'					
		
		declare @isQuebec int = 0
		if @ins_company_ID = '16373'
		begin
			set @isQuebec = 1
			set @Subject = 'New Reservation submitted by '+ @DebitorName + ' (webservice) : '+ cast(cast(@myEntryID as bigint) as varchar(10)) 	
			set @EmailAddress = 'avivamontrealreservation@discountcar.com;lrao@discountcar.com;selhallak@discountcar.ca;dgiordmaina@discountcar.com'	
		end	
		
		set @EmailAddress = @EmailAddress + ';'+ @AdjusterEmailAddress
		--set @EmailAddress = @EmailAddress + ';'+ @AdjusterEmailAddress +';'+@ICCEmailAddress
		
		if @EmailAddress != '' and @Subject != ''
		begin
			EXEC msdb..sp_send_dbmail @profile_name='Altbill',
			@recipients=@EmailAddress,
			@from_address  = 'iccinternal@discountcar.com',
			@subject=@Subject,
			@body=@EmailBody,
			@body_format = 'HTML'
		end	
		
		insert into carpro_app.dbo.sendemailqueue 
		(dbname, emailaddress, emailsubject, emailbody, emailformat, entryuser, entrytime, EmailfromAddress, EmailSentTime) 
		values
		('AVIVA_WS', @EmailAddress, @Subject, @EmailBody, 'HTML', @AdjusterID, getdate(), 'noreply@discountcar.com', getdate())
	end
end			
	
insert into tblDIAL_UsersLog (Adjuster_Username, ip_address, flag, Process_Code, entry_id) 
values (@WS_User, '100.100.100.100', 1, 1, @myEntryID)

if @bFlag = 1
	select @ErrorCode as ErrorCode, @ErrorMsg as ErrorMsg, 0 as ClaimEntryID, @isQuebec as isQuebec
else
	select @ErrorCode as ErrorCode, @ErrorMsg as ErrorMsg, @myEntryID as ClaimEntryID, @isQuebec as isQuebec		
	
	
	
















