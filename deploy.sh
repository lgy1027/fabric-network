#!/bin/bash
//清理环境
docker stop $(docker ps -aq)

docker rm $(docker ps -aq)

rm -rf channel-artifacts/

rm -rf crypto-config

sudo rm -rf peer/

//生成证书、通道配置文件、创世区块等
./bin/cryptogen generate --config=./crypto-config.yaml

mkdir channel-artifacts
./bin/configtxgen -profile SampleMultiNodeEtcdRaft -outputBlock ./channel-artifacts/genesis.block

./bin/configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/mychannel.tx -channelID mychannel

//crypto-config和channel-artifacts两个目录拷贝到其他节点
scp -r ./crypto-config/ root@192.168.1.8:/home/goproject/peer/raft-cluster
scp -r ./channel-artifacts/ root@192.168.1.8:/home/goproject/peer/raft-cluster

scp -r ./crypto-config/ root@192.168.1.9:/home/goproject/peer/raft-cluster
scp -r ./channel-artifacts/ root@192.168.1.9:/home/goproject/peer/raft-cluster

scp -r ./crypto-config/ root@192.168.1.10:/home/goproject/peer/raft-cluster
scp -r ./channel-artifacts/ root@192.168.1.10:/home/goproject/peer/raft-cluster


//启动orderer节点
docker-compose -f order0.yaml up -d

docker-compose -f order1.yaml up -d

docker-compose -f order2.yaml up -d


//启动peer0org1
docker-compose -f peer0org1.yaml up -d

docker exec -it cli0 bash

//创建通道
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/lgy.com/tlsca/tlsca.lgy.com-cert.pem
peer channel create -o orderer0.lgy.com:10050 -c mychannel -f ./channel-artifacts/mychannel.tx --tls --cafile $ORDERER_CA

//节点加入通道
peer channel join -b mychannel.block

//安装智能合约
peer chaincode install -n mycc -p /opt/gopath/src/github.com/chaincode/sacc -v 1.0

//实例化是能合约
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/lgy.com/tlsca/tlsca.lgy.com-cert.pem
peer chaincode instantiate -o orderer0.lgy.com:10050 --tls --cafile $ORDERER_CA -C mychannel -n mycc -v 1.0 -c '{"Args":["a","100"]}' -P "OR ('Org1MSP.peer','Org2MSP.peer')"

//查询
peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'


//交易
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/lgy.com/tlsca/tlsca.lgy.com-cert.pem
peer chaincode invoke --tls --cafile $ORDERER_CA -C mychannel -n mycc -c '{"Args":["set","a","20"]}'

//启动peer1org1节点
docker-compose -f peer1org1.yaml up -d

//将peer0org1生成的通道配置区块发送到peer1org1节点
scp -r ./mychannel.block root@192.168.1.8:/home/goproject/peer/raft-cluster/

sudo mv ./mychannel.block ./peer

//重新启动peer1org1节点
docker-compose -f peer1org1.yaml up -d

docker exec -it cli1 bash

//节点加入通道
peer channel join -b mychannel.block

//节点安装链码
peer chaincode install -n mycc -p /opt/gopath/src/github.com/chaincode/sacc -v 1.0

//启动peer0org2节点
docker-compose -f peer0org2.yaml up -d


//将peer0org1生成的通道配置区块发送到peer0org2节点
scp -r ./mychannel.block root@192.168.1.9:/home/goproject/peer/raft-cluster/

sudo mv ./mychannel.block ./peer

//重启peer0org2节点
docker-compose -f peer0org2.yaml up -d

docker exec -it cli0 bash

//节点加入通道
peer channel join -b mychannel.block

//节点安装智能合约
peer chaincode install -n mycc -p /opt/gopath/src/github.com/chaincode/sacc -v 1.0


//启动peer1org2
docker-compose -f peer1org2.yaml up -d

docker exec -it cli1 bash

peer channel join -b mychannel.block

peer chaincode install -n mycc -p /opt/gopath/src/github.com/chaincode/sacc -v 1.0