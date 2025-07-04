# kyverno

i'm already injecting my root ca cert with a kyverno policy. on cert change the configmap will change, however, until pods restart the .crt in the filesystem won't change. this is not critical as the root cert expires in 2035, but i should still be aware.