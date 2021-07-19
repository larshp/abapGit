INTERFACE zif_abapgit_apack_definitions
  PUBLIC.


  TYPES:
    BEGIN OF ty_dependency,
      group_id       TYPE string,
      artifact_id    TYPE string,
      version        TYPE string,
      sem_version    TYPE zif_abapgit_definitions=>ty_version,
      git_url        TYPE string,
      target_package TYPE devclass,
    END OF ty_dependency.
  TYPES:
    ty_dependencies TYPE STANDARD TABLE OF ty_dependency
                    WITH NON-UNIQUE DEFAULT KEY.
  TYPES ty_repository_type TYPE string.
  TYPES:
    BEGIN OF ty_descriptor_wo_dependencies,
      group_id        TYPE string,
      artifact_id     TYPE string,
      version         TYPE string,
      sem_version     TYPE zif_abapgit_definitions=>ty_version,
      repository_type TYPE ty_repository_type,
      git_url         TYPE string,
    END OF ty_descriptor_wo_dependencies.
  TYPES:
    BEGIN OF ty_descriptor.
      INCLUDE TYPE ty_descriptor_wo_dependencies.
  TYPES:
      dependencies TYPE ty_dependencies,
    END OF ty_descriptor.
  TYPES:
    ty_descriptors TYPE STANDARD TABLE OF ty_descriptor WITH NON-UNIQUE DEFAULT KEY.

  CONSTANTS c_dot_apack_manifest TYPE string VALUE '.apack-manifest.xml' ##NO_TEXT.
  CONSTANTS c_repository_type_abapgit TYPE ty_repository_type VALUE 'abapGit' ##NO_TEXT.
  CONSTANTS c_apack_interface_sap TYPE seoclsname VALUE 'IF_APACK_MANIFEST' ##NO_TEXT.
  CONSTANTS c_apack_interface_cust TYPE seoclsname VALUE 'ZIF_APACK_MANIFEST' ##NO_TEXT.
ENDINTERFACE.
