{ ... }:

{
  imports = [
    ./postgres.nix
    ./mysql.nix
    ./redis.nix
    ./rabbitmq.nix
  ];
}
