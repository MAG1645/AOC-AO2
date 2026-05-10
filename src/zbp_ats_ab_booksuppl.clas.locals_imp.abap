CLASS lhc_BookSuppl DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calcTotalPriceSuppl FOR DETERMINE ON MODIFY
      IMPORTING keys FOR BookSuppl~calcTotalPriceSuppl.

ENDCLASS.

CLASS lhc_BookSuppl IMPLEMENTATION.

  METHOD calcTotalPriceSuppl.

    modify entities of zats_ab_travel in local mode
        entity travel
            execute reCalcTotalPrice
            from CORRESPONDING #( keys ).


  ENDMETHOD.

ENDCLASS.
