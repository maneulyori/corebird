AC_PREREQ([2.65])
AC_INIT([corebird],[0.6],[mail@baedert.org])
AC_CONFIG_MACRO_DIR([m4])
AM_INIT_AUTOMAKE([foreign])
AC_CONFIG_FILES([Makefile
                 src/Makefile
                 ui/Makefile
                 data/Makefile
                 assets/Makefile
                 assets/icons/Makefile
                 src/util/Config.vala])


LT_INIT
AC_PROG_CC
AM_PROG_VALAC
AM_MAINTAINER_MODE

pkg_modules="gtk+-3.0 >= 3.10
             glib-2.0 >= 2.38
             rest-0.7
             libsoup-2.4
             gee-0.8
             json-glib-1.0
             libnotify
             sqlite3"
PKG_CHECK_MODULES(CB, [$pkg_modules])
CB_VALA_FLAGS=" \
  --pkg gtk+-3.0 \
  --pkg json-glib-1.0 \
  --pkg rest-0.7 \
  --pkg libnotify \
  --pkg gee-0.8 \
  --pkg sqlite3 \
  --pkg libsoup-2.4 \
  --pkg glib-2.0 \
  --target-glib=2.38 \
  --gresources=../resources.xml"

AC_SUBST(CB_CFLAGS)
AC_SUBST(CB_LIBS)
AC_SUBST(CB_VALA_FLAGS)

AC_PATH_PROG(GLIB_COMPILE_RESOURCES, glib-compile-resources)


AC_ARG_ENABLE(catalog, AC_HELP_STRING([--enable-catalog], [Whether to install the corebird glade catalog]), enable_catalog=$enableval, catalog=no)
AM_CONDITIONAL([ENABLE_CATALOG], [ test "$enable_catalog" = "yes" ])

AC_ARG_ENABLE(catalog, AC_HELP_STRING([--enable-tests], [Whether to build test cases]), enable_tests=$enableval, tests=no)
AM_CONDITIONAL([ENABLE_TESTS], [ test "$enable_tests" = "yes" ])


# Gettext stuff
GETTEXT_PACKAGE=corebird
AC_DEFINE_UNQUOTED([GETTEXT_PACKAGE], ["$GETTEXT_PACKAGE"], [Gettext Package])
AC_SUBST(GETTEXT_PACKAGE)
#AM_GNU_GETTEXT_VERSION([1.11])
AM_GLIB_GNU_GETTEXT



AC_OUTPUT


echo "
             Corebird  $VERSION
               Prefix: ${prefix}
        Vala Compiler: ${VALAC}
           C Compiler: ${CC}
"