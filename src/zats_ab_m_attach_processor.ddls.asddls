@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Processor projection entity for attachment'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true
define view entity ZATS_AB_M_ATTACH_PROCESSOR as projection on ZATS_AB_M_ATTACH
{
    key TravelId,
    key Id,
    Memo,
    Attachment,
    Filename,
    Filetype,
    LocalCreatedBy,
    LocalCreatedAt,
    LocalLastChangedBy,
    LocalLastChangedAt,
    LastChangedAt,
    /* Associations */
    _Travel: redirected to parent ZATS_AB_TRAVEL_PROCESSOR
}
