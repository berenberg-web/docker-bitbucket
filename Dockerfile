FROM openjdk:8u121-jdk

# Install git, ssh, sendmail
RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends \
    git \
    libtcnative-1 \
    sendmail \
    ssh \
 && apt-get clean autoclean \
 && apt-get autoremove --yes \
 && rm -rf /var/lib/{apt,dpkg,cache,log}/

# Bitbucket envs    
ENV BITBUCKET_USER=bitbucket \
    BITBUCKET_UID=1591 \
    BITBUCKET_GROUP=bitbucket \
    BITBUCKET_GID=1591 \
    BITBUCKET_HOME=/var/atlassian/application-data/bitbucket \
    BITBUCKET_INSTALL_DIR=/opt/atlassian/bitbucket \
    BITBUCKET_VERSION=4.14.4

# User settings  
RUN addgroup \
    --gid ${BITBUCKET_GID} \
    ${BITBUCKET_GROUP} \
 && adduser \
    --uid ${BITBUCKET_UID} \
    --ingroup ${BITBUCKET_GROUP} \
    --home ${BITBUCKET_HOME} \
    --shell /bin/false \
    --disabled-password \
    -c "Bitbucket Account" \
    --gecos "" \
    ${BITBUCKET_USER} 

# Install bitbucket + config
RUN mkdir -p ${BITBUCKET_INSTALL_DIR} \
 && curl -L --silent https://downloads.atlassian.com/software/stash/downloads/atlassian-bitbucket-${BITBUCKET_VERSION}.tar.gz | tar -xz --strip=1 -C "$BITBUCKET_INSTALL_DIR" \
 && mkdir -p ${BITBUCKET_INSTALL_DIR}/conf/Catalina \
 && chmod -R 700 \
    ${BITBUCKET_INSTALL_DIR}/conf/Catalina \
    ${BITBUCKET_INSTALL_DIR}/logs \
    ${BITBUCKET_INSTALL_DIR}/temp \
    ${BITBUCKET_INSTALL_DIR}/work \
 && chown -R ${BITBUCKET_USER}:${BITBUCKET_GROUP} ${BITBUCKET_INSTALL_DIR}/ \
 && ln -s "/usr/lib/x86_64-linux-gnu/libtcnative-1.so" "${BITBUCKET_INSTALL_DIR}/lib/native/libtcnative-1.so" \
 && sed -i -e \
    's@^export CATALINA_OPTS$@. $PRGDIR/catalina-connector-opts.sh\nexport CATALINA_OPTS@' \
    ${BITBUCKET_INSTALL_DIR}/bin/setenv.sh \
 && sed -i -e \
    's@$PRGDIR/catalina.sh@CATALINA_OPTS="$CATALINA_OPTS" $PRGDIR/catalina.sh@' \
    -e 's@$PRGDIR/startup.sh@CATALINA_OPTS="$CATALINA_OPTS" $PRGDIR/startup.sh@' \
    ${BITBUCKET_INSTALL_DIR}/bin/start-webapp.sh \
 && sed -i -e \
    's/port="7990"/port="7990" secure="${catalinaConnectorSecure}" scheme="${catalinaConnectorScheme}" proxyName="${catalinaConnectorProxyName}" proxyPort="${catalinaConnectorProxyPort}"/' \
    ${BITBUCKET_INSTALL_DIR}/conf/server.xml

COPY catalina-connector-opts.sh ${BITBUCKET_INSTALL_DIR}/bin/

# Custom start script
COPY docker-entrypoint.sh /usr/local/bin/

RUN chmod -R 755 /usr/local/bin/docker-entrypoint.sh

# HTTP & SSH Port
EXPOSE 7990 7999

WORKDIR ${BITBUCKET_INSTALL_DIR}
 
ENTRYPOINT [ "docker-entrypoint.sh" ]

# Run in foreground
CMD [ "sh", "-c", "su -s /bin/bash --preserve-environment -c '${BITBUCKET_INSTALL_DIR}/bin/start-bitbucket.sh -fg' ${BITBUCKET_USER}" ]
