#.rst:
# CMakeParseArguments
# -------------------
#
# Parse arguments given to a macro or a function.
#
# cmake_parse_arguments() is intended to be used in macros or functions
# for parsing the arguments given to that macro or function.  It
# processes the arguments and defines a set of variables which hold the
# values of the respective options.
#
# ::
#
#  cmake_parse_arguments(<prefix>
#                        <options>
#                        <one_value_keywords>
#                        <multi_value_keywords>
#                        [CMAKE_PARSE_ARGUMENTS_SKIP_EMPTY|CMAKE_PARSE_ARGUMENTS_KEEP_EMPTY]
#                        args...
#                        )
#
# The <options> argument contains all options for the respective macro,
# i.e.  keywords which can be used when calling the macro without any
# value following, like e.g.  the OPTIONAL keyword of the install()
# command.
#
# The <one_value_keywords> argument contains all keywords for this macro
# which are followed by one value, like e.g.  DESTINATION keyword of the
# install() command.
#
# The <multi_value_keywords> argument contains all keywords for this
# macro which can be followed by more than one value, like e.g.  the
# TARGETS or FILES keywords of the install() command.
#
# When done, cmake_parse_arguments() will have defined for each of the
# keywords listed in <options>, <one_value_keywords> and
# <multi_value_keywords> a variable composed of the given <prefix>
# followed by "_" and the name of the respective keyword.  These
# variables will then hold the respective value from the argument list.
# For the <options> keywords this will be TRUE or FALSE.
#
# All remaining arguments are collected in a variable
# <prefix>_UNPARSED_ARGUMENTS, this can be checked afterwards to see
# whether your macro was called with unrecognized parameters.
#
# The cmake CMAKE_PARSE_ARGUMENTS_SKIP_EMPTY (old behaviour) and
# CMAKE_PARSE_ARGUMENTS_KEEP_EMPTY (new behaviour) options decide how
# empty arguments should be handled. If none of these options is set,
# if the CMAKE_PARSE_ARGUMENTS_DEFAULT_SKIP_EMPTY directory property is
# set, is it used as default, otherwise, for compatibility, the default
# behaviour is to skip empty arguments, unless
# CMAKE_MINIMUM_REQUIRED_VERSION is 3.0.0 or greater.
#
#
#
# As an example here a my_install() macro, which takes similar arguments
# as the real install() command:
#
# ::
#
#    function(MY_INSTALL)
#      set(options OPTIONAL FAST)
#      set(oneValueArgs DESTINATION RENAME)
#      set(multiValueArgs TARGETS CONFIGURATIONS)
#      cmake_parse_arguments(MY_INSTALL "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}" )
#      ...
#
#
#
# Assume my_install() has been called like this:
#
# ::
#
#    my_install(TARGETS foo bar DESTINATION bin OPTIONAL blub)
#
#
#
# After the cmake_parse_arguments() call the macro will have set the
# following variables:
#
# ::
#
#    MY_INSTALL_OPTIONAL = TRUE
#    MY_INSTALL_FAST = FALSE (this option was not used when calling my_install()
#    MY_INSTALL_DESTINATION = "bin"
#    MY_INSTALL_RENAME = "" (was not used)
#    MY_INSTALL_TARGETS = "foo;bar"
#    MY_INSTALL_CONFIGURATIONS = "" (was not used)
#    MY_INSTALL_UNPARSED_ARGUMENTS = "blub" (no value expected after "OPTIONAL"
#
#
#
# You can then continue and process these variables.
#
# Keywords terminate lists of values, e.g.  if directly after a
# one_value_keyword another recognized keyword follows, this is
# interpreted as the beginning of the new option.  E.g.
# my_install(TARGETS foo DESTINATION OPTIONAL) would result in
# MY_INSTALL_DESTINATION set to "OPTIONAL", but MY_INSTALL_DESTINATION
# would be empty and MY_INSTALL_OPTIONAL would be set to TRUE therefore.
#
#
#
# If the "CMAKE_PARSE_ARGUMENTS_SKIP_EMPTY" option is set,
# cmake_parse_argumentswill not consider empty arguments.
# Therefore
#
# ::
#
#    my_install(DESTINATION "" TARGETS foo "" bar)
#
# Will set
#
# ::
#
#    MY_INSTALL_DESTINATION = (unset)
#    MY_INSTALL_MULTI = "foo;bar"
#
# Using the "CMAKE_PARSE_ARGUMENTS_SKIP_EMPTY" option instead, will set
#
# ::
#
#    MY_INSTALL_SINGLE = ""
#    MY_INSTALL_MULTI = "foo;;bar"
#
#
# It is also important to note that:
#
# ::
#
#      cmake_parse_arguments(MY_INSTALL "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}" )
#      cmake_parse_arguments(MY_INSTALL "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
#
# Will behave differently, because in the latter case empty arguments
# are not passed to cmake_parse_arguments.

#=============================================================================
# Copyright 2010 Alexander Neundorf <neundorf@kde.org>
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distribute this file outside of CMake, substitute the full
#  License text for the above reference.)


if(__CMAKE_PARSE_ARGUMENTS_INCLUDED)
  return()
endif()
set(__CMAKE_PARSE_ARGUMENTS_INCLUDED TRUE)


define_property(DIRECTORY PROPERTY "CMAKE_PARSE_ARGUMENTS_DEFAULT_SKIP_EMPTY" INHERITED
  BRIEF_DOCS "Whether empty arguments should be skipped or not by default."
  FULL_DOCS
  "See documentation of the cmake_parse_arguments() function in the "
  "CMakeParseArguments module."
  )


function(CMAKE_PARSE_ARGUMENTS prefix _optionNames _singleArgNames _multiArgNames)
  # first set all result variables to empty/FALSE
  foreach(arg_name ${_singleArgNames} ${_multiArgNames})
    set(${prefix}_${arg_name})
  endforeach()

  foreach(option ${_optionNames})
    set(${prefix}_${option} FALSE)
  endforeach()

  set(${prefix}_UNPARSED_ARGUMENTS)

  set(insideValues FALSE)
  set(currentArgName)

  get_property(_defaultSkipEmptySet DIRECTORY PROPERTY CMAKE_PARSE_ARGUMENTS_DEFAULT_SKIP_EMPTY SET)
  get_property(_defaultSkipEmpty    DIRECTORY PROPERTY CMAKE_PARSE_ARGUMENTS_DEFAULT_SKIP_EMPTY)

  # Keep compatibility with previous releases
  if(CMAKE_MINIMUM_REQUIRED_VERSION VERSION_LESS 3.0.0)
    set(_skipEmpty 1)
  else()
    set(_skipEmpty 0)
  endif()

  if(_defaultSkipEmptySet)
    set(_skipEmpty ${_defaultSkipEmpty})
  endif()

  if("x${ARGN}" MATCHES "^xCMAKE_PARSE_ARGUMENTS_(SKIP|KEEP)_EMPTY;?")
    if("${CMAKE_MATCH_1}" STREQUAL "SKIP")
        set(_skipEmpty 1)
    elseif("${CMAKE_MATCH_1}" STREQUAL "KEEP")
        set(_skipEmpty 0)
    endif()
    string(REGEX REPLACE "^${CMAKE_MATCH_0}" "" ARGN "x${ARGN}")
  endif()

  if(NOT _skipEmpty)
    set(_loopARGN IN LISTS ARGN)
  else()
    set(_loopARGN ${ARGN})
  endif()

  # now iterate over all arguments and fill the result variables
  foreach(currentArg ${_loopARGN})
    list(FIND _optionNames "${currentArg}" optionIndex)  # ... then this marks the end of the arguments belonging to this keyword
    list(FIND _singleArgNames "${currentArg}" singleArgIndex)  # ... then this marks the end of the arguments belonging to this keyword
    list(FIND _multiArgNames "${currentArg}" multiArgIndex)  # ... then this marks the end of the arguments belonging to this keyword
    if(${optionIndex} EQUAL -1  AND  ${singleArgIndex} EQUAL -1  AND  ${multiArgIndex} EQUAL -1)
      if(insideValues)
        if("${insideValues}" STREQUAL "SINGLE")
          if(_skipEmpty)
            set(${prefix}_${currentArgName} ${currentArg})
          else()
            set(${prefix}_${currentArgName} "${currentArg}")
          endif()
          set(insideValues FALSE)
        elseif("${insideValues}" STREQUAL "MULTI")
          if(_skipEmpty)
            list(APPEND ${prefix}_${currentArgName} ${currentArg})
          else()
            list(APPEND ${prefix}_${currentArgName} "${currentArg}")
          endif()
        endif()
      else()
        if(_skipEmpty)
          list(APPEND ${prefix}_UNPARSED_ARGUMENTS ${currentArg})
        else()
          list(APPEND ${prefix}_UNPARSED_ARGUMENTS "${currentArg}")
        endif()
      endif()
    else()
      if(NOT ${optionIndex} EQUAL -1)
        set(${prefix}_${currentArg} TRUE)
        set(insideValues FALSE)
      elseif(NOT ${singleArgIndex} EQUAL -1)
        set(currentArgName ${currentArg})
        set(${prefix}_${currentArgName})
        set(insideValues "SINGLE")
      elseif(NOT ${multiArgIndex} EQUAL -1)
        set(currentArgName ${currentArg})
        set(${prefix}_${currentArgName})
        set(insideValues "MULTI")
      endif()
    endif()

  endforeach()

  # propagate the result variables to the caller:
  foreach(arg_name ${_singleArgNames} ${_multiArgNames} ${_optionNames} UNPARSED_ARGUMENTS)
    if(DEFINED ${prefix}_${arg_name})
      set(${prefix}_${arg_name} "${${prefix}_${arg_name}}" PARENT_SCOPE)
    endif()
  endforeach()

endfunction()
