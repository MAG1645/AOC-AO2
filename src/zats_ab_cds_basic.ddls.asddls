@AbapCatalog.sqlViewName: 'ZATSABCDSBASIC'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Basics of CDS view'
@Metadata.ignorePropagatedAnnotations: true
define view ZATS_AB_CDS_BASIC as select from zats_ab_bpa
{
    key bp_id as BpId,
    bp_role as BpRole,
    company_name as CompanyName,
    street as Street,
    country as Country,
    region as Region,
    city as City
}
