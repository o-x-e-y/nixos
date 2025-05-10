let
  firefox = "firefox.desktop";
  zed = "dev.zed.Zed.desktop";
in
{
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = firefox;
      "x-scheme-handler/https" = firefox;
      "x-scheme-handler/about" = firefox;
      "x-scheme-handler/unknown" = firefox;
      "text/html" = firefox;

      "text/plain" = zed;
      "text/css" = zed;
      "text/csv" = zed;
      "text/javascript" = zed;
      "text/xml" = zed;
    };
  };
}
