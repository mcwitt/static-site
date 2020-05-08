let
  region = "us-east-1";
  accessKeyId = "dev";

in {
  resources.ec2KeyPairs.my-key-pair = { inherit region accessKeyId; };

  webserver = { resources, ... }: {
    deployment = {
      targetEnv = "ec2";

      ec2 = {
        accessKeyId = accessKeyId;
        region = region;
        instanceType = "t2.micro";
        keyPair = resources.ec2KeyPairs.my-key-pair;
        securityGroups =
          [ "default" "inbound-ssh-anywhere" "inbound-http-anywhere" ];
      };
    };
  };
}
