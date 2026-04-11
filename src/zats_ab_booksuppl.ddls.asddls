@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Supplement Child Entity'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #COMPOSITE
define view entity ZATS_AB_BOOKSUPPL as select from /dmo/booksuppl_m
association to parent ZATS_AB_BOOKING as _Booking
    on $projection.TravelId = _Booking.TravelId and
       $projection.BookingId = _Booking.BookingId
association[1..1] to ZATS_AB_TRAVEL as _Travel 
    on $projection.TravelId = _Travel.TravelId
association[1..1] to /DMO/I_Supplement as _Supplement 
    on $projection.SupplementId = _Supplement.SupplementID
association[1..*] to /DMO/I_SupplementText as _SupplementText 
    on $projection.SupplementId = _SupplementText.SupplementID    
{
    
    key /dmo/booksuppl_m.travel_id as TravelId,
    key /dmo/booksuppl_m.booking_id as BookingId,
    key /dmo/booksuppl_m.booking_supplement_id as BookingSupplementId,
    /dmo/booksuppl_m.supplement_id as SupplementId,
    @Semantics.amount.currencyCode: 'CurrencyCode'
    /dmo/booksuppl_m.price as Price,
    /dmo/booksuppl_m.currency_code as CurrencyCode,
    @Semantics.systemDateTime.lastChangedAt: true
    /dmo/booksuppl_m.last_changed_at as LastChangedAt,
    _Booking,
    _Travel,
    _Supplement,
    _SupplementText
}
