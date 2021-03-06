USE [Carpro_App]
GO
/****** Object:  StoredProcedure [dbo].[spCarproALLInsuranceClosedAgreementReport]    Script Date: 04/05/2018 09:43:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Exec spCarproALLInsuranceClosedAgreementReport
ALTER PROCEDURE [dbo].[spCarproALLInsuranceClosedAgreementReport]
@FromDate varchar(8)='20150501', 
@ToDate varchar(8) ='20150531',
@NonQuebecDebitorCodes varchar(MAX) = 'ALL',
@QuebecDebitorCodes varchar(MAX) = 'ALL'
AS
Begin

Create table #QuebecInsuranceClosedAgreements (
Supplier Varchar(50), 
InsurerType Varchar(50), 
InvoiceDate datetime, 
ParentInsurerName Varchar(MAX),
InsurerName Varchar(MAX),
ClaimType Varchar(50),
ExtentOfLoss Varchar(50),
RepairType Varchar(50),
Drivability Varchar(50),
InsuredClaimNumber Varchar(50),
InsuredPolicyNumber Varchar(50),
VendorContractNumber Varchar(50),
AuthRate Varchar(50),
AvgRate Varchar(50),
BaseRentalFee Varchar(50),
VehicleLicenseFee Varchar(50),
WinterTireFee Varchar(50),
KilometerCharges Varchar(50),
GeographicSurcharge Varchar(50),
DropFees Varchar(50),
DiscountDeductibleCoverage Varchar(50),
CollisionDamageWaiver Varchar(50),
PracticleAssistanceProgram Varchar(50),
SubTotal Varchar(50),
ProvincialTaxes Varchar(50),
FederalTaxes Varchar(50),
TotalFees  Varchar(50),
RentalDays  Varchar(50),
AuthorizedDays  Varchar(50),
DateOfIncident  datetime,
Month varchar(50),
RentalStartDate  datetime,
RentalEndDate  datetime,
ICC_Make  Varchar(50),
ICC_Model  Varchar(50),
ICC_Vehicle_Year  Varchar(50),
ICC_Category varchar(50),
CarManufacturer  Varchar(50),
CarModel  Varchar(50),
Category  Varchar(50),
CarCategory varchar(50),
VehicleYear  Varchar(50),
BranchCode  Varchar(50),
BranchName  Varchar(50),
BranchCity  Varchar(50),
BranchState  Varchar(50),
BranchCountry  Varchar(50),
GarageName Varchar(MAX),
GarageAddress Varchar(MAX),
BannerName Varchar(50),
AdjusterName Varchar(200),
CatastrophyFlag Varchar(50),
Preferred_Garages Varchar(50)
)



Create table #NonQuebecInsuranceClosedAgreements (
Supplier Varchar(50), 
InsurerType Varchar(50), 
InvoiceDate datetime, 
ParentInsurerName Varchar(MAX),
InsurerName Varchar(MAX),
ClaimType Varchar(50),
ExtentOfLoss Varchar(50),
RepairType Varchar(50),
Drivability Varchar(50),
InsuredClaimNumber Varchar(50),
InsuredPolicyNumber Varchar(50),
VendorContractNumber Varchar(50),
AuthRate Varchar(50),
AvgRate Varchar(50),
BaseRentalFee Varchar(50),
VehicleLicenseFee Varchar(50),
WinterTireFee Varchar(50),
KilometerCharges Varchar(50),
GeographicSurcharge Varchar(50),
DropFees Varchar(50),
DiscountDeductibleCoverage Varchar(50),
CollisionDamageWaiver Varchar(50),
PracticleAssistanceProgram Varchar(50),
SubTotal Varchar(50),
ProvincialTaxes Varchar(50),
FederalTaxes Varchar(50),
TotalFees  Varchar(50),
RentalDays  Varchar(50),
AuthorizedDays  Varchar(50),
DateOfIncident  datetime,
Month varchar(50),
RentalStartDate  datetime,
RentalEndDate  datetime,
ICC_Make  Varchar(50),
ICC_Model  Varchar(50),
ICC_Vehicle_Year  Varchar(50),
ICC_Category varchar(50),
CarManufacturer  Varchar(50),
CarModel  Varchar(50),
Category  Varchar(50),
CarCategory varchar(50),
VehicleYear  Varchar(50),
BranchCode  Varchar(50),
BranchName  Varchar(50),
BranchCity  Varchar(50),
BranchState  Varchar(50),
BranchCountry  Varchar(50),
GarageName Varchar(MAX),
GarageAddress Varchar(MAX),
BannerName Varchar(50),
AdjusterName Varchar(200),
CatastrophyFlag Varchar(50),
Preferred_Garages Varchar(50)
)


Insert into #NonQuebecInsuranceClosedAgreements
	Exec spCarproNonQuebecInsuranceClosedAgreementReport @FromDate, @ToDate, @NonQuebecDebitorCodes
Insert into #QuebecInsuranceClosedAgreements
	Exec spCarproQuebecInsuranceClosedAgreementReport @FromDate, @ToDate, @QuebecDebitorCodes
	
Select * from #QuebecInsuranceClosedAgreements
UNION ALL
Select * from #NonQuebecInsuranceClosedAgreements

END


--Exec [spCarproALLInsuranceClosedAgreementReport] '20160501', '20160530'