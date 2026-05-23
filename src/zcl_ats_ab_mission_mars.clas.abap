CLASS zcl_ats_ab_mission_mars DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    data: itab type table of string.
    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_ATS_AB_MISSION_MARS IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    data(lv_str) = lcl_earth=>start_engine(  ).
    appeND lv_str to itab.
    lv_str = lcl_earth=>leave_orbit(  ).
    appeND lv_str to itab.

    lv_str = lcl_ip=>enter_orbit(  ).
    appeND lv_str to itab.
    lv_str = lcl_ip=>leave_orbit(  ).
    appeND lv_str to itab.

    lv_str = lcl_mars=>enter_orbit(  ).
    appeND lv_str to itab.
    lv_str = lcl_mars=>start_exploration(  ).
    appeND lv_str to itab.

    out->write(
      EXPORTING
        data   = itab
*        name   =
*      RECEIVING
*        output =
    ).
  ENDMETHOD.
ENDCLASS.
