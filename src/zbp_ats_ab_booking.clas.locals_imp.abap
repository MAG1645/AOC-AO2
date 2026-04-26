CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS earlynumbering_cba_Bookingsupp FOR NUMBERING
      IMPORTING entities FOR CREATE Booking\_Bookingsuppl.

ENDCLASS.

CLASS lhc_Booking IMPLEMENTATION.

  METHOD earlynumbering_cba_Bookingsupp.

    data max_book_suppl_id type /dmo/booking_supplement_id.

    ""Step 1: Get All the travel request and their booking Supplements
    read entities of zats_ab_travel in local mode
        entity booking by \_BookingSuppl
        from CORRESPONDING #( entities )
        link data(lt_booking_suppl).

    ""Step 2: Cases to handle for Assigning unique Booking Supplement ID
    "1001, 1002, 1005
    loop at entities assIGNING fiELD-SYMBOL(<booking_group>) group by <booking_group>-%tky-BookingId.

        ""Step 3: Loop at the specific booking supplements of every unique booking id
        ""If there is already the data inside, assign the Booking id to our variable which is max
        "Pass 1 - 10,20
        "Pass 2 - 10
        "Pass 3 - 40,50
        ""Get the highest assigned (already) supplement id number
        loop at lt_booking_suppl into data(ls_book_suppl) using key entity
                                        where source-Travelid = <booking_group>-TravelId and
                                              source-BookingId = <booking_group>-BookingId.
           ""Determine the Already created Booking Id which is maximum
           if max_book_suppl_id < ls_book_suppl-target-BookingId.
                    max_book_suppl_id = ls_book_suppl-target-BookingId.
           endif.
        enDLOOP.

        ""Get the assigned supplement id for incoming request
        loop at entities into data(ls_entity) using key entity where travelid = <booking_group>-TravelId and
                                                                    BookingId = <booking_group>-BookingId.
             loop at ls_entity-%target into data(ls_target).
                if max_book_suppl_id < ls_target-BookingSupplementId.
                    max_book_suppl_id = ls_target-BookingSupplementId.
                endif.
             endloop.
        endloop.


        loop at entities assIGNING fiELD-SYMBOL(<booking>) using key entity
                                             where travelid = <booking_group>-TravelId and
                                                   bookingid = <booking_group>-BookingId.

        ""Step 5: Increment the Booking id +10 and assign the new id
        loop at <booking>-%target assigning field-symbol(<booksuppl_wo_number>).
           append corresponding #( <booksuppl_wo_number> ) to mapped-booksuppl
                                assigning field-symbol(<mapped_book_suppl>).
           ""Determine the Already created Booking Id which is maximum
           ""Assining the +10 as new booking id
           if <mapped_book_suppl>-BookingSupplementId is initial.
              max_book_suppl_id += 1.
              <mapped_book_suppl>-BookingSupplementId = max_book_suppl_id.
           endif.
        enDLOOP.
    enDLOOP.
    enDLOOP.

    ""Step 4: Loop over all the entities of travel with same travel id and increment the max booking id



  ENDMETHOD.

ENDCLASS.
