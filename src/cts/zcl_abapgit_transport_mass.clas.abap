CLASS zcl_abapgit_transport_mass DEFINITION
  PUBLIC
  INHERITING FROM zcl_abapgit_transport
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    CLASS-METHODS run.
  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS zcl_abapgit_transport_mass IMPLEMENTATION.


  METHOD run.

    DATA:
      lt_trkorr           TYPE trwbo_request_headers,
      lo_transport_zipper TYPE REF TO lcl_transport_zipper,
      lx_except           TYPE REF TO cx_root,
      lv_folder           TYPE string,
      lv_text             TYPE string.

    TRY.

        lt_trkorr = lcl_gui=>select_tr_requests( ).

        IF lt_trkorr[] IS NOT INITIAL.

          lv_folder = lcl_gui=>f4_folder( ).

          IF lv_folder IS INITIAL.
            " Empty folder
            zcx_abapgit_exception=>raise( 'Empty destination folder' ).
          ENDIF.

          " Instantiate transport zipper object that will also create the timestamped output folder
          CREATE OBJECT lo_transport_zipper TYPE lcl_transport_zipper
            EXPORTING
              iv_folder = lv_folder.

          " Generate the local zip files from the given list of transport requests
          lo_transport_zipper->generate_files(
            it_trkorr = lt_trkorr
            ig_logic  = zcl_abapgit_ui_factory=>get_popups( )->popup_folder_logic( ) ).

          " Open output folder if user asked it
          lcl_gui=>open_folder_frontend( lo_transport_zipper->get_folder( ) ).

        ELSE.
          " No data found for the provided selection criterias
          zcx_abapgit_exception=>raise( 'No transport requests selected' ).
        ENDIF.

      CATCH zcx_abapgit_exception INTO lx_except.

        lv_text = lx_except->get_text( ).
        MESSAGE lv_text TYPE 'S' DISPLAY LIKE 'E'.

    ENDTRY.

  ENDMETHOD.
ENDCLASS.
