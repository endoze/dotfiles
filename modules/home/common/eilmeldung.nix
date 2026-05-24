{ config, options, pkgs, lib, sourceRoot, userConfig, inputs, ... }:

let hasSops = options ? sops;
in
{
  imports = [ inputs.eilmeldung.homeManager.default ];

  config = lib.mkMerge ([
    {
      programs.eilmeldung = {
        enable = true;
        package = inputs.eilmeldung.packages.${pkgs.stdenv.hostPlatform.system}.eilmeldung;

        settings.input_config.mappings = {
          "j" = [ "down" "scrape" ];
          "k" = [ "up" "scrape" ];
        };
      };
    }
  ] ++ lib.optional hasSops {
    sops = {
      age.keyFile = "${userConfig.homeDirectory}/.config/sops/age/keys.txt";
      defaultSopsFile = sourceRoot + "/secrets/shared.enc.yaml";

      secrets."miniflux-token" = { };
    };

    programs.eilmeldung.settings.login_setup = {
      login_type = "direct_token";
      provider = "miniflux";
      url = "https://miniflux.kahdu.org/";
      token = "cmd:cat ${config.sops.secrets."miniflux-token".path}";
    };
  });
}
