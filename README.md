# static-site

Static site hosting personal content.

Generated using the [Rib](https://github.com/srid/rib) static site generator.

## Deploying with [NixOps](https://github.com/NixOS/nixops)

0. There's an unfortunate issue where `nix-build` doesn't work as expected from inside `nix-shell` (which is the case by default when we're inside the project directory, because we use `direnv`). Fortunately, there's a simple workaround: disable `direnv` before deploying (and re-enable afterwards).

    ``` shell
    $ direnv deny
    ```

1. The deployment configuration is in `./nixops`

    ``` sh
    $ cd nixops
    ```

2. (First deploy only.) Create a new deployment in the NixOps database (using the single-machine "simple" configuration):

    ``` sh
    $ nixops create simple.nix simple-ec2.nix -d simple-ec2
    ```
    Note: this requires an access key for `dev` to be defined, either in `~/.ec2-keys` or `~/.aws/credentials`. See the [NixOps User's Guide][nixops-guide-ec2] for details.

    It's also possible to deploy to a VirtualBox VM for local testing. See this [section][nixops-guide-vbox] of the guide.

3. Deploy using `nixops deploy`:

    ``` sh
    $ nixops deploy -d simple-ec2
    ```
    In theory, that's all there is to it. Note that the `deploy` command runs several steps:
    1. Spins up an EC2 instance with the type, region, and security groups specified in `simple-ec2.nix`.
      - Note: you'll need to first configure the referenced security groups by hand.
    2. Builds a "closure" (i.e. environment with dependencies) on your local machine
      - Note: to deploy from a darwin machine, you'll need to set up something like [nix-docker][nix-docker] to build dependencies in a linux environment. See this nice [tutorial][nixops-darwin-tutorial] for instructions.
    3. Pushes the closure to the EC2 instance
    4. Restarts relevant services on the EC2 instance (e.g. `nginx`)

[nix-docker]: https://github.com/LnL7/nix-docker
[nixops-darwin-tutorial]: https://medium.com/@zw3rk/provisioning-a-nixos-server-from-macos-d36055afc4ad
[nixops-guide-ec2]: https://releases.nixos.org/nixops/latest/manual/manual.html#sec-deploying-to-ec2
[nixops-guide-vbox]: https://releases.nixos.org/nixops/latest/manual/manual.html#idm140737322662048
