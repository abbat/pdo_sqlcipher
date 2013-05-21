#!/bin/sh

#
# SQLite3 compile options
#

CFLAGS=" \
	-DSQLITE_HAS_CODEC \
	-DSQLITE_ENABLE_UPDATE_DELETE_LIMIT \
	-DSQLITE_ENABLE_COLUMN_METADATA \
	-DSQLITE_ENABLE_STAT3 \
	-DSQLITE_ENABLE_RTREE \
	-DSQLITE_ENABLE_FTS3 \
	-DSQLITE_ENABLE_FTS3_PARENTHESIS \
	-DSQLITE_ENABLE_FTS4 \
	-DSQLITE_SECURE_DELETE \
	-DSQLITE_ENABLE_ICU \
	-DSQLITE_SOUNDEX \
	-DSQLITE_DEFAULT_FOREIGN_KEYS=1 \
	-I/usr/local/include"

LDFLAGS="-lcrypto -licuuc -licui18n -L/usr/local/lib"

#
# Get PHP source code (installed version)
#

PHP_CONFIG=$(which php-config)

if [ "x${PHP_CONFIG}" = "x" ]; then
	echo "Error: php-config not found"
	exit 1
fi

# 5.3.3-7+squeeze13
PHP_VER=$(${PHP_CONFIG} --version | cut -d '-' -f 1)

if [ "x${PHP_VER}" = "x" ]; then
	echo "Error: unknown php version"
	exit 1
fi

PHP_SRC="php-${PHP_VER}"
PHP_TGZ="${PHP_SRC}.tar.gz"

if [ ! -f "${PHP_TGZ}" ]; then
	wget "http://museum.php.net/php5/${PHP_TGZ}"
	if [ $? -ne 0 ]; then
		# newest version?
		wget -O "${PHP_TGZ}" "http://ru2.php.net/get/${PHP_TGZ}/from/this/mirror"
		if [ $? -ne 0 ]; then
			exit $?
		fi
	fi
fi

if [ ! -d "${PHP_SRC}" ]; then
	tar -xf "${PHP_TGZ}" -C ./
	if [ $? -ne 0 ]; then
		exit $?
	fi
fi

#
# Get SQLCipher source code and make SQLite Amalgamation
#

SQLCIPHER_SRC="sqlcipher.git"

if [ ! -d "${SQLCIPHER_SRC}" ]; then
	git clone "git://github.com/sqlcipher/sqlcipher.git" "${SQLCIPHER_SRC}"
	if [ $? -ne 0 ]; then
		exit $?
	fi
fi

if [ ! -f "${SQLCIPHER_SRC}/sqlite3.c" ]; then
	cd "${SQLCIPHER_SRC}"

	make distclean

	# subject to change (see http://www.sqlite.org/compile.html)
	./configure \
		--disable-shared \
		--enable-tempstore=yes \
		CFLAGS="${CFLAGS}" \
		LDFLAGS="${LDFLAGS}"
	if [ $? -ne 0 ]; then
		exit $?
	fi

	make
	if [ $? -ne 0 ]; then
		exit $?
	fi

	cd ..
fi

#
# Clone pdo_sqlite sources for pdo_sqlcipher
#

BUILD_DIR="build"

if [ -d "${BUILD_DIR}" ]; then
	rm -rf "${BUILD_DIR}"
	if [ $? -ne 0 ]; then
		exit $?
	fi
fi

mkdir -p "${BUILD_DIR}"
if [ $? -ne 0 ]; then
	exit $?
fi

PDO_SQLITE="${PHP_SRC}/ext/pdo_sqlite"

cp "${PDO_SQLITE}/"*.c "${PDO_SQLITE}"/*.h "${BUILD_DIR}/"

# magic :)
for FILE in "${BUILD_DIR}"/*
do
	cat "${FILE}" | \
		sed -e 's/<sqlite3.h>/"sqlite3.h"/g'                            | \
		sed -e 's/pdo_sqlite/pdo_sqlcipher/g'                           | \
		sed -e 's/php_sqlite3/php_sqlcipher/g'                          | \
		sed -e 's/sqlite_handle_/sqlcipher_handle_/g'                   | \
		sed -e 's/sqlite_stmt_methods/sqlcipher_stmt_methods/g'         | \
		sed -e 's/PDO_SQLITE/PDO_SQLCIPHER/g'                           | \
		sed -e 's/HEADER(sqlite)/HEADER(sqlcipher)/g'                   | \
		sed -e 's/PDO Driver for SQLite 3.x/PDO Driver for SQLCipher/g' | \
		sed -e 's/SQLite Library/SQLCipher Library/g'                   > \
		"${FILE}.tmp"
	if [ $? -ne 0 ]; then
		exit $?
	fi

	NEW_FILE=$(echo ${FILE} | sed 's/pdo_sqlite/pdo_sqlcipher/')

	mv "${FILE}.tmp" "${NEW_FILE}"
	if [ $? -ne 0 ]; then
		exit $?
	fi

	if [ "${NEW_FILE}" != "${FILE}" ]; then
		rm -f "${FILE}"
		if [ $? -ne 0 ]; then
			exit $?
		fi
	fi
done

#
# Build pdo_sqlcipher
#

cp "${SQLCIPHER_SRC}/sqlite3.c" "${BUILD_DIR}/sqlite3.c"
if [ $? -ne 0 ]; then
	exit $?
fi

cp "${SQLCIPHER_SRC}/sqlite3.h" "${BUILD_DIR}/sqlite3.h"
if [ $? -ne 0 ]; then
	exit $?
fi

cp "config.m4" "${BUILD_DIR}/config.m4"
if [ $? -ne 0 ]; then
	exit $?
fi

cd "${BUILD_DIR}"

phpize --clean
if [ $? -ne 0 ]; then
	exit $?
fi

phpize
if [ $? -ne 0 ]; then
	exit $?
fi

./configure \
	CFLAGS="${CFLAGS}" \
	LDFLAGS="${LDFLAGS}"
if [ $? -ne 0 ]; then
	exit $?
fi

make
if [ $? -ne 0 ]; then
	exit $?
fi

cd ..

#
# Copy binaries
#

RELEASE_DIR="release"

if [ -d "${RELEASE_DIR}" ]; then
	rm -rf "${RELEASE_DIR}"
	if [ $? -ne 0 ]; then
		exit $?
	fi
fi

mkdir -p "${RELEASE_DIR}"
if [ $? -ne 0 ]; then
	exit $?
fi

# pdo_sqlite.so
cp "${BUILD_DIR}/modules/pdo_sqlcipher.so" "${RELEASE_DIR}/pdo_sqlcipher.so"
if [ $? -ne 0 ]; then
	exit $?
fi

strip "${RELEASE_DIR}/pdo_sqlcipher.so"
if [ $? -ne 0 ]; then
	exit $?
fi

chmod 0644 "${RELEASE_DIR}/pdo_sqlcipher.so"
if [ $? -ne 0 ]; then
	exit $?
fi

# sqlcipher static binary
cp "${SQLCIPHER_SRC}/sqlite3" "${RELEASE_DIR}/sqlcipher"
if [ $? -ne 0 ]; then
	exit $?
fi

strip "${RELEASE_DIR}/sqlcipher"
if [ $? -ne 0 ]; then
	exit $?
fi

#
# Clean
#

rm -rf ${PHP_SRC}
rm -rf ${SQLCIPHER_SRC}
rm -rf ${BUILD_DIR}
rm -f  ${PHP_TGZ}
