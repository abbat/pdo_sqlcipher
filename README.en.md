# PDO SQLCipher

A driver for implementing [PDO](http://php.net/manual/en/book.pdo.php) (PHP Data Objects)  interface for [SQLCipher](http://sqlcipher.net) without replacing genuine PDO SQLite or the system version of [SQLite](http://www.sqlite.org/). It's based on PDO SQLite source code and created by simply replacing names and inserting SQLCipher code (instead of dynamic linking with SQLite libraries).

A detachment of this kind allows granting access to encrypted databases only to applications that obviously need it, without fear of data loss or slowing down other applications.

## Assembling

To assemble this extension, run `build.sh` script. After successful assembly, all the necessary files will be placed in the directory named `release`:

* `sqlcipher` - console client (equivalent of `sqlite3` client)
* `pdo_sqlcipher.so` - php extension (equivalent of `pdo_sqlite.so` extension)

If assembling is performed under Debain, the following dev packages may be required (in addition to standard):

* `libicu-dev`
* `libreadline-dev`
* `libssl-dev`
* `php5-dev`
* `tcl-dev`

If assembling is performed under RHEL, the following dev packages may be required (in addition to standard):

* `libicu-devel`
* `readline-devel`
* `openssl-devel`
* `php-devel`
* `tcl-devel`

If assembling is performed under FreeBSD, `lang/tcl-wrapper` port installation may be required (to support `tclsh`).

Assembling script was tested under Debian Wheezy (PHP 5.4.4-14) and FreeBSD 9.1 (PHP 5.4.13)

## Installation

Install this extension by copying files from the `release` directory:

* `sqlcipher` to the `/usr/local/bin/` directory 
* `pdo_sqlcipher.so` to the directory of php modules (depends on specific distro):
  * Debian:  `/usr/lib/php5/20100525/`
  * RHEL:    `/usr/lib64/php/modules/`
  * FreeBSD: `/usr/local/lib/php/20100525/`

And enable the php extension:

```
extension=pdo_sqlcipher.so
```

* Debian:  `/etc/php5/conf.d/pdo_sqlcipher.ini`
* RHEL:    `/etc/php.d/pdo_sqlcipher.ini`
* FreeBSD: `/usr/local/etc/php/usr/local/etc/php/extensions.ini`

You can find an example of extension usage in `example.php` file within the repository.
