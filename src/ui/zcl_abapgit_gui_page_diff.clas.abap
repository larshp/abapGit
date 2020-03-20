CLASS zcl_abapgit_gui_page_diff DEFINITION
  PUBLIC
  INHERITING FROM zcl_abapgit_gui_page
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_abapgit_gui_page_hotkey.

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
      tt_file_diff TYPE STANDARD TABLE OF ty_file_diff
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
      RAISING
        zcx_abapgit_exception.

    METHODS zif_abapgit_gui_event_handler~on_event
        REDEFINITION.
  PROTECTED SECTION.
    DATA mv_unified TYPE abap_bool VALUE abap_true ##NO_TEXT.
    DATA mo_repo TYPE REF TO zcl_abapgit_repo_online.
    DATA mt_diff_files TYPE tt_file_diff .
    METHODS:
      render_content REDEFINITION,
      scripts REDEFINITION,
      add_menu_end
        IMPORTING
          io_menu TYPE REF TO zcl_abapgit_html_toolbar ,
      calculate_diff
        IMPORTING
          is_file   TYPE zif_abapgit_definitions=>ty_file OPTIONAL
          is_object TYPE zif_abapgit_definitions=>ty_item OPTIONAL
        RAISING
          zcx_abapgit_exception,
      add_menu_begin
        IMPORTING
          io_menu TYPE REF TO zcl_abapgit_html_toolbar,
      render_table_head_non_unified
        IMPORTING
          io_html TYPE REF TO  zcl_abapgit_html
          is_diff TYPE ty_file_diff,
      render_beacon_begin_of_row
        IMPORTING
          io_html TYPE REF TO zcl_abapgit_html
          is_diff TYPE ty_file_diff,
      render_diff_head_after_state
        IMPORTING
          io_html TYPE REF TO zcl_abapgit_html
          is_diff TYPE ty_file_diff,
      insert_nav
        RETURNING
          VALUE(rv_insert_nav) TYPE abap_bool,
      render_line_split_middle
        IMPORTING
          io_html                TYPE REF TO zcl_abapgit_html
          iv_patch_line_possible TYPE abap_bool
          iv_filename            TYPE string
          is_diff_line           TYPE zif_abapgit_definitions=>ty_diff
          iv_index               TYPE sy-tabix
        RAISING
          zcx_abapgit_exception,
      build_menu
        RETURNING
          VALUE(ro_menu) TYPE REF TO zcl_abapgit_html_toolbar.

  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF c_actions,
        toggle_unified TYPE string VALUE 'toggle_unified',
      END OF c_actions .

    DATA mt_delayed_lines TYPE zif_abapgit_definitions=>ty_diffs_tt .
    DATA mv_repo_key TYPE zif_abapgit_persistence=>ty_repo-key .
    DATA mv_seed TYPE string .            " Unique page id to bind JS sessionStorage

    METHODS render_diff
      IMPORTING
        !is_diff       TYPE ty_file_diff
      RETURNING
        VALUE(ro_html) TYPE REF TO zcl_abapgit_html
      RAISING
        zcx_abapgit_exception .
    METHODS render_diff_head
      IMPORTING
        !is_diff       TYPE ty_file_diff
      RETURNING
        VALUE(ro_html) TYPE REF TO zcl_abapgit_html .
    METHODS render_table_head
      IMPORTING
        !is_diff       TYPE ty_file_diff
      RETURNING
        VALUE(ro_html) TYPE REF TO zcl_abapgit_html .
    METHODS render_beacon
      IMPORTING
        !is_diff_line  TYPE zif_abapgit_definitions=>ty_diff
        !is_diff       TYPE ty_file_diff
      RETURNING
        VALUE(ro_html) TYPE REF TO zcl_abapgit_html .
    METHODS render_line_split
      IMPORTING
        !is_diff_line  TYPE zif_abapgit_definitions=>ty_diff
        !iv_filename   TYPE string
        !iv_fstate     TYPE char1
        !iv_index      TYPE sy-tabix
      RETURNING
        VALUE(ro_html) TYPE REF TO zcl_abapgit_html
      RAISING
        zcx_abapgit_exception .
    METHODS render_line_unified
      IMPORTING
        !is_diff_line  TYPE zif_abapgit_definitions=>ty_diff OPTIONAL
      RETURNING
        VALUE(ro_html) TYPE REF TO zcl_abapgit_html .
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
        io_menu TYPE REF TO zcl_abapgit_html_toolbar .
    METHODS render_lines
      IMPORTING
        is_diff        TYPE ty_file_diff
      RETURNING
        VALUE(ro_html) TYPE REF TO zcl_abapgit_html
      RAISING
        zcx_abapgit_exception.

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

      " File types
      IF lines( lt_types ) > 1.
        lo_sub_filter->add( iv_txt = 'TYPE' iv_typ = zif_abapgit_html=>c_action_type-separator ).
        LOOP AT lt_types ASSIGNING <lv_i>.
          lo_sub_filter->add( iv_txt = <lv_i>
                       iv_typ = zif_abapgit_html=>c_action_type-onclick
                       iv_aux = 'type'
                       iv_chk = abap_true ).
        ENDLOOP.
      ENDIF.

      " Changed by
      IF lines( lt_users ) > 1.
        lo_sub_filter->add( iv_txt = 'CHANGED BY' iv_typ = zif_abapgit_html=>c_action_type-separator ).
        LOOP AT lt_users ASSIGNING <lv_i>.
          lo_sub_filter->add( iv_txt = <lv_i>
                       iv_typ = zif_abapgit_html=>c_action_type-onclick
                       iv_aux = 'changed-by'
                       iv_chk = abap_true ).
        ENDLOOP.
      ENDIF.

      io_menu->add( iv_txt = 'Filter'
                    io_sub = lo_sub_filter ) ##NO_TEXT.
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
                  io_sub = lo_sub_jump ) ##NO_TEXT.

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
      <ls_diff>-changed_by = to_lower( zcl_abapgit_objects=>changed_by( <ls_local>-item ) ).
    ENDIF.

    " Extension
    IF <ls_local>-file-filename IS NOT INITIAL.
      <ls_diff>-type = reverse( <ls_local>-file-filename ).
    ELSE.
      <ls_diff>-type = reverse( <ls_remote>-filename ).
    ENDIF.

    FIND FIRST OCCURRENCE OF '.' IN <ls_diff>-type MATCH OFFSET lv_offs.
    <ls_diff>-type = reverse( substring( val = <ls_diff>-type len = lv_offs ) ).
    IF <ls_diff>-type <> 'xml' AND <ls_diff>-type <> 'abap'.
      <ls_diff>-type = 'other'.
    ENDIF.

    IF <ls_diff>-type = 'other'
       AND is_binary( iv_d1 = <ls_remote>-data iv_d2 = <ls_local>-file-data ) = abap_true.
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


  METHOD constructor.

    DATA: lv_ts TYPE timestamp.

    super->constructor( ).
    ms_control-page_title = 'DIFF'.
    mv_unified            = zcl_abapgit_persistence_user=>get_instance( )->get_diff_unified( ).
    mv_repo_key           = iv_key.
    mo_repo              ?= zcl_abapgit_repo_srv=>get_instance( )->get( iv_key ).

    GET TIME STAMP FIELD lv_ts.
    mv_seed = |diff{ lv_ts }|. " Generate based on time

    ASSERT is_file IS INITIAL OR is_object IS INITIAL. " just one passed

    calculate_diff(
        is_file   = is_file
        is_object = is_object ).

    IF lines( mt_diff_files ) = 0.
      zcx_abapgit_exception=>raise( 'PAGE_DIFF ERROR: No diff files found' ).
    ENDIF.

    ms_control-page_menu = build_menu( ).

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


  METHOD render_beacon.

    DATA: lv_beacon  TYPE string,
          lt_beacons TYPE zif_abapgit_definitions=>ty_string_tt.

    CREATE OBJECT ro_html.

    IF is_diff_line-beacon > 0.
      lt_beacons = is_diff-o_diff->get_beacons( ).
      READ TABLE lt_beacons INTO lv_beacon INDEX is_diff_line-beacon.
    ELSE.
      lv_beacon = '---'.
    ENDIF.

    ro_html->add( '<thead class="nav_line">' ).
    ro_html->add( '<tr>' ).

    render_beacon_begin_of_row(
        io_html = ro_html
        is_diff = is_diff ).

    IF mv_unified = abap_true.
      ro_html->add( '<th class="num"></th>' ).
      ro_html->add( '<th class="mark"></th>' ).
      ro_html->add( |<th>@@ { is_diff_line-new_num } @@ { lv_beacon }</th>| ).
    ELSE.
      ro_html->add( |<th colspan="6">@@ { is_diff_line-new_num } @@ { lv_beacon }</th>| ).
    ENDIF.

    ro_html->add( '</tr>' ).
    ro_html->add( '</thead>' ).

  ENDMETHOD.


  METHOD render_content.

    DATA: ls_diff_file LIKE LINE OF mt_diff_files,
          li_progress  TYPE REF TO zif_abapgit_progress.


    CREATE OBJECT ro_html.

    li_progress = zcl_abapgit_progress=>get_instance( lines( mt_diff_files ) ).

    ro_html->add( |<div id="diff-list" data-repo-key="{ mv_repo_key }">| ).
    ro_html->add( zcl_abapgit_gui_chunk_lib=>render_js_error_banner( ) ).
    LOOP AT mt_diff_files INTO ls_diff_file.
      li_progress->show(
        iv_current = sy-tabix
        iv_text    = |Render Diff - { ls_diff_file-filename }| ).

      ro_html->add( render_diff( ls_diff_file ) ).
    ENDLOOP.
    IF sy-subrc <> 0.
      ro_html->add( |No more diffs| ).
    ENDIF.
    ro_html->add( '</div>' ).

  ENDMETHOD.


  METHOD render_diff.

    CREATE OBJECT ro_html.

    ro_html->add( |<div class="diff" data-type="{ is_diff-type
      }" data-changed-by="{ is_diff-changed_by
      }" data-file="{ is_diff-path && is_diff-filename }">| ). "#EC NOTEXT
    ro_html->add( render_diff_head( is_diff ) ).

    " Content
    IF is_diff-type <> 'binary'.
      ro_html->add( '<div class="diff_content">' ).         "#EC NOTEXT
      ro_html->add( |<table class="diff_tab syntax-hl" id={ is_diff-filename }>| ). "#EC NOTEXT
      ro_html->add( render_table_head( is_diff ) ).
      ro_html->add( render_lines( is_diff ) ).
      ro_html->add( '</table>' ).                           "#EC NOTEXT
    ELSE.
      ro_html->add( '<div class="diff_content paddings center grey">' ). "#EC NOTEXT
      ro_html->add( 'The content seems to be binary.' ).    "#EC NOTEXT
      ro_html->add( 'Cannot display as diff.' ).            "#EC NOTEXT
    ENDIF.
    ro_html->add( '</div>' ).                               "#EC NOTEXT

    ro_html->add( '</div>' ).                               "#EC NOTEXT

  ENDMETHOD.


  METHOD render_diff_head.

    DATA: ls_stats    TYPE zif_abapgit_definitions=>ty_count,
          lv_adt_link TYPE string.

    CREATE OBJECT ro_html.

    ro_html->add( '<div class="diff_head">' ).              "#EC NOTEXT

    ro_html->add_icon(
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

      ro_html->add( |<span class="diff_banner diff_ins">+ { ls_stats-insert }</span>| ).
      ro_html->add( |<span class="diff_banner diff_del">- { ls_stats-delete }</span>| ).
      ro_html->add( |<span class="diff_banner diff_upd">~ { ls_stats-update }</span>| ).
    ENDIF.

    " no links for nonexistent or deleted objects
    IF is_diff-lstate IS NOT INITIAL AND is_diff-lstate <> 'D'.
      lv_adt_link = zcl_abapgit_html=>a(
        iv_txt = |{ is_diff-path }{ is_diff-filename }|
        iv_typ = zif_abapgit_html=>c_action_type-sapevent
        iv_act = |jump?TYPE={ is_diff-obj_type }&NAME={ is_diff-obj_name }| ).
    ENDIF.

    IF lv_adt_link IS NOT INITIAL.
      ro_html->add( |<span class="diff_name">{ lv_adt_link }</span>| ). "#EC NOTEXT
    ELSE.
      ro_html->add( |<span class="diff_name">{ is_diff-path }{ is_diff-filename }</span>| ). "#EC NOTEXT
    ENDIF.

    ro_html->add( zcl_abapgit_gui_chunk_lib=>render_item_state(
      iv_lstate = is_diff-lstate
      iv_rstate = is_diff-rstate ) ).

    render_diff_head_after_state(
        io_html = ro_html
        is_diff = is_diff ).

    IF is_diff-fstate = c_fstate-both AND mv_unified = abap_true.
      ro_html->add( '<span class="attention pad-sides">Attention: Unified mode'
                 && ' highlighting for MM assumes local file is newer ! </span>' ). "#EC NOTEXT
    ENDIF.

    ro_html->add( |<span class="diff_changed_by">last change by: <span class="user">{
      is_diff-changed_by }</span></span>| ).

    ro_html->add( '</div>' ).                               "#EC NOTEXT

  ENDMETHOD.


  METHOD render_lines.

    DATA: lo_highlighter TYPE REF TO zcl_abapgit_syntax_highlighter,
          lt_diffs       TYPE zif_abapgit_definitions=>ty_diffs_tt,
          lv_insert_nav  TYPE abap_bool,
          lv_tabix       TYPE syst-tabix.

    FIELD-SYMBOLS <ls_diff>  LIKE LINE OF lt_diffs.

    lo_highlighter = zcl_abapgit_syntax_highlighter=>create( is_diff-filename ).
    CREATE OBJECT ro_html.

    lt_diffs = is_diff-o_diff->get( ).

    lv_insert_nav = insert_nav( ).

    LOOP AT lt_diffs ASSIGNING <ls_diff>.

      lv_tabix = sy-tabix.

      IF <ls_diff>-short = abap_false.
        lv_insert_nav = abap_true.
        CONTINUE.
      ENDIF.

      IF lv_insert_nav = abap_true. " Insert separator line with navigation
        ro_html->add( render_beacon( is_diff_line = <ls_diff> is_diff = is_diff ) ).
        lv_insert_nav = abap_false.
      ENDIF.

      IF lo_highlighter IS BOUND.
        <ls_diff>-new = lo_highlighter->process_line( <ls_diff>-new ).
        <ls_diff>-old = lo_highlighter->process_line( <ls_diff>-old ).
      ELSE.
        <ls_diff>-new = escape( val = <ls_diff>-new format = cl_abap_format=>e_html_attr ).
        <ls_diff>-old = escape( val = <ls_diff>-old format = cl_abap_format=>e_html_attr ).
      ENDIF.

      CONDENSE <ls_diff>-new_num. "get rid of leading spaces
      CONDENSE <ls_diff>-old_num.

      IF mv_unified = abap_true.
        ro_html->add( render_line_unified( is_diff_line = <ls_diff> ) ).
      ELSE.
        ro_html->add( render_line_split( is_diff_line = <ls_diff>
                                         iv_filename  = zcl_abapgit_gui_page_patch=>get_patch_id( is_diff )
                                         iv_fstate    = is_diff-fstate
                                         iv_index     = lv_tabix ) ).
      ENDIF.

    ENDLOOP.

    IF mv_unified = abap_true.
      ro_html->add( render_line_unified( ) ). " Release delayed lines
    ENDIF.

  ENDMETHOD.


  METHOD render_line_split.

    DATA: lv_new                 TYPE string,
          lv_old                 TYPE string,
          lv_mark                TYPE string,
          lv_bg                  TYPE string,
          lv_patch_line_possible TYPE abap_bool.

    CREATE OBJECT ro_html.

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

    IF lv_mark <> ` `.
      lv_patch_line_possible = abap_true.
    ENDIF.

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

    IF lv_mark <> ` `.
      lv_patch_line_possible = abap_true.
    ENDIF.

    " render line, inverse sides if remote is newer
    ro_html->add( '<tr>' ).                                 "#EC NOTEXT

    render_line_split_middle(
        io_html                = ro_html
        iv_patch_line_possible = lv_patch_line_possible
        iv_filename            = iv_filename
        is_diff_line           = is_diff_line
        iv_index               = iv_index  ).

    IF iv_fstate = c_fstate-remote. " Remote file leading changes
      ro_html->add( lv_old ). " local
      ro_html->add( lv_new ). " remote
    ELSE.             " Local leading changes or both were modified
      ro_html->add( lv_new ). " local
      ro_html->add( lv_old ). " remote
    ENDIF.

    ro_html->add( '</tr>' ).                                "#EC NOTEXT

  ENDMETHOD.


  METHOD render_line_unified.

    FIELD-SYMBOLS <ls_diff_line> LIKE LINE OF mt_delayed_lines.

    CREATE OBJECT ro_html.

    " Release delayed subsequent update lines
    IF is_diff_line-result <> zif_abapgit_definitions=>c_diff-update.
      LOOP AT mt_delayed_lines ASSIGNING <ls_diff_line>.
        ro_html->add( '<tr>' ).                             "#EC NOTEXT
        ro_html->add( |<td class="num diff_others" line-num="{ <ls_diff_line>-old_num }"></td>|
                   && |<td class="num diff_others" line-num=""></td>|
                   && |<td class="mark diff_others">-</td>|
                   && |<td class="code diff_del diff_unified">{ <ls_diff_line>-old }</td>| ).
        ro_html->add( '</tr>' ).                            "#EC NOTEXT
      ENDLOOP.
      LOOP AT mt_delayed_lines ASSIGNING <ls_diff_line>.
        ro_html->add( '<tr>' ).                             "#EC NOTEXT
        ro_html->add( |<td class="num diff_others" line-num=""></td>|
                   && |<td class="num diff_others" line-num="{ <ls_diff_line>-new_num }"></td>|
                   && |<td class="mark diff_others">+</td>|
                   && |<td class="code diff_ins diff_others">{ <ls_diff_line>-new }</td>| ).
        ro_html->add( '</tr>' ).                            "#EC NOTEXT
      ENDLOOP.
      CLEAR mt_delayed_lines.
    ENDIF.

    ro_html->add( '<tr>' ).                                 "#EC NOTEXT
    CASE is_diff_line-result.
      WHEN zif_abapgit_definitions=>c_diff-update.
        APPEND is_diff_line TO mt_delayed_lines. " Delay output of subsequent updates
      WHEN zif_abapgit_definitions=>c_diff-insert.
        ro_html->add( |<td class="num diff_others" line-num=""></td>|
                   && |<td class="num diff_others" line-num="{ is_diff_line-new_num }"></td>|
                   && |<td class="mark diff_others">+</td>|
                   && |<td class="code diff_ins diff_others">{ is_diff_line-new }</td>| ).
      WHEN zif_abapgit_definitions=>c_diff-delete.
        ro_html->add( |<td class="num diff_others" line-num="{ is_diff_line-old_num }"></td>|
                   && |<td class="num diff_others" line-num=""></td>|
                   && |<td class="mark diff_others">-</td>|
                   && |<td class="code diff_del diff_unified">{ is_diff_line-old }</td>| ).
      WHEN OTHERS. "none
        ro_html->add( |<td class="num diff_others" line-num="{ is_diff_line-old_num }"></td>|
                   && |<td class="num diff_others" line-num="{ is_diff_line-new_num }"></td>|
                   && |<td class="mark diff_others">&nbsp;</td>|
                   && |<td class="code diff_unified">{ is_diff_line-old }</td>| ).
    ENDCASE.
    ro_html->add( '</tr>' ).                                "#EC NOTEXT

  ENDMETHOD.


  METHOD render_table_head.

    CREATE OBJECT ro_html.

    ro_html->add( '<thead class="header">' ).               "#EC NOTEXT
    ro_html->add( '<tr>' ).                                 "#EC NOTEXT

    IF mv_unified = abap_true.
      ro_html->add( '<th class="num">old</th>' ).           "#EC NOTEXT
      ro_html->add( '<th class="num">new</th>' ).           "#EC NOTEXT
      ro_html->add( '<th class="mark"></th>' ).             "#EC NOTEXT
      ro_html->add( '<th>code</th>' ).                      "#EC NOTEXT
    ELSE.

      render_table_head_non_unified(
          io_html = ro_html
          is_diff = is_diff ).

      ro_html->add( '<th class="num"></th>' ).              "#EC NOTEXT
      ro_html->add( '<th class="mark"></th>' ).             "#EC NOTEXT
      ro_html->add( '<th>LOCAL</th>' ).                     "#EC NOTEXT
      ro_html->add( '<th class="num"></th>' ).              "#EC NOTEXT
      ro_html->add( '<th class="mark"></th>' ).             "#EC NOTEXT
      ro_html->add( '<th>REMOTE</th>' ).                    "#EC NOTEXT

    ENDIF.

    ro_html->add( '</tr>' ).                                "#EC NOTEXT
    ro_html->add( '</thead>' ).                             "#EC NOTEXT

  ENDMETHOD.


  METHOD scripts.

    ro_html = super->scripts( ).

    ro_html->add( 'restoreScrollPosition();' ).
    ro_html->add( 'var gHelper = new DiffHelper({' ).
    ro_html->add( |  seed:        "{ mv_seed }",| ).
    ro_html->add( '  ids: {' ).
    ro_html->add( '    jump:        "jump",' ).
    ro_html->add( '    diffList:    "diff-list",' ).
    ro_html->add( '    filterMenu:  "diff-filter",' ).
    ro_html->add( '  }' ).
    ro_html->add( '});' ).

    ro_html->add( 'addMarginBottom();' ).

    ro_html->add( 'var gGoJumpPalette = new CommandPalette(enumerateJumpAllFiles, {' ).
    ro_html->add( '  toggleKey: "F2",' ).
    ro_html->add( '  hotkeyDescription: "Jump to file ..."' ).
    ro_html->add( '});' ).

    " Feature for selecting ABAP code by column and copy to clipboard
    ro_html->add( 'var columnSelection = new DiffColumnSelection();' ).

  ENDMETHOD.


  METHOD zif_abapgit_gui_event_handler~on_event.

    CASE iv_action.
      WHEN c_actions-toggle_unified. " Toggle file diplay

        mv_unified = zcl_abapgit_persistence_user=>get_instance( )->toggle_diff_unified( ).
        ev_state   = zcl_abapgit_gui=>c_event_state-re_render.

      WHEN OTHERS.

        super->zif_abapgit_gui_event_handler~on_event(
           EXPORTING
             iv_action    = iv_action
             iv_prev_page = iv_prev_page
             iv_getdata   = iv_getdata
             it_postdata  = it_postdata
           IMPORTING
             ei_page      = ei_page
             ev_state     = ev_state ).

    ENDCASE.

  ENDMETHOD.


  METHOD zif_abapgit_gui_page_hotkey~get_hotkey_actions.

    DATA: ls_hotkey_action LIKE LINE OF rt_hotkey_actions.

    ls_hotkey_action-name   = |Stage changes|.
    ls_hotkey_action-action = |stagePatch|.
    ls_hotkey_action-hotkey = |s|.
    INSERT ls_hotkey_action INTO TABLE rt_hotkey_actions.

    ls_hotkey_action-name   = |Refresh local|.
    ls_hotkey_action-action = |refreshLocal|.
    ls_hotkey_action-hotkey = |r|.
    INSERT ls_hotkey_action INTO TABLE rt_hotkey_actions.

  ENDMETHOD.


  METHOD calculate_diff.

    DATA: lt_remote TYPE zif_abapgit_definitions=>ty_files_tt,
          lt_local  TYPE zif_abapgit_definitions=>ty_files_item_tt,
          lt_status TYPE zif_abapgit_definitions=>ty_results_tt.

    FIELD-SYMBOLS: <ls_status> LIKE LINE OF lt_status.

    CLEAR: mt_diff_files.

    lt_remote = mo_repo->get_files_remote( ).
    lt_local  = mo_repo->get_files_local( ).
    mo_repo->reset_status( ).
    lt_status = mo_repo->status( ).

    IF is_file IS NOT INITIAL.        " Diff for one file

      READ TABLE lt_status ASSIGNING <ls_status>
        WITH KEY path = is_file-path filename = is_file-filename.

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
        append_diff( it_remote = lt_remote
                     it_local  = lt_local
                     is_status = <ls_status> ).
      ENDLOOP.

    ENDIF.

  ENDMETHOD.


  METHOD add_menu_end.

    io_menu->add( iv_txt = 'Split/Unified view'
                  iv_act = c_actions-toggle_unified ) ##NO_TEXT.

  ENDMETHOD.


  METHOD add_menu_begin.

  ENDMETHOD.


  METHOD render_table_head_non_unified.

  ENDMETHOD.


  METHOD render_beacon_begin_of_row.

    io_html->add( '<th class="num"></th>' ).

  ENDMETHOD.


  METHOD render_diff_head_after_state.

  ENDMETHOD.


  METHOD insert_nav.

  ENDMETHOD.


  METHOD render_line_split_middle.

  ENDMETHOD.

ENDCLASS.
