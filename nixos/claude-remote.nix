# Remote Claude Code on the PC — phase 1.
#
# Runs `claude remote-control` as a dedicated, unprivileged `claude` user
# (lingering systemd user services, so no login is needed), and suspends the
# PC to S3 once Claude, SSH and the desk have all been idle for a while.
# Waking is done from Home Assistant via Wake-on-LAN (enabled on enp5s0 in
# pc-extras.nix). Prompts reach the PC only through Anthropic's servers; the
# PC dials out, nothing listens on the tailnet for them. SSH over Tailscale is
# the maintenance path.
#
# One-time manual steps after the first `nixos-rebuild switch` (as claude,
# over SSH: `ssh -p 24473 claude@nixos-pc`):
#   1. claude auth login          (claude.ai option — API keys are rejected)
#   2. cd ~/code && claude remote-control   → accept the Remote Control and
#      trust prompts, then Ctrl+C. Repeat in ~/code/<repo> for every entry in
#      `worktreeRepos` below.
#   3. ssh-keygen -t ed25519; git config --global gpg.format ssh;
#      git config --global user.signingkey ~/.ssh/id_ed25519.pub;
#      git config --global commit.gpgsign true; set user.name / user.email;
#      add the key on GitHub as a *signing* key.
#   4. gh auth login --with-token < token   (fine-grained, selected repos)
#      gh auth setup-git; clone repos into ~/code.
#   5. In an interactive `claude` session: /config → enable push notifications.
#   6. systemctl --user restart claude-rc-workspace
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # ── Knobs ────────────────────────────────────────────────────────────────
  idleMinutes = 20;

  # Repos under ~claude/code that get their own `--spawn worktree` server, e.g.
  # [ "grocery" "sequencer" ]. Each needs the one-time trust step above.
  # Kept empty for now: worktree mode has a reported restart loop under systemd.
  worktreeRepos = [ ];

  # Default model for spawned sessions. Must not require usage credits: the
  # credits consent prompt is not forwarded to the phone, so an unattended
  # turn would silently end. Verify against the Pro plan before relying on it.
  defaultModel = "sonnet";

  # Same pin as the system-wide claude-code in configuration.nix.
  pkgs-unstable = import inputs.nixpkgs-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
  };
  claude-code = pkgs-unstable.claude-code;

  activityDir = "/run/claude-activity";
  touchActivity = "${pkgs.coreutils}/bin/touch ${activityDir}/last";

  # Settings for every session the Remote Control servers spawn. Lives in the
  # Nix store, so sessions can read it but never rewrite their own hooks.
  touchHook = [
    {
      hooks = [
        {
          type = "command";
          command = touchActivity;
        }
      ];
    }
  ];
  toolHook = [
    {
      matcher = "*";
      hooks = [
        {
          type = "command";
          command = touchActivity;
        }
      ];
    }
  ];
  rcSettings = pkgs.writeText "claude-rc-settings.json" (
    builtins.toJSON {
      model = defaultModel;
      hooks = {
        UserPromptSubmit = touchHook;
        Stop = touchHook;
        PreToolUse = toolHook;
        PostToolUse = toolHook;
      };
    }
  );

  rcService =
    {
      dir,
      name,
      spawn,
    }:
    {
      description = "Claude Remote Control: ${name}";
      unitConfig = {
        # User units are installed for every user; only run for claude.
        ConditionUser = "claude";
        # Keep retrying while the network comes back after resume.
        StartLimitIntervalSec = 0;
      };
      path = [
        claude-code
        config.nix.package
      ]
      ++ (with pkgs; [
        git
        gh
        openssh
        coreutils
        bash
        gnugrep
        gnused
        findutils
      ]);
      environment = {
        DISABLE_AUTOUPDATER = "1"; # the Nix store copy can't update itself
      };
      serviceConfig = {
        WorkingDirectory = dir;
        ExecStart = lib.concatStringsSep " " [
          "${claude-code}/bin/claude remote-control"
          "--name ${name}"
          "--spawn ${spawn}"
          "--capacity 2" # Pro plan: two parallel sessions at most
          "--permission-mode acceptEdits"
          "--settings ${rcSettings}"
        ];
        Restart = "always";
        RestartSec = 30;
      };
    };
in
{
  # ── The claude user ──────────────────────────────────────────────────────
  # Not in wheel, docker or nix trusted-users. Home is 0700 (NixOS default),
  # and peter's home is 0700 too, so neither can read the other's files.
  users.groups.claude-activity = { };
  users.users.claude = {
    isNormalUser = true;
    description = "Claude Code (Remote Control)";
    linger = true;
    extraGroups = [ "claude-activity" ];
    packages = [
      claude-code
      pkgs.git
      pkgs.gh
    ];
    openssh.authorizedKeys.keys = config.users.users.peter.openssh.authorizedKeys.keys;
  };
  # peter's hypridle writes the desk-away marker.
  users.users.peter.extraGroups = [ "claude-activity" ];

  # ── Remote Control servers ───────────────────────────────────────────────
  # Default entry point: one same-dir server over all of ~/code, so it can
  # work in any repo below it and start new ones.
  systemd.user.services = {
    claude-rc-workspace =
      rcService {
        dir = "%h/code";
        name = "workspace";
        spawn = "same-dir";
      }
      // {
        wantedBy = [ "default.target" ];
      };

    # Optional per-repo servers with isolated worktrees: claude-rc@<repo>.
    "claude-rc@" = rcService {
      dir = "%h/code/%i";
      name = "%i";
      spawn = "worktree";
    };
  }
  // lib.genAttrs (map (r: "claude-rc@${r}") worktreeRepos) (_: {
    overrideStrategy = "asDropin";
    wantedBy = [ "default.target" ];
  });

  # ── Idle clock ───────────────────────────────────────────────────────────
  # $activityDir/last     mtime = last Claude activity, boot or resume
  # $activityDir/desk-away exists while peter's Hyprland session is idle
  systemd.tmpfiles.rules = [
    "d /home/claude/code 0750 claude users -"
    "d ${activityDir} 2775 root claude-activity -"
    "f ${activityDir}/last 0664 claude claude-activity -"
  ];

  # Every wake gets a full idle period of grace, so there is time to open the
  # app after tapping "Wake PC" in Home Assistant.
  powerManagement.resumeCommands = touchActivity;

  systemd.services.claude-idle-suspend = {
    description = "Suspend when Claude, SSH and the desk are all idle";
    path = with pkgs; [
      coreutils
      systemd
      gawk
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      last=$(stat -c %Y ${activityDir}/last 2>/dev/null || echo 0)
      now=$(date +%s)
      idle=$(( now - last ))
      if [ "$idle" -lt ${toString (idleMinutes * 60)} ]; then
        exit 0
      fi

      for s in $(loginctl list-sessions --no-legend | awk '{print $1}'); do
        class=$(loginctl show-session "$s" -p Class --value)
        state=$(loginctl show-session "$s" -p State --value)
        remote=$(loginctl show-session "$s" -p Remote --value)
        [ "$class" = user ] || continue
        # A logged-out session lingering on a leftover process doesn't count.
        [ "$state" = closing ] && continue
        if [ "$remote" = yes ]; then
          echo "SSH session $s open, not suspending"
          exit 0
        fi
        if [ ! -e ${activityDir}/desk-away ]; then
          echo "Local session $s active, not suspending"
          exit 0
        fi
      done

      echo "Idle for $(( idle / 60 )) min, suspending"
      systemctl suspend
    '';
  };

  systemd.timers.claude-idle-suspend = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10min";
      OnUnitActiveSec = "5min";
    };
  };

  # ── Desk marker (peter's Hyprland session) ───────────────────────────────
  # The hypridle listener that writes desk-away lives in pc-extras.nix, next
  # to the mkForce'd lock listener. hypridle never suspends on this machine;
  # suspending is left to the timer above so it can't cut off a Claude task.
  # A marker left over from a previous session must not count as "away".
  home-manager.users.peter.wayland.windowManager.hyprland.settings.exec-once = [
    "rm -f ${activityDir}/desk-away"
  ];
}
