CLASS zcl_abapgit_apack_helper DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS are_dependencies_met
      IMPORTING
        !it_dependencies TYPE zif_abapgit_apack_definitions=>tt_dependencies
      RETURNING
        VALUE(rv_status) TYPE zif_abapgit_definitions=>ty_yes_no
      RAISING
        zcx_abapgit_exception.

    CLASS-METHODS dependencies_popup
      IMPORTING
        !it_dependencies TYPE zif_abapgit_apack_definitions=>tt_dependencies
      RAISING
        zcx_abapgit_exception.

    CLASS-METHODS conv_str_to_version
      IMPORTING
        !iv_version       TYPE csequence
      RETURNING
        VALUE(rs_version) TYPE zif_abapgit_definitions=>ty_version
      RAISING
        zcx_abapgit_exception.

    CLASS-METHODS check_dependant_version
      IMPORTING
        !is_current   TYPE zif_abapgit_definitions=>ty_version
        !is_dependant TYPE zif_abapgit_definitions=>ty_version
      RAISING
        zcx_abapgit_exception.

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_manifest_declaration,
        clsname  TYPE seometarel-clsname,
        devclass TYPE devclass,
      END OF ty_manifest_declaration,
      tt_manifest_declaration TYPE STANDARD TABLE OF ty_manifest_declaration WITH NON-UNIQUE DEFAULT KEY.

    TYPES:
      BEGIN OF ty_dependency_status,
        met(1) TYPE c.
        INCLUDE TYPE zif_abapgit_apack_definitions=>ty_dependency.
    TYPES: END OF ty_dependency_status,
      tt_dependency_status TYPE STANDARD TABLE OF ty_dependency_status WITH NON-UNIQUE DEFAULT KEY.

    CLASS-METHODS get_dependencies_met_status
      IMPORTING
        !it_dependencies TYPE zif_abapgit_apack_definitions=>tt_dependencies
      RETURNING
        VALUE(rt_status) TYPE tt_dependency_status
      RAISING
        zcx_abapgit_exception.

    CLASS-METHODS get_installed_packages
      RETURNING
        VALUE(rt_packages) TYPE zif_abapgit_apack_definitions=>tt_descriptor
      RAISING
        zcx_abapgit_exception.

    CLASS-METHODS show_dependencies_popup
      IMPORTING
        !it_dependencies TYPE tt_dependency_status
      RAISING
        zcx_abapgit_exception.

ENDCLASS.



CLASS zcl_abapgit_apack_helper IMPLEMENTATION.


  METHOD are_dependencies_met.

    DATA: lt_dependencies_status TYPE tt_dependency_status.

    IF it_dependencies IS INITIAL.
      rv_status = 'Y'.
      RETURN.
    ENDIF.

    lt_dependencies_status = get_dependencies_met_status( it_dependencies ).

    LOOP AT lt_dependencies_status TRANSPORTING NO FIELDS WHERE met <> 'Y'.
      EXIT.
    ENDLOOP.

    IF sy-subrc = 0.
      rv_status = 'N'.
    ELSE.
      rv_status = 'Y'.
    ENDIF.

  ENDMETHOD.


  METHOD dependencies_popup.

    DATA: lt_met_status TYPE tt_dependency_status.

    lt_met_status = get_dependencies_met_status( it_dependencies ).

    show_dependencies_popup( lt_met_status ).

  ENDMETHOD.


  METHOD conv_str_to_version.

    DATA: lt_segments TYPE STANDARD TABLE OF string,
          lt_parts    TYPE STANDARD TABLE OF string,
          lv_segment  TYPE string.

    SPLIT iv_version AT '-' INTO TABLE lt_segments.

    READ TABLE lt_segments INTO lv_segment INDEX 1. " Version
    IF sy-subrc <> 0.   " No version
      RETURN.
    ENDIF.

    SPLIT lv_segment AT '.' INTO TABLE lt_parts.

    LOOP AT lt_parts INTO lv_segment.

      TRY.
          CASE sy-tabix.
            WHEN 1.
              rs_version-major = lv_segment.
            WHEN 2.
              rs_version-minor = lv_segment.
            WHEN 3.
              rs_version-patch = lv_segment.
          ENDCASE.
        CATCH cx_sy_conversion_no_number.
          zcx_abapgit_exception=>raise( 'Incorrect format for Semantic Version' ).
      ENDTRY.

    ENDLOOP.

    READ TABLE lt_segments INTO lv_segment INDEX 2. " Pre-release Version
    IF sy-subrc <> 0.   " No version
      RETURN.
    ENDIF.

    SPLIT lv_segment AT '.' INTO TABLE lt_parts.

    LOOP AT lt_parts INTO lv_segment.

      CASE sy-tabix.
        WHEN 1.
          rs_version-prerelase = lv_segment.
          TRANSLATE rs_version-prerelase TO LOWER CASE.
        WHEN 2.
          rs_version-prerelase_patch = lv_segment.
      ENDCASE.

    ENDLOOP.

    IF rs_version-prerelase <> 'rc' AND rs_version-prerelase <> 'beta' AND rs_version-prerelase <> 'alpha'.
      zcx_abapgit_exception=>raise( 'Incorrect format for Semantic Version' ).
    ENDIF.

  ENDMETHOD.


  METHOD check_dependant_version.

    CONSTANTS: lc_message TYPE string VALUE 'Current version is older than required'.

    IF is_dependant-major > is_current-major.
      zcx_abapgit_exception=>raise( lc_message ).
    ELSEIF is_dependant-major < is_current-major.
      RETURN.
    ENDIF.

    IF is_dependant-minor > is_current-minor.
      zcx_abapgit_exception=>raise( lc_message ).
    ELSEIF is_dependant-minor < is_current-minor.
      RETURN.
    ENDIF.

    IF is_dependant-patch > is_current-patch.
      zcx_abapgit_exception=>raise( lc_message ).
    ELSEIF is_dependant-patch < is_current-patch.
      RETURN.
    ENDIF.

    IF is_current-prerelase IS INITIAL.
      RETURN.
    ENDIF.

    CASE is_current-prerelase.
      WHEN 'rc'.
        IF is_dependant-prerelase = ''.
          zcx_abapgit_exception=>raise( lc_message ).
        ENDIF.

      WHEN 'beta'.
        IF is_dependant-prerelase = '' OR is_dependant-prerelase = 'rc'.
          zcx_abapgit_exception=>raise( lc_message ).
        ENDIF.

      WHEN 'alpha'.
        IF is_dependant-prerelase = '' OR is_dependant-prerelase = 'rc' OR is_dependant-prerelase = 'beta'.
          zcx_abapgit_exception=>raise( lc_message ).
        ENDIF.

    ENDCASE.

    IF is_dependant-prerelase = is_current-prerelase AND is_dependant-prerelase_patch > is_current-prerelase_patch.
      zcx_abapgit_exception=>raise( lc_message ).
    ENDIF.

  ENDMETHOD.


  METHOD get_dependencies_met_status.

    DATA: lt_installed_packages TYPE zif_abapgit_apack_definitions=>tt_descriptor,
          ls_installed_package  TYPE zif_abapgit_apack_definitions=>ty_descriptor,
          ls_dependecy          TYPE zif_abapgit_apack_definitions=>ty_dependency,
          ls_dependecy_popup    TYPE ty_dependency_status.

    IF it_dependencies IS INITIAL.
      RETURN.
    ENDIF.

    lt_installed_packages = get_installed_packages( ).

    LOOP AT it_dependencies INTO ls_dependecy.
      CLEAR: ls_dependecy_popup.

      MOVE-CORRESPONDING ls_dependecy TO ls_dependecy_popup.

      READ TABLE lt_installed_packages INTO ls_installed_package
        WITH KEY group_id    = ls_dependecy-group_id
                 artifact_id = ls_dependecy-artifact_id.
      IF sy-subrc <> 0.
        ls_dependecy_popup-met = 'N'.
      ELSE.
        TRY.
            check_dependant_version( is_current   = ls_installed_package-sem_version
                                     is_dependant = ls_dependecy-sem_version ).
            ls_dependecy_popup-met = 'Y'.
          CATCH zcx_abapgit_exception.
            ls_dependecy_popup-met = 'P'.
        ENDTRY.
      ENDIF.

      INSERT ls_dependecy_popup INTO TABLE rt_status.

    ENDLOOP.

  ENDMETHOD.


  METHOD get_installed_packages.

    DATA: lo_apack_reader            TYPE REF TO zcl_abapgit_apack_reader,
          lt_manifest_implementation TYPE tt_manifest_declaration,
          ls_manifest_implementation TYPE ty_manifest_declaration,
          lo_manifest_provider       TYPE REF TO object,
          ls_descriptor              TYPE zif_abapgit_apack_definitions=>ty_descriptor.

    SELECT seometarel~clsname tadir~devclass FROM seometarel "#EC CI_NOORDER
       INNER JOIN tadir ON seometarel~clsname = tadir~obj_name "#EC CI_BUFFJOIN
       INTO TABLE lt_manifest_implementation
       WHERE tadir~pgmid = 'R3TR'
         AND tadir~object = 'CLAS'
         AND seometarel~version = '1'
         AND ( seometarel~refclsname = 'ZIF_APACK_MANIFEST' OR seometarel~refclsname = 'IF_APACK_MANIFEST' ).

    LOOP AT lt_manifest_implementation INTO ls_manifest_implementation.
      CLEAR: lo_manifest_provider, lo_apack_reader.

      TRY.
          CREATE OBJECT lo_manifest_provider TYPE (ls_manifest_implementation-clsname).
        CATCH cx_sy_create_object_error.
          CLEAR: lo_manifest_provider.
      ENDTRY.

      IF lo_manifest_provider IS NOT BOUND.
        CONTINUE.
      ENDIF.

      lo_apack_reader = zcl_abapgit_apack_reader=>create_instance( ls_manifest_implementation-devclass ).
      lo_apack_reader->copy_manifest_descriptor( io_manifest_provider = lo_manifest_provider ).
      ls_descriptor = lo_apack_reader->get_manifest_descriptor( ).

      IF ls_descriptor IS NOT INITIAL.
        INSERT ls_descriptor INTO TABLE rt_packages.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD show_dependencies_popup.

    TYPES:
      BEGIN OF lty_color_line,
        exception(1) TYPE c,
        color        TYPE lvc_t_scol.
        INCLUDE TYPE ty_dependency_status.
    TYPES: t_hyperlink  TYPE salv_t_int4_column,
      END OF lty_color_line.

    TYPES: lty_color_tab TYPE STANDARD TABLE OF lty_color_line WITH DEFAULT KEY.

    DATA: lo_alv                 TYPE REF TO cl_salv_table,
          lo_functional_settings TYPE REF TO cl_salv_functional_settings,
          lo_hyperlinks          TYPE REF TO cl_salv_hyperlinks,
          lo_column              TYPE REF TO cl_salv_column,
          lo_column_table        TYPE REF TO cl_salv_column_table,
          lo_columns             TYPE REF TO cl_salv_columns_table,
          lt_columns             TYPE salv_t_column_ref,
          ls_column              LIKE LINE OF lt_columns,
          lt_color_table         TYPE lty_color_tab,
          lt_color_negative      TYPE lvc_t_scol,
          lt_color_normal        TYPE lvc_t_scol,
          lt_color_positive      TYPE lvc_t_scol,
          ls_color               TYPE lvc_s_scol,
          lv_handle              TYPE i,
          ls_hyperlink           TYPE salv_s_int4_column,
          lv_hyperlink           TYPE service_rl,
          lx_ex                  TYPE REF TO cx_root.

    FIELD-SYMBOLS: <ls_line>       TYPE lty_color_line,
                   <ls_dependency> LIKE LINE OF it_dependencies.

    IF it_dependencies IS INITIAL.
      RETURN.
    ENDIF.

    CLEAR: ls_color.
    ls_color-color-col = col_negative.
    APPEND ls_color TO lt_color_negative.

    CLEAR: ls_color.
    ls_color-color-col = col_normal.
    APPEND ls_color TO lt_color_normal.

    CLEAR: ls_color.
    ls_color-color-col = col_positive.
    APPEND ls_color TO lt_color_positive.

    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table  = lo_alv
                                CHANGING  t_table       = lt_color_table ).

        lo_functional_settings = lo_alv->get_functional_settings( ).
        lo_hyperlinks = lo_functional_settings->get_hyperlinks( ).

        lo_columns = lo_alv->get_columns( ).
        lt_columns = lo_columns->get( ).
        LOOP AT lt_columns INTO ls_column WHERE columnname CP 'SEM_VERSION-*'.
          ls_column-r_column->set_technical( ).
        ENDLOOP.

        lo_column = lo_columns->get_column( 'MET' ).
        lo_column->set_technical( ).

        lo_column = lo_columns->get_column( 'GROUP_ID' ).
        lo_column->set_short_text( 'Org/ProjId' ).

        lo_columns->set_color_column( 'COLOR' ).
        lo_columns->set_exception_column( 'EXCEPTION' ).
        lo_columns->set_hyperlink_entry_column( 'T_HYPERLINK' ).
        lo_columns->set_optimize( ).

        lo_column = lo_columns->get_column( 'GROUP_ID' ).
        lo_column->set_short_text( 'Org/ProjId' ).

        lo_column = lo_columns->get_column( 'ARTIFACT_ID' ).
        lo_column->set_short_text( 'Proj. Name' ).

        lo_column = lo_columns->get_column( 'GIT_URL' ).
        lo_column->set_short_text( 'Git URL' ).

        lo_column_table ?= lo_column.
        lo_column_table->set_cell_type( if_salv_c_cell_type=>link ).


        lo_column = lo_columns->get_column( 'VERSION' ).
        lo_column->set_short_text( 'Version' ).

        lo_column = lo_columns->get_column( 'TARGET_PACKAGE' ).
        lo_column->set_technical( ).

        lo_hyperlinks = lo_functional_settings->get_hyperlinks( ).

        CLEAR: lv_handle, ls_color.
        LOOP AT it_dependencies ASSIGNING <ls_dependency>.
          lv_handle = lv_handle + 1.

          APPEND INITIAL LINE TO lt_color_table ASSIGNING <ls_line>.
          MOVE-CORRESPONDING <ls_dependency> TO <ls_line>.

          CASE <ls_line>-met.
            WHEN 'Y'.
              <ls_line>-color     = lt_color_positive.
              <ls_line>-exception = '3'.
            WHEN 'P'.
              <ls_line>-color     = lt_color_normal.
              <ls_line>-exception = '2'.
            WHEN 'N'.
              <ls_line>-color     = lt_color_negative.
              <ls_line>-exception = '1'.
          ENDCASE.

          CLEAR: ls_hyperlink.
          ls_hyperlink-columnname = 'GIT_URL'.
          ls_hyperlink-value      = lv_handle.
          APPEND ls_hyperlink TO <ls_line>-t_hyperlink.

          lv_hyperlink = <ls_line>-git_url.
          lo_hyperlinks->add_hyperlink( handle    = lv_handle
                                        hyperlink = lv_hyperlink ).

        ENDLOOP.

        UNASSIGN <ls_line>.

        lo_alv->set_screen_popup( start_column = 30
                                  end_column   = 120
                                  start_line   = 10
                                  end_line     = 20 ).
        lo_alv->get_display_settings( )->set_list_header( 'APACK dependencies' ).
        lo_alv->display( ).

      CATCH cx_salv_msg cx_salv_not_found cx_salv_data_error cx_salv_existing INTO lx_ex.
        zcx_abapgit_exception=>raise( lx_ex->get_text( ) ).
    ENDTRY.

  ENDMETHOD.


ENDCLASS.
