FROM nixos/nix:latest

RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

RUN echo "endoze:x:1000:1000:Endoze:/home/endoze:/bin/sh" >> /etc/passwd && \
  echo "endoze:x:1000:" >> /etc/group && \
  mkdir -p /home/endoze && \
  chown -R 1000:1000 /home/endoze

COPY . /home/endoze/.dotfiles

WORKDIR /home/endoze/.dotfiles

RUN nix build .#homeConfigurations.docker.activationPackage && \
  chown -R 1000:1000 /home/endoze

USER endoze

RUN ./result/activate

ENV SHELL=/home/endoze/.nix-profile/bin/fish

WORKDIR /home/endoze

ENTRYPOINT ["/home/endoze/.nix-profile/bin/fish"]
