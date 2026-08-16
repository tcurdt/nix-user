{
  description = "declarative user profiles for nix";

  outputs =
    { self }:
    {
      nixosModules.profiles = ./modules/profiles.nix;
      darwinModules.profiles = ./modules/profiles.nix;

      profile.tcurdt = ./profiles/tcurdt.nix;
    };
}
