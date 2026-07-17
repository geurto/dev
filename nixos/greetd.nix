{ pkgs, ... }:

{
  # ── Greeter (greetd + tuigreet) ───────────────────────────────────────────
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = ''
          ${pkgs.tuigreet}/bin/tuigreet \
            --time \
            --remember \
            --cmd start-hyprland \
            --theme border=spanish_viridian;text=camarone;prompt=asparagus;time=camarone;action=camarone;button=dark_sea_green;container=dark_sea_green;input=spanish_viridian
        '';
        user = "greeter";
      };
    };
  };

  # ── Lock screen PAM service ───────────────────────────────────────────────
  security.pam.services.hyprlock = { };
}
