{ ... }:

{
  imports = [
    ./databases/postgres.nix
    ./databases/mysql.nix
    ./databases/redis.nix
    ./databases/rabbitmq.nix
  ];
}
