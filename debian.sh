#!/bin/sh

RELEASE_DIR="release"

mkdir -p package/usr/bin
if [ $? -ne 0 ]; then
	exit $?
fi

mkdir -p package/usr/lib/php5/20100525
if [ $? -ne 0 ]; then
	exit $?
fi

cp "${RELEASE_DIR}/pdo_sqlcipher.so" package/usr/lib/php5/20100525/
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
