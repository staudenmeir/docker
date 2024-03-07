ARG VERSION

# Compile Firebird PDO extension
FROM ubuntu:latest AS pdo_firebird

ARG VERSION

RUN apt-get update && \
    apt-get install -y python3-launchpadlib software-properties-common && \
    add-apt-repository ppa:ondrej/php -y && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl firebird-dev php${VERSION}-dev unzip

RUN curl -Ls https://github.com/php/php-src/archive/refs/heads/PHP-${VERSION}.zip > php-src.zip && \
    unzip -q php-src.zip && \
    mv php-src-PHP-${VERSION} php-src && \
    cd php-src/ext/pdo_firebird && \
    phpize && \
    CPPFLAGS=-I/usr/include/firebird ./configure && \
    make

ARG VERSION

FROM php:${VERSION}-cli

RUN apt-get update && \
    apt-get install -y unzip

## MySQL
RUN docker-php-ext-install pdo_mysql

# PostgreSQL
RUN apt-get install -y libpq-dev && \
    docker-php-ext-install pdo_pgsql

# SQL Server
RUN apt-get install -y gpg &&  \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg && \
    curl https://packages.microsoft.com/config/debian/12/prod.list | tee /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18 unixodbc-dev && \
    pecl install sqlsrv pdo_sqlsrv && \
    docker-php-ext-enable sqlsrv pdo_sqlsrv

# Firebird
COPY --from=pdo_firebird /php-src/ext/pdo_firebird/modules/pdo_firebird.so pdo_firebird.so

RUN mv pdo_firebird.so $(php-config --extension-dir) && \
    apt-get install -y firebird-dev && \
    docker-php-ext-enable pdo_firebird

RUN pecl install xdebug

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
