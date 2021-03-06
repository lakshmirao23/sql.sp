USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_SendTextMessage]    Script Date: 04/05/2018 09:40:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec [spDIAL_SendTextMessage] @sTextNumber = '6474478545', @EntryID = 3163058

ALTER proc [dbo].[spDIAL_SendTextMessage] 
@sMessage varchar(160) = null , @sTextNumber varchar(20) = null, @AdjusterID bigint = null, @EntryID bigint
as
begin
	-- add code here to check Lakshmi's new OPT-IN table for cell phone numbers
	declare @opt_in char(1)
	
	declare @LocAddress varchar(300), @LocCode bigint, @LocPhoneNo varchar(20)
	
	select @LocCode = dac_location_code from DA_CLAIMS (nolock) where DAC_ENTRY_ID = @EntryID
	
	if @LocCode > 0 
		begin
		  select @LocAddress = ltrim(rtrim(street)) + ', ' + ltrim(rtrim(city)) + ', ' + ltrim(rtrim(postal_no)) from BRANCHES (nolock) where BRANACH_CODE = @LocCode
		  select @LocPhoneNo = ltrim(rtrim(telephone1)) from BRANCHES (nolock) where BRANACH_CODE = @LocCode	  
		  
		  set  @sMessage = 'Your adjuster has arranged a rental for you with Discount Car @ ' + @LocAddress +', Phone # ' + @LocPhoneNo + ' . Your reference # '+ cast(cast(@EntryID as bigint) as varchar(10)) +'.'
		  
		end
	else if @LocCode = 0
		begin
			set  @sMessage = 'Your adjuster has arranged a rental for you with Discount Car.  Your reference # '+ cast(cast(@EntryID as bigint) as varchar(10)) +'. We will contact you shortly or you can call us at 1-800-404-4142.'	  
		end	
		
		--select @sMessage
		--select @LocCode
		
		--select dac_location_code from DA_CLAIMS (nolock) where DAC_ENTRY_ID = 3163058	
		
	select @opt_in = oi.Opt_In
	  from [Carpro_App].[dbo].[tblOptIn] oi (nolock)
	 where oi.cell_phone_number = @sTextNumber
	 
	if @opt_in is null
	begin
		set @opt_in='Y'
		
		insert [Carpro_App].[dbo].[tblOptIn]
			(
				 cell_phone_number
				,opt_in
				,added_datetime
				,updated_datetime
				, Inserted_By
				--, user
			)
			values
			(
				 @sTextNumber
				,@opt_in
				,GETDATE()
				,GETDATE()
				,@AdjusterID
				--, user
			)
	end
	  
	if @opt_in = 'Y'
	begin
		insert into [Carpro_App].[dbo].[SendQueue]
		(
			[net_number]
			,[message]
		)
		values(@sTextNumber,@sMessage)
	end
end


--select * from carpro_app.dbo.[tblOptIn] order by opt_id desc
-- select * from carpro_app.dbo.[SendQueue] order by id desc