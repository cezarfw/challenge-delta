#!/usr/bin/env bash

# Nome do programa - NodeAPI
#
#
# Site:        https://cezaraugustoroggia.com
# Autor:       Cezar Augusto Roggia
# Manutenção:  Cezar Augusto Roggia
#
# ---------------------------------------------------------------------
#
# Detalhar o programa
#       Serve para subir o ambiente do minikube, kubectl e as aplicacoes.
#       Sendo mysql, api com node e proxy com nginx.
#
# Execução:
#       $ ./script
#       O script não possui paramêtros
# ---------------------------------------------------------------------
#
# Testado em:
#   Bash 4.4.19
#
# ---------------------------------------------------------------------

echo ""
echo -e "\033[0;36mIniciando script de provisionamento\033[0m"
echo -e "\033[0;36mAguarde um momento enquanto faco algumas verificacoes necessarias\033[0m"


# Removendo cluster existente

sudo minikube delete > /dev/null 2>&1

sleep 10

# Removendo binario kubectl
sudo rm -rf /usr/local/bin/minikube > /dev/null 2>&1

rm -rf ~/.minikube > /dev/null

echo ""
echo -e "\033[0;36mPronto! Iniciando a instalacao do minikube e kubectl\033[0m"

# Instalacao do minikube
echo ""
echo ""
echo -e "\033[0;32m Instalacao do minikube\033[0m"
echo ""

curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube
sudo mv minikube /usr/local/bin/
echo ""

# Instalacao do kubectl
echo -e "\033[0;32m Instalacao do kubectl\033[0m"
echo ""

curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# Iniciando o cluster no minikube
echo ""
echo -e " \033[0;32m Inicializando minikube\033[0m"
echo ""
minikube start --extra-config=apiserver.service-node-port-range=1-65535

# Subindo as aplicacoes (banco de dados, nodeapi e nginx (proxy reverso))

kubectl delete -k ./manifestos/ > /dev/null 2>&1

echo ""
sleep 10

# Executando os manifestos para implementacao das apps no cluster kubernetes

echo -e "\033[0;32m Executando os manifestos do kubernetes\033[0m"
echo ""
kubectl create -k ./manifestos/

APP_IP=$(minikube service nginx -n hurb --url)

echo ""
while :; do

        PROXY_STATUS=$(kubectl get deployments.apps -n hurb nginx --output='jsonpath="{.status.availableReplicas}"' |tr -d '"')
        NODEAPI_STATUS=$(kubectl get deployments.apps -n hurb nodeapi --output='jsonpath="{.status.availableReplicas}"' |tr -d '"')
        DB_STATUS=$(kubectl get deployments.apps -n hurb mysql --output='jsonpath="{.status.availableReplicas}"' |tr -d '"')

        if [[ "$PROXY_STATUS" == "1" && "$NODEAPI_STATUS" == "1" && "$DB_STATUS" == "1" ]]
        then
		echo ""
   		echo -e "\033[0;32mProvisionamento do ambiente e apps finalizadas! \033[0m"
                break
        fi
        if [[ -z $PROXY_STATUS || -z $NODEAPI_STATUS && "$DB_STATUS" == "1" ]]
        then
		echo -e "\033[1;31m Aguarde um momento, aplicacaos ainda estao subindo!\033[0m" 
                sleep 10
        fi
done


# Criando pacote de exemplo pela API

sleep 5
echo ""

curl --location --request POST 'http://172.17.0.3' \
--header 'Content-Type: text/plain' \
--data-raw 'Pacote-Teste-v0.0.1' > /dev/null 2>&1

if [ "$?" -ne "0"  ] 
then
	echo ""
	echo -e "\033[1;31m Pacote teste nao foi criado corretamente, enviar manualmente para degubar a API\033[0m"
fi

echo ""
echo -e "\033[0;32mAcesse a aplicacao pela URL: $APP_IP \033[0m"
echo ""
echo ""

# Iniciando e abrindo dashboard
#minikube dashboard 


