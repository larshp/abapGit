CLASS zcl_abapgit_environment DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.

    INTERFACES zif_abapgit_environment .

    ALIASES compare_with_inactive
      FOR zif_abapgit_environment~compare_with_inactive .
    ALIASES is_merged
      FOR zif_abapgit_environment~is_merged .
    ALIASES is_repo_object_changes_allowed
      FOR zif_abapgit_environment~is_repo_object_changes_allowed .
    ALIASES is_restart_required
      FOR zif_abapgit_environment~is_restart_required .
    ALIASES is_sap_cloud_platform
      FOR zif_abapgit_environment~is_sap_cloud_platform .

    CLASS-METHODS get_instance
      RETURNING
        VALUE(ro_instance) TYPE REF TO zif_abapgit_environment .
    METHODS constructor .
  PROTECTED SECTION.
private section.

  class-data GO_INSTANCE type ref to ZIF_ABAPGIT_ENVIRONMENT .
  data MO_DELEGATE type ref to ZIF_ABAPGIT_ENVIRONMENT .

  methods INJECT
    importing
      !IO_ABAPGIT_ENVIRONMENT type ref to ZIF_ABAPGIT_ENVIRONMENT .
ENDCLASS.



CLASS ZCL_ABAPGIT_ENVIRONMENT IMPLEMENTATION.


  METHOD constructor.
    CREATE OBJECT mo_delegate TYPE lcl_abapgit_environment_logic.
  ENDMETHOD.


  METHOD get_instance.
    IF go_instance IS NOT BOUND.
      CREATE OBJECT go_instance TYPE zcl_abapgit_environment.
    ENDIF.
    ro_instance = go_instance.
  ENDMETHOD.


  METHOD inject.
    mo_delegate = io_abapgit_environment.
  ENDMETHOD.


  METHOD zif_abapgit_environment~compare_with_inactive.
    rv_result = mo_delegate->compare_with_inactive( ).
  ENDMETHOD.


  METHOD zif_abapgit_environment~is_merged.
    rv_result = mo_delegate->is_merged( ).
  ENDMETHOD.


  METHOD zif_abapgit_environment~is_repo_object_changes_allowed.
    rv_result = mo_delegate->is_repo_object_changes_allowed( ).
  ENDMETHOD.


  METHOD zif_abapgit_environment~is_restart_required.
    rv_result = mo_delegate->is_restart_required( ).
  ENDMETHOD.


  METHOD zif_abapgit_environment~is_sap_cloud_platform.
    rv_result = mo_delegate->is_sap_cloud_platform( ).
  ENDMETHOD.
ENDCLASS.
