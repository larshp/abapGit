CLASS zcl_abapgit_html_viewer_gui DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_abapgit_html_viewer .

    METHODS constructor
      IMPORTING
        !io_container           TYPE REF TO cl_gui_container DEFAULT cl_gui_container=>screen0
        !iv_disable_query_table TYPE abap_bool DEFAULT abap_true .
  PROTECTED SECTION.

    DATA mo_html_viewer TYPE REF TO cl_gui_html_viewer .

    METHODS on_event
        FOR EVENT sapevent OF cl_gui_html_viewer
      IMPORTING
        !action
        !frame
        !getdata
        !postdata
        !query_table .

  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_ABAPGIT_HTML_VIEWER_GUI IMPLEMENTATION.


  METHOD constructor.

    DATA: lt_events TYPE cntl_simple_events,
          ls_event  LIKE LINE OF lt_events.

    CREATE OBJECT mo_html_viewer
      EXPORTING
        query_table_disabled = iv_disable_query_table
        parent               = io_container.

    ls_event-eventid    = zif_abapgit_html_viewer=>m_id_sapevent.
    ls_event-appl_event = abap_true.
    APPEND ls_event TO lt_events.

    mo_html_viewer->set_registered_events( lt_events ).
    SET HANDLER on_event FOR mo_html_viewer.

  ENDMETHOD.


  METHOD on_event.

    RAISE EVENT zif_abapgit_html_viewer~sapevent
      EXPORTING
        action      = action
        frame       = frame
        getdata     = getdata
        postdata    = postdata
        query_table = query_table.

  ENDMETHOD.


  METHOD zif_abapgit_html_viewer~back.

    mo_html_viewer->go_back( ).

  ENDMETHOD.


  METHOD zif_abapgit_html_viewer~close_document.

    mo_html_viewer->close_document( ).

  ENDMETHOD.


  METHOD zif_abapgit_html_viewer~free.

    mo_html_viewer->free( ).

  ENDMETHOD.


  METHOD zif_abapgit_html_viewer~get_url.

    DATA lv_url TYPE c LENGTH 250.
    mo_html_viewer->get_current_url( IMPORTING url = lv_url ).
    cl_gui_cfw=>flush( ).
    rv_url = lv_url.

  ENDMETHOD.


  METHOD zif_abapgit_html_viewer~get_viewer.
    ro_result = mo_html_viewer.
  ENDMETHOD.


  METHOD zif_abapgit_html_viewer~load_data.

    DATA lv_url TYPE c LENGTH 250.
    DATA lv_assigned TYPE c LENGTH 250.

    lv_url = iv_url.
    mo_html_viewer->load_data(
      EXPORTING
        url                    = lv_url
        type                   = iv_type
        subtype                = iv_subtype
        size                   = iv_size
      IMPORTING
        assigned_url           = lv_assigned
      CHANGING
        data_table             = ct_data_table
      EXCEPTIONS
        dp_invalid_parameter   = 1
        dp_error_general       = 2
        cntl_error             = 3
        html_syntax_notcorrect = 4 ).
    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'Error loading data for HTML viewer' ).
    ENDIF.
    ev_assigned_url = lv_assigned.

  ENDMETHOD.


  METHOD zif_abapgit_html_viewer~set_registered_events.

    mo_html_viewer->set_registered_events(
      EXPORTING
        events                    = it_events
      EXCEPTIONS
        cntl_error                = 1
        cntl_system_error         = 2
        illegal_event_combination = 3 ).
    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'Error registering events for HTML viewer' ).
    ENDIF.

  ENDMETHOD.


  METHOD zif_abapgit_html_viewer~set_visiblity.
    DATA: lv_visible TYPE c LENGTH 1.

    IF iv_visible = abap_true.
      lv_visible = cl_gui_container=>visible_true.
    ELSE.
      lv_visible = cl_gui_container=>visible_false.
    ENDIF.

    mo_html_viewer->set_visible( lv_visible ).
  ENDMETHOD.


  METHOD zif_abapgit_html_viewer~show_url.

    DATA lv_url TYPE c LENGTH 250.
    lv_url = iv_url.
    mo_html_viewer->show_url(
      EXPORTING
        url                    = lv_url
      EXCEPTIONS
        cntl_error             = 1
        cnht_error_not_allowed = 2
        cnht_error_parameter   = 3
        dp_error_general       = 4 ).
    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'Error showing URL in HTML viewer' ).
    ENDIF.

  ENDMETHOD.
ENDCLASS.
