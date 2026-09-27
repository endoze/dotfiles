function shrinkrec -d "Compress a screen recording for sharing: crisp text, source frame rate, much smaller file"
    argparse h/help f/force 'w/width=' 'c/crf=' 's/suffix=' -- $argv
    or return 1

    if set -q _flag_help; or test (count $argv) -eq 0
        echo "Usage: shrinkrec [options] FILE..."
        echo ""
        echo "Re-encodes a screen recording to H.264 MP4 alongside the original."
        echo "Tuned for screen capture: text stays readable, frame rate is kept,"
        echo "and the result is small enough to drop into Slack."
        echo ""
        echo "Options:"
        echo "  -w, --width N     Max output width, never upscaled (default 3072)"
        echo "  -c, --crf N       Quality, lower is better/bigger (default 19)"
        echo "  -s, --suffix STR  Output name suffix (default -compressed)"
        echo "  -f, --force       Overwrite an existing output file"
        echo "  -h, --help        Show this help"
        test (count $argv) -eq 0; and not set -q _flag_help; and return 1
        return 0
    end

    set -l width (set -q _flag_width; and echo $_flag_width; or echo 3072)
    set -l crf (set -q _flag_crf; and echo $_flag_crf; or echo 19)
    set -l suffix (set -q _flag_suffix; and echo $_flag_suffix; or echo -compressed)

    # Use a local ffmpeg when there is one, otherwise pull it from nixpkgs.
    set -l ff ffmpeg
    if not command -q ffmpeg
        set ff nix run nixpkgs#ffmpeg --
    end

    # Cap the width without ever upscaling, and keep both dimensions even for yuv420p.
    set -l vf "scale='trunc(min(iw,$width)/2)*2':-2:flags=lanczos"

    set -l status_code 0

    for src in $argv
        if not test -f "$src"
            echo "shrinkrec: no such file: $src" >&2
            set status_code 1
            continue
        end

        set -l out (path change-extension '' -- "$src")"$suffix.mp4"

        if test -e "$out"; and not set -q _flag_force
            echo "shrinkrec: output already exists, pass --force to overwrite: $out" >&2
            set status_code 1
            continue
        end

        set -l before (string trim (wc -c <"$src"))

        $ff -hide_banner -loglevel warning -stats -y -i "$src" \
            -vf "$vf" \
            -c:v libx264 -preset medium -crf $crf -profile:v high \
            -pix_fmt yuv420p -movflags +faststart \
            -c:a aac \
            "$out"
        or begin
            echo "shrinkrec: ffmpeg failed on: $src" >&2
            set status_code 1
            continue
        end

        set -l after (string trim (wc -c <"$out"))
        printf '%s  %.1f MB -> %.1f MB\n' "$out" (math "$before / 1048576") (math "$after / 1048576")
    end

    return $status_code
end
