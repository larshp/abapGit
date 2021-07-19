CLASS zcl_abapgit_apack_migration DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.

    CONSTANTS c_apack_interface_version TYPE i VALUE 1 ##NO_TEXT.

    CLASS-METHODS run
      RAISING
        zcx_abapgit_exception.
    METHODS perform_migration
      RAISING
        zcx_abapgit_exception.
  PROTECTED SECTION.
  PRIVATE SECTION.

    METHODS interface_exists
      RETURNING
        VALUE(rv_interface_exists) TYPE abap_bool.
    METHODS interface_valid
      RETURNING
        VALUE(rv_interface_valid) TYPE abap_bool.
    METHODS create_interface
      RAISING
        zcx_abapgit_exception.
    METHODS add_interface_source_classic
      IMPORTING
        !is_clskey TYPE seoclskey
      RAISING
        zcx_abapgit_exception.
    METHODS add_interface_source
      IMPORTING
        !is_clskey TYPE seoclskey
      RAISING
        zcx_abapgit_exception.
    METHODS get_interface_source
      RETURNING
        VALUE(rt_source) TYPE zif_abapgit_definitions=>ty_string_tt.
    METHODS add_intf_source_and_activate
      RAISING
        zcx_abapgit_exception.
ENDCLASS.



CLASS zcl_abapgit_apack_migration IMPLEMENTATION.


  METHOD add_interface_source.

    DATA: lo_factory     TYPE REF TO object,
          lo_source      TYPE REF TO object,
          lt_source_code TYPE zif_abapgit_definitions=>ty_string_tt.

    "Buffer needs to be refreshed,
    "otherwise standard SAP CLIF_SOURCE reorder methods alphabetically
    CALL FUNCTION 'SEO_BUFFER_INIT'.
    CALL FUNCTION 'SEO_BUFFER_REFRESH'
      EXPORTING
        cifkey  = is_clskey
        version = seoc_version_inactive.

    TRY.
        CALL METHOD ('CL_OO_FACTORY')=>('CREATE_INSTANCE')
          RECEIVING
            result = lo_factory.

        CALL METHOD lo_factory->('CREATE_CLIF_SOURCE')
          EXPORTING
            clif_name = is_clskey-clsname
          RECEIVING
            result    = lo_source.

        TRY.
            CALL METHOD lo_source->('IF_OO_CLIF_SOURCE~LOCK').
          CATCH cx_oo_access_permission.
            zcx_abapgit_exception=>raise( 'source_new, access permission exception' ).
        ENDTRY.

        lt_source_code = get_interface_source( ).

        CALL METHOD lo_source->('IF_OO_CLIF_SOURCE~SET_SOURCE')
          EXPORTING
            source = lt_source_code.

        CALL METHOD lo_source->('IF_OO_CLIF_SOURCE~SAVE').
        CALL METHOD lo_source->('IF_OO_CLIF_SOURCE~UNLOCK').

      CATCH cx_sy_dyn_call_error.
        add_interface_source_classic( is_clskey ).
    ENDTRY.

  ENDMETHOD.


  METHOD add_interface_source_classic.

    DATA: lo_source      TYPE REF TO cl_oo_source,
          lt_source_code TYPE zif_abapgit_definitions=>ty_string_tt.

    CREATE OBJECT lo_source
      EXPORTING
        clskey             = is_clskey
      EXCEPTIONS
        class_not_existing = 1
        OTHERS             = 2.
    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'error from CL_OO_SOURCE' ).
    ENDIF.

    TRY.
        lo_source->access_permission( seok_access_modify ).
        lt_source_code = get_interface_source( ).
        lo_source->set_source( lt_source_code ).
        lo_source->save( ).
        lo_source->access_permission( seok_access_free ).
      CATCH cx_oo_access_permission.
        zcx_abapgit_exception=>raise( 'permission error' ).
      CATCH cx_oo_source_save_failure.
        zcx_abapgit_exception=>raise( 'save failure' ).
    ENDTRY.

  ENDMETHOD.


  METHOD add_intf_source_and_activate.

    DATA: ls_clskey           TYPE seoclskey,
          ls_inactive_object  TYPE dwinactiv,
          lt_inactive_objects TYPE TABLE OF dwinactiv.

    ls_clskey-clsname = zif_abapgit_apack_definitions=>c_apack_interface_cust.

    add_interface_source( ls_clskey ).

    ls_inactive_object-object   = 'INTF'.
    ls_inactive_object-obj_name = zif_abapgit_apack_definitions=>c_apack_interface_cust.
    INSERT ls_inactive_object INTO TABLE lt_inactive_objects.

    CALL FUNCTION 'RS_WORKING_OBJECTS_ACTIVATE'
      TABLES
        objects                = lt_inactive_objects
      EXCEPTIONS
        excecution_error       = 1
        cancelled              = 2
        insert_into_corr_error = 3
        OTHERS                 = 4.

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise_t100( ).
    ENDIF.

  ENDMETHOD.


  METHOD create_interface.

    DATA: ls_interface_properties TYPE vseointerf.

    ls_interface_properties-clsname  = zif_abapgit_apack_definitions=>c_apack_interface_cust.
    ls_interface_properties-version  = '1'.
    ls_interface_properties-langu    = 'E'.
    ls_interface_properties-descript = 'APACK: Manifest interface'.
    ls_interface_properties-exposure = '2'.
    ls_interface_properties-state    = '1'.
    ls_interface_properties-unicode  = abap_true.

    TRY.
        CALL FUNCTION 'SEO_INTERFACE_CREATE_COMPLETE'
          EXPORTING
            devclass        = '$TMP'
            suppress_dialog = abap_true " Parameter missing in 702
          CHANGING
            interface       = ls_interface_properties
          EXCEPTIONS
            existing        = 1
            is_class        = 2
            db_error        = 3
            component_error = 4
            no_access       = 5
            other           = 6
            OTHERS          = 7.
      CATCH cx_sy_dyn_call_param_not_found.
        CALL FUNCTION 'SEO_INTERFACE_CREATE_COMPLETE'
          EXPORTING
            devclass        = '$TMP'
          CHANGING
            interface       = ls_interface_properties
          EXCEPTIONS
            existing        = 1
            is_class        = 2
            db_error        = 3
            component_error = 4
            no_access       = 5
            other           = 6
            OTHERS          = 7.
    ENDTRY.

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise_t100( ).
    ENDIF.

    add_intf_source_and_activate( ).

  ENDMETHOD.


  METHOD get_interface_source.

    INSERT `INTERFACE zif_apack_manifest PUBLIC.` INTO TABLE rt_source.
    INSERT `` INTO TABLE rt_source.
    INSERT `  TYPES: BEGIN OF ty_dependency,` INTO TABLE rt_source.
    INSERT `           group_id       TYPE string,` INTO TABLE rt_source.
    INSERT `           artifact_id    TYPE string,` INTO TABLE rt_source.
    INSERT `           version        TYPE string,` INTO TABLE rt_source.
    INSERT `           git_url        TYPE string,` INTO TABLE rt_source.
    INSERT `           target_package TYPE devclass,` INTO TABLE rt_source.
    INSERT `         END OF ty_dependency,` INTO TABLE rt_source.
    INSERT `         ty_dependencies    TYPE STANDARD TABLE OF ty_dependency` INTO TABLE rt_source.
    INSERT `                            WITH NON-UNIQUE DEFAULT KEY,` INTO TABLE rt_source.
    INSERT `         ty_repository_type TYPE string,` INTO TABLE rt_source.
    INSERT `         BEGIN OF ty_descriptor,` INTO TABLE rt_source.
    INSERT `           group_id        TYPE string,` INTO TABLE rt_source.
    INSERT `           artifact_id     TYPE string,` INTO TABLE rt_source.
    INSERT `           version         TYPE string,` INTO TABLE rt_source.
    INSERT `           repository_type TYPE ty_repository_type,` INTO TABLE rt_source.
    INSERT `           git_url         TYPE string,` INTO TABLE rt_source.
    INSERT `           dependencies    TYPE ty_dependencies,` INTO TABLE rt_source.
    INSERT `         END OF ty_descriptor.` INTO TABLE rt_source.
    INSERT `` INTO TABLE rt_source.
    INSERT `  CONSTANTS: co_file_name         TYPE string VALUE '.apack-manifest.xml',` INTO TABLE rt_source.
    INSERT `             co_abap_git          TYPE ty_repository_type VALUE 'abapGit',` INTO TABLE rt_source.
    INSERT `             co_interface_version TYPE i VALUE 1.` INTO TABLE rt_source.
    INSERT `` INTO TABLE rt_source.
    INSERT `  DATA: descriptor TYPE ty_descriptor READ-ONLY.` INTO TABLE rt_source.
    INSERT `` INTO TABLE rt_source.
    INSERT `ENDINTERFACE.` INTO TABLE rt_source.

  ENDMETHOD.


  METHOD interface_exists.

    DATA: lv_interface_name TYPE seoclsname.

    SELECT SINGLE clsname FROM seoclass INTO lv_interface_name
      WHERE clsname = zif_abapgit_apack_definitions=>c_apack_interface_cust.
    rv_interface_exists = boolc( sy-subrc = 0 ).

  ENDMETHOD.


  METHOD interface_valid.

    FIELD-SYMBOLS: <lv_interface_vers> TYPE i.

    ASSIGN (zif_abapgit_apack_definitions=>c_apack_interface_cust)=>('CO_INTERFACE_VERSION') TO <lv_interface_vers>.
    rv_interface_valid = boolc( <lv_interface_vers> IS ASSIGNED
      AND <lv_interface_vers> >= c_apack_interface_version ).

  ENDMETHOD.


  METHOD perform_migration.

    IF interface_exists( ) = abap_false.
      create_interface( ).
    ELSEIF interface_valid( ) = abap_false.
      add_intf_source_and_activate( ).
    ENDIF.

  ENDMETHOD.


  METHOD run.

    DATA: lo_apack_migration TYPE REF TO zcl_abapgit_apack_migration.

    CREATE OBJECT lo_apack_migration.
    lo_apack_migration->perform_migration( ).

  ENDMETHOD.
ENDCLASS.
