INTERFACE zif_abapgit_gui_services
  PUBLIC .


  METHODS cache_asset
    IMPORTING
      !iv_text      TYPE string OPTIONAL
      !iv_xdata     TYPE xstring OPTIONAL
      !iv_url       TYPE string OPTIONAL
      !iv_type      TYPE c
      !iv_subtype   TYPE c
    RETURNING
      VALUE(rv_url) TYPE string
    RAISING
      zcx_abapgit_exception .
  METHODS register_event_handler
    IMPORTING
      !ii_event_handler TYPE REF TO zif_abapgit_gui_event_handler .
  METHODS get_current_page_name
    RETURNING
      VALUE(rv_page_name) TYPE string .
  METHODS get_hotkeys_ctl
    RETURNING
      VALUE(ri_hotkey_ctl) TYPE REF TO zif_abapgit_gui_hotkey_ctl .
  METHODS get_html_parts
    RETURNING
      VALUE(ro_parts) TYPE REF TO zcl_abapgit_html_parts .
  METHODS get_log
    IMPORTING
      iv_create_new TYPE abap_bool DEFAULT abap_false
    RETURNING
      VALUE(ri_log) TYPE REF TO zif_abapgit_log.
ENDINTERFACE.
