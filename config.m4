dnl $Id$
dnl config.m4 for extension pdo_sqlcipher
dnl vim:et:sw=2:ts=2:

PHP_ARG_ENABLE(pdo_sqlcipher, whether to enable pdo_sqlcipher support,
[  --enable-pdo_sqlcipher  Enable pdo_sqlcipher support])

if test "$PHP_PDO_SQLCIPHER" != "no"; then

    if test "$PHP_PDO" = "no" && test "$ext_shared" = "no"; then
        AC_MSG_ERROR([PDO is not enabled! Add --enable-pdo to your configure line.])
    fi

    AC_MSG_CHECKING([for PDO includes])
    if test -f $abs_srcdir/include/php/ext/pdo/php_pdo_driver.h; then
        pdo_inc_path=$abs_srcdir/ext
    elif test -f $abs_srcdir/ext/pdo/php_pdo_driver.h; then
        pdo_inc_path=$abs_srcdir/ext
    elif test -f $prefix/include/php/ext/pdo/php_pdo_driver.h; then
        pdo_inc_path=$prefix/include/php/ext
    elif test -f $prefix/include/php5/ext/pdo/php_pdo_driver.h; then
        pdo_inc_path=$prefix/include/php5/ext
    else
        AC_MSG_ERROR([Cannot find php_pdo_driver.h.])
    fi
    AC_MSG_RESULT($pdo_inc_path)

    php_pdo_sqlcipher_sources_core="pdo_sqlcipher.c sqlite_driver.c sqlite_statement.c sqlcipher3.c"

    PHP_NEW_EXTENSION(pdo_sqlcipher, $php_pdo_sqlcipher_sources_core, $ext_shared,,-I$pdo_inc_path)

    ifdef([PHP_ADD_EXTENSION_DEP],
    [
        PHP_ADD_EXTENSION_DEP(pdo_sqlcipher, pdo)
    ])
fi
