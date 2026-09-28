# Prometheus exporter for Hitron CODA DOCSIS 3.1 modems (not in nixpkgs), patched for the CODA-45.
# https://github.com/hairyhenderson/hitron_coda_exporter
{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "hitron-coda-exporter";
  version = "0.1.1-unstable-2025-06-19";

  src = fetchFromGitHub {
    owner = "hairyhenderson";
    repo = "hitron_coda_exporter";
    rev = "9ee7842fd8409b3d2392850c675a0b33d0df8821";
    hash = "sha256-w1exTFLNM7D6hXIaAlaqYnB33bj+8uYZBpqcGm936Lc=";
  };

  vendorHash = "sha256-WKabqkOP5Qtvkj1KX6jFD6VtiaLkmf9ufasMXmcJep4=";

  subPackages = [ "." ];

  # CODA-45 support (bridge-only, status-only UI with no login):
  #  - login failure is non-fatal; `modem_only: true` in the config skips Router/WiFi APIs
  #  - library: accept wrapped octet counters like "9 * 2e32 + 868756518"
  patches = [ ./modem-only.patch ];
  preBuild = ''
    chmod -R u+w vendor
    patch -d vendor -p1 < ${./octets.patch}
  '';

  ldflags = [
    "-s" "-w"
    "-X github.com/hairyhenderson/hitron_coda_exporter/internal/version.Version=${version}"
    "-X github.com/hairyhenderson/hitron_coda_exporter/internal/version.GitCommit=${src.rev}"
  ];

  doCheck = false;

  meta = {
    description = "Prometheus exporter for Hitron CODA cable modems";
    homepage = "https://github.com/hairyhenderson/hitron_coda_exporter";
    license = lib.licenses.mit;
    mainProgram = "hitron_coda_exporter";
  };
}
