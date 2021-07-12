CLASS zcl_abapgit_background_push_fi DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_abapgit_background.
  PROTECTED SECTION.

    CONSTANTS:
      BEGIN OF c_settings,
        name  TYPE string VALUE 'NAME',
        email TYPE string VALUE 'EMAIL',
      END OF c_settings.
    DATA mi_log TYPE REF TO zif_abapgit_log.

    METHODS build_comment
      IMPORTING
        !is_files         TYPE zif_abapgit_definitions=>ty_stage_files
      RETURNING
        VALUE(rv_comment) TYPE string.
    METHODS push_fixed
      IMPORTING
        !io_repo  TYPE REF TO zcl_abapgit_repo_online
        !iv_name  TYPE string
        !iv_email TYPE string
      RAISING
        zcx_abapgit_exception.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_abapgit_background_push_fi IMPLEMENTATION.


  METHOD build_comment.

    DATA: lt_objects TYPE STANDARD TABLE OF string WITH DEFAULT KEY,
          lv_str     TYPE string.

    FIELD-SYMBOLS: <ls_local> LIKE LINE OF is_files-local.

    LOOP AT is_files-local ASSIGNING <ls_local>.
      lv_str = |{ <ls_local>-item-obj_type } { <ls_local>-item-obj_name }|.
      APPEND lv_str TO lt_objects.
    ENDLOOP.

    SORT lt_objects AS TEXT.
    DELETE ADJACENT DUPLICATES FROM lt_objects.

    IF lines( lt_objects ) = 1.
      rv_comment = |BG: { lv_str }|.
    ELSE.
      rv_comment = 'BG: Multiple objects'.
      LOOP AT lt_objects INTO lv_str.
        CONCATENATE rv_comment zif_abapgit_definitions=>c_newline lv_str INTO rv_comment.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.


  METHOD push_fixed.

    DATA: ls_comment TYPE zif_abapgit_definitions=>ty_comment,
          ls_files   TYPE zif_abapgit_definitions=>ty_stage_files,
          lo_stage   TYPE REF TO zcl_abapgit_stage.

    FIELD-SYMBOLS: <ls_local>  LIKE LINE OF ls_files-local,
                   <ls_remote> LIKE LINE OF ls_files-remote.

    ls_files = zcl_abapgit_factory=>get_stage_logic( )->get( io_repo ).
    ASSERT lines( ls_files-local ) > 0
        OR lines( ls_files-remote ) > 0.

    CREATE OBJECT lo_stage.

    LOOP AT ls_files-local ASSIGNING <ls_local>.
      mi_log->add_info( |stage: { <ls_local>-file-path } { <ls_local>-file-filename }| ).
      lo_stage->add( iv_path     = <ls_local>-file-path
                     iv_filename = <ls_local>-file-filename
                     iv_data     = <ls_local>-file-data ).
    ENDLOOP.

    LOOP AT ls_files-remote ASSIGNING <ls_remote>.

      mi_log->add_info( |removed: { <ls_remote>-path } { <ls_remote>-filename }| ).

      lo_stage->rm( iv_path     = <ls_remote>-path
                    iv_filename = <ls_remote>-filename ).

    ENDLOOP.

    ls_comment-committer-name  = iv_name.
    ls_comment-committer-email = iv_email.
    ls_comment-comment         = build_comment( ls_files ).

    io_repo->push( is_comment = ls_comment
                   io_stage   = lo_stage ).

  ENDMETHOD.


  METHOD zif_abapgit_background~get_description.

    rv_description = 'Automatic push, fixed author'.

  ENDMETHOD.


  METHOD zif_abapgit_background~get_settings.

    DATA: ls_setting LIKE LINE OF ct_settings.

    READ TABLE ct_settings WITH KEY key = c_settings-name INTO ls_setting.
    IF sy-subrc <> 0.
      ls_setting-key = c_settings-name.
      ls_setting-value = 'foobar'.
      APPEND ls_setting TO ct_settings.
    ENDIF.

    READ TABLE ct_settings WITH KEY key = c_settings-email INTO ls_setting.
    IF sy-subrc <> 0.
      ls_setting-key = c_settings-email.
      ls_setting-value = 'foobar@localhost'.
      APPEND ls_setting TO ct_settings.
    ENDIF.

  ENDMETHOD.


  METHOD zif_abapgit_background~run.

    DATA: ls_files   TYPE zif_abapgit_definitions=>ty_stage_files,
          ls_setting LIKE LINE OF it_settings,
          lv_name    TYPE string,
          lv_email   TYPE string.

    mi_log = ii_log.
    ls_files = zcl_abapgit_factory=>get_stage_logic( )->get( io_repo ).

    IF lines( ls_files-local ) = 0 AND lines( ls_files-remote ) = 0.
      ii_log->add_info( 'Nothing to stage' ).
      RETURN.
    ENDIF.

    READ TABLE it_settings WITH KEY key = c_settings-name INTO ls_setting. "#EC CI_SUBRC
    lv_name = ls_setting-value.

    READ TABLE it_settings WITH KEY key = c_settings-email INTO ls_setting. "#EC CI_SUBRC
    lv_email = ls_setting-value.

    push_fixed(
      io_repo  = io_repo
      iv_name  = lv_name
      iv_email = lv_email ).

  ENDMETHOD.
ENDCLASS.
