{ config, ... }:
{
  home-manager.users.${config.main-user.username} = {
    programs.fastfetch = {
      enable = true;
      settings = {
        logo = {
          source = ./../public/fastfetch-dofsmie.ans;
        };
        display = {
          separator = ": ";
          color = "green";
        };
        general = {
          thread = true;
        };
        modules = [
          {
            type = "title";
            format = "{#red}[{#}{6}{7}{8} {#magenta}{3}{#red}]{#}";
            color = {
              user = "yellow";
              at = "cyan";
              host = "blue";
            };
          }
          {
            type = "separator";
            string = "-";
            length = 30;
          }
          "os"
          "host"
          "kernel"
          "uptime"
          "packages"
          "shell"          
          "de"
          "wm"
          "wmtheme"
          "theme"
          
          "break"
          {
            type = "cpu";
            showPeCoreCount = true;
            temp = true;
          }
          {
            type = "gpu";
            driverSpecific = true;
            temp = true;
          }
          {
            type = "memory";
            format = "{} / {}";
          }
          {
            type = "physicaldisk";
            key = "Disk";
          }
          {
            type = "display";
            format = "{width}x{height} @ {preferred-refresh-rate} in {inch}\" [{type}]";
          }
          {
            type = "battery";
            temp = true;
            format = "{4} - [{5}]";
          }
          
          "break"
          {
            type = "weather";
            timeout = 1000;
          }
          
          "break"
          "version"
          "break"
          "colors"
        ];
      };
    };
  };
}
