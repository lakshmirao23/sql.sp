USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Re_Auth_LIVE]    Script Date: 04/05/2018 09:39:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- exec [spDIAL_Re_Auth_LIVE]

ALTER PROCEDURE [dbo].[spDIAL_Re_Auth_LIVE] 	
@RemedyEntryID bigint = 3233832, 
@Debitor_Code bigint = 16367, 
@AdjusterID bigint = 17724,  
@PolicyNo varchar(30) = 'A16230075PLA', 
@ClaimNo varchar(30) = 'app5392357', 
@Insured_Vehiclemake varchar(35) = 'Mazda',  
@Insured_VehicleModel varchar(35) = '3 GX', 
@Authorized_VehicleCategory varchar(20) = 'B', 
@Insured_VehicleYear varchar(35) = '2005',
@Authorizedrate decimal(18,2) = 28.00, 
@AuthToDate varchar(8) = '20131205',
@DaysAuthorized int = 1, 
@UF decimal(18,2) = 10.00, 
@WT decimal (18,2) = 5.00, 
@CDW decimal (18, 2) = 25.99, 
@TaxPaidBy int = 1,
@AuthNotes varchar(500) = 'LAKSHMI', 
@FinalAuth varchar(1) = 'Y',

@Transferable_Coverage  varchar(1) = '', 
@Transferable_Coverage_Paid_By int = 0,
@Loss_of_use varchar(1) = '',
@Driveable varchar(1) = '', 
@ThirdParty varchar(1) = '',
@TotalLoss varchar(1) = '', 
@PolicyMax decimal (18, 2) = 0.00,
@ClaimType int = 0,
@WithoutPrejudice INT = 1,
@DRPPay varchar(1) = 'N',
@RepairLocation bigint = 2597,
@RentalDaysToDate int = 0,
@TotalAuthDays int = 23,
@ClientIp varchar(100) = '',
@LoggedInUserName varchar(20) = 'UNKNOWN'

AS

BEGIN	
	SET NOCOUNT ON;	
	Declare @ModyorCreateTime bigint, @ModorCreateDate varchar(8), @ModyorCreatedByUser varchar(8), @AdjusterUserName varchar(10), @InsuredEquivClass varchar(2)	
	Declare @AdjusterLastName varchar(30),@AdjusterFirstName varchar(30), @AdjusterTelephoneNo varchar(20), @TP_Ins_PhoneNo varchar(20), @DebitorPhone varchar(20)
	Declare @myNoteID bigint, @AgreementNo bigint
	Declare @myAuthEntryID bigint
	declare @AuthFromDate varchar(8), @AuthFromTime int, @AuthSerial int , @AuthToTime  int, @AgreementOpenTime int
	declare @dFinalTotal decimal(18,2), @dTotalExtras decimal(18,2), @dTotalInsurances decimal(18,2), @dTotalTaxes decimal(18,2)
	declare @LocationCode int, @CompanyCode int, @PST decimal(18,2), @GSTorHST decimal(18, 2), @TotalRental decimal(18,2)
	declare @DB varchar(30)
	declare @RATE_SR_NO int
	declare @RATE_DET_SR_NO int, @ReservationNo varchar(20), @Rental_Package varchar(10) ='1D', @DAC_Status int
	Declare @LocName varchar(200), @LocAddress varchar(300), @LocArea varchar(20), @LocCity varchar(50), @LocPostalCode varchar(30), @LocPhone varchar(200), @LocFax varchar(200)
	Declare @ClientName varchar(300), @ClientPhone varchar(30)
	DECLARE @GarageName varchar(200), @GarageAddress varchar(300), @GaragePhone varchar(20), @GarageCity varchar(50), @GaragePostalCode varchar(30), @GarageEmail varchar(200)
	declare @AuthIDinchars char(15) 
	
	declare @AdjusterSubject varchar(100)
	declare @AdjusterBody varchar(1000)
	declare @AdjusterEmailAddress varchar(200)
	
	declare @Subject varchar(200)
	declare @Body varchar(1000)
	declare @InternalEmailAddress varchar(200)	
	declare @ProvinceCode int, @isFranchisee varchar(1)
	DECLARE @RateNo int, @DCA_Bill_To int
	declare @MultipleDebitorAuthNo varchar(15), @Agreement_Status_Code int
	declare @Third_Party_Debitor_Code bigint, @Third_Party_policyMax decimal(18, 2)
	DECLARE @RecID int = 1
	
	DECLARE @RentalPrice decimal(18,2), @Insurances_Price decimal(18,2) , @Extras_Price decimal(18,2), @Insu_NonVat_Sum decimal(18,2)
	DECLARE @KM_Sum decimal(18,2), @Airport_Fee decimal(18,2) , @DropOff_Fee decimal(18,2), @Fuel_Sum decimal(18,2)
	DECLARE @Tel_Sum decimal(18,2), @Delivery_Sum decimal(18,2) , @Pickup_Sum decimal(18,2), @Other_Sum decimal(18,2)
	DECLARE @Damages_Sum decimal(18,2), @Deductible_Sum decimal(18,2) , @Traffic_Sum decimal(18,2), @Reduction_Sum decimal(18,2), @MDA_Authrate decimal(18,2)
	DECLARE @MDA_TotalDays int, @MDA_Max_Amt decimal(18,2), @Old_TotalAmount decimal(18,2), @Old_VAT decimal(18,2), @Old_SERVICE_FEE decimal(18,2), @MDA_TotalDays_Old int				  		
	Declare @iDocNobigint bigint	
	declare @iProcessCode int
				
	set @MultipleDebitorAuthNo = ''	
	
	SELECT @DebitorPhone = phone1 FROM DEBITORS (NOLOCK) WHERE DEBITOR_CODE = @Debitor_Code	
	
	IF @FinalAuth = '' 
		SET @FinalAuth = 'N'	
	
	select @InternalEmailAddress =  dial_pal_email_id from DEBITORS D (nolock) where DEBITOR_CODE=@Debitor_Code			
	set @InternalEmailAddress = @InternalEmailAddress 	
	
	SELECT @LocationCode = isnull(DAC_LOCATION_CODE, DAC_RENTAL_CHECK_OUT_BRANCH_CODE),@AgreementNo = DAC_AGREEMENT_NUMBER, 
	@ReservationNo = DAC_RESERVATION_NO , @DAC_Status = DAC_STATUS, @AgreementOpenTime =  DAC_AGR_OPEN_TIME, 
	@ClientName = DAC_INSURED_FIRST_NAME + ' ' + DAC_INSURED_NAME , @ClientPhone = DAC_CLIENT_PHONE, @GarageName = DAC_GARAGE_NAME , 
	@isFranchisee = ltrim(rtrim(DAC_ARS_WEB)), @PolicyMax = DAC_MAX_ALLOW, @Third_Party_Debitor_Code = DAC_TP_INS_CO, @Third_Party_policyMax = DAC_TP_MAX_ALLOW 
	FROM DA_CLAIMS  (nolock) WHERE DAC_ENTRY_ID = @RemedyEntryId
	
	--select @CompanyCode = Company_code from branches (nolock) where branach_code =@LocationCode
	
	---------------------------------------------------------------------Unique ID for DA_Authorization---------------------------------------------------------------------------------
	Declare @iAuthIDDocNo bigint
	SELECT @iAuthIDDocNo =DND_DOCUMENT_NUMBER+1 from DOCUMENT_NUMBERS_DISCOUNT b(nolock) WHERE DND_COMPANY_CODE = 0 AND DND_BRANCH_CODE = 0 AND DND_DOCUMENT_TYPE = 90		
	
	if exists( select dca_entry_id from da_authorization(nolock) where  dca_entry_id = @iAuthIDDocNo)
	begin	
		while exists( select dca_entry_id from da_authorization(nolock)	where dca_entry_id	= @iAuthIDDocNo)
		begin			
			if not exists( select dca_entry_id from da_authorization(nolock) where dca_entry_id = @iAuthIDDocNo)
				break				
			select @iAuthIDDocNo= @iAuthIDDocNo + 1
		end
	end
	
	select @myAuthEntryID =	@iAuthIDDocNo		
					
	UPDATE DOCUMENT_NUMBERS_DISCOUNT SET  DND_DOCUMENT_NUMBER = @myAuthEntryID 
	WHERE DND_COMPANY_CODE = 0 AND DND_BRANCH_CODE = 0 AND DND_DOCUMENT_TYPE = 90 	
	------------------------------------------------------------------------END--------------------------------------------------------------------------------------------------------

	set @ModyorCreateTime = DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate())
	set @ModyorCreatedByUser = 'DIAL'
	set @ModorCreateDate = CONVERT(varchar(8), GETDATE(),112)	
	
	------------------------------------- sending email notifications------------------------------------------------------------------------------------------------------------------
	SELECT @AdjusterLastName = DAA_LAST_NAME, @AdjusterFirstName = DAA_FIRST_NAME, 
	@AdjusterTelephoneNo = DAA_PHONE, @AdjusterUserName = EMPLOYEE_ID , @AdjusterEmailAddress = DAA_EMAIL
	FROM DA_ADJUSTER (nolock) WHERE DAA_ENTRY_ID = @AdjusterID
	
	select @ProvinceCode = PROVINCE_CODE from BRANCHES (nolock) where BRANACH_CODE = @LocationCode	
	
	SELECT @LocName = BRANACH_NAME , @LocAddress = STREET, @LocArea = OPERATION_AREA  , @LocCity = CITY, @LocPostalCode = POSTAL_NO, 
	@LocFax = FAX , @LocPhone = TELEPHONE1,@CompanyCode = Company_code FROM ONTARIOLIVE..branches (nolock) WHERE BRANACH_CODE = @LocationCode
	
	SELECT @GarageName = GARAGE_NAME, @GarageAddress = ADDRESS, @GaragePhone = TEL_NO, @GarageCity = CITY, @GaragePostalCode = ZIF_CODE, 
	@GarageEmail = EMAIL_ADDRESS FROM GARAGES (nolock) WHERE GARAGE_NO = @RepairLocation				
	
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	select @DB =isnull(DATABASE_NAME,1)  from DATABASE_SETUP(nolock) where DATABASE_ID = @CompanyCode	
	
	if LTRIM(rtrim(@AuthNotes)) = '' 
		set @AuthNotes = 'Authorization Added'
		
	--------------------------------------------------------NOTES DATA ENTRY -----------------------------------------------------------------------------------------------------------
	
	if @AuthNotes != ''	
	BEGIN
		select @myNoteID = max(DCN_ID) + 1 from DA_NOTES_HISTORY (nolock) 
		if not exists 
		(select DCN_ID from DA_NOTES_HISTORY (nolock) where DCN_ID=@myNoteID) and @myNoteID is not null
		begin
			INSERT INTO DA_NOTES_HISTORY(DCN_ID,DCN_CLAIM_ID,DCN_NOTES,DCN_NOTES_TYPE,DCN_USER_ID,DCN_DATE,DCN_TIME,DCN_ASSIGNEE_GROUP,DCN_DOCUMENT_TYPE)VALUES
			(@myNoteID, @RemedyEntryId,  isnull(@AuthNotes, ''), 3, @LoggedInUserName , @ModorCreateDate , @ModyorCreateTime, '', 1)
		end
	END
	
	if @WithoutPrejudice = 1
	begin
		declare @NoteIDPrej bigint
		select  @NoteIDPrej =  max(DCN_ID) + 1 from DA_NOTES_HISTORY(nolock)  
		if not exists 
		(select DCN_ID from DA_NOTES_HISTORY (nolock) where DCN_ID=@NoteIDPrej) and @NoteIDPrej is not null
		begin
		Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
		Values(@NoteIDPrej,@RemedyEntryID,'*******      WOP    *******',3,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
		DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')	
		end
	end	
	
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		
	IF @TotalAuthDays = 0
	SET @TotalAuthDays = @DaysAuthorized
	
	UPDATE DA_CLAIMS SET  
	DAC_SUBMITTER = @ModyorCreatedByUser ,
	DAC_RENTAL_CONTROLLED_BY = '' ,
	DAC_MODIFIED_DATE = @ModorCreateDate ,
	DAC_MODIFIED_TIME = @ModyorCreateTime ,
	DAC_LAST_MODIFIED_BY = @ModyorCreatedByUser ,
	DAC_MAKE = isnull(@Insured_Vehiclemake, ''), 
	DAC_MODEL = isnull(@Insured_VehicleModel, '') ,
	DAC_AUTHOR_DAYS = CASE WHEN  @DaysAuthorized > 0 and @Authorizedrate > 0 and @Authorized_VehicleCategory != '' THEN @TotalAuthDays END, --isnull(@DaysAuthorized, 0),
	DAC_TAX_PAID_BY = isnull(@TaxPaidBy, '') ,
	DAC_COLLISION_COVERAGE = isnull(@Transferable_Coverage, ''),	
	DAC_PAID_BY = isnull(@Transferable_Coverage_Paid_By, 0),
	DAC_LOSS_OF_USE = isnull(@Loss_of_use, ''),
	DAC_THIRD_PARTY = isnull(@ThirdParty, ''),		
	DAC_DRIVABLE = isnull(@Driveable, ''),
	DAC_MAX_ALLOW = isnull(@PolicyMax, 0),		
	DAC_TOTAL_LOSS = isnull(@TotalLoss, ''),
	DAC_CLAIM_TYPE = isnull(@ClaimType, 0),
	DAC_DRP_PAY = isnull(@DRPPay, ''),
	DAC_RATE_OUT = ISNULL(@Authorizedrate, 0),
	DAC_YEAR = @Insured_VehicleYear,
	DAC_GARAGE_NAME = isnull(@GarageName, ''),
	DAC_GARAGE_ADDRESS = isnull(@GarageAddress, ''),
	DAC_GARAGE_PHONE = isnull(@GaragePhone, ''),
	DAC_GARAGE_CITY = isnull(@GarageCity, ''),
	DAC_GARAGE_COMMENTS = '',
	DAC_GARAGE_POSTAL_CODE = isnull(@GaragePostalCode, ''),
	DAC_GARAGE_EMAIL = ISNULL(@GarageEmail, '') ,
	DAC_GARAGE_ID = @RepairLocation	,
	FINAL_AUTH = @FinalAuth,	
	DAC_STATUS = 
	CASE 
	when @AgreementNo = 0 and @ReservationNo = '' then 0
	when @AgreementNo = 0 and @ReservationNo != '' then 1
	WHEN  @FinalAuth = 'Y' or (@TotalAuthDays >= @RentalDaysToDate and @AgreementNo > 0)  THEN 2		
	else 3 END,
	--DAC_AUTHOR_DAYS = 
	DAC_REF_INS_COMPANY_ID = isnull(@Debitor_Code, 0),
	DAC_REFERRAL_ADJUSTER_ID = 0,
	DAC_IND_ADJ_COMPANY_ID = 0,
	DAC_INDEPENDENT_ADJUSTER_ID = 0,
	DAC_INDEPENDENT_ADJUSTER_PHONE = '',
	DAC_SAME_AS_REFERRAL_COMP = 0,
	DAC_INS_COMPANY_ID = isnull(@Debitor_Code, 0),
	DAC_INS_COMPANY_PHONE = isnull(@DebitorPhone, ''),
	DAC_COMPANY_ADJUSTER_ID = isnull(@AdjusterID, 0),
	DAC_COMPANY_ADJ_LAST_NAME = isnull(@AdjusterLastName, ''),
	DAC_COMPANY_ADJ_FIRST_NAME = isnull(@AdjusterFirstName, ''),
	DAC_ADJUSTER_PHONE_NUMBER = isnull(@AdjusterTelephoneNo, ''),
	DAC_INS_CLAIM = @ClaimNo
	WHERE DAC_ENTRY_ID = @RemedyEntryId			
	
	IF @DaysAuthorized > 0 and @Authorizedrate > 0 and @Authorized_VehicleCategory != '' 
	BEGIN
		if @AgreementNo = 0  and @ReservationNo = ''
		begin
			UPDATE DA_CLAIMS SET DAC_STATUS = 0 WHERE DAC_ENTRY_ID = @RemedyEntryId
		end		
			
		if @AgreementNo = 0  and @ReservationNo != ''
		begin
			UPDATE DA_CLAIMS SET DAC_STATUS = 1 WHERE DAC_ENTRY_ID = @RemedyEntryId
		end
			
		if @AgreementNo > 0 
		begin
			if @TotalAuthDays >= @RentalDaysToDate
			begin
				UPDATE DA_CLAIMS SET DAC_STATUS = 2 WHERE DAC_ENTRY_ID = @RemedyEntryId
			end
			else 
			UPDATE DA_CLAIMS SET DAC_STATUS = 3 WHERE DAC_ENTRY_ID = @RemedyEntryId
		end
	
	
		----------------------------------------------------- DETERMINE DB FOR TAXES CALCULATION ON DA_AUTHORIZATION TABLE--------------------------------------------------------
		IF @isFranchisee = 'Y'
		SELECT @DB =
		CASE  
			when @isFranchisee = 'Y' AND @ProvinceCode = 3 then 'ONTARIOLIVE' 
			WHEN @isFranchisee = 'Y' AND @ProvinceCode = 5 then  'ALBERTALIVE' 
			WHEN @isFranchisee = 'Y' AND @ProvinceCode IN (6, 9, 10,11) then  'MARITIMESLIVE' 
			WHEN @isFranchisee = 'Y' AND @ProvinceCode = 1 THEN 'BCLIVE' 
			WHEN @isFranchisee = 'Y' AND @ProvinceCode = 2 THEN 'SASKATCHEWANLIVE' 
		ELSE
				'ONTARIOLIVE' 		
		end	
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------
			
		set @TotalRental = @Authorizedrate * @DaysAuthorized
			
		IF @DB = 'ONTARIOLIVE'
		begin
			select top 1 @InsuredEquivClass =  ltrim(rtrim(EQUIVALENT_CLASS)) from EXTERNAL_MAKE_MODEL (nolock) 
			where ltrim(rtrim(make)) = @Insured_Vehiclemake and ltrim(rtrim(model)) like '%'+@Insured_VehicleModel+'%' 
				
			select 
			@PST = case when VAT_BY_BRANCHES_YN = 'N' then dc.SERVICE_FEE  else br.service_fee end, 	
			@GSTorHST  = case when VAT_BY_BRANCHES_YN = 'N' then dc.INTERNATIONAL_VAT else 	br.VAT_PERCENT end 
			from DEFAULT_CONTROL dc (nolock) left join BRANCHES br (nolock) 
			on  dc.COMPANY_NO = br.COMPANY_CODE
			AND br.BRANACH_CODE = @LocationCode		
			where dc.COMPANY_NO = @CompanyCode				
		end	
		else IF @DB = 'ALBERTALIVE'
		begin
			select top 1 @InsuredEquivClass =  ltrim(rtrim(EQUIVALENT_CLASS)) from ALBERTALIVE..EXTERNAL_MAKE_MODEL (nolock) 
			where ltrim(rtrim(make)) = @Insured_Vehiclemake and ltrim(rtrim(model)) like '%'+@Insured_VehicleModel+'%' 
				
			select 
			@PST = case when VAT_BY_BRANCHES_YN = 'N' then dc.SERVICE_FEE  else br.service_fee end, 	
			@GSTorHST  = case when VAT_BY_BRANCHES_YN = 'N' then dc.INTERNATIONAL_VAT else 	br.VAT_PERCENT end 
			from ALBERTALIVE..DEFAULT_CONTROL dc (nolock) left join ALBERTALIVE..BRANCHES br (nolock) 
			on  dc.COMPANY_NO = br.COMPANY_CODE
			AND br.BRANACH_CODE = @LocationCode		
			where dc.COMPANY_NO = @CompanyCode				
		end
		else IF @DB = 'MARITIMESLIVE'
		begin
			select top 1 @InsuredEquivClass =  ltrim(rtrim(EQUIVALENT_CLASS)) from MARITIMESLIVE..EXTERNAL_MAKE_MODEL (nolock) 
			where ltrim(rtrim(make)) = @Insured_Vehiclemake and ltrim(rtrim(model)) like '%'+@Insured_VehicleModel+'%' 
				
			select 
			@PST = case when VAT_BY_BRANCHES_YN = 'N' then dc.SERVICE_FEE  else br.service_fee end, 	
			@GSTorHST  = case when VAT_BY_BRANCHES_YN = 'N' then dc.INTERNATIONAL_VAT else 	br.VAT_PERCENT end 
			from MARITIMESLIVE..DEFAULT_CONTROL dc (nolock) left join MARITIMESLIVE..BRANCHES br (nolock) 
			on  dc.COMPANY_NO = br.COMPANY_CODE
			AND br.BRANACH_CODE = @LocationCode		
			where dc.COMPANY_NO = @CompanyCode				
		end	
		else IF @DB = 'BCLIVE'
		begin
			select top 1 @InsuredEquivClass =  ltrim(rtrim(EQUIVALENT_CLASS)) from BCLIVE..EXTERNAL_MAKE_MODEL (nolock) 
			where ltrim(rtrim(make)) = @Insured_Vehiclemake and ltrim(rtrim(model)) like '%'+@Insured_VehicleModel+'%' 
				
			select 
			@PST = case when VAT_BY_BRANCHES_YN = 'N' then dc.SERVICE_FEE  else br.service_fee end, 	
			@GSTorHST  = case when VAT_BY_BRANCHES_YN = 'N' then dc.INTERNATIONAL_VAT else 	br.VAT_PERCENT end 
			from BCLIVE..DEFAULT_CONTROL dc (nolock) left join BCLIVE..BRANCHES br (nolock) 
			on  dc.COMPANY_NO = br.COMPANY_CODE
			AND br.BRANACH_CODE = @LocationCode		
			where dc.COMPANY_NO = @CompanyCode				
		end	
		else IF @DB = 'SASKATCHEWANLIVE'
		begin
			select top 1 @InsuredEquivClass =  ltrim(rtrim(EQUIVALENT_CLASS)) from SASKATCHEWANLIVE..EXTERNAL_MAKE_MODEL (nolock) 
			where ltrim(rtrim(make)) = @Insured_Vehiclemake and ltrim(rtrim(model)) like '%'+@Insured_VehicleModel+'%' 
				
			select 
			@PST = case when VAT_BY_BRANCHES_YN = 'N' then dc.SERVICE_FEE  else br.service_fee end, 	
			@GSTorHST  = case when VAT_BY_BRANCHES_YN = 'N' then dc.INTERNATIONAL_VAT else 	br.VAT_PERCENT end 
			from SASKATCHEWANLIVE..DEFAULT_CONTROL dc (nolock) left join SaskatchewanLIVE..BRANCHES br (nolock) 
			on  dc.COMPANY_NO = br.COMPANY_CODE
			AND br.BRANACH_CODE = @LocationCode		
			where dc.COMPANY_NO = @CompanyCode				
		end			
		
			
		IF @InsuredEquivClass = ''
		SET @InsuredEquivClass = @Authorized_VehicleCategory	

			
		--Because of the comlexity, only choose one of the rate
		select @RATE_SR_NO = rs.RATE_SR_NO, @RATE_DET_SR_NO = rs.RATE_DET_SR_NO, @RateNo = t.RATE_NO  from DEBITORS d (nolock) 
		inner join TARIFF_RATES t (nolock) on d.TARIFF_CODE = t.TARIFF_CODE 
		inner join RATES_SECTION_2 rs (nolock) on t.RATE_NO = rs.RATE_NO
		where d.DEBITOR_CODE = @Debitor_Code and rs.F_GROUP = @Authorized_VehicleCategory
		and rs.RENTAL_PACKAGE =	@Rental_Package	
				
		if @@ROWCOUNT >1
			select @RATE_SR_NO = rs.RATE_SR_NO, @RATE_DET_SR_NO = rs.RATE_DET_SR_NO, @RateNo = t.RATE_NO from DEBITORS d (nolock) 
			inner join TARIFF_RATES t (nolock) on d.TARIFF_CODE = t.TARIFF_CODE 
			inner join RATES_SECTION_2 rs (nolock) on t.RATE_NO = rs.RATE_NO
			INNER JOIN RATES_SECTION_1 r1 (nolock) on r1.RATE_NO = rs.RATE_NO
			where d.DEBITOR_CODE = @Debitor_Code and rs.F_GROUP = @Authorized_VehicleCategory
			and rs.RENTAL_PACKAGE =	@Rental_Package	
			and r1.RATE_NAME like '%within%'
			
				
		Declare @VLI_Rate decimal(18,2)			
		
			
		IF @DB = 'ONTARIOLIVE' --FROM [ONTARIOLIVE].[dbo].[EXTRAS_SECTION_2]
		begin		    
			select @Agreement_Status_Code = status_code from ONTARIOLIVE..agreements (nolock) where agreement_no=@AgreementNo
			
			SELECT @VLI_Rate = UNIT_PRICE from ONTARIOLIVE..RATE_EXTRAS where EXTRAS_CODE='VLI' and F_GROUP =@Authorized_VehicleCategory and RATE_SR_NO =@RATE_SR_NO
			if @VLI_Rate is null
				select @VLI_Rate = RATE_PER_UNIT  from ONTARIOLIVE..EXTRAS_SECTION_2(nolock) WHERE ltrim(rtrim(CODE)) ='VLI'
		end			
		else IF @DB = 'ALBERTALIVE'
		begin
			select @Agreement_Status_Code = status_code from ALBERTALIVE..agreements (nolock) where agreement_no=@AgreementNo
		
			select @VLI_Rate = UNIT_PRICE from ALBERTALIVE..RATE_EXTRAS where EXTRAS_CODE='VLI' and F_GROUP =@Authorized_VehicleCategory and RATE_SR_NO =@RATE_SR_NO
			if @VLI_Rate is null
				select @VLI_Rate = RATE_PER_UNIT  from ALBERTALIVE..EXTRAS_SECTION_2(nolock) WHERE ltrim(rtrim(CODE)) ='VLI'
		end			
		
		else IF @DB = 'MARITIMESLIVE'
		begin
			select @Agreement_Status_Code = status_code from MARITIMESLIVE..agreements (nolock) where agreement_no=@AgreementNo				
			
			select @VLI_Rate = UNIT_PRICE from MARITIMESLIVE..RATE_EXTRAS where EXTRAS_CODE='VLI' and F_GROUP =@Authorized_VehicleCategory and RATE_SR_NO =@RATE_SR_NO
			
			if @VLI_Rate is null
				select @VLI_Rate = RATE_PER_UNIT  from MARITIMESLIVE..EXTRAS_SECTION_2(nolock) WHERE ltrim(rtrim(CODE)) ='VLI'
		end		
		else IF @DB = 'BCLIVE'
		begin
			select @Agreement_Status_Code = status_code from BCLIVE..agreements (nolock) where agreement_no=@AgreementNo	
			
			select @VLI_Rate = UNIT_PRICE from BCLIVE..RATE_EXTRAS where EXTRAS_CODE='VLI' and F_GROUP =@Authorized_VehicleCategory and RATE_SR_NO =@RATE_SR_NO
			
			if @VLI_Rate is null
				select @VLI_Rate = RATE_PER_UNIT  from BCLIVE..EXTRAS_SECTION_2(nolock) WHERE ltrim(rtrim(CODE)) ='VLI'
		end
		else IF @DB = 'SASKATCHEWANLIVE'
		begin
			select @Agreement_Status_Code = status_code from SASKATCHEWANLIVE..agreements (nolock) where agreement_no=@AgreementNo	
			
			select @VLI_Rate = UNIT_PRICE from SASKATCHEWANLIVE..RATE_EXTRAS where EXTRAS_CODE='VLI' and F_GROUP =@Authorized_VehicleCategory and RATE_SR_NO =@RATE_SR_NO
			
			if @VLI_Rate is null
				select @VLI_Rate = RATE_PER_UNIT  from SASKATCHEWANLIVE..EXTRAS_SECTION_2(nolock) WHERE ltrim(rtrim(CODE)) ='VLI'
		end			
			
		SET @dFinalTotal = (@Authorizedrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0)+ isnull(@VLI_Rate, 0))  * @DaysAuthorized 
		SET @dTotalExtras = (ISNULL(@UF, 0.0) + ISNULL(@WT, 0.0)+ isnull(@VLI_Rate, 0))* @DaysAuthorized  --+ ISNULL(@CDW, 0) 
		SET @dTotalInsurances = ISNULL(@CDW, 0.0) * @DaysAuthorized  				
			
		if @TaxPaidBy = 1 -- insurance
		begin
		  set @dTotalTaxes = @dFinalTotal * ((@GSTorHST + @PST)* .01)
		  set @dFinalTotal = @dFinalTotal + @dTotalTaxes
		end  
		else if @TaxPaidBy = 2 --customer
		begin	   		
			 set @dTotalTaxes = 0			 
		end	
			
		select * 
		into #myTemp
		from DA_AUTHORIZATION (nolock) 
		WHERE  DCA_CLAIM_ID =@RemedyEntryId
		
		SELECT @AuthFromTime = DAC_AUTHOR_TO_TIME, @DCA_Bill_To = DCA_BILL_TO FROM #myTemp(nolock) 
		group by DCA_AUTHOR_TO_DATE, DAC_AUTHOR_TO_TIME , DCA_BILL_TO
		ORDER BY DCA_AUTHOR_TO_DATE DESC
			
		drop table #myTemp	
			
		select @AuthToTime = @AuthFromTime	
			
		if @AuthFromDate is null or @AuthFromDate ='00000000'
		begin
			if @AuthToDate != '00000000' AND @AgreementNo >0
			begin
				set @AuthFromDate = convert(varchar(8), DATEADD(d, -@DaysAuthorized, convert(varchar(8), @AuthToDate, 112)), 112)	
				set @AuthSerial = 1
				set @AuthFromTime = @AgreementOpenTime
				set @AuthToTime = @AgreementOpenTime
			end
		ELSE
			BEGIN
				set @AuthFromDate =  convert(varchar(8), GETDATE(), 112)
				set @AuthToDate = convert(varchar(8), DATEADD(d, @DaysAuthorized, convert(varchar(8), GETDATE(), 112)), 112)	
				set @AuthSerial = 1
				set @AuthFromTime = 60
				set @AuthToTime = 60
			END 
		end	
			
		INSERT INTO DA_AUTHORIZATION(
			DCA_ENTRY_ID, 
			DCA_CLAIM_ID ,
			DCA_SUBMITTER ,
			DCA_CREATE_DATE,
			DCA_LAST_MODIFIED_BY,
			DCA_MODIFIED_DATE,
			DCA_STATUS,
			DCA_SHORT_DESCRIPTION ,
			DCA_ASSIGNEEGROUP,
			DCA_AUTHOR_FROM_DATE,
			DCA_AUTHOR_TO_DATE,
			DCA_AUTHOR_RATE,
			DCA_AUTHOR_AGENT_ID ,
			DCA_A_DAYS,
			DCA_AUTH_NOTES,
			DCA_BILL_TO,
			DCA_THEFT_WAIVER_AUTH,
			DCA_AUTH_VEHICLE,
			DAC_AUTHOR_FROM_TIME,
			DAC_AUTHOR_TO_TIME,
			DAC_VEH_EQUIV,
			DAC_PACKAGE,
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
			FINAL_AUTH,
			AGREEMENT_NO,
			BODY_SHOP_DIFF_FLAT_AMT,
			BODY_SHOP_DIFF_DAYS,
			DCA_AGR_AUTHORIZATION_NO
			)
			select 
			DCA_ENTRY_ID = @myAuthEntryID,
			DCA_CLAIM_ID = @RemedyEntryId,
			DCA_SUBMITTER = @ModyorCreatedByUser,
			DCA_CREATE_DATE = CONVERT(VARCHAR(8), GETDATE(), 112),
			DCA_LAST_MODIFIED_BY = @ModyorCreatedByUser,
			DCA_MODIFIED_DATE = CONVERT(VARCHAR(8), GETDATE(), 112),
			DCA_STATUS = 0,
			DCA_SHORT_DESCRIPTION = '',
			DCA_ASSIGNEEGROUP = '',
			DCA_AUTHOR_FROM_DATE =  @AuthFromDate,
			DCA_AUTHOR_TO_DATE =  CASE WHEN left(@AuthToDate,4) >= '2013' THEN @AuthToDate ELSE '00000000' END,
			DCA_AUTHOR_RATE = isnull(@Authorizedrate, 0.00),
			DCA_AUTHOR_AGENT_ID = '',
			DCA_A_DAYS = @DaysAuthorized,
			DCA_AUTH_NOTES = isnull(@AuthNotes, ''),
			DCA_BILL_TO = 1,
			DCA_THEFT_WAIVER_AUTH = '', 
			DCA_AUTH_VEHICLE = isnull(@Authorized_VehicleCategory, ''),
			DAC_AUTHOR_FROM_TIME = @AuthFromTime,
			DAC_AUTHOR_TO_TIME = @AuthToTime,
			DAC_VEH_EQUIV = isnull(@InsuredEquivClass, @Authorized_VehicleCategory),
			DAC_PACKAGE = @Rental_Package,	
			RATE_SR_NO = @RATE_SR_NO,
			RATE_DET_SR_NO = @RATE_DET_SR_NO,
			DAC_TAXES_PAID_BY = @TaxPaidBy,
			DAC_FINAL_TOTAL = @dFinalTotal,
			DCA_TOTAL_EXTRAS = @dTotalExtras ,
			DCA_TOTAL_INSURANCES = @dTotalInsurances,
			DCA_TOTAL_TAXES = @dTotalTaxes,
			DCA_TOTAL_RENTAL = @TotalRental ,
			VAT_PER = @GSTorHST,
			SERVICE_PER = @PST,
			FIRST_CHARGE_GROUP = @Authorized_VehicleCategory,
			FIRST_NO_OF_DAYS = @DaysAuthorized,
			FIRST_RENTAL_PACKAGE = @Rental_Package,
			FIRST_RATE_SR_NO = @RATE_SR_NO,
			FIRST_RATE_DET_SR_NO = @RATE_DET_SR_NO,
			FIRST_PER_DAY_PRICE = @Authorizedrate,
			FINAL_AUTH = @FinalAuth,
			AGREEMENT_NO = @AgreementNo,
			BODY_SHOP_DIFF_FLAT_AMT = 0,
			BODY_SHOP_DIFF_DAYS = 0,
			DCA_AGR_AUTHORIZATION_NO=''
			
			
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
			
		INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)VALUES
		(@myAuthEntryID,@ModyorCreatedByUser,@ModorCreateDate,@ModyorCreateTime,'Process','','Authorization Create', @RemedyEntryId)	
		INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)VALUES
		(@myAuthEntryID,@ModyorCreatedByUser,@ModorCreateDate,@ModyorCreateTime,'From Date','',CONVERT(VARCHAR(10), @AuthFromDate, 103) , @RemedyEntryId)	
		INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)VALUES
		(@myAuthEntryID,@ModyorCreatedByUser,@ModorCreateDate,@ModyorCreateTime,'To Date','',CONVERT(VARCHAR(10), @AuthToDate, 103), @RemedyEntryId)	
		INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)VALUES
		(@myAuthEntryID,@ModyorCreatedByUser,@ModorCreateDate,@ModyorCreateTime,'Authorization Days','',@DaysAuthorized, @RemedyEntryId)	
		INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)VALUES
		(@myAuthEntryID,@ModyorCreatedByUser,@ModorCreateDate,@ModyorCreateTime,'Authorization Rate','',@Authorizedrate, @RemedyEntryId)	
		INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)VALUES
		(@myAuthEntryID,@ModyorCreatedByUser,@ModorCreateDate,@ModyorCreateTime,'Authorization Category','',@Authorized_VehicleCategory, @RemedyEntryId)	
		INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)VALUES
		(@myAuthEntryID,@ModyorCreatedByUser,@ModorCreateDate,@ModyorCreateTime,'Vehicle Equivalent','',ISNULL(@InsuredEquivClass, @Authorized_VehicleCategory), @RemedyEntryId)	
		INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)VALUES
		(@myAuthEntryID,@ModyorCreatedByUser,@ModorCreateDate,@ModyorCreateTime,'Tax Paid By','','1', @RemedyEntryId)	
		INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)VALUES
		(@myAuthEntryID,@ModyorCreatedByUser,@ModorCreateDate,@ModyorCreateTime,'Bill To','','1', @RemedyEntryId)	
		INSERT INTO REMEDY_AUTH_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO,CLAIM_ID)VALUES
		(@myAuthEntryID,@ModyorCreatedByUser,@ModorCreateDate,@ModyorCreateTime,'Final Authorization','',@FinalAuth, @RemedyEntryId)
		INSERT INTO REMEDY_LOG_FILE(ENTRY_ID,MODIFIED_BY,MODIFIED_DATE,MODIFIED_TIME,FIELD_NAME,CHANGED_FROM,CHANGED_TO)
		VALUES(@RemedyEntryId,@ModyorCreatedByUser,@ModorCreateDate,@ModyorCreateTime,'Process','','Modify')
			
		UPDATE DA_CLAIMS SET DAC_RATE_OUT = @Authorizedrate ,INS_COMP_AUTH_DAYS = @TotalAuthDays WHERE DAC_ENTRY_ID = @RemedyEntryId			
		
		declare @MaxAmount decimal(18,2)
		if @Debitor_Code = @Third_Party_Debitor_Code 
			set @MaxAmount = @Third_Party_policyMax
        else                      						
		    set @MaxAmount = @PolicyMax			  
			
		if @DB = 'ONTARIOLIVE'
		BEGIN	
		if (@agreementno > 0  and @Agreement_Status_Code  in (0,1,2,3)) or (@ReservationNo != '' and @agreementno=0)
		begin		  
			select @MultipleDebitorAuthNo = AUTHORIZATION_NO,
			@RentalPrice = rental_price, @Insurances_Price = insurances_price , @Extras_Price = extras_price, @Insu_NonVat_Sum = Insu_NonVat_Sum,
			@KM_Sum = KM_Sum, @Airport_Fee = Airport_Fee, @DropOff_Fee = DropOff_Fee, @Fuel_Sum = Fuel_Sum, @Tel_Sum = Tel_Sum,
			@Delivery_Sum = Delivery_Sum, @Pickup_Sum = Pickup_Sum, @Other_Sum = Other_Sum, @Damages_Sum = Damages_Sum, 
			@Deductible_Sum = Deductible_Sum, @Traffic_Sum = Traffic_Sum, @Reduction_Sum = Reduction_Sum,
			@MDA_Max_Amt = MAX_AMOUNT , @Old_VAT = sales_tax,  @Old_SERVICE_FEE = service_tax , @MDA_TotalDays_Old = days, @Old_TotalAmount = amount 
			from ONTARIOLIVE..MULTIPLE_DEBITOR_AUTH (nolock) 
			where ((AGREEMENT = @AgreementNo and @AgreementNo >0) or (RESERVATION_NO = @ReservationNo and @agreementno=0)) 
			and debitor_code = @Debitor_Code AND @DCA_Bill_To != 2	
			  
		    if @Debitor_Code = @Third_Party_Debitor_Code 
			  set @MDA_Max_Amt = @Third_Party_policyMax
		    else                      						
			  set @MDA_Max_Amt = @PolicyMax
		  
		    select @MDA_Authrate = sum(DCA_AUTHOR_RATE*dca_a_days)/sum(dca_a_days), @MDA_TotalDays = sum(dca_a_days)  from da_authorization (nolock) where dca_Claim_id=@RemedyEntryId	
		    	  
		    select @RecID = isnull(REC_ID, 0)+1  from AGREEMENT_LOG_FILE where MASTER_AGREEMENT = @AgreementNo

		    INSERT INTO ontarioLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
		    VALUES(@AgreementNo,'DIAL', @ModorCreateDate, @ModyorCreateTime,'Modify Auth From Claim','','','D',@RecID)		
		    INSERT INTO ontarioLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
		    VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Authorization Created: 0000000','',@ModorCreateDate,'D',@RecID+1)	
		    INSERT INTO ontarioLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
		    VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Charge Group','', @Authorized_VehicleCategory,'D',@RecID+2)		
		    INSERT INTO ontarioLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
		    VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Per Day Price','',@Authorizedrate,'D',@RecID+3)		
		    INSERT INTO ontarioLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
		    VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Rate Sr No.','',@RATE_SR_NO,'D',@RecID+4)		
			INSERT INTO ontarioLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
			VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Rate Det Sr No.','',@RATE_DET_SR_NO,'D',@RecID+5)		
			INSERT INTO ontarioLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
			VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Sold Days','',@RATE_SR_NO,'D',@RecID+6)				
			INSERT INTO ontarioLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
			VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Days',@MDA_TotalDays_Old, @MDA_TotalDays, 'D', @RecID+7)		
			INSERT INTO ontarioLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
			VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Total Amount','',@RATE_DET_SR_NO,'D',@RecID+8)		
		
		--D - DATA	--T - TRANSACTION
		  
		if @MultipleDebitorAuthNo != '' --update
		BEGIN
				IF @ReservationNo != '' AND @AgreementNo = 0	-- reservation stage			
				begin
					UPDATE ontarioLIVE..MULTIPLE_DEBITOR_AUTH SET					
					RESERVATION_NO = @ReservationNo,
					DEBITOR_CODE = @Debitor_Code,
					AUTHORIZATION_NO = @MultipleDebitorAuthNo,
					DAYS = @MDA_TotalDays,							
					AGENTCOMMEXTERNV = 'O',
					F_GROUP = @Authorized_VehicleCategory,
					RENTAL_PACKAGE = @Rental_Package,
					Sold_Days = @MDA_TotalDays,
					LOSS_DATE = '00000000',
					CURRENCY = 'CAD',
					PER_DAY_PRICE = @MDA_Authrate,
					RATE_NO = isnull(@RateNo, 0), 
					RATE_SR_NO = @RATE_SR_NO,
					RATE_DET_SR_NO = @RATE_DET_SR_NO,
					VAT_PERCENT = @GSTorHST,
					SERVICE_FEE_PERCENT = @PST,
					RENTAL_PRICE = (@MDA_Authrate) * @MDA_TotalDays, --0.00,
					INSURANCES_PRICE = @Insurances_Price+@dTotalInsurances , --0.00,
					EXTRAS_PRICE = @Extras_Price+@dTotalExtras,
					AMOUNT = @Old_TotalAmount + @dFinalTotal,
					TAXABLE_SUM = (@MDA_Authrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @MDA_TotalDays ,
					SERVICABLE_SUM = 0.00,
					SALES_TAX = @Old_VAT+ @dTotalTaxes,
					SERVICE_TAX = @Old_SERVICE_FEE + 0.00,
					EXCHANGE_RATE = 1,
					SUBTOTAL = (@MDA_Authrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @MDA_TotalDays,
					MAX_AMOUNT = @MDA_Max_Amt,
					MAX_AMOUNT_CREDIT = @Tel_Sum,
					claim_no = @RemedyEntryID	
					WHERE RESERVATION_NO = @ReservationNo and AUTHORIZATION_NO = @MultipleDebitorAuthNo and DEBITOR_CODE = @Debitor_Code
				end
				
				IF @AgreementNo > 0				
				begin
					UPDATE ontarioLIVE..MULTIPLE_DEBITOR_AUTH SET 
					agreement = @AgreementNo,					
					RESERVATION_NO = @ReservationNo,
					DEBITOR_CODE = @Debitor_Code,
					AUTHORIZATION_NO = @MultipleDebitorAuthNo,
					DAYS = @MDA_TotalDays,							
					AGENTCOMMEXTERNV = 'O',
					F_GROUP = @Authorized_VehicleCategory,
					RENTAL_PACKAGE = @Rental_Package,
					Sold_Days = @MDA_TotalDays,
					LOSS_DATE = '00000000',
					CURRENCY = 'CAD',
					PER_DAY_PRICE = @MDA_Authrate,
					RATE_NO = isnull(@RateNo, 0), 
					RATE_SR_NO = @RATE_SR_NO,
					RATE_DET_SR_NO = @RATE_DET_SR_NO,
					VAT_PERCENT = @GSTorHST,
					SERVICE_FEE_PERCENT = @PST,
					RENTAL_PRICE = (@MDA_Authrate)  * @MDA_TotalDays, --0.00,
					INSURANCES_PRICE = @Insurances_Price+@dTotalInsurances , --0.00,
					EXTRAS_PRICE = @Extras_Price+@dTotalExtras,
					AMOUNT = @Old_TotalAmount + @dFinalTotal,
					TAXABLE_SUM = (@MDA_Authrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @MDA_TotalDays ,
					SERVICABLE_SUM = 0.00,
					SALES_TAX = @Old_VAT+ @dTotalTaxes,
					SERVICE_TAX = @Old_SERVICE_FEE + 0.00,
					EXCHANGE_RATE = 1,
					SUBTOTAL = (@MDA_Authrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @MDA_TotalDays,
					MAX_AMOUNT = @MDA_Max_Amt,
					MAX_AMOUNT_CREDIT = @Tel_Sum,
					claim_no = @RemedyEntryID	
					WHERE AGREEMENT = @AgreementNo and AUTHORIZATION_NO = @MultipleDebitorAuthNo and DEBITOR_CODE = @Debitor_Code
				end		
				
				
			if not exists
			(select 1 from ontarioLIVE..DEBITOR_PAY_FLAGS (nolock) where AUTHRIZATION_NO = @MultipleDebitorAuthNo --AND AGREEMENT_NO= @AgreementNo AND DEBITOR_CODE= @debitor_code
			)							
			begin
			insert into ontarioLIVE..DEBITOR_PAY_FLAGS (
			[AUTHRIZATION_NO]
			,[PAY_RENTAL]
			,[PAY_EXTENSION]
			,[PAY_UPSELL]
			,[PAY_KM]
			,[PAY_FUEL]		
			,[PAY_DAMAGE]
			,[PAY_TRAFFIC]
			,[PAY_AIRPORTFEE]
			,[PAY_DROPOFFFEE]
			,[PAY_DELIVERY]
			,[PAY_PICKUP]
			,[PAY_INS]
			,[PAY_EXT]
			,[PAY_OTHER]
			,[GET_RED]
			,[PAY_SERVICE]
			,[PAY_VAT]
			,[PAY_TELEPHONE]
			,[PAY_DEDUACTABLE]
			,[PAY_HIGH_WAY_TICKET]
			,[PAY_HIGHWAYADMIN]
			,[CREATED_FROM]
			,[AGREEMENT_NO]
			,[DEBITOR_CODE]
			,[SEPARATE_DAMAGE_INVOICE]
			,[SEPARATE_TRAFFIC_INVOICE]
			,[PREBILLING_IN_ADVANCE]
			,[BILLTO_END_OF_MONTH]
			,[PREBILLING_INVOICE_METHOD]
			,[REQUIRE_VOUCHER_CONFIRMATION]
			,[COMBINATION_PREBILLING]
			,[FULLY_AUTHORIZE]
			,[COMBINATION_INVOICE]
			,[COMB_DAMGE_INVOICE]
			,[COMB_TRAFFIC_INVOICE]
			,[COMB_HIGHWAY_INVOICE]
			,[PREBILLING_CHARGE_KM]
			,[RENTAL_BEFORE_DISCOUNT]
			,[RENTAL_EXT_BEFORE_DISCOUNT]
			,[KM_PRICE_BEFORE_DISCOUNT]
			,[RENTAL_VAT_AMOUNT]
			,[RENTAL_EXT_VAT_AMOUNT]
			,[INS_SUM_BEFORE_DISCOUNT]
			,[INS_SUM_BEFORE_DIS_WITHOUTVAT]
			,[KM_VAT_AMOUNT]
			,[CUST_TRAFFIC_ADMIN_FEE]
			,[AIRPORT_VAT_AMOUNT]
			,[DROPOFF_VAT_AMOUNT]
			,[FUEL_VAT_AMOUNT]
			,[DELIVERY_VAT_AMOUNT]
			,[PICKKUP_VAT_AMOUNT]
			,[OTHERSUM_VAT_AMOUNT]
			,[REDUCTION_VAT_AMOUNT]
			,[DAMAGES_VAT_AMOUNT]
			,[DEDUCTIBLE_VAT_AMOUNT]
			,[TRAFFIC_VAT_AMOUNT]
			,[INS_VAT_AMOUNT]
			,[EXTRAS_VAT_AMOUNT]
			,[DISCOUNT_VAT_AMOUNT]
			,[RENTAL_SERVICE_AMOUNT]
			,[RENTALEXT_SERVICE_AMOUNT]
			,[KM_SERVICE_AMOUNT]
			,[AIRPORT_SERVICE_AMOUNT]
			,[DROPOFF_SERVICE_AMOUNT]
			,[FUEL_SERVICE_AMOUNT]
			,[DELIVERY_SERVICE_AMOUNT]
			,[PICKUP_SERVICE_AMOUNT]
			,[OTHERSUM_SERVICE_AMOUNT]
			,[REDUCTION_SERVICE_AMOUNT]
			,[DAMAGES_SERVICE_AMOUNT]
			,[DEDCTIBLE_SERVICE_AMOUNT]
			,[TRAFFIC_SERVICE_AMOUNT]
			,[INS_SERVICE_AMOUNT]
			,[EXTRAS_SERVICE_AMOUNT]
			,[DISCOUNT_SERVICE_AMOUNT]
			,[PACKAGE_PRICE]
			,[PACKAGE_EXT_PRICE]
			,[KM_PRICE]
			,[RENTAL_DISCOUNT_AMOUNT]
			,[RENTAL_EXT_DISCOUNT_SUM]
			,[KM_DISCOUNT_AMOUNT]
			,[INS_DISCOUNT_AMOUNT]
			,[INS_DISC_AMOUNT_WT_OUT_VAT]
			,[TOTAL_DISCOUNT_AMOUNT]
			,[NON_TAXBLE_AMOUNT]
			,[NON_SERVICABLE_AMOUNT]
			,[PACKAGE_DAYS]
			,[PACKAGE_ADD_DAYS]
			,[EXTENSION_DAYS]
			,[TRAFFIC_ADMIN_FEE_VAT_AMT]
			,[TRAFFIC_ADMIN_FEE_SERVICE_AMT]
			,[TRAFFIC_AMT_WO_ADMIN_FEE]
			,[BILLING_FREQUENCY]
			,[SEPARATE_REPLACEMENT_INV]
			,[SEPARATE_FUEL_INV]
			,[COMB_FUEL_INVOICE]
			,[INVOICE_BY]
			,[PAY_TOLL]
			,[SEPARATE_TOLL_INVOICE]
			,[TOLL_WO_ADMIN_FEE]
			,[TOLL_ADMIN_FEE]
			,[TOLL_VAT_AMT]
			,[TOLL_SERVICE_AMT]
			,[TOLL_ADMIN_FEEPER_SETUP]
			,[TOLL_ADMIN_FEEAMT_SETUP]
			,[DAMAGE_WO_ADMIN_FEE]
			,[DAMAGE_ADMIN_FEE]
			,[DED_WO_ADMIN_FEE]
			,[DED_ADMIN_FEE]
			,[PAY_ENTIRE_BILL]
			,[PAY_ALL_TAXES]
			,[PAY_RATE_PER_DAY]
			,[PAY_SURCHARGE]
			,[PAY_GST_HST]
			,[MONTHLY_DAYS]
			)

		   select 
		   [AUTHRIZATION_NO] = @MultipleDebitorAuthNo
		  ,[PAY_RENTAL] = 'Y'
		  ,[PAY_EXTENSION]= ''
		  ,[PAY_UPSELL]= ''
		  ,[PAY_KM]= 'N'
		  ,[PAY_FUEL]= 'N'
		  ,[PAY_DAMAGE]= 'N'
		  ,[PAY_TRAFFIC]= 'N'
		  ,[PAY_AIRPORTFEE]= 'N'
		  ,[PAY_DROPOFFFEE]= 'N'
		  ,[PAY_DELIVERY]= 'N'
		  ,[PAY_PICKUP]= 'N'
		  ,[PAY_INS]= CASE WHEN @CDW > 0 THEN 'Y' ELSE 'N' END
		  ,[PAY_EXT]= 'Y'
		  ,[PAY_OTHER]= 'N'
		  ,[GET_RED]= 'Y'
		  ,[PAY_SERVICE]= CASE WHEN @PST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_VAT]= CASE WHEN @GSTorHST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_TELEPHONE]= ''
		  ,[PAY_DEDUACTABLE]= ''
		  ,[PAY_HIGH_WAY_TICKET]= ''
		  ,[PAY_HIGHWAYADMIN]= ''
		  ,[CREATED_FROM]= ''
		  ,[AGREEMENT_NO]= @AgreementNo
		  ,[DEBITOR_CODE]= @debitor_code
		  ,[SEPARATE_DAMAGE_INVOICE]= ''
		  ,[SEPARATE_TRAFFIC_INVOICE] = ''
		  ,[PREBILLING_IN_ADVANCE]= ''
		  ,[BILLTO_END_OF_MONTH]= ''
		  ,[PREBILLING_INVOICE_METHOD]= ''
		  ,[REQUIRE_VOUCHER_CONFIRMATION]= ''
		  ,[COMBINATION_PREBILLING]= ''
		  ,[FULLY_AUTHORIZE]= ''
		  ,[COMBINATION_INVOICE]= ''
		  ,[COMB_DAMGE_INVOICE]= ''
		  ,[COMB_TRAFFIC_INVOICE]= ''
		  ,[COMB_HIGHWAY_INVOICE]= ''
		  ,[PREBILLING_CHARGE_KM]= ''
		  ,[RENTAL_BEFORE_DISCOUNT]=  @MDA_Authrate * @TotalAuthDays
		  ,[RENTAL_EXT_BEFORE_DISCOUNT]= ''
		  ,[KM_PRICE_BEFORE_DISCOUNT]= ''
		  ,[RENTAL_VAT_AMOUNT]= @Old_VAT+ @dTotalTaxes
		  ,[RENTAL_EXT_VAT_AMOUNT]= ''
		  ,[INS_SUM_BEFORE_DISCOUNT]= @Insurances_Price+@dTotalInsurances
		  ,[INS_SUM_BEFORE_DIS_WITHOUTVAT]= ''
		  ,[KM_VAT_AMOUNT]= ''
		  ,[CUST_TRAFFIC_ADMIN_FEE]= ''
		  ,[AIRPORT_VAT_AMOUNT]= ''
		  ,[DROPOFF_VAT_AMOUNT]= ''
		  ,[FUEL_VAT_AMOUNT]= ''
		  ,[DELIVERY_VAT_AMOUNT]= ''
		  ,[PICKKUP_VAT_AMOUNT]= ''
		  ,[OTHERSUM_VAT_AMOUNT]= ''
		  ,[REDUCTION_VAT_AMOUNT]= ''
		  ,[DAMAGES_VAT_AMOUNT]= ''
		  ,[DEDUCTIBLE_VAT_AMOUNT]= ''
		  ,[TRAFFIC_VAT_AMOUNT]= ''
		  ,[INS_VAT_AMOUNT]= ((@Insurances_Price+@dTotalInsurances) * @GSTorHST) / 100
		  ,[EXTRAS_VAT_AMOUNT]= ((@Extras_Price+@dTotalExtras) * @GSTorHST) / 100
		  ,[DISCOUNT_VAT_AMOUNT]= ''
		  ,[RENTAL_SERVICE_AMOUNT]= @Old_SERVICE_FEE + 0.00
		  ,[RENTALEXT_SERVICE_AMOUNT]= ''
		  ,[KM_SERVICE_AMOUNT]= ''
		  ,[AIRPORT_SERVICE_AMOUNT]= ''
		  ,[DROPOFF_SERVICE_AMOUNT]= ''
		  ,[FUEL_SERVICE_AMOUNT]= ''
		  ,[DELIVERY_SERVICE_AMOUNT]= ''
		  ,[PICKUP_SERVICE_AMOUNT]= ''
		  ,[OTHERSUM_SERVICE_AMOUNT]= ''
		  ,[REDUCTION_SERVICE_AMOUNT]= ''
		  ,[DAMAGES_SERVICE_AMOUNT]= ''
		  ,[DEDCTIBLE_SERVICE_AMOUNT]= ''
		  ,[TRAFFIC_SERVICE_AMOUNT] = 0
		  ,[INS_SERVICE_AMOUNT] = 0
		  ,[EXTRAS_SERVICE_AMOUNT] = 0
		  ,[DISCOUNT_SERVICE_AMOUNT] = 0
		  ,[PACKAGE_PRICE] = 0
		  ,[PACKAGE_EXT_PRICE] = 0
		  ,[KM_PRICE] = 0
		  ,[RENTAL_DISCOUNT_AMOUNT] = 0
		  ,[RENTAL_EXT_DISCOUNT_SUM] = 0
		  ,[KM_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISC_AMOUNT_WT_OUT_VAT] = 0
		  ,[TOTAL_DISCOUNT_AMOUNT] = 0
		  ,[NON_TAXBLE_AMOUNT] = 0
		  ,[NON_SERVICABLE_AMOUNT] = 0
		  ,[PACKAGE_DAYS] = 0
		  ,[PACKAGE_ADD_DAYS] = 0
		  ,[EXTENSION_DAYS] = 0
		  ,[TRAFFIC_ADMIN_FEE_VAT_AMT] = 0
		  ,[TRAFFIC_ADMIN_FEE_SERVICE_AMT] = 0
		  ,[TRAFFIC_AMT_WO_ADMIN_FEE] = 0
		  ,[BILLING_FREQUENCY] = 0
		  ,[SEPARATE_REPLACEMENT_INV] = 'N'
		  ,[SEPARATE_FUEL_INV] = 'N'
		  ,[COMB_FUEL_INVOICE] = 'N'
		  ,[INVOICE_BY] = 'A'
		  ,[PAY_TOLL] =  'N'
		  ,[SEPARATE_TOLL_INVOICE] = 'N'
		  ,[TOLL_WO_ADMIN_FEE] = 0
		  ,[TOLL_ADMIN_FEE] = 0
		  ,[TOLL_VAT_AMT] = 0
		  ,[TOLL_SERVICE_AMT] = 0
		  ,[TOLL_ADMIN_FEEPER_SETUP] = 0
		  ,[TOLL_ADMIN_FEEAMT_SETUP] = 0
		  ,[DAMAGE_WO_ADMIN_FEE] = 0
		  ,[DAMAGE_ADMIN_FEE] = 0
		  ,[DED_WO_ADMIN_FEE] = 0
		  ,[DED_ADMIN_FEE] = 0
		  ,[PAY_ENTIRE_BILL]  = 'N'
		  ,[PAY_ALL_TAXES] = 'Y'
		  ,[PAY_RATE_PER_DAY] = 'N'
		  ,[PAY_SURCHARGE] = 'N'
		  ,[PAY_GST_HST] = 'Y'
		  ,[MONTHLY_DAYS] = 0
		end
		
		ELSE
		BEGIN -- UPDATE MDA DEBITOR_FLAGS
		UPDATE ontarioLIVE..DEBITOR_PAY_FLAGS SET 
		   --[AUTHRIZATION_NO] = @MultipleDebitorAuthNo
		  [PAY_RENTAL] = 'Y'
		  ,[PAY_EXTENSION]= ''
		  ,[PAY_UPSELL]= ''
		  ,[PAY_KM]= 'N'
		  ,[PAY_FUEL]= 'N'
		  ,[PAY_DAMAGE]= 'N'
		  ,[PAY_TRAFFIC]= 'N'
		  ,[PAY_AIRPORTFEE]= 'N'
		  ,[PAY_DROPOFFFEE]= 'N'
		  ,[PAY_DELIVERY]= 'N'
		  ,[PAY_PICKUP]= 'N'
		  ,[PAY_INS]= CASE WHEN @CDW > 0 THEN 'Y' ELSE 'N' END
		  ,[PAY_EXT]= 'Y'
		  ,[PAY_OTHER]= 'N'
		  ,[GET_RED]= 'Y'
		  ,[PAY_SERVICE]= CASE WHEN @PST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_VAT]= CASE WHEN @GSTorHST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_TELEPHONE]= ''
		  ,[PAY_DEDUACTABLE]= ''
		  ,[PAY_HIGH_WAY_TICKET]= ''
		  ,[PAY_HIGHWAYADMIN]= ''
		  ,[CREATED_FROM]= ''
		  ,[AGREEMENT_NO]= @AgreementNo
		  ,[DEBITOR_CODE]= @debitor_code
		  ,[SEPARATE_DAMAGE_INVOICE]= ''
		  ,[SEPARATE_TRAFFIC_INVOICE] = ''
		  ,[PREBILLING_IN_ADVANCE]= ''
		  ,[BILLTO_END_OF_MONTH]= ''
		  ,[PREBILLING_INVOICE_METHOD]= ''
		  ,[REQUIRE_VOUCHER_CONFIRMATION]= ''
		  ,[COMBINATION_PREBILLING]= ''
		  ,[FULLY_AUTHORIZE]= ''
		  ,[COMBINATION_INVOICE]= ''
		  ,[COMB_DAMGE_INVOICE]= ''
		  ,[COMB_TRAFFIC_INVOICE]= ''
		  ,[COMB_HIGHWAY_INVOICE]= ''
		  ,[PREBILLING_CHARGE_KM]= ''
		  ,[RENTAL_BEFORE_DISCOUNT]=  @MDA_Authrate * @TotalAuthDays
		  ,[RENTAL_EXT_BEFORE_DISCOUNT]= ''
		  ,[KM_PRICE_BEFORE_DISCOUNT]= ''
		  ,[RENTAL_VAT_AMOUNT]= @Old_VAT+ @dTotalTaxes
		  ,[RENTAL_EXT_VAT_AMOUNT]= ''
		  ,[INS_SUM_BEFORE_DISCOUNT]= @Insurances_Price+@dTotalInsurances
		  ,[INS_SUM_BEFORE_DIS_WITHOUTVAT]= ''
		  ,[KM_VAT_AMOUNT]= ''
		  ,[CUST_TRAFFIC_ADMIN_FEE]= ''
		  ,[AIRPORT_VAT_AMOUNT]= ''
		  ,[DROPOFF_VAT_AMOUNT]= ''
		  ,[FUEL_VAT_AMOUNT]= ''
		  ,[DELIVERY_VAT_AMOUNT]= ''
		  ,[PICKKUP_VAT_AMOUNT]= ''
		  ,[OTHERSUM_VAT_AMOUNT]= ''
		  ,[REDUCTION_VAT_AMOUNT]= ''
		  ,[DAMAGES_VAT_AMOUNT]= ''
		  ,[DEDUCTIBLE_VAT_AMOUNT]= ''
		  ,[TRAFFIC_VAT_AMOUNT]= ''
		  ,[INS_VAT_AMOUNT]= ((@Insurances_Price+@dTotalInsurances) * @GSTorHST) / 100
		  ,[EXTRAS_VAT_AMOUNT]= ((@Extras_Price+@dTotalExtras) * @GSTorHST) / 100
		  ,[DISCOUNT_VAT_AMOUNT]= ''
		  ,[RENTAL_SERVICE_AMOUNT]= @Old_SERVICE_FEE + 0.00
		  ,[RENTALEXT_SERVICE_AMOUNT]= ''
		  ,[KM_SERVICE_AMOUNT]= ''
		  ,[AIRPORT_SERVICE_AMOUNT]= ''
		  ,[DROPOFF_SERVICE_AMOUNT]= ''
		  ,[FUEL_SERVICE_AMOUNT]= ''
		  ,[DELIVERY_SERVICE_AMOUNT]= ''
		  ,[PICKUP_SERVICE_AMOUNT]= ''
		  ,[OTHERSUM_SERVICE_AMOUNT]= ''
		  ,[REDUCTION_SERVICE_AMOUNT]= ''
		  ,[DAMAGES_SERVICE_AMOUNT]= ''
		  ,[DEDCTIBLE_SERVICE_AMOUNT]= ''
		  ,[TRAFFIC_SERVICE_AMOUNT] = 0
		  ,[INS_SERVICE_AMOUNT] = 0
		  ,[EXTRAS_SERVICE_AMOUNT] = 0
		  ,[DISCOUNT_SERVICE_AMOUNT] = 0
		  ,[PACKAGE_PRICE] = 0
		  ,[PACKAGE_EXT_PRICE] = 0
		  ,[KM_PRICE] = 0
		  ,[RENTAL_DISCOUNT_AMOUNT] = 0
		  ,[RENTAL_EXT_DISCOUNT_SUM] = 0
		  ,[KM_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISC_AMOUNT_WT_OUT_VAT] = 0
		  ,[TOTAL_DISCOUNT_AMOUNT] = 0
		  ,[NON_TAXBLE_AMOUNT] = 0
		  ,[NON_SERVICABLE_AMOUNT] = 0
		  ,[PACKAGE_DAYS] = 0
		  ,[PACKAGE_ADD_DAYS] = 0
		  ,[EXTENSION_DAYS] = 0
		  ,[TRAFFIC_ADMIN_FEE_VAT_AMT] = 0
		  ,[TRAFFIC_ADMIN_FEE_SERVICE_AMT] = 0
		  ,[TRAFFIC_AMT_WO_ADMIN_FEE] = 0
		  ,[BILLING_FREQUENCY] = 0
		  ,[SEPARATE_REPLACEMENT_INV] = 'N'
		  ,[SEPARATE_FUEL_INV] = 'N'
		  ,[COMB_FUEL_INVOICE] = 'N'
		  ,[INVOICE_BY] = 'A'
		  ,[PAY_TOLL] =  'N'
		  ,[SEPARATE_TOLL_INVOICE] = 'N'
		  ,[TOLL_WO_ADMIN_FEE] = 0
		  ,[TOLL_ADMIN_FEE] = 0
		  ,[TOLL_VAT_AMT] = 0
		  ,[TOLL_SERVICE_AMT] = 0
		  ,[TOLL_ADMIN_FEEPER_SETUP] = 0
		  ,[TOLL_ADMIN_FEEAMT_SETUP] = 0
		  ,[DAMAGE_WO_ADMIN_FEE] = 0
		  ,[DAMAGE_ADMIN_FEE] = 0
		  ,[DED_WO_ADMIN_FEE] = 0
		  ,[DED_ADMIN_FEE] = 0
		  ,[PAY_ENTIRE_BILL]  = 'N'
		  ,[PAY_ALL_TAXES] = 'Y'
		  ,[PAY_RATE_PER_DAY] = 'N'
		  ,[PAY_SURCHARGE] = 'N'
		  ,[PAY_GST_HST] = 'Y'
		  ,[MONTHLY_DAYS] = 0
		  WHERE [AUTHRIZATION_NO] = @MultipleDebitorAuthNo AND DEBITOR_CODE=@debitor_code AND AGREEMENT_NO=@AgreementNo
		  END
				
			UPDATE DA_CLAIMS SET  DAC_RATE_OUT = ISNULL(@MDA_Authrate, 0), INS_COMP_AUTH_DAYS = @MDA_TotalDays WHERE DAC_ENTRY_ID = @RemedyEntryId	
			end
			ELSE
			BEGIN --create MDA						
			-------------------------------  AUTHORIZATION NO FOR MULTIPLE DEBITOR AUTH | AUTHORIZATION_AGR_RES    -------------------------------------
			
			SELECT @iDocNobigint =DN_DOCUMENT_NUMBER+1 from DOCUMENT_NUMBERS b(nolock) WHERE DN_COMPANY_CODE = 1 AND DN_BRANCH_CODE = 0 AND DN_DOCUMENT_TYPE = 12		
			
			if exists( select AUTHORIZATION_NO from ontarioLIVE..MULTIPLE_DEBITOR_AUTH(nolock)	where  convert(bigint,AUTHORIZATION_NO)	=@iDocNobigint)
			begin	
				while exists( select AUTHORIZATION_NO from ontarioLIVE..MULTIPLE_DEBITOR_AUTH(nolock)	where  convert(bigint,AUTHORIZATION_NO)	=@iDocNobigint)
				begin
					
					if not exists( select AUTHORIZATION_NO from ontarioLIVE..MULTIPLE_DEBITOR_AUTH(nolock)	where  convert(bigint,AUTHORIZATION_NO)	=@iDocNobigint)
						break
						
					select @iDocNobigint= @iDocNobigint + 1
				end
			end
			
			select @MultipleDebitorAuthNo= RIGHT( convert(varchar(20),@iDocNobigint + 10000000000000000),15)				
							
			UPDATE DOCUMENT_NUMBERS SET  DN_DOCUMENT_NUMBER = @iDocNobigint 
			WHERE DN_COMPANY_CODE = @CompanyCode AND DN_BRANCH_CODE = 0 AND DN_DOCUMENT_TYPE = 12 		
			-----------------------------------------END----------------------------------------------------------------------------------------------------
			INSERT INTO ontarioLIVE..MULTIPLE_DEBITOR_AUTH
			(AGREEMENT,
			RESERVATION_NO,
			DEBITOR_CODE,
			AUTHORIZATION_NO,
			DAYS,
			AGENTCOMMEXTERNV,
			F_GROUP,
			RENTAL_PACKAGE,
			Sold_Days,
			LOSS_DATE,
			CURRENCY,
			PER_DAY_PRICE,
			RATE_SR_NO,
			RATE_DET_SR_NO,
			VAT_PERCENT,
			SERVICE_FEE_PERCENT,
			RENTAL_PRICE,
			INSURANCES_PRICE,
			EXTRAS_PRICE,
			AMOUNT,
			TAXABLE_SUM,
			SERVICABLE_SUM,
			SALES_TAX,
			SERVICE_TAX,
			EXCHANGE_RATE,
			SUBTOTAL,
			FIRST_CHARGE_GROUP,
			FIRST_NO_OF_DAYS,
			FIRST_RENTAL_PACKAGE,
			FIRST_RATE_SR_NO,
			FIRST_RATE_DET_SR_NO,
			FIRST_PER_DAY_PRICE,
			BODY_SHOP_DIFF_FLAT_AMT,
			BODY_SHOP_DIFF_DAYS,
			MAX_AMOUNT,
			MAX_AMOUNT_CREDIT,
			claim_no,
			RATE_NO 
			)
			SELECT
			AGREEMENT = @AgreementNo,
			RESERVATION_NO = @ReservationNo,
			DEBITOR_CODE = @Debitor_Code,
			AUTHORIZATION_NO = @MultipleDebitorAuthNo,
			DAYS = @DaysAuthorized,
			AGENTCOMMEXTERNV = 'O',
			F_GROUP = @Authorized_VehicleCategory,
			RENTAL_PACKAGE = @Rental_Package,
			Sold_Days = @DaysAuthorized,
			LOSS_DATE = '00000000',
			CURRENCY = 'CAD',
			PER_DAY_PRICE = @Authorizedrate,
			RATE_SR_NO = @RATE_SR_NO,
			RATE_DET_SR_NO = @RATE_DET_SR_NO,
			VAT_PERCENT = @GSTorHST,
			SERVICE_FEE_PERCENT = @PST,
			RENTAL_PRICE = (@Authorizedrate)  * @DaysAuthorized, --0.00,
			INSURANCES_PRICE = @dTotalInsurances , --0.00,
			EXTRAS_PRICE = @dTotalExtras,
			AMOUNT = @dFinalTotal,
			TAXABLE_SUM = (@Authorizedrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @DaysAuthorized ,
			SERVICABLE_SUM = 0.00,
			SALES_TAX = @dTotalTaxes,
			SERVICE_TAX = 0.00,
			EXCHANGE_RATE = 1,
			SUBTOTAL = (@Authorizedrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @DaysAuthorized,
			FIRST_CHARGE_GROUP = @Authorized_VehicleCategory,
			FIRST_NO_OF_DAYS = @DaysAuthorized,
			FIRST_RENTAL_PACKAGE = @Rental_Package,
			FIRST_RATE_SR_NO = @RATE_SR_NO,
			FIRST_RATE_DET_SR_NO = @RATE_DET_SR_NO,
			FIRST_PER_DAY_PRICE = @Authorizedrate,
			BODY_SHOP_DIFF_FLAT_AMT  = 0.00,
			BODY_SHOP_DIFF_DAYS = 0,
			MAX_AMOUNT = @MaxAmount,
			MAX_AMOUNT_CREDIT = 0,
			claim_no = @RemedyEntryID,
			RATE_NO = isnull(@RateNo, 0)			
			
			if not exists
			(select 1 from ontarioLIVE..DEBITOR_PAY_FLAGS (nolock) where AUTHRIZATION_NO = @MultipleDebitorAuthNo --AND AGREEMENT_NO=@AGREEMENTNO AND DEBITOR_CODE=@debitor_code
			)							
			begin
			insert into ontarioLIVE..DEBITOR_PAY_FLAGS (
			[AUTHRIZATION_NO]
			,[PAY_RENTAL]
			,[PAY_EXTENSION]
			,[PAY_UPSELL]
			,[PAY_KM]
			,[PAY_FUEL]		
			,[PAY_DAMAGE]
			,[PAY_TRAFFIC]
			,[PAY_AIRPORTFEE]
			,[PAY_DROPOFFFEE]
			,[PAY_DELIVERY]
			,[PAY_PICKUP]
			,[PAY_INS]
			,[PAY_EXT]
			,[PAY_OTHER]
			,[GET_RED]
			,[PAY_SERVICE]
			,[PAY_VAT]
			,[PAY_TELEPHONE]
			,[PAY_DEDUACTABLE]
			,[PAY_HIGH_WAY_TICKET]
			,[PAY_HIGHWAYADMIN]
			,[CREATED_FROM]
			,[AGREEMENT_NO]
			,[DEBITOR_CODE]
			,[SEPARATE_DAMAGE_INVOICE]
			,[SEPARATE_TRAFFIC_INVOICE]
			,[PREBILLING_IN_ADVANCE]
			,[BILLTO_END_OF_MONTH]
			,[PREBILLING_INVOICE_METHOD]
			,[REQUIRE_VOUCHER_CONFIRMATION]
			,[COMBINATION_PREBILLING]
			,[FULLY_AUTHORIZE]
			,[COMBINATION_INVOICE]
			,[COMB_DAMGE_INVOICE]
			,[COMB_TRAFFIC_INVOICE]
			,[COMB_HIGHWAY_INVOICE]
			,[PREBILLING_CHARGE_KM]
			,[RENTAL_BEFORE_DISCOUNT]
			,[RENTAL_EXT_BEFORE_DISCOUNT]
			,[KM_PRICE_BEFORE_DISCOUNT]
			,[RENTAL_VAT_AMOUNT]
			,[RENTAL_EXT_VAT_AMOUNT]
			,[INS_SUM_BEFORE_DISCOUNT]
			,[INS_SUM_BEFORE_DIS_WITHOUTVAT]
			,[KM_VAT_AMOUNT]
			,[CUST_TRAFFIC_ADMIN_FEE]
			,[AIRPORT_VAT_AMOUNT]
			,[DROPOFF_VAT_AMOUNT]
			,[FUEL_VAT_AMOUNT]
			,[DELIVERY_VAT_AMOUNT]
			,[PICKKUP_VAT_AMOUNT]
			,[OTHERSUM_VAT_AMOUNT]
			,[REDUCTION_VAT_AMOUNT]
			,[DAMAGES_VAT_AMOUNT]
			,[DEDUCTIBLE_VAT_AMOUNT]
			,[TRAFFIC_VAT_AMOUNT]
			,[INS_VAT_AMOUNT]
			,[EXTRAS_VAT_AMOUNT]
			,[DISCOUNT_VAT_AMOUNT]
			,[RENTAL_SERVICE_AMOUNT]
			,[RENTALEXT_SERVICE_AMOUNT]
			,[KM_SERVICE_AMOUNT]
			,[AIRPORT_SERVICE_AMOUNT]
			,[DROPOFF_SERVICE_AMOUNT]
			,[FUEL_SERVICE_AMOUNT]
			,[DELIVERY_SERVICE_AMOUNT]
			,[PICKUP_SERVICE_AMOUNT]
			,[OTHERSUM_SERVICE_AMOUNT]
			,[REDUCTION_SERVICE_AMOUNT]
			,[DAMAGES_SERVICE_AMOUNT]
			,[DEDCTIBLE_SERVICE_AMOUNT]
			,[TRAFFIC_SERVICE_AMOUNT]
			,[INS_SERVICE_AMOUNT]
			,[EXTRAS_SERVICE_AMOUNT]
			,[DISCOUNT_SERVICE_AMOUNT]
			,[PACKAGE_PRICE]
			,[PACKAGE_EXT_PRICE]
			,[KM_PRICE]
			,[RENTAL_DISCOUNT_AMOUNT]
			,[RENTAL_EXT_DISCOUNT_SUM]
			,[KM_DISCOUNT_AMOUNT]
			,[INS_DISCOUNT_AMOUNT]
			,[INS_DISC_AMOUNT_WT_OUT_VAT]
			,[TOTAL_DISCOUNT_AMOUNT]
			,[NON_TAXBLE_AMOUNT]
			,[NON_SERVICABLE_AMOUNT]
			,[PACKAGE_DAYS]
			,[PACKAGE_ADD_DAYS]
			,[EXTENSION_DAYS]
			,[TRAFFIC_ADMIN_FEE_VAT_AMT]
			,[TRAFFIC_ADMIN_FEE_SERVICE_AMT]
			,[TRAFFIC_AMT_WO_ADMIN_FEE]
			,[BILLING_FREQUENCY]
			,[SEPARATE_REPLACEMENT_INV]
			,[SEPARATE_FUEL_INV]
			,[COMB_FUEL_INVOICE]
			,[INVOICE_BY]
			,[PAY_TOLL]
			,[SEPARATE_TOLL_INVOICE]
			,[TOLL_WO_ADMIN_FEE]
			,[TOLL_ADMIN_FEE]
			,[TOLL_VAT_AMT]
			,[TOLL_SERVICE_AMT]
			,[TOLL_ADMIN_FEEPER_SETUP]
			,[TOLL_ADMIN_FEEAMT_SETUP]
			,[DAMAGE_WO_ADMIN_FEE]
			,[DAMAGE_ADMIN_FEE]
			,[DED_WO_ADMIN_FEE]
			,[DED_ADMIN_FEE]
			,[PAY_ENTIRE_BILL]
			,[PAY_ALL_TAXES]
			,[PAY_RATE_PER_DAY]
			,[PAY_SURCHARGE]
			,[PAY_GST_HST]
			,[MONTHLY_DAYS]
			)

		   select 
		   [AUTHRIZATION_NO] = @MultipleDebitorAuthNo
		  ,[PAY_RENTAL] = 'Y'
		  ,[PAY_EXTENSION]= ''
		  ,[PAY_UPSELL]= ''
		  ,[PAY_KM]= 'N'
		  ,[PAY_FUEL]= 'N'
		  ,[PAY_DAMAGE]= 'N'
		  ,[PAY_TRAFFIC]= 'N'
		  ,[PAY_AIRPORTFEE]= 'N'
		  ,[PAY_DROPOFFFEE]= 'N'
		  ,[PAY_DELIVERY]= 'N'
		  ,[PAY_PICKUP]= 'N'
		  ,[PAY_INS]= CASE WHEN @CDW > 0 THEN 'Y' ELSE 'N' END
		  ,[PAY_EXT]= 'Y'
		  ,[PAY_OTHER]= 'N'
		  ,[GET_RED]= 'Y'
		  ,[PAY_SERVICE]= CASE WHEN @PST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_VAT]= CASE WHEN @GSTorHST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_TELEPHONE]= ''
		  ,[PAY_DEDUACTABLE]= ''
		  ,[PAY_HIGH_WAY_TICKET]= ''
		  ,[PAY_HIGHWAYADMIN]= ''
		  ,[CREATED_FROM]= ''
		  ,[AGREEMENT_NO]= @AgreementNo
		  ,[DEBITOR_CODE]= @debitor_code
		  ,[SEPARATE_DAMAGE_INVOICE]= ''
		  ,[SEPARATE_TRAFFIC_INVOICE] = ''
		  ,[PREBILLING_IN_ADVANCE]= ''
		  ,[BILLTO_END_OF_MONTH]= ''
		  ,[PREBILLING_INVOICE_METHOD]= ''
		  ,[REQUIRE_VOUCHER_CONFIRMATION]= ''
		  ,[COMBINATION_PREBILLING]= ''
		  ,[FULLY_AUTHORIZE]= ''
		  ,[COMBINATION_INVOICE]= ''
		  ,[COMB_DAMGE_INVOICE]= ''
		  ,[COMB_TRAFFIC_INVOICE]= ''
		  ,[COMB_HIGHWAY_INVOICE]= ''
		  ,[PREBILLING_CHARGE_KM]= ''
		  ,[RENTAL_BEFORE_DISCOUNT]=  @MDA_Authrate * @TotalAuthDays
		  ,[RENTAL_EXT_BEFORE_DISCOUNT]= ''
		  ,[KM_PRICE_BEFORE_DISCOUNT]= ''
		  ,[RENTAL_VAT_AMOUNT]= @Old_VAT+ @dTotalTaxes
		  ,[RENTAL_EXT_VAT_AMOUNT]= ''
		  ,[INS_SUM_BEFORE_DISCOUNT]= @Insurances_Price+@dTotalInsurances
		  ,[INS_SUM_BEFORE_DIS_WITHOUTVAT]= ''
		  ,[KM_VAT_AMOUNT]= ''
		  ,[CUST_TRAFFIC_ADMIN_FEE]= ''
		  ,[AIRPORT_VAT_AMOUNT]= ''
		  ,[DROPOFF_VAT_AMOUNT]= ''
		  ,[FUEL_VAT_AMOUNT]= ''
		  ,[DELIVERY_VAT_AMOUNT]= ''
		  ,[PICKKUP_VAT_AMOUNT]= ''
		  ,[OTHERSUM_VAT_AMOUNT]= ''
		  ,[REDUCTION_VAT_AMOUNT]= ''
		  ,[DAMAGES_VAT_AMOUNT]= ''
		  ,[DEDUCTIBLE_VAT_AMOUNT]= ''
		  ,[TRAFFIC_VAT_AMOUNT]= ''
		  ,[INS_VAT_AMOUNT]= ((@Insurances_Price+@dTotalInsurances) * @GSTorHST) / 100
		  ,[EXTRAS_VAT_AMOUNT]= ((@Extras_Price+@dTotalExtras) * @GSTorHST) / 100
		  ,[DISCOUNT_VAT_AMOUNT]= ''
		  ,[RENTAL_SERVICE_AMOUNT]= @Old_SERVICE_FEE + 0.00
		  ,[RENTALEXT_SERVICE_AMOUNT]= ''
		  ,[KM_SERVICE_AMOUNT]= ''
		  ,[AIRPORT_SERVICE_AMOUNT]= ''
		  ,[DROPOFF_SERVICE_AMOUNT]= ''
		  ,[FUEL_SERVICE_AMOUNT]= ''
		  ,[DELIVERY_SERVICE_AMOUNT]= ''
		  ,[PICKUP_SERVICE_AMOUNT]= ''
		  ,[OTHERSUM_SERVICE_AMOUNT]= ''
		  ,[REDUCTION_SERVICE_AMOUNT]= ''
		  ,[DAMAGES_SERVICE_AMOUNT]= ''
		  ,[DEDCTIBLE_SERVICE_AMOUNT]= ''
		  ,[TRAFFIC_SERVICE_AMOUNT] = 0
		  ,[INS_SERVICE_AMOUNT] = 0
		  ,[EXTRAS_SERVICE_AMOUNT] = 0
		  ,[DISCOUNT_SERVICE_AMOUNT] = 0
		  ,[PACKAGE_PRICE] = 0
		  ,[PACKAGE_EXT_PRICE] = 0
		  ,[KM_PRICE] = 0
		  ,[RENTAL_DISCOUNT_AMOUNT] = 0
		  ,[RENTAL_EXT_DISCOUNT_SUM] = 0
		  ,[KM_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISC_AMOUNT_WT_OUT_VAT] = 0
		  ,[TOTAL_DISCOUNT_AMOUNT] = 0
		  ,[NON_TAXBLE_AMOUNT] = 0
		  ,[NON_SERVICABLE_AMOUNT] = 0
		  ,[PACKAGE_DAYS] = 0
		  ,[PACKAGE_ADD_DAYS] = 0
		  ,[EXTENSION_DAYS] = 0
		  ,[TRAFFIC_ADMIN_FEE_VAT_AMT] = 0
		  ,[TRAFFIC_ADMIN_FEE_SERVICE_AMT] = 0
		  ,[TRAFFIC_AMT_WO_ADMIN_FEE] = 0
		  ,[BILLING_FREQUENCY] = 0
		  ,[SEPARATE_REPLACEMENT_INV] = 'N'
		  ,[SEPARATE_FUEL_INV] = 'N'
		  ,[COMB_FUEL_INVOICE] = 'N'
		  ,[INVOICE_BY] = 'A'
		  ,[PAY_TOLL] =  'N'
		  ,[SEPARATE_TOLL_INVOICE] = 'N'
		  ,[TOLL_WO_ADMIN_FEE] = 0
		  ,[TOLL_ADMIN_FEE] = 0
		  ,[TOLL_VAT_AMT] = 0
		  ,[TOLL_SERVICE_AMT] = 0
		  ,[TOLL_ADMIN_FEEPER_SETUP] = 0
		  ,[TOLL_ADMIN_FEEAMT_SETUP] = 0
		  ,[DAMAGE_WO_ADMIN_FEE] = 0
		  ,[DAMAGE_ADMIN_FEE] = 0
		  ,[DED_WO_ADMIN_FEE] = 0
		  ,[DED_ADMIN_FEE] = 0
		  ,[PAY_ENTIRE_BILL]  = 'N'
		  ,[PAY_ALL_TAXES] = 'Y'
		  ,[PAY_RATE_PER_DAY] = 'N'
		  ,[PAY_SURCHARGE] = 'N'
		  ,[PAY_GST_HST] = 'Y'
		  ,[MONTHLY_DAYS] = 0
		end
		else
		begin
		   update  ontarioLIVE..DEBITOR_PAY_FLAGS set 
		   [AUTHRIZATION_NO] = @MultipleDebitorAuthNo
		  ,[PAY_RENTAL] = 'Y'
		  ,[PAY_EXTENSION]= ''
		  ,[PAY_UPSELL]= ''
		  ,[PAY_KM]= 'N'
		  ,[PAY_FUEL]= 'N'
		  ,[PAY_DAMAGE]= 'N'
		  ,[PAY_TRAFFIC]= 'N'
		  ,[PAY_AIRPORTFEE]= 'N'
		  ,[PAY_DROPOFFFEE]= 'N'
		  ,[PAY_DELIVERY]= 'N'
		  ,[PAY_PICKUP]= 'N'
		  ,[PAY_INS]= CASE WHEN @CDW > 0 THEN 'Y' ELSE 'N' END
		  ,[PAY_EXT]= 'Y'
		  ,[PAY_OTHER]= 'N'
		  ,[GET_RED]= 'Y'
		  ,[PAY_SERVICE]= CASE WHEN @PST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_VAT]= CASE WHEN @GSTorHST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_TELEPHONE]= ''
		  ,[PAY_DEDUACTABLE]= ''
		  ,[PAY_HIGH_WAY_TICKET]= ''
		  ,[PAY_HIGHWAYADMIN]= ''
		  ,[CREATED_FROM]= ''
		  ,[AGREEMENT_NO]= @AgreementNo
		  ,[DEBITOR_CODE]= @debitor_code
		  ,[SEPARATE_DAMAGE_INVOICE]= ''
		  ,[SEPARATE_TRAFFIC_INVOICE] = ''
		  ,[PREBILLING_IN_ADVANCE]= ''
		  ,[BILLTO_END_OF_MONTH]= ''
		  ,[PREBILLING_INVOICE_METHOD]= ''
		  ,[REQUIRE_VOUCHER_CONFIRMATION]= ''
		  ,[COMBINATION_PREBILLING]= ''
		  ,[FULLY_AUTHORIZE]= ''
		  ,[COMBINATION_INVOICE]= ''
		  ,[COMB_DAMGE_INVOICE]= ''
		  ,[COMB_TRAFFIC_INVOICE]= ''
		  ,[COMB_HIGHWAY_INVOICE]= ''
		  ,[PREBILLING_CHARGE_KM]= ''
		  ,[RENTAL_BEFORE_DISCOUNT]=  @MDA_Authrate * @TotalAuthDays
		  ,[RENTAL_EXT_BEFORE_DISCOUNT]= ''
		  ,[KM_PRICE_BEFORE_DISCOUNT]= ''
		  ,[RENTAL_VAT_AMOUNT]= @Old_VAT+ @dTotalTaxes
		  ,[RENTAL_EXT_VAT_AMOUNT]= ''
		  ,[INS_SUM_BEFORE_DISCOUNT]= @Insurances_Price+@dTotalInsurances
		  ,[INS_SUM_BEFORE_DIS_WITHOUTVAT]= ''
		  ,[KM_VAT_AMOUNT]= ''
		  ,[CUST_TRAFFIC_ADMIN_FEE]= ''
		  ,[AIRPORT_VAT_AMOUNT]= ''
		  ,[DROPOFF_VAT_AMOUNT]= ''
		  ,[FUEL_VAT_AMOUNT]= ''
		  ,[DELIVERY_VAT_AMOUNT]= ''
		  ,[PICKKUP_VAT_AMOUNT]= ''
		  ,[OTHERSUM_VAT_AMOUNT]= ''
		  ,[REDUCTION_VAT_AMOUNT]= ''
		  ,[DAMAGES_VAT_AMOUNT]= ''
		  ,[DEDUCTIBLE_VAT_AMOUNT]= ''
		  ,[TRAFFIC_VAT_AMOUNT]= ''
		  ,[INS_VAT_AMOUNT]= ((@Insurances_Price+@dTotalInsurances) * @GSTorHST) / 100
		  ,[EXTRAS_VAT_AMOUNT]= ((@Extras_Price+@dTotalExtras) * @GSTorHST) / 100
		  ,[DISCOUNT_VAT_AMOUNT]= ''
		  ,[RENTAL_SERVICE_AMOUNT]= @Old_SERVICE_FEE + 0.00
		  ,[RENTALEXT_SERVICE_AMOUNT]= ''
		  ,[KM_SERVICE_AMOUNT]= ''
		  ,[AIRPORT_SERVICE_AMOUNT]= ''
		  ,[DROPOFF_SERVICE_AMOUNT]= ''
		  ,[FUEL_SERVICE_AMOUNT]= ''
		  ,[DELIVERY_SERVICE_AMOUNT]= ''
		  ,[PICKUP_SERVICE_AMOUNT]= ''
		  ,[OTHERSUM_SERVICE_AMOUNT]= ''
		  ,[REDUCTION_SERVICE_AMOUNT]= ''
		  ,[DAMAGES_SERVICE_AMOUNT]= ''
		  ,[DEDCTIBLE_SERVICE_AMOUNT]= ''
		  ,[TRAFFIC_SERVICE_AMOUNT] = 0
		  ,[INS_SERVICE_AMOUNT] = 0
		  ,[EXTRAS_SERVICE_AMOUNT] = 0
		  ,[DISCOUNT_SERVICE_AMOUNT] = 0
		  ,[PACKAGE_PRICE] = 0
		  ,[PACKAGE_EXT_PRICE] = 0
		  ,[KM_PRICE] = 0
		  ,[RENTAL_DISCOUNT_AMOUNT] = 0
		  ,[RENTAL_EXT_DISCOUNT_SUM] = 0
		  ,[KM_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISC_AMOUNT_WT_OUT_VAT] = 0
		  ,[TOTAL_DISCOUNT_AMOUNT] = 0
		  ,[NON_TAXBLE_AMOUNT] = 0
		  ,[NON_SERVICABLE_AMOUNT] = 0
		  ,[PACKAGE_DAYS] = 0
		  ,[PACKAGE_ADD_DAYS] = 0
		  ,[EXTENSION_DAYS] = 0
		  ,[TRAFFIC_ADMIN_FEE_VAT_AMT] = 0
		  ,[TRAFFIC_ADMIN_FEE_SERVICE_AMT] = 0
		  ,[TRAFFIC_AMT_WO_ADMIN_FEE] = 0
		  ,[BILLING_FREQUENCY] = 0
		  ,[SEPARATE_REPLACEMENT_INV] = 'N'
		  ,[SEPARATE_FUEL_INV] = 'N'
		  ,[COMB_FUEL_INVOICE] = 'N'
		  ,[INVOICE_BY] = 'A'
		  ,[PAY_TOLL] =  'N'
		  ,[SEPARATE_TOLL_INVOICE] = 'N'
		  ,[TOLL_WO_ADMIN_FEE] = 0
		  ,[TOLL_ADMIN_FEE] = 0
		  ,[TOLL_VAT_AMT] = 0
		  ,[TOLL_SERVICE_AMT] = 0
		  ,[TOLL_ADMIN_FEEPER_SETUP] = 0
		  ,[TOLL_ADMIN_FEEAMT_SETUP] = 0
		  ,[DAMAGE_WO_ADMIN_FEE] = 0
		  ,[DAMAGE_ADMIN_FEE] = 0
		  ,[DED_WO_ADMIN_FEE] = 0
		  ,[DED_ADMIN_FEE] = 0
		  ,[PAY_ENTIRE_BILL]  = 'N'
		  ,[PAY_ALL_TAXES] = 'Y'
		  ,[PAY_RATE_PER_DAY] = 'N'
		  ,[PAY_SURCHARGE] = 'N'
		  ,[PAY_GST_HST] = 'Y'
		  ,[MONTHLY_DAYS] = 0
		  where [AUTHRIZATION_NO] = @MultipleDebitorAuthNo AND AGREEMENT_NO=@AGREEMENTNO AND DEBITOR_CODE=@debitor_code
		end	
			END--end to create MDA	
		END
						
		END	--(@agreementno > 0  and @Agreement_Status_Code  in (0,1,2,3)) or (@ReservationNo != '' and @agreementno=0)
		
		if not exists 
		(select AUTHORIZATION_NO from ONTARIOLIVE..AUTHORIZATION_AGR_RES (nolock) where AUTHORIZATION_NO=@MultipleDebitorAuthNo AND FROM_DATE=@AuthFromDate AND FROM_TIME = @AuthFromTime)		
		begin
		INSERT INTO ONTARIOLIVE..AUTHORIZATION_AGR_RES(AUTHORIZATION_NO,FROM_DATE,FROM_TIME,AUTH_SERIAL,AGREEMENT_NO,CAR_GROUP,RATE_PER_DAY,AUTH_DAYS,RATE_SR_NO,RATE_DET_SR_NO,TO_DATE,TO_TIME)
		VALUES
		(@MultipleDebitorAuthNo,@AuthFromDate,@AuthFromTime, 
		isnull((SELECT (MAX(AUTH_SERIAL)) FROM ONTARIOLIVE..AUTHORIZATION_AGR_RES (NOLOCK) where AUTHORIZATION_NO=@MultipleDebitorAuthNo), 0)+1, @AgreementNo, @Authorized_VehicleCategory, 
		@Authorizedrate,@DaysAuthorized,@RATE_SR_NO,@RATE_DET_SR_NO,@AuthToDate, @AuthToTime)		
		END
			
		if @VLI_Rate > 0  and @AuthFromDate != '00000000'
		begin
			if not exists --VIREN INSISTEN ON FRIDAY NOV 29,2013 TO PUT 2 INSERTS STATEMENT ONE WITH 0 AND WITH AGREEMENTNO
			(select EXTRAS_CODE from ONTARIOLIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='VLI' and RESAUTHVOUCHER=@MultipleDebitorAuthNo and MASTER_AGREEMENT=0)		
			begin
				INSERT INTO ontarioLIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES
				(@MultipleDebitorAuthNo,'00000000','VLI', 0,0,'', @VLI_Rate, @VLI_Rate*@DaysAuthorized)
			end
				
			if not exists --VIREN INSISTEN ON FRIDAY NOV 29,2013 TO PUT 2 INSERTS STATEMENT ONE WITH 0 AND WITH AGREEMENTNO
			(select EXTRAS_CODE from ONTARIOLIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='VLI' and RESAUTHVOUCHER='' and MASTER_AGREEMENT=@AgreementNo)		
			begin	
				INSERT INTO ontarioLIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES
				('','00000000','VLI', @AgreementNo,1,'', @VLI_Rate, @VLI_Rate*@DaysAuthorized)
			end
		end
			
		if @UF > 0  and @AuthFromDate != '00000000'
		begin
			if not exists 
			(select EXTRAS_CODE from ONTARIOLIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='UF' and RESAUTHVOUCHER=@MultipleDebitorAuthNo and MASTER_AGREEMENT=0)		
			begin			
				INSERT INTO ontarioLIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES(@MultipleDebitorAuthNo,'00000000' ,'UF', 0, 0, '' ,@UF, @UF*@DaysAuthorized)
			end
			
			if not exists --VIREN INSISTEN ON FRIDAY NOV 29,2013 TO PUT 2 INSERTS STATEMENT ONE WITH 0 AND WITH AGREEMENTNO
			(select EXTRAS_CODE from ONTARIOLIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='UF' and RESAUTHVOUCHER='' and MASTER_AGREEMENT=@AgreementNo)		
			begin					
				INSERT INTO ontarioLIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES('','00000000' ,'UF', @AgreementNo,1,'',@UF, @UF*@DaysAuthorized)
			end	
		end			

		if @WT > 0 and @AuthFromDate != '00000000'
		begin
			if not exists 
			(select EXTRAS_CODE from ONTARIOLIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='WT' and RESAUTHVOUCHER=@MultipleDebitorAuthNo)		
			begin
				INSERT INTO ontarioLIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES(@MultipleDebitorAuthNo,'00000000','WT', 0,0,'',@WT, @WT*@DaysAuthorized)	
			end		
			
			if not exists --VIREN INSISTEN ON FRIDAY NOV 29,2013 TO PUT 2 INSERTS STATEMENT ONE WITH 0 AND WITH AGREEMENTNO
			(select EXTRAS_CODE from ONTARIOLIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='WT' and RESAUTHVOUCHER='' and MASTER_AGREEMENT=@AgreementNo)		
			begin		
				INSERT INTO ontarioLIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES('','00000000','WT', @AgreementNo,1,'',@WT, @WT*@DaysAuthorized)							
			end
		end			

		if @CDW > 0 and @AuthFromDate != '00000000'
		begin
			if not exists 
			(select INSURANCE_CODE from ONTARIOLIVE..AGREEMENT_INSURANCES (nolock) where MASTER_AGREEMENT=0 and INSURANCE_CODE='CDW' and RESAUTHVOUCHER=@MultipleDebitorAuthNo)		
			begin
				INSERT INTO ontarioLIVE..AGREEMENT_INSURANCES(RESAUTHVOUCHER,INSURANCE_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,PRICE_PER_DAY, F_SUM)
				VALUES(@MultipleDebitorAuthNo,'CDW', @AgreementNo,0,'', @CDW, @CDW*@DaysAuthorized)	
			end
			
			if not exists 
			(select INSURANCE_CODE from ONTARIOLIVE..AGREEMENT_INSURANCES (nolock) where MASTER_AGREEMENT=@AgreementNo and INSURANCE_CODE='CDW' and RESAUTHVOUCHER='' and SUV_AGREEMENT=1)					
			begin	
				INSERT INTO ontarioLIVE..AGREEMENT_INSURANCES(RESAUTHVOUCHER,INSURANCE_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,PRICE_PER_DAY, F_SUM)
				VALUES('','CDW', @AgreementNo,1,'', @CDW, @CDW*@DaysAuthorized)				
			end
		end				
	end --db
		
		
		
	if @DB = 'ALBERTALIVE'
		BEGIN	
		if (@agreementno > 0  and @Agreement_Status_Code  in (0,1,2,3)) or (@ReservationNo != '' and @agreementno=0)
		begin		  
			select @MultipleDebitorAuthNo = AUTHORIZATION_NO,
			@RentalPrice = rental_price, @Insurances_Price = insurances_price , @Extras_Price = extras_price, @Insu_NonVat_Sum = Insu_NonVat_Sum,
			@KM_Sum = KM_Sum, @Airport_Fee = Airport_Fee, @DropOff_Fee = DropOff_Fee, @Fuel_Sum = Fuel_Sum, @Tel_Sum = Tel_Sum,
			@Delivery_Sum = Delivery_Sum, @Pickup_Sum = Pickup_Sum, @Other_Sum = Other_Sum, @Damages_Sum = Damages_Sum, 
			@Deductible_Sum = Deductible_Sum, @Traffic_Sum = Traffic_Sum, @Reduction_Sum = Reduction_Sum,
			@MDA_Max_Amt = MAX_AMOUNT , @Old_VAT = sales_tax,  @Old_SERVICE_FEE = service_tax , @MDA_TotalDays_Old = days, @Old_TotalAmount = amount 
			from ALBERTALIVE..MULTIPLE_DEBITOR_AUTH (nolock) 
			where ((AGREEMENT = @AgreementNo and @AgreementNo >0) or (RESERVATION_NO = @ReservationNo and @agreementno=0)) 
			and debitor_code = @Debitor_Code AND @DCA_Bill_To != 2	
			  
		    if @Debitor_Code = @Third_Party_Debitor_Code 
			  set @MDA_Max_Amt = @Third_Party_policyMax
		    else                      						
			  set @MDA_Max_Amt = @PolicyMax
		  
		    select @MDA_Authrate = sum(DCA_AUTHOR_RATE*dca_a_days)/sum(dca_a_days), @MDA_TotalDays = sum(dca_a_days)  from da_authorization (nolock) where dca_Claim_id=@RemedyEntryId	
		    	  
		    select @RecID = isnull(REC_ID, 0)+1  from AGREEMENT_LOG_FILE where MASTER_AGREEMENT = @AgreementNo

		    INSERT INTO ALBERTALIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
		    VALUES(@AgreementNo,'DIAL', @ModorCreateDate, @ModyorCreateTime,'Modify Auth From Claim','','','D',@RecID)		
		    INSERT INTO ALBERTALIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
		    VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Authorization Created: 0000000','',@ModorCreateDate,'D',@RecID+1)	
		    INSERT INTO ALBERTALIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
		    VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Charge Group','', @Authorized_VehicleCategory,'D',@RecID+2)		
		    INSERT INTO ALBERTALIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
		    VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Per Day Price','',@Authorizedrate,'D',@RecID+3)		
		    INSERT INTO ALBERTALIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
		    VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Rate Sr No.','',@RATE_SR_NO,'D',@RecID+4)		
			INSERT INTO ALBERTALIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
			VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Rate Det Sr No.','',@RATE_DET_SR_NO,'D',@RecID+5)		
			INSERT INTO ALBERTALIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
			VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Sold Days','',@RATE_SR_NO,'D',@RecID+6)				
			INSERT INTO ALBERTALIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
			VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Days',@MDA_TotalDays_Old, @MDA_TotalDays, 'D', @RecID+7)		
			INSERT INTO ALBERTALIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
			VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Total Amount','',@RATE_DET_SR_NO,'D',@RecID+8)		
		
		--D - DATA	--T - TRANSACTION
		  
		if @MultipleDebitorAuthNo != '' --update
		BEGIN
				IF @ReservationNo != '' AND @AgreementNo = 0	-- reservation stage			
				begin
					UPDATE ALBERTALIVE..MULTIPLE_DEBITOR_AUTH SET					
					RESERVATION_NO = @ReservationNo,
					DEBITOR_CODE = @Debitor_Code,
					AUTHORIZATION_NO = @MultipleDebitorAuthNo,
					DAYS = @MDA_TotalDays,							
					AGENTCOMMEXTERNV = 'O',
					F_GROUP = @Authorized_VehicleCategory,
					RENTAL_PACKAGE = @Rental_Package,
					Sold_Days = @MDA_TotalDays,
					LOSS_DATE = '00000000',
					CURRENCY = 'CAD',
					PER_DAY_PRICE = @MDA_Authrate,
					RATE_NO = isnull(@RateNo, 0), 
					RATE_SR_NO = @RATE_SR_NO,
					RATE_DET_SR_NO = @RATE_DET_SR_NO,
					VAT_PERCENT = @GSTorHST,
					SERVICE_FEE_PERCENT = @PST,
					RENTAL_PRICE = (@MDA_Authrate) * @MDA_TotalDays, --0.00,
					INSURANCES_PRICE = @Insurances_Price+@dTotalInsurances , --0.00,
					EXTRAS_PRICE = @Extras_Price+@dTotalExtras,
					AMOUNT = @Old_TotalAmount + @dFinalTotal,
					TAXABLE_SUM = (@MDA_Authrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @MDA_TotalDays ,
					SERVICABLE_SUM = 0.00,
					SALES_TAX = @Old_VAT+ @dTotalTaxes,
					SERVICE_TAX = @Old_SERVICE_FEE + 0.00,
					EXCHANGE_RATE = 1,
					SUBTOTAL = (@MDA_Authrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @MDA_TotalDays,
					MAX_AMOUNT = @MDA_Max_Amt,
					MAX_AMOUNT_CREDIT = @Tel_Sum,
					claim_no = @RemedyEntryID	
					WHERE RESERVATION_NO = @ReservationNo and AUTHORIZATION_NO = @MultipleDebitorAuthNo and DEBITOR_CODE = @Debitor_Code
				end
				
				IF @AgreementNo > 0				
				begin
					UPDATE ALBERTALIVE..MULTIPLE_DEBITOR_AUTH SET 
					agreement = @AgreementNo,					
					RESERVATION_NO = @ReservationNo,
					DEBITOR_CODE = @Debitor_Code,
					AUTHORIZATION_NO = @MultipleDebitorAuthNo,
					DAYS = @MDA_TotalDays,							
					AGENTCOMMEXTERNV = 'O',
					F_GROUP = @Authorized_VehicleCategory,
					RENTAL_PACKAGE = @Rental_Package,
					Sold_Days = @MDA_TotalDays,
					LOSS_DATE = '00000000',
					CURRENCY = 'CAD',
					PER_DAY_PRICE = @MDA_Authrate,
					RATE_NO = isnull(@RateNo, 0), 
					RATE_SR_NO = @RATE_SR_NO,
					RATE_DET_SR_NO = @RATE_DET_SR_NO,
					VAT_PERCENT = @GSTorHST,
					SERVICE_FEE_PERCENT = @PST,
					RENTAL_PRICE = (@MDA_Authrate)  * @MDA_TotalDays, --0.00,
					INSURANCES_PRICE = @Insurances_Price+@dTotalInsurances , --0.00,
					EXTRAS_PRICE = @Extras_Price+@dTotalExtras,
					AMOUNT = @Old_TotalAmount + @dFinalTotal,
					TAXABLE_SUM = (@MDA_Authrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @MDA_TotalDays ,
					SERVICABLE_SUM = 0.00,
					SALES_TAX = @Old_VAT+ @dTotalTaxes,
					SERVICE_TAX = @Old_SERVICE_FEE + 0.00,
					EXCHANGE_RATE = 1,
					SUBTOTAL = (@MDA_Authrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @MDA_TotalDays,
					MAX_AMOUNT = @MDA_Max_Amt,
					MAX_AMOUNT_CREDIT = @Tel_Sum,
					claim_no = @RemedyEntryID	
					WHERE AGREEMENT = @AgreementNo and AUTHORIZATION_NO = @MultipleDebitorAuthNo and DEBITOR_CODE = @Debitor_Code
				end		
				
				
			if not exists
			(select 1 from ALBERTALIVE..DEBITOR_PAY_FLAGS (nolock) where AUTHRIZATION_NO = @MultipleDebitorAuthNo --AND AGREEMENT_NO= @AgreementNo AND DEBITOR_CODE= @debitor_code
			)							
			begin
			insert into ALBERTALIVE..DEBITOR_PAY_FLAGS (
			[AUTHRIZATION_NO]
			,[PAY_RENTAL]
			,[PAY_EXTENSION]
			,[PAY_UPSELL]
			,[PAY_KM]
			,[PAY_FUEL]		
			,[PAY_DAMAGE]
			,[PAY_TRAFFIC]
			,[PAY_AIRPORTFEE]
			,[PAY_DROPOFFFEE]
			,[PAY_DELIVERY]
			,[PAY_PICKUP]
			,[PAY_INS]
			,[PAY_EXT]
			,[PAY_OTHER]
			,[GET_RED]
			,[PAY_SERVICE]
			,[PAY_VAT]
			,[PAY_TELEPHONE]
			,[PAY_DEDUACTABLE]
			,[PAY_HIGH_WAY_TICKET]
			,[PAY_HIGHWAYADMIN]
			,[CREATED_FROM]
			,[AGREEMENT_NO]
			,[DEBITOR_CODE]
			,[SEPARATE_DAMAGE_INVOICE]
			,[SEPARATE_TRAFFIC_INVOICE]
			,[PREBILLING_IN_ADVANCE]
			,[BILLTO_END_OF_MONTH]
			,[PREBILLING_INVOICE_METHOD]
			,[REQUIRE_VOUCHER_CONFIRMATION]
			,[COMBINATION_PREBILLING]
			,[FULLY_AUTHORIZE]
			,[COMBINATION_INVOICE]
			,[COMB_DAMGE_INVOICE]
			,[COMB_TRAFFIC_INVOICE]
			,[COMB_HIGHWAY_INVOICE]
			,[PREBILLING_CHARGE_KM]
			,[RENTAL_BEFORE_DISCOUNT]
			,[RENTAL_EXT_BEFORE_DISCOUNT]
			,[KM_PRICE_BEFORE_DISCOUNT]
			,[RENTAL_VAT_AMOUNT]
			,[RENTAL_EXT_VAT_AMOUNT]
			,[INS_SUM_BEFORE_DISCOUNT]
			,[INS_SUM_BEFORE_DIS_WITHOUTVAT]
			,[KM_VAT_AMOUNT]
			,[CUST_TRAFFIC_ADMIN_FEE]
			,[AIRPORT_VAT_AMOUNT]
			,[DROPOFF_VAT_AMOUNT]
			,[FUEL_VAT_AMOUNT]
			,[DELIVERY_VAT_AMOUNT]
			,[PICKKUP_VAT_AMOUNT]
			,[OTHERSUM_VAT_AMOUNT]
			,[REDUCTION_VAT_AMOUNT]
			,[DAMAGES_VAT_AMOUNT]
			,[DEDUCTIBLE_VAT_AMOUNT]
			,[TRAFFIC_VAT_AMOUNT]
			,[INS_VAT_AMOUNT]
			,[EXTRAS_VAT_AMOUNT]
			,[DISCOUNT_VAT_AMOUNT]
			,[RENTAL_SERVICE_AMOUNT]
			,[RENTALEXT_SERVICE_AMOUNT]
			,[KM_SERVICE_AMOUNT]
			,[AIRPORT_SERVICE_AMOUNT]
			,[DROPOFF_SERVICE_AMOUNT]
			,[FUEL_SERVICE_AMOUNT]
			,[DELIVERY_SERVICE_AMOUNT]
			,[PICKUP_SERVICE_AMOUNT]
			,[OTHERSUM_SERVICE_AMOUNT]
			,[REDUCTION_SERVICE_AMOUNT]
			,[DAMAGES_SERVICE_AMOUNT]
			,[DEDCTIBLE_SERVICE_AMOUNT]
			,[TRAFFIC_SERVICE_AMOUNT]
			,[INS_SERVICE_AMOUNT]
			,[EXTRAS_SERVICE_AMOUNT]
			,[DISCOUNT_SERVICE_AMOUNT]
			,[PACKAGE_PRICE]
			,[PACKAGE_EXT_PRICE]
			,[KM_PRICE]
			,[RENTAL_DISCOUNT_AMOUNT]
			,[RENTAL_EXT_DISCOUNT_SUM]
			,[KM_DISCOUNT_AMOUNT]
			,[INS_DISCOUNT_AMOUNT]
			,[INS_DISC_AMOUNT_WT_OUT_VAT]
			,[TOTAL_DISCOUNT_AMOUNT]
			,[NON_TAXBLE_AMOUNT]
			,[NON_SERVICABLE_AMOUNT]
			,[PACKAGE_DAYS]
			,[PACKAGE_ADD_DAYS]
			,[EXTENSION_DAYS]
			,[TRAFFIC_ADMIN_FEE_VAT_AMT]
			,[TRAFFIC_ADMIN_FEE_SERVICE_AMT]
			,[TRAFFIC_AMT_WO_ADMIN_FEE]
			,[BILLING_FREQUENCY]
			,[SEPARATE_REPLACEMENT_INV]
			,[SEPARATE_FUEL_INV]
			,[COMB_FUEL_INVOICE]
			,[INVOICE_BY]
			,[PAY_TOLL]
			,[SEPARATE_TOLL_INVOICE]
			,[TOLL_WO_ADMIN_FEE]
			,[TOLL_ADMIN_FEE]
			,[TOLL_VAT_AMT]
			,[TOLL_SERVICE_AMT]
			,[TOLL_ADMIN_FEEPER_SETUP]
			,[TOLL_ADMIN_FEEAMT_SETUP]
			,[DAMAGE_WO_ADMIN_FEE]
			,[DAMAGE_ADMIN_FEE]
			,[DED_WO_ADMIN_FEE]
			,[DED_ADMIN_FEE]
			,[PAY_ENTIRE_BILL]
			,[PAY_ALL_TAXES]
			,[PAY_RATE_PER_DAY]
			,[PAY_SURCHARGE]
			,[PAY_GST_HST]
			,[MONTHLY_DAYS]
			)

		   select 
		   [AUTHRIZATION_NO] = @MultipleDebitorAuthNo
		  ,[PAY_RENTAL] = 'Y'
		  ,[PAY_EXTENSION]= ''
		  ,[PAY_UPSELL]= ''
		  ,[PAY_KM]= 'N'
		  ,[PAY_FUEL]= 'N'
		  ,[PAY_DAMAGE]= 'N'
		  ,[PAY_TRAFFIC]= 'N'
		  ,[PAY_AIRPORTFEE]= 'N'
		  ,[PAY_DROPOFFFEE]= 'N'
		  ,[PAY_DELIVERY]= 'N'
		  ,[PAY_PICKUP]= 'N'
		  ,[PAY_INS]= CASE WHEN @CDW > 0 THEN 'Y' ELSE 'N' END
		  ,[PAY_EXT]= 'Y'
		  ,[PAY_OTHER]= 'N'
		  ,[GET_RED]= 'Y'
		  ,[PAY_SERVICE]= CASE WHEN @PST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_VAT]= CASE WHEN @GSTorHST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_TELEPHONE]= ''
		  ,[PAY_DEDUACTABLE]= ''
		  ,[PAY_HIGH_WAY_TICKET]= ''
		  ,[PAY_HIGHWAYADMIN]= ''
		  ,[CREATED_FROM]= ''
		  ,[AGREEMENT_NO]= @AgreementNo
		  ,[DEBITOR_CODE]= @debitor_code
		  ,[SEPARATE_DAMAGE_INVOICE]= ''
		  ,[SEPARATE_TRAFFIC_INVOICE] = ''
		  ,[PREBILLING_IN_ADVANCE]= ''
		  ,[BILLTO_END_OF_MONTH]= ''
		  ,[PREBILLING_INVOICE_METHOD]= ''
		  ,[REQUIRE_VOUCHER_CONFIRMATION]= ''
		  ,[COMBINATION_PREBILLING]= ''
		  ,[FULLY_AUTHORIZE]= ''
		  ,[COMBINATION_INVOICE]= ''
		  ,[COMB_DAMGE_INVOICE]= ''
		  ,[COMB_TRAFFIC_INVOICE]= ''
		  ,[COMB_HIGHWAY_INVOICE]= ''
		  ,[PREBILLING_CHARGE_KM]= ''
		  ,[RENTAL_BEFORE_DISCOUNT]=  @MDA_Authrate * @TotalAuthDays
		  ,[RENTAL_EXT_BEFORE_DISCOUNT]= ''
		  ,[KM_PRICE_BEFORE_DISCOUNT]= ''
		  ,[RENTAL_VAT_AMOUNT]= @Old_VAT+ @dTotalTaxes
		  ,[RENTAL_EXT_VAT_AMOUNT]= ''
		  ,[INS_SUM_BEFORE_DISCOUNT]= @Insurances_Price+@dTotalInsurances
		  ,[INS_SUM_BEFORE_DIS_WITHOUTVAT]= ''
		  ,[KM_VAT_AMOUNT]= ''
		  ,[CUST_TRAFFIC_ADMIN_FEE]= ''
		  ,[AIRPORT_VAT_AMOUNT]= ''
		  ,[DROPOFF_VAT_AMOUNT]= ''
		  ,[FUEL_VAT_AMOUNT]= ''
		  ,[DELIVERY_VAT_AMOUNT]= ''
		  ,[PICKKUP_VAT_AMOUNT]= ''
		  ,[OTHERSUM_VAT_AMOUNT]= ''
		  ,[REDUCTION_VAT_AMOUNT]= ''
		  ,[DAMAGES_VAT_AMOUNT]= ''
		  ,[DEDUCTIBLE_VAT_AMOUNT]= ''
		  ,[TRAFFIC_VAT_AMOUNT]= ''
		  ,[INS_VAT_AMOUNT]= ((@Insurances_Price+@dTotalInsurances) * @GSTorHST) / 100
		  ,[EXTRAS_VAT_AMOUNT]= ((@Extras_Price+@dTotalExtras) * @GSTorHST) / 100
		  ,[DISCOUNT_VAT_AMOUNT]= ''
		  ,[RENTAL_SERVICE_AMOUNT]= @Old_SERVICE_FEE + 0.00
		  ,[RENTALEXT_SERVICE_AMOUNT]= ''
		  ,[KM_SERVICE_AMOUNT]= ''
		  ,[AIRPORT_SERVICE_AMOUNT]= ''
		  ,[DROPOFF_SERVICE_AMOUNT]= ''
		  ,[FUEL_SERVICE_AMOUNT]= ''
		  ,[DELIVERY_SERVICE_AMOUNT]= ''
		  ,[PICKUP_SERVICE_AMOUNT]= ''
		  ,[OTHERSUM_SERVICE_AMOUNT]= ''
		  ,[REDUCTION_SERVICE_AMOUNT]= ''
		  ,[DAMAGES_SERVICE_AMOUNT]= ''
		  ,[DEDCTIBLE_SERVICE_AMOUNT]= ''
		  ,[TRAFFIC_SERVICE_AMOUNT] = 0
		  ,[INS_SERVICE_AMOUNT] = 0
		  ,[EXTRAS_SERVICE_AMOUNT] = 0
		  ,[DISCOUNT_SERVICE_AMOUNT] = 0
		  ,[PACKAGE_PRICE] = 0
		  ,[PACKAGE_EXT_PRICE] = 0
		  ,[KM_PRICE] = 0
		  ,[RENTAL_DISCOUNT_AMOUNT] = 0
		  ,[RENTAL_EXT_DISCOUNT_SUM] = 0
		  ,[KM_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISC_AMOUNT_WT_OUT_VAT] = 0
		  ,[TOTAL_DISCOUNT_AMOUNT] = 0
		  ,[NON_TAXBLE_AMOUNT] = 0
		  ,[NON_SERVICABLE_AMOUNT] = 0
		  ,[PACKAGE_DAYS] = 0
		  ,[PACKAGE_ADD_DAYS] = 0
		  ,[EXTENSION_DAYS] = 0
		  ,[TRAFFIC_ADMIN_FEE_VAT_AMT] = 0
		  ,[TRAFFIC_ADMIN_FEE_SERVICE_AMT] = 0
		  ,[TRAFFIC_AMT_WO_ADMIN_FEE] = 0
		  ,[BILLING_FREQUENCY] = 0
		  ,[SEPARATE_REPLACEMENT_INV] = 'N'
		  ,[SEPARATE_FUEL_INV] = 'N'
		  ,[COMB_FUEL_INVOICE] = 'N'
		  ,[INVOICE_BY] = 'A'
		  ,[PAY_TOLL] =  'N'
		  ,[SEPARATE_TOLL_INVOICE] = 'N'
		  ,[TOLL_WO_ADMIN_FEE] = 0
		  ,[TOLL_ADMIN_FEE] = 0
		  ,[TOLL_VAT_AMT] = 0
		  ,[TOLL_SERVICE_AMT] = 0
		  ,[TOLL_ADMIN_FEEPER_SETUP] = 0
		  ,[TOLL_ADMIN_FEEAMT_SETUP] = 0
		  ,[DAMAGE_WO_ADMIN_FEE] = 0
		  ,[DAMAGE_ADMIN_FEE] = 0
		  ,[DED_WO_ADMIN_FEE] = 0
		  ,[DED_ADMIN_FEE] = 0
		  ,[PAY_ENTIRE_BILL]  = 'N'
		  ,[PAY_ALL_TAXES] = 'Y'
		  ,[PAY_RATE_PER_DAY] = 'N'
		  ,[PAY_SURCHARGE] = 'N'
		  ,[PAY_GST_HST] = 'Y'
		  ,[MONTHLY_DAYS] = 0
		end
		
		ELSE
		BEGIN -- UPDATE MDA DEBITOR_FLAGS
		UPDATE ALBERTALIVE..DEBITOR_PAY_FLAGS SET 
		   --[AUTHRIZATION_NO] = @MultipleDebitorAuthNo
		  [PAY_RENTAL] = 'Y'
		  ,[PAY_EXTENSION]= ''
		  ,[PAY_UPSELL]= ''
		  ,[PAY_KM]= 'N'
		  ,[PAY_FUEL]= 'N'
		  ,[PAY_DAMAGE]= 'N'
		  ,[PAY_TRAFFIC]= 'N'
		  ,[PAY_AIRPORTFEE]= 'N'
		  ,[PAY_DROPOFFFEE]= 'N'
		  ,[PAY_DELIVERY]= 'N'
		  ,[PAY_PICKUP]= 'N'
		  ,[PAY_INS]= CASE WHEN @CDW > 0 THEN 'Y' ELSE 'N' END
		  ,[PAY_EXT]= 'Y'
		  ,[PAY_OTHER]= 'N'
		  ,[GET_RED]= 'Y'
		  ,[PAY_SERVICE]= CASE WHEN @PST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_VAT]= CASE WHEN @GSTorHST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_TELEPHONE]= ''
		  ,[PAY_DEDUACTABLE]= ''
		  ,[PAY_HIGH_WAY_TICKET]= ''
		  ,[PAY_HIGHWAYADMIN]= ''
		  ,[CREATED_FROM]= ''
		  ,[AGREEMENT_NO]= @AgreementNo
		  ,[DEBITOR_CODE]= @debitor_code
		  ,[SEPARATE_DAMAGE_INVOICE]= ''
		  ,[SEPARATE_TRAFFIC_INVOICE] = ''
		  ,[PREBILLING_IN_ADVANCE]= ''
		  ,[BILLTO_END_OF_MONTH]= ''
		  ,[PREBILLING_INVOICE_METHOD]= ''
		  ,[REQUIRE_VOUCHER_CONFIRMATION]= ''
		  ,[COMBINATION_PREBILLING]= ''
		  ,[FULLY_AUTHORIZE]= ''
		  ,[COMBINATION_INVOICE]= ''
		  ,[COMB_DAMGE_INVOICE]= ''
		  ,[COMB_TRAFFIC_INVOICE]= ''
		  ,[COMB_HIGHWAY_INVOICE]= ''
		  ,[PREBILLING_CHARGE_KM]= ''
		  ,[RENTAL_BEFORE_DISCOUNT]=  @MDA_Authrate * @TotalAuthDays
		  ,[RENTAL_EXT_BEFORE_DISCOUNT]= ''
		  ,[KM_PRICE_BEFORE_DISCOUNT]= ''
		  ,[RENTAL_VAT_AMOUNT]= @Old_VAT+ @dTotalTaxes
		  ,[RENTAL_EXT_VAT_AMOUNT]= ''
		  ,[INS_SUM_BEFORE_DISCOUNT]= @Insurances_Price+@dTotalInsurances
		  ,[INS_SUM_BEFORE_DIS_WITHOUTVAT]= ''
		  ,[KM_VAT_AMOUNT]= ''
		  ,[CUST_TRAFFIC_ADMIN_FEE]= ''
		  ,[AIRPORT_VAT_AMOUNT]= ''
		  ,[DROPOFF_VAT_AMOUNT]= ''
		  ,[FUEL_VAT_AMOUNT]= ''
		  ,[DELIVERY_VAT_AMOUNT]= ''
		  ,[PICKKUP_VAT_AMOUNT]= ''
		  ,[OTHERSUM_VAT_AMOUNT]= ''
		  ,[REDUCTION_VAT_AMOUNT]= ''
		  ,[DAMAGES_VAT_AMOUNT]= ''
		  ,[DEDUCTIBLE_VAT_AMOUNT]= ''
		  ,[TRAFFIC_VAT_AMOUNT]= ''
		  ,[INS_VAT_AMOUNT]= ((@Insurances_Price+@dTotalInsurances) * @GSTorHST) / 100
		  ,[EXTRAS_VAT_AMOUNT]= ((@Extras_Price+@dTotalExtras) * @GSTorHST) / 100
		  ,[DISCOUNT_VAT_AMOUNT]= ''
		  ,[RENTAL_SERVICE_AMOUNT]= @Old_SERVICE_FEE + 0.00
		  ,[RENTALEXT_SERVICE_AMOUNT]= ''
		  ,[KM_SERVICE_AMOUNT]= ''
		  ,[AIRPORT_SERVICE_AMOUNT]= ''
		  ,[DROPOFF_SERVICE_AMOUNT]= ''
		  ,[FUEL_SERVICE_AMOUNT]= ''
		  ,[DELIVERY_SERVICE_AMOUNT]= ''
		  ,[PICKUP_SERVICE_AMOUNT]= ''
		  ,[OTHERSUM_SERVICE_AMOUNT]= ''
		  ,[REDUCTION_SERVICE_AMOUNT]= ''
		  ,[DAMAGES_SERVICE_AMOUNT]= ''
		  ,[DEDCTIBLE_SERVICE_AMOUNT]= ''
		  ,[TRAFFIC_SERVICE_AMOUNT] = 0
		  ,[INS_SERVICE_AMOUNT] = 0
		  ,[EXTRAS_SERVICE_AMOUNT] = 0
		  ,[DISCOUNT_SERVICE_AMOUNT] = 0
		  ,[PACKAGE_PRICE] = 0
		  ,[PACKAGE_EXT_PRICE] = 0
		  ,[KM_PRICE] = 0
		  ,[RENTAL_DISCOUNT_AMOUNT] = 0
		  ,[RENTAL_EXT_DISCOUNT_SUM] = 0
		  ,[KM_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISC_AMOUNT_WT_OUT_VAT] = 0
		  ,[TOTAL_DISCOUNT_AMOUNT] = 0
		  ,[NON_TAXBLE_AMOUNT] = 0
		  ,[NON_SERVICABLE_AMOUNT] = 0
		  ,[PACKAGE_DAYS] = 0
		  ,[PACKAGE_ADD_DAYS] = 0
		  ,[EXTENSION_DAYS] = 0
		  ,[TRAFFIC_ADMIN_FEE_VAT_AMT] = 0
		  ,[TRAFFIC_ADMIN_FEE_SERVICE_AMT] = 0
		  ,[TRAFFIC_AMT_WO_ADMIN_FEE] = 0
		  ,[BILLING_FREQUENCY] = 0
		  ,[SEPARATE_REPLACEMENT_INV] = 'N'
		  ,[SEPARATE_FUEL_INV] = 'N'
		  ,[COMB_FUEL_INVOICE] = 'N'
		  ,[INVOICE_BY] = 'A'
		  ,[PAY_TOLL] =  'N'
		  ,[SEPARATE_TOLL_INVOICE] = 'N'
		  ,[TOLL_WO_ADMIN_FEE] = 0
		  ,[TOLL_ADMIN_FEE] = 0
		  ,[TOLL_VAT_AMT] = 0
		  ,[TOLL_SERVICE_AMT] = 0
		  ,[TOLL_ADMIN_FEEPER_SETUP] = 0
		  ,[TOLL_ADMIN_FEEAMT_SETUP] = 0
		  ,[DAMAGE_WO_ADMIN_FEE] = 0
		  ,[DAMAGE_ADMIN_FEE] = 0
		  ,[DED_WO_ADMIN_FEE] = 0
		  ,[DED_ADMIN_FEE] = 0
		  ,[PAY_ENTIRE_BILL]  = 'N'
		  ,[PAY_ALL_TAXES] = 'Y'
		  ,[PAY_RATE_PER_DAY] = 'N'
		  ,[PAY_SURCHARGE] = 'N'
		  ,[PAY_GST_HST] = 'Y'
		  ,[MONTHLY_DAYS] = 0
		  WHERE [AUTHRIZATION_NO] = @MultipleDebitorAuthNo AND DEBITOR_CODE=@debitor_code AND AGREEMENT_NO=@AgreementNo
		  END
				
			UPDATE DA_CLAIMS SET  DAC_RATE_OUT = ISNULL(@MDA_Authrate, 0), INS_COMP_AUTH_DAYS = @MDA_TotalDays WHERE DAC_ENTRY_ID = @RemedyEntryId	
			end
			ELSE
			BEGIN --create MDA						
			-------------------------------  AUTHORIZATION NO FOR MULTIPLE DEBITOR AUTH | AUTHORIZATION_AGR_RES    -------------------------------------
			
			SELECT @iDocNobigint =DN_DOCUMENT_NUMBER+1 from DOCUMENT_NUMBERS b(nolock) WHERE DN_COMPANY_CODE = 1 AND DN_BRANCH_CODE = 0 AND DN_DOCUMENT_TYPE = 12		
			
			if exists( select AUTHORIZATION_NO from ALBERTALIVE..MULTIPLE_DEBITOR_AUTH(nolock)	where  convert(bigint,AUTHORIZATION_NO)	=@iDocNobigint)
			begin	
				while exists( select AUTHORIZATION_NO from ALBERTALIVE..MULTIPLE_DEBITOR_AUTH(nolock)	where  convert(bigint,AUTHORIZATION_NO)	=@iDocNobigint)
				begin
					
					if not exists( select AUTHORIZATION_NO from ALBERTALIVE..MULTIPLE_DEBITOR_AUTH(nolock)	where  convert(bigint,AUTHORIZATION_NO)	=@iDocNobigint)
						break
						
					select @iDocNobigint= @iDocNobigint + 1
				end
			end
			
			select @MultipleDebitorAuthNo= RIGHT( convert(varchar(20),@iDocNobigint + 10000000000000000),15)				
							
			UPDATE DOCUMENT_NUMBERS SET  DN_DOCUMENT_NUMBER = @iDocNobigint 
			WHERE DN_COMPANY_CODE = @CompanyCode AND DN_BRANCH_CODE = 0 AND DN_DOCUMENT_TYPE = 12 		
			-----------------------------------------END----------------------------------------------------------------------------------------------------
			INSERT INTO ALBERTALIVE..MULTIPLE_DEBITOR_AUTH
			(AGREEMENT,
			RESERVATION_NO,
			DEBITOR_CODE,
			AUTHORIZATION_NO,
			DAYS,
			AGENTCOMMEXTERNV,
			F_GROUP,
			RENTAL_PACKAGE,
			Sold_Days,
			LOSS_DATE,
			CURRENCY,
			PER_DAY_PRICE,
			RATE_SR_NO,
			RATE_DET_SR_NO,
			VAT_PERCENT,
			SERVICE_FEE_PERCENT,
			RENTAL_PRICE,
			INSURANCES_PRICE,
			EXTRAS_PRICE,
			AMOUNT,
			TAXABLE_SUM,
			SERVICABLE_SUM,
			SALES_TAX,
			SERVICE_TAX,
			EXCHANGE_RATE,
			SUBTOTAL,
			FIRST_CHARGE_GROUP,
			FIRST_NO_OF_DAYS,
			FIRST_RENTAL_PACKAGE,
			FIRST_RATE_SR_NO,
			FIRST_RATE_DET_SR_NO,
			FIRST_PER_DAY_PRICE,
			BODY_SHOP_DIFF_FLAT_AMT,
			BODY_SHOP_DIFF_DAYS,
			MAX_AMOUNT,
			MAX_AMOUNT_CREDIT,
			claim_no,
			RATE_NO 
			)
			SELECT
			AGREEMENT = @AgreementNo,
			RESERVATION_NO = @ReservationNo,
			DEBITOR_CODE = @Debitor_Code,
			AUTHORIZATION_NO = @MultipleDebitorAuthNo,
			DAYS = @DaysAuthorized,
			AGENTCOMMEXTERNV = 'O',
			F_GROUP = @Authorized_VehicleCategory,
			RENTAL_PACKAGE = @Rental_Package,
			Sold_Days = @DaysAuthorized,
			LOSS_DATE = '00000000',
			CURRENCY = 'CAD',
			PER_DAY_PRICE = @Authorizedrate,
			RATE_SR_NO = @RATE_SR_NO,
			RATE_DET_SR_NO = @RATE_DET_SR_NO,
			VAT_PERCENT = @GSTorHST,
			SERVICE_FEE_PERCENT = @PST,
			RENTAL_PRICE = (@Authorizedrate)  * @DaysAuthorized, --0.00,
			INSURANCES_PRICE = @dTotalInsurances , --0.00,
			EXTRAS_PRICE = @dTotalExtras,
			AMOUNT = @dFinalTotal,
			TAXABLE_SUM = (@Authorizedrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @DaysAuthorized ,
			SERVICABLE_SUM = 0.00,
			SALES_TAX = @dTotalTaxes,
			SERVICE_TAX = 0.00,
			EXCHANGE_RATE = 1,
			SUBTOTAL = (@Authorizedrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @DaysAuthorized,
			FIRST_CHARGE_GROUP = @Authorized_VehicleCategory,
			FIRST_NO_OF_DAYS = @DaysAuthorized,
			FIRST_RENTAL_PACKAGE = @Rental_Package,
			FIRST_RATE_SR_NO = @RATE_SR_NO,
			FIRST_RATE_DET_SR_NO = @RATE_DET_SR_NO,
			FIRST_PER_DAY_PRICE = @Authorizedrate,
			BODY_SHOP_DIFF_FLAT_AMT  = 0.00,
			BODY_SHOP_DIFF_DAYS = 0,
			MAX_AMOUNT = @MaxAmount,
			MAX_AMOUNT_CREDIT = 0,
			claim_no = @RemedyEntryID,
			RATE_NO = isnull(@RateNo, 0)			
			
			if not exists
			(select 1 from ALBERTALIVE..DEBITOR_PAY_FLAGS (nolock) where AUTHRIZATION_NO = @MultipleDebitorAuthNo --AND AGREEMENT_NO=@AGREEMENTNO AND DEBITOR_CODE=@debitor_code
			)							
			begin
			insert into ALBERTALIVE..DEBITOR_PAY_FLAGS (
			[AUTHRIZATION_NO]
			,[PAY_RENTAL]
			,[PAY_EXTENSION]
			,[PAY_UPSELL]
			,[PAY_KM]
			,[PAY_FUEL]		
			,[PAY_DAMAGE]
			,[PAY_TRAFFIC]
			,[PAY_AIRPORTFEE]
			,[PAY_DROPOFFFEE]
			,[PAY_DELIVERY]
			,[PAY_PICKUP]
			,[PAY_INS]
			,[PAY_EXT]
			,[PAY_OTHER]
			,[GET_RED]
			,[PAY_SERVICE]
			,[PAY_VAT]
			,[PAY_TELEPHONE]
			,[PAY_DEDUACTABLE]
			,[PAY_HIGH_WAY_TICKET]
			,[PAY_HIGHWAYADMIN]
			,[CREATED_FROM]
			,[AGREEMENT_NO]
			,[DEBITOR_CODE]
			,[SEPARATE_DAMAGE_INVOICE]
			,[SEPARATE_TRAFFIC_INVOICE]
			,[PREBILLING_IN_ADVANCE]
			,[BILLTO_END_OF_MONTH]
			,[PREBILLING_INVOICE_METHOD]
			,[REQUIRE_VOUCHER_CONFIRMATION]
			,[COMBINATION_PREBILLING]
			,[FULLY_AUTHORIZE]
			,[COMBINATION_INVOICE]
			,[COMB_DAMGE_INVOICE]
			,[COMB_TRAFFIC_INVOICE]
			,[COMB_HIGHWAY_INVOICE]
			,[PREBILLING_CHARGE_KM]
			,[RENTAL_BEFORE_DISCOUNT]
			,[RENTAL_EXT_BEFORE_DISCOUNT]
			,[KM_PRICE_BEFORE_DISCOUNT]
			,[RENTAL_VAT_AMOUNT]
			,[RENTAL_EXT_VAT_AMOUNT]
			,[INS_SUM_BEFORE_DISCOUNT]
			,[INS_SUM_BEFORE_DIS_WITHOUTVAT]
			,[KM_VAT_AMOUNT]
			,[CUST_TRAFFIC_ADMIN_FEE]
			,[AIRPORT_VAT_AMOUNT]
			,[DROPOFF_VAT_AMOUNT]
			,[FUEL_VAT_AMOUNT]
			,[DELIVERY_VAT_AMOUNT]
			,[PICKKUP_VAT_AMOUNT]
			,[OTHERSUM_VAT_AMOUNT]
			,[REDUCTION_VAT_AMOUNT]
			,[DAMAGES_VAT_AMOUNT]
			,[DEDUCTIBLE_VAT_AMOUNT]
			,[TRAFFIC_VAT_AMOUNT]
			,[INS_VAT_AMOUNT]
			,[EXTRAS_VAT_AMOUNT]
			,[DISCOUNT_VAT_AMOUNT]
			,[RENTAL_SERVICE_AMOUNT]
			,[RENTALEXT_SERVICE_AMOUNT]
			,[KM_SERVICE_AMOUNT]
			,[AIRPORT_SERVICE_AMOUNT]
			,[DROPOFF_SERVICE_AMOUNT]
			,[FUEL_SERVICE_AMOUNT]
			,[DELIVERY_SERVICE_AMOUNT]
			,[PICKUP_SERVICE_AMOUNT]
			,[OTHERSUM_SERVICE_AMOUNT]
			,[REDUCTION_SERVICE_AMOUNT]
			,[DAMAGES_SERVICE_AMOUNT]
			,[DEDCTIBLE_SERVICE_AMOUNT]
			,[TRAFFIC_SERVICE_AMOUNT]
			,[INS_SERVICE_AMOUNT]
			,[EXTRAS_SERVICE_AMOUNT]
			,[DISCOUNT_SERVICE_AMOUNT]
			,[PACKAGE_PRICE]
			,[PACKAGE_EXT_PRICE]
			,[KM_PRICE]
			,[RENTAL_DISCOUNT_AMOUNT]
			,[RENTAL_EXT_DISCOUNT_SUM]
			,[KM_DISCOUNT_AMOUNT]
			,[INS_DISCOUNT_AMOUNT]
			,[INS_DISC_AMOUNT_WT_OUT_VAT]
			,[TOTAL_DISCOUNT_AMOUNT]
			,[NON_TAXBLE_AMOUNT]
			,[NON_SERVICABLE_AMOUNT]
			,[PACKAGE_DAYS]
			,[PACKAGE_ADD_DAYS]
			,[EXTENSION_DAYS]
			,[TRAFFIC_ADMIN_FEE_VAT_AMT]
			,[TRAFFIC_ADMIN_FEE_SERVICE_AMT]
			,[TRAFFIC_AMT_WO_ADMIN_FEE]
			,[BILLING_FREQUENCY]
			,[SEPARATE_REPLACEMENT_INV]
			,[SEPARATE_FUEL_INV]
			,[COMB_FUEL_INVOICE]
			,[INVOICE_BY]
			,[PAY_TOLL]
			,[SEPARATE_TOLL_INVOICE]
			,[TOLL_WO_ADMIN_FEE]
			,[TOLL_ADMIN_FEE]
			,[TOLL_VAT_AMT]
			,[TOLL_SERVICE_AMT]
			,[TOLL_ADMIN_FEEPER_SETUP]
			,[TOLL_ADMIN_FEEAMT_SETUP]
			,[DAMAGE_WO_ADMIN_FEE]
			,[DAMAGE_ADMIN_FEE]
			,[DED_WO_ADMIN_FEE]
			,[DED_ADMIN_FEE]
			,[PAY_ENTIRE_BILL]
			,[PAY_ALL_TAXES]
			,[PAY_RATE_PER_DAY]
			,[PAY_SURCHARGE]
			,[PAY_GST_HST]
			,[MONTHLY_DAYS]
			)

		   select 
		   [AUTHRIZATION_NO] = @MultipleDebitorAuthNo
		  ,[PAY_RENTAL] = 'Y'
		  ,[PAY_EXTENSION]= ''
		  ,[PAY_UPSELL]= ''
		  ,[PAY_KM]= 'N'
		  ,[PAY_FUEL]= 'N'
		  ,[PAY_DAMAGE]= 'N'
		  ,[PAY_TRAFFIC]= 'N'
		  ,[PAY_AIRPORTFEE]= 'N'
		  ,[PAY_DROPOFFFEE]= 'N'
		  ,[PAY_DELIVERY]= 'N'
		  ,[PAY_PICKUP]= 'N'
		  ,[PAY_INS]= CASE WHEN @CDW > 0 THEN 'Y' ELSE 'N' END
		  ,[PAY_EXT]= 'Y'
		  ,[PAY_OTHER]= 'N'
		  ,[GET_RED]= 'Y'
		  ,[PAY_SERVICE]= CASE WHEN @PST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_VAT]= CASE WHEN @GSTorHST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_TELEPHONE]= ''
		  ,[PAY_DEDUACTABLE]= ''
		  ,[PAY_HIGH_WAY_TICKET]= ''
		  ,[PAY_HIGHWAYADMIN]= ''
		  ,[CREATED_FROM]= ''
		  ,[AGREEMENT_NO]= @AgreementNo
		  ,[DEBITOR_CODE]= @debitor_code
		  ,[SEPARATE_DAMAGE_INVOICE]= ''
		  ,[SEPARATE_TRAFFIC_INVOICE] = ''
		  ,[PREBILLING_IN_ADVANCE]= ''
		  ,[BILLTO_END_OF_MONTH]= ''
		  ,[PREBILLING_INVOICE_METHOD]= ''
		  ,[REQUIRE_VOUCHER_CONFIRMATION]= ''
		  ,[COMBINATION_PREBILLING]= ''
		  ,[FULLY_AUTHORIZE]= ''
		  ,[COMBINATION_INVOICE]= ''
		  ,[COMB_DAMGE_INVOICE]= ''
		  ,[COMB_TRAFFIC_INVOICE]= ''
		  ,[COMB_HIGHWAY_INVOICE]= ''
		  ,[PREBILLING_CHARGE_KM]= ''
		  ,[RENTAL_BEFORE_DISCOUNT]=  @MDA_Authrate * @TotalAuthDays
		  ,[RENTAL_EXT_BEFORE_DISCOUNT]= ''
		  ,[KM_PRICE_BEFORE_DISCOUNT]= ''
		  ,[RENTAL_VAT_AMOUNT]= @Old_VAT+ @dTotalTaxes
		  ,[RENTAL_EXT_VAT_AMOUNT]= ''
		  ,[INS_SUM_BEFORE_DISCOUNT]= @Insurances_Price+@dTotalInsurances
		  ,[INS_SUM_BEFORE_DIS_WITHOUTVAT]= ''
		  ,[KM_VAT_AMOUNT]= ''
		  ,[CUST_TRAFFIC_ADMIN_FEE]= ''
		  ,[AIRPORT_VAT_AMOUNT]= ''
		  ,[DROPOFF_VAT_AMOUNT]= ''
		  ,[FUEL_VAT_AMOUNT]= ''
		  ,[DELIVERY_VAT_AMOUNT]= ''
		  ,[PICKKUP_VAT_AMOUNT]= ''
		  ,[OTHERSUM_VAT_AMOUNT]= ''
		  ,[REDUCTION_VAT_AMOUNT]= ''
		  ,[DAMAGES_VAT_AMOUNT]= ''
		  ,[DEDUCTIBLE_VAT_AMOUNT]= ''
		  ,[TRAFFIC_VAT_AMOUNT]= ''
		  ,[INS_VAT_AMOUNT]= ((@Insurances_Price+@dTotalInsurances) * @GSTorHST) / 100
		  ,[EXTRAS_VAT_AMOUNT]= ((@Extras_Price+@dTotalExtras) * @GSTorHST) / 100
		  ,[DISCOUNT_VAT_AMOUNT]= ''
		  ,[RENTAL_SERVICE_AMOUNT]= @Old_SERVICE_FEE + 0.00
		  ,[RENTALEXT_SERVICE_AMOUNT]= ''
		  ,[KM_SERVICE_AMOUNT]= ''
		  ,[AIRPORT_SERVICE_AMOUNT]= ''
		  ,[DROPOFF_SERVICE_AMOUNT]= ''
		  ,[FUEL_SERVICE_AMOUNT]= ''
		  ,[DELIVERY_SERVICE_AMOUNT]= ''
		  ,[PICKUP_SERVICE_AMOUNT]= ''
		  ,[OTHERSUM_SERVICE_AMOUNT]= ''
		  ,[REDUCTION_SERVICE_AMOUNT]= ''
		  ,[DAMAGES_SERVICE_AMOUNT]= ''
		  ,[DEDCTIBLE_SERVICE_AMOUNT]= ''
		  ,[TRAFFIC_SERVICE_AMOUNT] = 0
		  ,[INS_SERVICE_AMOUNT] = 0
		  ,[EXTRAS_SERVICE_AMOUNT] = 0
		  ,[DISCOUNT_SERVICE_AMOUNT] = 0
		  ,[PACKAGE_PRICE] = 0
		  ,[PACKAGE_EXT_PRICE] = 0
		  ,[KM_PRICE] = 0
		  ,[RENTAL_DISCOUNT_AMOUNT] = 0
		  ,[RENTAL_EXT_DISCOUNT_SUM] = 0
		  ,[KM_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISC_AMOUNT_WT_OUT_VAT] = 0
		  ,[TOTAL_DISCOUNT_AMOUNT] = 0
		  ,[NON_TAXBLE_AMOUNT] = 0
		  ,[NON_SERVICABLE_AMOUNT] = 0
		  ,[PACKAGE_DAYS] = 0
		  ,[PACKAGE_ADD_DAYS] = 0
		  ,[EXTENSION_DAYS] = 0
		  ,[TRAFFIC_ADMIN_FEE_VAT_AMT] = 0
		  ,[TRAFFIC_ADMIN_FEE_SERVICE_AMT] = 0
		  ,[TRAFFIC_AMT_WO_ADMIN_FEE] = 0
		  ,[BILLING_FREQUENCY] = 0
		  ,[SEPARATE_REPLACEMENT_INV] = 'N'
		  ,[SEPARATE_FUEL_INV] = 'N'
		  ,[COMB_FUEL_INVOICE] = 'N'
		  ,[INVOICE_BY] = 'A'
		  ,[PAY_TOLL] =  'N'
		  ,[SEPARATE_TOLL_INVOICE] = 'N'
		  ,[TOLL_WO_ADMIN_FEE] = 0
		  ,[TOLL_ADMIN_FEE] = 0
		  ,[TOLL_VAT_AMT] = 0
		  ,[TOLL_SERVICE_AMT] = 0
		  ,[TOLL_ADMIN_FEEPER_SETUP] = 0
		  ,[TOLL_ADMIN_FEEAMT_SETUP] = 0
		  ,[DAMAGE_WO_ADMIN_FEE] = 0
		  ,[DAMAGE_ADMIN_FEE] = 0
		  ,[DED_WO_ADMIN_FEE] = 0
		  ,[DED_ADMIN_FEE] = 0
		  ,[PAY_ENTIRE_BILL]  = 'N'
		  ,[PAY_ALL_TAXES] = 'Y'
		  ,[PAY_RATE_PER_DAY] = 'N'
		  ,[PAY_SURCHARGE] = 'N'
		  ,[PAY_GST_HST] = 'Y'
		  ,[MONTHLY_DAYS] = 0
		end
		else
		begin
		   update  ALBERTALIVE..DEBITOR_PAY_FLAGS set 
		   [AUTHRIZATION_NO] = @MultipleDebitorAuthNo
		  ,[PAY_RENTAL] = 'Y'
		  ,[PAY_EXTENSION]= ''
		  ,[PAY_UPSELL]= ''
		  ,[PAY_KM]= 'N'
		  ,[PAY_FUEL]= 'N'
		  ,[PAY_DAMAGE]= 'N'
		  ,[PAY_TRAFFIC]= 'N'
		  ,[PAY_AIRPORTFEE]= 'N'
		  ,[PAY_DROPOFFFEE]= 'N'
		  ,[PAY_DELIVERY]= 'N'
		  ,[PAY_PICKUP]= 'N'
		  ,[PAY_INS]= CASE WHEN @CDW > 0 THEN 'Y' ELSE 'N' END
		  ,[PAY_EXT]= 'Y'
		  ,[PAY_OTHER]= 'N'
		  ,[GET_RED]= 'Y'
		  ,[PAY_SERVICE]= CASE WHEN @PST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_VAT]= CASE WHEN @GSTorHST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_TELEPHONE]= ''
		  ,[PAY_DEDUACTABLE]= ''
		  ,[PAY_HIGH_WAY_TICKET]= ''
		  ,[PAY_HIGHWAYADMIN]= ''
		  ,[CREATED_FROM]= ''
		  ,[AGREEMENT_NO]= @AgreementNo
		  ,[DEBITOR_CODE]= @debitor_code
		  ,[SEPARATE_DAMAGE_INVOICE]= ''
		  ,[SEPARATE_TRAFFIC_INVOICE] = ''
		  ,[PREBILLING_IN_ADVANCE]= ''
		  ,[BILLTO_END_OF_MONTH]= ''
		  ,[PREBILLING_INVOICE_METHOD]= ''
		  ,[REQUIRE_VOUCHER_CONFIRMATION]= ''
		  ,[COMBINATION_PREBILLING]= ''
		  ,[FULLY_AUTHORIZE]= ''
		  ,[COMBINATION_INVOICE]= ''
		  ,[COMB_DAMGE_INVOICE]= ''
		  ,[COMB_TRAFFIC_INVOICE]= ''
		  ,[COMB_HIGHWAY_INVOICE]= ''
		  ,[PREBILLING_CHARGE_KM]= ''
		  ,[RENTAL_BEFORE_DISCOUNT]=  @MDA_Authrate * @TotalAuthDays
		  ,[RENTAL_EXT_BEFORE_DISCOUNT]= ''
		  ,[KM_PRICE_BEFORE_DISCOUNT]= ''
		  ,[RENTAL_VAT_AMOUNT]= @Old_VAT+ @dTotalTaxes
		  ,[RENTAL_EXT_VAT_AMOUNT]= ''
		  ,[INS_SUM_BEFORE_DISCOUNT]= @Insurances_Price+@dTotalInsurances
		  ,[INS_SUM_BEFORE_DIS_WITHOUTVAT]= ''
		  ,[KM_VAT_AMOUNT]= ''
		  ,[CUST_TRAFFIC_ADMIN_FEE]= ''
		  ,[AIRPORT_VAT_AMOUNT]= ''
		  ,[DROPOFF_VAT_AMOUNT]= ''
		  ,[FUEL_VAT_AMOUNT]= ''
		  ,[DELIVERY_VAT_AMOUNT]= ''
		  ,[PICKKUP_VAT_AMOUNT]= ''
		  ,[OTHERSUM_VAT_AMOUNT]= ''
		  ,[REDUCTION_VAT_AMOUNT]= ''
		  ,[DAMAGES_VAT_AMOUNT]= ''
		  ,[DEDUCTIBLE_VAT_AMOUNT]= ''
		  ,[TRAFFIC_VAT_AMOUNT]= ''
		  ,[INS_VAT_AMOUNT]= ((@Insurances_Price+@dTotalInsurances) * @GSTorHST) / 100
		  ,[EXTRAS_VAT_AMOUNT]= ((@Extras_Price+@dTotalExtras) * @GSTorHST) / 100
		  ,[DISCOUNT_VAT_AMOUNT]= ''
		  ,[RENTAL_SERVICE_AMOUNT]= @Old_SERVICE_FEE + 0.00
		  ,[RENTALEXT_SERVICE_AMOUNT]= ''
		  ,[KM_SERVICE_AMOUNT]= ''
		  ,[AIRPORT_SERVICE_AMOUNT]= ''
		  ,[DROPOFF_SERVICE_AMOUNT]= ''
		  ,[FUEL_SERVICE_AMOUNT]= ''
		  ,[DELIVERY_SERVICE_AMOUNT]= ''
		  ,[PICKUP_SERVICE_AMOUNT]= ''
		  ,[OTHERSUM_SERVICE_AMOUNT]= ''
		  ,[REDUCTION_SERVICE_AMOUNT]= ''
		  ,[DAMAGES_SERVICE_AMOUNT]= ''
		  ,[DEDCTIBLE_SERVICE_AMOUNT]= ''
		  ,[TRAFFIC_SERVICE_AMOUNT] = 0
		  ,[INS_SERVICE_AMOUNT] = 0
		  ,[EXTRAS_SERVICE_AMOUNT] = 0
		  ,[DISCOUNT_SERVICE_AMOUNT] = 0
		  ,[PACKAGE_PRICE] = 0
		  ,[PACKAGE_EXT_PRICE] = 0
		  ,[KM_PRICE] = 0
		  ,[RENTAL_DISCOUNT_AMOUNT] = 0
		  ,[RENTAL_EXT_DISCOUNT_SUM] = 0
		  ,[KM_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISC_AMOUNT_WT_OUT_VAT] = 0
		  ,[TOTAL_DISCOUNT_AMOUNT] = 0
		  ,[NON_TAXBLE_AMOUNT] = 0
		  ,[NON_SERVICABLE_AMOUNT] = 0
		  ,[PACKAGE_DAYS] = 0
		  ,[PACKAGE_ADD_DAYS] = 0
		  ,[EXTENSION_DAYS] = 0
		  ,[TRAFFIC_ADMIN_FEE_VAT_AMT] = 0
		  ,[TRAFFIC_ADMIN_FEE_SERVICE_AMT] = 0
		  ,[TRAFFIC_AMT_WO_ADMIN_FEE] = 0
		  ,[BILLING_FREQUENCY] = 0
		  ,[SEPARATE_REPLACEMENT_INV] = 'N'
		  ,[SEPARATE_FUEL_INV] = 'N'
		  ,[COMB_FUEL_INVOICE] = 'N'
		  ,[INVOICE_BY] = 'A'
		  ,[PAY_TOLL] =  'N'
		  ,[SEPARATE_TOLL_INVOICE] = 'N'
		  ,[TOLL_WO_ADMIN_FEE] = 0
		  ,[TOLL_ADMIN_FEE] = 0
		  ,[TOLL_VAT_AMT] = 0
		  ,[TOLL_SERVICE_AMT] = 0
		  ,[TOLL_ADMIN_FEEPER_SETUP] = 0
		  ,[TOLL_ADMIN_FEEAMT_SETUP] = 0
		  ,[DAMAGE_WO_ADMIN_FEE] = 0
		  ,[DAMAGE_ADMIN_FEE] = 0
		  ,[DED_WO_ADMIN_FEE] = 0
		  ,[DED_ADMIN_FEE] = 0
		  ,[PAY_ENTIRE_BILL]  = 'N'
		  ,[PAY_ALL_TAXES] = 'Y'
		  ,[PAY_RATE_PER_DAY] = 'N'
		  ,[PAY_SURCHARGE] = 'N'
		  ,[PAY_GST_HST] = 'Y'
		  ,[MONTHLY_DAYS] = 0
		  where [AUTHRIZATION_NO] = @MultipleDebitorAuthNo AND AGREEMENT_NO=@AGREEMENTNO AND DEBITOR_CODE=@debitor_code
		end	
			END--end to create MDA	
		END
						
		END	--(@agreementno > 0  and @Agreement_Status_Code  in (0,1,2,3)) or (@ReservationNo != '' and @agreementno=0)
		
		if not exists 
		(select AUTHORIZATION_NO from ALBERTALIVE..AUTHORIZATION_AGR_RES (nolock) where AUTHORIZATION_NO=@MultipleDebitorAuthNo AND FROM_DATE=@AuthFromDate AND FROM_TIME = @AuthFromTime)		
		begin
		INSERT INTO ALBERTALIVE..AUTHORIZATION_AGR_RES(AUTHORIZATION_NO,FROM_DATE,FROM_TIME,AUTH_SERIAL,AGREEMENT_NO,CAR_GROUP,RATE_PER_DAY,AUTH_DAYS,RATE_SR_NO,RATE_DET_SR_NO,TO_DATE,TO_TIME)
		VALUES
		(@MultipleDebitorAuthNo,@AuthFromDate,@AuthFromTime, 
		isnull((SELECT (MAX(AUTH_SERIAL)) FROM ALBERTALIVE..AUTHORIZATION_AGR_RES (NOLOCK) where AUTHORIZATION_NO=@MultipleDebitorAuthNo), 0)+1, @AgreementNo, @Authorized_VehicleCategory, 
		@Authorizedrate,@DaysAuthorized,@RATE_SR_NO,@RATE_DET_SR_NO,@AuthToDate, @AuthToTime)		
		END
			
			
		if @VLI_Rate > 0  and @AuthFromDate != '00000000'
		begin
			if not exists --VIREN INSISTEN ON FRIDAY NOV 29,2013 TO PUT 2 INSERTS STATEMENT ONE WITH 0 AND WITH AGREEMENTNO
			(select EXTRAS_CODE from ALBERTALIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='VLI' and RESAUTHVOUCHER=@MultipleDebitorAuthNo and MASTER_AGREEMENT=0)		
			begin
				INSERT INTO ALBERTALIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES
				(@MultipleDebitorAuthNo,'00000000','VLI', 0,0,'', @VLI_Rate, @VLI_Rate*@DaysAuthorized)
			end
				
			if not exists --VIREN INSISTEN ON FRIDAY NOV 29,2013 TO PUT 2 INSERTS STATEMENT ONE WITH 0 AND WITH AGREEMENTNO
			(select EXTRAS_CODE from ALBERTALIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='VLI' and RESAUTHVOUCHER='' and MASTER_AGREEMENT=@AgreementNo)		
			begin	
				INSERT INTO ALBERTALIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES
				('','00000000','VLI', @AgreementNo,1,'', @VLI_Rate, @VLI_Rate*@DaysAuthorized)
			end
		end
			
		if @UF > 0  and @AuthFromDate != '00000000'
		begin
			if not exists 
			(select EXTRAS_CODE from ALBERTALIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='UF' and RESAUTHVOUCHER=@MultipleDebitorAuthNo and MASTER_AGREEMENT=0)		
			begin			
				INSERT INTO ALBERTALIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES(@MultipleDebitorAuthNo,'00000000' ,'UF', 0, 0, '' ,@UF, @UF*@DaysAuthorized)
			end
			
			if not exists --VIREN INSISTEN ON FRIDAY NOV 29,2013 TO PUT 2 INSERTS STATEMENT ONE WITH 0 AND WITH AGREEMENTNO
			(select EXTRAS_CODE from ALBERTALIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='UF' and RESAUTHVOUCHER='' and MASTER_AGREEMENT=@AgreementNo)		
			begin					
				INSERT INTO ALBERTALIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES('','00000000' ,'UF', @AgreementNo,1,'',@UF, @UF*@DaysAuthorized)
			end	
		end			

		if @WT > 0 and @AuthFromDate != '00000000'
		begin
			if not exists 
			(select EXTRAS_CODE from ALBERTALIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='WT' and RESAUTHVOUCHER=@MultipleDebitorAuthNo)		
			begin
				INSERT INTO ALBERTALIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES(@MultipleDebitorAuthNo,'00000000','WT', 0,0,'',@WT, @WT*@DaysAuthorized)	
			end		
			
			if not exists --VIREN INSISTEN ON FRIDAY NOV 29,2013 TO PUT 2 INSERTS STATEMENT ONE WITH 0 AND WITH AGREEMENTNO
			(select EXTRAS_CODE from ALBERTALIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='WT' and RESAUTHVOUCHER='' and MASTER_AGREEMENT=@AgreementNo)		
			begin		
				INSERT INTO ALBERTALIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES('','00000000','WT', @AgreementNo,1,'',@WT, @WT*@DaysAuthorized)							
			end
		end			

		if @CDW > 0 and @AuthFromDate != '00000000'
		begin
			if not exists 
			(select INSURANCE_CODE from ALBERTALIVE..AGREEMENT_INSURANCES (nolock) where MASTER_AGREEMENT=0 and INSURANCE_CODE='CDW' and RESAUTHVOUCHER=@MultipleDebitorAuthNo)		
			begin
				INSERT INTO ALBERTALIVE..AGREEMENT_INSURANCES(RESAUTHVOUCHER,INSURANCE_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,PRICE_PER_DAY, F_SUM)
				VALUES(@MultipleDebitorAuthNo,'CDW', @AgreementNo,0,'', @CDW, @CDW*@DaysAuthorized)	
			end
			
			if not exists 
			(select INSURANCE_CODE from ALBERTALIVE..AGREEMENT_INSURANCES (nolock) where MASTER_AGREEMENT=@AgreementNo and INSURANCE_CODE='CDW' and RESAUTHVOUCHER='' and SUV_AGREEMENT=1)					
			begin	
				INSERT INTO ALBERTALIVE..AGREEMENT_INSURANCES(RESAUTHVOUCHER,INSURANCE_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,PRICE_PER_DAY, F_SUM)
				VALUES('','CDW', @AgreementNo,1,'', @CDW, @CDW*@DaysAuthorized)				
			end
		end	
		
				
		end --db		
		
		
		if @DB = 'MARITIMESLIVE'
		BEGIN	
		if (@agreementno > 0  and @Agreement_Status_Code  in (0,1,2,3)) or (@ReservationNo != '' and @agreementno=0)
		begin		  
			select @MultipleDebitorAuthNo = AUTHORIZATION_NO,
			@RentalPrice = rental_price, @Insurances_Price = insurances_price , @Extras_Price = extras_price, @Insu_NonVat_Sum = Insu_NonVat_Sum,
			@KM_Sum = KM_Sum, @Airport_Fee = Airport_Fee, @DropOff_Fee = DropOff_Fee, @Fuel_Sum = Fuel_Sum, @Tel_Sum = Tel_Sum,
			@Delivery_Sum = Delivery_Sum, @Pickup_Sum = Pickup_Sum, @Other_Sum = Other_Sum, @Damages_Sum = Damages_Sum, 
			@Deductible_Sum = Deductible_Sum, @Traffic_Sum = Traffic_Sum, @Reduction_Sum = Reduction_Sum,
			@MDA_Max_Amt = MAX_AMOUNT , @Old_VAT = sales_tax,  @Old_SERVICE_FEE = service_tax , @MDA_TotalDays_Old = days, @Old_TotalAmount = amount 
			from MARITIMESLIVE..MULTIPLE_DEBITOR_AUTH (nolock) 
			where ((AGREEMENT = @AgreementNo and @AgreementNo >0) or (RESERVATION_NO = @ReservationNo and @agreementno=0)) 
			and debitor_code = @Debitor_Code AND @DCA_Bill_To != 2	
			  
		    if @Debitor_Code = @Third_Party_Debitor_Code 
			  set @MDA_Max_Amt = @Third_Party_policyMax
		    else                      						
			  set @MDA_Max_Amt = @PolicyMax
		  
		    select @MDA_Authrate = sum(DCA_AUTHOR_RATE*dca_a_days)/sum(dca_a_days), @MDA_TotalDays = sum(dca_a_days)  from da_authorization (nolock) where dca_Claim_id=@RemedyEntryId	
		    	  
		    select @RecID = isnull(REC_ID, 0)+1  from MARITIMESLIVE..AGREEMENT_LOG_FILE where MASTER_AGREEMENT = @AgreementNo

		    INSERT INTO MARITIMESLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
		    VALUES(@AgreementNo,'DIAL', @ModorCreateDate, @ModyorCreateTime,'Modify Auth From Claim','','','D',@RecID)		
		    INSERT INTO MARITIMESLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
		    VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Authorization Created: 0000000','',@ModorCreateDate,'D',@RecID+1)	
		    INSERT INTO MARITIMESLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
		    VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Charge Group','', @Authorized_VehicleCategory,'D',@RecID+2)		
		    INSERT INTO MARITIMESLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
		    VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Per Day Price','',@Authorizedrate,'D',@RecID+3)		
		    INSERT INTO MARITIMESLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
		    VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Rate Sr No.','',@RATE_SR_NO,'D',@RecID+4)		
			INSERT INTO MARITIMESLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
			VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Rate Det Sr No.','',@RATE_DET_SR_NO,'D',@RecID+5)		
			INSERT INTO MARITIMESLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
			VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Sold Days','',@RATE_SR_NO,'D',@RecID+6)				
			INSERT INTO MARITIMESLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
			VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Days',@MDA_TotalDays_Old, @MDA_TotalDays, 'D', @RecID+7)		
			INSERT INTO MARITIMESLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
			VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Total Amount','',@RATE_DET_SR_NO,'D',@RecID+8)		
		
		--D - DATA	--T - TRANSACTION
		  
		if @MultipleDebitorAuthNo != '' --update
		BEGIN
				IF @ReservationNo != '' AND @AgreementNo = 0	-- reservation stage			
				begin
					UPDATE MARITIMESLIVE..MULTIPLE_DEBITOR_AUTH SET					
					RESERVATION_NO = @ReservationNo,
					DEBITOR_CODE = @Debitor_Code,
					AUTHORIZATION_NO = @MultipleDebitorAuthNo,
					DAYS = @MDA_TotalDays,							
					AGENTCOMMEXTERNV = 'O',
					F_GROUP = @Authorized_VehicleCategory,
					RENTAL_PACKAGE = @Rental_Package,
					Sold_Days = @MDA_TotalDays,
					LOSS_DATE = '00000000',
					CURRENCY = 'CAD',
					PER_DAY_PRICE = @MDA_Authrate,
					RATE_NO = isnull(@RateNo, 0), 
					RATE_SR_NO = @RATE_SR_NO,
					RATE_DET_SR_NO = @RATE_DET_SR_NO,
					VAT_PERCENT = @GSTorHST,
					SERVICE_FEE_PERCENT = @PST,
					RENTAL_PRICE = (@MDA_Authrate) * @MDA_TotalDays, --0.00,
					INSURANCES_PRICE = @Insurances_Price+@dTotalInsurances , --0.00,
					EXTRAS_PRICE = @Extras_Price+@dTotalExtras,
					AMOUNT = @Old_TotalAmount + @dFinalTotal,
					TAXABLE_SUM = (@MDA_Authrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @MDA_TotalDays ,
					SERVICABLE_SUM = 0.00,
					SALES_TAX = @Old_VAT+ @dTotalTaxes,
					SERVICE_TAX = @Old_SERVICE_FEE + 0.00,
					EXCHANGE_RATE = 1,
					SUBTOTAL = (@MDA_Authrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @MDA_TotalDays,
					MAX_AMOUNT = @MDA_Max_Amt,
					MAX_AMOUNT_CREDIT = @Tel_Sum,
					claim_no = @RemedyEntryID	
					WHERE RESERVATION_NO = @ReservationNo and AUTHORIZATION_NO = @MultipleDebitorAuthNo and DEBITOR_CODE = @Debitor_Code
				end
				
				IF @AgreementNo > 0				
				begin
					UPDATE MARITIMESLIVE..MULTIPLE_DEBITOR_AUTH SET 
					agreement = @AgreementNo,					
					RESERVATION_NO = @ReservationNo,
					DEBITOR_CODE = @Debitor_Code,
					AUTHORIZATION_NO = @MultipleDebitorAuthNo,
					DAYS = @MDA_TotalDays,							
					AGENTCOMMEXTERNV = 'O',
					F_GROUP = @Authorized_VehicleCategory,
					RENTAL_PACKAGE = @Rental_Package,
					Sold_Days = @MDA_TotalDays,
					LOSS_DATE = '00000000',
					CURRENCY = 'CAD',
					PER_DAY_PRICE = @MDA_Authrate,
					RATE_NO = isnull(@RateNo, 0), 
					RATE_SR_NO = @RATE_SR_NO,
					RATE_DET_SR_NO = @RATE_DET_SR_NO,
					VAT_PERCENT = @GSTorHST,
					SERVICE_FEE_PERCENT = @PST,
					RENTAL_PRICE = (@MDA_Authrate)  * @MDA_TotalDays, --0.00,
					INSURANCES_PRICE = @Insurances_Price+@dTotalInsurances , --0.00,
					EXTRAS_PRICE = @Extras_Price+@dTotalExtras,
					AMOUNT = @Old_TotalAmount + @dFinalTotal,
					TAXABLE_SUM = (@MDA_Authrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @MDA_TotalDays ,
					SERVICABLE_SUM = 0.00,
					SALES_TAX = @Old_VAT+ @dTotalTaxes,
					SERVICE_TAX = @Old_SERVICE_FEE + 0.00,
					EXCHANGE_RATE = 1,
					SUBTOTAL = (@MDA_Authrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @MDA_TotalDays,
					MAX_AMOUNT = @MDA_Max_Amt,
					MAX_AMOUNT_CREDIT = @Tel_Sum,
					claim_no = @RemedyEntryID	
					WHERE AGREEMENT = @AgreementNo and AUTHORIZATION_NO = @MultipleDebitorAuthNo and DEBITOR_CODE = @Debitor_Code
				end		
				
				
			if not exists
			(select 1 from MARITIMESLIVE..DEBITOR_PAY_FLAGS (nolock) where AUTHRIZATION_NO = @MultipleDebitorAuthNo --AND AGREEMENT_NO= @AgreementNo AND DEBITOR_CODE= @debitor_code
			)							
			begin
			insert into MARITIMESLIVE..DEBITOR_PAY_FLAGS (
			[AUTHRIZATION_NO]
			,[PAY_RENTAL]
			,[PAY_EXTENSION]
			,[PAY_UPSELL]
			,[PAY_KM]
			,[PAY_FUEL]		
			,[PAY_DAMAGE]
			,[PAY_TRAFFIC]
			,[PAY_AIRPORTFEE]
			,[PAY_DROPOFFFEE]
			,[PAY_DELIVERY]
			,[PAY_PICKUP]
			,[PAY_INS]
			,[PAY_EXT]
			,[PAY_OTHER]
			,[GET_RED]
			,[PAY_SERVICE]
			,[PAY_VAT]
			,[PAY_TELEPHONE]
			,[PAY_DEDUACTABLE]
			,[PAY_HIGH_WAY_TICKET]
			,[PAY_HIGHWAYADMIN]
			,[CREATED_FROM]
			,[AGREEMENT_NO]
			,[DEBITOR_CODE]
			,[SEPARATE_DAMAGE_INVOICE]
			,[SEPARATE_TRAFFIC_INVOICE]
			,[PREBILLING_IN_ADVANCE]
			,[BILLTO_END_OF_MONTH]
			,[PREBILLING_INVOICE_METHOD]
			,[REQUIRE_VOUCHER_CONFIRMATION]
			,[COMBINATION_PREBILLING]
			,[FULLY_AUTHORIZE]
			,[COMBINATION_INVOICE]
			,[COMB_DAMGE_INVOICE]
			,[COMB_TRAFFIC_INVOICE]
			,[COMB_HIGHWAY_INVOICE]
			,[PREBILLING_CHARGE_KM]
			,[RENTAL_BEFORE_DISCOUNT]
			,[RENTAL_EXT_BEFORE_DISCOUNT]
			,[KM_PRICE_BEFORE_DISCOUNT]
			,[RENTAL_VAT_AMOUNT]
			,[RENTAL_EXT_VAT_AMOUNT]
			,[INS_SUM_BEFORE_DISCOUNT]
			,[INS_SUM_BEFORE_DIS_WITHOUTVAT]
			,[KM_VAT_AMOUNT]
			,[CUST_TRAFFIC_ADMIN_FEE]
			,[AIRPORT_VAT_AMOUNT]
			,[DROPOFF_VAT_AMOUNT]
			,[FUEL_VAT_AMOUNT]
			,[DELIVERY_VAT_AMOUNT]
			,[PICKKUP_VAT_AMOUNT]
			,[OTHERSUM_VAT_AMOUNT]
			,[REDUCTION_VAT_AMOUNT]
			,[DAMAGES_VAT_AMOUNT]
			,[DEDUCTIBLE_VAT_AMOUNT]
			,[TRAFFIC_VAT_AMOUNT]
			,[INS_VAT_AMOUNT]
			,[EXTRAS_VAT_AMOUNT]
			,[DISCOUNT_VAT_AMOUNT]
			,[RENTAL_SERVICE_AMOUNT]
			,[RENTALEXT_SERVICE_AMOUNT]
			,[KM_SERVICE_AMOUNT]
			,[AIRPORT_SERVICE_AMOUNT]
			,[DROPOFF_SERVICE_AMOUNT]
			,[FUEL_SERVICE_AMOUNT]
			,[DELIVERY_SERVICE_AMOUNT]
			,[PICKUP_SERVICE_AMOUNT]
			,[OTHERSUM_SERVICE_AMOUNT]
			,[REDUCTION_SERVICE_AMOUNT]
			,[DAMAGES_SERVICE_AMOUNT]
			,[DEDCTIBLE_SERVICE_AMOUNT]
			,[TRAFFIC_SERVICE_AMOUNT]
			,[INS_SERVICE_AMOUNT]
			,[EXTRAS_SERVICE_AMOUNT]
			,[DISCOUNT_SERVICE_AMOUNT]
			,[PACKAGE_PRICE]
			,[PACKAGE_EXT_PRICE]
			,[KM_PRICE]
			,[RENTAL_DISCOUNT_AMOUNT]
			,[RENTAL_EXT_DISCOUNT_SUM]
			,[KM_DISCOUNT_AMOUNT]
			,[INS_DISCOUNT_AMOUNT]
			,[INS_DISC_AMOUNT_WT_OUT_VAT]
			,[TOTAL_DISCOUNT_AMOUNT]
			,[NON_TAXBLE_AMOUNT]
			,[NON_SERVICABLE_AMOUNT]
			,[PACKAGE_DAYS]
			,[PACKAGE_ADD_DAYS]
			,[EXTENSION_DAYS]
			,[TRAFFIC_ADMIN_FEE_VAT_AMT]
			,[TRAFFIC_ADMIN_FEE_SERVICE_AMT]
			,[TRAFFIC_AMT_WO_ADMIN_FEE]
			,[BILLING_FREQUENCY]
			,[SEPARATE_REPLACEMENT_INV]
			,[SEPARATE_FUEL_INV]
			,[COMB_FUEL_INVOICE]
			,[INVOICE_BY]
			,[PAY_TOLL]
			,[SEPARATE_TOLL_INVOICE]
			,[TOLL_WO_ADMIN_FEE]
			,[TOLL_ADMIN_FEE]
			,[TOLL_VAT_AMT]
			,[TOLL_SERVICE_AMT]
			,[TOLL_ADMIN_FEEPER_SETUP]
			,[TOLL_ADMIN_FEEAMT_SETUP]
			,[DAMAGE_WO_ADMIN_FEE]
			,[DAMAGE_ADMIN_FEE]
			,[DED_WO_ADMIN_FEE]
			,[DED_ADMIN_FEE]
			,[PAY_ENTIRE_BILL]
			,[PAY_ALL_TAXES]
			,[PAY_RATE_PER_DAY]
			,[PAY_SURCHARGE]
			,[PAY_GST_HST]
			,[MONTHLY_DAYS]
			)

		   select 
		   [AUTHRIZATION_NO] = @MultipleDebitorAuthNo
		  ,[PAY_RENTAL] = 'Y'
		  ,[PAY_EXTENSION]= ''
		  ,[PAY_UPSELL]= ''
		  ,[PAY_KM]= 'N'
		  ,[PAY_FUEL]= 'N'
		  ,[PAY_DAMAGE]= 'N'
		  ,[PAY_TRAFFIC]= 'N'
		  ,[PAY_AIRPORTFEE]= 'N'
		  ,[PAY_DROPOFFFEE]= 'N'
		  ,[PAY_DELIVERY]= 'N'
		  ,[PAY_PICKUP]= 'N'
		  ,[PAY_INS]= CASE WHEN @CDW > 0 THEN 'Y' ELSE 'N' END
		  ,[PAY_EXT]= 'Y'
		  ,[PAY_OTHER]= 'N'
		  ,[GET_RED]= 'Y'
		  ,[PAY_SERVICE]= CASE WHEN @PST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_VAT]= CASE WHEN @GSTorHST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_TELEPHONE]= ''
		  ,[PAY_DEDUACTABLE]= ''
		  ,[PAY_HIGH_WAY_TICKET]= ''
		  ,[PAY_HIGHWAYADMIN]= ''
		  ,[CREATED_FROM]= ''
		  ,[AGREEMENT_NO]= @AgreementNo
		  ,[DEBITOR_CODE]= @debitor_code
		  ,[SEPARATE_DAMAGE_INVOICE]= ''
		  ,[SEPARATE_TRAFFIC_INVOICE] = ''
		  ,[PREBILLING_IN_ADVANCE]= ''
		  ,[BILLTO_END_OF_MONTH]= ''
		  ,[PREBILLING_INVOICE_METHOD]= ''
		  ,[REQUIRE_VOUCHER_CONFIRMATION]= ''
		  ,[COMBINATION_PREBILLING]= ''
		  ,[FULLY_AUTHORIZE]= ''
		  ,[COMBINATION_INVOICE]= ''
		  ,[COMB_DAMGE_INVOICE]= ''
		  ,[COMB_TRAFFIC_INVOICE]= ''
		  ,[COMB_HIGHWAY_INVOICE]= ''
		  ,[PREBILLING_CHARGE_KM]= ''
		  ,[RENTAL_BEFORE_DISCOUNT]=  @MDA_Authrate * @TotalAuthDays
		  ,[RENTAL_EXT_BEFORE_DISCOUNT]= ''
		  ,[KM_PRICE_BEFORE_DISCOUNT]= ''
		  ,[RENTAL_VAT_AMOUNT]= @Old_VAT+ @dTotalTaxes
		  ,[RENTAL_EXT_VAT_AMOUNT]= ''
		  ,[INS_SUM_BEFORE_DISCOUNT]= @Insurances_Price+@dTotalInsurances
		  ,[INS_SUM_BEFORE_DIS_WITHOUTVAT]= ''
		  ,[KM_VAT_AMOUNT]= ''
		  ,[CUST_TRAFFIC_ADMIN_FEE]= ''
		  ,[AIRPORT_VAT_AMOUNT]= ''
		  ,[DROPOFF_VAT_AMOUNT]= ''
		  ,[FUEL_VAT_AMOUNT]= ''
		  ,[DELIVERY_VAT_AMOUNT]= ''
		  ,[PICKKUP_VAT_AMOUNT]= ''
		  ,[OTHERSUM_VAT_AMOUNT]= ''
		  ,[REDUCTION_VAT_AMOUNT]= ''
		  ,[DAMAGES_VAT_AMOUNT]= ''
		  ,[DEDUCTIBLE_VAT_AMOUNT]= ''
		  ,[TRAFFIC_VAT_AMOUNT]= ''
		  ,[INS_VAT_AMOUNT]= ((@Insurances_Price+@dTotalInsurances) * @GSTorHST) / 100
		  ,[EXTRAS_VAT_AMOUNT]= ((@Extras_Price+@dTotalExtras) * @GSTorHST) / 100
		  ,[DISCOUNT_VAT_AMOUNT]= ''
		  ,[RENTAL_SERVICE_AMOUNT]= @Old_SERVICE_FEE + 0.00
		  ,[RENTALEXT_SERVICE_AMOUNT]= ''
		  ,[KM_SERVICE_AMOUNT]= ''
		  ,[AIRPORT_SERVICE_AMOUNT]= ''
		  ,[DROPOFF_SERVICE_AMOUNT]= ''
		  ,[FUEL_SERVICE_AMOUNT]= ''
		  ,[DELIVERY_SERVICE_AMOUNT]= ''
		  ,[PICKUP_SERVICE_AMOUNT]= ''
		  ,[OTHERSUM_SERVICE_AMOUNT]= ''
		  ,[REDUCTION_SERVICE_AMOUNT]= ''
		  ,[DAMAGES_SERVICE_AMOUNT]= ''
		  ,[DEDCTIBLE_SERVICE_AMOUNT]= ''
		  ,[TRAFFIC_SERVICE_AMOUNT] = 0
		  ,[INS_SERVICE_AMOUNT] = 0
		  ,[EXTRAS_SERVICE_AMOUNT] = 0
		  ,[DISCOUNT_SERVICE_AMOUNT] = 0
		  ,[PACKAGE_PRICE] = 0
		  ,[PACKAGE_EXT_PRICE] = 0
		  ,[KM_PRICE] = 0
		  ,[RENTAL_DISCOUNT_AMOUNT] = 0
		  ,[RENTAL_EXT_DISCOUNT_SUM] = 0
		  ,[KM_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISC_AMOUNT_WT_OUT_VAT] = 0
		  ,[TOTAL_DISCOUNT_AMOUNT] = 0
		  ,[NON_TAXBLE_AMOUNT] = 0
		  ,[NON_SERVICABLE_AMOUNT] = 0
		  ,[PACKAGE_DAYS] = 0
		  ,[PACKAGE_ADD_DAYS] = 0
		  ,[EXTENSION_DAYS] = 0
		  ,[TRAFFIC_ADMIN_FEE_VAT_AMT] = 0
		  ,[TRAFFIC_ADMIN_FEE_SERVICE_AMT] = 0
		  ,[TRAFFIC_AMT_WO_ADMIN_FEE] = 0
		  ,[BILLING_FREQUENCY] = 0
		  ,[SEPARATE_REPLACEMENT_INV] = 'N'
		  ,[SEPARATE_FUEL_INV] = 'N'
		  ,[COMB_FUEL_INVOICE] = 'N'
		  ,[INVOICE_BY] = 'A'
		  ,[PAY_TOLL] =  'N'
		  ,[SEPARATE_TOLL_INVOICE] = 'N'
		  ,[TOLL_WO_ADMIN_FEE] = 0
		  ,[TOLL_ADMIN_FEE] = 0
		  ,[TOLL_VAT_AMT] = 0
		  ,[TOLL_SERVICE_AMT] = 0
		  ,[TOLL_ADMIN_FEEPER_SETUP] = 0
		  ,[TOLL_ADMIN_FEEAMT_SETUP] = 0
		  ,[DAMAGE_WO_ADMIN_FEE] = 0
		  ,[DAMAGE_ADMIN_FEE] = 0
		  ,[DED_WO_ADMIN_FEE] = 0
		  ,[DED_ADMIN_FEE] = 0
		  ,[PAY_ENTIRE_BILL]  = 'N'
		  ,[PAY_ALL_TAXES] = 'Y'
		  ,[PAY_RATE_PER_DAY] = 'N'
		  ,[PAY_SURCHARGE] = 'N'
		  ,[PAY_GST_HST] = 'Y'
		  ,[MONTHLY_DAYS] = 0
		end
		
		ELSE
		BEGIN -- UPDATE MDA DEBITOR_FLAGS
		UPDATE MARITIMESLIVE..DEBITOR_PAY_FLAGS SET 
		   --[AUTHRIZATION_NO] = @MultipleDebitorAuthNo
		  [PAY_RENTAL] = 'Y'
		  ,[PAY_EXTENSION]= ''
		  ,[PAY_UPSELL]= ''
		  ,[PAY_KM]= 'N'
		  ,[PAY_FUEL]= 'N'
		  ,[PAY_DAMAGE]= 'N'
		  ,[PAY_TRAFFIC]= 'N'
		  ,[PAY_AIRPORTFEE]= 'N'
		  ,[PAY_DROPOFFFEE]= 'N'
		  ,[PAY_DELIVERY]= 'N'
		  ,[PAY_PICKUP]= 'N'
		  ,[PAY_INS]= CASE WHEN @CDW > 0 THEN 'Y' ELSE 'N' END
		  ,[PAY_EXT]= 'Y'
		  ,[PAY_OTHER]= 'N'
		  ,[GET_RED]= 'Y'
		  ,[PAY_SERVICE]= CASE WHEN @PST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_VAT]= CASE WHEN @GSTorHST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_TELEPHONE]= ''
		  ,[PAY_DEDUACTABLE]= ''
		  ,[PAY_HIGH_WAY_TICKET]= ''
		  ,[PAY_HIGHWAYADMIN]= ''
		  ,[CREATED_FROM]= ''
		  ,[AGREEMENT_NO]= @AgreementNo
		  ,[DEBITOR_CODE]= @debitor_code
		  ,[SEPARATE_DAMAGE_INVOICE]= ''
		  ,[SEPARATE_TRAFFIC_INVOICE] = ''
		  ,[PREBILLING_IN_ADVANCE]= ''
		  ,[BILLTO_END_OF_MONTH]= ''
		  ,[PREBILLING_INVOICE_METHOD]= ''
		  ,[REQUIRE_VOUCHER_CONFIRMATION]= ''
		  ,[COMBINATION_PREBILLING]= ''
		  ,[FULLY_AUTHORIZE]= ''
		  ,[COMBINATION_INVOICE]= ''
		  ,[COMB_DAMGE_INVOICE]= ''
		  ,[COMB_TRAFFIC_INVOICE]= ''
		  ,[COMB_HIGHWAY_INVOICE]= ''
		  ,[PREBILLING_CHARGE_KM]= ''
		  ,[RENTAL_BEFORE_DISCOUNT]=  @MDA_Authrate * @TotalAuthDays
		  ,[RENTAL_EXT_BEFORE_DISCOUNT]= ''
		  ,[KM_PRICE_BEFORE_DISCOUNT]= ''
		  ,[RENTAL_VAT_AMOUNT]= @Old_VAT+ @dTotalTaxes
		  ,[RENTAL_EXT_VAT_AMOUNT]= ''
		  ,[INS_SUM_BEFORE_DISCOUNT]= @Insurances_Price+@dTotalInsurances
		  ,[INS_SUM_BEFORE_DIS_WITHOUTVAT]= ''
		  ,[KM_VAT_AMOUNT]= ''
		  ,[CUST_TRAFFIC_ADMIN_FEE]= ''
		  ,[AIRPORT_VAT_AMOUNT]= ''
		  ,[DROPOFF_VAT_AMOUNT]= ''
		  ,[FUEL_VAT_AMOUNT]= ''
		  ,[DELIVERY_VAT_AMOUNT]= ''
		  ,[PICKKUP_VAT_AMOUNT]= ''
		  ,[OTHERSUM_VAT_AMOUNT]= ''
		  ,[REDUCTION_VAT_AMOUNT]= ''
		  ,[DAMAGES_VAT_AMOUNT]= ''
		  ,[DEDUCTIBLE_VAT_AMOUNT]= ''
		  ,[TRAFFIC_VAT_AMOUNT]= ''
		  ,[INS_VAT_AMOUNT]= ((@Insurances_Price+@dTotalInsurances) * @GSTorHST) / 100
		  ,[EXTRAS_VAT_AMOUNT]= ((@Extras_Price+@dTotalExtras) * @GSTorHST) / 100
		  ,[DISCOUNT_VAT_AMOUNT]= ''
		  ,[RENTAL_SERVICE_AMOUNT]= @Old_SERVICE_FEE + 0.00
		  ,[RENTALEXT_SERVICE_AMOUNT]= ''
		  ,[KM_SERVICE_AMOUNT]= ''
		  ,[AIRPORT_SERVICE_AMOUNT]= ''
		  ,[DROPOFF_SERVICE_AMOUNT]= ''
		  ,[FUEL_SERVICE_AMOUNT]= ''
		  ,[DELIVERY_SERVICE_AMOUNT]= ''
		  ,[PICKUP_SERVICE_AMOUNT]= ''
		  ,[OTHERSUM_SERVICE_AMOUNT]= ''
		  ,[REDUCTION_SERVICE_AMOUNT]= ''
		  ,[DAMAGES_SERVICE_AMOUNT]= ''
		  ,[DEDCTIBLE_SERVICE_AMOUNT]= ''
		  ,[TRAFFIC_SERVICE_AMOUNT] = 0
		  ,[INS_SERVICE_AMOUNT] = 0
		  ,[EXTRAS_SERVICE_AMOUNT] = 0
		  ,[DISCOUNT_SERVICE_AMOUNT] = 0
		  ,[PACKAGE_PRICE] = 0
		  ,[PACKAGE_EXT_PRICE] = 0
		  ,[KM_PRICE] = 0
		  ,[RENTAL_DISCOUNT_AMOUNT] = 0
		  ,[RENTAL_EXT_DISCOUNT_SUM] = 0
		  ,[KM_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISC_AMOUNT_WT_OUT_VAT] = 0
		  ,[TOTAL_DISCOUNT_AMOUNT] = 0
		  ,[NON_TAXBLE_AMOUNT] = 0
		  ,[NON_SERVICABLE_AMOUNT] = 0
		  ,[PACKAGE_DAYS] = 0
		  ,[PACKAGE_ADD_DAYS] = 0
		  ,[EXTENSION_DAYS] = 0
		  ,[TRAFFIC_ADMIN_FEE_VAT_AMT] = 0
		  ,[TRAFFIC_ADMIN_FEE_SERVICE_AMT] = 0
		  ,[TRAFFIC_AMT_WO_ADMIN_FEE] = 0
		  ,[BILLING_FREQUENCY] = 0
		  ,[SEPARATE_REPLACEMENT_INV] = 'N'
		  ,[SEPARATE_FUEL_INV] = 'N'
		  ,[COMB_FUEL_INVOICE] = 'N'
		  ,[INVOICE_BY] = 'A'
		  ,[PAY_TOLL] =  'N'
		  ,[SEPARATE_TOLL_INVOICE] = 'N'
		  ,[TOLL_WO_ADMIN_FEE] = 0
		  ,[TOLL_ADMIN_FEE] = 0
		  ,[TOLL_VAT_AMT] = 0
		  ,[TOLL_SERVICE_AMT] = 0
		  ,[TOLL_ADMIN_FEEPER_SETUP] = 0
		  ,[TOLL_ADMIN_FEEAMT_SETUP] = 0
		  ,[DAMAGE_WO_ADMIN_FEE] = 0
		  ,[DAMAGE_ADMIN_FEE] = 0
		  ,[DED_WO_ADMIN_FEE] = 0
		  ,[DED_ADMIN_FEE] = 0
		  ,[PAY_ENTIRE_BILL]  = 'N'
		  ,[PAY_ALL_TAXES] = 'Y'
		  ,[PAY_RATE_PER_DAY] = 'N'
		  ,[PAY_SURCHARGE] = 'N'
		  ,[PAY_GST_HST] = 'Y'
		  ,[MONTHLY_DAYS] = 0
		  WHERE [AUTHRIZATION_NO] = @MultipleDebitorAuthNo AND DEBITOR_CODE=@debitor_code AND AGREEMENT_NO=@AgreementNo
		  END
				
			UPDATE DA_CLAIMS SET  DAC_RATE_OUT = ISNULL(@MDA_Authrate, 0), INS_COMP_AUTH_DAYS = @MDA_TotalDays WHERE DAC_ENTRY_ID = @RemedyEntryId	
			end
			ELSE
			BEGIN --create MDA						
			-------------------------------  AUTHORIZATION NO FOR MULTIPLE DEBITOR AUTH | AUTHORIZATION_AGR_RES    -------------------------------------
			
			SELECT @iDocNobigint =DN_DOCUMENT_NUMBER+1 from DOCUMENT_NUMBERS b(nolock) WHERE DN_COMPANY_CODE = 1 AND DN_BRANCH_CODE = 0 AND DN_DOCUMENT_TYPE = 12		
			
			if exists( select AUTHORIZATION_NO from MARITIMESLIVE..MULTIPLE_DEBITOR_AUTH(nolock)	where  convert(bigint,AUTHORIZATION_NO)	=@iDocNobigint)
			begin	
				while exists( select AUTHORIZATION_NO from MARITIMESLIVE..MULTIPLE_DEBITOR_AUTH(nolock)	where  convert(bigint,AUTHORIZATION_NO)	=@iDocNobigint)
				begin
					
					if not exists( select AUTHORIZATION_NO from MARITIMESLIVE..MULTIPLE_DEBITOR_AUTH(nolock)	where  convert(bigint,AUTHORIZATION_NO)	=@iDocNobigint)
						break
						
					select @iDocNobigint= @iDocNobigint + 1
				end
			end
			
			select @MultipleDebitorAuthNo= RIGHT( convert(varchar(20),@iDocNobigint + 10000000000000000),15)				
							
			UPDATE DOCUMENT_NUMBERS SET  DN_DOCUMENT_NUMBER = @iDocNobigint 
			WHERE DN_COMPANY_CODE = @CompanyCode AND DN_BRANCH_CODE = 0 AND DN_DOCUMENT_TYPE = 12 		
			-----------------------------------------END----------------------------------------------------------------------------------------------------
			INSERT INTO MARITIMESLIVE..MULTIPLE_DEBITOR_AUTH
			(AGREEMENT,
			RESERVATION_NO,
			DEBITOR_CODE,
			AUTHORIZATION_NO,
			DAYS,
			AGENTCOMMEXTERNV,
			F_GROUP,
			RENTAL_PACKAGE,
			Sold_Days,
			LOSS_DATE,
			CURRENCY,
			PER_DAY_PRICE,
			RATE_SR_NO,
			RATE_DET_SR_NO,
			VAT_PERCENT,
			SERVICE_FEE_PERCENT,
			RENTAL_PRICE,
			INSURANCES_PRICE,
			EXTRAS_PRICE,
			AMOUNT,
			TAXABLE_SUM,
			SERVICABLE_SUM,
			SALES_TAX,
			SERVICE_TAX,
			EXCHANGE_RATE,
			SUBTOTAL,
			FIRST_CHARGE_GROUP,
			FIRST_NO_OF_DAYS,
			FIRST_RENTAL_PACKAGE,
			FIRST_RATE_SR_NO,
			FIRST_RATE_DET_SR_NO,
			FIRST_PER_DAY_PRICE,
			BODY_SHOP_DIFF_FLAT_AMT,
			BODY_SHOP_DIFF_DAYS,
			MAX_AMOUNT,
			MAX_AMOUNT_CREDIT,
			claim_no,
			RATE_NO 
			)
			SELECT
			AGREEMENT = @AgreementNo,
			RESERVATION_NO = @ReservationNo,
			DEBITOR_CODE = @Debitor_Code,
			AUTHORIZATION_NO = @MultipleDebitorAuthNo,
			DAYS = @DaysAuthorized,
			AGENTCOMMEXTERNV = 'O',
			F_GROUP = @Authorized_VehicleCategory,
			RENTAL_PACKAGE = @Rental_Package,
			Sold_Days = @DaysAuthorized,
			LOSS_DATE = '00000000',
			CURRENCY = 'CAD',
			PER_DAY_PRICE = @Authorizedrate,
			RATE_SR_NO = @RATE_SR_NO,
			RATE_DET_SR_NO = @RATE_DET_SR_NO,
			VAT_PERCENT = @GSTorHST,
			SERVICE_FEE_PERCENT = @PST,
			RENTAL_PRICE = (@Authorizedrate)  * @DaysAuthorized, --0.00,
			INSURANCES_PRICE = @dTotalInsurances , --0.00,
			EXTRAS_PRICE = @dTotalExtras,
			AMOUNT = @dFinalTotal,
			TAXABLE_SUM = (@Authorizedrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @DaysAuthorized ,
			SERVICABLE_SUM = 0.00,
			SALES_TAX = @dTotalTaxes,
			SERVICE_TAX = 0.00,
			EXCHANGE_RATE = 1,
			SUBTOTAL = (@Authorizedrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @DaysAuthorized,
			FIRST_CHARGE_GROUP = @Authorized_VehicleCategory,
			FIRST_NO_OF_DAYS = @DaysAuthorized,
			FIRST_RENTAL_PACKAGE = @Rental_Package,
			FIRST_RATE_SR_NO = @RATE_SR_NO,
			FIRST_RATE_DET_SR_NO = @RATE_DET_SR_NO,
			FIRST_PER_DAY_PRICE = @Authorizedrate,
			BODY_SHOP_DIFF_FLAT_AMT  = 0.00,
			BODY_SHOP_DIFF_DAYS = 0,
			MAX_AMOUNT = @MaxAmount,
			MAX_AMOUNT_CREDIT = 0,
			claim_no = @RemedyEntryID,
			RATE_NO = isnull(@RateNo, 0)			
			
			if not exists
			(select 1 from MARITIMESLIVE..DEBITOR_PAY_FLAGS (nolock) where AUTHRIZATION_NO = @MultipleDebitorAuthNo --AND AGREEMENT_NO=@AGREEMENTNO AND DEBITOR_CODE=@debitor_code
			)							
			begin
			insert into MARITIMESLIVE..DEBITOR_PAY_FLAGS (
			[AUTHRIZATION_NO]
			,[PAY_RENTAL]
			,[PAY_EXTENSION]
			,[PAY_UPSELL]
			,[PAY_KM]
			,[PAY_FUEL]		
			,[PAY_DAMAGE]
			,[PAY_TRAFFIC]
			,[PAY_AIRPORTFEE]
			,[PAY_DROPOFFFEE]
			,[PAY_DELIVERY]
			,[PAY_PICKUP]
			,[PAY_INS]
			,[PAY_EXT]
			,[PAY_OTHER]
			,[GET_RED]
			,[PAY_SERVICE]
			,[PAY_VAT]
			,[PAY_TELEPHONE]
			,[PAY_DEDUACTABLE]
			,[PAY_HIGH_WAY_TICKET]
			,[PAY_HIGHWAYADMIN]
			,[CREATED_FROM]
			,[AGREEMENT_NO]
			,[DEBITOR_CODE]
			,[SEPARATE_DAMAGE_INVOICE]
			,[SEPARATE_TRAFFIC_INVOICE]
			,[PREBILLING_IN_ADVANCE]
			,[BILLTO_END_OF_MONTH]
			,[PREBILLING_INVOICE_METHOD]
			,[REQUIRE_VOUCHER_CONFIRMATION]
			,[COMBINATION_PREBILLING]
			,[FULLY_AUTHORIZE]
			,[COMBINATION_INVOICE]
			,[COMB_DAMGE_INVOICE]
			,[COMB_TRAFFIC_INVOICE]
			,[COMB_HIGHWAY_INVOICE]
			,[PREBILLING_CHARGE_KM]
			,[RENTAL_BEFORE_DISCOUNT]
			,[RENTAL_EXT_BEFORE_DISCOUNT]
			,[KM_PRICE_BEFORE_DISCOUNT]
			,[RENTAL_VAT_AMOUNT]
			,[RENTAL_EXT_VAT_AMOUNT]
			,[INS_SUM_BEFORE_DISCOUNT]
			,[INS_SUM_BEFORE_DIS_WITHOUTVAT]
			,[KM_VAT_AMOUNT]
			,[CUST_TRAFFIC_ADMIN_FEE]
			,[AIRPORT_VAT_AMOUNT]
			,[DROPOFF_VAT_AMOUNT]
			,[FUEL_VAT_AMOUNT]
			,[DELIVERY_VAT_AMOUNT]
			,[PICKKUP_VAT_AMOUNT]
			,[OTHERSUM_VAT_AMOUNT]
			,[REDUCTION_VAT_AMOUNT]
			,[DAMAGES_VAT_AMOUNT]
			,[DEDUCTIBLE_VAT_AMOUNT]
			,[TRAFFIC_VAT_AMOUNT]
			,[INS_VAT_AMOUNT]
			,[EXTRAS_VAT_AMOUNT]
			,[DISCOUNT_VAT_AMOUNT]
			,[RENTAL_SERVICE_AMOUNT]
			,[RENTALEXT_SERVICE_AMOUNT]
			,[KM_SERVICE_AMOUNT]
			,[AIRPORT_SERVICE_AMOUNT]
			,[DROPOFF_SERVICE_AMOUNT]
			,[FUEL_SERVICE_AMOUNT]
			,[DELIVERY_SERVICE_AMOUNT]
			,[PICKUP_SERVICE_AMOUNT]
			,[OTHERSUM_SERVICE_AMOUNT]
			,[REDUCTION_SERVICE_AMOUNT]
			,[DAMAGES_SERVICE_AMOUNT]
			,[DEDCTIBLE_SERVICE_AMOUNT]
			,[TRAFFIC_SERVICE_AMOUNT]
			,[INS_SERVICE_AMOUNT]
			,[EXTRAS_SERVICE_AMOUNT]
			,[DISCOUNT_SERVICE_AMOUNT]
			,[PACKAGE_PRICE]
			,[PACKAGE_EXT_PRICE]
			,[KM_PRICE]
			,[RENTAL_DISCOUNT_AMOUNT]
			,[RENTAL_EXT_DISCOUNT_SUM]
			,[KM_DISCOUNT_AMOUNT]
			,[INS_DISCOUNT_AMOUNT]
			,[INS_DISC_AMOUNT_WT_OUT_VAT]
			,[TOTAL_DISCOUNT_AMOUNT]
			,[NON_TAXBLE_AMOUNT]
			,[NON_SERVICABLE_AMOUNT]
			,[PACKAGE_DAYS]
			,[PACKAGE_ADD_DAYS]
			,[EXTENSION_DAYS]
			,[TRAFFIC_ADMIN_FEE_VAT_AMT]
			,[TRAFFIC_ADMIN_FEE_SERVICE_AMT]
			,[TRAFFIC_AMT_WO_ADMIN_FEE]
			,[BILLING_FREQUENCY]
			,[SEPARATE_REPLACEMENT_INV]
			,[SEPARATE_FUEL_INV]
			,[COMB_FUEL_INVOICE]
			,[INVOICE_BY]
			,[PAY_TOLL]
			,[SEPARATE_TOLL_INVOICE]
			,[TOLL_WO_ADMIN_FEE]
			,[TOLL_ADMIN_FEE]
			,[TOLL_VAT_AMT]
			,[TOLL_SERVICE_AMT]
			,[TOLL_ADMIN_FEEPER_SETUP]
			,[TOLL_ADMIN_FEEAMT_SETUP]
			,[DAMAGE_WO_ADMIN_FEE]
			,[DAMAGE_ADMIN_FEE]
			,[DED_WO_ADMIN_FEE]
			,[DED_ADMIN_FEE]
			,[PAY_ENTIRE_BILL]
			,[PAY_ALL_TAXES]
			,[PAY_RATE_PER_DAY]
			,[PAY_SURCHARGE]
			,[PAY_GST_HST]
			,[MONTHLY_DAYS]
			)

		   select 
		   [AUTHRIZATION_NO] = @MultipleDebitorAuthNo
		  ,[PAY_RENTAL] = 'Y'
		  ,[PAY_EXTENSION]= ''
		  ,[PAY_UPSELL]= ''
		  ,[PAY_KM]= 'N'
		  ,[PAY_FUEL]= 'N'
		  ,[PAY_DAMAGE]= 'N'
		  ,[PAY_TRAFFIC]= 'N'
		  ,[PAY_AIRPORTFEE]= 'N'
		  ,[PAY_DROPOFFFEE]= 'N'
		  ,[PAY_DELIVERY]= 'N'
		  ,[PAY_PICKUP]= 'N'
		  ,[PAY_INS]= CASE WHEN @CDW > 0 THEN 'Y' ELSE 'N' END
		  ,[PAY_EXT]= 'Y'
		  ,[PAY_OTHER]= 'N'
		  ,[GET_RED]= 'Y'
		  ,[PAY_SERVICE]= CASE WHEN @PST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_VAT]= CASE WHEN @GSTorHST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_TELEPHONE]= ''
		  ,[PAY_DEDUACTABLE]= ''
		  ,[PAY_HIGH_WAY_TICKET]= ''
		  ,[PAY_HIGHWAYADMIN]= ''
		  ,[CREATED_FROM]= ''
		  ,[AGREEMENT_NO]= @AgreementNo
		  ,[DEBITOR_CODE]= @debitor_code
		  ,[SEPARATE_DAMAGE_INVOICE]= ''
		  ,[SEPARATE_TRAFFIC_INVOICE] = ''
		  ,[PREBILLING_IN_ADVANCE]= ''
		  ,[BILLTO_END_OF_MONTH]= ''
		  ,[PREBILLING_INVOICE_METHOD]= ''
		  ,[REQUIRE_VOUCHER_CONFIRMATION]= ''
		  ,[COMBINATION_PREBILLING]= ''
		  ,[FULLY_AUTHORIZE]= ''
		  ,[COMBINATION_INVOICE]= ''
		  ,[COMB_DAMGE_INVOICE]= ''
		  ,[COMB_TRAFFIC_INVOICE]= ''
		  ,[COMB_HIGHWAY_INVOICE]= ''
		  ,[PREBILLING_CHARGE_KM]= ''
		  ,[RENTAL_BEFORE_DISCOUNT]=  @MDA_Authrate * @TotalAuthDays
		  ,[RENTAL_EXT_BEFORE_DISCOUNT]= ''
		  ,[KM_PRICE_BEFORE_DISCOUNT]= ''
		  ,[RENTAL_VAT_AMOUNT]= @Old_VAT+ @dTotalTaxes
		  ,[RENTAL_EXT_VAT_AMOUNT]= ''
		  ,[INS_SUM_BEFORE_DISCOUNT]= @Insurances_Price+@dTotalInsurances
		  ,[INS_SUM_BEFORE_DIS_WITHOUTVAT]= ''
		  ,[KM_VAT_AMOUNT]= ''
		  ,[CUST_TRAFFIC_ADMIN_FEE]= ''
		  ,[AIRPORT_VAT_AMOUNT]= ''
		  ,[DROPOFF_VAT_AMOUNT]= ''
		  ,[FUEL_VAT_AMOUNT]= ''
		  ,[DELIVERY_VAT_AMOUNT]= ''
		  ,[PICKKUP_VAT_AMOUNT]= ''
		  ,[OTHERSUM_VAT_AMOUNT]= ''
		  ,[REDUCTION_VAT_AMOUNT]= ''
		  ,[DAMAGES_VAT_AMOUNT]= ''
		  ,[DEDUCTIBLE_VAT_AMOUNT]= ''
		  ,[TRAFFIC_VAT_AMOUNT]= ''
		  ,[INS_VAT_AMOUNT]= ((@Insurances_Price+@dTotalInsurances) * @GSTorHST) / 100
		  ,[EXTRAS_VAT_AMOUNT]= ((@Extras_Price+@dTotalExtras) * @GSTorHST) / 100
		  ,[DISCOUNT_VAT_AMOUNT]= ''
		  ,[RENTAL_SERVICE_AMOUNT]= @Old_SERVICE_FEE + 0.00
		  ,[RENTALEXT_SERVICE_AMOUNT]= ''
		  ,[KM_SERVICE_AMOUNT]= ''
		  ,[AIRPORT_SERVICE_AMOUNT]= ''
		  ,[DROPOFF_SERVICE_AMOUNT]= ''
		  ,[FUEL_SERVICE_AMOUNT]= ''
		  ,[DELIVERY_SERVICE_AMOUNT]= ''
		  ,[PICKUP_SERVICE_AMOUNT]= ''
		  ,[OTHERSUM_SERVICE_AMOUNT]= ''
		  ,[REDUCTION_SERVICE_AMOUNT]= ''
		  ,[DAMAGES_SERVICE_AMOUNT]= ''
		  ,[DEDCTIBLE_SERVICE_AMOUNT]= ''
		  ,[TRAFFIC_SERVICE_AMOUNT] = 0
		  ,[INS_SERVICE_AMOUNT] = 0
		  ,[EXTRAS_SERVICE_AMOUNT] = 0
		  ,[DISCOUNT_SERVICE_AMOUNT] = 0
		  ,[PACKAGE_PRICE] = 0
		  ,[PACKAGE_EXT_PRICE] = 0
		  ,[KM_PRICE] = 0
		  ,[RENTAL_DISCOUNT_AMOUNT] = 0
		  ,[RENTAL_EXT_DISCOUNT_SUM] = 0
		  ,[KM_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISC_AMOUNT_WT_OUT_VAT] = 0
		  ,[TOTAL_DISCOUNT_AMOUNT] = 0
		  ,[NON_TAXBLE_AMOUNT] = 0
		  ,[NON_SERVICABLE_AMOUNT] = 0
		  ,[PACKAGE_DAYS] = 0
		  ,[PACKAGE_ADD_DAYS] = 0
		  ,[EXTENSION_DAYS] = 0
		  ,[TRAFFIC_ADMIN_FEE_VAT_AMT] = 0
		  ,[TRAFFIC_ADMIN_FEE_SERVICE_AMT] = 0
		  ,[TRAFFIC_AMT_WO_ADMIN_FEE] = 0
		  ,[BILLING_FREQUENCY] = 0
		  ,[SEPARATE_REPLACEMENT_INV] = 'N'
		  ,[SEPARATE_FUEL_INV] = 'N'
		  ,[COMB_FUEL_INVOICE] = 'N'
		  ,[INVOICE_BY] = 'A'
		  ,[PAY_TOLL] =  'N'
		  ,[SEPARATE_TOLL_INVOICE] = 'N'
		  ,[TOLL_WO_ADMIN_FEE] = 0
		  ,[TOLL_ADMIN_FEE] = 0
		  ,[TOLL_VAT_AMT] = 0
		  ,[TOLL_SERVICE_AMT] = 0
		  ,[TOLL_ADMIN_FEEPER_SETUP] = 0
		  ,[TOLL_ADMIN_FEEAMT_SETUP] = 0
		  ,[DAMAGE_WO_ADMIN_FEE] = 0
		  ,[DAMAGE_ADMIN_FEE] = 0
		  ,[DED_WO_ADMIN_FEE] = 0
		  ,[DED_ADMIN_FEE] = 0
		  ,[PAY_ENTIRE_BILL]  = 'N'
		  ,[PAY_ALL_TAXES] = 'Y'
		  ,[PAY_RATE_PER_DAY] = 'N'
		  ,[PAY_SURCHARGE] = 'N'
		  ,[PAY_GST_HST] = 'Y'
		  ,[MONTHLY_DAYS] = 0
		end
		else
		begin
		   update  MARITIMESLIVE..DEBITOR_PAY_FLAGS set 
		   [AUTHRIZATION_NO] = @MultipleDebitorAuthNo
		  ,[PAY_RENTAL] = 'Y'
		  ,[PAY_EXTENSION]= ''
		  ,[PAY_UPSELL]= ''
		  ,[PAY_KM]= 'N'
		  ,[PAY_FUEL]= 'N'
		  ,[PAY_DAMAGE]= 'N'
		  ,[PAY_TRAFFIC]= 'N'
		  ,[PAY_AIRPORTFEE]= 'N'
		  ,[PAY_DROPOFFFEE]= 'N'
		  ,[PAY_DELIVERY]= 'N'
		  ,[PAY_PICKUP]= 'N'
		  ,[PAY_INS]= CASE WHEN @CDW > 0 THEN 'Y' ELSE 'N' END
		  ,[PAY_EXT]= 'Y'
		  ,[PAY_OTHER]= 'N'
		  ,[GET_RED]= 'Y'
		  ,[PAY_SERVICE]= CASE WHEN @PST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_VAT]= CASE WHEN @GSTorHST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_TELEPHONE]= ''
		  ,[PAY_DEDUACTABLE]= ''
		  ,[PAY_HIGH_WAY_TICKET]= ''
		  ,[PAY_HIGHWAYADMIN]= ''
		  ,[CREATED_FROM]= ''
		  ,[AGREEMENT_NO]= @AgreementNo
		  ,[DEBITOR_CODE]= @debitor_code
		  ,[SEPARATE_DAMAGE_INVOICE]= ''
		  ,[SEPARATE_TRAFFIC_INVOICE] = ''
		  ,[PREBILLING_IN_ADVANCE]= ''
		  ,[BILLTO_END_OF_MONTH]= ''
		  ,[PREBILLING_INVOICE_METHOD]= ''
		  ,[REQUIRE_VOUCHER_CONFIRMATION]= ''
		  ,[COMBINATION_PREBILLING]= ''
		  ,[FULLY_AUTHORIZE]= ''
		  ,[COMBINATION_INVOICE]= ''
		  ,[COMB_DAMGE_INVOICE]= ''
		  ,[COMB_TRAFFIC_INVOICE]= ''
		  ,[COMB_HIGHWAY_INVOICE]= ''
		  ,[PREBILLING_CHARGE_KM]= ''
		  ,[RENTAL_BEFORE_DISCOUNT]=  @MDA_Authrate * @TotalAuthDays
		  ,[RENTAL_EXT_BEFORE_DISCOUNT]= ''
		  ,[KM_PRICE_BEFORE_DISCOUNT]= ''
		  ,[RENTAL_VAT_AMOUNT]= @Old_VAT+ @dTotalTaxes
		  ,[RENTAL_EXT_VAT_AMOUNT]= ''
		  ,[INS_SUM_BEFORE_DISCOUNT]= @Insurances_Price+@dTotalInsurances
		  ,[INS_SUM_BEFORE_DIS_WITHOUTVAT]= ''
		  ,[KM_VAT_AMOUNT]= ''
		  ,[CUST_TRAFFIC_ADMIN_FEE]= ''
		  ,[AIRPORT_VAT_AMOUNT]= ''
		  ,[DROPOFF_VAT_AMOUNT]= ''
		  ,[FUEL_VAT_AMOUNT]= ''
		  ,[DELIVERY_VAT_AMOUNT]= ''
		  ,[PICKKUP_VAT_AMOUNT]= ''
		  ,[OTHERSUM_VAT_AMOUNT]= ''
		  ,[REDUCTION_VAT_AMOUNT]= ''
		  ,[DAMAGES_VAT_AMOUNT]= ''
		  ,[DEDUCTIBLE_VAT_AMOUNT]= ''
		  ,[TRAFFIC_VAT_AMOUNT]= ''
		  ,[INS_VAT_AMOUNT]= ((@Insurances_Price+@dTotalInsurances) * @GSTorHST) / 100
		  ,[EXTRAS_VAT_AMOUNT]= ((@Extras_Price+@dTotalExtras) * @GSTorHST) / 100
		  ,[DISCOUNT_VAT_AMOUNT]= ''
		  ,[RENTAL_SERVICE_AMOUNT]= @Old_SERVICE_FEE + 0.00
		  ,[RENTALEXT_SERVICE_AMOUNT]= ''
		  ,[KM_SERVICE_AMOUNT]= ''
		  ,[AIRPORT_SERVICE_AMOUNT]= ''
		  ,[DROPOFF_SERVICE_AMOUNT]= ''
		  ,[FUEL_SERVICE_AMOUNT]= ''
		  ,[DELIVERY_SERVICE_AMOUNT]= ''
		  ,[PICKUP_SERVICE_AMOUNT]= ''
		  ,[OTHERSUM_SERVICE_AMOUNT]= ''
		  ,[REDUCTION_SERVICE_AMOUNT]= ''
		  ,[DAMAGES_SERVICE_AMOUNT]= ''
		  ,[DEDCTIBLE_SERVICE_AMOUNT]= ''
		  ,[TRAFFIC_SERVICE_AMOUNT] = 0
		  ,[INS_SERVICE_AMOUNT] = 0
		  ,[EXTRAS_SERVICE_AMOUNT] = 0
		  ,[DISCOUNT_SERVICE_AMOUNT] = 0
		  ,[PACKAGE_PRICE] = 0
		  ,[PACKAGE_EXT_PRICE] = 0
		  ,[KM_PRICE] = 0
		  ,[RENTAL_DISCOUNT_AMOUNT] = 0
		  ,[RENTAL_EXT_DISCOUNT_SUM] = 0
		  ,[KM_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISC_AMOUNT_WT_OUT_VAT] = 0
		  ,[TOTAL_DISCOUNT_AMOUNT] = 0
		  ,[NON_TAXBLE_AMOUNT] = 0
		  ,[NON_SERVICABLE_AMOUNT] = 0
		  ,[PACKAGE_DAYS] = 0
		  ,[PACKAGE_ADD_DAYS] = 0
		  ,[EXTENSION_DAYS] = 0
		  ,[TRAFFIC_ADMIN_FEE_VAT_AMT] = 0
		  ,[TRAFFIC_ADMIN_FEE_SERVICE_AMT] = 0
		  ,[TRAFFIC_AMT_WO_ADMIN_FEE] = 0
		  ,[BILLING_FREQUENCY] = 0
		  ,[SEPARATE_REPLACEMENT_INV] = 'N'
		  ,[SEPARATE_FUEL_INV] = 'N'
		  ,[COMB_FUEL_INVOICE] = 'N'
		  ,[INVOICE_BY] = 'A'
		  ,[PAY_TOLL] =  'N'
		  ,[SEPARATE_TOLL_INVOICE] = 'N'
		  ,[TOLL_WO_ADMIN_FEE] = 0
		  ,[TOLL_ADMIN_FEE] = 0
		  ,[TOLL_VAT_AMT] = 0
		  ,[TOLL_SERVICE_AMT] = 0
		  ,[TOLL_ADMIN_FEEPER_SETUP] = 0
		  ,[TOLL_ADMIN_FEEAMT_SETUP] = 0
		  ,[DAMAGE_WO_ADMIN_FEE] = 0
		  ,[DAMAGE_ADMIN_FEE] = 0
		  ,[DED_WO_ADMIN_FEE] = 0
		  ,[DED_ADMIN_FEE] = 0
		  ,[PAY_ENTIRE_BILL]  = 'N'
		  ,[PAY_ALL_TAXES] = 'Y'
		  ,[PAY_RATE_PER_DAY] = 'N'
		  ,[PAY_SURCHARGE] = 'N'
		  ,[PAY_GST_HST] = 'Y'
		  ,[MONTHLY_DAYS] = 0
		  where [AUTHRIZATION_NO] = @MultipleDebitorAuthNo AND AGREEMENT_NO=@AGREEMENTNO AND DEBITOR_CODE=@debitor_code
		end	
			END--end to create MDA	
		END
						
		--(@agreementno > 0  and @Agreement_Status_Code  in (0,1,2,3)) or (@ReservationNo != '' and @agreementno=0)
		
		if not exists 
		(select AUTHORIZATION_NO from MARITIMESLIVE..AUTHORIZATION_AGR_RES (nolock) where AUTHORIZATION_NO=@MultipleDebitorAuthNo AND FROM_DATE=@AuthFromDate AND FROM_TIME = @AuthFromTime)		
		begin
		INSERT INTO MARITIMESLIVE..AUTHORIZATION_AGR_RES(AUTHORIZATION_NO,FROM_DATE,FROM_TIME,AUTH_SERIAL,AGREEMENT_NO,CAR_GROUP,RATE_PER_DAY,AUTH_DAYS,RATE_SR_NO,RATE_DET_SR_NO,TO_DATE,TO_TIME)
		VALUES
		(@MultipleDebitorAuthNo,@AuthFromDate,@AuthFromTime, 
		isnull((SELECT (MAX(AUTH_SERIAL)) FROM MARITIMESLIVE..AUTHORIZATION_AGR_RES (NOLOCK) where AUTHORIZATION_NO=@MultipleDebitorAuthNo), 0)+1, @AgreementNo, @Authorized_VehicleCategory, 
		@Authorizedrate,@DaysAuthorized,@RATE_SR_NO,@RATE_DET_SR_NO,@AuthToDate, @AuthToTime)		
		END
			
		
		
		if @VLI_Rate > 0  and @AuthFromDate != '00000000'
		begin
			if not exists --VIREN INSISTEN ON FRIDAY NOV 29,2013 TO PUT 2 INSERTS STATEMENT ONE WITH 0 AND WITH AGREEMENTNO
			(select EXTRAS_CODE from MARITIMESLIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='VLI' and RESAUTHVOUCHER=@MultipleDebitorAuthNo and MASTER_AGREEMENT=0)		
			begin
				INSERT INTO MARITIMESLIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES
				(@MultipleDebitorAuthNo,'00000000','VLI', 0,0,'', @VLI_Rate, @VLI_Rate*@DaysAuthorized)
			end
				
			if not exists --VIREN INSISTEN ON FRIDAY NOV 29,2013 TO PUT 2 INSERTS STATEMENT ONE WITH 0 AND WITH AGREEMENTNO
			(select EXTRAS_CODE from MARITIMESLIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='VLI' and RESAUTHVOUCHER='' and MASTER_AGREEMENT=@AgreementNo)		
			begin	
				INSERT INTO MARITIMESLIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES
				('','00000000','VLI', @AgreementNo,1,'', @VLI_Rate, @VLI_Rate*@DaysAuthorized)
			end
		end
			
		if @UF > 0  and @AuthFromDate != '00000000'
		begin
			if not exists 
			(select EXTRAS_CODE from MARITIMESLIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='UF' and RESAUTHVOUCHER=@MultipleDebitorAuthNo and MASTER_AGREEMENT=0)		
			begin			
				INSERT INTO MARITIMESLIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES(@MultipleDebitorAuthNo,'00000000' ,'UF', 0, 0, '' ,@UF, @UF*@DaysAuthorized)
			end
			
			if not exists --VIREN INSISTEN ON FRIDAY NOV 29,2013 TO PUT 2 INSERTS STATEMENT ONE WITH 0 AND WITH AGREEMENTNO
			(select EXTRAS_CODE from MARITIMESLIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='UF' and RESAUTHVOUCHER='' and MASTER_AGREEMENT=@AgreementNo)		
			begin					
				INSERT INTO MARITIMESLIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES('','00000000' ,'UF', @AgreementNo,1,'',@UF, @UF*@DaysAuthorized)
			end	
		end			

		if @WT > 0 and @AuthFromDate != '00000000'
		begin
			if not exists 
			(select EXTRAS_CODE from MARITIMESLIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='WT' and RESAUTHVOUCHER=@MultipleDebitorAuthNo)		
			begin
				INSERT INTO MARITIMESLIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES(@MultipleDebitorAuthNo,'00000000','WT', 0,0,'',@WT, @WT*@DaysAuthorized)	
			end		
			
			if not exists --VIREN INSISTEN ON FRIDAY NOV 29,2013 TO PUT 2 INSERTS STATEMENT ONE WITH 0 AND WITH AGREEMENTNO
			(select EXTRAS_CODE from MARITIMESLIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='WT' and RESAUTHVOUCHER='' and MASTER_AGREEMENT=@AgreementNo)		
			begin		
				INSERT INTO MARITIMESLIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES('','00000000','WT', @AgreementNo,1,'',@WT, @WT*@DaysAuthorized)							
			end
		end			

		if @CDW > 0 and @AuthFromDate != '00000000'
		begin
			if not exists 
			(select INSURANCE_CODE from MARITIMESLIVE..AGREEMENT_INSURANCES (nolock) where MASTER_AGREEMENT=0 and INSURANCE_CODE='CDW' and RESAUTHVOUCHER=@MultipleDebitorAuthNo)		
			begin
				INSERT INTO MARITIMESLIVE..AGREEMENT_INSURANCES(RESAUTHVOUCHER,INSURANCE_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,PRICE_PER_DAY, F_SUM)
				VALUES(@MultipleDebitorAuthNo,'CDW', @AgreementNo,0,'', @CDW, @CDW*@DaysAuthorized)	
			end
			
			if not exists 
			(select INSURANCE_CODE from MARITIMESLIVE..AGREEMENT_INSURANCES (nolock) where MASTER_AGREEMENT=@AgreementNo and INSURANCE_CODE='CDW' and RESAUTHVOUCHER='' and SUV_AGREEMENT=1)					
			begin	
				INSERT INTO MARITIMESLIVE..AGREEMENT_INSURANCES(RESAUTHVOUCHER,INSURANCE_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,PRICE_PER_DAY, F_SUM)
				VALUES('','CDW', @AgreementNo,1,'', @CDW, @CDW*@DaysAuthorized)				
			end
		--end	
		END	
		
						
		end --db
		
		
		
		if @DB = 'BCLIVE'
		BEGIN	
		if (@agreementno > 0  and @Agreement_Status_Code  in (0,1,2,3)) or (@ReservationNo != '' and @agreementno=0)
		begin		  
			select @MultipleDebitorAuthNo = AUTHORIZATION_NO,
			@RentalPrice = rental_price, @Insurances_Price = insurances_price , @Extras_Price = extras_price, @Insu_NonVat_Sum = Insu_NonVat_Sum,
			@KM_Sum = KM_Sum, @Airport_Fee = Airport_Fee, @DropOff_Fee = DropOff_Fee, @Fuel_Sum = Fuel_Sum, @Tel_Sum = Tel_Sum,
			@Delivery_Sum = Delivery_Sum, @Pickup_Sum = Pickup_Sum, @Other_Sum = Other_Sum, @Damages_Sum = Damages_Sum, 
			@Deductible_Sum = Deductible_Sum, @Traffic_Sum = Traffic_Sum, @Reduction_Sum = Reduction_Sum,
			@MDA_Max_Amt = MAX_AMOUNT , @Old_VAT = sales_tax,  @Old_SERVICE_FEE = service_tax , @MDA_TotalDays_Old = days, @Old_TotalAmount = amount 
			from BCLIVE..MULTIPLE_DEBITOR_AUTH (nolock) 
			where ((AGREEMENT = @AgreementNo and @AgreementNo >0) or (RESERVATION_NO = @ReservationNo and @agreementno=0)) 
			and debitor_code = @Debitor_Code AND @DCA_Bill_To != 2	
			  
		    if @Debitor_Code = @Third_Party_Debitor_Code 
			  set @MDA_Max_Amt = @Third_Party_policyMax
		    else                      						
			  set @MDA_Max_Amt = @PolicyMax
		  
		    select @MDA_Authrate = sum(DCA_AUTHOR_RATE*dca_a_days)/sum(dca_a_days), @MDA_TotalDays = sum(dca_a_days)  from da_authorization (nolock) where dca_Claim_id=@RemedyEntryId	
		    	  
		    select @RecID = isnull(REC_ID, 0)+1  from BCLIVE..AGREEMENT_LOG_FILE where MASTER_AGREEMENT = @AgreementNo

		    INSERT INTO BCLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
		    VALUES(@AgreementNo,'DIAL', @ModorCreateDate, @ModyorCreateTime,'Modify Auth From Claim','','','D',@RecID)		
		    INSERT INTO BCLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
		    VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Authorization Created: 0000000','',@ModorCreateDate,'D',@RecID+1)	
		    INSERT INTO BCLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
		    VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Charge Group','', @Authorized_VehicleCategory,'D',@RecID+2)		
		    INSERT INTO BCLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
		    VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Per Day Price','',@Authorizedrate,'D',@RecID+3)		
		    INSERT INTO BCLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
		    VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Rate Sr No.','',@RATE_SR_NO,'D',@RecID+4)		
			INSERT INTO BCLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
			VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Rate Det Sr No.','',@RATE_DET_SR_NO,'D',@RecID+5)		
			INSERT INTO BCLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
			VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Sold Days','',@RATE_SR_NO,'D',@RecID+6)				
			INSERT INTO BCLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
			VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Days',@MDA_TotalDays_Old, @MDA_TotalDays, 'D', @RecID+7)		
			INSERT INTO BCLIVE..AGREEMENT_LOG_FILE(MASTER_AGREEMENT,TUSR,TDAT,TTIM,FIELD_NAME,CHANGED_FROM,CHANGED_TO,Record_type,REC_ID)
			VALUES(@AgreementNo,'DIAL',@ModorCreateDate, @ModyorCreateTime,'Total Amount','',@RATE_DET_SR_NO,'D',@RecID+8)		
		
		--D - DATA	--T - TRANSACTION
		  
		if @MultipleDebitorAuthNo != '' --update
		BEGIN
				IF @ReservationNo != '' AND @AgreementNo = 0	-- reservation stage			
				begin
					UPDATE BCLIVE..MULTIPLE_DEBITOR_AUTH SET					
					RESERVATION_NO = @ReservationNo,
					DEBITOR_CODE = @Debitor_Code,
					AUTHORIZATION_NO = @MultipleDebitorAuthNo,
					DAYS = @MDA_TotalDays,							
					AGENTCOMMEXTERNV = 'O',
					F_GROUP = @Authorized_VehicleCategory,
					RENTAL_PACKAGE = @Rental_Package,
					Sold_Days = @MDA_TotalDays,
					LOSS_DATE = '00000000',
					CURRENCY = 'CAD',
					PER_DAY_PRICE = @MDA_Authrate,
					RATE_NO = isnull(@RateNo, 0), 
					RATE_SR_NO = @RATE_SR_NO,
					RATE_DET_SR_NO = @RATE_DET_SR_NO,
					VAT_PERCENT = @GSTorHST,
					SERVICE_FEE_PERCENT = @PST,
					RENTAL_PRICE = (@MDA_Authrate) * @MDA_TotalDays, --0.00,
					INSURANCES_PRICE = @Insurances_Price+@dTotalInsurances , --0.00,
					EXTRAS_PRICE = @Extras_Price+@dTotalExtras,
					AMOUNT = @Old_TotalAmount + @dFinalTotal,
					TAXABLE_SUM = (@MDA_Authrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @MDA_TotalDays ,
					SERVICABLE_SUM = 0.00,
					SALES_TAX = @Old_VAT+ @dTotalTaxes,
					SERVICE_TAX = @Old_SERVICE_FEE + 0.00,
					EXCHANGE_RATE = 1,
					SUBTOTAL = (@MDA_Authrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @MDA_TotalDays,
					MAX_AMOUNT = @MDA_Max_Amt,
					MAX_AMOUNT_CREDIT = @Tel_Sum,
					claim_no = @RemedyEntryID	
					WHERE RESERVATION_NO = @ReservationNo and AUTHORIZATION_NO = @MultipleDebitorAuthNo and DEBITOR_CODE = @Debitor_Code
				end
				
				IF @AgreementNo > 0				
				begin
					UPDATE BCLIVE..MULTIPLE_DEBITOR_AUTH SET 
					agreement = @AgreementNo,					
					RESERVATION_NO = @ReservationNo,
					DEBITOR_CODE = @Debitor_Code,
					AUTHORIZATION_NO = @MultipleDebitorAuthNo,
					DAYS = @MDA_TotalDays,							
					AGENTCOMMEXTERNV = 'O',
					F_GROUP = @Authorized_VehicleCategory,
					RENTAL_PACKAGE = @Rental_Package,
					Sold_Days = @MDA_TotalDays,
					LOSS_DATE = '00000000',
					CURRENCY = 'CAD',
					PER_DAY_PRICE = @MDA_Authrate,
					RATE_NO = isnull(@RateNo, 0), 
					RATE_SR_NO = @RATE_SR_NO,
					RATE_DET_SR_NO = @RATE_DET_SR_NO,
					VAT_PERCENT = @GSTorHST,
					SERVICE_FEE_PERCENT = @PST,
					RENTAL_PRICE = (@MDA_Authrate)  * @MDA_TotalDays, --0.00,
					INSURANCES_PRICE = @Insurances_Price+@dTotalInsurances , --0.00,
					EXTRAS_PRICE = @Extras_Price+@dTotalExtras,
					AMOUNT = @Old_TotalAmount + @dFinalTotal,
					TAXABLE_SUM = (@MDA_Authrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @MDA_TotalDays ,
					SERVICABLE_SUM = 0.00,
					SALES_TAX = @Old_VAT+ @dTotalTaxes,
					SERVICE_TAX = @Old_SERVICE_FEE + 0.00,
					EXCHANGE_RATE = 1,
					SUBTOTAL = (@MDA_Authrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @MDA_TotalDays,
					MAX_AMOUNT = @MDA_Max_Amt,
					MAX_AMOUNT_CREDIT = @Tel_Sum,
					claim_no = @RemedyEntryID	
					WHERE AGREEMENT = @AgreementNo and AUTHORIZATION_NO = @MultipleDebitorAuthNo and DEBITOR_CODE = @Debitor_Code
				end		
				
				
			if not exists
			(select 1 from BCLIVE..DEBITOR_PAY_FLAGS (nolock) where AUTHRIZATION_NO = @MultipleDebitorAuthNo --AND AGREEMENT_NO= @AgreementNo AND DEBITOR_CODE= @debitor_code
			)							
			begin
			insert into BCLIVE..DEBITOR_PAY_FLAGS (
			[AUTHRIZATION_NO]
			,[PAY_RENTAL]
			,[PAY_EXTENSION]
			,[PAY_UPSELL]
			,[PAY_KM]
			,[PAY_FUEL]		
			,[PAY_DAMAGE]
			,[PAY_TRAFFIC]
			,[PAY_AIRPORTFEE]
			,[PAY_DROPOFFFEE]
			,[PAY_DELIVERY]
			,[PAY_PICKUP]
			,[PAY_INS]
			,[PAY_EXT]
			,[PAY_OTHER]
			,[GET_RED]
			,[PAY_SERVICE]
			,[PAY_VAT]
			,[PAY_TELEPHONE]
			,[PAY_DEDUACTABLE]
			,[PAY_HIGH_WAY_TICKET]
			,[PAY_HIGHWAYADMIN]
			,[CREATED_FROM]
			,[AGREEMENT_NO]
			,[DEBITOR_CODE]
			,[SEPARATE_DAMAGE_INVOICE]
			,[SEPARATE_TRAFFIC_INVOICE]
			,[PREBILLING_IN_ADVANCE]
			,[BILLTO_END_OF_MONTH]
			,[PREBILLING_INVOICE_METHOD]
			,[REQUIRE_VOUCHER_CONFIRMATION]
			,[COMBINATION_PREBILLING]
			,[FULLY_AUTHORIZE]
			,[COMBINATION_INVOICE]
			,[COMB_DAMGE_INVOICE]
			,[COMB_TRAFFIC_INVOICE]
			,[COMB_HIGHWAY_INVOICE]
			,[PREBILLING_CHARGE_KM]
			,[RENTAL_BEFORE_DISCOUNT]
			,[RENTAL_EXT_BEFORE_DISCOUNT]
			,[KM_PRICE_BEFORE_DISCOUNT]
			,[RENTAL_VAT_AMOUNT]
			,[RENTAL_EXT_VAT_AMOUNT]
			,[INS_SUM_BEFORE_DISCOUNT]
			,[INS_SUM_BEFORE_DIS_WITHOUTVAT]
			,[KM_VAT_AMOUNT]
			,[CUST_TRAFFIC_ADMIN_FEE]
			,[AIRPORT_VAT_AMOUNT]
			,[DROPOFF_VAT_AMOUNT]
			,[FUEL_VAT_AMOUNT]
			,[DELIVERY_VAT_AMOUNT]
			,[PICKKUP_VAT_AMOUNT]
			,[OTHERSUM_VAT_AMOUNT]
			,[REDUCTION_VAT_AMOUNT]
			,[DAMAGES_VAT_AMOUNT]
			,[DEDUCTIBLE_VAT_AMOUNT]
			,[TRAFFIC_VAT_AMOUNT]
			,[INS_VAT_AMOUNT]
			,[EXTRAS_VAT_AMOUNT]
			,[DISCOUNT_VAT_AMOUNT]
			,[RENTAL_SERVICE_AMOUNT]
			,[RENTALEXT_SERVICE_AMOUNT]
			,[KM_SERVICE_AMOUNT]
			,[AIRPORT_SERVICE_AMOUNT]
			,[DROPOFF_SERVICE_AMOUNT]
			,[FUEL_SERVICE_AMOUNT]
			,[DELIVERY_SERVICE_AMOUNT]
			,[PICKUP_SERVICE_AMOUNT]
			,[OTHERSUM_SERVICE_AMOUNT]
			,[REDUCTION_SERVICE_AMOUNT]
			,[DAMAGES_SERVICE_AMOUNT]
			,[DEDCTIBLE_SERVICE_AMOUNT]
			,[TRAFFIC_SERVICE_AMOUNT]
			,[INS_SERVICE_AMOUNT]
			,[EXTRAS_SERVICE_AMOUNT]
			,[DISCOUNT_SERVICE_AMOUNT]
			,[PACKAGE_PRICE]
			,[PACKAGE_EXT_PRICE]
			,[KM_PRICE]
			,[RENTAL_DISCOUNT_AMOUNT]
			,[RENTAL_EXT_DISCOUNT_SUM]
			,[KM_DISCOUNT_AMOUNT]
			,[INS_DISCOUNT_AMOUNT]
			,[INS_DISC_AMOUNT_WT_OUT_VAT]
			,[TOTAL_DISCOUNT_AMOUNT]
			,[NON_TAXBLE_AMOUNT]
			,[NON_SERVICABLE_AMOUNT]
			,[PACKAGE_DAYS]
			,[PACKAGE_ADD_DAYS]
			,[EXTENSION_DAYS]
			,[TRAFFIC_ADMIN_FEE_VAT_AMT]
			,[TRAFFIC_ADMIN_FEE_SERVICE_AMT]
			,[TRAFFIC_AMT_WO_ADMIN_FEE]
			,[BILLING_FREQUENCY]
			,[SEPARATE_REPLACEMENT_INV]
			,[SEPARATE_FUEL_INV]
			,[COMB_FUEL_INVOICE]
			,[INVOICE_BY]
			,[PAY_TOLL]
			,[SEPARATE_TOLL_INVOICE]
			,[TOLL_WO_ADMIN_FEE]
			,[TOLL_ADMIN_FEE]
			,[TOLL_VAT_AMT]
			,[TOLL_SERVICE_AMT]
			,[TOLL_ADMIN_FEEPER_SETUP]
			,[TOLL_ADMIN_FEEAMT_SETUP]
			,[DAMAGE_WO_ADMIN_FEE]
			,[DAMAGE_ADMIN_FEE]
			,[DED_WO_ADMIN_FEE]
			,[DED_ADMIN_FEE]
			,[PAY_ENTIRE_BILL]
			,[PAY_ALL_TAXES]
			,[PAY_RATE_PER_DAY]
			,[PAY_SURCHARGE]
			,[PAY_GST_HST]
			,[MONTHLY_DAYS]
			)

		   select 
		   [AUTHRIZATION_NO] = @MultipleDebitorAuthNo
		  ,[PAY_RENTAL] = 'Y'
		  ,[PAY_EXTENSION]= ''
		  ,[PAY_UPSELL]= ''
		  ,[PAY_KM]= 'N'
		  ,[PAY_FUEL]= 'N'
		  ,[PAY_DAMAGE]= 'N'
		  ,[PAY_TRAFFIC]= 'N'
		  ,[PAY_AIRPORTFEE]= 'N'
		  ,[PAY_DROPOFFFEE]= 'N'
		  ,[PAY_DELIVERY]= 'N'
		  ,[PAY_PICKUP]= 'N'
		  ,[PAY_INS]= CASE WHEN @CDW > 0 THEN 'Y' ELSE 'N' END
		  ,[PAY_EXT]= 'Y'
		  ,[PAY_OTHER]= 'N'
		  ,[GET_RED]= 'Y'
		  ,[PAY_SERVICE]= CASE WHEN @PST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_VAT]= CASE WHEN @GSTorHST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_TELEPHONE]= ''
		  ,[PAY_DEDUACTABLE]= ''
		  ,[PAY_HIGH_WAY_TICKET]= ''
		  ,[PAY_HIGHWAYADMIN]= ''
		  ,[CREATED_FROM]= ''
		  ,[AGREEMENT_NO]= @AgreementNo
		  ,[DEBITOR_CODE]= @debitor_code
		  ,[SEPARATE_DAMAGE_INVOICE]= ''
		  ,[SEPARATE_TRAFFIC_INVOICE] = ''
		  ,[PREBILLING_IN_ADVANCE]= ''
		  ,[BILLTO_END_OF_MONTH]= ''
		  ,[PREBILLING_INVOICE_METHOD]= ''
		  ,[REQUIRE_VOUCHER_CONFIRMATION]= ''
		  ,[COMBINATION_PREBILLING]= ''
		  ,[FULLY_AUTHORIZE]= ''
		  ,[COMBINATION_INVOICE]= ''
		  ,[COMB_DAMGE_INVOICE]= ''
		  ,[COMB_TRAFFIC_INVOICE]= ''
		  ,[COMB_HIGHWAY_INVOICE]= ''
		  ,[PREBILLING_CHARGE_KM]= ''
		  ,[RENTAL_BEFORE_DISCOUNT]=  @MDA_Authrate * @TotalAuthDays
		  ,[RENTAL_EXT_BEFORE_DISCOUNT]= ''
		  ,[KM_PRICE_BEFORE_DISCOUNT]= ''
		  ,[RENTAL_VAT_AMOUNT]= @Old_VAT+ @dTotalTaxes
		  ,[RENTAL_EXT_VAT_AMOUNT]= ''
		  ,[INS_SUM_BEFORE_DISCOUNT]= @Insurances_Price+@dTotalInsurances
		  ,[INS_SUM_BEFORE_DIS_WITHOUTVAT]= ''
		  ,[KM_VAT_AMOUNT]= ''
		  ,[CUST_TRAFFIC_ADMIN_FEE]= ''
		  ,[AIRPORT_VAT_AMOUNT]= ''
		  ,[DROPOFF_VAT_AMOUNT]= ''
		  ,[FUEL_VAT_AMOUNT]= ''
		  ,[DELIVERY_VAT_AMOUNT]= ''
		  ,[PICKKUP_VAT_AMOUNT]= ''
		  ,[OTHERSUM_VAT_AMOUNT]= ''
		  ,[REDUCTION_VAT_AMOUNT]= ''
		  ,[DAMAGES_VAT_AMOUNT]= ''
		  ,[DEDUCTIBLE_VAT_AMOUNT]= ''
		  ,[TRAFFIC_VAT_AMOUNT]= ''
		  ,[INS_VAT_AMOUNT]= ((@Insurances_Price+@dTotalInsurances) * @GSTorHST) / 100
		  ,[EXTRAS_VAT_AMOUNT]= ((@Extras_Price+@dTotalExtras) * @GSTorHST) / 100
		  ,[DISCOUNT_VAT_AMOUNT]= ''
		  ,[RENTAL_SERVICE_AMOUNT]= @Old_SERVICE_FEE + 0.00
		  ,[RENTALEXT_SERVICE_AMOUNT]= ''
		  ,[KM_SERVICE_AMOUNT]= ''
		  ,[AIRPORT_SERVICE_AMOUNT]= ''
		  ,[DROPOFF_SERVICE_AMOUNT]= ''
		  ,[FUEL_SERVICE_AMOUNT]= ''
		  ,[DELIVERY_SERVICE_AMOUNT]= ''
		  ,[PICKUP_SERVICE_AMOUNT]= ''
		  ,[OTHERSUM_SERVICE_AMOUNT]= ''
		  ,[REDUCTION_SERVICE_AMOUNT]= ''
		  ,[DAMAGES_SERVICE_AMOUNT]= ''
		  ,[DEDCTIBLE_SERVICE_AMOUNT]= ''
		  ,[TRAFFIC_SERVICE_AMOUNT] = 0
		  ,[INS_SERVICE_AMOUNT] = 0
		  ,[EXTRAS_SERVICE_AMOUNT] = 0
		  ,[DISCOUNT_SERVICE_AMOUNT] = 0
		  ,[PACKAGE_PRICE] = 0
		  ,[PACKAGE_EXT_PRICE] = 0
		  ,[KM_PRICE] = 0
		  ,[RENTAL_DISCOUNT_AMOUNT] = 0
		  ,[RENTAL_EXT_DISCOUNT_SUM] = 0
		  ,[KM_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISC_AMOUNT_WT_OUT_VAT] = 0
		  ,[TOTAL_DISCOUNT_AMOUNT] = 0
		  ,[NON_TAXBLE_AMOUNT] = 0
		  ,[NON_SERVICABLE_AMOUNT] = 0
		  ,[PACKAGE_DAYS] = 0
		  ,[PACKAGE_ADD_DAYS] = 0
		  ,[EXTENSION_DAYS] = 0
		  ,[TRAFFIC_ADMIN_FEE_VAT_AMT] = 0
		  ,[TRAFFIC_ADMIN_FEE_SERVICE_AMT] = 0
		  ,[TRAFFIC_AMT_WO_ADMIN_FEE] = 0
		  ,[BILLING_FREQUENCY] = 0
		  ,[SEPARATE_REPLACEMENT_INV] = 'N'
		  ,[SEPARATE_FUEL_INV] = 'N'
		  ,[COMB_FUEL_INVOICE] = 'N'
		  ,[INVOICE_BY] = 'A'
		  ,[PAY_TOLL] =  'N'
		  ,[SEPARATE_TOLL_INVOICE] = 'N'
		  ,[TOLL_WO_ADMIN_FEE] = 0
		  ,[TOLL_ADMIN_FEE] = 0
		  ,[TOLL_VAT_AMT] = 0
		  ,[TOLL_SERVICE_AMT] = 0
		  ,[TOLL_ADMIN_FEEPER_SETUP] = 0
		  ,[TOLL_ADMIN_FEEAMT_SETUP] = 0
		  ,[DAMAGE_WO_ADMIN_FEE] = 0
		  ,[DAMAGE_ADMIN_FEE] = 0
		  ,[DED_WO_ADMIN_FEE] = 0
		  ,[DED_ADMIN_FEE] = 0
		  ,[PAY_ENTIRE_BILL]  = 'N'
		  ,[PAY_ALL_TAXES] = 'Y'
		  ,[PAY_RATE_PER_DAY] = 'N'
		  ,[PAY_SURCHARGE] = 'N'
		  ,[PAY_GST_HST] = 'Y'
		  ,[MONTHLY_DAYS] = 0
		end
		
		ELSE
		BEGIN -- UPDATE MDA DEBITOR_FLAGS
		UPDATE BCLIVE..DEBITOR_PAY_FLAGS SET 
		   --[AUTHRIZATION_NO] = @MultipleDebitorAuthNo
		  [PAY_RENTAL] = 'Y'
		  ,[PAY_EXTENSION]= ''
		  ,[PAY_UPSELL]= ''
		  ,[PAY_KM]= 'N'
		  ,[PAY_FUEL]= 'N'
		  ,[PAY_DAMAGE]= 'N'
		  ,[PAY_TRAFFIC]= 'N'
		  ,[PAY_AIRPORTFEE]= 'N'
		  ,[PAY_DROPOFFFEE]= 'N'
		  ,[PAY_DELIVERY]= 'N'
		  ,[PAY_PICKUP]= 'N'
		  ,[PAY_INS]= CASE WHEN @CDW > 0 THEN 'Y' ELSE 'N' END
		  ,[PAY_EXT]= 'Y'
		  ,[PAY_OTHER]= 'N'
		  ,[GET_RED]= 'Y'
		  ,[PAY_SERVICE]= CASE WHEN @PST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_VAT]= CASE WHEN @GSTorHST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_TELEPHONE]= ''
		  ,[PAY_DEDUACTABLE]= ''
		  ,[PAY_HIGH_WAY_TICKET]= ''
		  ,[PAY_HIGHWAYADMIN]= ''
		  ,[CREATED_FROM]= ''
		  ,[AGREEMENT_NO]= @AgreementNo
		  ,[DEBITOR_CODE]= @debitor_code
		  ,[SEPARATE_DAMAGE_INVOICE]= ''
		  ,[SEPARATE_TRAFFIC_INVOICE] = ''
		  ,[PREBILLING_IN_ADVANCE]= ''
		  ,[BILLTO_END_OF_MONTH]= ''
		  ,[PREBILLING_INVOICE_METHOD]= ''
		  ,[REQUIRE_VOUCHER_CONFIRMATION]= ''
		  ,[COMBINATION_PREBILLING]= ''
		  ,[FULLY_AUTHORIZE]= ''
		  ,[COMBINATION_INVOICE]= ''
		  ,[COMB_DAMGE_INVOICE]= ''
		  ,[COMB_TRAFFIC_INVOICE]= ''
		  ,[COMB_HIGHWAY_INVOICE]= ''
		  ,[PREBILLING_CHARGE_KM]= ''
		  ,[RENTAL_BEFORE_DISCOUNT]=  @MDA_Authrate * @TotalAuthDays
		  ,[RENTAL_EXT_BEFORE_DISCOUNT]= ''
		  ,[KM_PRICE_BEFORE_DISCOUNT]= ''
		  ,[RENTAL_VAT_AMOUNT]= @Old_VAT+ @dTotalTaxes
		  ,[RENTAL_EXT_VAT_AMOUNT]= ''
		  ,[INS_SUM_BEFORE_DISCOUNT]= @Insurances_Price+@dTotalInsurances
		  ,[INS_SUM_BEFORE_DIS_WITHOUTVAT]= ''
		  ,[KM_VAT_AMOUNT]= ''
		  ,[CUST_TRAFFIC_ADMIN_FEE]= ''
		  ,[AIRPORT_VAT_AMOUNT]= ''
		  ,[DROPOFF_VAT_AMOUNT]= ''
		  ,[FUEL_VAT_AMOUNT]= ''
		  ,[DELIVERY_VAT_AMOUNT]= ''
		  ,[PICKKUP_VAT_AMOUNT]= ''
		  ,[OTHERSUM_VAT_AMOUNT]= ''
		  ,[REDUCTION_VAT_AMOUNT]= ''
		  ,[DAMAGES_VAT_AMOUNT]= ''
		  ,[DEDUCTIBLE_VAT_AMOUNT]= ''
		  ,[TRAFFIC_VAT_AMOUNT]= ''
		  ,[INS_VAT_AMOUNT]= ((@Insurances_Price+@dTotalInsurances) * @GSTorHST) / 100
		  ,[EXTRAS_VAT_AMOUNT]= ((@Extras_Price+@dTotalExtras) * @GSTorHST) / 100
		  ,[DISCOUNT_VAT_AMOUNT]= ''
		  ,[RENTAL_SERVICE_AMOUNT]= @Old_SERVICE_FEE + 0.00
		  ,[RENTALEXT_SERVICE_AMOUNT]= ''
		  ,[KM_SERVICE_AMOUNT]= ''
		  ,[AIRPORT_SERVICE_AMOUNT]= ''
		  ,[DROPOFF_SERVICE_AMOUNT]= ''
		  ,[FUEL_SERVICE_AMOUNT]= ''
		  ,[DELIVERY_SERVICE_AMOUNT]= ''
		  ,[PICKUP_SERVICE_AMOUNT]= ''
		  ,[OTHERSUM_SERVICE_AMOUNT]= ''
		  ,[REDUCTION_SERVICE_AMOUNT]= ''
		  ,[DAMAGES_SERVICE_AMOUNT]= ''
		  ,[DEDCTIBLE_SERVICE_AMOUNT]= ''
		  ,[TRAFFIC_SERVICE_AMOUNT] = 0
		  ,[INS_SERVICE_AMOUNT] = 0
		  ,[EXTRAS_SERVICE_AMOUNT] = 0
		  ,[DISCOUNT_SERVICE_AMOUNT] = 0
		  ,[PACKAGE_PRICE] = 0
		  ,[PACKAGE_EXT_PRICE] = 0
		  ,[KM_PRICE] = 0
		  ,[RENTAL_DISCOUNT_AMOUNT] = 0
		  ,[RENTAL_EXT_DISCOUNT_SUM] = 0
		  ,[KM_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISC_AMOUNT_WT_OUT_VAT] = 0
		  ,[TOTAL_DISCOUNT_AMOUNT] = 0
		  ,[NON_TAXBLE_AMOUNT] = 0
		  ,[NON_SERVICABLE_AMOUNT] = 0
		  ,[PACKAGE_DAYS] = 0
		  ,[PACKAGE_ADD_DAYS] = 0
		  ,[EXTENSION_DAYS] = 0
		  ,[TRAFFIC_ADMIN_FEE_VAT_AMT] = 0
		  ,[TRAFFIC_ADMIN_FEE_SERVICE_AMT] = 0
		  ,[TRAFFIC_AMT_WO_ADMIN_FEE] = 0
		  ,[BILLING_FREQUENCY] = 0
		  ,[SEPARATE_REPLACEMENT_INV] = 'N'
		  ,[SEPARATE_FUEL_INV] = 'N'
		  ,[COMB_FUEL_INVOICE] = 'N'
		  ,[INVOICE_BY] = 'A'
		  ,[PAY_TOLL] =  'N'
		  ,[SEPARATE_TOLL_INVOICE] = 'N'
		  ,[TOLL_WO_ADMIN_FEE] = 0
		  ,[TOLL_ADMIN_FEE] = 0
		  ,[TOLL_VAT_AMT] = 0
		  ,[TOLL_SERVICE_AMT] = 0
		  ,[TOLL_ADMIN_FEEPER_SETUP] = 0
		  ,[TOLL_ADMIN_FEEAMT_SETUP] = 0
		  ,[DAMAGE_WO_ADMIN_FEE] = 0
		  ,[DAMAGE_ADMIN_FEE] = 0
		  ,[DED_WO_ADMIN_FEE] = 0
		  ,[DED_ADMIN_FEE] = 0
		  ,[PAY_ENTIRE_BILL]  = 'N'
		  ,[PAY_ALL_TAXES] = 'Y'
		  ,[PAY_RATE_PER_DAY] = 'N'
		  ,[PAY_SURCHARGE] = 'N'
		  ,[PAY_GST_HST] = 'Y'
		  ,[MONTHLY_DAYS] = 0
		  WHERE [AUTHRIZATION_NO] = @MultipleDebitorAuthNo AND DEBITOR_CODE=@debitor_code AND AGREEMENT_NO=@AgreementNo
		  END
				
			UPDATE DA_CLAIMS SET  DAC_RATE_OUT = ISNULL(@MDA_Authrate, 0), INS_COMP_AUTH_DAYS = @MDA_TotalDays WHERE DAC_ENTRY_ID = @RemedyEntryId	
			end
			ELSE
			BEGIN --create MDA						
			-------------------------------  AUTHORIZATION NO FOR MULTIPLE DEBITOR AUTH | AUTHORIZATION_AGR_RES    -------------------------------------
			
			SELECT @iDocNobigint =DN_DOCUMENT_NUMBER+1 from DOCUMENT_NUMBERS b(nolock) WHERE DN_COMPANY_CODE = 1 AND DN_BRANCH_CODE = 0 AND DN_DOCUMENT_TYPE = 12		
			
			if exists( select AUTHORIZATION_NO from BCLIVE..MULTIPLE_DEBITOR_AUTH(nolock)	where  convert(bigint,AUTHORIZATION_NO)	=@iDocNobigint)
			begin	
				while exists( select AUTHORIZATION_NO from BCLIVE..MULTIPLE_DEBITOR_AUTH(nolock)	where  convert(bigint,AUTHORIZATION_NO)	=@iDocNobigint)
				begin
					
					if not exists( select AUTHORIZATION_NO from BCLIVE..MULTIPLE_DEBITOR_AUTH(nolock)	where  convert(bigint,AUTHORIZATION_NO)	=@iDocNobigint)
						break
						
					select @iDocNobigint= @iDocNobigint + 1
				end
			end
			
			select @MultipleDebitorAuthNo= RIGHT( convert(varchar(20),@iDocNobigint + 10000000000000000),15)				
							
			UPDATE DOCUMENT_NUMBERS SET  DN_DOCUMENT_NUMBER = @iDocNobigint 
			WHERE DN_COMPANY_CODE = @CompanyCode AND DN_BRANCH_CODE = 0 AND DN_DOCUMENT_TYPE = 12 		
			-----------------------------------------END----------------------------------------------------------------------------------------------------
			INSERT INTO BCLIVE..MULTIPLE_DEBITOR_AUTH
			(AGREEMENT,
			RESERVATION_NO,
			DEBITOR_CODE,
			AUTHORIZATION_NO,
			DAYS,
			AGENTCOMMEXTERNV,
			F_GROUP,
			RENTAL_PACKAGE,
			Sold_Days,
			LOSS_DATE,
			CURRENCY,
			PER_DAY_PRICE,
			RATE_SR_NO,
			RATE_DET_SR_NO,
			VAT_PERCENT,
			SERVICE_FEE_PERCENT,
			RENTAL_PRICE,
			INSURANCES_PRICE,
			EXTRAS_PRICE,
			AMOUNT,
			TAXABLE_SUM,
			SERVICABLE_SUM,
			SALES_TAX,
			SERVICE_TAX,
			EXCHANGE_RATE,
			SUBTOTAL,
			FIRST_CHARGE_GROUP,
			FIRST_NO_OF_DAYS,
			FIRST_RENTAL_PACKAGE,
			FIRST_RATE_SR_NO,
			FIRST_RATE_DET_SR_NO,
			FIRST_PER_DAY_PRICE,
			BODY_SHOP_DIFF_FLAT_AMT,
			BODY_SHOP_DIFF_DAYS,
			MAX_AMOUNT,
			MAX_AMOUNT_CREDIT,
			claim_no,
			RATE_NO 
			)
			SELECT
			AGREEMENT = @AgreementNo,
			RESERVATION_NO = @ReservationNo,
			DEBITOR_CODE = @Debitor_Code,
			AUTHORIZATION_NO = @MultipleDebitorAuthNo,
			DAYS = @DaysAuthorized,
			AGENTCOMMEXTERNV = 'O',
			F_GROUP = @Authorized_VehicleCategory,
			RENTAL_PACKAGE = @Rental_Package,
			Sold_Days = @DaysAuthorized,
			LOSS_DATE = '00000000',
			CURRENCY = 'CAD',
			PER_DAY_PRICE = @Authorizedrate,
			RATE_SR_NO = @RATE_SR_NO,
			RATE_DET_SR_NO = @RATE_DET_SR_NO,
			VAT_PERCENT = @GSTorHST,
			SERVICE_FEE_PERCENT = @PST,
			RENTAL_PRICE = (@Authorizedrate)  * @DaysAuthorized, --0.00,
			INSURANCES_PRICE = @dTotalInsurances , --0.00,
			EXTRAS_PRICE = @dTotalExtras,
			AMOUNT = @dFinalTotal,
			TAXABLE_SUM = (@Authorizedrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @DaysAuthorized ,
			SERVICABLE_SUM = 0.00,
			SALES_TAX = @dTotalTaxes,
			SERVICE_TAX = 0.00,
			EXCHANGE_RATE = 1,
			SUBTOTAL = (@Authorizedrate + ISNULL(@UF, 0) + ISNULL(@WT, 0) + ISNULL(@CDW, 0))  * @DaysAuthorized,
			FIRST_CHARGE_GROUP = @Authorized_VehicleCategory,
			FIRST_NO_OF_DAYS = @DaysAuthorized,
			FIRST_RENTAL_PACKAGE = @Rental_Package,
			FIRST_RATE_SR_NO = @RATE_SR_NO,
			FIRST_RATE_DET_SR_NO = @RATE_DET_SR_NO,
			FIRST_PER_DAY_PRICE = @Authorizedrate,
			BODY_SHOP_DIFF_FLAT_AMT  = 0.00,
			BODY_SHOP_DIFF_DAYS = 0,
			MAX_AMOUNT = @MaxAmount,
			MAX_AMOUNT_CREDIT = 0,
			claim_no = @RemedyEntryID,
			RATE_NO = isnull(@RateNo, 0)			
			
			if not exists
			(select 1 from BCLIVE..DEBITOR_PAY_FLAGS (nolock) where AUTHRIZATION_NO = @MultipleDebitorAuthNo AND AGREEMENT_NO=@AGREEMENTNO AND DEBITOR_CODE=@debitor_code)							
			begin
			insert into BCLIVE..DEBITOR_PAY_FLAGS (
			[AUTHRIZATION_NO]
			,[PAY_RENTAL]
			,[PAY_EXTENSION]
			,[PAY_UPSELL]
			,[PAY_KM]
			,[PAY_FUEL]		
			,[PAY_DAMAGE]
			,[PAY_TRAFFIC]
			,[PAY_AIRPORTFEE]
			,[PAY_DROPOFFFEE]
			,[PAY_DELIVERY]
			,[PAY_PICKUP]
			,[PAY_INS]
			,[PAY_EXT]
			,[PAY_OTHER]
			,[GET_RED]
			,[PAY_SERVICE]
			,[PAY_VAT]
			,[PAY_TELEPHONE]
			,[PAY_DEDUACTABLE]
			,[PAY_HIGH_WAY_TICKET]
			,[PAY_HIGHWAYADMIN]
			,[CREATED_FROM]
			,[AGREEMENT_NO]
			,[DEBITOR_CODE]
			,[SEPARATE_DAMAGE_INVOICE]
			,[SEPARATE_TRAFFIC_INVOICE]
			,[PREBILLING_IN_ADVANCE]
			,[BILLTO_END_OF_MONTH]
			,[PREBILLING_INVOICE_METHOD]
			,[REQUIRE_VOUCHER_CONFIRMATION]
			,[COMBINATION_PREBILLING]
			,[FULLY_AUTHORIZE]
			,[COMBINATION_INVOICE]
			,[COMB_DAMGE_INVOICE]
			,[COMB_TRAFFIC_INVOICE]
			,[COMB_HIGHWAY_INVOICE]
			,[PREBILLING_CHARGE_KM]
			,[RENTAL_BEFORE_DISCOUNT]
			,[RENTAL_EXT_BEFORE_DISCOUNT]
			,[KM_PRICE_BEFORE_DISCOUNT]
			,[RENTAL_VAT_AMOUNT]
			,[RENTAL_EXT_VAT_AMOUNT]
			,[INS_SUM_BEFORE_DISCOUNT]
			,[INS_SUM_BEFORE_DIS_WITHOUTVAT]
			,[KM_VAT_AMOUNT]
			,[CUST_TRAFFIC_ADMIN_FEE]
			,[AIRPORT_VAT_AMOUNT]
			,[DROPOFF_VAT_AMOUNT]
			,[FUEL_VAT_AMOUNT]
			,[DELIVERY_VAT_AMOUNT]
			,[PICKKUP_VAT_AMOUNT]
			,[OTHERSUM_VAT_AMOUNT]
			,[REDUCTION_VAT_AMOUNT]
			,[DAMAGES_VAT_AMOUNT]
			,[DEDUCTIBLE_VAT_AMOUNT]
			,[TRAFFIC_VAT_AMOUNT]
			,[INS_VAT_AMOUNT]
			,[EXTRAS_VAT_AMOUNT]
			,[DISCOUNT_VAT_AMOUNT]
			,[RENTAL_SERVICE_AMOUNT]
			,[RENTALEXT_SERVICE_AMOUNT]
			,[KM_SERVICE_AMOUNT]
			,[AIRPORT_SERVICE_AMOUNT]
			,[DROPOFF_SERVICE_AMOUNT]
			,[FUEL_SERVICE_AMOUNT]
			,[DELIVERY_SERVICE_AMOUNT]
			,[PICKUP_SERVICE_AMOUNT]
			,[OTHERSUM_SERVICE_AMOUNT]
			,[REDUCTION_SERVICE_AMOUNT]
			,[DAMAGES_SERVICE_AMOUNT]
			,[DEDCTIBLE_SERVICE_AMOUNT]
			,[TRAFFIC_SERVICE_AMOUNT]
			,[INS_SERVICE_AMOUNT]
			,[EXTRAS_SERVICE_AMOUNT]
			,[DISCOUNT_SERVICE_AMOUNT]
			,[PACKAGE_PRICE]
			,[PACKAGE_EXT_PRICE]
			,[KM_PRICE]
			,[RENTAL_DISCOUNT_AMOUNT]
			,[RENTAL_EXT_DISCOUNT_SUM]
			,[KM_DISCOUNT_AMOUNT]
			,[INS_DISCOUNT_AMOUNT]
			,[INS_DISC_AMOUNT_WT_OUT_VAT]
			,[TOTAL_DISCOUNT_AMOUNT]
			,[NON_TAXBLE_AMOUNT]
			,[NON_SERVICABLE_AMOUNT]
			,[PACKAGE_DAYS]
			,[PACKAGE_ADD_DAYS]
			,[EXTENSION_DAYS]
			,[TRAFFIC_ADMIN_FEE_VAT_AMT]
			,[TRAFFIC_ADMIN_FEE_SERVICE_AMT]
			,[TRAFFIC_AMT_WO_ADMIN_FEE]
			,[BILLING_FREQUENCY]
			,[SEPARATE_REPLACEMENT_INV]
			,[SEPARATE_FUEL_INV]
			,[COMB_FUEL_INVOICE]
			,[INVOICE_BY]
			,[PAY_TOLL]
			,[SEPARATE_TOLL_INVOICE]
			,[TOLL_WO_ADMIN_FEE]
			,[TOLL_ADMIN_FEE]
			,[TOLL_VAT_AMT]
			,[TOLL_SERVICE_AMT]
			,[TOLL_ADMIN_FEEPER_SETUP]
			,[TOLL_ADMIN_FEEAMT_SETUP]
			,[DAMAGE_WO_ADMIN_FEE]
			,[DAMAGE_ADMIN_FEE]
			,[DED_WO_ADMIN_FEE]
			,[DED_ADMIN_FEE]
			,[PAY_ENTIRE_BILL]
			,[PAY_ALL_TAXES]
			,[PAY_RATE_PER_DAY]
			,[PAY_SURCHARGE]
			,[PAY_GST_HST]
			,[MONTHLY_DAYS]
			)

		   select 
		   [AUTHRIZATION_NO] = @MultipleDebitorAuthNo
		  ,[PAY_RENTAL] = 'Y'
		  ,[PAY_EXTENSION]= ''
		  ,[PAY_UPSELL]= ''
		  ,[PAY_KM]= 'N'
		  ,[PAY_FUEL]= 'N'
		  ,[PAY_DAMAGE]= 'N'
		  ,[PAY_TRAFFIC]= 'N'
		  ,[PAY_AIRPORTFEE]= 'N'
		  ,[PAY_DROPOFFFEE]= 'N'
		  ,[PAY_DELIVERY]= 'N'
		  ,[PAY_PICKUP]= 'N'
		  ,[PAY_INS]= CASE WHEN @CDW > 0 THEN 'Y' ELSE 'N' END
		  ,[PAY_EXT]= 'Y'
		  ,[PAY_OTHER]= 'N'
		  ,[GET_RED]= 'Y'
		  ,[PAY_SERVICE]= CASE WHEN @PST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_VAT]= CASE WHEN @GSTorHST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_TELEPHONE]= ''
		  ,[PAY_DEDUACTABLE]= ''
		  ,[PAY_HIGH_WAY_TICKET]= ''
		  ,[PAY_HIGHWAYADMIN]= ''
		  ,[CREATED_FROM]= ''
		  ,[AGREEMENT_NO]= @AgreementNo
		  ,[DEBITOR_CODE]= @debitor_code
		  ,[SEPARATE_DAMAGE_INVOICE]= ''
		  ,[SEPARATE_TRAFFIC_INVOICE] = ''
		  ,[PREBILLING_IN_ADVANCE]= ''
		  ,[BILLTO_END_OF_MONTH]= ''
		  ,[PREBILLING_INVOICE_METHOD]= ''
		  ,[REQUIRE_VOUCHER_CONFIRMATION]= ''
		  ,[COMBINATION_PREBILLING]= ''
		  ,[FULLY_AUTHORIZE]= ''
		  ,[COMBINATION_INVOICE]= ''
		  ,[COMB_DAMGE_INVOICE]= ''
		  ,[COMB_TRAFFIC_INVOICE]= ''
		  ,[COMB_HIGHWAY_INVOICE]= ''
		  ,[PREBILLING_CHARGE_KM]= ''
		  ,[RENTAL_BEFORE_DISCOUNT]=  @MDA_Authrate * @TotalAuthDays
		  ,[RENTAL_EXT_BEFORE_DISCOUNT]= ''
		  ,[KM_PRICE_BEFORE_DISCOUNT]= ''
		  ,[RENTAL_VAT_AMOUNT]= @Old_VAT+ @dTotalTaxes
		  ,[RENTAL_EXT_VAT_AMOUNT]= ''
		  ,[INS_SUM_BEFORE_DISCOUNT]= @Insurances_Price+@dTotalInsurances
		  ,[INS_SUM_BEFORE_DIS_WITHOUTVAT]= ''
		  ,[KM_VAT_AMOUNT]= ''
		  ,[CUST_TRAFFIC_ADMIN_FEE]= ''
		  ,[AIRPORT_VAT_AMOUNT]= ''
		  ,[DROPOFF_VAT_AMOUNT]= ''
		  ,[FUEL_VAT_AMOUNT]= ''
		  ,[DELIVERY_VAT_AMOUNT]= ''
		  ,[PICKKUP_VAT_AMOUNT]= ''
		  ,[OTHERSUM_VAT_AMOUNT]= ''
		  ,[REDUCTION_VAT_AMOUNT]= ''
		  ,[DAMAGES_VAT_AMOUNT]= ''
		  ,[DEDUCTIBLE_VAT_AMOUNT]= ''
		  ,[TRAFFIC_VAT_AMOUNT]= ''
		  ,[INS_VAT_AMOUNT]= ((@Insurances_Price+@dTotalInsurances) * @GSTorHST) / 100
		  ,[EXTRAS_VAT_AMOUNT]= ((@Extras_Price+@dTotalExtras) * @GSTorHST) / 100
		  ,[DISCOUNT_VAT_AMOUNT]= ''
		  ,[RENTAL_SERVICE_AMOUNT]= @Old_SERVICE_FEE + 0.00
		  ,[RENTALEXT_SERVICE_AMOUNT]= ''
		  ,[KM_SERVICE_AMOUNT]= ''
		  ,[AIRPORT_SERVICE_AMOUNT]= ''
		  ,[DROPOFF_SERVICE_AMOUNT]= ''
		  ,[FUEL_SERVICE_AMOUNT]= ''
		  ,[DELIVERY_SERVICE_AMOUNT]= ''
		  ,[PICKUP_SERVICE_AMOUNT]= ''
		  ,[OTHERSUM_SERVICE_AMOUNT]= ''
		  ,[REDUCTION_SERVICE_AMOUNT]= ''
		  ,[DAMAGES_SERVICE_AMOUNT]= ''
		  ,[DEDCTIBLE_SERVICE_AMOUNT]= ''
		  ,[TRAFFIC_SERVICE_AMOUNT] = 0
		  ,[INS_SERVICE_AMOUNT] = 0
		  ,[EXTRAS_SERVICE_AMOUNT] = 0
		  ,[DISCOUNT_SERVICE_AMOUNT] = 0
		  ,[PACKAGE_PRICE] = 0
		  ,[PACKAGE_EXT_PRICE] = 0
		  ,[KM_PRICE] = 0
		  ,[RENTAL_DISCOUNT_AMOUNT] = 0
		  ,[RENTAL_EXT_DISCOUNT_SUM] = 0
		  ,[KM_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISC_AMOUNT_WT_OUT_VAT] = 0
		  ,[TOTAL_DISCOUNT_AMOUNT] = 0
		  ,[NON_TAXBLE_AMOUNT] = 0
		  ,[NON_SERVICABLE_AMOUNT] = 0
		  ,[PACKAGE_DAYS] = 0
		  ,[PACKAGE_ADD_DAYS] = 0
		  ,[EXTENSION_DAYS] = 0
		  ,[TRAFFIC_ADMIN_FEE_VAT_AMT] = 0
		  ,[TRAFFIC_ADMIN_FEE_SERVICE_AMT] = 0
		  ,[TRAFFIC_AMT_WO_ADMIN_FEE] = 0
		  ,[BILLING_FREQUENCY] = 0
		  ,[SEPARATE_REPLACEMENT_INV] = 'N'
		  ,[SEPARATE_FUEL_INV] = 'N'
		  ,[COMB_FUEL_INVOICE] = 'N'
		  ,[INVOICE_BY] = 'A'
		  ,[PAY_TOLL] =  'N'
		  ,[SEPARATE_TOLL_INVOICE] = 'N'
		  ,[TOLL_WO_ADMIN_FEE] = 0
		  ,[TOLL_ADMIN_FEE] = 0
		  ,[TOLL_VAT_AMT] = 0
		  ,[TOLL_SERVICE_AMT] = 0
		  ,[TOLL_ADMIN_FEEPER_SETUP] = 0
		  ,[TOLL_ADMIN_FEEAMT_SETUP] = 0
		  ,[DAMAGE_WO_ADMIN_FEE] = 0
		  ,[DAMAGE_ADMIN_FEE] = 0
		  ,[DED_WO_ADMIN_FEE] = 0
		  ,[DED_ADMIN_FEE] = 0
		  ,[PAY_ENTIRE_BILL]  = 'N'
		  ,[PAY_ALL_TAXES] = 'Y'
		  ,[PAY_RATE_PER_DAY] = 'N'
		  ,[PAY_SURCHARGE] = 'N'
		  ,[PAY_GST_HST] = 'Y'
		  ,[MONTHLY_DAYS] = 0
		end
		else
		begin
		   update  BCLIVE..DEBITOR_PAY_FLAGS set 
		   [AUTHRIZATION_NO] = @MultipleDebitorAuthNo
		  ,[PAY_RENTAL] = 'Y'
		  ,[PAY_EXTENSION]= ''
		  ,[PAY_UPSELL]= ''
		  ,[PAY_KM]= 'N'
		  ,[PAY_FUEL]= 'N'
		  ,[PAY_DAMAGE]= 'N'
		  ,[PAY_TRAFFIC]= 'N'
		  ,[PAY_AIRPORTFEE]= 'N'
		  ,[PAY_DROPOFFFEE]= 'N'
		  ,[PAY_DELIVERY]= 'N'
		  ,[PAY_PICKUP]= 'N'
		  ,[PAY_INS]= CASE WHEN @CDW > 0 THEN 'Y' ELSE 'N' END
		  ,[PAY_EXT]= 'Y'
		  ,[PAY_OTHER]= 'N'
		  ,[GET_RED]= 'Y'
		  ,[PAY_SERVICE]= CASE WHEN @PST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_VAT]= CASE WHEN @GSTorHST > 0 OR @TaxPaidBy = 1 THEN 'Y' ELSE 'N' END
		  ,[PAY_TELEPHONE]= ''
		  ,[PAY_DEDUACTABLE]= ''
		  ,[PAY_HIGH_WAY_TICKET]= ''
		  ,[PAY_HIGHWAYADMIN]= ''
		  ,[CREATED_FROM]= ''
		  ,[AGREEMENT_NO]= @AgreementNo
		  ,[DEBITOR_CODE]= @debitor_code
		  ,[SEPARATE_DAMAGE_INVOICE]= ''
		  ,[SEPARATE_TRAFFIC_INVOICE] = ''
		  ,[PREBILLING_IN_ADVANCE]= ''
		  ,[BILLTO_END_OF_MONTH]= ''
		  ,[PREBILLING_INVOICE_METHOD]= ''
		  ,[REQUIRE_VOUCHER_CONFIRMATION]= ''
		  ,[COMBINATION_PREBILLING]= ''
		  ,[FULLY_AUTHORIZE]= ''
		  ,[COMBINATION_INVOICE]= ''
		  ,[COMB_DAMGE_INVOICE]= ''
		  ,[COMB_TRAFFIC_INVOICE]= ''
		  ,[COMB_HIGHWAY_INVOICE]= ''
		  ,[PREBILLING_CHARGE_KM]= ''
		  ,[RENTAL_BEFORE_DISCOUNT]=  @MDA_Authrate * @TotalAuthDays
		  ,[RENTAL_EXT_BEFORE_DISCOUNT]= ''
		  ,[KM_PRICE_BEFORE_DISCOUNT]= ''
		  ,[RENTAL_VAT_AMOUNT]= @Old_VAT+ @dTotalTaxes
		  ,[RENTAL_EXT_VAT_AMOUNT]= ''
		  ,[INS_SUM_BEFORE_DISCOUNT]= @Insurances_Price+@dTotalInsurances
		  ,[INS_SUM_BEFORE_DIS_WITHOUTVAT]= ''
		  ,[KM_VAT_AMOUNT]= ''
		  ,[CUST_TRAFFIC_ADMIN_FEE]= ''
		  ,[AIRPORT_VAT_AMOUNT]= ''
		  ,[DROPOFF_VAT_AMOUNT]= ''
		  ,[FUEL_VAT_AMOUNT]= ''
		  ,[DELIVERY_VAT_AMOUNT]= ''
		  ,[PICKKUP_VAT_AMOUNT]= ''
		  ,[OTHERSUM_VAT_AMOUNT]= ''
		  ,[REDUCTION_VAT_AMOUNT]= ''
		  ,[DAMAGES_VAT_AMOUNT]= ''
		  ,[DEDUCTIBLE_VAT_AMOUNT]= ''
		  ,[TRAFFIC_VAT_AMOUNT]= ''
		  ,[INS_VAT_AMOUNT]= ((@Insurances_Price+@dTotalInsurances) * @GSTorHST) / 100
		  ,[EXTRAS_VAT_AMOUNT]= ((@Extras_Price+@dTotalExtras) * @GSTorHST) / 100
		  ,[DISCOUNT_VAT_AMOUNT]= ''
		  ,[RENTAL_SERVICE_AMOUNT]= @Old_SERVICE_FEE + 0.00
		  ,[RENTALEXT_SERVICE_AMOUNT]= ''
		  ,[KM_SERVICE_AMOUNT]= ''
		  ,[AIRPORT_SERVICE_AMOUNT]= ''
		  ,[DROPOFF_SERVICE_AMOUNT]= ''
		  ,[FUEL_SERVICE_AMOUNT]= ''
		  ,[DELIVERY_SERVICE_AMOUNT]= ''
		  ,[PICKUP_SERVICE_AMOUNT]= ''
		  ,[OTHERSUM_SERVICE_AMOUNT]= ''
		  ,[REDUCTION_SERVICE_AMOUNT]= ''
		  ,[DAMAGES_SERVICE_AMOUNT]= ''
		  ,[DEDCTIBLE_SERVICE_AMOUNT]= ''
		  ,[TRAFFIC_SERVICE_AMOUNT] = 0
		  ,[INS_SERVICE_AMOUNT] = 0
		  ,[EXTRAS_SERVICE_AMOUNT] = 0
		  ,[DISCOUNT_SERVICE_AMOUNT] = 0
		  ,[PACKAGE_PRICE] = 0
		  ,[PACKAGE_EXT_PRICE] = 0
		  ,[KM_PRICE] = 0
		  ,[RENTAL_DISCOUNT_AMOUNT] = 0
		  ,[RENTAL_EXT_DISCOUNT_SUM] = 0
		  ,[KM_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISCOUNT_AMOUNT] = 0
		  ,[INS_DISC_AMOUNT_WT_OUT_VAT] = 0
		  ,[TOTAL_DISCOUNT_AMOUNT] = 0
		  ,[NON_TAXBLE_AMOUNT] = 0
		  ,[NON_SERVICABLE_AMOUNT] = 0
		  ,[PACKAGE_DAYS] = 0
		  ,[PACKAGE_ADD_DAYS] = 0
		  ,[EXTENSION_DAYS] = 0
		  ,[TRAFFIC_ADMIN_FEE_VAT_AMT] = 0
		  ,[TRAFFIC_ADMIN_FEE_SERVICE_AMT] = 0
		  ,[TRAFFIC_AMT_WO_ADMIN_FEE] = 0
		  ,[BILLING_FREQUENCY] = 0
		  ,[SEPARATE_REPLACEMENT_INV] = 'N'
		  ,[SEPARATE_FUEL_INV] = 'N'
		  ,[COMB_FUEL_INVOICE] = 'N'
		  ,[INVOICE_BY] = 'A'
		  ,[PAY_TOLL] =  'N'
		  ,[SEPARATE_TOLL_INVOICE] = 'N'
		  ,[TOLL_WO_ADMIN_FEE] = 0
		  ,[TOLL_ADMIN_FEE] = 0
		  ,[TOLL_VAT_AMT] = 0
		  ,[TOLL_SERVICE_AMT] = 0
		  ,[TOLL_ADMIN_FEEPER_SETUP] = 0
		  ,[TOLL_ADMIN_FEEAMT_SETUP] = 0
		  ,[DAMAGE_WO_ADMIN_FEE] = 0
		  ,[DAMAGE_ADMIN_FEE] = 0
		  ,[DED_WO_ADMIN_FEE] = 0
		  ,[DED_ADMIN_FEE] = 0
		  ,[PAY_ENTIRE_BILL]  = 'N'
		  ,[PAY_ALL_TAXES] = 'Y'
		  ,[PAY_RATE_PER_DAY] = 'N'
		  ,[PAY_SURCHARGE] = 'N'
		  ,[PAY_GST_HST] = 'Y'
		  ,[MONTHLY_DAYS] = 0
		  where [AUTHRIZATION_NO] = @MultipleDebitorAuthNo AND AGREEMENT_NO=@AGREEMENTNO AND DEBITOR_CODE=@debitor_code
		end	
			END--end to create MDA	
		END
						
			--(@agreementno > 0  and @Agreement_Status_Code  in (0,1,2,3)) or (@ReservationNo != '' and @agreementno=0)
		
		if not exists 
		(select AUTHORIZATION_NO from BCLIVE..AUTHORIZATION_AGR_RES (nolock) where AUTHORIZATION_NO=@MultipleDebitorAuthNo AND FROM_DATE=@AuthFromDate AND FROM_TIME = @AuthFromTime)		
		begin
		INSERT INTO BCLIVE..AUTHORIZATION_AGR_RES(AUTHORIZATION_NO,FROM_DATE,FROM_TIME,AUTH_SERIAL,AGREEMENT_NO,CAR_GROUP,RATE_PER_DAY,AUTH_DAYS,RATE_SR_NO,RATE_DET_SR_NO,TO_DATE,TO_TIME)
		VALUES
		(@MultipleDebitorAuthNo,@AuthFromDate,@AuthFromTime, 
		isnull((SELECT (MAX(AUTH_SERIAL)) FROM BCLIVE..AUTHORIZATION_AGR_RES (NOLOCK) where AUTHORIZATION_NO=@MultipleDebitorAuthNo), 0)+1, @AgreementNo, @Authorized_VehicleCategory, 
		@Authorizedrate,@DaysAuthorized,@RATE_SR_NO,@RATE_DET_SR_NO,@AuthToDate, @AuthToTime)		
		END		
		
		if @VLI_Rate > 0  and @AuthFromDate != '00000000'
		begin
			if not exists --VIREN INSISTEN ON FRIDAY NOV 29,2013 TO PUT 2 INSERTS STATEMENT ONE WITH 0 AND WITH AGREEMENTNO
			(select EXTRAS_CODE from BCLIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='VLI' and RESAUTHVOUCHER=@MultipleDebitorAuthNo and MASTER_AGREEMENT=0)		
			begin
				INSERT INTO BCLIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES
				(@MultipleDebitorAuthNo,'00000000','VLI', 0,0,'', @VLI_Rate, @VLI_Rate*@DaysAuthorized)
			end
				
			if not exists --VIREN INSISTEN ON FRIDAY NOV 29,2013 TO PUT 2 INSERTS STATEMENT ONE WITH 0 AND WITH AGREEMENTNO
			(select EXTRAS_CODE from BCLIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='VLI' and RESAUTHVOUCHER='' and MASTER_AGREEMENT=@AgreementNo)		
			begin	
				INSERT INTO BCLIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES
				('','00000000','VLI', @AgreementNo,1,'', @VLI_Rate, @VLI_Rate*@DaysAuthorized)
			end	
		END
			
		if @UF > 0  and @AuthFromDate != '00000000'
		begin
			if not exists 
			(select EXTRAS_CODE from BCLIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='UF' and RESAUTHVOUCHER=@MultipleDebitorAuthNo and MASTER_AGREEMENT=0)		
			begin			
				INSERT INTO BCLIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES(@MultipleDebitorAuthNo,'00000000' ,'UF', 0, 0, '' ,@UF, @UF*@DaysAuthorized)
			end
			
			if not exists --VIREN INSISTEN ON FRIDAY NOV 29,2013 TO PUT 2 INSERTS STATEMENT ONE WITH 0 AND WITH AGREEMENTNO
			(select EXTRAS_CODE from BCLIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='UF' and RESAUTHVOUCHER='' and MASTER_AGREEMENT=@AgreementNo)		
			begin					
				INSERT INTO BCLIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES('','00000000' ,'UF', @AgreementNo,1,'',@UF, @UF*@DaysAuthorized)
			end	
		end			

		if @WT > 0 and @AuthFromDate != '00000000'
		begin
			if not exists 
			(select EXTRAS_CODE from BCLIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='WT' and RESAUTHVOUCHER=@MultipleDebitorAuthNo)		
			begin
				INSERT INTO BCLIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES(@MultipleDebitorAuthNo,'00000000','WT', 0,0,'',@WT, @WT*@DaysAuthorized)	
			end		
			
			if not exists --VIREN INSISTEN ON FRIDAY NOV 29,2013 TO PUT 2 INSERTS STATEMENT ONE WITH 0 AND WITH AGREEMENTNO
			(select EXTRAS_CODE from BCLIVE..AGREEMENT_EXTRAS (nolock) where EXTRAS_CODE='WT' and RESAUTHVOUCHER='' and MASTER_AGREEMENT=@AgreementNo)		
			begin		
				INSERT INTO BCLIVE..AGREEMENT_EXTRAS(RESAUTHVOUCHER,FROM_DATE,EXTRAS_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,RATE_PER_DAY, F_SUM)
				VALUES('','00000000','WT', @AgreementNo,1,'',@WT, @WT*@DaysAuthorized)							
			end
		end			

		if @CDW > 0 and @AuthFromDate != '00000000'
		begin
			if not exists 
			(select INSURANCE_CODE from ONTARIOLIVE..AGREEMENT_INSURANCES (nolock) where MASTER_AGREEMENT=0 and INSURANCE_CODE='CDW' and RESAUTHVOUCHER=@MultipleDebitorAuthNo)		
			begin
				INSERT INTO ontarioLIVE..AGREEMENT_INSURANCES(RESAUTHVOUCHER,INSURANCE_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,PRICE_PER_DAY, F_SUM)
				VALUES(@MultipleDebitorAuthNo,'CDW', @AgreementNo,0,'', @CDW, @CDW*@DaysAuthorized)	
			end
			
			if not exists 
			(select INSURANCE_CODE from ONTARIOLIVE..AGREEMENT_INSURANCES (nolock) where MASTER_AGREEMENT=@AgreementNo and INSURANCE_CODE='CDW' and RESAUTHVOUCHER='' and SUV_AGREEMENT=1)					
			begin	
				INSERT INTO ontarioLIVE..AGREEMENT_INSURANCES(RESAUTHVOUCHER,INSURANCE_CODE,MASTER_AGREEMENT,SUV_AGREEMENT,QUOTATION_NO,PRICE_PER_DAY, F_SUM)
				VALUES('','CDW', @AgreementNo,1,'', @CDW, @CDW*@DaysAuthorized)				
			end	
		end	
	end --db
	
	IF @DaysAuthorized > 0 and @Authorizedrate > 0 and @Authorized_VehicleCategory != '' 
	BEGIN
			declare @NoteIDAuthorized bigint
			select @NoteIDAuthorized =  max(DCN_ID) + 1 from DA_NOTES_HISTORY(nolock) 
			if not exists 
				(select  DCN_ID from DA_NOTES_HISTORY (nolock) where DCN_ID=@NoteIDAuthorized) and @NoteIDAuthorized is not null
			begin			
				Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
				Values(@NoteIDAuthorized,@RemedyEntryID, 'Extension - # of Days (' +  CONVERT(varchar(8), @DaysAuthorized)+ ')'+ '  Extended Until : ('+ CONVERT(varchar(20),  dbo.convertToDate(@AuthToDate)) +')' ,3,@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
				DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')	
			end
			
			set @Subject = 'Adjuster Authorization (''Note'' ''Auth'')'
			
			select @Body =  '<font face=''verdana'' size=''2''>Claim ID: ' + convert(varchar(20),CONVERT(bigint, @RemedyEntryID)) + '<br><br>' 
			+ 'Claim Number: ' + isnull(@ClaimNo, '') + '<br><br>' +  'Policy Number:' + isnull(@PolicyNo, '') + '<br><br>'  
			+ 'Client Name: ' + isnull(@ClientName, '') + '<br><br>' +  'DRP Shop: ' + isnull(@DRPPay, '') + '<br><br>'  
			+ 'Garage Name:' + isnull(@GarageName, '') + '<br><br>'  
			+ 'Policy Max: ' + isnull(convert(varchar(20), @PolicyMax), '') + '<br><br>' 		
			+ 'Authorized To Date:' + isnull(convert(varchar(20),  dbo.convertToDate(@AuthToDate)), '')  + '<br><br>' 
			+ 'Additional Days Authorized: ' + isnull(convert(varchar(10), @DaysAuthorized), '') + '<br><br>' 
			+ 'Authorized Rate:' + isnull(convert(varchar(20), @Authorizedrate), '') + '<br><br>'  
			+ 'Final Auth: ' + isnull(@FinalAuth, '') + '<br><br>' 
			+ 'Notes:' + isnull(@AuthNotes, '') +  '<br><br></font>'
		
			EXEC msdb..sp_send_dbmail @profile_name='Altbill',
			@recipients=@InternalEmailAddress,
			@from_address  = 'noreply@discountcar.com',
			@subject=@Subject,
			@body_format = 'HTML',	
			@body=@Body	
			
			insert into Carpro_App.dbo.[SendEmailQueue](
				  [dbName]
				  ,[EmailAddress]
				  ,[EmailfromAddress]
				  ,[EmailSubject]
				  ,[EmailBody]   
				  ,EmailFormat
				  ,[EntryTime]
				  ,[EntryUser],
				  EmailSentTime)
			Values ('DIAL3.0', @InternalEmailAddress,'dcatr@discount.com',@Subject, @Body ,'html', getdate(),'DIAL3.0', getdate())	
				
			
		set @AdjusterSubject = 'Discount Rental authorization confirmation'
			
		select @AdjusterBody = '<font face=''verdana'' size=''2''>This email confirms that your rental authorization has been submitted successfully on ' 
		+  convert(varchar(20), GETDATE())   
		+ '<br><br>' + 'Adjuster’s Name: ' + isnull(@AdjusterFirstName, '') + ' ' + isnull(@AdjusterLastName , '')
		+ '<br><br>' + 'Reservation / Entry ID # OR Agreement #: ' 
		+  case when @AgreementNo > 0 then  convert(varchar(20), convert(bigint, @AgreementNo)) else convert(varchar(20), convert(bigint, @RemedyEntryID)) end
		+ '<br><br>' + 'Location: ' + isnull(@LocName, '') + ' ' + isnull(@LocAddress, '') + ' ' 
		+ isnull(@LocCity, '')  + ' ' + isnull(@LocPostalCode, '') + ' ' + isnull(@LocPhone, '')
		+ '<br><br>' + 'Claim No: ' + isnull(@ClaimNo, '')
		+ '<br><br>' + 'Policy Number: ' + isnull(@PolicyNo, '')
		+ '<br><br>' + 'Insured’s Name: ' + isnull(@ClientName, '')
		+ '<br><br>' + 'Insured’s Phone #: ' + isnull(@ClientPhone, '')		
		+ '<br><br>Authorized To Date:' + isnull(convert(varchar(20),  dbo.convertToDate(@AuthToDate)) , '') + '<br><br>' 
		+ 'Additional Days Authorized: ' + isnull(convert(varchar(10), @DaysAuthorized), '') + '<br><br>' 
		+ 'Authorized Rate:' + isnull(convert(varchar(20), @Authorizedrate), '') + '<br><br>'  
		+ 'Final Auth: ' + isnull(@FinalAuth, '') + '<br><br>' 
		+ 'Notes:' + isnull(@AuthNotes, '') +  '<br><br></font>'		
	
		set @AdjusterEmailAddress = @AdjusterEmailAddress+';dialsupport@discountcar.com' 
		
		EXEC msdb..sp_send_dbmail @profile_name='Altbill',
		@recipients=@AdjusterEmailAddress,
		@from_address  = 'noreply@discountcar.com',
		@subject=@AdjusterSubject,
		@body=@AdjusterBody	,
		@body_format = 'HTML'
		
		insert into Carpro_App.dbo.[SendEmailQueue](
				  [dbName]
				  ,[EmailAddress]
				  ,[EmailfromAddress]
				  ,[EmailSubject]
				  ,[EmailBody]   
				  ,EmailFormat
				  ,[EntryTime]
				  ,[EntryUser],EmailSentTime)
		Values ('DIAL3.0', @AdjusterEmailAddress,'noreply@discountcar.com',@AdjusterSubject, @AdjusterBody ,'html', getdate(),'DIAL3.0', GETDATE())
  
	--END		
	
	if @FinalAuth = 'Y'
	begin
			declare @NoteIDFinal bigint
			select  @NoteIDFinal =  max(DCN_ID) + 1 from DA_NOTES_HISTORY(nolock)  
			if not exists 
				(select  DCN_ID from DA_NOTES_HISTORY (nolock) where DCN_ID=@NoteIDFinal)  and @NoteIDFinal is not null
			begin						
				Insert into DA_NOTES_HISTORY(DCN_ID, DCN_CLAIM_ID, DCN_NOTES, DCN_NOTES_TYPE, DCN_USER_ID, DCN_DATE, DCN_TIME,DCN_DOCUMENT_TYPE, DCN_SUBJECT)
				Values(@NoteIDFinal,@RemedyEntryID, '***   FINAL - (' +  CONVERT(varchar(20), dbo.convertToDate(@AuthToDate))+ ')'+'  ***' ,3,
				@LoggedInUserName,CONVERT(varchar(8), getdate(),112), 
				DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate()),1, 'Update from Adjuster')
			end
		
			set @Subject = convert(varchar(20),CONVERT(bigint, @RemedyEntryID)) + ' - FINAL'
			
			select @Body =  '<font face=''verdana'' size=''2''>Claim ID: ' + convert(varchar(20),CONVERT(bigint, @RemedyEntryID)) + '<br><br>' 
			+ 'Claim Number: ' + isnull(@ClaimNo, '') + '<br><br>' +  'Policy Number:' + isnull(@PolicyNo, '') + '<br><br>'  
			+ 'Client Name: ' + isnull(@ClientName, '') + '<br><br>' +  'DRP Shop: ' + isnull(@DRPPay,'') + '<br><br>'  
			+ 'Garage Name:' + isnull(@GarageName, '') + '<br><br>'  
			+ 'Policy Max: ' + isnull(convert(varchar(20), @PolicyMax), '') + '<br><br>' 		
			+ 'Authorized To Date:' + isnull(convert(varchar(20),  dbo.convertToDate(@AuthToDate)) , '') + '<br><br>' 
			+ 'Additional Days Authorized: ' + isnull(convert(varchar(10), @DaysAuthorized), '') + '<br><br>' 
			+ 'Authorized Rate:' + isnull(convert(varchar(20), @Authorizedrate), '') + '<br><br>'  
			+ 'Final Auth: ' + isnull(@FinalAuth, '') + '<br><br>' 
			+ 'Notes:' + isnull(@AuthNotes, '') +  '<br><br></font>'	
		
			EXEC msdb..sp_send_dbmail @profile_name='Altbill',
			@recipients=@InternalEmailAddress,
			@from_address  = 'noreply@discountcar.com',
			@subject=@Subject,
			@body_format = 'HTML',	
			@body=@Body	
			
			insert into Carpro_App.dbo.[SendEmailQueue](
				  [dbName]
				  ,[EmailAddress]
				  ,[EmailfromAddress]
				  ,[EmailSubject]
				  ,[EmailBody]   
				  ,EmailFormat
				  ,[EntryTime]
				  ,[EntryUser],
				  EmailSentTime)
			Values ('DIAL3.0', @InternalEmailAddress,'dcatr@discount.com',@Subject, @Body ,'html', getdate(),'DIAL3.0', getdate())
		end		
		
		IF @DaysAuthorized > 0 and @Authorizedrate > 0 and @Authorized_VehicleCategory != ''
			set @iProcessCode=2		
		else if @FinalAuth = 'Y'
			set @iProcessCode=6
		else 
			set @iProcessCode=3
		
		insert into tblDIAL_UsersLog (Adjuster_Username, ip_address, flag, Process_Code, entry_id) 
		values (@AdjusterUserName, @ClientIp, 1, @iProcessCode, @RemedyEntryID)	

	END
	
	
   










