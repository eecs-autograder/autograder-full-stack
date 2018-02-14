FROM jameslp/autograder-sandbox:3.1.0

RUN apt-get update --fix-missing
RUN apt-get install -y software-properties-common
RUN apt-get install -y cppcheck

RUN add-apt-repository ppa:webupd8team/java
RUN apt-get update

RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
    apt-get install -y oracle-java8-installer

ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
ENV JAVA_TOOL_OPTIONS -Xms512m -Xmx512m -XX:+UseSerialGC -XX:MaxMetaspaceSize=256m -XX:CompressedClassSpaceSize=128m

RUN apt-get install -y unzip

COPY pmd-bin-6.0.1.zip .
RUN unzip pmd-bin-6.0.1.zip
RUN mv pmd-bin-6.0.1 /opt/pmd
RUN cp /opt/pmd/bin/run.sh /opt/pmd/bin/pmd.sh

COPY oclint-0.13-x86_64-linux-4.4.0-93-generic.tar.gz .
RUN tar -xzf oclint-0.13-x86_64-linux-4.4.0-93-generic.tar.gz
RUN mv oclint-0.13 /opt/oclint

ENV PATH /opt/oclint/bin:/opt/pmd/bin:$PATH
