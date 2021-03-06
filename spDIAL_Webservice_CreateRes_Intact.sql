USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Webservice_CreateRes_Intact]    Script Date: 04/05/2018 09:41:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec [spDIAL_Webservice_CreateRes_Intact]
--grant exec on [spDIAL_Webservice_CreateRes_Intact] to crystal

ALTER procedure [dbo].[spDIAL_Webservice_CreateRes_Intact]
@Username varchar(50) = 'intact',
@Password varchar(50) = '1dis2count',
@RequestID varchar(50) = '1DBDFG',
@policyissuinggroup varchar(100) = 'INTACT',
@claimsprocessingbranch varchar(100) = 'UNI',
@Adjuster_UserName varchar(10) = 'AZUK',
@Adjuster_PhoneNumber varchar(20) = '4168008351', 
@Referral_Adjuster_UserName varchar(10) = '',
@Insured_First_Name varchar(69) = 'Lakshmi',
@Insured_Last_Name varchar(69) = 'Rao', 
@Insured_Home_Number varchar(20) = '', 
@Insured_Work_Number varchar(20) = '', 
@Insured_Cell_Number varchar(20) = '', 
@Insured_CallPriority varchar(20) = 1, 
@Insured_EmailAddress varchar(100) = 'lrao@discountcar.com',
@Insured_Policy_Number varchar(30) = '11', 
@Insured_Claim_Number varchar(30) = '123', 
@Insured_VehicleYear varchar(20) = 0,
@Insured_Vehiclemake varchar(35) = '',  
@Insured_VehicleModel varchar(35) = '',  
@Insured_Address varchar(255) = '',  
@Insured_City varchar(60) = '',  
@Insured_PostalCode varchar(40) = '',  
@TaxPaidBy varchar(20) = 'Customer', 
@AdditionalDrivername varchar(100) = '', 
@DateOfLoss varchar(8) = '00000000', 
@TotalLoss varchar(3) = '', 
@Driveable varchar(3) = '', 
@Theft varchar(3) = '', 
@PolicyMax varchar(20) = '0.00', 
@PolicyMax_Details varchar(500) = 'Lakshmi Rao', 
@AuthToDate varchar(8) = '00000000',
@DaysAuthorized varchar(20) = '0', 
@Rental_Car_Class varchar(20) = '', 
@GarageName varchar(200) = '', 
@GaragePhone varchar(20) = '',
@GarageAddress varchar(300) = '',
@GaragePostalCode varchar(30) = '', 
@GarageCity varchar(50) = '', 
@ThirdParty varchar(1) = '',
@Notes varchar(500) = '',
@sClaimsData varchar(8000) = '',
@transferrable_coverage varchar(3) = 'NO',
@transferrable_coverage_paid_by varchar(20) = 'Customer',
@action varchar(20) = 'insert'

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

if ISNUMERIC(@DaysAuthorized) = 1  
begin
	set @IntDaysAuthorized = @DaysAuthorized	
end
else
begin
	set @IntDaysAuthorized = 0	
end	

if ISNUMERIC(@PolicyMax) = 1  
begin
	set @DecPolicyMax = @PolicyMax	
end
else
begin
	set @DecPolicyMax = 0	
end	

set @DebitorCode = 0

set @bFlag = 0

if @bFlag = 0
begin
	if isnull(@Username,'') = '' 
	begin
		set @bFlag = 1
		set @ErrorMsg = 'Username is undefined'
		set @ErrorCode = '2000'
	end
end

if @bFlag = 0
begin
	if @Username != 'intact' 
	begin
		set @bFlag = 1
		set @ErrorMsg = 'Invalid Username'
		set @ErrorCode = '2001'
	end
end

if @bFlag = 0
begin
	if isnull(@Password,'') = '' 
	begin
		set @bFlag = 1
		set @ErrorMsg = 'Password is undefined'
		set @ErrorCode = '2002'
	end
end


if @bFlag = 0
begin
	if @Password != '1dis2count'
	begin
		set @bFlag = 1
		set @ErrorMsg = 'Invalid Password'
		set @ErrorCode = '2003'
	end
end

if @bFlag = 0
begin
	if isnull(@action,'') = '' 
	begin
		set @bFlag = 1
		set @ErrorMsg = 'Action is undefined'
		set @ErrorCode = '2004'
	end
end

if @bFlag = 0
begin
	if isnull(@action,'') != 'insert'  and isnull(@action,'') != 'update' and isnull(@action,'') != 'cancel'
	begin
		set @bFlag = 1
		set @ErrorMsg = 'Invalid Action'
		set @ErrorCode = '2005'
	end
end

if @bFlag = 0
begin
	if isnull(@RequestID, '') = ''
	begin
		set @bFlag = 1
		set @ErrorMsg = 'RequestID is undefined'
		set @ErrorCode = '2006'
	end
end

if @bFlag = 0
begin
	if exists (select requestid from tblWS_Insurance_Logs (nolock) where requestid=@RequestID)
	begin
		set @bFlag = 1
		set @ErrorMsg = 'RequestID is not Unique'
		set @ErrorCode = '2007'
	end
end

if @bFlag = 0 
begin
	if isnull(@policyissuinggroup, '') = '' 
	begin
		set @bFlag = 1
		set @ErrorMsg = 'Policy Issuing Group is undefined'
		set @ErrorCode = '2008'
	end
end

if @bFlag = 0 
begin
	if not exists (select code from dbo.vwIntact_PolicyIssuingGroup (nolock) where code=@policyissuinggroup)
	begin
		set @bFlag = 1
		set @ErrorMsg = 'Invalid Policy Issuing Group'
		set @ErrorCode = '2009'
	end
end

if @bFlag = 0 
begin
	if isnull(@claimsprocessingbranch, '') = '' 
	begin
		set @bFlag = 1
		set @ErrorMsg = 'Claims Processing branch is undefined'
		set @ErrorCode = '2010'
	end
end

if @bFlag = 0 
begin
	if not exists (select code from dbo.vwIntact_ClaimsProcessingBranch (nolock) where code=@claimsprocessingbranch)
	begin
		set @bFlag = 1
		set @ErrorMsg = 'Invalid Claims Processing branch'
		set @ErrorCode = '2011'
	end
end

if @bFlag = 0
begin
	if isnull(@Adjuster_UserName, '') = ''
	begin
		set @bFlag = 1
		set @ErrorMsg = 'Adjuster Username is undefined'
		set @ErrorCode = '2012'
	end
end

if @bFlag = 0
begin
	if not exists (select DAA_ENTRY_ID from da_adjuster (nolock) where employee_id=@Adjuster_UserName)
	begin
		set @bFlag = 1
		set @ErrorMsg = 'Adjuster username not found on Discount system'
		set @ErrorCode = '2013'
	end
end

if @bFlag = 0 
begin
	select @DebitorCode = debitor_code from da_adjuster (nolock) where employee_id=@Adjuster_UserName 	
	declare @validDebitor	varchar(500)	
	
	select @validDebitor = debitor_name from DEBITORS (nolock) 
	where (DEBITOR_NAME like '%intact%' or  DEBITOR_NAME like '%belair%' or  DEBITOR_NAME like '%jevco%') and DEBITOR_CODE= @DebitorCode 
	
	if isnull(@validDebitor, '') = ''
	begin
		set @bFlag = 1
		set @ErrorMsg = 'Invalid Adjuster username'
		set @ErrorCode = '2014'
	end
end

if @bFlag = 0
begin
	if not exists (select STATUS from da_adjuster (nolock) where employee_id=@Adjuster_UserName and STATUS = 'A')
	begin
		set @bFlag = 1
		set @ErrorMsg = 'Inactive Adjuster'
		set @ErrorCode = '2015'
	end
end

if @bFlag = 0 
begin
	if isnull(@Insured_Claim_Number, '') = '' and isnull(@Insured_Policy_Number, '') = ''
	begin
		set @bFlag = 1
		set @ErrorMsg = 'Claim No and Policy No are blank'
		set @ErrorCode = '2016'
	end
end

if @bFlag = 0
begin
	if not exists (select value from dbo.vwDIAL_PaidBy (nolock) where value=@TaxPaidBy)
	begin
		set @bFlag = 1
		set @ErrorMsg = 'Invalid Taxes Paid By.'
		set @ErrorCode = '2017'
	end
end


if @bFlag = 0
begin
	if isnull(@transferrable_coverage, '') = '' 
	begin
		set @bFlag = 1
		set @ErrorMsg = 'Transferable Coverage is undefined.'
		set @ErrorCode = '2018'
	end
end

if @bFlag = 0
begin
	if isnull(@transferrable_coverage, '') != 'yes'  and  isnull(@transferrable_coverage, '') != 'no'
	begin
		set @bFlag = 1
		set @ErrorMsg = 'Invalid Transferable Coverage'
		set @ErrorCode = '2019'
	end
end

if @bFlag = 0
begin
	if isnull(@transferrable_coverage, '') = 'NO' and ISNULL(@transferrable_coverage_paid_by, '') = ''
	begin
		set @bFlag = 1
		set @ErrorMsg = 'Transferable Coverage Paid By is undefined.'
		set @ErrorCode = '2020'
	end
end

if @bFlag = 0
begin
	if isnull(@transferrable_coverage, '') = 'NO' 
	begin
		if not exists (select value from dbo.vwDIAL_PaidBy (nolock) where value=@transferrable_coverage_paid_by)
		begin
			set @bFlag = 1
			set @ErrorMsg = 'Invalid Transferable Coverage Paid By.'
			set @ErrorCode = '2021'
		end
	end
end

if @bFlag = 0
begin
	declare @ClaimType int					

	if @TotalLoss = 'yes'
		set @TotalLoss = 'Y'
	else if @TotalLoss = 'no'	
		set @TotalLoss = 'N'
		
	if @Driveable = 'yes'
		set @Driveable = 'Y'	
	else if @Driveable = 'no'	
		set @Driveable = 'N'
		
	if @Theft = 'yes'
	begin
		set @Theft = 'Y'
		set @ClaimType = 2
	end	
	else if @Theft = 'no'		
	begin
		set @Theft = 'N'
		set @ClaimType = 0
	end

	if @ThirdParty = 'yes'
		set @ThirdParty = 'Y'	
	else if @ThirdParty = 'no'	
		set @ThirdParty = 'N'
	
	declare @transferrable_coverage_val varchar(1)
	
	if @transferrable_coverage = 'yes'
		set @transferrable_coverage_val = 'Y'	
	else if @transferrable_coverage = 'no'	
		set @transferrable_coverage_val = 'N'				
	
	declare @transferrable_coverage_paid_by_Desc varchar(100), @transferrable_coverage_paid_by_val int
		
	select @TaxPaidByVal = code from vwDIAL_PaidBy where value=@TaxPaidBy	
	select @TaxPaidByDesc =value from vwDIAL_PaidBy where code=@TaxPaidByVal			
	
	select @transferrable_coverage_paid_by_Desc =value, @transferrable_coverage_paid_by_val = code from vwDIAL_PaidBy where code= @transferrable_coverage_paid_by		

	SELECT @AdjusterLastName = ltrim(rtrim(DAA_LAST_NAME)), @AdjusterFirstName = ltrim(rtrim(DAA_FIRST_NAME)), @AdjusterTelephoneNo = DAA_PHONE, 
	@AdjusterID = DAA_ENTRY_ID  
	FROM DA_ADJUSTER (nolock) WHERE EMPLOYEE_ID = @Adjuster_UserName

	SELECT @DebitorPhone = phone1, @DebitorName = isnull(ltrim(rtrim(DEBITOR_NAME)), '') FROM DEBITORS (NOLOCK) WHERE DEBITOR_CODE = @DebitorCode

	select top 1 @InsuredEquivClass =  ltrim(rtrim(EQUIVALENT_CLASS)) from EXTERNAL_MAKE_MODEL (nolock) 
	where ltrim(rtrim(make)) = @Insured_Vehiclemake and ltrim(rtrim(model)) like '%'+@Insured_VehicleModel+'%' 

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

		if LEFT( @AuthToDate, 4) >= '2013'
			set @AuthFromDate = convert(varchar(8), DATEADD(d, -@IntDaysAuthorized, convert(varchar(8), @AuthToDate, 112)), 112)
		else
			set @AuthFromDate = convert(varchar(8), convert(varchar(8), GETDATE(), 112))
			set @AuthToDate =  convert(varchar(8), DATEADD(d, @IntDaysAuthorized, convert(varchar(8), @AuthFromDate, 112)), 112)	

			set @CompanyCode = 1
			set @DB = 'ONTARIOLIVE'	
			
			select @GSTorHST = national_vat, @PST=SERVICE_FEE from DEFAULT_CONTROL (nolock) where COMPANY_NO=@CompanyCode

			select @RATE_SR_NO = rs.RATE_SR_NO, @RATE_DET_SR_NO = rs.RATE_DET_SR_NO, @Authorizedrate = rs.CUSTOMER_PER_DAY from DEBITORS d (nolock) 
			inner join TARIFF_RATES t (nolock) on d.TARIFF_CODE = t.TARIFF_CODE 
			inner join RATES_SECTION_2 rs (nolock) on t.RATE_NO = rs.RATE_NO
			where d.DEBITOR_CODE = @DebitorCode and rs.F_GROUP = @Rental_Car_Class
			and rs.RENTAL_PACKAGE =	@Rental_Package	
				
			if @@ROWCOUNT >1
			select @RATE_SR_NO = rs.RATE_SR_NO, @RATE_DET_SR_NO = rs.RATE_DET_SR_NO, @Authorizedrate = rs.CUSTOMER_PER_DAY from DEBITORS d (nolock) 
			inner join TARIFF_RATES t (nolock) on d.TARIFF_CODE = t.TARIFF_CODE 
			inner join RATES_SECTION_2 rs (nolock) on t.RATE_NO = rs.RATE_NO
			INNER JOIN RATES_SECTION_1 r1 (nolock) on r1.RATE_NO = rs.RATE_NO
			where d.DEBITOR_CODE = @DebitorCode and rs.F_GROUP = @Rental_Car_Class
			and rs.RENTAL_PACKAGE =	@Rental_Package	
			and r1.RATE_NAME like '%within%'	
				
			select @VLI_Rate = ISNULL(UNIT_PRICE, 0) from RATE_EXTRAS where ltrim(rtrim(EXTRAS_CODE))='VLI' and F_GROUP =@Rental_Car_Class and RATE_SR_NO =@RATE_SR_NO
			
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
		  
		  IF @InsuredEquivClass = ''
		  SET @InsuredEquivClass = @Rental_Car_Class

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
			DAC_POLICY = upper(isnull(@Insured_Policy_Number, '')),
			DAC_INS_CLAIM = upper(isnull(@Insured_Claim_Number, '')),
			DAC_AGREEMENT_NUMBER = 0,
			DAC_CLIENT_PHONE = isnull(@Insured_Home_Number, ''),
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
			DAC_ADJUSTER_PHONE_NUMBER = isnull(@Adjuster_PhoneNumber, @AdjusterTelephoneNo),
			DAC_THIRD_PARTY = upper(isnull(@ThirdParty, '')),
			DAC_DRIVABLE = upper(isnull(@Driveable, '')),
			DAC_TOTAL_LOSS = upper(isnull(@TotalLoss, '')),
			DAC_DATE_OF_LOSS = convert(varchar(8), @DateOfLoss, 112),
			DAC_COLLISION_COVERAGE = isnull(@transferrable_coverage_val, ''),
			DAC_DEDUC_COLLISION = 0.00,
			DAC_CLAIM_TYPE = isnull(@ClaimType, ''),
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
			DAC_CLIENT_BUS = upper(isnull(@Insured_Work_Number, '')),
			DAC_POSTAL_CODE = upper(isnull(@Insured_PostalCode, '')),
			DAC_CLIENT_EMAIL = upper(isnull(@Insured_EmailAddress, '')),
			DAC_CUST_ALT_PHONE = ISNULL(@Insured_Cell_Number, ''),
			DAC_ADDITIONAL_DRIVER = upper(ISNULL(@AdditionalDrivername, '')),
			DAC_MAKE = upper(isnull(@Insured_Vehiclemake, '')),
			DAC_MODEL = upper(isnull(@Insured_VehicleModel, '')),
			DAC_YEAR = isnull(@Insured_VehicleYear, ''),
			DAC_EQUIVALENT_GROUP = upper(isnull(@Rental_Car_Class,'')),
			DAC_GARAGE_ID = 0,
			DAC_GARAGE_SECOND_NAME = '',
			DAC_GARAGE_NAME = upper(isnull(@GarageName, '')),
			DAC_GARAGE_ADDRESS = upper(isnull(@GarageAddress, '')),
			DAC_GARAGE_PHONE = isnull(@GaragePhone, ''),
			DAC_GARAGE_CITY = upper(isnull(@GarageCity, '')),
			DAC_GARAGE_COMMENTS = '',
			DAC_GARAGE_POSTAL_CODE = upper(isnull(@GaragePostalCode, '')),
			DAC_GARAGE_EMAIL = '',
			DAC_DATE_OF_REPAIR = '00000000',
			DAC_LOCATION_CODE = 0,
			DAC_LOCATION_NAME = upper(isnull(@LocName, '')),
			DAC_LOCATION_ADDRESS = upper(isnull(@LocAddress, '')),
			DAC_LOCATION_CITY = upper(isnull(@LocCity, '')),
			DAC_LOCATION_AREA = upper(isnull(@LocArea, '')),
			DAC_LOCATION_POSTAL_CODE = upper(isnull(@LocPostalCode, '')),
			DAC_LOCATION_PHONE = isnull(@LocPhone, ''),
			DAC_LOCATION_FAX = isnull(@LocFax, ''),
			DAC_LOCATION_COMMENTS = '',
			DAC_RENTAL_COMP_NAME = '',
			DAC_ASSIGNEEGROUP = '',
			DAC_CLIENT_FIRST_NAME = upper(isnull(@Insured_First_Name, '')),
			DAC_CLIENT_LAST_NAME = upper(isnull(@Insured_Last_Name, '')),
			DAC_RESERVATION_NO = '',
			DAC_REQ_FIELD = '',
			VEHICLE_CLASS = upper(isnull(@Rental_Car_Class, @InsuredEquivClass)),
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
			DAC_ALTERNATE_DRIVER_NAME = upper(isnull(@AdditionalDrivername, '')),
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
			DAC_RENTAL_CONTROLLED_BY = '',
			OK_TO_BILL = 0,
			CREATION_SOURCE = 1,
			DAC_AUTHORIZED_RATE = isnull(@Authorizedrate, 0),
			DAC_CREATE_TIME = @ModyorCreateTime,
			DAC_MODIFIED_TIME = @ModyorCreateTime,
			DISPUTE='',
			DAC_AUTHOR_DAYS = CASE WHEN @IntDaysAuthorized > 0 and @Authorizedrate>0 and @Rental_Car_Class != '' THEN  @IntDaysAuthorized ELSE 0 END,
			CATEGORY_VEHICLE = upper(isnull(@Rental_Car_Class,''))
			
			if @myAuthEntryID < (select  MAX(dca_entry_id)+1 from da_authorization(nolock))
			begin		
				select @myAuthEntryID = MAX(dca_entry_id)+1 from da_authorization(nolock)
								
				UPDATE DOCUMENT_NUMBERS_DISCOUNT SET  DND_DOCUMENT_NUMBER = @myAuthEntryID 
				WHERE DND_COMPANY_CODE = 0 AND DND_BRANCH_CODE = 0 AND DND_DOCUMENT_TYPE = 90	
			end

			if @IntDaysAuthorized > 0 and @Rental_Car_Class != ''
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
				DCA_AUTHOR_TO_DATE =  CASE WHEN left(@AuthToDate,4) >= '2013' THEN @AuthToDate ELSE '00000000' END,
				DCA_AUTHOR_RATE = isnull(@Authorizedrate, 0.00),
				DCA_AUTHOR_AGENT_ID = '',
				DCA_A_DAYS = @IntDaysAuthorized,
				DCA_AUTH_NOTES = upper(isnull(@Notes, '')),
				DCA_BILL_TO = 1,
				DCA_AUTH_VEHICLE = upper(isnull(@Rental_Car_Class, '')),
				DAC_AUTHOR_FROM_TIME = 60,
				DAC_AUTHOR_TO_TIME = 60,
				DAC_VEH_EQUIV = upper(isnull(@InsuredEquivClass, @Rental_Car_Class)),
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
				FIRST_CHARGE_GROUP = isnull(@Rental_Car_Class, ''),
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
				--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'To Date','',left(@AuthToDate, 20), @myEntryID)

				--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
				--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Authorization Days','',left(@IntDaysAuthorized, 20),  @myEntryID)

				--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
				--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Authorization Rate','',@Authorizedrate, @myEntryID)

				--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
				--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Authorization Category','',@Rental_Car_Class, @myEntryID)

				--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
				--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Vehicle Equivalent','',ISNULL(@InsuredEquivClass, @Rental_Car_Class), @myEntryID)

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
			 


			--if @Insured_Vehiclemake != '' 
			--	INSERT INTO REMEDY_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO)
			--	VALUES(@myEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Car Make','',left(@Insured_Vehiclemake, 20))
			 
			--if @Insured_VehicleModel != '' 
			--	INSERT INTO REMEDY_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO)
			--	VALUES(@myEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Car Model','',left(@Insured_VehicleModel, 20))	

				INSERT INTO CLAIM_ABEND_INFO(CLAIM_NO,LAST_AGREEMENT_NO,LAST_RESERVATION_NO)VALUES(@myEntryID, 0,'')	
			 
			 if isnull(LTRIM(RTRIM(@Notes)), '') ='' 
			   set @Notes = '*** NEW RESERVATION ***'
			   
			 --if @ThirdParty = 'Y'  
			 --  set @Notes = @Notes + ' ***   THIRD PARTY RENTAL – CUST RESP FOR CDW CHARGES   ***'
			
			 if @TaxPaidByVal = 2	
			   set @Notes = @Notes + ' ***   H.S.T. IS TO BE BILLED TO THE CUSTOMER  ***'
		   
			 
			 if @Notes != ''
				declare @myNoteIDAuth bigint	
				select @myNoteIDAuth = max(DCN_ID) + 1 from DA_NOTES_HISTORY(nolock) 
				if not exists 
					(select DCN_ID from DA_NOTES_HISTORY (nolock) where DCN_ID=@myNoteIDAuth) and @myNoteIDAuth is not null
				begin 
					begin try		
						Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
						Values(@myNoteIDAuth, @myEntryID,isnull(@Notes, ''),1,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
						DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')			
					end try		
					begin catch		
						Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
						Values(@myNoteIDAuth+1, @myEntryID,isnull(@Notes, ''),1,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
						DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')	
					end catch
				end	
				
				
				
				
			if isnull(@PolicyMax_Details, '') != ''
				declare @PolicyMaxDetailsNoteID bigint	
				
				declare @PolicyMaxDesc varchar(1000)
				
				set @PolicyMaxDesc = '*** POLICY MAX DETAILS ***' + @PolicyMax_Details 
				select @PolicyMaxDetailsNoteID = max(DCN_ID) + 1 from DA_NOTES_HISTORY(nolock) 
				if not exists 
					(select DCN_ID from DA_NOTES_HISTORY (nolock) where DCN_ID=@PolicyMaxDetailsNoteID) and @PolicyMaxDetailsNoteID is not null
				begin 
					begin try		
						Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
						Values(@PolicyMaxDetailsNoteID, @myEntryID,isnull(@PolicyMaxDesc, ''),3,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
						DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Policy Max Details Info from the Adjuster')			
					end try		
					begin catch		
						Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
						Values(@PolicyMaxDetailsNoteID+1, @myEntryID,isnull(@PolicyMaxDesc, ''),3,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
						DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Policy Max Details Info from the Adjuster')	
					end catch
				end			
				
			declare @IntCallPriority int
			declare @CallPriorityNote  varchar(500)		
			
			set @IntCallPriority = @Insured_CallPriority
			
			if @IntCallPriority = 1
				set @CallPriorityNote = '*** CALL CELL NUMBER - '+ @Insured_Cell_Number + '***'
			
			if @IntCallPriority = 2
				set @CallPriorityNote = '*** CALL HOME NUMBER - '+ @Insured_Home_Number + '***'
			
			if @IntCallPriority = 3
				set @CallPriorityNote = '*** CALL WORK NUMBER - '+ @Insured_Work_Number+ '***'		
				
			declare @CallPriorityNoteID int				
				
			if @Insured_CallPriority >= 1 AND ISNULL(@CallPriorityNote, '') != ''		
			select @CallPriorityNoteID = max(DCN_ID) + 1 from DA_NOTES_HISTORY(nolock) 
			if not exists 
				(select DCN_ID from DA_NOTES_HISTORY (nolock) where DCN_ID=@CallPriorityNoteID) and @CallPriorityNoteID is not null
			begin 
				begin try		
					Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
					Values(@CallPriorityNoteID, @myEntryID,isnull(@CallPriorityNote, ''),3,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
					DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Call Priority from the Adjuster')			
				end try		
				begin catch		
					Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
					Values(@CallPriorityNoteID+1, @myEntryID,isnull(@CallPriorityNote, ''),3,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
					DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Call Priority from the Adjuster')	
				end catch
			end										
				
				
			DECLARE @EmailAddress varchar(500)
			declare @EmailBody varchar(2000)
				
			select @EmailAddress = dial_pal_email_id from DEBITORS D (nolock) where DEBITOR_CODE = @DebitorCode
			
			declare @UpgradeRequesteddesc varchar(100), @Subject varchar(200), @InsCompanyID varchar(100), @MontrealEmailAddress varchar(200)
			declare @WS_User varchar(200)		
			set @WS_User = 'Intact_WS'			
	end try
	begin catch
		set @bFlag = 1
		set @ErrorMsg = 'Database error'
		set @ErrorCode = '2022'	
	end catch

	declare @policyissuinggroupDesc varchar(200)
	declare @claimsprocessingbranchDesc varchar(200)

	select @policyissuinggroupDesc = Description from  [vwIntact_PolicyIssuingGroup] where code=@policyissuinggroup
	select @claimsprocessingbranchDesc = NAME from  vwIntact_ClaimsProcessingBranch where code=@claimsprocessingbranch

	set @EmailBody = '<font face=''verdana'' size=''2''>A new reservation was submitted by '+ @DebitorName +' through the Discount Webservice.<br><br>' 
				+ 'Entry ID: '+ cast(cast(@myEntryID as bigint) as varchar(10))+ '<br><br>' 			
				+ 'Insurance Company ID: '+ cast(cast(@DebitorCode as bigint) as varchar(10))+ '<br><br>' 							
				+ 'Policy Issuing Group: ' + isnull(@policyissuinggroupDesc, '') + '<br><br>' 							
				+ 'Claims Processing Branch: ' + isnull(@claimsprocessingbranchDesc, '') + '<br><br>' 											
				+ 'Adjuster Name: ' + isnull(@AdjusterFirstName, '') + ' ' + isnull(@AdjusterLastName, '') + '<br><br>' 							
				+ 'Insured Name: ' + isnull(@Insured_First_Name, '') + ' ' + isnull(@Insured_Last_Name, '') + '<br><br>' 				
				+ 'Claim Number: ' + isnull(@Insured_Claim_Number, '') + '<br><br>' 
				+ 'Policy Number:' + isnull(@Insured_Policy_Number, '') + '<br><br>' 
				+ 'Insured Vehicle Make: ' + isnull(@Insured_Vehiclemake, '')+ '<br><br>' 													
				+ 'Insured Vehicle Model: ' + isnull(@Insured_VehicleModel, '')+ '<br><br>' 													
				+ 'Insured Vehicle Year: ' + isnull(@Insured_VehicleYear, '')+ '<br><br>' 																
				+ 'Insured Call Priority: ' + isnull(@CallPriorityNote, '')+ '<br><br>' 													
				+ 'Insured Home#: ' + isnull(@Insured_Home_Number, '')+ '<br><br>' 													
				+ 'Insured Cell#: ' + isnull(@Insured_Cell_Number, '')+ '<br><br>' 													
				+ 'Insured Work#: ' + isnull(@Insured_Work_Number, '')+ '<br><br>' 																	
				+ 'Total Loss:' + isnull(@TotalLoss , '') + '<br><br>' 
				+ 'Drivable:' + isnull(@Driveable  , '') + '<br><br>' 
				+ 'Theft:' + isnull(@Theft, '') + '<br><br>' 
				+ 'PolicyMax Details:' + isnull(@PolicyMax_Details, '') + '<br><br>' 
				+ 'Rental Car Class:' + isnull(@Rental_Car_Class, '') + '<br><br>' 
				+ 'Garage Name:' + isnull(@GarageName, '') + '<br><br>' 
				+ 'Garage Phone:' + isnull(@GaragePhone, '') + '<br><br>' 
				+ 'Garage Address:' + isnull(@GarageAddress, '') + '<br><br>' 
				+ 'Garage Postal Code:' + isnull(@GaragePostalCode, '') + '<br><br>' 
				+ 'Garage City:' + isnull(@GarageCity, '') + '<br><br>' 
				+ 'Third Party:' + isnull(@ThirdParty, '') + '<br><br>' 
				+ 'Additional Drivername :' + isnull(@AdditionalDrivername, '') + '<br><br>' 
				+ 'TaxPaidBy  :' + isnull(@TaxPaidByDesc, '') + '<br><br>' 
				+ 'Transferrable Coverage  :' + isnull(@transferrable_coverage, '') + '<br><br>' 
				+ 'Transferrable Coverage Paid By :' + isnull(@transferrable_coverage_paid_by, '') + '<br><br>' 
				+ 'Note: ' + isnull(@Notes, '')+ '<br><br>' 			
				+ '</font>'	  	  	  
			
		set @Subject = 'New Reservation submitted by '+ @DebitorName +' (webservice) : '+ cast(cast(@myEntryID as bigint) as varchar(10)) 	
		set @EmailAddress = 'lrao@discountcar.com;selhallak@discountcar.ca;dgiordmaina@discountcar.com'			
		
		if @claimsprocessingbranch =  'qcs' or @claimsprocessingbranch =  'qcl' or @claimsprocessingbranch = 'tel' or @claimsprocessingbranch = 'anj' or @claimsprocessingbranch = 'sth' or @claimsprocessingbranch ='cre' or @claimsprocessingbranch =  'ani' 
		begin
			set @Subject = 'New Reservation submitted by '+ @policyissuinggroupDesc + ' - ' + @claimsprocessingbranchDesc + ' (webservice) : '+ cast(cast(@myEntryID as bigint) as varchar(10)) 	
			set @EmailAddress = 'lrao@discountcar.com;selhallak@discountcar.ca;dgiordmaina@discountcar.com'	
		end	
		
		if @EmailAddress != '' and @Subject != ''
		begin
			EXEC msdb..sp_send_dbmail @profile_name='Altbill',
			@recipients=@EmailAddress,
			@from_address  = 'iccinternal@discountcar.com',
			@subject=@Subject,
			@body=@EmailBody,
			@body_format = 'HTML'
		end	
	end
end			
	
		
if @bFlag = 1
	select @ErrorCode as ErrorCode, @ErrorMsg as ErrorMsg, 0 as ClaimEntryID
else
	select @ErrorCode as ErrorCode, @ErrorMsg as ErrorMsg, @myEntryID as ClaimEntryID	
	
	
	
















