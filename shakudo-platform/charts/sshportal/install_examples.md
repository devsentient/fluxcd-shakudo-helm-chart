# Example helm installs


## shakdemo
helm install ssh-portal ssh_portal --set publicKey=id_ed25519_shakdemo.pub,privateKey=id_ed25519_shakdemo,domain=shakdemo.hyperplane.dev,namespace=pipelines-j481vhvk,gateway=istio-16xu7q55/ingress-gateway-1y79qhu9 --kube-context shakdemo


## shakdemo
helm install ssh-portal ssh_portal --set publicKey=id_ed25519_kin.pub,privateKey=id_ed25519_kin,domain=kin.hyperplane.dev,namespace=pipelines-kycrph1i,gateway=istio-nhi6febg/ingress-gateway-sg3vma59 --kube-context gke_kinfoundation_us-central1-a_kin-7d17c08