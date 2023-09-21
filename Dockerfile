# syntax=docker/dockerfile:1
FROM php:7.4-apache
COPY ./sslip.crt /etc/apache2/ssl/ssl.crt
COPY ./sslip.key /etc/apache2/ssl/ssl.key
RUN mkdir -p /var/run/apache2/
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf
#RUN echo "ServerName oncoccdi" | tee /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite
RUN a2enmod ssl
#RUN a2enconf 000-default
RUN apt update -qq
RUN apt install --no-install-recommends software-properties-common dirmngr gnupg2 gfortran libblas-dev liblapack-dev libssl-dev libcurl4-openssl-dev libxml2-dev wget git -y
RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -P /tmp
RUN bash /tmp/Miniconda3-latest-Linux-x86_64.sh -p /var/www/html/miniconda3 -b
WORKDIR /opt
RUN git clone https://github.com/rghu/reconCNV.git
WORKDIR /opt/reconCNV
SHELL ["/bin/bash", "-c"] 
ENV PATH="${PATH}:/var/www/html/miniconda3/bin"
RUN conda env create -f environment.yml
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/"
RUN apt install --no-install-recommends r-base -y
RUN set -x \
        && apt-get update -qq \
        && apt-get install libaio-dev mc unzip zlib1g-dev libmemcached-dev --no-install-recommends --no-install-suggests -y \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*
RUN R -e "install.packages('https://cran.r-project.org/src/contrib/Archive/locfit/locfit_1.5-9.1.tar.gz', repos=NULL, type='source')"
RUN R -e "install.packages('dplyr');install.packages('tibble');install.packages('BiocManager');install.packages('KernSmooth');BiocManager::install('sva');BiocManager::install('edgeR');BiocManager::install('DESeq2');"
ENV ORA_CLIENT=instantclient-basic-linux.x64-21.1.0.0.0.zip
ENV ORA_CLIENT_SDK=instantclient-sdk-linux.x64-21.1.0.0.0.zip
ENV ORA_URL_PART=https://download.oracle.com/otn_software/linux/instantclient/211000
ENV ORA_CLIENT_DIR=/opt/instantclient_21_1
WORKDIR /opt
RUN curl -O ${ORA_URL_PART}/${ORA_CLIENT} \
    && curl -O ${ORA_URL_PART}/${ORA_CLIENT_SDK} \
    && unzip /opt/${ORA_CLIENT} \
    && unzip /opt/${ORA_CLIENT_SDK} \
    && rm /opt/${ORA_CLIENT} && rm ${ORA_CLIENT_SDK}
ENV LD_LIBRARY_PATH=${ORA_CLIENT_DIR}
RUN ldconfig
RUN perl -MCPAN -e 'install Bundle::DBI;install Bundle::LWP;install Try::Tiny;install MIME::Lite;install +YAML;install Test::NoWarnings;install DBD::Oracle'
#COPY oncogenomics /var/www/html/clinomics
RUN apt-get update -qq && apt-get install -y libmcrypt-dev \
    && pecl install mcrypt-1.0.4 \
    && echo "instantclient,${ORA_CLIENT_DIR}" | pecl install oci8-2.2.0 \
    && docker-php-ext-enable mcrypt
RUN echo "extension=oci8.so" > /usr/local/etc/php/conf.d/php-oci8.ini
RUN echo "<?php echo phpinfo(); ?>" > /var/www/html/phpinfo.php
RUN chown -R www-data:www-data /var/www
WORKDIR /var/www/html
CMD ["apache2-foreground"]
