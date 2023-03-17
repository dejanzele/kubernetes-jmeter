FROM justb4/jmeter:5.5

LABEL maintainer="pejcev.dejan@gmail.com"

EXPOSE 1099 60001
ENV SSL_DISABLED true

ADD plugins/ ${JMETER_CUSTOM_PLUGINS_FOLDER}
ADD lib/ ${JMETER_HOME}/lib
COPY ./docker/jmeter-slave/entrypoint.sh /jmeter_entrypoint.sh
RUN chmod +x /jmeter_entrypoint.sh

ENTRYPOINT /jmeter_entrypoint.sh
