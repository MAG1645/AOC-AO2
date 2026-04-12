@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Processor projection entity'
@Metadata.ignorePropagatedAnnotations: false
@VDM.viewType: #CONSUMPTION
define view entity ZATS_AB_BOOKING_PROCESSOR as projection on ZATS_AB_BOOKING
{
    key TravelId,
    key BookingId,
    BookingDate,
    CustomerId,
    CarrierId,
    ConnectionId,
    FlightDate,
    FlightPrice,
    CurrencyCode,
    BookingStatus,
    LastChangedAt,
    /* Associations */
    _BookingStatus,
    _BookingSuppl: redirected to composition child ZATS_AB_BOOKSUPPL_PROCESSOR,
    _Carrier,
    _Connection,
    _Customer,
    _Travel: redirected to parent ZATS_AB_TRAVEL_PROCESSOR
}
