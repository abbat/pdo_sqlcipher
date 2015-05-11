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
	-I. -I/usr/local/include"

LDFLAGS="-lcrypto -licuuc -licui18n -L/usr/local/lib"


PHP_CONFIG=$(which php-config)

if [ "x${PHP_CONFIG}" = "x" ]; then
	echo "Error: php-config not found"
	exit 1
fi

PHP_VER=$(${PHP_CONFIG} --version )
PHP_API=$(${PHP_CONFIG} --phpapi )

if [ "x${PHP_VER}" = "x" ]; then
	echo "Error: unknown php version"
	exit 1
fi

PHP_SRC1="$(dpkg-query -W -f='${Version}' php5)"
PHP_SRC=${PHP_SRC1%*-*}

if [ ! -f "${PHP_SRC}" ]; then
	apt-get source php5
	if [ $? -ne 0 ]; then
		# sources.list not defined source packages
		echo "Cannot get the php source package, please add a 'source' line to /etc/apt/sources.list"
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
if [ $? -ne 0 ]; then
	exit $?
fi

# magic :)
for FILE in "${BUILD_DIR}"/*
do
	cat "${FILE}" | \
		sed -e 's/sqlite/sqlcipher/g'         | \
		sed -e 's/SQLite/SQLCipher/g'         | \
		sed -e 's/PDO_SQLITE/PDO_SQLCIPHER/g' > \
		"${FILE}.tmp"
	if [ $? -ne 0 ]; then
		exit $?
	fi

	NEW_FILE=$(echo ${FILE} | sed 's/sqlite/sqlcipher/')

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

# magic for sqlite3 api sources
cp "${SQLCIPHER_SRC}/sqlite3.c" "${BUILD_DIR}/sqlcipher3.c"
if [ $? -ne 0 ]; then
	exit $?
fi

cp "${SQLCIPHER_SRC}/sqlite3.h" "${BUILD_DIR}/sqlcipher3.h"
if [ $? -ne 0 ]; then
	exit $?
fi

for FILE in "${BUILD_DIR}"/sqlcipher3.*
do
	sed -ie 's/sqlite3/sqlcipher3/g' "${FILE}"
	if [ $? -ne 0 ]; then
		exit $?
	fi

	sed -rie 's/(".*)sqlcipher3(.*")/\1sqlite3\2/g' "${FILE}"
	if [ $? -ne 0 ]; then
		exit $?
	fi
done

#
# Build pdo_sqlcipher
#

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
cp "${SQLCIPHER_SRC}/sqlcipher" "${RELEASE_DIR}/sqlcipher"
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

#rm -rf ${PHP_SRC}
#rm -rf ${SQLCIPHER_SRC}
#rm -rf ${BUILD_DIR}
#rm -f  ${PHP_TGZ}


## Create the .deb package

LIBICU="$(dpkg-query -W -f='${Package}\n' libicu* | grep -v '\-')
LIBICU_VER="$(dpkg-query -W  -f='${Version}' $LIBICU)"

sed -i "s/_PHP_VER/$PHP_VER/g;s/_PHP_API/$PHP_API/g;s/_LIBICU/$LIBICU/g;s/_LIBICU_VER/$LIBICU_VER/g" package/DEBIAN/control

mkdir -p package/usr/bin
if [ $? -ne 0 ]; then
	exit $?
fi

mkdir -p package/usr/lib/php5/${PHP_API}
if [ $? -ne 0 ]; then
	exit $?
fi

cp "${RELEASE_DIR}/pdo_sqlcipher.so" package/usr/lib/php5/${PHP_API}/
if [ $? -ne 0 ]; then
	exit $?
fi

cp "${RELEASE_DIR}/sqlcipher" package/usr/bin/
if [ $? -ne 0 ]; then
	exit $?
fi

cd package

md5deep -rl etc usr > DEBIAN/md5sums
if [ $? -ne 0 ]; then
	exit $?
fi

cd ..

fakeroot dpkg-deb -z9 -b package
if [ $? -ne 0 ]; then
	exit $?
fi

mv package.deb php5-sqlcipher.deb
if [ $? -ne 0 ]; then
	exit $?
fi

# http://lintian.debian.org/tags.html
lintian php5-sqlcipher.deb
if [ $? -ne 0 ]; then
	exit $?
fi

# clean
rm -rf package/usr/bin
rm -rf package/usr/lib
rm -f  package/DEBIAN/md5sums

