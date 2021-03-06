USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Dealer]    Script Date: 04/05/2018 09:33:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--Get the Garages
-- exec spDIAL_Dealer @Dealer_Name ='RIDGEHILL FORD LTD (DEALERSHIP)', @bIsCurrentOpen =0
-- exec spDIAL_Dealer  @bIsCurrentOpen =0
-- exec spDIAL_Dealer @lat = 43.65,@lon=-79.38
ALTER Proc [dbo].[spDIAL_Dealer] 
@Dealer_Name varchar(50) ='myers', @Lat float = null,  @Lon float = null,  
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
		select a.DEBITOR_CODE as DEALER_NO, convert(float,p.latitude) GR_LATITUDE, convert(float,p.longitude) GR_LONGITUDE
		 ,DEBITOR_NAME Dealer_Name, A.BILLING_ADDRESS Street, a.CITY_BILLING City, replace(replace(ltrim(rtrim(a.ZIF_BILLING)), ' ', ''), '-', '') Postal, A.CONTACT1_TEL Phone
		 into #myTemp
		FROM Debitors a(nolock)	inner join DEBITORS_SECTION2 D (nolock) on a.DEBITOR_CODE = d.DEBITOR_CODE
		inner join Carpro_App..tblPotalCode_Lat_Lon_Canada p  (nolock) on  p.PostalCode = replace(replace(ltrim(rtrim(a.ZIF_BILLING)), ' ', ''), '-', '')
		where 1=2 and  a.DEBITOR_TYPE='D'  and a.DEBITOR_CODE = d.DEBITOR_CODE and d.IN_STOP_LIST = 'A' and a.DEBITOR_CODE >0 
		and ((@Dealer_Name is null or A.DEBITOR_NAME like '%' + @Dealer_Name +'%' ))
		
		if @Lat is null 
		begin		
			insert into  #myTemp
			select a.DEBITOR_CODE as DEALER_NO, convert(float,p.latitude) GR_LATITUDE, convert(float,p.longitude) GR_LONGITUDE
			 ,DEBITOR_NAME Dealer_Name, A.BILLING_ADDRESS Street, a.CITY_BILLING City, replace(replace(ltrim(rtrim(a.ZIF_BILLING)), ' ', ''), '-', '') Postal, A.CONTACT1_TEL Phone		
			FROM debitors a(nolock) 		
			inner join DEBITORS_SECTION2 D (nolock) on a.DEBITOR_CODE = d.DEBITOR_CODE
			inner join Carpro_App..tblPotalCode_Lat_Lon_Canada p  (nolock) on  p.PostalCode = replace(replace(ltrim(rtrim(a.ZIF_BILLING)), ' ', ''), '-', '')
			where  a.DEBITOR_TYPE='D'  and a.DEBITOR_CODE = d.DEBITOR_CODE and d.IN_STOP_LIST = 'A' and a.DEBITOR_CODE >0 
			and ((@Dealer_Name is null or A.DEBITOR_NAME like '%' + @Dealer_Name +'%' ))
		end
		else
		begin		
			insert into  #myTemp
			select Code as DEALER_NO, convert(float,GR_LATITUDE) GR_LATITUDE, convert(float,GR_LONGITUDE)
			 ,DEBITOR_NAME, Street, City, Postal, Phone
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
			SELECT 
			A.DEBITOR_CODE Code, A.DEBITOR_NAME, convert(float,p.latitude) GR_LATITUDE, convert(float,p.longitude) GR_LONGITUDE, Radians(@lat -	p.latitude) AS dLat,
			Radians(@lon - 	p.longitude) dLon,
			A.BILLING_ADDRESS Street, a.CITY_BILLING City, replace(replace(ltrim(rtrim(a.ZIF_BILLING)), ' ', ''), '-', '') Postal, A.CONTACT1_TEL Phone
			FROM debitors a(nolock)
			inner join DEBITORS_SECTION2 D (nolock) on a.DEBITOR_CODE = d.DEBITOR_CODE
			inner join Carpro_App..tblPotalCode_Lat_Lon_Canada p  (nolock) on  p.PostalCode = replace(replace(ltrim(rtrim(a.ZIF_BILLING)), ' ', ''), '-', '')
			where  a.DEBITOR_TYPE='D'  and a.DEBITOR_CODE = d.DEBITOR_CODE and d.IN_STOP_LIST = 'A' and a.DEBITOR_CODE >0  
			and (@Dealer_Name is null or A.DEBITOR_NAME like '%' + @Dealer_Name +'%' )			
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

		select DEALER_NO, Code as Branch_Code, BR_LATITUDE, BR_LONGITUDE, Distance_KM
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
		SELECT c.DEALER_NO,B.BRANCH_CODE Code, BR_LATITUDE, BR_LONGITUDE, Radians(c.GR_LATITUDE -	BR_LATITUDE) AS dLat,
		Radians(c.GR_LONGITUDE - BR_LONGITUDE) dLon
		,A.BRANACH_NAME, A.STREET Street, a.CITY City, a.POSTAL_NO Postal, A.[STATE] [State], A.TELEPHONE1 Phone, GR_LATITUDE
		FROM BRANCHES a(nolock) inner join
		BRANCHES_SEC_TWO b(nolock)  ON a.BRANACH_CODE = b.BRANCH_CODE
		right join #myTemp c(nolock)
		on 1=1
		where a.BRANCH_STATUS = 'A' 
		and ltrim(rtrim(b.BR_LATITUDE)) !=''
		and ltrim(rtrim(c.Postal)) !=''
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
			select DEALER_NO,  a.Branch_Code, BR_LATITUDE, BR_LONGITUDE, Distance_KM
			, Branch_Name, Street, City, Postal, [State], Phone, b.OpenHour
			from #myBranchHour a left join
			#myBranch b on
			a.Branch_Code = b.Branch_Code
		else
		begin
		
			declare @WeekDayToday varchar(20), @iCurrentTime bigint
			select @WeekDayToday = datepart(DW, GETDATE()), @iCurrentTime= (DATEPART(hh, GETDATE()) * 3600) + (DATEPART(mi, GETDATE()) * 60) + DATEPART(ss, GETDATE())

			select DEALER_NO,  a.Branch_Code, BR_LATITUDE, BR_LONGITUDE, Distance_KM
			, Branch_Name, Street, City, Postal, [State], Phone, b.OpenHour
			from #myBranchHour a left join
			#myBranch b on
			a.Branch_Code = b.Branch_Code inner join BRANACH_SCHEDULES c(nolock)
		 on a.Branch_Code = c.BRANACH
		 where c.KIND_DAY_CODE between 1 and 7
		 and c.KIND_DAY_CODE = @WeekDayToday
		 and @iCurrentTime between c.WORK_FROM and c.WORK_TO

		
		end		
		
		
	--	select * from #myTemp where LTRIM(rtrim(Postal)) !=''

		drop table #myBranch	
		drop table #myBranchHour	
		drop table #myTemp




