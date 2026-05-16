@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection for root travel entity'
@Metadata.ignorePropagatedAnnotations: false
@VDM.viewType: #CONSUMPTION
@Metadata.allowExtensions: true
define root view entity ZATS_AB_TRAVEL_PROCESSOR as projection on ZATS_AB_TRAVEL
{
    key TravelId,
    AgencyId,
    CustomerId,
    BeginDate,
    EndDate,
    BookingFee,
    TotalPrice,
    CurrencyCode,
    Description,
    OverallStatus,
    CreatedBy,
    CreatedAt,
    LastChangedBy,
    LastChangedAt,
    AgencyName,
    CustomerName,
    StatusText,
    Minion,
    @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_ATS_AB_VE'
    @EndUserText.label: 'CO2 Tax'
    virtual CO2Tax: abap.int4,
    @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_ATS_AB_VE'
    @EndUserText.label: 'Day Of Travel'
    virtual dayOfFlight: abap.char(10),
    /* Associations */
    _Agency,
    _Booking : redirected to composition child ZATS_AB_BOOKING_PROCESSOR,
    _Attachments: redirected to composition child ZATS_AB_M_ATTACH_PROCESSOR,
    _Currency,
    _Customer,
    _OverallStatus
}
