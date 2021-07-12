INTERFACE zif_abapgit_background
  PUBLIC.


  TYPES:
    BEGIN OF ty_settings,
      key   TYPE string,
      value TYPE string,
    END OF ty_settings.
  TYPES:
    ty_settings_tt TYPE STANDARD TABLE OF ty_settings WITH DEFAULT KEY.

  CLASS-METHODS get_description
    RETURNING
      VALUE(rv_description) TYPE string.
  CLASS-METHODS get_settings
    CHANGING
      VALUE(ct_settings) TYPE ty_settings_tt.
  METHODS run
    IMPORTING
      !io_repo     TYPE REF TO zcl_abapgit_repo_online
      !ii_log      TYPE REF TO zif_abapgit_log
      !it_settings TYPE ty_settings_tt OPTIONAL
    RAISING
      zcx_abapgit_exception.
ENDINTERFACE.
