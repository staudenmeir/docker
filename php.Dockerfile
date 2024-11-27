ARG VERSION

# Compile Firebird PDO extension
FROM debian:bookworm AS pdo_firebird

ARG VERSION

RUN apt update && \
    apt install -y apt-transport-https curl lsb-release unzip && \
    curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg && \
    sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' && \
    apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y firebird-dev php${VERSION}-dev

RUN curl -Ls https://github.com/php/php-src/archive/refs/heads/PHP-${VERSION}.zip > php-src.zip && \
    unzip -q php-src.zip && \
    mv php-src-PHP-${VERSION} php-src && \
    cd php-src/ext/pdo_firebird && \
    phpize && \
    CPPFLAGS=-I/usr/include/firebird ./configure && \
    make

ARG VERSION

FROM php:${VERSION}-cli

RUN apt update && \
    apt install -y unzip

# MySQL
RUN docker-php-ext-install pdo_mysql

# PostgreSQL
RUN apt install -y libpq-dev && \
    docker-php-ext-install pdo_pgsql

# SQL Server
RUN apt install -y gpg &&  \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg && \
    curl https://packages.microsoft.com/config/debian/12/prod.list | tee /etc/apt/sources.list.d/mssql-release.list && \
    apt update && \
    ACCEPT_EULA=Y apt install -y msodbcsql18 unixodbc-dev && \
    pecl install sqlsrv pdo_sqlsrv && \
    docker-php-ext-enable sqlsrv pdo_sqlsrv

# Oracle
RUN apt install -y libaio1 libaio-dev && \
    mkdir /opt/oracle && \
    curl -o '/opt/oracle/basiclite.zip' 'https://download.oracle.com/otn_software/linux/instantclient/instantclient-basiclite-linuxx64.zip' && \
    unzip -o '/opt/oracle/basiclite.zip' -d /opt/oracle && \
    curl -o '/opt/oracle/sdk.zip' 'https://download.oracle.com/otn_software/linux/instantclient/instantclient-sdk-linuxx64.zip' && \
    unzip -o '/opt/oracle/sdk.zip' -d /opt/oracle && \
    mv /opt/oracle/instantclient_* /opt/oracle/instantclient && \
    ln -sf /opt/oracle/instantclient/*.so* /usr/lib/ && \
    echo 'instantclient,/opt/oracle/instantclient/' | pecl install oci8 && \
    docker-php-ext-enable oci8

# Firebird
COPY --from=pdo_firebird /php-src/ext/pdo_firebird/modules/pdo_firebird.so pdo_firebird.so

RUN mv pdo_firebird.so $(php-config --extension-dir) && \
    apt install -y firebird-dev && \
    docker-php-ext-enable pdo_firebird

RUN pecl install xdebug-3.4.0beta1

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
