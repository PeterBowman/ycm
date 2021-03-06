#=============================================================================
# Copyright 2013-2014 Istituto Italiano di Tecnologia (IIT)
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


set(YCM_CMAKE_DOWNLOAD_URL "https://raw.githubusercontent.com/Kitware/CMake/<REF>/<FILE>"
    CACHE STRING "Url used to download CMake modules")
set_property(CACHE YCM_CMAKE_DOWNLOAD_URL PROPERTY
             STRINGS "https://raw.githubusercontent.com/Kitware/CMake/<REF>/<FILE>"
                     "http://cmake.org/gitweb?p=cmake.git\;a=blob_plain\;f=<FILE>\;hb=<REF>")
mark_as_advanced(YCM_CMAKE_DOWNLOAD_URL)

function(_YCM_CMAKE_NEXT_WRITE_README _ref _dir)
  file(WRITE "${_dir}/README"
"Files in this folder and its subfolder come from CMake git repository
(ref ${_ref}):

  git://cmake.org/cmake.git

They were imported exactly as they are on the original repository, in
order to supply the new features and bugfix available in newer releases
to user with older cmake releases.

These files are distributed under the OSI-approved BSD License;
see accompanying file Copyright.txt for details.
")
endfunction()

function(_YCM_CMAKE_NEXT_DOWNLOAD _ref _dir _files)
  _ycm_download(cmake-${_ref} "CMake git repository"
                "${YCM_CMAKE_DOWNLOAD_URL}"
                "${_ref}" "${_dir}" "${_files}")
  _ycm_cmake_next_write_readme(${_ref} "${_dir}")
endfunction()

function(_YCM_CMAKE_NEXT_INSTALL _ref)
  _ycm_install(cmake-${_ref} ${ARGN})
endfunction()

# Download and install files from CMake git at configure time, useful to
# download the modules used by the YCM build that are not available
# on older CMake versions
function(_YCM_CMAKE_NEXT_DOWNLOAD_NOW _ref _dir _files)
  # loop over a list of file and sha1
  list(LENGTH _files _size)
  foreach(_i RANGE 1 ${_size} 2)
    math(EXPR _j "${_i} - 1")
    list(GET _files ${_j} _file)
    list(GET _files ${_i} _sha1)

    string(REPLACE "<REF>" "${_ref}" _src "${YCM_CMAKE_DOWNLOAD_URL}")
    string(REPLACE "<FILE>" "${_file}" _src "${_src}")
    set(_dest "${_dir}/${_file}")
    set(_orig_dest "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/cmake-${_ref}.dir/downloads/${_file}")
    set(_offline_dest "${CMAKE_SOURCE_DIR}/downloads/cmake-${_ref}/${_file}")

    if(EXISTS "${_offline_dest}")
      execute_process(COMMAND ${CMAKE_COMMAND} -E copy_if_different "${_offline_dest}" "${_orig_dest}")
    endif()

    if(NOT EXISTS ${_orig_dest})
      message(STATUS "Downloading file ${_file} from CMake git repository (ref ${_ref})")
      file(DOWNLOAD "${_src}" "${_orig_dest}"
           EXPECTED_HASH SHA1=${_sha1})
    endif()

    if(WIN32)
      # On Windows we change files end of lines to the windows ones
      file(READ "${_orig_dest}" _tmp)
      string(REPLACE "/r/n" "/n" _tmp "${_tmp}")
      file(WRITE "${_dest}" "${_tmp}")
    else()
      execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${_orig_dest}" "${_dest}")
    endif()

    execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${_orig_dest}" "${_offline_dest}")

    set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES ${_dest})
  endforeach()
  _ycm_cmake_next_write_readme(${_ref} "${_dir}")
endfunction()


# Downloaded modules               CMake Version   Uncommitted
#                                                  Changes
#
#  FindMatlab                       3.7
#  FeatureSummary                   3.8
#  UseSWIG                          3.8
#  WriteBasicConfigVersionFile      3.11            Yes (CMAKE_ROOT)
#  FindPython                       3.12
#  FindPython/Support               3.12
#  FindPython2                      3.12
#  FindPython3                      3.12
#  CMakeParseArguments              ---             Yes
#  FindGLEW                         ---             Yes
#
# Changes in dependencies
#  FindPackageHandleStandardArgs

# NOTE: keep CMake version values listed at root/YCMConfig.cmake.in up
# to date with changes in the previous table.


################################################################################
# Files not available or containing bugs in CMake 3.5.2
# Imported from CMake tag v3.6.2
if(NOT CMAKE_MINIMUM_REQUIRED_VERSION VERSION_LESS 3.6)
  # Just a reminder to remove this when we change cmake version
  message(AUTHOR_WARNING "CMake minimum required version greater than 3.5. You can remove this.")
endif()

# None


################################################################################
# Files not available or containing bugs in CMake 3.6.3
# Imported from CMake tag v3.7.2
if(NOT CMAKE_MINIMUM_REQUIRED_VERSION VERSION_LESS 3.7)
  # Just a reminder to remove this when we change cmake version
  message(AUTHOR_WARNING "CMake minimum required version greater than 3.6. You can remove this.")
endif()

# We assume that the user won't downgrade his CMake, therefore it's not
# necessary to download and install these files if already included in CMake
if(CMAKE_VERSION VERSION_LESS 3.7 OR YCM_MAINTAINER_MODE)

  set(_files Copyright.txt                               142359ab254d35db46c6d3d29a06d6cf2d570919
             Modules/FindMatlab.cmake                    fab238dfd6bc346af6cfbc4c0a3b7af48f19c09c)
  _ycm_cmake_next_download(v3.7.2 "${CMAKE_CURRENT_BINARY_DIR}/cmake-3.7" "${_files}")
  _ycm_cmake_next_install(v3.7.2 DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/cmake-3.7"
                                 DESTINATION "${YCM_INSTALL_MODULE_DIR}")
endif()


################################################################################
# Files not available or containing bugs in CMake 3.7.2
# Imported from CMake tag v3.8.2
if(NOT CMAKE_MINIMUM_REQUIRED_VERSION VERSION_LESS 3.8)
  # Just a reminder to remove this when we change cmake version
  message(AUTHOR_WARNING "CMake minimum required version greater than 3.7. You can remove this.")
endif()

# We assume that the user won't downgrade his CMake, therefore it's not
# necessary to download and install these files if already included in CMake
if(CMAKE_VERSION VERSION_LESS 3.7 OR YCM_MAINTAINER_MODE)

  set(_files Copyright.txt                               510b21e4b3a70f0288bac0d89de8c333a36b159a
             Modules/UseSWIG.cmake                       cf40cd32fdaa22c6c27887324983122ee9cde799
             Modules/FindSWIG.cmake                      dea8c36114b8fcd934118a0fc86c0641cd191c18  # Required to use this version of UseSWIG
             Modules/FindPackageHandleStandardArgs.cmake 53300617d441f9cd08375a3599d15e6f60187441  # Used by FindSWIG
             Modules/FindPackageMessage.cmake            68bfe02f96faabad103d59811b324d82d7c1d178  # Used by FindPackageHandleStandardArgs
             Modules/CMakeParseArguments.cmake           eaf4dbce829d0eca5db28fc4b1a36b42f7948ad3) # Used by FindPackageHandleStandardArgs

  _ycm_cmake_next_download(v3.8.2 "${CMAKE_CURRENT_BINARY_DIR}/cmake-3.8" "${_files}")
  _ycm_cmake_next_install(v3.8.2 DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/cmake-3.8"
                                 DESTINATION "${YCM_INSTALL_MODULE_DIR}")
endif()


################################################################################
# Files not available or containing bugs in CMake 3.8.2
# Imported from CMake tag v3.9.6
if(NOT CMAKE_MINIMUM_REQUIRED_VERSION VERSION_LESS 3.9)
  # Just a reminder to remove this when we change cmake version
  message(AUTHOR_WARNING "CMake minimum required version greater than 3.8. You can remove this.")
endif()

# None


################################################################################
# Files not available or containing bugs in CMake 3.9.6
# Imported from CMake tag v3.10.2
if(NOT CMAKE_MINIMUM_REQUIRED_VERSION VERSION_LESS 3.10)
  # Just a reminder to remove this when we change cmake version
  message(AUTHOR_WARNING "CMake minimum required version greater than 3.9. You can remove this.")
endif()

# None


################################################################################
# Files not available or containing bugs in CMake 3.10.2
# Imported from CMake tag v3.11.2
if(NOT CMAKE_MINIMUM_REQUIRED_VERSION VERSION_LESS 3.11)
  # Just a reminder to remove this when we change cmake version
  message(AUTHOR_WARNING "CMake minimum required version greater than 3.10. You can remove this.")
endif()

# We assume that the user won't downgrade his CMake, therefore it's not
# necessary to download and install these files if already included in CMake
if(CMAKE_VERSION VERSION_LESS 3.11 OR YCM_MAINTAINER_MODE)

  set(_files Copyright.txt                                        adb9e42eb50d36c7934d78bc339214d1600f8cb3
             Modules/BasicConfigVersion-SameMinorVersion.cmake.in 9f8a3d2e75026677375705fa008325d18d24c3d7)

  file(COPY v3.11.0/WriteBasicConfigVersionFile.cmake
       DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/cmake-3.11/Modules")

  _ycm_cmake_next_download(v3.11.2 "${CMAKE_CURRENT_BINARY_DIR}/cmake-3.11" "${_files}")
  _ycm_cmake_next_install(v3.11.2 DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/cmake-3.11"
                                  DESTINATION "${YCM_INSTALL_MODULE_DIR}")
endif()


################################################################################
# Files not yet available or containing bugs in current CMake release (v3.11.2)
# Imported from latest revision tested
if(NOT CMAKE_VERSION VERSION_LESS 3.12)
    # Just a reminder to update files when a new cmake version is released
    message(AUTHOR_WARNING "CMake version is ${CMAKE_VERSION}. You should update this.")
endif()

# We assume that the user won't downgrade his CMake, therefore it's not
# necessary to download and install these files if already included in CMake
if(CMAKE_VERSION VERSION_LESS 3.12 OR YCM_MAINTAINER_MODE)

  set(_ref f248f8ad7898816a5a627e288d3a04fed993967f)
  set(_files Copyright.txt                                        96563e603328872bc22d31a3445e23b438292751
             Modules/FindPython.cmake                             b55c8a5e7e32efa98c0a86f1e45e6498a13cb828
             Modules/FindPython/Support.cmake                     cc625449f3bdfa9bfec17fcf386e3df73e1c56da
             Modules/FindPython2.cmake                            b79f69806d150c759be0504e4a8f2e54553e9330
             Modules/FindPython3.cmake                            aaa31c35f5167b385018f0863676ac4baf9b22e2
             Modules/CMakeFindFrameworks.cmake                    053fd8fd4bb7bc08fb6595b0a212de097a86084f  # Used by FindPython/Support.cmake
             Modules/FindPackageHandleStandardArgs.cmake          286ff571e093a25caaa4d2390d3b9729bc5ff44d  # Used by FindPython/Support.cmake
             Modules/FindPackageMessage.cmake                     68bfe02f96faabad103d59811b324d82d7c1d178  # Used by FindPackageHandleStandardArgs
             Modules/SelectLibraryConfigurations.cmake            e09bf3cd3f1faa1f9cc8f5924216a7fe3e4594d4) # Used by FindPython/Support.cmake

  _ycm_cmake_next_download(${_ref} "${CMAKE_CURRENT_BINARY_DIR}/cmake-next" "${_files}")
  _ycm_cmake_next_install(${_ref} DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/cmake-next"
                                  DESTINATION "${YCM_INSTALL_MODULE_DIR}")
endif()

################################################################################
# Files with patches not yet merged in CMake master

# Always installed
set(YCM_CMAKE_PROPOSED_FILES proposed/ExternalProject.cmake
                             proposed/CMakeParseArguments.cmake
                             proposed/FindGLEW.cmake)
set(YCM_CMAKE_PROPOSED_EXTRA_FILES  Copyright.txt # Must be redistributed together with CMake files
                                    README)       # Overwrite README generated by _ycm_cmake_next_download
_ycm_cmake_next_install(proposed FILES ${YCM_CMAKE_PROPOSED_FILES}
                                 DESTINATION "${YCM_INSTALL_MODULE_DIR}/cmake-proposed/Modules")
_ycm_cmake_next_install(proposed FILES ${YCM_CMAKE_PROPOSED_EXTRA_FILES}
                                 DESTINATION "${YCM_INSTALL_MODULE_DIR}/cmake-proposed")
