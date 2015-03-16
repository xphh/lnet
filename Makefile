#
# makefile
#

# top dir
TOPDIR = $(shell pwd)
# project name
PJNAME = lnet

# tool chain prefix
CROSS = $(CP)
# debug or release
DEBUG = 0
# static or shared or exec
BINARY = shared
# target name
TARGET = core.dll
# output binary path
INSTALL_PATH = $(TOPDIR)/lnet

# source dir
SRCPATH = $(TOPDIR)/src
# source sub dir
SRCSUBDIR = 

# header dir
INCDIR = $(TOPDIR)

# dependence library path
LIBDIR = 
# dependence library
LIBS = rt

# compile flags
CFLAGS = -Wall -fPIC

# link flags
LDFLAGS = 

# make
include $(TOPDIR)/common.mk
