.DEFAULT_GOAL = none

none:

install-nix-overlays-nixos:
	cp -r overlays* /etc/nixos

install-nix-overlays-nixpkgs:
	mkdir -p $(HOME)/.config/nixpkgs
	cp -r overlays/* $(HOME)/.config/nixpkgs

BF_SDE_DEPS = $(wildcard environments/bf-sde/*)
BMV2_DEPS = $(wildcard environments/bmv2/*)

bf-sde-env-closure: nixpkgs.nix $(BF_SDE_DEPS)
	set -e; \
	nix-build --cores 0 -E 'import ./environments/bf-sde/inputs.nix (import ./nixpkgs.nix)'; \
	paths=$$(nix-instantiate --eval ./environments/bf-sde/store-paths.nix | sed -e 's/\"//g'); \
	nix-store --export $$paths >$@

bf-sde-env: $(BF_SDE_DEPS)
	nix-shell --pure --cores 0 ./environments/bf-sde/env.nix || true

bmv2-env: $(BMV2_DEPS)
	nix-shell --pure --cores 0 ./environments/bmv2/env.nix || true
