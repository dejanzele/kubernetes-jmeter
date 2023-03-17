FROM justb4/jmeter:5.5

LABEL maintainer="pejcev.dejan@gmail.com"

EXPOSE 60000
ENV SSL_DISABLED true
ENV ONE_SHOT true
ENV SLAVE_SVC_NAME jmeter-slave
ENV TESTS_DIR /test

ADD plugins/ ${JMETER_CUSTOM_PLUGINS_FOLDER}
ADD lib/ ${JMETER_HOME}/lib
COPY ./docker/jmeter-master/entrypoint.sh /jmeter_entrypoint.sh
RUN chmod +x /jmeter_entrypoint.sh && mkdir /test

ENTRYPOINT /jmeter_entrypoint.sh
