{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatMapStringsSep
    concatStringsSep
    escapeShellArg
    # filter
    filterAttrs
    listToAttrs
    mapAttrs'
    mapAttrsToList
    mkAfter
    mkIf
    mkOption
    nameValuePair
    optionalString
    types
    unique
    ;

  profileType = types.submoduleWith {
    specialArgs = { inherit pkgs; };
    modules = [
      {
        options = {
          packages = mkOption {
            type = types.listOf types.package;
            default = [ ];
          };

          shellAliases = mkOption {
            type = types.attrsOf types.str;
            default = { };
          };

          sessionVariables = mkOption {
            type = types.attrsOf (
              types.oneOf [
                types.str
                types.int
                types.bool
              ]
            );
            default = { };
          };

          sessionPath = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Paths relative to the account's home directory.";
          };

          bashInit = mkOption {
            type = types.lines;
            default = "";
          };

          files = mkOption {
            type = types.attrsOf types.path;
            default = { };
            description = "Files to link relative to the account's home directory.";
          };
        };
      }
    ];
  };

  usersWithProfiles = filterAttrs (_username: user: user.profile != null) config.users.users;

  userProfileModule =
    { config, ... }:
    {
      options.profile = mkOption {
        type = types.nullOr profileType;
        default = null;
        description = "Declarative account profile.";
      };

      config.packages = mkIf (config.profile != null) config.profile.packages;
    };

  renderSessionVariables =
    variables:
    concatStringsSep "\n" (
      mapAttrsToList (name: value: "export ${name}=${escapeShellArg (toString value)}") variables
    );

  renderSessionPath =
    paths:
    optionalString (paths != [ ]) ''
      for account_profile_path in ${
        concatMapStringsSep " " (path: ''"$HOME"/${escapeShellArg path}'') paths
      }; do
        case ":$PATH:" in
          *":$account_profile_path:"*) ;;
          *) PATH="$account_profile_path:$PATH" ;;
        esac
      done
      unset account_profile_path
      export PATH
    '';

  renderAliases =
    aliases:
    concatStringsSep "\n" (
      mapAttrsToList (name: value: "alias ${name}=${escapeShellArg value}") aliases
    );

  accountFiles =
    username: profile:
    let
      profileScript = pkgs.writeText "account-profile-${username}-profile" ''
        ${renderSessionVariables profile.sessionVariables}
        ${renderSessionPath profile.sessionPath}
      '';
      bashrc = pkgs.writeText "account-profile-${username}-bashrc" ''
        if [ -f "$HOME/.profile" ]; then
          . "$HOME/.profile"
        fi

        if [[ $- == *i* ]]; then
          ${renderAliases profile.shellAliases}
          ${profile.bashInit}
        fi
      '';
      bashProfile = pkgs.writeText "account-profile-${username}-bash-profile" ''
        if [ -f "$HOME/.bashrc" ]; then
          . "$HOME/.bashrc"
        fi
      '';
    in
    profile.files
    // {
      ".profile" = profileScript;
      ".bashrc" = bashrc;
      ".bash_profile" = bashProfile;
    };

  parentDirectories =
    relativePath:
    let
      directory = builtins.dirOf relativePath;
    in
    if directory == "." then [ ] else parentDirectories directory ++ [ directory ];

  accountDirectories =
    user: files:
    map (directory: "${user.home}/${directory}") (
      unique (builtins.concatMap parentDirectories (builtins.attrNames files))
    );

  linuxTmpfiles =
    username: user:
    let
      files = accountFiles username user.profile;
      directoryRules = listToAttrs (
        map (
          directory:
          nameValuePair directory {
            d = {
              user = username;
              group = user.group;
              mode = "0755";
            };
          }
        ) (accountDirectories user files)
      );
      fileRules = mapAttrs' (
        relativePath: source:
        nameValuePair "${user.home}/${relativePath}" {
          "L+" = {
            argument = toString source;
            user = username;
            group = user.group;
          };
        }
      ) files;
    in
    directoryRules // fileRules;

  darwinActivation = concatMapStringsSep "\n" (
    username:
    let
      user = usersWithProfiles.${username};
      files = accountFiles username user.profile;
    in
    ''
      account_profile_group="$(${pkgs.coreutils}/bin/id -g ${escapeShellArg username})"
      ${concatMapStringsSep "\n" (directory: ''
        ${pkgs.coreutils}/bin/mkdir -p ${escapeShellArg directory}
        ${pkgs.coreutils}/bin/chown ${escapeShellArg username}:"$account_profile_group" ${escapeShellArg directory}
        ${pkgs.coreutils}/bin/chmod 0755 ${escapeShellArg directory}
      '') (accountDirectories user files)}
      ${concatStringsSep "\n" (
        mapAttrsToList (relativePath: source: ''
          ${pkgs.coreutils}/bin/ln -sfn ${escapeShellArg (toString source)} ${escapeShellArg "${user.home}/${relativePath}"}
          ${pkgs.coreutils}/bin/chown -h ${escapeShellArg username}:"$account_profile_group" ${escapeShellArg "${user.home}/${relativePath}"}
        '') files
      )}
      unset account_profile_group
    ''
  ) (builtins.attrNames usersWithProfiles);
in
{
  options.users.users = mkOption {
    type = types.attrsOf (types.submodule userProfileModule);
  };

  config =
    if options ? systemd then
      {
        systemd.tmpfiles.settings = mapAttrs' (
          username: user: nameValuePair "10-account-profile-${username}" (linuxTmpfiles username user)
        ) usersWithProfiles;
      }
    else if options ? system.activationScripts then
      {
        assertions = mapAttrsToList (username: user: {
          assertion = user.home != null;
          message = "users.users.${username}.home must be set when using an account profile.";
        }) usersWithProfiles;

        system.activationScripts.postActivation.text = mkAfter darwinActivation;
      }
    else
      { };
}
