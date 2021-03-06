USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Locations_Schedule]    Script Date: 04/05/2018 09:37:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec spDIAL_Locations_Schedule @lat= 43.7471, @lon=	-79.5305,@distant =25, @OnlyShowOpenLocation = 1
--exec spDIAL_Locations_Schedule @lat= 43.7471, @lon=	-79.5305,@distant =25, @OnlyShowOpenLocation = 0

ALTER Proc [dbo].[spDIAL_Locations_Schedule]
 @lat float, @lon float, @distant float =25.0, @OnlyShowOpenLocation bit = 1
as
      Declare @R Float(8); 

      Set @R =   6367.45  
      
       SELECT B.BRANCH_CODE Code, BR_LATITUDE, BR_LONGITUDE
            ,A.BRANACH_NAME, A.STREET Street, a.CITY City, a.POSTAL_NO Postal, A.[STATE] [State], A.TELEPHONE1 Phone, a.KIOSK as IsKiosk
            into #myTemp1
            FROM BRANCHES a(nolock) inner join
            BRANCHES_SEC_TWO b(nolock)  ON a.BRANACH_CODE = b.BRANCH_CODE
            where a.BRANCH_STATUS = 'A'  and b.BRANCH_CODE > 99 and b.branch_code <> 165 and a.PORTAL_RES = 1      

		select Code as Branch_Code, BR_LATITUDE, BR_LONGITUDE, Distance_KM
		 ,BRANACH_NAME Branch_Name, Street, City, Postal, [State], Phone, IsKiosk 
		 , CONVERT(varchar(300),'') Open_Hour, ROW_NUMBER() over (order by Distance_KM) myID
		 into #myTemp
		from
		(
		SELECT T2.*, round(2 * Asin(Sqrt(T2.a))*@R,2) Distance_KM
		FROM
		(
		SELECT T1.*, Sin(dLat / 2)  
                 * Sin(dLat / 2)  
                 + Cos(Radians(BR_LATITUDE)) 
                 * Cos(Radians(@lat))  
                 * Sin(dLon / 2)  
                 * Sin(dLon / 2) a
		FROM
		(
		 SELECT Code, BR_LATITUDE, BR_LONGITUDE, Radians(@lat -    BR_LATITUDE) AS dLat,
            Radians(@lon - BR_LONGITUDE) dLon
            ,BRANACH_NAME, Street,City, Postal, [State], Phone, IsKiosk
            FROM #myTemp1
		) T1
		) T2
		) T3
		where Distance_KM < @distant
		order by Distance_KM


 declare @iCount int =1, @iTotalCount int, @sOpenHour varchar(300), @iBranch_Code int
 
 select @iTotalCount =MAX(myID) from #myTemp
 
 While (@iCount <= @iTotalCount)
 begin
 
	
	select @iBranch_Code = branch_code from #myTemp where myID =@iCount
	
	exec spDIAL_Locations_OpenHour @iBranch_Code, @sOpenHour  output
	
	update #myTemp
	set Open_Hour = @sOpenHour
	where myID = @iCount
 
	select @iCount = @iCount +1
 end
 
 if @OnlyShowOpenLocation = 0
	 select  Branch_Code, Branch_Name, BR_LATITUDE, BR_LONGITUDE, Distance_KM , Open_Hour , Street, a.City, Postal, [State], Phone 
	 ,case when g.GARAGE_NAME != '' then '*** Discount Car Onsite @ ' + left(ltrim(rtrim(g.GARAGE_NAME)), 20) + ' ***' else '' end as Onsite,
	 case when IsKiosk = 1 then 'Quick Car Kiosk' else '' end as IsKiosk
     from #myTemp a
     left join tblDIAL_Discount_Garage_Onsite o on o.Discount_Location_Code = branch_code
     left join GARAGES (nolock) g on g.GARAGE_NO = o.Garage_No
     where isnull(Open_Hour, '') != ''
 else
 begin
 
	declare @WeekDayToday varchar(20), @iCurrentTime bigint
	select @WeekDayToday = datepart(DW, GETDATE()), @iCurrentTime= (DATEPART(hh, GETDATE()) * 3600) + (DATEPART(mi, GETDATE()) * 60) + DATEPART(ss, GETDATE())

	 select  Branch_Code, Branch_Name, BR_LATITUDE, BR_LONGITUDE, Distance_KM , Open_Hour , Street, #myTemp.City, Postal, [State], Phone
	 ,case when g.GARAGE_NAME != '' then '*** Discount Car Onsite @ ' + left(ltrim(rtrim(g.GARAGE_NAME)), 20) + ' ***' else '' end as Onsite,
	 case when IsKiosk = 1 then 'Quick Car Kiosk' else '' end as IsKiosk 
	 from #myTemp 
	 inner join BRANACH_SCHEDULES a(nolock)	 on #myTemp.Branch_Code = a.BRANACH
	 left join tblDIAL_Discount_Garage_Onsite o on o.Discount_Location_Code = branch_code
     left join GARAGES (nolock) g on g.GARAGE_NO = o.Garage_No
	 where a.KIND_DAY_CODE between 1 and 7 
	 and a.KIND_DAY_CODE = @WeekDayToday
	 and @iCurrentTime between a.WORK_FROM and a.WORK_TO
		 
 end
 drop table #myTemp
 drop table #myTemp1
 




