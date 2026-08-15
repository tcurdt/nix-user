# nix-home

Personal Home Manager setup as a reusable flake module.

## What this provides

- `homeManagerModules.tcurdt` as the main module to import from other flakes
- `nixosModules.default` to enable Home Manager on NixOS with sane defaults
- Platform-specific layering via `modules/darwin.nix` and `modules/linux.nix`

## Local usage

```bash
nix flake check path:.
```

## Consume from another flake

Add input:

```nix
inputs.home.url = "github:tcurdt/nix-home";
```

Import module:

```nix
home-manager.users.tcurdt.imports = [
  inputs.home.homeManagerModules.tcurdt
];
```

For NixOS, import the integration module once:

```nix
modules = [
  inputs.home.nixosModules.default
  ./machine.nix
];
```

After changing this flake, update consumers such as `nix-server`:

```bash
cd ../nix-server
just update
just check
```

## Layout

- `modules/common.nix`: shared config
- `modules/darwin.nix`: macOS-specific additions
- `modules/linux.nix`: Linux-specific additions
- `flake.nix`: exports `homeManagerModules.tcurdt` and composes modules
