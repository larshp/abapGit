CLASS zcl_abapgit_apack_helper DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS are_dependencies_met
      IMPORTING
        !it_dependecies  TYPE zif_abapgit_apack_definitions=>tt_dependencies
      RETURNING
        VALUE(rv_status) TYPE zif_abapgit_definitions=>ty_yes_no
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
        met TYPE abap_bool.
        INCLUDE TYPE zif_abapgit_apack_definitions=>ty_dependency.
      TYPES: END OF ty_dependency_status,
      tt_dependency_status TYPE STANDARD TABLE OF ty_dependency_status WITH NON-UNIQUE DEFAULT KEY.

    CLASS-METHODS get_installed_packages
      RETURNING
        VALUE(rt_packages) TYPE zif_abapgit_apack_definitions=>tt_descriptor.

    CLASS-METHODS show_dependencies_popup
      IMPORTING
        !it_dependecies TYPE tt_dependency_status
      RAISING
        zcx_abapgit_exception .

ENDCLASS.



CLASS zcl_abapgit_apack_helper IMPLEMENTATION.


  METHOD are_dependencies_met.

    DATA: lt_installed_packages TYPE zif_abapgit_apack_definitions=>tt_descriptor,
          ls_dependecy          TYPE zif_abapgit_apack_definitions=>ty_dependency,
          lt_dependecies_popup  TYPE tt_dependency_status,
          ls_dependecy_popup    TYPE ty_dependency_status.

    IF it_dependecies IS INITIAL.
      rv_status = 'Y'.
    ELSE.
      lt_installed_packages = get_installed_packages( ).

      LOOP AT it_dependecies INTO ls_dependecy.
        CLEAR: ls_dependecy_popup.

        MOVE-CORRESPONDING ls_dependecy TO ls_dependecy_popup.

        READ TABLE lt_installed_packages TRANSPORTING NO FIELDS
          WITH KEY group_id    = ls_dependecy-group_id
                   artifact_id = ls_dependecy-artifact_id
                   git_url     = ls_dependecy-git_url.
        IF sy-subrc = 0.
          ls_dependecy_popup-met = abap_true.
        ELSE.
          ls_dependecy_popup-met = abap_false.
          rv_status = 'N'.
        ENDIF.

        INSERT ls_dependecy_popup INTO TABLE lt_dependecies_popup.

      ENDLOOP.

      IF rv_status = 'N'.
        show_dependencies_popup( lt_dependecies_popup ).
      ELSE.
        rv_status = 'Y'.
      ENDIF.

    ENDIF.

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
        color TYPE lvc_t_scol.
        INCLUDE TYPE ty_dependency_status.
      TYPES: END OF lty_color_line.

    TYPES: lty_color_tab TYPE STANDARD TABLE OF lty_color_line WITH DEFAULT KEY.

    DATA: lo_alv            TYPE REF TO cl_salv_table,
          lo_column         TYPE REF TO cl_salv_column,
          lo_columns        TYPE REF TO cl_salv_columns_table,
          lt_color_table    TYPE lty_color_tab,
          lt_color_negative TYPE lvc_t_scol,
          lt_color_positive TYPE lvc_t_scol,
          ls_color          TYPE lvc_s_scol,
          lx_ex             TYPE REF TO cx_root.

    FIELD-SYMBOLS: <ls_line>       TYPE lty_color_line,
                   <ls_dependency> LIKE LINE OF it_dependecies.

    IF it_dependecies IS INITIAL.
      RETURN.
    ENDIF.

    ls_color-color-col = col_negative.
    APPEND ls_color TO lt_color_negative.

    ls_color-color-col = col_positive.
    APPEND ls_color TO lt_color_positive.

    CLEAR ls_color.

    LOOP AT it_dependecies ASSIGNING <ls_dependency>.
      APPEND INITIAL LINE TO lt_color_table ASSIGNING <ls_line>.
      MOVE-CORRESPONDING <ls_dependency> TO <ls_line>.
    ENDLOOP.

    LOOP AT lt_color_table ASSIGNING <ls_line>.
      IF <ls_line>-met = abap_false.
        <ls_line>-color = lt_color_negative.
      ELSE.
        <ls_line>-color = lt_color_positive.
      ENDIF.
    ENDLOOP.
    UNASSIGN <ls_line>.

    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
                                CHANGING t_table       = lt_color_table ).

        lo_columns = lo_alv->get_columns( ).
        lo_columns->get_column( 'MET' )->set_short_text( 'Met' ).
        lo_columns->set_color_column( 'COLOR' ).
        lo_columns->set_optimize( ).

        lo_column = lo_columns->get_column( 'GROUP_ID' ).
        lo_column->set_short_text( 'Org/ProjId' ).

        lo_column = lo_columns->get_column( 'ARTIFACT_ID' ).
        lo_column->set_short_text( 'Proj. Name' ).

        lo_column = lo_columns->get_column( 'GIT_URL' ).
        lo_column->set_short_text( 'Git URL' ).

        lo_column = lo_columns->get_column( 'VERSION' ).
        lo_column->set_technical( ).

        lo_column = lo_columns->get_column( 'TARGET_PACKAGE' ).
        lo_column->set_technical( ).

        lo_alv->set_screen_popup( start_column = 30
                                  end_column   = 100
                                  start_line   = 10
                                  end_line     = 20 ).
        lo_alv->get_display_settings( )->set_list_header( 'Requirements' ).
        lo_alv->display( ).

      CATCH cx_salv_msg cx_salv_not_found cx_salv_data_error INTO lx_ex.
        zcx_abapgit_exception=>raise( lx_ex->get_text( ) ).
    ENDTRY.

  ENDMETHOD.


ENDCLASS.
