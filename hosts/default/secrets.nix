{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = config.mainUser.username;
in
{
  sops = {
    defaultSopsFile = ./../../secrets/secrets.yaml;
    age.keyFile = "/home/${user}/.config/sops/age/keys.txt";

    secrets =
      lib.genAttrs
        [
          "canvas-api-key"
          # minecraft server addresses
          "grahp-city"
          "grahp-survival"
          "deepseek-api-key"
          "dashscope-api-key"
          "cronometer-email"
          "cronometer-password"
          "intervals_icu_key"
          "garmin-connect-email"
          "garmin-connect-password"
          "justwatch-email"
          "justwatch-password"
          "git_fhict_token"
        ]
        (_: {
          owner = user;
        })
      // {
        github_ssh_key = {
          owner = user;
          path = "/home/${user}/.ssh/id_ed25519_github";
          mode = "0600";
        };
      };

    templates."dsh-env" = {
      content = ''
        DEEPSEEK_API_KEY=${config.sops.placeholder.deepseek-api-key}
        DASHSCOPE_API_KEY=${config.sops.placeholder.dashscope-api-key}
        CRONOMETER_USERNAME=${config.sops.placeholder.cronometer-email}
        CRONOMETER_PASSWORD=${config.sops.placeholder.cronometer-password}
        INTERVALS_API_KEY=${config.sops.placeholder.intervals_icu_key}
      '';
      owner = user;
      mode = "0600";
    };

    templates."git-credentials-fhict" = {
      content = ''
        username=oxey
        password=${config.sops.placeholder.git_fhict_token}
      '';
      owner = user;
      mode = "0600";
    };
  };

  environment.systemPackages = [ pkgs.sops ];
}
