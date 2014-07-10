#.rst:
# YCMEPHelper
# -----------
#
# A helper for :module:`ExternalProject`::
#
#  ycm_ep_helper(<name>
#    [DOCS]
#    [TYPE <type>]
#    [STYLE <style>]
#    [COMPONENT <component>] (default = "external")
#    [REPOSITORY <repo>]
#    [EXCLUDE_FROM_ALL <0|1>]
#   #--Git only arguments-----------
#    [TAG <tag>]
#   #--Svn only arguments-----------
#    [REVISION <revision>]
#    [USERNAME <username>]
#    [PASSWORD <password>]
#    [TRUST_CERT <0|1>]
#   #--CMake arguments---------
#    [CMAKE_ARGS]
#    [CMAKE_CACHE_ARGS]
#    [DEPENDS]
#    [DOWNLOAD_COMMAND]
#    [UPDATE_COMMAND]
#    [PATCH_COMMAND]
#    [CONFIGURE_COMMAND]
#    [BUILD_COMMAND]
#    [INSTALL_COMMAND]
#    [TEST_COMMAND]
#    [CLEAN_COMMAND] (not in ExternalProject)
#    )
#
#  YCM_BOOTSTRAP()
#
# .. variable:: NON_INTERACTIVE_BUILD
#
# .. variable:: YCM_BOOTSTRAP_BASE_ADDRESS
#
# .. variable:: YCM_SKIP_HASH_CHECK
#
# .. variable:: YCM_BOOTSTRAP_VERBOSE
#

# TODO Add variable YCM_INSTALL_PREFIX

#=============================================================================
# Copyright 2013-2014 iCub Facility, Istituto Italiano di Tecnologia
#   Authors: Daniele E. Domenichelli <daniele.domenichelli@iit.it>
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distribute this file outside of YCM, substitute the full
#  License text for the above reference.)


if(DEFINED __YCMEPHELPER_INCLUDED)
  return()
endif()
set(__YCMEPHELPER_INCLUDED TRUE)



########################################################################
# Hashes of YCM files to be checked

# Files downloaded during YCM bootstrap
set(_ycm_CMakeParseArguments_sha1sum 0c4d3f7ed248145cbeb67cbd6fd7190baf2e4517)
set(_ycm_ExternalProject_sha1sum     3a575c379969d8ae2f40dddc79db139aab0de39f)

# Files in all projects that need to bootstrap YCM
set(_ycm_IncludeUrl_sha1sum          6d865c7d82ea88b655417a7e7b438d049e0f0655)
set(_ycm_YCMBootstrap_sha1sum        39aae494b6706887af042d2bef83bed1fa278c3b)


########################################################################
# _YCM_INCLUDE
#
# Internal macro to include files from cmake-next.
# If YCM was not found, we are bootstrapping, therefore we need to
# download and use these modules instead of the ones found by cmake
# This must be a macro and not a function in order not to enclose in a
# new scope the variables added by the included files.

macro(_YCM_INCLUDE _module)
    if(YCM_FOUND)
        include(${_module})
    else()
        # We assume that YCMEPHelper was included using include_url, or that at
        # least the IncludeUrl command exists.
        if(NOT COMMAND include_url)
            include(IncludeUrl)
        endif()
        unset(_expected_hash_args)
        if(NOT YCM_SKIP_HASH_CHECK)
            set(_expected_hash_args EXPECTED_HASH SHA1=${_ycm_${_module}_sha1sum})
        endif()
        include_url(${YCM_BOOTSTRAP_BASE_ADDRESS}/cmake-next/Modules/${_module}.cmake
                    ${_expected_hash_args}
                    STATUS _download_status)
        if(NOT _download_status EQUAL 0)
            list(GET 0 _download_status _download_status_0)
            list(GET 1 _download_status _download_status_1)
            message(FATAL_ERROR "Download failed with ${_download_status_0}: ${_download_status_1}")
        endif()

        unset(_expected_hash_args)
        unset(_download_status)
        unset(_download_status_0)
        unset(_download_status_1)
    endif()
endmacro()


########################################################################
# _YCM_HASH_CHECK
#
# Internal function to check if a module in user repository is updated
# at the latest version and eventually print an AUTHOR_WARNING.
#
# if the variable YCM_SKIP_HASH_CHECK is set it does nothing

function(_YCM_HASH_CHECK _module)
    if(YCM_SKIP_HASH_CHECK)
        return()
    endif()

    # FIXME is there a way to find the module without including it?
    include(${_module} RESULT_VARIABLE _module_file OPTIONAL)
    if(_module_file)
        file(SHA1 ${_module_file} _module_sha1sum)
        if(NOT "${_module_sha1sum}" STREQUAL "${_ycm_${_module}_sha1sum}")
            message(AUTHOR_WARNING
"YCM_BOOTSTRAP HASH mismatch
  for file: [${_module_file}]
    expected hash: [${_ycm_${_module}_sha1sum}]
      actual hash: [${_module_sha1sum}]
Perhaps it is outdated or you have local modification. Please consider upgrading it, or contributing your changes to YCM.
")
        endif()
    endif()
endfunction()



########################################################################
# _YCM_SETUP
#
# Internal function to perform generic setup.
# This must be a macro and not a function in order not to enclose in a
# new scope the variables added by the included files.

unset(__YCM_SETUP_CALLED)
macro(_YCM_SETUP)
    if(DEFINED __YCM_SETUP_CALLED)
        return()
    endif()
    set(__YCM_SETUP_CALLED 1)

    _ycm_include(CMakeParseArguments)
    _ycm_include(ExternalProject)

    set_property(DIRECTORY PROPERTY EP_SOURCE_DIR_PERSISTENT 1)
    if(NOT NON_INTERACTIVE_BUILD)
      # Non interactive builds should always perform the update step
      set_property(DIRECTORY PROPERTY EP_SCM_DISCONNECTED 1)
    endif()
    set_property(DIRECTORY PROPERTY CMAKE_PARSE_ARGUMENTS_DEFAULT_SKIP_EMPTY FALSE)
    set_property(GLOBAL PROPERTY USE_FOLDERS ON)

    set(CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY 1)
    set(CMAKE_FIND_PACKAGE_NO_SYSTEM_PACKAGE_REGISTRY 1)

    option(YCM_EP_EXPERT_MODE "Enable all targets for projects in development mode" OFF)
    option(YCM_EP_MAINTAINER_MODE "Enable all targets for projects in development mode" OFF)
    mark_as_advanced(YCM_EP_EXPERT_MODE
                     YCM_EP_MAINTAINER_MODE)

    if(MSVC_VERSION OR XCODE_VERSION)
        set(_update-all ALL_UPDATE)
        set(_fetch-all ALL_FETCH)
        set(_status-all ALL_STATUS)
        set(_clean-all ALL_CLEAN)
        set(_print-directories-all ALL_PRINT_DIRECTORIES)
    else()
        set(_update-all update-all)
        set(_fetch-all fetch-all)
        set(_status-all status-all)
        set(_clean-all clean-all)
        set(_print-directories-all print-directories-all)
    endif()

    if(NOT YCM_FOUND) # Useless if we don't need to bootstrap
        set(YCM_BOOTSTRAP_BASE_ADDRESS "https://raw.github.com/robotology/ycm/HEAD/" CACHE STRING "Base address of YCM repository")
        mark_as_advanced(YCM_BOOTSTRAP_BASE_ADDRESS)
    endif()
endmacro()


########################################################################
# _YCM_SETUP_GIT
#
# Internal function to perform GIT setup.

unset(__YCM_GIT_SETUP_CALLED CACHE)
function(_YCM_SETUP_GIT)
    if(DEFINED __YCM_GIT_SETUP_CALLED)
        return()
    endif()
    set(__YCM_GIT_SETUP_CALLED 1 CACHE INTERNAL "")

    find_package(Git QUIET)
    if(NOT GIT_EXECUTABLE)
        message(FATAL_ERROR "Please install Git")
    endif()

    execute_process(COMMAND ${GIT_EXECUTABLE} config --get user.name
                    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                    RESULT_VARIABLE _error_code
                    OUTPUT_VARIABLE _output_name
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(NOT NON_INTERACTIVE_BUILD AND _error_code)
        message(FATAL_ERROR "Failed to get name to use for git commits. Please set it with \"git config --global user.name Firstname Lastname\"")
    endif()

    execute_process(COMMAND ${GIT_EXECUTABLE} config --get user.email
                    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                    RESULT_VARIABLE _error_code
                    OUTPUT_VARIABLE _output_email
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(NOT NON_INTERACTIVE_BUILD AND _error_code)
        message(FATAL_ERROR "Failed to get name to use for git commits. Please set it with \"git config --global user.email name@example.com\"")
    endif()

    set(YCM_GIT_COMMIT_NAME "${_output_name}" CACHE STRING "Name to use for git commits")
    set(YCM_GIT_COMMIT_EMAIL "${_output_email}" CACHE STRING "Email address to use for git commits")
    mark_as_advanced(YCM_GIT_COMMIT_NAME YCM_GIT_COMMIT_EMAIL)


    # TYPE GIT STYLE GITHUB
    set(YCM_GIT_GITHUB_USERNAME "" CACHE STRING "Username to use for github git repositories")
    set(YCM_GIT_GITHUB_COMMIT_NAME "" CACHE STRING "Name to use for git commits for github git repositories (if empty will use YCM_GIT_COMMIT_NAME)")
    set(YCM_GIT_GITHUB_COMMIT_EMAIL "" CACHE STRING "Email address to use for git commits for github git repositories (if empty will use YCM_GIT_COMMIT_EMAIL)")
    set(YCM_GIT_GITHUB_BASE_ADDRESS "https://github.com/" CACHE STRING "Address to use for github git repositories")
    set_property(CACHE YCM_GIT_GITHUB_BASE_ADDRESS PROPERTY STRINGS "https://github.com/"
                                                                    "git://github.com/"
                                                                    "ssh://git@github.com/"
                                                                    "git@github.com:"
                                                                    "github:")
    mark_as_advanced(YCM_GIT_GITHUB_USERNAME
                     YCM_GIT_GITHUB_COMMIT_NAME
                     YCM_GIT_GITHUB_COMMIT_EMAIL
                     YCM_GIT_GITHUB_BASE_ADDRESS)


    # TYPE GIT STYLE KDE
    set(YCM_GIT_KDE_USERNAME "" CACHE STRING "Username to use for kde git repositories")
    set(YCM_GIT_KDE_COMMIT_NAME "" CACHE STRING "Name to use for git commits for kde git repositories (if empty will use YCM_GIT_COMMIT_NAME)")
    set(YCM_GIT_KDE_COMMIT_EMAIL "" CACHE STRING "Email address to use for git commits for kde git repositories (if empty will use YCM_GIT_COMMIT_EMAIL)")
    set(YCM_GIT_KDE_BASE_ADDRESS "git://anongit.kde.org/" CACHE STRING "Address to use for kde git repositories")
    set_property(CACHE YCM_GIT_KDE_BASE_ADDRESS PROPERTY STRINGS "git://anongit.kde.org/"
                                                                 "ssh://git@git.kde.org/"
                                                                 "git@git.kde.org:"
                                                                 "kde:")
    mark_as_advanced(YCM_GIT_KDE_USERNAME
                     YCM_GIT_KDE_COMMIT_NAME
                     YCM_GIT_KDE_COMMIT_EMAIL
                     YCM_GIT_KDE_BASE_ADDRESS)


    # TYPE GIT STYLE GNOME
    set(YCM_GIT_GNOME_USERNAME "" CACHE STRING "Username to use for gnome git repositories")
    set(YCM_GIT_GNOME_COMMIT_NAME "" CACHE STRING "Name to use for git commits for gnome git repositories (if empty will use YCM_GIT_COMMIT_NAME)")
    set(YCM_GIT_GNOME_COMMIT_EMAIL "" CACHE STRING "Email address to use for git commits for gnome git repositories (if empty will use YCM_GIT_COMMIT_EMAIL)")
    set(YCM_GIT_GNOME_BASE_ADDRESS "git://git.gnome.org/" CACHE STRING "Address to use for gnome git repositories")
    set_property(CACHE YCM_GIT_GNOME_BASE_ADDRESS PROPERTY STRINGS "git://git.gnome.org/"
                                                                   "ssh://git@git.gnome.org/"
                                                                   "git@git.gnome.org:"
                                                                   "gnome:")
    mark_as_advanced(YCM_GIT_GNOME_USERNAME
                     YCM_GIT_GNOME_COMMIT_NAME
                     YCM_GIT_GNOME_COMMIT_EMAIL
                     YCM_GIT_GNOME_BASE_ADDRESS)


    # TYPE GIT STYLE SOURCEFORGE
    set(YCM_GIT_SOURCEFORGE_USERNAME "" CACHE STRING "Username to use for sourceforge git repositories")
    set(YCM_GIT_SOURCEFORGE_COMMIT_NAME "" CACHE STRING "Name to use for git commits for sourceforge git repositories (if empty will use YCM_GIT_COMMIT_NAME)")
    set(YCM_GIT_SOURCEFORGE_COMMIT_EMAIL "" CACHE STRING "Email address to use for git commits for sourceforge git repositories (if empty will use YCM_GIT_COMMIT_EMAIL)")
    set(YCM_GIT_SOURCEFORGE_BASE_ADDRESS "git://git.code.sf.net/p/" CACHE STRING "Address to use for sourceforge git repositories")
    set_property(CACHE YCM_GIT_SOURCEFORGE_BASE_ADDRESS PROPERTY STRINGS "git://git.code.sf.net/p/"
                                                                         "ssh://${YCM_GIT_SOURCEFORGE_USERNAME}@git.code.sf.net/p/"
                                                                         "${YCM_GIT_SOURCEFORGE_USERNAME}@git.code.sf.net:p/"
                                                                         "sf:")
    mark_as_advanced(YCM_GIT_SOURCEFORGE_USERNAME
                     YCM_GIT_SOURCEFORGE_COMMIT_NAME
                     YCM_GIT_SOURCEFORGE_COMMIT_EMAIL
                     YCM_GIT_SOURCEFORGE_BASE_ADDRESS)


    # TYPE GIT STYLE GITLAB_ICUB_ORG
    set(YCM_GIT_GITLAB_ICUB_ORG_USERNAME "" CACHE STRING "Username to use for IIT iCub Facility Gitlab git repositories")
    set(YCM_GIT_GITLAB_ICUB_ORG_COMMIT_NAME "" CACHE STRING "Name to use for git commits for IIT iCub Facility Gitlab git repositories (if empty will use YCM_GIT_COMMIT_NAME)")
    set(YCM_GIT_GITLAB_ICUB_ORG_COMMIT_EMAIL "" CACHE STRING "Email address to use for git commits for IIT iCub Facility Gitlab git repositories (if empty will use YCM_GIT_COMMIT_EMAIL)")
    set(YCM_GIT_GITLAB_ICUB_ORG_BASE_ADDRESS "https://gitlab.icub.org/" CACHE STRING "Address to use for IIT iCub Facility Gitlab git repositories")
    set_property(CACHE YCM_GIT_GITLAB_ICUB_ORG_BASE_ADDRESS PROPERTY STRINGS "https://gitlab.icub.org/"
                                                                             "git://gitlab.icub.org/"
                                                                             "ssh://git@gitlab.icub.org/"
                                                                             "git@gitlab.icub.org:"
                                                                             "icub:")
    mark_as_advanced(YCM_GIT_GITLAB_ICUB_ORG_USERNAME
                     YCM_GIT_GITLAB_ICUB_ORG_COMMIT_NAME
                     YCM_GIT_GITLAB_ICUB_ORG_COMMIT_EMAIL
                     YCM_GIT_GITLAB_ICUB_ORG_BASE_ADDRESS)

    # TYPE GIT STYLE GITLAB_ROBOTOLOGY
    set(YCM_GIT_GITLAB_ROBOTOLOGY_USERNAME "" CACHE STRING "Username to use for IIT Robotology Gitlab git repositories")
    set(YCM_GIT_GITLAB_ROBOTOLOGY_COMMIT_NAME "" CACHE STRING "Name to use for git commits for IIT Robotology Gitlab git repositories (if empty will use YCM_GIT_COMMIT_NAME)")
    set(YCM_GIT_GITLAB_ROBOTOLOGY_COMMIT_EMAIL "" CACHE STRING "Email address to use for git commits for IIT Robotology Gitlab git repositories (if empty will use YCM_GIT_COMMIT_EMAIL)")
    set(YCM_GIT_GITLAB_ROBOTOLOGY_BASE_ADDRESS "https://gitlab.icub.org/" CACHE STRING "Address to use for IIT Robotology Gitlab git repositories")
    set_property(CACHE YCM_GIT_GITLAB_ROBOTOLOGY_BASE_ADDRESS PROPERTY STRINGS "https://gitlab.icub.org/"
                                                                               "git://gitlab.icub.org/"
                                                                               "ssh://git@gitlab.icub.org/"
                                                                               "git@gitlab.robotology.eu:"
                                                                               "icub:")
    mark_as_advanced(YCM_GIT_GITLAB_ROBOTOLOGY_USERNAME
                     YCM_GIT_GITLAB_ROBOTOLOGY_COMMIT_NAME
                     YCM_GIT_GITLAB_ROBOTOLOGY_COMMIT_EMAIL
                     YCM_GIT_GITLAB_ROBOTOLOGY_BASE_ADDRESS)


    # TYPE GIT STYLE LOCAL
    set(YCM_GIT_LOCAL_BASE_ADDRESS "" CACHE INTERNAL "Address to use for local git repositories")


    # TYPE GIT STYLE NONE
    set(YCM_GIT_NONE_BASE_ADDRESS "" CACHE INTERNAL "Address to use for other git repositories")

endfunction()


########################################################################
# _YCM_SETUP_SVN
#
# Internal function to perform SVN setup.

unset(__YCM_SVN_SETUP_CALLED CACHE)
function(_YCM_SETUP_SVN)
    if(DEFINED __YCM_SVN_SETUP_CALLED)
        return()
    endif()
    set(__YCM_SVN_SETUP_CALLED 1 CACHE INTERNAL "")

    find_package(Subversion QUIET)
    if(NOT Subversion_SVN_EXECUTABLE)
        message(FATAL_ERROR "Please install Svn")
    endif()

    # TYPE SVN STYLE SOURCEFORGE
    set(YCM_SVN_SOURCEFORGE_USERNAME "" CACHE STRING "Username to use for sourceforge svn repositories")
    set(YCM_SVN_SOURCEFORGE_PASSWORD "" CACHE STRING "Password to use for sourceforge svn repositories")
    set(YCM_SVN_SOURCEFORGE_BASE_ADDRESS "https://svn.code.sf.net/p/" CACHE INTERNAL "Address to use for sourceforge svn repositories")
    mark_as_advanced(YCM_SVN_SOURCEFORGE_USERNAME
                     YCM_SVN_SOURCEFORGE_PASSWORD)
endfunction()


########################################################################
# _YCM_EP_ADD_UPDATE_STEP
#
# Add "update" step for any repository.

function(_YCM_EP_ADD_UPDATE_STEP)
    if(NOT TARGET ${_update-all})
        add_custom_target(${_update-all})
        set_property(TARGET ${_update-all} PROPERTY FOLDER "YCMTargets")
    endif()

    # The update step is automatically created, we just need to explicitly
    # make it a target
    ExternalProject_Add_StepTargets(${_name} NO_DEPENDS update)
    add_dependencies(${_update-all} ${_name}-update)
endfunction()


########################################################################
# _YCM_EP_ADD_CONFIGURE_STEP
#
# Add "configure" step for any repository.

function(_YCM_EP_ADD_CONFIGURE_STEP)
    # The condigure step is automatically created, we just need to explicitly
    # make it a target
    ExternalProject_Add_StepTargets(${_name} configure)
endfunction()


########################################################################
# _YCM_EP_ADD_FETCH_STEP
#
# Add "fetch" step for git repositories.

function(_YCM_EP_ADD_FETCH_STEP _name)
    if("${_YH_${_name}_TYPE}" STREQUAL "GIT")
        if(NOT TARGET ${_fetch-all})
            add_custom_target(${_fetch-all})
            set_property(TARGET ${_fetch-all} PROPERTY FOLDER "YCMTargets")
        endif()

        ExternalProject_Add_Step(${_name} fetch
                                 COMMAND ${GIT_EXECUTABLE} fetch --all --prune
                                 WORKING_DIRECTORY ${${_name}_SOURCE_DIR}
                                 COMMENT "Performing fetch step for '${_name}'"
                                 DEPENDEES download
                                 EXCLUDE_FROM_MAIN 1
                                 ALWAYS 1)
        ExternalProject_Add_StepTargets(${_name} NO_DEPENDS fetch)
        add_dependencies(${_fetch-all} ${_name}-fetch)
    endif()
endfunction()


########################################################################
# _YCM_EP_ADD_STATUS_STEP
#
# Add "status" step for git and svn repositories.

function(_YCM_EP_ADD_STATUS_STEP _name)
    unset(_cmd)
    if("${_YH_${_name}_TYPE}" STREQUAL "GIT")
        set(_cmd COMMAND ${GIT_EXECUTABLE} status)
    elseif("${_YH_${_name}_TYPE}" STREQUAL "SVN")
        set(_cmd COMMAND ${Subversion_SVN_EXECUTABLE} status)
    endif()

    if(DEFINED _cmd)
        if(NOT TARGET ${_status-all})
            add_custom_target(${_status-all})
            set_property(TARGET ${_status-all} PROPERTY FOLDER "YCMTargets")
        endif()

        ExternalProject_Get_Property(${_name} source_dir)
        ExternalProject_Add_Step(${_name} status
                                 COMMAND ${CMAKE_COMMAND} -E cmake_echo_color --switch=$(COLOR) --cyan "Working directory: ${source_dir}"
                                 ${_cmd}
                                 WORKING_DIRECTORY ${source_dir}
                                 DEPENDEES download
                                 EXCLUDE_FROM_MAIN 1
                                 ALWAYS 1)
        ExternalProject_Add_StepTargets(${_name} NO_DEPENDS status)
        add_dependencies(${_status-all} ${_name}-status)
        unset(_cmd)
    endif()
endfunction()


########################################################################
# _YCM_EP_ADD_CLEAN_STEP
#
# Add "clean" step for any repository.

function(_YCM_EP_ADD_CLEAN_STEP _name)
    unset(_cmd)
# FIXME is _YH_${_name}_CLEAN_COMMAND to the function?

    if(NOT DEFINED _YH_${_name}_CLEAN_COMMAND OR _YH_${_name}_CLEAN_COMMAND STREQUAL "_")
        set(_cmd ${CMAKE_COMMAND} --build ${${_name}_BINARY_DIR} --config ${CMAKE_CFG_INTDIR} --target clean)
    elseif(NOT "${_YH_${_name}_CLEAN_COMMAND}" STREQUAL "")
        set(_cmd ${_YH_${_name}_CLEAN_COMMAND})
    endif()
    if(DEFINED _cmd)
        if(NOT TARGET ${_clean-all})
            add_custom_target(${_clean-all})
            set_property(TARGET ${_clean-all} PROPERTY FOLDER "YCMTargets")
        endif()

        ExternalProject_Add_Step(${_name} clean
                                 COMMAND ${_cmd}
                                 WORKING_DIRECTORY ${${_name}_BINARY_DIR}
                                 COMMENT "Performing clean step for '${_name}'"
                                 DEPENDEES configure
                                 EXCLUDE_FROM_MAIN 1
                                 ALWAYS 1)
        ExternalProject_Add_StepTargets(${_name} NO_DEPENDS clean)
        add_dependencies(${_clean-all} ${_name}-clean)
        unset(_cmd)
    endif()
endfunction()

########################################################################
# _YCM_EP_ADD_DEPENDEES_STEPS
#
# Add "dependees" and "dependees-update" steps for all the `DEPENDS` of any
# repository, if these are in development mode.

function(_YCM_EP_ADD_DEPENDEES_STEPS _name)
    get_property(_depends_set TARGET ${_name} PROPERTY _EP_DEPENDS SET)

    if(_depends_set)
        get_property(_binary_dir TARGET ${_name} PROPERTY _EP_BINARY_DIR)
        get_property(_depends TARGET ${_name} PROPERTY _EP_DEPENDS)

        # dependees step (build all packages required by this package)
        ExternalProject_Add_Step(${_name} dependees
                                 WORKING_DIRECTORY ${_binary_dir}
                                 COMMENT "Dependencies for '${_name}' built."
                                 EXCLUDE_FROM_MAIN 1
                                 ALWAYS 1)
        ExternalProject_Add_StepTargets(${_name} NO_DEPENDS dependees)
        foreach(_dep ${_depends})
            if(TARGET ${_dep})
                ExternalProject_Add_StepDependencies(${_name} dependees ${_dep})
            endif()
        endforeach()

        # dependees-update step (update all packages required by this package)
        ExternalProject_Add_Step(${_name} dependees-update
                                 WORKING_DIRECTORY ${binary_dir}
                                 COMMENT "Dependencies for '${_name}' updated."
                                 EXCLUDE_FROM_MAIN 1
                                 ALWAYS 1)
        ExternalProject_Add_StepTargets(${_name} NO_DEPENDS dependees-update)
        foreach(_dep ${_depends})
            if(TARGET ${_dep}-update) # only if the target update exists for the dependency
                ExternalProject_Add_StepDependencies(${_name} dependees-update ${_dep}-update)
            endif()
        endforeach()
    endif()
endfunction()


########################################################################
# _YCM_EP_ADD_DEPENDERS_STEPS
#
# Add "dependers" and "dependers-update" steps for any "DEPENDS" of this
# repository.

function(_YCM_EP_ADD_DEPENDERS_STEPS _name)
    get_property(_depends_set TARGET ${_name} PROPERTY _EP_DEPENDS SET)

    if(_depends_set)
        get_property(_depends TARGET ${_name} PROPERTY _EP_DEPENDS)
        foreach(_dep ${_depends})
            if(TARGET ${_dep})
                get_property(is_ep TARGET ${_dep} PROPERTY _EP_IS_EXTERNAL_PROJECT)
                if(is_ep)
                    if(YCM_EP_DEVEL_MODE_${_dep} OR YCM_EP_MAINTAINER_MODE)
                        get_property(_dep_binary_dir TARGET ${_dep} PROPERTY _EP_BINARY_DIR)

                        # dependers step (build all packages that require this package)
                        if(NOT TARGET ${_dep}-dependers)
                            ExternalProject_Add_Step(${_dep} dependers
                                                     WORKING_DIRECTORY ${_dep_binary_dir}
                                                     COMMENT "Dependers for '${_dep}' built."
                                                     EXCLUDE_FROM_MAIN 1
                                                     ALWAYS 1)
                            ExternalProject_Add_StepTargets(${_dep} NO_DEPENDS dependers)
                        endif()
                        ExternalProject_Add_StepDependencies(${_dep} dependers ${_name})

                        # dependers-update step (update all packages that require this package)
                        if(TARGET ${_name}-update)
                            if(NOT TARGET ${_dep}-dependers-update)
                                ExternalProject_Add_Step(${_dep} dependers-update
                                                         WORKING_DIRECTORY ${${_dep}_BINARY_DIR}
                                                         COMMENT "Dependers for '${_dep}' updated."
                                                         EXCLUDE_FROM_MAIN 1
                                                         ALWAYS 1)
                                ExternalProject_Add_StepTargets(${_dep} NO_DEPENDS dependers-update)
                            endif()
                            ExternalProject_Add_StepDependencies(${_dep} dependers-update ${_name}-update)
                        endif()
                    endif()
                endif()
            endif()
        endforeach()
    endif()
endfunction()


########################################################################
# _YCM_EP_ADD_EDIT_CACHE_STEP
#
# Add "edit_cache" step for cmake repositories.

function(_YCM_EP_ADD_EDIT_CACHE_STEP _name)
    # edit cache target for cmake projects
    _ep_get_configure_command_id(${_name} _${_name}_configure_command_id)
    if(_${_name}_configure_command_id STREQUAL "cmake")

        ExternalProject_Add_Step(${_name} edit_cache
                                 COMMAND ${CMAKE_EDIT_COMMAND} -H${_source_dir} -B${_binary_dir}
                                 WORKING_DIRECTORY ${${_name}_BUILD_DIR}
                                 DEPENDEES configure
                                 EXCLUDE_FROM_MAIN 1
                                 COMMENT "Running CMake cache editor for ${_name}..."
                                 ALWAYS 1)
        ExternalProject_Add_StepTargets(${_name} NO_DEPENDS edit_cache)
    endif()
endfunction()


########################################################################
# _YCM_EP_ADD_PRINT_DIRECTORIES_STEP
#
# Add "print-directories" step for any repository.
# This step prints source and build directories for an external project.

function(_YCM_EP_ADD_PRINT_DIRECTORIES_STEP _name)
    if(NOT TARGET ${_print-directories-all})
        add_custom_target(${_print-directories-all})
        set_property(TARGET ${_print-directories-all} PROPERTY FOLDER "YCMTargets")
    endif()

    get_property(_source_dir TARGET ${_name} PROPERTY _EP_SOURCE_DIR)
    get_property(_binary_dir TARGET ${_name} PROPERTY _EP_BINARY_DIR)

    ExternalProject_Add_Step(${_name} print-directories
                             COMMAND ${CMAKE_COMMAND} -E echo ""
                             COMMAND ${CMAKE_COMMAND} -E cmake_echo_color --switch=$(COLOR) --cyan "${_name} SOURCE directory: "
                             COMMAND ${CMAKE_COMMAND} -E echo "    ${_source_dir}"
                             COMMAND ${CMAKE_COMMAND} -E echo ""
                             COMMAND ${CMAKE_COMMAND} -E cmake_echo_color --switch=$(COLOR) --cyan "${_name} BINARY directory: "
                             COMMAND ${CMAKE_COMMAND} -E echo "    ${_binary_dir}"
                             COMMAND ${CMAKE_COMMAND} -E echo ""
                             WORKING_DIRECTORY ${_source_dir}
                             EXCLUDE_FROM_MAIN 1
                             COMMENT "Directories for ${_name}"
                             ALWAYS 1)
    ExternalProject_Add_StepTargets(${_name} NO_DEPENDS print-directories)
    add_dependencies(${_print-directories-all} ${_name}-print-directories)
endfunction()


########################################################################
# YCM_EP_HELPER
#
# Helper function to add a repository using ExternalProject

function(YCM_EP_HELPER _name)
    # Adding target twice is not allowed
    if(TARGET ${_name})
        message(WARNING "Failed to add target ${_name}. A target with the same name already exists.")
        return()
    endif()
    # Check arguments
    set(_options )
    set(_oneValueArgs TYPE
                      STYLE
                      COMPONENT
                      REPOSITORY
                      EXCLUDE_FROM_ALL
                      TAG         # GIT only
                      REVISION    # SVN only
                      USERNAME    # SVN only
                      PASSWORD    # SVN only
                      TRUST_CERT) # SVN only
    set(_multiValueArgs CMAKE_ARGS
                        CMAKE_CACHE_ARGS
                        DEPENDS
                        DOWNLOAD_COMMAND
                        UPDATE_COMMAND
                        PATCH_COMMAND
                        CONFIGURE_COMMAND
                        BUILD_COMMAND
                        INSTALL_COMMAND
                        TEST_COMMAND
                        CLEAN_COMMAND)

    cmake_parse_arguments(_YH_${_name} "${_options}" "${_oneValueArgs}" "${_multiValueArgs}" "${ARGN}")

    # Allow to override parameters by setting variables
    foreach(_arg ${_oneValueArgs} ${_multiValueArgs})
        if(DEFINED ${_name}_${_arg})
            set(_YH_${_name}_${_arg} ${${_name}_${_arg}})
        endif()
    endforeach()


    # Check that all required arguments are set
    if(NOT DEFINED _YH_${_name}_TYPE)
        message(FATAL_ERROR "Missing TYPE argument")
    endif()
    if(NOT "x${_YH_${_name}_TYPE}" MATCHES "^x(GIT|SVN)$")
        message(FATAL_ERROR "Unsupported VCS TYPE:\n  ${_YH_${_name}_TYPE}\n")
    endif()
    if("${_YH_${_name}_TYPE}" STREQUAL "GIT")
      # TODO Check GIT arguments
    elseif("${_YH_${_name}_TYPE}" STREQUAL "SVN")
      # TODO Check SVN arguments
    endif()

    if(NOT DEFINED _YH_${_name}_STYLE)
        message(FATAL_ERROR "Missing STYLE argument")
    endif()

    if(NOT DEFINED _YH_${_name}_REPOSITORY)
        message(FATAL_ERROR "Missing REPOSITORY argument")
    endif()

    if(NOT DEFINED _YH_${_name}_COMPONENT)
        set(_YH_${_name}_COMPONENT external)
#     elseif(NOT "x${_YH_${_name}_COMPONENT}" MATCHES "^x(external|documentation)$")
#         message(WARNING "Unknown component:\n  ${_YH_${_name}_COMPONENT}\n")
    elseif(_YH_${_name}_COMPONENT STREQUAL "build")
        message(AUTHOR_WARNING "Using \"build\" is dangerous, you should choose another name for the component.")
    endif()

    # Generic variables
    set(${_name}_PREFIX ${CMAKE_BINARY_DIR}/${_YH_${_name}_COMPONENT})
    set(${_name}_SOURCE_DIR ${CMAKE_SOURCE_DIR}/${_YH_${_name}_COMPONENT}/${_name})
    set(${_name}_DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/${_YH_${_name}_COMPONENT})
    set(${_name}_BINARY_DIR ${CMAKE_BINARY_DIR}/${_YH_${_name}_COMPONENT}/${_name})
    set(${_name}_INSTALL_DIR ${CMAKE_BINARY_DIR}/install) # TODO Use a cached variable for installation outside build directory
    set(${_name}_TMP_DIR ${CMAKE_BINARY_DIR}/${_YH_${_name}_COMPONENT}/${_name}${CMAKE_FILES_DIRECTORY}/YCMTmp)
    set(${_name}_STAMP_DIR ${CMAKE_BINARY_DIR}/${_YH_${_name}_COMPONENT}/${_name}${CMAKE_FILES_DIRECTORY}/YCMStamp)

    set(${_name}_DIR_ARGS PREFIX ${${_name}_PREFIX}
                          SOURCE_DIR ${${_name}_SOURCE_DIR}
                          DOWNLOAD_DIR ${${_name}_DOWNLOAD_DIR}
                          BINARY_DIR ${${_name}_BINARY_DIR}
                          INSTALL_DIR ${${_name}_INSTALL_DIR}
                          TMP_DIR ${${_name}_TMP_DIR}
                          STAMP_DIR ${${_name}_STAMP_DIR})

    # ExternalProject does not handle correctly arguments containing ";" passed
    # using CMAKE_ARGS, and instead splits them into several arguments. This is
    # a workaround that replaces ";" with "|" and sets LIST_SEPARATOR "|" in
    # order to interpret them correctly.
    #
    # TODO FIXME check what happens when the "*_COMMAND" arguments are passed.
    file(TO_CMAKE_PATH "$ENV{CMAKE_PREFIX_PATH}" _CMAKE_PREFIX_PATH)
    list(APPEND _CMAKE_PREFIX_PATH ${${_name}_INSTALL_DIR})
    list(REMOVE_DUPLICATES _CMAKE_PREFIX_PATH)
    string(REPLACE ";" "|" _CMAKE_PREFIX_PATH "${_CMAKE_PREFIX_PATH}")
    set(${_name}_CMAKE_ARGS "--no-warn-unused-cli"
                            "-DCMAKE_PREFIX_PATH:PATH=${_CMAKE_PREFIX_PATH}"      # Path used by cmake for finding stuff
                            "-DCMAKE_INSTALL_PREFIX:PATH=${${_name}_INSTALL_DIR}" # Where to do the installation
                            "-DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}"       # If there is a CMAKE_BUILD_TYPE it is important to ensure it is passed down.
                            "-DCMAKE_SKIP_RPATH:PATH=\"${CMAKE_SKIP_RPATH}\""
                            "-DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}")
    if(_YH_${_name}_CMAKE_ARGS)
        list(APPEND ${_name}_CMAKE_ARGS ${_YH_${_name}_CMAKE_ARGS})
    endif()

    set(${_name}_ALL_CMAKE_ARGS CMAKE_ARGS ${${_name}_CMAKE_ARGS})

    if(_YH_${_name}_CMAKE_CACHE_ARGS)
        list(APPEND ${_name}_ALL_CMAKE_ARGS CMAKE_CACHE_ARGS ${_YH_${_name}_CMAKE_CACHE_ARGS})
    endif()
    list(APPEND ${_name}_ALL_CMAKE_ARGS LIST_SEPARATOR "|")

    foreach(_dep ${_YH_${_name}_DEPENDS})
        if(TARGET ${_dep})
            get_property(is_ep TARGET ${_dep} PROPERTY _EP_IS_EXTERNAL_PROJECT)
            if(is_ep)
                set(_YH_${_name}_DEPENDS_ARGS ${_YH_${_name}_DEPENDS_ARGS} ${_dep})
            endif()
        endif()
    endforeach()

    if(_YH_${_name}_DEPENDS_ARGS)
        set(${_name}_DEPENDS_ARGS DEPENDS ${_YH_${_name}_DEPENDS_ARGS})
    endif()

    unset(${_name}_COMMAND_ARGS)
    if("${_YH_${_name}_COMPONENT}" STREQUAL "documentation")
        # Documentation component does not have a build step, unless
        # specified by the user.
        # The string "_" can be used to specify that the default command
        # should be left.
        foreach(_step CONFIGURE
                      BUILD
                      INSTALL)
            if(NOT DEFINED _YH_${_name}_${_step}_COMMAND)
                set(_YH_${_name}_${_step}_COMMAND "")
            elseif(_YH_${_name}_${_step}_COMMAND STREQUAL "_")
                unset(_YH_${_name}_${_step}_COMMAND)
            endif()
        endforeach()
    endif()
    foreach(_step DOWNLOAD
                  UPDATE PATCH
                  CONFIGURE
                  BUILD
                  INSTALL
                  TEST)
        if(CMAKE_VERSION VERSION_LESS 3.1.0)
            # HACK: set(var "" PARENT_SCOPE) before CMake 3.1.0 did not set an empty string, but
            # instead unset the variable.
            # Therefore after cmake_parse_arguments, even if the variables are defined, they are not
            # set.
            if("${ARGN}" MATCHES ";?${_step}_COMMAND;"  AND  NOT DEFINED _YH_${_name}_${_step}_COMMAND)
                set(_YH_${_name}_${_step}_COMMAND "")
            endif()
        endif()
        if(DEFINED _YH_${_name}_${_step}_COMMAND)
            string(CONFIGURE "${_YH_${_name}_${_step}_COMMAND}" _YH_${_name}_${_step}_COMMAND @ONLY)
            list(APPEND ${_name}_COMMAND_ARGS ${_step}_COMMAND "${_YH_${_name}_${_step}_COMMAND}")
        endif()
    endforeach()

    # CLEAN_COMMAND is not accepted by ExternalProject, so we clean it here
    if(CMAKE_VERSION VERSION_LESS 3.1.0)
        # HACK: (see previous one)
        if("${ARGN}" MATCHES ";?CLEAN_COMMAND;"  AND  NOT DEFINED _YH_${_name}_CLEAN_COMMAND)
            set(_YH_${_name}_CLEAN_COMMAND "")
        endif()
    endif()


    if("${_YH_${_name}_COMPONENT}" STREQUAL "documentation")
        set(${_name}_STEP_ARGS SCM_DISCONNECTED 0)
    endif()


    unset(${_name}_EXTRA_ARGS})
    if(DEFINED _YH_${_name}_EXCLUDE_FROM_ALL)
        list(APPEND ${_name}_EXTRA_ARGS EXCLUDE_FROM_ALL ${_YH_${_name}_EXCLUDE_FROM_ALL})
    endif()


    # Repository dependent variables
    unset(${_name}_REPOSITORY_ARGS)
    unset(_setup_repo_cmd)

    if("${_YH_${_name}_TYPE}" STREQUAL "GIT")
        # Specific setup for GIT
        _ycm_setup_git()

        list(APPEND ${_name}_REPOSITORY_ARGS GIT_REPOSITORY ${YCM_GIT_${_YH_${_name}_STYLE}_BASE_ADDRESS}${_YH_${_name}_REPOSITORY})

        if(DEFINED _YH_${_name}_TAG)
            list(APPEND ${_name}_REPOSITORY_ARGS GIT_TAG ${_YH_${_name}_TAG})
        endif()

       if(YCM_GIT_${_YH_${_name}_STYLE}_COMMIT_NAME)
            unset(${_name}_COMMIT_NAME)
            set(_setup_repo_cmd ${_setup_repo_cmd}
                                 COMMAND ${GIT_EXECUTABLE} config --local user.name ${YCM_GIT_${_YH_${_name}_STYLE}_COMMIT_NAME})
        endif()

        if(YCM_GIT_${_YH_${_name}_STYLE}_COMMIT_EMAIL)
            set(_setup_repo_cmd ${_setup_repo_cmd}
                                 COMMAND ${GIT_EXECUTABLE} config --local user.email ${YCM_GIT_${_YH_${_name}_STYLE}_COMMIT_EMAIL})
       endif()
    elseif("${_YH_${_name}_TYPE}" STREQUAL "SVN")
        # Specific setup for SVN
        _ycm_setup_svn()

        list(APPEND ${_name}_REPOSITORY_ARGS SVN_REPOSITORY ${YCM_SVN_${_YH_${_name}_STYLE}_BASE_ADDRESS}${_YH_${_name}_REPOSITORY})

        if(YCM_SVN_${_YH_${_name}_STYLE}_USERNAME)
            list(APPEND ${_name}_REPOSITORY_ARGS SVN_USERNAME ${YCM_SVN_${_YH_${_name}_STYLE}_USERNAME})
        endif()

        if(YCM_SVN_${_YH_${_name}_STYLE}_PASSWORD)
            list(APPEND ${_name}_REPOSITORY_ARGS SVN_PASSWORD ${YCM_SVN_${_YH_${_name}_STYLE}_PASSWORD})
        endif()

        if(DEFINED _YH_${_name}_TRUST_CERT)
            list(APPEND ${_name}_REPOSITORY_ARGS SVN_TRUST_CERT ${_YH_${_name}_TRUST_CERT})
        endif()
    endif()

    option(YCM_EP_DEVEL_MODE_${_name} "Enable development targets for the \"${_name}\" project" OFF)
    if("${_YH_${_name}_COMPONENT}" STREQUAL "external")
        mark_as_advanced(YCM_EP_DEVEL_MODE_${_name})
    endif()

    unset(${_name}_ARGS)
    foreach(_arg IN LISTS ${_name}_REPOSITORY_ARGS
                          ${_name}_DIR_ARGS
                          ${_name}_ALL_CMAKE_ARGS
                          ${_name}_DEPENDS_ARGS
                          ${_name}_COMMAND_ARGS
                          ${_name}_STEP_ARGS
                          ${_name}_EXTRA_ARGS)
        list(APPEND ${_name}_ARGS "${_arg}")
    endforeach()
    ExternalProject_Add(${_name} "${${_name}_ARGS}")

    if(_setup_repo_cmd)
        ExternalProject_Add_Step(${_name} setup-repository
                                 ${_setup_repo_cmd}
                                 WORKING_DIRECTORY ${${_name}_SOURCE_DIR}
                                 COMMENT "Performing setup-repository step for '${_name}'"
                                 DEPENDEES download
                                 DEPENDERS update)
    endif()


# Extra steps
    if(YCM_EP_DEVEL_MODE_${_name} OR YCM_EP_MAINTAINER_MODE)
        _ycm_ep_add_configure_step(${_name})
        _ycm_ep_add_fetch_step(${_name})
        _ycm_ep_add_status_step(${_name})
        _ycm_ep_add_clean_step(${_name})
        _ycm_ep_add_edit_cache_step(${_name})
        _ycm_ep_add_print_directories_step(${_name})
        _ycm_ep_add_dependees_steps(${_name})
        if(YCM_EP_EXPERT_MODE OR YCM_EP_MAINTAINER_MODE)
            _ycm_ep_add_update_step(${_name})
        endif()
    else()
        _ycm_ep_add_update_step(${_name})
    endif()
    _ycm_ep_add_dependers_steps(${_name})

    # Set some useful variables in parent scope
    foreach(_d PREFIX
              SOURCE_DIR
              DOWNLOAD_DIR
              BINARY_DIR
              INSTALL_DIR
              TMP_DIR
              STAMP_DIR)
        set(${_name}_${_d} ${${_name}_${_d}} PARENT_SCOPE)
    endforeach()

    # Set some useful global properties
    if(NOT _name STREQUAL "YCM")
        set_property(GLOBAL APPEND PROPERTY YCM_PROJECTS ${_name})
        get_property(_components GLOBAL PROPERTY YCM_COMPONENTS)
        list(APPEND _components ${_YH_${_name}_COMPONENT})
        list(REMOVE_DUPLICATES _components)
        set_property(GLOBAL PROPERTY YCM_COMPONENTS ${_components})

        # TODO foreach on all the variables?
        set_property(GLOBAL PROPERTY _YCM_${_name}_COMPONENT ${_YH_${_name}_COMPONENT})
        set_property(GLOBAL PROPERTY _YCM_${_name}_DEPENDS ${_YH_${_name}_DEPENDS})

        set_property(GLOBAL APPEND PROPERTY _YCM_${_name}_PROJECTS ${_name})
    endif()
endfunction()


########################################################################
# YCM_WRITE_CDASH_PROJECT_FILE
#
# Write cdash Project.xml file::
#
#  ycm_write_cdash_project_file(<filename>)
#
# This function writes a Project.xml file that can be read and
# interpreted by CDash.

function(YCM_WRITE_CDASH_PROJECT_FILE _filename)
    get_property(_projects GLOBAL PROPERTY YCM_PROJECTS)

    # For CTEST_PROJECT_NAME
    include(${CMAKE_SOURCE_DIR}/CTestConfig.cmake OPTIONAL)

    if(NOT DEFINED CTEST_PROJECT_NAME OR CTEST_PROJECT_NAME STREQUAL "")
        message(SEND_ERROR "Cannot generate Project.xml. Please set CTEST_PROJECT_NAME variable or add a ${CMAKE_SOURCE_DIR}/CTestConfig.cmake file")
    endif()

    file(WRITE ${_filename} "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Project name=\"${CTEST_PROJECT_NAME}\">\n")

    foreach(_proj ${_projects})
        file(APPEND "${_filename}" "\n  <SubProject name=\"${_proj}\">")
        get_property(_dependencies GLOBAL PROPERTY _YCM_${_proj}_DEPENDS)
        foreach(_dep ${_dependencies})
            list(FIND _projects ${_dep} _is_ycm)
            if(NOT _is_ycm EQUAL -1)
                file(APPEND "${_filename}" "\n    <Dependency name=\"${_dep}\" />")
            else()
                file(APPEND "${_filename}" "\n    <!-- <Dependency name=\"${_dep}\" /> -->")
            endif()
        endforeach()
        file(APPEND "${_filename}" "\n  </SubProject>\n")
    endforeach()
file(APPEND "${_filename}" "</Project>\n")
endfunction()


########################################################################
# YCM_WRITE_CTEST_SUBPROJECT_CONFIG_FILE
#
# Write ctest subprojects file::
#
#  ycm_write_ctest_subproject_config_file(<filename>)
#
# This function writes a cmake file that can be used in ctest scripts.

function(YCM_WRITE_CTEST_SUBPROJECT_CONFIG_FILE _filename)
    get_property(_projects GLOBAL PROPERTY YCM_PROJECTS)
    file(WRITE ${_filename} "set(CTEST_PROJECT_SUBPROJECTS")
    foreach(_proj ${_projects})
        file(APPEND "${_filename}" "\n      ${_proj}")
    endforeach()
    file(APPEND "${_filename}" ")\n")
    foreach(_proj ${_projects})
      get_property(_component GLOBAL PROPERTY _YCM_${_proj}_COMPONENT)
      file(APPEND "${_filename}" "
set(${_proj}_SOURCE_DIR \${CTEST_SOURCE_DIRECTORY}/${_component}/${_proj})
set(${_proj}_BINARY_DIR \${CTEST_BINARY_DIRECTORY}/${_component}/${_proj})
")
    endforeach()
endfunction()


########################################################################
# YCM_WRITE_DOT_FILE
#
# Write dot file::
#
#  ycm_write_dot_file(<filename>)
#
# This function writes a dot file that produces a graph showing all the
# subprojects, dependencies and components.

function(YCM_WRITE_DOT_FILE _filename)
    get_property(_projects GLOBAL PROPERTY YCM_PROJECTS)
    get_property(_components GLOBAL PROPERTY YCM_COMPONENTS)
    foreach(_proj ${_projects})
        get_property(_component GLOBAL PROPERTY _YCM_${_proj}_COMPONENT)
        get_property(_dependencies GLOBAL PROPERTY _YCM_${_proj}_DEPENDS)

        if(NOT _component STREQUAL "documentation"
           AND NOT _component STREQUAL "templates"
           AND NOT _component STREQUAL "examples")

            set(_${_component}_subgraph  "${_${_component}_subgraph}\n    ${_proj}")
            foreach(_dep ${_dependencies})
                list(FIND _projects ${_dep} _is_ycm)
                if(_is_ycm EQUAL -1)
                    list(APPEND _found_on_system ${_dep})
                    list(REMOVE_DUPLICATES _found_on_system)
                    set(_arrows "${_arrows}\n  ${_proj} -> ${_dep} [color=\"lightgray\" style=\"dashed\"];")
                else()
                    get_property(_dep_component GLOBAL PROPERTY _YCM_${_dep}_COMPONENT)
                    if(_dep_component STREQUAL "external")
                        set(_arrows "${_arrows}\n  ${_proj} -> ${_dep} [color=\"gray\"];")
                    else()
                        set(_arrows "${_arrows}\n  ${_proj} -> ${_dep};")
                    endif()
                endif()
            endforeach()
        endif()
    endforeach()
    foreach(_dep ${_found_on_system})
        set(_found_on_system_subgraph "${_found_on_system_subgraph}\n    ${_dep}")
    endforeach()

    file(WRITE ${_filename}
"digraph ${PROJECT_NAME} {
  graph [ranksep=\"1.5\", nodesep=\"0.1\" rankdir=\"BT\"];
")

    if(_found_on_system_subgraph)
        file(APPEND ${_filename} "
  subgraph cluster_system {
    label=\"System\";
    style=\"dashed\";
    color=\"orangered1\";
    bgcolor=\"oldlace\";
    node [shape=\"pentagon\", color=\"orangered3\", fontsize=\"8\"];
${_found_on_system_subgraph}
  }
")
    endif()

    if(_external_subgraph)
        file(APPEND "${_filename}" "
  subgraph cluster_external {
    label=\"External\";
    style=\"dashed\";
    color=\"green\";
    bgcolor=\"mintcream\";
    node [shape=\"box\", color=\"darkgreen\"];
${_external_subgraph}
  }
")
    endif()

    list(REMOVE_ITEM _components "external" "documentation" "templates" "examples")
    foreach(_component ${_components})
        if(_${_component}_subgraph)
            file(APPEND "${_filename}" "
  subgraph cluster_${_component} {
    label=\"${_component}\";
    color=\"dodgerblue1\";
    bgcolor = \"aliceblue\";
    node [style=\"bold\", shape=\"note\", color=\"dodgerblue3\"];
${_${_component}_subgraph}
  }
")
        endif()
    endforeach()

    file(APPEND "${_filename}" "\n${_arrows}\n}\n")
endfunction()


########################################################################
# YCM_BOOTSTRAP
#
# Bootstrap YCM.
#
# If the variable YCM_BOOTSTRAP_VERBOSE is set it prints all the output
# from the commands executed.

unset(__YCM_BOOTSTRAPPED_CALLED CACHE)
macro(YCM_BOOTSTRAP)
    if(YCM_FOUND  OR  DEFINED __YCM_BOOTSTRAPPED_CALLED)
        return()
    endif()
    set(__YCM_BOOTSTRAPPED_CALLED TRUE CACHE INTERNAL "")

    _ycm_hash_check(IncludeUrl)
    _ycm_hash_check(YCMBootstrap)

    if(NOT YCM_BOOTSTRAP_VERBOSE)
        set(_quiet_args OUTPUT_QUIET ERROR_QUIET)
    else()
        set(_quiet_args )
    endif()

    ycm_ep_helper(YCM TYPE GIT
                      STYLE GITHUB
                      REPOSITORY robotology/ycm.git
                      TAG master
                      EXCLUDE_FROM_ALL 1)


    message(STATUS "Performing download step (git clone) for 'YCM'")
    execute_process(COMMAND ${CMAKE_COMMAND} -P ${YCM_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/YCMTmp/YCM-gitclone.cmake
                    ${_quiet_args}
                    RESULT_VARIABLE _result)
    if(_result)
        message(FATAL_ERROR "Cannot clone YCM repository (${_result})")
    endif()

    message(STATUS "Performing update step for 'YCM'")
    execute_process(COMMAND ${CMAKE_COMMAND} -P ${YCM_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/YCMTmp/YCM-gitupdate.cmake
                    ${_quiet_args}
                    RESULT_VARIABLE _result)
    if(_result)
        message(FATAL_ERROR "Cannot update YCM repository")
    endif()

    message(STATUS "Performing configure step for 'YCM'")
    file(READ ${YCM_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/YCMTmp/YCM-cfgcmd.txt _cmd)
    string(STRIP "${_cmd}" _cmd)
    string(REGEX REPLACE "^cmd='(.+)'" "\\1" _cmd "${_cmd}")
    execute_process(COMMAND ${_cmd}
                    WORKING_DIRECTORY ${YCM_BINARY_DIR}
                    ${_quiet_args}
                    RESULT_VARIABLE _result)
    if(_result)
        message(FATAL_ERROR "Cannot configure YCM repository")
    endif()

    # On multi-config generators (MSVC and XCode) always build in
    # "Release" configuration
    if(CMAKE_CONFIGURATION_TYPES)
        set(_configuration --config Release)
    endif()

    message(STATUS "Performing uninstall step for 'YCM'")
    execute_process(COMMAND ${CMAKE_COMMAND} --build ${YCM_BINARY_DIR} ${_configuration} --target uninstall
                    WORKING_DIRECTORY ${YCM_BINARY_DIR}
                    ${_quiet_args}
                    RESULT_VARIABLE _result)
    # If uninstall fails, YCM was not previously installed,
    # therefore do not fail with error

    message(STATUS "Performing build step for 'YCM'")
    execute_process(COMMAND ${CMAKE_COMMAND} --build ${YCM_BINARY_DIR} ${_configuration}
                    WORKING_DIRECTORY ${YCM_BINARY_DIR}
                    ${_quiet_args}
                    RESULT_VARIABLE _result)
    if(_result)
        message(FATAL_ERROR "Cannot build YCM")
    endif()

    message(STATUS "Performing install step for 'YCM'")
    execute_process(COMMAND ${CMAKE_COMMAND} --build ${YCM_BINARY_DIR} ${_configuration} --target install
                    WORKING_DIRECTORY ${YCM_BINARY_DIR}
                    ${_quiet_args}
                    RESULT_VARIABLE _result)
    if(_result)
        message(FATAL_ERROR "Cannot install YCM")
    endif()

    # Find the package, so that can be used now.
    find_package(YCM PATHS ${YCM_INSTALL_DIR} NO_DEFAULT_PATH)

    # Reset YCM_DIR variable so that next find_package will fail to locate the package and this will be kept updated
    set(YCM_DIR "YCM_DIR-NOTFOUND" CACHE PATH "The directory containing a CMake configuration file for YCM." FORCE)

    # Trick FeatureSummary to believe that YCM was not found
    get_property(_packages_found GLOBAL PROPERTY PACKAGES_FOUND)
    get_property(_packages_not_found GLOBAL PROPERTY PACKAGES_NOT_FOUND)
    list(REMOVE_ITEM _packages_found YCM)
    list(APPEND _packages_not_found YCM)
    set_property(GLOBAL PROPERTY PACKAGES_FOUND ${_packages_found})
    set_property(GLOBAL PROPERTY PACKAGES_NOT_FOUND ${_packages_not_found})

    # Cleanup used variables
    unset(_quiet_args)
    unset(_result)
    unset(_packages_found)
    unset(_packages_not_found)

endmacro()


########################################################################
# Main

_ycm_setup()
