USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Garage_Branch_Location]    Script Date: 04/05/2018 09:35:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Get the Branch_Locations close to Garages
--Return the close branch information
ALTER Proc [dbo].[spDIAL_Garage_Branch_Location] 
@Garage_No varchar(50) =null,  @distant float =25.0
as

	Declare @R Float(8), @lat float, @lon float

	Set @R =   6367.45 
	--http://weblogs.asp.net/jimjackson/archive/2009/02/13/calculating-distances-between-latitude-and-longitude-t-sql-haversine.aspx
	--Case @ReturnType  
            --When 'Miles' Then 3956.55  
            --When 'Kilometers' Then 6367.45 
            --When 'Feet' Then 20890584 
            --When 'Meters' Then 6367450 
            --Else 20890584 -- Default feet (Garmin rel elev) 
            --End 

		select   @lat = GR_LATITUDE, @lon =GR_LONGITUDE
		FROM GARAGES a(nolock)
		where  a.GROUF_CODE =3 
		

		select Code as Branch_Code, BR_LATITUDE, BR_LONGITUDE, Distance_KM
		 ,BRANACH_NAME Branch_Name, Street, City, Postal, [State], Phone
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
		SELECT B.BRANCH_CODE Code, BR_LATITUDE, BR_LONGITUDE, Radians(@lat -	BR_LATITUDE) AS dLat,
		Radians(@lon - BR_LONGITUDE) dLon
		,A.BRANACH_NAME, A.STREET Street, a.CITY City, a.POSTAL_NO Postal, A.[STATE] [State], A.TELEPHONE1 Phone
		FROM BRANCHES a(nolock) inner join
		BRANCHES_SEC_TWO b(nolock)  ON a.BRANACH_CODE = b.BRANCH_CODE
		where a.BRANCH_STATUS = 'A' 
		) T1
		) T2
		) T3
		where Distance_KM < @distant
		order by Distance_KM
		





