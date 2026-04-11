@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Cube'
@Metadata.ignorePropagatedAnnotations: false
@VDM.viewType: #COMPOSITE
@Analytics.dataCategory: #CUBE
define view entity ZCO_ATS_AB_SLS_CUBE as select from ZCO_ATS_AB_SALES( I_Curr : 'USD' ) as sales
association of many to many ZI_ATS_AB_BPA as _BusinessPartner 
on $projection.Buyer = _BusinessPartner.BusinessPartnerId
{
    key OrderId,
    key ItemId,
    Product,
    ConvertCurrency,
    @Aggregation.default: #SUM
    ConvertedAmount,
    @Aggregation.default: #SUM
    Qty,
    Uom,
    Buyer,
    ProductName,
    ProductCategory,
    _BusinessPartner.CompanyName
}
