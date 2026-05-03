CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR travel RESULT result.
    METHODS copytravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~copytravel.
    METHODS recalctotalprice FOR MODIFY
      IMPORTING keys FOR ACTION travel~recalctotalprice.
    METHODS calctotalprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR travel~calctotalprice.
    METHODS validateheaderdata FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validateheaderdata.
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

        append value #( %cid = entity-%cid %key = entity-%key
                        %is_draft = entity-%is_draft
         ) to mapped-travel.

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

       ""Booking data prepration
       "We have to pass %cid_ref to tell system, that the bookings belongs to
       "which travel request - a record was inserted in itab for booking
       append value #( %cid_ref = keys[ key entity %tky = <travel>-%tky ]-%cid
                     ) to bookings_cba assIGNING fiELD-SYMBOL(<booking_cba>).

       ""Preapre all the bookings from existing request which needs to be copied
       loop at book_read_result assIGNING fiELD-SYMBOL(<booking>) where travelid =  <travel>-TravelId.

        ""Lets pass a unique booking cid - Concatenate the CID of travel with BookingId of existing travel
        append value #( %cid = keys[ key entity %tky = <travel>-%tky ]-%cid && <booking>-BookingId
                        %data = corRESPONDING #( book_read_result[ key entity %tky = <booking>-%tky ] except travelid ) )
                to <booking_cba>-%target assIGNING fiELD-SYMBOL(<new_booking>).

        <new_booking>-BookingStatus = 'N'.

        """---start of supplement
           ""Booking data prepration
           "We have to pass %cid_ref to tell system, that the bookings belongs to
           "which travel request - a record was inserted in itab for booking
           append value #( %cid_ref = keys[ key entity %tky = <travel>-%tky ]-%cid && <booking>-BookingId
                         ) to booksuppl_cba assIGNING fiELD-SYMBOL(<booksuppl_cba>).

           ""Preapre all the bookings from existing request which needs to be copied
           loop at booksuppl_read_result assIGNING fiELD-SYMBOL(<book_suppl>) using key entity where travelid =  <travel>-TravelId
                                                                                and bookingid =  <booking>-BookingId.

            ""Lets pass a unique booking cid - Concatenate the CID of travel with BookingId of existing travel
            append value #( %cid = keys[ key entity %tky = <travel>-%tky ]-%cid && <booking>-BookingId && <book_suppl>-BookingSupplementId
                            %data = corRESPONDING #( <book_suppl> except travelid bookingid ) )
                    to <booksuppl_cba>-%target.
           endloop.
        """---end of sumpplement


       enDLOOP.



    enDLOOP.

    ""Step 3: Insert data in DB using EML
    modify entities of zats_ab_travel in local mode
        entity travel
         create fields ( agencyid customerid begindate enddate bookingfee totalprice currencycode overallstatus )
           with travels
            create by \_Booking fields ( bookingid bookingdate customerid carrierid connectionid flightdate flightprice currencycode bookingstatus )
                with bookings_cba
                enTITY booking
                 create by \_BookingSuppl fields ( BookingSupplementId SupplementId Price CurrencyCode )
                    with booksuppl_cba
         mapped data(mapped_data).

    "mapped-travel = mapped_data-travel.
    mapped = mapped_data.






  ENDMETHOD.

  METHOD reCalcTotalPrice.

*    Define a structure where we can store all the Booking Fees and Currency Code
     types : begin of ty_total_cost,
                amount type /dmo/total_price,
                currency type /dmo/currency_code,
             end of ty_total_cost.

     data ls_header_curr type /dmo/currency_code.
     data amounts_per_currencycode type standard table of ty_total_cost.
*    Read all the travel instances, subsequent Bookings inside that using EML
*    Read all the Booking Supplements for each Booking using EML
    read entities of zats_ab_travel in local mode
    entity travel
        fields ( bookingfee currencycode ) with corrESPONDING #( keys )
        result data(travel)
        failed failed.

    read entities of zats_ab_travel in local mode
    entity travel by \_Booking
        fields ( flightprice currencycode ) with corrESPONDING #( travel )
        result data(booking)
        failed failed.

    read entities of zats_ab_travel in local mode
    entity booking by \_BookingSuppl
        fields ( price currencycode ) with corrESPONDING #( booking )
        result data(booksuppl)
        failed failed.

" Delete records where currencycode is empty, optionally throw error
     delete travel where currencycode is initial.
     delete booking where currencycode is initial.
     delete booksuppl where currencycode is initial.

*    Loop at header, item and item childs Total All the amounts in itab for Common currency
     loop at travel assigning field-symbol(<fs_travel>).

        amounts_per_currencycode = value #( ( amount = <fs_travel>-BookingFee
                                              currency = <fs_travel>-CurrencyCode ) ).
        ls_header_curr = <fs_travel>-CurrencyCode.

        loop at booking into data(wa_booking) where travelid = <fs_travel>-travelid.

            ""add all numeric column values by comparing non-numeric columns
            collect value ty_total_cost( amount = wa_booking-FlightPrice
                                         currency = wa_booking-CurrencyCode )
                                         into amounts_per_currencycode.

            loop at booksuppl into data(wa_suppl) where travelid = wa_booking-travelid and
                                                          bookingid = wa_booking-bookingid.
                collect value ty_total_cost( amount = wa_suppl-price
                                         currency = wa_suppl-CurrencyCode )
                                         into amounts_per_currencycode.

            endloop.

        endloop.
        clear <fs_travel>-TotalPrice.
     endloop.



*    Compare the currency of Booking and Supplement with header currency
     loop at amounts_per_currencycode into data(ls_amount_per_currency).
*           If it does not match, perform currency conversion
        if ls_amount_per_currency-currency = ls_header_curr.
            <fs_travel>-TotalPrice += ls_amount_per_currency-amount.
        else.
            /dmo/cl_flight_amdp=>convert_currency(
              EXPORTING
                iv_amount               = ls_amount_per_currency-amount
                iv_currency_code_source = ls_amount_per_currency-currency
                iv_currency_code_target = ls_header_curr
                iv_exchange_rate_date   = cl_abap_context_info=>get_system_date(  )
              IMPORTING
                ev_amount               =  data(total_amt)
            ).

            <fs_travel>-TotalPrice += total_amt.
        endif.

     endloop.

*    Total all the amount in a variable and set it to the Travel header level using EML
     modify entities of zats_ab_travel in local mode
     entity travel
     update fields ( totalprice )
     with corresponding #( travel ).
*    Return the mapped data as a result of internal action



  ENDMETHOD.

  METHOD calcTotalPrice.

    ""How to call an action using the EML
    modify entities of zats_ab_travel in local mode
        entity travel
            execute reCalcTotalPrice
            from CORRESPONDING #( keys ).

  ENDMETHOD.

  METHOD validateHeaderData.

    ""Step 1: Read the data of incoming request from EML
    read entities of zats_ab_travel
        entity travel
            fields ( agencyid customerid begindate enddate )
            with corresponding #( keys )
            result data(lt_travel).

    ""Step 2: Declare sorted table to hold customer ids and agency id
    data : lt_customers type sorted table of /dmo/customer with unique key customer_id,
           lt_agency    type sorted table of /dmo/agency   with unique key agency_id.

    ""Step 3: Extract the unique customer and agency ids from travel data
    lt_customers = correSPONDING #( lt_travel DISCARDING DUPLICATES mapping customer_id = customerid except * ).
    lt_agency = correSPONDING #( lt_travel DISCARDING DUPLICATES mapping agency_id = agencyid except * ).

    delete lt_customers where customer_id is initial.
    delete lt_agency where agency_id is initial.

    ""Step 4: Extract the Customer and Agency Data from Databased based on travel data
    if lt_customers is not initial.

        select from /dmo/customer fields customer_id
            for all entries in @lt_customers
                where customer_id = @lt_customers-customer_id
                into table @data(lt_cust_db).

    endif.
    if lt_agency is not initial.

        select from /dmo/agency fields agency_id
            for all entries in @lt_agency
                where agency_id = @lt_agency-agency_id
                into table @data(lt_agency_db).

    endif.

    ""Step 5: Loop at incoming data to validate customer and agency one by one
    loop at lt_travel into data(ls_travel).
        ""Check if customer id is blank
        ""OR
        ""If in the DB customer does not exist
        if ( ls_travel-customerid is initial OR NOT line_exists( lt_cust_db[ customer_id = ls_travel-customerid ] ) ).

            append value #( %tky = ls_travel-%tky ) to failed-travel.
            append value #( %tky = ls_travel-%tky
                            %element-customerid = if_abap_behv=>mk-on
                            %msg = new /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>customer_unkown
                                                                customer_id = ls_travel-CustomerId
                                                                severity = if_abap_behv_message=>severity-error
                            )
             ) to reported-travel.

        endif.

        ""Check if customer id is blank
        ""OR
        ""If in the DB customer does not exist
        if ( ls_travel-agencyid is initial OR NOT line_exists( lt_agency_db[ agency_id = ls_travel-agencyid ] ) ).

            append value #( %tky = ls_travel-%tky ) to failed-travel.
            append value #( %tky = ls_travel-%tky
                            %element-agencyid = if_abap_behv=>mk-on
                            %msg = new /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>agency_unkown
                                                                agency_id = ls_travel-agencyid
                                                                severity = if_abap_behv_message=>severity-error
                            )
             ) to reported-travel.

        endif.

        ""Homework : Add following validations
        "1. Check if the travel start date is >= todays
        "2. Travel End date must be > Begin Date
        "3. Travel begin and end date must not be Initial

    endloop.









  ENDMETHOD.

ENDCLASS.
