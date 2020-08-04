CLASS zcl_abapgit_user_master_record DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.
    CONSTANTS gc_cc_category TYPE string VALUE 'C' ##NO_TEXT.
    CLASS-METHODS get_instance
      IMPORTING
        !iv_user       TYPE uname
      RETURNING
        VALUE(ro_user) TYPE REF TO zcl_abapgit_user_master_record .
    METHODS constructor
      IMPORTING
        !iv_user TYPE uname .
    METHODS get_name
      RETURNING
        VALUE(rv_name) TYPE zif_abapgit_definitions=>ty_git_user-name .
    METHODS get_email
      RETURNING
        VALUE(rv_email) TYPE zif_abapgit_definitions=>ty_git_user-email .
  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_user,
        user   TYPE uname,
        o_user TYPE REF TO zcl_abapgit_user_master_record,
      END OF ty_user.

    CLASS-DATA:
      gt_user TYPE HASHED TABLE OF ty_user
                   WITH UNIQUE KEY user.

    DATA:
      ms_user TYPE zif_abapgit_definitions=>ty_git_user.

    TYPES:
      ty_lt_return TYPE STANDARD TABLE OF bapiret2 WITH DEFAULT KEY,
      ty_lt_smtp   TYPE STANDARD TABLE OF bapiadsmtp WITH DEFAULT KEY.
    METHODS check_user_exists
      IMPORTING VALUE(iv_user)    TYPE uname
      EXPORTING VALUE(es_address) TYPE bapiaddr3
                VALUE(et_smtp)    TYPE ty_lt_smtp
      RAISING   zcx_abapgit_exception.
    TYPES:
      ty_lt_dev_clients TYPE SORTED TABLE OF sy-mandt WITH UNIQUE KEY table_line.

    METHODS get_user_dtls_from_other
      IMPORTING
        iv_user TYPE uname.

    METHODS insert_user IMPORTING is_user        TYPE ty_user
                        RETURNING VALUE(rs_user) TYPE ty_user
                        .
ENDCLASS.



CLASS zcl_abapgit_user_master_record IMPLEMENTATION.


  METHOD constructor.

    DATA: ls_address     TYPE bapiaddr3,
          lt_smtp        TYPE TABLE OF bapiadsmtp,
          ls_smtp        TYPE bapiadsmtp,
          lt_dev_clients TYPE SORTED TABLE OF sy-mandt WITH UNIQUE KEY table_line,
          ls_user        TYPE ty_user,
          lo_exception TYPE REF TO zcx_abapgit_exception.

    "Get user details
    TRY.
        check_user_exists(
              EXPORTING
                iv_user = iv_user
              IMPORTING
                es_address   = ls_address
                et_smtp      = lt_smtp
                ).

        " Choose the first email from SU01
        SORT lt_smtp BY consnumber ASCENDING.

        LOOP AT lt_smtp INTO ls_smtp.
          ms_user-email = ls_smtp-e_mail.
          EXIT.
        ENDLOOP.

        " Attempt to use the full name from SU01
        ms_user-name = ls_address-fullname.

        ls_user-user = iv_user.
        ls_user-o_user = me.
        "insert the user
        insert_user( is_user = ls_user ).

      CATCH zcx_abapgit_exception INTO lo_exception.
        "handle exception
        "Could not find user,try to get from other clients
        get_user_dtls_from_other( iv_user ).
    ENDTRY.

  ENDMETHOD.


  METHOD get_email.

    rv_email = ms_user-email.

  ENDMETHOD.


  METHOD get_instance.

    DATA: ls_user TYPE ty_user.
    FIELD-SYMBOLS: <ls_user> TYPE ty_user.

    READ TABLE gt_user ASSIGNING <ls_user>
                       WITH TABLE KEY user = iv_user.
    IF sy-subrc = 0.
      ro_user = <ls_user>-o_user.
      RETURN.
    ENDIF.

    CREATE OBJECT ro_user
      EXPORTING
        iv_user = iv_user.

ENDMETHOD.


METHOD get_name.

  rv_name = ms_user-name.

ENDMETHOD.


METHOD insert_user.
  FIELD-SYMBOLS: <ls_user> TYPE ty_user.

  INSERT  is_user
          INTO TABLE gt_user
          ASSIGNING <ls_user>.
  IF <ls_user> IS ASSIGNED.
    rs_user = <ls_user>.
  ENDIF.
ENDMETHOD.

METHOD check_user_exists.
  DATA lt_return TYPE ty_lt_return.


  CALL FUNCTION 'BAPI_USER_GET_DETAIL'
    EXPORTING
      username = iv_user
    IMPORTING
      address  = es_address
    TABLES
      return   = lt_return
      addsmtp  = et_smtp.

  LOOP AT lt_return TRANSPORTING NO FIELDS WHERE type CA 'EA'.
    zcx_abapgit_exception=>raise( |User: { iv_user } is invalid!| ).
  ENDLOOP.

ENDMETHOD.


METHOD get_user_dtls_from_other.

  DATA lt_dev_clients TYPE ty_lt_dev_clients.


  FIELD-SYMBOLS: <lv_dev_client> LIKE LINE OF lt_dev_clients.

  " Could not find the user Try other development clients
  SELECT mandt INTO TABLE lt_dev_clients
    FROM t000
    WHERE cccategory  = gc_cc_category
      AND mandt      <> sy-mandt
    ORDER BY PRIMARY KEY.

    LOOP AT lt_dev_clients ASSIGNING <lv_dev_client>.
      SELECT SINGLE p~name_text a~smtp_addr INTO (ms_user-name,ms_user-email)
        FROM usr21 AS u
        INNER JOIN adrp AS p ON p~persnumber = u~persnumber
                            AND p~client     = u~mandt
        INNER JOIN adr6 AS a ON a~persnumber = u~persnumber
                            AND a~addrnumber = u~addrnumber
                            AND a~client     = u~mandt
        CLIENT SPECIFIED
        WHERE u~mandt      = <lv_dev_client>
          AND u~bname      = iv_user
          AND p~date_from <= sy-datum
          AND p~date_to   >= sy-datum
          AND a~date_from <= sy-datum.

        IF sy-subrc = 0.
          EXIT.
        ENDIF.
      ENDLOOP.

    ENDMETHOD.

ENDCLASS.
