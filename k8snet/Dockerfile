FROM busybox

MAINTAINER 1065940@qq.com

ENV GOPATH /fabricServer

RUN mkdir /fabricServer && mkdir /fabricServer/src

ADD fabricServer /fabricServer
ADD fabricServer /fabricServer/src/chaincode
WORKDIR /fabricServer
EXPOSE 8899
#ENTRYPOINT ["./fabricServer"]
CMD ["/bin/bash"]
