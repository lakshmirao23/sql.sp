USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_CreateRes]    Script Date: 04/05/2018 09:33:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	--exec [spDIAL_CreateRes] 
	--@DebitorCode = 16837, 
	--@AdjusterID = 17724, 
	--@Insured_LastName  = 'Rao', 
	--@Insured_FirstName  = 'Lakshmi',
	--@PolicyNo  = '123456', 
	--@ClaimNo  = 'ADASDA', 
	--@TelePhoneNo  = 'FASFDAFAFAFAF', 
	--@DiscountLocationCode  = 0,
	--@Insured_Vehiclemake  = '',  
	--@Insured_VehicleModel  = '',  
	--@Authorized_VehicleCategory  = '', 
	--@Insured_VehicleYear  = '',
	--@Authorizedrate  = 25.99, 
	--@PolicyMax = 0, 
	--@VehiclePickUpDate  = '00000000', 
	--@AuthToDate = '00000000',
	--@DaysAuthorized  = 1, 
	--@UF  = 5.00, 
	--@WT  = 10.00, 
	--@CDW  = 11.99,
	--@EstimatedRepairHours  = 0, 
	--@EstimatedRentalPeriod  = 0,
	--@ExistingDiscountRental  = 0, 
	--@UpgradeRequested  = 0, 
	--@AuthNotes = '',
	--@DateOfLoss  = '00000000', 
	--@TaxPaidBy = 1, 
	--@TotalLoss  = '', 
	--@ClaimType  = 0,
	--@Driveable  = '', 
	--@Transferable_Coverage   = '', 
	--@Transferable_Coverage_Paid_By  = 0,
	--@ThirdParty  = '',
	--@TP_Ins_Company  = 0, 
	--@TP_PolicyNo  = '',
	--@WithoutPrejudice  = 1, 
	--@AdditionalDriver  = '', 
	--@AlternatePhone  = '',
	--@RepairLocation  = 0, 
	--@RentalControlledBy  = '', 
	--@Different_DriverFromInsured  = '', 
	--@Different_Driver_FirstName  = '',
	--@Different_Driver_City  = '',
	--@Different_Driver_Address  = '', 
	--@Different_Driver_PostalCode  = '',
	--@Different_Driver_Phone  = '', 
	--@GarageNo = -1, 
	--@SendSMS = 0, 
	--@SendEmail = 0, 
	--@sTextCellNumber ='', 
	--@EmailAddress = ''

ALTER procedure [dbo].[spDIAL_CreateRes]
@DebitorCode bigint = 16837, 
@AdjusterID bigint = 17724, 
@Insured_LastName varchar(70) = 'Rao', 
@Insured_FirstName varchar(70) = 'Lakshmi',
@PolicyNo varchar(30) = '123456', 
@ClaimNo varchar(30) = '', 
@TelePhoneNo varchar(20) = '', 
@DiscountLocationCode bigint = 0,
@Insured_Vehiclemake varchar(35) = '',  
@Insured_VehicleModel varchar(35) = '',  
@Authorized_VehicleCategory varchar(20) = '', 
@Insured_VehicleYear varchar(35) = '',
@Authorizedrate decimal(18,2) = 0.00, 
@PolicyMax decimal(18,2) = 0.00, 
@VehiclePickUpDate varchar(8) = '00000000', 
@AuthToDate varchar(8) = '00000000',
@DaysAuthorized int = 0, 
@UF decimal(18,2) = 0.00, 
@WT decimal (18,2) = 0.00, 
@CDW decimal (18, 2) = 0.00,
@EstimatedRepairHours float = 0, 
@EstimatedRepairAmount float = 0,
@EstimatedRentalPeriod float = 0,
@ExistingDiscountRental int = 0, 
@UpgradeRequested int = 0, 
@AuthNotes varchar(500) = '',
@DateOfLoss varchar(8) = '00000000', 
@TaxPaidBy int = 0, 
@TotalLoss varchar(1) = '', 
@ClaimType int = 0,
@Driveable varchar(1) = '', 
@Transferable_Coverage  varchar(1) = '', 
@Transferable_Coverage_Paid_By int = 0,
@ThirdParty varchar(1) = '',
@TP_Ins_Company bigint = 0, 
@TP_PolicyNo varchar(35) = '',
@WithoutPrejudice INT = 0, 
@AdditionalDriver varchar(100) = '', 
@AlternatePhone varchar(20) = '',
--@RepairLocation bigint = 0, 
@RentalControlledBy varchar(30) = '', 
@Different_DriverFromInsured varchar(1) = '', 
@Different_Driver_FirstName varchar(50) = '',
@Different_Driver_City varchar(60) = '',
@Different_Driver_Address varchar(255) = '', 
@Different_Driver_PostalCode varchar(7) = '',
@Different_Driver_Phone varchar(20) = '', 
@GarageNo bigint = 0, 
@SendSMS int = 0, 
@SendEmail int = 0, 
@sTextCellNumber varchar(20) = '', 
@EmailAddress varchar(200) = '',
@ClientIp varchar(100) = '',
@LoggedInUserName varchar(20)

as

begin
Declare @myEntryID bigint, @myAuthEntryID bigint
Declare @AdjusterLastName varchar(30),@AdjusterFirstName varchar(30), @AdjusterTelephoneNo varchar(20), @TP_Ins_PhoneNo varchar(20), @DebitorPhone varchar(20), @AdjusterUserName varchar(30)
Declare @GarageName varchar(200), @GarageAddress varchar(300), @GaragePhone varchar(20), @GarageCity varchar(50), @GaragePostalCode varchar(30), @GarageEmail varchar(200)
Declare @LocName varchar(200), @LocAddress varchar(300), @LocArea varchar(20), @LocCity varchar(50), @LocPostalCode varchar(30), @LocPhone varchar(200), @LocFax varchar(200)
Declare @InsuredEquivClass varchar(3) = ''
declare @dFinalTotal decimal(18,2), @dTotalExtras decimal(18,2), @dTotalInsurances decimal(18,2), @dTotalTaxes decimal(18,2)
Declare @myNoteID bigint, @ModyorCreatedByUser varchar(30), @ModyorCreatedDate varchar(8), @ModyorCreateTime int, @AuthFromDate varchar(8)

declare @RATE_SR_NO int, @PST decimal(18,2), @GSTorHST decimal(18, 2), @CompanyCode int=1
declare @RATE_DET_SR_NO int, @Rental_Package varchar(10) ='1D', @DAC_Status int, @TotalRental decimal(18,2)
declare @ClaimDesc varchar(30) = '', @TaxPaidByDesc varchar(30) = ''
declare @ProvinceCode int
Declare @VLI_Rate decimal(18,2) = 0
declare @DB varchar(30)

select @ClaimDesc = [text] from vwDIAL_ClaimType where value=@ClaimType
select @TaxPaidByDesc =value from vwDIAL_PaidBy where code=@TaxPaidBy

SELECT @AdjusterLastName = DAA_LAST_NAME, @AdjusterFirstName = DAA_FIRST_NAME, @AdjusterTelephoneNo = DAA_PHONE, @AdjusterUserName = EMPLOYEE_ID 
FROM DA_ADJUSTER (nolock) WHERE DAA_ENTRY_ID = @AdjusterID

IF @TP_Ins_Company > 0
	SELECT @TP_Ins_PhoneNo = PHONE1 FROM DEBITORS (NOLOCK) WHERE DEBITOR_CODE = @TP_Ins_Company
	
IF @TP_Ins_Company = -1
	SET @TP_Ins_Company = 0
	
--if @PolicyMax = 0
--	set @PolicyMax = 9999.99


SELECT @DebitorPhone = phone1 FROM DEBITORS (NOLOCK) WHERE DEBITOR_CODE = @DebitorCode
SELECT @LocName = BRANACH_NAME , @LocAddress = STREET, @LocArea = OPERATION_AREA  , @LocCity = CITY, @LocPostalCode = POSTAL_NO, @LocFax = FAX , 
@LocPhone = TELEPHONE1, @ProvinceCode = PROVINCE_CODE, @CompanyCode = COMPANY_CODE 
FROM ONTARIOLIVE..branches (nolock) WHERE BRANACH_CODE = @DiscountLocationCode

select top 1 @InsuredEquivClass =  ltrim(rtrim(EQUIVALENT_CLASS)) from EXTERNAL_MAKE_MODEL (nolock) 
where ltrim(rtrim(make)) = @Insured_Vehiclemake and ltrim(rtrim(model)) like '%'+@Insured_VehicleModel+'%' 

SELECT @GarageName = GARAGE_NAME, @GarageAddress = ADDRESS, @GaragePhone = TEL_NO, @GarageCity = CITY, @GaragePostalCode = ZIF_CODE, 
@GarageEmail = EMAIL_ADDRESS FROM GARAGES (nolock) WHERE GARAGE_NO = @GarageNo

--select @myEntryID = MAX(DAC_ENTRY_ID)+1 from DA_CLAIMS(nolock)
--UPDATE DOCUMENT_NUMBERS_DISCOUNT SET  DND_DOCUMENT_NUMBER = @myEntryID WHERE DND_COMPANY_CODE = 0 AND DND_BRANCH_CODE = 0 AND DND_DOCUMENT_TYPE = 84	

	select @myEntryID = DND_DOCUMENT_NUMBER+1
	from DOCUMENT_NUMBERS_DISCOUNT(nolock)
	WHERE DND_COMPANY_CODE = 0 AND DND_BRANCH_CODE = 0 AND DND_DOCUMENT_TYPE = 84	
	
	
	UPDATE DOCUMENT_NUMBERS_DISCOUNT SET  DND_DOCUMENT_NUMBER = @myEntryID 
	WHERE DND_COMPANY_CODE = 0 AND DND_BRANCH_CODE = 0 AND DND_DOCUMENT_TYPE = 84


	select @myAuthEntryID = DND_DOCUMENT_NUMBER+1
	from DOCUMENT_NUMBERS_DISCOUNT(nolock)
	WHERE DND_COMPANY_CODE = 0 AND DND_BRANCH_CODE = 0 AND DND_DOCUMENT_TYPE = 90	
	
	
	UPDATE DOCUMENT_NUMBERS_DISCOUNT SET  DND_DOCUMENT_NUMBER = @myAuthEntryID 
	WHERE DND_COMPANY_CODE = 0 AND DND_BRANCH_CODE = 0 AND DND_DOCUMENT_TYPE = 90

--select @myAuthEntryID = MAX(dca_entry_id)+1 from da_authorization(nolock)
--UPDATE DOCUMENT_NUMBERS_DISCOUNT SET  DND_DOCUMENT_NUMBER = @myAuthEntryID WHERE DND_COMPANY_CODE = 0 AND DND_BRANCH_CODE = 0 AND DND_DOCUMENT_TYPE = 90	

--select * from DOCUMENT_NUMBERS_DISCOUNT

--SET @dFinalTotal = (@Authorizedrate + ISNULL(@UF, 0.0) + ISNULL(@WT, 0.0) + ISNULL(@CDW, 0.0))  * @DaysAuthorized 
--SET @dTotalExtras = ISNULL(@UF, 0.0) + ISNULL(@WT, 0.0) * @DaysAuthorized  --+ ISNULL(@CDW, 0)  
--SET @dTotalInsurances = ISNULL(@CDW, 0.0) * @DaysAuthorized 
set @ModyorCreatedByUser = 'DIAL'
set @ModyorCreatedDate = CONVERT(varchar(8), GETDATE(), 112)
set @ModyorCreateTime = DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate())

if LEFT( @AuthToDate, 4) >= '2013'
	set @AuthFromDate = convert(varchar(8), DATEADD(d, -@DaysAuthorized, convert(varchar(8), @AuthToDate, 112)), 112)
else
	set @AuthFromDate = convert(varchar(8), convert(varchar(8), GETDATE(), 112))
	set @AuthToDate =  convert(varchar(8), DATEADD(d, @DaysAuthorized, convert(varchar(8), @AuthFromDate, 112)), 112)
	
if @VehiclePickUpDate != '00000000'	
	set @AuthFromDate = @VehiclePickUpDate

if @CompanyCode is null
BEGIN
	set @CompanyCode = 1
	set @DB = 'ONTARIOLIVE'
end	

if @CompanyCode is not null
begin
      select @DB=DATABASE_NAME from DATABASE_SETUP where DATABASE_ID =@CompanyCode
end	
	
IF @CompanyCode = 3
SELECT @DB =
	CASE  
	when @CompanyCode = 3 AND @ProvinceCode = 3 then 'ONTARIOLIVE' 
	WHEN @CompanyCode = 3 AND @ProvinceCode = 5 then  'ALBERTALIVE' 
	WHEN @CompanyCode = 3 AND @ProvinceCode IN (6, 9, 10) then  'MARITIMESLIVE' 
	WHEN @CompanyCode = 3 AND @ProvinceCode = 1 THEN 'BCLIVE' 
	WHEN @CompanyCode = 3 AND @ProvinceCode = 2 THEN 'SASKATCKEWANLIVE2' 	
	WHEN @CompanyCode = 3 AND @ProvinceCode = 11 THEN 'NEWFOUNDLANDLIVE' 	
	ELSE
		'ONTARIOLIVE' 		
end	

if (select VAT_BY_BRANCHES_YN from DEFAULT_CONTROL (nolock) where COMPANY_NO=@CompanyCode)='N'
	select @GSTorHST = national_vat, @PST=SERVICE_FEE from DEFAULT_CONTROL (nolock) where COMPANY_NO=@CompanyCode
else
begin
	select @GSTorHST = VAT_PERCENT, @PST=SERVICE_FEE from branches (nolock) where BRANACH_CODE=@DiscountLocationCode	
end

--if @TaxPaidBy = 1 --insurance
--begin
--  set @dTotalTaxes = @dFinalTotal * (@GSTorHST * .01)
--  set @dFinalTotal = @dFinalTotal + @dTotalTaxes
--end  
--else if @TaxPaidBy = 2 -- customer
--  set @dTotalTaxes = 0.00  

	select @RATE_SR_NO = rs.RATE_SR_NO, @RATE_DET_SR_NO = rs.RATE_DET_SR_NO from DEBITORS d (nolock) 
	inner join TARIFF_RATES t (nolock) on d.TARIFF_CODE = t.TARIFF_CODE 
	inner join RATES_SECTION_2 rs (nolock) on t.RATE_NO = rs.RATE_NO
	where d.DEBITOR_CODE = @DebitorCode and rs.F_GROUP = @Authorized_VehicleCategory
	and rs.RENTAL_PACKAGE =	@Rental_Package	
		
	if @@ROWCOUNT >1
		select @RATE_SR_NO = rs.RATE_SR_NO, @RATE_DET_SR_NO = rs.RATE_DET_SR_NO from DEBITORS d (nolock) 
		inner join TARIFF_RATES t (nolock) on d.TARIFF_CODE = t.TARIFF_CODE 
		inner join RATES_SECTION_2 rs (nolock) on t.RATE_NO = rs.RATE_NO
		INNER JOIN RATES_SECTION_1 r1 (nolock) on r1.RATE_NO = rs.RATE_NO
		where d.DEBITOR_CODE = @DebitorCode and rs.F_GROUP = @Authorized_VehicleCategory
		and rs.RENTAL_PACKAGE =	@Rental_Package	
		--and r1.RATE_NAME like '%within%'	
		and r1.RATE_NAME like '%ON%' AND  CONVERT(varchar(8),getdate(),112) between r1.FROM_DATE and r1.TO_DATE AND r1.RATE_NAME NOT like '% us%'
		

		
	--select @VLI_Rate = UNIT_PRICE from RATE_EXTRAS where EXTRAS_CODE='VLI' and F_GROUP =@Authorized_VehicleCategory and RATE_SR_NO =@RATE_SR_NO
	
	IF @DB = 'ONTARIOLIVE' --FROM [ONTARIOLIVE].[dbo].[EXTRAS_SECTION_2]
	begin
		select @VLI_Rate = ISNULL(UNIT_PRICE, 0) from RATE_EXTRAS where ltrim(rtrim(EXTRAS_CODE))='VLI' and F_GROUP =@Authorized_VehicleCategory and RATE_SR_NO =@RATE_SR_NO
		if @VLI_Rate = 0
			select @VLI_Rate = RATE_PER_UNIT  from EXTRAS_SECTION_2(nolock) WHERE ltrim(rtrim(CODE)) ='VLI'
	end
	else IF @DB = 'ALBERTALIVE'
	begin
		select @VLI_Rate = UNIT_PRICE from ALBERTALIVE..RATE_EXTRAS where ltrim(rtrim(EXTRAS_CODE))='VLI' and F_GROUP =@Authorized_VehicleCategory and RATE_SR_NO =@RATE_SR_NO
		if @VLI_Rate = 0
			select @VLI_Rate = RATE_PER_UNIT  from ALBERTALIVE..EXTRAS_SECTION_2(nolock) WHERE ltrim(rtrim(CODE)) ='VLI'
	end		
	else IF @DB = 'MARITIMESLIVE'
	begin
		select @VLI_Rate = UNIT_PRICE from MARITIMESLIVE..RATE_EXTRAS where ltrim(rtrim(EXTRAS_CODE))='VLI' and F_GROUP =@Authorized_VehicleCategory and RATE_SR_NO =@RATE_SR_NO
		if @VLI_Rate = 0
			select @VLI_Rate = RATE_PER_UNIT  from MARITIMESLIVE..EXTRAS_SECTION_2(nolock) WHERE ltrim(rtrim(CODE)) ='VLI'
	end		
	else IF @DB = 'BCLIVE'
	begin
		select @VLI_Rate = UNIT_PRICE from BCLIVE..RATE_EXTRAS where ltrim(rtrim(EXTRAS_CODE))='VLI' and F_GROUP =@Authorized_VehicleCategory and RATE_SR_NO =@RATE_SR_NO
		if @VLI_Rate = 0
			select @VLI_Rate = RATE_PER_UNIT  from BCLIVE..EXTRAS_SECTION_2(nolock) WHERE ltrim(rtrim(CODE)) ='VLI'
	end		
	else IF @DB = 'SASKATCHEWANLIVE2'
	begin
		select @VLI_Rate = UNIT_PRICE from SaskatchewanLive2..RATE_EXTRAS where ltrim(rtrim(EXTRAS_CODE))='VLI' and F_GROUP =@Authorized_VehicleCategory and RATE_SR_NO =@RATE_SR_NO
		if @VLI_Rate = 0
			select @VLI_Rate = RATE_PER_UNIT  from SaskatchewanLive2..EXTRAS_SECTION_2(nolock) WHERE ltrim(rtrim(CODE)) ='VLI'
	end		
	else IF @DB = 'NEWFOUNDLANDLIVE'
	begin
		select @VLI_Rate = UNIT_PRICE from NewfoundlandLive..RATE_EXTRAS where ltrim(rtrim(EXTRAS_CODE))='VLI' and F_GROUP =@Authorized_VehicleCategory and RATE_SR_NO =@RATE_SR_NO
		if @VLI_Rate = 0
			select @VLI_Rate = RATE_PER_UNIT  from NewfoundlandLive..EXTRAS_SECTION_2(nolock) WHERE ltrim(rtrim(CODE)) ='VLI'
	end		
	
	SET @dFinalTotal = (@Authorizedrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0)+ isnull(@VLI_Rate, 0))  * @DaysAuthorized 
	SET @dTotalExtras = (ISNULL(@UF, 0.0) + ISNULL(@WT, 0.0)+ isnull(@VLI_Rate, 0))* @DaysAuthorized  --+ ISNULL(@CDW, 0) 
	SET @dTotalInsurances = ISNULL(@CDW, 0.0) * @DaysAuthorized  	
		
	--declare @dFinalTotalCustomer decimal(18,2)
	--SET @dFinalTotalCustomer = (@Authorizedrate + isnull(@VLI_Rate, 0)) * @DaysAuthorized 		
	
	if @TaxPaidBy = 1
	begin
	  SET @dTotalTaxes = @dFinalTotal * ((@GSTorHST + @PST)* .01)
	  SET @dFinalTotal = @dFinalTotal + @dTotalTaxes
	end  
	else if @TaxPaidBy = 2
	begin	   
	  --SET @dTotalTaxes = @dFinalTotalCustomer *  ((@GSTorHST + @PST)* .01)
	  --SET @dFinalTotal = @dFinalTotalCustomer + @dTotalTaxes
	  --SET @dTotalExtras = isnull(@VLI_Rate, 0)* @DaysAuthorized
	  SET @dTotalTaxes = 0.00
	end	
  
  set @TotalRental = @Authorizedrate * @DaysAuthorized  
  
  IF @InsuredEquivClass = ''
  SET @InsuredEquivClass = @Authorized_VehicleCategory

	if @myEntryID < (select  MAX(DAC_ENTRY_ID)+1 from da_claims(nolock))
			begin
				
				select @myEntryID = MAX(DAC_ENTRY_ID)+1 from da_claims(nolock)
				
				UPDATE DOCUMENT_NUMBERS_DISCOUNT SET  DND_DOCUMENT_NUMBER = @myEntryID 
				WHERE DND_COMPANY_CODE = 0 AND DND_BRANCH_CODE = 0 AND DND_DOCUMENT_TYPE = 84	

			end


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
--DAC_AUTHOR_DAYS,
DAC_AUTHORIZED_RATE,
DAC_CREATE_TIME,
DAC_MODIFIED_TIME,
DISPUTE,
DAC_AUTHOR_DAYS
) 

select 
DAC_ENTRY_ID = @myEntryID,
DAC_SUBMITTER = 'DIAL',
DAC_CREATE_DATE = CONVERT(VARCHAR(8), GETDATE(), 112),
DAC_TRANS_BRANCH_CODE = @DiscountLocationCode,
DAC_LAST_MODIFIED_BY = 'DIAL',
DAC_MODIFIED_DATE = CONVERT(VARCHAR(8), GETDATE(), 112),
DAC_STATUS = 0,
DAC_POLICY = isnull(@PolicyNo, ''),
DAC_INS_CLAIM = isnull(@ClaimNo, ''),
DAC_AGREEMENT_NUMBER = 0,
DAC_CLIENT_PHONE = isnull(@TelePhoneNo, ''),
DAC_ICC_CODE = '',
DAC_REFERRAL_SOURCE_ID = 1,
DAC_REFERRAL_METHOD_ID = 3,
DAC_REF_INS_COMPANY_ID = isnull(@DebitorCode, 0),
DAC_REFERRAL_ADJUSTER_ID = 0,
DAC_IND_ADJ_COMPANY_ID = 0,
DAC_INDEPENDENT_ADJUSTER_ID = 0,
DAC_INDEPENDENT_ADJUSTER_PHONE = '',
DAC_SAME_AS_REFERRAL_COMP = 0,
DAC_INS_COMPANY_ID = isnull(@DebitorCode, 0),
DAC_INS_COMPANY_PHONE = isnull(@DebitorPhone, ''),
DAC_COMPANY_ADJUSTER_ID = isnull(@AdjusterID, 0),
DAC_COMPANY_ADJ_LAST_NAME = isnull(@AdjusterLastName, ''),
DAC_COMPANY_ADJ_FIRST_NAME = isnull(@AdjusterFirstName, ''),
DAC_ADJUSTER_PHONE_NUMBER = isnull(@AdjusterTelephoneNo, ''),
DAC_THIRD_PARTY = isnull(@ThirdParty, ''),
DAC_DRIVABLE = isnull(@Driveable, ''),
DAC_TOTAL_LOSS = isnull(@TotalLoss, ''),
DAC_DATE_OF_LOSS = convert(varchar(8), @DateOfLoss, 112),
DAC_COLLISION_COVERAGE = isnull(@Transferable_Coverage, ''),
DAC_DEDUC_COLLISION = 0.00,
DAC_CLAIM_TYPE = isnull(@ClaimType, ''),
DAC_RECOVERED = '',
DAC_DEDUC_COMPREHENSIVE = 0.00,
DAC_PAID_BY = isnull(@Transferable_Coverage_Paid_By, ''),
DAC_MAX_ALLOW = isnull(@PolicyMax, 0),
DAC_INVOICE_DATE = '00000000',
DAC_LOSS_OF_USE = 'Y',
DAC_BILL_INDEPD_ADJ = '',
DAC_THEFT_WAIVER = 0,
DAC_TAX_PAID_BY = isnull(@TaxPaidBy, ''),
DAC_TP_INS_CO = isnull(@TP_Ins_Company, ''),
DAC_TP_INS_COMPANY_PHONE = ISNULL(@TP_Ins_PhoneNo, ''),
DAC_TP_ADJUSTER_ID = 0,
DAC_TP_ADJUSTER_LAST_NAME = '',
DAC_TP_ADJUSTER_FIRST_NAME = '',
DAC_TP_ADJUSTER_PHONE_NO = '',
DAC_TP_POLICY_NAME = '',
DAC_TP_INS_POLICY = ISNULL(@TP_PolicyNo, ''),
DAC_TP_CLAIM = '',
DAC_TP_MAX_ALLOW = 0.00,
DAC_INSURED_CODE = 0,
DAC_INSURED_NAME = isnull(upper(@Insured_LastName), ''),
DAC_INSURED_FIRST_NAME = isnull(upper(@Insured_FirstName), ''),
DAC_SAME_AS_INS_NAME = 0,
DAC_CLIENT_CODE = 0,
DAC_CLIENT_ADDRESS = '',
DAC_CLIENT_CITY = '',
DAC_CLIENT_BUS = @AlternatePhone,
DAC_POSTAL_CODE = '',
DAC_CLIENT_EMAIL = @EmailAddress,
DAC_CUST_ALT_PHONE = ISNULL(@sTextCellNumber, ''),
DAC_ADDITIONAL_DRIVER = ISNULL(@AdditionalDriver, ''),
DAC_MAKE = isnull(@Insured_Vehiclemake, ''),
DAC_MODEL = isnull(@Insured_VehicleModel, ''),
DAC_YEAR = isnull(@Insured_VehicleYear, ''),
DAC_EQUIVALENT_GROUP = isnull(@InsuredEquivClass, @Authorized_VehicleCategory),
DAC_GARAGE_ID = case when isnull(@GarageNo, 0) <= 0 then 0 else @GarageNo end,
DAC_GARAGE_SECOND_NAME = '',
DAC_GARAGE_NAME = isnull(@GarageName, ''),
DAC_GARAGE_ADDRESS = isnull(@GarageAddress, ''),
DAC_GARAGE_PHONE = isnull(@GaragePhone, ''),
DAC_GARAGE_CITY = isnull(@GarageCity, ''),
DAC_GARAGE_COMMENTS = '',
DAC_GARAGE_POSTAL_CODE = isnull(@GaragePostalCode, ''),
DAC_GARAGE_EMAIL = ISNULL(@GarageEmail, ''),
DAC_DATE_OF_REPAIR = '00000000',
DAC_LOCATION_CODE = isnull(@DiscountLocationCode, ''),
DAC_LOCATION_NAME = isnull(@LocName, ''),
DAC_LOCATION_ADDRESS = isnull(@LocAddress, ''),
DAC_LOCATION_CITY = isnull(@LocCity, ''),
DAC_LOCATION_AREA = isnull(@LocArea, ''),
DAC_LOCATION_POSTAL_CODE = isnull(@LocPostalCode, ''),
DAC_LOCATION_PHONE = isnull(@LocPhone, ''),
DAC_LOCATION_FAX = isnull(@LocFax, ''),
DAC_LOCATION_COMMENTS = '',
DAC_RENTAL_COMP_NAME = '',
DAC_ASSIGNEEGROUP = '',
DAC_CLIENT_FIRST_NAME = isnull(@Insured_FirstName, ''),
DAC_CLIENT_LAST_NAME = isnull(@Insured_LastName, ''),
DAC_RESERVATION_NO = '',
DAC_REQ_FIELD = '',
VEHICLE_CLASS = isnull(@InsuredEquivClass, @Authorized_VehicleCategory),
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
FINAL_AUTH = '',
DAC_COMMERCIAL_POLICY = '',
DAC_REFERENCE_ENTRY_ID = '',
APPOINTMENT_DATE  = '00000000',
SPLIT_BILL = '',
EST_REPAIRE_HOURS = isnull(@EstimatedRepairHours, 0),
GARAGE_SHOP_NO = isnull(@GarageNo, 0),
B1 =  0.00000,
B2 =  0.00000,
B3 =  0.00000,
B4 =  0.00000,
ASSIGNED_AGENT = '',
DAC_ARS_WEB = '' ,
DAC_PROT_THEFT_WAIVER = 'N',
DAC_OLD_RENTAL_AGREEMENTNO = '',
DAC_ALTERNATE_DRIVER = isnull(@Different_DriverFromInsured, ''),
DAC_ALTERNATE_DRIVER_NAME = isnull(@AdditionalDriver, ''),
DIFF_DRIVER_FIRST_NAME = isnull(@Different_Driver_FirstName, ''),
DAC_ALTERNATE_DRIVER_PHONE = isnull(@Different_Driver_Phone, ''),
DAC_ALTERNATE_DRIVER_ADDR = isnull(@Different_Driver_Address, ''),
DAC_ALTERNATE_DRIVER_CITY = isnull(@Different_Driver_City, ''),
DAC_ALTERNATE_DRV_POSTAL_CODE = isnull(@Different_Driver_PostalCode, ''),
DAC_ESTIMATED_RENTAL_PERIOD = isnull(@EstimatedRentalPeriod, ''),
ESTIMATED_REPAIR_HOURS = isnull(@EstimatedRepairHours, 0),
DAC_UPGRADE_REQUESTED = isnull(@UpgradeRequested, 0),
DAC_EXISTING_DISCOUNT_RENTAL = isnull(@ExistingDiscountRental, ''),
DAC_PARENT_INS_COMP_ADJ = 0,
DAC_RENTAL_CONTROLLED_BY = isnull(@RentalControlledBy , ''),
OK_TO_BILL = 0,
CREATION_SOURCE = 1,
DAC_AUTHORIZED_RATE = isnull(@Authorizedrate, 0),
DAC_CREATE_TIME = @ModyorCreateTime,
DAC_MODIFIED_TIME = @ModyorCreateTime,
DISPUTE='',
DAC_AUTHOR_DAYS = CASE WHEN @DaysAuthorized > 0 and @Authorizedrate>0 and @Authorized_VehicleCategory != '' THEN  @DaysAuthorized ELSE 0 END

-- from date we will calculate based on auth to date

	if @myAuthEntryID < (select  MAX(dca_entry_id)+1 from da_authorization(nolock))
			begin
				
				select @myAuthEntryID = MAX(dca_entry_id)+1 from da_authorization(nolock)
				
				UPDATE DOCUMENT_NUMBERS_DISCOUNT SET  DND_DOCUMENT_NUMBER = @myAuthEntryID 
				WHERE DND_COMPANY_CODE = 0 AND DND_BRANCH_CODE = 0 AND DND_DOCUMENT_TYPE = 90	

			end


if @DaysAuthorized > 0 and @Authorizedrate>0 and @Authorized_VehicleCategory != ''
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
	DCA_SUBMITTER = 'DIAL',
	DCA_CREATE_DATE = CONVERT(VARCHAR(8), GETDATE(), 112),
	DCA_LAST_MODIFIED_BY = 'DIAL',
	DCA_MODIFIED_DATE = CONVERT(VARCHAR(8), GETDATE(), 112),
	DCA_AUTHOR_FROM_DATE =  @AuthFromDate,
	DCA_AUTHOR_TO_DATE =  CASE WHEN left(@AuthToDate,4) >= '2013' THEN @AuthToDate ELSE '00000000' END,
	DCA_AUTHOR_RATE = isnull(@Authorizedrate, 0.00),
	DCA_AUTHOR_AGENT_ID = '',
	DCA_A_DAYS = @DaysAuthorized,
	DCA_AUTH_NOTES = isnull(@AuthNotes, ''),
	DCA_BILL_TO = 1,
	DCA_AUTH_VEHICLE = isnull(@Authorized_VehicleCategory, ''),
	DAC_AUTHOR_FROM_TIME = 60,
	DAC_AUTHOR_TO_TIME = 60,
	DAC_VEH_EQUIV = isnull(@InsuredEquivClass, @Authorized_VehicleCategory),
	DAC_PACKAGE = @Rental_Package,
	FINAL_AUTH = 'N',
	RATE_SR_NO = ISNULL(@RATE_SR_NO, 0),
	RATE_DET_SR_NO = ISNULL(@RATE_DET_SR_NO, 0),
	DAC_TAXES_PAID_BY = @TaxPaidBy,
	DAC_FINAL_TOTAL = isnull(@dFinalTotal, 0),
	DCA_TOTAL_EXTRAS = isnull(@dTotalExtras, 0) ,
	DCA_TOTAL_INSURANCES = isnull(@dTotalInsurances, 0),
	DCA_TOTAL_TAXES = isnull(@dTotalTaxes, 0),
	DCA_TOTAL_RENTAL = isnull(@TotalRental, 0) ,
	VAT_PER = isnull(@GSTorHST, 0),
	SERVICE_PER = isnull(@PST, 0),
	FIRST_CHARGE_GROUP = isnull(@Authorized_VehicleCategory, ''),
	FIRST_NO_OF_DAYS = isnull(@DaysAuthorized, 0),
	FIRST_RENTAL_PACKAGE = @Rental_Package,
	FIRST_RATE_SR_NO = ISNULL(@RATE_SR_NO, 0),
	FIRST_RATE_DET_SR_NO = ISNULL(@RATE_DET_SR_NO, 0),
	FIRST_PER_DAY_PRICE = isnull(@Authorizedrate, 0),
	AGREEMENT_NO = 0,
	BODY_SHOP_DIFF_FLAT_AMT = 0,
	BODY_SHOP_DIFF_DAYS = 0
	
	
	
	--update DA_CLAIMS set DAC_AUTHOR_DAYS = @DaysAuthorized where DAC_ENTRY_ID=@myEntryID
	
	
	
	if @VLI_Rate > 0 
		begin
		if not exists 
		(select dae_extra_code from da_authorization_extras (nolock) where dae_auth_entry_id=@myAuthEntryID and dae_extra_code='VLI')
		begin
			insert into	da_authorization_extras(dae_auth_entry_id, dae_extra_code, dae_price) values 
			(@myAuthEntryID, 'VLI', @VLI_Rate)
		end	
	end
	
	if @UF > 0 
		begin
		if not exists 
		(select dae_extra_code from da_authorization_extras (nolock) where dae_auth_entry_id=@myAuthEntryID and dae_extra_code='UF')
		begin
			insert into	da_authorization_extras(dae_auth_entry_id, dae_extra_code, dae_price) values 
			(@myAuthEntryID, 'UF', @UF)
		end	
	end

	if @WT > 0 
		begin
		if not exists 
		(select dae_extra_code from da_authorization_extras (nolock) where dae_auth_entry_id=@myAuthEntryID and dae_extra_code='WT')
		begin
			insert into	da_authorization_extras(dae_auth_entry_id, dae_extra_code, dae_price) values 
			(@myAuthEntryID, 'WT', @WT)
		end	
	end

	if @CDW > 0 
		begin
		if not exists 
		(
		select dae_insurance_code from da_authorization_insurances (nolock) where dae_auth_entry_id=@myAuthEntryID and dae_insurance_code='CDW'
		)
		begin
		insert into	da_authorization_insurances(dae_auth_entry_id, dae_insurance_code, dae_price) values 
		(@myAuthEntryID, 'CDW', @CDW)
		end
	end
	
	--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
	--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Process','','Authorization Create', @myEntryID)

	--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
	--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'From Date','',left(@AuthFromDate, 20), @myEntryID)

	--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
	--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'To Date','',left(@AuthToDate, 20), @myEntryID)

	--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
	--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Authorization Days','',left(@DaysAuthorized, 20),  @myEntryID)

	--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
	--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Authorization Rate','',@Authorizedrate, @myEntryID)

	--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
	--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Authorization Category','',@Authorized_VehicleCategory, @myEntryID)

	--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
	--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Vehicle Equivalent','',ISNULL(@InsuredEquivClass, @Authorized_VehicleCategory), @myEntryID)

	--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
	--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Tax Paid By','',@TaxPaidBy, @myEntryID)

	--INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)
	--VALUES(@myAuthEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Bill To','','1', @myEntryID)	
end

	
	
	--INSERT INTO REMEDY_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO)
	--VALUES(@myEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Process','','Create')
	 
	--INSERT INTO REMEDY_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO)
	--VALUES(@myEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Referral Ins. Company','',@DebitorCode)
	 
	--INSERT INTO REMEDY_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO)
	--VALUES(@myEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Insurance Company','',@DebitorCode)
	 
	--INSERT INTO REMEDY_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO)
	--VALUES(@myEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Insured Last Name','',left(@Insured_LastName, 20))
	 
	--INSERT INTO REMEDY_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO)
	--VALUES(@myEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Insured First Name','',left(@Insured_FirstName,20))
 
--if @GarageNo > 0
--	INSERT INTO REMEDY_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO)
--	VALUES(@myEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Garage Code','',@GarageNo)

--if @Insured_Vehiclemake != '' 
--	INSERT INTO REMEDY_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO)
--	VALUES(@myEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Car Make','',left(@Insured_Vehiclemake, 20))
 
--if @Insured_VehicleModel != '' 
--	INSERT INTO REMEDY_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO)
--	VALUES(@myEntryID,@ModyorCreatedByUser,@ModyorCreatedDate,@ModyorCreateTime,'Car Model','',left(@Insured_VehicleModel, 20))	

	INSERT INTO CLAIM_ABEND_INFO(CLAIM_NO,LAST_AGREEMENT_NO,LAST_RESERVATION_NO)VALUES(@myEntryID, 0,'')	
 
if isnull(LTRIM(RTRIM(@AuthNotes)), '') = '' 
   set @AuthNotes = '** NEW RESERVATION **'
 
--if @ThirdParty = 'Y'  
--	set @AuthNotes = @AuthNotes + ' **   THIRD PARTY RENTAL – CUST RESP FOR CDW CHARGES   **'
	
if @TaxPaidBy = 2	
	set @AuthNotes = @AuthNotes + ' **   DRIVER RESPONSIBLE FOR H.S.T  **'
   
 
 if @AuthNotes != ''
	declare @myNoteIDAuth bigint	
	--select @myNoteIDAuth = max(DCN_ID) + 1 from DA_NOTES_HISTORY(nolock) 
	--if not exists 
	--	(select DCN_ID from DA_NOTES_HISTORY (nolock) where DCN_ID=@myNoteIDAuth) and @myNoteIDAuth is not null
	--begin 
	--	begin try		
	--		Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
	--		Values(@myNoteIDAuth, @myEntryID,isnull(@AuthNotes, ''),3,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
	--		DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')			
	--	end try		
	--	begin catch		
	--		Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
	--		Values(@myNoteIDAuth+1, @myEntryID,isnull(@AuthNotes, ''),3,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
	--		DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')	
	--	end catch
	--end
	
	select @myNoteIDAuth = max(DCN_ID) + 1 from DA_NOTES_HISTORY(nolock) 
	if not exists 
		(select DCN_ID from DA_NOTES_HISTORY (nolock) where DCN_ID=@myNoteIDAuth) and @myNoteIDAuth is not null
	begin 
		begin try		
			Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
			Values(@myNoteIDAuth, @myEntryID,isnull(@AuthNotes, ''),1,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
			DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')			
		end try		
		begin catch		
			Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
			Values(@myNoteIDAuth+1, @myEntryID,isnull(@AuthNotes, ''),1,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
			DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')	
		end catch
	end
	
if @WithoutPrejudice = 1
begin
	declare @myNoteIDPrej bigint	
	select  @myNoteIDPrej = max(DCN_ID) + 1 from DA_NOTES_HISTORY(nolock) 
	if not exists 
	(select DCN_ID from DA_NOTES_HISTORY (nolock) where DCN_ID=@myNoteIDPrej) and @myNoteIDPrej is not null
	begin			
		begin try
			Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
			Values(@myNoteIDPrej,@myEntryID,'*******      WOP    *******',1,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
			DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')	
		end try
		begin catch
			Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
			Values(@myNoteIDPrej+1,@myEntryID,'*******      WOP    *******',1,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
			DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')	
		end catch
	end
	
	--select  @myNoteIDPrej = max(DCN_ID) + 1 from DA_NOTES_HISTORY(nolock) 
	--if not exists 
	--(select DCN_ID from DA_NOTES_HISTORY (nolock) where DCN_ID=@myNoteIDPrej) and @myNoteIDPrej is not null
	--begin			
	--	begin try
	--		Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
	--		Values(@myNoteIDPrej,@myEntryID,'*******      WOP    *******',3,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
	--		DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')	
	--	end try
	--	begin catch
	--		Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
	--		Values(@myNoteIDPrej+1,@myEntryID,'*******      WOP    *******',3,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
	--		DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')	
	--	end catch
	--end
end


If(@EstimatedRepairHours > 0 and @EstimatedRepairAmount > 0 and @EstimatedRentalPeriod > 0)
begin
	Insert Into Carpro_App..tblDial_Labor_Hours
	(
		ClaimEntryID,
		Agreement_No,
		Claim_No,
		Policy_No,
		Insured_First_Name,
		Insured_Last_Name,
		Insurance_Company_ID,
		Estimated_Repair_Hours,
		Estimated_Amount,
		Estimated_Repair_Days,
		Adjuster_ID,
		Adjuster_First_Name,
		Adjuster_Last_Name,
		Created_Date,
		Last_Modified_Date
	)
	Select
		ClaimEntryID = @myEntryID,
		Agreement_No = 0,
		Claim_No = isnull(@ClaimNo, ''),
		Policy_No = isnull(@PolicyNo, ''),
		Insured_First_Name = isnull(upper(@Insured_FirstName), ''),
		Insured_Last_Name = isnull(upper(@Insured_LastName), ''),
		Insurance_Company_ID = isnull(@DebitorCode, 0),
		Estimated_Repair_Hours = isnull(@EstimatedRepairHours, 0),
		Estimated_Amount = isnull(@EstimatedRepairAmount, 0),
		Estimated_Repair_Days = isnull(@EstimatedRentalPeriod, 0),
		Adjuster_ID = isnull(@AdjusterID, 0),
		Adjuster_First_Name = isnull(@AdjusterFirstName, ''),
		Adjuster_Last_Name = isnull(@AdjusterFirstName, ''),
		Created_Date = GETDATE(),
		Last_Modified_Date = GETDATE()
End


--if @ThirdParty = 'Y'
--begin
--	declare @ThirdPartyNOTE bigint	
--	select  @ThirdPartyNOTE = max(DCN_ID) + 1 from DA_NOTES_HISTORY(nolock) 
--	if not exists 
--	(select DCN_ID from DA_NOTES_HISTORY (nolock) where DCN_ID=@ThirdPartyNOTE) and @ThirdPartyNOTE is not null
--	begin			
--		begin try
--			Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
--			Values(@ThirdPartyNOTE,@myEntryID,'***      THIRD PARTY RENTAL – CUST RESP FOR CDW CHARGES     ***',3,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
--			DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')	
--		end try
--		begin catch
--			Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
--			Values(@ThirdPartyNOTE+1,@myEntryID,'***       THIRD PARTY RENTAL – CUST RESP FOR CDW CHARGES    ***',3,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
--			DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')	
--		end catch
--	end
--end


--if @TaxPaidBy = 2
--begin
--	declare @TaxPaidByNOTE bigint	
--	select  @TaxPaidByNOTE = max(DCN_ID) + 1 from DA_NOTES_HISTORY(nolock) 
--	if not exists 
--	(select DCN_ID from DA_NOTES_HISTORY (nolock) where DCN_ID=@TaxPaidByNOTE) and @TaxPaidByNOTE is not null
--	begin			
--		begin try
--			Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
--			Values(@TaxPaidByNOTE,@myEntryID,'***  H.S.T. IS TO BE BILLED TO THE CUSTOMER  ***',3,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
--			DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')	
--		end try
--		begin catch
--			Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
--			Values(@TaxPaidByNOTE+1,@myEntryID,'***  H.S.T. IS TO BE BILLED TO THE CUSTOMER  ***',3,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
--			DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')	
--		end catch
--	end
--end


if @SendSMS = 1  
begin
  declare @opt_in char(1), @sMessage varchar(160)
  
  if @DiscountLocationCode > 0 
  begin		  
	  set  @sMessage = 'Your adjuster has arranged a rental for you with Discount Car @ ' + @LocAddress +', Phone # ' + @LocPhone + ' . Your reference # '+ cast(cast(@myEntryID as bigint) as varchar(10)) +'.'		  
  end
  else if @DiscountLocationCode = 0
  begin
      set  @sMessage = 'Your adjuster has arranged a rental for you with Discount Car.  Your reference # '+ cast(cast(@myEntryID as bigint) as varchar(10)) +'. We will contact you shortly or you can call us at 1-800-404-4142.'	  
  end				
		
  select @opt_in = oi.Opt_In from [Carpro_App].[dbo].[tblOptIn] oi (nolock) where oi.cell_phone_number = @sTextCellNumber
	 
	if @opt_in is null
	begin
		set @opt_in='Y'		
		insert [Carpro_App].[dbo].[tblOptIn](cell_phone_number,opt_in,added_datetime,updated_datetime, Inserted_By)
		values (@sTextCellNumber,@opt_in,GETDATE(),GETDATE(),@AdjusterID)
	end
	  
	if @opt_in = 'Y'
	begin
		insert into [Carpro_App].[dbo].[SendQueue]([net_number],[message]) values(@sTextCellNumber,@sMessage)
	end
end 

if @SendEmail = 1
begin
	Declare @Subject varchar(200)
	Declare @EmailBody varchar(600)
	
	if @DiscountLocationCode > 0 
	begin	  
	  set @EmailBody = '<font face=''verdana'' size=''2''>Hello ' + @Insured_FirstName + ' ' + @Insured_LastName + '<br><br>' + 'Your Claims adjuster has arranged a rental vehicle for you with Discount Car and Truck Rentals.' + '<br><br>' + 'Your Reference # '+ cast(cast(@myEntryID as bigint) as varchar(10)) + '<br><br>' + 'Discount Location: '+ @LocAddress + '<br><br>Discount Location Phone #:' + @LocPhone + '<br><br>' + 'You will be contacted shortly by one of our friendly agents.' + '<br><br>' + 'If you have any questions, you may reach us at 1-800-404-4142</font>'	  	  	  
	end
	else if @DiscountLocationCode = 0
	begin
    	set @EmailBody = '<font face=''verdana'' size=''2''>Hello ' + @Insured_FirstName + ' ' + @Insured_LastName + '<br><br>' + 'Your Claims adjuster has arranged a rental vehicle for you with Discount Car and Truck Rentals.' + '<br><br>' + 'Your Reference # '+ cast(cast(@myEntryID as bigint) as varchar(10)) + '<br><br>' + 'You will be contacted shortly by one of our friendly agents.' + '<br><br>' + 'If you have any questions, you may reach us at 1-800-404-4142</font>'	  	  	  
	end	

	set @Subject = 'Discount Rental Reference # '+ cast(cast(@myEntryID as bigint) as varchar(10)) 
	
	--SET @EmailAddress = 'LRAO@DISCOUNTCAR.COM'
	
	EXEC msdb..sp_send_dbmail @profile_name='Altbill',
	@recipients = @EmailAddress,
	@from_address  = 'noreply@discountcar.com',
	@subject = @Subject,
	@body = @EmailBody,
	@body_format = 'HTML'

	insert into carpro_app.dbo.sendemailqueue 
	(dbname, emailaddress, emailsubject, emailbody, emailformat, entryuser, entrytime, EmailfromAddress, EmailSentTime) 
	values
	('DIAL 3.0', @EmailAddress, @Subject, @EmailBody, 'HTML', @AdjusterID, getdate(), 'noreply@discountcar.com', GETDATE())
end


	Declare @AuthSubject varchar(200)
	Declare @AuthEmailBody varchar(1000)
	Declare @AuthEmailAddress varchar(200)
	
	--select @AuthEmailAddress = dial_pal_email_id from DEBITORS D (nolock)  left join DA_ADJUSTER a (nolock) on d.DEBITOR_CODE = a.DEBITOR_CODE where DAA_ENTRY_ID = @AdjusterID
	
	select @AuthEmailAddress = dial_pal_email_id from DEBITORS D (nolock) where DEBITOR_CODE = @DebitorCode
	
	set @AuthEmailBody = '<font face=''verdana'' size=''2''>This will confirm the submission of a rental request from the Discount Canada Adjuster Web Site by ' 
			+  isnull(@AdjusterFirstName, '') + ' ' + isnull(@AdjusterLastName, '') + ' at ' + CONVERT(VARCHAR(19),GETDATE())+ '<br><br>' 
			+ 'Adjuster Name: ' + isnull(@AdjusterFirstName, '') + ' ' + isnull(@AdjusterLastName, '') + '<br><br>' 
			+ 'Rental Reference No: '+ cast(cast(@myEntryID as bigint) as varchar(10))+ '<br><br>' 
			+ 'Claim Number: ' + isnull(@ClaimNo, '') + '<br><br>' 
			+ 'Policy Number:' + isnull(@PolicyNo, '') + '<br><br>' 			
			+ 'Insured Name: ' + isnull(@Insured_FirstName, '') + ' ' + isnull(@Insured_LastName, '') + '<br><br>' 
			+ 'Authorized Rate: ' + ISNULL(convert(varchar(20), isnull(@Authorizedrate, 0)), '') + '<br><br>' 
			+ 'Tel(H): ' + isnull(@TelePhoneNo, '')+ '<br><br>' 
			+ 'Tel(W): ' + isnull(@AlternatePhone, '')		+ '<br><br>' 
			+ 'Mobile(C): ' + isnull(@sTextCellNumber, '')		+ '<br><br>' 
			+ 'Policy Max: ' + isnull(convert(varchar(20), @PolicyMax), '')	+ '<br><br>' 
			+ 'Transferable Coverage:' + isnull(@Transferable_Coverage, '') 	+ '<br><br>' 
			+ 'Claim Type: ' + isnull(convert(varchar(10), @ClaimDesc), '')+ '<br><br>' 
			+ 'Tax Paid By: ' + isnull(convert(varchar(10), @TaxPaidByDesc), '')+ '<br><br>' 
			+ 'Note: ' + isnull(@AuthNotes, '')+ '<br><br>' 
			+ 'Garage: ' + isnull(@GarageAddress, '')+ '<br><br>' 
			+ 'Date : ' + CONVERT(VARCHAR(19),GETDATE())+ '<br><br>' 
			+ 'Requested Location:' + isnull(@LocAddress, '')+ '<br><br>' 
			+ 'Requested Location Phone No:' + isnull(@LocPhone, '')+ '<br><br>' 
			+ '</font>'	  	  	  
	
	set @AuthSubject = 'Claim Entry ID # '+ cast(cast(@myEntryID as bigint) as varchar(10))
	
	--SET @AuthEmailAddress = 'LRAO@DISCOUNTCAR.COM;aluztono@discountcar.com;;dGiordmaina@DISCOUNTCAR.com'
	--SET @AuthEmailAddress = 'LRAO@DISCOUNTCAR.COM;'
	
	set @AuthEmailAddress = @AuthEmailAddress 
	
	EXEC msdb..sp_send_dbmail @profile_name='Altbill',
	@recipients=@AuthEmailAddress,
	@from_address  = 'noreply@discountcar.com',
	@subject=@AuthSubject,
	@body=@AuthEmailBody,
	@body_format = 'HTML'

	insert into carpro_app.dbo.sendemailqueue 
	(dbname, emailaddress, emailsubject, emailbody, emailformat, entryuser, entrytime, EmailfromAddress, EmailSentTime) 
	values
	('DIAL 3.0', @AuthEmailAddress, @AuthSubject, @AuthEmailBody, 'HTML', @AdjusterID, getdate(), 'noreply@discountcar.com', getdate())
	
	if (@LoggedInUserName = 'dgig' or @LoggedInUserName = 'td')
	begin
		insert into tblDIAL_UsersLog (Adjuster_Username, ip_address, flag, Process_Code, entry_id) 
		values ('Insurance Portal - '+ @LoggedInUserName, @ClientIp, 1, 1, @myEntryID)
	end
	else
	begin		
		insert into tblDIAL_UsersLog (Adjuster_Username, ip_address, flag, Process_Code, entry_id) 
		values (@AdjusterUserName, @ClientIp, 1, 1, @myEntryID)
	end

select @myEntryID as ClaimEntryID

end