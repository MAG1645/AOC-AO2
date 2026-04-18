@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Supplement processor projection entity'
@Metadata.ignorePropagatedAnnotations: false
@VDM.viewType: #CONSUMPTION
@Metadata.allowExtensions: true
define view entity ZATS_AB_BOOKSUPPL_PROCESSOR as projection on ZATS_AB_BOOKSUPPL
{
    key TravelId,
    key BookingId,
    key BookingSupplementId,
    SupplementId,
    Price,
    CurrencyCode,
    LastChangedAt,
    /* Associations */
    _Booking: redirected to parent ZATS_AB_BOOKING_PROCESSOR,
    _Supplement,
    _SupplementText,
    _Travel: redirected to ZATS_AB_TRAVEL_PROCESSOR
}
