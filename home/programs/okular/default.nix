{
  programs.okular = {
    enable = true;

    accessibility.changeColors = {
      enable = true;
      mode = "Paper";
      # paperColor = "253,246,227";
    };
  };

  programs.plasma.configFile."okularpartrc"."Zoom" = {
    "ZoomMode" = 4;
    "CustomZoomFactor" = 66;
  };
}
