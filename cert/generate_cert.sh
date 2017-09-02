#!/bin/bash

#ca
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

##harbor
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server harbor.json | cfssljson -bare harbor
