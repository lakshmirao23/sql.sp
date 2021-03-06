USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_UpdateRes_For_Webservice]    Script Date: 04/05/2018 09:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[spDIAL_UpdateRes_For_Webservice] 	
@RemedyEntryID bigint = 3233832, 
@AdjusterID bigint = 17724,  
@RentalControlledBy varchar(30) = '', 
@RepairLocation bigint = 2597,
@TotalLoss varchar(1) = '', 
@ClaimType int = 0,
@PolicyMax decimal (18, 2) = 0.00,
@UpgradeRequested int = 0, 
@ClientIp varchar(100) = '',
@LoggedInUserName varchar(20) = 'UNKNOWN'

AS

BEGIN	

	SET NOCOUNT ON;	
	
	Declare @ModyorCreatedDate varchar(8), @ModyorCreateTime int
	Declare @GarageName varchar(200), @GarageAddress varchar(300), @GaragePhone varchar(20), @GarageCity varchar(50), @GaragePostalCode varchar(30), @GarageEmail varchar(200)
	
	set @ModyorCreatedDate = CONVERT(varchar(8), GETDATE(), 112)
	set @ModyorCreateTime = DATEPART(hour,getdate())*60*60 +DATEPART(MINUTE,getdate())*60+ DATEPART(SECOND,getdate())
	
	SELECT @GarageName = GARAGE_NAME, @GarageAddress = ADDRESS, @GaragePhone = TEL_NO, @GarageCity = CITY, @GaragePostalCode = ZIF_CODE, 
	@GarageEmail = EMAIL_ADDRESS FROM GARAGES (nolock) WHERE GARAGE_NO = @RepairLocation
		
	UPDATE DA_CLAIMS SET  
	DAC_SUBMITTER = @LoggedInUserName ,	
	DAC_MODIFIED_DATE = @ModyorCreatedDate ,
	DAC_MODIFIED_TIME = @ModyorCreateTime ,
	DAC_LAST_MODIFIED_BY = @LoggedInUserName ,
	DAC_UPGRADE_REQUESTED = isnull(@UpgradeRequested, ''),		
	DAC_RENTAL_CONTROLLED_BY = isnull(@RentalControlledBy , ''),
	DAC_MAX_ALLOW = isnull(@PolicyMax, 0),		
	DAC_TOTAL_LOSS = isnull(@TotalLoss, ''),
	DAC_CLAIM_TYPE = isnull(@ClaimType, 0),	
	DAC_GARAGE_NAME = isnull(@GarageName, ''),
	DAC_GARAGE_ADDRESS = isnull(@GarageAddress, ''),
	DAC_GARAGE_PHONE = isnull(@GaragePhone, ''),
	DAC_GARAGE_CITY = isnull(@GarageCity, ''),	
	DAC_GARAGE_POSTAL_CODE = isnull(@GaragePostalCode, ''),
	DAC_GARAGE_EMAIL = ISNULL(@GarageEmail, '') ,
	DAC_GARAGE_ID = @RepairLocation		
	WHERE DAC_ENTRY_ID = @RemedyEntryId		
	
	
END
	
	
   













