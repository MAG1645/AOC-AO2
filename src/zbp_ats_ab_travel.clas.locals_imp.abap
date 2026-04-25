CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.
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

ENDCLASS.
