CLASS zcl_abapgit_apack_writer DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.

    CLASS-METHODS create_instance
      IMPORTING
        !is_apack_manifest_descriptor TYPE zif_abapgit_apack_definitions=>ty_descriptor
      RETURNING
        VALUE(ro_manifest_writer)     TYPE REF TO zcl_abapgit_apack_writer.
    METHODS serialize
      RETURNING
        VALUE(rv_xml) TYPE string
      RAISING
        zcx_abapgit_exception.
    METHODS constructor
      IMPORTING
        !is_apack_manifest_descriptor TYPE zif_abapgit_apack_definitions=>ty_descriptor.
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA ms_manifest_descriptor TYPE zif_abapgit_apack_definitions=>ty_descriptor.
ENDCLASS.



CLASS zcl_abapgit_apack_writer IMPLEMENTATION.


  METHOD constructor.
    ms_manifest_descriptor = is_apack_manifest_descriptor.
  ENDMETHOD.


  METHOD create_instance.
    CREATE OBJECT ro_manifest_writer EXPORTING is_apack_manifest_descriptor = is_apack_manifest_descriptor.
  ENDMETHOD.


  METHOD serialize.

    DATA: ls_manifest_descriptor LIKE ms_manifest_descriptor.

    FIELD-SYMBOLS: <ls_dependency> LIKE LINE OF ls_manifest_descriptor-dependencies.

    " Setting repository type automatically to 'abapGit' as there is no other one right now
    ms_manifest_descriptor-repository_type = zif_abapgit_apack_definitions=>c_repository_type_abapgit.

    ls_manifest_descriptor = ms_manifest_descriptor.
    CLEAR: ls_manifest_descriptor-sem_version.

    LOOP AT ls_manifest_descriptor-dependencies ASSIGNING <ls_dependency>.
      CLEAR: <ls_dependency>-sem_version.
    ENDLOOP.

    CALL TRANSFORMATION id
      OPTIONS initial_components = 'suppress'
      SOURCE data = ls_manifest_descriptor
      RESULT XML rv_xml.

    rv_xml = zcl_abapgit_xml_pretty=>print( rv_xml ).

    REPLACE FIRST OCCURRENCE
      OF REGEX '<\?xml version="1\.0" encoding="[\w-]+"\?>'
      IN rv_xml
      WITH '<?xml version="1.0" encoding="utf-8"?>'.

  ENDMETHOD.
ENDCLASS.
