CLASS zcl_abapgit_gui DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_abapgit_gui_services .

    CONSTANTS:
      BEGIN OF c_event_state,
        not_handled         TYPE i VALUE 0,
        re_render           TYPE i VALUE 1,
        new_page            TYPE i VALUE 2,
        go_back             TYPE i VALUE 3,
        no_more_act         TYPE i VALUE 4,
        new_page_w_bookmark TYPE i VALUE 5,
        go_back_to_bookmark TYPE i VALUE 6,
        new_page_replacing  TYPE i VALUE 7,
      END OF c_event_state .
    CONSTANTS:
      BEGIN OF c_action,
        go_home TYPE string VALUE 'go_home',
        go_db   TYPE string VALUE 'go_db',
      END OF c_action .

    METHODS go_home
      RAISING
        zcx_abapgit_exception .
    METHODS back
      IMPORTING
        !iv_to_bookmark TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(rv_exit)  TYPE abap_bool
      RAISING
        zcx_abapgit_exception .
    METHODS on_event
        FOR EVENT sapevent OF zif_abapgit_html_viewer
      IMPORTING
        !action
        !frame
        !getdata
        !postdata
        !query_table .
    METHODS constructor
      IMPORTING
        !io_component         TYPE REF TO object OPTIONAL
        !ii_asset_man         TYPE REF TO zif_abapgit_gui_asset_manager OPTIONAL
        !ii_hotkey_ctl        TYPE REF TO zif_abapgit_gui_hotkey_ctl OPTIONAL
        !ii_html_processor    TYPE REF TO zif_abapgit_gui_html_processor OPTIONAL
        !iv_rollback_on_error TYPE abap_bool DEFAULT abap_true
      RAISING
        zcx_abapgit_exception .
    METHODS free .
    METHODS set_focus
      RAISING
        zcx_abapgit_exception .
  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_page_stack,
        page     TYPE REF TO zif_abapgit_gui_renderable,
        bookmark TYPE abap_bool,
      END OF ty_page_stack .

    DATA mv_rollback_on_error TYPE abap_bool .
    DATA mi_cur_page TYPE REF TO zif_abapgit_gui_renderable .
    DATA:
      mt_stack             TYPE STANDARD TABLE OF ty_page_stack .
    DATA:
      mt_event_handlers    TYPE STANDARD TABLE OF REF TO zif_abapgit_gui_event_handler .
    DATA mi_router TYPE REF TO zif_abapgit_gui_event_handler .
    DATA mi_asset_man TYPE REF TO zif_abapgit_gui_asset_manager .
    DATA mi_hotkey_ctl TYPE REF TO zif_abapgit_gui_hotkey_ctl .
    DATA mi_html_processor TYPE REF TO zif_abapgit_gui_html_processor .
    DATA mi_html_viewer TYPE REF TO zif_abapgit_html_viewer .
    DATA mo_html_parts TYPE REF TO zcl_abapgit_html_parts .
    DATA mi_common_log TYPE REF TO zif_abapgit_log .

    METHODS cache_html
      IMPORTING
        !iv_text      TYPE string
      RETURNING
        VALUE(rv_url) TYPE string
      RAISING
        zcx_abapgit_exception .
    METHODS startup
      RAISING
        zcx_abapgit_exception .
    METHODS render
      RAISING
        zcx_abapgit_exception .
    METHODS call_page
      IMPORTING
        !ii_page          TYPE REF TO zif_abapgit_gui_renderable
        !iv_with_bookmark TYPE abap_bool DEFAULT abap_false
        !iv_replacing     TYPE abap_bool DEFAULT abap_false
      RAISING
        zcx_abapgit_exception .
    METHODS handle_action
      IMPORTING
        !iv_action   TYPE c
        !iv_getdata  TYPE c OPTIONAL
        !it_postdata TYPE zif_abapgit_html_viewer=>ty_post_data OPTIONAL .
    METHODS handle_error
      IMPORTING
        !ix_exception TYPE REF TO zcx_abapgit_exception .
ENDCLASS.



CLASS zcl_abapgit_gui IMPLEMENTATION.


  METHOD back.

    DATA: lv_index TYPE i,
          ls_stack LIKE LINE OF mt_stack.

    " If viewer is showing Internet page, then use browser navigation
    IF mi_html_viewer->get_url( ) CP 'http*'.
      mi_html_viewer->back( ).
      RETURN.
    ENDIF.

    lv_index = lines( mt_stack ).

    IF lv_index = 0.
      rv_exit = abap_true.
      RETURN.
    ENDIF.

    DO lv_index TIMES.
      READ TABLE mt_stack INDEX lv_index INTO ls_stack.
      ASSERT sy-subrc = 0.

      DELETE mt_stack INDEX lv_index.
      ASSERT sy-subrc = 0.

      lv_index = lv_index - 1.

      IF iv_to_bookmark = abap_false OR ls_stack-bookmark = abap_true.
        EXIT.
      ENDIF.
    ENDDO.

    mi_cur_page = ls_stack-page. " last page always stays
    render( ).

  ENDMETHOD.


  METHOD cache_html.

    rv_url = zif_abapgit_gui_services~cache_asset(
      iv_text    = iv_text
      iv_type    = 'text'
      iv_subtype = 'html' ).

  ENDMETHOD.


  METHOD call_page.

    DATA: ls_stack TYPE ty_page_stack.

    IF iv_replacing = abap_false AND NOT mi_cur_page IS INITIAL.
      ls_stack-page     = mi_cur_page.
      ls_stack-bookmark = iv_with_bookmark.
      APPEND ls_stack TO mt_stack.
    ENDIF.

    mi_cur_page = ii_page.
    render( ).

  ENDMETHOD.


  METHOD constructor.

    IF io_component IS BOUND.
      IF zcl_abapgit_gui_utils=>is_renderable( io_component ) = abap_true.
        mi_cur_page ?= io_component. " direct page
      ELSE.
        IF zcl_abapgit_gui_utils=>is_event_handler( io_component ) = abap_false.
          zcx_abapgit_exception=>raise( 'Component must be renderable or be an event handler' ).
        ENDIF.
        mi_router ?= io_component.
      ENDIF.
    ENDIF.

    CREATE OBJECT mo_html_parts.

    mv_rollback_on_error = iv_rollback_on_error.
    mi_asset_man      = ii_asset_man.
    mi_hotkey_ctl     = ii_hotkey_ctl.
    mi_html_processor = ii_html_processor. " Maybe improve to middlewares stack ??
    startup( ).

  ENDMETHOD.


  METHOD free.

    SET HANDLER on_event FOR mi_html_viewer ACTIVATION space.
    mi_html_viewer->close_document( ).
    mi_html_viewer->free( ).
    FREE mi_html_viewer.

  ENDMETHOD.


  METHOD go_home.

    DATA: ls_stack LIKE LINE OF mt_stack,
          lv_mode  TYPE tabname.

    IF mi_router IS BOUND.
      CLEAR: mt_stack, mt_event_handlers.
      APPEND mi_router TO mt_event_handlers.
      " on_event doesn't accept strings directly
      GET PARAMETER ID 'DBT' FIELD lv_mode.
      CASE lv_mode.
        WHEN 'ZABAPGIT'.
          on_event( action = |{ c_action-go_db }| ).
        WHEN OTHERS.
          on_event( action = |{ c_action-go_home }| ).
      ENDCASE.
    ELSE.
      IF lines( mt_stack ) > 0.
        READ TABLE mt_stack INTO ls_stack INDEX 1.
        mi_cur_page = ls_stack-page.
      ENDIF.
      render( ).
    ENDIF.

  ENDMETHOD.


  METHOD handle_action.

    DATA:
      lx_exception TYPE REF TO zcx_abapgit_exception,
      li_handler   TYPE REF TO zif_abapgit_gui_event_handler,
      li_event     TYPE REF TO zif_abapgit_gui_event,
      ls_handled   TYPE zif_abapgit_gui_event_handler=>ty_handling_result.

    CREATE OBJECT li_event TYPE zcl_abapgit_gui_event
      EXPORTING
        ii_gui_services = me
        iv_action       = iv_action
        iv_getdata      = iv_getdata
        it_postdata     = it_postdata.

    TRY.
        LOOP AT mt_event_handlers INTO li_handler.
          ls_handled = li_handler->on_event( li_event ).
          IF ls_handled-state IS NOT INITIAL AND ls_handled-state <> c_event_state-not_handled. " is handled
            EXIT.
          ENDIF.
        ENDLOOP.

        CASE ls_handled-state.
          WHEN c_event_state-re_render.
            render( ).
          WHEN c_event_state-new_page.
            call_page( ls_handled-page ).
          WHEN c_event_state-new_page_w_bookmark.
            call_page(
              ii_page = ls_handled-page
              iv_with_bookmark = abap_true ).
          WHEN c_event_state-new_page_replacing.
            call_page(
              ii_page = ls_handled-page
              iv_replacing = abap_true ).
          WHEN c_event_state-go_back.
            back( ).
          WHEN c_event_state-go_back_to_bookmark.
            back( abap_true ).
          WHEN c_event_state-no_more_act.
            " Do nothing, handling completed
          WHEN OTHERS.
            zcx_abapgit_exception=>raise( |Unknown action: { iv_action }| ).
        ENDCASE.

      CATCH zcx_abapgit_cancel ##NO_HANDLER.
        " Do nothing = gc_event_state-no_more_act
      CATCH zcx_abapgit_exception INTO lx_exception.
        handle_error( lx_exception ).
    ENDTRY.

  ENDMETHOD.


  METHOD handle_error.

    DATA: li_gui_error_handler TYPE REF TO zif_abapgit_gui_error_handler,
          lx_exception         TYPE REF TO cx_root.

    IF mv_rollback_on_error = abap_true.
      ROLLBACK WORK.
    ENDIF.

    TRY.
        li_gui_error_handler ?= mi_cur_page.

        IF li_gui_error_handler IS BOUND AND li_gui_error_handler->handle_error( ix_exception ) = abap_true.
          " We rerender the current page to display the error box
          render( ).
        ELSEIF ix_exception->mi_log IS BOUND.
          mi_common_log = ix_exception->mi_log.
          IF mi_common_log->get_log_level( ) >= zif_abapgit_log=>c_log_level-warning.
            zcl_abapgit_log_viewer=>show_log( mi_common_log ).
          ENDIF.
        ELSE.
          MESSAGE ix_exception TYPE 'S' DISPLAY LIKE 'E'.
        ENDIF.

      CATCH zcx_abapgit_exception cx_sy_move_cast_error INTO lx_exception.
        " In case of fire we just fallback to plain old message
        MESSAGE lx_exception TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.

  ENDMETHOD.


  METHOD on_event.

    handle_action(
      iv_action   = action
      iv_getdata  = getdata
      it_postdata = postdata ).

  ENDMETHOD.


  METHOD render.

    DATA: lv_url  TYPE string,
          lv_html TYPE string,
          li_html TYPE REF TO zif_abapgit_html.

    IF mi_cur_page IS NOT BOUND.
      zcx_abapgit_exception=>raise( 'GUI error: no current page' ).
    ENDIF.

    CLEAR mt_event_handlers.
    mo_html_parts->clear( ).

    IF mi_router IS BOUND.
      APPEND mi_router TO mt_event_handlers.
    ENDIF.

    IF mi_hotkey_ctl IS BOUND.
      mi_hotkey_ctl->reset( ).
    ENDIF.

    li_html = mi_cur_page->render( ).
    lv_html = li_html->render( iv_no_indent_jscss = abap_true ).

    IF mi_html_processor IS BOUND.
      lv_html = mi_html_processor->process(
        iv_html         = lv_html
        ii_gui_services = me ).
    ENDIF.

    lv_url = cache_html( lv_html ).
    mi_html_viewer->show_url( lv_url ).

  ENDMETHOD.


  METHOD set_focus.
    cl_gui_control=>set_focus(
      EXPORTING
        control           = mi_html_viewer->get_viewer( )
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 3 ).
    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( |Error in: cl_gui_control=>set_focus - SUBRC = { sy-subrc }| ).
    ENDIF.
  ENDMETHOD.


  METHOD startup.

    DATA: lt_events TYPE cntl_simple_events,
          ls_event  LIKE LINE OF lt_events,
          lt_assets TYPE zif_abapgit_gui_asset_manager=>ty_web_assets.

    FIELD-SYMBOLS <ls_asset> LIKE LINE OF lt_assets.


    mi_html_viewer = zcl_abapgit_ui_factory=>get_html_viewer( ).

    IF mi_asset_man IS BOUND.
      lt_assets = mi_asset_man->get_all_assets( ).
      LOOP AT lt_assets ASSIGNING <ls_asset> WHERE is_cacheable = abap_true.
        zif_abapgit_gui_services~cache_asset(
          iv_xdata   = <ls_asset>-content
          iv_url     = <ls_asset>-url
          iv_type    = <ls_asset>-type
          iv_subtype = <ls_asset>-subtype ).
      ENDLOOP.
    ENDIF.

    ls_event-eventid    = mi_html_viewer->m_id_sapevent.
    ls_event-appl_event = abap_true.
    APPEND ls_event TO lt_events.

    mi_html_viewer->set_registered_events( lt_events ).
    SET HANDLER on_event FOR mi_html_viewer.

  ENDMETHOD.


  METHOD zif_abapgit_gui_services~cache_asset.

    TYPES: ty_hex TYPE x LENGTH 200.

    DATA: lt_xdata TYPE STANDARD TABLE OF ty_hex WITH DEFAULT KEY,
          lv_size  TYPE i,
          lt_html  TYPE w3htmltab.

    ASSERT iv_text IS SUPPLIED OR iv_xdata IS SUPPLIED.

    IF iv_text IS SUPPLIED. " String input
      zcl_abapgit_convert=>string_to_tab(
         EXPORTING
           iv_str  = iv_text
         IMPORTING
           ev_size = lv_size
           et_tab  = lt_html ).

      mi_html_viewer->load_data(
        EXPORTING
          iv_type         = iv_type
          iv_subtype      = iv_subtype
          iv_size         = lv_size
          iv_url          = iv_url
        IMPORTING
          ev_assigned_url = rv_url
        CHANGING
          ct_data_table   = lt_html ).
    ELSE. " Raw input
      zcl_abapgit_convert=>xstring_to_bintab(
        EXPORTING
          iv_xstr   = iv_xdata
        IMPORTING
          ev_size   = lv_size
          et_bintab = lt_xdata ).

      mi_html_viewer->load_data(
        EXPORTING
          iv_type         = iv_type
          iv_subtype      = iv_subtype
          iv_size         = lv_size
          iv_url          = iv_url
        IMPORTING
          ev_assigned_url = rv_url
        CHANGING
          ct_data_table   = lt_xdata ).
    ENDIF.

    ASSERT sy-subrc = 0. " Image data error

  ENDMETHOD.


  METHOD zif_abapgit_gui_services~get_current_page_name.

    DATA li_page_hoc TYPE REF TO zcl_abapgit_gui_page_hoc.

    IF mi_cur_page IS BOUND.
      rv_page_name = cl_abap_classdescr=>describe_by_object_ref( mi_cur_page )->get_relative_name( ).

      " For HOC components return name of child component instead
      IF rv_page_name = 'ZCL_ABAPGIT_GUI_PAGE_HOC'.
        li_page_hoc ?= mi_cur_page.
        IF li_page_hoc->get_child( ) IS BOUND.
          rv_page_name = cl_abap_classdescr=>describe_by_object_ref(
                           li_page_hoc->get_child( ) )->get_relative_name( ).
        ENDIF.
      ENDIF.
    ENDIF." ELSE - return is empty => initial page

  ENDMETHOD.


  METHOD zif_abapgit_gui_services~get_hotkeys_ctl.
    ri_hotkey_ctl = mi_hotkey_ctl.
  ENDMETHOD.


  METHOD zif_abapgit_gui_services~get_html_parts.
    ro_parts = mo_html_parts.
  ENDMETHOD.


  METHOD zif_abapgit_gui_services~get_log.

    IF iv_create_new = abap_true OR mi_common_log IS NOT BOUND.
      CREATE OBJECT mi_common_log TYPE zcl_abapgit_log.
    ENDIF.

    ri_log = mi_common_log.

  ENDMETHOD.


  METHOD zif_abapgit_gui_services~register_event_handler.
    ASSERT ii_event_handler IS BOUND.
    INSERT ii_event_handler INTO mt_event_handlers INDEX 1.
  ENDMETHOD.
ENDCLASS.
