ARG VERSION

FROM php:${VERSION}-cli

COPY --from=ghcr.io/mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions @composer xdebug pdo_mysql pdo_pgsql pdo_firebird pdo_sqlsrv sqlsrv oci8
