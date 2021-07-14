CLASS zcl_abapgit_gui_page_diff DEFINITION
  PUBLIC
  INHERITING FROM zcl_abapgit_gui_page
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_file_diff,
        path       TYPE string,
        filename   TYPE string,
        obj_type   TYPE string,
        obj_name   TYPE string,
        lstate     TYPE char1,
        rstate     TYPE char1,
        fstate     TYPE char1, " FILE state - Abstraction for shorter ifs
        o_diff     TYPE REF TO zcl_abapgit_diff,
        changed_by TYPE xubname,
        type       TYPE string,
      END OF ty_file_diff.
    TYPES:
      ty_file_diffs TYPE STANDARD TABLE OF ty_file_diff
                        WITH NON-UNIQUE DEFAULT KEY
                        WITH NON-UNIQUE SORTED KEY secondary
                             COMPONENTS path filename.

    CONSTANTS:
      BEGIN OF c_fstate,
        local  TYPE char1 VALUE 'L',
        remote TYPE char1 VALUE 'R',
        both   TYPE char1 VALUE 'B',
      END OF c_fstate.

    METHODS constructor
      IMPORTING
        !iv_key    TYPE zif_abapgit_persistence=>ty_repo-key
        !is_file   TYPE zif_abapgit_definitions=>ty_file OPTIONAL
        !is_object TYPE zif_abapgit_definitions=>ty_item OPTIONAL
        !it_files  TYPE zif_abapgit_definitions=>ty_stage_tt OPTIONAL
      RAISING
        zcx_abapgit_exception.

    METHODS zif_abapgit_gui_event_handler~on_event
        REDEFINITION.
  PROTECTED SECTION.

    DATA mv_unified TYPE abap_bool VALUE abap_true ##NO_TEXT.
    DATA mo_repo TYPE REF TO zcl_abapgit_repo .
    DATA mt_diff_files TYPE ty_file_diffs .

    METHODS get_normalized_fname_with_path
      IMPORTING
        !is_diff           TYPE ty_file_diff
      RETURNING
        VALUE(rv_filename) TYPE string .
    METHODS normalize_path
      IMPORTING
        !iv_path             TYPE string
      RETURNING
        VALUE(rv_normalized) TYPE string .
    METHODS normalize_filename
      IMPORTING
        !iv_filename         TYPE string
      RETURNING
        VALUE(rv_normalized) TYPE string .
    METHODS add_menu_end
      IMPORTING
        !io_menu TYPE REF TO zcl_abapgit_html_toolbar .
    METHODS calculate_diff
      IMPORTING
        !is_file   TYPE zif_abapgit_definitions=>ty_file OPTIONAL
        !is_object TYPE zif_abapgit_definitions=>ty_item OPTIONAL
        !it_files  TYPE zif_abapgit_definitions=>ty_stage_tt OPTIONAL
      RAISING
        zcx_abapgit_exception .
    METHODS add_menu_begin
      IMPORTING
        !io_menu TYPE REF TO zcl_abapgit_html_toolbar .
    METHODS render_table_head_non_unified
      IMPORTING
        !ii_html TYPE REF TO zif_abapgit_html
        !is_diff TYPE ty_file_diff .
    METHODS render_beacon_begin_of_row
      IMPORTING
        !ii_html TYPE REF TO zif_abapgit_html
        !is_diff TYPE ty_file_diff .
    METHODS render_diff_head_after_state
      IMPORTING
        !ii_html TYPE REF TO zif_abapgit_html
        !is_diff TYPE ty_file_diff .
    METHODS insert_nav
      RETURNING
        VALUE(rv_insert_nav) TYPE abap_bool .
    METHODS render_line_split_row
      IMPORTING
        !ii_html      TYPE REF TO zif_abapgit_html
        !iv_filename  TYPE string
        !is_diff_line TYPE zif_abapgit_definitions=>ty_diff
        !iv_index     TYPE sy-tabix
        !iv_fstate    TYPE char1
        !iv_new       TYPE string
        !iv_old       TYPE string
      RAISING
        zcx_abapgit_exception .
    METHODS build_menu
      RETURNING
        VALUE(ro_menu) TYPE REF TO zcl_abapgit_html_toolbar .
    METHODS set_layout.

    METHODS render_content
        REDEFINITION .
  PRIVATE SECTION.

    CONSTANTS:
      BEGIN OF c_actions,
        toggle_unified      TYPE string VALUE 'toggle_unified',
        toggle_hidden_chars TYPE string VALUE 'toggle_hidden_chars',
      END OF c_actions .
    DATA mt_delayed_lines TYPE zif_abapgit_definitions=>ty_diffs_tt .
    DATA mv_repo_key TYPE zif_abapgit_persistence=>ty_repo-key .
    DATA mv_seed TYPE string .                    " Unique page id to bind JS sessionStorage
    DATA mv_hidden_chars TYPE abap_bool .

    METHODS render_diff
      IMPORTING
        !is_diff       TYPE ty_file_diff
      RETURNING
        VALUE(ri_html) TYPE REF TO zif_abapgit_html
      RAISING
        zcx_abapgit_exception .
    METHODS render_diff_head
      IMPORTING
        !is_diff       TYPE ty_file_diff
      RETURNING
        VALUE(ri_html) TYPE REF TO zif_abapgit_html
      RAISING
        zcx_abapgit_exception .
    METHODS render_table_head
      IMPORTING
        !is_diff       TYPE ty_file_diff
      RETURNING
        VALUE(ri_html) TYPE REF TO zif_abapgit_html
      RAISING
        zcx_abapgit_exception .
    METHODS render_beacon
      IMPORTING
        !is_diff_line  TYPE zif_abapgit_definitions=>ty_diff
        !is_diff       TYPE ty_file_diff
      RETURNING
        VALUE(ri_html) TYPE REF TO zif_abapgit_html .
    METHODS render_line_split
      IMPORTING
        !is_diff_line  TYPE zif_abapgit_definitions=>ty_diff
        !iv_filename   TYPE string
        !iv_fstate     TYPE char1
        !iv_index      TYPE sy-tabix
      RETURNING
        VALUE(ri_html) TYPE REF TO zif_abapgit_html
      RAISING
        zcx_abapgit_exception .
    METHODS render_line_unified
      IMPORTING
        !is_diff_line  TYPE zif_abapgit_definitions=>ty_diff OPTIONAL
      RETURNING
        VALUE(ri_html) TYPE REF TO zif_abapgit_html .
    METHODS append_diff
      IMPORTING
        !it_remote TYPE zif_abapgit_definitions=>ty_files_tt
        !it_local  TYPE zif_abapgit_definitions=>ty_files_item_tt
        !is_status TYPE zif_abapgit_definitions=>ty_result
      RAISING
        zcx_abapgit_exception .
    METHODS is_binary
      IMPORTING
        !iv_d1        TYPE xstring
        !iv_d2        TYPE xstring
      RETURNING
        VALUE(rv_yes) TYPE abap_bool .
    METHODS add_jump_sub_menu
      IMPORTING
        !io_menu TYPE REF TO zcl_abapgit_html_toolbar .
    METHODS add_filter_sub_menu
      IMPORTING
        !io_menu TYPE REF TO zcl_abapgit_html_toolbar .
    METHODS render_lines
      IMPORTING
        !is_diff       TYPE ty_file_diff
      RETURNING
        VALUE(ri_html) TYPE REF TO zif_abapgit_html
      RAISING
        zcx_abapgit_exception .
    METHODS render_table_head_unified
      IMPORTING
        !ii_html TYPE REF TO zif_abapgit_html .
    METHODS render_scripts
      RETURNING
        VALUE(ri_html) TYPE REF TO zif_abapgit_html
      RAISING
        zcx_abapgit_exception .
    METHODS is_file_requested
      IMPORTING
        it_files                    TYPE zif_abapgit_definitions=>ty_stage_tt
        is_status                   TYPE zif_abapgit_definitions=>ty_result
      RETURNING
        VALUE(rv_is_file_requested) TYPE abap_bool.
ENDCLASS.



CLASS zcl_abapgit_gui_page_diff IMPLEMENTATION.


  METHOD add_filter_sub_menu.

    DATA:
      lo_sub_filter TYPE REF TO zcl_abapgit_html_toolbar,
      lt_types      TYPE string_table,
      lt_users      TYPE string_table.

    FIELD-SYMBOLS: <ls_diff> LIKE LINE OF mt_diff_files,
                   <lv_i>    TYPE string.
    " Get unique
    LOOP AT mt_diff_files ASSIGNING <ls_diff>.
      APPEND <ls_diff>-type TO lt_types.
      APPEND <ls_diff>-changed_by TO lt_users.
    ENDLOOP.

    SORT lt_types.
    DELETE ADJACENT DUPLICATES FROM lt_types.

    SORT lt_users.
    DELETE ADJACENT DUPLICATES FROM lt_users.

    IF lines( lt_types ) > 1 OR lines( lt_users ) > 1.
      CREATE OBJECT lo_sub_filter EXPORTING iv_id = 'diff-filter'.

      IF lines( lt_users ) > 1.
        lo_sub_filter->add( iv_txt = 'Only my changes'
                            iv_typ = zif_abapgit_html=>c_action_type-onclick
                            iv_aux = |{ sy-uname }|
                            iv_chk = abap_false ).
      ENDIF.

      " File types
      IF lines( lt_types ) > 1.
        lo_sub_filter->add( iv_txt = 'TYPE'
                            iv_typ = zif_abapgit_html=>c_action_type-separator ).
        LOOP AT lt_types ASSIGNING <lv_i>.
          lo_sub_filter->add( iv_txt = <lv_i>
                       iv_typ = zif_abapgit_html=>c_action_type-onclick
                       iv_aux = 'type'
                       iv_chk = abap_true ).
        ENDLOOP.
      ENDIF.

      " Changed by
      IF lines( lt_users ) > 1.
        lo_sub_filter->add( iv_txt = 'CHANGED BY'
                            iv_typ = zif_abapgit_html=>c_action_type-separator ).
        LOOP AT lt_users ASSIGNING <lv_i>.
          lo_sub_filter->add( iv_txt = <lv_i>
                       iv_typ = zif_abapgit_html=>c_action_type-onclick
                       iv_aux = 'changed-by'
                       iv_chk = abap_true ).
        ENDLOOP.
      ENDIF.

      io_menu->add( iv_txt = 'Filter'
                    io_sub = lo_sub_filter ).
    ENDIF.

  ENDMETHOD.


  METHOD add_jump_sub_menu.

    DATA: lo_sub_jump    TYPE REF TO zcl_abapgit_html_toolbar,
          lv_jump_target TYPE string.
    FIELD-SYMBOLS: <ls_diff> LIKE LINE OF mt_diff_files.

    CREATE OBJECT lo_sub_jump EXPORTING iv_id = 'jump'.

    LOOP AT mt_diff_files ASSIGNING <ls_diff>.

      lv_jump_target = <ls_diff>-path && <ls_diff>-filename.

      lo_sub_jump->add(
          iv_id  = |li_jump_{ sy-tabix }|
          iv_txt = lv_jump_target
          iv_typ = zif_abapgit_html=>c_action_type-onclick ).

    ENDLOOP.

    io_menu->add( iv_txt = 'Jump'
                  io_sub = lo_sub_jump ).

  ENDMETHOD.


  METHOD add_menu_begin.

  ENDMETHOD.


  METHOD add_menu_end.

    io_menu->add( iv_txt = 'Split/Unified'
                  iv_act = c_actions-toggle_unified ).

    io_menu->add( iv_txt   = '&para;'
                  iv_title = 'Toggle Hidden Characters'
                  iv_act   = c_actions-toggle_hidden_chars ).

  ENDMETHOD.


  METHOD append_diff.

    DATA:
      lv_offs    TYPE i,
      ls_r_dummy LIKE LINE OF it_remote ##NEEDED,
      ls_l_dummy LIKE LINE OF it_local  ##NEEDED.

    FIELD-SYMBOLS: <ls_remote> LIKE LINE OF it_remote,
                   <ls_local>  LIKE LINE OF it_local,
                   <ls_diff>   LIKE LINE OF mt_diff_files.


    READ TABLE it_remote ASSIGNING <ls_remote>
      WITH KEY filename = is_status-filename
               path     = is_status-path.
    IF sy-subrc <> 0.
      ASSIGN ls_r_dummy TO <ls_remote>.
    ENDIF.

    READ TABLE it_local ASSIGNING <ls_local>
      WITH KEY file-filename = is_status-filename
               file-path     = is_status-path.
    IF sy-subrc <> 0.
      ASSIGN ls_l_dummy TO <ls_local>.
    ENDIF.

    IF <ls_local> IS INITIAL AND <ls_remote> IS INITIAL.
      zcx_abapgit_exception=>raise( |DIFF: file not found { is_status-filename }| ).
    ENDIF.

    APPEND INITIAL LINE TO mt_diff_files ASSIGNING <ls_diff>.
    <ls_diff>-path     = is_status-path.
    <ls_diff>-filename = is_status-filename.
    <ls_diff>-obj_type = is_status-obj_type.
    <ls_diff>-obj_name = is_status-obj_name.
    <ls_diff>-lstate   = is_status-lstate.
    <ls_diff>-rstate   = is_status-rstate.

    IF <ls_diff>-lstate IS NOT INITIAL AND <ls_diff>-rstate IS NOT INITIAL.
      <ls_diff>-fstate = c_fstate-both.
    ELSEIF <ls_diff>-lstate IS NOT INITIAL.
      <ls_diff>-fstate = c_fstate-local.
    ELSE. "rstate IS NOT INITIAL, lstate = empty.
      <ls_diff>-fstate = c_fstate-remote.
    ENDIF.

    " Changed by
    IF <ls_local>-item-obj_type IS NOT INITIAL.
      <ls_diff>-changed_by = zcl_abapgit_objects=>changed_by( <ls_local>-item ).
    ENDIF.
    IF <ls_diff>-changed_by IS INITIAL.
      <ls_diff>-changed_by = zcl_abapgit_objects_super=>c_user_unknown.
    ENDIF.

    " Extension
    IF <ls_local>-file-filename IS NOT INITIAL.
      <ls_diff>-type = reverse( <ls_local>-file-filename ).
    ELSE.
      <ls_diff>-type = reverse( <ls_remote>-filename ).
    ENDIF.

    FIND FIRST OCCURRENCE OF '.' IN <ls_diff>-type MATCH OFFSET lv_offs.
    <ls_diff>-type = reverse( substring( val = <ls_diff>-type
                                         len = lv_offs ) ).
    IF <ls_diff>-type <> 'xml' AND <ls_diff>-type <> 'abap'.
      <ls_diff>-type = 'other'.
    ENDIF.

    IF <ls_diff>-type = 'other'
       AND is_binary( iv_d1 = <ls_remote>-data
                      iv_d2 = <ls_local>-file-data ) = abap_true.
      <ls_diff>-type = 'binary'.
    ENDIF.

    " Diff data
    IF <ls_diff>-type <> 'binary'.
      IF <ls_diff>-fstate = c_fstate-remote. " Remote file leading changes
        CREATE OBJECT <ls_diff>-o_diff
          EXPORTING
            iv_new = <ls_remote>-data
            iv_old = <ls_local>-file-data.
      ELSE.             " Local leading changes or both were modified
        CREATE OBJECT <ls_diff>-o_diff
          EXPORTING
            iv_new = <ls_local>-file-data
            iv_old = <ls_remote>-data.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD build_menu.

    CREATE OBJECT ro_menu.

    add_menu_begin( ro_menu ).
    add_jump_sub_menu( ro_menu ).
    add_filter_sub_menu( ro_menu ).
    add_menu_end( ro_menu ).

  ENDMETHOD.


  METHOD calculate_diff.

    DATA: lt_remote TYPE zif_abapgit_definitions=>ty_files_tt,
          lt_local  TYPE zif_abapgit_definitions=>ty_files_item_tt,
          lt_status TYPE zif_abapgit_definitions=>ty_results_tt.

    DATA li_exit TYPE REF TO zif_abapgit_exit.

    FIELD-SYMBOLS: <ls_status> LIKE LINE OF lt_status.

    CLEAR: mt_diff_files.

    lt_remote = mo_repo->get_files_remote( ).
    lt_local  = mo_repo->get_files_local( ).
    mo_repo->reset_status( ).
    lt_status = mo_repo->status( ).

    li_exit = zcl_abapgit_exit=>get_instance( ).
    li_exit->pre_calculate_repo_status(
      EXPORTING
        is_repo_meta = mo_repo->ms_data
      CHANGING
        ct_local  = lt_local
        ct_remote = lt_remote ).

    IF is_file IS NOT INITIAL.        " Diff for one file

      READ TABLE lt_status ASSIGNING <ls_status>
        WITH KEY path = is_file-path filename = is_file-filename.
      ASSERT sy-subrc = 0.

      append_diff( it_remote = lt_remote
                   it_local  = lt_local
                   is_status = <ls_status> ).

    ELSEIF is_object IS NOT INITIAL.  " Diff for whole object

      LOOP AT lt_status ASSIGNING <ls_status>
          WHERE obj_type = is_object-obj_type
          AND obj_name = is_object-obj_name
          AND match IS INITIAL.
        append_diff( it_remote = lt_remote
                     it_local  = lt_local
                     is_status = <ls_status> ).
      ENDLOOP.

    ELSE.                             " Diff for the whole repo

      SORT lt_status BY
        path ASCENDING
        filename ASCENDING.
      LOOP AT lt_status ASSIGNING <ls_status> WHERE match IS INITIAL.

        IF is_file_requested( it_files  = it_files
                              is_status = <ls_status> ) = abap_true.

          append_diff( it_remote = lt_remote
                       it_local  = lt_local
                       is_status = <ls_status> ).

        ENDIF.

      ENDLOOP.

    ENDIF.

  ENDMETHOD.


  METHOD constructor.

    DATA: lv_ts TYPE timestamp.

    super->constructor( ).
    ms_control-page_title = 'Diff'.
    mv_unified            = zcl_abapgit_persistence_user=>get_instance( )->get_diff_unified( ).
    set_layout( ).
    mv_repo_key           = iv_key.
    mo_repo              ?= zcl_abapgit_repo_srv=>get_instance( )->get( iv_key ).

    GET TIME STAMP FIELD lv_ts.
    mv_seed = |diff{ lv_ts }|. " Generate based on time

    ASSERT is_file IS INITIAL OR is_object IS INITIAL. " just one passed

    calculate_diff(
        is_file   = is_file
        is_object = is_object
        it_files  = it_files ).

    IF lines( mt_diff_files ) = 0.
      zcx_abapgit_exception=>raise( 'PAGE_DIFF ERROR: No diff files found' ).
    ENDIF.

    ms_control-page_menu = build_menu( ).

  ENDMETHOD.

  METHOD set_layout.

    IF mv_unified = abap_true.
      ms_control-page_layout = c_page_layout-centered.
    ELSE.
      ms_control-page_layout = c_page_layout-full_width.
    ENDIF.

  ENDMETHOD.


  METHOD get_normalized_fname_with_path.

    rv_filename = normalize_path( is_diff-path )
               && `_`
               && normalize_filename( is_diff-filename ).

  ENDMETHOD.


  METHOD insert_nav.

  ENDMETHOD.


  METHOD is_binary.

    FIELD-SYMBOLS <lv_data> LIKE iv_d1.

    IF iv_d1 IS NOT INITIAL. " One of them might be new and so empty
      ASSIGN iv_d1 TO <lv_data>.
    ELSE.
      ASSIGN iv_d2 TO <lv_data>.
    ENDIF.

    rv_yes = zcl_abapgit_utils=>is_binary( <lv_data> ).

  ENDMETHOD.


  METHOD normalize_filename.

    rv_normalized = replace( val  = iv_filename
                             sub  = '.'
                             occ  = 0
                             with = '_' ).

  ENDMETHOD.


  METHOD normalize_path.

    rv_normalized = replace( val  = iv_path
                             sub  = '/'
                             occ  = 0
                             with = '_' ).

  ENDMETHOD.


  METHOD render_beacon.

    DATA: lv_beacon  TYPE string,
          lt_beacons TYPE zif_abapgit_definitions=>ty_string_tt.

    CREATE OBJECT ri_html TYPE zcl_abapgit_html.

    IF is_diff_line-beacon > 0.
      lt_beacons = is_diff-o_diff->get_beacons( ).
      READ TABLE lt_beacons INTO lv_beacon INDEX is_diff_line-beacon.
    ELSE.
      lv_beacon = '---'.
    ENDIF.

    ri_html->add( '<thead class="nav_line">' ).
    ri_html->add( '<tr>' ).

    render_beacon_begin_of_row(
      ii_html = ri_html
      is_diff = is_diff ).

    IF mv_unified = abap_true.
      ri_html->add( '<th class="num"></th>' ).
      ri_html->add( '<th class="mark"></th>' ).
      ri_html->add( |<th>@@ { is_diff_line-new_num } @@ { lv_beacon }</th>| ).
    ELSE.
      ri_html->add( |<th colspan="6">@@ { is_diff_line-new_num } @@ { lv_beacon }</th>| ).
    ENDIF.

    ri_html->add( '</tr>' ).
    ri_html->add( '</thead>' ).

  ENDMETHOD.


  METHOD render_beacon_begin_of_row.

    ii_html->add( '<th class="num"></th>' ).

  ENDMETHOD.


  METHOD render_content.

    DATA: ls_diff_file LIKE LINE OF mt_diff_files,
          li_progress  TYPE REF TO zif_abapgit_progress.

    CREATE OBJECT ri_html TYPE zcl_abapgit_html.

    li_progress = zcl_abapgit_progress=>get_instance( lines( mt_diff_files ) ).

    ri_html->add( `<div class="repo">` ).
    ri_html->add( zcl_abapgit_gui_chunk_lib=>render_repo_top( mo_repo ) ).
    ri_html->add( `</div>` ).

    ri_html->add( |<div id="diff-list" data-repo-key="{ mv_repo_key }">| ).
    ri_html->add( zcl_abapgit_gui_chunk_lib=>render_js_error_banner( ) ).
    LOOP AT mt_diff_files INTO ls_diff_file.
      li_progress->show(
        iv_current = sy-tabix
        iv_text    = |Render Diff - { ls_diff_file-filename }| ).

      ri_html->add( render_diff( ls_diff_file ) ).
    ENDLOOP.
    IF sy-subrc <> 0.
      ri_html->add( |No more diffs| ).
    ENDIF.
    ri_html->add( '</div>' ).

    register_deferred_script( render_scripts( ) ).

    li_progress->off( ).

  ENDMETHOD.


  METHOD render_diff.

    CREATE OBJECT ri_html TYPE zcl_abapgit_html.

    ri_html->add( |<div class="diff" data-type="{ is_diff-type
      }" data-changed-by="{ is_diff-changed_by
      }" data-file="{ is_diff-path && is_diff-filename }">| ).
    ri_html->add( render_diff_head( is_diff ) ).

    " Content
    IF is_diff-type <> 'binary'.
      ri_html->add( '<div class="diff_content">' ).
      ri_html->add( |<table class="diff_tab syntax-hl" id="{ is_diff-filename }">| ).
      ri_html->add( render_table_head( is_diff ) ).
      ri_html->add( render_lines( is_diff ) ).
      ri_html->add( '</table>' ).
    ELSE.
      ri_html->add( '<div class="diff_content paddings center grey">' ).
      ri_html->add( 'The content seems to be binary.' ).
      ri_html->add( 'Cannot display as diff.' ).
    ENDIF.
    ri_html->add( '</div>' ).

    ri_html->add( '</div>' ).

  ENDMETHOD.


  METHOD render_diff_head.

    DATA: ls_stats    TYPE zif_abapgit_definitions=>ty_count,
          lv_adt_link TYPE string.

    CREATE OBJECT ri_html TYPE zcl_abapgit_html.

    ri_html->add( '<div class="diff_head">' ).

    ri_html->add_icon(
      iv_name    = 'chevron-down'
      iv_hint    = 'Collapse/Expand'
      iv_class   = 'cursor-pointer'
      iv_onclick = 'onDiffCollapse(event)' ).

    IF is_diff-type <> 'binary'.
      ls_stats = is_diff-o_diff->stats( ).
      IF is_diff-fstate = c_fstate-both. " Merge stats into 'update' if both were changed
        ls_stats-update = ls_stats-update + ls_stats-insert + ls_stats-delete.
        CLEAR: ls_stats-insert, ls_stats-delete.
      ENDIF.

      ri_html->add( |<span class="diff_banner diff_ins">+ { ls_stats-insert }</span>| ).
      ri_html->add( |<span class="diff_banner diff_del">- { ls_stats-delete }</span>| ).
      ri_html->add( |<span class="diff_banner diff_upd">~ { ls_stats-update }</span>| ).
    ENDIF.

    " no links for nonexistent or deleted objects
    IF NOT ( is_diff-lstate = zif_abapgit_definitions=>c_state-unchanged AND
             is_diff-rstate = zif_abapgit_definitions=>c_state-added ) AND
         NOT is_diff-lstate = zif_abapgit_definitions=>c_state-deleted.
      lv_adt_link = ri_html->a(
        iv_txt = |{ is_diff-path }{ is_diff-filename }|
        iv_typ = zif_abapgit_html=>c_action_type-sapevent
        iv_act = |jump?TYPE={ is_diff-obj_type }&NAME={ is_diff-obj_name }| ).
    ENDIF.

    IF lv_adt_link IS NOT INITIAL.
      ri_html->add( |<span class="diff_name">{ lv_adt_link }</span>| ).
    ELSE.
      ri_html->add( |<span class="diff_name">{ is_diff-path }{ is_diff-filename }</span>| ).
    ENDIF.

    ri_html->add( zcl_abapgit_gui_chunk_lib=>render_item_state(
      iv_lstate = is_diff-lstate
      iv_rstate = is_diff-rstate ) ).

    render_diff_head_after_state(
      ii_html = ri_html
      is_diff = is_diff ).

    ri_html->add( '<span class="diff_changed_by">Last Changed by: ' ).
    ri_html->add( zcl_abapgit_gui_chunk_lib=>render_user_name( is_diff-changed_by ) ).
    ri_html->add( '</span>' ).

    ri_html->add( '</div>' ).

  ENDMETHOD.


  METHOD render_diff_head_after_state.

    IF is_diff-fstate = c_fstate-both AND mv_unified = abap_true.
      ii_html->add( '<span class="attention pad-sides">Attention: Unified mode'
                 && ' highlighting for MM assumes local file is newer ! </span>' ).
    ENDIF.

  ENDMETHOD.


  METHOD render_lines.

    DATA: lo_highlighter TYPE REF TO zcl_abapgit_syntax_highlighter,
          lt_diffs       TYPE zif_abapgit_definitions=>ty_diffs_tt,
          lv_insert_nav  TYPE abap_bool,
          lv_tabix       TYPE syst-tabix.

    FIELD-SYMBOLS <ls_diff> LIKE LINE OF lt_diffs.

    lo_highlighter = zcl_abapgit_syntax_factory=>create( iv_filename     = is_diff-filename
                                                         iv_hidden_chars = mv_hidden_chars ).
    CREATE OBJECT ri_html TYPE zcl_abapgit_html.

    lt_diffs = is_diff-o_diff->get( ).

    lv_insert_nav = insert_nav( ).

    LOOP AT lt_diffs ASSIGNING <ls_diff>.

      lv_tabix = sy-tabix.

      IF <ls_diff>-short = abap_false.
        lv_insert_nav = abap_true.
        CONTINUE.
      ENDIF.

      IF lv_insert_nav = abap_true. " Insert separator line with navigation
        ri_html->add( render_beacon( is_diff_line = <ls_diff>
                                     is_diff = is_diff ) ).
        lv_insert_nav = abap_false.
      ENDIF.

      IF lo_highlighter IS BOUND.
        <ls_diff>-new = lo_highlighter->process_line( <ls_diff>-new ).
        <ls_diff>-old = lo_highlighter->process_line( <ls_diff>-old ).
      ELSE.
        <ls_diff>-new = escape( val = <ls_diff>-new
                                format = cl_abap_format=>e_html_attr ).
        <ls_diff>-old = escape( val = <ls_diff>-old
                                format = cl_abap_format=>e_html_attr ).
      ENDIF.

      CONDENSE <ls_diff>-new_num. "get rid of leading spaces
      CONDENSE <ls_diff>-old_num.

      IF mv_unified = abap_true.
        ri_html->add( render_line_unified( is_diff_line = <ls_diff> ) ).
      ELSE.
        ri_html->add( render_line_split( is_diff_line = <ls_diff>
                                         iv_filename  = get_normalized_fname_with_path( is_diff )
                                         iv_fstate    = is_diff-fstate
                                         iv_index     = lv_tabix ) ).
      ENDIF.

    ENDLOOP.

    IF mv_unified = abap_true.
      ri_html->add( render_line_unified( ) ). " Release delayed lines
    ENDIF.

  ENDMETHOD.


  METHOD render_line_split.

    DATA: lv_new  TYPE string,
          lv_old  TYPE string,
          lv_mark TYPE string,
          lv_bg   TYPE string.

    CREATE OBJECT ri_html TYPE zcl_abapgit_html.

    " New line
    lv_mark = ` `.
    IF is_diff_line-result IS NOT INITIAL.
      IF iv_fstate = c_fstate-both OR is_diff_line-result = zif_abapgit_definitions=>c_diff-update.
        lv_bg = ' diff_upd'.
        lv_mark = `~`.
      ELSEIF is_diff_line-result = zif_abapgit_definitions=>c_diff-insert.
        lv_bg = ' diff_ins'.
        lv_mark = `+`.
      ENDIF.
    ENDIF.
    lv_new = |<td class="num diff_others" line-num="{ is_diff_line-new_num }"></td>|
          && |<td class="mark diff_others">{ lv_mark }</td>|
          && |<td class="code{ lv_bg } diff_left">{ is_diff_line-new }</td>|.

    " Old line
    CLEAR lv_bg.
    lv_mark = ` `.
    IF is_diff_line-result IS NOT INITIAL.
      IF iv_fstate = c_fstate-both OR is_diff_line-result = zif_abapgit_definitions=>c_diff-update.
        lv_bg = ' diff_upd'.
        lv_mark = `~`.
      ELSEIF is_diff_line-result = zif_abapgit_definitions=>c_diff-delete.
        lv_bg = ' diff_del'.
        lv_mark = `-`.
      ENDIF.
    ENDIF.
    lv_old = |<td class="num diff_others" line-num="{ is_diff_line-old_num }"></td>|
          && |<td class="mark diff_others">{ lv_mark }</td>|
          && |<td class="code{ lv_bg } diff_right">{ is_diff_line-old }</td>|.

    " render line, inverse sides if remote is newer
    ri_html->add( '<tr>' ).

    render_line_split_row(
        ii_html                = ri_html
        iv_filename            = iv_filename
        is_diff_line           = is_diff_line
        iv_index               = iv_index
        iv_fstate              = iv_fstate
        iv_old                 = lv_old
        iv_new                 = lv_new ).

    ri_html->add( '</tr>' ).

  ENDMETHOD.


  METHOD render_line_split_row.

    IF iv_fstate = c_fstate-remote. " Remote file leading changes
      ii_html->add( iv_old ). " local
      ii_html->add( iv_new ). " remote
    ELSE.             " Local leading changes or both were modified
      ii_html->add( iv_new ). " local
      ii_html->add( iv_old ). " remote
    ENDIF.

  ENDMETHOD.


  METHOD render_line_unified.

    FIELD-SYMBOLS <ls_diff_line> LIKE LINE OF mt_delayed_lines.

    CREATE OBJECT ri_html TYPE zcl_abapgit_html.

    " Release delayed subsequent update lines
    IF is_diff_line-result <> zif_abapgit_definitions=>c_diff-update.
      LOOP AT mt_delayed_lines ASSIGNING <ls_diff_line>.
        ri_html->add( '<tr>' ).
        ri_html->add( |<td class="num diff_others" line-num="{ <ls_diff_line>-old_num }"></td>|
                   && |<td class="num diff_others" line-num=""></td>|
                   && |<td class="mark diff_others">-</td>|
                   && |<td class="code diff_del diff_unified">{ <ls_diff_line>-old }</td>| ).
        ri_html->add( '</tr>' ).
      ENDLOOP.
      LOOP AT mt_delayed_lines ASSIGNING <ls_diff_line>.
        ri_html->add( '<tr>' ).
        ri_html->add( |<td class="num diff_others" line-num=""></td>|
                   && |<td class="num diff_others" line-num="{ <ls_diff_line>-new_num }"></td>|
                   && |<td class="mark diff_others">+</td>|
                   && |<td class="code diff_ins diff_others">{ <ls_diff_line>-new }</td>| ).
        ri_html->add( '</tr>' ).
      ENDLOOP.
      CLEAR mt_delayed_lines.
    ENDIF.

    ri_html->add( '<tr>' ).
    CASE is_diff_line-result.
      WHEN zif_abapgit_definitions=>c_diff-update.
        APPEND is_diff_line TO mt_delayed_lines. " Delay output of subsequent updates
      WHEN zif_abapgit_definitions=>c_diff-insert.
        ri_html->add( |<td class="num diff_others" line-num=""></td>|
                   && |<td class="num diff_others" line-num="{ is_diff_line-new_num }"></td>|
                   && |<td class="mark diff_others">+</td>|
                   && |<td class="code diff_ins diff_others">{ is_diff_line-new }</td>| ).
      WHEN zif_abapgit_definitions=>c_diff-delete.
        ri_html->add( |<td class="num diff_others" line-num="{ is_diff_line-old_num }"></td>|
                   && |<td class="num diff_others" line-num=""></td>|
                   && |<td class="mark diff_others">-</td>|
                   && |<td class="code diff_del diff_unified">{ is_diff_line-old }</td>| ).
      WHEN OTHERS. "none
        ri_html->add( |<td class="num diff_others" line-num="{ is_diff_line-old_num }"></td>|
                   && |<td class="num diff_others" line-num="{ is_diff_line-new_num }"></td>|
                   && |<td class="mark diff_others">&nbsp;</td>|
                   && |<td class="code diff_unified">{ is_diff_line-old }</td>| ).
    ENDCASE.
    ri_html->add( '</tr>' ).

  ENDMETHOD.


  METHOD render_scripts.

    CREATE OBJECT ri_html TYPE zcl_abapgit_html.

    ri_html->set_title( cl_abap_typedescr=>describe_by_object_ref( me )->get_relative_name( ) ).

    ri_html->add( 'restoreScrollPosition();' ).
    ri_html->add( 'var gHelper = new DiffHelper({' ).
    ri_html->add( |  seed:        "{ mv_seed }",| ).
    ri_html->add( '  ids: {' ).
    ri_html->add( '    jump:        "jump",' ).
    ri_html->add( '    diffList:    "diff-list",' ).
    ri_html->add( '    filterMenu:  "diff-filter",' ).
    ri_html->add( '  }' ).
    ri_html->add( '});' ).

    ri_html->add( 'addMarginBottom();' ).

    ri_html->add( 'var gGoJumpPalette = new CommandPalette(enumerateJumpAllFiles, {' ).
    ri_html->add( '  toggleKey: "F2",' ).
    ri_html->add( '  hotkeyDescription: "Jump to file ..."' ).
    ri_html->add( '});' ).

    " Feature for selecting ABAP code by column and copy to clipboard
    ri_html->add( 'var columnSelection = new DiffColumnSelection();' ).

  ENDMETHOD.


  METHOD render_table_head.

    CREATE OBJECT ri_html TYPE zcl_abapgit_html.
    ri_html->add( '<thead class="header">' ).
    ri_html->add( '<tr>' ).

    IF mv_unified = abap_true.

      render_table_head_unified( ri_html ).

    ELSE.

      render_table_head_non_unified(
          ii_html = ri_html
          is_diff = is_diff ).

    ENDIF.

    ri_html->add( '</tr>' ).
    ri_html->add( '</thead>' ).

  ENDMETHOD.


  METHOD render_table_head_non_unified.

    ii_html->add( '<th class="num"></th>' ).
    ii_html->add( '<th class="mark"></th>' ).
    ii_html->add( '<th>LOCAL</th>' ).
    ii_html->add( '<th class="num"></th>' ).
    ii_html->add( '<th class="mark"></th>' ).
    ii_html->add( '<th>REMOTE</th>' ).

  ENDMETHOD.


  METHOD render_table_head_unified.

    ii_html->add( '<th class="num">old</th>' ).
    ii_html->add( '<th class="num">new</th>' ).
    ii_html->add( '<th class="mark"></th>' ).
    ii_html->add( '<th>code</th>' ).

  ENDMETHOD.


  METHOD zif_abapgit_gui_event_handler~on_event.

    CASE ii_event->mv_action.
      WHEN c_actions-toggle_unified. " Toggle file diplay

        mv_unified = zcl_abapgit_persistence_user=>get_instance( )->toggle_diff_unified( ).
        set_layout( ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.

      WHEN c_actions-toggle_hidden_chars. " Toggle display of hidden characters

        mv_hidden_chars = boolc( mv_hidden_chars = abap_false ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.

      WHEN OTHERS.

        rs_handled = super->zif_abapgit_gui_event_handler~on_event( ii_event ).

    ENDCASE.

  ENDMETHOD.


  METHOD is_file_requested.

    IF lines( it_files ) = 0.
      rv_is_file_requested = abap_true.
      RETURN.
    ENDIF.

    READ TABLE it_files WITH KEY file-path     = is_status-path
                                 file-filename = is_status-filename
                        TRANSPORTING NO FIELDS.
    rv_is_file_requested = boolc( sy-subrc = 0 ).

  ENDMETHOD.

ENDCLASS.
