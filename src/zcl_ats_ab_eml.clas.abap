CLASS zcl_ats_ab_eml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
    data : lv_ops type c vaLUE 'R'.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_ats_ab_eml IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    case lv_ops.
        when 'R'.

            "EML to Read data
            READ ENTITIES OF ZATS_AB_TRAVEL
                ENTITY Travel
                "BY \_Booking ALL FIELDS
                FIELDS ( travelid agencyid customerid begindate totalprice currencycode ) WITH
                VALUE #(
                            ( travelid = '00000010' )
                            ( travelid = '00000024' )
                            ( travelid = '505585' )
                       )
                RESULT data(lt_result)
                FAILED data(lt_failed)
                REPORTED data(lt_reported)
                .

            out->write(
              EXPORTING
                data   = lt_result
            ).

            out->write(
              EXPORTING
                data   = lt_failed
            ).

            out->write(
              EXPORTING
                data   = lt_reported
            ).

        when 'C'.

            "prepare test data for create
            data(lv_descr) = 'Anubhav Rocks with ABAP'.
            data(lv_agency) = '070016'.
            data(lv_cust) = '000697'.


            MODIFY ENTITIES OF ZATS_AB_TRAVEL
                ENTITY Travel
                CREATE FIELDS ( travelid agencyid customerid begindate enddate totalprice currencycode bookingfee description overallstatus )
                WITH VALUE #(
                                (
                                    %cid = 'ANUBHAV'
                                    travelid = '00012347'
                                    agencyid = lv_agency
                                    CustomerId = lv_cust
                                    BeginDate = cl_abap_context_info=>get_system_date(  )
                                    endDate = cl_abap_context_info=>get_system_date(  ) + 30
                                    Description = lv_descr
                                    OverallStatus = 'O'
                                )
                                (
                                    %cid = 'ANUBHAV-1'
                                    travelid = '00012355'
                                    agencyid = lv_agency
                                    CustomerId = lv_cust
                                    BeginDate = cl_abap_context_info=>get_system_date(  )
                                    endDate = cl_abap_context_info=>get_system_date(  ) + 30
                                    Description = lv_descr
                                    OverallStatus = 'O'
                                )
                                (
                                    %cid = 'ANUBHAV-2'
                                    travelid = '00012347'
                                    agencyid = lv_agency
                                    CustomerId = lv_cust
                                    BeginDate = cl_abap_context_info=>get_system_date(  )
                                    endDate = cl_abap_context_info=>get_system_date(  ) + 30
                                    Description = lv_descr
                                    OverallStatus = 'O'
                                )

                             )
                FAILED lt_failed
                REPORTED lt_reported
                MAPPED data(lt_mapped).

            COMMIT ENTITIES.

            out->write(
              EXPORTING
                data   = lt_mapped
*                name   =
*              RECEIVING
*                output =
            ).

            out->write(
              EXPORTING
                data   = lt_failed
*                name   =
*              RECEIVING
*                output =
            ).


        when 'U'.

            "prepare test data for create
            lv_descr = 'Hola amigo! changed'.
            lv_agency = '070022'.

            MODIFY ENTITIES OF ZATS_AB_TRAVEL
                ENTITY Travel
                UPDATE FIELDS (  agencyid description )
                WITH VALUE #(
                                (
                                    travelid = '00012347'
                                    agencyid = lv_agency
                                    Description = lv_descr
                                )
                                (
                                    travelid = '00012355'
                                    agencyid = lv_agency
                                    Description = lv_descr
                                )
                                (
                                    travelid = '0505858'
                                    agencyid = lv_agency
                                    Description = lv_descr
                                )

                             )
                FAILED lt_failed
                REPORTED lt_reported
                MAPPED lt_mapped.

            COMMIT ENTITIES.

            out->write(
              EXPORTING
                data   = lt_mapped
*                name   =
*              RECEIVING
*                output =
            ).

            out->write(
              EXPORTING
                data   = lt_failed
*                name   =
*              RECEIVING
*                output =
            ).

        when 'D'.

        MODIFY ENTITIES OF ZATS_AB_TRAVEL
                ENTITY Travel
                DELETE FROM
                VALUE #(
                                (
                                    travelid = '00012347'
                                )
                                (
                                    travelid = '00012355'
                                )
                                (
                                    travelid = '0505858'
                                )

                             )
                FAILED lt_failed
                REPORTED lt_reported
                MAPPED lt_mapped.

            COMMIT ENTITIES.

            out->write(
              EXPORTING
                data   = lt_mapped
*                name   =
*              RECEIVING
*                output =
            ).

            out->write(
              EXPORTING
                data   = lt_failed
*                name   =
*              RECEIVING
*                output =
            ).

    ENDCASE.











  ENDMETHOD.
ENDCLASS.
