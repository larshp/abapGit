*  This class is intended to provide generic serialization based on SOBJ-definitions.
* For developers inheriting from this class: BE AWARE: This class will directly insert into
* and delete dynamically from the object's metadata-tables.
* Though this has been tested and is based upon code developed by SAP for a similar purpose,
* this is a risky operation. Please do verify the where-statements generated by the XML-bridge
* for correctness of your dedicated object-type!
*    No risk, no fun.
CLASS zsaplink_generic_obj DEFINITION
  PUBLIC
  INHERITING FROM zsaplink
  ABSTRACT
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        !name TYPE string .

    METHODS checkexists
         REDEFINITION .
    METHODS createixmldocfromobject
         REDEFINITION .
    METHODS createobjectfromixmldoc
         REDEFINITION .
  PROTECTED SECTION.

    TYPES:
      BEGIN OF ty_s_tlogo_tables,
        tabname      TYPE ddobjname,
        where_clause TYPE string,
        data         TYPE REF TO data,
      END OF ty_s_tlogo_tables .
    TYPES:
      ty_t_tlogo_tables TYPE SORTED TABLE OF ty_s_tlogo_tables WITH UNIQUE KEY tabname .

    METHODS add_table_metadata
      IMPORTING
        !io_ixmldocument TYPE REF TO if_ixml_document
        !io_root_node    TYPE REF TO if_ixml_element .
    METHODS serialize_table_content
      IMPORTING
        !io_ixmldocument TYPE REF TO if_ixml_document
        !io_root_node    TYPE REF TO if_ixml_element
      RAISING
        zcx_saplink .
    METHODS update_db_table_content
      IMPORTING
        !i_ixmldocument TYPE REF TO if_ixml_document
      RAISING
        zcx_saplink .

    METHODS deleteobject
         REDEFINITION .
  PRIVATE SECTION.

    DATA mo_xml_bridge TYPE REF TO lcl_tlogo_xml_bridge .
    CONSTANTS co_xml_metadata TYPE string VALUE 'objMetaData' ##NO_TEXT.

    METHODS get_xml_bridge
      RETURNING
        VALUE(ro_xml_bridge) TYPE REF TO lcl_tlogo_xml_bridge .
    METHODS metadata_to_xml
      IMPORTING
        !it_metadata               TYPE lcl_tlogo_xml_bridge=>tt_obj_metadata
      RETURNING
        VALUE(ro_metadata_element) TYPE REF TO if_ixml_element .
    METHODS xml_to_metadata
      IMPORTING
        !io_metadata_element TYPE REF TO if_ixml_element
      RETURNING
        VALUE(rt_metadata)   TYPE lcl_tlogo_xml_bridge=>tt_obj_metadata .
    METHODS validate_metadata
      IMPORTING
        !it_metadata TYPE lcl_tlogo_xml_bridge=>tt_obj_metadata
      RAISING
        zcx_saplink .
ENDCLASS.



CLASS ZSAPLINK_GENERIC_OBJ IMPLEMENTATION.


  METHOD add_table_metadata.

*    add the table's metdata
    DATA(lt_metadata) = get_xml_bridge( )->get_table_metadata( CONV #( me->objname ) ).

*    encapsulate the simple transformation metadata-table-element to have a fixed name
    DATA(lo_md_element) = io_ixmldocument->create_element( co_xml_metadata ).
    lo_md_element->append_child( me->metadata_to_xml( lt_metadata ) ).
    io_root_node->append_child( lo_md_element ).

  ENDMETHOD.


  METHOD checkexists.
    exists = me->get_xml_bridge( )->exists( CONV #( objname ) ).
  ENDMETHOD.


  METHOD constructor.
*/---------------------------------------------------------------------\
*|   This file is part of SAPlink.                                     |
*|                                                                     |
*|   SAPlink is free software; you can redistribute it and/or modify   |
*|   it under the terms of the GNU General Public License as published |
*|   by the Free Software Foundation; either version 2 of the License, |
*|   or (at your option) any later version.                            |
*|                                                                     |
*|   SAPlink is distributed in the hope that it will be useful,        |
*|   but WITHOUT ANY WARRANTY; without even the implied warranty of    |
*|   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the     |
*|   GNU General Public License for more details.                      |
*|                                                                     |
*|   You should have received a copy of the GNU General Public License |
*|   along with SAPlink; if not, write to the                          |
*|   Free Software Foundation, Inc.,                                   |
*|   51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA          |
*\---------------------------------------------------------------------/
    super->constructor( name = name ).

  ENDMETHOD.


  METHOD createixmldocfromobject.
*    convention by saplink: The root element has to be named with the OBJTYPE,
*    the first attribute of the root node denotes the objname
    DATA lo_root_node TYPE REF TO if_ixml_element.
    ixmldocument = ixml->create_document( ).

    lo_root_node = ixmldocument->create_element( me->getobjecttype( ) ).
    lo_root_node->set_attribute(
        name      = 'objname'    " NAME
        value     = objname
    ).

    serialize_table_content(
        io_ixmldocument = ixmldocument
        io_root_node    = lo_root_node ).

    add_table_metadata(
        io_ixmldocument = ixmldocument
        io_root_node    = lo_root_node ).

    ixmldocument->append_child( lo_root_node ).

  ENDMETHOD.


  METHOD createobjectfromixmldoc.

*    validate the metadata of the underlying DB tables
*    As insert/update/delete to a table is being performed, the table structure actually
*    defines an interface. The compatibility of this interface has to be validated prior
*    to consuming it
    DATA(lo_obj_metadata_elem) = ixmldocument->get_elements_by_tag_name( name = co_xml_metadata )->get_item( 0 ).

    IF lo_obj_metadata_elem IS INITIAL.
      BREAK-POINT. "this seems to be an old file-format where no consistency between the tables can be checked.
*    => proceed only if you know what you're doing and jump over the next statement.
      RAISE EXCEPTION TYPE zcx_saplink
        EXPORTING
          textid = zcx_saplink=>error_message
          msg    = 'Old (unsupported) format'.
    ELSE.
      DATA(lt_obj_metadata) = me->xml_to_metadata( CAST #( lo_obj_metadata_elem->get_first_child( ) ) ).
      me->validate_metadata( lt_obj_metadata ).
    ENDIF.

*    write the content serialized in the XML document into the DB tables
    update_db_table_content( ixmldocument ).

  ENDMETHOD.


  METHOD deleteobject.
    "do not do anything - the update of the object implicitly deletes obsolete entries
    ASSERT 1 = 1.

    RETURN.

*    there is an opportunity to explicitly purge all tables with the corresponding keys,
*    but this is actually not necessary (and quite a critical operation).
    get_xml_bridge( )->delete_object( CONV #( objname ) ).

  ENDMETHOD.


  METHOD get_xml_bridge.
    IF mo_xml_bridge IS INITIAL.
*    can't be called in the constructor as getObjectType is intended to be polymorphic
      mo_xml_bridge = NEW lcl_tlogo_xml_bridge( i_tlogo = CONV #( me->getobjecttype( ) ) ).
    ENDIF.

    ro_xml_bridge = mo_xml_bridge.

  ENDMETHOD.


  METHOD metadata_to_xml.
    DATA(lo_document_md) = ixml->create_document( ).

    CALL TRANSFORMATION id
        SOURCE metadata = it_metadata
        RESULT XML lo_document_md.

    ro_metadata_element = lo_document_md->get_root_element( ).

  ENDMETHOD.


  METHOD serialize_table_content.

*    read table content to XML
    IF get_xml_bridge( )->exists( CONV #( me->objname ) ) = abap_false.
      RAISE EXCEPTION TYPE zcx_saplink
        EXPORTING
          textid = zcx_saplink=>not_found.
    ENDIF.

    get_xml_bridge( )->compose_xml(
      EXPORTING
        i_objnm       = CONV #( me->objname )   " Object name in object directory
      IMPORTING
        e_string_xml = DATA(lv_string_xml)   " XML Data
    ).

    DATA(lo_xml_bridge_document) = convertstringtoixmldoc( xmlstring = lv_string_xml ).

    io_root_node->append_child( lo_xml_bridge_document->get_root_element( ) ).

  ENDMETHOD.


  METHOD update_db_table_content.

*    unpack the actual document from the saplink-specific wrapper
    DATA(lo_xml_bridge_transport_elem) = i_ixmldocument->get_elements_by_tag_name( name = CONV #( lcl_tlogo_xml_bridge=>p_c_xml_tag_transport ) )->get_item( 0 ).
    IF lo_xml_bridge_transport_elem IS INITIAL.
      RAISE EXCEPTION TYPE zcx_saplink
        EXPORTING
          textid = zcx_saplink=>incorrect_file_format
          msg    = 'No object data found'.
    ELSE.
      DATA(lo_xml_bridge_document) = cl_ixml=>create( )->create_document( ).
      lo_xml_bridge_document->append_child( lo_xml_bridge_transport_elem ).
    ENDIF.

*    during existence check, a sanity check is being performed (that not more than one entry in the
*    primary table is affected). Thus, issue an existence check without evaluating the result
    get_xml_bridge( )->exists( CONV #( me->objname ) ).


    get_xml_bridge( )->parse_xml(
      EXPORTING
        i_objnm      = CONV #( me->objname )    " Object name in object directory
        i_string_xml = convertixmldoctostring( lo_xml_bridge_document )    " String with XML Data
      IMPORTING
        e_subrc      = DATA(lv_subrc_parsing)    " Return Value, Return Value After ABAP Statements
    ).
    IF lv_subrc_parsing IS INITIAL.

      get_xml_bridge( )->save(
        IMPORTING
          e_subrc    = DATA(lv_subrc_save)
      ).

      IF lv_subrc_save IS INITIAL.

*      perform after import methods
        get_xml_bridge( )->activate( ).
      ELSE.
        RAISE EXCEPTION TYPE zcx_saplink
          EXPORTING
            textid = zcx_saplink=>error_message
            msg    = |An error occurred when saving { objname }. Check Application log Object { cl_rso_repository=>p_c_bal_log_object }|.
      ENDIF.

    ELSE.
      RAISE EXCEPTION TYPE zcx_saplink
        EXPORTING
          textid = zcx_saplink=>error_message
          msg    = 'Object could not be identified in source'.
    ENDIF.

  ENDMETHOD.


  METHOD validate_metadata.
*    this method checks whether the metadata of the tables of the transport object
*    substantially differ between the object serialized and the current system.
*    This is necessary as the DB-table is treated as interface in this tool

*    all the tables which are filled in the source need to exist locally with all fields from
*    the source system existing with the same technical datatype locally as well
    DEFINE exception_metadata.
      RAISE EXCEPTION TYPE zcx_saplink
              EXPORTING
                textid = zcx_saplink=>error_message
                msg    = 'Database structure differs. Object cannot be imported.'.
    END-OF-DEFINITION.

    LOOP AT it_metadata ASSIGNING FIELD-SYMBOL(<ls_metadata>) WHERE count > 0. "only the relevant tables need to be validated

      DATA lt_dfies TYPE dfies_table.

*   get the DDIC info of the local table structure
      CALL FUNCTION 'DDIF_NAMETAB_GET'
        EXPORTING
          tabname   = CONV ddobjname( <ls_metadata>-db_table )
        TABLES
          dfies_tab = lt_dfies
        EXCEPTIONS
          not_found = 1.
      ASSERT sy-subrc = 0.

*      compare the fields-information which is relevant to technical compatibility.
      LOOP AT <ls_metadata>-fields_definition ASSIGNING FIELD-SYMBOL(<ls_origin_fielddef>).
        READ TABLE lt_dfies ASSIGNING FIELD-SYMBOL(<ls_local_fielddef>) WITH KEY fieldname = <ls_origin_fielddef>-fieldname.
        IF sy-subrc NE 0.
          exception_metadata.
        ENDIF.

        IF <ls_local_fielddef>-datatype NE <ls_origin_fielddef>-datatype
           OR <ls_local_fielddef>-inttype NE <ls_origin_fielddef>-inttype.
          exception_metadata.
        ENDIF.

        IF <ls_local_fielddef>-leng NE <ls_origin_fielddef>-leng.
          "<ls_local_fielddef>-intlen NE <ls_origin_fielddef>-intlen. Does not have to be the same when transporting between unicode and non-unicode-systems
          exception_metadata.
        ENDIF.

        IF <ls_local_fielddef>-decimals NE <ls_origin_fielddef>-decimals.
          exception_metadata.
        ENDIF.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.


  METHOD xml_to_metadata.

    DATA(lo_document_md) = ixml->create_document( ).

    lo_document_md->append_child( io_metadata_element ).

    CALL TRANSFORMATION id
        SOURCE XML  lo_document_md
        RESULT      metadata = rt_metadata .

  ENDMETHOD.
ENDCLASS.