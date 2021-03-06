USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Locations]    Script Date: 04/05/2018 09:37:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec spDIAL_Locations  @city_code = 3133
--exec spDIAL_Locations  @Province_Code = 3
--exec spDIAL_Locations 3, null, 'm8z'
--exec spDIAL_Locations null, null, 'm8z'
ALTER Proc [dbo].[spDIAL_Locations]
@Province_Code int = null,
@City_Code int = null,
@Postal_Code varchar(20) =null
as
begin

SELECT B.BRANACH_CODE AS BRANACHCODE,B2.BR_LATITUDE AS BRLATITUDE ,B2.BR_LONGITUDE AS BRLONGITUDE,POSTAL_NO AS POSTALNO,
--P.PROVINCIENAAM AS PROVINCENAME, 
 (SELECT PROVINCIENAAM FROM PROVINCIES P (nolock) WHERE P.PROVINCIECODE=B.PROVINCE_CODE ) AS PROVINCENAME, 
 (SELECT NAME FROM CITIESAREAS C (nolock) WHERE C.CODE=B.BRANCH_CITY ) AS BRANCHCITYNAME, 
 --C.NAME AS BRANCHCITYNAME, 
 STREET,TELEPHONE1,BRANACH_NAME AS BRANACHNAME,HOUSE_NUMBER AS HOUSENUMBER,BRANCH_CITY AS BRANCHCITY,COUNTRY,FAX--,
 FROM BRANCHES B(nolock), BRANCHES_SEC_TWO B2(nolock)  
 --LEFT OUTER JOIN dbo.PROVINCIES P(nolock) ON P.PROVINCIECODE=B.PROVINCE_CODE
 --LEFT OUTER JOIN dbo.CITIESAREAS C(nolock) ON C.CODE=B.BRANCH_CITY	
WHERE 
B.BRANACH_CODE = B2.BRANCH_CODE and
(@Province_Code is null or  B.PROVINCE_CODE= @Province_Code)
AND (B.BRANCH_STATUS = 'A') and B.PORTAL_RES=1
AND ((@City_Code is null or B.BRANCH_CITY=@City_Code)
and (@Postal_Code is null or (@City_Code is null and len(ltrim(rtrim(@Postal_Code))) > 0 
and left(ltrim(rtrim(@Postal_Code)),3) = left(ltrim(rtrim(b.POSTAL_NO)),3)))
)
order by BRANACH_NAME

end



