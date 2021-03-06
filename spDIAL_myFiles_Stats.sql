USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_myFiles_Stats]    Script Date: 04/05/2018 09:38:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Create date: <Jan 21, 2013 spDIAL_myFiles_Stats>
-- Description:	<My Files (To Do, Completed, Invoices, Unassigned, Pending%(todo + invoice)/(todo + invoice + completed)->0 if null)>
-- =============================================
--EXEC spDIAL_myFiles_Stats 16833
--0 - NEW, 1-BOOKED, 2-ACTIVE, 3-EXPIRED, 4-INACTIVE, 5-CANCELLED, 6-ABEND	 
ALTER PROCEDURE [dbo].[spDIAL_myFiles_Stats]	
@Debitor_Code INT, @dtStartDate smalldatetime ='01/01/2013', @dtEndDate smalldatetime ='01/31/2013 23:59:00'
AS
BEGIN	
	SET NOCOUNT ON;
	
	Declare @myStats Table (
	Debitor_Code bigint,
	Adjuster_ID bigint,
	ToDo bigint,
	Completed bigint,
	Invoice bigint,
	Unassigned bigint
	)	


	
		
	--To do
	
	Declare @myTodoStats Table (
	Debitor_Code bigint,
	Adjuster_ID bigint,
	ToDo bigint
	)	

	insert into @myTodoStats
	SELECT  DAC_INS_COMPANY_ID,
            DAC_COMPANY_ADJUSTER_ID, COUNT(*) TODO_COUNT
	FROM
	(
		SELECT D.OK_TO_BILL AS okToBill,ISNULL(R.STATUS_CODE,0) AS dacRentalAgrStatus,ISNULL(ISNULL(V.ACKNOWLEDGE,EB.ACKNOWLEDGE),'N') AS acknowledge  , ISNULL(ISNULL(V.DISPUTE,EB.DISPUTE),'N') AS dispute,ISNUll((SELECT TOP 1 'Y' FROM EBILLING_INVOICE_DATA E WHERE E.ENTRY_ID=DAC_ENTRY_ID),'N') AS ebillrecPresent,
                  CASE 
            WHEN D.DAC_STATUS=4 or R.STATUS_CODE=0 OR R.STATUS_CODE=4  THEN 
                  ISNULL(R.SOLD_DAYS, Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))))
            ELSE              
                  ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()), 0)
                  --ISNULL(DATEDIFF(DAY,dbo.convertToDate(D.DAC_AGR_OPEN_DATE),GETDATE()),0) 
            END AS rentaldays ,
                 CASE 
                              WHEN D.DAC_STATUS=4 or R.STATUS_CODE=4   THEN 
                                    ROUND(dauth.DCA_AUTHOR_RATE * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))))  +
                                    (ISNULL(dauth.DCA_AUTHOR_RATE,0) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))) * ISNULL(dauth.VAT_PER,0)/100),2)
                              WHEN DAC_AGR_OPEN_DATE > '00000000' THEN
                                    ISNULL(dauth.DCA_AUTHOR_RATE,0) * ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()),0) + 
                                    ((ISNULL(dauth.DCA_AUTHOR_RATE,0)* ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()),0)) * ISNULL(dauth.VAT_PER,0)/100)
                              ELSE NULL      
            end AS totalRental ,
            ISNULL(dauth.dca_a_days,0) AS dacAuthorDays,
            D.DAC_RESERVATION_NO AS dacReservationNo,
            D.DAC_AGREEMENT_NUMBER AS dacAgreementNumber,
            D.DAC_CLIENT_LAST_NAME AS dacClientLastName,
            D.DAC_CLIENT_FIRST_NAME AS dacClientFirstName,
            D.DAC_AGR_OPEN_DATE AS dacAgreementOpenDate,
            CASE 
                  WHEN (D.DAC_ARS_WEB!='Y' AND R.STATUS_CODE=0 or R.STATUS_CODE=4) OR      (D.DAC_ARS_WEB='Y' AND D.DAC_AGR_CLOSE_DATE!='00000000')  THEN D.DAC_AGR_CLOSE_DATE
                  ELSE '00000000'
            END   AS dacAgreementCloseDate,
            ISNULL(dauth.DCA_AUTHOR_RATE,0) AS dacAuthorizedRate,
            D.DAC_TAX_PAID_BY AS dacTaxPaidBy,            
            DA.DAA_LAST_NAME AS dacCompanyAdjLastName,
            DA.DAA_FIRST_NAME AS dacCompanyAdjFirstName,
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
            D.DAC_INVOICE_DATE AS  dacInvoiceDate,            
            DB1.DEBITOR_NAME AS dacInsCompanyName,
            D.DAC_INS_COMPANY_ID,
            D.DAC_COMPANY_ADJUSTER_ID,
            ISNULL(V.INVOICE_NO,0) AS invoiceNo
            FROM DA_CLAIMS D(NOLOCK)
                  LEFT OUTER JOIN RemedeyAgr R(NOLOCK) ON R.AGREEMENT_NO = D.DAC_AGREEMENT_NUMBER
                  LEFT OUTER JOIN Vw_Dial_Inv V(NOLOCK) ON V.AGREEMENT_NO = D.DAC_AGREEMENT_NUMBER AND V.INVOICE_TYPE = 'C' AND V.INV_STATUS != 9 AND D.DAC_INS_COMPANY_ID = v.DEBITOR_NO
                  LEFT OUTER JOIN EBILLING_INVOICE_DATA EB(NOLOCK) on EB.Entry_ID = D.DAC_ENTRY_ID
                  LEFT OUTER JOIN (SELECT da.DCA_CLAIM_ID,ISNULL(AVG(VAT_PER),0)VAT_PER,ISNULL(SUM(dca_a_days),0) dca_a_days,ISNULL(AVG(DCA_AUTHOR_RATE),0) DCA_AUTHOR_RATE,
													MAX(DA.DCA_AUTHOR_TO_DATE) DCA_AUTHOR_TO_DATE
                                                      from DA_AUTHORIZATION da(NOLOCK) where DCA_BILL_TO=1 GROUP BY da.DCA_CLAIM_ID )
                                                      AS dauth ON D.DAC_ENTRY_ID = dauth.DCA_CLAIM_ID
                              LEFT JOIN DEBITORS DB1(NOLOCK)
                              ON D.DAC_INS_COMPANY_ID = DB1.DEBITOR_CODE
                              LEFT JOIN DA_ADJUSTER DA(NOLOCK)
                              ON D.DAC_COMPANY_ADJUSTER_ID = DA.DAA_ENTRY_ID
                              
                  WHERE(
                                          (
                              (

                                                D.DAC_STATUS=3
                                                AND ISNULL(dauth.dca_a_days,0) < (DATEDIFF(DAY,dbo.convertToDate(D.dac_agr_open_date),
                                                CASE WHEN (D.DAC_ARS_WEB!='Y' AND R.STATUS_CODE=0 OR R.STATUS_CODE=4) OR (D.DAC_ARS_WEB='Y' AND D.DAC_AGR_CLOSE_DATE!='00000000') 
                                    THEN dbo.convertToDate(D.dac_agr_close_date)
                                                ELSE
                                    CASE WHEN dbo.convertToDate(D.DAC_AGR_OPEN_DATE) = CONVERT (CHAR(8),GETDATE(),112)
                                    THEN GETDATE()+1 
                                    ELSE GETDATE() 
                                    END 
                                                END)
                                                )
                             )
                        AND D.DAC_STATUS in(3,4)                      
                        and charindex('UNKNOWN',D.DAC_COMPANY_ADJ_FIRST_NAME) =0
                         and charindex('UNKNOWN',D.DAC_COMPANY_ADJ_LAST_NAME) =0
                        AND D.DAC_COMPANY_ADJUSTER_ID > 0
                        )
                  )
                  AND D.DAC_INS_COMPANY_ID=@Debitor_Code
                  AND D.DAC_STATUS < 5
                  --AND (@AdjusterID=0 OR D.DAC_COMPANY_ADJUSTER_ID = @AdjusterID) 
    ) T1
	GROUP BY DAC_INS_COMPANY_ID,
            DAC_COMPANY_ADJUSTER_ID
	
	
	Declare @myCompleteStats Table (
	Debitor_Code bigint,
	Adjuster_ID bigint,
	Completed bigint
	)	
	
	
	INSERT INTO @myCompleteStats
	select DAC_INS_COMPANY_ID,
            DAC_COMPANY_ADJUSTER_ID, count(*) AS COMPLETE_COUNT
	from
	(
	  SELECT OK_TO_BILL AS okToBill,              
      CASE 
      WHEN D.DAC_STATUS=4 or R.STATUS_CODE=0 OR R.STATUS_CODE=4  THEN 
      ISNULL(R.SOLD_DAYS, Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))))
	  WHEN D.DAC_STATUS=1 THEN 
      ISNULL(RR.SOLD_DAYS, Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,RR.CHECK_OUT_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,RR.CHECK_OUT_DATE,112))), DATEADD(SECOND,RR.CHECK_IN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,RR.CHECK_IN_DATE,112)))))
      WHEN D.DAC_AGR_OPEN_DATE >'00000000' THEN
      ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()), 0)
	  ELSE NULL      
      END AS rentaldays ,                   
      CASE 
                              WHEN D.DAC_STATUS=4 or R.STATUS_CODE=4   THEN 
                                    ROUND(dauth.DCA_AUTHOR_RATE * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112)))))  +
                                    (ISNULL(dauth.DCA_AUTHOR_RATE,0) * ISNULL(R.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), DATEADD(SECOND,DAC_AGR_CLOSE_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_CLOSE_DATE,112))))) * ISNULL(dauth.VAT_PER,0)/100),2)
                                    
							WHEN D.DAC_STATUS=1   THEN  --FOR RESERVATION
                                    ROUND(dauth.DCA_AUTHOR_RATE * ISNULL(RR.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,RR.CHECK_OUT_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,RR.CHECK_OUT_DATE,112))), DATEADD(SECOND,RR.CHECK_IN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,RR.CHECK_IN_DATE,112)))))  +
                                    (ISNULL(dauth.DCA_AUTHOR_RATE,0) *  ISNULL(RR.SOLD_DAYS,Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,RR.CHECK_OUT_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,RR.CHECK_OUT_DATE,112))), DATEADD(SECOND,RR.CHECK_IN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,RR.CHECK_IN_DATE,112))))) * ISNULL(dauth.VAT_PER,0)/100),2)                                    
                              
                            WHEN D.DAC_AGR_OPEN_DATE >'00000000' THEN
                                    ISNULL(dauth.DCA_AUTHOR_RATE,0) * ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()),0) + 
                                    ((ISNULL(dauth.DCA_AUTHOR_RATE,0)* ISNULL(Carpro_App.dbo.fn_Cal_hourly_RentalDays(DB1.DAYS_CALC_LOGIC, DATEADD(SECOND,DAC_AGR_OPEN_TIME,CONVERT(DATETIME,CONVERT(VARCHAR,DAC_AGR_OPEN_DATE,112))), GETDATE()),0)) * ISNULL(dauth.VAT_PER,0)/100)
                            ELSE NULL   
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
					D.DAC_INS_COMPANY_ID,
					D.DAC_COMPANY_ADJUSTER_ID,
            CASE D.DAC_INVOICE_DATE
                  WHEN '00000000' THEN ''
                  ELSE D.DAC_INVOICE_DATE END AS  dacInvoiceDate,                  
                  DB1.DEBITOR_NAME AS dacInsCompanyName,
                  FINAL_AUTH AS finalAuth 
            FROM DA_CLAIMS D(nolock)
            LEFT OUTER JOIN RemedeyAgr R(nolock) ON R.AGREEMENT_NO = D.DAC_AGREEMENT_NUMBER
            LEFT OUTER JOIN (SELECT da.DCA_CLAIM_ID,ISNULL(AVG(VAT_PER),0)VAT_PER,ISNULL(sum(dca_a_days),0) dca_a_days,
                                    ROUND(ISNULL(AVG(DCA_AUTHOR_RATE),0),2) DCA_AUTHOR_RATE FROM DA_AUTHORIZATION da(nolock) 
                                    WHERE DCA_BILL_TO = 1 GROUP BY da.DCA_CLAIM_ID )AS dauth ON D.DAC_ENTRY_ID = dauth.DCA_CLAIM_ID    
             LEFT JOIN DA_ADJUSTER DA(NOLOCK) ON DA.DAA_ENTRY_ID = D.DAC_COMPANY_ADJUSTER_ID
             LEFT JOIN DEBITORS DB1(NOLOCK)
             ON DB1.DEBITOR_CODE = D.DAC_INS_COMPANY_ID
             LEFT JOIN [RemedeyRes] RR(NOLOCK)
             ON D.[DAC_RESERVATION_NO] = RR.[RESERVATION_NO]
            WHERE(
                         (
                              (     
                                    (D.DAC_ARS_WEB!='Y' AND D.FINAL_AUTH='Y' 
                                          AND NOT EXISTS (SELECT 1 FROM Vw_Dial_Inv I(NOLOCK) INNER JOIN DEBITORS Db(NOLOCK) 
                                                                  ON Db.DEBITOR_CODE = I.DEBITOR_NO 
                                                                  WHERE I.INVOICE_NO != 0 AND  I.INVOICE_TYPE = 'C' AND INV_STATUS != 9 
                                                                        AND D.DAC_AGREEMENT_NUMBER = I.Agreement_No AND Db.Debitor_type = 'O' AND  I.DEBITOR_NO = D.DAC_INS_COMPANY_ID) 
                                                      AND NOT EXISTS( SELECT 1 FROM oldRemdyAgr ag(NOLOCK) 
                                                                              WHERE ag.agreement_no = D.DAC_AGREEMENT_NUMBER AND ag.old_agreement_no != '' )
                                    ) 
                                    OR
                                    (D.DAC_ARS_WEB='Y' AND NOT EXISTS (SELECT 1 FROM EBILLING_INVOICE_DATA E(NOLOCK) WHERE E.Entry_ID = D.DAC_ENTRY_ID) 
                                    AND dauth.dca_a_days >=      (DATEDIFF(DAY,dbo.convertToDate(D.DAC_AGR_OPEN_DATE),
                                                                              CASE
                                                                                    WHEN (D.DAC_ARS_WEB != 'Y' AND R.STATUS_CODE = 0 OR R.STATUS_CODE = 4) OR (D.DAC_ARS_WEB='Y' AND D.DAC_AGR_CLOSE_DATE!='00000000') 
                                                                                    THEN dbo.convertToDate(D.DAC_AGR_CLOSE_DATE)
                                                                                    ELSE GETDATE() 
                                                                              END)
                                                                        )
                                    )
                              )
                              OR 
                              (dauth.dca_a_days >= (DATEDIFF(DAY,dbo.convertToDate(D.dac_agr_open_date),
                                                                        CASE
                                                                        WHEN (D.DAC_ARS_WEB != 'Y' AND R.STATUS_CODE = 0 OR R.STATUS_CODE = 4) OR (D.DAC_ARS_WEB = 'Y' AND D.DAC_AGR_CLOSE_DATE != '00000000') 
                                                                        THEN 
                                                                              dbo.convertToDate(D.DAC_AGR_CLOSE_DATE)
                                                                        ELSE 
                                                                              CASE 
                                                                                    WHEN dbo.convertToDate(D.DAC_AGR_OPEN_DATE) = CONVERT (CHAR(8),GETDATE(),112)
                                                                                    THEN GETDATE()+1 
                                                                                    ELSE GETDATE() 
                                                                                    END 
                                                                        END   )
                                                                        )
                              AND (
                                          (D.DAC_ARS_WEB != 'Y' AND R.STATUS_CODE = 1 OR R.STATUS_CODE = 2 OR D.DAC_AGREEMENT_NUMBER = 0) 
                                          OR (D.DAC_ARS_WEB='Y' AND (D.DAC_AGR_CLOSE_DATE='00000000' OR D.DAC_AGREEMENT_NUMBER=0) )
                                    )
                              )
                               OR --Lakshmi added on 20130124
                              (
								D.DAC_STATUS IN (0,1) -- BOOK SINCE NEW DOESN'T HAVE START_DATE ON RESERVATION
							  )		
                        )
                and d.dac_status < 5
                and charindex('UNKNOWN',D.DAC_COMPANY_ADJ_FIRST_NAME) =0
                and charindex('UNKNOWN',D.DAC_COMPANY_ADJ_LAST_NAME) =0
                AND D.DAC_COMPANY_ADJUSTER_ID>0
                AND ((d.DAC_AGR_OPEN_DATE !='00000000' AND D.DAC_STATUS IN (1,2,3,4)) OR (d.DAC_AGR_OPEN_DATE >='00000000' AND D.DAC_STATUS IN (0) ))
                AND dac_create_date>'20120101'
                  )
                  AND (D.DAC_INS_COMPANY_ID =@Debitor_Code
                  )               
                  AND DAC_MODIFIED_DATE BETWEEN  CONVERT(VARCHAR(8),@dtStartDate,112)  AND CONVERT(VARCHAR(8),@dtEndDate,112)   
	) T2
	GROUP BY DAC_INS_COMPANY_ID,
            DAC_COMPANY_ADJUSTER_ID
	


Declare @myInvoiceStats Table (
	Debitor_Code bigint,
	Adjuster_ID bigint,
	Invoice bigint
	)	
	
INSERT INTO @myInvoiceStats
select DAC_INS_COMPANY_ID,
            DAC_COMPANY_ADJUSTER_ID,
	 count(*) COUNT_INVOICE
	from
	(
	  SELECT INV_FROM AS invFrom, INVOICE_NO AS invoiceNo, INVOICE_DATE AS invoiceDate, AGREEMENT_NO AS agreementNo, DEBITOR_NO AS debitORNo,
	   		DAC_POLICY AS dacPolicy, DAC_INS_CLAIM AS dacInsClaim,DAC_CLIENT_LAST_NAME AS dacClientLastName, DAC_CLIENT_FIRST_NAME AS dacClientFirstName,
	   		DAC_COMPANY_ADJUSTER_ID , DAA_FULL_NAME AS daaFullName, ISNUll(DIAL_INVOICES.ACKNOWLEDGE,'N') AS acknowledge,
	   		DAC_ENTRY_ID AS daaEntryId, DAC_ARS_WEB AS dacArsWeb, DEBITOR_TYPE AS debitORType, ISNUll(DIAL_INVOICES.DISPUTE,'N') AS dispute,
	   		CASE WHEN E.ENTRY_ID IS NOT NULL THEN 'Y' ELSE 'N' END AS ebillrecPresent,
	   		DIAL_INVOICES.DEBITOR_NO DAC_INS_COMPANY_ID
		FROM vw_DIAL_INVOICES DIAL_INVOICES(nolock) left join Ebilling_invoice_data E(nolock)
			on DIAL_INVOICES.DAC_ENTRY_ID = E.ENTRY_ID
		WHERE  
		  INVOICE_DATE BETWEEN CONVERT(VARCHAR(8),DATEADD(WEEK,-2,GETDATE()),112) AND CONVERT(VARCHAR(8),GETDATE(),112)   --DISPLAY ONLY 2 WEEK PRIOR TODAY				  		 
		  AND DEBITOR_NO =@Debitor_Code
		  AND
		  (--D.DAC_STATUS=4 AND
                                          (DIAL_INVOICES.DAC_ARS_WEB!='Y' AND 
                                                                        EXISTS
                                                (SELECT * FROM Vw_Dial_Inv I(NOLOCK) INNER JOIN DEBITORS Db(NOLOCK)
                                                ON  Db.DEBITOR_CODE = I.DEBITOR_NO 
                                                WHERE I.INVOICE_NO!=0                                                   
                                                AND I.ACKNOWLEDGE !='Y' AND I.DISPUTE != 'Y' AND I.INVOICE_TYPE='C' AND INV_STATUS!=9 
                                                AND DIAL_INVOICES.AGREEMENT_NO = I.Agreement_No AND Db.DEBITOR_TYPE = 'O' AND DIAL_INVOICES.DEBITOR_NO=I.DEBITOR_NO)
                                          )

                                          OR 
                                          (DIAL_INVOICES.DAC_ARS_WEB = 'Y' AND EXISTS 
                                                (SELECT * from EBILLING_INVOICE_DATA E WHERE E.ENTRY_ID = DIAL_INVOICES.DAC_ENTRY_ID AND E.ACKNOWLEDGE !='Y'                                                 
                                                AND E.DISPUTE != 'Y')
                                          )
                                                )	
	) T3
	GROUP BY DAC_INS_COMPANY_ID,
            DAC_COMPANY_ADJUSTER_ID
	
	

Declare @myUnassignedStats Table (
	Debitor_Code bigint,
	Adjuster_ID bigint,
	Unassigned bigint
	)	
	


	INSERT INTO @myUnassignedStats
	select  DAC_INS_COMPANY_ID, null, count(*) UNASSIGNED_COUNT
	from
	(
		select DAC_COMPANY_ADJUSTER_ID, ISNULL(DAC_CLIENT_FIRST_NAME,'') + ' ' + ISNULL(DAC_CLIENT_LAST_NAME,'') AS [Client Name], DAC_CLIENT_PHONE CLIENT_PHONE
		,DAC_POLICY POLICY_NO, DAC_INS_CLAIM AS CLAIM_NO
		, DAC_INS_COMPANY_ID
		from da_claims(nolock)
		where DAC_STATUS < 4
		and ((dac_company_adj_first_name like '%unknown%' or dac_company_adj_last_name like '%unknown%') or DAC_COMPANY_ADJUSTER_ID = 0)
				and DAC_INS_COMPANY_ID =@Debitor_Code
	
	) t4
	group by DAC_INS_COMPANY_ID

--SELECT * FROM @myTodoStats	
--SELECT * FROM @myCompleteStats	
--SELECT * FROM @myInvoiceStats	
--SELECT * FROM @myUnassignedStats	

INSERT INTO @myStats(Debitor_Code,Adjuster_ID )
SELECT @Debitor_Code, Adjuster_ID
FROM
(
SELECT DISTINCT Adjuster_ID
FROM
(
SELECT Adjuster_ID FROM @myTodoStats	
UNION
SELECT Adjuster_ID FROM @myCompleteStats	
UNION
SELECT Adjuster_ID FROM @myInvoiceStats	
UNION
SELECT Adjuster_ID FROM @myUnassignedStats	
) TT
) TTT

update t1
set ToDo = t2.ToDo
from @myStats t1 inner join @myTodoStats t2
on t1.Adjuster_ID= t2.Adjuster_ID

update t1
set Completed = t2.Completed
from @myStats t1 inner join @myCompleteStats t2
on t1.Adjuster_ID= t2.Adjuster_ID

update t1
set Invoice = t2.Invoice
from @myStats t1 inner join @myInvoiceStats t2
on t1.Adjuster_ID= t2.Adjuster_ID


update @myStats
set Unassigned = t2.Unassigned
from @myStats t1 inner join @myUnassignedStats t2
on t1.Debitor_Code= t2.Debitor_Code

select 
case
	when (Isnull(t1.ToDo,0)) = 0 then 0 
	else
	t1.ToDo
	end as ToDo,
case
	when (Isnull(t1.Completed,0)) = 0 then 0 
	else
	t1.Completed
	end as Completed,	
case
	when (Isnull(t1.Invoice,0)) = 0 then 0 
	else
	t1.Invoice
	end as Invoice,	
case
	when (Isnull(t1.Unassigned,0)) = 0 then 0 
	else
	t1.Unassigned
	end as Unassigned,		
	t1.Debitor_Code, t1.Adjuster_ID
--t1.*,  
,[Pending] =
ROUND(
CONVERT(float,
case
	when (Isnull(t1.ToDo,0) + ISNULL(t1.Completed,0) + ISNULL(t1.Invoice,0) ) =0 then 0
	else (Isnull(t1.ToDo,0) + ISNULL(t1.Invoice,0) )*100.0/(Isnull(t1.ToDo,0) + ISNULL(t1.Completed,0) + ISNULL(t1.Invoice,0) )
end),2)
,b.DAA_FULL_NAME AS Adjust_Name from @myStats t1 inner join 
	DA_ADJUSTER b(nolock) 
	on t1.ADJUSTER_ID = b.DAA_ENTRY_ID
	where  ltrim(rtrim(b.STATUS)) ='A'
	--Declare @myStats Table (
	--Debitor_Code bigint,
	--Adjuster_ID bigint,
	--ToDo bigint,
	--Completed bigint,
	--Invoice bigint,
	--Unassigned bigint
	--)	
	
	
	
--DROP TABLE #myTempTable    

END




















