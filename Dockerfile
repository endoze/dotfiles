FROM nixos/nix:latest

RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

COPY . /dotfiles

WORKDIR /dotfiles

# Build user setup script and create user via Nix
RUN nix build .#packages.x86_64-linux.dockerUserSetup -o /tmp/user-setup && \
    /tmp/user-setup/bin/setup-user

# Build home-manager activation as root (has nix store permissions)
RUN nix build .#homeConfigurations.docker.activationPackage -o /home/endoze/.hm-activation && \
    chown -R 1000:100 /home/endoze && \
    chown -R 1000:100 /nix

# Copy dotfiles for the user
RUN cp -r /dotfiles /home/endoze/.dotfiles && \
    chown -R 1000:100 /home/endoze/.dotfiles

# Switch to endoze and activate home-manager
USER endoze
ENV USER=endoze
WORKDIR /home/endoze
RUN ./.hm-activation/activate

ENV PATH="/home/endoze/.nix-profile/bin:$PATH"
ENTRYPOINT ["/home/endoze/.nix-profile/bin/fish"]
