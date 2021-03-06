USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Garage]    Script Date: 04/05/2018 09:35:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- insert into tblDIAL_Discount_Garage_Onsite(Garage_No, Discount_Location_Code, Onsite) values (2084, 303, 1)

--Get the Garages
-- exec spDial_garage @garage_name='maaco'  , @bIsCurrentOpen = 1   
-- exec spDial_garage @garage_name='maaco'  , @bIsCurrentOpen = 0                                                                                    '
--exec spDIAL_Garage @Garage_Name ='city', @bIsCurrentOpen =0
--exec spDIAL_Garage @Garage_Name ='city', @bIsCurrentOpen =1
-- exec spDIAL_Garage @lat = 43.0592,@lon=-79.1481  
ALTER Proc [dbo].[spDIAL_Garage] 
@Garage_Name varchar(50) =null, @Lat float = null,  @Lon float = null,  
@distant_garage  float =1000.0, @distant_location float =100.0, @bIsCurrentOpen bit = 0
as

	Declare @R Float(8); 

	Set @R =   6367.45 
	--http://weblogs.asp.net/jimjackson/archive/2009/02/13/calculating-distances-between-latitude-and-longitude-t-sql-haversine.aspx
	--Case @ReturnType  
            --When 'Miles' Then 3956.55  
            --When 'Kilometers' Then 6367.45 
            --When 'Feet' Then 20890584 
            --When 'Meters' Then 6367450 
            --Else 20890584 -- Default feet (Garmin rel elev) 
            --End 
		select a.GARAGE_NO as GARAGE_NO, convert(float,GR_LATITUDE) GR_LATITUDE, convert(float,GR_LONGITUDE) GR_LONGITUDE
		 ,GARAGE_NAME, replace(A.[ADDRESS], '', '`') as Street, City, a.ZIF_CODE Postal, A.TEL_NO Phone, case when ISNULL(onsite, 0) = 1 then '*** Discount Car and Truck Rentals Onsite ***' else '' end Onsite
		 into #myTemp
		FROM GARAGES a(nolock) 
		left join DEBITORS_SECTION2 D (nolock) on a.DEBITOR_CODE = d.DEBITOR_CODE
		left join tblDIAL_Discount_Garage_Onsite Onsite on Onsite.Garage_No = a.Garage_No
		where 1=2 and a.GROUF_CODE =3  and a.DEBITOR_CODE = d.DEBITOR_CODE and d.IN_STOP_LIST = 'A' and a.DEBITOR_CODE >0 
	
		if @Lat is null 
		begin
		
		insert into  #myTemp
		select a.GARAGE_NO as GARAGE_NO, convert(float,GR_LATITUDE) GR_LATITUDE, convert(float,GR_LONGITUDE) GR_LONGITUDE
		 ,GARAGE_NAME, replace(A.[ADDRESS], '', '`') as Street, City, a.ZIF_CODE Postal, A.TEL_NO Phone, case when ISNULL(onsite, 0) = 1 then '*** Discount Car and Truck Rentals Onsite ***' else '' end Onsite
		 --into #myTemp
		FROM GARAGES a(nolock) 
		--request came on dec 13, 2014 from matt and rahim to show only active garages
		left join DEBITORS_SECTION2 D (nolock) on a.DEBITOR_CODE = d.DEBITOR_CODE 
		left join tblDIAL_Discount_Garage_Onsite Onsite on Onsite.Garage_No = a.Garage_No
		where  a.GROUF_CODE =3  and a.DEBITOR_CODE = d.DEBITOR_CODE and d.IN_STOP_LIST = 'A' and a.DEBITOR_CODE >0 
		and ((@Garage_Name is null or A.GARAGE_NAME like '%' + @Garage_Name +'%' )
		--and (@Lat is null or (@Lat  = a.GR_LATITUDE and  @Lon =a.GR_LONGITUDE ))
		)
		end
		else
		begin
		
		insert into  #myTemp
		select Code as GARAGE_NO, convert(float,GR_LATITUDE) GR_LATITUDE, convert(float,GR_LONGITUDE)
		 ,GARAGE_NAME, Street, City, Postal, Phone, case when ISNULL(onsite, 0) = 1 then '*** Discount Car and Truck Rentals Onsite ***' else '' end Onsite
		from
		(
		SELECT T2.*, round(2 * Asin(Sqrt(T2.a))*@R,2) Distance_KM
		FROM
		(
		SELECT T1.*, Sin(dLat / 2)  
                 * Sin(dLat / 2)  
                 + Cos(Radians(GR_LATITUDE)) 
                 * Cos(Radians(@lat))  
                 * Sin(dLon / 2)  
                 * Sin(dLon / 2) a
		FROM
		(
		SELECT A.GARAGE_NO Code, A.GARAGE_NAME, GR_LATITUDE, GR_LONGITUDE, Radians(@lat -	GR_LATITUDE) AS dLat,
		Radians(@lon - GR_LONGITUDE) dLon
		, replace(A.[ADDRESS], '', '`') as Street, a.CITY City, a.ZIF_CODE Postal, A.TEL_NO Phone, Onsite
		FROM GARAGES a(nolock) left join DEBITORS_SECTION2 D (nolock) on a.DEBITOR_CODE = d.DEBITOR_CODE
		left join tblDIAL_Discount_Garage_Onsite Onsite on Onsite.Garage_No = a.Garage_No
		where  a.GROUF_CODE =3  and a.DEBITOR_CODE = d.DEBITOR_CODE and d.IN_STOP_LIST = 'A' and a.DEBITOR_CODE >0  
		and (@Garage_Name is null or A.GARAGE_NAME like '%' + @Garage_Name +'%' )	
		) T1
		) T2
		) T3
		where Distance_KM < @distant_garage
		order by Distance_KM            

	
	
	
	
		end
		
		select top 25 * 
		into #myTemp1
		from #myTemp 
		
		truncate table #myTemp
		
		insert into #myTemp
		select * from #myTemp1
		
		drop table #myTemp1
		
		select * from #myTemp --order by Distance_KM		

		select GARAGE_NO, Code as Branch_Code, BR_LATITUDE, BR_LONGITUDE, Distance_KM
		 ,BRANACH_NAME Branch_Name, Street, City, Postal, [State], Phone
		 into #myBranchHour
		from
		(
		SELECT T2.*, round(2 * Asin(Sqrt(T2.a))*@R,2) Distance_KM
		FROM
		(
		SELECT T1.*, Sin(dLat / 2)  
                 * Sin(dLat / 2)  
                 + Cos(Radians(BR_LATITUDE)) 
                 * Cos(Radians(GR_LATITUDE))  
                 * Sin(dLon / 2)  
                 * Sin(dLon / 2) a
		FROM
		(
		SELECT c.GARAGE_NO,B.BRANCH_CODE Code, BR_LATITUDE, BR_LONGITUDE, Radians(c.GR_LATITUDE -	BR_LATITUDE) AS dLat,
		Radians(c.GR_LONGITUDE - BR_LONGITUDE) dLon
		,A.BRANACH_NAME, A.STREET Street, a.CITY City, a.POSTAL_NO Postal, A.[STATE] [State], A.TELEPHONE1 Phone, GR_LATITUDE
		FROM BRANCHES a(nolock) inner join
		BRANCHES_SEC_TWO b(nolock)  ON a.BRANACH_CODE = b.BRANCH_CODE
		right join #myTemp c(nolock)
		on 1=1
		where a.BRANCH_STATUS = 'A' 
		and ltrim(rtrim(b.BR_LATITUDE)) !=''
		and ltrim(rtrim(c.Postal)) !='' 
		and a.PORTAL_RES = 1 and a.KIOSK = 0 
		) T1
		) T2
		) T3
		where Distance_KM < @distant_location
		order by 1,5
		
		

		
		declare @iCount int =1, @iTotalCount int, @sOpenHour varchar(300), @iBranch_Code int
		
		select IDENTITY(INT,1,1) myID, Branch_Code, CONVERT(varchar(300), '') OpenHour
		into #myBranch
		from
		(
		select distinct Branch_Code
		from #myBranchHour
		) t10
		
		select @iTotalCount =MAX(myID) from #myBranch
 
 While (@iCount <= @iTotalCount)
 begin
 
	
	select @iBranch_Code = branch_code from #myBranch where myID =@iCount
	
	exec spDIAL_Locations_OpenHour @iBranch_Code, @sOpenHour  output
	
	update #myBranch
	set OpenHour = @sOpenHour
	where myID = @iCount
 
	select @iCount = @iCount +1
 end
 
		if @bIsCurrentOpen = 0
			select a.GARAGE_NO,  a.Branch_Code, BR_LATITUDE, BR_LONGITUDE, Distance_KM
			, Branch_Name, Street, City, Postal, [State], Phone, b.OpenHour
			--, isnull(Onsite, 0) Onsite
			from #myBranchHour a left join #myBranch b on a.Branch_Code = b.Branch_Code
			--left join tblDIAL_Discount_Garage_Onsite Onsite on Onsite.Garage_No = a.Garage_No
		else
		begin
		
			declare @WeekDayToday varchar(20), @iCurrentTime bigint
			select @WeekDayToday = datepart(DW, GETDATE()), @iCurrentTime= (DATEPART(hh, GETDATE()) * 3600) + (DATEPART(mi, GETDATE()) * 60) + DATEPART(ss, GETDATE())

			select a.GARAGE_NO,  a.Branch_Code, BR_LATITUDE, BR_LONGITUDE, Distance_KM
			, Branch_Name, Street, City, Postal, [State], Phone, b.OpenHour from #myBranchHour a 
			left join #myBranch b on a.Branch_Code = b.Branch_Code inner join BRANACH_SCHEDULES c(nolock)			
		 on a.Branch_Code = c.BRANACH
		 where c.KIND_DAY_CODE between 1 and 7
		 and c.KIND_DAY_CODE = @WeekDayToday
		 and @iCurrentTime between c.WORK_FROM and c.WORK_TO

		
		end		
		
		
	--	select * from #myTemp where LTRIM(rtrim(Postal)) !=''

		drop table #myBranch	
		drop table #myBranchHour	
		drop table #myTemp



