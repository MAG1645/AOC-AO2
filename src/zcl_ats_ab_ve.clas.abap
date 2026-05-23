CLASS zcl_ats_ab_ve DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_sadl_exit .
    INTERFACES if_sadl_exit_calc_element_read .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_ATS_AB_VE IMPLEMENTATION.


  METHOD if_sadl_exit_calc_element_read~calculate.

    check not it_original_data is initial.

    data : lt_calc_data type standard table of zats_ab_travel_processor with deFAULT KEY,
           lv_rate      type p decIMALS 2 value '0.025'.


    lt_calc_data = corRESPONDING #( it_original_data ).

    loop at lt_calc_data asSIGNING fiELD-SYMBOL(<fs_calc_data>).

        <fs_calc_data>-CO2Tax = <fs_calc_data>-TotalPrice * lv_rate.
        ""here you can write code to get day of travel
        <fs_calc_data>-dayOfFlight = 'Sunday'.

    endloop.

    ct_calculated_data = corresponding #( lt_calc_data ).

  ENDMETHOD.


  METHOD if_sadl_exit_calc_element_read~get_calculation_info.

  ENDMETHOD.
ENDCLASS.
