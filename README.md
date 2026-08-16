# nix-user

Declarative user profiles shared by NixOS and nix-darwin without Home Manager.

## What this provides

- `nixosModules.profiles` for NixOS consumers
- `darwinModules.profiles` for nix-darwin consumers
- `profile.tcurdt` as the shared account profile

## Local usage

```bash
nix flake check path:.
```

## Consume from another flake

Add input:

```nix
inputs.nix-user.url = "github:tcurdt/nix-user";
```

Import the platform module:

```nix
imports = [
  inputs.nix-user.nixosModules.profiles
];
```

For nix-darwin, use the Darwin module instead:

```nix
imports = [
  inputs.nix-user.darwinModules.profiles
];
```

Assign the profile to an account on either platform:

```nix
users.users.tcurdt.profile = import inputs.nix-user.profile.tcurdt;
```

## Layout

- `modules/profiles.nix`: shared profile schema and platform activation backends
- `profiles/tcurdt.nix`: account packages and configuration
- `flake.nix`: module and profile exports
