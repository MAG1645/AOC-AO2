@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Analytic Query for Sales Dashboard'
@Metadata.ignorePropagatedAnnotations: false
@VDM.viewType: #CONSUMPTION
@Analytics.query: true
define view entity ZC_ATS_AB_SLS_ANA as select from ZCO_ATS_AB_SLS_CUBE
{
    key ProductName,
    @Consumption.filter.selectionType: #SINGLE
    key ProductCategory,
    @AnalyticsDetails.query.axis: #ROWS
    key CompanyName,
    ConvertCurrency,
    ConvertedAmount,
    Qty,
    Uom
}
