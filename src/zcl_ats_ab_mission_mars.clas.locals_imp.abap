*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
*Class pools
class lcl_earth definition.
    pubLIC SECTION.
        class-METHODS start_engine reTURNING VALUE(r_result) type string.
        class-METHODS leave_orbit reTURNING VALUE(r_result) type string.
endclass.

CLASS lcl_earth IMPLEMENTATION.

  METHOD leave_orbit.
    r_result = 'Meede, We are out in space'.
  ENDMETHOD.

  METHOD start_engine.
    r_result = 'We start the countdown!'.
  ENDMETHOD.

ENDCLASS.

class lcl_ip definition.
    pubLIC SECTION.
        class-METHODS enter_orbit reTURNING VALUE(r_result) type string.
        class-METHODS leave_orbit reTURNING VALUE(r_result) type string.
endclass.

CLASS lcl_ip IMPLEMENTATION.

  METHOD leave_orbit.
    r_result = 'Leave orbit and continue mission'.
  ENDMETHOD.

  METHOD enter_orbit.
    r_result = 'We enter orbit, start charging'.
  ENDMETHOD.

ENDCLASS.


class lcl_mars definition.
    pubLIC SECTION.
        class-METHODS start_exploration reTURNING VALUE(r_result) type string.
        class-METHODS enter_orbit reTURNING VALUE(r_result) type string.
endclass.

CLASS lcl_mars IMPLEMENTATION.

  METHOD enter_orbit.
    r_result = 'Orbit Insertion to mars success'.
  ENDMETHOD.

  METHOD start_exploration.
    r_result = 'Roger! we found water on Mars'.
  ENDMETHOD.

ENDCLASS.
