USE [Carpro_App]
GO
/****** Object:  StoredProcedure [dbo].[spBannerNetworkReport]    Script Date: 04/05/2018 09:42:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EXEC spBannerNetworkReport
ALTER PROCEDURE [dbo].[spBannerNetworkReport]
	@START_DATE VARCHAR(10) = '20170701', 
	@END_DATE VARCHAR(10) = '20170730',
	@BannerCode int = 3,
	@GarageCode varchar(8000) = '',
	@DebitorCode varchar(8000) = '',
	@LossType varchar(3) = ''
AS
BEGIN
	
		DECLARE
	@BEGIN datetime, --'10/01/2011'
	@END  datetime--'12/01/2011'
	
	SET   @BEGIN = CONVERT(VARCHAR, CONVERT(DATETIME, @START_DATE), 101)
	SET   @END = CONVERT(VARCHAR, CONVERT(DATETIME, @END_DATE), 101)
	SET   @END = DATEADD(SECOND, 24*60*60-1, @END)
	
	 if OBJECT_ID('tempdb..#tblGARAGENOS') is not null
	drop table #tblGARAGENOS
	
	if OBJECT_ID('tempdb..#tblGARAGENOSALL') is not null
	drop table #tblGARAGENOSALL	
	
	if OBJECT_ID('tempdb..#tblDEBITORS') is not null
	drop table #tblDEBITORS	
	
	if OBJECT_ID('tempdb..#tblDEBITORSAll') is not null
	drop table #tblDEBITORSAll	
	
	Create table #tblGARAGENOS
	(
	       GARAGE_NO INT
	)	
	
	Create table #tblGARAGENOSALL
	(
	       GARAGE_NO INT,
	       GARAGE_NAME varchar(255)
	)	
	
	Create table #tblDEBITORS
	(
	       DEBITOR_CODE BIGINT
	)
	
	Create table #tblDEBITORSAll
	(
	       DEBITOR_CODE BIGINT
	)

	INSERT INTO #tblGARAGENOS
	Select * from Carpro_App.dbo.ufn_String_To_Table(@GarageCode)	
	
	INSERT INTO #tblDEBITORS
	Select * from Carpro_App.dbo.ufn_String_To_Table(@DebitorCode)	
			
	INSERT INTO #tblDEBITORSAll	
	select DEBITOR_CODE  from OntarioLive..DEBITORS (nolock) where DEBITOR_CODE in (select DEBITOR_CODE from #tblDEBITORS) or SUV_DEBITOR_OF in (select DEBITOR_CODE from #tblDEBITORS)
		
	INSERT INTO #tblGARAGENOSALL	
	select GARAGE_NO, GARAGE_NAME   from OntarioLive..GARAGES (nolock) where GARAGE_NAME in (select GARAGE_NAME from #tblGARAGENOS T INNER JOIN OntarioLive..GARAGES G(NOLOCK) ON T.GARAGE_NO = G.GARAGE_NO)
	UNION
	select GARAGE_NO, GARAGE_NAME   from AlbertaLive..GARAGES (nolock) where GARAGE_NAME in (select GARAGE_NAME from #tblGARAGENOS T INNER JOIN OntarioLive..GARAGES G(NOLOCK) ON T.GARAGE_NO = G.GARAGE_NO)
	UNION
	select GARAGE_NO, GARAGE_NAME  from MaritimesLive..GARAGES (nolock) where GARAGE_NAME in (select GARAGE_NAME from #tblGARAGENOS T INNER JOIN OntarioLive..GARAGES G(NOLOCK) ON T.GARAGE_NO = G.GARAGE_NO)
	UNION
	select GARAGE_NO, GARAGE_NAME  from BCLive..GARAGES (nolock) where GARAGE_NAME in (select GARAGE_NAME from #tblGARAGENOS T INNER JOIN OntarioLive..GARAGES G(NOLOCK) ON T.GARAGE_NO = G.GARAGE_NO)	
	UNION
	select GARAGE_NO, GARAGE_NAME   from SaskatchewanLive2..GARAGES (nolock) where GARAGE_NAME in (select GARAGE_NAME from #tblGARAGENOS T INNER JOIN OntarioLive..GARAGES G(NOLOCK) ON T.GARAGE_NO = G.GARAGE_NO)	
	UNION
	select GARAGE_NO, GARAGE_NAME  from NewfoundlandLive2..GARAGES (nolock) where GARAGE_NAME in (select GARAGE_NAME from #tblGARAGENOS T INNER JOIN OntarioLive..GARAGES G(NOLOCK) ON T.GARAGE_NO = G.GARAGE_NO)		
   		    
   		      
    SELECT DISTINCT 'From_Remedy' Source, 
    case  when C.DAC_ARS_WEB ='N' then PROVINCE when C.DAC_ARS_WEB = 'Y' then B.State end PROVINCE,
	ltrim(rtrim(ISNULL(DAC_GARAGE_NAME, G.GARAGE_NAME))) as GARAGE_NAME, 
	cast(cast(ISNULL( AG.AGREEMENT_NO, C.DAC_AGREEMENT_NUMBER) as bigint) as varchar(15))  as AgreementNo, 	
	cast(cast( AG.PARENT_EXTEND_AGREEMENT_NO as bigint) as varchar(15))  as ParentAgreementNo, 	
    C.DAC_CLIENT_FIRST_NAME + ' ' + C.DAC_CLIENT_LAST_NAME as Renter_Name,
    case  when C.DAC_ARS_WEB ='N' then AG.SOLD_DAYS when C.DAC_ARS_WEB ='Y' and DAC_AGR_OPEN_DATE between '20100101' and '20491231' and  DAC_AGR_CLOSE_DATE between '20100101' and '20491231' then Carpro_App.dbo.fn_Cal_hourly_RentalDays(d.DAYS_CALC_LOGIC, DATEADD(SECOND,C.DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,C.DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,C.DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,C.DAC_AGR_CLOSE_DATE,112)))) end  Rental_Days, 
    case  when C.DAC_ARS_WEB ='N' then i.RENTAL when C.DAC_ARS_WEB = 'Y' then h.RATE_CHARGED end Rental_Sum,
	DEBITOR_NAME AS [INS COMPANY NAME], DAC_TOTAL_LOSS as [TOTAL LOSS], AUTHDAY AS [TOTAL AUTHOR DAYS], 
	C.DAC_AGR_OPEN_DATE AS CHECK_OUT_DATE, C.DAC_AGR_OPEN_TIME AS CHECK_OUT_TIME, C.DAC_AGR_CLOSE_DATE AS CHECK_IN_DATE, C.DAC_AGR_CLOSE_TIME AS CHECK_IN_TIME,
	DAC_DRIVABLE AS DRIVABLE, BRANACH_NAME AS [LOCATION NAME], B.STREET [LOCATION ADDRESS], 
	--G.ADDRESS AS [GARAGE ADDRESS], 
	DAC_GARAGE_ADDRESS AS [GARAGE ADDRESS], 
    C.DAC_INS_CLAIM as CLAIM_NO,
    C.DAC_POLICY as POLICY_NO
	into #tempDataRemedy
	FROM [ONTARIOLIVE].DBO.DA_CLAIMS C (NOLOCK) 	
	left join OntarioLive..EBILLING_INVOICE_DATA H(nolock) on C.DAC_ENTRY_ID = H.ENTRY_ID
	LEFT JOIN ONTARIOLIVE.DBO.BRANCHES  B (NOLOCK) ON C.DAC_LOCATION_CODE = B.BRANACH_CODE 
	LEFT JOIN ONTARIOLIVE.DBO.DEBITORS  D (NOLOCK) ON C.DAC_INS_COMPANY_ID = D.DEBITOR_CODE 
	LEFT JOIN ONTARIOLIVE.DBO.DATABASE_SETUP S (NOLOCK) ON C.DAC_COMPANY_CODE = S.DATABASE_ID
	LEFT JOIN DBO.VW_DataBase_SetUp DS (NOLOCK) ON DS.DATABASE_NAME = S.DATABASE_NAME 
	LEFT JOIN [ONTARIOLIVE].DBO.GARAGES G (NOLOCK)ON C.DAC_GARAGE_ID = G.GARAGE_NO
	LEFT JOIN (
		SELECT DCA_CLAIM_ID, SUM(DCA_A_DAYS) AS AUTHDAY, 
		SUM(DAC_FINAL_TOTAL) AS DAC_FINAL_TOTAL, AVG(DCA_AUTHOR_RATE) AS AUTHORRATE 
		FROM ONTARIOLIVE..DA_AUTHORIZATION (NOLOCK)  WHERE DCA_BILL_TO = 1  and DCA_AUTHOR_FROM_DATE >= '20100101' and DCA_AUTHOR_TO_DATE <= '20501231'
		GROUP BY DCA_CLAIM_ID 
	) A ON C.DAC_ENTRY_ID = A.DCA_CLAIM_ID 
	LEFT JOIN (
		Select Agreement_No, PARENT_EXTEND_AGREEMENT_NO, SOLD_DAYS from Ontariolive..Agreements (NOLOCK)
		union 
		Select Agreement_No, PARENT_EXTEND_AGREEMENT_NO, SOLD_DAYS from ALBERTALIVE..Agreements (NOLOCK)
		union 
		Select Agreement_No, PARENT_EXTEND_AGREEMENT_NO, SOLD_DAYS from MaritimesLive..Agreements (NOLOCK)
		union 
		Select Agreement_No, PARENT_EXTEND_AGREEMENT_NO, SOLD_DAYS from BCLive..Agreements (NOLOCK)
		union 
		Select Agreement_No, PARENT_EXTEND_AGREEMENT_NO, SOLD_DAYS from SaskatchewanLive2..Agreements (NOLOCK)
		union 
		Select Agreement_No, PARENT_EXTEND_AGREEMENT_NO, SOLD_DAYS from NewfoundlandLive2..Agreements (NOLOCK)
		union
		Select Agreement_No, PARENT_EXTEND_AGREEMENT_NO, SOLD_DAYS from SaskatchewanLive..Agreements (NOLOCK)
		union 
		Select Agreement_No, PARENT_EXTEND_AGREEMENT_NO, SOLD_DAYS from NewfoundlandLive..Agreements (NOLOCK)
	) AG ON AG.AGREEMENT_NO = C.DAC_AGREEMENT_NUMBER
	left join (
		select AGREEMENT_NO, case when SUM(RENTAL) < 0 then (select SUM(RENTAL) from OntarioLive..Invoices a (nolock) where INV_STATUS !=9 and INVOICE_TYPE in ('C', 'D') and a.AGREEMENT_NO = B.AGREEMENT_NO group by AGREEMENT_NO) else SUM(RENTAL) end as RENTAL from OntarioLive..INVOICES b (nolock) where INV_STATUS !=9 group by AGREEMENT_NO
		union
		select AGREEMENT_NO, case when SUM(RENTAL) < 0 then (select SUM(RENTAL) from AlbertaLive..Invoices a(nolock) where INV_STATUS !=9 and INVOICE_TYPE in ('C', 'D') and a.AGREEMENT_NO = B.AGREEMENT_NO group by AGREEMENT_NO) else SUM(RENTAL) end as RENTAL from AlbertaLive..INVOICES b (nolock) where INV_STATUS !=9 group by AGREEMENT_NO
		union
		select AGREEMENT_NO, case when SUM(RENTAL) < 0 then (select SUM(RENTAL) from BCLive..Invoices a (nolock) where INV_STATUS !=9 and INVOICE_TYPE in ('C', 'D') and a.AGREEMENT_NO = B.AGREEMENT_NO group by AGREEMENT_NO) else SUM(RENTAL) end as RENTAL from BCLive..INVOICES b (nolock) where INV_STATUS !=9 group by AGREEMENT_NO
		union
		select AGREEMENT_NO, case when SUM(RENTAL) < 0 then (select SUM(RENTAL) from MaritimesLive..Invoices a (nolock) where INV_STATUS !=9 and INVOICE_TYPE in ('C', 'D') and a.AGREEMENT_NO = B.AGREEMENT_NO group by AGREEMENT_NO) else SUM(RENTAL) end as RENTAL from MaritimesLive..INVOICES b (nolock) where INV_STATUS !=9 group by AGREEMENT_NO
		union
		select AGREEMENT_NO, case when SUM(RENTAL) < 0 then (select SUM(RENTAL) from SaskatchewanLive..Invoices a (nolock) where INV_STATUS !=9 and INVOICE_TYPE in ('C', 'D') and a.AGREEMENT_NO = B.AGREEMENT_NO group by AGREEMENT_NO) else SUM(RENTAL) end as RENTAL from SaskatchewanLive..INVOICES b (nolock) where INV_STATUS !=9 group by AGREEMENT_NO
		union
		select AGREEMENT_NO, case when SUM(RENTAL) < 0 then (select SUM(RENTAL) from SaskatchewanLive2..Invoices a (nolock) where INV_STATUS !=9 and INVOICE_TYPE in ('C', 'D') and a.AGREEMENT_NO = B.AGREEMENT_NO group by AGREEMENT_NO) else SUM(RENTAL) end as RENTAL from SaskatchewanLive2..INVOICES b (nolock) where INV_STATUS !=9 group by AGREEMENT_NO
		union
		select AGREEMENT_NO, case when SUM(RENTAL) < 0 then (select SUM(RENTAL) from NewfoundlandLive..Invoices a (nolock) where INV_STATUS !=9 and INVOICE_TYPE in ('C', 'D') and a.AGREEMENT_NO = B.AGREEMENT_NO group by AGREEMENT_NO) else SUM(RENTAL) end as RENTAL from NewfoundlandLive..INVOICES b (nolock) where INV_STATUS !=9 group by AGREEMENT_NO
		union
		select AGREEMENT_NO, case when SUM(RENTAL) < 0 then (select SUM(RENTAL) from NewfoundlandLive2..Invoices a (nolock) where INV_STATUS !=9 and INVOICE_TYPE in ('C', 'D') and a.AGREEMENT_NO = B.AGREEMENT_NO group by AGREEMENT_NO) else SUM(RENTAL) end as RENTAL from NewfoundlandLive2..INVOICES b (nolock) where INV_STATUS !=9 group by AGREEMENT_NO
		) i
		on  ISNULL( AG.AGREEMENT_NO, C.DAC_AGREEMENT_NUMBER)= i.AGREEMENT_NO 
	WHERE DAC_AGREEMENT_NUMBER > 0 AND DAC_STATUS = 4 and C.DAC_INS_COMPANY_ID > 0
	AND (G.GARAGES_ACCOUNT_GROUP = @BannerCode)
	and (@GarageCode ='' OR exists (select 1 from #tblGARAGENOSALL GARAGENOS where GARAGENOS.GARAGE_NO = C.DAC_GARAGE_ID and Upper(GARAGENOS.Garage_Name) = Upper(C.Dac_Garage_Name)))
	and (@DebitorCode ='' OR exists (select 1 from #tblDEBITORSAll INS_COMPANIES where INS_COMPANIES.DEBITOR_CODE = C.DAC_INS_COMPANY_ID))
	AND (@LossType ='' OR @LossType = DAC_DRIVABLE)
	AND C.DAC_AGR_CLOSE_DATE!='00000000'
	
	
	
	
	SELECT DISTINCT 'From_RMS' Source, 'ON' as PROVINCE, ltrim(rtrim(GARAGE_NAME)) as GARAGE_NAME, --, GARAGE_NO 
    cast(cast(A.Agreement_No as bigint) as varchar(15)) as AgreementNo,
    cast(cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) as varchar(15))  as ParentAgreementNo, 	
    A.DRIVER_FIRST_NAME + ' ' + A.DRIVER_LAST_NAME as Renter_Name,
	A.SOLD_DAYS AS [RENTAL_DAYS], i.RENTAL as Rental_Sum, 
	DEBITOR_NAME AS [INS COMPANY NAME], 
	'' as [TOTAL LOSS], '' as [TOTAL AUTHOR DAYS],
	A.CHECK_OUT_DATE AS CHECK_OUT_DATE, A.CHECK_OUT_TIME AS CHECK_OUT_TIME, A.CHECK_IN_DATE AS CHECK_IN_DATE, A.CHECK_IN_TIME AS CHECK_IN_TIME,
	'' as DRIVABLE,	BRANACH_NAME AS [LOCATION NAME], B.STREET as [LOCATION ADDRESS], G.ADDRESS AS GARAGE_ADRESS, 
	ISNULL(DAC_INS_CLAIM, '') as CLAIM_NO, ISNULL(DAC_POLICY, '') as POLICY_NO
	INTO #tempDataAgreements
	FROM [ONTARIOLIVE].DBO.AGREEMENTS A (NOLOCK) 
	LEFT JOIN OntarioLive.DBO.BRANCHES B (NOLOCK) ON B.BRANACH_CODE = A.CHECK_OUT_BRANACH 
	LEFT JOIN OntarioLive..DEBITORS D (NOLOCK) ON D.DEBITOR_CODE = A.DEBITOR_CODE 
	LEFT JOIN [ONTARIOLIVE].DBO.REPAIRED_AT R (NOLOCK) ON A.AGREEMENT_NO = R.AGREEMENT_NO
	LEFT JOIN ONTARIOLIVE..DA_CLAIMS C (NOLOCK) ON C.DAC_AGREEMENT_NUMBER = A.AGREEMENT_NO
	LEFT JOIN [ONTARIOLIVE].DBO.GARAGES G (NOLOCK) ON G.GARAGE_NO = R.BODY_SHOP 	
	left join (
		select AGREEMENT_NO, case when SUM(RENTAL) < 0 then (select SUM(RENTAL) from OntarioLive..Invoices a (nolock) where INV_STATUS !=9 and INVOICE_TYPE in ('C', 'D') and a.AGREEMENT_NO = B.AGREEMENT_NO group by AGREEMENT_NO) else SUM(RENTAL) end as RENTAL from OntarioLive..INVOICES b (nolock) where INV_STATUS !=9 group by AGREEMENT_NO
		) i
		on  A.AGREEMENT_NO = i.AGREEMENT_NO
	WHERE 	
	STATUS_CODE = 4 AND GARAGES_ACCOUNT_GROUP = @BannerCode and A.DEBITOR_CODE > 0
	and (@GarageCode ='' OR exists (select 1 from #tblGARAGENOSALL GARAGENOS where GARAGENOS.GARAGE_NO = R.BODY_SHOP) )
	and (@DebitorCode ='' OR exists (select 1 from #tblDEBITORSAll INS_COMPANIES where INS_COMPANIES.DEBITOR_CODE = A.DEBITOR_CODE))
	AND A.CHECK_IN_DATE!='00000000' 	
	UNION 	
	SELECT DISTINCT 'From_RMS' Source, 'AB' as PROVINCE, ltrim(rtrim(GARAGE_NAME)) as GARAGE_NAME, --, GARAGE_NO 
    cast(cast(A.Agreement_No as bigint) as varchar(15)) as AgreementNo,
    cast(cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) as varchar(15))  as ParentAgreementNo, 	
    A.DRIVER_FIRST_NAME + ' ' + A.DRIVER_LAST_NAME as Renter_Name,
	A.SOLD_DAYS AS [RENTAL_DAYS], i.RENTAL as Rental_Sum, 
	DEBITOR_NAME AS [INS COMPANY NAME], 
	'' as [TOTAL LOSS], '' as [TOTAL AUTHOR DAYS],
	A.CHECK_OUT_DATE AS CHECK_OUT_DATE, A.CHECK_OUT_TIME AS CHECK_OUT_TIME, A.CHECK_IN_DATE AS CHECK_IN_DATE, A.CHECK_IN_TIME AS CHECK_IN_TIME,
	'' as DRIVABLE,	BRANACH_NAME AS [LOCATION NAME], B.STREET as [LOCATION ADDRESS], G.ADDRESS AS GARAGE_ADRESS,
	ISNULL(DAC_INS_CLAIM, '') as CLAIM_NO, ISNULL(DAC_POLICY, '') as POLICY_NO
	FROM [ALBERTALIVE].DBO.AGREEMENTS A (NOLOCK) 
	LEFT JOIN [ALBERTALIVE].DBO.BRANCHES B (NOLOCK) ON B.BRANACH_CODE = A.CHECK_OUT_BRANACH 
	LEFT JOIN [ALBERTALIVE]..DEBITORS D (NOLOCK) ON D.DEBITOR_CODE = A.DEBITOR_CODE  
	LEFT JOIN [ALBERTALIVE].DBO.REPAIRED_AT R (NOLOCK) ON A.AGREEMENT_NO = R.AGREEMENT_NO
	LEFT JOIN ONTARIOLIVE..DA_CLAIMS C (NOLOCK) ON C.DAC_AGREEMENT_NUMBER = A.AGREEMENT_NO
	LEFT JOIN [ALBERTALIVE].DBO.GARAGES G (NOLOCK) ON G.GARAGE_NO = R.BODY_SHOP 	
	left join (
		select AGREEMENT_NO, case when SUM(RENTAL) < 0 then (select SUM(RENTAL) from ALBERTALIVE..Invoices a (nolock) where INV_STATUS !=9 and INVOICE_TYPE in ('C', 'D') and a.AGREEMENT_NO = B.AGREEMENT_NO group by AGREEMENT_NO) else SUM(RENTAL) end as RENTAL from ALBERTALIVE..INVOICES b (nolock) where INV_STATUS !=9 group by AGREEMENT_NO
		) i
		on  A.AGREEMENT_NO = i.AGREEMENT_NO 
	WHERE 	
	STATUS_CODE = 4 AND  GARAGES_ACCOUNT_GROUP = @BannerCode and A.DEBITOR_CODE > 0
	and (@GarageCode ='' OR exists (select 1 from #tblGARAGENOSALL GARAGENOS where GARAGENOS.GARAGE_NO = R.BODY_SHOP) )
	and (@DebitorCode ='' OR exists (select 1 from #tblDEBITORSAll INS_COMPANIES where INS_COMPANIES.DEBITOR_CODE = A.DEBITOR_CODE))
	AND A.CHECK_IN_DATE!='00000000'  	
	UNION 	
	SELECT DISTINCT 'From_RMS' Source, 'MT' as PROVINCE, ltrim(rtrim(GARAGE_NAME)) as GARAGE_NAME, --, GARAGE_NO 
    cast(cast(A.Agreement_No as bigint) as varchar(15)) as AgreementNo,
    cast(cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) as varchar(15))  as ParentAgreementNo, 	
    A.DRIVER_FIRST_NAME + ' ' + A.DRIVER_LAST_NAME as Renter_Name,
	A.SOLD_DAYS AS [RENTAL_DAYS], i.RENTAL as Rental_Sum, 
	DEBITOR_NAME AS [INS COMPANY NAME], 
	'' as [TOTAL LOSS], '' as [TOTAL AUTHOR DAYS],
	A.CHECK_OUT_DATE AS CHECK_OUT_DATE, A.CHECK_OUT_TIME AS CHECK_OUT_TIME, A.CHECK_IN_DATE AS CHECK_IN_DATE, A.CHECK_IN_TIME AS CHECK_IN_TIME,
	'' as DRIVABLE,	BRANACH_NAME AS [LOCATION NAME], B.STREET as [LOCATION ADDRESS], G.ADDRESS AS GARAGE_ADRESS,
	ISNULL(DAC_INS_CLAIM, '') as CLAIM_NO, ISNULL(DAC_POLICY, '') as POLICY_NO
	FROM MaritimesLive.DBO.AGREEMENTS A (NOLOCK) 
	LEFT JOIN MaritimesLive.DBO.BRANCHES B (NOLOCK) ON B.BRANACH_CODE = A.CHECK_OUT_BRANACH 
	LEFT JOIN MaritimesLive..DEBITORS D (NOLOCK) ON D.DEBITOR_CODE = A.DEBITOR_CODE
	LEFT JOIN MaritimesLive.DBO.REPAIRED_AT R (NOLOCK) ON A.AGREEMENT_NO = R.AGREEMENT_NO
	LEFT JOIN ONTARIOLIVE..DA_CLAIMS C (NOLOCK) ON C.DAC_AGREEMENT_NUMBER = A.AGREEMENT_NO
	LEFT JOIN MaritimesLive.DBO.GARAGES G (NOLOCK) ON G.GARAGE_NO = R.BODY_SHOP 	
	left join (
		select AGREEMENT_NO, case when SUM(RENTAL) < 0 then (select SUM(RENTAL) from MaritimesLive..Invoices a (nolock) where INV_STATUS !=9 and INVOICE_TYPE in ('C', 'D') and a.AGREEMENT_NO = B.AGREEMENT_NO  group by AGREEMENT_NO) else SUM(RENTAL) end as RENTAL from MaritimesLive..INVOICES b (nolock) where INV_STATUS !=9 group by AGREEMENT_NO
		) i
		on  A.AGREEMENT_NO = i.AGREEMENT_NO 
	WHERE 	
	STATUS_CODE = 4  and GARAGES_ACCOUNT_GROUP = @BannerCode and A.DEBITOR_CODE > 0
	and (@GarageCode ='' OR exists (select 1 from #tblGARAGENOSALL GARAGENOS where GARAGENOS.GARAGE_NO =  R.BODY_SHOP) )
	and (@DebitorCode ='' OR exists (select 1 from #tblDEBITORSAll INS_COMPANIES where INS_COMPANIES.DEBITOR_CODE = A.DEBITOR_CODE))
	AND A.CHECK_IN_DATE!='00000000'  	
	UNION 	
	SELECT DISTINCT 'From_RMS' Source, 'BC' as PROVINCE, ltrim(rtrim(GARAGE_NAME)) as GARAGE_NAME, --, GARAGE_NO 
    cast(cast(A.Agreement_No as bigint) as varchar(15)) as AgreementNo,
    cast(cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) as varchar(15))  as ParentAgreementNo, 	
    A.DRIVER_FIRST_NAME + ' ' + A.DRIVER_LAST_NAME as Renter_Name,
	A.SOLD_DAYS AS [RENTAL_DAYS], i.RENTAL as Rental_Sum, 
	DEBITOR_NAME AS [INS COMPANY NAME], 
	'' as [TOTAL LOSS], '' as [TOTAL AUTHOR DAYS],
	A.CHECK_OUT_DATE AS CHECK_OUT_DATE, A.CHECK_OUT_TIME AS CHECK_OUT_TIME, A.CHECK_IN_DATE AS CHECK_IN_DATE, A.CHECK_IN_TIME AS CHECK_IN_TIME,
	'' as DRIVABLE,	BRANACH_NAME AS [LOCATION NAME], B.STREET as [LOCATION ADDRESS], G.ADDRESS AS GARAGE_ADRESS,
	ISNULL(DAC_INS_CLAIM, '') as CLAIM_NO, ISNULL(DAC_POLICY, '') as POLICY_NO
	FROM BCLive.DBO.AGREEMENTS A (NOLOCK) 
	LEFT JOIN BCLive.DBO.BRANCHES B (NOLOCK) ON B.BRANACH_CODE = A.CHECK_OUT_BRANACH 
	LEFT JOIN BCLive..DEBITORS D (NOLOCK) ON D.DEBITOR_CODE = A.DEBITOR_CODE
	LEFT JOIN BCLive.DBO.REPAIRED_AT R (NOLOCK) ON A.AGREEMENT_NO = R.AGREEMENT_NO
	LEFT JOIN ONTARIOLIVE..DA_CLAIMS C (NOLOCK) ON C.DAC_AGREEMENT_NUMBER = A.AGREEMENT_NO
	LEFT JOIN BCLive.DBO.GARAGES G (NOLOCK) ON G.GARAGE_NO = R.BODY_SHOP 	
	left join (
		select AGREEMENT_NO, case when SUM(RENTAL) < 0 then (select SUM(RENTAL) from BCLive..Invoices a (nolock) where INV_STATUS !=9 and INVOICE_TYPE in ('C', 'D') and a.AGREEMENT_NO = B.AGREEMENT_NO  group by AGREEMENT_NO) else SUM(RENTAL) end as RENTAL from BCLive..INVOICES b (nolock) where INV_STATUS !=9 group by AGREEMENT_NO
		) i
		on  A.AGREEMENT_NO = i.AGREEMENT_NO
	WHERE 	
	STATUS_CODE = 4 AND  GARAGES_ACCOUNT_GROUP = @BannerCode and A.DEBITOR_CODE > 0
	and (@GarageCode ='' OR exists (select 1 from #tblGARAGENOSALL GARAGENOS where GARAGENOS.GARAGE_NO =  R.BODY_SHOP) )
	and (@DebitorCode ='' OR exists (select 1 from #tblDEBITORSAll INS_COMPANIES where INS_COMPANIES.DEBITOR_CODE = A.DEBITOR_CODE))
	AND A.CHECK_IN_DATE!='00000000' 
	UNION 	
	SELECT DISTINCT 'From_RMS' Source, 'SK' as PROVINCE, ltrim(rtrim(GARAGE_NAME)) as GARAGE_NAME, --, GARAGE_NO 
    cast(cast(A.Agreement_No as bigint) as varchar(15)) as AgreementNo,
    cast(cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) as varchar(15))  as ParentAgreementNo, 	
    A.DRIVER_FIRST_NAME + ' ' + A.DRIVER_LAST_NAME as Renter_Name,
	A.SOLD_DAYS AS [RENTAL_DAYS], i.RENTAL as Rental_Sum, 
	DEBITOR_NAME AS [INS COMPANY NAME], 
	'' as [TOTAL LOSS], '' as [TOTAL AUTHOR DAYS],
	A.CHECK_OUT_DATE AS CHECK_OUT_DATE, A.CHECK_OUT_TIME AS CHECK_OUT_TIME, A.CHECK_IN_DATE AS CHECK_IN_DATE, A.CHECK_IN_TIME AS CHECK_IN_TIME,
	'' as DRIVABLE,	BRANACH_NAME AS [LOCATION NAME], B.STREET as [LOCATION ADDRESS], G.ADDRESS AS GARAGE_ADRESS,
	ISNULL(DAC_INS_CLAIM, '') as CLAIM_NO, ISNULL(DAC_POLICY, '') as POLICY_NO
	FROM SaskatchewanLive2.DBO.AGREEMENTS A (NOLOCK) 
	LEFT JOIN SaskatchewanLive2.DBO.BRANCHES B (NOLOCK) ON B.BRANACH_CODE = A.CHECK_OUT_BRANACH 
	LEFT JOIN SaskatchewanLive2..DEBITORS D (NOLOCK) ON D.DEBITOR_CODE = A.DEBITOR_CODE
	LEFT JOIN SaskatchewanLive2.DBO.REPAIRED_AT R (NOLOCK) ON A.AGREEMENT_NO = R.AGREEMENT_NO
	LEFT JOIN ONTARIOLIVE..DA_CLAIMS C (NOLOCK) ON C.DAC_AGREEMENT_NUMBER = A.AGREEMENT_NO
	LEFT JOIN SaskatchewanLive2.DBO.GARAGES G (NOLOCK) ON G.GARAGE_NO = R.BODY_SHOP
	left join (
		select AGREEMENT_NO, case when SUM(RENTAL) < 0 then (select SUM(RENTAL) from SaskatchewanLive2..Invoices a (nolock) where INV_STATUS !=9 and INVOICE_TYPE in ('C', 'D') and a.AGREEMENT_NO = B.AGREEMENT_NO  group by AGREEMENT_NO) else SUM(RENTAL) end as RENTAL from SaskatchewanLive2..INVOICES b (nolock) where INV_STATUS !=9 group by AGREEMENT_NO
		) i
		on  A.AGREEMENT_NO = i.AGREEMENT_NO 
	WHERE 	
	STATUS_CODE = 4  and GARAGES_ACCOUNT_GROUP = @BannerCode and A.DEBITOR_CODE > 0
	and (@GarageCode ='' OR exists (select 1 from #tblGARAGENOSALL GARAGENOS where GARAGENOS.GARAGE_NO =  R.BODY_SHOP) )
	and (@DebitorCode ='' OR exists (select 1 from #tblDEBITORSAll INS_COMPANIES where INS_COMPANIES.DEBITOR_CODE = A.DEBITOR_CODE))
	AND A.CHECK_IN_DATE!='00000000'  	
	UNION 	
	SELECT DISTINCT 'From_RMS' Source, 'NL' as PROVINCE, ltrim(rtrim(GARAGE_NAME)) as GARAGE_NAME, --, GARAGE_NO 
    cast(cast(A.Agreement_No as bigint) as varchar(15)) as AgreementNo,
    cast(cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) as varchar(15))  as ParentAgreementNo, 	
    A.DRIVER_FIRST_NAME + ' ' + A.DRIVER_LAST_NAME as Renter_Name,
	A.SOLD_DAYS AS [RENTAL_DAYS], i.RENTAL as Rental_Sum, 
	DEBITOR_NAME AS [INS COMPANY NAME], 
	'' as [TOTAL LOSS], '' as [TOTAL AUTHOR DAYS],
	A.CHECK_OUT_DATE AS CHECK_OUT_DATE, A.CHECK_OUT_TIME AS CHECK_OUT_TIME, A.CHECK_IN_DATE AS CHECK_IN_DATE, A.CHECK_IN_TIME AS CHECK_IN_TIME,
	'' as DRIVABLE,	BRANACH_NAME AS [LOCATION NAME], B.STREET as [LOCATION ADDRESS], G.ADDRESS AS GARAGE_ADRESS,
	ISNULL(DAC_INS_CLAIM, '') as CLAIM_NO, ISNULL(DAC_POLICY, '') as POLICY_NO
	FROM NewfoundlandLive2.DBO.AGREEMENTS A (NOLOCK) 
	LEFT JOIN NewfoundlandLive2.DBO.BRANCHES B (NOLOCK) ON B.BRANACH_CODE = A.CHECK_OUT_BRANACH 
	LEFT JOIN NewfoundlandLive2..DEBITORS D (NOLOCK) ON D.DEBITOR_CODE = A.DEBITOR_CODE
	LEFT JOIN NewfoundlandLive2.DBO.REPAIRED_AT R (NOLOCK) ON A.AGREEMENT_NO = R.AGREEMENT_NO
	LEFT JOIN ONTARIOLIVE..DA_CLAIMS C (NOLOCK) ON C.DAC_AGREEMENT_NUMBER = A.AGREEMENT_NO
	LEFT JOIN NewfoundlandLive2.DBO.GARAGES G (NOLOCK) ON G.GARAGE_NO = R.BODY_SHOP 	
	left join (
		select AGREEMENT_NO, case when SUM(RENTAL) < 0 then (select SUM(RENTAL) from NewfoundlandLive2..Invoices a (nolock) where INV_STATUS !=9 and INVOICE_TYPE in ('C', 'D') and a.AGREEMENT_NO = B.AGREEMENT_NO group by AGREEMENT_NO) else SUM(RENTAL) end as RENTAL from NewfoundlandLive2..INVOICES b (nolock) where INV_STATUS !=9 group by AGREEMENT_NO
		) i
		on  A.AGREEMENT_NO = i.AGREEMENT_NO
	WHERE 	
	STATUS_CODE = 4  and GARAGES_ACCOUNT_GROUP = @BannerCode and A.DEBITOR_CODE > 0 
	and (@GarageCode ='' OR exists (select 1 from #tblGARAGENOSALL GARAGENOS where GARAGENOS.GARAGE_NO =  R.BODY_SHOP) )
	and (@DebitorCode ='' OR exists (select 1 from #tblDEBITORSAll INS_COMPANIES where INS_COMPANIES.DEBITOR_CODE = A.DEBITOR_CODE))
	AND A.CHECK_IN_DATE!='00000000'  	
	UNION 	
	SELECT DISTINCT 'From_RMS' Source, 'SK' as PROVINCE, ltrim(rtrim(GARAGE_NAME)) as GARAGE_NAME, --, GARAGE_NO 
    cast(cast(A.Agreement_No as bigint) as varchar(15)) as AgreementNo,
    cast(cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) as varchar(15))  as ParentAgreementNo, 	
    A.DRIVER_FIRST_NAME + ' ' + A.DRIVER_LAST_NAME as Renter_Name,
	A.SOLD_DAYS AS [RENTAL_DAYS], i.RENTAL as Rental_Sum, 
	DEBITOR_NAME AS [INS COMPANY NAME], 
	'' as [TOTAL LOSS], '' as [TOTAL AUTHOR DAYS],
	A.CHECK_OUT_DATE AS CHECK_OUT_DATE, A.CHECK_OUT_TIME AS CHECK_OUT_TIME, A.CHECK_IN_DATE AS CHECK_IN_DATE, A.CHECK_IN_TIME AS CHECK_IN_TIME,
	'' as DRIVABLE,	BRANACH_NAME AS [LOCATION NAME], B.STREET as [LOCATION ADDRESS], G.ADDRESS AS GARAGE_ADRESS,
	ISNULL(DAC_INS_CLAIM, '') as CLAIM_NO, ISNULL(DAC_POLICY, '') as POLICY_NO
	FROM SaskatchewanLive.DBO.AGREEMENTS A (NOLOCK) 
	LEFT JOIN SaskatchewanLive.DBO.BRANCHES B (NOLOCK) ON B.BRANACH_CODE = A.CHECK_OUT_BRANACH 
	LEFT JOIN SaskatchewanLive..DEBITORS D (NOLOCK) ON D.DEBITOR_CODE = A.DEBITOR_CODE
	LEFT JOIN SaskatchewanLive.DBO.REPAIRED_AT R (NOLOCK) ON A.AGREEMENT_NO = R.AGREEMENT_NO
	LEFT JOIN ONTARIOLIVE..DA_CLAIMS C (NOLOCK) ON C.DAC_AGREEMENT_NUMBER = A.AGREEMENT_NO
	LEFT JOIN SaskatchewanLive.DBO.GARAGES G (NOLOCK) ON G.GARAGE_NO = R.BODY_SHOP
	left join (
		select AGREEMENT_NO, case when SUM(RENTAL) < 0 then (select SUM(RENTAL) from SaskatchewanLive..Invoices a (nolock) where INV_STATUS !=9 and INVOICE_TYPE in ('C', 'D') and a.AGREEMENT_NO = B.AGREEMENT_NO  group by AGREEMENT_NO) else SUM(RENTAL) end as RENTAL from SaskatchewanLive..INVOICES b (nolock) where INV_STATUS !=9 group by AGREEMENT_NO
		) i
		on  A.AGREEMENT_NO = i.AGREEMENT_NO 
	WHERE 	
	STATUS_CODE = 4  and GARAGES_ACCOUNT_GROUP = @BannerCode and A.DEBITOR_CODE > 0 
	and (@GarageCode ='' OR exists (select 1 from #tblGARAGENOSALL GARAGENOS where GARAGENOS.GARAGE_NO =  R.BODY_SHOP) )
	and (@DebitorCode ='' OR exists (select 1 from #tblDEBITORSAll INS_COMPANIES where INS_COMPANIES.DEBITOR_CODE = A.DEBITOR_CODE))
	AND A.CHECK_IN_DATE!='00000000'  	
	UNION 	
	SELECT DISTINCT 'From_RMS' Source, 'NL' as PROVINCE, ltrim(rtrim(GARAGE_NAME)) as GARAGE_NAME, --, GARAGE_NO 
    cast(cast(A.Agreement_No as bigint) as varchar(15)) as AgreementNo,
    cast(cast(A.PARENT_EXTEND_AGREEMENT_NO as bigint) as varchar(15))  as ParentAgreementNo, 	
    A.DRIVER_FIRST_NAME + ' ' + A.DRIVER_LAST_NAME as Renter_Name,
	A.SOLD_DAYS AS [RENTAL_DAYS], i.RENTAL as Rental_Sum, 
	DEBITOR_NAME AS [INS COMPANY NAME], 
	'' as [TOTAL LOSS], '' as [TOTAL AUTHOR DAYS],
	A.CHECK_OUT_DATE AS CHECK_OUT_DATE, A.CHECK_OUT_TIME AS CHECK_OUT_TIME, A.CHECK_IN_DATE AS CHECK_IN_DATE, A.CHECK_IN_TIME AS CHECK_IN_TIME,
	'' as DRIVABLE,	BRANACH_NAME AS [LOCATION NAME], B.STREET as [LOCATION ADDRESS], G.ADDRESS AS GARAGE_ADRESS,
	ISNULL(DAC_INS_CLAIM, '') as CLAIM_NO, ISNULL(DAC_POLICY, '') as POLICY_NO
	FROM NewfoundlandLive.DBO.AGREEMENTS A (NOLOCK) 
	LEFT JOIN NewfoundlandLive.DBO.BRANCHES B (NOLOCK) ON B.BRANACH_CODE = A.CHECK_OUT_BRANACH 
	LEFT JOIN NewfoundlandLive..DEBITORS D (NOLOCK) ON D.DEBITOR_CODE = A.DEBITOR_CODE
	LEFT JOIN NewfoundlandLive.DBO.REPAIRED_AT R (NOLOCK) ON A.AGREEMENT_NO = R.AGREEMENT_NO
	LEFT JOIN ONTARIOLIVE..DA_CLAIMS C (NOLOCK) ON C.DAC_AGREEMENT_NUMBER = A.AGREEMENT_NO
	LEFT JOIN NewfoundlandLive.DBO.GARAGES G (NOLOCK) ON G.GARAGE_NO = R.BODY_SHOP 	
	left join (
		select AGREEMENT_NO, case when SUM(RENTAL) < 0 then (select SUM(RENTAL) from NewfoundlandLive..Invoices (nolock) a where INV_STATUS !=9 and INVOICE_TYPE in ('C', 'D') and a.AGREEMENT_NO = B.AGREEMENT_NO  group by AGREEMENT_NO) else SUM(RENTAL) end as RENTAL from NewfoundlandLive..INVOICES b (nolock) where INV_STATUS !=9 group by AGREEMENT_NO
		) i
		on  A.AGREEMENT_NO = i.AGREEMENT_NO
	WHERE 	
	STATUS_CODE = 4  and GARAGES_ACCOUNT_GROUP = @BannerCode and A.DEBITOR_CODE > 0 
	and (@GarageCode ='' OR exists (select 1 from #tblGARAGENOSALL GARAGENOS where GARAGENOS.GARAGE_NO =  R.BODY_SHOP) )
	and (@DebitorCode ='' OR exists (select 1 from #tblDEBITORSAll INS_COMPANIES where INS_COMPANIES.DEBITOR_CODE = A.DEBITOR_CODE))
	AND A.CHECK_IN_DATE!='00000000'  	
	
	
	Delete from #tempDataAgreements where AgreementNo in (select AgreementNo from #tempDataRemedy where cast(ParentAgreementNo as bigint) = 0)
	
	Delete from #tempDataRemedy where cast(ParentAgreementNo as bigint) > 0
	
	Select * into #tempData from #tempDataRemedy r
	Union
	Select * from #tempDataAgreements a 
	
	
	select Source, GARAGE_NAME, PROVINCE,Renter_Name, SUM(RENTAL_DAYS) as RENTAL_DAYS, SUM(Rental_Sum)  as Rental_Sum , 
	case when cast(MAX(ParentAgreementNo)as bigint) > 0 then cast(MIN(AGREEMENTNO) as bigint) else cast(MAX(AGREEMENTNO) as bigint) end AGREEMENTNO,
	case when cast(MAX(ParentAgreementNo) as bigint) > 0 then MIN(DATEADD(SECOND,CHECK_OUT_TIME,CONVERT(datetime,CONVERT(VARCHAR,CHECK_OUT_DATE,112)))) else MAX(DATEADD(SECOND,CHECK_OUT_TIME,CONVERT(datetime,CONVERT(VARCHAR,CHECK_OUT_DATE,112)))) end Contact_Open,
	case when cast(MAX(ParentAgreementNo) as bigint) > 0 then MIN(DATEADD(SECOND,CHECK_IN_TIME,CONVERT(datetime,CONVERT(VARCHAR,CHECK_IN_DATE,112)))) else MAX(DATEADD(SECOND,CHECK_IN_TIME,CONVERT(datetime,CONVERT(VARCHAR,CHECK_IN_DATE,112)))) end Contact_Closed,
	[INS COMPANY NAME], [TOTAL LOSS],  
	DRIVABLE, [LOCATION NAME],  [LOCATION ADDRESS], [GARAGE ADDRESS], CLAIM_NO, POLICY_NO
	into #tempFinalData
	from #tempData
	group by  Renter_Name, GARAGE_NAME, PROVINCE, PROVINCE, [INS COMPANY NAME], [TOTAL LOSS], DRIVABLE, 
	[LOCATION NAME],  [LOCATION ADDRESS], [GARAGE ADDRESS], Source, CLAIM_NO, POLICY_NO
	
	
	select source as Source, PROVINCE as Province, GARAGE_NAME as [Garage Name], Renter_Name as [Renter Name], cast(AgreementNo as bigint) as Agreement#, 
	cast(RENTAL_DAYS as bigint) as [Rental Days], cast(Rental_Sum as bigint) as [Rental Sum],  
	[INS COMPANY NAME] as [Insurance Company], Contact_Open as [Contact Open], Contact_Closed as [Contact Closed],
	CLAIM_NO as [Claim No], POLICY_NO as [Policy No], 
	[TOTAL LOSS] as [Total Loss],
	DRIVABLE as Drivable, [LOCATION NAME] as [Location Name],  [LOCATION ADDRESS] as [Location Address], [GARAGE ADDRESS] as [Garage Address]
	from
	(
	select ROW_NUMBER() over (partition by agreementno order by source) myRank,* from #tempFinalData 
	) t
	where  myRank = 1 and Contact_Closed BETWEEN @BEGIN AND  @END
	order by [INS COMPANY NAME]
	
	select GARAGE_NAME as [Garage Name],count(AgreementNo) as [Total Rentals], sum(RENTAL_DAYS) AS [Total Rental Days], 
	convert(decimal(18,2) ,sum(RENTAL_SUM)) AS [Total Rental Sum] 
	from(
	select ROW_NUMBER() over (partition by agreementno order by source) myRank,* from #tempFinalData 
	) t	
	where myRank = 1 and Contact_Closed BETWEEN @BEGIN AND  @END
	group by GARAGE_NAME order by GARAGE_NAME	
	
	
	select SUM([Total Rentals]) as [Total Rentals], SUM([Total Rental Days]) as [Total Rental Days], SUM([Total Rental Sum]) as [Total Rental Sum] from(
	select GARAGE_NAME as [Garage Name],count(AgreementNo) as [Total Rentals], sum(RENTAL_DAYS) AS [Total Rental Days], 
	convert(decimal(18,2) ,sum(RENTAL_SUM)) AS [Total Rental Sum] 
	from(
	select ROW_NUMBER() over (partition by agreementno order by source) myRank,* from #tempFinalData 
	) t	
	where myRank = 1 and Contact_Closed BETWEEN @BEGIN AND  @END
	group by GARAGE_NAME 	
	) a
	
	drop table #tempDataRemedy
	drop table #tempDataAgreements
	drop table #tempData
	drop table #tempFinalData
END
