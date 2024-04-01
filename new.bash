PROJECT_ID="riseworksstaging"
INSTANCE_NAME="rise-tf-primary"
CLIENT_CERT_NAME="client-cert"
GATEWAY_INSTANCE_NAME="gatewayvpc-wallets-vpc-sql"
GATEWAY_CLIENT_CERT_NAME="gateway-client-cert"
SERVICE_ACCOUNT_KEY_FILE="riseworksdev-tf-sa.json"


gcloud config set project ${PROJECT_ID} 

gcloud sql ssl client-certs create $CLIENT_CERT_NAME client-key.pem --instance=$INSTANCE_NAME

sleep 10

gcloud sql ssl client-certs describe $CLIENT_CERT_NAME --instance=$INSTANCE_NAME --format="value(cert)" > client-cert.pem

sleep 10

gcloud sql instances describe $INSTANCE_NAME --format="value(serverCaCert.cert)" > server-ca.pem

sleep 10

gcloud sql instances patch $INSTANCE_NAME --ssl-mode=TRUSTED_CLIENT_CERTIFICATE_REQUIRED

sleep 50

gcloud secrets create gcp-tf-client-cert --replication-policy="automatic"

gcloud secrets create gcp-tf-server-ca --replication-policy="automatic"

gcloud secrets create gcp-tf-client-key --replication-policy="automatic"

gcloud secrets versions add gcp-tf-client-cert --data-file="client-cert.pem"

gcloud secrets versions add gcp-tf-server-ca --data-file="server-ca.pem"

gcloud secrets versions add gcp-tf-client-key --data-file="client-key.pem"


##CREATE SAME ONE BUT FOR GATEWAY

gcloud sql ssl client-certs create $GATEWAY_CLIENT_CERT_NAME gateway-client-key.pem --instance=$GATEWAY_INSTANCE_NAME

sleep 10

gcloud sql ssl client-certs describe $GATEWAY_CLIENT_CERT_NAME --instance=$GATEWAY_INSTANCE_NAME --format="value(cert)" > gateway-client-cert.pem

sleep 10

gcloud sql instances describe $GATEWAY_INSTANCE_NAME --format="value(serverCaCert.cert)" > gateway-server-ca.pem

sleep 10

gcloud sql instances patch $GATEWAY_INSTANCE_NAME --ssl-mode=TRUSTED_CLIENT_CERTIFICATE_REQUIRED

sleep 50

gcloud secrets create gateway-gcp-tf-client-cert --replication-policy="automatic"

gcloud secrets create gateway-gcp-tf-server-ca --replication-policy="automatic"

gcloud secrets create gateway-gcp-tf-client-key --replication-policy="automatic"

gcloud secrets versions add gateway-gcp-tf-client-cert --data-file="gateway-client-cert.pem"

gcloud secrets versions add gateway-gcp-tf-server-ca --data-file="gateway-server-ca.pem"

gcloud secrets versions add gateway-gcp-tf-client-key --data-file="gateway-client-key.pem"



##PSC CONNECT

# gcloud compute addresses create cloudsqlredisnewvpc --project=$PROJECT_ID --region=us-central1 --subnet=internal-api-vpc-subnet --addresses=10.13.1.0

# gcloud compute forwarding-rules create cloudsqlstoragenewvpcendpoint --address=cloudsqlredisnewvpc --project=riseworksstaging --region=us-central1 --network=internal-api-vpc --target-service-attachment=projects/x26457cdd1884a259p-tp/regions/us-central1/serviceAttachments/a-b929afbf526f-psc-service-attachment-afad745b8b50f292

# gcloud dns managed-zones create internal-api-vpc-dns --project=riseworksstaging --description=internal-dns-forsql --dns-name=internal-dns-forsql --networks=internal-api-vpc --visibility=private

# gcloud dns managed-zones create internal-api-vpc-dns --project=riseworksstaging --description=riseworksdev --dns-name=us-central1.sql.goog. --networks=internal-api-vpc --visibility=private


# gcloud compute addresses create ingresscloudsqlredisnewvpc --project=riseworksstaging --region=us-central1 --subnet=ingress-api-vpc-subnet --addresses=10.10.0.1


# gcloud compute forwarding-rules create ingresscloudsqlstoragenewvpcendpoint --address=ingresscloudsqlredisnewvpc --project=riseworksstaging --region=us-central1 --network=ingress-api-vpc --target-service-attachment=projects/x26457cdd1884a259p-tp/regions/us-central1/serviceAttachments/a-b929afbf526f-psc-service-attachment-afad745b8b50f292

# gcloud dns managed-zones create ingress-api-vpc-dns --project=riseworksstaging --description=riseworksstaging --dns-name=us-central1.sql.goog. --networks=ingress-api-vpc --visibility=private


# gcloud compute addresses create defaultsqlredisnewvpc --project=riseworksstaging --region=us-central1 --subnet=default --addresses=10.128.0.8

# gcloud compute forwarding-rules create cloudsqlredisnewvpcendpoint --address=cloudsqlredisnewvpc --project=riseworks-devops-rnd --region=us-central1 --network=default --target-service-attachment=projects/i6b67ad08cd233fb7p-tp/regions/us-central1/serviceAttachments/a-d32b3ee831e9-psc-service-attachment-efcc945548681043

# gcloud dns managed-zones create default-api-vpc-dns --project=riseworksstaging --description=riseworksstaging --dns-name=us-central1.sql.goog. --networks=default --visibility=private



# gcloud dns managed-zones create default-api-vpc-dns --project=riseworks-devops-rnd --description=riseworks-devops-rnd --dns-name=us-central1.sql.goog. --networks=default --visibility=private