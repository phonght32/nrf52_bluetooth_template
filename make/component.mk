# Main Project Makefile 
# This Makefile is included directly from the user project Makefile in order to call the component.mk
# makefiles of all components (in a seperate make process) to build all libraries, then links them 
# together into the final file. 


# Default path of the project. Assume the Makefile is exist in current project directory.
ifndef PROJECT_PATH
PROJECT_PATH := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
export PROJECT_PATH
endif

# Component directory. The project Makefile can override these directory, or add extra component
# directory via EXTRA_COMPONENT_DIRS
ifndef COMPONENT_DIRS
EXTRA_COMPONENT_DIRS ?=
COMPONENT_DIRS := $(PROJECT_PATH)/components $(EXTRA_COMPONENT_DIRS) $(PROJECT_PATH)/main
endif

# Make sure that every directory in the list is absulute path without trailing slash.
COMPONENT_DIRS := $(foreach cd,$(COMPONENT_DIRS),$(abspath $(cd)))
export COMPONENT_DIRS

# This is neccessary to split COMPONET_DIRS into SINGLE_COMPONET_DIRS and MULTI_COMPONENT_DIRS.
# SINGLE_COMPONENT_DIRS contain a component.mk file and MULTI_COMPONENT_DIRS contain folder which
# contrain component.mk file. For example /blablabla/components/user_components/component.mk
SINGLE_COMPONENT_DIRS := $(abspath $(dir $(dir $(foreach cd, $(COMPONENT_DIRS), $(wildcard $(cd)/component.mk)))))
export SINGLE_COMPONENT_DIRS
MULTI_COMPONENT_DIRS := $(filter-out $(SINGLE_COMPONENT_DIRS),$(COMPONENT_DIRS))

# Find all component names (which folder contain component.mk file).
# We need to do this for MULTI_COMPONENT_DIRS only, since SINGLE_COMPONENT_DIRS
# are already known to contain component.mk.
ifndef COMPONENTS
COMPONENTS := $(dir $(foreach cd,$(MULTI_COMPONENT_DIRS),$(wildcard $(cd)/*/component.mk))) $(SINGLE_COMPONENT_DIRS)
COMPONENTS := $(sort $(foreach comp,$(COMPONENTS),$(lastword $(subst /, ,$(comp)))))
endif
export COMPONENTS

# Resolve all of COMPONENTS into absolute paths in COMPONENT_PATHS.
# For each entry in COMPONENT_DIRS:
# - either this is directory with multiple components, in which case check that
#   a subdirectory with component name exists, and it contains a component.mk file.
# - or, this is a directory of a single component, in which case the name of this
#   directory has to match the component name
#
# If a component name exists in multiple COMPONENT_DIRS, we take the first match.
#
# NOTE: These paths must be generated WITHOUT a trailing / so we
# can use $(notdir x) to get the component name.
COMPONENT_PATHS += $(foreach comp,$(COMPONENTS),\
                        $(firstword $(foreach cd,$(COMPONENT_DIRS),\
                            $(if $(findstring $(cd),$(MULTI_COMPONENT_DIRS)),\
                                 $(abspath $(dir $(wildcard $(cd)/$(comp)/component.mk))),)\
                            $(if $(findstring $(cd),$(SINGLE_COMPONENT_DIRS)),\
                                 $(if $(filter $(comp),$(notdir $(cd))),$(cd),),)\
                   )))
export COMPONENT_PATHS

# Default include and source directory in components folder.
# 	- COMPONENT_INCLUDES: include directory regarless self directory.
#	- COMPONENT_SOURCES: source directory regarless self directory.
COMPONENT_INCLUDES += include
COMPONENT_SOURCES += 

# Get all variable in every components. This variable include COMPONENT_INCLUDES and COMPONENT_SOURCES.
include $(foreach comp, $(COMPONENT_PATHS), $(addprefix $(comp)/, component.mk))


# Add component include prefix paths to componnent paths to get all absolute include paths. 
COMPONENTS_INCLUDE_PATHS += $(foreach comp, $(COMPONENT_PATHS), \
						$(foreach comp_inc, $(COMPONENT_INCLUDES), \
							$(addprefix $(subst $(PROJECT_PATH)/, ,$(comp)/), $(comp_inc))))
						

# Add component source prefix paths to component paths to get all absolute source paths.
COMPONENTS_SOURCE_PATHS += $(COMPONENT_PATHS)
COMPONENTS_SOURCE_PATHS += $(foreach comp, $(COMPONENT_PATHS), \
						$(foreach comp_src, $(COMPONENT_SOURCES), \
							$(addprefix $(comp)/, $(comp_src))))

# Get all source files include .c and .s
C_SOURCES += $(foreach comp_src, $(COMPONENTS_SOURCE_PATHS), $(wildcard $(comp_src)/*.c))
CPP_SOURCES += $(foreach comp_src, $(COMPONENTS_SOURCE_PATHS), $(wildcard $(comp_src)/*.cpp))
ASM_SOURCES += $(foreach comp_src, $(COMPONENTS_SOURCE_PATHS), $(wildcard $(comp_src)/*.s))

COMPONENTS_C_SOURCES += $(foreach c_source, $(C_SOURCES), $(subst $(PROJECT_PATH)/, ,$(c_source)))
COMPONENTS_CPP_SOURCES += $(foreach cpp_source, $(CPP_SOURCES), $(subst $(PROJECT_PATH)/, ,$(cpp_source)))
COMPONENTS_ASM_SOURCES += $(foreach asm_source, $(ASM_SOURCES), $(subst $(PROJECT_PATH)/, ,$(asm_source)))

export COMPONENTS_INCLUDE_PATHS
export COMPONENTS_C_SOURCES