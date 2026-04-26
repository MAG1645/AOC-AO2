CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR travel RESULT result.
    METHODS copytravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~copytravel.
    METHODS earlynumbering_cba_booking FOR NUMBERING
      IMPORTING entities FOR CREATE travel\_booking.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE travel.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_authorizations.
*    data: lt_failed type response for failed early zats_ab_travel.
*    data: lt_reported type response for REPORTED early zats_ab_travel.
*    data : lt_test type response for MAPPED zats_ab_travel//travel.
    "AUTHORITY-CHECK
  ENDMETHOD.

  METHOD earlynumbering_create.

    data: entity type strUCTURE FOR create zats_ab_travel,
          travel_id_max type /dmo/travel_id.

    ""Step 1: Ensure that the travel id is not passed by user, so we can generate id
    loop at entities into entity where travelid is not initial.
        append corRESPONDING #( entity ) to mapped-travel.
    enDLOOP.

    ""Step 2: lets take all travel request data in another copy
    ""        filter out record which has travel id, only keep where travel id blank
    data(entities_wo_travelid) = entities.
    delete entities_wo_travelid where travelid is not initial.

    ""Step 3: Lets use SNRO generator to create travel id
    "" example current no 422 , i want 3 = 426, 426-3 = 423
    "" 423+1 = 424, 424+1 = 425, 425+1 = 426
    try.
        cl_numberrange_runtime=>number_get(
          EXPORTING
            nr_range_nr       = '01'
            object            = CONV #( '/DMO/TRAVL' )
            quantity          = CONV #( LINES( entities_wo_travelid ) )
          IMPORTING
            number            = data(number_range_key)
            returncode        = data(number_Range_return_code)
            returned_quantity = data(number_Range_returned_quantity)
        ).
    catCH cx_number_ranges into data(lx_number_ranges).
        ""Step 4: If there is a dump inside, we will just fill failed and reported
        loop at entities_wo_travelid into entity.
            append value #( %cid = entity-%cid %key = entity-%key %msg = lx_number_ranges )
                to reported-travel.
            append value #( %cid = entity-%cid %key = entity-%key )
                to failed-travel.
        endloop.
    enDTRY.

    ""Step 5: handle special cases if no. range exhaused, about to get exhaused
    case number_Range_return_code.
        when '1'.
            "About to exhause 99% numbers finished - warning
            loop at entities_wo_travelid into entity.
                append value #( %cid = entity-%cid %key = entity-%key
                                %msg = new /dmo/cm_flight_messages(
                                            textid = /dmo/cm_flight_messages=>number_range_depleted
                                            severity = if_abap_behv_message=>severity-warning
                                        ) )
                    to reported-travel.
            endloop.
        when '2' OR '3'.
            ""last number was retured or no. range exhaused
            append value #( %cid = entity-%cid %key = entity-%key
                                %msg = new /dmo/cm_flight_messages(
                                            textid = /dmo/cm_flight_messages=>not_sufficient_numbers
                                            severity = if_abap_behv_message=>severity-warning
                                        ) )
                    to reported-travel.
            append value #( %cid = entity-%cid %key = entity-%key
                            %fail-cause = if_abap_behv=>cause-conflict )
                to failed-travel.

    eNDCASE.

    ""Step 6 : Final check for all numbers
    assert number_Range_returned_quantity = LINES( entities_wo_travelid ).

    ""Step 7 Loop over the incoming data and assign the travel id by incrementing it
    ""       send the data wrapped to RAP framewor
    travel_id_max = number_range_key - number_range_returned_quantity.

    loop at entities_wo_travelid into entity.

        travel_id_max += 1.
        entity-TravelId = travel_id_max.

        append value #( %cid = entity-%cid %key = entity-%key ) to mapped-travel.

    endloop.

  ENDMETHOD.

  METHOD earlynumbering_cba_Booking.

    data max_booking_id type /dmo/booking_id.

    ""Step 1: Get All the travel request and their bookings
    read entities of zats_ab_travel in local mode
        entity travel by \_Booking
        from CORRESPONDING #( entities )
        link data(lt_bookings).

    ""Step 2: Cases to handle for Assigning unique Booking ID
    "1001, 1002, 1005
    loop at entities assIGNING fiELD-SYMBOL(<travel_group>) group by <travel_group>-TravelId.

        ""Step 3: Loop at the specific booking of every unique travel id
        ""If there is already the data inside, assign the Booking id to our variable which is max
        "Pass 1 - 10,20
        "Pass 2 - 10
        "Pass 3 - 40,50
        loop at lt_bookings into data(ls_bookings) using key entity
                                        where source-Travelid = <travel_group>-TravelId.
           ""Determine the Already created Booking Id which is maximum
           if max_booking_id < ls_bookings-target-BookingId.
              max_booking_id = ls_bookings-target-BookingId.
           endif.
        enDLOOP.
    enDLOOP.

    ""Step 4: Loop over all the entities of travel with same travel id and increment the max booking id

    loop at entities assIGNING fiELD-SYMBOL(<travel>) group by <travel>-TravelId.

        ""Step 5: Increment the Booking id +10 and assign the new id
        loop at <travel>-%target assigning field-symbol(<travel_wo_number>).
           append corresponding #( <travel_wo_number> ) to mapped-booking
                                assigning field-symbol(<mapped_booking>).
           ""Determine the Already created Booking Id which is maximum
           ""Assining the +10 as new booking id
           if <mapped_booking>-BookingId is initial.
              max_booking_id += 10.
              <mapped_booking>-BookingId = max_booking_id.
           endif.
        enDLOOP.
    enDLOOP.


  ENDMETHOD.

  METHOD get_instance_features.

    ""Use case: check the status of the current travel request
    ""          if cancelled, disable the booking creation

    ""Step 1: EML to read the travel status
    read entities of zats_ab_travel in local mode
        entity travel
            fields ( travelid overallstatus )
            with corresponding #( keys )
        result data(lt_travel)
        failed data(lt_failed).

    ""Step 2: Return the result with booking creation is possible or not
    read table lt_travel into data(ls_travel) index 1.

    if ( ls_travel-OverallStatus = 'X' ).
       data(lv_allow) = if_abap_behv=>fc-o-disabled.
    else.
        lv_allow = if_abap_behv=>fc-o-enabled.
    endif.


    result = value #(  for travel in lt_travel ( %tky = travel-%tky
                                                 %assoc-_Booking = lv_allow ) ).





  ENDMETHOD.

  METHOD copyTravel.

    "Shallow Copy = Header
    "Deep Copy = Header, Items, Sub Items
    ""Step 1: Declare data to store new records
    data: travels type table for create zats_ab_travel\\Travel,
          bookings_cba type table for create zats_ab_travel\\Travel\_Booking,
          booksuppl_cba type table for create zats_ab_travel\\Booking\_BookingSuppl.


    "Step 1:Validate to make sure no data with blank %cid is allowed
    read table keys with key %cid = '' into data(key_with_initial_cid).
    assert     key_with_initial_cid is initial.

    "Step 2: Read all the existing data of travel, booking, supplement

    read entities of zats_ab_travel in local mode
    entity travel
        all fields with corrESPONDING #( keys )
        result data(travel_read_result)
        failed failed.

    read entities of zats_ab_travel in local mode
    entity travel by \_Booking
        all fields with corrESPONDING #( travel_read_result )
        result data(book_read_result)
        failed failed.

    read entities of zats_ab_travel in local mode
    entity booking by \_BookingSuppl
        all fields with corrESPONDING #( book_read_result )
        result data(booksuppl_read_result)
        failed failed.

    ""Step 2: Prepare the data to be inserted in DB
    loop at travel_read_result assIGNING fiELD-SYMBOL(<travel>).

       ""Travel data prepare
       append value #( %cid = keys[ %tky = <travel>-%tky ]-%cid
                       %data = corrESPONDING #( <travel> except travelid )
                     ) to travels assIGNING fiELD-SYMBOL(<new_travel>).

       <new_travel>-BeginDate = cl_abap_context_info=>get_system_date( ).
       <new_travel>-EndDate = cl_abap_context_info=>get_system_date( ) + 30.
       <new_travel>-OverallStatus = 'N'.



    enDLOOP.

    ""Step 3: Insert data in DB using EML
    modify entities of zats_ab_travel in local mode
        entity travel
         create fields ( agencyid customerid begindate enddate bookingfee totalprice currencycode overallstatus )
           with travels
         mapped data(mapped_data).

    mapped-travel = mapped_data-travel.






  ENDMETHOD.

ENDCLASS.
