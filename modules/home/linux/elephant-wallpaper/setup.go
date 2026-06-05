package main

import (
	"fmt"
	"log/slog"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/abenz1267/elephant/v2/pkg/common"
	"github.com/abenz1267/elephant/v2/pkg/pb/pb"
)

var (
	Name       = "wallpaper"
	NamePretty = "Wallpaper"
)

type Config struct {
	common.Config `koanf:",squash"`
	Dirs          []string `koanf:"dirs"`
}

var config *Config

var imageExts = map[string]bool{
	".jpg": true, ".jpeg": true, ".png": true,
	".webp": true, ".gif": true, ".bmp": true,
}

func Setup() {
	LoadConfig()
}

func LoadConfig() {
	home, _ := os.UserHomeDir()
	config = &Config{
		Config: common.Config{
			Icon:                 "preferences-desktop-wallpaper",
			HideFromProviderlist: false,
			MinScore:             0,
		},
		Dirs: []string{
			filepath.Join(home, ".config", "hypr", "wallpapers"),
			filepath.Join(home, "Pictures", "Wallpapers"),
		},
	}
	common.LoadConfig(Name, config)
}

func Available() bool {
	return true
}

func Query(_ net.Conn, query string, _ bool, exact bool, _ uint8) []*pb.QueryResponse_Item {
	var items []*pb.QueryResponse_Item

	for _, dir := range config.Dirs {
		entries, err := os.ReadDir(dir)
		if err != nil {
			continue
		}

		for _, entry := range entries {
			if entry.IsDir() {
				continue
			}

			ext := strings.ToLower(filepath.Ext(entry.Name()))
			if !imageExts[ext] {
				continue
			}

			fullPath := filepath.Join(dir, entry.Name())
			name := entry.Name()

			item := &pb.QueryResponse_Item{
				Identifier:  fullPath,
				Text:        name,
				Subtext:     dir,
				Provider:    Name,
				Icon:        fullPath,
				Preview:     fullPath,
				PreviewType: "image",
				Score:       100,
				Actions:     []string{"apply"},
			}

			if query != "" {
				score, positions, start := common.FuzzyScore(query, name, exact)
				if score <= config.MinScore {
					continue
				}
				item.Score = score
				item.Fuzzyinfo = &pb.QueryResponse_Item_FuzzyInfo{
					Positions: positions,
					Start:     start,
				}
			}

			items = append(items, item)
		}
	}

	return items
}

func Activate(_ bool, identifier, _ string, _ string, _ string, _ uint8, _ net.Conn) {
	home, _ := os.UserHomeDir()
	currentWallpaper := filepath.Join(home, ".config", "hypr", "current-wallpaper")

	os.Remove(currentWallpaper)
	if err := os.Symlink(identifier, currentWallpaper); err != nil {
		slog.Error(Name, "symlink", err)
		return
	}

	go func() {
		exec.Command("awww", "img", identifier,
			"--transition-type", "random",
			"--transition-fps", "60",
			"--transition-duration", "1",
		).Run()
		exec.Command("wallust-apply", identifier).Run()
	}()
}

func Icon() string {
	return config.Icon
}

func HideFromProviderlist() bool {
	return config.HideFromProviderlist
}

func PrintDoc(_ bool) {
	fmt.Println("Wallpaper provider: browse and apply wallpapers with theme generation")
}

func State(_ string) *pb.ProviderStateResponse {
	return &pb.ProviderStateResponse{}
}
