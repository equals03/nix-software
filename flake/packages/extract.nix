{
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    extract = pkgs.writeShellApplication {
      name = "extract";

      runtimeInputs = with pkgs; [
        file
        libarchive
        gzip
        bzip2
        xz
        zstd
        lzip
        lz4
        unrar
      ];

      meta = with lib; {
        description = "Safely extract common archive formats using file-based type detection";
        longDescription = ''
          extract is a small shell utility for unpacking common archive formats
          with sensible defaults. It uses file(1) to detect the real archive type
          instead of trusting filename extensions, extracts into a dedicated
          directory by default, supports listing and dry-run modes, and protects
          against accidental overwrites for single-file decompression.

          Supported formats include tar, gzip, bzip2, xz, zstd, lzip, lz4, zip,
          7z, and rar, depending on the capabilities of the configured extractors.
        '';
        license = licenses.mit;
        mainProgram = "extract";
        platforms = platforms.unix;
      };

      text = ''
        set -euo pipefail

        usage() {
          cat <<'EOF'
        Usage:
          extract [OPTIONS] ARCHIVE [DESTINATION]

        Extract common archive formats using file(1) to detect the real type.

        Options:
          -l, --list       List archive contents instead of extracting
          -n, --dry-run    Show what would be done without extracting
          -h, --help       Show this help message

        Examples:
          extract foo.tar.gz
          extract foo.zip ./out
          extract --list foo.7z
          extract --dry-run foo.tar.zst
        EOF
        }

        die() {
          echo "error: $*" >&2
          exit 1
        }

        default_dest() {
          local name
          name=$(basename "$1")

          case "$name" in
            *.tar.gz)  name=''${name%.tar.gz} ;;
            *.tgz)     name=''${name%.tgz} ;;
            *.tar.bz2) name=''${name%.tar.bz2} ;;
            *.tbz2)    name=''${name%.tbz2} ;;
            *.tar.xz)  name=''${name%.tar.xz} ;;
            *.txz)     name=''${name%.txz} ;;
            *.tar.zst) name=''${name%.tar.zst} ;;
            *.tzst)    name=''${name%.tzst} ;;
            *.tar.lz)  name=''${name%.tar.lz} ;;
            *.tar.lz4) name=''${name%.tar.lz4} ;;
            *.tar)     name=''${name%.tar} ;;
            *.zip)     name=''${name%.zip} ;;
            *.7z)      name=''${name%.7z} ;;
            *.rar)     name=''${name%.rar} ;;
            *.gz)      name=''${name%.gz} ;;
            *.bz2)     name=''${name%.bz2} ;;
            *.xz)      name=''${name%.xz} ;;
            *.zst)     name=''${name%.zst} ;;
            *.lz)      name=''${name%.lz} ;;
            *.lz4)     name=''${name%.lz4} ;;
          esac

          printf '%s\n' "$name"
        }

        strip_single_compression_suffix() {
          local name
          name=$(basename "$1")

          case "$name" in
            *.gz)  name=''${name%.gz} ;;
            *.bz2) name=''${name%.bz2} ;;
            *.xz)  name=''${name%.xz} ;;
            *.zst) name=''${name%.zst} ;;
            *.lz)  name=''${name%.lz} ;;
            *.lz4) name=''${name%.lz4} ;;
          esac

          printf '%s\n' "$name"
        }

        is_tar_stream() {
          local archive=$1
          bsdtar -tf "$archive" >/dev/null 2>&1
        }

        is_archive_mime() {
          local mime=$1
          local desc=$2

          case "$mime" in
            application/zip | \
            application/x-tar | \
            application/gzip | \
            application/x-gzip | \
            application/x-bzip2 | \
            application/x-xz | \
            application/zstd | \
            application/x-zstd | \
            application/x-7z-compressed | \
            application/vnd.rar | \
            application/x-rar | \
            application/x-rar-compressed | \
            application/x-lzip | \
            application/x-lz4)
              return 0
              ;;
          esac

          case "$desc" in
            *"Zip archive data"* | \
            *"tar archive"* | \
            *"gzip compressed data"* | \
            *"bzip2 compressed data"* | \
            *"XZ compressed data"* | \
            *"Zstandard compressed data"* | \
            *"7-zip archive data"* | \
            *"RAR archive data"* | \
            *"lzip compressed data"* | \
            *"LZ4 compressed data"*)
              return 0
              ;;
          esac

          return 1
        }

        is_single_compressor_mime() {
          local mime=$1
          local desc=$2

          case "$mime" in
            application/gzip | \
            application/x-gzip | \
            application/x-bzip2 | \
            application/x-xz | \
            application/zstd | \
            application/x-zstd | \
            application/x-lzip | \
            application/x-lz4)
              return 0
              ;;
          esac

          case "$desc" in
            *"gzip compressed data"* | \
            *"bzip2 compressed data"* | \
            *"XZ compressed data"* | \
            *"Zstandard compressed data"* | \
            *"lzip compressed data"* | \
            *"LZ4 compressed data"*)
              return 0
              ;;
          esac

          return 1
        }

        list_archive() {
          local archive=$1
          local mime=$2
          local desc=$3

          case "$mime" in
            application/vnd.rar | application/x-rar | application/x-rar-compressed)
              unrar l "$archive"
              return
              ;;
          esac

          case "$desc" in
            *"RAR archive data"*)
              unrar l "$archive"
              return
              ;;
          esac

          if bsdtar -tf "$archive" >/dev/null 2>&1; then
            bsdtar -tf "$archive"
            return
          fi

          if is_single_compressor_mime "$mime" "$desc"; then
            strip_single_compression_suffix "$archive"
            return
          fi

          die "cannot list unsupported archive type: $mime"
        }

        extract_single_compressed_file() {
          local archive=$1
          local dest=$2
          local mime=$3
          local desc=$4

          local out
          out=$(strip_single_compression_suffix "$archive")

          local target="$dest/$out"

          if [[ -e "$target" ]]; then
            die "refusing to overwrite existing file: $target"
          fi

          mkdir -p "$dest"

          case "$mime" in
            application/gzip | application/x-gzip)
              gzip -dc "$archive" > "$target"
              return
              ;;

            application/x-bzip2)
              bzip2 -dc "$archive" > "$target"
              return
              ;;

            application/x-xz)
              xz -dc "$archive" > "$target"
              return
              ;;

            application/zstd | application/x-zstd)
              zstd -dc "$archive" > "$target"
              return
              ;;

            application/x-lzip)
              lzip -dc "$archive" > "$target"
              return
              ;;

            application/x-lz4)
              lz4 -dc "$archive" > "$target"
              return
              ;;
          esac

          case "$desc" in
            *"gzip compressed data"*)
              gzip -dc "$archive" > "$target"
              ;;

            *"bzip2 compressed data"*)
              bzip2 -dc "$archive" > "$target"
              ;;

            *"XZ compressed data"*)
              xz -dc "$archive" > "$target"
              ;;

            *"Zstandard compressed data"*)
              zstd -dc "$archive" > "$target"
              ;;

            *"lzip compressed data"*)
              lzip -dc "$archive" > "$target"
              ;;

            *"LZ4 compressed data"*)
              lz4 -dc "$archive" > "$target"
              ;;

            *)
              die "unsupported single-file compression type: $mime"
              ;;
          esac
        }

        extract_archive() {
          local archive=$1
          local dest=$2
          local mime=$3
          local desc=$4

          mkdir -p "$dest"

          case "$mime" in
            application/vnd.rar | application/x-rar | application/x-rar-compressed)
              unrar x "$archive" "$dest/"
              return
              ;;
          esac

          case "$desc" in
            *"RAR archive data"*)
              unrar x "$archive" "$dest/"
              return
              ;;
          esac

          if bsdtar -tf "$archive" >/dev/null 2>&1; then
            bsdtar -xf "$archive" -C "$dest"
            return
          fi

          if is_single_compressor_mime "$mime" "$desc"; then
            extract_single_compressed_file "$archive" "$dest" "$mime" "$desc"
            return
          fi

          die "unsupported archive type: $mime"
        }

        list_mode=false
        dry_run=false

        args=()

        while [[ $# -gt 0 ]]; do
          case "$1" in
            -l|--list)
              list_mode=true
              shift
              ;;

            -n|--dry-run)
              dry_run=true
              shift
              ;;

            -h|--help)
              usage
              exit 0
              ;;

            --)
              shift
              args+=("$@")
              break
              ;;

            -*)
              die "unknown option: $1"
              ;;

            *)
              args+=("$1")
              shift
              ;;
          esac
        done

        if [[ ''${#args[@]} -lt 1 || ''${#args[@]} -gt 2 ]]; then
          usage
          exit 1
        fi

        archive=''${args[0]}
        dest=''${args[1]:-"$(default_dest "$archive")"}

        [[ -f "$archive" ]] || die "not a file: $archive"

        mime=$(file --brief --mime-type "$archive")
        desc=$(file --brief "$archive")

        if ! is_archive_mime "$mime" "$desc"; then
          echo "file reports:" >&2
          echo "  MIME:        $mime" >&2
          echo "  Description: $desc" >&2
          die "unsupported file type"
        fi

        if [[ "$list_mode" == true ]]; then
          list_archive "$archive" "$mime" "$desc"
          exit 0
        fi

        if [[ "$dry_run" == true ]]; then
          echo "Archive:      $archive"
          echo "Destination:  $dest"
          echo "MIME:         $mime"
          echo "Description:  $desc"

          if is_tar_stream "$archive"; then
            echo "Mode:         archive extraction via bsdtar"
          elif is_single_compressor_mime "$mime" "$desc"; then
            echo "Mode:         single-file decompression"
            echo "Output file:  $dest/$(strip_single_compression_suffix "$archive")"
          else
            echo "Mode:         fallback extraction"
          fi

          exit 0
        fi

        extract_archive "$archive" "$dest" "$mime" "$desc"
      '';
    };
  in {
    packages = {
      inherit extract;
    };
  };
}
