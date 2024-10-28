how to install mysql:
1. please create pv, and the pv number need to equal the replica num
  kubectl apply -f persistentVolume.yaml
2. create statefulset
   healm install mysql .

by above step, then can success to create mysql master and slave nodes
