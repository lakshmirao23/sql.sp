USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_MyFiles_Search]    Script Date: 04/05/2018 09:38:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---- =============================================
---- Create date: <Jan 21, 2013>
---- Description:	<My Files (To Do, Completed, Invoices)>
---- =============================================
----EXEC [spDIAL_MyFiles_Search] @AdjusterID = 17724, @ExpiringIn=2
----EXEC [spDIAL_MyFiles_Search] @AdjusterID=17724, @Claim_or_Policy_No='', @Dac_Status =4
----0 - NEW, 1-BOOKED, 2-ACTIVE, 3-EXPIRED, 4-INACTIVE, 5-CANCELLED, 6-ABEND	 
ALTER PROCEDURE [dbo].[spDIAL_MyFiles_Search]	
@Claim_or_Policy_No varchar(30) = '', 
@ClientLastName varchar(70) = '', 
@AgreementNo bigint = 0,
@ReservationNo varchar(12) = '',
@AdjusterID INT,  
@DebitorCode int = 0, 
@Dac_Status int = 0, 
@ExpiringIn int = 0

AS
--BEGIN	
--	SET NOCOUNT ON;
	        
	  SELECT dauth.DCA_AUTHOR_TO_DATE, OK_TO_BILL AS okToBill,   
	  D.DAC_STATUS AS dacRentalAgrStatus,           
      CASE 
      --WHEN D.DAC_STATUS=4 or R.STATUS_CODE=0 OR R.STATUS_CODE=4  THEN 
      --      ISNULL(R.SOLD_DAYS, Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))))
		WHEN R.SOLD_DAYS >0 THEN
			R.SOLD_DAYS
        WHEN D.DAC_STATUS=1 AND RR.SOLD_DAYS >0 THEN 
            RR.SOLD_DAYS
        WHEN D.DAC_STATUS=1 AND RR.CHECK_OUT_DATE >'00000000' AND RR.CHECK_IN_DATE >'00000000' THEN
            Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,RR.CHECK_OUT_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,RR.CHECK_OUT_DATE,112))), DATEADD(SECOND,RR.CHECK_IN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,RR.CHECK_IN_DATE,112))))
      WHEN D.DAC_AGR_OPEN_DATE >'00000000' AND D.DAC_AGR_CLOSE_DATE >'00000000' THEN
            Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,D.DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,D.DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,D.DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,D.DAC_AGR_CLOSE_DATE,112))))
      --WHEN D.DAC_AGR_OPEN_DATE>'00000000' THEN
      --      Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE())
      ELSE NULL
      END AS rentaldays ,                   
		CASE 
                            --WHEN D.DAC_STATUS=4 or R.STATUS_CODE=4   THEN 
                                    --ROUND(dauth.DCA_AUTHOR_RATE * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))))  +
                                    --(ISNULL(dauth.DCA_AUTHOR_RATE,0) * ISNULL(R.SOLD_DAYS, ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))))) * ISNULL(dauth.VAT_PER,0)/100),2)
							
                            WHEN D.DAC_STATUS=1 AND D.DAC_ARS_WEB != 'Y' AND RR.SOLD_DAYS > 0 THEN  --FOR RESERVATION Corp
                                        ROUND(dauth.DCA_AUTHOR_RATE * RR.SOLD_DAYS,2) 
                            WHEN D.DAC_STATUS=1 AND D.DAC_ARS_WEB != 'Y' AND RR.CHECK_OUT_DATE >'00000000' AND RR.CHECK_IN_DATE >'00000000' THEN  --FOR RESERVATION
										ROUND(dauth.DCA_AUTHOR_RATE * Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,RR.CHECK_OUT_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,RR.CHECK_OUT_DATE,112))), DATEADD(SECOND,RR.CHECK_IN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,RR.CHECK_IN_DATE,112))))  +
										(ISNULL(dauth.DCA_AUTHOR_RATE,0) * Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,RR.CHECK_OUT_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,RR.CHECK_OUT_DATE,112))), DATEADD(SECOND,RR.CHECK_IN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,RR.CHECK_IN_DATE,112)))) * ISNULL(dauth.VAT_PER,0)/100),2) 
                                  --WHEN D.DAC_STATUS=1 AND D.DAC_ARS_WEB != 'Y' AND D.DAC_AGR_OPEN_DATE>'00000000' THEN  --FOR RESERVATION
                                  WHEN D.DAC_STATUS=1 AND D.DAC_ARS_WEB = 'Y' AND D.DAC_AGR_OPEN_DATE>'00000000' AND D.DAC_AGR_CLOSE_DATE >'00000000' THEN  --FOR RESERVATION Franchise
                            ROUND(dauth.DCA_AUTHOR_RATE * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))))  +
                            (ISNULL(dauth.DCA_AUTHOR_RATE,0) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))) * ISNULL(dauth.VAT_PER,0)/100),2)                                       
                            WHEN R.SOLD_DAYS> 0 THEN
                                  ROUND((dauth.DCA_AUTHOR_RATE * R.SOLD_DAYS  + ISNULL(dauth.DCA_AUTHOR_RATE,0) * R.SOLD_DAYS* ISNULL(dauth.VAT_PER,0)/100),2)  
                            WHEN  D.DAC_AGR_OPEN_DATE>'00000000' AND D.DAC_AGR_CLOSE_DATE >'00000000' THEN   
                                                      ROUND(dauth.DCA_AUTHOR_RATE * Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))  +
                                    (ISNULL(dauth.DCA_AUTHOR_RATE,0) * Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))) * ISNULL(dauth.VAT_PER,0)/100),2)                                             
                            ELSE
                                    null
                            END AS totalRental ,
                  ISNULL(dauth.dca_a_days,0) AS dacAuthorDays,
                  D.DAC_RESERVATION_NO AS dacReservationNo,
                  D.DAC_AGREEMENT_NUMBER AS dacAgreementNumber,
                  D.DAC_CLIENT_LAST_NAME AS dacClientLastName,
                  D.DAC_CLIENT_FIRST_NAME AS dacClientFirstName,
             CASE
                  D.DAC_AGR_OPEN_DATE     WHEN '00000000' THEN ''
                  ELSE D.DAC_AGR_OPEN_DATE END AS dacAgreementOpenDate,
             CASE 
                  WHEN (D.DAC_ARS_WEB!='Y' AND R.STATUS_CODE = 0 OR R.STATUS_CODE = 4) OR (D.DAC_ARS_WEB = 'Y' AND D.DAC_AGR_CLOSE_DATE != '00000000')  THEN D.DAC_AGR_CLOSE_DATE
                  ELSE '00000000'   END   AS dacAgreementCloseDate,
                  ISNULL(dauth.DCA_AUTHOR_RATE,0) AS dacAuthorizedRate,
                  D.DAC_TAX_PAID_BY AS dacTaxPaidBy,                  
                  ISNULL(DA.DAA_LAST_NAME,'')AS dacCompanyAdjLastName,
                  ISNULL(DA.DAA_FIRST_NAME ,'') AS dacCompanyAdjFirstName, 
                  D.DAC_POLICY AS dacPolicy,
                  D.DAC_INS_CLAIM AS dacInsClaim,
                  D.DAC_LOCATION_NAME AS dacLocationName,
                  D.DAC_MAKE AS dacMake,
                  D.DAC_MODEL AS dacModel,
                  D.DAC_YEAR AS dacYear,
                  D.DAC_RENTAL_MAKE AS dacRentalMake,
                  D.DAC_RENTAL_MODEL AS dacRentalModel,
                  D.DAC_RENTAL_YEAR AS dacRentalYear,
                  D.DAC_EQUIVALENT_GROUP AS dacEquivalentGroup,
                  D.DAC_STATUS AS dacStatus,
                  D.DAC_ARS_WEB AS dacArsWeb,
                  D.DAC_ENTRY_ID AS dacEntryId,
                        CASE D.DAC_INVOICE_DATE
                  WHEN '00000000' THEN ''
                  ELSE D.DAC_INVOICE_DATE END AS  dacInvoiceDate,                  
                  DB1.DEBITOR_NAME AS dacInsCompanyName,
                  FINAL_AUTH AS finalAuth ,
            ISNULL(V.INVOICE_NO,0) AS invoiceNo 
            FROM DA_CLAIMS D(NOLOCK)
                  LEFT OUTER JOIN RemedeyAgr R(NOLOCK) ON R.AGREEMENT_NO = D.DAC_AGREEMENT_NUMBER
                  LEFT OUTER JOIN Vw_Dial_Inv V(NOLOCK) ON V.AGREEMENT_NO = D.DAC_AGREEMENT_NUMBER AND V.INVOICE_TYPE = 'C' AND V.INV_STATUS != 9 AND D.DAC_INS_COMPANY_ID = v.DEBITOR_NO
                  LEFT OUTER JOIN EBILLING_INVOICE_DATA EB(NOLOCK) on EB.Entry_ID = D.DAC_ENTRY_ID
                  LEFT OUTER JOIN (SELECT da.DCA_CLAIM_ID,ISNULL(AVG(VAT_PER),0)VAT_PER,ISNULL(SUM(dca_a_days),0) dca_a_days,ISNULL(AVG(DCA_AUTHOR_RATE),0) DCA_AUTHOR_RATE
											,MAX(DA.DCA_AUTHOR_TO_DATE) DCA_AUTHOR_TO_DATE
                                                      from DA_AUTHORIZATION da(NOLOCK) where DCA_BILL_TO=1 GROUP BY da.DCA_CLAIM_ID )
                                                      AS dauth ON D.DAC_ENTRY_ID = dauth.DCA_CLAIM_ID
                              LEFT JOIN DEBITORS DB1(NOLOCK)
                              ON D.DAC_INS_COMPANY_ID = DB1.DEBITOR_CODE
                              LEFT JOIN DA_ADJUSTER DA(NOLOCK)
                              ON D.DAC_COMPANY_ADJUSTER_ID = DA.DAA_ENTRY_ID
                              LEFT JOIN [RemedeyRes] RR(NOLOCK)
                              ON D.[DAC_RESERVATION_NO] = RR.[RESERVATION_NO]  
                     --LEFT JOIN (SELECT DCA_CLAIM_ID,DCA_AUTHOR_TO_DATE, MAX(DAC_AUTHOR_TO_TIME) DAC_AUTHOR_TO_TIME from DA_AUTHORIZATION da(NOLOCK)
                     --         WHERE DCA_BILL_TO=1
                     --         group by DCA_CLAIM_ID,DCA_AUTHOR_TO_DATE
                     --         ) dauth_time on dauth.DCA_CLAIM_ID =dauth_time.DCA_CLAIM_ID
                     --         and dauth.DCA_AUTHOR_TO_DATE =dauth_time.DCA_AUTHOR_TO_DATE                                        
                  WHERE  ((@AgreementNo = 0 or @AgreementNo is null) OR  @AgreementNo = D.DAC_AGREEMENT_NUMBER)
                  AND ((@Dac_Status = 0 or @Dac_Status is null) OR @Dac_Status = D.DAC_STATUS) 
                  AND ((@ClientLastName = '' or @ClientLastName is null) OR DAC_CLIENT_LAST_NAME like '%' + @ClientLastName+'%') 
                  --AND ((@debitorName ='' or @debitorName is null) OR DB1.DEBITOR_NAME  LIKE '%' +@debitorName +'%') 
                  AND (@DebitorCode=0 OR D.DAC_INS_COMPANY_ID=@DebitorCode)
                 -- AND ((@AdjusterLastName ='' or @AdjusterLastName is  null ) OR DA.DAA_LAST_NAME LIKE '%'+ @AdjusterLastName+'%') 
                 -- AND ((@LocCode = 0 or @LocCode is null) OR @LocCode = D.DAC_LOCATION_CODE)
                  AND ((@Claim_or_Policy_No = '' or @Claim_or_Policy_No is null) OR (@Claim_or_Policy_No = ltrim(rtrim(D.DAC_POLICY)) or @Claim_or_Policy_No =ltrim(rtrim(D.DAC_INS_CLAIM)) )) 
                  --AND ((@Claim_No ='' or @Claim_No is null) OR ltrim(rtrim(D.DAC_INS_CLAIM)) = @Claim_No) 
                  AND ((@ReservationNo = '' or @ReservationNo is null) OR @ReservationNo = D.DAC_RESERVATION_NO) 
                  --AND ((@AgrToDate is null or @AgrToDate = '') OR @AgrToDate <= D.DAC_AGR_OPEN_DATE) 
                  --AND ((@AgrFromDate is null or @AgrFromDate = '') OR @AgrFromDate >= D.DAC_AGR_OPEN_DATE) 
                  --AND ((@AgrToDate is null or @AgrToDate = '') OR @AgrToDate <= D.DAC_AGR_CLOSE_DATE) 
                  --AND ((@AgrFromDate is null or @AgrFromDate = '') OR @AgrFromDate >= D.DAC_AGR_CLOSE_DATE) 
                  --AND ((@InvoiceToDate is null or @InvoiceToDate = '') or  @InvoiceToDate <= D.DAC_INVOICE_DATE) 
                  --AND ((@InvoiceFromDate is null or @InvoiceFromDate = '') or  @InvoiceFromDate >= D.DAC_INVOICE_DATE)
                  --AND (@AdjusterID=0 OR D.DAC_COMPANY_ADJUSTER_ID = @AdjusterID)
                  AND (D.DAC_INS_COMPANY_ID IN 
                              (SELECT  
                                    [INS_COMPANY_ID]
                                    FROM [dbo].[ADJUSTER_DEBITORS] (nolock)
                                    where ADJUSTER_ID =@AdjusterID
                              ))
                        AND D.DAC_STATUS < 5
				AND ( (@ExpiringIn = 0 or @ExpiringIn IS NULL ) OR (DAUTH.DCA_AUTHOR_TO_DATE!='00000000' AND DAUTH.DCA_AUTHOR_TO_DATE BETWEEN  CONVERT(VARCHAR(8), GETDATE(),112 ) AND CONVERT(VARCHAR(8),DATEADD(DAY,@ExpiringIn, GETDATE()),112 )  and d.DAC_STATUS < 4 AND D.DAC_COMPANY_ADJUSTER_ID = @AdjusterID))





