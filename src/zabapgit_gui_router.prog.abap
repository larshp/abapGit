*&---------------------------------------------------------------------*
*&  Include           ZABAPGIT_GUI_ROUTER
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
*       CLASS lcl_gui_router DEFINITION
*----------------------------------------------------------------------*
CLASS lcl_gui_router DEFINITION FINAL.
  PUBLIC SECTION.

    METHODS on_event
      IMPORTING iv_action    TYPE clike
                iv_prev_page TYPE clike
                iv_getdata   TYPE clike OPTIONAL
                it_postdata  TYPE cnht_post_data_tab OPTIONAL
      EXPORTING ei_page      TYPE REF TO lif_gui_page
                ev_state     TYPE i
      RAISING   lcx_exception.

  PRIVATE SECTION.

    METHODS get_page_by_name
      IMPORTING iv_name        TYPE clike
      RETURNING VALUE(ri_page) TYPE REF TO lif_gui_page
      RAISING   lcx_exception.

    METHODS get_page_diff
      IMPORTING iv_getdata     TYPE clike
      RETURNING VALUE(ri_page) TYPE REF TO lif_gui_page
      RAISING   lcx_exception.

    METHODS get_page_branch_overview
      IMPORTING iv_getdata     TYPE clike
      RETURNING VALUE(ri_page) TYPE REF TO lif_gui_page
      RAISING   lcx_exception.

    METHODS get_page_stage
      IMPORTING iv_key         TYPE lcl_persistence_repo=>ty_repo-key
      RETURNING VALUE(ri_page) TYPE REF TO lif_gui_page
      RAISING   lcx_exception.

    METHODS get_page_db_by_name
      IMPORTING iv_name        TYPE clike
                iv_getdata     TYPE clike
      RETURNING VALUE(ri_page) TYPE REF TO lif_gui_page
      RAISING   lcx_exception.

    METHODS repo_pull
      IMPORTING iv_key TYPE lcl_persistence_repo=>ty_repo-key
      RAISING   lcx_exception.

    METHODS reset
      IMPORTING iv_key TYPE lcl_persistence_repo=>ty_repo-key
      RAISING   lcx_exception.

    METHODS create_branch
      IMPORTING iv_key TYPE lcl_persistence_repo=>ty_repo-key
      RAISING   lcx_exception.

    METHODS db_delete
      IMPORTING iv_getdata TYPE clike
      RAISING   lcx_exception.

    METHODS db_save
      IMPORTING it_postdata TYPE cnht_post_data_tab
      RAISING   lcx_exception.

ENDCLASS.

*----------------------------------------------------------------------*
*       CLASS lcl_gui_router IMPLEMENTATION
*----------------------------------------------------------------------*
CLASS lcl_gui_router IMPLEMENTATION.

  METHOD on_event.

    DATA: lv_url     TYPE string,
          lv_key     TYPE lcl_persistence_repo=>ty_repo-key,
          ls_item    TYPE ty_item.

    lv_key = iv_getdata. " TODO refactor
    lv_url = iv_getdata. " TODO refactor

    TRY.
        CASE iv_action.
            " General routing
          WHEN 'main'
              OR 'explore'
              OR 'db'
              OR 'background_run'.
            ei_page  = get_page_by_name( iv_action ).
            ev_state = gc_event_state-new_page.
          WHEN 'background'.
            lv_key = iv_getdata.
            CREATE OBJECT ei_page TYPE lcl_gui_page_background
              EXPORTING
                iv_key = lv_key.
            ev_state = gc_event_state-new_page.
          WHEN 'abapgit_home'.
            lcl_services_abapgit=>open_abapgit_homepage( ).
            ev_state = gc_event_state-no_more_act.
          WHEN 'abapgit_installation'.
            lcl_services_abapgit=>install_abapgit( ).
            ev_state = gc_event_state-re_render.
          WHEN 'jump'.
            lcl_html_action_utils=>jump_decode( EXPORTING iv_string   = iv_getdata
                                                IMPORTING ev_obj_type = ls_item-obj_type
                                                          ev_obj_name = ls_item-obj_name ).
            lcl_objects=>jump( ls_item ).
            ev_state = gc_event_state-no_more_act.
          WHEN 'diff'.
            ei_page  = get_page_diff( iv_getdata ).
            ev_state = gc_event_state-new_page.

            " DB actions
          WHEN 'db_display' OR 'db_edit'.
            ei_page  = get_page_db_by_name( iv_name = iv_action  iv_getdata = iv_getdata ).
            IF iv_prev_page = 'PAGE_DB_DISPLAY'.
              ev_state = gc_event_state-new_page_replacing.
            ELSE.
              ev_state = gc_event_state-new_page.
            ENDIF.
          WHEN 'db_delete'.
            db_delete( iv_getdata = iv_getdata ).
            ev_state = gc_event_state-re_render.
          WHEN 'db_save'.
            db_save( it_postdata ).
            ev_state = gc_event_state-go_back.

            " Repository services actions
          WHEN gc_action-repo_refresh.  " Repo refresh
            lcl_services_repo=>refresh( lv_key ).
            ev_state = gc_event_state-re_render.
          WHEN gc_action-repo_purge.    " Repo remove & purge all objects
            lcl_services_repo=>purge( lv_key ).
            ev_state = gc_event_state-re_render.
          WHEN gc_action-repo_remove.   " Repo remove
            lcl_services_repo=>remove( lv_key ).
            ev_state = gc_event_state-re_render.
          WHEN gc_action-repo_clone OR 'install'.    " Repo clone, 'install' is for explore page
            lcl_services_repo=>clone( lv_url ).
            ev_state = gc_event_state-re_render.


            " ZIP services actions
          WHEN 'zipimport'.
            lv_key   = iv_getdata.
            lcl_zip=>import( lv_key ).
            ev_state = gc_event_state-re_render.
          WHEN 'zipexport'.
            lv_key   = iv_getdata.
            lcl_zip=>export( lcl_app=>repo_srv( )->get( lv_key ) ).
            ev_state = gc_event_state-no_more_act.
          WHEN 'packagezip'.
            lcl_popups=>repo_package_zip( ).
            ev_state = gc_event_state-no_more_act.
          WHEN 'transportzip'.
            lcl_transport=>zip( ).
            ev_state = gc_event_state-no_more_act.

            " Repository online actions
          WHEN 'pull'.
            lv_key   = iv_getdata.
            repo_pull( lv_key ).
            ev_state = gc_event_state-re_render.
          WHEN 'stage'.
            lv_key   = iv_getdata.
            ei_page  = get_page_stage( lv_key ).
            ev_state = gc_event_state-new_page_w_bookmark.
          WHEN 'reset'.
            lv_key   = iv_getdata.
            reset( lv_key ).
            ev_state = gc_event_state-re_render.
          WHEN 'create_branch'.
            lv_key   = iv_getdata.
            create_branch( lv_key ).
            ev_state = gc_event_state-re_render.
          WHEN 'branch_overview'.
            ei_page  = get_page_branch_overview( iv_getdata ).
            ev_state = gc_event_state-new_page.
          WHEN OTHERS.
            ev_state = gc_event_state-not_handled.
        ENDCASE.
      CATCH lcx_cancel.
        ev_state = gc_event_state-no_more_act.
    ENDTRY.
  ENDMETHOD.        " on_event

  METHOD get_page_by_name.

    DATA: lv_page_class TYPE string,
          lv_message    TYPE string.

    lv_page_class = |LCL_GUI_PAGE_{ to_upper( iv_name ) }|.

    TRY.
        CREATE OBJECT ri_page TYPE (lv_page_class).
      CATCH cx_sy_create_object_error.
        lv_message = |Cannot create page class { lv_page_class }|.
        lcx_exception=>raise( lv_message ).
    ENDTRY.

  ENDMETHOD.        " get_page_by_name

  METHOD get_page_db_by_name.

    DATA: lv_page_class TYPE string,
          lv_message    TYPE string,
          ls_key        TYPE lcl_persistence_db=>ty_content.

    lv_page_class = |LCL_GUI_PAGE_{ to_upper( iv_name ) }|.
    ls_key        = lcl_html_action_utils=>dbkey_decode( iv_getdata ).

    TRY.
        CREATE OBJECT ri_page TYPE (lv_page_class)
          EXPORTING
            is_key = ls_key.

      CATCH cx_sy_create_object_error.
        lv_message = |Cannot create page class { lv_page_class }|.
        lcx_exception=>raise( lv_message ).
    ENDTRY.

  ENDMETHOD.        " get_page_db_by_name

  METHOD get_page_branch_overview.

    DATA: lo_repo TYPE REF TO lcl_repo_online,
          lo_page TYPE REF TO lcl_gui_page_branch_overview,
          lv_key  TYPE lcl_persistence_repo=>ty_repo-key.


    lv_key = iv_getdata.

    lo_repo ?= lcl_app=>repo_srv( )->get( lv_key ).

    CREATE OBJECT lo_page
      EXPORTING
        io_repo = lo_repo.

    ri_page = lo_page.

  ENDMETHOD.

  METHOD get_page_diff.

    DATA: lt_remote TYPE ty_files_tt,
          lt_local  TYPE ty_files_item_tt,
          lo_page   TYPE REF TO lcl_gui_page_diff,
          lo_repo   TYPE REF TO lcl_repo_online,
          ls_file   TYPE ty_repo_file,
          lv_key    TYPE lcl_persistence_repo=>ty_repo-key.

    FIELD-SYMBOLS: <ls_remote> LIKE LINE OF lt_remote,
                   <ls_local>  LIKE LINE OF lt_local.

    lcl_html_action_utils=>file_decode( EXPORTING iv_string = iv_getdata
                                        IMPORTING ev_key    = lv_key
                                                  eg_file   = ls_file ).

    lo_repo  ?= lcl_app=>repo_srv( )->get( lv_key ).
    lt_remote = lo_repo->get_files_remote( ).
    lt_local  = lo_repo->get_files_local( ).

    READ TABLE lt_remote ASSIGNING <ls_remote>
      WITH KEY filename = ls_file-filename
               path     = ls_file-path.
    IF sy-subrc <> 0.
      lcx_exception=>raise( 'file not found remotely' ).
    ENDIF.

    READ TABLE lt_local ASSIGNING <ls_local>
      WITH KEY file-filename = ls_file-filename
               file-path     = ls_file-path.
    IF sy-subrc <> 0.
      lcx_exception=>raise( 'file not found locally' ).
    ENDIF.

    CREATE OBJECT lo_page
      EXPORTING
        is_local  = <ls_local>-file
        is_remote = <ls_remote>.

    ri_page = lo_page.

  ENDMETHOD.

  METHOD reset.

    DATA: lo_repo   TYPE REF TO lcl_repo_online,
          lv_answer TYPE c LENGTH 1.


    lo_repo ?= lcl_app=>repo_srv( )->get( iv_key ).

    IF lo_repo->is_write_protected( ) = abap_true.
      lcx_exception=>raise( 'Cannot reset. Local code is write-protected by repo config' ).
    ENDIF.

    lv_answer = lcl_popups=>popup_to_confirm(
      titlebar              = 'Warning'
      text_question         = 'Reset local objects?'
      text_button_1         = 'Ok'
      icon_button_1         = 'ICON_OKAY'
      text_button_2         = 'Cancel'
      icon_button_2         = 'ICON_CANCEL'
      default_button        = '2'
      display_cancel_button = abap_false
    ).  "#EC NOTEXT

    IF lv_answer = '2'.
      RETURN.
    ENDIF.

    lo_repo->deserialize( ).

  ENDMETHOD.

  METHOD create_branch.

    DATA: lv_name   TYPE string,
          lv_cancel TYPE abap_bool,
          lo_repo   TYPE REF TO lcl_repo_online.


    lo_repo ?= lcl_app=>repo_srv( )->get( iv_key ).

    lcl_popups=>create_branch_popup(
      IMPORTING
        ev_name   = lv_name
        ev_cancel = lv_cancel ).
    IF lv_cancel = abap_true.
      RETURN.
    ENDIF.

    ASSERT lv_name CP 'refs/heads/+*'.

    lcl_git_porcelain=>create_branch(
      io_repo = lo_repo
      iv_name = lv_name
      iv_from = lo_repo->get_sha1_local( ) ).

* automatically switch to new branch
    lo_repo->set_branch_name( lv_name ).

    MESSAGE 'Switched to new branch' TYPE 'S' ##NO_TEXT.

  ENDMETHOD.

  METHOD repo_pull.

    DATA: lo_repo TYPE REF TO lcl_repo_online.

    lo_repo ?= lcl_app=>repo_srv( )->get( iv_key ).

    IF lo_repo->is_write_protected( ) = abap_true.
      lcx_exception=>raise( 'Cannot pull. Local code is write-protected by repo config' ).
    ENDIF.

    lo_repo->refresh( ).
    lo_repo->deserialize( ).

    COMMIT WORK.

  ENDMETHOD.                    "pull

  METHOD get_page_stage.

    DATA: lo_repo       TYPE REF TO lcl_repo_online,
          lo_stage_page TYPE REF TO lcl_gui_page_stage.


    lo_repo ?= lcl_app=>repo_srv( )->get( iv_key ).

    " force refresh on stage, to make sure the latest local and remote files are used
    lo_repo->refresh( ).

    CREATE OBJECT lo_stage_page
      EXPORTING
        io_repo = lo_repo.

    ri_page = lo_stage_page.

  ENDMETHOD.

  METHOD db_delete.

    DATA: lv_answer TYPE c LENGTH 1,
          ls_key    TYPE lcl_persistence_db=>ty_content.


    ls_key = lcl_html_action_utils=>dbkey_decode( iv_getdata ).

    lv_answer = lcl_popups=>popup_to_confirm(
      titlebar              = 'Warning'
      text_question         = 'Delete?'
      text_button_1         = 'Ok'
      icon_button_1         = 'ICON_DELETE'
      text_button_2         = 'Cancel'
      icon_button_2         = 'ICON_CANCEL'
      default_button        = '2'
      display_cancel_button = abap_false
    ).  "#EC NOTEXT

    IF lv_answer = '2'.
      RETURN.
    ENDIF.

    lcl_app=>db( )->delete(
      iv_type  = ls_key-type
      iv_value = ls_key-value ).

    COMMIT WORK.

  ENDMETHOD.

  METHOD db_save.

    DATA: lv_string  TYPE string,
          ls_content TYPE lcl_persistence_db=>ty_content,
          lt_fields  TYPE tihttpnvp.

    FIELD-SYMBOLS: <ls_field> LIKE LINE OF lt_fields.


    CONCATENATE LINES OF it_postdata INTO lv_string.

    lt_fields = cl_http_utility=>if_http_utility~string_to_fields( lv_string ).

    READ TABLE lt_fields ASSIGNING <ls_field> WITH KEY name = 'type' ##NO_TEXT.
    ASSERT sy-subrc = 0.
    ls_content-type = <ls_field>-value.

    READ TABLE lt_fields ASSIGNING <ls_field> WITH KEY name = 'value' ##NO_TEXT.
    ASSERT sy-subrc = 0.
    ls_content-value = <ls_field>-value.

    READ TABLE lt_fields ASSIGNING <ls_field> WITH KEY name = 'xmldata' ##NO_TEXT.
    ASSERT sy-subrc = 0.
    IF <ls_field>-value(1) <> '<'.
      ls_content-data_str = <ls_field>-value+1. " hmm
    ENDIF.

    lcl_app=>db( )->update(
      iv_type  = ls_content-type
      iv_value = ls_content-value
      iv_data  = ls_content-data_str ).

    COMMIT WORK.

  ENDMETHOD.

ENDCLASS.           " lcl_gui_router