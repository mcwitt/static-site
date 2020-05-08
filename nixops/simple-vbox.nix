{
  webserver = _: {
    deployment = {
      targetEnv = "virtualbox";

      virtualbox = {
        memorySize = 1024; # megabytes
        virtualbox.vcpu = 2; # number of cpus
      };
    };
  };
}
