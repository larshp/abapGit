CLASS zcl_abapgit_object_enhs DEFINITION PUBLIC INHERITING FROM zcl_abapgit_objects_super FINAL.

  PUBLIC SECTION.
    INTERFACES zif_abapgit_object.
    ALIASES mo_files FOR zif_abapgit_object~mo_files.

  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS:
      factory
        IMPORTING
          iv_tool        TYPE enhtooltype
        RETURNING
          VALUE(ri_enho) TYPE REF TO zif_abapgit_object_enhs
        RAISING
          zcx_abapgit_exception.

ENDCLASS.



CLASS ZCL_ABAPGIT_OBJECT_ENHS IMPLEMENTATION.


  METHOD factory.

    CASE iv_tool.
      WHEN cl_enh_tool_badi_def=>tooltype.
        CREATE OBJECT ri_enho TYPE zcl_abapgit_object_enhs_badi_d.
      WHEN cl_enh_tool_hook_def=>tool_type.
        CREATE OBJECT ri_enho TYPE zcl_abapgit_object_enhs_hook_d.
      WHEN OTHERS.
        zcx_abapgit_exception=>raise( |ENHS: Unsupported tool { iv_tool }| ).
    ENDCASE.

  ENDMETHOD.


  METHOD zif_abapgit_object~changed_by.

    DATA: lv_spot_name TYPE enhspotname,
          li_spot_ref  TYPE REF TO if_enh_spot_tool.

    lv_spot_name = ms_item-obj_name.

    TRY.
        li_spot_ref = cl_enh_factory=>get_enhancement_spot( lv_spot_name ).
        li_spot_ref->get_attributes( IMPORTING changedby = rv_user ).

      CATCH cx_enh_root.
        rv_user = c_user_unknown.
    ENDTRY.

  ENDMETHOD.


  METHOD zif_abapgit_object~delete.

    DATA: lv_spot_name  TYPE enhspotname,
          li_enh_object TYPE REF TO if_enh_object.
    DATA lx_io_error TYPE REF TO cx_enh_io_error.
    DATA lx_permission TYPE REF TO cx_enh_permission_denied.
    DATA lx_canceled TYPE REF TO cx_enh_canceled.
    DATA lx_internal TYPE REF TO cx_enh_internal_error.
    DATA lx_locked TYPE REF TO cx_enh_is_locked.
    DATA lx_composit TYPE REF TO cx_enh_composite_not_empty.
    DATA lx_not_allowed TYPE REF TO cx_enh_mod_not_allowed.

    lv_spot_name  = ms_item-obj_name.

    TRY.
        li_enh_object ?= cl_enh_factory=>get_enhancement_spot( spot_name = lv_spot_name
                                                               lock      = abap_true ).

        li_enh_object->delete( nevertheless_delete = abap_true
                               run_dark            = abap_true ).

        li_enh_object->unlock( ).

      CATCH cx_enh_io_error INTO lx_io_error.
        zcx_abapgit_exception=>raise(
          iv_text = |Delete: I/O error from CL_ENH_FACTORY for { lv_spot_name }|
          ix_previous = lx_io_error ).
      CATCH cx_enh_permission_denied INTO lx_permission.
        zcx_abapgit_exception=>raise(
          iv_text = |Delete: No permission error from CL_ENH_FACTORY for { lv_spot_name }|
          ix_previous = lx_permission ).
      CATCH cx_enh_canceled INTO lx_canceled.
        zcx_abapgit_exception=>raise(
          iv_text = |Delete: Canceled error from CL_ENH_FACTORY for { lv_spot_name }|
          ix_previous = lx_canceled ).
      CATCH cx_enh_internal_error INTO lx_internal.
        zcx_abapgit_exception=>raise(
          iv_text = |Delete: Internal error from CL_ENH_FACTORY for { lv_spot_name }|
          ix_previous = lx_internal ).
      CATCH cx_enh_is_locked INTO lx_locked.
        zcx_abapgit_exception=>raise(
          iv_text = |Delete: Is locked error from CL_ENH_FACTORY for { lv_spot_name }|
          ix_previous = lx_locked ).
      CATCH cx_enh_composite_not_empty INTO lx_composit.
        zcx_abapgit_exception=>raise(
          iv_text = |Delete: Composite is not empty error from CL_ENH_FACTORY for { lv_spot_name }|
          ix_previous = lx_composit ).
      CATCH cx_enh_mod_not_allowed INTO lx_not_allowed.
        zcx_abapgit_exception=>raise(
          iv_text = |Delete: Modification not allowed error from CL_ENH_FACTORY for { lv_spot_name }|
          ix_previous = lx_not_allowed ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_abapgit_object~deserialize.

    DATA: lv_parent    TYPE enhspotcompositename,
          lv_spot_name TYPE enhspotname,
          lv_tool      TYPE enhspottooltype,
          lv_package   LIKE iv_package,
          li_spot_ref  TYPE REF TO if_enh_spot_tool,
          li_enhs      TYPE REF TO zif_abapgit_object_enhs.
    DATA lx_io_error TYPE REF TO cx_enh_io_error.
    DATA lx_permission TYPE REF TO cx_enh_permission_denied.
    DATA lx_canceled TYPE REF TO cx_enh_canceled.
    DATA lx_internal TYPE REF TO cx_enh_internal_error.
    DATA lx_locked TYPE REF TO cx_enh_is_locked.
    DATA lx_create TYPE REF TO cx_enh_create_error.

    IF zif_abapgit_object~exists( ) = abap_true.
      zif_abapgit_object~delete( iv_package ).
    ENDIF.

    io_xml->read( EXPORTING iv_name = 'TOOL'
                  CHANGING  cg_data = lv_tool ).

    lv_spot_name = ms_item-obj_name.
    lv_package   = iv_package.

    TRY.
        cl_enh_factory=>create_enhancement_spot(
          EXPORTING
            spot_name      = lv_spot_name
            tooltype       = lv_tool
            dark           = abap_false
            compositename  = lv_parent
          IMPORTING
            spot           = li_spot_ref
          CHANGING
            devclass       = lv_package ).

      CATCH cx_enh_io_error INTO lx_io_error.
        zcx_abapgit_exception=>raise(
          iv_text = |Deserialize: I/O error from CL_ENH_FACTORY for { lv_spot_name }|
          ix_previous = lx_io_error ).
      CATCH cx_enh_permission_denied INTO lx_permission.
        zcx_abapgit_exception=>raise(
          iv_text = |Deserialize: No permission error from CL_ENH_FACTORY for { lv_spot_name }|
          ix_previous = lx_permission ).
      CATCH cx_enh_canceled INTO lx_canceled.
        zcx_abapgit_exception=>raise(
          iv_text = |Deserialize: Canceled error from CL_ENH_FACTORY for { lv_spot_name }|
          ix_previous = lx_canceled ).
      CATCH cx_enh_internal_error INTO lx_internal.
        zcx_abapgit_exception=>raise(
          iv_text = |Deserialize: Internal error from CL_ENH_FACTORY for { lv_spot_name }|
          ix_previous = lx_internal ).
      CATCH cx_enh_is_locked INTO lx_locked.
        zcx_abapgit_exception=>raise(
          iv_text = |Deserialize: Is locked error from CL_ENH_FACTORY for { lv_spot_name }|
          ix_previous = lx_locked ).
      CATCH cx_enh_create_error INTO lx_create.
        zcx_abapgit_exception=>raise(
          iv_text = |Deserialize: Create error from CL_ENH_FACTORY for { lv_spot_name }|
          ix_previous = lx_create ).
    ENDTRY.

    li_enhs = factory( lv_tool ).

    li_enhs->deserialize( io_xml           = io_xml
                          iv_package       = iv_package
                          ii_enh_spot_tool = li_spot_ref ).

  ENDMETHOD.


  METHOD zif_abapgit_object~exists.

    DATA: lv_spot_name TYPE enhspotname,
          li_spot_ref  TYPE REF TO if_enh_spot_tool.

    lv_spot_name = ms_item-obj_name.

    TRY.
        li_spot_ref = cl_enh_factory=>get_enhancement_spot( lv_spot_name ).

        rv_bool = abap_true.

      CATCH cx_enh_root.
        rv_bool = abap_false.
    ENDTRY.

  ENDMETHOD.


  METHOD zif_abapgit_object~get_comparator.
    RETURN.
  ENDMETHOD.


  METHOD zif_abapgit_object~get_deserialize_steps.
    APPEND zif_abapgit_object=>gc_step_id-abap TO rt_steps.
  ENDMETHOD.


  METHOD zif_abapgit_object~get_metadata.
    rs_metadata = get_metadata( ).
  ENDMETHOD.


  METHOD zif_abapgit_object~is_active.
    rv_active = is_active( ).
  ENDMETHOD.


  METHOD zif_abapgit_object~is_locked.

    rv_is_locked = abap_false.

  ENDMETHOD.


  METHOD zif_abapgit_object~jump.

    CALL FUNCTION 'RS_TOOL_ACCESS'
      EXPORTING
        operation     = 'SHOW'
        object_name   = ms_item-obj_name
        object_type   = 'ENHS'
        in_new_window = abap_true.

  ENDMETHOD.


  METHOD zif_abapgit_object~serialize.

    DATA: lv_spot_name TYPE enhspotname,
          li_spot_ref  TYPE REF TO if_enh_spot_tool,
          li_enhs      TYPE REF TO zif_abapgit_object_enhs,
          lx_root      TYPE REF TO cx_root.
    DATA lx_io_error TYPE REF TO cx_enh_io_error.
    DATA lx_permission TYPE REF TO cx_enh_permission_denied.
    DATA lx_canceled TYPE REF TO cx_enh_canceled.
    DATA lx_internal TYPE REF TO cx_enh_internal_error.
    DATA lx_locked TYPE REF TO cx_enh_is_locked.

    lv_spot_name = ms_item-obj_name.

    TRY.
        li_spot_ref = cl_enh_factory=>get_enhancement_spot( lv_spot_name ).

      CATCH cx_enh_io_error INTO lx_io_error.
        zcx_abapgit_exception=>raise(
          iv_text = |Serialize: I/O error from CL_ENH_FACTORY for { lv_spot_name }|
          ix_previous = lx_io_error ).
      CATCH cx_enh_permission_denied INTO lx_permission.
        zcx_abapgit_exception=>raise(
          iv_text = |Serialize: No permission error from CL_ENH_FACTORY for { lv_spot_name }|
          ix_previous = lx_permission ).
      CATCH cx_enh_canceled INTO lx_canceled.
        zcx_abapgit_exception=>raise(
          iv_text = |Serialize: Canceled error from CL_ENH_FACTORY for { lv_spot_name }|
          ix_previous = lx_canceled ).
      CATCH cx_enh_internal_error INTO lx_internal.
        zcx_abapgit_exception=>raise(
          iv_text = |Serialize: Internal error from CL_ENH_FACTORY for { lv_spot_name }|
          ix_previous = lx_internal ).
      CATCH cx_enh_is_locked INTO lx_locked.
        zcx_abapgit_exception=>raise(
          iv_text = |Serialize: Is locked error from CL_ENH_FACTORY for { lv_spot_name }|
          ix_previous = lx_locked ).
    ENDTRY.

    li_enhs = factory( li_spot_ref->get_tool( ) ).

    li_enhs->serialize( io_xml           = io_xml
                        ii_enh_spot_tool = li_spot_ref ).

  ENDMETHOD.
ENDCLASS.
