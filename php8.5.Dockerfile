FROM php:8.5-cli

COPY --from=ghcr.io/mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions @composer xdebug pdo_mysql pdo_pgsql pdo_sqlsrv sqlsrv oci8
