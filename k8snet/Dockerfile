FROM busybox

MAINTAINER lgy

ENV GOPATH /fabricServer

RUN mkdir /fabricServer && mkdir /fabricServer/src

ADD fabricServer /fabricServer
ADD fabricServer /fabricServer/src/chaincode
WORKDIR /fabricServer
EXPOSE 8899
#ENTRYPOINT ["./fabricServer"]
CMD ["/bin/bash"]