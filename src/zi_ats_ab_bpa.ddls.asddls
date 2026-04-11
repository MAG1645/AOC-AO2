@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Basic Interface for Business partner'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
@Analytics.dataCategory: #DIMENSION
define view entity ZI_ATS_AB_BPA as select from zats_ab_bpa
{
    key bp_id as BusinessPartnerId,
    bp_role as BpRole,
    company_name as CompanyName,
    country as Country
}
