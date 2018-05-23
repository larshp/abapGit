INTERFACE zif_abapgit_definitions PUBLIC.

  TYPES:
    ty_type    TYPE c LENGTH 6 .
  TYPES:
    ty_bitbyte TYPE c LENGTH 8 .
  TYPES:
    ty_sha1    TYPE c LENGTH 40 .
  TYPES: ty_adler32 TYPE x LENGTH 4.
  TYPES:
    BEGIN OF ty_file_signature,
      path     TYPE string,
      filename TYPE string,
      sha1     TYPE zif_abapgit_definitions=>ty_sha1,
    END OF ty_file_signature .
  TYPES:
    ty_file_signatures_tt TYPE STANDARD TABLE OF
           ty_file_signature WITH DEFAULT KEY .
  TYPES:
    ty_file_signatures_ts TYPE SORTED TABLE OF
           ty_file_signature WITH UNIQUE KEY path filename .
  TYPES:
    BEGIN OF ty_file.
      INCLUDE TYPE ty_file_signature.
  TYPES: data TYPE xstring,
         END OF ty_file .
  TYPES:
    ty_files_tt TYPE STANDARD TABLE OF ty_file WITH DEFAULT KEY .
  TYPES:
    ty_string_tt TYPE STANDARD TABLE OF string WITH DEFAULT KEY .

  TYPES: ty_repo_ref_tt TYPE STANDARD TABLE OF REF TO zcl_abapgit_repo WITH DEFAULT KEY.

  TYPES ty_git_branch_type TYPE char2 .
  TYPES:
    BEGIN OF ty_git_branch,
      sha1         TYPE zif_abapgit_definitions=>ty_sha1,
      name         TYPE string,
      type         TYPE ty_git_branch_type,
      is_head      TYPE abap_bool,
      display_name TYPE string,
    END OF ty_git_branch .
  TYPES:
    ty_git_branch_list_tt TYPE STANDARD TABLE OF ty_git_branch WITH DEFAULT KEY .

  CONSTANTS:
    BEGIN OF c_git_branch_type,
      branch TYPE ty_git_branch_type VALUE 'HD',
      tag    TYPE ty_git_branch_type VALUE 'TG',
      other  TYPE ty_git_branch_type VALUE 'ZZ',
    END OF c_git_branch_type .
  CONSTANTS c_head_name TYPE string VALUE 'HEAD' ##NO_TEXT.

  TYPES:
    BEGIN OF ty_git_user,
      name  TYPE string,
      email TYPE string,
    END OF ty_git_user .
  TYPES:
    BEGIN OF ty_comment,
      committer TYPE ty_git_user,
      author    TYPE ty_git_user,
      comment   TYPE string,
    END OF ty_comment .
  TYPES:
    BEGIN OF ty_item,
      obj_type TYPE tadir-object,
      obj_name TYPE tadir-obj_name,
      devclass TYPE devclass,
    END OF ty_item .
  TYPES:
    ty_items_tt TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY .
  TYPES:
    ty_items_ts TYPE SORTED TABLE OF ty_item WITH UNIQUE KEY obj_type obj_name .
  TYPES:
    BEGIN OF ty_file_item,
      file TYPE zif_abapgit_definitions=>ty_file,
      item TYPE ty_item,
    END OF ty_file_item .
  TYPES:
    ty_files_item_tt TYPE STANDARD TABLE OF ty_file_item WITH DEFAULT KEY .

  TYPES: ty_yes_no TYPE c LENGTH 1.

  TYPES: BEGIN OF ty_overwrite.
      INCLUDE TYPE ty_item.
  TYPES: decision TYPE ty_yes_no,
         END OF ty_overwrite.

  TYPES: ty_overwrite_tt TYPE STANDARD TABLE OF ty_overwrite WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_requirements,
           met      TYPE ty_yes_no,
           decision TYPE ty_yes_no,
         END OF ty_requirements.

  TYPES: BEGIN OF ty_transport,
           required  TYPE abap_bool,
           transport TYPE trkorr,
         END OF ty_transport.


  TYPES: BEGIN OF ty_deserialize_checks,
           overwrite       TYPE ty_overwrite_tt,
           warning_package TYPE ty_overwrite_tt,
           requirements    TYPE ty_requirements,
           transport       TYPE ty_transport,
         END OF ty_deserialize_checks.

  TYPES:
    BEGIN OF ty_metadata,
      class        TYPE string,
      version      TYPE string,
      late_deser   TYPE abap_bool,
      delete_tadir TYPE abap_bool,
      ddic         TYPE abap_bool,
    END OF ty_metadata .
  TYPES:
    BEGIN OF ty_web_asset,
      url     TYPE w3url,
      base64  TYPE string,
      content TYPE xstring,
    END OF ty_web_asset .
  TYPES:
    tt_web_assets TYPE STANDARD TABLE OF ty_web_asset WITH DEFAULT KEY .
  TYPES:
    BEGIN OF ty_repo_file,
      path       TYPE string,
      filename   TYPE string,
      is_changed TYPE abap_bool,
      rstate     TYPE char1,
      lstate     TYPE char1,
    END OF ty_repo_file .
  TYPES:
    tt_repo_files TYPE STANDARD TABLE OF ty_repo_file WITH DEFAULT KEY .
  TYPES:
    BEGIN OF ty_stage_files,
      local  TYPE zif_abapgit_definitions=>ty_files_item_tt,
      remote TYPE zif_abapgit_definitions=>ty_files_tt,
    END OF ty_stage_files .
  TYPES:
    ty_chmod TYPE c LENGTH 6 .
  TYPES:
    BEGIN OF ty_object,
      sha1    TYPE zif_abapgit_definitions=>ty_sha1,
      type    TYPE zif_abapgit_definitions=>ty_type,
      data    TYPE xstring,
      adler32 TYPE ty_adler32,
    END OF ty_object .
  TYPES:
    ty_objects_tt TYPE STANDARD TABLE OF ty_object WITH DEFAULT KEY .
  TYPES:
    BEGIN OF ty_tadir,
      pgmid    TYPE tadir-pgmid,
      object   TYPE tadir-object,
      obj_name TYPE tadir-obj_name,
      devclass TYPE tadir-devclass,
      korrnum  TYPE tadir-korrnum,
      path     TYPE string,
    END OF ty_tadir .
  TYPES:
    ty_tadir_tt TYPE STANDARD TABLE OF ty_tadir WITH DEFAULT KEY .
  TYPES:
    BEGIN OF ty_result,
      obj_type TYPE tadir-object,
      obj_name TYPE tadir-obj_name,
      path     TYPE string,
      filename TYPE string,
      package  TYPE devclass,
      match    TYPE sap_bool,
      lstate   TYPE char1,
      rstate   TYPE char1,
    END OF ty_result .
  TYPES:
    ty_results_tt TYPE STANDARD TABLE OF ty_result WITH DEFAULT KEY .
  TYPES:
    ty_sval_tt TYPE STANDARD TABLE OF sval WITH DEFAULT KEY .
  TYPES:
    ty_seocompotx_tt TYPE STANDARD TABLE OF seocompotx WITH DEFAULT KEY .
  TYPES:
    BEGIN OF ty_tpool.
      INCLUDE TYPE textpool.
  TYPES:   split TYPE c LENGTH 8.
  TYPES: END OF ty_tpool .
  TYPES:
    ty_tpool_tt TYPE STANDARD TABLE OF ty_tpool WITH DEFAULT KEY .
  TYPES:
    BEGIN OF ty_sotr,
      header  TYPE sotr_head,
      entries TYPE sotr_text_tt,
    END OF ty_sotr .
  TYPES:
    ty_sotr_tt TYPE STANDARD TABLE OF ty_sotr WITH DEFAULT KEY .
  TYPES:
    BEGIN OF ty_transport_to_branch,
      branch_name TYPE string,
      commit_text TYPE string,
    END OF ty_transport_to_branch .

  TYPES: BEGIN OF ty_create,
           name   TYPE string,
           parent TYPE string,
         END OF ty_create.

  TYPES: BEGIN OF ty_commit,
           sha1       TYPE ty_sha1,
           parent1    TYPE ty_sha1,
           parent2    TYPE ty_sha1,
           author     TYPE string,
           email      TYPE string,
           time       TYPE string,
           message    TYPE string,
           branch     TYPE string,
           merge      TYPE string,
           tags       TYPE stringtab,
           create     TYPE STANDARD TABLE OF ty_create WITH DEFAULT KEY,
           compressed TYPE abap_bool,
         END OF ty_commit.

  TYPES: ty_commit_tt TYPE STANDARD TABLE OF ty_commit WITH DEFAULT KEY.

  CONSTANTS: BEGIN OF c_diff,
               insert TYPE c LENGTH 1 VALUE 'I',
               delete TYPE c LENGTH 1 VALUE 'D',
               update TYPE c LENGTH 1 VALUE 'U',
             END OF c_diff.

  TYPES: BEGIN OF ty_diff,
           new_num TYPE c LENGTH 6,
           new     TYPE string,
           result  TYPE c LENGTH 1,
           old_num TYPE c LENGTH 6,
           old     TYPE string,
           short   TYPE abap_bool,
           beacon  TYPE i,
         END OF ty_diff.
  TYPES:  ty_diffs_tt TYPE STANDARD TABLE OF ty_diff WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_count,
           insert TYPE i,
           delete TYPE i,
           update TYPE i,
         END OF ty_count.

  TYPES:
    BEGIN OF ty_expanded,
      path  TYPE string,
      name  TYPE string,
      sha1  TYPE ty_sha1,
      chmod TYPE ty_chmod,
    END OF ty_expanded .
  TYPES:
    ty_expanded_tt TYPE STANDARD TABLE OF ty_expanded WITH DEFAULT KEY .

  TYPES: BEGIN OF ty_ancestor,
           commit TYPE ty_sha1,
           tree   TYPE ty_sha1,
           time   TYPE string,
           body   TYPE string,
         END OF ty_ancestor.

  TYPES: BEGIN OF ty_merge,
           repo     TYPE REF TO zcl_abapgit_repo_online,
           source   TYPE ty_git_branch,
           target   TYPE ty_git_branch,
           common   TYPE ty_ancestor,
           stree    TYPE ty_expanded_tt,
           ttree    TYPE ty_expanded_tt,
           ctree    TYPE ty_expanded_tt,
           result   TYPE ty_expanded_tt,
           stage    TYPE REF TO zcl_abapgit_stage,
           conflict TYPE string,
         END OF ty_merge.

  TYPES: BEGIN OF ty_merge_conflict,
           path        TYPE string,
           filename    TYPE string,
           source_sha1 TYPE zif_abapgit_definitions=>ty_sha1,
           source_data TYPE xstring,
           target_sha1 TYPE zif_abapgit_definitions=>ty_sha1,
           target_data TYPE xstring,
           result_sha1 TYPE zif_abapgit_definitions=>ty_sha1,
           result_data TYPE xstring,
         END OF ty_merge_conflict,
         tt_merge_conflict TYPE STANDARD TABLE OF ty_merge_conflict WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_repo_item,
           obj_type TYPE tadir-object,
           obj_name TYPE tadir-obj_name,
           sortkey  TYPE i,
           path     TYPE string,
           is_dir   TYPE abap_bool,
           changes  TYPE i,
           lstate   TYPE char1,
           rstate   TYPE char1,
           files    TYPE tt_repo_files,
         END OF ty_repo_item.
  TYPES tt_repo_items TYPE STANDARD TABLE OF ty_repo_item WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_s_user_settings,
           max_lines        TYPE i,
           adt_jump_enabled TYPE abap_bool,
         END OF ty_s_user_settings.

  CONSTANTS gc_xml_version TYPE string VALUE 'v1.0.0' ##NO_TEXT.
  CONSTANTS gc_abap_version TYPE string VALUE 'v1.67.0' ##NO_TEXT.
  CONSTANTS:
    BEGIN OF gc_type,
      commit TYPE zif_abapgit_definitions=>ty_type VALUE 'commit', "#EC NOTEXT
      tree   TYPE zif_abapgit_definitions=>ty_type VALUE 'tree', "#EC NOTEXT
      ref_d  TYPE zif_abapgit_definitions=>ty_type VALUE 'ref_d', "#EC NOTEXT
      tag    TYPE zif_abapgit_definitions=>ty_type VALUE 'tag', "#EC NOTEXT
      blob   TYPE zif_abapgit_definitions=>ty_type VALUE 'blob', "#EC NOTEXT
    END OF gc_type .
  CONSTANTS:
    BEGIN OF gc_state, " https://git-scm.com/docs/git-status
      unchanged TYPE char1 VALUE '',
      added     TYPE char1 VALUE 'A',
      modified  TYPE char1 VALUE 'M',
      deleted   TYPE char1 VALUE 'D', "For future use
      mixed     TYPE char1 VALUE '*',
    END OF gc_state .
  CONSTANTS:
    BEGIN OF gc_chmod,
      file       TYPE ty_chmod VALUE '100644',
      executable TYPE ty_chmod VALUE '100755',
      dir        TYPE ty_chmod VALUE '40000 ',
    END OF gc_chmod .
  CONSTANTS:
    BEGIN OF gc_event_state,
      not_handled         VALUE 0,
      re_render           VALUE 1,
      new_page            VALUE 2,
      go_back             VALUE 3,
      no_more_act         VALUE 4,
      new_page_w_bookmark VALUE 5,
      go_back_to_bookmark VALUE 6,
      new_page_replacing  VALUE 7,
    END OF gc_event_state .
  CONSTANTS:
    BEGIN OF gc_html_opt,
      strong   TYPE c VALUE 'E',
      cancel   TYPE c VALUE 'C',
      crossout TYPE c VALUE 'X',
    END OF gc_html_opt .
  CONSTANTS:
    BEGIN OF gc_action_type,
      sapevent  TYPE c VALUE 'E',
      url       TYPE c VALUE 'U',
      onclick   TYPE c VALUE 'C',
      separator TYPE c VALUE 'S',
      dummy     TYPE c VALUE '_',
    END OF gc_action_type .
  CONSTANTS gc_crlf TYPE abap_cr_lf VALUE cl_abap_char_utilities=>cr_lf ##NO_TEXT.
  CONSTANTS gc_newline TYPE abap_char1 VALUE cl_abap_char_utilities=>newline ##NO_TEXT.
  CONSTANTS gc_english TYPE spras VALUE 'E' ##NO_TEXT.
  CONSTANTS gc_root_dir TYPE string VALUE '/' ##NO_TEXT.
  CONSTANTS gc_dot_abapgit TYPE string VALUE '.abapgit.xml' ##NO_TEXT.
  CONSTANTS gc_author_regex TYPE string VALUE '^([\\\w\s\.\,\#@\-_1-9\(\) ]+) <(.*)> (\d{10})\s?.\d{4}$' ##NO_TEXT.
  CONSTANTS:
    BEGIN OF gc_action,
      repo_refresh             TYPE string VALUE 'repo_refresh',
      repo_remove              TYPE string VALUE 'repo_remove',
      repo_settings            TYPE string VALUE 'repo_settings',
      repo_purge               TYPE string VALUE 'repo_purge',
      repo_newonline           TYPE string VALUE 'repo_newonline',
      repo_newoffline          TYPE string VALUE 'repo_newoffline',
      repo_remote_attach       TYPE string VALUE 'repo_remote_attach',
      repo_remote_detach       TYPE string VALUE 'repo_remote_detach',
      repo_remote_change       TYPE string VALUE 'repo_remote_change',
      repo_refresh_checksums   TYPE string VALUE 'repo_refresh_checksums',
      repo_toggle_fav          TYPE string VALUE 'repo_toggle_fav',
      repo_transport_to_branch TYPE string VALUE 'repo_transport_to_branch',
      repo_syntax_check        TYPE string VALUE 'repo_syntax_check',

      abapgit_home             TYPE string VALUE 'abapgit_home',
      abapgit_wiki             TYPE string VALUE 'abapgit_wiki',
      abapgit_install          TYPE string VALUE 'abapgit_install',
      abapgit_install_pi       TYPE string VALUE 'abapgit_install_pi',

      zip_import               TYPE string VALUE 'zip_import',
      zip_export               TYPE string VALUE 'zip_export',
      zip_package              TYPE string VALUE 'zip_package',
      zip_transport            TYPE string VALUE 'zip_transport',
      zip_object               TYPE string VALUE 'zip_object',

      git_pull                 TYPE string VALUE 'git_pull',
      git_reset                TYPE string VALUE 'git_reset',
      git_branch_create        TYPE string VALUE 'git_branch_create',
      git_branch_switch        TYPE string VALUE 'git_branch_switch',
      git_branch_delete        TYPE string VALUE 'git_branch_delete',
      git_tag_create           TYPE string VALUE 'git_tag_create',
      git_tag_delete           TYPE string VALUE 'git_tag_delete',
      git_tag_switch           TYPE string VALUE 'git_tag_switch',
      git_commit               TYPE string VALUE 'git_commit',

      db_display               TYPE string VALUE 'db_display',
      db_edit                  TYPE string VALUE 'db_edit',
      bg_update                TYPE string VALUE 'bg_update',

      go_main                  TYPE string VALUE 'go_main',
      go_explore               TYPE string VALUE 'go_explore',
      go_db                    TYPE string VALUE 'go_db',
      go_background            TYPE string VALUE 'go_background',
      go_background_run        TYPE string VALUE 'go_background_run',
      go_diff                  TYPE string VALUE 'go_diff',
      go_stage                 TYPE string VALUE 'go_stage',
      go_commit                TYPE string VALUE 'go_commit',
      go_branch_overview       TYPE string VALUE 'go_branch_overview',
      go_tag_overview          TYPE string VALUE 'go_tag_overview',
      go_playground            TYPE string VALUE 'go_playground',
      go_debuginfo             TYPE string VALUE 'go_debuginfo',
      go_settings              TYPE string VALUE 'go_settings',
      go_tutorial              TYPE string VALUE 'go_tutorial',

      jump                     TYPE string VALUE 'jump',
      jump_pkg                 TYPE string VALUE 'jump_pkg',
    END OF gc_action .
  CONSTANTS:
    BEGIN OF gc_version,
      active   TYPE r3state VALUE 'A',
      inactive TYPE r3state VALUE 'I',
    END OF gc_version .
  CONSTANTS gc_tag_prefix TYPE string VALUE 'refs/tags/' ##NO_TEXT.

ENDINTERFACE.
