INTERFACE zif_abapgit_html_viewer
  PUBLIC .


  TYPES:
    ty_char256 TYPE c LENGTH 256 .
  TYPES:
    ty_post_data TYPE STANDARD TABLE OF ty_char256 WITH DEFAULT KEY .
  TYPES:
    BEGIN OF ty_name_value,
      name  TYPE c LENGTH 30,
      value TYPE c LENGTH 250,
    END OF ty_name_value .
  TYPES:
    ty_query_table TYPE STANDARD TABLE OF ty_name_value WITH DEFAULT KEY .

  CONSTANTS m_id_sapevent TYPE i VALUE 1 ##NO_TEXT.

  EVENTS sapevent
    EXPORTING
      VALUE(action) TYPE c OPTIONAL
      VALUE(frame) TYPE c OPTIONAL
      VALUE(getdata) TYPE c OPTIONAL
      VALUE(postdata) TYPE ty_post_data OPTIONAL
      VALUE(query_table) TYPE ty_query_table OPTIONAL .

  METHODS load_data
    IMPORTING
      !iv_url          TYPE string OPTIONAL
      !iv_type         TYPE c DEFAULT 'text'
      !iv_subtype      TYPE c DEFAULT 'html'
      !iv_size         TYPE i DEFAULT 0
    EXPORTING
      !ev_assigned_url TYPE string
    CHANGING
      !ct_data_table   TYPE STANDARD TABLE
    RAISING
      zcx_abapgit_exception .
  METHODS set_registered_events
    IMPORTING
      !it_events TYPE cntl_simple_events
    RAISING
      zcx_abapgit_exception .
  METHODS show_url
    IMPORTING
      !iv_url TYPE string
    RAISING
      zcx_abapgit_exception .
  METHODS free .
  METHODS close_document .
  METHODS get_url
    RETURNING
      VALUE(rv_url) TYPE string .
  METHODS back .
  METHODS set_visiblity
    IMPORTING
      !iv_visible TYPE abap_bool .
  METHODS get_viewer
    RETURNING
      VALUE(ro_result) TYPE REF TO cl_gui_html_viewer .
ENDINTERFACE.
