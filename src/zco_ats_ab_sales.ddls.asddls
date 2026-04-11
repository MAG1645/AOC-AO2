@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Composite CDS entity'
@Metadata.ignorePropagatedAnnotations: false
@VDM.viewType: #COMPOSITE
define view entity ZCO_ATS_AB_SALES
with parameters I_Curr : abap.cuky(5)
 as select from ZI_ATS_AB_SALES as sales
association of many to many ZI_ATS_AB_PRODUCT as _Product
on $projection.Product = _Product.ProductId 
{
    key OrderId,
    key ItemId,
    Product,
    Amount,
    Currency,
    cast('USD' as abap.cuky) as ConvertCurrency,
    @Semantics.amount.currencyCode: 'ConvertCurrency'
    currency_conversion( amount => Amount, 
                        source_currency => Currency, 
                        target_currency => $parameters.I_Curr, 
                        exchange_rate_date => $session.system_date )
                            as ConvertedAmount,
    Qty,
    Uom,
    Buyer,
    _Product.Name as ProductName,
    _Product.Category as ProductCategory
}
