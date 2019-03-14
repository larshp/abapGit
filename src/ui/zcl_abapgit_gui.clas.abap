CLASS zcl_abapgit_gui DEFINITION
  PUBLIC
  FINAL .

  PUBLIC SECTION.
    CONSTANTS:
      BEGIN OF c_event_state,
        not_handled         VALUE 0,
        re_render           VALUE 1,
        new_page            VALUE 2,
        go_back             VALUE 3,
        no_more_act         VALUE 4,
        new_page_w_bookmark VALUE 5,
        go_back_to_bookmark VALUE 6,
        new_page_replacing  VALUE 7,
      END OF c_event_state .

    CONSTANTS:
      BEGIN OF c_action,
        go_home TYPE string VALUE 'go_home',
      END OF c_action.

    METHODS go_home
      RAISING zcx_abapgit_exception.

    METHODS back
      IMPORTING iv_to_bookmark TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(rv_exit) TYPE abap_bool
      RAISING   zcx_abapgit_exception.

    METHODS on_event FOR EVENT sapevent OF cl_gui_html_viewer
      IMPORTING action frame getdata postdata query_table.

    METHODS constructor
      IMPORTING
        ii_router    TYPE REF TO zif_abapgit_gui_router
        ii_asset_man TYPE REF TO zif_abapgit_gui_asset_manager
      RAISING
        zcx_abapgit_exception.

    METHODS free.

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES: BEGIN OF ty_page_stack,
             page     TYPE REF TO zif_abapgit_gui_page,
             bookmark TYPE abap_bool,
           END OF ty_page_stack.

    DATA: mi_cur_page    TYPE REF TO zif_abapgit_gui_page,
          mt_stack       TYPE STANDARD TABLE OF ty_page_stack,
          mi_router      TYPE REF TO zif_abapgit_gui_router,
          mi_asset_man   TYPE REF TO zif_abapgit_gui_asset_manager,
          mo_html_viewer TYPE REF TO cl_gui_html_viewer.

    METHODS startup
      RAISING zcx_abapgit_exception.

    METHODS cache_html
      IMPORTING iv_text       TYPE string
      RETURNING VALUE(rv_url) TYPE w3url.

    METHODS cache_asset
      IMPORTING iv_text       TYPE string OPTIONAL
                iv_xdata      TYPE xstring OPTIONAL
                iv_url        TYPE w3url OPTIONAL
                iv_type       TYPE c
                iv_subtype    TYPE c
      RETURNING VALUE(rv_url) TYPE w3url.

    METHODS render
      RAISING zcx_abapgit_exception.

    METHODS get_current_page_name
      RETURNING VALUE(rv_page_name) TYPE string.

    METHODS call_page
      IMPORTING ii_page          TYPE REF TO zif_abapgit_gui_page
                iv_with_bookmark TYPE abap_bool DEFAULT abap_false
                iv_replacing     TYPE abap_bool DEFAULT abap_false
      RAISING   zcx_abapgit_exception.

    METHODS handle_action
      IMPORTING iv_action      TYPE c
                iv_frame       TYPE c OPTIONAL
                iv_getdata     TYPE c OPTIONAL
                it_postdata    TYPE cnht_post_data_tab OPTIONAL
                it_query_table TYPE cnht_query_table OPTIONAL.

ENDCLASS.



CLASS ZCL_ABAPGIT_GUI IMPLEMENTATION.


  METHOD back.

    DATA: lv_index TYPE i,
          ls_stack LIKE LINE OF mt_stack.

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


  METHOD cache_asset.

    DATA: lv_xstr  TYPE xstring,
          lt_xdata TYPE lvc_t_mime,
          lv_size  TYPE int4.

    ASSERT iv_text IS SUPPLIED OR iv_xdata IS SUPPLIED.

    IF iv_text IS SUPPLIED. " String input
      lv_xstr = zcl_abapgit_string_utils=>string_to_xstring( iv_text ).
    ELSE. " Raw input
      lv_xstr = iv_xdata.
    ENDIF.

    zcl_abapgit_string_utils=>xstring_to_bintab(
      EXPORTING
        iv_xstr   = lv_xstr
      IMPORTING
        ev_size   = lv_size
        et_bintab = lt_xdata ).

    mo_html_viewer->load_data(
      EXPORTING
        type         = iv_type
        subtype      = iv_subtype
        size         = lv_size
        url          = iv_url
      IMPORTING
        assigned_url = rv_url
      CHANGING
        data_table   = lt_xdata
      EXCEPTIONS
        OTHERS       = 1 ) ##NO_TEXT.

    ASSERT sy-subrc = 0. " Image data error

  ENDMETHOD.


  METHOD cache_html.

    rv_url = cache_asset( iv_text    = iv_text
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

    mi_router    = ii_router.
    mi_asset_man = ii_asset_man.
    startup( ).

  ENDMETHOD.


  METHOD free.

    SET HANDLER me->on_event FOR mo_html_viewer ACTIVATION space.
    mo_html_viewer->close_document( ).
    mo_html_viewer->free( ).
    FREE mo_html_viewer.

  ENDMETHOD.


  METHOD get_current_page_name.
    IF mi_cur_page IS BOUND.
      rv_page_name =
        cl_abap_classdescr=>describe_by_object_ref( mi_cur_page
          )->get_relative_name( ).
    ENDIF." ELSE - return is empty => initial page

  ENDMETHOD.


  METHOD go_home.

    on_event( action = |{ c_action-go_home }| ). " doesn't accept strings directly

  ENDMETHOD.


  METHOD handle_action.

    DATA: lx_exception TYPE REF TO zcx_abapgit_exception,
          li_page      TYPE REF TO zif_abapgit_gui_page,
          lv_state     TYPE i.

    TRY.
        IF mi_cur_page IS BOUND.
          mi_cur_page->on_event(
            EXPORTING
              iv_action    = iv_action
              iv_prev_page = get_current_page_name( )
              iv_getdata   = iv_getdata
              it_postdata  = it_postdata
            IMPORTING
              ei_page      = li_page
              ev_state     = lv_state ).
        ENDIF.

        IF lv_state IS INITIAL.
          mi_router->on_event(
            EXPORTING
              iv_action    = iv_action
              iv_prev_page = get_current_page_name( )
              iv_getdata   = iv_getdata
              it_postdata  = it_postdata
            IMPORTING
              ei_page      = li_page
              ev_state     = lv_state ).
        ENDIF.

        CASE lv_state.
          WHEN c_event_state-re_render.
            render( ).
          WHEN c_event_state-new_page.
            call_page( li_page ).
          WHEN c_event_state-new_page_w_bookmark.
            call_page( ii_page = li_page iv_with_bookmark = abap_true ).
          WHEN c_event_state-new_page_replacing.
            call_page( ii_page = li_page iv_replacing = abap_true ).
          WHEN c_event_state-go_back.
            back( ).
          WHEN c_event_state-go_back_to_bookmark.
            back( abap_true ).
          WHEN c_event_state-no_more_act.
            " Do nothing, handling completed
          WHEN OTHERS.
            zcx_abapgit_exception=>raise( |Unknown action: { iv_action }| ).
        ENDCASE.

      CATCH zcx_abapgit_exception INTO lx_exception.
        ROLLBACK WORK.
        MESSAGE lx_exception TYPE 'S' DISPLAY LIKE 'E'.
      CATCH zcx_abapgit_cancel ##NO_HANDLER.
        " Do nothing = gc_event_state-no_more_act
    ENDTRY.

  ENDMETHOD.


  METHOD on_event.

    handle_action(
      iv_action      = action
      iv_frame       = frame
      iv_getdata     = getdata
      it_postdata    = postdata
      it_query_table = query_table ).

  ENDMETHOD.


  METHOD render.

    DATA: lv_url  TYPE w3url,
          lo_html TYPE REF TO zcl_abapgit_html.

    lo_html = mi_cur_page->render( ).
    lv_url  = cache_html( lo_html->render( iv_no_indent_jscss = abap_true ) ).

    mo_html_viewer->show_url( lv_url ).

  ENDMETHOD.


  METHOD startup.

    DATA: lt_events TYPE cntl_simple_events,
          ls_event  LIKE LINE OF lt_events,
          lt_assets TYPE zif_abapgit_gui_asset_manager=>tt_web_assets.

    FIELD-SYMBOLS <ls_asset> LIKE LINE OF lt_assets.

    CREATE OBJECT mo_html_viewer
      EXPORTING
        query_table_disabled = abap_true
        parent               = cl_gui_container=>screen0.

    lt_assets = mi_asset_man->get_all_assets( ).
    LOOP AT lt_assets ASSIGNING <ls_asset>.
      cache_asset( iv_xdata   = <ls_asset>-content
                   iv_url     = <ls_asset>-url
                   iv_type    = <ls_asset>-type
                   iv_subtype = <ls_asset>-subtype ).
    ENDLOOP.

    ls_event-eventid    = mo_html_viewer->m_id_sapevent.
    ls_event-appl_event = abap_true.
    APPEND ls_event TO lt_events.

    mo_html_viewer->set_registered_events( lt_events ).
    SET HANDLER me->on_event FOR mo_html_viewer.

  ENDMETHOD.
ENDCLASS.
