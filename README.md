# PDO SQLCipher

[English version](https://github.com/abbat/pdo_sqlcipher/blob/master/README.en.md)

Драйвер, реализующий интерфейс [PDO](http://php.net/manual/en/book.pdo.php) (PHP Data Objects) для [SQLCipher](http://sqlcipher.net) без замещения оригинальной версии PDO SQLite или системной версии [SQLite](http://www.sqlite.org/). Основан на оригинальном коде PDO SQLite путем простого замещения имен и встраиванием кода SQLCipher (вместо динамической линковки с библиотеками SQLite).

Подобное разделение позволяет работать с шифрованными базами только тем приложениям, которые в этом явно нуждаются не опасаясь потери данных или замедления работы остальных приложений.

## Сборка

Для сборки расширения запустите скрипт `build.sh`. После успешной сборки необходимые файлы будут помещены в директорию `release`:

* `sqlcipher` - консольный клиент (аналогичный клиенту `sqlite3`)
* `pdo_sqlcipher.so` - расширение php (аналогичное расширению `pdo_sqlite.so`)

Для сборки под Debain могут потребоваться (помимо стандартных) следующие dev пакеты:

* `libicu-dev`
* `libreadline-dev`
* `libssl-dev`
* `php5-dev`
* `tcl-dev`

Для сборки под RHEL могут потребоваться (помимо стандартных) следующие dev пакеты:

* `libicu-devel`
* `readline-devel`
* `openssl-devel`
* `php-devel`
* `tcl-devel`

Для сборки под FreeBSD может потребоваться установка порта `lang/tcl-wrapper` (для поддержки `tclsh`).

Скрипт сборки протестирован на Debian Wheezy (PHP 5.4.4-14) и FreeBSD 9.1 (PHP 5.4.13)

## Установка

Для установки расширения скопируйте файлы из директории `release`:

* `sqlcipher` в директорию `/usr/local/bin/`
* `pdo_sqlcipher.so` в директорию модулей php (зависит от дистрибутива):
  * Debian:  `/usr/lib/php5/20100525/`
  * RHEL:    `/usr/lib64/php/modules/`
  * FreeBSD: `/usr/local/lib/php/20100525/`

И подключите расширение php:

```
extension=pdo_sqlcipher.so
```

* Debian:  `/etc/php5/conf.d/pdo_sqlcipher.ini`
* RHEL:    `/etc/php.d/pdo_sqlcipher.ini`
* FreeBSD: `/usr/local/etc/php/usr/local/etc/php/extensions.ini`

Пример использования расширения можно найти в файле `example.php` репозитория.
