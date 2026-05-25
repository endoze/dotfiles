FROM nixos/nix:latest

# nix.conf with no reference to private cache. Substituter + key are
# supplied only via --option flags during the secret-mounted RUN, so
# they never persist in any layer.
RUN printf '%s\n' \
      'experimental-features = nix-command flakes' \
      'require-sigs = false' \
      >> /etc/nix/nix.conf

COPY . /home/endoze/.dotfiles
WORKDIR /home/endoze/.dotfiles

# Build user setup + home-manager activation. The netrc is mounted as
# tmpfs for this RUN only — it is never written to a layer. Substituter
# URL and public key are passed via --option, so the resulting image
# carries zero reference to the private cache host.
RUN --mount=type=secret,id=attic-netrc,target=/etc/nix/attic-netrc \
    nix build .#packages.x86_64-linux.dockerUserSetup -o /tmp/user-setup \
        --option netrc-file /etc/nix/attic-netrc \
        --option extra-substituters https://cache.kahdu.org/main \
        --option extra-trusted-public-keys main:ch1Il2WBscgvKTDg00wIqQCT/wSyqlA7lD0n2m2VkOg= \
 && /tmp/user-setup/bin/setup-user \
 && nix build .#homeConfigurations.docker.activationPackage \
        -o /home/endoze/.hm-activation \
        --option netrc-file /etc/nix/attic-netrc \
        --option extra-substituters https://cache.kahdu.org/main \
        --option extra-trusted-public-keys main:ch1Il2WBscgvKTDg00wIqQCT/wSyqlA7lD0n2m2VkOg= \
 && chown -R 1000:100 /home/endoze \
 && chown -R 1000:100 /nix

USER endoze
ENV USER=endoze
WORKDIR /home/endoze
RUN ./.hm-activation/activate

ENV PATH="/home/endoze/.nix-profile/bin:$PATH"
ENTRYPOINT ["/home/endoze/.nix-profile/bin/fish"]
